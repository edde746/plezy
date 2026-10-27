import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage_webos/flutter_secure_storage_webos.dart';
import 'package:flutter_test/flutter_test.dart';

const _options = <String, String>{};
const _index = 'flutter_secure_storage';
const _iv = 'AAAAAAAAAAAAAAAAAAAAAA==';

/// Bind dummy ciphertext to its key so premature key deletion/replacement is
/// observable. OS cryptography is outside this fault-injection test's scope.
class _Backend {
  final keys = <String>{_index, 'vault'};
  final handles = <String, ({String key, bool encrypting})>{};
  final removed = <String>[];
  Map<String, String?> row = {};
  String? unavailableKey;
  bool generationFails = false;
  bool valueEncryptionFails = false;
  bool indexEncryptionFails = false;
  bool storeFails = false;
  bool loadFails = false;
  bool cleanupFails = false;
  bool loseAcknowledgement = false;
  bool conflictOnce = false;
  int stores = 0;
  int generations = 0;
  int serial = 0;

  _Backend() {
    seed({'vault': 'ORIGINAL_DUMMY_KEY'});
  }
  String encrypted(String key, String plain) =>
      _iv + base64Encode(utf8.encode(jsonEncode({'key': key, 'data': base64Encode(utf8.encode(plain))})));
  void seed(Map<String, String> entries) {
    keys.addAll(entries.keys);
    row = {
      'keys': encrypted(_index, jsonEncode(entries.keys.toList())),
      'datas': jsonEncode([for (final entry in entries.entries) encrypted(entry.key, entry.value)]),
    };
  }

  Future<Object?> storage(MethodCall call) async {
    if (call.method == 'load') {
      if (loadFails) throw PlatformException(code: 'io');
      return Map<String, String?>.from(row);
    }
    expect(call.method, 'compareAndStore', reason: 'all writes must compare the expected persisted row');
    stores++;
    if (storeFails) throw PlatformException(code: 'io');
    final args = Map<String, Object?>.from(call.arguments as Map);
    if (conflictOnce) {
      conflictOnce = false;
      seed({'vault': 'ORIGINAL_DUMMY_KEY', 'other-isolate': 'OTHER_DUMMY_KEY'});
    }
    if (row['keys'] != args['expectedKeys'] || row['datas'] != args['expectedDatas']) return false;
    // Both currently referenced legacy keys must survive until the commit.
    if ((row['keys'] ?? '').startsWith(_iv)) expect(keys, contains(_index));
    row = {'keys': args['keys'] as String, 'datas': args['datas'] as String};
    if (loseAcknowledgement) throw PlatformException(code: 'io');
    return true;
  }

  Future<Object?> service(MethodCall call) async {
    final args = Map<String, Object?>.from(call.arguments as Map);
    final key = args['name'] as String?;
    switch (call.method) {
      case 'keymanager/generateKey':
        generations++;
        if (generationFails) return false;
        expect(keys, isNot(contains(key)), reason: 'never regenerate a key backing saved ciphertext');
        keys.add(key!);
        return true;
      case 'keymanager/removeKey':
        if (cleanupFails) throw PlatformException(code: 'unavailable');
        removed.add(key!);
        keys.remove(key);
        return true;
      case 'keymanager/begin':
        if (!keys.contains(key) || key == unavailableKey) return {'returnValue': false};
        final params = Map<String, Object?>.from(args['params'] as Map);
        final id = '${serial++}';
        handles[id] = (key: key!, encrypting: (params['purpose'] as List).contains('encrypt'));
        return {'returnValue': true, 'iv': _iv, 'handle': id};
      case 'keymanager/finish':
        final handle = handles[args['handle']]!;
        if (!keys.contains(handle.key)) return {'returnValue': false};
        if (handle.encrypting) {
          final plain = utf8.decode(base64Decode(args['data'] as String));
          final isIndex = plain.startsWith('[');
          if ((isIndex && indexEncryptionFails) || (!isIndex && valueEncryptionFails)) return {'returnValue': false};
          return {'returnValue': true, 'output': encrypted(handle.key, plain).substring(24)};
        }
        final decoded = jsonDecode(utf8.decode(base64Decode(args['data'] as String))) as Map;
        if (decoded['key'] != handle.key) return {'returnValue': false};
        return {'returnValue': true, 'output': decoded['data']};
      case 'keymanager/abort':
        handles.remove(args['handle']);
        return true;
    }
    throw StateError(call.method);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late _Backend backend;
  late FlutterSecureStorageWebos storage;
  Future<String?> read([String key = 'vault']) => storage.read(key: key, options: _options);
  Future<void> write(String value, [String key = 'vault']) => storage.write(key: key, value: value, options: _options);
  final unavailable = isA<PlatformException>().having((e) => e.code, 'code', 'secure_storage_unavailable');

  setUp(() {
    backend = _Backend();
    storage = FlutterSecureStorageWebos();
    messenger.setMockMethodCallHandler(const MethodChannel('webos/secure_storage'), backend.storage);
    messenger.setMockMethodCallHandler(const MethodChannel('webos_plugin'), backend.service);
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(const MethodChannel('webos/secure_storage'), null);
    messenger.setMockMethodCallHandler(const MethodChannel('webos_plugin'), null);
  });

  test('legacy reads and missing-key checks perform no writes or key rotation', () async {
    expect(await read(), 'ORIGINAL_DUMMY_KEY');
    expect(await read('absent'), isNull);
    expect(await storage.containsKey(key: 'vault', options: _options), isTrue);
    expect(backend.stores, 0);
    expect(backend.generations, 0);
    expect(backend.removed, isEmpty);
  });

  for (final key in ['vault', _index]) {
    test('transient $key failure preserves bytes and recovers in a fresh adapter', () async {
      final before = Map.of(backend.row);
      backend.unavailableKey = key;
      await expectLater(read(), throwsA(unavailable));
      expect(backend.row, before);
      expect(backend.stores, 0);
      expect(backend.removed, isEmpty);
      backend.unavailableKey = null;
      storage = FlutterSecureStorageWebos();
      expect(await read(), 'ORIGINAL_DUMMY_KEY');
    });
  }

  test('readAll propagates an unavailable entry instead of returning a partial store', () async {
    backend.seed({'vault': 'ORIGINAL_DUMMY_KEY', 'other': 'OTHER'});
    backend.unavailableKey = 'other';
    await expectLater(storage.readAll(options: _options), throwsA(unavailable));
    expect(backend.stores, 0);
    backend.unavailableKey = null;
    expect(await storage.readAll(options: _options), {'vault': 'ORIGINAL_DUMMY_KEY', 'other': 'OTHER'});
  });

  test('native load failure is not treated as a new empty store', () async {
    backend.loadFails = true;
    await expectLater(write('replacement'), throwsA(isA<PlatformException>()));
    expect(backend.stores, 0);
    expect(backend.generations, 0);
    backend.loadFails = false;
    expect(await read(), 'ORIGINAL_DUMMY_KEY');
  });

  test('malformed persisted lists are preserved and reported', () async {
    backend.row['datas'] = '[]';
    final before = Map.of(backend.row);
    await expectLater(write('replacement'), throwsA(isA<PlatformException>()));
    expect(backend.row, before);
    expect(backend.stores, 0);
  });

  for (final failure in ['generation', 'value-encryption', 'index-encryption', 'store']) {
    test('$failure failure during overwrite preserves the previous usable credential', () async {
      final before = Map.of(backend.row);
      backend.generationFails = failure == 'generation';
      backend.valueEncryptionFails = failure == 'value-encryption';
      backend.indexEncryptionFails = failure == 'index-encryption';
      backend.storeFails = failure == 'store';
      await expectLater(write('REPLACEMENT'), throwsA(isA<PlatformException>()));
      expect(backend.row, before);
      expect(backend.keys, containsAll([_index, 'vault']));
      if (failure != 'store') {
        expect(backend.keys, {_index, 'vault'}, reason: 'uncommitted staging keys are cleaned up');
      }
      backend.generationFails = backend.valueEncryptionFails = backend.indexEncryptionFails = backend.storeFails =
          false;
      storage = FlutterSecureStorageWebos();
      expect(await read(), 'ORIGINAL_DUMMY_KEY');
    });
  }

  test('overwrite upgrades legacy envelopes atomically and survives restart', () async {
    await write('REPLACEMENT');
    expect(backend.row['keys'], startsWith('v2:fss_'));
    expect(backend.removed, containsAll([_index, 'vault']));
    storage = FlutterSecureStorageWebos();
    expect(await read(), 'REPLACEMENT');
    await write('SECOND');
    expect(await read(), 'SECOND');
  });

  test('unaffected legacy entries stay readable after an index upgrade', () async {
    backend.seed({'vault': 'ORIGINAL_DUMMY_KEY', 'other': 'OTHER'});
    await write('REPLACEMENT');
    storage = FlutterSecureStorageWebos();
    expect(await storage.readAll(options: _options), {'vault': 'REPLACEMENT', 'other': 'OTHER'});
    expect(backend.keys, contains('other'));
  });

  test('failed delete/deleteAll leaves existing credentials intact', () async {
    backend.storeFails = true;
    final before = Map.of(backend.row);
    await expectLater(storage.delete(key: 'vault', options: _options), throwsA(isA<PlatformException>()));
    await expectLater(storage.deleteAll(options: _options), throwsA(isA<PlatformException>()));
    expect(backend.row, before);
    expect(backend.keys, containsAll([_index, 'vault']));
    backend.storeFails = false;
    expect(await read(), 'ORIGINAL_DUMMY_KEY');
  });

  test('delete and deleteAll work after restart and allow writing again', () async {
    await write('NEW');
    await write('OTHER', 'other');
    await storage.delete(key: 'vault', options: _options);
    storage = FlutterSecureStorageWebos();
    expect(await read(), isNull);
    expect(await read('other'), 'OTHER');
    await storage.deleteAll(options: _options);
    storage = FlutterSecureStorageWebos();
    expect(await storage.readAll(options: _options), isEmpty);
    await write('RESTORED');
    expect(await read(), 'RESTORED');
  });

  test('fresh-store reads do not initialize keys and first writes survive restart', () async {
    backend.row = {};
    backend.keys.clear();
    expect(await read(), isNull);
    expect(backend.generations, 0);
    expect(backend.stores, 0);
    await write('FIRST');
    storage = FlutterSecureStorageWebos();
    expect(await read(), 'FIRST');
  });

  test('two instances serialize writes and refresh their cached view', () async {
    final second = FlutterSecureStorageWebos();
    await Future.wait([write('ONE', 'one'), second.write(key: 'two', value: 'TWO', options: _options)]);
    expect(await storage.readAll(options: _options), {'vault': 'ORIGINAL_DUMMY_KEY', 'one': 'ONE', 'two': 'TWO'});
    expect(await second.read(key: 'one', options: _options), 'ONE');
  });

  test('cross-isolate CAS conflict reloads and preserves the concurrent addition', () async {
    backend.conflictOnce = true;
    await write('NEW');
    expect(await storage.readAll(options: _options), {'vault': 'NEW', 'other-isolate': 'OTHER_DUMMY_KEY'});
    expect(backend.stores, 2);
  });

  test('lost commit acknowledgement never deletes keys that may now be active', () async {
    backend.loseAcknowledgement = true;
    await expectLater(write('COMMITTED'), throwsA(isA<PlatformException>()));
    backend.loseAcknowledgement = false;
    storage = FlutterSecureStorageWebos();
    expect(await read(), 'COMMITTED');
  });

  test('key cleanup failure does not invalidate the newly committed credential', () async {
    backend.cleanupFails = true;
    await write('NEW');
    storage = FlutterSecureStorageWebos();
    expect(await read(), 'NEW');
  });
}

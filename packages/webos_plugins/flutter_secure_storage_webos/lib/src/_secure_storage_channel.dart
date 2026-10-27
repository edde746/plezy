import 'dart:convert';

import 'package:flutter/services.dart';

import '_secure_storage_client.dart';

const String dbRowKey = 'flutter_secure_storage';

class StorageWriteException extends PlatformException {
  StorageWriteException(Object cause, {required this.mayHaveCommitted})
      : super(
            code: cause is PlatformException ? cause.code : 'secure_storage_unavailable',
            message: 'The credential store could not be updated. Retry the operation.');
  final bool mayHaveCommitted;
}

class SecureStorageChannel {
  SecureStorageChannel(this._client);
  static const MethodChannel _channel = MethodChannel('webos/secure_storage');
  final SecureStorageClient _client;
  Map<String, String> _kvs = {};
  String? _keys;
  String? _datas;

  /// Always refresh: another instance/isolate may have committed since our last
  /// operation. Reading never seeds, prunes, rotates keys, or writes storage.
  Future<void> open() async {
    final row = await _channel.invokeMapMethod<String, Object?>('load');
    if (row == null) throw _corrupt();
    final keys = row['keys'];
    final datas = row['datas'];
    if (keys == null && datas == null) {
      _keys = _datas = null;
      _kvs = {};
      return;
    }
    if (keys is! String || datas is! String) throw _corrupt();
    final names = _decodeArray(await _client.readSecret(dbRowKey, keys));
    final values = _decodeArray(datas);
    if (names.length != values.length || names.toSet().length != names.length || names.any((s) => s.isEmpty)) {
      throw _corrupt();
    }
    _kvs = Map.fromIterables(names, values);
    _keys = keys;
    _datas = datas;
  }

  bool containsKey(String key) => _kvs.containsKey(key);
  String? rawValue(String key) => _kvs[key];
  Map<String, String> entries() => Map.unmodifiable(_kvs);
  Future<void> setRaw(String key, String value) => _flush({..._kvs, key: value});
  Future<void> removeRaw(String key) => _flush({..._kvs}..remove(key));
  Future<void> clear() => _flush({});

  Future<void> _flush(Map<String, String> next) async {
    final String staged;
    try {
      staged = await _client.createSecret(jsonEncode(next.keys.toList(growable: false)));
    } catch (error) {
      throw StorageWriteException(error, mayHaveCommitted: false);
    }
    final datas = jsonEncode(next.values.toList(growable: false));
    // Native SQLite compare-and-store is one transaction, including first-use
    // insertion. A different isolate cannot silently overwrite a newer row.
    // If the acknowledgement is lost, retain staging keys: the commit may have
    // succeeded. A subsequent operation reloads the durable state.
    final bool? committed;
    try {
      committed = await _channel.invokeMethod<bool>('compareAndStore', {
        'expectedKeys': _keys,
        'expectedDatas': _datas,
        'keys': staged,
        'datas': datas,
      });
    } catch (error) {
      throw StorageWriteException(error, mayHaveCommitted: true);
    }
    if (committed != true) {
      if (committed == false) await _client.removeKeyBestEffort(_client.secretKey(dbRowKey, staged));
      throw StorageWriteException(
          PlatformException(
              code: committed == false ? 'secure_storage_conflict' : 'secure_storage_unavailable',
              message: 'The credential store changed. Retry the operation.'),
          mayHaveCommitted: committed != false);
    }
    final oldKeys = _keys;
    _keys = staged;
    _datas = datas;
    _kvs = next;
    if (oldKeys != null) await _client.removeSecretBestEffort(dbRowKey, oldKeys);
  }

  List<String> _decodeArray(String text) {
    try {
      final value = jsonDecode(text);
      if (value is List && value.every((item) => item is String)) return value.cast<String>();
    } on FormatException {/* Preserve malformed persisted data for recovery. */}
    throw _corrupt();
  }

  PlatformException _corrupt() =>
      PlatformException(code: 'secure_storage_corrupt', message: 'The saved credential store could not be decoded.');
}

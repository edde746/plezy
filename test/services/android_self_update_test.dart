import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/services/android_self_update.dart';

Map<String, Object?> _asset(String abi, {String? digest, int? size}) => {
  'name': AndroidSelfUpdate.assetNameFor(abi),
  'browser_download_url': 'https://github.com/edde746/plezy/releases/download/1.0.0/plezy-android-$abi.tar.gz',
  'size': ?size,
  'digest': ?digest,
};

/// One tar entry: a ustar header (as GNU tar writes it) and the data padded to 512 bytes.
List<int> _tarEntry(String name, List<int> data, {int type = 0x30}) {
  final header = Uint8List(512);
  void put(int offset, List<int> bytes) => header.setRange(offset, offset + bytes.length, bytes);
  void octal(int offset, int width, int value) =>
      put(offset, ascii.encode('${value.toRadixString(8).padLeft(width - 1, '0')}\u0000'));
  final nameBytes = utf8.encode(name);
  put(0, nameBytes.length > 100 ? nameBytes.sublist(0, 100) : nameBytes);
  octal(100, 8, 420);
  octal(108, 8, 0);
  octal(116, 8, 0);
  octal(124, 12, data.length);
  octal(136, 12, 0);
  header[156] = type;
  put(257, ascii.encode('ustar  \u0000'));
  put(148, ascii.encode('        '));
  final sum = header.fold<int>(0, (a, b) => a + b);
  put(148, ascii.encode('${sum.toRadixString(8).padLeft(6, '0')}\u0000 '));
  return [...header, ...data, ...List<int>.filled((512 - data.length % 512) % 512, 0)];
}

/// A gzip-compressed tar: [entries] and the two zero blocks that end an archive.
Uint8List _tarGzOf(List<List<int>> entries) =>
    Uint8List.fromList(gzip.encode([for (final e in entries) ...e, ...List<int>.filled(1024, 0)]));

/// A gzip-compressed tar holding [files], as `tar -czf` would write it.
Uint8List _tarGz(Map<String, List<int>> files) =>
    _tarGzOf([for (final MapEntry(:key, :value) in files.entries) _tarEntry(key, value)]);

/// Incompressible bytes, so a fixture spans several transfer chunks once gzipped.
List<int> _fakeApk(int length) {
  var state = 0x2545F491;
  return List<int>.generate(length, (_) {
    state = (state * 1103515245 + 12345) & 0x7fffffff;
    return state >> 16 & 0xff;
  });
}

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('plezy_self_update_test');
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  group('selectAsset', () {
    final assets = <Object?>[
      _asset('arm64-v8a'),
      _asset('armeabi-v7a'),
      _asset('x86_64'),
      {'name': 'plezy-windows-installer.exe', 'browser_download_url': 'https://example.com/x.exe'},
    ];

    test('keeps the ABI the app runs as, even on a device that supports a 64-bit one', () {
      final asset = AndroidSelfUpdate.selectAsset(
        assets,
        const AndroidAbiInfo(running: 'armeabi-v7a', supported: ['arm64-v8a', 'armeabi-v7a', 'armeabi']),
      );
      expect(asset?.abi, 'armeabi-v7a');
      expect(asset?.name, 'plezy-android-armeabi-v7a.tar.gz');
    });

    test('falls back to the device ABIs in their order of preference', () {
      final asset = AndroidSelfUpdate.selectAsset(
        assets,
        const AndroidAbiInfo(running: 'x86', supported: ['x86', 'x86_64', 'arm64-v8a']),
      );
      expect(asset?.abi, 'x86_64');
    });

    test('is null when the release has no APK for the device', () {
      expect(AndroidSelfUpdate.selectAsset(assets, const AndroidAbiInfo(running: 'mips', supported: ['mips'])), isNull);
    });

    test('ignores an asset without an https download URL', () {
      final asset = AndroidSelfUpdate.selectAsset([
        {'name': 'plezy-android-arm64-v8a.tar.gz', 'browser_download_url': 'http://example.com/a.tar.gz'},
        _asset('armeabi-v7a'),
      ], const AndroidAbiInfo(running: 'arm64-v8a', supported: ['arm64-v8a', 'armeabi-v7a']));
      expect(asset?.abi, 'armeabi-v7a');
    });

    test('reads the size and the GitHub sha256 digest', () {
      final hex = 'AB' * 32;
      final asset = AndroidSelfUpdate.selectAsset([
        _asset('arm64-v8a', digest: 'sha256:$hex', size: 1234),
      ], const AndroidAbiInfo(running: 'arm64-v8a', supported: ['arm64-v8a']));
      expect(asset?.size, 1234);
      expect(asset?.sha256, hex.toLowerCase());
    });
  });

  test('parseSha256Digest accepts only sha256:<64 hex>', () {
    expect(AndroidSelfUpdate.parseSha256Digest('sha256:${'0' * 64}'), '0' * 64);
    expect(AndroidSelfUpdate.parseSha256Digest('sha512:${'0' * 64}'), isNull);
    expect(AndroidSelfUpdate.parseSha256Digest('sha256:abc'), isNull);
    expect(AndroidSelfUpdate.parseSha256Digest(null), isNull);
  });

  group('extractTarGzEntry', () {
    test('extracts plezy.apk next to other entries', () async {
      final apk = _fakeApk(70000);
      final archive = File('${temp.path}/a.tar.gz')
        ..writeAsBytesSync(_tarGz({'README.txt': utf8.encode('hi'), 'plezy.apk': apk}));
      final target = File('${temp.path}/out/plezy.apk');

      expect(await AndroidSelfUpdate.extractTarGzEntry(archive, 'plezy.apk', target), isTrue);
      expect(target.readAsBytesSync(), apk);
    });

    test('follows a GNU long-name header', () async {
      final longName = '${'d' * 120}/plezy.apk';
      final archive = File('${temp.path}/a.tar.gz')
        ..writeAsBytesSync(
          _tarGzOf([
            _tarEntry('././@LongLink', [...utf8.encode(longName), 0], type: 0x4C),
            _tarEntry(longName, _fakeApk(10)),
          ]),
        );
      final target = File('${temp.path}/plezy.apk');

      expect(await AndroidSelfUpdate.extractTarGzEntry(archive, longName, target), isTrue);
      expect(target.readAsBytesSync(), _fakeApk(10));
    });

    test('follows a pax path record', () async {
      final record = utf8.encode(' path=release/plezy.apk\n');
      final length = record.length + 2; // two digits
      final archive = File('${temp.path}/a.tar.gz')
        ..writeAsBytesSync(
          _tarGzOf([
            _tarEntry('PaxHeaders/x', [...ascii.encode('$length'), ...record], type: 0x78),
            _tarEntry('truncated-name', _fakeApk(10)),
          ]),
        );
      final target = File('${temp.path}/plezy.apk');

      expect(await AndroidSelfUpdate.extractTarGzEntry(archive, 'release/plezy.apk', target), isTrue);
      expect(target.readAsBytesSync(), _fakeApk(10));
    });

    test('skips a directory entry of the same name', () async {
      final archive = File('${temp.path}/a.tar.gz')
        ..writeAsBytesSync(
          _tarGzOf([_tarEntry('plezy.apk', const [], type: 0x35), _tarEntry('./plezy.apk', _fakeApk(9))]),
        );
      final target = File('${temp.path}/plezy.apk');

      expect(await AndroidSelfUpdate.extractTarGzEntry(archive, 'plezy.apk', target), isTrue);
      expect(target.readAsBytesSync(), _fakeApk(9));
    });

    test('reports a missing entry', () async {
      final archive = File('${temp.path}/a.tar.gz')..writeAsBytesSync(_tarGz({'other.apk': _fakeApk(10)}));
      expect(await AndroidSelfUpdate.extractTarGzEntry(archive, 'plezy.apk', File('${temp.path}/x')), isFalse);
    });

    test('rejects a truncated archive and leaves no partial APK', () async {
      final tar = _tarEntry('plezy.apk', _fakeApk(5000));
      final archive = File('${temp.path}/a.tar.gz')..writeAsBytesSync(gzip.encode(tar.sublist(0, 2048)));
      final target = File('${temp.path}/plezy.apk');

      await expectLater(AndroidSelfUpdate.extractTarGzEntry(archive, 'plezy.apk', target), throwsFormatException);
      expect(target.existsSync(), isFalse);
    });

    test('rejects a corrupted header', () async {
      final tar = Uint8List.fromList(_tarEntry('plezy.apk', _fakeApk(10)));
      tar[0] ^= 0x01;
      final archive = File('${temp.path}/a.tar.gz')..writeAsBytesSync(gzip.encode(tar));

      await expectLater(
        AndroidSelfUpdate.extractTarGzEntry(archive, 'plezy.apk', File('${temp.path}/plezy.apk')),
        throwsFormatException,
      );
    });
  });

  group('download', () {
    final apk = _fakeApk(200000);
    final body = _tarGz({'plezy.apk': apk});
    final digest = sha256.convert(body).toString();

    AndroidUpdateAsset assetFor({String? sha256, int? size}) => AndroidUpdateAsset(
      name: 'plezy-android-arm64-v8a.tar.gz',
      url: 'https://example.com/plezy-android-arm64-v8a.tar.gz',
      abi: 'arm64-v8a',
      sha256: sha256,
      size: size,
    );

    http.Client serve(List<int> bytes, {int status = 200}) => MockClient.streaming((request, _) async {
      // Several chunks, like a real transfer.
      final chunks = <List<int>>[
        for (var i = 0; i < bytes.length; i += 16384) bytes.sublist(i, (i + 16384).clamp(0, bytes.length)),
      ];
      return http.StreamedResponse(Stream.fromIterable(chunks), status, contentLength: bytes.length);
    });

    test('verifies the digest, extracts the APK and reports progress', () async {
      final progress = <int>[];
      final file = await AndroidSelfUpdate.download(
        assetFor(sha256: digest, size: body.length),
        client: serve(body),
        workDirectory: Directory('${temp.path}/work'),
        onProgress: (received, total) {
          expect(total, body.length);
          progress.add(received);
        },
      );

      expect(file.readAsBytesSync(), apk);
      expect(progress.last, body.length);
      expect(progress, orderedEquals([...progress]..sort()));
      expect(File('${temp.path}/work/plezy-android-arm64-v8a.tar.gz').existsSync(), isFalse, reason: 'archive removed');
    });

    test('works without a published digest', () async {
      final file = await AndroidSelfUpdate.download(
        assetFor(),
        client: serve(body),
        workDirectory: Directory('${temp.path}/work'),
      );
      expect(file.readAsBytesSync(), apk);
    });

    test('rejects an archive that does not match the published digest', () async {
      await expectLater(
        AndroidSelfUpdate.download(
          assetFor(sha256: '0' * 64),
          client: serve(body),
          workDirectory: Directory('${temp.path}/work'),
        ),
        throwsA(isA<AndroidSelfUpdateException>().having((e) => e.error, 'error', AndroidSelfUpdateError.corrupt)),
      );
      expect(Directory('${temp.path}/work').listSync(), isEmpty);
    });

    test('rejects a short transfer', () async {
      await expectLater(
        AndroidSelfUpdate.download(
          assetFor(size: body.length + 10),
          client: serve(body),
          workDirectory: Directory('${temp.path}/work'),
        ),
        throwsA(isA<AndroidSelfUpdateException>().having((e) => e.error, 'error', AndroidSelfUpdateError.download)),
      );
      expect(Directory('${temp.path}/work').listSync(), isEmpty);
    });

    test('reports an HTTP error as a download failure', () async {
      await expectLater(
        AndroidSelfUpdate.download(
          assetFor(),
          client: serve(const [], status: 404),
          workDirectory: Directory('${temp.path}/work'),
        ),
        throwsA(isA<AndroidSelfUpdateException>().having((e) => e.error, 'error', AndroidSelfUpdateError.download)),
      );
    });

    test('reports an archive without plezy.apk as corrupt', () async {
      await expectLater(
        AndroidSelfUpdate.download(
          assetFor(),
          client: serve(_tarGz({'other': _fakeApk(10)})),
          workDirectory: Directory('${temp.path}/work'),
        ),
        throwsA(isA<AndroidSelfUpdateException>().having((e) => e.error, 'error', AndroidSelfUpdateError.corrupt)),
      );
    });

    test('stops when cancelled and leaves nothing behind', () async {
      var chunks = 0;
      await expectLater(
        AndroidSelfUpdate.download(
          assetFor(),
          client: serve(body),
          workDirectory: Directory('${temp.path}/work'),
          onProgress: (_, _) => chunks++,
          isCancelled: () => chunks >= 2,
        ),
        throwsA(isA<AndroidSelfUpdateException>().having((e) => e.error, 'error', AndroidSelfUpdateError.cancelled)),
      );
      expect(Directory('${temp.path}/work').listSync(), isEmpty);
    });

    test('clears a previous attempt before downloading', () async {
      final work = Directory('${temp.path}/work')..createSync();
      File('${work.path}/plezy.apk').writeAsStringSync('stale');
      final file = await AndroidSelfUpdate.download(assetFor(), client: serve(body), workDirectory: work);
      expect(file.readAsBytesSync(), apk);
    });
  });
}

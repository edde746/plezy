import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/services/android_update_service.dart';

List<int> tarGz(List<int> apk, {String name = 'plezy.apk'}) {
  final header = Uint8List(512);
  void text(int offset, int length, String value) => header.setRange(offset, offset + value.length, ascii.encode(value));
  void octal(int offset, int length, int value) => text(offset, length, '${value.toRadixString(8).padLeft(length - 1, '0')}\u0000');
  text(0, 100, name);
  octal(124, 12, apk.length);
  header[156] = 0x30;
  for (var i = 148; i < 156; i++) header[i] = 0x20;
  final checksum = header.fold<int>(0, (sum, byte) => sum + byte);
  text(148, 8, '${checksum.toRadixString(8).padLeft(6, '0')}\u0000 ');
  final tar = BytesBuilder(copy: false)..add(header)..add(apk);
  tar.add(Uint8List((512 - (apk.length % 512)) % 512));
  tar.add(Uint8List(1024));
  return gzip.encode(tar.takeBytes());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final apk = [1, 2, 3, 4];
  final archive = tarGz(apk);
  final url = Uri.parse('https://github.com/edde746/plezy/releases/download/2.19.0/plezy-android-arm64-v8a.tar.gz');

  test('selects the existing release archive for the preferred ABI', () {
    final asset = AndroidUpdateAsset.select([
      {
        'name': 'plezy-android-arm64-v8a.tar.gz',
        'browser_download_url': url.toString(),
        'size': archive.length,
        'digest': 'sha256:${sha256.convert(archive)}',
      },
    ], ['arm64-v8a']);
    expect(asset?.url, url);
  });

  test('downloads, verifies, extracts, and passes plezy.apk to Android', () async {
    final directory = await Directory.systemTemp.createTemp('plezy-update-');
    addTearDown(() => directory.delete(recursive: true));
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    addTearDown(() => messenger.setMockMethodCallHandler(AndroidUpdateService.channel, null));
    messenger.setMockMethodCallHandler(AndroidUpdateService.channel, (call) async {
      switch (call.method) {
        case 'requestInstallPermission':
          return true;
        case 'prepareUpdateDirectory':
          return directory.path;
        case 'installUpdate':
          expect(await File(call.arguments['path'] as String).readAsBytes(), apk);
          return null;
      }
      return null;
    });

    final asset = AndroidUpdateAsset(
      url: url,
      size: archive.length,
      sha256Digest: sha256.convert(archive).toString(),
    );
    await AndroidUpdateService(client: MockClient((_) async => http.Response.bytes(archive, 200))).downloadAndInstall(asset, (_) {});
    expect(await File('${directory.path}/update.apk').readAsBytes(), apk);
    expect(await File('${directory.path}/update.tar.gz').exists(), isFalse);
  });

  test('rejects an archive that does not contain plezy.apk', () async {
    final directory = await Directory.systemTemp.createTemp('plezy-update-');
    addTearDown(() => directory.delete(recursive: true));
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    addTearDown(() => messenger.setMockMethodCallHandler(AndroidUpdateService.channel, null));
    messenger.setMockMethodCallHandler(AndroidUpdateService.channel, (call) async {
      if (call.method == 'requestInstallPermission') return true;
      if (call.method == 'prepareUpdateDirectory') return directory.path;
      fail('Installer must not be opened for an invalid archive');
    });
    final bad = tarGz(apk, name: '../plezy.apk');
    final asset = AndroidUpdateAsset(url: url, size: bad.length, sha256Digest: sha256.convert(bad).toString());
    await expectLater(
      AndroidUpdateService(client: MockClient((_) async => http.Response.bytes(bad, 200))).downloadAndInstall(asset, (_) {}),
      throwsA(isA<FormatException>()),
    );
  });
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class AndroidUpdateAsset {
  final Uri url;
  final int size;
  final String? sha256Digest;

  const AndroidUpdateAsset({required this.url, required this.size, this.sha256Digest});

  static AndroidUpdateAsset? select(List<dynamic> assets, List<String> abis) {
    for (final name in abis.map((abi) => 'plezy-android-$abi.tar.gz')) {
      for (final asset in assets.whereType<Map>()) {
        if (asset['name'] != name) continue;
        final url = Uri.tryParse(asset['browser_download_url'] as String? ?? '');
        final size = asset['size'];
        final digest = asset['digest'];
        if (url == null || !isTrustedUrl(url) || size is! int || size <= 0 || size > maxArchiveSize) continue;
        if (digest != null && (digest is! String || !RegExp(r'^sha256:[a-fA-F0-9]{64}$').hasMatch(digest))) continue;
        return AndroidUpdateAsset(
          url: url,
          size: size,
          sha256Digest: (digest as String?)?.substring(7).toLowerCase(),
        );
      }
    }
    return null;
  }

  static const maxArchiveSize = 512 * 1024 * 1024;
  static const maxApkSize = 768 * 1024 * 1024;

  static bool isTrustedUrl(Uri url) =>
      url.scheme == 'https' &&
      url.host == 'github.com' &&
      url.port == 443 &&
      url.userInfo.isEmpty &&
      !url.hasQuery &&
      !url.hasFragment &&
      url.path.startsWith('/edde746/plezy/releases/download/') &&
      url.path.endsWith('.tar.gz');
}

class UpdateDownloadCancelled implements Exception {}

class AndroidUpdateService {
  static const channel = MethodChannel('com.plezy/app_update');
  static bool _active = false;
  final http.Client _client;
  bool _cancelled = false;

  AndroidUpdateService({http.Client? client}) : _client = client ?? http.Client();

  static Future<List<String>> supportedAbis() async =>
      await channel.invokeListMethod<String>('getSupportedAbis') ?? <String>[];

  void cancel() {
    _cancelled = true;
    _client.close();
  }

  void _checkCancelled() {
    if (_cancelled) throw UpdateDownloadCancelled();
  }

  Future<void> downloadAndInstall(AndroidUpdateAsset asset, void Function(double) onProgress) async {
    if (_active) throw StateError('An update is already in progress');
    _active = true;
    File? partial;
    File? archive;
    File? apk;
    var installerOpened = false;
    try {
      final allowed = await channel.invokeMethod<bool>('requestInstallPermission');
      if (allowed != true) throw PlatformException(code: 'INSTALL_PERMISSION_DENIED');
      final directory = await channel.invokeMethod<String>('prepareUpdateDirectory');
      if (directory == null) throw StateError('Update cache unavailable');
      partial = File('$directory/update.tar.gz.part');
      archive = File('$directory/update.tar.gz');
      apk = File('$directory/update.apk');
      await _download(asset, partial, onProgress);
      _checkCancelled();
      await partial.rename(archive.path);
      await _extractApk(archive, apk);
      await archive.delete();
      _checkCancelled();
      await channel.invokeMethod<void>('installUpdate', {'path': apk.path});
      installerOpened = true;
    } catch (_) {
      if (_cancelled) throw UpdateDownloadCancelled();
      rethrow;
    } finally {
      _client.close();
      if (partial != null && await partial.exists()) await partial.delete();
      if (archive != null && await archive.exists()) await archive.delete();
      if (!installerOpened && apk != null && await apk.exists()) await apk.delete();
      _active = false;
    }
  }

  Future<void> _download(AndroidUpdateAsset asset, File target, void Function(double) onProgress) async {
    if (!AndroidUpdateAsset.isTrustedUrl(asset.url)) throw const FormatException('Invalid update URL');
    final response = await _client.send(http.Request('GET', asset.url)).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) throw HttpException('Update download failed (${response.statusCode})');
    final sink = target.openWrite();
    var received = 0;
    try {
      await for (final chunk in response.stream.timeout(const Duration(seconds: 30))) {
        _checkCancelled();
        received += chunk.length;
        if (received > asset.size) throw const FormatException('Update archive is too large');
        sink.add(chunk);
        onProgress(received / asset.size);
      }
    } finally {
      await sink.close();
    }
    if (received != asset.size) throw const FormatException('Incomplete update download');
    if (asset.sha256Digest != null && (await sha256.bind(target.openRead()).first).toString() != asset.sha256Digest) {
      throw const FormatException('Update checksum mismatch');
    }
  }

  Future<void> _extractApk(File archive, File target) async {
    final reader = _ChunkReader(gzip.decoder.bind(archive.openRead()));
    try {
      final header = await reader.readExact(512);
      _validateTarChecksum(header);
      final name = _tarString(header, 0, 100);
      final size = _tarOctal(header, 124, 12);
      final type = header[156];
      if ((name != 'plezy.apk' && name != './plezy.apk') || (type != 0 && type != 0x30)) {
        throw const FormatException('Unexpected update archive contents');
      }
      if (size <= 0 || size > AndroidUpdateAsset.maxApkSize) {
        throw const FormatException('Invalid APK size');
      }
      final sink = target.openWrite();
      var remaining = size;
      try {
        while (remaining > 0) {
          _checkCancelled();
          final chunk = await reader.readExact(math.min(64 * 1024, remaining));
          sink.add(chunk);
          remaining -= chunk.length;
        }
      } finally {
        await sink.close();
      }
      final padding = (512 - (size % 512)) % 512;
      if (padding > 0) await reader.readExact(padding);
      if (!(await reader.readExact(512)).every((byte) => byte == 0)) {
        throw const FormatException('Unexpected extra update archive entry');
      }
    } catch (_) {
      if (await target.exists()) await target.delete();
      rethrow;
    } finally {
      await reader.cancel();
    }
  }

  static String _tarString(Uint8List header, int offset, int length) {
    final bytes = header.sublist(offset, offset + length);
    final end = bytes.indexOf(0);
    return utf8.decode(end < 0 ? bytes : bytes.sublist(0, end));
  }

  static int _tarOctal(Uint8List header, int offset, int length) {
    final text = ascii.decode(header.sublist(offset, offset + length), allowInvalid: false).replaceAll('\u0000', '').trim();
    if (!RegExp(r'^[0-7]+$').hasMatch(text)) throw const FormatException('Invalid tar header');
    return int.parse(text, radix: 8);
  }

  static void _validateTarChecksum(Uint8List header) {
    final expected = _tarOctal(header, 148, 8);
    var actual = 0;
    for (var i = 0; i < 512; i++) {
      actual += i >= 148 && i < 156 ? 0x20 : header[i];
    }
    if (actual != expected) throw const FormatException('Invalid tar checksum');
  }
}

class _ChunkReader {
  final StreamIterator<List<int>> _iterator;
  Uint8List _current = Uint8List(0);
  int _offset = 0;

  _ChunkReader(Stream<List<int>> stream) : _iterator = StreamIterator(stream);

  Future<Uint8List> readExact(int length) async {
    final result = Uint8List(length);
    var written = 0;
    while (written < length) {
      if (_offset == _current.length) {
        if (!await _iterator.moveNext()) throw const FormatException('Truncated update archive');
        _current = Uint8List.fromList(_iterator.current);
        _offset = 0;
      }
      final count = math.min(length - written, _current.length - _offset);
      result.setRange(written, written + count, _current, _offset);
      written += count;
      _offset += count;
    }
    return result;
  }

  Future<void> cancel() => _iterator.cancel();
}

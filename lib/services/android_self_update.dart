import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../utils/app_logger.dart';
import '../utils/media_server_http_client.dart';

/// Why an Android self-update stopped. [code] is one of the [AndroidSelfUpdateError] values;
/// the dialog maps it to a message.
class AndroidSelfUpdateException implements Exception {
  const AndroidSelfUpdateException(this.error, [this.message]);

  final AndroidSelfUpdateError error;
  final String? message;

  @override
  String toString() => 'AndroidSelfUpdateException(${error.name}${message == null ? '' : ': $message'})';
}

enum AndroidSelfUpdateError {
  /// The release carries no APK this device can run.
  noCompatibleAsset,

  /// The download failed or was cut short.
  download,

  /// The archive did not match the digest GitHub published for it, or held no APK.
  corrupt,

  /// The APK is not Plezy, or is signed by a different key than the installed app, so Android
  /// would refuse it as an update.
  signatureMismatch,

  /// The user cancelled the download.
  cancelled,

  /// The system installer could not be opened.
  installer,
}

/// A release asset the device can install, picked by [AndroidSelfUpdate.selectAsset].
@immutable
class AndroidUpdateAsset {
  const AndroidUpdateAsset({required this.name, required this.url, required this.abi, this.size, this.sha256});

  final String name;
  final String url;
  final String abi;

  /// Size GitHub reports for the asset, when it does.
  final int? size;

  /// Lowercase hex SHA-256 from the asset's `digest` field, when GitHub published one.
  final String? sha256;
}

/// The ABIs the running process can use, as the platform reports them.
@immutable
class AndroidAbiInfo {
  const AndroidAbiInfo({required this.running, required this.supported});

  /// The ABI the installed APK runs as (e.g. `armeabi-v7a` on a TV with a 32-bit userland even
  /// when the SoC is 64-bit). Preferred, so an update keeps the variant the user installed.
  final String? running;

  /// `Build.SUPPORTED_ABIS`, most preferred first.
  final List<String> supported;
}

/// In-app updates for the GitHub Android build, the way TV apps installed from GitHub usually
/// update: download the release's APK, then hand it to the system package installer, which asks
/// the user to confirm. Android keeps the app's data across the update.
///
/// Only the GitHub build declares `REQUEST_INSTALL_PACKAGES` (see android/app/build.gradle.kts);
/// [isSupported] is false everywhere else, and the update dialog keeps its "View Release" link.
class AndroidSelfUpdate {
  AndroidSelfUpdate._();

  static const channel = MethodChannel('com.plezy/app_update');

  /// Release asset name for an ABI. Matches the "Package APKs" step of .github/workflows/build.yml.
  static String assetNameFor(String abi) => 'plezy-android-$abi.tar.gz';

  /// The APK's name inside each release archive.
  static const apkEntryName = 'plezy.apk';

  /// Upper bound on the archive, to stop a broken or hostile response from filling the disk.
  static const maxDownloadBytes = 512 * 1024 * 1024;

  /// A stalled transfer gives up after this long without data.
  static const _idleTimeout = Duration(seconds: 45);

  static bool? _supportedCache;

  /// Whether this install can update itself: Android, and the manifest declares
  /// `REQUEST_INSTALL_PACKAGES`. Cached for the process; false when the platform side is missing.
  static Future<bool> isSupported() async {
    final cached = _supportedCache;
    if (cached != null) return cached;
    if (!Platform.isAndroid) return false;
    var supported = false;
    try {
      supported = await channel.invokeMethod<bool>('isSupported') ?? false;
    } on PlatformException catch (e, stackTrace) {
      appLogger.w('Self-update support unavailable', error: e, stackTrace: stackTrace);
    } on MissingPluginException {
      supported = false;
    }
    return _supportedCache = supported;
  }

  @visibleForTesting
  static void debugSetSupported(bool? value) => _supportedCache = value;

  /// Replaces the HTTP client [download] uses when none is passed, for widget tests.
  @visibleForTesting
  static http.Client? debugHttpClient;

  static Future<AndroidAbiInfo> abiInfo() async {
    final raw = await channel.invokeMapMethod<String, Object?>('getAbis') ?? const {};
    return AndroidAbiInfo(
      running: raw['running'] as String?,
      supported: (raw['supported'] as List<Object?>? ?? const []).whereType<String>().toList(),
    );
  }

  /// Picks the asset for this device from a GitHub release's `assets` list: the ABI the app runs
  /// as first, then the others the device supports in its order of preference. Null when the
  /// release has none of them.
  static AndroidUpdateAsset? selectAsset(List<Object?> assets, AndroidAbiInfo abis) {
    final byName = <String, Map<Object?, Object?>>{
      for (final asset in assets.whereType<Map<Object?, Object?>>())
        if (asset['name'] case final String name) name: asset,
    };
    final order = <String>[?abis.running, ...abis.supported];
    for (final abi in order) {
      final asset = byName[assetNameFor(abi)];
      final url = asset?['browser_download_url'];
      if (asset == null || url is! String || !url.startsWith('https://')) continue;
      return AndroidUpdateAsset(
        name: assetNameFor(abi),
        url: url,
        abi: abi,
        size: asset['size'] is int ? asset['size'] as int : null,
        sha256: parseSha256Digest(asset['digest']),
      );
    }
    return null;
  }

  /// The hex digest from GitHub's `sha256:<hex>` asset digest, or null for anything else.
  static String? parseSha256Digest(Object? digest) {
    if (digest is! String) return null;
    final match = RegExp(r'^sha256:([0-9a-fA-F]{64})$').firstMatch(digest.trim());
    return match?.group(1)?.toLowerCase();
  }

  /// Downloads [asset], checks it, extracts the APK and returns its path. [onProgress] gets the
  /// bytes received and the expected total (null when unknown). [isCancelled] is polled between
  /// chunks.
  static Future<File> download(
    AndroidUpdateAsset asset, {
    void Function(int received, int? total)? onProgress,
    bool Function()? isCancelled,
    http.Client? client,
    Directory? workDirectory,
  }) async {
    final dir = workDirectory ?? Directory('${(await getTemporaryDirectory()).path}/app_update');
    // Each update starts clean: a previous attempt's archive or APK is never reused.
    if (await dir.exists()) await dir.delete(recursive: true);
    await dir.create(recursive: true);

    final archive = File('${dir.path}/${asset.name}');
    final digest = await _downloadTo(
      asset,
      archive,
      client ?? debugHttpClient ?? httpClient.inner,
      onProgress: onProgress,
      isCancelled: isCancelled,
    );
    final expected = asset.sha256;
    if (expected != null && digest != expected) {
      await _deleteQuietly(archive);
      throw AndroidSelfUpdateException(AndroidSelfUpdateError.corrupt, 'SHA-256 $digest, expected $expected');
    }

    final apk = File('${dir.path}/$apkEntryName');
    try {
      final found = await extractTarGzEntry(archive, apkEntryName, apk);
      if (!found) throw const AndroidSelfUpdateException(AndroidSelfUpdateError.corrupt, 'No APK in the archive');
    } on AndroidSelfUpdateException {
      rethrow;
    } on FormatException catch (e) {
      throw AndroidSelfUpdateException(AndroidSelfUpdateError.corrupt, e.message);
    } finally {
      await _deleteQuietly(archive);
    }
    return apk;
  }

  /// Streams [asset] into [target] and returns the hex SHA-256 of what was written.
  static Future<String> _downloadTo(
    AndroidUpdateAsset asset,
    File target,
    http.Client client, {
    void Function(int received, int? total)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final http.StreamedResponse response;
    try {
      response = await client.send(http.Request('GET', Uri.parse(asset.url))).timeout(_idleTimeout);
    } on TimeoutException catch (e) {
      throw AndroidSelfUpdateException(AndroidSelfUpdateError.download, 'Timed out connecting: $e');
    } on Exception catch (e) {
      throw AndroidSelfUpdateException(AndroidSelfUpdateError.download, '$e');
    }
    if (response.statusCode != 200) {
      unawaited(response.stream.drain<void>().catchError((_) {}));
      throw AndroidSelfUpdateException(AndroidSelfUpdateError.download, 'HTTP ${response.statusCode}');
    }

    final total = asset.size ?? response.contentLength;
    if (total != null && total > maxDownloadBytes) {
      unawaited(response.stream.drain<void>().catchError((_) {}));
      throw AndroidSelfUpdateException(AndroidSelfUpdateError.download, 'Archive too large: $total bytes');
    }

    final digestSink = _DigestSink();
    final hasher = sha256.startChunkedConversion(digestSink);
    final sink = target.openWrite();
    var received = 0;
    var completed = false;
    try {
      await for (final chunk in response.stream.timeout(_idleTimeout)) {
        if (isCancelled?.call() ?? false) {
          throw const AndroidSelfUpdateException(AndroidSelfUpdateError.cancelled);
        }
        received += chunk.length;
        if (received > maxDownloadBytes) {
          throw const AndroidSelfUpdateException(AndroidSelfUpdateError.download, 'Archive too large');
        }
        hasher.add(chunk);
        sink.add(chunk);
        onProgress?.call(received, total);
      }
      if (isCancelled?.call() ?? false) {
        throw const AndroidSelfUpdateException(AndroidSelfUpdateError.cancelled);
      }
      if (total != null && received != total) {
        throw AndroidSelfUpdateException(AndroidSelfUpdateError.download, 'Received $received of $total bytes');
      }
      completed = true;
    } on AndroidSelfUpdateException {
      rethrow;
    } on Exception catch (e) {
      throw AndroidSelfUpdateException(AndroidSelfUpdateError.download, '$e');
    } finally {
      await sink.close();
      if (!completed) await _deleteQuietly(target);
    }
    hasher.close();
    return digestSink.value.toString();
  }

  /// Copies the regular file named [entryName] out of the gzip-compressed tar [archive] into
  /// [target], streaming so a large APK never sits in memory. False when the archive has no such
  /// entry. Throws [FormatException] for a malformed or truncated archive.
  ///
  /// Reads ustar, GNU long-name (`L`) and pax (`x`) headers, which is what GNU and BSD tar write.
  static Future<bool> extractTarGzEntry(File archive, String entryName, File target) async {
    final reader = _ByteReader(archive.openRead().transform(gzip.decoder));
    try {
      String? longName;
      while (true) {
        final header = await reader.read(512);
        if (header == null || header.every((b) => b == 0)) return false;
        _checkTarHeader(header);

        final size = _parseOctal(header, 124, 12);
        final type = header[156];
        final padded = (size + 511) & ~511;
        final pendingName = longName;
        longName = null;

        switch (type) {
          case 0x4C: // 'L': GNU long name for the next entry
            final data = await reader.readRequired(padded);
            longName = _cString(data, 0, size);
            continue;
          case 0x78: // 'x': pax extended header for the next entry
            final data = await reader.readRequired(padded);
            longName = _paxPath(data.sublist(0, size));
            continue;
          case 0x67: // 'g': pax global header
            await reader.skip(padded);
            continue;
        }

        final name = pendingName ?? _ustarName(header);
        final isRegular = type == 0 || type == 0x30 || type == 0x37; // NUL, '0', '7'
        if (isRegular && _normalize(name) == entryName) {
          await target.parent.create(recursive: true);
          final sink = target.openWrite();
          var done = false;
          try {
            await reader.pipe(size, sink);
            done = true;
          } finally {
            await sink.close();
            if (!done) await _deleteQuietly(target);
          }
          return true;
        }
        await reader.skip(padded);
      }
    } finally {
      await reader.cancel();
    }
  }

  static void _checkTarHeader(Uint8List header) {
    var sum = 0;
    for (var i = 0; i < 512; i++) {
      sum += (i >= 148 && i < 156) ? 0x20 : header[i];
    }
    if (sum != _parseOctal(header, 148, 8)) throw const FormatException('Bad tar header checksum');
  }

  static int _parseOctal(Uint8List bytes, int offset, int length) {
    var value = 0;
    var seen = false;
    for (var i = offset; i < offset + length; i++) {
      final b = bytes[i];
      if (b == 0 || b == 0x20) {
        if (seen) break;
        continue;
      }
      if (b < 0x30 || b > 0x37) throw const FormatException('Bad octal field in tar header');
      value = value * 8 + (b - 0x30);
      seen = true;
    }
    return value;
  }

  static String _cString(Uint8List bytes, int offset, int length) {
    var end = offset;
    while (end < offset + length && bytes[end] != 0) {
      end++;
    }
    return utf8.decode(bytes.sublist(offset, end), allowMalformed: true);
  }

  static String _ustarName(Uint8List header) {
    final name = _cString(header, 0, 100);
    final isUstar = _cString(header, 257, 5) == 'ustar';
    final prefix = isUstar ? _cString(header, 345, 155) : '';
    return prefix.isEmpty ? name : '$prefix/$name';
  }

  /// The `path` record of a pax extended header (`<length> path=<value>\n` records).
  static String? _paxPath(Uint8List data) {
    final text = utf8.decode(data, allowMalformed: true);
    for (final record in text.split('\n')) {
      final space = record.indexOf(' ');
      if (space < 0) continue;
      final keyValue = record.substring(space + 1);
      if (keyValue.startsWith('path=')) return keyValue.substring(5);
    }
    return null;
  }

  static String _normalize(String name) => name.startsWith('./') ? name.substring(2) : name;

  /// Checks that [apk] is an update Android will accept: this app's package, signed by the same
  /// key as the installed copy. The installer would refuse anything else with a bare
  /// "App not installed".
  static Future<void> verifyApk(File apk) async {
    final Map<String, Object?>? info;
    try {
      info = await channel.invokeMapMethod<String, Object?>('inspectApk', {'path': apk.path});
    } on PlatformException catch (e) {
      throw AndroidSelfUpdateException(AndroidSelfUpdateError.corrupt, e.message);
    }
    if (info == null) throw const AndroidSelfUpdateException(AndroidSelfUpdateError.corrupt, 'Unreadable APK');
    if (info['samePackage'] != true || info['sameSigner'] != true) {
      throw AndroidSelfUpdateException(
        AndroidSelfUpdateError.signatureMismatch,
        'package ${info['packageName']}, same signer: ${info['sameSigner']}',
      );
    }
  }

  /// Whether Android lets Plezy open the package installer (the per-app "Install unknown apps"
  /// permission on Android 8+).
  static Future<bool> canRequestInstall() async => await channel.invokeMethod<bool>('canRequestInstall') ?? false;

  /// Opens the settings page where the user allows Plezy to install apps. False when the device
  /// has no such page.
  static Future<bool> openInstallPermissionSettings() async =>
      await channel.invokeMethod<bool>('openInstallPermissionSettings') ?? false;

  /// Hands [apk] to the system package installer, which asks the user to confirm.
  static Future<void> install(File apk) async {
    try {
      await channel.invokeMethod<void>('install', {'path': apk.path});
    } on PlatformException catch (e) {
      throw AndroidSelfUpdateException(AndroidSelfUpdateError.installer, e.message);
    }
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException catch (_) {}
  }
}

class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}

/// Exact-length reads over a byte stream.
class _ByteReader {
  _ByteReader(Stream<List<int>> stream) : _iterator = StreamIterator(stream);

  final StreamIterator<List<int>> _iterator;
  List<int> _chunk = const [];
  int _offset = 0;

  Future<bool> _fill() async {
    while (_offset >= _chunk.length) {
      if (!await _iterator.moveNext()) return false;
      _chunk = _iterator.current;
      _offset = 0;
    }
    return true;
  }

  /// [length] bytes, or null when the stream ended before the first one.
  Future<Uint8List?> read(int length) async {
    final out = Uint8List(length);
    var filled = 0;
    while (filled < length) {
      if (!await _fill()) {
        if (filled == 0) return null;
        throw const FormatException('Truncated tar archive');
      }
      final n = (length - filled).clamp(0, _chunk.length - _offset);
      out.setRange(filled, filled + n, _chunk, _offset);
      filled += n;
      _offset += n;
    }
    return out;
  }

  Future<Uint8List> readRequired(int length) async {
    if (length == 0) return Uint8List(0);
    final data = await read(length);
    if (data == null) throw const FormatException('Truncated tar archive');
    return data;
  }

  /// Writes the next [length] bytes to [sink], then skips the block padding.
  Future<void> pipe(int length, IOSink sink) async {
    var remaining = length;
    while (remaining > 0) {
      if (!await _fill()) throw const FormatException('Truncated tar archive');
      final n = remaining.clamp(0, _chunk.length - _offset);
      sink.add(_chunk.sublist(_offset, _offset + n));
      _offset += n;
      remaining -= n;
    }
    await skip(((length + 511) & ~511) - length, allowEnd: true);
  }

  Future<void> skip(int length, {bool allowEnd = false}) async {
    var remaining = length;
    while (remaining > 0) {
      if (!await _fill()) {
        if (allowEnd) return;
        throw const FormatException('Truncated tar archive');
      }
      final n = remaining.clamp(0, _chunk.length - _offset);
      _offset += n;
      remaining -= n;
    }
  }

  Future<void> cancel() => _iterator.cancel();
}

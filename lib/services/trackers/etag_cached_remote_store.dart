import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../utils/abortable_http_request.dart';
import '../../utils/app_logger.dart';
import '../../utils/platform_http_client_stub.dart'
    if (dart.library.io) '../../utils/platform_http_client_io.dart'
    as platform;
import '../base_shared_preferences_service.dart';

/// An index parsed out of a cached remote file.
abstract interface class RemoteIndex {
  bool get isEmpty;

  /// Reported after a successful refresh, e.g. `'1234 tvdb entries'`.
  String get logSummary;
}

/// Base for the mapping stores backed by a static file on jsDelivr.
///
/// Owns the whole lifecycle: lazy download on first use, a disk copy in the
/// app-support directory, parsing in a background isolate, and a weekly
/// conditional-GET ([maybeRefresh], If-None-Match) to pick up upstream changes.
/// Subclasses supply the source, the cache keys and the two isolate entry
/// points, and build their lookups on top of [ensureLoaded].
abstract class EtagCachedRemoteStore<T extends RemoteIndex> {
  static const Duration _refreshInterval = Duration(days: 7);
  static const Duration _requestTimeout = Duration(seconds: 60);

  final String diskFileName;
  final String prefsEtagKey;
  final String prefsLastCheckKey;
  final String sourceUrl;
  final String acceptHeader;

  /// Prefixes log lines and the abortable-request operation names.
  final String logLabel;

  /// Returned when nothing could be loaded; never cached.
  final T emptyIndex;

  /// Parses a raw body. Top-level so it can run in a `compute` isolate.
  final T Function(String raw) parse;

  /// Reads the disk copy and parses it inside the isolate. Halves peak memory
  /// vs. reading the string on the main isolate and shipping it across.
  final T Function(String path) readAndParse;

  EtagCachedRemoteStore({
    required this.diskFileName,
    required this.prefsEtagKey,
    required this.prefsLastCheckKey,
    required this.sourceUrl,
    required this.acceptHeader,
    required this.logLabel,
    required this.emptyIndex,
    required this.parse,
    required this.readAndParse,
  });

  T? _index;
  Future<T>? _loading;
  bool _refreshRunning = false;

  /// Lazily load, downloading on first use. Subsequent calls return the
  /// cached index in O(1). Concurrent callers share the same Future.
  /// Schedules a background refresh after the first successful load.
  @protected
  Future<T> ensureLoaded() async {
    final existing = _index;
    if (existing != null) return existing;
    final loading = _loading;
    if (loading != null) return loading;

    final fresh = _loadOrFetch();
    _loading = fresh;
    try {
      final idx = await fresh;
      // Don't cache an empty index (network failure, no disk copy) — let the
      // next lookup retry so transient offline periods self-heal.
      if (!idx.isEmpty) {
        _index = idx;
        unawaited(maybeRefresh());
      }
      return idx;
    } finally {
      _loading = null;
    }
  }

  Future<T> _loadOrFetch() async {
    final path = await _diskPath();
    try {
      return await compute(readAndParse, path);
    } on FileSystemException {
      appLogger.d('$logLabel: no disk cache, downloading from jsDelivr');
      final raw = await _download();
      if (raw == null) return emptyIndex;
      return await compute(parse, raw);
    } catch (e) {
      appLogger.w('$logLabel: parse failed — deleting disk copy so next lookup re-downloads', error: e);
      await _deleteDiskCopy();
      return emptyIndex;
    }
  }

  /// GET the mapping, save it to disk, and return the body. Returns `null`
  /// on any failure (offline, 4xx/5xx, timeout).
  Future<String?> _download() async {
    final client = platform.createPlatformClient();
    try {
      final res = await sendAbortableHttpRequest(
        client,
        'GET',
        Uri.parse(sourceUrl),
        headers: {'Accept': acceptHeader},
        timeout: _requestTimeout,
        operation: '$logLabel mapping download',
      );
      if (res.statusCode != 200) {
        appLogger.d('$logLabel: download returned HTTP ${res.statusCode}');
        return null;
      }
      await _writeDiskCopy(res.body, etag: res.headers['etag']);
      // Seed the weekly throttle so a same-week relaunch skips the refresh.
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setInt(prefsLastCheckKey, DateTime.now().millisecondsSinceEpoch);
      return res.body;
    } catch (e) {
      appLogger.w('$logLabel: download failed', error: e);
      return null;
    } finally {
      client.close();
    }
  }

  /// Conditional-GET the mapping if the last check was >[_refreshInterval] ago
  /// and we already have an index loaded. No-op when nothing is loaded — the
  /// first lookup handles the initial download.
  Future<void> maybeRefresh() async {
    if (_refreshRunning) return;
    if (_index == null) return;
    _refreshRunning = true;
    try {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      final lastCheck = prefs.getInt(prefsLastCheckKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastCheck < _refreshInterval.inMilliseconds) return;

      final etag = prefs.getString(prefsEtagKey);
      final client = platform.createPlatformClient();
      try {
        final res = await sendAbortableHttpRequest(
          client,
          'GET',
          Uri.parse(sourceUrl),
          headers: {'If-None-Match': ?etag, 'Accept': acceptHeader},
          timeout: _requestTimeout,
          operation: '$logLabel mapping refresh',
        );
        await prefs.setInt(prefsLastCheckKey, now);

        if (res.statusCode == 304) {
          appLogger.d('$logLabel: mapping unchanged (304)');
          return;
        }
        if (res.statusCode != 200) {
          appLogger.d('$logLabel: refresh returned HTTP ${res.statusCode}');
          return;
        }

        await _writeDiskCopy(res.body, etag: res.headers['etag']);
        final fresh = await compute(parse, res.body);
        _index = fresh;
        appLogger.d('$logLabel: mapping refreshed (${fresh.logSummary})');
      } finally {
        client.close();
      }
    } catch (e) {
      appLogger.d('$logLabel: refresh failed (non-fatal)', error: e);
    } finally {
      _refreshRunning = false;
    }
  }

  Future<void> _writeDiskCopy(String body, {String? etag}) async {
    await File(await _diskPath()).writeAsString(body, flush: true);
    if (etag != null) {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setString(prefsEtagKey, etag);
    }
  }

  Future<void> _deleteDiskCopy() async {
    try {
      await File(await _diskPath()).delete();
    } on FileSystemException {
      // Already gone.
    }
  }

  Future<String> _diskPath() async {
    final dir = await getApplicationSupportDirectory();
    return p.join(dir.path, diskFileName);
  }

  @visibleForTesting
  void resetForTesting() {
    _index = null;
    _loading = null;
  }
}

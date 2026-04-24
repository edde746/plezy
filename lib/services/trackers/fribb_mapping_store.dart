import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/trackers/fribb_mapping_row.dart';
import '../../utils/app_logger.dart';
import '../../utils/platform_http_client_stub.dart'
    if (dart.library.io) '../../utils/platform_http_client_io.dart'
    as platform;

/// Indexed view of the Fribb mapping database, queried by external ID.
///
/// Three lookup tables (tvdb / tmdb / imdb) into a shared list of rows.
/// A single tvdb_id may map to multiple rows (split-cour anime → one per
/// season); callers that have a Plex season number should filter by
/// [FribbMappingRow.tvdbSeason] or [FribbMappingRow.tmdbSeason].
class FribbIndex {
  final Map<int, List<FribbMappingRow>> byTvdb;
  final Map<int, List<FribbMappingRow>> byTmdb;
  final Map<String, List<FribbMappingRow>> byImdb;

  const FribbIndex({required this.byTvdb, required this.byTmdb, required this.byImdb});

  bool get isEmpty => byTvdb.isEmpty && byTmdb.isEmpty && byImdb.isEmpty;
}

/// Loads and refreshes the Fribb anime-lists mapping on demand.
///
/// On first lookup the ~5 MB JSON is downloaded from jsDelivr and cached to
/// the app-support directory. Subsequent lookups read from the cache. Parsing
/// runs in a background isolate. [maybeRefresh] does a weekly conditional-GET
/// (If-None-Match) to pick up upstream changes.
class FribbMappingStore {
  static const String _diskFileName = 'anime-list-mini.json';
  static const String _prefsEtagKey = 'fribb_anime_list_etag';
  static const String _prefsLastCheckKey = 'fribb_anime_list_last_check';

  /// jsDelivr (CDN-backed). `raw.githubusercontent.com` rate-limits
  /// aggressively on shared IPs and returns 429 mid-refresh.
  static const String _sourceUrl = 'https://cdn.jsdelivr.net/gh/Fribb/anime-lists@master/anime-list-mini.json';

  static const Duration _refreshInterval = Duration(days: 7);
  static const Duration _requestTimeout = Duration(seconds: 60);

  FribbMappingStore._();
  static final FribbMappingStore instance = FribbMappingStore._();

  FribbIndex? _index;
  Future<FribbIndex>? _loading;
  bool _refreshRunning = false;

  /// Lazily load, downloading on first use. Subsequent calls return the
  /// cached index in O(1). Concurrent callers share the same Future.
  /// Schedules a background refresh after the first successful load.
  Future<FribbIndex> _ensureLoaded() async {
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

  Future<FribbIndex> _loadOrFetch() async {
    final path = await _diskPath();
    try {
      return await compute(_readAndParse, path);
    } on FileSystemException {
      appLogger.d('Fribb: no disk cache, downloading from jsDelivr');
      final raw = await _download();
      if (raw == null) return const FribbIndex(byTvdb: {}, byTmdb: {}, byImdb: {});
      return await compute(_parseAndIndex, raw);
    } catch (e) {
      appLogger.w('Fribb: parse failed — deleting disk copy so next lookup re-downloads', error: e);
      await _deleteDiskCopy();
      return const FribbIndex(byTvdb: {}, byTmdb: {}, byImdb: {});
    }
  }

  /// GET the mapping, save it to disk, and return the body. Returns `null`
  /// on any failure (offline, 4xx/5xx, timeout).
  Future<String?> _download() async {
    final client = platform.createPlatformClient();
    try {
      final res = await client
          .get(Uri.parse(_sourceUrl), headers: const {'Accept': 'application/json'})
          .timeout(_requestTimeout);
      if (res.statusCode != 200) {
        appLogger.d('Fribb: download returned HTTP ${res.statusCode}');
        return null;
      }
      await _writeDiskCopy(res.body, etag: res.headers['etag']);
      // Seed the weekly throttle so a same-week relaunch skips the refresh.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsLastCheckKey, DateTime.now().millisecondsSinceEpoch);
      return res.body;
    } catch (e) {
      appLogger.w('Fribb: download failed', error: e);
      return null;
    } finally {
      client.close();
    }
  }

  /// Look up rows by Plex external IDs. Returns the first non-empty candidate
  /// list in preference order: tvdb → tmdb → imdb.
  Future<List<FribbMappingRow>> lookup({int? tvdbId, int? tmdbId, String? imdbId}) async {
    final idx = await _ensureLoaded();
    if (tvdbId != null) {
      final hits = idx.byTvdb[tvdbId];
      if (hits != null && hits.isNotEmpty) return hits;
    }
    if (tmdbId != null) {
      final hits = idx.byTmdb[tmdbId];
      if (hits != null && hits.isNotEmpty) return hits;
    }
    if (imdbId != null) {
      final hits = idx.byImdb[imdbId];
      if (hits != null && hits.isNotEmpty) return hits;
    }
    return const [];
  }

  /// Conditional-GET the mapping if the last check was >[_refreshInterval] ago
  /// and we already have an index loaded. No-op when nothing is loaded — the
  /// first lookup handles the initial download.
  Future<void> maybeRefresh() async {
    if (_refreshRunning) return;
    if (_index == null) return;
    _refreshRunning = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt(_prefsLastCheckKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastCheck < _refreshInterval.inMilliseconds) return;

      final etag = prefs.getString(_prefsEtagKey);
      final client = platform.createPlatformClient();
      try {
        final res = await client
            .get(
              Uri.parse(_sourceUrl),
              headers: {'If-None-Match': ?etag, 'Accept': 'application/json'},
            )
            .timeout(_requestTimeout);
        await prefs.setInt(_prefsLastCheckKey, now);

        if (res.statusCode == 304) {
          appLogger.d('Fribb: mapping unchanged (304)');
          return;
        }
        if (res.statusCode != 200) {
          appLogger.d('Fribb: refresh returned HTTP ${res.statusCode}');
          return;
        }

        await _writeDiskCopy(res.body, etag: res.headers['etag']);
        final fresh = await compute(_parseAndIndex, res.body);
        _index = fresh;
        appLogger.d('Fribb: mapping refreshed (${fresh.byTvdb.length} tvdb entries)');
      } finally {
        client.close();
      }
    } catch (e) {
      appLogger.d('Fribb: refresh failed (non-fatal)', error: e);
    } finally {
      _refreshRunning = false;
    }
  }

  Future<void> _writeDiskCopy(String body, {String? etag}) async {
    await File(await _diskPath()).writeAsString(body, flush: true);
    if (etag != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsEtagKey, etag);
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
    return p.join(dir.path, _diskFileName);
  }

  @visibleForTesting
  void resetForTesting() {
    _index = null;
    _loading = null;
  }
}

/// Read the JSON from disk and parse it inside the isolate. Halves peak
/// memory vs. reading the string on the main isolate and shipping it across.
FribbIndex _readAndParse(String path) {
  final raw = File(path).readAsStringSync();
  return _parseAndIndex(raw);
}

/// Top-level so it can run in a `compute` isolate (which can't capture
/// instance state).
FribbIndex _parseAndIndex(String raw) {
  final decoded = json.decode(raw);
  if (decoded is! List) return const FribbIndex(byTvdb: {}, byTmdb: {}, byImdb: {});

  final byTvdb = <int, List<FribbMappingRow>>{};
  final byTmdb = <int, List<FribbMappingRow>>{};
  final byImdb = <String, List<FribbMappingRow>>{};

  for (final raw in decoded) {
    if (raw is! Map) continue;
    final row = FribbMappingRow.fromJson(raw.cast<String, dynamic>());
    final tvdb = row.tvdbId;
    if (tvdb != null) {
      (byTvdb[tvdb] ??= <FribbMappingRow>[]).add(row);
    }
    final tmdb = row.tmdbId;
    if (tmdb != null) {
      (byTmdb[tmdb] ??= <FribbMappingRow>[]).add(row);
    }
    final imdb = row.imdbId;
    if (imdb != null && imdb.isNotEmpty) {
      (byImdb[imdb] ??= <FribbMappingRow>[]).add(row);
    }
  }

  return FribbIndex(byTvdb: byTvdb, byTmdb: byTmdb, byImdb: byImdb);
}

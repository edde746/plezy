import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../models/trackers/anime_lists_mapping.dart';
import '../../models/trackers/fribb_mapping_row.dart';
import '../../utils/abortable_http_request.dart';
import '../../utils/app_logger.dart';
import '../../utils/platform_http_client_stub.dart'
    if (dart.library.io) '../../utils/platform_http_client_io.dart'
    as platform;
import '../base_shared_preferences_service.dart';
import 'anime_lists_index.dart';
import 'anime_mappings_decoder.dart';
import 'fribb_index.dart';

/// The anime mappings — Fribb's anime-lists and Anime-Lists' episode mappings
/// in one ~0.65 MB file, released daily by
/// https://github.com/edde746/anime-mappings.
///
/// Owns the whole lifecycle: lazy download on first use, a disk copy in the
/// app-support directory, decoding in a background isolate, and a daily
/// conditional GET ([maybeRefresh], If-None-Match) to pick up new releases.
class AnimeMappingsStore implements FribbMappingLookup, AnimeListsMappingLookup {
  static const String _sourceUrl =
      'https://github.com/edde746/anime-mappings/releases/latest/download/anime-mappings.bin.gz';
  static const String _diskFileName = 'anime-mappings.bin.gz';
  static const String _prefsEtagKey = 'anime_mappings_etag';
  static const String _prefsLastCheckKey = 'anime_mappings_last_check';
  static const Duration _refreshInterval = Duration(days: 1);
  static const Duration _requestTimeout = Duration(seconds: 60);

  /// The two upstream files this store's predecessors downloaded on their
  /// own, with their cache keys. Deleted when the combined file is first
  /// fetched so they do not sit in app support forever.
  static const List<String> _legacyDiskFileNames = ['anime-list-mini.json', 'anime-list.xml'];
  static const List<String> _legacyPrefsKeys = [
    'fribb_anime_list_etag',
    'fribb_anime_list_last_check',
    'anime_lists_etag',
    'anime_lists_last_check',
  ];

  AnimeMappingsStore._();

  static final AnimeMappingsStore instance = AnimeMappingsStore._();

  AnimeMappingsIndex? _index;
  Future<AnimeMappingsIndex>? _loading;
  bool _refreshRunning = false;

  /// See [FribbIndex.lookup].
  @override
  Future<List<FribbMappingRow>> lookup({
    required bool movie,
    int? anidbId,
    int? tvdbId,
    int? tmdbId,
    String? imdbId,
  }) async => (await _ensureLoaded()).fribb.lookup(
    movie: movie,
    anidbId: anidbId,
    tvdbId: tvdbId,
    tmdbId: tmdbId,
    imdbId: imdbId,
  );

  @override
  Future<FribbMappingRow?> lookupByMal(int malId) async => (await _ensureLoaded()).fribb.byMal[malId];

  @override
  Future<AnimeEpisodeMatch?> lookupEpisode({int? tvdbId, int? tmdbId, int? season, int? episodeNumber}) async =>
      (await _ensureLoaded()).animeLists.lookupEpisode(
        tvdbId: tvdbId,
        tmdbId: tmdbId,
        season: season,
        episodeNumber: episodeNumber,
      );

  @override
  Future<Set<int>> lookupAnimeIdsForSeason({int? tvdbId, int? tmdbId, required int season}) async =>
      (await _ensureLoaded()).animeLists.animeIdsForSeason(tvdbId: tvdbId, tmdbId: tmdbId, season: season);

  @override
  Future<Set<int>> lookupAnimeIdsForShow({int? tvdbId, int? tmdbId}) async =>
      (await _ensureLoaded()).animeLists.animeIdsForShow(tvdbId: tvdbId, tmdbId: tmdbId);

  /// Lazily load, downloading on first use. Subsequent calls return the
  /// cached index in O(1). Concurrent callers share the same Future.
  /// Schedules a background refresh after the first successful load.
  Future<AnimeMappingsIndex> _ensureLoaded() async {
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

  Future<AnimeMappingsIndex> _loadOrFetch() async {
    final path = await _diskPath(_diskFileName);
    try {
      return await compute(_readAndDecode, path);
    } on FileSystemException {
      appLogger.d('Anime mappings: no disk cache, downloading from GitHub');
      await _deleteLegacyCopies();
      final data = await _download();
      if (data == null) return AnimeMappingsIndex.empty;
      return await compute(decodeAnimeMappings, data);
    } catch (e) {
      appLogger.w('Anime mappings: decode failed — deleting disk copy so next lookup re-downloads', error: e);
      await _deleteDiskCopy();
      return AnimeMappingsIndex.empty;
    }
  }

  /// GET the mappings, save them to disk, and return the body. Returns `null`
  /// on any failure (offline, 4xx/5xx, timeout).
  Future<Uint8List?> _download() async {
    final client = platform.createPlatformClient();
    try {
      final res = await sendAbortableHttpRequest(
        client,
        'GET',
        Uri.parse(_sourceUrl),
        timeout: _requestTimeout,
        operation: 'Anime mappings download',
      );
      if (res.statusCode != 200) {
        appLogger.d('Anime mappings: download returned HTTP ${res.statusCode}');
        return null;
      }
      await _writeDiskCopy(res.bodyBytes, etag: res.headers['etag']);
      // Seed the daily throttle so a same-day relaunch skips the refresh.
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setInt(_prefsLastCheckKey, DateTime.now().millisecondsSinceEpoch);
      return res.bodyBytes;
    } catch (e) {
      appLogger.w('Anime mappings: download failed', error: e);
      return null;
    } finally {
      client.close();
    }
  }

  /// Conditional-GET the mappings if the last check was >[_refreshInterval]
  /// ago and we already have an index loaded. No-op when nothing is loaded —
  /// the first lookup handles the initial download.
  Future<void> maybeRefresh() async {
    if (_refreshRunning) return;
    if (_index == null) return;
    _refreshRunning = true;
    try {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      final lastCheck = prefs.getInt(_prefsLastCheckKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastCheck < _refreshInterval.inMilliseconds) return;

      final etag = prefs.getString(_prefsEtagKey);
      final client = platform.createPlatformClient();
      try {
        // GitHub redirects the latest-release URL to the asset itself, which
        // answers the forwarded If-None-Match with 304 while it is unchanged.
        final res = await sendAbortableHttpRequest(
          client,
          'GET',
          Uri.parse(_sourceUrl),
          headers: {'If-None-Match': ?etag},
          timeout: _requestTimeout,
          operation: 'Anime mappings refresh',
        );
        await prefs.setInt(_prefsLastCheckKey, now);

        if (res.statusCode == 304) {
          appLogger.d('Anime mappings: unchanged (304)');
          return;
        }
        if (res.statusCode != 200) {
          appLogger.d('Anime mappings: refresh returned HTTP ${res.statusCode}');
          return;
        }

        await _writeDiskCopy(res.bodyBytes, etag: res.headers['etag']);
        final fresh = await compute(decodeAnimeMappings, res.bodyBytes);
        _index = fresh;
        appLogger.d('Anime mappings: refreshed (${fresh.logSummary})');
      } finally {
        client.close();
      }
    } catch (e) {
      appLogger.d('Anime mappings: refresh failed (non-fatal)', error: e);
    } finally {
      _refreshRunning = false;
    }
  }

  Future<void> _writeDiskCopy(Uint8List body, {String? etag}) async {
    await File(await _diskPath(_diskFileName)).writeAsBytes(body, flush: true);
    if (etag != null) {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setString(_prefsEtagKey, etag);
    }
  }

  Future<void> _deleteDiskCopy() => _deleteFile(_diskFileName);

  Future<void> _deleteLegacyCopies() async {
    for (final name in _legacyDiskFileNames) {
      await _deleteFile(name);
    }
    try {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      for (final key in _legacyPrefsKeys) {
        await prefs.remove(key);
      }
    } catch (e) {
      appLogger.d('Anime mappings: could not clear legacy cache keys', error: e);
    }
  }

  Future<void> _deleteFile(String name) async {
    try {
      await File(await _diskPath(name)).delete();
    } on FileSystemException {
      // Already gone.
    }
  }

  Future<String> _diskPath(String name) async {
    final dir = await getApplicationSupportDirectory();
    return p.join(dir.path, name);
  }

  @visibleForTesting
  void resetForTesting() {
    _index = null;
    _loading = null;
  }
}

/// Reads the disk copy and decodes it inside the isolate. Halves peak memory
/// vs. reading the bytes on the main isolate and shipping them across.
AnimeMappingsIndex _readAndDecode(String path) => decodeAnimeMappings(File(path).readAsBytesSync());

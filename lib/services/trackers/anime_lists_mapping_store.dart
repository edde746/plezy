import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';

import '../../models/trackers/anime_lists_mapping.dart';
import '../../utils/abortable_http_request.dart';
import '../../utils/app_logger.dart';
import '../../utils/json_utils.dart';
import '../../utils/platform_http_client_stub.dart'
    if (dart.library.io) '../../utils/platform_http_client_io.dart'
    as platform;
import '../base_shared_preferences_service.dart';

class AnimeListsIndex {
  final Map<int, List<AnimeListEntry>> byTvdb;
  final Map<int, List<AnimeListEntry>> byTmdbTv;

  const AnimeListsIndex({required this.byTvdb, required this.byTmdbTv});

  bool get isEmpty => byTvdb.isEmpty && byTmdbTv.isEmpty;
}

abstract interface class AnimeListsMappingLookup {
  Future<AnimeEpisodeMatch?> lookupEpisode({int? tvdbId, int? tmdbId, int? season, int? episodeNumber});

  Future<Set<int>> lookupAnimeIdsForSeason({int? tvdbId, int? tmdbId, required int season});

  Future<Set<int>> lookupAnimeIdsForShow({int? tvdbId, int? tmdbId});
}

class AnimeListsMappingStore implements AnimeListsMappingLookup {
  static const String _diskFileName = 'anime-list.xml';
  static const String _prefsEtagKey = 'anime_lists_etag';
  static const String _prefsLastCheckKey = 'anime_lists_last_check';
  static const String _sourceUrl = 'https://cdn.jsdelivr.net/gh/Anime-Lists/anime-lists@master/anime-list.xml';

  static const Duration _refreshInterval = Duration(days: 7);
  static const Duration _requestTimeout = Duration(seconds: 60);

  AnimeListsMappingStore._();
  static final AnimeListsMappingStore instance = AnimeListsMappingStore._();

  AnimeListsIndex? _index;
  Future<AnimeListsIndex>? _loading;
  bool _refreshRunning = false;

  Future<AnimeListsIndex> _ensureLoaded() async {
    final existing = _index;
    if (existing != null) return existing;
    final loading = _loading;
    if (loading != null) return loading;

    final fresh = _loadOrFetch();
    _loading = fresh;
    try {
      final idx = await fresh;
      if (!idx.isEmpty) {
        _index = idx;
        unawaited(maybeRefresh());
      }
      return idx;
    } finally {
      _loading = null;
    }
  }

  Future<AnimeListsIndex> _loadOrFetch() async {
    final path = await _diskPath();
    try {
      return await compute(_readAndParseAnimeLists, path);
    } on FileSystemException {
      appLogger.d('Anime-Lists: no disk cache, downloading from jsDelivr');
      final raw = await _download();
      if (raw == null) return const AnimeListsIndex(byTvdb: {}, byTmdbTv: {});
      return await compute(parseAnimeListsIndex, raw);
    } catch (e) {
      appLogger.w('Anime-Lists: parse failed - deleting disk copy so next lookup re-downloads', error: e);
      await _deleteDiskCopy();
      return const AnimeListsIndex(byTvdb: {}, byTmdbTv: {});
    }
  }

  Future<String?> _download() async {
    final client = platform.createPlatformClient();
    try {
      final res = await sendAbortableHttpRequest(
        client,
        'GET',
        Uri.parse(_sourceUrl),
        headers: const {'Accept': 'application/xml,text/xml'},
        timeout: _requestTimeout,
        operation: 'Anime-Lists mapping download',
      );
      if (res.statusCode != 200) {
        appLogger.d('Anime-Lists: download returned HTTP ${res.statusCode}');
        return null;
      }
      await _writeDiskCopy(res.body, etag: res.headers['etag']);
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setInt(_prefsLastCheckKey, DateTime.now().millisecondsSinceEpoch);
      return res.body;
    } catch (e) {
      appLogger.w('Anime-Lists: download failed', error: e);
      return null;
    } finally {
      client.close();
    }
  }

  @override
  Future<AnimeEpisodeMatch?> lookupEpisode({int? tvdbId, int? tmdbId, int? season, int? episodeNumber}) async {
    final idx = await _ensureLoaded();
    return lookupAnimeListEpisodeInIndex(
      idx,
      tvdbId: tvdbId,
      tmdbId: tmdbId,
      season: season,
      episodeNumber: episodeNumber,
    );
  }

  @override
  Future<Set<int>> lookupAnimeIdsForSeason({int? tvdbId, int? tmdbId, required int season}) async {
    final idx = await _ensureLoaded();
    if (tvdbId != null) {
      final ids = _seasonAnimeIds(idx.byTvdb[tvdbId], AnimeListProvider.tvdb, season);
      if (ids.isNotEmpty) return ids;
    }
    if (tmdbId != null) {
      return _seasonAnimeIds(idx.byTmdbTv[tmdbId], AnimeListProvider.tmdb, season);
    }
    return const <int>{};
  }

  @override
  Future<Set<int>> lookupAnimeIdsForShow({int? tvdbId, int? tmdbId}) async {
    final idx = await _ensureLoaded();
    if (tvdbId != null) {
      final entries = idx.byTvdb[tvdbId];
      if (entries != null && entries.isNotEmpty) return {for (final entry in entries) entry.anidbId};
    }
    if (tmdbId != null) {
      final entries = idx.byTmdbTv[tmdbId];
      if (entries != null && entries.isNotEmpty) return {for (final entry in entries) entry.anidbId};
    }
    return const <int>{};
  }

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
        final res = await sendAbortableHttpRequest(
          client,
          'GET',
          Uri.parse(_sourceUrl),
          headers: {'If-None-Match': ?etag, 'Accept': 'application/xml,text/xml'},
          timeout: _requestTimeout,
          operation: 'Anime-Lists mapping refresh',
        );
        await prefs.setInt(_prefsLastCheckKey, now);

        if (res.statusCode == 304) {
          appLogger.d('Anime-Lists: mapping unchanged (304)');
          return;
        }
        if (res.statusCode != 200) {
          appLogger.d('Anime-Lists: refresh returned HTTP ${res.statusCode}');
          return;
        }

        await _writeDiskCopy(res.body, etag: res.headers['etag']);
        final fresh = await compute(parseAnimeListsIndex, res.body);
        _index = fresh;
        appLogger.d('Anime-Lists: mapping refreshed (${fresh.byTvdb.length} tvdb entries)');
      } finally {
        client.close();
      }
    } catch (e) {
      appLogger.d('Anime-Lists: refresh failed (non-fatal)', error: e);
    } finally {
      _refreshRunning = false;
    }
  }

  Future<void> _writeDiskCopy(String body, {String? etag}) async {
    await File(await _diskPath()).writeAsString(body, flush: true);
    if (etag != null) {
      final prefs = await BaseSharedPreferencesService.sharedCache();
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

@visibleForTesting
AnimeEpisodeMatch? lookupAnimeListEpisodeInIndex(
  AnimeListsIndex idx, {
  int? tvdbId,
  int? tmdbId,
  int? season,
  int? episodeNumber,
}) {
  if (season == null || episodeNumber == null || episodeNumber <= 0) return null;
  if (tvdbId != null) {
    final selected = _selectMatch(_matches(idx.byTvdb[tvdbId], AnimeListProvider.tvdb, season, episodeNumber));
    if (selected != null) return selected;
  }
  if (tmdbId != null) {
    return _selectMatch(_matches(idx.byTmdbTv[tmdbId], AnimeListProvider.tmdb, season, episodeNumber));
  }
  return null;
}

List<AnimeEpisodeMatch> _matches(
  List<AnimeListEntry>? entries,
  AnimeListProvider provider,
  int season,
  int episodeNumber,
) {
  if (entries == null || entries.isEmpty) return const [];
  return [
    for (final entry in entries)
      ...entry.resolveEpisode(provider: provider, externalSeason: season, externalEpisode: episodeNumber),
  ];
}

AnimeEpisodeMatch? _selectMatch(List<AnimeEpisodeMatch> matches) {
  if (matches.isEmpty) return null;
  final bestPriority = matches.map(_matchPriority).reduce((a, b) => a < b ? a : b);
  final best = matches.where((match) => _matchPriority(match) == bestPriority).toList(growable: false);
  final first = best.first;
  if (best.every(first.sameEpisode)) return first;
  return null;
}

int _matchPriority(AnimeEpisodeMatch match) => switch (match.kind) {
  AnimeListMatchKind.explicit => 0,
  AnimeListMatchKind.range => 1,
  AnimeListMatchKind.defaultMapping => 2,
};

Set<int> _seasonAnimeIds(List<AnimeListEntry>? entries, AnimeListProvider provider, int season) {
  if (entries == null || entries.isEmpty) return const <int>{};
  return {
    for (final entry in entries)
      if (entry.mapsSeason(provider: provider, externalSeason: season)) entry.anidbId,
  };
}

AnimeListsIndex _readAndParseAnimeLists(String path) {
  final raw = File(path).readAsStringSync();
  return parseAnimeListsIndex(raw);
}

@visibleForTesting
AnimeListsIndex parseAnimeListsIndex(String raw) {
  final document = XmlDocument.parse(raw);
  final byTvdb = <int, List<AnimeListEntry>>{};
  final byTmdbTv = <int, List<AnimeListEntry>>{};

  for (final anime in document.findAllElements('anime')) {
    final anidbId = flexibleInt(anime.getAttribute('anidbid'));
    if (anidbId == null) continue;
    final entry = AnimeListEntry(
      anidbId: anidbId,
      name: anime.getElement('name')?.innerText.trim(),
      rawTvdbId: anime.getAttribute('tvdbid'),
      tvdbId: flexibleInt(anime.getAttribute('tvdbid')),
      defaultTvdbSeason: _seasonRef(anime.getAttribute('defaulttvdbseason')),
      episodeOffset: flexibleInt(anime.getAttribute('episodeoffset')) ?? 0,
      tmdbTvId: flexibleInt(anime.getAttribute('tmdbtv')),
      tmdbSeason: _seasonRef(anime.getAttribute('tmdbseason')),
      tmdbOffset: flexibleInt(anime.getAttribute('tmdboffset')) ?? 0,
      tmdbMovieIds: _intList(anime.getAttribute('tmdbid')),
      imdbIds: _stringList(anime.getAttribute('imdbid')),
      mappings: _parseMappings(anime),
    );

    final tvdb = entry.tvdbId;
    if (tvdb != null) (byTvdb[tvdb] ??= <AnimeListEntry>[]).add(entry);
    final tmdbTv = entry.tmdbTvId;
    if (tmdbTv != null) (byTmdbTv[tmdbTv] ??= <AnimeListEntry>[]).add(entry);
  }

  return AnimeListsIndex(byTvdb: byTvdb, byTmdbTv: byTmdbTv);
}

AnimeListSeasonRef? _seasonRef(String? value) {
  if (value == null || value.isEmpty) return null;
  if (value == 'a') return const AnimeListSeasonRef.absolute();
  final number = flexibleInt(value);
  return number == null ? null : AnimeListSeasonRef.number(number);
}

List<int> _intList(String? value) {
  if (value == null || value.isEmpty) return const [];
  return [
    for (final part in value.split(','))
      ?flexibleInt(part.trim()),
  ];
}

List<String> _stringList(String? value) {
  if (value == null || value.isEmpty) return const [];
  return [
    for (final part in value.split(','))
      if (part.trim().isNotEmpty) part.trim(),
  ];
}

List<AnimeListEpisodeMapping> _parseMappings(XmlElement anime) {
  final list = anime.getElement('mapping-list');
  if (list == null) return const [];
  final mappings = <AnimeListEpisodeMapping>[];
  for (final mapping in list.findElements('mapping')) {
    final anidbSeason = flexibleInt(mapping.getAttribute('anidbseason'));
    if (anidbSeason == null) continue;
    final start = flexibleInt(mapping.getAttribute('start'));
    final end = flexibleInt(mapping.getAttribute('end'));
    final offset = flexibleInt(mapping.getAttribute('offset')) ?? 0;
    final explicit = _parseExplicitMappings(mapping.innerText);

    final tvdbSeason = flexibleInt(mapping.getAttribute('tvdbseason'));
    if (tvdbSeason != null) {
      mappings.add(
        AnimeListEpisodeMapping(
          anidbSeason: anidbSeason,
          provider: AnimeListProvider.tvdb,
          externalSeason: tvdbSeason,
          start: start,
          end: end,
          offset: offset,
          explicit: explicit,
        ),
      );
    }

    final tmdbSeason = flexibleInt(mapping.getAttribute('tmdbseason'));
    if (tmdbSeason != null) {
      mappings.add(
        AnimeListEpisodeMapping(
          anidbSeason: anidbSeason,
          provider: AnimeListProvider.tmdb,
          externalSeason: tmdbSeason,
          start: start,
          end: end,
          offset: offset,
          explicit: explicit,
        ),
      );
    }
  }
  return mappings;
}

List<AnimeListExplicitEpisodeMapping> _parseExplicitMappings(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return const [];
  final mappings = <AnimeListExplicitEpisodeMapping>[];
  for (final segment in trimmed.split(';')) {
    final item = segment.trim();
    if (item.isEmpty) continue;
    final separator = item.indexOf('-');
    if (separator <= 0 || separator == item.length - 1) continue;
    final anidbEpisode = flexibleInt(item.substring(0, separator));
    if (anidbEpisode == null) continue;
    final externalEpisodes = <int>[];
    for (final target in item.substring(separator + 1).split('+')) {
      final externalEpisode = flexibleInt(target.trim());
      if (externalEpisode == null || externalEpisode == 0) continue;
      externalEpisodes.add(externalEpisode);
    }
    if (externalEpisodes.isEmpty) continue;
    mappings.add(AnimeListExplicitEpisodeMapping(anidbEpisode: anidbEpisode, externalEpisodes: externalEpisodes));
  }
  return mappings;
}

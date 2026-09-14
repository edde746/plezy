import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

import '../../models/trackers/anime_lists_mapping.dart';
import '../../utils/json_utils.dart';
import 'etag_cached_remote_store.dart';

class AnimeListsIndex implements RemoteIndex {
  final Map<int, List<AnimeListEntry>> byTvdb;
  final Map<int, List<AnimeListEntry>> byTmdbTv;

  const AnimeListsIndex({required this.byTvdb, required this.byTmdbTv});

  @override
  bool get isEmpty => byTvdb.isEmpty && byTmdbTv.isEmpty;

  @override
  String get logSummary => '${byTvdb.length} tvdb entries';
}

abstract interface class AnimeListsMappingLookup {
  Future<AnimeEpisodeMatch?> lookupEpisode({int? tvdbId, int? tmdbId, int? season, int? episodeNumber});

  Future<Set<int>> lookupAnimeIdsForSeason({int? tvdbId, int? tmdbId, required int season});

  Future<Set<int>> lookupAnimeIdsForShow({int? tvdbId, int? tmdbId});
}

class AnimeListsMappingStore extends EtagCachedRemoteStore<AnimeListsIndex> implements AnimeListsMappingLookup {
  AnimeListsMappingStore._()
    : super(
        diskFileName: 'anime-list.xml',
        prefsEtagKey: 'anime_lists_etag',
        prefsLastCheckKey: 'anime_lists_last_check',
        sourceUrl: 'https://cdn.jsdelivr.net/gh/Anime-Lists/anime-lists@master/anime-list.xml',
        acceptHeader: 'application/xml,text/xml',
        logLabel: 'Anime-Lists',
        emptyIndex: const AnimeListsIndex(byTvdb: {}, byTmdbTv: {}),
        parse: parseAnimeListsIndex,
        readAndParse: _readAndParseAnimeLists,
      );

  static final AnimeListsMappingStore instance = AnimeListsMappingStore._();

  @override
  Future<AnimeEpisodeMatch?> lookupEpisode({int? tvdbId, int? tmdbId, int? season, int? episodeNumber}) async {
    final idx = await ensureLoaded();
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
    final idx = await ensureLoaded();
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
    final idx = await ensureLoaded();
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
  return [for (final part in value.split(',')) ?flexibleInt(part.trim())];
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

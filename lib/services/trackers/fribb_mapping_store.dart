import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import '../../models/trackers/fribb_mapping_row.dart';
import '../../utils/app_logger.dart';
import 'etag_cached_remote_store.dart';

/// Indexed view of the Fribb mapping database, queried by external ID.
///
/// Three lookup tables (tvdb / tmdb / imdb) into a shared list of rows.
/// A single tvdb_id may map to multiple rows (split-cour anime → one per
/// season); callers that have a Plex season number should filter by
/// [FribbMappingRow.tvdbSeason] or [FribbMappingRow.tmdbSeason].
class FribbIndex implements RemoteIndex {
  final Map<int, List<FribbMappingRow>> byTvdb;
  final Map<int, List<FribbMappingRow>> byTmdb;
  final Map<String, List<FribbMappingRow>> byImdb;

  /// Reverse index for the Explore catalog: MAL id → its (single) row, so a
  /// MAL entry can be matched back to library external ids.
  final Map<int, FribbMappingRow> byMal;

  /// AniDB id → its (single) row. AniDB is the dataset's own primary key, so
  /// unlike the three catalog indexes this one never resolves to a list.
  /// Plex's HAMA agent identifies anime by AniDB id and nothing else, which is
  /// the only way a library item reaches the mapping through it (#1788).
  final Map<int, FribbMappingRow> byAnidb;

  const FribbIndex({
    required this.byTvdb,
    required this.byTmdb,
    required this.byImdb,
    this.byMal = const {},
    this.byAnidb = const {},
  });

  @override
  bool get isEmpty => byTvdb.isEmpty && byTmdb.isEmpty && byImdb.isEmpty && byMal.isEmpty && byAnidb.isEmpty;

  @override
  String get logSummary => '${byTvdb.length} tvdb entries';
}

abstract interface class FribbMappingLookup {
  Future<List<FribbMappingRow>> lookup({int? anidbId, int? tvdbId, int? tmdbId, String? imdbId});

  Future<FribbMappingRow?> lookupByMal(int malId);
}

/// Loads and refreshes the Fribb anime-lists mapping on demand — the ~5 MB
/// JSON, indexed by external ID.
class FribbMappingStore extends EtagCachedRemoteStore<FribbIndex> implements FribbMappingLookup {
  FribbMappingStore._()
    : super(
        diskFileName: 'anime-list-mini.json',
        prefsEtagKey: 'fribb_anime_list_etag',
        prefsLastCheckKey: 'fribb_anime_list_last_check',
        // jsDelivr (CDN-backed). `raw.githubusercontent.com` rate-limits
        // aggressively on shared IPs and returns 429 mid-refresh.
        sourceUrl: 'https://cdn.jsdelivr.net/gh/Fribb/anime-lists@master/anime-list-mini.json',
        acceptHeader: 'application/json',
        logLabel: 'Fribb',
        emptyIndex: const FribbIndex(byTvdb: {}, byTmdb: {}, byImdb: {}),
        parse: parseFribbIndex,
        readAndParse: _readAndParse,
      );

  static final FribbMappingStore instance = FribbMappingStore._();

  /// Look up rows by a library item's external IDs. Returns the first non-empty
  /// candidate list in preference order: anidb → tvdb → tmdb → imdb.
  ///
  /// AniDB leads because it is the dataset's primary key: it names exactly one
  /// entry, where a tvdb/tmdb/imdb hit can be a whole split-cour show the
  /// caller still has to disambiguate.
  @override
  Future<List<FribbMappingRow>> lookup({int? anidbId, int? tvdbId, int? tmdbId, String? imdbId}) async {
    final idx = await ensureLoaded();
    if (anidbId != null) {
      final hit = idx.byAnidb[anidbId];
      if (hit != null) return [hit];
    }
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

  @override
  Future<FribbMappingRow?> lookupByMal(int malId) async => (await ensureLoaded()).byMal[malId];
}

FribbIndex _readAndParse(String path) {
  final raw = File(path).readAsStringSync();
  return parseFribbIndex(raw);
}

/// Parse the raw `anime-list-mini.json` body into an indexed [FribbIndex].
/// Top-level so it can run in a `compute` isolate (which can't capture instance
/// state). A row may carry several imdb/tmdb ids (movie collections / the
/// tv+movie split), so each row is fanned out under every id it declares.
///
/// Per-row parsing is guarded: a single malformed row is skipped rather than
/// aborting the whole parse — that previously emptied the index and triggered a
/// disk-delete/re-download loop (#1402).
@visibleForTesting
FribbIndex parseFribbIndex(String raw) {
  final decoded = json.decode(raw);
  if (decoded is! List) return const FribbIndex(byTvdb: {}, byTmdb: {}, byImdb: {});

  final byTvdb = <int, List<FribbMappingRow>>{};
  final byTmdb = <int, List<FribbMappingRow>>{};
  final byImdb = <String, List<FribbMappingRow>>{};
  final byMal = <int, FribbMappingRow>{};
  final byAnidb = <int, FribbMappingRow>{};

  var skipped = 0;
  for (final raw in decoded) {
    if (raw is! Map) continue;
    final FribbMappingRow row;
    try {
      row = FribbMappingRow.fromJson(raw.cast<String, dynamic>());
    } catch (_) {
      skipped++;
      continue;
    }
    final tvdb = row.tvdbId;
    if (tvdb != null) {
      (byTvdb[tvdb] ??= <FribbMappingRow>[]).add(row);
    }
    for (final tmdb in row.tmdbIds ?? const <int>[]) {
      (byTmdb[tmdb] ??= <FribbMappingRow>[]).add(row);
    }
    for (final imdb in row.imdbIds ?? const <String>[]) {
      if (imdb.isEmpty) continue;
      (byImdb[imdb] ??= <FribbMappingRow>[]).add(row);
    }
    final mal = row.malId;
    if (mal != null) byMal.putIfAbsent(mal, () => row);
    final anidb = row.anidbId;
    if (anidb != null) byAnidb.putIfAbsent(anidb, () => row);
  }

  if (skipped > 0) appLogger.w('Fribb: skipped $skipped malformed row(s)');
  return FribbIndex(byTvdb: byTvdb, byTmdb: byTmdb, byImdb: byImdb, byMal: byMal, byAnidb: byAnidb);
}

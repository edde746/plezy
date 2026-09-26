// ignore_for_file: invalid_annotation_target
import 'package:json_annotation/json_annotation.dart';

import '../../utils/json_utils.dart';

part 'fribb_mapping_row.g.dart';

Object? _readTvdbSeason(Map json, String key) {
  final season = json['season'];
  return season is Map ? season['tvdb'] : null;
}

Object? _readTmdbSeason(Map json, String key) {
  final season = json['season'];
  return season is Map ? season['tmdb'] : null;
}

/// Fribb's `themoviedb_id` is `{"tv": <int>}` (always a single id) or
/// `{"movie": [<int>, ...]}` (one or more). TMDB numbers movies and TV series
/// independently, so the key is the only thing saying which namespace an id
/// lives in: TMDB 982 is both the film The Manchurian Candidate and the series
/// Transformers: Armada. The row's `type` cannot stand in for it — a MOVIE row
/// can be a TMDB TV special (`{"tv": id}` at season 0) and an OVA a TMDB movie.
///
/// A legacy flat int / numeric string / bare list carries no key, so there the
/// row's own `type` is the only hint left — enough to survive a future schema
/// re-flip without guessing on the current one.
Object? _readTmdbTvId(Map json, String key) {
  final value = json['themoviedb_id'];
  if (value is Map) return value['tv'];
  if (_isMovieType(json['type'])) return null;
  return value is List ? value.firstOrNull : value;
}

Object? _readTmdbMovieIds(Map json, String key) {
  final value = json['themoviedb_id'];
  if (value is Map) return value['movie'];
  return _isMovieType(json['type']) ? value : null;
}

bool _isMovieType(Object? type) => type == 'MOVIE';

List<int>? _flexibleIntList(Object? v) {
  final ids = <int>[];
  void add(Object? e) {
    final n = flexibleInt(e);
    if (n != null) ids.add(n);
  }

  if (v is List) {
    v.forEach(add);
  } else {
    add(v);
  }
  return ids.isEmpty ? null : ids;
}

/// Defensive String coercion — Fribb's `type` is a string enum today, but the
/// schema has churned, so never hard-cast it.
String? _typeString(Object? v) => v is String ? v : null;

/// One row from `anime-list-mini.json` (Fribb/anime-lists).
@JsonSerializable(createToJson: false)
class FribbMappingRow {
  @JsonKey(name: 'anidb_id', fromJson: flexibleInt)
  final int? anidbId;
  @JsonKey(name: 'anilist_id', fromJson: flexibleInt)
  final int? anilistId;

  /// Fribb's `imdb_id` is an array of IMDb GUIDs (movie collections / multi-part
  /// can carry several); a Plex item matches if its single IMDb id is any one.
  @JsonKey(name: 'imdb_id', fromJson: flexibleStringList)
  final List<String>? imdbIds;
  @JsonKey(name: 'mal_id', fromJson: flexibleInt)
  final int? malId;
  @JsonKey(name: 'simkl_id', fromJson: flexibleInt)
  final int? simklId;

  /// TMDB TV series id, from `themoviedb_id: {"tv": id}`.
  @JsonKey(readValue: _readTmdbTvId, fromJson: flexibleInt)
  final int? tmdbTvId;

  /// TMDB movie ids, from `themoviedb_id: {"movie": [ids]}`. A movie collection
  /// or multi-part film can carry several; a library movie matches if its single
  /// TMDB id is any one. Never mixed with [tmdbTvId].
  @JsonKey(readValue: _readTmdbMovieIds, fromJson: _flexibleIntList)
  final List<int>? tmdbMovieIds;
  @JsonKey(name: 'tvdb_id', fromJson: flexibleInt)
  final int? tvdbId;

  /// Plex season number this mapping corresponds to. A single show-level
  /// external ID can resolve to multiple rows for split-cour anime; the
  /// resolver picks by matching the episode's `parentIndex` against these.
  @JsonKey(readValue: _readTvdbSeason, fromJson: flexibleInt)
  final int? tvdbSeason;
  @JsonKey(readValue: _readTmdbSeason, fromJson: flexibleInt)
  final int? tmdbSeason;

  /// `TV` / `MOVIE` / `OVA` / `ONA` / `SPECIAL` / `UNKNOWN` / `null`.
  @JsonKey(fromJson: _typeString)
  final String? type;

  const FribbMappingRow({
    this.anidbId,
    this.anilistId,
    this.imdbIds,
    this.malId,
    this.simklId,
    this.tmdbTvId,
    this.tmdbMovieIds,
    this.tvdbId,
    this.tvdbSeason,
    this.tmdbSeason,
    this.type,
  });

  bool get isMovie => _isMovieType(type);

  /// The TMDB id in the namespace the caller presents this entry in — a movie
  /// id for a movie, the series id otherwise — or null when Fribb has none there.
  int? tmdbIdFor({required bool movie}) => movie ? tmdbMovieIds?.firstOrNull : tmdbTvId;

  factory FribbMappingRow.fromJson(Map<String, dynamic> json) => _$FribbMappingRowFromJson(json);
}

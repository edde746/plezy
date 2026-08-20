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

/// Flatten Fribb's `themoviedb_id` into a flat id list. Current schema is an
/// object: `{"tv": <int>}` (always a single id) or `{"movie": [<int>, ...]}`
/// (one or more). Tolerant of a legacy flat int / numeric string / bare list
/// so the parser survives a future schema re-flip.
List<int>? _flattenTmdbIds(Object? v) {
  final ids = <int>[];
  void add(Object? e) {
    final n = flexibleInt(e);
    if (n != null) ids.add(n);
  }

  switch (v) {
    case final Map m:
      add(m['tv']);
      final movie = m['movie'];
      if (movie is List) {
        movie.forEach(add);
      } else {
        add(movie);
      }
    case final List l:
      l.forEach(add);
    default:
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

  /// Fribb's `themoviedb_id` is `{"tv": id}` or `{"movie": [ids]}`. Flattened to
  /// a list so a Plex item matches if its single TMDB id is any one.
  @JsonKey(name: 'themoviedb_id', fromJson: _flattenTmdbIds)
  final List<int>? tmdbIds;
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
    this.tmdbIds,
    this.tvdbId,
    this.tvdbSeason,
    this.tmdbSeason,
    this.type,
  });

  bool get isMovie => type == 'MOVIE';

  factory FribbMappingRow.fromJson(Map<String, dynamic> json) => _$FribbMappingRowFromJson(json);
}

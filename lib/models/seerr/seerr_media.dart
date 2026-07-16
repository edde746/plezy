import 'package:json_annotation/json_annotation.dart';

import 'seerr_request.dart';

part 'seerr_media.g.dart';

/// Seerr availability of a title/season on the linked media server
/// (`MediaInfo.status`).
enum SeerrMediaStatus {
  unknown(1),
  pending(2),
  processing(3),
  partiallyAvailable(4),
  available(5),
  deleted(6);

  final int code;
  const SeerrMediaStatus(this.code);

  static SeerrMediaStatus fromCode(int? code) =>
      values.where((v) => v.code == code).firstOrNull ?? SeerrMediaStatus.unknown;
}

/// A movie or TV entry from Seerr's TMDB-backed discover/search endpoints.
///
/// TMDB uses `title`/`releaseDate` for movies and `name`/`firstAirDate` for
/// TV; [displayTitle]/[date] paper over the split. `mediaType` is absent on
/// the single-type discover endpoints — the client coerces it there.
@JsonSerializable(createToJson: false)
class SeerrMedia {
  final int id;
  final String? mediaType;
  final String? title;
  final String? name;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final String? firstAirDate;
  final double? voteAverage;
  final int? voteCount;
  final SeerrMediaInfo? mediaInfo;

  const SeerrMedia({
    required this.id,
    this.mediaType,
    this.title,
    this.name,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.firstAirDate,
    this.voteAverage,
    this.voteCount,
    this.mediaInfo,
  });

  bool get isMovie => mediaType == 'movie';

  String get displayTitle => title ?? name ?? '';

  String? get date => releaseDate ?? firstAirDate;

  int? get year {
    final d = date;
    if (d == null || d.length < 4) return null;
    return int.tryParse(d.substring(0, 4));
  }

  factory SeerrMedia.fromJson(Map<String, dynamic> json) => _$SeerrMediaFromJson(json);
}

/// Seerr's knowledge of a title on the linked media server: availability
/// status plus any open requests. Absent entirely for titles Seerr has
/// never seen.
@JsonSerializable(createToJson: false)
class SeerrMediaInfo {
  final int? id;
  final int? tmdbId;
  final int? tvdbId;

  @JsonKey(name: 'status', fromJson: SeerrMediaStatus.fromCode)
  final SeerrMediaStatus status;
  @JsonKey(name: 'status4k', fromJson: SeerrMediaStatus.fromCode)
  final SeerrMediaStatus status4k;

  /// TV only: per-season availability.
  final List<SeerrSeasonInfo>? seasons;

  /// Open/settled requests for this title (used to disable already-requested
  /// seasons in the request sheet).
  final List<SeerrRequest>? requests;

  const SeerrMediaInfo({
    this.id,
    this.tmdbId,
    this.tvdbId,
    this.status = SeerrMediaStatus.unknown,
    this.status4k = SeerrMediaStatus.unknown,
    this.seasons,
    this.requests,
  });

  factory SeerrMediaInfo.fromJson(Map<String, dynamic> json) => _$SeerrMediaInfoFromJson(json);
}

/// Availability of one season (`MediaInfo.seasons[]`).
@JsonSerializable(createToJson: false)
class SeerrSeasonInfo {
  final int seasonNumber;
  @JsonKey(name: 'status', fromJson: SeerrMediaStatus.fromCode)
  final SeerrMediaStatus status;
  @JsonKey(name: 'status4k', fromJson: SeerrMediaStatus.fromCode)
  final SeerrMediaStatus status4k;

  const SeerrSeasonInfo({
    required this.seasonNumber,
    this.status = SeerrMediaStatus.unknown,
    this.status4k = SeerrMediaStatus.unknown,
  });

  factory SeerrSeasonInfo.fromJson(Map<String, dynamic> json) => _$SeerrSeasonInfoFromJson(json);
}

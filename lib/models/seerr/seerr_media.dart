import 'package:json_annotation/json_annotation.dart';

import '../../utils/json_utils.dart';

import 'seerr_request.dart';
import 'seerr_session.dart';

part 'seerr_media.g.dart';

/// Seerr availability of a title/season on the linked media server
/// (`MediaInfo.status`).
///
/// The wire codes are NOT product-neutral: Overseerr ends at DELETED=6 while
/// Jellyseerr inserts BLOCKLISTED=6 and shifts DELETED to 7. Models therefore
/// keep the raw code and [resolve] maps it where the session's
/// [SeerrProduct] is known.
enum SeerrMediaStatus {
  unknown,
  pending,
  processing,
  partiallyAvailable,
  available,
  blocklisted,
  deleted;

  /// Decode a raw `MediaInfo.status` code for [product]. Codes 1-5 agree
  /// across products; 6/7 diverge (Overseerr: 6=DELETED, 7 unused;
  /// Jellyseerr: 6=BLOCKLISTED, 7=DELETED). For [SeerrProduct.unknown]
  /// (legacy persisted sessions) both map to [blocklisted] — not available
  /// and not requestable, safe under either contract — until the next
  /// `/settings/public` fetch persists the real product. Unrecognized codes
  /// decode as [unknown].
  static SeerrMediaStatus resolve(int? code, SeerrProduct product) => switch (code) {
    1 => unknown,
    2 => pending,
    3 => processing,
    4 => partiallyAvailable,
    5 => available,
    6 => product == SeerrProduct.overseerr ? deleted : blocklisted,
    7 => switch (product) {
      SeerrProduct.overseerr => unknown,
      SeerrProduct.jellyseerr => deleted,
      SeerrProduct.unknown => blocklisted,
    },
    _ => unknown,
  };
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
  final double? popularity;
  final String? originalLanguage;
  final String? originalTitle;
  final String? originalName;
  final bool? adult;
  final List<String>? originCountry;

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
    this.popularity,
    this.originalLanguage,
    this.originalTitle,
    this.originalName,
    this.adult,
    this.originCountry,
  });

  bool get isMovie => mediaType == 'movie';

  /// Localized title, falling back to the original when the requested
  /// language has no translation. TMDB answers a `language` query with an
  /// empty string rather than omitting the field, so `??` alone is not enough.
  String get displayTitle => firstNonBlank([title, name, originalTitle, originalName]) ?? '';

  String? get date => releaseDate ?? firstAirDate;

  String? get displayOriginalTitle => originalTitle ?? originalName;

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

  /// Raw `MediaInfo.status` wire codes — product-dependent for 6/7, so kept
  /// undecoded here; resolve via [status]/[status4k] where the session's
  /// product is known.
  @JsonKey(name: 'status')
  final int? statusCode;
  @JsonKey(name: 'status4k')
  final int? status4kCode;

  /// TV only: per-season availability.
  final List<SeerrSeasonInfo>? seasons;

  /// Open/settled requests for this title (used to disable already-requested
  /// seasons in the request sheet).
  final List<SeerrRequest>? requests;

  const SeerrMediaInfo({
    this.id,
    this.tmdbId,
    this.tvdbId,
    this.statusCode,
    this.status4kCode,
    this.seasons,
    this.requests,
  });

  SeerrMediaStatus status(SeerrProduct product) => SeerrMediaStatus.resolve(statusCode, product);

  SeerrMediaStatus status4k(SeerrProduct product) => SeerrMediaStatus.resolve(status4kCode, product);

  factory SeerrMediaInfo.fromJson(Map<String, dynamic> json) => _$SeerrMediaInfoFromJson(json);
}

/// Availability of one season (`MediaInfo.seasons[]`).
@JsonSerializable(createToJson: false)
class SeerrSeasonInfo {
  final int seasonNumber;

  /// Raw wire codes, as on [SeerrMediaInfo].
  @JsonKey(name: 'status')
  final int? statusCode;
  @JsonKey(name: 'status4k')
  final int? status4kCode;

  const SeerrSeasonInfo({required this.seasonNumber, this.statusCode, this.status4kCode});

  SeerrMediaStatus status(SeerrProduct product) => SeerrMediaStatus.resolve(statusCode, product);

  SeerrMediaStatus status4k(SeerrProduct product) => SeerrMediaStatus.resolve(status4kCode, product);

  factory SeerrSeasonInfo.fromJson(Map<String, dynamic> json) => _$SeerrSeasonInfoFromJson(json);
}

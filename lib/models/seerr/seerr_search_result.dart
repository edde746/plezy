import 'seerr_media_info.dart';

/// One row of a `/search` or `/discover` response. Discriminated by
/// `mediaType` (`movie` | `tv` | `person`).
sealed class SeerrSearchResult {
  /// TMDB id for movie/tv; Seerr's person id for person.
  int get id;
  String get mediaType;

  static SeerrSearchResult? fromJson(Map<String, dynamic> json) {
    final type = json['mediaType'] as String?;
    return switch (type) {
      'movie' => SeerrMovieResult.fromJson(json),
      'tv' => SeerrTvResult.fromJson(json),
      'person' => SeerrPersonResult.fromJson(json),
      _ => null,
    };
  }
}

class SeerrMovieResult extends SeerrSearchResult {
  @override
  final int id;
  @override
  String get mediaType => 'movie';

  final String title;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final double voteAverage;
  final SeerrMediaInfo? mediaInfo;

  SeerrMovieResult({
    required this.id,
    required this.title,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.voteAverage = 0,
    this.mediaInfo,
  });

  factory SeerrMovieResult.fromJson(Map<String, dynamic> json) {
    final info = json['mediaInfo'];
    return SeerrMovieResult(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      overview: json['overview'] as String?,
      posterPath: json['posterPath'] as String?,
      backdropPath: json['backdropPath'] as String?,
      releaseDate: json['releaseDate'] as String?,
      voteAverage: (json['voteAverage'] as num?)?.toDouble() ?? 0,
      mediaInfo: info is Map<String, dynamic> ? SeerrMediaInfo.fromJson(info) : null,
    );
  }
}

class SeerrTvResult extends SeerrSearchResult {
  @override
  final int id;
  @override
  String get mediaType => 'tv';

  final String name;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? firstAirDate;
  final double voteAverage;
  final SeerrMediaInfo? mediaInfo;

  SeerrTvResult({
    required this.id,
    required this.name,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.firstAirDate,
    this.voteAverage = 0,
    this.mediaInfo,
  });

  factory SeerrTvResult.fromJson(Map<String, dynamic> json) {
    final info = json['mediaInfo'];
    return SeerrTvResult(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      overview: json['overview'] as String?,
      posterPath: json['posterPath'] as String?,
      backdropPath: json['backdropPath'] as String?,
      firstAirDate: json['firstAirDate'] as String?,
      voteAverage: (json['voteAverage'] as num?)?.toDouble() ?? 0,
      mediaInfo: info is Map<String, dynamic> ? SeerrMediaInfo.fromJson(info) : null,
    );
  }
}

class SeerrPersonResult extends SeerrSearchResult {
  @override
  final int id;
  @override
  String get mediaType => 'person';

  final String name;
  final String? profilePath;
  final double popularity;

  SeerrPersonResult({required this.id, required this.name, this.profilePath, this.popularity = 0});

  factory SeerrPersonResult.fromJson(Map<String, dynamic> json) {
    return SeerrPersonResult(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      profilePath: json['profilePath'] as String?,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0,
    );
  }
}

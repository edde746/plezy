import 'seerr_media_info.dart';

/// One genre tag.
class SeerrGenre {
  final int id;
  final String name;
  const SeerrGenre({required this.id, required this.name});

  factory SeerrGenre.fromJson(Map<String, dynamic> json) =>
      SeerrGenre(id: (json['id'] as num?)?.toInt() ?? 0, name: json['name'] as String? ?? '');
}

/// `/api/v1/movie/{tmdbId}` response — enough to render a detail page and
/// drive the request sheet.
class SeerrMovieDetails {
  final int id;
  final String? imdbId;
  final String title;
  final String originalTitle;
  final String? overview;
  final String? tagline;
  final String? releaseDate;
  final int? runtime;
  final String? posterPath;
  final String? backdropPath;
  final List<SeerrGenre> genres;
  final double voteAverage;
  final SeerrMediaInfo? mediaInfo;

  const SeerrMovieDetails({
    required this.id,
    this.imdbId,
    required this.title,
    required this.originalTitle,
    this.overview,
    this.tagline,
    this.releaseDate,
    this.runtime,
    this.posterPath,
    this.backdropPath,
    this.genres = const [],
    this.voteAverage = 0,
    this.mediaInfo,
  });

  factory SeerrMovieDetails.fromJson(Map<String, dynamic> json) {
    final rawGenres = json['genres'];
    final genres = <SeerrGenre>[];
    if (rawGenres is List) {
      for (final g in rawGenres) {
        if (g is Map<String, dynamic>) genres.add(SeerrGenre.fromJson(g));
      }
    }
    final info = json['mediaInfo'];
    return SeerrMovieDetails(
      id: (json['id'] as num).toInt(),
      imdbId: json['imdbId'] as String?,
      title: json['title'] as String? ?? '',
      originalTitle: json['originalTitle'] as String? ?? json['title'] as String? ?? '',
      overview: json['overview'] as String?,
      tagline: json['tagline'] as String?,
      releaseDate: json['releaseDate'] as String?,
      runtime: (json['runtime'] as num?)?.toInt(),
      posterPath: json['posterPath'] as String?,
      backdropPath: json['backdropPath'] as String?,
      genres: genres,
      voteAverage: (json['voteAverage'] as num?)?.toDouble() ?? 0,
      mediaInfo: info is Map<String, dynamic> ? SeerrMediaInfo.fromJson(info) : null,
    );
  }
}

import 'seerr_credits.dart';
import 'seerr_media_info.dart';
import 'seerr_movie_details.dart';

class SeerrSeason {
  final int seasonNumber;
  final int episodeCount;

  const SeerrSeason({
    required this.seasonNumber,
    required this.episodeCount,
  });

  factory SeerrSeason.fromJson(Map<String, dynamic> json) {
    return SeerrSeason(
      seasonNumber: (json['seasonNumber'] as num?)?.toInt() ?? 0,
      episodeCount: (json['episodeCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// `/api/v1/tv/{tmdbId}` response.
class SeerrTvDetails {
  final int id;
  final String name;
  final String originalName;
  final String? overview;
  final String? tagline;
  final String? firstAirDate;
  final String? lastAirDate;
  final int numberOfEpisodes;
  final int numberOfSeasons;
  final String? posterPath;
  final String? backdropPath;
  final List<SeerrGenre> genres;
  final List<SeerrSeason> seasons;
  final double voteAverage;
  final int voteCount;
  final SeerrCredits credits;
  final SeerrMediaInfo? mediaInfo;

  const SeerrTvDetails({
    required this.id,
    required this.name,
    required this.originalName,
    this.overview,
    this.tagline,
    this.firstAirDate,
    this.lastAirDate,
    this.numberOfEpisodes = 0,
    this.numberOfSeasons = 0,
    this.posterPath,
    this.backdropPath,
    this.genres = const [],
    this.seasons = const [],
    this.voteAverage = 0,
    this.voteCount = 0,
    this.credits = const SeerrCredits(),
    this.mediaInfo,
  });

  factory SeerrTvDetails.fromJson(Map<String, dynamic> json) {
    final rawGenres = json['genres'];
    final genres = <SeerrGenre>[];
    if (rawGenres is List) {
      for (final g in rawGenres) {
        if (g is Map<String, dynamic>) genres.add(SeerrGenre.fromJson(g));
      }
    }
    final rawSeasons = json['seasons'];
    final seasons = <SeerrSeason>[];
    if (rawSeasons is List) {
      for (final s in rawSeasons) {
        if (s is Map<String, dynamic>) {
          final season = SeerrSeason.fromJson(s);
          // Seerr returns season 0 (specials) which most users don't request;
          // surface them so the user can choose but list them last.
          seasons.add(season);
        }
      }
    }
    seasons.sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));
    final info = json['mediaInfo'];
    final rawCredits = json['credits'];
    return SeerrTvDetails(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      originalName: json['originalName'] as String? ?? json['name'] as String? ?? '',
      overview: json['overview'] as String?,
      tagline: json['tagline'] as String?,
      firstAirDate: json['firstAirDate'] as String?,
      lastAirDate: json['lastAirDate'] as String?,
      numberOfEpisodes: (json['numberOfEpisodes'] as num?)?.toInt() ?? 0,
      numberOfSeasons: (json['numberOfSeasons'] as num?)?.toInt() ?? 0,
      posterPath: json['posterPath'] as String?,
      backdropPath: json['backdropPath'] as String?,
      genres: genres,
      seasons: seasons,
      voteAverage: (json['voteAverage'] as num?)?.toDouble() ?? 0,
      voteCount: (json['voteCount'] as num?)?.toInt() ?? 0,
      credits: rawCredits is Map<String, dynamic> ? SeerrCredits.fromJson(rawCredits) : const SeerrCredits(),
      mediaInfo: info is Map<String, dynamic> ? SeerrMediaInfo.fromJson(info) : null,
    );
  }
}

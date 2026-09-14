import '../../utils/json_utils.dart';
import 'simkl_ids.dart';
import 'simkl_rating.dart';
import 'simkl_recommendation.dart';
import 'simkl_title.dart';

/// Rich movie, TV, or anime record returned by Simkl's detail endpoints.
class SimklDetail {
  final String? title;
  final int? year;
  final String? animeType;
  final String? originalTitle;
  final String? englishTitle;
  final List<String>? alternateTitles;
  final String? url;
  final String? poster;
  final String? fanart;
  final SimklIds ids;
  final int? rank;
  final String? dropRate;
  final String? released;
  final String? physicalRelease;
  final String? firstAired;
  final String? lastAired;
  final SimklAirs? airs;
  final int? runtime;
  final String? certification;
  final int? budget;
  final int? revenue;
  final String? overview;
  final List<String>? genres;
  final String? country;
  final String? language;
  final int? totalEpisodes;
  final String? status;
  final String? network;
  final String? director;
  final List<String>? studios;
  final String? seasonNameYear;
  final SimklRatings? ratings;
  final String? trailer;
  final List<SimklRecommendation> recommendations;

  const SimklDetail({
    this.title,
    this.year,
    this.animeType,
    this.originalTitle,
    this.englishTitle,
    this.alternateTitles,
    this.url,
    this.poster,
    this.fanart,
    required this.ids,
    this.rank,
    this.dropRate,
    this.released,
    this.physicalRelease,
    this.firstAired,
    this.lastAired,
    this.airs,
    this.runtime,
    this.certification,
    this.budget,
    this.revenue,
    this.overview,
    this.genres,
    this.country,
    this.language,
    this.totalEpisodes,
    this.status,
    this.network,
    this.director,
    this.studios,
    this.seasonNameYear,
    this.ratings,
    this.trailer,
    this.recommendations = const [],
  });

  factory SimklDetail.fromJson(Map<String, dynamic> json) => SimklDetail(
    title: json['title'] as String?,
    year: flexibleInt(json['year']),
    animeType: json['anime_type'] as String?,
    originalTitle: json['title_romaji'] as String?,
    englishTitle: json['en_title'] as String?,
    alternateTitles: simklTitleNames(json['alt_titles']),
    url: json['url'] as String?,
    poster: json['poster'] as String?,
    fanart: json['fanart'] as String?,
    ids: parseFlexibleJsonObject(json['ids'], SimklIds.fromJson) ?? const SimklIds(),
    rank: flexibleInt(json['rank']),
    dropRate: json['droprate']?.toString(),
    released: json['released'] as String?,
    physicalRelease: (json['released_dvd'] ?? json['dvd_date']) as String?,
    firstAired: json['first_aired'] as String?,
    lastAired: json['last_aired'] as String?,
    airs: parseFlexibleJsonObject(json['airs'], SimklAirs.fromJson),
    runtime: flexibleInt(json['runtime']),
    certification: json['certification'] as String?,
    budget: flexibleInt(json['budget']),
    revenue: flexibleInt(json['revenue']),
    overview: json['overview'] as String?,
    genres: flexibleStringList(json['genres']),
    country: json['country'] as String?,
    language: json['language'] as String?,
    totalEpisodes: flexibleInt(json['total_episodes']),
    status: json['status'] as String?,
    network: json['network'] as String?,
    director: json['director'] as String?,
    studios: simklTitleNames(json['studios']),
    seasonNameYear: json['season_name_year'] as String?,
    ratings: parseFlexibleJsonObject(json['ratings'], SimklRatings.fromJson),
    trailer: _firstTrailer(json['trailers']),
    recommendations: parseFlexibleJsonList(json['users_recommendations'], SimklRecommendation.fromJson),
  );

  static String? _firstTrailer(Object? raw) {
    for (final trailer in flexibleMapList(raw)) {
      final youtube = trailer['youtube'];
      if (youtube is String && youtube.trim().isNotEmpty) return youtube.trim();
    }
    return null;
  }
}

class SimklAirs {
  final String? day;
  final String? time;
  final String? timezone;

  const SimklAirs({this.day, this.time, this.timezone});

  factory SimklAirs.fromJson(Map<String, dynamic> json) =>
      SimklAirs(day: json['day'] as String?, time: json['time'] as String?, timezone: json['timezone'] as String?);
}

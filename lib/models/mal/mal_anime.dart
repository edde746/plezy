import 'package:json_annotation/json_annotation.dart';

import '../../utils/json_utils.dart';

part 'mal_anime.g.dart';

/// Poster art from MAL's `main_picture` field (absolute https URLs on
/// `api-cdn.myanimelist.net`). MAL serves no backdrop/fanart art.
@JsonSerializable(createToJson: false)
class MalPicture {
  final String? medium;
  final String? large;

  const MalPicture({this.medium, this.large});

  String? get primary {
    final largeUrl = large?.trim();
    if (largeUrl != null && largeUrl.isNotEmpty) return largeUrl;
    final mediumUrl = medium?.trim();
    return mediumUrl == null || mediumUrl.isEmpty ? null : mediumUrl;
  }

  factory MalPicture.fromJson(Map<String, dynamic> json) => _$MalPictureFromJson(json);
}

@JsonSerializable(createToJson: false)
class MalAlternativeTitles {
  final String? en;
  final String? ja;
  final List<String>? synonyms;

  const MalAlternativeTitles({this.en, this.ja, this.synonyms});

  factory MalAlternativeTitles.fromJson(Map<String, dynamic> json) => _$MalAlternativeTitlesFromJson(json);
}

@JsonSerializable(createToJson: false)
class MalGenre {
  final String? name;

  const MalGenre({this.name});

  factory MalGenre.fromJson(Map<String, dynamic> json) => _$MalGenreFromJson(json);
}

@JsonSerializable(createToJson: false)
class MalStudio {
  final String? name;

  const MalStudio({this.name});

  factory MalStudio.fromJson(Map<String, dynamic> json) => _$MalStudioFromJson(json);
}

@JsonSerializable(createToJson: false)
class MalStartSeason {
  @JsonKey(fromJson: flexibleInt)
  final int? year;
  final String? season;

  const MalStartSeason({this.year, this.season});

  factory MalStartSeason.fromJson(Map<String, dynamic> json) => _$MalStartSeasonFromJson(json);
}

@JsonSerializable(createFactory: false, createToJson: false)
class MalBroadcast {
  @JsonKey(name: 'day_of_the_week')
  final String? dayOfTheWeek;
  @JsonKey(name: 'start_time')
  final String? startTime;

  const MalBroadcast({this.dayOfTheWeek, this.startTime});

  factory MalBroadcast.fromJson(Map<String, dynamic> json) =>
      MalBroadcast(dayOfTheWeek: json['day_of_the_week'] as String?, startTime: json['start_time'] as String?);
}

/// An anime summary node from MAL API v2 catalog endpoints
/// (`/users/@me/animelist`, `/anime/suggestions`, `/anime/ranking`), with the
/// fields Plezy requests (see `MalClient.catalogFields`).
@JsonSerializable(createToJson: false)
class MalAnime {
  /// MAL's audience-rating strings mapped for display.
  static const Map<String, String> _certifications = {
    'g': 'G',
    'pg': 'PG',
    'pg_13': 'PG-13',
    'r': 'R',
    'r+': 'R+',
    'rx': 'Rx',
  };

  @JsonKey(fromJson: flexibleInt)
  final int? id;

  /// Default (romaji) title; [displayTitle] prefers the English one.
  final String? title;
  @JsonKey(name: 'main_picture')
  final MalPicture? mainPicture;
  @JsonKey(name: 'alternative_titles')
  final MalAlternativeTitles? alternativeTitles;

  /// `YYYY-MM-DD`, `YYYY-MM`, or `YYYY`.
  @JsonKey(name: 'start_date')
  final String? startDate;
  final String? synopsis;

  /// Community rating, 0–10.
  final double? mean;
  final List<MalGenre>? genres;

  /// `tv` / `movie` / `ova` / `ona` / `special` / `music` / ...
  @JsonKey(name: 'media_type')
  final String? mediaType;

  /// Audience rating: `g` / `pg` / `pg_13` / `r` / `r+` / `rx`.
  final String? rating;
  @JsonKey(name: 'num_episodes', fromJson: flexibleInt)
  final int? numEpisodes;

  /// Seconds per episode (total runtime for movies).
  @JsonKey(name: 'average_episode_duration', fromJson: flexibleInt)
  final int? averageEpisodeDuration;
  @JsonKey(name: 'start_season')
  final MalStartSeason? startSeason;

  /// `currently_airing` / `finished_airing` / `not_yet_aired`.
  final String? status;
  final List<MalStudio>? studios;
  @JsonKey(name: 'num_scoring_users', fromJson: flexibleInt)
  final int? numScoringUsers;

  final MalBroadcast? broadcast;
  @JsonKey(fromJson: flexibleInt)
  final int? popularity;
  @JsonKey(name: 'num_list_users', fromJson: flexibleInt)
  final int? numListUsers;

  /// MAL score rank, distinct from `/anime/ranking`'s entry-level leaderboard
  /// position.
  @JsonKey(fromJson: flexibleInt)
  final int? rank;

  /// `white` / `gray` / `black`.
  final String? nsfw;
  final String? source;
  @JsonKey(name: 'end_date')
  final String? endDate;

  const MalAnime({
    this.id,
    this.title,
    this.mainPicture,
    this.alternativeTitles,
    this.startDate,
    this.synopsis,
    this.mean,
    this.genres,
    this.mediaType,
    this.rating,
    this.numEpisodes,
    this.averageEpisodeDuration,
    this.startSeason,
    this.status,
    this.studios,
    this.numScoringUsers,
    this.broadcast,
    this.popularity,
    this.numListUsers,
    this.rank,
    this.nsfw,
    this.source,
    this.endDate,
  });

  bool get isMovie => mediaType == 'movie';

  /// English title when MAL has one, else the default (romaji) title. Media
  /// servers index by the English/agent title, so this is also what library
  /// matching searches for.
  String get displayTitle {
    final en = alternativeTitles?.en;
    if (en != null && en.isNotEmpty) return en;
    return title ?? '';
  }

  int? get year => startSeason?.year ?? _yearFromStartDate;

  int? get _yearFromStartDate {
    final date = startDate;
    if (date == null || date.length < 4) return null;
    return int.tryParse(date.substring(0, 4));
  }

  int? get runtimeMinutes {
    final seconds = averageEpisodeDuration;
    if (seconds == null || seconds <= 0) return null;
    return (seconds / 60).round();
  }

  String? get certification => _certifications[rating];

  List<String>? get genreNames {
    final names = [for (final genre in genres ?? const <MalGenre>[]) ?genre.name];
    return names.isEmpty ? null : names;
  }

  String? get primaryStudio {
    final name = studios?.firstOrNull?.name;
    return name == null || name.isEmpty ? null : name;
  }

  factory MalAnime.fromJson(Map<String, dynamic> json) => _$MalAnimeFromJson(json);
}

/// One community recommendation from an anime detail body.
class MalAnimeRecommendation {
  final MalAnime anime;
  final int? count;

  const MalAnimeRecommendation({required this.anime, this.count});

  static MalAnimeRecommendation? fromEntry(Object? raw) {
    if (raw is! Map) return null;
    final node = raw['node'];
    if (node is! Map) return null;
    return MalAnimeRecommendation(
      anime: MalAnime.fromJson(node.cast<String, dynamic>()),
      count: flexibleInt(raw['num_recommendations']),
    );
  }
}

/// One labelled franchise edge from an anime detail body.
class MalAnimeRelation {
  final MalAnime anime;
  final String? type;

  const MalAnimeRelation({required this.anime, this.type});

  static MalAnimeRelation? fromEntry(Object? raw) {
    if (raw is! Map) return null;
    final node = raw['node'];
    if (node is! Map) return null;
    final type = raw['relation_type'];
    return MalAnimeRelation(
      anime: MalAnime.fromJson(node.cast<String, dynamic>()),
      type: type is String && type.isNotEmpty ? type : null,
    );
  }
}

/// MAL list-status counts from an anime detail body.
class MalStatistics {
  final int? numListUsers;
  final int? watching;
  final int? completed;
  final int? onHold;
  final int? dropped;
  final int? planToWatch;

  const MalStatistics({this.numListUsers, this.watching, this.completed, this.onHold, this.dropped, this.planToWatch});

  factory MalStatistics.fromJson(Map<dynamic, dynamic> json) {
    final status = json['status'];
    final statuses = status is Map ? status : const <String, dynamic>{};
    return MalStatistics(
      numListUsers: flexibleInt(json['num_list_users']),
      watching: flexibleInt(statuses['watching']),
      completed: flexibleInt(statuses['completed']),
      onHold: flexibleInt(statuses['on_hold']),
      dropped: flexibleInt(statuses['dropped']),
      planToWatch: flexibleInt(statuses['plan_to_watch']),
    );
  }
}

/// The single `GET /anime/{id}` body used for detail enrichment,
/// recommendations and labelled franchise relations.
class MalAnimeDetail {
  final MalAnime anime;
  final List<MalAnimeRecommendation> recommendations;
  final List<MalAnimeRelation> relations;
  final MalStatistics? statistics;
  final List<MalPicture> pictures;
  final String? background;

  const MalAnimeDetail({
    required this.anime,
    this.recommendations = const [],
    this.relations = const [],
    this.statistics,
    this.pictures = const [],
    this.background,
  });

  factory MalAnimeDetail.fromJson(Map<String, dynamic> json, {int relatedLimit = 20}) {
    final recommendations = json['recommendations'];
    final relations = json['related_anime'];
    final statistics = json['statistics'];
    final pictures = json['pictures'];
    final rawBackground = json['background'];
    final background = rawBackground is String ? rawBackground.trim() : null;
    return MalAnimeDetail(
      anime: MalAnime.fromJson(json),
      recommendations: [
        if (recommendations is List)
          for (final raw in recommendations.take(relatedLimit)) ?MalAnimeRecommendation.fromEntry(raw),
      ],
      relations: [
        if (relations is List)
          for (final raw in relations.take(relatedLimit)) ?MalAnimeRelation.fromEntry(raw),
      ],
      statistics: statistics is Map ? MalStatistics.fromJson(statistics) : null,
      pictures: [
        if (pictures is List)
          for (final raw in pictures)
            if (raw is Map) MalPicture.fromJson(raw.cast<String, dynamic>()),
      ],
      background: background == null || background.isEmpty ? null : background,
    );
  }
}

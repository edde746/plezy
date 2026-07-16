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
    final url = large ?? medium;
    return url == null || url.isEmpty ? null : url;
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

  const MalStartSeason({this.year});

  factory MalStartSeason.fromJson(Map<String, dynamic> json) => _$MalStartSeasonFromJson(json);
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

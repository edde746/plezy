// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mal_anime.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MalPicture _$MalPictureFromJson(Map<String, dynamic> json) => MalPicture(
  medium: json['medium'] as String?,
  large: json['large'] as String?,
);

MalAlternativeTitles _$MalAlternativeTitlesFromJson(
  Map<String, dynamic> json,
) => MalAlternativeTitles(
  en: json['en'] as String?,
  ja: json['ja'] as String?,
  synonyms: (json['synonyms'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

MalGenre _$MalGenreFromJson(Map<String, dynamic> json) =>
    MalGenre(name: json['name'] as String?);

MalStudio _$MalStudioFromJson(Map<String, dynamic> json) =>
    MalStudio(name: json['name'] as String?);

MalStartSeason _$MalStartSeasonFromJson(Map<String, dynamic> json) =>
    MalStartSeason(year: flexibleInt(json['year']));

MalAnime _$MalAnimeFromJson(Map<String, dynamic> json) => MalAnime(
  id: flexibleInt(json['id']),
  title: json['title'] as String?,
  mainPicture: json['main_picture'] == null
      ? null
      : MalPicture.fromJson(json['main_picture'] as Map<String, dynamic>),
  alternativeTitles: json['alternative_titles'] == null
      ? null
      : MalAlternativeTitles.fromJson(
          json['alternative_titles'] as Map<String, dynamic>,
        ),
  startDate: json['start_date'] as String?,
  synopsis: json['synopsis'] as String?,
  mean: (json['mean'] as num?)?.toDouble(),
  genres: (json['genres'] as List<dynamic>?)
      ?.map((e) => MalGenre.fromJson(e as Map<String, dynamic>))
      .toList(),
  mediaType: json['media_type'] as String?,
  rating: json['rating'] as String?,
  numEpisodes: flexibleInt(json['num_episodes']),
  averageEpisodeDuration: flexibleInt(json['average_episode_duration']),
  startSeason: json['start_season'] == null
      ? null
      : MalStartSeason.fromJson(json['start_season'] as Map<String, dynamic>),
  status: json['status'] as String?,
  studios: (json['studios'] as List<dynamic>?)
      ?.map((e) => MalStudio.fromJson(e as Map<String, dynamic>))
      .toList(),
  numScoringUsers: flexibleInt(json['num_scoring_users']),
);

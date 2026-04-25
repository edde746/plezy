// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plex_user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlexUserProfile _$PlexUserProfileFromJson(
  Map<String, dynamic> json,
) => PlexUserProfile(
  autoSelectAudio: json['autoSelectAudio'] as bool? ?? true,
  defaultAudioAccessibility:
      (json['defaultAudioAccessibility'] as num?)?.toInt() ?? 0,
  defaultAudioLanguage: json['defaultAudioLanguage'] as String?,
  defaultAudioLanguages: (json['defaultAudioLanguages'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  defaultSubtitleLanguage: json['defaultSubtitleLanguage'] as String?,
  defaultSubtitleLanguages: (json['defaultSubtitleLanguages'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  autoSelectSubtitle: (json['autoSelectSubtitle'] as num?)?.toInt() ?? 0,
  defaultSubtitleAccessibility:
      (json['defaultSubtitleAccessibility'] as num?)?.toInt() ?? 0,
  defaultSubtitleForced: (json['defaultSubtitleForced'] as num?)?.toInt() ?? 1,
  watchedIndicator: (json['watchedIndicator'] as num?)?.toInt() ?? 1,
  mediaReviewsVisibility:
      (json['mediaReviewsVisibility'] as num?)?.toInt() ?? 0,
  mediaReviewsLanguages: (json['mediaReviewsLanguages'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$PlexUserProfileToJson(PlexUserProfile instance) =>
    <String, dynamic>{
      'autoSelectAudio': instance.autoSelectAudio,
      'defaultAudioAccessibility': instance.defaultAudioAccessibility,
      'defaultAudioLanguage': instance.defaultAudioLanguage,
      'defaultAudioLanguages': instance.defaultAudioLanguages,
      'defaultSubtitleLanguage': instance.defaultSubtitleLanguage,
      'defaultSubtitleLanguages': instance.defaultSubtitleLanguages,
      'autoSelectSubtitle': instance.autoSelectSubtitle,
      'defaultSubtitleAccessibility': instance.defaultSubtitleAccessibility,
      'defaultSubtitleForced': instance.defaultSubtitleForced,
      'watchedIndicator': instance.watchedIndicator,
      'mediaReviewsVisibility': instance.mediaReviewsVisibility,
      'mediaReviewsLanguages': instance.mediaReviewsLanguages,
    };

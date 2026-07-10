// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plex_user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlexUserProfile _$PlexUserProfileFromJson(
  Map<String, dynamic> json,
) => PlexUserProfile(
  autoSelectAudio: _boolOrTrue(json['autoSelectAudio']),
  defaultAudioAccessibility: _intOr0(json['defaultAudioAccessibility']),
  defaultAudioLanguage: _flexibleLanguage(json['defaultAudioLanguage']),
  defaultAudioLanguages: flexibleCsvStringList(json['defaultAudioLanguages']),
  defaultSubtitleLanguage: _flexibleLanguage(json['defaultSubtitleLanguage']),
  defaultSubtitleLanguages: flexibleCsvStringList(
    json['defaultSubtitleLanguages'],
  ),
  autoSelectSubtitle: _intOr0(json['autoSelectSubtitle']),
  defaultSubtitleAccessibility: _intOr0(json['defaultSubtitleAccessibility']),
  defaultSubtitleForced: _intOr1(json['defaultSubtitleForced']),
  watchedIndicator: _intOr1(json['watchedIndicator']),
  mediaReviewsVisibility: _intOr0(json['mediaReviewsVisibility']),
  mediaReviewsLanguages: flexibleCsvStringList(json['mediaReviewsLanguages']),
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

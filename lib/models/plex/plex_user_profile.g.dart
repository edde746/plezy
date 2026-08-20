// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plex_user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlexUserProfile _$PlexUserProfileFromJson(
  Map<String, dynamic> json,
) => PlexUserProfile(
  autoSelectAudio: _boolOrTrue(json['autoSelectAudio']),
  defaultAudioLanguage: _flexibleLanguage(json['defaultAudioLanguage']),
  defaultAudioLanguages: flexibleCsvStringList(json['defaultAudioLanguages']),
  defaultSubtitleLanguage: _flexibleLanguage(json['defaultSubtitleLanguage']),
  defaultSubtitleLanguages: flexibleCsvStringList(
    json['defaultSubtitleLanguages'],
  ),
);

Map<String, dynamic> _$PlexUserProfileToJson(PlexUserProfile instance) =>
    <String, dynamic>{
      'autoSelectAudio': instance.autoSelectAudio,
      'defaultAudioLanguage': instance.defaultAudioLanguage,
      'defaultAudioLanguages': instance.defaultAudioLanguages,
      'defaultSubtitleLanguage': instance.defaultSubtitleLanguage,
      'defaultSubtitleLanguages': instance.defaultSubtitleLanguages,
    };

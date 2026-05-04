// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'livetv_lineup.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LiveTvCountry _$LiveTvCountryFromJson(Map<String, dynamic> json) => LiveTvCountry(
  key: json['key'] as String?,
  type: json['type'] as String?,
  title: json['title'] as String? ?? '',
  code: json['code'] as String? ?? '',
  language: json['language'] as String?,
  languageTitle: json['languageTitle'] as String?,
  example: json['example'] as String?,
  flavor: flexibleInt(json['flavor']),
);

LiveTvLanguage _$LiveTvLanguageFromJson(Map<String, dynamic> json) =>
    LiveTvLanguage(code: json['code'] as String? ?? '', title: json['title'] as String? ?? '');

LiveTvRegion _$LiveTvRegionFromJson(Map<String, dynamic> json) => LiveTvRegion(
  key: json['key'] as String? ?? '',
  type: json['type'] as String?,
  title: json['title'] as String? ?? '',
);

LiveTvLineup _$LiveTvLineupFromJson(Map<String, dynamic> json) => LiveTvLineup(
  uuid: json['uuid'] as String? ?? '',
  type: json['type'] as String?,
  title: json['title'] as String?,
  lineupType: flexibleInt(json['lineupType']),
  location: json['location'] as String?,
  channels: json['Channel'] == null ? const [] : _parseChannels(json['Channel']),
);

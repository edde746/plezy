// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plex_subtitle_search_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlexSubtitleSearchResult _$PlexSubtitleSearchResultFromJson(
  Map<String, dynamic> json,
) => PlexSubtitleSearchResult(
  id: _flexibleIntOrZero(json['id']),
  key: readStringField(json, 'key') as String? ?? '',
  codec: readStringField(json, 'codec') as String?,
  language: readStringField(json, 'language') as String?,
  languageCode: readStringField(json, 'languageCode') as String?,
  score: flexibleDouble(json['score']),
  providerTitle: readStringField(json, 'providerTitle') as String?,
  title: readStringField(json, 'title') as String?,
  displayTitle: readStringField(json, 'displayTitle') as String?,
  hearingImpaired: json['hearingImpaired'] == null
      ? false
      : flexibleBool(json['hearingImpaired']),
  perfectMatch: json['perfectMatch'] == null
      ? false
      : flexibleBool(json['perfectMatch']),
  downloaded: json['downloaded'] == null
      ? false
      : flexibleBool(json['downloaded']),
  forced: json['forced'] == null ? false : flexibleBool(json['forced']),
);

Map<String, dynamic> _$PlexSubtitleSearchResultToJson(
  PlexSubtitleSearchResult instance,
) => <String, dynamic>{
  'id': instance.id,
  'key': instance.key,
  'codec': instance.codec,
  'language': instance.language,
  'languageCode': instance.languageCode,
  'score': instance.score,
  'providerTitle': instance.providerTitle,
  'title': instance.title,
  'displayTitle': instance.displayTitle,
  'hearingImpaired': instance.hearingImpaired,
  'perfectMatch': instance.perfectMatch,
  'downloaded': instance.downloaded,
  'forced': instance.forced,
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subtitle_search_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubtitleSearchResult _$SubtitleSearchResultFromJson(Map<String, dynamic> json) => SubtitleSearchResult(
  id: flexibleIntOrZero(json['id']),
  key: readStringField(json, 'key') as String? ?? '',
  codec: readStringField(json, 'codec') as String?,
  language: readStringField(json, 'language') as String?,
  languageCode: readStringField(json, 'languageCode') as String?,
  score: flexibleDouble(json['score']),
  providerTitle: readStringField(json, 'providerTitle') as String?,
  title: readStringField(json, 'title') as String?,
  displayTitle: readStringField(json, 'displayTitle') as String?,
  hearingImpaired: flexibleBool(json['hearingImpaired']),
  perfectMatch: flexibleBool(json['perfectMatch']),
  downloaded: flexibleBool(json['downloaded']),
  forced: flexibleBool(json['forced']),
);

Map<String, dynamic> _$SubtitleSearchResultToJson(SubtitleSearchResult instance) => <String, dynamic>{
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

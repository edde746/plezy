// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plex_match_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlexMatchResult _$PlexMatchResultFromJson(Map<String, dynamic> json) =>
    PlexMatchResult(
      guid: readStringField(json, 'guid') as String? ?? '',
      name: readStringField(json, 'name') as String? ?? '',
      year: flexibleInt(json['year']),
      score: flexibleInt(json['score']),
      thumb: readStringField(json, 'thumb') as String?,
      summary: readStringField(json, 'summary') as String?,
      type: readStringField(json, 'type') as String?,
      matched: json['matched'] == null ? false : flexibleBool(json['matched']),
    );

Map<String, dynamic> _$PlexMatchResultToJson(PlexMatchResult instance) =>
    <String, dynamic>{
      'guid': instance.guid,
      'name': instance.name,
      'year': instance.year,
      'score': instance.score,
      'thumb': instance.thumb,
      'summary': instance.summary,
      'type': instance.type,
      'matched': instance.matched,
    };

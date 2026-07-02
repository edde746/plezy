// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_rooms_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecentRoom _$RecentRoomFromJson(Map<String, dynamic> json) => RecentRoom(
  code: json['code'] as String,
  name: json['name'] as String?,
  lastUsed: _dateTimeFromMillis((json['lastUsed'] as num).toInt()),
  controlMode: _controlModeFromIndex((json['controlMode'] as num?)?.toInt()),
);

Map<String, dynamic> _$RecentRoomToJson(RecentRoom instance) => <String, dynamic>{
  'code': instance.code,
  'name': ?instance.name,
  'lastUsed': _dateTimeToMillis(instance.lastUsed),
  'controlMode': ?_controlModeToIndex(instance.controlMode),
};

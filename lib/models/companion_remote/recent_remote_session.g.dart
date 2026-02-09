// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_remote_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecentRemoteSession _$RecentRemoteSessionFromJson(Map<String, dynamic> json) => RecentRemoteSession(
  sessionId: json['sessionId'] as String,
  pin: json['pin'] as String,
  deviceName: json['deviceName'] as String,
  platform: json['platform'] as String,
  lastConnected: DateTime.parse(json['lastConnected'] as String),
);

Map<String, dynamic> _$RecentRemoteSessionToJson(RecentRemoteSession instance) => <String, dynamic>{
  'sessionId': instance.sessionId,
  'pin': instance.pin,
  'deviceName': instance.deviceName,
  'platform': instance.platform,
  'lastConnected': instance.lastConnected.toIso8601String(),
};

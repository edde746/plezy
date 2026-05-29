// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mal_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MalSession _$MalSessionFromJson(Map<String, dynamic> json) => MalSession(
  accessToken: json['access_token'] as String,
  refreshToken: json['refresh_token'] as String,
  expiresAt: (json['expires_at'] as num).toInt(),
  createdAt: (json['created_at'] as num).toInt(),
  username: json['username'] as String?,
);

Map<String, dynamic> _$MalSessionToJson(MalSession instance) => <String, dynamic>{
  'access_token': instance.accessToken,
  'refresh_token': instance.refreshToken,
  'expires_at': instance.expiresAt,
  'username': instance.username,
  'created_at': instance.createdAt,
};

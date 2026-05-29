// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trakt_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TraktSession _$TraktSessionFromJson(Map<String, dynamic> json) => TraktSession(
  accessToken: json['access_token'] as String,
  refreshToken: json['refresh_token'] as String,
  expiresAt: (json['expires_at'] as num).toInt(),
  scope: json['scope'] as String? ?? 'public',
  createdAt: (json['created_at'] as num).toInt(),
  username: json['username'] as String?,
);

Map<String, dynamic> _$TraktSessionToJson(TraktSession instance) => <String, dynamic>{
  'access_token': instance.accessToken,
  'refresh_token': instance.refreshToken,
  'expires_at': instance.expiresAt,
  'username': instance.username,
  'scope': instance.scope,
  'created_at': instance.createdAt,
};

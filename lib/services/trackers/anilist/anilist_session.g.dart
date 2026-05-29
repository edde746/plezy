// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anilist_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnilistSession _$AnilistSessionFromJson(Map<String, dynamic> json) => AnilistSession(
  accessToken: json['access_token'] as String,
  expiresAt: (json['expires_at'] as num).toInt(),
  createdAt: (json['created_at'] as num).toInt(),
  username: json['username'] as String?,
);

Map<String, dynamic> _$AnilistSessionToJson(AnilistSession instance) => <String, dynamic>{
  'access_token': instance.accessToken,
  'expires_at': instance.expiresAt,
  'username': instance.username,
  'created_at': instance.createdAt,
};

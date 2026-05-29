// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simkl_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SimklSession _$SimklSessionFromJson(Map<String, dynamic> json) => SimklSession(
  accessToken: json['access_token'] as String,
  createdAt: (json['created_at'] as num).toInt(),
  username: json['username'] as String?,
);

Map<String, dynamic> _$SimklSessionToJson(SimklSession instance) => <String, dynamic>{
  'access_token': instance.accessToken,
  'username': instance.username,
  'created_at': instance.createdAt,
};

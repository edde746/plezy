// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seerr_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SeerrUser _$SeerrUserFromJson(Map<String, dynamic> json) => SeerrUser(
  id: (json['id'] as num).toInt(),
  displayName: json['displayName'] as String?,
  email: json['email'] as String?,
  permissions: (json['permissions'] as num?)?.toInt(),
  avatar: json['avatar'] as String?,
);

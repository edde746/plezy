// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seerr_public_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SeerrPublicSettings _$SeerrPublicSettingsFromJson(Map<String, dynamic> json) =>
    SeerrPublicSettings(
      initialized: json['initialized'] as bool? ?? false,
      applicationTitle: json['applicationTitle'] as String?,
      localLogin: json['localLogin'] as bool? ?? true,
      mediaServerLogin: json['mediaServerLogin'] as bool? ?? true,
      mediaServerType: (json['mediaServerType'] as num?)?.toInt(),
      movie4kEnabled: json['movie4kEnabled'] as bool? ?? false,
      series4kEnabled: json['series4kEnabled'] as bool? ?? false,
      partialRequestsEnabled: json['partialRequestsEnabled'] as bool? ?? true,
    );

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plex_activity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlexActivity _$PlexActivityFromJson(Map<String, dynamic> json) => PlexActivity(
  uuid: json['uuid'] as String? ?? '',
  type: json['type'] as String? ?? '',
  title: json['title'] as String? ?? '',
  subtitle: json['subtitle'] as String?,
  progress: (json['progress'] as num?)?.toInt() ?? 0,
  cancellable: json['cancellable'] as bool? ?? false,
);

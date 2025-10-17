// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_container.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaContainer<T> _$MediaContainerFromJson<T>(Map<String, dynamic> json) =>
    MediaContainer<T>(
      size: (json['size'] as num?)?.toInt(),
      totalSize: (json['totalSize'] as num?)?.toInt(),
      offset: (json['offset'] as num?)?.toInt(),
      identifier: json['identifier'] as String?,
      directories: (json['Directory'] as List<dynamic>?)
          ?.map((e) => PlexLibrary.fromJson(e as Map<String, dynamic>))
          .toList(),
      metadata: (json['Metadata'] as List<dynamic>?)
          ?.map((e) => PlexMetadata.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MediaContainerToJson<T>(MediaContainer<T> instance) =>
    <String, dynamic>{
      'size': instance.size,
      'totalSize': instance.totalSize,
      'offset': instance.offset,
      'identifier': instance.identifier,
      'Directory': instance.directories,
      'Metadata': instance.metadata,
    };

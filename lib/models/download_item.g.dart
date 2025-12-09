// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DownloadItem _$DownloadItemFromJson(Map<String, dynamic> json) => DownloadItem(
  id: json['id'] as String,
  metadata: PlexMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
  downloadUrl: json['downloadUrl'] as String?,
  localPath: json['localPath'] as String?,
  title: json['title'] as String?,
  status:
      $enumDecodeNullable(_$DownloadStatusEnumMap, json['status']) ??
      DownloadStatus.pending,
  progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
  error: json['error'] as String?,
);

Map<String, dynamic> _$DownloadItemToJson(DownloadItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'metadata': instance.metadata,
      'downloadUrl': instance.downloadUrl,
      'title': instance.title,
      'localPath': instance.localPath,
      'status': _$DownloadStatusEnumMap[instance.status]!,
      'progress': instance.progress,
      'error': instance.error,
    };

const _$DownloadStatusEnumMap = {
  DownloadStatus.pending: 'pending',
  DownloadStatus.downloading: 'downloading',
  DownloadStatus.completed: 'completed',
  DownloadStatus.failed: 'failed',
  DownloadStatus.canceled: 'canceled',
  DownloadStatus.paused: 'paused',
};

import 'package:json_annotation/json_annotation.dart';
import 'plex_metadata.dart';

part 'download_item.g.dart';

enum DownloadStatus {
  pending,
  downloading,
  completed,
  failed,
  canceled,
  paused,
}

@JsonSerializable()
class DownloadItem {
  final String id; // usually metadata.ratingKey
  final PlexMetadata metadata;
  final String? downloadUrl;
  final String? title;

  /// Path relative to application documents directory, or absolute path
  String? localPath;

  DownloadStatus status;

  double progress; // 0.0 to 1.0

  String? error;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final int downloadSpeed; // bytes per second

  DownloadItem({
    required this.id,
    required this.metadata,
    this.downloadUrl,
    this.localPath,
    this.title,
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
    this.downloadSpeed = 0,
    this.error,
  });

  factory DownloadItem.fromJson(Map<String, dynamic> json) =>
      _$DownloadItemFromJson(json);
  Map<String, dynamic> toJson() => _$DownloadItemToJson(this);

  DownloadItem copyWith({
    String? id,
    PlexMetadata? metadata,
    String? downloadUrl,
    String? localPath,
    String? title,
    DownloadStatus? status,
    double? progress,
    int? downloadSpeed,
    String? error,
  }) {
    return DownloadItem(
      id: id ?? this.id,
      metadata: metadata ?? this.metadata,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      localPath: localPath ?? this.localPath,
      title: title ?? this.title,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      error: error ?? this.error,
    );
  }
}

// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

import '../utils/formatters.dart';

part 'download_models.freezed.dart';

enum DownloadStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
  partial, // Some episodes downloaded, but not all (for shows/seasons)
}

@freezed
sealed class DownloadProgress with _$DownloadProgress {
  const DownloadProgress._();

  const factory DownloadProgress({
    required String globalKey,
    required DownloadStatus status,
    @Default(0) int progress,
    @Default(0) int downloadedBytes,
    @Default(0) int totalBytes,
    @Default(0.0) double speed,
    String? errorMessage,
    String? currentFile,
    String? thumbPath,
    // Whether the native download task is actively transferring (received
    // `TaskStatus.running`), as opposed to being enqueued and held in the
    // download queue. Held items read as "Queued" even though they carry a
    // downloading status. Transient — never persisted.
    @Default(false) bool running,
  }) = _DownloadProgress;

  double get progressPercent => progress / 100.0;

  /// Ring/bar value for status indicators, or null to render an indeterminate
  /// "downloading" state. A server-transcoded download reports no total size,
  /// so its byte progress never advances — surfacing a frozen 0% would look
  /// stuck. Only nulls out while downloading with an unknown total AND no
  /// percentage yet (a live transcode); an aggregate or any download that
  /// reports a percent keeps its determinate value.
  double? get determinateProgress =>
      status == DownloadStatus.downloading && totalBytes <= 0 && progress <= 0 ? null : progressPercent;

  /// The status to render in the UI. A download enqueued but held in the queue
  /// (its native task hasn't started, so [running] is false) still carries a
  /// `downloading` status; everywhere it must read as "Queued". Centralizes the
  /// rule so every surface (action button, episode card, …) stays consistent.
  DownloadStatus get displayStatus => status == DownloadStatus.downloading && !running ? DownloadStatus.queued : status;

  String get speedFormatted => ByteFormatter.formatSpeed(speed);
  String get downloadedFormatted => ByteFormatter.formatBytes(downloadedBytes);
  String get totalFormatted => ByteFormatter.formatBytes(totalBytes);

  bool get hasArtworkPaths => thumbPath != null;
}

@freezed
sealed class DeletionProgress with _$DeletionProgress {
  const DeletionProgress._();

  const factory DeletionProgress({
    required String globalKey,
    required String itemTitle,
    required int currentItem,
    required int totalItems,
    String? currentOperation,
  }) = _DeletionProgress;

  double get progressPercent => totalItems > 0 ? (currentItem / totalItems) : 0.0;

  int get progressPercentInt => (progressPercent * 100).round();

  bool get isComplete => currentItem >= totalItems;
}

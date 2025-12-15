import '../utils/formatters.dart';

enum DownloadStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
  partial, // Some episodes downloaded, but not all (for shows/seasons)
}

class DownloadProgress {
  final String globalKey;
  final DownloadStatus status;
  final int progress; // 0-100
  final int downloadedBytes;
  final int totalBytes;
  final double speed; // bytes per second
  final String? errorMessage;
  final String?
  currentFile; // What's being downloaded (video, subtitles, artwork)

  // Thumbnail path (populated after artwork download completes)
  final String? thumbPath;

  const DownloadProgress({
    required this.globalKey,
    required this.status,
    this.progress = 0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.speed = 0,
    this.errorMessage,
    this.currentFile,
    this.thumbPath,
  });

  double get progressPercent => progress / 100.0;

  String get speedFormatted => ByteFormatter.formatSpeed(speed);
  String get downloadedFormatted => ByteFormatter.formatBytes(downloadedBytes);
  String get totalFormatted => ByteFormatter.formatBytes(totalBytes);

  Duration? get estimatedTimeRemaining {
    if (speed <= 0 || totalBytes <= 0) return null;
    final remainingBytes = totalBytes - downloadedBytes;
    if (remainingBytes <= 0) return Duration.zero;
    return Duration(seconds: (remainingBytes / speed).round());
  }

  /// Check if this progress update includes artwork paths
  bool get hasArtworkPaths => thumbPath != null;

  DownloadProgress copyWith({
    String? globalKey,
    DownloadStatus? status,
    int? progress,
    int? downloadedBytes,
    int? totalBytes,
    double? speed,
    String? errorMessage,
    String? currentFile,
    String? thumbPath,
  }) {
    return DownloadProgress(
      globalKey: globalKey ?? this.globalKey,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      speed: speed ?? this.speed,
      errorMessage: errorMessage ?? this.errorMessage,
      currentFile: currentFile ?? this.currentFile,
      thumbPath: thumbPath ?? this.thumbPath,
    );
  }
}

class DeletionProgress {
  final String globalKey;
  final String itemTitle;
  final int currentItem;
  final int totalItems;
  final String? currentOperation;

  const DeletionProgress({
    required this.globalKey,
    required this.itemTitle,
    required this.currentItem,
    required this.totalItems,
    this.currentOperation,
  });

  double get progressPercent =>
      totalItems > 0 ? (currentItem / totalItems) : 0.0;

  int get progressPercentInt => (progressPercent * 100).round();

  bool get isComplete => currentItem >= totalItems;

  DeletionProgress copyWith({
    String? globalKey,
    String? itemTitle,
    int? currentItem,
    int? totalItems,
    String? currentOperation,
  }) {
    return DeletionProgress(
      globalKey: globalKey ?? this.globalKey,
      itemTitle: itemTitle ?? this.itemTitle,
      currentItem: currentItem ?? this.currentItem,
      totalItems: totalItems ?? this.totalItems,
      currentOperation: currentOperation ?? this.currentOperation,
    );
  }

  @override
  String toString() {
    return 'DeletionProgress(globalKey: $globalKey, itemTitle: $itemTitle, '
        'currentItem: $currentItem, totalItems: $totalItems, '
        'progressPercent: $progressPercentInt%)';
  }
}

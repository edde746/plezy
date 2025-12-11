import 'download_status.dart';

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

  String get speedFormatted {
    if (speed < 1024) return '${speed.toStringAsFixed(0)} B/s';
    if (speed < 1024 * 1024) return '${(speed / 1024).toStringAsFixed(1)} KB/s';
    return '${(speed / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  String get downloadedFormatted => _formatBytes(downloadedBytes);
  String get totalFormatted => _formatBytes(totalBytes);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

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

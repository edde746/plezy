part of '../clip_export_service.dart';

const Duration clipDefaultLookback = Duration(seconds: 30);
const Duration clipMinimumDuration = Duration(seconds: 1);
const Duration clipTrimWindowBefore = Duration(minutes: 3);
const Duration clipTrimWindowAfter = Duration(minutes: 1);

class ClipSource {
  final String uri;
  final Map<String, String> headers;
  final bool isTranscoding;
  final Duration timelineOffset;
  final Duration duration;
  final String title;
  final String? subtitle;
  final String? container;
  final MediaDisplayCriteria? displayCriteria;

  const ClipSource({
    required this.uri,
    this.headers = const {},
    required this.isTranscoding,
    this.timelineOffset = Duration.zero,
    required this.duration,
    required this.title,
    this.subtitle,
    this.container,
    this.displayCriteria,
  });

  MediaDisplayColorType get colorType => displayCriteria?.colorType ?? MediaDisplayColorType.unknown;

  bool get canEncodeHdr =>
      !isTranscoding && (colorType == MediaDisplayColorType.pq || colorType == MediaDisplayColorType.hlg);
}

class ClipSelection {
  final Duration start;
  final Duration end;

  const ClipSelection({required this.start, required this.end});

  Duration get duration => end - start;

  ClipSelection clampedTo(Duration sourceDuration) {
    final safeDuration = sourceDuration <= Duration.zero ? end : sourceDuration;
    final clampedStart = _clampDuration(start, Duration.zero, safeDuration);
    final clampedEnd = _clampDuration(end, clampedStart, safeDuration);
    return ClipSelection(start: clampedStart, end: clampedEnd);
  }

  void validate(Duration sourceDuration) {
    if (start < Duration.zero) {
      throw ClipExportException(t.videoControls.clip.startBeforeBeginning);
    }
    if (end <= start) {
      throw ClipExportException(t.videoControls.clip.endAfterStart);
    }
    if (duration < clipMinimumDuration) {
      throw ClipExportException(t.videoControls.clip.minimumDuration);
    }
    if (sourceDuration > Duration.zero && end > sourceDuration) {
      throw ClipExportException(t.videoControls.clip.endPastVideo);
    }
  }
}

enum ClipExportStage { idle, running, completed, failed, canceled }

enum ClipExportFormat { hevcSdr, h264Sdr, hevcHdr, source }

class ClipExportJobState {
  final ClipExportStage stage;
  final double? progress;

  const ClipExportJobState({required this.stage, this.progress});

  const ClipExportJobState.idle() : this(stage: ClipExportStage.idle);
}

class ClipExportException implements Exception {
  final String message;

  const ClipExportException(this.message);

  @override
  String toString() => message;
}

Duration _clampDuration(Duration value, Duration min, Duration max) {
  if (value < min) return min;
  if (value > max) return max;
  return value;
}

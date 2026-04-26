import 'package:flutter/widgets.dart';

import '../i18n/strings.g.dart';
import '../models/transcode_quality_preset.dart';
import 'dialogs.dart';
import 'formatters.dart';

const int _audioBitrateEstimateKbps = 192;

/// User-facing label for a quality preset.
///
/// Examples:
/// - [TranscodeQualityPreset.original] → "Original"
/// - [TranscodeQualityPreset.p720_2mbps] → "720p 2 Mbps"
/// - [TranscodeQualityPreset.p480_1_5mbps] → "480p 1.5 Mbps"
String qualityPresetLabel(TranscodeQualityPreset preset) {
  if (preset.isOriginal) return t.videoControls.qualityOriginal;
  final height = preset.resolutionHeight?.toString() ?? '';
  final bitrate = _formatBitrate(preset.videoBitrateKbps!);
  return t.videoControls.qualityPresetLabel(resolution: height, bitrate: bitrate);
}

String _formatBitrate(int kbps) {
  final mbps = kbps / 1000.0;
  if (mbps >= 10) return mbps.toStringAsFixed(0);
  if (mbps == mbps.roundToDouble()) return mbps.toStringAsFixed(0);
  return mbps.toStringAsFixed(1);
}

/// File-size hint for a quality row, e.g. `3.6 GB (45%)`. Transcode presets
/// append the ratio vs. source so the user can compare at a glance; Original
/// returns the raw source size. Prefers [sourceSizeBytes] when known (the
/// actual file size, matches what File Info shows) and falls back to
/// `bitrate × duration` when only bitrate is available. Returns `null`
/// when inputs are missing.
String? qualityPresetSizeEstimate({
  required TranscodeQualityPreset preset,
  required int? sourceBitrateKbps,
  required int? sourceDurationMs,
  int? sourceSizeBytes,
}) {
  if (preset.isOriginal) {
    if (sourceSizeBytes != null && sourceSizeBytes > 0) {
      return ByteFormatter.formatBytes(sourceSizeBytes);
    }
    if (sourceDurationMs == null || sourceDurationMs <= 0) return null;
    if (sourceBitrateKbps == null || sourceBitrateKbps <= 0) return null;
    return ByteFormatter.formatBytes(sourceBitrateKbps * sourceDurationMs ~/ 8);
  }

  if (sourceDurationMs == null || sourceDurationMs <= 0) return null;
  final videoKbps = preset.videoBitrateKbps;
  if (videoKbps == null) return null;
  final totalKbps = videoKbps + _audioBitrateEstimateKbps;
  final estimatedBytes = totalKbps * sourceDurationMs ~/ 8;
  final size = ByteFormatter.formatBytes(estimatedBytes);

  // Percentage compares estimated transcode size to the same source figure
  // the "Original" row displays — the real file size when known, otherwise
  // the bitrate × duration estimate. Mixing the two bases (real file size
  // vs. bitrate-based estimate) was causing visible mismatches.
  int? sourceBytes;
  if (sourceSizeBytes != null && sourceSizeBytes > 0) {
    sourceBytes = sourceSizeBytes;
  } else if (sourceBitrateKbps != null && sourceBitrateKbps > 0) {
    sourceBytes = sourceBitrateKbps * sourceDurationMs ~/ 8;
  }
  if (sourceBytes != null && sourceBytes > 0) {
    final pct = (estimatedBytes * 100 / sourceBytes).round();
    return '$size ($pct%)';
  }
  return size;
}

/// Quality-preset picker dialog — shares [TranscodeQualityPreset.displayOrder]
/// with the in-player sheet. Returns the selected preset, or `null` if dismissed.
Future<TranscodeQualityPreset?> showQualityPickerDialog(
  BuildContext context, {
  String? title,
  int? sourceBitrateKbps,
  int? sourceDurationMs,
  int? sourceSizeBytes,
}) {
  String labelFor(TranscodeQualityPreset p) {
    final base = qualityPresetLabel(p);
    final size = qualityPresetSizeEstimate(
      preset: p,
      sourceBitrateKbps: sourceBitrateKbps,
      sourceDurationMs: sourceDurationMs,
      sourceSizeBytes: sourceSizeBytes,
    );
    return size == null ? base : toBulletedString([base, size]);
  }

  return showOptionPickerDialog<TranscodeQualityPreset>(
    context,
    title: title ?? t.videoControls.qualityColumnHeader,
    options: TranscodeQualityPreset.displayOrder.map((p) => (icon: null, label: labelFor(p), value: p)).toList(),
  );
}

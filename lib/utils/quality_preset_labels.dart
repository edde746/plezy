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
/// returns just the raw source size. Returns `null` when inputs are missing.
String? qualityPresetSizeEstimate({
  required TranscodeQualityPreset preset,
  required int? sourceBitrateKbps,
  required int? sourceDurationMs,
}) {
  if (sourceDurationMs == null || sourceDurationMs <= 0) return null;

  if (preset.isOriginal) {
    if (sourceBitrateKbps == null || sourceBitrateKbps <= 0) return null;
    return ByteFormatter.formatBytes(sourceBitrateKbps * sourceDurationMs ~/ 8);
  }

  final videoKbps = preset.videoBitrateKbps;
  if (videoKbps == null) return null;
  final totalKbps = videoKbps + _audioBitrateEstimateKbps;
  final size = ByteFormatter.formatBytes(totalKbps * sourceDurationMs ~/ 8);

  if (sourceBitrateKbps != null && sourceBitrateKbps > 0) {
    final pct = (totalKbps * 100 / sourceBitrateKbps).round();
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
}) {
  String labelFor(TranscodeQualityPreset p) {
    final base = qualityPresetLabel(p);
    final size = qualityPresetSizeEstimate(
      preset: p,
      sourceBitrateKbps: sourceBitrateKbps,
      sourceDurationMs: sourceDurationMs,
    );
    return size == null ? base : toBulletedString([base, size]);
  }

  return showOptionPickerDialog<TranscodeQualityPreset>(
    context,
    title: title ?? t.videoControls.qualityColumnHeader,
    options: TranscodeQualityPreset.displayOrder.map((p) => (icon: null, label: labelFor(p), value: p)).toList(),
  );
}

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../models/download_models.dart';
import '../widgets/app_icon.dart';

/// Visual weight preset.
///
/// - [muted] blends the status color with the surrounding muted text color
///   (used in compact list contexts like episode rows where a saturated color
///   would fight the primary content).
/// - [saturated] uses the status color directly (used in tree view / expanded
///   contexts where the status is the primary signal).
enum DownloadStatusIconVariant { muted, saturated }

/// Renders a compact status indicator for a download: queued/paused/failed/etc.
/// When [status] is [DownloadStatus.downloading] and [progress] is non-null,
/// renders a dual-ring progress indicator instead of a static icon.
///
/// Returns `SizedBox.shrink()` for any status that shouldn't have a visible
/// indicator in the caller's context (e.g. partial).
class DownloadStatusIcon extends StatelessWidget {
  final DownloadStatus? status;
  final double size;
  final DownloadStatusIconVariant variant;

  /// Optional 0.0–1.0 progress for the downloading state's ring.
  /// If null while downloading, shows an indeterminate spinner.
  final double? progress;

  /// Color to blend with in [DownloadStatusIconVariant.muted]. Required when
  /// variant=muted (usually `tokens(context).textMuted`).
  final Color? mutedBase;

  /// Optional override for the primary color (e.g. used in downloading
  /// variant=muted to pick the theme's primary rather than a fixed blue).
  final Color? overrideColor;

  const DownloadStatusIcon({
    super.key,
    required this.status,
    this.size = 16,
    this.variant = DownloadStatusIconVariant.saturated,
    this.progress,
    this.mutedBase,
    this.overrideColor,
  });

  Color _tint(Color base) {
    if (variant == DownloadStatusIconVariant.saturated || mutedBase == null) return base;
    return Color.lerp(mutedBase, base, 0.3) ?? base;
  }

  @override
  Widget build(BuildContext context) {
    final s = status;
    if (s == null) return const SizedBox.shrink();

    switch (s) {
      case DownloadStatus.queued:
        return AppIcon(Symbols.schedule_rounded, fill: 1, size: size, color: _tint(Colors.orange));
      case DownloadStatus.downloading:
        // No progress value — render a static "downloading" icon (callers
        // without per-item progress, e.g. the download tree view).
        if (progress == null) {
          return AppIcon(Symbols.downloading_rounded, fill: 1, size: size, color: _tint(overrideColor ?? Colors.blue));
        }
        final primary = overrideColor ?? Theme.of(context).colorScheme.primary;
        final tinted = _tint(primary);
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: 1.0,
                strokeWidth: size * 0.1,
                valueColor: AlwaysStoppedAnimation<Color>(tinted.withValues(alpha: 0.3)),
              ),
              CircularProgressIndicator(
                value: progress,
                strokeWidth: size * 0.1,
                valueColor: AlwaysStoppedAnimation<Color>(tinted),
              ),
            ],
          ),
        );
      case DownloadStatus.paused:
        return AppIcon(
          Symbols.pause_circle_outline_rounded,
          fill: 1,
          size: size,
          color: _tint(variant == DownloadStatusIconVariant.muted ? Colors.amber : Colors.grey),
        );
      case DownloadStatus.failed:
        return AppIcon(
          variant == DownloadStatusIconVariant.muted ? Symbols.error_outline_rounded : Symbols.error_rounded,
          fill: 1,
          size: size,
          color: _tint(Colors.red),
        );
      case DownloadStatus.cancelled:
        return AppIcon(Symbols.cancel_rounded, fill: 1, size: size, color: _tint(Colors.grey));
      case DownloadStatus.completed:
        return AppIcon(
          variant == DownloadStatusIconVariant.muted
              ? Symbols.file_download_done_rounded
              : Symbols.check_circle_rounded,
          fill: 1,
          size: size,
          color: _tint(Colors.green),
        );
      case DownloadStatus.partial:
        return AppIcon(Symbols.downloading_rounded, fill: 1, size: size, color: _tint(Colors.orange));
    }
  }
}

/// Indeterminate spinner used while the download is being queued (pre-status).
/// Separate widget because it doesn't correspond to a [DownloadStatus] value.
class DownloadQueueingSpinner extends StatelessWidget {
  final double size;
  final Color? color;

  const DownloadQueueingSpinner({super.key, this.size = 12, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(strokeWidth: size * 0.125, color: color),
    );
  }
}

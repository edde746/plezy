import 'package:flutter/material.dart';

import '../models.dart';
import '../transfer.dart';

/// A reactive progress bar widget bound to a [Transfer].
///
/// Automatically updates progress, percentage, transfer speed, and status
/// without requiring parent widget rebuilds.
class TransferProgressBar extends StatelessWidget {
  /// The [Transfer] to observe.
  final Transfer transfer;

  /// Whether to display percentage text (e.g. `'45%'`). Defaults to `true`.
  final bool showPercentage;

  /// Whether to display the text status badge (e.g. `'Transferring'`, `'Waiting for Wi-Fi'`). Defaults to `true`.
  final bool showStatusText;

  /// Whether to display live network transfer speed (e.g. `'1.2 MB/s'`). Defaults to `true`.
  final bool showSpeed;

  /// Custom color override for the progress bar. If null, a color based on [TaskStatus] is used.
  final Color? progressColor;

  /// Background color of the progress bar track.
  final Color? backgroundColor;

  /// Custom [TextStyle] for the status, speed, and percentage labels.
  final TextStyle? textStyle;

  /// Height of the progress bar in logical pixels. Defaults to `6.0`.
  final double height;

  /// Creates a reactive [TransferProgressBar].
  const TransferProgressBar({
    super.key,
    required this.transfer,
    this.showPercentage = true,
    this.showStatusText = true,
    this.showSpeed = true,
    this.progressColor,
    this.backgroundColor,
    this.textStyle,
    this.height = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveTextStyle =
        textStyle ?? theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);

    return ValueListenableBuilder<TaskStatus>(
      valueListenable: transfer.statusNotifier,
      builder: (context, status, _) =>
          ValueListenableBuilder<TransferHoldReason>(
            valueListenable: transfer.holdReasonNotifier,
            builder: (context, holdReason, _) => ValueListenableBuilder<double?>(
              valueListenable: transfer.progressNotifier,
              builder: (context, progress, _) => ValueListenableBuilder<double>(
                valueListenable: transfer.networkSpeedNotifier,
                builder: (context, speed, _) {
                  final effectiveColor = _colorForStatus(
                    status,
                    holdReason,
                    theme,
                  );

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(height / 2),
                        child: SizedBox(
                          height: height,
                          child: LinearProgressIndicator(
                            value: status == TaskStatus.complete
                                ? 1.0
                                : (progress != null && progress >= 0.0
                                      ? progress
                                      : null),
                            color: effectiveColor,
                            backgroundColor:
                                backgroundColor ??
                                theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                      if (showPercentage || showStatusText || showSpeed) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (showStatusText)
                              Text(
                                _statusLabel(status, holdReason),
                                style: effectiveTextStyle.copyWith(
                                  color: effectiveColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (showSpeed &&
                                    speed > 0 &&
                                    status == TaskStatus.running) ...[
                                  Text(
                                    _formatSpeed(speed),
                                    style: effectiveTextStyle.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (showPercentage) ...[
                                  if (status == TaskStatus.complete)
                                    Text(
                                      '100%',
                                      style: effectiveTextStyle.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  else if (progress != null && progress >= 0.0)
                                    Text(
                                      '${(progress * 100).toStringAsFixed(0)}%',
                                      style: effectiveTextStyle.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
    );
  }

  Color _colorForStatus(
    TaskStatus status,
    TransferHoldReason holdReason,
    ThemeData theme,
  ) {
    if (progressColor != null) return progressColor!;
    if (holdReason != TransferHoldReason.none) {
      return Colors.orange;
    }
    return switch (status) {
      .complete => Colors.green,
      .failed || .notFound => theme.colorScheme.error,
      .paused || .waitingToRetry => Colors.orange,
      .running || .enqueued => theme.colorScheme.primary,
      .canceled => theme.colorScheme.outline,
    };
  }

  String _statusLabel(TaskStatus status, TransferHoldReason holdReason) =>
      switch (holdReason) {
        .waitingForWiFi => 'Waiting for Wi-Fi',
        .offline => 'Waiting for network',
        .none => switch (status) {
          .enqueued => 'Enqueued',
          .running => 'Transferring',
          .complete => 'Complete',
          .paused => 'Paused',
          .waitingToRetry => 'Waiting to retry',
          .failed => 'Failed',
          .notFound => 'Not found',
          .canceled => 'Canceled',
        },
      };

  String _formatSpeed(double mbPerSec) => switch (mbPerSec) {
    <= 0 => '',
    >= 1.0 => '${mbPerSec.toStringAsFixed(1)} MB/s',
    _ => '${(mbPerSec * 1000).round()} kB/s',
  };
}

/// Alias for [TransferProgressBar] for backward compatibility
typedef FileTransferProgressBar = TransferProgressBar;

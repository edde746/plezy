import 'package:flutter/material.dart';

import '../models.dart';
import '../task.dart';
import '../transfer.dart';

/// An adaptive action button for a [Transfer].
///
/// Dynamically toggles between Pause, Resume, Retry, and Complete actions
/// based on the transfer's current [TaskStatus].
class TransferButton extends StatelessWidget {
  /// The [Transfer] to control.
  final Transfer transfer;

  /// Icon size in logical pixels (defaults to `24.0`).
  final double iconSize;

  /// Padding around the icon button.
  final EdgeInsetsGeometry padding;

  /// Color override for the icon.
  final Color? color;

  /// Optional callback invoked when the user cancels the transfer.
  ///
  /// If omitted, defaults to calling [Transfer.cancel].
  final VoidCallback? onCancel;

  /// Creates a reactive [TransferButton].
  const TransferButton({
    super.key,
    required this.transfer,
    this.iconSize = 24.0,
    this.padding = const EdgeInsets.all(8.0),
    this.color,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<TaskStatus>(
      valueListenable: transfer.statusNotifier,
      builder: (context, status, _) {
        final canPause =
            transfer.task is DownloadTask && transfer.task.allowPause;
        return switch (status) {
          .running || .enqueued =>
            canPause
                ? IconButton(
                    icon: Icon(Icons.pause_circle_outline, size: iconSize),
                    color: color ?? theme.colorScheme.primary,
                    padding: padding,
                    tooltip: 'Pause',
                    onPressed: () => transfer.pause(),
                  )
                : IconButton(
                    icon: Icon(Icons.cancel_outlined, size: iconSize),
                    color: color ?? theme.colorScheme.error,
                    padding: padding,
                    tooltip: 'Cancel',
                    onPressed: onCancel ?? () => transfer.cancel(),
                  ),
          .paused || .waitingToRetry => IconButton(
            icon: Icon(Icons.play_circle_outline, size: iconSize),
            color: color ?? Colors.orange,
            padding: padding,
            tooltip: 'Resume',
            onPressed: () => transfer.resume(),
          ),
          .failed || .notFound => IconButton(
            icon: Icon(Icons.refresh, size: iconSize),
            color: color ?? theme.colorScheme.error,
            padding: padding,
            tooltip: 'Retry',
            onPressed: () => transfer.resume(),
          ),
          .complete => Icon(
            Icons.check_circle,
            size: iconSize,
            color: color ?? Colors.green,
          ),
          .canceled => IconButton(
            icon: Icon(Icons.replay, size: iconSize),
            color: color ?? theme.colorScheme.outline,
            padding: padding,
            tooltip: 'Restart',
            onPressed: () => transfer.resume(),
          ),
        };
      },
    );
  }
}

/// Alias for [TransferButton] for backward compatibility
typedef FileTransferButton = TransferButton;

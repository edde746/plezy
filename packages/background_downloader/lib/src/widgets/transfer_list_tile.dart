import 'package:flutter/material.dart';

import '../task.dart';
import '../transfer.dart';
import 'transfer_button.dart';
import 'transfer_progress_bar.dart';

/// A plug-and-play [ListTile] displaying a [Transfer] with
/// filename, progress bar, transfer speed, and action controls.
class TransferListTile extends StatelessWidget {
  /// The [Transfer] to display and interact with.
  final Transfer transfer;

  /// Optional custom leading widget. If null, a circular icon based on task type is rendered.
  final Widget? leading;

  /// Optional custom trailing widget. If null, a [TransferButton] is rendered.
  final Widget? trailing;

  /// Optional callback invoked when the tile is tapped.
  final VoidCallback? onTap;

  /// Whether to show live network speed in the progress subtitle. Defaults to `true`.
  final bool showSpeed;

  /// Whether to show percentage text in the progress subtitle. Defaults to `true`.
  final bool showPercentage;

  /// Creates a [TransferListTile].
  const TransferListTile({
    super.key,
    required this.transfer,
    this.leading,
    this.trailing,
    this.onTap,
    this.showSpeed = true,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final title = transfer.task.displayName.isNotEmpty
        ? transfer.task.displayName
        : transfer.task.filename;

    return ListTile(
      leading: leading ?? _defaultLeading(context),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6.0),
        child: TransferProgressBar(
          transfer: transfer,
          showSpeed: showSpeed,
          showPercentage: showPercentage,
        ),
      ),
      trailing: trailing ?? TransferButton(transfer: transfer),
      onTap: onTap,
    );
  }

  Widget _defaultLeading(BuildContext context) {
    final theme = Theme.of(context);
    final isUpload = transfer.task is UploadTask;

    return CircleAvatar(
      backgroundColor: theme.colorScheme.primaryContainer,
      foregroundColor: theme.colorScheme.onPrimaryContainer,
      child: Icon(isUpload ? Icons.upload_file : Icons.download, size: 20),
    );
  }
}

/// Alias for [TransferListTile] for backward compatibility
typedef FileTransferListTile = TransferListTile;

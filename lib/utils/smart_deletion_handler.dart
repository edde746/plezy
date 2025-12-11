import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/download_provider.dart';
import '../widgets/deletion_progress_dialog.dart';

class SmartDeletionHandler {
  /// Execute deletion with smart progress dialog
  /// Only shows dialog if deletion takes longer than delayMs
  static Future<void> deleteWithProgress({
    required BuildContext context,
    required DownloadProvider provider,
    required String globalKey,
    int delayMs = 500,
  }) async {
    bool dialogShown = false;
    bool deletionComplete = false;

    // Start a timer to show dialog after delay
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (!deletionComplete && context.mounted) {
        dialogShown = true;
        _showProgressDialog(context, provider, globalKey);
      }
    });

    try {
      // Start deletion
      await provider.deleteDownload(globalKey);
      deletionComplete = true;

      // Close dialog if shown
      if (dialogShown && context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      deletionComplete = true;

      // Close dialog if shown
      if (dialogShown && context.mounted) {
        Navigator.of(context).pop();
      }

      rethrow; // Let caller handle error
    }
  }

  /// Show progress dialog and listen to updates
  static void _showProgressDialog(
    BuildContext context,
    DownloadProvider provider,
    String globalKey,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Consumer<DownloadProvider>(
        builder: (context, provider, child) {
          final progress = provider.getDeletionProgress(globalKey);

          // If no progress, show simple fallback
          if (progress == null) {
            return const AlertDialog(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('Deleting...'),
                ],
              ),
            );
          }

          return DeletionProgressDialog(progress: progress);
        },
      ),
    );
  }
}

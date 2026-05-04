import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../i18n/strings.g.dart';
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

    Future.delayed(Duration(milliseconds: delayMs), () {
      if (!deletionComplete && context.mounted) {
        dialogShown = true;
        _showProgressDialog(context, provider, globalKey);
      }
    });

    try {
      await provider.deleteDownload(globalKey);
    } finally {
      deletionComplete = true;
      // Close dialog if shown (with canPop guard to prevent double-pop)
      if (dialogShown && context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    }
  }

  static void _showProgressDialog(BuildContext context, DownloadProvider _, String globalKey) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Consumer<DownloadProvider>(
        builder: (context, provider, child) {
          final progress = provider.getDeletionProgress(globalKey);

          if (progress == null) {
            return AlertDialog(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [const CircularProgressIndicator(), const SizedBox(width: 20), Text(t.downloads.deleting)],
              ),
            );
          }

          return DeletionProgressDialog(progress: progress);
        },
      ),
    );
  }
}

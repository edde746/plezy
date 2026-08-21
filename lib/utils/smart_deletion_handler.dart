import 'dart:async';

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
    bool deletionComplete = false;
    ({NavigatorState navigator, DialogRoute<void> route})? progressDialog;

    final progressTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!deletionComplete && context.mounted) {
        progressDialog = _showProgressDialog(context, globalKey);
      }
    });

    try {
      await provider.deleteDownload(globalKey);
    } finally {
      deletionComplete = true;
      progressTimer.cancel();
      final dialog = progressDialog;
      if (dialog != null && dialog.navigator.mounted && dialog.route.isActive) {
        dialog.navigator.removeRoute(dialog.route);
      }
    }
  }

  static ({NavigatorState navigator, DialogRoute<void> route}) _showProgressDialog(
    BuildContext context,
    String globalKey,
  ) {
    final navigator = Navigator.of(context);
    final route = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Consumer<DownloadProvider>(
        builder: (context, provider, child) {
          final progress = provider.getDeletionProgress(globalKey);

          if (progress == null) {
            return AlertDialog(
              content: Row(
                mainAxisSize: .min,
                children: [const CircularProgressIndicator(), const SizedBox(width: 20), Text(t.downloads.deleting)],
              ),
            );
          }

          return DeletionProgressDialog(progress: progress);
        },
      ),
    );
    navigator.push(route);
    return (navigator: navigator, route: route);
  }
}

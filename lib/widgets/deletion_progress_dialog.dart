import 'package:flutter/material.dart';
import '../models/deletion_progress.dart';
import '../i18n/strings.g.dart';

class DeletionProgressDialog extends StatelessWidget {
  final DeletionProgress progress;

  const DeletionProgressDialog({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);

    return PopScope(
      canPop: false, // Prevent back button dismissal
      child: AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular progress indicator
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(),
            ),

            const SizedBox(height: 24),

            // Progress text
            Text(
              t.downloads.deletingWithProgress(
                title: progress.itemTitle,
                current: progress.currentItem,
                total: progress.totalItems,
              ),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Progress text
            Text(
              'Deleting ${progress.itemTitle}... (${progress.currentItem} of ${progress.totalItems})',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Progress bar
            LinearProgressIndicator(value: progress.progressPercent),

            const SizedBox(height: 8),

            // Percentage text
            Text(
              '${progress.progressPercentInt}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            // Optional: Current operation
            if (progress.currentOperation != null) ...[
              const SizedBox(height: 8),
              Text(
                progress.currentOperation!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

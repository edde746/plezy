import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// Dialog for sharing a watch together session with others
class SessionInviteDialog extends StatelessWidget {
  final String sessionId;
  final int participantCount;

  const SessionInviteDialog({super.key, required this.sessionId, required this.participantCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Icon(Symbols.group, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Watch Together', style: theme.textTheme.titleLarge),
                        Text(
                          '$participantCount ${participantCount == 1 ? 'participant' : 'participants'}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Symbols.close)),
                ],
              ),

              const SizedBox(height: 24),

              // QR Code
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: QrImageView(
                    data: sessionId,
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Session ID with copy button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Session Code',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            sessionId,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _copyToClipboard(context),
                      icon: const Icon(Symbols.content_copy),
                      tooltip: 'Copy code',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Instructions
              Text(
                'Share this code with others to let them join your watch session.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Share button
              FilledButton.icon(
                onPressed: () => _share(context),
                icon: const Icon(Symbols.share),
                label: const Text('Share'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: sessionId));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session code copied to clipboard')));
  }

  void _share(BuildContext context) {
    final text = 'Join my Watch Together session!\n\nSession Code: $sessionId';
    Share.share(text, subject: 'Watch Together Invite');
  }
}

/// Show the session invite dialog
Future<void> showSessionInviteDialog(BuildContext context, {required String sessionId, required int participantCount}) {
  return showDialog(
    context: context,
    builder: (context) => SessionInviteDialog(sessionId: sessionId, participantCount: participantCount),
  );
}

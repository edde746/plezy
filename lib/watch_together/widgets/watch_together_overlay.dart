import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../models/watch_session.dart';
import '../providers/watch_together_provider.dart';

/// Overlay shown on the video player when in a watch together session
class WatchTogetherOverlay extends StatelessWidget {
  /// Callback when the user wants to leave the session
  final VoidCallback? onLeaveSession;

  const WatchTogetherOverlay({super.key, this.onLeaveSession});

  @override
  Widget build(BuildContext context) {
    return Consumer<WatchTogetherProvider>(
      builder: (context, provider, child) {
        if (!provider.isInSession) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: 16,
          right: 16,
          child: _SessionIndicator(
            participantCount: provider.participantCount,
            isHost: provider.isHost,
            isSyncing: provider.isSyncing,
            controlMode: provider.controlMode,
            sessionId: provider.sessionId,
            onTap: () => _showSessionMenu(context, provider),
          ),
        );
      },
    );
  }

  void _showSessionMenu(BuildContext context, WatchTogetherProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _SessionMenuSheet(provider: provider, onLeaveSession: onLeaveSession),
    );
  }
}

/// Small indicator showing session status
class _SessionIndicator extends StatelessWidget {
  final int participantCount;
  final bool isHost;
  final bool isSyncing;
  final ControlMode controlMode;
  final String? sessionId;
  final VoidCallback onTap;

  const _SessionIndicator({
    required this.participantCount,
    required this.isHost,
    required this.isSyncing,
    required this.controlMode,
    required this.sessionId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sync indicator or group icon
              if (isSyncing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              else
                Icon(Symbols.group, size: 18, color: isHost ? theme.colorScheme.primary : Colors.white),

              const SizedBox(width: 6),

              // Participant count
              Text(
                '$participantCount',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),

              // Host badge
              if (isHost) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    t.watchTogether.hostBadge,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet showing session details and actions
class _SessionMenuSheet extends StatelessWidget {
  final WatchTogetherProvider provider;
  final VoidCallback? onLeaveSession;

  const _SessionMenuSheet({required this.provider, this.onLeaveSession});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      Text(t.watchTogether.title, style: theme.textTheme.titleMedium),
                      Text(
                        provider.isHost ? t.watchTogether.youAreHost : t.watchTogether.watchingWithOthers,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                // Control mode badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    provider.controlMode == ControlMode.hostOnly
                        ? t.watchTogether.hostControls
                        : t.watchTogether.anyoneControls,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),

            // Session code with copy button
            if (provider.sessionId != null) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _copySessionCode(context, provider.sessionId!),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${t.watchTogether.sessionCode}: ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        provider.sessionId!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Symbols.content_copy_rounded,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Participants list
            Text(t.watchTogether.participants, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            ...provider.participants.map(
              (p) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: p.isHost ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    p.isHost ? Symbols.star : Symbols.person,
                    color: p.isHost ? Colors.white : theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                title: Text(p.displayName),
                subtitle: p.isHost ? Text(t.watchTogether.host) : null,
                trailing: p.isBuffering
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : null,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Actions
            ListTile(
              leading: Icon(Symbols.logout, color: theme.colorScheme.error),
              title: Text(
                provider.isHost ? t.watchTogether.endSession : t.watchTogether.leaveSession,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmLeave(context);
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  void _copySessionCode(BuildContext context, String sessionId) {
    Clipboard.setData(ClipboardData(text: sessionId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.watchTogether.sessionCodeCopied)),
    );
  }

  void _confirmLeave(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(provider.isHost ? t.watchTogether.endSessionQuestion : t.watchTogether.leaveSessionQuestion),
        content: Text(
          provider.isHost ? t.watchTogether.endSessionConfirmOverlay : t.watchTogether.leaveSessionConfirmOverlay,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.common.cancel)),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              provider.leaveSession();
              onLeaveSession?.call();
            },
            child: Text(provider.isHost ? t.watchTogether.endSession : t.watchTogether.leave),
          ),
        ],
      ),
    );
  }
}

/// Compact sync indicator for showing during drift correction
class SyncingIndicator extends StatelessWidget {
  const SyncingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WatchTogetherProvider>(
      builder: (context, provider, child) {
        if (!provider.isSyncing) {
          return const SizedBox.shrink();
        }

        return Positioned(
          bottom: 80,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(t.watchTogether.syncing, style: const TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

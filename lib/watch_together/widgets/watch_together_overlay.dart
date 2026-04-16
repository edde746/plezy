import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../utils/dialogs.dart';
import '../../utils/platform_detector.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/overlay_sheet.dart';
import '../models/watch_session.dart';
import '../providers/watch_together_provider.dart';

/// Overlay shown on the video player when in a watch together session
/// Session indicator badge for embedding in the video controls header.
/// Shows participant count, host badge, and opens the session menu on tap.
class WatchTogetherSessionIndicator extends StatelessWidget {
  final VoidCallback? onLeaveSession;

  const WatchTogetherSessionIndicator({super.key, this.onLeaveSession});

  @override
  Widget build(BuildContext context) {
    return Consumer<WatchTogetherProvider>(
      builder: (context, provider, child) {
        return _SessionIndicator(
          participantCount: provider.participantCount,
          isHost: provider.isHost,
          isSyncing: provider.isSyncing,
          controlMode: provider.controlMode,
          sessionId: provider.sessionId,
          onTap: () => _showSessionMenu(context, provider),
        );
      },
    );
  }

  void _showSessionMenu(BuildContext context, WatchTogetherProvider provider) {
    OverlaySheetController.of(context).show(
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
    return Material(
      color: Colors.black54,
      borderRadius: const BorderRadius.all(Radius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sync indicator or group icon
              if (isSyncing)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: PlatformDetector.isTV()
                      ? const Icon(Symbols.sync_rounded, size: 16, color: Colors.white)
                      : const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              else
                Icon(Symbols.group, size: 18, color: isHost ? Colors.amber : Colors.white),

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
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                  child: Text(
                    t.watchTogether.hostBadge,
                    style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
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
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
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
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${t.watchTogether.sessionCode}: ',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      Text(
                        provider.sessionId!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Symbols.content_copy_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
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
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: PlatformDetector.isTV()
                            ? const Icon(Symbols.hourglass_empty_rounded, size: 16)
                            : const CircularProgressIndicator(strokeWidth: 2),
                      )
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
                OverlaySheetController.of(context).close();
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
    showSuccessSnackBar(context, t.watchTogether.sessionCodeCopied);
  }

  void _confirmLeave(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: provider.isHost ? t.watchTogether.endSessionQuestion : t.watchTogether.leaveSessionQuestion,
      message: provider.isHost ? t.watchTogether.endSessionConfirmOverlay : t.watchTogether.leaveSessionConfirmOverlay,
      confirmText: provider.isHost ? t.watchTogether.endSession : t.watchTogether.leave,
      isDestructive: true,
    );

    if (confirmed) {
      provider.leaveSession();
      onLeaveSession?.call();
    }
  }
}

/// Auto-dismissing toast for participant join/leave events
class ParticipantNotificationOverlay extends StatefulWidget {
  const ParticipantNotificationOverlay({super.key});

  @override
  State<ParticipantNotificationOverlay> createState() => _ParticipantNotificationOverlayState();
}

class _ParticipantNotificationOverlayState extends State<ParticipantNotificationOverlay> {
  StreamSubscription<ParticipantEvent>? _subscription;
  final List<_NotificationEntry> _notifications = [];
  int _nextId = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscription?.cancel();
    try {
      final provider = context.read<WatchTogetherProvider>();
      _subscription = provider.participantEvents.listen(_onEvent);
    } catch (_) {}
  }

  void _onEvent(ParticipantEvent event) {
    if (!mounted) return;
    final id = _nextId++;
    setState(() {
      _notifications.add(_NotificationEntry(id: id, event: event));
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _notifications.removeWhere((n) => n.id == id);
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_notifications.isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: 60,
      left: 0,
      right: 0,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _notifications.map((n) {
            final text = switch (n.event.type) {
              ParticipantEventType.joined => t.watchTogether.participantJoined(name: n.event.displayName),
              ParticipantEventType.left => t.watchTogether.participantLeft(name: n.event.displayName),
              ParticipantEventType.paused => t.watchTogether.participantPaused(name: n.event.displayName),
              ParticipantEventType.resumed => t.watchTogether.participantResumed(name: n.event.displayName),
              ParticipantEventType.seeked => t.watchTogether.participantSeeked(name: n.event.displayName),
              ParticipantEventType.buffering => t.watchTogether.participantBuffering(name: n.event.displayName),
            };
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NotificationEntry {
  final int id;
  final ParticipantEvent event;
  const _NotificationEntry({required this.id, required this.event});
}

/// Compact sync indicator for showing during drift correction
class SyncingIndicator extends StatelessWidget {
  const SyncingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<WatchTogetherProvider, bool>(
      selector: (_, provider) => provider.isSyncing,
      builder: (context, isSyncing, child) {
        if (!isSyncing) return const SizedBox.shrink();
        return _StatusPill(tvIcon: Symbols.sync_rounded, label: t.watchTogether.syncing);
      },
    );
  }
}

/// Indicator shown when playback is deferred waiting for participants to load
class WaitingForParticipantsIndicator extends StatelessWidget {
  const WaitingForParticipantsIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<WatchTogetherProvider, bool>(
      selector: (_, provider) => provider.isDeferredPlay,
      builder: (context, isDeferredPlay, child) {
        if (!isDeferredPlay) return const SizedBox.shrink();
        return _StatusPill(tvIcon: Symbols.hourglass_empty_rounded, label: t.watchTogether.waitingForParticipants);
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData tvIcon;
  final String label;

  const _StatusPill({required this.tvIcon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: PlatformDetector.isTV()
                    ? Icon(tvIcon, size: 14, color: Colors.white)
                    : const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../models/plex_friend.dart';
import '../../utils/app_logger.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../models/watch_invitation.dart';
import '../models/watch_session.dart';
import '../providers/watch_together_provider.dart';
import '../widgets/friend_selection_sheet.dart';
import '../widgets/join_session_dialog.dart';

/// Main screen for Watch Together functionality
///
/// Allows users to:
/// - Create a new watch session
/// - Join an existing session
/// - View active session info and participants
/// - Leave/end session
class WatchTogetherScreen extends StatelessWidget {
  const WatchTogetherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WatchTogetherProvider>(
      builder: (context, watchTogether, child) {
        // Non-hosts must use "Leave Session" button - disable back navigation and hide button
        final canGoBack = watchTogether.isHost || !watchTogether.isInSession;
        return PopScope(
          canPop: canGoBack,
          child: FocusedScrollScaffold(
            title: Text(t.watchTogether.title),
            automaticallyImplyLeading: canGoBack,
            slivers: watchTogether.isInSession
                ? _buildActiveSessionSlivers(watchTogether)
                : [SliverFillRemaining(hasScrollBody: false, child: _NotInSessionView(watchTogether: watchTogether))],
          ),
        );
      },
    );
  }

  List<Widget> _buildActiveSessionSlivers(WatchTogetherProvider watchTogether) {
    return [
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: _ActiveSessionContent(watchTogether: watchTogether),
            ),
          ),
        ),
      ),
    ];
  }
}

/// View shown when not in a session
class _NotInSessionView extends StatefulWidget {
  final WatchTogetherProvider watchTogether;

  const _NotInSessionView({required this.watchTogether});

  @override
  State<_NotInSessionView> createState() => _NotInSessionViewState();
}

class _NotInSessionViewState extends State<_NotInSessionView> {
  bool _isCreating = false;
  bool _isJoining = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pendingInvitations = widget.watchTogether.pendingInvitations;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Symbols.group_rounded, size: 80, color: theme.colorScheme.primary),
                const SizedBox(height: 24),
                Text(t.watchTogether.title, style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  t.watchTogether.description,
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),

                // Pending invitations section
                if (pendingInvitations.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  _buildPendingInvitations(context, pendingInvitations),
                ],

                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    autofocus: pendingInvitations.isEmpty,
                    onPressed: _isCreating || _isJoining ? null : _createSession,
                    icon: _isCreating
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Symbols.add_rounded),
                    label: Text(_isCreating ? t.watchTogether.creating : t.watchTogether.createSession),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isCreating || _isJoining ? null : _joinSession,
                    icon: _isJoining
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Symbols.group_add_rounded),
                    label: Text(_isJoining ? t.watchTogether.joining : t.watchTogether.joinSession),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingInvitations(BuildContext context, List<WatchInvitation> invitations) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Symbols.mail_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  t.watchTogether.pendingInvitations,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...invitations.map((invitation) => _buildInvitationTile(context, invitation)),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationTile(BuildContext context, WatchInvitation invitation) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
            child: Text(
              invitation.hostDisplayName.isNotEmpty ? invitation.hostDisplayName[0].toUpperCase() : '?',
              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invitation.hostDisplayName,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  invitation.mediaTitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: () => _acceptInvitation(invitation),
            icon: const Icon(Symbols.check_rounded),
            tooltip: t.watchTogether.accept,
          ),
          const SizedBox(width: 4),
          IconButton.outlined(
            onPressed: () => _declineInvitation(invitation),
            icon: const Icon(Symbols.close_rounded),
            tooltip: t.watchTogether.decline,
          ),
        ],
      ),
    );
  }

  Future<void> _acceptInvitation(WatchInvitation invitation) async {
    setState(() => _isJoining = true);
    try {
      await widget.watchTogether.acceptInvitation(invitation);
    } catch (e) {
      appLogger.e('Failed to accept invitation', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${t.watchTogether.failedToJoin}: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  void _declineInvitation(WatchInvitation invitation) {
    widget.watchTogether.declineInvitation(invitation);
  }

  Future<void> _createSession() async {
    final controlMode = await _showControlModeDialog();
    if (controlMode == null || !mounted) return;

    setState(() => _isCreating = true);

    try {
      await widget.watchTogether.createSession(controlMode: controlMode);

      // Show friend selection sheet after session is created
      if (mounted) {
        await showFriendSelectionSheet(
          context,
          onFriendsSelected: (friends) => _inviteFriends(friends),
        );
      }
    } catch (e) {
      appLogger.e('Failed to create session', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${t.watchTogether.failedToCreate}: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _inviteFriends(List<PlexFriend> friends) {
    if (friends.isEmpty) return;

    widget.watchTogether.inviteFriends(
      friends: friends,
      mediaTitle: widget.watchTogether.currentMediaTitle ?? 'Watch Together Session',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t.watchTogether.invite}: ${friends.length} ${t.watchTogether.inviteFriends.toLowerCase()}')),
      );
    }
  }

  Future<ControlMode?> _showControlModeDialog() {
    return showDialog<ControlMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.watchTogether.controlMode),
        content: Text(t.watchTogether.controlModeQuestion),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.common.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, ControlMode.hostOnly),
            child: Text(t.watchTogether.hostOnly),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ControlMode.anyone),
            child: Text(t.watchTogether.anyone),
          ),
        ],
      ),
    );
  }

  Future<void> _joinSession() async {
    final sessionId = await showJoinSessionDialog(context);
    if (sessionId == null || !mounted) return;

    setState(() => _isJoining = true);

    try {
      await widget.watchTogether.joinSession(sessionId);
    } catch (e) {
      appLogger.e('Failed to join session', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${t.watchTogether.failedToJoin}: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }
}

/// Content shown when in an active session (without scroll wrapper)
class _ActiveSessionContent extends StatelessWidget {
  final WatchTogetherProvider watchTogether;

  const _ActiveSessionContent({required this.watchTogether});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = watchTogether.session!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Session Info Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      watchTogether.isHost ? Symbols.star_rounded : Symbols.group_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            watchTogether.isHost ? t.watchTogether.hostingSession : t.watchTogether.inSession,
                            style: theme.textTheme.titleMedium,
                          ),
                          _SessionCodeRow(sessionId: session.sessionId),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      session.controlMode == ControlMode.anyone
                          ? Symbols.groups_rounded
                          : Symbols.admin_panel_settings_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      session.controlMode == ControlMode.anyone
                          ? t.watchTogether.anyoneCanControl
                          : t.watchTogether.hostControlsPlayback,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Participants Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Symbols.people_rounded, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      '${t.watchTogether.participants} (${watchTogether.participantCount})',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...watchTogether.participants.map(
                  (participant) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          participant.isHost ? Symbols.star_rounded : Symbols.person_rounded,
                          size: 20,
                          color: participant.isHost ? Colors.amber : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Text(participant.displayName, style: theme.textTheme.bodyMedium),
                        if (participant.isHost) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              t.watchTogether.host,
                              style: theme.textTheme.labelSmall?.copyWith(color: Colors.amber.shade700),
                            ),
                          ),
                        ],
                        if (participant.isBuffering) ...[
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Invited Friends Card (host only, if any)
        if (watchTogether.isHost && watchTogether.invitedFriends.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Symbols.send_rounded, color: theme.colorScheme.secondary),
                      const SizedBox(width: 12),
                      Text(t.watchTogether.inviteFriends, style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...watchTogether.invitedFriends.entries.map(
                    (entry) {
                      final friendData = entry.value;
                      final status = friendData.status;
                      final friendName = friendData.name;
                      final statusColor = status == 'accepted'
                          ? Colors.green
                          : status == 'declined'
                              ? Colors.red
                              : theme.colorScheme.onSurfaceVariant;
                      final statusText = status == 'accepted'
                          ? t.watchTogether.invitationAccepted
                          : status == 'declined'
                              ? t.watchTogether.invitationDeclined
                              : t.watchTogether.invitationPending;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(Symbols.person_rounded, size: 20, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 12),
                            Expanded(child: Text(friendName, style: theme.textTheme.bodyMedium)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                statusText,
                                style: theme.textTheme.labelSmall?.copyWith(color: statusColor),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Invite Friends Button (host only)
        if (watchTogether.isHost) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => _showInviteFriends(context),
              icon: const Icon(Symbols.person_add_rounded),
              label: Text(t.watchTogether.inviteFriends),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Leave/End Session Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            autofocus: !watchTogether.isHost,
            onPressed: () => _leaveSession(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
            ),
            icon: Icon(watchTogether.isHost ? Symbols.close_rounded : Symbols.logout_rounded),
            label: Text(watchTogether.isHost ? t.watchTogether.endSession : t.watchTogether.leaveSession),
          ),
        ),
      ],
    );
  }

  void _showInviteFriends(BuildContext context) {
    showFriendSelectionSheet(
      context,
      onFriendsSelected: (friends) {
        if (friends.isEmpty) return;

        watchTogether.inviteFriends(
          friends: friends,
          mediaTitle: watchTogether.currentMediaTitle ?? 'Watch Together Session',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t.watchTogether.invite}: ${friends.length}')),
        );
      },
    );
  }

  Future<void> _leaveSession(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(watchTogether.isHost ? t.watchTogether.endSessionQuestion : t.watchTogether.leaveSessionQuestion),
        content: Text(watchTogether.isHost ? t.watchTogether.endSessionConfirm : t.watchTogether.leaveSessionConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.common.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: Text(watchTogether.isHost ? t.watchTogether.end : t.watchTogether.leave),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await watchTogether.leaveSession();
    }
  }
}

/// Tappable session code row with copy functionality
class _SessionCodeRow extends StatelessWidget {
  final String sessionId;

  const _SessionCodeRow({required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _copySessionCode(context),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${t.watchTogether.sessionCode}: $sessionId',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Symbols.content_copy_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  void _copySessionCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: sessionId));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.watchTogether.sessionCodeCopied)));
  }
}

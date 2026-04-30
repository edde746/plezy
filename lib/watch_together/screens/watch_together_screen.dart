import 'dart:io';

import 'package:flutter/material.dart';
import '../../utils/future_extensions.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../focus/focusable_button.dart';
import '../../focus/focusable_wrapper.dart';
import '../../profiles/active_profile_provider.dart';
import '../../services/settings_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/dialogs.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/dialog_action_button.dart';
import '../../utils/video_player_navigation.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../models/watch_session.dart';
import '../providers/watch_together_provider.dart';
import '../services/recent_rooms_service.dart';
import '../services/watch_together_peer_service.dart';
import '../widgets/join_session_dialog.dart';
import '../../widgets/loading_indicator_box.dart';

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
  String? _enteringRoomCode;
  bool? _healthOk;
  String? _customRelayUrl;
  List<RecentRoom> _recentRooms = [];

  @override
  void initState() {
    super.initState();
    _customRelayUrl = SettingsService.instanceOrNull?.read(SettingsService.customRelayUrl);
    _recentRooms = RecentRoomsService.getRecentRooms();
    _checkHealth();
  }

  bool get _isBusy => _isCreating || _isJoining || _enteringRoomCode != null;

  String? get _plexDisplayName => context.read<ActiveProfileProvider>().active?.displayName;

  Future<void> _checkHealth() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(Uri.parse(WatchTogetherPeerService.healthUrlFor(_customRelayUrl)));
      final response = await request.close().namedTimeout(
        const Duration(seconds: 5),
        operation: 'WatchTogether health check',
      );
      final body = await response.transform(const SystemEncoding().decoder).join();
      client.close();
      if (!mounted) return;
      setState(() => _healthOk = response.statusCode == 200 && body.trim() == 'ok');
    } catch (e) {
      appLogger.w('Watch Together health check failed', error: e);
      if (!mounted) return;
      setState(() => _healthOk = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              if (_healthOk == false) ...[
                const SizedBox(height: 24),
                Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Symbols.warning_rounded, color: theme.colorScheme.onErrorContainer),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            t.watchTogether.relayUnreachable,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: FocusableButton(
                  autofocus: _recentRooms.isEmpty,
                  onPressed: _isBusy ? null : _createSession,
                  child: FilledButton.icon(
                    onPressed: _isBusy ? null : _createSession,
                    icon: _isCreating ? const LoadingIndicatorBox(size: 20) : const Icon(Symbols.add_rounded),
                    label: Text(_isCreating ? t.watchTogether.creating : t.watchTogether.createSession),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FocusableButton(
                  onPressed: _isBusy ? null : _joinSession,
                  child: OutlinedButton.icon(
                    onPressed: _isBusy ? null : _joinSession,
                    icon: _isJoining ? const LoadingIndicatorBox(size: 20) : const Icon(Symbols.group_add_rounded),
                    label: Text(_isJoining ? t.watchTogether.joining : t.watchTogether.joinSession),
                  ),
                ),
              ),
              if (_recentRooms.isNotEmpty) ...[
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(t.watchTogether.recentRooms, style: theme.textTheme.titleSmall),
                ),
                const SizedBox(height: 8),
                ..._recentRooms.map(
                  (room) => _RecentRoomTile(
                    room: room,
                    isBusy: _isBusy,
                    isEntering: _enteringRoomCode == room.code,
                    onTap: () => _enterRoom(room),
                    onRename: () => _renameRoom(room),
                    onRemove: () => _removeRoom(room),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createSession() async {
    final controlMode = await _showControlModeDialog();
    if (controlMode == null || !mounted) return;

    setState(() => _isCreating = true);

    try {
      final sessionId = await widget.watchTogether.createSession(
        controlMode: controlMode,
        displayName: _plexDisplayName,
      );
      await RecentRoomsService.addOrUpdateRoom(sessionId, controlMode: controlMode);
      if (mounted) setState(() => _recentRooms = RecentRoomsService.getRecentRooms());
    } catch (e) {
      appLogger.e('Failed to create session', error: e);
      if (mounted) {
        showErrorSnackBar(context, '${t.watchTogether.failedToCreate}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  Future<ControlMode?> _showControlModeDialog() {
    return showDialog<ControlMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.watchTogether.controlMode),
        content: Text(t.watchTogether.controlModeQuestion),
        actions: [
          DialogActionButton(onPressed: () => Navigator.pop(context), label: t.common.cancel),
          DialogActionButton(
            onPressed: () => Navigator.pop(context, ControlMode.hostOnly),
            label: t.watchTogether.hostOnly,
          ),
          DialogActionButton(
            onPressed: () => Navigator.pop(context, ControlMode.anyone),
            label: t.watchTogether.anyone,
            isPrimary: true,
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
      await widget.watchTogether.joinSession(sessionId, displayName: _plexDisplayName);
      await RecentRoomsService.addOrUpdateRoom(sessionId);
      if (mounted) setState(() => _recentRooms = RecentRoomsService.getRecentRooms());
    } catch (e) {
      appLogger.e('Failed to join session', error: e);
      if (mounted) {
        showErrorSnackBar(context, '${t.watchTogether.failedToJoin}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  Future<void> _enterRoom(RecentRoom room) async {
    setState(() => _enteringRoomCode = room.code);

    try {
      await widget.watchTogether.enterRoom(
        room.code,
        controlMode: room.controlMode ?? ControlMode.anyone,
        displayName: _plexDisplayName,
      );
      await RecentRoomsService.addOrUpdateRoom(room.code);
      if (mounted) setState(() => _recentRooms = RecentRoomsService.getRecentRooms());
    } catch (e) {
      appLogger.e('Failed to enter room', error: e);
      if (mounted) {
        showErrorSnackBar(context, '${t.watchTogether.failedToJoin}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _enteringRoomCode = null);
      }
    }
  }

  Future<void> _renameRoom(RecentRoom room) async {
    final controller = TextEditingController(text: room.name ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.watchTogether.renameRoom),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: room.code),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.common.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(t.common.save)),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !mounted) return;

    await RecentRoomsService.renameRoom(room.code, name.isEmpty ? null : name);
    setState(() => _recentRooms = RecentRoomsService.getRecentRooms());
  }

  Future<void> _removeRoom(RecentRoom room) async {
    await RecentRoomsService.removeRoom(room.code);
    setState(() => _recentRooms = RecentRoomsService.getRecentRooms());
  }
}

class _RecentRoomTile extends StatelessWidget {
  final RecentRoom room;
  final bool isBusy;
  final bool isEntering;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onRemove;

  const _RecentRoomTile({
    required this.room,
    required this.isBusy,
    required this.isEntering,
    required this.onTap,
    required this.onRename,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = room.name ?? room.code;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: FocusableWrapper(
        useBackgroundFocus: true,
        borderRadius: 12,
        onSelect: isBusy ? null : onTap,
        onLongPress: () => _showActions(context),
        child: ListTile(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          leading: isEntering ? const LoadingIndicatorBox(size: 24) : const Icon(Symbols.meeting_room_rounded),
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: room.name != null
              ? Text(
                  room.code,
                  style: TextStyle(fontFamily: 'monospace', color: theme.colorScheme.onSurfaceVariant),
                )
              : null,
          trailing: IconButton(icon: const Icon(Symbols.more_vert_rounded), onPressed: () => _showActions(context)),
          onTap: isBusy ? null : onTap,
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Symbols.edit_rounded),
              title: Text(t.watchTogether.renameRoom),
              onTap: () {
                Navigator.pop(context);
                onRename();
              },
            ),
            ListTile(
              leading: Icon(Symbols.delete_rounded, color: Theme.of(context).colorScheme.error),
              title: Text(t.watchTogether.removeRoom, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () {
                Navigator.pop(context);
                onRemove();
              },
            ),
          ],
        ),
      ),
    );
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
                              borderRadius: const BorderRadius.all(Radius.circular(12)),
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

        const SizedBox(height: 24),

        if (!watchTogether.isHost && watchTogether.hasCurrentPlayback) ...[
          _JoinCurrentPlaybackCard(watchTogether: watchTogether),
          const SizedBox(height: 16),
        ],

        // Leave/End Session Button
        SizedBox(
          width: double.infinity,
          child: FocusableButton(
            autofocus: watchTogether.isHost || !watchTogether.hasCurrentPlayback,
            onPressed: () => _leaveSession(context),
            child: OutlinedButton.icon(
              onPressed: () => _leaveSession(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
              ),
              icon: Icon(watchTogether.isHost ? Symbols.close_rounded : Symbols.logout_rounded),
              label: Text(watchTogether.isHost ? t.watchTogether.endSession : t.watchTogether.leaveSession),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _leaveSession(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: watchTogether.isHost ? t.watchTogether.endSessionQuestion : t.watchTogether.leaveSessionQuestion,
      message: watchTogether.isHost ? t.watchTogether.endSessionConfirm : t.watchTogether.leaveSessionConfirm,
      confirmText: watchTogether.isHost ? t.watchTogether.end : t.watchTogether.leave,
      isDestructive: true,
    );

    if (confirmed) {
      await watchTogether.leaveSession();
    }
  }
}

class _JoinCurrentPlaybackCard extends StatefulWidget {
  final WatchTogetherProvider watchTogether;

  const _JoinCurrentPlaybackCard({required this.watchTogether});

  @override
  State<_JoinCurrentPlaybackCard> createState() => _JoinCurrentPlaybackCardState();
}

class _JoinCurrentPlaybackCardState extends State<_JoinCurrentPlaybackCard> {
  bool _isJoining = false;

  Future<void> _joinCurrentPlayback() async {
    final ratingKey = widget.watchTogether.currentMediaRatingKey;
    final serverId = widget.watchTogether.currentMediaServerId;
    if (ratingKey == null || serverId == null) return;

    setState(() => _isJoining = true);

    try {
      await navigateToWatchTogetherPlayback(
        context,
        ratingKey: ratingKey,
        serverId: serverId,
        onBeforeNavigate: () {
          widget.watchTogether.markCurrentPlaybackHandled(ratingKey: ratingKey, serverId: serverId);
        },
      );
    } catch (e, stackTrace) {
      appLogger.e('WatchTogether: Failed to open current playback', error: e, stackTrace: stackTrace);
      if (mounted) {
        showErrorSnackBar(context, t.watchTogether.failedToOpenCurrentPlayback);
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaTitle = widget.watchTogether.currentMediaTitle;
    if (widget.watchTogether.isHost || mediaTitle == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Symbols.play_circle_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.watchTogether.currentPlayback, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        t.watchTogether.joinCurrentPlaybackDescription,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(mediaTitle, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FocusableButton(
                autofocus: true,
                onPressed: _isJoining ? null : _joinCurrentPlayback,
                child: FilledButton.icon(
                  onPressed: _isJoining ? null : _joinCurrentPlayback,
                  icon: _isJoining ? const LoadingIndicatorBox() : const Icon(Symbols.play_arrow_rounded),
                  label: Text(_isJoining ? t.watchTogether.joining : t.watchTogether.joinCurrentPlayback),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tappable session code row with copy functionality
class _SessionCodeRow extends StatelessWidget {
  final String sessionId;

  const _SessionCodeRow({required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FocusableWrapper(
      useBackgroundFocus: true,
      disableScale: true,
      borderRadius: 4,
      onSelect: () => _copySessionCode(context),
      child: InkWell(
        onTap: () => _copySessionCode(context),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
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
      ),
    );
  }

  void _copySessionCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: sessionId));
    showSnackBar(context, t.watchTogether.sessionCodeCopied);
  }
}

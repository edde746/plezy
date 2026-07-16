import 'dart:io';
import '../../media/ids.dart';

import 'package:flutter/material.dart';
import '../../utils/future_extensions.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../mixins/mounted_set_state_mixin.dart';
import '../../focus/focusable_button.dart';
import '../../focus/focusable_text_field.dart';
import '../../focus/focusable_wrapper.dart';
import '../../profiles/active_profile_provider.dart';
import '../../services/settings_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/dialogs.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/dialog_action_button.dart';
import '../../widgets/app_icon.dart';
import '../../utils/video_player_navigation.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/app_menu.dart';
import '../../widgets/overlay_sheet.dart';
import '../models/watch_session.dart';
import '../providers/watch_together_provider.dart';
import '../services/recent_rooms_service.dart';
import '../services/watch_together_peer_service.dart';
import '../widgets/join_session_dialog.dart';
import '../../widgets/loading_indicator_box.dart';

class WatchTogetherScreen extends StatelessWidget {
  const WatchTogetherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WatchTogetherProvider>(
      builder: (context, watchTogether, child) {
        final canGoBack = watchTogether.isHost || !watchTogether.isInSession;
        // The host owns sheet + system back: a back with the actions sheet open
        // closes it; otherwise the route pops only when [canGoBack] (a guest in
        // an active session can't leave). canGoBack==true also preserves the iOS
        // interactive swipe-back.
        return OverlaySheetHost(
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

class _NotInSessionViewState extends State<_NotInSessionView> with MountedSetStateMixin {
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
    final client = HttpClient();
    try {
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(Uri.parse(WatchTogetherPeerService.healthUrlFor(_customRelayUrl)));
      final response = await request.close().namedTimeout(
        const Duration(seconds: 5),
        operation: 'WatchTogether health check',
      );
      final body = await response.transform(const SystemEncoding().decoder).join();
      if (!mounted) return;
      setState(() => _healthOk = response.statusCode == 200 && body.trim() == 'ok');
    } catch (e) {
      appLogger.w('Watch Together health check failed', error: e);
      if (!mounted) return;
      setState(() => _healthOk = false);
    } finally {
      client.close(force: true);
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
            mainAxisSize: .min,
            children: [
              AppIcon(Symbols.group_rounded, size: 80, color: theme.colorScheme.primary),
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
                        AppIcon(Symbols.warning_rounded, color: theme.colorScheme.onErrorContainer),
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
                  useBackgroundFocus: true,
                  child: FilledButton.icon(
                    onPressed: _isBusy ? null : _createSession,
                    icon: _isCreating ? const LoadingIndicatorBox(size: 20) : const AppIcon(Symbols.add_rounded),
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
                    icon: _isJoining ? const LoadingIndicatorBox(size: 20) : const AppIcon(Symbols.group_add_rounded),
                    label: Text(_isJoining ? t.watchTogether.joining : t.watchTogether.joinSession),
                  ),
                ),
              ),
              if (_recentRooms.isNotEmpty) ...[
                const SizedBox(height: 32),
                Align(
                  alignment: .centerLeft,
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
      setStateIfMounted(() => _recentRooms = RecentRoomsService.getRecentRooms());
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
    return showScopedDialog<ControlMode>(
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
      setStateIfMounted(() => _recentRooms = RecentRoomsService.getRecentRooms());
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
      setStateIfMounted(() => _recentRooms = RecentRoomsService.getRecentRooms());
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
    final name = await showScopedDialog<String>(
      context: context,
      builder: (_) => _RenameRoomDialog(room: room),
    );
    if (name == null || !mounted) return;

    await RecentRoomsService.renameRoom(room.code, name.isEmpty ? null : name);
    setStateIfMounted(() => _recentRooms = RecentRoomsService.getRecentRooms());
  }

  Future<void> _removeRoom(RecentRoom room) async {
    await RecentRoomsService.removeRoom(room.code);
    setStateIfMounted(() => _recentRooms = RecentRoomsService.getRecentRooms());
  }
}

class _RenameRoomDialog extends StatefulWidget {
  final RecentRoom room;

  const _RenameRoomDialog({required this.room});

  @override
  State<_RenameRoomDialog> createState() => _RenameRoomDialogState();
}

class _RenameRoomDialogState extends State<_RenameRoomDialog> {
  late final _controller = TextEditingController(text: widget.room.name ?? '');
  final _fieldFocusNode = FocusNode(debugLabel: 'WatchTogetherRenameField');
  final _cancelFocusNode = FocusNode(debugLabel: 'WatchTogetherRenameCancel');
  final _saveFocusNode = FocusNode(debugLabel: 'WatchTogetherRenameSave');

  @override
  void dispose() {
    _fieldFocusNode.dispose();
    _cancelFocusNode.dispose();
    _saveFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) {
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(t.watchTogether.renameRoom),
      content: FocusableTextField(
        controller: _controller,
        focusNode: _fieldFocusNode,
        autofocus: true,
        decoration: InputDecoration(hintText: widget.room.code),
        onNavigateDown: _saveFocusNode.requestFocus,
        onSubmitted: _submit,
      ),
      actions: [
        DialogActionButton(
          focusNode: _cancelFocusNode,
          onPressed: () => Navigator.pop(context),
          onNavigateRight: _saveFocusNode.requestFocus,
          label: t.common.cancel,
        ),
        DialogActionButton(
          focusNode: _saveFocusNode,
          onPressed: () => _submit(_controller.text),
          onNavigateLeft: _cancelFocusNode.requestFocus,
          isPrimary: true,
          label: t.common.save,
        ),
      ],
    );
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
        // Hold SELECT/OK to open the rename/remove menu on TV/dpad (matches media cards).
        enableLongPress: true,
        // The wrapper owns key handling; the ListTile's InkWell and the trailing
        // more_vert IconButton must not steal focus from the long-press handler.
        descendantsAreFocusable: false,
        onSelect: isBusy ? null : onTap,
        onLongPress: () => _showActions(context),
        child: Material(
          type: MaterialType.transparency,
          child: ListTile(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            leading: isEntering ? const LoadingIndicatorBox(size: 24) : const AppIcon(Symbols.meeting_room_rounded),
            title: Text(title, maxLines: 1, overflow: .ellipsis),
            subtitle: room.name != null
                ? Text(
                    room.code,
                    style: TextStyle(fontFamily: 'monospace', color: theme.colorScheme.onSurfaceVariant),
                  )
                : null,
            trailing: IconButton(
              icon: const AppIcon(Symbols.more_vert_rounded),
              onPressed: () => _showActions(context),
            ),
            onTap: isBusy ? null : onTap,
            onLongPress: () => _showActions(context),
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    OverlaySheetController.of(context).show(
      showDragHandle: true,
      builder: (context) => AppMenuSheet<String>(
        entries: [
          AppMenuItem(value: 'rename', icon: Symbols.edit_rounded, label: t.watchTogether.renameRoom),
          AppMenuItem(
            value: 'remove',
            icon: Symbols.delete_rounded,
            label: t.watchTogether.removeRoom,
            destructive: true,
          ),
        ],
        onSelected: (value) {
          if (value == 'rename') {
            onRename();
          } else if (value == 'remove') {
            onRemove();
          }
        },
      ),
    );
  }
}

class _ActiveSessionContent extends StatelessWidget {
  final WatchTogetherProvider watchTogether;

  const _ActiveSessionContent({required this.watchTogether});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = watchTogether.session!;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Row(
                  children: [
                    AppIcon(
                      watchTogether.isHost ? Symbols.star_rounded : Symbols.group_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: .start,
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
                    AppIcon(
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

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Row(
                  children: [
                    AppIcon(Symbols.people_rounded, color: theme.colorScheme.primary),
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
                        AppIcon(
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
              icon: AppIcon(watchTogether.isHost ? Symbols.close_rounded : Symbols.logout_rounded),
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
        serverId: ServerId(serverId),
        onBeforeNavigate: () {
          widget.watchTogether.markCurrentPlaybackHandled(ratingKey: ratingKey, serverId: ServerId(serverId));
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
          crossAxisAlignment: .start,
          children: [
            Row(
              children: [
                AppIcon(Symbols.play_circle_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
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
                useBackgroundFocus: true,
                child: FilledButton.icon(
                  onPressed: _isJoining ? null : _joinCurrentPlayback,
                  icon: _isJoining ? const LoadingIndicatorBox() : const AppIcon(Symbols.play_arrow_rounded),
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
            mainAxisSize: .min,
            children: [
              Text(
                '${t.watchTogether.sessionCode}: $sessionId',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              AppIcon(Symbols.content_copy_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
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

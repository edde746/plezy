import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../games/game_session_exchange.dart';
import '../../i18n/strings.g.dart';
import '../../i18n/presentation_formats.dart';
import '../../utils/dialogs.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_menu.dart';
import '../../widgets/dialog_action_button.dart';

class GameSessionsDialog extends StatefulWidget {
  const GameSessionsDialog({super.key, required this.request, required this.isCurrent});
  final Future<GameSessionControlReply> Function(GameSessionAction, {String? target}) request;
  final bool Function() isCurrent;
  @override
  State<GameSessionsDialog> createState() => _GameSessionsDialogState();
}

class _GameSessionsDialogState extends State<GameSessionsDialog> {
  List<RemoteGameSession> _sessions = const [];
  bool _busy = false;
  GameSessionControlStatus? _status;

  Future<GameSessionControlReply> _request(GameSessionAction action, {String? target}) async {
    try {
      return await widget.request(action, target: target);
    } catch (_) {
      return const GameSessionControlReply(GameSessionControlStatus.unavailable);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_busy || !widget.isCurrent()) return;
    setState(() => _busy = true);
    final reply = await _request(GameSessionAction.list);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = widget.isCurrent() ? reply.status : GameSessionControlStatus.unavailable;
      _sessions = widget.isCurrent() && reply.status == GameSessionControlStatus.ok ? reply.sessions : const [];
    });
  }

  Future<void> _act(RemoteGameSession session, GameSessionAction action) async {
    if (_busy || !widget.isCurrent()) return;
    if (action == GameSessionAction.disconnect) {
      final confirmed = await showConfirmDialog(
        context,
        title: t.games.disconnect,
        message: '${isolateDisplayText(session.title)}\n\n${t.games.disconnectHelp}',
        confirmText: t.games.disconnect,
      );
      if (!confirmed || !mounted || !widget.isCurrent()) return;
    }
    setState(() => _busy = true);
    final reply = await _request(action, target: session.id);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = widget.isCurrent() ? reply.status : GameSessionControlStatus.unavailable;
      // A result is an acknowledgement, not an authoritative new snapshot.
      _sessions = const [];
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(t.games.remoteSessions),
    scrollable: true,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.games.remoteSessionsHelp),
        if (_busy) ...[const SizedBox(height: 12), const LinearProgressIndicator()],
        if (_status != null && _status != GameSessionControlStatus.ok)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Semantics(
              liveRegion: true,
              child: Text(switch (_status!) {
                GameSessionControlStatus.denied => t.games.remoteSessionsDenied,
                GameSessionControlStatus.submitted => t.games.remoteSessionSubmitted,
                _ => t.games.remoteSessionsUnavailable,
              }),
            ),
          ),
        if (_status == GameSessionControlStatus.ok && _sessions.isEmpty)
          Padding(padding: const EdgeInsets.only(top: 12), child: Text(t.games.noRemoteSessions)),
        for (final session in _sessions)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(isolateDisplayText(session.title)),
            leading: AppIcon(session.audible ? Symbols.volume_up_rounded : Symbols.volume_off_rounded),
            subtitle: Text(session.audible ? t.games.remoteSessionAudible : t.games.remoteSessionMuted),
            trailing: AppMenuButton<GameSessionAction>(
              tooltip: t.games.remoteSessionActions,
              adaptiveSheet: true,
              icon: const AppIcon(Symbols.more_vert_rounded),
              entriesBuilder: (_) => _busy || !widget.isCurrent()
                  ? []
                  : [
                      AppMenuItem(
                        value: GameSessionAction.listen,
                        label: t.games.remoteSessionListen,
                        icon: Symbols.volume_up_rounded,
                      ),
                      AppMenuItem(
                        value: GameSessionAction.mute,
                        label: t.games.remoteSessionMute,
                        icon: Symbols.volume_off_rounded,
                      ),
                      AppMenuItem(
                        value: GameSessionAction.fullscreen,
                        label: t.companionRemote.remote.fullscreen,
                        icon: Symbols.fullscreen_rounded,
                      ),
                      AppMenuItem(
                        value: GameSessionAction.disconnect,
                        label: t.games.disconnect,
                        icon: Symbols.stop_rounded,
                      ),
                    ],
              onSelected: (action) => _act(session, action),
            ),
          ),
      ],
    ),
    actions: [
      DialogActionButton(label: t.common.close, onPressed: () => Navigator.pop(context)),
      DialogActionButton(label: t.games.remoteSessionsRefresh, onPressed: _busy ? null : _load),
    ],
  );
}

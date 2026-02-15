import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../utils/app_logger.dart';
import '../../utils/dialogs.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../models/watch_session.dart';
import '../providers/watch_together_provider.dart';
import '../services/watch_together_peer_service.dart';
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
  bool? _healthOk;

  @override
  void initState() {
    super.initState();
    _checkHealth();
  }

  Future<void> _checkHealth() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(Uri.parse(WatchTogetherPeerService.healthUrl));
      final response = await request.close().timeout(const Duration(seconds: 5));
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
                child: FilledButton.icon(
                  autofocus: true,
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
    );
  }

  Future<void> _createSession() async {
    final controlMode = await _showControlModeDialog();
    if (controlMode == null || !mounted) return;

    setState(() => _isCreating = true);

    try {
      await widget.watchTogether.createSession(controlMode: controlMode);
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

  Future<ControlMode?> _showControlModeDialog() {
    const buttonPadding = EdgeInsets.symmetric(horizontal: 18, vertical: 14);
    const buttonShape = StadiumBorder();
    return showDialog<ControlMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.watchTogether.controlMode),
        content: Text(t.watchTogether.controlModeQuestion),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(padding: buttonPadding, shape: buttonShape),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ControlMode.hostOnly),
            style: TextButton.styleFrom(padding: buttonPadding, shape: buttonShape),
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

        const SizedBox(height: 24),

        // Leave/End Session Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            autofocus: true,
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

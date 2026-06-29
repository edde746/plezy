import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../connection/connection.dart';
import '../../connection/connection_registry.dart';
import '../../focus/focusable_button.dart';
import '../../focus/focusable_wrapper.dart';
import '../../i18n/strings.g.dart';
import '../../providers/seerr_session_provider.dart';
import '../../utils/dialogs.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/loading_indicator_box.dart';
import 'add_seerr_screen.dart';

/// Manage configured Seerr instances. Lists each [SeerrConnection] with
/// per-row actions: sign out (clear session), make default, remove. A
/// trailing button kicks off the add-instance flow.
class SeerrSettingsScreen extends StatefulWidget {
  const SeerrSettingsScreen({super.key});

  @override
  State<SeerrSettingsScreen> createState() => _SeerrSettingsScreenState();
}

class _SeerrSettingsScreenState extends State<SeerrSettingsScreen> {
  late Future<List<SeerrConnection>> _instancesFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _instancesFuture = _load();
  }

  Future<List<SeerrConnection>> _load() async {
    final registry = context.read<ConnectionRegistry>();
    return registry.listSeerr();
  }

  void _refresh() {
    setState(() => _instancesFuture = _load());
  }

  Future<void> _signOut(SeerrConnection conn) async {
    final session = context.read<SeerrSessionProvider>();
    final isActive = session.connection?.id == conn.id;
    if (!isActive) {
      // Signing out a non-active instance: just blank the cookie on the row.
      final registry = context.read<ConnectionRegistry>();
      await registry.upsert(conn.copyWith(sessionCookie: '', sessionCookieCapturedAt: null));
      if (!mounted) return;
      showSuccessSnackBar(context, t.seerr.settings.signedOut(label: conn.instanceLabel));
      _refresh();
      return;
    }
    setState(() => _busy = true);
    try {
      await session.disconnect();
      if (!mounted) return;
      showSuccessSnackBar(context, t.seerr.settings.signedOut(label: conn.instanceLabel));
      _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(SeerrConnection conn) async {
    final confirmed = await showDeleteConfirmation(
      context,
      title: t.seerr.settings.removeTitle,
      message: t.seerr.settings.removeBody(label: conn.instanceLabel),
      confirmText: t.common.delete,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      final session = context.read<SeerrSessionProvider>();
      final registry = context.read<ConnectionRegistry>();
      final isActive = session.connection?.id == conn.id;
      if (isActive) {
        await session.disconnect();
      }
      await registry.remove(conn.id);
      if (!mounted) return;
      showSuccessSnackBar(context, t.seerr.settings.removed(label: conn.instanceLabel));
      _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addInstance() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddSeerrScreen()),
    );
    if (added == true && mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return FocusedScrollScaffold(
      title: Text(t.seerr.settings.title),
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                t.seerr.settings.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            FutureBuilder<List<SeerrConnection>>(
              future: _instancesFuture,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(padding: EdgeInsets.all(24), child: Center(child: LoadingIndicatorBox()));
                }
                final instances = snap.data ?? const <SeerrConnection>[];
                if (instances.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(t.seerr.settings.empty, style: Theme.of(context).textTheme.bodySmall),
                  );
                }
                return Column(
                  children: [
                    for (final conn in instances)
                      _InstanceRow(
                        connection: conn,
                        busy: _busy,
                        onSignOut: () => _signOut(conn),
                        onRemove: () => _remove(conn),
                      ),
                  ],
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: FocusableButton(
                onPressed: _busy ? null : _addInstance,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _addInstance,
                  icon: const AppIcon(Symbols.add_rounded, fill: 1),
                  label: Text(t.seerr.settings.addInstance),
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

class _InstanceRow extends StatelessWidget {
  final SeerrConnection connection;
  final bool busy;
  final VoidCallback onSignOut;
  final VoidCallback onRemove;

  const _InstanceRow({
    required this.connection,
    required this.busy,
    required this.onSignOut,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final signedIn = connection.sessionCookie.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: FocusableWrapper(
        disableScale: true,
        borderRadius: 12,
        descendantsAreFocusable: true,
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppIcon(Symbols.playlist_add_check_rounded, fill: 1, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(connection.instanceLabel, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            connection.baseUrl,
                            style: theme.textTheme.bodySmall?.copyWith(color: muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            signedIn
                                ? t.seerr.settings.signedInAs(user: connection.jellyfinUsername)
                                : t.seerr.settings.notSignedIn,
                            style: theme.textTheme.bodySmall?.copyWith(color: muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (signedIn)
                      FocusableButton(
                        onPressed: busy ? null : onSignOut,
                        child: OutlinedButton.icon(
                          onPressed: busy ? null : onSignOut,
                          icon: const AppIcon(Symbols.logout_rounded, fill: 1, size: 18),
                          label: Text(t.seerr.settings.signOut),
                        ),
                      ),
                    FocusableButton(
                      onPressed: busy ? null : onRemove,
                      child: OutlinedButton.icon(
                        onPressed: busy ? null : onRemove,
                        icon: const AppIcon(Symbols.delete_rounded, fill: 1, size: 18),
                        label: Text(t.seerr.settings.remove),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

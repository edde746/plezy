import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../connection/connection.dart';
import '../../connection/connection_registry.dart';
import '../../i18n/strings.g.dart';
import '../../models/plex/plex_home_user.dart';
import '../../profiles/active_profile_binder.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/plex_home_service.dart';
import '../../profiles/profile.dart';
import '../../profiles/profile_avatar.dart';
import '../../profiles/profile_connection.dart';
import '../../profiles/profile_connection_registry.dart';
import '../../profiles/profile_registry.dart';
import '../../profiles/profiles_view.dart';
import '../../providers/download_provider.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/backend_badge.dart';
import '../../widgets/desktop_app_bar.dart';
import '../../utils/dialogs.dart';
import '../settings/add_connection_screen.dart';
import 'pin_entry_dialog.dart';
import 'pin_status_row.dart';
import 'profile_name_field.dart';

/// Manage one [Profile] — rename, change PIN, list/add/remove
/// connections, set the default connection.
///
/// Plex Home profiles can't be renamed (Plex owns the display name); their
/// PIN lives on Plex too — both fields are read-only here. They can still
/// pick up additional connections via the borrow flow.
class ProfileDetailScreen extends StatefulWidget {
  final Profile profile;

  const ProfileDetailScreen({super.key, required this.profile});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  late final TextEditingController _nameController;
  late Profile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _nameController = TextEditingController(text: widget.profile.displayName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || name == _profile.displayName) return;
    final updated = _profile.copyWith(displayName: name);
    await context.read<ProfileRegistry>().upsert(updated);
    if (!mounted) return;
    setState(() => _profile = updated);
    showSuccessSnackBar(context, 'Profile renamed.');
  }

  Future<void> _setPin() async {
    final pin = await captureAndConfirmPin(context, onMismatch: (ctx) => showErrorSnackBar(ctx, "PINs don't match"));
    if (pin == null || !mounted) return;
    final updated = _profile.copyWith(pinHash: computePinHash(pin));
    await context.read<ProfileRegistry>().upsert(updated);
    if (!mounted) return;
    setState(() => _profile = updated);
  }

  Future<void> _clearPin() async {
    final updated = _profile.copyWith(clearPin: true);
    await context.read<ProfileRegistry>().upsert(updated);
    if (!mounted) return;
    setState(() => _profile = updated);
  }

  Future<void> _addConnection() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddConnectionScreen(targetProfile: _profile)));
  }

  Future<void> _removeConnection(ProfileConnection pc, Connection conn) async {
    final confirmed = await showConfirmDialog(
      context,
      title: t.profiles.removeConnectionTitle,
      message: t.profiles.removeConnectionMessage(
        displayName: _profile.displayName,
        connectionLabel: conn.displayLabel,
      ),
      confirmText: t.profiles.removeConnection,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    await context.read<DownloadProvider>().releaseDownloadsForProfileServers(
      _profile.id,
      _serverIdsForConnection(conn),
    );
    if (!mounted) return;
    await context.read<ProfileConnectionRegistry>().remove(_profile.id, pc.connectionId);
    if (!mounted) return;
    unawaited(context.read<ActiveProfileBinder>().rebindIfActive(_profile.id));
  }

  Set<String> _serverIdsForConnection(Connection conn) {
    return switch (conn) {
      PlexAccountConnection(:final servers) => servers.map((s) => s.clientIdentifier).toSet(),
      JellyfinConnection(:final serverMachineId) => {serverMachineId},
    };
  }

  Future<void> _deleteProfile() async {
    final confirmed = await showDeleteConfirmation(
      context,
      title: t.profiles.deleteProfileTitle,
      message: t.profiles.deleteProfileMessage(displayName: _profile.displayName),
      confirmText: t.common.delete,
    );
    if (!confirmed || !mounted) return;
    final pcRegistry = context.read<ProfileConnectionRegistry>();
    final profileRegistry = context.read<ProfileRegistry>();
    final downloadProvider = context.read<DownloadProvider>();
    final active = context.read<ActiveProfileProvider>();
    final wasActive = active.activeId == _profile.id;
    await downloadProvider.deleteDownloadsForProfile(_profile.id);
    await pcRegistry.removeAllForProfile(_profile.id);
    await profileRegistry.remove(_profile.id);
    if (wasActive) {
      final remaining = active.profiles.where((p) => p.id != _profile.id).toList();
      if (remaining.isNotEmpty) {
        await active.activate(remaining.first);
      } else {
        await active.clearActiveProfile();
      }
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLocal = _profile.isLocal;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          ExcludeFocus(child: CustomAppBar(title: Text(_profile.displayName), pinned: true)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Center(child: ProfileAvatar(profile: _profile, size: 96)),
                const SizedBox(height: 24),
                Text(t.profiles.profileNameLabel, style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                if (isLocal)
                  ProfileNameField(
                    controller: _nameController,
                    onChanged: () => setState(() {}),
                    trailing: FilledButton(
                      onPressed:
                          _nameController.text.trim().isEmpty || _nameController.text.trim() == _profile.displayName
                          ? null
                          : _saveName,
                      child: Text(t.common.save),
                    ),
                  )
                else
                  Text(
                    _profile.displayName,
                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                const SizedBox(height: 24),
                Text(t.profiles.pinProtectionLabel, style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                if (!isLocal)
                  Text(
                    _profile.plexProtected ? t.profiles.pinManagedByPlex : t.profiles.noPinSetEditOnPlex,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  )
                else if (_profile.pinHash == null)
                  OutlinedButton.icon(
                    onPressed: _setPin,
                    icon: const AppIcon(Symbols.lock_outline_rounded, fill: 1),
                    label: Text(t.profiles.setPin),
                  )
                else
                  PinStatusRow(onChange: _setPin, onRemove: _clearPin),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(child: Text(t.profiles.connectionsLabel, style: theme.textTheme.labelLarge)),
                    TextButton.icon(
                      onPressed: _addConnection,
                      icon: const AppIcon(Symbols.add_rounded, fill: 1),
                      label: Text(t.profiles.add),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _ConnectionsList(profile: _profile, onRemove: _removeConnection),
                const SizedBox(height: 24),
                if (isLocal)
                  OutlinedButton.icon(
                    onPressed: _deleteProfile,
                    icon: AppIcon(Symbols.delete_outline_rounded, fill: 1, color: theme.colorScheme.error),
                    label: Text(t.profiles.deleteProfileButton, style: TextStyle(color: theme.colorScheme.error)),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionsList extends StatelessWidget {
  final Profile profile;
  final Future<void> Function(ProfileConnection pc, Connection conn) onRemove;

  const _ConnectionsList({required this.profile, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pcRegistry = context.read<ProfileConnectionRegistry>();
    final connRegistry = context.read<ConnectionRegistry>();
    final plexHome = context.read<PlexHomeService>();

    return StreamBuilder<List<ProfileConnection>>(
      stream: pcRegistry.watchForProfile(profile.id),
      builder: (context, snapshot) {
        final pcs = snapshot.data ?? const <ProfileConnection>[];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return StreamBuilder<Map<String, List<PlexHomeUser>>>(
          stream: plexHome.stream,
          initialData: plexHome.current,
          builder: (context, homeSnap) {
            final homeCache = homeSnap.data ?? const <String, List<PlexHomeUser>>{};
            return FutureBuilder<List<Connection>>(
              future: connRegistry.list(),
              builder: (context, snap) {
                final all = snap.data ?? const <Connection>[];
                final byId = {for (final c in all) c.id: c};
                // Plex Home profiles have an implicit parent connection that
                // isn't in the join table — list it first so the user sees the
                // full picture. It can't be removed (the profile *is* a home
                // user of that account) and isn't shown for locals.
                final parentConn = profile.isPlexHome ? byId[profile.parentConnectionId] : null;
                final visiblePcs = visibleProfileConnections(profile, pcs);
                if (visiblePcs.isEmpty && parentConn == null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      t.profiles.noConnectionsHint,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                    ),
                  );
                }
                return Column(
                  children: [
                    if (parentConn != null)
                      Card(
                        child: ListTile(
                          leading: BackendBadge(backend: parentConn.backend, size: 24),
                          title: Text(parentConn.displayLabel),
                          subtitle: Text(t.profiles.plexHomeAccount),
                        ),
                      ),
                    for (final pc in visiblePcs)
                      if (byId[pc.connectionId] case final conn?)
                        Card(
                          child: ListTile(
                            leading: BackendBadge(backend: conn.backend, size: 24),
                            title: Text(conn.displayLabel),
                            subtitle: _ConnectionSubtitle.build(conn: conn, pc: pc, homeCache: homeCache, theme: theme),
                            trailing: PopupMenuButton<String>(
                              itemBuilder: (_) => [
                                if (!pc.isDefault)
                                  PopupMenuItem(
                                    value: 'default',
                                    onTap: () => WidgetsBinding.instance.addPostFrameCallback(
                                      (_) => pcRegistry.setDefault(profile.id, pc.connectionId),
                                    ),
                                    child: Text(t.profiles.makeDefault),
                                  ),
                                PopupMenuItem(
                                  value: 'remove',
                                  onTap: () => WidgetsBinding.instance.addPostFrameCallback((_) => onRemove(pc, conn)),
                                  child: Text(t.profiles.removeConnection),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Renders the "as {homeUser} · Default" sub-line under each connection
/// row. The home-user lookup turns the bare account label (e.g. the
/// owner's email) into something the user can match to the picker —
/// otherwise borrowed-from-different-home connections look identical.
class _ConnectionSubtitle {
  static Widget? build({
    required Connection conn,
    required ProfileConnection pc,
    required Map<String, List<PlexHomeUser>> homeCache,
    required ThemeData theme,
  }) {
    final parts = <String>[];
    if (conn is PlexAccountConnection) {
      final users = homeCache[conn.id];
      if (users != null) {
        final user = users.where((u) => u.uuid == pc.userIdentifier).firstOrNull;
        if (user != null) parts.add('as ${user.displayName}');
      }
    }
    if (pc.isDefault) parts.add(t.profiles.connectionDefault);
    if (parts.isEmpty) return null;
    return Text(parts.join(' · '));
  }
}

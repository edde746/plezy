import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../connection/connection.dart';
import '../../connection/connection_registry.dart';
import '../../i18n/strings.g.dart';
import '../../mixins/controller_disposer_mixin.dart';
import '../../models/plex/plex_home_user.dart';
import '../../profiles/active_profile_binder.dart';
import '../../profiles/plex_home_service.dart';
import '../../profiles/profile.dart';
import '../../profiles/profile_avatar.dart';
import '../../profiles/profile_connection_cleanup.dart';
import '../../profiles/profile_connection.dart';
import '../../profiles/profile_connection_registry.dart';
import '../../profiles/profile_registry.dart';
import '../../profiles/profiles_view.dart';
import '../../providers/download_provider.dart';
import '../../providers/hidden_libraries_provider.dart';
import '../../providers/multi_server_provider.dart';
import '../../services/storage_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../focus/focusable_button.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_menu.dart';
import '../../widgets/backend_badge.dart';
import '../../widgets/focusable_popup_menu_button.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../utils/dialogs.dart';
import '../settings/add_connection_screen.dart';
import '../settings/edit_jellyfin_connection_screen.dart';
import 'pin_entry_dialog.dart';
import 'pin_status_row.dart';
import 'profile_delete_flow.dart';
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

class _ProfileDetailScreenState extends State<ProfileDetailScreen> with ControllerDisposerMixin {
  late final TextEditingController _nameController = createTextEditingController(text: widget.profile.displayName);
  final _nameFocusNode = FocusNode(debugLabel: 'ProfileDetail:Name');
  final _saveNameFocusNode = FocusNode(debugLabel: 'ProfileDetail:SaveName');
  final _setPinFocusNode = FocusNode(debugLabel: 'ProfileDetail:SetPin');
  final _addConnectionFocusNode = FocusNode(debugLabel: 'ProfileDetail:AddConnection');
  final _deleteProfileFocusNode = FocusNode(debugLabel: 'ProfileDetail:DeleteProfile');
  late Profile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _saveNameFocusNode.dispose();
    _setPinFocusNode.dispose();
    _addConnectionFocusNode.dispose();
    _deleteProfileFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || name == _profile.displayName) return;
    final updated = _profile.copyWith(displayName: name);
    await context.read<ProfileRegistry>().upsert(updated);
    if (!mounted) return;
    setState(() => _profile = updated);
    showSuccessSnackBar(context, t.profiles.profileRenamed);
  }

  Future<void> _setPin() async {
    final pin = await captureAndConfirmPin(
      context,
      onMismatch: (ctx) => showErrorSnackBar(ctx, t.profiles.pinsDontMatch),
    );
    if (pin == null || !mounted) return;
    final profile = _profile;
    if (profile is! LocalProfile) return;
    final updated = profile.copyWith(pinHash: computePinHash(pin));
    await context.read<ProfileRegistry>().upsert(updated);
    if (!mounted) return;
    setState(() => _profile = updated);
  }

  Future<void> _clearPin() async {
    final profile = _profile;
    if (profile is! LocalProfile) return;
    final updated = profile.copyWith(pinHash: null);
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
    await removeProfileConnectionAndCleanup(
      profileId: _profile.id,
      connection: conn,
      profileConnections: context.read<ProfileConnectionRegistry>(),
      connections: context.read<ConnectionRegistry>(),
      storage: context.read<StorageService>(),
      serverManager: context.read<MultiServerProvider>().serverManager,
    );
    if (!mounted) return;
    await Provider.maybeOf<HiddenLibrariesProvider>(context, listen: false)?.refresh();
    if (!mounted) return;
    unawaited(context.read<ActiveProfileBinder>().rebindIfActive(_profile.id));
  }

  Future<void> _editConnection(Connection conn) async {
    if (conn is! JellyfinConnection) return;
    final changed = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => EditJellyfinConnectionScreen(connection: conn)));
    if (changed != true || !mounted) return;
    setState(() {});
    unawaited(context.read<ActiveProfileBinder>().rebindIfActive(_profile.id));
  }

  Set<String> _serverIdsForConnection(Connection conn) {
    return switch (conn) {
      PlexAccountConnection(:final servers) => servers.map((s) => s.clientIdentifier).toSet(),
      JellyfinConnection(:final serverMachineId) => {serverMachineId},
    };
  }

  Future<void> _deleteProfile() async {
    final deleted = await confirmAndDeleteProfile(
      context,
      profile: _profile,
      title: t.profiles.deleteProfileTitle,
      message: t.profiles.deleteProfileMessage(displayName: _profile.displayName),
      confirmText: t.common.delete,
    );
    if (!deleted || !mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLocal = _profile.isLocal;

    return FocusedScrollScaffold(
      title: Text(_profile.displayName),
      slivers: [
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
                  focusNode: _nameFocusNode,
                  onChanged: () => setState(() {}),
                  onNavigateRight: _saveNameFocusNode.requestFocus,
                  trailing: FocusableButton(
                    focusNode: _saveNameFocusNode,
                    onNavigateLeft: _nameFocusNode.requestFocus,
                    onPressed:
                        _nameController.text.trim().isEmpty || _nameController.text.trim() == _profile.displayName
                        ? null
                        : _saveName,
                    child: FilledButton(
                      onPressed:
                          _nameController.text.trim().isEmpty || _nameController.text.trim() == _profile.displayName
                          ? null
                          : _saveName,
                      child: Text(t.common.save),
                    ),
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
                FocusableButton(
                  focusNode: _setPinFocusNode,
                  onPressed: _setPin,
                  child: OutlinedButton.icon(
                    onPressed: _setPin,
                    icon: const AppIcon(Symbols.lock_outline_rounded, fill: 1),
                    label: Text(t.profiles.setPin),
                  ),
                )
              else
                PinStatusRow(onChange: _setPin, onRemove: _clearPin),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: Text(t.profiles.connectionsLabel, style: theme.textTheme.labelLarge)),
                  FocusableButton(
                    focusNode: _addConnectionFocusNode,
                    onPressed: _addConnection,
                    child: TextButton.icon(
                      onPressed: _addConnection,
                      icon: const AppIcon(Symbols.add_rounded, fill: 1),
                      label: Text(t.profiles.add),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _ConnectionsList(profile: _profile, onRemove: _removeConnection, onEdit: _editConnection),
              const SizedBox(height: 24),
              if (isLocal)
                FocusableButton(
                  focusNode: _deleteProfileFocusNode,
                  onPressed: _deleteProfile,
                  child: OutlinedButton.icon(
                    onPressed: _deleteProfile,
                    icon: AppIcon(Symbols.delete_outline_rounded, fill: 1, color: theme.colorScheme.error),
                    label: Text(t.profiles.deleteProfileButton, style: TextStyle(color: theme.colorScheme.error)),
                  ),
                ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ConnectionsList extends StatelessWidget {
  final Profile profile;
  final Future<void> Function(ProfileConnection pc, Connection conn) onRemove;
  final Future<void> Function(Connection conn) onEdit;

  const _ConnectionsList({required this.profile, required this.onRemove, required this.onEdit});

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
            padding: .symmetric(vertical: 20),
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
                            trailing: FocusablePopupMenuButton<String>(
                              icon: const AppIcon(Symbols.more_vert_rounded, fill: 1),
                              tooltip: t.profiles.manage,
                              onSelected: (value) {
                                if (value == 'default') {
                                  unawaited(pcRegistry.setDefault(profile.id, pc.connectionId));
                                } else if (value == 'edit') {
                                  unawaited(onEdit(conn));
                                } else if (value == 'remove') {
                                  unawaited(onRemove(pc, conn));
                                }
                              },
                              itemBuilder: (_) => [
                                if (!pc.isDefault) AppMenuItem(value: 'default', label: t.profiles.makeDefault),
                                if (conn is JellyfinConnection) AppMenuItem(value: 'edit', label: t.common.edit),
                                AppMenuItem(value: 'remove', label: t.profiles.removeConnection),
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
        if (user != null) parts.add(t.profiles.connectionAs(displayName: user.displayName));
      }
    }
    if (pc.isDefault) parts.add(t.profiles.connectionDefault);
    if (parts.isEmpty) return null;
    return Text(parts.join(' · '));
  }
}

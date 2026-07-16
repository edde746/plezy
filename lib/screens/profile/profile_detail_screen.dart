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
import '../../widgets/settings_section.dart';
import '../../utils/dialogs.dart';
import '../settings/add_connection_screen.dart';
import '../settings/edit_jellyfin_connection_screen.dart';
import 'pin_entry_dialog.dart';
import 'pin_status_row.dart';
import 'profile_teardown.dart';
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
  final _changePinFocusNode = FocusNode(debugLabel: 'ProfileDetail:ChangePin');
  final _addConnectionFocusNode = FocusNode(debugLabel: 'ProfileDetail:AddConnection');
  final _deleteProfileFocusNode = FocusNode(debugLabel: 'ProfileDetail:DeleteProfile');
  late Profile _profile;
  StreamSubscription<List<Profile>>? _profileSub;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    // Keep the snapshot live: the registry row can change underneath this
    // screen (rename from another surface, PIN cleared elsewhere) and the
    // header/PIN section would otherwise show stale state until reopened.
    if (_profile.isLocal) {
      _profileSub = context.read<ProfileRegistry>().watchProfiles().listen((locals) {
        Profile? updated;
        for (final p in locals) {
          if (p.id == _profile.id) {
            updated = p;
            break;
          }
        }
        if (updated == null || updated == _profile || !mounted) return;
        final namePristine = _nameController.text.trim() == _profile.displayName;
        setState(() {
          _profile = updated!;
          if (namePristine) _nameController.text = updated.displayName;
        });
      });
    }
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    _nameFocusNode.dispose();
    _saveNameFocusNode.dispose();
    _setPinFocusNode.dispose();
    _changePinFocusNode.dispose();
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
    final hadPin = profile.pinHash != null;
    final updated = profile.copyWith(pinHash: computePinHash(pin));
    await context.read<ProfileRegistry>().upsert(updated);
    if (!mounted) return;
    setState(() => _profile = updated);
    if (!hadPin) {
      // The Set PIN button (and its focus node) just left the tree — hand
      // DPAD focus to the replacing row instead of dropping it.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _changePinFocusNode.requestFocus();
      });
    }
  }

  Future<void> _clearPin() async {
    final profile = _profile;
    if (profile is! LocalProfile) return;
    final updated = profile.copyWith(pinHash: null);
    await context.read<ProfileRegistry>().upsert(updated);
    if (!mounted) return;
    setState(() => _profile = updated);
    // Reverse swap of _setPin: the row (and the focused Remove button)
    // just left the tree.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _setPinFocusNode.requestFocus();
    });
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
    final downloads = context.read<DownloadProvider>();
    final pcRegistry = context.read<ProfileConnectionRegistry>();
    final connRegistry = context.read<ConnectionRegistry>();
    final storage = context.read<StorageService>();
    final serverManager = context.read<MultiServerProvider>().serverManager;
    final hiddenLibraries = context.read<HiddenLibrariesProvider?>();
    final binder = context.read<ActiveProfileBinder>();

    // Release downloads only for servers the profile actually loses — the
    // same server can stay reachable through another connection (a second
    // Plex account sharing the server, another Jellyfin user).
    final retainedServerIds = await _retainedServerIds(
      excludingConnectionId: conn.id,
      profileConnections: pcRegistry,
      connections: connRegistry,
    );
    await downloads.releaseDownloadsForProfileServers(
      _profile.id,
      _serverIdsForConnection(conn).difference(retainedServerIds),
    );
    await removeProfileConnectionAndCleanup(
      profileId: _profile.id,
      connection: conn,
      profileConnections: pcRegistry,
      connections: connRegistry,
      storage: storage,
      serverManager: serverManager,
    );
    await hiddenLibraries?.refresh();
    unawaited(binder.rebindIfActive(_profile.id));
  }

  /// Server ids the profile keeps after removing [excludingConnectionId]:
  /// its other join rows plus, for Plex Home profiles, the implicit parent
  /// account.
  Future<Set<String>> _retainedServerIds({
    required String excludingConnectionId,
    required ProfileConnectionRegistry profileConnections,
    required ConnectionRegistry connections,
  }) async {
    final rows = await profileConnections.listForProfile(_profile.id);
    final byId = {for (final c in await connections.list()) c.id: c};
    final retained = <String>{};
    for (final row in rows) {
      if (row.connectionId == excludingConnectionId) continue;
      final other = byId[row.connectionId];
      if (other != null) retained.addAll(_serverIdsForConnection(other));
    }
    final parentId = _profile.isPlexHome ? _profile.parentConnectionId : null;
    if (parentId != null && parentId != excludingConnectionId) {
      final parent = byId[parentId];
      if (parent != null) retained.addAll(_serverIdsForConnection(parent));
    }
    return retained;
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

  /// Sign out of this virtual profile's parent Plex account. The profile
  /// ceases to exist with the account, so pop the detail screen — unless
  /// the teardown already reset the stack to AuthScreen (unmounted here).
  Future<void> _signOutParentAccount(Connection parentConn) async {
    final signedOut = await confirmAndSignOutPlexAccount(context, accountConnectionId: parentConn.id);
    if (!signedOut || !mounted) return;
    Navigator.of(context).pop(true);
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
                PinStatusRow(onChange: _setPin, onRemove: _clearPin, changeFocusNode: _changePinFocusNode),
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
              _ConnectionsList(
                profile: _profile,
                onRemove: _removeConnection,
                onEdit: _editConnection,
                onSignOutParent: _signOutParentAccount,
              ),
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

class _ConnectionsList extends StatefulWidget {
  final Profile profile;
  final Future<void> Function(ProfileConnection pc, Connection conn) onRemove;
  final Future<void> Function(Connection conn) onEdit;
  final Future<void> Function(Connection conn) onSignOutParent;

  const _ConnectionsList({
    required this.profile,
    required this.onRemove,
    required this.onEdit,
    required this.onSignOutParent,
  });

  @override
  State<_ConnectionsList> createState() => _ConnectionsListState();
}

class _ConnectionsListState extends State<_ConnectionsList> {
  // Created once: building streams/futures inside build re-subscribes and
  // refetches on every parent rebuild (each keystroke in the name field),
  // flashing the spinner and hammering the DB.
  Stream<List<ProfileConnection>>? _pcsStream;
  Stream<Map<String, List<PlexHomeUser>>>? _homeStream;
  Map<String, List<PlexHomeUser>>? _homeInitial;
  Stream<List<Connection>>? _connectionsStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pcsStream ??= context.read<ProfileConnectionRegistry>().watchForProfile(widget.profile.id);
    final plexHome = context.read<PlexHomeService>();
    _homeStream ??= plexHome.stream;
    _homeInitial ??= plexHome.current;
    _connectionsStream ??= context.read<ConnectionRegistry>().watchConnections();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = widget.profile;
    final pcRegistry = context.read<ProfileConnectionRegistry>();

    return StreamBuilder<List<ProfileConnection>>(
      stream: _pcsStream,
      builder: (context, snapshot) {
        final pcs = snapshot.data ?? const <ProfileConnection>[];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: .symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return StreamBuilder<Map<String, List<PlexHomeUser>>>(
          stream: _homeStream,
          initialData: _homeInitial,
          builder: (context, homeSnap) {
            final homeCache = homeSnap.data ?? const <String, List<PlexHomeUser>>{};
            return StreamBuilder<List<Connection>>(
              stream: _connectionsStream,
              builder: (context, snap) {
                final all = snap.data ?? const <Connection>[];
                final byId = {for (final c in all) c.id: c};
                // Plex Home profiles have an implicit parent connection that
                // isn't in the join table — list it first so the user sees the
                // full picture. The profile *is* a home user of that account,
                // so the only removal is signing out of the whole account;
                // it isn't shown for locals.
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
                // The screen already pads its content; SettingsGroup supplies
                // the M3E connected-group card geometry.
                return SettingsGroup(
                  margin: EdgeInsets.zero,
                  children: [
                    if (parentConn != null)
                      ListTile(
                        leading: BackendBadge(backend: parentConn.backend, size: 24),
                        title: Text(parentConn.displayLabel),
                        subtitle: Text(t.profiles.plexHomeAccount),
                        trailing: FocusablePopupMenuButton<String>(
                          icon: const AppIcon(Symbols.more_vert_rounded, fill: 1),
                          tooltip: t.profiles.manage,
                          onSelected: (value) {
                            if (value == 'sign_out') {
                              unawaited(widget.onSignOutParent(parentConn));
                            }
                          },
                          itemBuilder: (_) => [AppMenuItem(value: 'sign_out', label: t.profiles.signOut)],
                        ),
                      ),
                    for (final pc in visiblePcs)
                      if (byId[pc.connectionId] case final conn?)
                        ListTile(
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
                                unawaited(widget.onEdit(conn));
                              } else if (value == 'remove') {
                                unawaited(widget.onRemove(pc, conn));
                              }
                            },
                            itemBuilder: (_) => [
                              if (!pc.isDefault) AppMenuItem(value: 'default', label: t.profiles.makeDefault),
                              if (conn is JellyfinConnection) AppMenuItem(value: 'edit', label: t.common.edit),
                              AppMenuItem(value: 'remove', label: t.profiles.removeConnection),
                            ],
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

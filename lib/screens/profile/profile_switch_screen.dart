import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../connection/connection_registry.dart';
import '../../focus/focusable_wrapper.dart';
import '../../i18n/strings.g.dart';
import '../../media/media_backend.dart';
import '../../mixins/mounted_set_state_mixin.dart';
import '../../profiles/active_profile_binder.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/plex_home_service.dart';
import '../../profiles/profile.dart';
import '../../profiles/profile_activation.dart';
import '../../profiles/profile_avatar.dart';
import '../../profiles/profile_connection.dart';
import '../../profiles/profile_connection_registry.dart';
import '../../profiles/profile_registry.dart';
import '../../profiles/profiles_view.dart';
import '../../services/app_exit_service.dart';
import '../../services/storage_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/dialogs.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_menu.dart';
import '../../widgets/backend_badge.dart';
import '../../widgets/focusable_popup_menu_button.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/profile_switching_overlay.dart';
import '../libraries/state_messages.dart';
import '../auth_screen.dart';
import 'add_local_profile_screen.dart';
import 'profile_delete_flow.dart';
import 'profile_detail_screen.dart';

/// Flat picker showing every [Profile] in the system — Plex Home users
/// auto-surfaced from connected accounts, plus user-created locals.
///
/// Each tile shows avatar, name, an Active badge for the current profile,
/// and one backend chip per connection bound to the profile (parent Plex
/// account + any borrowed connections for Plex Home users).
class ProfileSwitchScreen extends StatefulWidget {
  final bool requireSelection;

  const ProfileSwitchScreen({super.key, this.requireSelection = false});

  @override
  State<ProfileSwitchScreen> createState() => _ProfileSwitchScreenState();
}

class _ProfileSwitchScreenState extends State<ProfileSwitchScreen> with MountedSetStateMixin {
  bool _allowPop = false;
  final Map<String, FocusNode> _profileFocusNodes = {};
  final Map<String, FocusNode> _profileMenuFocusNodes = {};
  final Map<String, GlobalKey<AppMenuButtonState<_TileAction>>> _profileMenuKeys = {};
  bool _focusRequested = false;
  bool _switching = false;
  Stream<ProfilesView>? _viewStream;
  StorageService? _viewStreamStorage;
  StorageService? _storage;
  Future<StorageService>? _storageFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureViewStream();
    if (_storage == null) {
      unawaited(
        (_storageFuture ??= StorageService.getInstance()).then((s) {
          setStateIfMounted(() => _storage = s);
        }),
      );
    }
  }

  void _ensureViewStream() {
    if (_viewStream != null && identical(_viewStreamStorage, _storage)) return;
    _viewStreamStorage = _storage;
    _viewStream = watchProfilesView(
      profiles: context.read<ProfileRegistry>(),
      profileConnections: context.read<ProfileConnectionRegistry>(),
      connections: context.read<ConnectionRegistry>(),
      plexHome: context.read<PlexHomeService>(),
      storage: _storage,
    );
  }

  @override
  void dispose() {
    for (final node in _profileFocusNodes.values) {
      node.dispose();
    }
    for (final node in _profileMenuFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _ensureViewStream();
    return PopScope(
      canPop: !widget.requireSelection || _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && widget.requireSelection) {
          unawaited(AppExitService.requestExit());
        }
      },
      child: StreamBuilder<ProfilesView>(
        stream: _viewStream,
        initialData: ProfilesView.empty,
        builder: (context, snapshot) {
          final view = snapshot.data ?? ProfilesView.empty;
          _pruneProfileFocusResources(view.profiles.map((p) => p.id).toSet());
          // `context.select` only rebuilds when `activeId` actually
          // changes. `context.watch` would rebuild on every provider
          // notification — combined with the stream, that doubles the
          // build cost on each profile-switch.
          final activeId = context.select<ActiveProfileProvider, String?>((p) => p.activeId);
          return Stack(
            children: [
              FocusedScrollScaffold(
                title: Text(t.screens.switchProfile),
                automaticallyImplyLeading: !widget.requireSelection,
                onBackPressed: widget.requireSelection ? () => unawaited(AppExitService.requestExit()) : null,
                slivers: [
                  if (view.profiles.isEmpty)
                    SliverFillRemaining(
                      child: EmptyStateWidget(
                        message: t.messages.noProfilesAvailable,
                        subtitle: t.messages.contactAdminForProfiles,
                        icon: Symbols.person_off_rounded,
                      ),
                    )
                  else
                    ..._buildSections(view, activeId),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverToBoxAdapter(
                      child: FocusableWrapper(
                        disableScale: true,
                        borderRadius: 100,
                        useBackgroundFocus: true,
                        descendantsAreFocusable: false,
                        onSelect: _switching ? null : _addLocalProfile,
                        child: OutlinedButton.icon(
                          onPressed: _switching ? null : _addLocalProfile,
                          icon: const AppIcon(Symbols.person_add_rounded, fill: 1),
                          label: Text(t.profiles.addPlezyProfile),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_switching) const ProfileSwitchingOverlay(),
            ],
          );
        },
      ),
    );
  }

  FocusNode _profileFocusNode(Profile profile) {
    return _profileFocusNodes.putIfAbsent(profile.id, () => FocusNode(debugLabel: 'ProfileTile:${profile.id}'));
  }

  FocusNode _profileMenuFocusNode(Profile profile) {
    return _profileMenuFocusNodes.putIfAbsent(profile.id, () => FocusNode(debugLabel: 'ProfileActions:${profile.id}'));
  }

  GlobalKey<AppMenuButtonState<_TileAction>> _profileMenuKey(Profile profile) {
    return _profileMenuKeys.putIfAbsent(profile.id, () => GlobalKey<AppMenuButtonState<_TileAction>>());
  }

  void _pruneProfileFocusResources(Set<String> activeIds) {
    for (final id in _profileFocusNodes.keys.toList()) {
      if (!activeIds.contains(id)) {
        _profileFocusNodes.remove(id)?.dispose();
      }
    }
    for (final id in _profileMenuFocusNodes.keys.toList()) {
      if (!activeIds.contains(id)) {
        _profileMenuFocusNodes.remove(id)?.dispose();
      }
    }
    for (final id in _profileMenuKeys.keys.toList()) {
      if (!activeIds.contains(id)) {
        _profileMenuKeys.remove(id);
      }
    }
  }

  void _openProfileMenu(Profile profile) {
    _profileMenuKeys[profile.id]?.currentState?.showButtonMenu();
  }

  List<Widget> _buildSections(ProfilesView view, String? activeId) {
    return [_profileList(view.profiles, view, activeId, autofocusFirst: true)];
  }

  SliverList _profileList(List<Profile> profiles, ProfilesView view, String? activeId, {required bool autofocusFirst}) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final profile = profiles[index];
        final isActive = profile.id == activeId;
        final isFirstSelectable = autofocusFirst && index == 0;
        final profileFocusNode = _profileFocusNode(profile);
        final menuFocusNode = _profileMenuFocusNode(profile);
        final menuKey = _profileMenuKey(profile);
        final onManage = !widget.requireSelection ? () => _manageProfile(profile) : null;
        final onDelete = profile.isLocal && !widget.requireSelection ? () => _deleteProfile(profile) : null;
        final onSignOut = profile.isPlexHome && profile.parentConnectionId != null && !widget.requireSelection
            ? () => _signOutPlexAccount(profile)
            : null;
        final hasMenu = onManage != null || onDelete != null || onSignOut != null;

        if (isFirstSelectable && !_focusRequested) {
          _focusRequested = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) profileFocusNode.requestFocus();
          });
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: FocusableWrapper(
            autofocus: isFirstSelectable,
            focusNode: profileFocusNode,
            disableScale: true,
            enableLongPress: hasMenu,
            onLongPress: hasMenu ? () => _openProfileMenu(profile) : null,
            onNavigateRight: hasMenu ? () => menuFocusNode.requestFocus() : null,
            onSelect: _switching || (isActive && !widget.requireSelection) ? null : () => _switchTo(profile),
            child: Card(
              child: _ProfileTile(
                profile: profile,
                isActive: isActive && !widget.requireSelection,
                chips: _chipsFor(profile, view),
                onTap: () => _switchTo(profile),
                // Manage available for any profile — adding/removing
                // borrowed connections is supported on plex_home too. Delete
                // stays local-only (Plex Home users are owned by Plex).
                onManage: onManage,
                onDelete: onDelete,
                onSignOut: onSignOut,
                menuFocusNode: menuFocusNode,
                menuKey: menuKey,
                onMenuNavigateLeft: () => profileFocusNode.requestFocus(),
              ),
            ),
          ),
        );
      }, childCount: profiles.length),
    );
  }

  Future<void> _manageProfile(Profile profile) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileDetailScreen(profile: profile)));
  }

  /// Drop the parent Plex account [profile] hangs off — same effect as
  /// "Forget account" elsewhere in Plex apps. The connection's join rows
  /// cascade away (FK on connection_id), [PlexHomeService]'s
  /// `_onChange` listener evicts the cached home users + shadow profile
  /// rows, and a binder rebind clears the runtime client. Plex doesn't
  /// expose a single-session revoke endpoint we can rely on, so we don't
  /// touch the server side — the user can revoke via plex.tv if they want.
  Future<void> _signOutPlexAccount(Profile profile) async {
    final parentId = profile.parentConnectionId;
    if (parentId == null) return;
    final connRegistry = context.read<ConnectionRegistry>();
    final parent = await connRegistry.getPlexAccount(parentId);
    if (parent == null || !mounted) return;

    final confirmed = await showDeleteConfirmation(
      context,
      title: t.profiles.signOutPlexTitle,
      message: t.profiles.signOutPlexMessage(displayName: parent.displayLabel),
      confirmText: t.profiles.signOut,
    );
    if (!confirmed || !mounted) return;

    final active = context.read<ActiveProfileProvider>();
    final activeProfile = active.active;
    final wasActiveAccount = activeProfile?.parentConnectionId == parentId;
    final remainingProfiles = active.profiles
        .where((p) => p.id != activeProfile?.id && p.parentConnectionId != parentId)
        .toList();
    final binder = context.read<ActiveProfileBinder>();
    final navigator = Navigator.of(context, rootNavigator: true);

    try {
      await connRegistry.remove(parentId);
      final noConnectionsLeft = (await connRegistry.list()).isEmpty;
      if (noConnectionsLeft) {
        await active.clearActiveProfile();
        unawaited(binder.rebindActive());
        if (navigator.mounted) {
          unawaited(navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AuthScreen()), (_) => false));
        }
        return;
      }
      if (!mounted) return;
      // If the active virtual profile belonged to the removed account, make
      // the storage state explicit instead of relying on provider fallback.
      if (wasActiveAccount) {
        if (remainingProfiles.isNotEmpty) {
          await active.activate(remainingProfiles.first);
        } else {
          await active.clearActiveProfile();
          unawaited(binder.rebindActive());
        }
      } else {
        // Active profile stayed the same, but borrowed rows for this account
        // may have cascaded away.
        unawaited(binder.rebindActive());
      }
      if (!mounted) return;
      showSuccessSnackBar(context, t.profiles.signedOutPlex);
    } catch (e, st) {
      appLogger.w('Plex sign-out failed for $parentId', error: e, stackTrace: st);
      if (mounted) {
        showErrorSnackBar(context, t.profiles.signOutFailed);
      }
    }
  }

  Future<void> _deleteProfile(Profile profile) async {
    await confirmAndDeleteProfile(
      context,
      profile: profile,
      title: t.profiles.deleteThisProfileTitle,
      message: t.profiles.deleteThisProfileMessage(displayName: profile.displayName),
    );
  }

  List<_ChipData> _chipsFor(Profile profile, ProfilesView view) {
    final chips = <_ChipData>[];
    // Plex Home profiles implicitly own their parent Plex connection (no
    // join-table row), so prepend it before any borrowed connections.
    if (profile.isPlexHome) {
      final parentId = profile.parentConnectionId;
      if (parentId != null) {
        final conn = view.connectionsById[parentId];
        if (conn != null) chips.add(_ChipData(backend: conn.backend, label: conn.displayLabel));
      }
    }
    final pcs = visibleProfileConnections(
      profile,
      view.connectionsByProfile[profile.id] ?? const <ProfileConnection>[],
    );
    for (final pc in pcs) {
      final conn = view.connectionsById[pc.connectionId];
      if (conn != null) chips.add(_ChipData(backend: conn.backend, label: conn.displayLabel));
    }
    return chips;
  }

  Future<void> _addLocalProfile() async {
    await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const AddLocalProfileScreen()));
  }

  Future<void> _switchTo(Profile profile) async {
    if (_switching) return;
    setState(() => _switching = true);
    try {
      final navigator = Navigator.of(context, rootNavigator: true);
      final switched = await switchProfileFromUi(context, profile);
      if (!mounted || !switched) return;
      if (widget.requireSelection) {
        setState(() => _allowPop = true);
      }
      navigator.pop(true);
    } finally {
      setStateIfMounted(() => _switching = false);
    }
  }
}

class _ProfileTile extends StatelessWidget {
  final Profile profile;
  final bool isActive;
  final List<_ChipData> chips;
  final VoidCallback onTap;
  final VoidCallback? onManage;
  final VoidCallback? onDelete;
  final VoidCallback? onSignOut;
  final FocusNode menuFocusNode;
  final GlobalKey<AppMenuButtonState<_TileAction>> menuKey;
  final VoidCallback onMenuNavigateLeft;

  const _ProfileTile({
    required this.profile,
    required this.isActive,
    required this.chips,
    required this.onTap,
    this.onManage,
    this.onDelete,
    this.onSignOut,
    required this.menuFocusNode,
    required this.menuKey,
    required this.onMenuNavigateLeft,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMenu = onManage != null || onDelete != null || onSignOut != null;
    return InkWell(
      onTap: isActive ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ProfileAvatar(profile: profile, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                mainAxisSize: .min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(profile.displayName, style: theme.textTheme.titleMedium, overflow: .ellipsis),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            t.profiles.active,
                            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  _ConnectionChips(chips: chips),
                ],
              ),
            ),
            if (hasMenu)
              _ProfileActionsButton(
                menuKey: menuKey,
                focusNode: menuFocusNode,
                onNavigateLeft: onMenuNavigateLeft,
                onSelected: _handleAction,
                actions: [
                  if (onManage != null) _TileAction.manage,
                  if (onDelete != null) _TileAction.delete,
                  if (onSignOut != null) _TileAction.signOut,
                ],
              )
            else if (!isActive)
              const Padding(padding: .only(left: 8), child: AppIcon(Symbols.chevron_right_rounded, fill: 1)),
          ],
        ),
      ),
    );
  }

  void _handleAction(_TileAction action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (action) {
        case _TileAction.manage:
          onManage?.call();
          break;
        case _TileAction.delete:
          onDelete?.call();
          break;
        case _TileAction.signOut:
          onSignOut?.call();
          break;
      }
    });
  }
}

class _ProfileActionsButton extends StatelessWidget {
  final GlobalKey<AppMenuButtonState<_TileAction>> menuKey;
  final FocusNode focusNode;
  final VoidCallback onNavigateLeft;
  final ValueChanged<_TileAction> onSelected;
  final List<_TileAction> actions;

  const _ProfileActionsButton({
    required this.menuKey,
    required this.focusNode,
    required this.onNavigateLeft,
    required this.onSelected,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return FocusablePopupMenuButton<_TileAction>(
      menuKey: menuKey,
      focusNode: focusNode,
      semanticLabel: t.profiles.manage,
      onNavigateLeft: onNavigateLeft,
      icon: const AppIcon(Symbols.more_vert_rounded, fill: 1),
      tooltip: t.profiles.manage,
      onSelected: onSelected,
      itemBuilder: (_) => [for (final action in actions) AppMenuItem(value: action, label: action.label)],
    );
  }
}

extension _TileActionLabel on _TileAction {
  String get label {
    return switch (this) {
      _TileAction.manage => t.profiles.manage,
      _TileAction.delete => t.profiles.delete,
      _TileAction.signOut => t.profiles.signOut,
    };
  }
}

enum _TileAction { manage, delete, signOut }

class _ConnectionChips extends StatelessWidget {
  final List<_ChipData> chips;

  const _ConnectionChips({required this.chips});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (chips.isEmpty) {
      return Text(t.profiles.noConnections, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error));
    }
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final c in chips)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: .min,
              children: [
                BackendBadge(backend: c.backend, size: 12),
                const SizedBox(width: 4),
                Text(c.label, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
      ],
    );
  }
}

class _ChipData {
  final MediaBackend backend;
  final String label;
  const _ChipData({required this.backend, required this.label});
}

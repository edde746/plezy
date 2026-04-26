import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../connection/connection_registry.dart';
import '../../focus/focusable_wrapper.dart';
import '../../i18n/strings.g.dart';
import '../../media/media_backend.dart';
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
import '../../providers/download_provider.dart';
import '../../services/storage_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/dialogs.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/backend_badge.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../libraries/state_messages.dart';
import 'add_local_profile_screen.dart';
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

class _ProfileSwitchScreenState extends State<ProfileSwitchScreen> {
  bool _allowPop = false;
  final FocusNode _firstSelectableFocusNode = FocusNode();
  bool _focusRequested = false;
  bool _switching = false;
  Stream<ProfilesView>? _viewStream;
  StorageService? _storage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewStream ??= watchProfilesView(
      profiles: context.read<ProfileRegistry>(),
      profileConnections: context.read<ProfileConnectionRegistry>(),
      connections: context.read<ConnectionRegistry>(),
      plexHome: context.read<PlexHomeService>(),
      storage: _storage,
    );
    if (_storage == null) {
      unawaited(
        StorageService.getInstance().then((s) {
          if (mounted) setState(() => _storage = s);
        }),
      );
    }
  }

  @override
  void dispose() {
    _firstSelectableFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.requireSelection || _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && widget.requireSelection) {
          SystemNavigator.pop();
        }
      },
      child: StreamBuilder<ProfilesView>(
        stream: _viewStream,
        initialData: ProfilesView.empty,
        builder: (context, snapshot) {
          final view = snapshot.data ?? ProfilesView.empty;
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
                onBackPressed: widget.requireSelection ? () => SystemNavigator.pop() : null,
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
              // Modal busy overlay so users see the switch is in flight.
              // Without this the screen visually freezes for a few seconds
              // while the binder fetches user tokens and rebuilds servers.
              // `Positioned.fill` is required: a non-positioned `ColoredBox`
              // sizes itself to its child (just the Card+Center), leaving
              // the rest of the screen un-dimmed and tappable.
              if (_switching)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black54,
                    child: Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 56, height: 56, child: CircularProgressIndicator()),
                              const SizedBox(height: 16),
                              Text(t.profiles.switchingProfile),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
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

        if (isFirstSelectable && !_focusRequested) {
          _focusRequested = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _firstSelectableFocusNode.requestFocus();
          });
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: FocusableWrapper(
            autofocus: isFirstSelectable,
            focusNode: isFirstSelectable ? _firstSelectableFocusNode : null,
            disableScale: true,
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
                onManage: !widget.requireSelection ? () => _manageProfile(profile) : null,
                onDelete: profile.isLocal && !widget.requireSelection ? () => _deleteProfile(profile) : null,
                onSignOut: profile.isPlexHome && profile.parentConnectionId != null && !widget.requireSelection
                    ? () => _signOutPlexAccount(profile)
                    : null,
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

    try {
      await connRegistry.remove(parentId);
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
    final confirmed = await showDeleteConfirmation(
      context,
      title: t.profiles.deleteThisProfileTitle,
      message: t.profiles.deleteThisProfileMessage(displayName: profile.displayName),
    );
    if (!confirmed || !mounted) return;

    final pcRegistry = context.read<ProfileConnectionRegistry>();
    final registry = context.read<ProfileRegistry>();
    final downloadProvider = context.read<DownloadProvider>();
    final active = context.read<ActiveProfileProvider>();
    final wasActive = active.activeId == profile.id;
    try {
      await downloadProvider.deleteDownloadsForProfile(profile.id);
      await pcRegistry.removeAllForProfile(profile.id);
      await registry.remove(profile.id);
    } catch (e, st) {
      appLogger.w('Failed to delete profile ${profile.id}', error: e, stackTrace: st);
      if (mounted) {
        showErrorSnackBar(context, t.errors.failedToDeleteProfile(displayName: profile.displayName));
      }
      return;
    }

    // If we just deleted the active profile, hand off to the first
    // remaining one — otherwise the binder is left bound to a ghost.
    if (wasActive) {
      final remaining = active.profiles.where((p) => p.id != profile.id).toList();
      if (remaining.isNotEmpty) {
        await active.activate(remaining.first);
      } else {
        await active.clearActiveProfile();
      }
    }
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
      final navigator = Navigator.of(context);
      final activeProvider = context.read<ActiveProfileProvider>();
      final ok = await activateProfileWithPin(context, profile);
      if (!mounted) return;
      if (!ok) {
        if (context.mounted) {
          showErrorSnackBar(context, t.errors.failedToSwitchProfile(displayName: profile.displayName));
        }
        return;
      }
      // Stay on the picker while the binder mints the per-user token,
      // fetches servers, and pushes them into MultiServerManager. The
      // PIN dialog (if any) overlays the picker via the root navigator,
      // so popping early would briefly expose the previous profile's
      // empty-state screen behind the dialog.
      final bound = await activeProvider.awaitBindingSettle();
      if (!mounted) return;
      if (!bound) {
        if (context.mounted) {
          showErrorSnackBar(context, t.errors.failedToSwitchProfile(displayName: profile.displayName));
        }
        return;
      }
      if (widget.requireSelection) {
        setState(() => _allowPop = true);
      }
      navigator.pop(true);
    } finally {
      if (mounted) setState(() => _switching = false);
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

  const _ProfileTile({
    required this.profile,
    required this.isActive,
    required this.chips,
    required this.onTap,
    this.onManage,
    this.onDelete,
    this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMenu = onManage != null || onDelete != null || onSignOut != null;
    return InkWell(
      onTap: isActive ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: [
            ProfileAvatar(profile: profile, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          profile.displayName,
                          style: theme.textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
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
              PopupMenuButton<_TileAction>(
                icon: const AppIcon(Symbols.more_vert_rounded, fill: 1),
                tooltip: 'Profile actions',
                itemBuilder: (_) => [
                  if (onManage != null)
                    PopupMenuItem(
                      value: _TileAction.manage,
                      onTap: () => WidgetsBinding.instance.addPostFrameCallback((_) => onManage?.call()),
                      child: Text(t.profiles.manage),
                    ),
                  if (onDelete != null)
                    PopupMenuItem(
                      value: _TileAction.delete,
                      onTap: () => WidgetsBinding.instance.addPostFrameCallback((_) => onDelete?.call()),
                      child: Text(t.profiles.delete),
                    ),
                  if (onSignOut != null)
                    PopupMenuItem(
                      value: _TileAction.signOut,
                      onTap: () => WidgetsBinding.instance.addPostFrameCallback((_) => onSignOut?.call()),
                      child: Text(t.profiles.signOut),
                    ),
                ],
              )
            else if (!isActive)
              const Padding(padding: EdgeInsets.only(left: 8), child: AppIcon(Symbols.chevron_right_rounded, fill: 1)),
          ],
        ),
      ),
    );
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
      return Text('No connections', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error));
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
              mainAxisSize: MainAxisSize.min,
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

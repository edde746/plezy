import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../connection/connection.dart';
import '../../connection/connection_registry.dart';
import '../../focus/focusable_wrapper.dart';
import '../../i18n/strings.g.dart';
import '../../profiles/active_profile_binder.dart';
import '../../profiles/plex_home_service.dart';
import '../../profiles/plex_home_switch.dart';
import '../../profiles/profile.dart';
import '../../profiles/profile_activation.dart';
import '../../profiles/profile_connection.dart';
import '../../profiles/profile_connection_registry.dart';
import '../../profiles/profile_merge.dart';
import '../../profiles/profile_registry.dart';
import '../../services/plex_auth_service.dart';
import '../../services/storage_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/backend_badge.dart';
import '../../widgets/desktop_app_bar.dart';
import '../libraries/state_messages.dart';
import 'pin_entry_dialog.dart';

/// Pick a connection from another profile and attach it to [targetProfile]
/// as an independent copy.
///
/// For each candidate (sourceProfile, profileConnection):
/// 1. If the source profile is PIN-protected (local kind), prompt for its
///    PIN and verify locally before revealing the borrow action.
/// 2. For Plex sources: call `/home/users/{uuid}/switch` from the parent
///    account token with the source's `userIdentifier` and (if the target
///    Home user is `protected`) the Home PIN. The borrower gets its own
///    fresh user-token.
/// 3. For Jellyfin sources: copy the existing `userToken` (one user per
///    Jellyfin connection).
class BorrowConnectionScreen extends StatefulWidget {
  final Profile targetProfile;
  final bool popOnSuccess;

  const BorrowConnectionScreen({super.key, required this.targetProfile, this.popOnSuccess = false});

  @override
  State<BorrowConnectionScreen> createState() => _BorrowConnectionScreenState();
}

class _BorrowConnectionScreenState extends State<BorrowConnectionScreen> {
  late Future<List<_BorrowCandidate>> _candidatesFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _candidatesFuture = _loadCandidates();
  }

  Future<List<_BorrowCandidate>> _loadCandidates() async {
    final pcRegistry = context.read<ProfileConnectionRegistry>();
    final connRegistry = context.read<ConnectionRegistry>();
    final profileRegistry = context.read<ProfileRegistry>();
    final plexHome = context.read<PlexHomeService>();

    await plexHome.start();
    final results = await Future.wait([
      pcRegistry.listAll(),
      connRegistry.list(),
      profileRegistry.list(),
      StorageService.getInstance(),
    ]);
    final allPcs = results[0] as List<ProfileConnection>;
    final allConns = results[1] as List<Connection>;
    final localProfiles = results[2] as List<Profile>;
    final storage = results[3] as StorageService;
    final connById = {for (final c in allConns) c.id: c};
    final allProfiles = mergeLocalWithPlexHome(
      locals: localProfiles,
      plexHomeByConnectionId: plexHome.current,
      connectionsById: connById,
      storage: storage,
    );

    // What does the target already have? Skip duplicates by connection id.
    final targetConnIds = allPcs
        .where((pc) => pc.profileId == widget.targetProfile.id)
        .map((pc) => pc.connectionId)
        .toSet();
    // Plex Home profiles also implicitly own their parent Plex connection.
    if (widget.targetProfile.parentConnectionId != null) {
      targetConnIds.add(widget.targetProfile.parentConnectionId!);
    }

    final out = <_BorrowCandidate>[];
    final seen = <String>{};

    // Dedup by the *thing being borrowed* — (connection, user) — not the
    // source profile. If two profiles already borrowed the same Home user,
    // the borrow operation is identical regardless of which one the picker
    // points at; showing both is just clutter.
    String key(String connId, String userId) => '$connId/$userId';

    // Pass 1: virtual Plex Home profiles (auto-surfaced from PlexHomeService)
    // come first so they win as the canonical source for a given Home user.
    // Their parent Plex connection isn't represented as a join row, so
    // synthesize a ProfileConnection on the fly with userToken=null — the
    // borrow flow re-mints the token via `/home/users/{uuid}/switch` from
    // the parent account anyway, so the placeholder never gets persisted.
    for (final source in allProfiles) {
      if (source.id == widget.targetProfile.id) continue;
      if (!source.isPlexHome) continue;
      final parentId = source.parentConnectionId;
      final homeUuid = source.plexHomeUserUuid;
      if (parentId == null || homeUuid == null) continue;
      if (targetConnIds.contains(parentId)) continue;
      final conn = connById[parentId];
      if (conn == null) continue;
      if (!seen.add(key(conn.id, homeUuid))) continue;
      out.add(
        _BorrowCandidate(
          source: source,
          pc: ProfileConnection(
            profileId: source.id,
            connectionId: parentId,
            userToken: null,
            userIdentifier: homeUuid,
          ),
          connection: conn,
        ),
      );
    }

    // Pass 2: persisted ProfileConnection rows from any other profile
    // (local profiles' own connections + already-borrowed rows on plex_home
    // profiles). Skipped when (conn, user) already surfaced via pass 1.
    for (final pc in allPcs) {
      if (pc.profileId == widget.targetProfile.id) continue;
      if (targetConnIds.contains(pc.connectionId)) continue;
      final conn = connById[pc.connectionId];
      if (conn == null) continue;
      final source = allProfiles.firstWhere(
        (p) => p.id == pc.profileId,
        orElse: () => widget.targetProfile, // sentinel — skipped below
      );
      if (source.id == widget.targetProfile.id) continue;
      if (!seen.add(key(conn.id, pc.userIdentifier))) continue;
      out.add(_BorrowCandidate(source: source, pc: pc, connection: conn));
    }

    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<_BorrowCandidate>>(
        future: _candidatesFuture,
        builder: (context, snapshot) {
          final candidates = snapshot.data ?? const <_BorrowCandidate>[];
          return CustomScrollView(
            slivers: [
              ExcludeFocus(
                child: CustomAppBar(
                  title: Text(t.profiles.borrowAddTo(displayName: widget.targetProfile.displayName)),
                  pinned: true,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                sliver: SliverToBoxAdapter(
                  child: Text(t.profiles.borrowExplain, style: Theme.of(context).textTheme.bodySmall),
                ),
              ),
              if (snapshot.connectionState != ConnectionState.done)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              else if (candidates.isEmpty)
                SliverFillRemaining(
                  child: EmptyStateWidget(
                    message: t.profiles.borrowEmpty,
                    subtitle: t.profiles.borrowEmptySubtitle,
                    icon: Symbols.share_rounded,
                    iconSize: 48,
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final cand = candidates[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: FocusableWrapper(
                        autofocus: index == 0,
                        disableScale: true,
                        onSelect: _busy ? null : () => _borrow(cand),
                        child: Card(
                          child: _BorrowTile(candidate: cand, onTap: () => _borrow(cand)),
                        ),
                      ),
                    );
                  }, childCount: candidates.length),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _borrow(_BorrowCandidate cand) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (!await _verifySourcePin(cand)) return;
      switch (cand.connection) {
        case PlexAccountConnection():
          await _borrowPlex(cand);
        case JellyfinConnection():
          await _borrowJellyfin(cand);
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _candidatesFuture = _loadCandidates();
        });
      }
    }
  }

  /// Verify the source profile's PIN if it has one. Locals check the local
  /// hash; Plex Home sources doing a non-Plex borrow do a
  /// `/home/users/{uuid}/switch` round-trip against the parent account so
  /// Plex validates the PIN server-side (the minted token is discarded —
  /// we only need the validation side effect).
  ///
  /// Plex-source borrows of a Plex Home profile pass through
  /// `switchPlexHomeUserWithPin` in [_borrowPlex] anyway (it mints the
  /// target's user-token), so re-validating here would prompt twice for
  /// the same PIN. Skip in that case and let the inner call handle it.
  Future<bool> _verifySourcePin(_BorrowCandidate cand) async {
    if (!cand.source.isPinProtected) return true;
    if (cand.source.isLocal) {
      final pin = await showPinEntryDialog(context, cand.source.displayName);
      if (pin == null) return false;
      if (!verifyProfilePin(cand.source, pin)) {
        if (!mounted) return false;
        showErrorSnackBar(context, 'Incorrect PIN.');
        return false;
      }
      return true;
    }
    // Plex Home source: defer to _borrowPlex's PIN prompt for Plex borrows.
    if (cand.connection is PlexAccountConnection) return true;
    // Other backends (Jellyfin) — validate via /switch and discard the token.
    final parentId = cand.source.parentConnectionId;
    final homeUuid = cand.source.plexHomeUserUuid;
    if (parentId == null || homeUuid == null) return false;
    final parent = await context.read<ConnectionRegistry>().getPlexAccount(parentId);
    if (parent == null) {
      if (mounted) showErrorSnackBar(context, 'Source profile is missing its parent account.');
      return false;
    }
    final auth = await PlexAuthService.create();
    try {
      final result = await switchPlexHomeUserWithPin(
        auth: auth,
        accountToken: parent.accountToken,
        homeUserUuid: homeUuid,
        requiresPin: true,
        promptForPin: ({String? errorMessage}) async {
          if (!mounted) return null;
          return showPinEntryDialog(context, cand.source.displayName, errorMessage: errorMessage);
        },
        logLabel: cand.source.displayName,
      );
      if (!result.succeeded) {
        if (result.status == PlexHomeSwitchStatus.failed && mounted) {
          showErrorSnackBar(context, 'Failed to verify PIN.');
        }
        return false;
      }
      return true;
    } finally {
      auth.dispose();
    }
  }

  Future<void> _borrowPlex(_BorrowCandidate cand) async {
    final pcRegistry = context.read<ProfileConnectionRegistry>();
    final auth = await PlexAuthService.create();
    try {
      final account = cand.connection as PlexAccountConnection;
      final result = await switchPlexHomeUserWithPin(
        auth: auth,
        accountToken: account.accountToken,
        homeUserUuid: cand.pc.userIdentifier,
        requiresPin: cand.source.plexProtected,
        promptForPin: ({String? errorMessage}) async {
          if (!mounted) return null;
          return showPinEntryDialog(context, cand.source.displayName, errorMessage: errorMessage);
        },
        logLabel: cand.source.displayName,
      );
      if (!result.succeeded) {
        if (result.status == PlexHomeSwitchStatus.failed && mounted) {
          showErrorSnackBar(context, 'Failed to borrow connection.');
        }
        return;
      }
      await pcRegistry.upsert(
        ProfileConnection(
          profileId: widget.targetProfile.id,
          connectionId: account.id,
          userToken: result.userToken!,
          userIdentifier: cand.pc.userIdentifier,
          tokenAcquiredAt: DateTime.now(),
        ),
      );
      if (mounted) {
        unawaited(context.read<ActiveProfileBinder>().rebindIfActive(widget.targetProfile.id));
        if (widget.popOnSuccess) {
          Navigator.of(context).pop(true);
          return;
        }
        showSuccessSnackBar(context, 'Connection borrowed.');
      }
    } catch (e, st) {
      appLogger.w('Borrow failed', error: e, stackTrace: st);
      if (mounted) {
        showErrorSnackBar(context, 'Failed to borrow connection.');
      }
    } finally {
      auth.dispose();
    }
  }

  Future<void> _borrowJellyfin(_BorrowCandidate cand) async {
    final jelly = cand.connection as JellyfinConnection;
    final pcRegistry = context.read<ProfileConnectionRegistry>();
    await pcRegistry.upsert(
      ProfileConnection(
        profileId: widget.targetProfile.id,
        connectionId: jelly.id,
        userToken: cand.pc.hasToken ? cand.pc.userToken : jelly.accessToken,
        userIdentifier: cand.pc.userIdentifier.isNotEmpty ? cand.pc.userIdentifier : jelly.userId,
        tokenAcquiredAt: DateTime.now(),
      ),
    );
    if (mounted) {
      unawaited(context.read<ActiveProfileBinder>().rebindIfActive(widget.targetProfile.id));
      if (widget.popOnSuccess) {
        Navigator.of(context).pop(true);
        return;
      }
      showSuccessSnackBar(context, 'Connection borrowed.');
    }
  }
}

class _BorrowCandidate {
  final Profile source;
  final ProfileConnection pc;
  final Connection connection;

  const _BorrowCandidate({required this.source, required this.pc, required this.connection});

  String get connectionLabel => connection.displayLabel;
}

class _BorrowTile extends StatelessWidget {
  final _BorrowCandidate candidate;
  final VoidCallback onTap;

  const _BorrowTile({required this.candidate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BackendBadge(backend: candidate.connection.backend, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(candidate.connectionLabel, style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'From ${candidate.source.displayName}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      if (candidate.source.isPinProtected) ...[
                        const SizedBox(width: 6),
                        AppIcon(Symbols.lock_rounded, fill: 1, size: 12, color: theme.colorScheme.onSurfaceVariant),
                      ],
                    ],
                  ),
                  if (candidate.connection is PlexAccountConnection)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('as ${candidate.source.displayName}', style: theme.textTheme.bodySmall),
                    ),
                ],
              ),
            ),
            const Padding(padding: EdgeInsets.only(left: 8, top: 4), child: AppIcon(Symbols.add_rounded, fill: 1)),
          ],
        ),
      ),
    );
  }
}

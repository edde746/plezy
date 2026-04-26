import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../connection/connection.dart';
import '../../connection/connection_registry.dart';
import '../../i18n/strings.g.dart';
import '../../profiles/active_profile_binder.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/plex_home_service.dart';
import '../../profiles/profile.dart';
import '../../profiles/profile_connection_registry.dart';
import '../../services/plex_auth_service.dart';
import '../../utils/app_logger.dart';
import '../../media/media_backend.dart';
import '../../widgets/backend_badge.dart';
import '../../widgets/desktop_app_bar.dart';
import '../auth/plex_pin_auth_flow.dart';
import '../profile/borrow_connection_screen.dart';
import 'async_form_state_mixin.dart';
import 'connection_persistence.dart';

/// Add a Plex account to the [ConnectionRegistry].
///
/// Hands off the PIN/QR/polling UI to [PlexPinAuthFlow]; this screen owns
/// the post-token-received flow: build the [PlexAccountConnection], guard
/// against duplicates, register with the live [MultiServerManager], and
/// either pop with success or route into [BorrowConnectionScreen] for the
/// passed-in profile.
///
/// When [targetProfile] is provided, after a successful sign-in the user
/// is routed into [BorrowConnectionScreen] for that target so they can
/// pick which Home user from the new account to attach to the profile.
class AddPlexAccountScreen extends StatefulWidget {
  /// When set, after sign-in route into the borrow flow for this profile.
  /// The new account's Home users surface globally either way; the borrow
  /// step is what creates the [ProfileConnection] row that grants this
  /// profile access to one of them.
  final Profile? targetProfile;

  const AddPlexAccountScreen({super.key, this.targetProfile});

  @override
  State<AddPlexAccountScreen> createState() => _AddPlexAccountScreenState();
}

class _AddPlexAccountScreenState extends State<AddPlexAccountScreen> with AsyncFormStateMixin {
  Future<void> _onTokenReceived(String token) async {
    final completed = await runAsync<bool>(
      () async {
        // Pull the account label first so the row is human-readable. Falls
        // back to "Plex" when the user info call fails (rare; e.g. token
        // works but plex.tv is rate-limiting).
        String accountLabel = 'Plex';
        // Account UUID from plex.tv — this is what makes multi-account work.
        // The clientIdentifier is per-device (same for every Plex account on
        // this install), so keying connection.id off it would collapse two
        // different Plex accounts into the same row. Falls back to the
        // client identifier only if the user-info call fails outright;
        // re-signing into the same account will then upsert the legacy row.
        String accountUuid = '';
        final auth = await PlexAuthService.create();
        try {
          try {
            final info = await auth.getUserInfo(token);
            accountLabel = (info['username'] as String?) ?? (info['email'] as String?) ?? 'Plex';
            final uuid = (info['uuid'] as String?)?.trim();
            if (uuid != null && uuid.isNotEmpty) accountUuid = uuid;
          } catch (e) {
            appLogger.d('getUserInfo after add-account failed (using fallback): $e');
          }

          final servers = await auth.fetchServers(token);
          if (!mounted) return false;

          final connection = PlexAccountConnection(
            id: 'plex.${accountUuid.isNotEmpty ? accountUuid : auth.clientIdentifier}',
            accountToken: token,
            clientIdentifier: auth.clientIdentifier,
            accountLabel: accountLabel,
            servers: servers,
            createdAt: DateTime.now(),
            lastAuthenticatedAt: DateTime.now(),
          );

          if (!mounted) return false;
          // Persist the registry row. Binding is deliberately left to
          // ActiveProfileBinder below (global reauth) or the borrow flow
          // (profile-scoped add) so we never put the raw account token into
          // the active runtime session.
          final target = widget.targetProfile;
          await persistAndBindConnection(
            context: context,
            connection: connection,
            bindToProfile: null,
            addToManager: null,
          );

          if (!mounted) return false;
          // Live-fetch the new account's Home users into [PlexHomeService]'s
          // cache so the picker immediately surfaces them as virtual profiles.
          // Must be awaited before pushing the borrow screen — that screen
          // reads `activeProvider.profiles` once in initState (no reactive
          // subscription), so navigating before the home users land yields
          // an empty candidate list. Errors are swallowed inside
          // `_fetchAndCache`; await is safe.
          await context.read<PlexHomeService>().refresh(connection);

          if (!mounted) return false;
          if (target != null) {
            final borrowed = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => BorrowConnectionScreen(targetProfile: target, popOnSuccess: true)),
            );
            if (!mounted) return borrowed == true;
            if (borrowed == true) {
              Navigator.of(context).pop(true);
              return true;
            }
            throw StateError(t.addServer.failedToRegisterAccount(error: 'Connection was not borrowed'));
          }
          await _rebindActiveIfUses(connection.id);
          if (!mounted) return false;
          Navigator.of(context).pop(true);
          return true;
        } finally {
          auth.dispose();
        }
      },
      errorMapper: (e) {
        appLogger.e('Failed to register Plex account', error: e);
        return t.addServer.failedToRegisterAccount(error: e.toString());
      },
    );
    if (mounted && completed != true) {
      throw StateError(errorText ?? t.addServer.failedToRegisterAccount(error: 'Unknown error'));
    }
  }

  Future<void> _rebindActiveIfUses(String connectionId) async {
    final activeProvider = context.read<ActiveProfileProvider>();
    await activeProvider.initialize();
    if (!mounted) return;

    final active = activeProvider.active;
    if (active == null) return;
    var usesConnection = active.parentConnectionId == connectionId;
    if (!usesConnection) {
      final pcs = await context.read<ProfileConnectionRegistry>().listForProfile(active.id);
      usesConnection = pcs.any((pc) => pc.connectionId == connectionId);
    }
    if (!mounted || !usesConnection) return;
    await context.read<ActiveProfileBinder>().rebindActive();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          ExcludeFocus(child: CustomAppBar(title: Text(t.addServer.addPlexTitle), pinned: true)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t.addServer.plexAuthIntro, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  PlexPinAuthFlow(
                    onTokenReceived: _onTokenReceived,
                    initialButtonsBuilder: (context, browser, qr, busy) => Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          onPressed: busy || this.busy ? null : browser,
                          icon: const BackendBadge(backend: MediaBackend.plex, size: 18),
                          label: Text(t.auth.signInWithPlex),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: busy || this.busy ? null : qr,
                          icon: const AppIcon(Symbols.qr_code_rounded, fill: 1),
                          label: Text(t.auth.showQRCode),
                        ),
                      ],
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      errorText!,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

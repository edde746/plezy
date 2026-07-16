import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../connection/connection.dart';
import '../../connection/connection_registry.dart';
import '../../connection/plex_account_setup.dart';
import '../../focus/focusable_button.dart';
import '../../i18n/strings.g.dart';
import '../../profiles/active_profile_binder.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/plex_home_service.dart';
import '../../profiles/profile.dart';
import '../../profiles/profile_connection_cleanup.dart';
import '../../profiles/profile_connection_registry.dart';
import '../../services/storage_service.dart';
import '../../utils/app_logger.dart';
import '../../media/media_backend.dart';
import '../../widgets/backend_badge.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../auth/plex_pin_auth_flow.dart';
import '../profile/borrow_connection_screen.dart';
import 'async_form_state_mixin.dart';

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
        final connRegistry = context.read<ConnectionRegistry>();
        final pcRegistry = context.read<ProfileConnectionRegistry>();
        final plexHome = context.read<PlexHomeService>();
        final storage = context.read<StorageService>();
        final target = widget.targetProfile;

        // Shared token→connection pipeline: identity resolution, dedup of a
        // legacy client-id-keyed row, registry upsert, and the home-user
        // fetch (which must land before the borrow screen — it reads
        // `activeProvider.profiles` once in initState). Binding is
        // deliberately left to ActiveProfileBinder below (global reauth) or
        // the borrow flow (profile-scoped add) so we never put the raw
        // account token into the active runtime session.
        final registration = await registerPlexAccountFromToken(
          token: token,
          connections: connRegistry,
          profileConnections: pcRegistry,
          storage: storage,
          plexHome: plexHome,
        );
        final connection = registration.connection;

        if (!mounted) return false;
        if (target != null) {
          final borrowed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => BorrowConnectionScreen(targetProfile: target, popOnSuccess: true)),
          );
          if (borrowed != true) {
            // The user backed out of picking a home user — a cancel, not an
            // error. If this flow created the account solely to attach it
            // to the profile, remove it again so a cancelled attach doesn't
            // leave a global account behind.
            if (!registration.existedBefore) {
              await removePlexAccountConnectionAndCleanup(
                account: connection,
                profileConnections: pcRegistry,
                connections: connRegistry,
                storage: storage,
              );
            }
            if (mounted) Navigator.of(context).pop(false);
            return true;
          }
          if (mounted) Navigator.of(context).pop(true);
          return true;
        }
        await _rebindActiveIfUses(connection.id);
        if (!mounted) return false;
        Navigator.of(context).pop(true);
        return true;
      },
      errorMapper: (e) {
        appLogger.e('Failed to register Plex account', error: e);
        return t.addServer.failedToRegisterAccount(error: e.toString());
      },
    );
    if (mounted && completed != true) {
      throw StateError(errorText ?? t.addServer.failedToRegisterAccount(error: t.common.unknown));
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
    return FocusedScrollScaffold(
      title: Text(t.addServer.addPlexTitle),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: .min,
                  crossAxisAlignment: .stretch,
                  children: [
                    PlexPinAuthFlow(
                      onTokenReceived: _onTokenReceived,
                      initialButtonsBuilder: (context, browser, qr, busy) => Column(
                        mainAxisSize: .min,
                        crossAxisAlignment: .stretch,
                        children: [
                          FocusableButton(
                            useBackgroundFocus: true,
                            onPressed: busy || this.busy ? null : browser,
                            child: FilledButton.icon(
                              onPressed: busy || this.busy ? null : browser,
                              icon: const BackendBadge(backend: MediaBackend.plex, size: 18),
                              label: Text(t.auth.signInWithPlex),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FocusableButton(
                            useBackgroundFocus: true,
                            onPressed: busy || this.busy ? null : qr,
                            child: OutlinedButton.icon(
                              onPressed: busy || this.busy ? null : qr,
                              icon: const AppIcon(Symbols.qr_code_rounded, fill: 1),
                              label: Text(t.auth.showQRCode),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...buildInlineError(theme, gap: 16, center: true),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

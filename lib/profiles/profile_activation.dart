import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connection/connection.dart';
import '../connection/connection_registry.dart';
import '../screens/profile/pin_entry_dialog.dart';
import '../services/plex_auth_service.dart';
import 'active_profile_binder.dart';
import 'active_profile_provider.dart';
import 'plex_home_switch.dart';
import 'profile.dart';
import 'profile_connection.dart';
import 'profile_connection_registry.dart';

/// Activate [profile] from a UI surface, prompting for the PIN when the
/// profile is protected. Returns `true` on successful activation, `false`
/// when the user cancelled the PIN dialog. Loops on wrong-PIN entries
/// until the user submits the right PIN or backs out.
///
/// The retry loop uses the same shake-on-error pattern as Plex Home users
/// — see [showPinEntryDialog].
///
/// For [ProfileKind.plexHome] profiles whose `plexProtected` flag is set,
/// the PIN is validated up front via `/home/users/{uuid}/switch` so a
/// failed PIN never flips `_active`. The minted user-token is saved and
/// the profile is marked pre-verified on the binder, so it reuses the cached
/// token instead of re-prompting for the same PIN.
Future<bool> activateProfileWithPin(BuildContext context, Profile profile) async {
  final active = context.read<ActiveProfileProvider>();

  if (profile.isPlexHome) {
    if (profile.plexProtected) {
      final ok = await _preVerifyPlexHomePin(context, profile);
      if (!ok) return false;
    }
    return active.activate(profile);
  }

  if (!profile.isPinProtected) {
    return active.activate(profile);
  }

  String? errorMessage;
  while (true) {
    if (!context.mounted) return false;
    final pin = await showPinEntryDialog(context, profile.displayName, errorMessage: errorMessage);
    if (pin == null) return false; // user cancelled
    final ok = await active.activate(profile, pin: pin);
    if (ok) return true;
    errorMessage = 'Incorrect PIN. Please try again.';
  }
}

/// Validate [profile]'s PIN with Plex via `/home/users/{uuid}/switch`. On
/// success, persist the minted user-token and mark the profile as
/// pre-verified so [ActiveProfileBinder] reuses the cached token instead
/// of re-prompting. Returns `false` on cancel or a final failure (caller
/// must abort activation in that case).
///
/// Returns `true` without doing anything when the profile lacks the
/// parent/uuid metadata or the parent connection is missing — the
/// binder's existing missing-metadata path will fire and silently
/// produce an empty bind, matching today's behavior. We don't want to
/// fail activation outright for users in unusual data states.
Future<bool> _preVerifyPlexHomePin(BuildContext context, Profile profile) async {
  final parentId = profile.parentConnectionId;
  final homeUuid = profile.plexHomeUserUuid;
  if (parentId == null || homeUuid == null) return true;

  final connections = context.read<ConnectionRegistry>();
  final all = await connections.list();
  PlexAccountConnection? account;
  for (final c in all) {
    if (c.id == parentId && c is PlexAccountConnection) {
      account = c;
      break;
    }
  }
  if (account == null) return true;

  final auth = await PlexAuthService.create();
  try {
    final result = await switchPlexHomeUserWithPin(
      auth: auth,
      accountToken: account.accountToken,
      homeUserUuid: homeUuid,
      requiresPin: true,
      promptForPin: ({String? errorMessage}) async {
        if (!context.mounted) return null;
        return showPinEntryDialog(context, profile.displayName, errorMessage: errorMessage);
      },
      logLabel: profile.displayName,
    );
    if (!result.succeeded) return false;
    if (!context.mounted) return false;
    final pcRegistry = context.read<ProfileConnectionRegistry>();
    await pcRegistry.upsert(
      ProfileConnection(
        profileId: profile.id,
        connectionId: account.id,
        userToken: result.userToken,
        userIdentifier: homeUuid,
        tokenAcquiredAt: DateTime.now(),
      ),
    );
    if (!context.mounted) return false;
    context.read<ActiveProfileBinder>().markPlexHomePreVerified(profile.id);
    return true;
  } finally {
    auth.dispose();
  }
}

/// Verify [pin] against [profile]'s stored PIN hash *without* activating it.
/// Used by the borrow flow: we need to confirm the user knows the source
/// profile's PIN before letting them copy a connection out of it.
///
/// Plex Home profiles can't be verified locally — their PIN lives on Plex's
/// servers. Callers should fall through to a real `/home/users/.../switch`
/// call instead.
bool verifyProfilePin(Profile profile, String pin) {
  if (!profile.isLocal) return false;
  final hash = profile.pinHash;
  if (hash == null || hash.isEmpty) return true;
  return verifyPin(pin, hash);
}

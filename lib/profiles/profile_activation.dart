import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connection/connection.dart';
import '../connection/connection_registry.dart';
import '../i18n/strings.g.dart';
import '../screens/profile/pin_entry_dialog.dart';
import '../services/storage_service.dart';
import '../services/tvos_user_profile_service.dart';
import '../utils/app_logger.dart';
import '../utils/dialogs.dart';
import '../utils/platform_detector.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/dialog_action_button.dart';
import 'active_profile_binder.dart';
import 'active_profile_provider.dart';
import 'plex_home_switch.dart';
import 'profile.dart';
import 'profile_connection_registry.dart';

/// How a UI-driven activation attempt ended. `cancelled` (user backed out
/// of a PIN dialog) is not an error and must not surface a failure message.
enum ProfileActivationOutcome { activated, cancelled, failed }

/// Activate [profile] from a UI surface, prompting for the PIN when the
/// profile is protected. Loops on wrong-PIN entries until the user submits
/// the right PIN or backs out.
///
/// The retry loop uses the same shake-on-error pattern as Plex Home users
/// — see [showPinEntryDialog].
///
/// For [ProfileKind.plexHome] profiles whose `plexProtected` flag is set,
/// the PIN is validated up front via `/home/users/{uuid}/switch` so a
/// failed PIN never flips `_active`. The minted user-token is saved and
/// the profile is marked pre-verified on the binder, so it reuses the cached
/// token instead of re-prompting for the same PIN.
Future<ProfileActivationOutcome> activateProfileWithPin(BuildContext context, Profile profile) async {
  final active = context.read<ActiveProfileProvider>();
  final binder = context.read<ActiveProfileBinder>();

  if (profile.isPlexHome) {
    if (profile.plexProtected) {
      final verified = await _preVerifyPlexHomePin(context, profile);
      if (verified != PlexHomeSwitchStatus.success) {
        return verified == PlexHomeSwitchStatus.cancelled
            ? ProfileActivationOutcome.cancelled
            : ProfileActivationOutcome.failed;
      }
    }
    binder.markUserInitiatedActivation(profile.id);
    return await active.activate(profile) ? ProfileActivationOutcome.activated : ProfileActivationOutcome.failed;
  }

  if (!profile.isPinProtected) {
    binder.markUserInitiatedActivation(profile.id);
    return await active.activate(profile) ? ProfileActivationOutcome.activated : ProfileActivationOutcome.failed;
  }

  String? errorMessage;
  while (true) {
    if (!context.mounted) return ProfileActivationOutcome.cancelled;
    final pin = await showPinEntryDialog(context, profile.displayName, errorMessage: errorMessage);
    if (pin == null) return ProfileActivationOutcome.cancelled; // user backed out
    final hash = profile.pinHash;
    if (hash != null && verifyPin(pin, hash)) {
      binder.markUserInitiatedActivation(profile.id);
      return await active.activate(profile, pin: pin)
          ? ProfileActivationOutcome.activated
          : ProfileActivationOutcome.failed;
    }
    errorMessage = t.profiles.incorrectPinTryAgain;
  }
}

/// Activate [profile] from a UI surface, then wait until the active profile's
/// server/token binding has settled. Shows the standard switch failure message
/// for activation and binding failures — but not for a PIN-dialog cancel,
/// which is the user changing their mind, not an error.
Future<bool> switchProfileFromUi(BuildContext context, Profile profile) async {
  final activeProvider = context.read<ActiveProfileProvider>();
  final outcome = await activateProfileWithPin(context, profile);
  if (!context.mounted) return false;
  switch (outcome) {
    case ProfileActivationOutcome.cancelled:
      return false;
    case ProfileActivationOutcome.failed:
      showErrorSnackBar(context, t.errors.failedToSwitchProfile(displayName: profile.displayName));
      return false;
    case ProfileActivationOutcome.activated:
      break;
  }

  final bound = await activeProvider.awaitBindingSettle();
  if (!context.mounted) return false;
  if (!bound) {
    showErrorSnackBar(context, t.errors.failedToSwitchProfile(displayName: profile.displayName));
    return false;
  }
  await maybePromptTvosProfileMapping(context, profile);
  return true;
}

enum _TvosMappingChoice { yes, notNow, dontAskAgain }

/// After a successful manual profile switch on Apple TV, offer to map the
/// current tvOS system user to [profile] so future user switches activate
/// it automatically (see [activateTvosMappedProfile]).
///
/// Stays quiet once this tvOS user has a mapping or opted out: "not now"
/// re-asks on a later switch, "don't ask again" (and clearing the mapping
/// from the settings screen) silences it for good.
Future<void> maybePromptTvosProfileMapping(BuildContext context, Profile profile) async {
  if (!PlatformDetector.isAppleTV()) return;
  final tvosUserId = await TvosUserProfileService().getCurrentUser();
  if (tvosUserId == null) return;
  final storage = await StorageService.getInstance();
  if (storage.getProfileIdForTvosUser(tvosUserId) != null) return;
  if (storage.wasTvosUserPromptedForMapping(tvosUserId)) return;
  if (!context.mounted) return;

  final choice = await showScopedDialog<_TvosMappingChoice>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(t.profiles.appleTvSync),
      content: Text(t.profiles.appleTvSyncPromptMessage(displayName: profile.displayName)),
      actions: [
        DialogActionButton(
          onPressed: () => Navigator.pop(dialogContext, _TvosMappingChoice.dontAskAgain),
          label: t.profiles.appleTvSyncPromptDontAskAgain,
        ),
        DialogActionButton(
          onPressed: () => Navigator.pop(dialogContext, _TvosMappingChoice.notNow),
          label: t.profiles.appleTvSyncPromptNotNow,
        ),
        DialogActionButton(
          autofocus: true,
          onPressed: () => Navigator.pop(dialogContext, _TvosMappingChoice.yes),
          label: t.common.yes,
          isPrimary: true,
        ),
      ],
    ),
  );

  switch (choice) {
    case _TvosMappingChoice.yes:
      await storage.setProfileIdForTvosUser(tvosUserId, profile.id);
    case _TvosMappingChoice.dontAskAgain:
      await storage.markTvosUserPromptedForMapping(tvosUserId);
    case _TvosMappingChoice.notNow:
    case null:
      // Ask again on a later manual switch.
      break;
  }
}

/// Validate [profile]'s PIN with Plex via `/home/users/{uuid}/switch`. On
/// success, persist the minted user-token and mark the profile as
/// pre-verified so [ActiveProfileBinder] reuses the cached token instead
/// of re-prompting.
///
/// Returns [PlexHomeSwitchStatus.success] without doing anything when the
/// profile lacks the parent/uuid metadata or the parent connection is
/// missing — the binder's existing missing-metadata path will fire and
/// silently produce an empty bind, matching today's behavior. We don't
/// want to fail activation outright for users in unusual data states.
Future<PlexHomeSwitchStatus> _preVerifyPlexHomePin(BuildContext context, Profile profile) async {
  final parentId = profile.parentConnectionId;
  final homeUuid = profile.plexHomeUserUuid;
  if (parentId == null || homeUuid == null) return PlexHomeSwitchStatus.success;

  final connections = context.read<ConnectionRegistry>();
  final pcRegistry = context.read<ProfileConnectionRegistry>();
  final binder = context.read<ActiveProfileBinder>();
  final all = await connections.list();
  PlexAccountConnection? account;
  for (final c in all) {
    if (c.id == parentId && c is PlexAccountConnection) {
      account = c;
      break;
    }
  }
  if (account == null) return PlexHomeSwitchStatus.success;

  final result = await mintPlexHomeUserToken(
    account: account,
    homeUserUuid: homeUuid,
    requiresPin: true,
    promptForPin: ({String? errorMessage}) async {
      if (!context.mounted) return null;
      return showPinEntryDialog(context, profile.displayName, errorMessage: errorMessage);
    },
    persistTo: pcRegistry,
    persistProfileId: profile.id,
    logLabel: profile.displayName,
  );
  if (result.succeeded) binder.markPlexHomePreVerified(profile.id);
  return result.status;
}

/// Auto-activate the Plezy profile mapped to the current Apple TV system
/// user, if any (see [TvosUserProfileService] and
/// [StorageService.getProfileIdForTvosUser]).
///
/// Non-PIN profiles switch silently. A PIN-protected mapped profile routes
/// through [activateProfileWithPin] — the same prompt as a manual switch —
/// when [context] is usable; a cancelled or wrong PIN just leaves the
/// current profile in place. Without a context, protected profiles are
/// skipped as a safe fallback. Returns true when a different profile was
/// activated.
Future<bool> activateTvosMappedProfile({
  required ActiveProfileProvider activeProfile,
  required ActiveProfileBinder binder,
  String? tvosUserId,
  BuildContext? context,
}) async {
  if (!PlatformDetector.isAppleTV()) return false;
  final userId = tvosUserId ?? await TvosUserProfileService().getCurrentUser();
  if (userId == null) return false;
  final storage = await StorageService.getInstance();
  final mappedId = storage.getProfileIdForTvosUser(userId);
  if (mappedId == null || mappedId == activeProfile.active?.id) return false;
  Profile? match;
  for (final p in activeProfile.profiles) {
    if (p.id == mappedId) {
      match = p;
      break;
    }
  }
  if (match == null) return false;
  if (match.isPinProtected) {
    if (context == null || !context.mounted) return false;
    appLogger.i('tvOS user mapping: asking PIN to activate ${match.displayName} ($mappedId)');
    return await activateProfileWithPin(context, match) == ProfileActivationOutcome.activated;
  }
  appLogger.i('tvOS user mapping: auto-activating ${match.displayName} ($mappedId)');
  binder.markUserInitiatedActivation(match.id);
  return activeProfile.activate(match);
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

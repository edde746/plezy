import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../connection/connection.dart';
import '../../connection/connection_registry.dart';
import '../../database/app_database.dart';
import '../../i18n/strings.g.dart';
import '../../profiles/active_profile_binder.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/profile.dart';
import '../../profiles/profile_connection.dart';
import '../../profiles/profile_connection_registry.dart';
import '../../profiles/profile_registry.dart';
import '../../services/storage_service.dart';
import '../../utils/app_logger.dart';
import '../profile/profile_switch_screen.dart';

/// Durably provision a freshly-authenticated [connection] and its optional
/// [bindToProfile] ownership row.
///
/// [firstRunProfile], [connection], and [bindToProfile] are committed in one
/// shared database transaction. The new profile is activated only after that
/// relational commit. If activation rejects or throws, the relational bundle
/// and the exact prior active-profile marker are restored before the original
/// error is rethrown.
///
/// All durable collaborators are captured before the first await, so a route
/// unmount cannot interrupt the command between artifacts. Runtime pickup is
/// left to the active-profile binder on the next switch or rebind. The helper
/// itself does not navigate.
Future<void> persistAndBindConnection({
  required BuildContext context,
  required Connection connection,
  required ProfileConnection? bindToProfile,
  Profile? firstRunProfile,
}) async {
  final db = context.read<AppDatabase>();
  final profiles = context.read<ProfileRegistry>();
  final connections = context.read<ConnectionRegistry>();
  final profileConnections = context.read<ProfileConnectionRegistry>();
  final activeProfiles = context.read<ActiveProfileProvider>();
  final storage = context.read<StorageService>();

  final priorActiveProfileId = storage.getActiveProfileId();
  final priorConnection = await connections.get(connection.id);

  await db.runIdentityMutation(
    () => db.transaction(() async {
      if (firstRunProfile != null) {
        await profiles.upsert(firstRunProfile);
      }
      await connections.upsert(connection);
      if (bindToProfile != null) {
        await profileConnections.upsert(bindToProfile);
      }
    }),
  );

  if (firstRunProfile != null) {
    try {
      final activated = await activeProfiles.activate(firstRunProfile);
      if (!activated) {
        throw StateError('The first-run profile could not be activated');
      }
    } catch (error, stackTrace) {
      await _compensateFailedActivation(
        db: db,
        profiles: profiles,
        connections: connections,
        profileConnections: profileConnections,
        activeProfiles: activeProfiles,
        storage: storage,
        firstRunProfile: firstRunProfile,
        bindToProfile: bindToProfile,
        attemptedConnection: connection,
        priorConnection: priorConnection,
        priorActiveProfileId: priorActiveProfileId,
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

Future<void> _compensateFailedActivation({
  required AppDatabase db,
  required ProfileRegistry profiles,
  required ConnectionRegistry connections,
  required ProfileConnectionRegistry profileConnections,
  required ActiveProfileProvider activeProfiles,
  required StorageService storage,
  required Profile firstRunProfile,
  required ProfileConnection? bindToProfile,
  required Connection attemptedConnection,
  required Connection? priorConnection,
  required String? priorActiveProfileId,
}) async {
  try {
    await db.runIdentityMutation(
      () => db.transaction(() async {
        if (bindToProfile != null) {
          await profileConnections.remove(bindToProfile.profileId, bindToProfile.connectionId);
        }
        await profiles.remove(firstRunProfile.id);
        if (priorConnection == null) {
          await connections.remove(attemptedConnection.id);
        } else {
          await connections.upsert(priorConnection);
        }
      }),
    );
  } catch (error, stackTrace) {
    appLogger.e('First-run relational compensation failed', error: error, stackTrace: stackTrace);
  }

  try {
    await storage.clearProfileLastUsed(firstRunProfile.id);
  } catch (error, stackTrace) {
    appLogger.e('First-run recency compensation failed', error: error, stackTrace: stackTrace);
  }

  try {
    if (priorActiveProfileId == null) {
      await storage.clearActiveProfileId();
    } else {
      await storage.setActiveProfileId(priorActiveProfileId);
    }
  } catch (error, stackTrace) {
    appLogger.e('First-run active marker compensation failed', error: error, stackTrace: stackTrace);
  }

  try {
    await activeProfiles.reloadFromStorage();
  } catch (error, stackTrace) {
    appLogger.e('First-run active profile reload failed', error: error, stackTrace: stackTrace);
  }
}

/// Durably provisions a freshly-authenticated direct server connection (Jellyfin, Plex Direct, etc.),
/// resolves or creates the profile it binds to, rebinds if active, and pops the current route with `true`.
///
/// If [targetProfile] is provided, binds directly to it.
/// If no target is provided and active profile exists, binds to it.
/// If multiple profiles exist and none is active, prompts for selection using [ProfileSwitchScreen].
/// If no profiles exist at all, provisions a new local first-run profile using [defaultProfileName].
Future<void> persistDirectServerConnectionAndExit({
  required BuildContext context,
  required Connection connection,
  required String userIdentifier,
  required String userToken,
  required String defaultProfileName,
  Profile? targetProfile,
  required void Function(String error) onError,
}) async {
  final activeProvider = context.read<ActiveProfileProvider>();
  await activeProvider.initialize();
  if (!context.mounted) return;

  var boundProfile = targetProfile ?? activeProvider.active;
  if (targetProfile == null && boundProfile == null && activeProvider.profiles.isNotEmpty) {
    await Navigator.of(
      context,
      rootNavigator: true,
    ).push<bool>(MaterialPageRoute(builder: (_) => const ProfileSwitchScreen(requireSelection: true)));
    if (!context.mounted) return;
    boundProfile = activeProvider.active;
    if (boundProfile == null) {
      onError(t.messages.noProfilesAvailable);
      return;
    }
  }

  Profile? firstRunProfile;
  if (targetProfile == null && boundProfile == null && activeProvider.profiles.isEmpty) {
    final now = DateTime.now();
    firstRunProfile = Profile.local(
      id: 'local-${const Uuid().v4()}',
      displayName: defaultProfileName,
      sortOrder: now.millisecondsSinceEpoch,
      createdAt: now,
    );
    boundProfile = firstRunProfile;
  }

  final bindProfile = boundProfile;
  if (bindProfile == null) {
    onError(t.messages.noProfilesAvailable);
    return;
  }

  await persistAndBindConnection(
    context: context,
    connection: connection,
    bindToProfile: ProfileConnection(
      profileId: bindProfile.id,
      connectionId: connection.id,
      userToken: userToken,
      userIdentifier: userIdentifier,
      tokenAcquiredAt: DateTime.now(),
    ),
    firstRunProfile: firstRunProfile,
  );

  final boundToActive = bindProfile.id == activeProvider.activeId;
  if (!context.mounted) return;
  if (boundToActive) {
    await context.read<ActiveProfileBinder>().rebindIfActive(bindProfile.id);
  }

  if (!context.mounted) return;
  Navigator.of(context).pop(true);
}

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../connection/connection.dart';
import '../../connection/connection_registry.dart';
import '../../database/app_database.dart';
import '../../media/ids.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/profile.dart';
import '../../profiles/profile_connection.dart';
import '../../profiles/profile_connection_registry.dart';
import '../../profiles/profile_registry.dart';
import '../../providers/libraries_provider.dart';
import '../../providers/multi_server_provider.dart';
import '../../services/storage_service.dart';
import '../../utils/app_logger.dart';

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
/// unmount cannot interrupt the command between artifacts. Runtime manager,
/// visibility, and library-loading effects remain post-commit and mounted
/// gated. The helper itself does not navigate.
Future<bool> persistAndBindConnection({
  required BuildContext context,
  required Connection connection,
  required ProfileConnection? bindToProfile,
  required Future<bool> Function()? addToManager,
  Profile? firstRunProfile,
  String? visibleServerId,
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

  if (!context.mounted || addToManager == null) return false;
  final added = await addToManager();
  if (!context.mounted || !added) return added;

  final mp = context.read<MultiServerProvider>();
  if (visibleServerId != null) {
    mp.addToVisibleServerIds(ServerId(visibleServerId));
  }
  unawaited(context.read<LibrariesProvider>().loadLibraries());
  return true;
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

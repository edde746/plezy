import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../connection/connection_registry.dart';
import '../../database/app_database.dart';
import '../../i18n/strings.g.dart';
import '../../profiles/active_profile_binder.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/plex_home_service.dart';
import '../../profiles/profile.dart';
import '../../profiles/profile_connection_cleanup.dart';
import '../../profiles/profile_connection_registry.dart';
import '../../profiles/profile_registry.dart';
import '../../providers/companion_remote_provider.dart';
import '../../providers/download_provider.dart';
import '../../providers/discover_provider.dart';
import '../../providers/hidden_libraries_provider.dart';
import '../../providers/multi_server_provider.dart';
import '../../providers/playback_state_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/api_cache.dart';
import '../../services/multi_server_manager.dart';
import '../../services/storage_service.dart';
import '../../services/system_shelf_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/dialogs.dart';
import '../../utils/snackbar_helper.dart';
import '../auth_screen.dart';

/// The collaborators every teardown flow needs, snapshotted from [context]
/// BEFORE the first await so no flow touches `context.read` mid-teardown.
class SessionTeardownScope {
  final ActiveProfileProvider active;
  final ActiveProfileBinder binder;
  final PlexHomeService plexHome;
  final ProfileRegistry profileRegistry;
  final ProfileConnectionRegistry profileConnections;
  final ConnectionRegistry connections;
  final MultiServerProvider multiServer;
  final HiddenLibrariesProvider? hiddenLibraries;
  final DiscoverProvider? discover;
  final DownloadProvider downloads;
  final AppDatabase database;
  final StorageService storage;
  final NavigatorState navigator;
  final SystemShelfService shelf;

  MultiServerManager get serverManager => multiServer.serverManager;

  ProfileConnectionCleanup get cleanup => ProfileConnectionCleanup(
    profileConnections: profileConnections,
    connections: connections,
    storage: storage,
    serverManager: serverManager,
  );

  SessionTeardownScope.of(BuildContext context)
    : active = context.read<ActiveProfileProvider>(),
      binder = context.read<ActiveProfileBinder>(),
      plexHome = context.read<PlexHomeService>(),
      profileRegistry = context.read<ProfileRegistry>(),
      profileConnections = context.read<ProfileConnectionRegistry>(),
      connections = context.read<ConnectionRegistry>(),
      multiServer = context.read<MultiServerProvider>(),
      hiddenLibraries = context.read<HiddenLibrariesProvider?>(),
      discover = context.read<DiscoverProvider?>(),
      downloads = context.read<DownloadProvider>(),
      database = context.read<AppDatabase>(),
      storage = context.read<StorageService>(),
      shelf = SystemShelfService(),
      navigator = Navigator.of(context, rootNavigator: true);
}

/// Decide where the session lands after any profile/connection removal and
/// apply it. Mirrors the boot guard: no connections, or connections but no
/// resolvable profile, routes to [AuthScreen]; otherwise the active profile
/// is kept (optionally rebound) or the next non-PIN-protected profile is
/// activated so the picker can force an explicit, PIN-checked choice when
/// only protected profiles remain.
///
/// Returns true when it navigated to [AuthScreen] — the caller must stop
/// touching its own UI in that case.
Future<bool> settleSessionAfterRemoval(
  SessionTeardownScope scope, {
  bool rebindIfActiveKept = false,
  String? endedShelfOwner,
}) async {
  final result = await scope.cleanup.resolvePostRemovalState(
    profileRegistry: scope.profileRegistry,
    plexHomeUsers: scope.plexHome.current,
  );

  if (result.route == PostRemovalRoute.signedOut) {
    await scope.active.clearActiveProfile();
    await scope.binder.rebindActive();
    if (scope.navigator.mounted) {
      unawaited(
        scope.navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AuthScreen()), (_) => false),
      );
    }
    return true;
  }

  final activeId = scope.storage.getActiveProfileId();
  final activeStillExists = activeId != null && result.profiles.any((p) => p.id == activeId);
  if (activeStillExists) {
    if (rebindIfActiveKept) {
      if (endedShelfOwner == activeId) {
        await resumeFreshSystemShelf(scope, activeId);
      } else {
        await scope.binder.rebindActive();
      }
    }
  } else {
    // Auto-activation must not bypass PIN gates ([activate] rejects local
    // PIN profiles without a pin; protected Plex Home profiles would PIN
    // prompt at bind time) — skip protected profiles instead.
    Profile? next;
    for (final profile in result.profiles) {
      if (!profile.isPinProtected) {
        next = profile;
        break;
      }
    }
    // The removal was a user action: mark the hand-off activation as
    // user-initiated so the binder binds it (bypassing the initial-bind
    // defer and any suppressed failed-bind marker).
    if (next != null) scope.binder.markUserInitiatedActivation(next.id);
    final activated = next != null && await scope.active.activate(next);
    if (!activated) {
      await scope.active.clearActiveProfile();
      await scope.binder.rebindActive();
    }
  }
  await scope.hiddenLibraries?.refresh();
  return false;
}

/// Rebinds a surviving owner before admitting fresh shelf publication.
///
/// A failed rebind deliberately leaves the owner invalidated and the native
/// shelf empty.
Future<void> resumeFreshSystemShelf(SessionTeardownScope scope, String profileId) async {
  if (scope.active.activeId != profileId) return;
  try {
    await scope.binder.rebindIfActive(profileId);
    if (scope.active.activeId != profileId) return;
    scope.shelf.beginProfileSession(profileId);
    if (scope.multiServer.hasConnectedServers) {
      await scope.discover?.load();
    }
  } catch (error, stackTrace) {
    appLogger.w('Failed to restore system shelf after profile teardown', error: error, stackTrace: stackTrace);
  }
}

Future<String?> _activeProfileUsingConnection(SessionTeardownScope scope, String connectionId) async {
  final active = scope.active.active;
  if (active == null) return null;
  final usesConnection =
      active.parentConnectionId == connectionId ||
      (await scope.profileConnections.listForProfile(active.id)).any((row) => row.connectionId == connectionId);
  if (!usesConnection || scope.active.activeId != active.id) return null;
  return active.id;
}

Future<bool> confirmAndDeleteProfile(
  BuildContext context, {
  required Profile profile,
  required String title,
  required String message,
  String? confirmText,
}) async {
  final confirmed = await showDeleteConfirmation(context, title: title, message: message, confirmText: confirmText);
  if (!confirmed || !context.mounted) return false;

  try {
    await deleteProfile(context, profile);
    return true;
  } catch (error, stackTrace) {
    appLogger.w('Failed to delete profile ${profile.id}', error: error, stackTrace: stackTrace);
    if (context.mounted) {
      showErrorSnackBar(context, t.errors.failedToDeleteProfile(displayName: profile.displayName));
    }
    return false;
  }
}

/// Delete a local profile and everything it owns: downloads, sync rules,
/// queued watch actions, join rows (pruning now-unreferenced Jellyfin
/// connections), last-used marker, and user-scoped prefs.
Future<void> deleteProfile(BuildContext context, Profile profile) async {
  final scope = SessionTeardownScope.of(context);
  final endedOwner = scope.active.activeId == profile.id ? profile.id : null;
  if (endedOwner != null) {
    await scope.shelf.endProfileSession(endedOwner);
  }

  try {
    await scope.downloads.deleteDownloadsForProfile(profile.id);
    await scope.database.deleteSyncRulesForProfile(profile.id);
    await scope.database.deleteWatchActionsForProfile(profile.id);
    await scope.cleanup.removeAllProfileConnections(profile.id);
    await scope.profileRegistry.remove(profile.id);
    await scope.storage.clearProfileLastUsed(profile.id);
    await scope.storage.clearUserScopedPreferencesForProfile(profile.id);

    await settleSessionAfterRemoval(scope, endedShelfOwner: endedOwner);
  } catch (_) {
    if (endedOwner != null) {
      await resumeFreshSystemShelf(scope, endedOwner);
    }
    rethrow;
  }
}

/// Sign out of a Plex account after confirmation: the account connection,
/// its virtual Plex Home profiles, and their borrowed connections are all
/// removed (#1423); surviving borrower profiles release the account's
/// server downloads. Plex exposes no reliable single-session revoke
/// endpoint, so the server side is untouched — the user can revoke the
/// device via plex.tv.
///
/// Returns true when the sign-out ran, false when cancelled or the account
/// no longer exists.
Future<bool> confirmAndSignOutPlexAccount(BuildContext context, {required String accountConnectionId}) async {
  final account = await context.read<ConnectionRegistry>().getPlexAccount(accountConnectionId);
  if (account == null || !context.mounted) return false;

  final confirmed = await showDeleteConfirmation(
    context,
    title: t.profiles.signOutPlexTitle,
    message: t.profiles.signOutPlexMessage(displayName: account.displayLabel),
    confirmText: t.profiles.signOut,
  );
  if (!confirmed || !context.mounted) return false;

  final scope = SessionTeardownScope.of(context);
  String? endedOwner;
  try {
    final removal = await planPlexAccountConnectionRemoval(
      account: account,
      profileConnections: scope.profileConnections,
    );
    endedOwner = await _activeProfileUsingConnection(scope, accountConnectionId);
    if (endedOwner != null) {
      await scope.shelf.endProfileSession(endedOwner);
    }

    // Physical download cleanup can fail. Finish it while the account and
    // every ownership join still exist so a retry can resolve the same plan
    // instead of stranding files without an owner.
    for (final profileId in removal.removedVirtualProfileIds) {
      await scope.downloads.deleteDownloadsForProfile(profileId);
    }
    final accountServerIds = {for (final server in account.servers) server.clientIdentifier};
    for (final profileId in removal.borrowerProfileIds) {
      await scope.downloads.releaseDownloadsForProfileServers(profileId, accountServerIds);
    }

    await scope.cleanup.removePlexAccountConnection(account, plannedRemoval: removal);
    for (final profileId in removal.removedVirtualProfileIds) {
      await scope.database.deleteSyncRulesForProfile(profileId);
      await scope.database.deleteWatchActionsForProfile(profileId);
    }

    final navigatedAway = await settleSessionAfterRemoval(scope, rebindIfActiveKept: true, endedShelfOwner: endedOwner);
    if (!navigatedAway && context.mounted) {
      showSuccessSnackBar(context, t.profiles.signedOutPlex);
    }
    return true;
  } catch (e, st) {
    if (endedOwner != null) {
      await resumeFreshSystemShelf(scope, endedOwner);
    }
    appLogger.w('Plex sign-out failed for $accountConnectionId', error: e, stackTrace: st);
    if (context.mounted) {
      showErrorSnackBar(context, t.profiles.signOutFailed);
    }
    return false;
  }
}

/// Full logout: clear every profile, connection, credential, cached API
/// row, and user-scoped pref, then reset to [AuthScreen]. The caller
/// confirms first.
Future<void> logoutAllProfiles(BuildContext context) async {
  final scope = SessionTeardownScope.of(context);
  final userProfileProvider = context.read<UserProfileProvider>();
  final companionRemote = context.read<CompanionRemoteProvider>();
  final playbackState = context.read<PlaybackStateProvider>();

  final activeOwner = scope.active.activeId;
  if (activeOwner != null) {
    await scope.shelf.endProfileSession(activeOwner);
  }

  await companionRemote.resetForLogout();
  await userProfileProvider.logout();
  // Downloads are device-local data, not credentials. Keep their physical
  // files and pinned metadata, but detach profile ownership before deleting
  // the profiles so the next selected profile can adopt them.
  await scope.downloads.detachDownloadsForLogout();
  scope.multiServer.clearAllConnections();
  // Drop the profile/connection rows so the next sign-in starts clean and
  // doesn't bind to stale tokens or orphaned profile rows.
  await scope.profileConnections.clear();
  await scope.profileRegistry.clear();
  await scope.connections.clear();
  await scope.plexHome.clearAll();
  await scope.storage.clearActiveProfileId();
  await scope.storage.clearAllProfileLastUsed();
  await scope.storage.clearAllUserScopedPreferences();
  // Queued watch actions and sync rules are keyed by the profiles that just
  // ceased to exist; left behind they'd strand forever (or worse, replay
  // through the next sign-in's clients).
  await scope.database.clearAllWatchActions();
  await scope.database.clearAllSyncRules();
  // Preserve pinned rows backing offline downloads; all session/API data is
  // volatile and must not cross into the next sign-in.
  await ApiCache.clearRegisteredVolatile();
  await scope.hiddenLibraries?.refresh();
  playbackState.clearShuffle();

  if (scope.navigator.mounted) {
    unawaited(scope.navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AuthScreen()), (_) => false));
  }
}

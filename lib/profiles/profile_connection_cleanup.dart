import '../connection/connection.dart';
import '../connection/connection_registry.dart';
import '../media/ids.dart';
import '../models/plex/plex_home_user.dart';
import '../services/multi_server_manager.dart';
import '../services/storage_service.dart';
import 'profile.dart';
import 'profile_connection_registry.dart';
import 'profile_merge.dart';
import 'profile_registry.dart';

/// Profile ids affected by a Plex account removal. Planning is read-only so
/// callers can finish failure-prone cleanup before committing join/account
/// deletion.
typedef PlexAccountRemoval = ({
  /// The account's virtual Plex Home profiles — they cease to exist.
  Set<String> removedVirtualProfileIds,

  /// Profiles that survive but had a join row onto the removed account
  /// (locals that borrowed a home user).
  Set<String> borrowerProfileIds,
});

Future<PlexAccountRemoval> planPlexAccountConnectionRemoval({
  required PlexAccountConnection account,
  required ProfileConnectionRegistry profileConnections,
}) async {
  final rows = await profileConnections.listAll();
  final removedVirtualProfileIds = <String>{
    for (final row in rows)
      if (parsePlexHomeProfileId(row.profileId)?.accountConnectionId == account.id) row.profileId,
  };
  final borrowerProfileIds = <String>{
    for (final row in rows)
      if (row.connectionId == account.id && !removedVirtualProfileIds.contains(row.profileId)) row.profileId,
  };
  return (removedVirtualProfileIds: removedVirtualProfileIds, borrowerProfileIds: borrowerProfileIds);
}

/// Where the session should land after a profile or connection removal.
enum PostRemovalRoute { signedOut, staySignedIn }

/// Removal of profile↔connection join rows and everything they leave
/// unreferenced, bound to one set of registries. Every flow resolves the same
/// instances from the provider tree, so callers construct this once and call
/// through it.
class ProfileConnectionCleanup {
  ProfileConnectionCleanup({
    required this.profileConnections,
    required this.connections,
    required this.storage,
    this.serverManager,
  });

  final ProfileConnectionRegistry profileConnections;
  final ConnectionRegistry connections;
  final StorageService storage;
  final MultiServerManager? serverManager;

  Future<void> removeProfileConnection({required String profileId, required Connection connection}) async {
    final removedServerIds = _serverIdsForConnection(connection);
    await profileConnections.remove(profileId, connection.id);
    await _clearProfileServerPrefsNoLongerReferenced(
      profileId: profileId,
      removedServerIds: removedServerIds,
      clearEverywhereWhenUnreferenced: connection is JellyfinConnection,
    );

    if (connection is JellyfinConnection) {
      await _removeUnreferencedJellyfinConnection(connection);
    }
  }

  Future<void> removeAllProfileConnections(String profileId) async {
    final rows = await profileConnections.listForProfile(profileId);
    if (rows.isEmpty) return;

    final all = await connections.list();
    final byId = {for (final connection in all) connection.id: connection};
    for (final row in rows) {
      final connection = byId[row.connectionId];
      if (connection == null) {
        await profileConnections.remove(profileId, row.connectionId);
        continue;
      }
      await removeProfileConnection(profileId: profileId, connection: connection);
    }
  }

  /// Sign out of a Plex account: remove the account [Connection], every join
  /// row referencing it, and everything owned by its virtual Plex Home
  /// profiles — including borrowed Jellyfin connections left unreferenced,
  /// which previously survived as orphans and wedged the session (#1423).
  ///
  /// Pass a read-only [plannedRemoval] from
  /// [planPlexAccountConnectionRemoval] when failure-prone caller-owned cleanup
  /// must finish before this destructive commit. Omitting it preserves the
  /// atomic add/cancel-account cleanup path.
  ///
  /// All cleanup is explicit and completes before this returns; correctness
  /// must not depend on [PlexHomeService]'s stream-driven `_onChange`, which
  /// runs later and no-ops.
  Future<PlexAccountRemoval> removePlexAccountConnection(
    PlexAccountConnection account, {
    PlexAccountRemoval? plannedRemoval,
  }) async {
    final removal =
        plannedRemoval ??
        await planPlexAccountConnectionRemoval(account: account, profileConnections: profileConnections);
    final removedVirtualProfileIds = removal.removedVirtualProfileIds;
    final borrowerProfileIds = removal.borrowerProfileIds;
    final rows = await profileConnections.listAll();
    // Remove direct join rows first so per-profile pref cleanup observes each
    // row going away; the FK cascade from the connection delete is then a no-op.
    for (final row in rows.where((r) => r.connectionId == account.id)) {
      await removeProfileConnection(profileId: row.profileId, connection: account);
    }
    await connections.remove(account.id);
    await storage.clearPlexHomeUsersCache(account.id);

    // The account's virtual profiles die with the connection; their borrowed
    // connections and per-profile prefs must go too.
    for (final profileId in removedVirtualProfileIds) {
      await removeAllProfileConnections(profileId);
      await storage.clearProfileLastUsed(profileId);
      await storage.clearUserScopedPreferencesForProfile(profileId);
    }

    return (removedVirtualProfileIds: removedVirtualProfileIds, borrowerProfileIds: borrowerProfileIds);
  }

  /// In-session mirror of the boot guard (`main.dart`: "stored connections
  /// exist but no profiles resolved — returning to auth"): prune orphaned
  /// Jellyfin connections, then decide whether any selectable profile remains.
  /// [plexHomeUsers] is [PlexHomeService.current]; stale entries for removed
  /// accounts are harmless because the connection map is re-read here.
  Future<({PostRemovalRoute route, List<Profile> profiles})> resolvePostRemovalState({
    required ProfileRegistry profileRegistry,
    required Map<String, List<PlexHomeUser>> plexHomeUsers,
  }) async {
    await pruneUnreferencedJellyfinConnections();
    final conns = await connections.list();
    if (conns.isEmpty) return (route: PostRemovalRoute.signedOut, profiles: const <Profile>[]);

    final merged = mergeLocalWithPlexHome(
      locals: await profileRegistry.list(),
      plexHomeByConnectionId: plexHomeUsers,
      connectionsById: {for (final c in conns) c.id: c},
      storage: storage,
    );
    if (merged.isEmpty) return (route: PostRemovalRoute.signedOut, profiles: const <Profile>[]);
    return (route: PostRemovalRoute.staySignedIn, profiles: merged);
  }

  Future<int> pruneUnreferencedJellyfinConnections() async {
    final all = await connections.list();
    final referencedConnectionIds = (await profileConnections.listAll()).map((row) => row.connectionId).toSet();
    var removed = 0;

    for (final connection in all.whereType<JellyfinConnection>()) {
      if (referencedConnectionIds.contains(connection.id)) continue;
      await _removeJellyfinConnection(connection);
      removed++;
    }

    return removed;
  }

  Future<void> _removeUnreferencedJellyfinConnection(JellyfinConnection connection) async {
    if ((await profileConnections.listForConnection(connection.id)).isNotEmpty) return;
    await _removeJellyfinConnection(connection);
  }

  Future<void> _removeJellyfinConnection(JellyfinConnection connection) async {
    await connections.remove(connection.id);
    serverManager?.removeJellyfinConnection(connection);
    final serverId = ServerId.tryParse(connection.serverMachineId);
    if (serverId != null && !await _isServerReferenced(serverId)) {
      await storage.clearLibraryPreferencesForServerEverywhere(serverId);
    }
  }

  Future<void> _clearProfileServerPrefsNoLongerReferenced({
    required String profileId,
    required Set<ServerId> removedServerIds,
    required bool clearEverywhereWhenUnreferenced,
  }) async {
    if (removedServerIds.isEmpty) return;
    final remainingProfileServerIds = await _serverIdsForProfile(profileId);
    final activeProfileId = storage.getActiveProfileId();

    for (final serverId in removedServerIds) {
      if (remainingProfileServerIds.contains(serverId)) continue;
      final serverStillReferenced = await _isServerReferenced(serverId);
      if (serverStillReferenced || !clearEverywhereWhenUnreferenced) {
        await storage.clearLibraryPreferencesForServer(
          serverId,
          profileId: profileId,
          includeLegacy: activeProfileId == profileId,
        );
      } else {
        await storage.clearLibraryPreferencesForServerEverywhere(serverId);
      }
    }
  }

  /// Server ids reachable through this profile's join rows. Narrower than
  /// `ActiveProfileBinder._expectedServerIdsForProfile`: an implicit Plex Home
  /// parent is not counted here, so folding the two together would change which
  /// per-profile prefs survive an unlink.
  Future<Set<ServerId>> _serverIdsForProfile(String profileId) async {
    final rows = await profileConnections.listForProfile(profileId);
    if (rows.isEmpty) return const {};

    final all = await connections.list();
    final byId = {for (final connection in all) connection.id: connection};
    return {
      for (final row in rows)
        if (byId[row.connectionId] case final connection?) ..._serverIdsForConnection(connection),
    };
  }

  Future<bool> _isServerReferenced(ServerId serverId) async {
    final rows = await profileConnections.listAll();
    if (rows.isEmpty) return false;

    final all = await connections.list();
    final byId = {for (final connection in all) connection.id: connection};
    for (final row in rows) {
      final connection = byId[row.connectionId];
      if (connection != null && _serverIdsForConnection(connection).contains(serverId)) return true;
    }
    return false;
  }
}

// [ServerId]-typed for the preference APIs, which drops ids that fail to
// parse; the twin in profile_detail_screen.dart stays raw so it can be
// differenced against download keys.
Set<ServerId> _serverIdsForConnection(Connection connection) {
  return switch (connection) {
    PlexAccountConnection(:final servers) => {
      for (final server in servers) ?ServerId.tryParse(server.clientIdentifier),
    },
    JellyfinConnection(:final serverMachineId) => {?ServerId.tryParse(serverMachineId)},
  };
}

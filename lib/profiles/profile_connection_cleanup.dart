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

Future<void> removeProfileConnectionAndCleanup({
  required String profileId,
  required Connection connection,
  required ProfileConnectionRegistry profileConnections,
  required ConnectionRegistry connections,
  required StorageService storage,
  MultiServerManager? serverManager,
}) async {
  final removedServerIds = _serverIdsForConnection(connection);
  await profileConnections.remove(profileId, connection.id);
  await _clearProfileServerPrefsNoLongerReferenced(
    profileId: profileId,
    removedServerIds: removedServerIds,
    profileConnections: profileConnections,
    connections: connections,
    storage: storage,
    clearEverywhereWhenUnreferenced: connection is JellyfinConnection,
  );

  if (connection is JellyfinConnection) {
    await _removeUnreferencedJellyfinConnection(
      connection,
      profileConnections: profileConnections,
      connections: connections,
      storage: storage,
      serverManager: serverManager,
    );
  }
}

Future<void> removeAllProfileConnectionsAndCleanup({
  required String profileId,
  required ProfileConnectionRegistry profileConnections,
  required ConnectionRegistry connections,
  required StorageService storage,
  MultiServerManager? serverManager,
}) async {
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
    await removeProfileConnectionAndCleanup(
      profileId: profileId,
      connection: connection,
      profileConnections: profileConnections,
      connections: connections,
      storage: storage,
      serverManager: serverManager,
    );
  }
}

/// Profile ids affected by a Plex account removal, so the caller can sweep
/// per-profile data (downloads, sync rules, queued watch actions) that this
/// layer doesn't own.
typedef PlexAccountRemoval = ({
  /// The account's virtual Plex Home profiles — they cease to exist.
  Set<String> removedVirtualProfileIds,

  /// Profiles that survive but had a join row onto the removed account
  /// (locals that borrowed a home user).
  Set<String> borrowerProfileIds,
});

/// Sign out of a Plex account: remove the account [Connection], every join
/// row referencing it, and everything owned by its virtual Plex Home
/// profiles — including borrowed Jellyfin connections left unreferenced,
/// which previously survived as orphans and wedged the session (#1423).
///
/// All cleanup is explicit and completes before this returns; correctness
/// must not depend on [PlexHomeService]'s stream-driven `_onChange`, which
/// runs later and no-ops.
Future<PlexAccountRemoval> removePlexAccountConnectionAndCleanup({
  required PlexAccountConnection account,
  required ProfileConnectionRegistry profileConnections,
  required ConnectionRegistry connections,
  required StorageService storage,
  MultiServerManager? serverManager,
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

  // Remove direct join rows first so per-profile pref cleanup observes each
  // row going away; the FK cascade from the connection delete is then a no-op.
  for (final row in rows.where((r) => r.connectionId == account.id)) {
    await removeProfileConnectionAndCleanup(
      profileId: row.profileId,
      connection: account,
      profileConnections: profileConnections,
      connections: connections,
      storage: storage,
      serverManager: serverManager,
    );
  }
  await connections.remove(account.id);
  await storage.clearPlexHomeUsersCache(account.id);

  // The account's virtual profiles die with the connection; their borrowed
  // connections and per-profile prefs must go too.
  for (final profileId in removedVirtualProfileIds) {
    await removeAllProfileConnectionsAndCleanup(
      profileId: profileId,
      profileConnections: profileConnections,
      connections: connections,
      storage: storage,
      serverManager: serverManager,
    );
    await storage.clearProfileLastUsed(profileId);
    await storage.clearUserScopedPreferencesForProfile(profileId);
  }

  return (removedVirtualProfileIds: removedVirtualProfileIds, borrowerProfileIds: borrowerProfileIds);
}

/// Where the session should land after a profile or connection removal.
enum PostRemovalRoute { signedOut, staySignedIn }

/// In-session mirror of the boot guard (`main.dart`: "stored connections
/// exist but no profiles resolved — returning to auth"): prune orphaned
/// Jellyfin connections, then decide whether any selectable profile remains.
/// [plexHomeUsers] is [PlexHomeService.current]; stale entries for removed
/// accounts are harmless because the connection map is re-read here.
Future<({PostRemovalRoute route, List<Profile> profiles})> resolvePostRemovalState({
  required ProfileRegistry profileRegistry,
  required ProfileConnectionRegistry profileConnections,
  required ConnectionRegistry connections,
  required Map<String, List<PlexHomeUser>> plexHomeUsers,
  required StorageService storage,
  MultiServerManager? serverManager,
}) async {
  await pruneUnreferencedJellyfinConnections(
    profileConnections: profileConnections,
    connections: connections,
    storage: storage,
    serverManager: serverManager,
  );
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

Future<int> pruneUnreferencedJellyfinConnections({
  required ProfileConnectionRegistry profileConnections,
  required ConnectionRegistry connections,
  required StorageService storage,
  MultiServerManager? serverManager,
}) async {
  final all = await connections.list();
  final referencedConnectionIds = (await profileConnections.listAll()).map((row) => row.connectionId).toSet();
  var removed = 0;

  for (final connection in all.whereType<JellyfinConnection>()) {
    if (referencedConnectionIds.contains(connection.id)) continue;
    await _removeJellyfinConnection(
      connection,
      profileConnections: profileConnections,
      connections: connections,
      storage: storage,
      serverManager: serverManager,
    );
    removed++;
  }

  return removed;
}

Future<void> _removeUnreferencedJellyfinConnection(
  JellyfinConnection connection, {
  required ProfileConnectionRegistry profileConnections,
  required ConnectionRegistry connections,
  required StorageService storage,
  MultiServerManager? serverManager,
}) async {
  if ((await profileConnections.listForConnection(connection.id)).isNotEmpty) return;
  await _removeJellyfinConnection(
    connection,
    profileConnections: profileConnections,
    connections: connections,
    storage: storage,
    serverManager: serverManager,
  );
}

Future<void> _removeJellyfinConnection(
  JellyfinConnection connection, {
  required ProfileConnectionRegistry profileConnections,
  required ConnectionRegistry connections,
  required StorageService storage,
  MultiServerManager? serverManager,
}) async {
  await connections.remove(connection.id);
  serverManager?.removeJellyfinConnection(connection);
  final serverId = ServerId.tryParse(connection.serverMachineId);
  if (serverId != null &&
      !await _isServerReferenced(serverId, profileConnections: profileConnections, connections: connections)) {
    await storage.clearLibraryPreferencesForServerEverywhere(serverId);
  }
}

Future<void> _clearProfileServerPrefsNoLongerReferenced({
  required String profileId,
  required Set<ServerId> removedServerIds,
  required ProfileConnectionRegistry profileConnections,
  required ConnectionRegistry connections,
  required StorageService storage,
  required bool clearEverywhereWhenUnreferenced,
}) async {
  if (removedServerIds.isEmpty) return;
  final remainingProfileServerIds = await _serverIdsForProfile(
    profileId,
    profileConnections: profileConnections,
    connections: connections,
  );
  final activeProfileId = storage.getActiveProfileId();

  for (final serverId in removedServerIds) {
    if (remainingProfileServerIds.contains(serverId)) continue;
    final serverStillReferenced = await _isServerReferenced(
      serverId,
      profileConnections: profileConnections,
      connections: connections,
    );
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

Future<Set<ServerId>> _serverIdsForProfile(
  String profileId, {
  required ProfileConnectionRegistry profileConnections,
  required ConnectionRegistry connections,
}) async {
  final rows = await profileConnections.listForProfile(profileId);
  if (rows.isEmpty) return const {};

  final all = await connections.list();
  final byId = {for (final connection in all) connection.id: connection};
  return {
    for (final row in rows)
      if (byId[row.connectionId] case final connection?) ..._serverIdsForConnection(connection),
  };
}

Future<bool> _isServerReferenced(
  ServerId serverId, {
  required ProfileConnectionRegistry profileConnections,
  required ConnectionRegistry connections,
}) async {
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

Set<ServerId> _serverIdsForConnection(Connection connection) {
  return switch (connection) {
    PlexAccountConnection(:final servers) => {
      for (final server in servers) ?ServerId.tryParse(server.clientIdentifier),
    },
    JellyfinConnection(:final serverMachineId) => {?ServerId.tryParse(serverMachineId)},
  };
}

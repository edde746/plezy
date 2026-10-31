import '../connection/connection.dart';
import '../models/jellyfin/bonfire_profile.dart';
import '../models/plex/plex_home_user.dart';
import '../services/storage_service.dart';
import 'profile.dart';
import 'profile_connection.dart';
import 'server_connection_lookup.dart';

/// Groups profile-connection rows by profile id, preserving input order.
Map<String, List<ProfileConnection>> groupConnectionsByProfile(List<ProfileConnection> pcs) {
  final out = <String, List<ProfileConnection>>{};
  for (final pc in pcs) {
    out.putIfAbsent(pc.profileId, () => []).add(pc);
  }
  return out;
}

/// Join-table rows that should be shown as explicit, user-manageable
/// connections for [profile].
///
/// Plex Home and Jellyfin Bonfire profiles own their parent connection
/// implicitly through [Profile.parentConnectionId]. A parent
/// [ProfileConnection] row may still exist as a token cache, but UI should
/// not render it as a removable borrowed connection.
List<ProfileConnection> visibleProfileConnections(Profile profile, List<ProfileConnection> pcs) {
  final parentId = profile.parentConnectionId;
  if ((!profile.isPlexHome && !profile.isJellyfinBonfire) || parentId == null) return pcs;
  return pcs.where((pc) => pc.connectionId != parentId).toList();
}

/// Merge local profiles with virtual Plex Home and Bonfire profiles. Each
/// Plex Home user becomes a virtual profile attached to its `connectionId`,
/// each Bonfire `/list` entry a virtual profile attached to its Jellyfin
/// connection. Profiles whose connection isn't registered are dropped — they
/// can't be activated until the parent account is re-added.
List<Profile> mergeLocalWithPlexHome({
  required List<Profile> locals,
  required Map<String, List<PlexHomeUser>> plexHomeByConnectionId,
  required Map<String, Connection> connectionsById,
  Map<String, List<BonfireProfile>> bonfireByConnectionId = const {},
  Map<String, List<ProfileConnection>> localConnectionsByProfile = const {},
  StorageService? storage,
}) {
  final out = <Profile>[for (final local in locals) _withLatestStoredLastUsed(local, storage)];
  final bonfireMasterConnectionIds = <String>{};
  for (final entry in plexHomeByConnectionId.entries) {
    final connectionId = entry.key;
    if (!connectionsById.containsKey(connectionId)) continue;
    for (final user in entry.value) {
      out.add(
        Profile.virtualPlexHome(
          connectionId: connectionId,
          homeUser: user,
          lastUsedAt: storage?.getProfileLastUsed(
            plexHomeProfileId(accountConnectionId: connectionId, homeUserUuid: user.uuid),
          ),
        ),
      );
    }
  }
  for (final entry in bonfireByConnectionId.entries) {
    final connectionId = entry.key;
    // Bonfire profiles bind through the parent connection's master token, so
    // a non-Jellyfin (or unregistered) connection id can't host them. Keys
    // are machine ids; the host row is usually the compound sign-in
    // connection on that machine.
    final conn = jellyfinConnectionForServerId(connectionsById, connectionId);
    if (conn == null) continue;
    if (entry.value.any((p) => p.isMaster)) bonfireMasterConnectionIds.add(connectionId);
    for (final profile in entry.value) {
      out.add(
        Profile.virtualJellyfinBonfire(
          connectionId: connectionId,
          profile: profile,
          serverBaseUrl: conn.baseUrl,
          lastUsedAt: storage?.getProfileLastUsed(
            bonfireProfileId(connectionId: connectionId, bonfireUserId: profile.profileUserId),
          ),
        ),
      );
    }
  }
  // The master Bonfire row IS the parent account: a local profile whose only
  // connection is that parent would render as a duplicate row without
  // Bonfire's PIN semantics (two "dalgibbard" entries, one padlocked).
  // Locals that also borrow other connections stay visible.
  if (bonfireMasterConnectionIds.isNotEmpty) {
    out.removeWhere((p) {
      if (p is! LocalProfile) return false;
      final rows = localConnectionsByProfile[p.id];
      if (rows != null && rows.length == 1) {
        // The set carries machine ids; join rows carry the parent connection's
        // persisted row id (compound machineId/userId on fresh installs).
        // Match either shape.
        final rowConnection = connectionsById[rows.single.connectionId];
        final rowConnId = rows.single.connectionId;
        final rowMachineId =
            rowConnection is JellyfinConnection ? rowConnection.serverMachineId : rowConnId;
        return bonfireMasterConnectionIds.contains(rowConnId) ||
            bonfireMasterConnectionIds.contains(rowMachineId);
      }
      // A freshly created account row with no join rows yet still duplicates
      // the Bonfire master row when it names the same Jellyfin user.
      if (rows == null || rows.isEmpty) {
        final name = p.displayName.trim().toLowerCase();
        for (final id in bonfireMasterConnectionIds) {
          if (jellyfinConnectionForServerId(connectionsById, id) case final JellyfinConnection conn) {
            if (conn.userName.trim().toLowerCase() == name) return true;
          }
        }
      }
      return false;
    });
  }
  return sortProfilesByLastUsed(out);
}

List<Profile> sortProfilesByLastUsed(List<Profile> profiles) {
  final indexed = profiles.indexed.toList();
  indexed.sort((a, b) {
    final aLastUsed = a.$2.lastUsedAt;
    final bLastUsed = b.$2.lastUsedAt;
    if (aLastUsed == null && bLastUsed == null) return a.$1.compareTo(b.$1);
    if (aLastUsed == null) return 1;
    if (bLastUsed == null) return -1;
    final byLastUsed = bLastUsed.compareTo(aLastUsed);
    if (byLastUsed != 0) return byLastUsed;
    return a.$1.compareTo(b.$1);
  });
  return [for (final entry in indexed) entry.$2];
}

Profile _withLatestStoredLastUsed(Profile profile, StorageService? storage) {
  final storedLastUsed = storage?.getProfileLastUsed(profile.id);
  final currentLastUsed = profile.lastUsedAt;
  final lastUsedAt = switch ((currentLastUsed, storedLastUsed)) {
    (null, final stored?) => stored,
    (final current?, null) => current,
    (final current?, final stored?) => stored.isAfter(current) ? stored : current,
    _ => null,
  };
  if (lastUsedAt == currentLastUsed) return profile;
  return profile.copyWith(lastUsedAt: lastUsedAt);
}

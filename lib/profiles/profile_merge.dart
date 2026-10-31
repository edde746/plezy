import '../connection/connection.dart';
import '../models/jellyfin/bonfire_profile.dart';
import '../models/plex/plex_home_user.dart';
import '../services/storage_service.dart';
import 'profile.dart';
import 'profile_connection.dart';

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
  StorageService? storage,
}) {
  final out = <Profile>[for (final local in locals) _withLatestStoredLastUsed(local, storage)];
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
    // a non-Jellyfin (or unregistered) connection id can't host them.
    final conn = connectionsById[connectionId];
    if (conn is! JellyfinConnection) continue;
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

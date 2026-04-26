import '../connection/connection.dart';
import '../models/plex/plex_home_user.dart';
import '../services/storage_service.dart';
import 'profile.dart';

/// Merge local profiles with virtual Plex Home profiles. Each Plex Home
/// user becomes a virtual profile attached to its `connectionId`. Home
/// users whose connection isn't registered are dropped — their profile
/// can't be activated until the parent account is re-added.
List<Profile> mergeLocalWithPlexHome({
  required List<Profile> locals,
  required Map<String, List<PlexHomeUser>> plexHomeByConnectionId,
  required Map<String, Connection> connectionsById,
  StorageService? storage,
}) {
  final out = <Profile>[...locals];
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
  return out;
}

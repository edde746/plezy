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

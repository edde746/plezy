import '../connection/connection.dart';
import '../models/plex/plex_home_user.dart';
import '../services/jellyfin_mappers.dart';
import 'profile.dart';
import 'profile_connection.dart';

/// Picture URL per profile id, `null` meaning "render initials".
///
/// A [PlexHomeProfile] owns its picture: Plex serves a per-home-user avatar
/// and [Profile.virtualPlexHome] already carries it, so those pass through
/// untouched.
///
/// A [LocalProfile] has no picture of its own. It shows the user picture of
/// the connection it was linked to **first** — the oldest by
/// [Connection.createdAt], ties broken by connection id so the choice is
/// stable. If that connection has no picture the profile falls back to
/// initials; we deliberately do *not* skip ahead to a later connection, so the
/// avatar stays a property of "the first connection" rather than of whichever
/// backend happens to have an image today.
///
/// The join row is not a usable ordering key: `profile_connections` has no
/// creation timestamp, and `tokenAcquiredAt` is rewritten every time the
/// binder re-mints a Plex Home token.
Map<String, String?> resolveProfileAvatarUrls({
  required List<Profile> profiles,
  required Map<String, List<ProfileConnection>> connectionsByProfile,
  required Map<String, Connection> connectionsById,
  required Map<String, List<PlexHomeUser>> plexHomeByConnectionId,
}) {
  return {
    for (final profile in profiles)
      profile.id: _avatarForProfile(
        profile: profile,
        links: connectionsByProfile[profile.id] ?? const [],
        connectionsById: connectionsById,
        plexHomeByConnectionId: plexHomeByConnectionId,
      ),
  };
}

String? _avatarForProfile({
  required Profile profile,
  required List<ProfileConnection> links,
  required Map<String, Connection> connectionsById,
  required Map<String, List<PlexHomeUser>> plexHomeByConnectionId,
}) {
  final own = profile.avatarThumbUrl;
  if (own != null && own.isNotEmpty) return own;
  // A Plex Home user with no avatar set keeps its initials. Plex owns that
  // profile's identity end to end, so it must never borrow the picture of a
  // connection it happens to have been lent.
  if (profile.isPlexHome) return null;

  ProfileConnection? firstLink;
  Connection? first;
  for (final link in links) {
    // A link whose connection was removed can't contribute a picture, and it
    // must not win the ordering either.
    final connection = connectionsById[link.connectionId];
    if (connection == null) continue;
    if (first == null || _isEarlier(connection, first)) {
      first = connection;
      firstLink = link;
    }
  }
  if (first == null || firstLink == null) return null;

  return connectionAvatarUrl(connection: first, link: firstLink, plexHomeByConnectionId: plexHomeByConnectionId);
}

bool _isEarlier(Connection candidate, Connection incumbent) {
  final byCreatedAt = candidate.createdAt.compareTo(incumbent.createdAt);
  if (byCreatedAt != 0) return byCreatedAt < 0;
  return candidate.id.compareTo(incumbent.id) < 0;
}

/// Picture a single connection contributes to [link]'s profile, or `null`.
///
/// Plex resolves through the join row rather than the account owner: a profile
/// borrows a *specific* Home user (`userIdentifier`), and that user's live
/// [PlexHomeUser.thumb] is the picture Plex shows for it. Reading the live
/// cache also means the avatar tracks Plex's hourly refresh for free.
///
/// Jellyfin and Emby use the same `/Users/{uid}/Images/Primary` route, so the
/// shared [JellyfinConnection] arm is dialect-agnostic.
String? connectionAvatarUrl({
  required Connection connection,
  required ProfileConnection link,
  required Map<String, List<PlexHomeUser>> plexHomeByConnectionId,
}) {
  return switch (connection) {
    JellyfinConnection(:final baseUrl, :final userId, :final primaryImageTag) => jellyfinUserImageUrl(
      baseUrl: baseUrl,
      userId: userId,
      tag: primaryImageTag,
    ),
    PlexAccountConnection() => _plexHomeUserThumb(plexHomeByConnectionId[connection.id], link.userIdentifier),
    PlexDirectConnection() => null,
  };
}

String? _plexHomeUserThumb(List<PlexHomeUser>? homeUsers, String homeUserUuid) {
  if (homeUsers == null || homeUserUuid.isEmpty) return null;
  for (final user in homeUsers) {
    if (user.uuid != homeUserUuid) continue;
    return user.thumb.isEmpty ? null : user.thumb;
  }
  return null;
}

import 'connection.dart';

/// Backend-neutral auth service interface. Each backend's implementation
/// (`PlexConnectionAuthService`, `JellyfinConnectionAuthService`) drives its
/// own UX (PIN flow vs. password) but produces the same opaque
/// [Connection] record at the end.
abstract class ConnectionAuthService {
  /// Best-effort check that an existing token still works. Returns false on
  /// 401/403; throws on transport failures the caller should retry.
  Future<bool> validate(Connection connection);

  /// Refresh whatever side-channel state belongs to a connection — for Plex
  /// that's the discovered server list and Home users; for Jellyfin it's a
  /// no-op once auth has succeeded. Returns the updated connection.
  Future<Connection> refresh(Connection connection);

  /// Revoke the token server-side and forget local credentials. The caller
  /// is responsible for removing the row from [ConnectionRegistry].
  Future<void> signOut(Connection connection);
}

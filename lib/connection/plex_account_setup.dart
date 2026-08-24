import '../profiles/plex_home_service.dart';
import '../profiles/profile_connection_registry.dart';
import '../services/plex_auth_service.dart';
import '../services/storage_service.dart';
import '../utils/app_logger.dart';
import 'connection.dart';
import 'connection_registry.dart';

/// Outcome of [registerPlexAccountFromToken]. [homeUsersFetched] is false
/// when the `/home/users` fetch failed — first-sign-in flows can't build
/// any profile without it and must not conflate that with "no users".
/// [existedBefore] tells add-flows whether a cancelled attach should
/// remove the account again (it was created solely for the attach).
typedef PlexAccountRegistration = ({
  PlexAccountConnection connection,
  bool homeUsersFetched,
  bool existedBefore,
  String username,
  String email,
});

/// Result of [buildPlexAccountConnection]: the assembled connection plus the
/// raw identity fields callers fold into their own records and dedup scans.
typedef PlexAccountBuild = ({PlexAccountConnection connection, String username, String email, String accountUuid});

/// Shared token → [PlexAccountConnection] pipeline: resolve the plex.tv
/// account identity, list the account's servers, and assemble a connection
/// row stamped "now". [registerPlexAccountFromToken] and both
/// [ConnectionBootstrap] entry points (the PLEX_TOKEN dev seed and the
/// legacy-token migration) funnel through here so the id/label policy can't
/// drift. Each caller keeps its delta via the knobs:
///
/// - [clientIdentifier] is persisted on the row and keys it when the account
///   uuid is unavailable. `null` uses the short-lived [PlexAuthService]'s own
///   per-device id (the same [StorageService]-backed value).
/// - [fetchUserInfo]/[fetchServers] override the identity/server sources —
///   the legacy migration injects a test seam and the cached legacy server
///   list. When both are given (and [clientIdentifier] is set) no
///   [PlexAuthService] is created at all.
/// - [keyByAccountUuid]: the dev seed keys its row by client id even when
///   the account uuid is known.
/// - [tolerateUserInfoFailure]: sign-in and migration fall back to a
///   client-id-keyed row when the identity lookup fails; the dev seed aborts
///   instead of seeding a mislabelled row.
Future<PlexAccountBuild> buildPlexAccountConnection(
  String token, {
  String? clientIdentifier,
  Future<Map<String, dynamic>> Function(String token)? fetchUserInfo,
  Future<List<PlexServer>> Function(String token)? fetchServers,
  bool keyByAccountUuid = true,
  bool tolerateUserInfoFailure = true,
}) async {
  PlexAuthService? auth;
  try {
    if (clientIdentifier == null || fetchUserInfo == null || fetchServers == null) {
      auth = await PlexAuthService.create();
    }
    // Account identity from plex.tv — the uuid is what makes multi-account
    // work (the clientIdentifier is per-device and identical for every Plex
    // account on this install). Falls back to the client identifier only
    // when the user-info call fails outright; a later successful sign-in
    // migrates that legacy row via [_migrateLegacyClientIdRow].
    String username = '';
    String email = '';
    String accountUuid = '';
    try {
      final info = await (fetchUserInfo ?? auth!.getUserInfo)(token);
      username = (info['username'] as String?) ?? '';
      email = (info['email'] as String?) ?? '';
      accountUuid = (info['uuid'] as String?)?.trim() ?? '';
    } catch (e) {
      if (!tolerateUserInfoFailure) rethrow;
      appLogger.d('Plex user-info lookup failed (using fallback identity): $e');
    }

    final servers = await (fetchServers ?? auth!.fetchServers)(token);
    final clientId = clientIdentifier ?? auth!.clientIdentifier;
    final connection = PlexAccountConnection(
      id: 'plex.${keyByAccountUuid && accountUuid.isNotEmpty ? accountUuid : clientId}',
      accountToken: token,
      clientIdentifier: clientId,
      accountLabel: username.isNotEmpty ? username : (email.isNotEmpty ? email : 'Plex'),
      servers: servers,
      createdAt: DateTime.now(),
      lastAuthenticatedAt: DateTime.now(),
    );
    return (connection: connection, username: username, email: email, accountUuid: accountUuid);
  } finally {
    auth?.dispose();
  }
}

/// Shared post-auth pipeline for a fresh plex.tv [token]: resolve the
/// account identity, persist the [PlexAccountConnection] (folding in a
/// legacy client-id-keyed row from an earlier failed identity lookup), and
/// refresh its Plex Home users. Used by the first-sign-in AuthScreen and
/// the add-account settings flow so identity/dedup policy can't drift.
Future<PlexAccountRegistration> registerPlexAccountFromToken({
  required String token,
  required ConnectionRegistry connections,
  required ProfileConnectionRegistry profileConnections,
  required StorageService storage,
  required PlexHomeService plexHome,
}) async {
  final build = await buildPlexAccountConnection(token);
  final connection = build.connection;
  final legacyId = 'plex.${connection.clientIdentifier}';
  final existedBefore =
      await connections.get(connection.id) != null ||
      (build.accountUuid.isNotEmpty &&
          legacyId != connection.id &&
          await connections.get(legacyId) is PlexAccountConnection);
  await connections.upsert(connection);

  if (build.accountUuid.isNotEmpty) {
    await _migrateLegacyClientIdRow(
      replacement: connection,
      clientIdentifier: connection.clientIdentifier,
      connections: connections,
      profileConnections: profileConnections,
      storage: storage,
    );
  }

  // Fetch home users now so pickers surface the account's virtual
  // profiles immediately.
  final homeUsersFetched = await plexHome.refresh(connection);
  return (
    connection: connection,
    homeUsersFetched: homeUsersFetched,
    existedBefore: existedBefore,
    username: build.username,
    email: build.email,
  );
}

/// A row keyed by the per-device client identifier (created when an earlier
/// sign-in couldn't resolve the account uuid) would duplicate the account —
/// and collides with every other account on this device. Fold it into the
/// uuid-keyed [replacement]: re-point its join rows, then remove it.
///
/// Virtual profile ids that embedded the legacy account id are not
/// rewritten; their (rare) borrowed rows become orphans that the startup
/// prune and post-removal settle already clean up.
Future<void> _migrateLegacyClientIdRow({
  required PlexAccountConnection replacement,
  required String clientIdentifier,
  required ConnectionRegistry connections,
  required ProfileConnectionRegistry profileConnections,
  required StorageService storage,
}) async {
  final legacyId = 'plex.$clientIdentifier';
  if (legacyId == replacement.id) return;
  final legacy = await connections.get(legacyId);
  if (legacy is! PlexAccountConnection) return;

  final rows = await profileConnections.listForConnection(legacyId);
  for (final row in rows) {
    await profileConnections.upsert(row.copyWith(connectionId: replacement.id));
  }
  await storage.clearPlexHomeUsersCache(legacyId);
  // The FK cascade drops the legacy rows we just re-pointed copies of.
  await connections.remove(legacyId);
  appLogger.i('Migrated legacy Plex account row $legacyId → ${replacement.id}');
}

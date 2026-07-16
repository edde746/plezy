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
  final auth = await PlexAuthService.create();
  try {
    // Account identity from plex.tv — the uuid is what makes multi-account
    // work (the clientIdentifier is per-device and identical for every Plex
    // account on this install). Falls back to the client identifier only
    // when the user-info call fails outright; a later successful sign-in
    // migrates that legacy row below.
    String username = '';
    String email = '';
    String accountUuid = '';
    try {
      final info = await auth.getUserInfo(token);
      username = (info['username'] as String?) ?? '';
      email = (info['email'] as String?) ?? '';
      accountUuid = (info['uuid'] as String?)?.trim() ?? '';
    } catch (e) {
      appLogger.d('getUserInfo after Plex sign-in failed (using fallback identity): $e');
    }

    final servers = await auth.fetchServers(token);
    final connection = PlexAccountConnection(
      id: 'plex.${accountUuid.isNotEmpty ? accountUuid : auth.clientIdentifier}',
      accountToken: token,
      clientIdentifier: auth.clientIdentifier,
      accountLabel: username.isNotEmpty ? username : (email.isNotEmpty ? email : 'Plex'),
      servers: servers,
      createdAt: DateTime.now(),
      lastAuthenticatedAt: DateTime.now(),
    );
    final legacyId = 'plex.${auth.clientIdentifier}';
    final existedBefore =
        await connections.get(connection.id) != null ||
        (accountUuid.isNotEmpty &&
            legacyId != connection.id &&
            await connections.get(legacyId) is PlexAccountConnection);
    await connections.upsert(connection);

    if (accountUuid.isNotEmpty) {
      await _migrateLegacyClientIdRow(
        replacement: connection,
        clientIdentifier: auth.clientIdentifier,
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
      username: username,
      email: email,
    );
  } finally {
    auth.dispose();
  }
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

import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../models/plex/plex_home.dart';
import '../models/plex/plex_home_user.dart';
import '../profiles/profile.dart';
import '../profiles/profile_registry.dart';
import '../services/plex_auth_service.dart';
import '../services/server_registry.dart';
import '../services/storage_service.dart';
import '../utils/app_logger.dart';
import 'connection.dart';
import 'connection_registry.dart';

/// One-shot helpers that bridge between the legacy single-Plex-account
/// SharedPreferences state (`StorageService.plexToken` +
/// `currentUserUUID` + `homeUsersCache` + `ServerRegistry.getServers()`)
/// and the new [ConnectionRegistry] world.
///
/// Plex Home users are NOT persisted here — the bootstrap copies the
/// legacy `homeUsersCache` into the per-connection
/// `plex_home_users_{connectionId}` SharedPreferences slot so
/// [PlexHomeService] picks it up on cold start.
class ConnectionBootstrap {
  ConnectionBootstrap({
    required this.storage,
    required this.connectionRegistry,
    required this.serverRegistry,
    required this.profileRegistry,
    Future<List<PlexHomeUser>> Function(String accountToken)? plexHomeUserFetcher,
    Future<Map<String, dynamic>> Function(String accountToken)? plexUserInfoFetcher,
  }) : _plexHomeUserFetcher = plexHomeUserFetcher ?? _fetchPlexHomeUsers,
       _plexUserInfoFetcher = plexUserInfoFetcher ?? _fetchPlexUserInfo;

  final StorageService storage;
  final ConnectionRegistry connectionRegistry;
  final ServerRegistry serverRegistry;
  final ProfileRegistry profileRegistry;
  final Future<List<PlexHomeUser>> Function(String accountToken) _plexHomeUserFetcher;
  final Future<Map<String, dynamic>> Function(String accountToken) _plexUserInfoFetcher;

  static const String _keyProfileMigrationV1Done = 'profile_migration_v1_done';
  static const String _ownerProfileIdPrefix = 'local-';

  /// Run all idempotent boot-time migrations. Best-effort — errors are
  /// logged but never thrown.
  Future<void> run() async {
    await seedFromDevTokenDefine();
    final hadLegacyPlexToken = (storage.getPlexToken() ?? '').isNotEmpty;
    final hadLegacyProfileState = _hasLegacyProfileState();
    final migratedAccount = await migrateLegacyPlexAccount();
    final account = await _firstPlexAccount(migratedAccount);
    final alreadyMigrated = storage.prefs.getBool(_keyProfileMigrationV1Done) ?? false;
    if (!alreadyMigrated) {
      if (account == null && (hadLegacyPlexToken || hadLegacyProfileState)) {
        appLogger.w('Migration: legacy profile state present but Plex account was not migrated; will retry later');
        return;
      }
      // Drop any plex_home rows left over from the pre-refactor data
      // model — Plex Home users are now fetched live, never persisted.
      await profileRegistry.dropAllPlexHomeRows();
      if (account != null) {
        final prepared = await _preparePlexVirtualProfile(account);
        if (!prepared) {
          if (migratedAccount != null && hadLegacyPlexToken) {
            await connectionRegistry.remove(migratedAccount.id);
          }
          appLogger.w('Migration: could not hydrate Plex Home profiles for ${account.id}; will retry later');
          return;
        }
      }
      await _ensureOwnerProfile();
      if (hadLegacyPlexToken) {
        await storage.clearLegacyPlexToken();
      }
      await storage.clearServersList();
      await storage.prefs.setBool(_keyProfileMigrationV1Done, true);
    } else {
      await storage.clearServersList();
      await _recoverLegacyProfilePromotionIfNeeded(account);
      await _migrateLegacyPlexHomeUsersCacheForExistingAccount(account);
    }
  }

  bool _hasLegacyProfileState() {
    return (storage.getCurrentUserUUID() ?? '').isNotEmpty ||
        (storage.prefs.getString('home_users_cache') ?? '').isNotEmpty;
  }

  /// Screenshot automation injects a Plex token via the `PLEX_TOKEN`
  /// dart-define so the app boots already-signed-in. Inserts a
  /// [PlexAccountConnection] directly when the env var is non-empty AND
  /// the registry doesn't already have a Plex account, fetching the user
  /// info + servers like the auth screen does. No-op in normal builds.
  Future<void> seedFromDevTokenDefine() async {
    const devToken = String.fromEnvironment('PLEX_TOKEN');
    if (devToken.isEmpty) return;
    final existing = await connectionRegistry.list();
    if (existing.whereType<PlexAccountConnection>().isNotEmpty) return;

    try {
      final auth = await PlexAuthService.create();
      try {
        final info = await auth.getUserInfo(devToken);
        final servers = await auth.fetchServers(devToken);
        final clientId = await storage.getOrCreateClientIdentifier();
        final conn = PlexAccountConnection(
          id: 'plex.$clientId',
          accountToken: devToken,
          clientIdentifier: clientId,
          accountLabel: (info['username'] as String?) ?? (info['email'] as String?) ?? 'Plex',
          servers: servers,
          createdAt: DateTime.now(),
          lastAuthenticatedAt: DateTime.now(),
        );
        await connectionRegistry.upsert(conn);
        appLogger.i('Seeded Plex account from PLEX_TOKEN dart-define as ${conn.id}');
      } finally {
        auth.dispose();
      }
    } catch (e, st) {
      appLogger.w('PLEX_TOKEN seed failed', error: e, stackTrace: st);
    }
  }

  /// If a legacy Plex token sits in [StorageService] without a corresponding
  /// row in [ConnectionRegistry], wrap it as a [PlexAccountConnection] and
  /// insert. Best-effort: errors are logged but never thrown.
  Future<PlexAccountConnection?> migrateLegacyPlexAccount() async {
    final token = storage.getPlexToken();
    if (token == null || token.isEmpty) return null;

    final existing = await connectionRegistry.list();
    final alreadyMigrated = existing
        .whereType<PlexAccountConnection>()
        .where((c) => c.accountToken == token)
        .firstOrNull;
    if (alreadyMigrated != null) {
      return alreadyMigrated;
    }

    try {
      final clientId = await storage.getOrCreateClientIdentifier();
      final servers = await serverRegistry.getServers();

      String accountLabel = 'Plex';
      String accountUuid = '';
      try {
        final info = await _plexUserInfoFetcher(token);
        accountLabel = (info['username'] as String?) ?? (info['email'] as String?) ?? 'Plex';
        accountUuid = (info['uuid'] as String?)?.trim() ?? '';
      } catch (e) {
        appLogger.d('Plex migration: account label lookup failed (using fallback): $e');
      }

      final conn = PlexAccountConnection(
        id: 'plex.${accountUuid.isNotEmpty ? accountUuid : clientId}',
        accountToken: token,
        clientIdentifier: clientId,
        accountLabel: accountLabel,
        servers: servers,
        createdAt: DateTime.now(),
        lastAuthenticatedAt: DateTime.now(),
      );
      await connectionRegistry.upsert(conn);
      appLogger.i('Migrated legacy Plex account into ConnectionRegistry as ${conn.id}');
      return conn;
    } catch (e, st) {
      appLogger.w('Plex account migration failed', error: e, stackTrace: st);
      return null;
    }
  }

  /// Hydrate Plex Home users for [account] and select a virtual Plex Home
  /// profile. Plex users are never persisted as local Plezy profiles.
  Future<bool> _preparePlexVirtualProfile(PlexAccountConnection account) async {
    final copied = await _migrateLegacyPlexHomeUsersCache(account.id);
    var users = copied ? _readPlexHomeUsersCache(account.id) : null;
    users ??= await _fetchAndCachePlexHomeUsers(account);
    final hydratedUsers = users;
    if (hydratedUsers.isEmpty) return false;

    final legacyActiveUuid = storage.getCurrentUserUUID();
    PlexHomeUser selected;
    if (legacyActiveUuid != null && legacyActiveUuid.isNotEmpty) {
      selected = hydratedUsers.firstWhere(
        (u) => u.uuid == legacyActiveUuid,
        orElse: () => _preferredPlexHomeUser(hydratedUsers),
      );
      if (selected.uuid != legacyActiveUuid) {
        appLogger.w('Migration: legacy Plex Home UUID $legacyActiveUuid not found; using ${selected.uuid} instead');
      }
    } else {
      selected = _preferredPlexHomeUser(hydratedUsers);
    }

    final activeProfileId = plexHomeProfileId(accountConnectionId: account.id, homeUserUuid: selected.uuid);
    await storage.setActiveProfileId(activeProfileId);
    await storage.clearCurrentUserUUID();
    await Future.wait([storage.prefs.remove('home_users_cache'), storage.prefs.remove('home_users_cache_expiry')]);
    appLogger.i('Migration: selected Plex Home profile ${selected.displayName} → $activeProfileId');
    return true;
  }

  PlexHomeUser _preferredPlexHomeUser(List<PlexHomeUser> users) {
    return users.firstWhere((u) => u.admin, orElse: () => users.first);
  }

  Future<bool> _migrateLegacyPlexHomeUsersCache(String connectionId) async {
    final raw = storage.prefs.getString('home_users_cache');
    if (raw == null || raw.isEmpty) return false;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return false;
      final home = PlexHome.fromJson(decoded);
      if (home.users.isEmpty) return false;
      await storage.savePlexHomeUsersCache(connectionId, home.users.map((u) => u.toJson()).toList());
      appLogger.i('Migration: copied ${home.users.length} Plex Home users into cache for $connectionId');
      return true;
    } catch (e, st) {
      appLogger.w('Plex Home cache migration failed', error: e, stackTrace: st);
      return false;
    }
  }

  List<PlexHomeUser>? _readPlexHomeUsersCache(String connectionId) {
    final raw = storage.getPlexHomeUsersCacheJson(connectionId);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded.whereType<Map<String, dynamic>>().map(PlexHomeUser.fromJson).toList();
    } catch (e, st) {
      appLogger.w('Migration: failed to read Plex Home cache for $connectionId', error: e, stackTrace: st);
      return null;
    }
  }

  Future<List<PlexHomeUser>> _fetchAndCachePlexHomeUsers(PlexAccountConnection account) async {
    try {
      final users = await _plexHomeUserFetcher(account.accountToken);
      if (users.isNotEmpty) {
        await storage.savePlexHomeUsersCache(account.id, users.map((u) => u.toJson()).toList());
        appLogger.i('Migration: fetched ${users.length} Plex Home users for ${account.id}');
      }
      return users;
    } catch (e, st) {
      appLogger.w('Migration: Plex Home fetch failed for ${account.id}', error: e, stackTrace: st);
      return const [];
    }
  }

  Future<void> _migrateLegacyPlexHomeUsersCacheForExistingAccount(PlexAccountConnection? account) async {
    if (storage.prefs.getString('home_users_cache') == null) return;
    var target = account;
    if (target == null) {
      final connections = await connectionRegistry.list();
      for (final conn in connections) {
        if (conn is PlexAccountConnection) {
          target = conn;
          break;
        }
      }
    }
    if (target == null) return;
    final copied = await _migrateLegacyPlexHomeUsersCache(target.id);
    if (copied) {
      await Future.wait([storage.prefs.remove('home_users_cache'), storage.prefs.remove('home_users_cache_expiry')]);
    }
  }

  /// Make sure fresh non-Plex installs always have at least one local profile.
  /// Migrated Plex accounts select a virtual Plex Home profile instead.
  Future<void> _ensureOwnerProfile() async {
    final existing = await profileRegistry.list();
    if (existing.isNotEmpty) return;
    if (storage.getActiveProfileId() != null) return;

    final owner = Profile(
      id: '$_ownerProfileIdPrefix${const Uuid().v4()}',
      kind: ProfileKind.local,
      displayName: 'Default',
      sortOrder: 0,
      createdAt: DateTime.now(),
    );
    await profileRegistry.upsert(owner);
    await storage.setActiveProfileId(owner.id);
    appLogger.i('Migration: created placeholder Default profile (no Plex account on first launch)');
  }

  Future<PlexAccountConnection?> _firstPlexAccount(PlexAccountConnection? preferred) async {
    if (preferred != null) return preferred;
    final connections = await connectionRegistry.list();
    for (final conn in connections) {
      if (conn is PlexAccountConnection) return conn;
    }
    return null;
  }

  Future<void> _recoverLegacyProfilePromotionIfNeeded(PlexAccountConnection? account) async {
    if (!_hasLegacyProfileState()) return;
    final target = await _firstPlexAccount(account);
    if (target == null) return;
    await _preparePlexVirtualProfile(target);
  }
}

Future<List<PlexHomeUser>> _fetchPlexHomeUsers(String accountToken) async {
  final auth = await PlexAuthService.create();
  try {
    final home = await auth.getHomeUsers(accountToken);
    return home.users;
  } finally {
    auth.dispose();
  }
}

Future<Map<String, dynamic>> _fetchPlexUserInfo(String accountToken) async {
  final auth = await PlexAuthService.create();
  try {
    return await auth.getUserInfo(accountToken);
  } finally {
    auth.dispose();
  }
}

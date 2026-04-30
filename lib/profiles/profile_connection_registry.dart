import 'dart:async';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../services/credential_vault.dart';
import '../utils/app_logger.dart';
import 'profile_connection.dart';

/// CRUD over the [ProfileConnections] join table.
///
/// Mirrors [ConnectionRegistry] in shape: drift is the source of truth,
/// `watch*` streams changes, and a single [setDefault] enforces the
/// "exactly one default per profile" invariant.
class ProfileConnectionRegistry {
  ProfileConnectionRegistry(this._db);

  final AppDatabase _db;

  Stream<List<ProfileConnection>> watchAll() {
    return _db.select(_db.profileConnections).watch().asyncMap((rows) async => Future.wait(rows.map(_rowToModel)));
  }

  Stream<List<ProfileConnection>> watchForProfile(String profileId) {
    return (_db.select(_db.profileConnections)
          ..where((t) => t.profileId.equals(profileId))
          ..orderBy(_orderingForProfile))
        .watch()
        .asyncMap((rows) async => Future.wait(rows.map(_rowToModel)));
  }

  Future<List<ProfileConnection>> listForProfile(String profileId) async {
    final rows =
        await (_db.select(_db.profileConnections)
              ..where((t) => t.profileId.equals(profileId))
              ..orderBy(_orderingForProfile))
            .get();
    return Future.wait(rows.map(_rowToModel));
  }

  static List<OrderingTerm Function($ProfileConnectionsTable)> get _orderingForProfile => [
    (t) => OrderingTerm.desc(t.isDefault),
    (t) => OrderingTerm.asc(t.connectionId),
  ];

  Future<List<ProfileConnection>> listForConnection(String connectionId) async {
    final rows = await (_db.select(_db.profileConnections)..where((t) => t.connectionId.equals(connectionId))).get();
    return Future.wait(rows.map(_rowToModel));
  }

  Future<List<ProfileConnection>> listAll() async {
    final rows = await _db.select(_db.profileConnections).get();
    return Future.wait(rows.map(_rowToModel));
  }

  Future<ProfileConnection?> get(String profileId, String connectionId) async {
    final row = await (_db.select(
      _db.profileConnections,
    )..where((t) => t.profileId.equals(profileId) & t.connectionId.equals(connectionId))).getSingleOrNull();
    return row == null ? null : _rowToModel(row);
  }

  /// Insert a new join row. If [makeDefault] is true, [pc.isDefault] is true,
  /// or this is the first row for [pc.profileId], the row becomes the
  /// default for that profile.
  ///
  /// Fast path: when no default-flip is requested, skips the transaction
  /// (one cheap SELECT to detect first-row, then a single insert).
  Future<void> upsert(ProfileConnection pc, {bool makeDefault = false}) async {
    final wantsDefault = makeDefault || pc.isDefault;
    if (!wantsDefault) {
      // Preserve the row's existing `isDefault` on update so token/metadata
      // refreshes don't clobber the default flag. First-row inserts inherit
      // default automatically.
      final existing = await get(pc.profileId, pc.connectionId);
      final bool isDefault;
      if (existing != null) {
        isDefault = existing.isDefault;
      } else {
        isDefault = !await _hasAnyForProfile(pc.profileId);
      }
      await _db.into(_db.profileConnections).insertOnConflictUpdate(await _companion(pc, isDefault: isDefault));
      appLogger.d('ProfileConnectionRegistry: upserted ${pc.profileId}/${pc.connectionId}');
      return;
    }
    await _db.transaction(() async {
      await (_db.update(_db.profileConnections)..where((t) => t.profileId.equals(pc.profileId))).write(
        const ProfileConnectionsCompanion(isDefault: Value(false)),
      );
      await _db.into(_db.profileConnections).insertOnConflictUpdate(await _companion(pc, isDefault: true));
    });
    appLogger.d('ProfileConnectionRegistry: upserted ${pc.profileId}/${pc.connectionId} (default)');
  }

  Future<bool> _hasAnyForProfile(String profileId) async {
    final row =
        await (_db.selectOnly(_db.profileConnections)
              ..addColumns([_db.profileConnections.connectionId])
              ..where(_db.profileConnections.profileId.equals(profileId))
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  Future<ProfileConnectionsCompanion> _companion(ProfileConnection pc, {bool? isDefault}) async {
    final protectedToken = pc.userToken == null ? '' : await CredentialVault.protect(pc.userToken!);
    return ProfileConnectionsCompanion(
      profileId: Value(pc.profileId),
      connectionId: Value(pc.connectionId),
      // Drift column is non-nullable with default `''`; map a null
      // userToken (lazy-fetch sentinel) back to the empty-string default
      // so existing rows and inserts share representation.
      userToken: Value(protectedToken),
      userIdentifier: Value(pc.userIdentifier),
      isDefault: Value(isDefault ?? pc.isDefault),
      tokenAcquiredAt: Value(pc.tokenAcquiredAt?.millisecondsSinceEpoch),
      lastUsedAt: Value(pc.lastUsedAt?.millisecondsSinceEpoch),
    );
  }

  /// Insert a new join row only if `(profileId, connectionId)` doesn't
  /// already exist. Used by [ProfileSyncService] to surface new Plex Home
  /// users without clobbering tokens cached by prior switches.
  Future<void> insertIfAbsent(ProfileConnection pc) async {
    await _db.into(_db.profileConnections).insert(await _companion(pc), mode: InsertMode.insertOrIgnore);
  }

  /// Cache the freshly-acquired user token (e.g. after a `/home/users/switch`
  /// call). Updates `tokenAcquiredAt` to now.
  Future<void> recordToken(String profileId, String connectionId, String token) async {
    await (_db.update(
      _db.profileConnections,
    )..where((t) => t.profileId.equals(profileId) & t.connectionId.equals(connectionId))).write(
      ProfileConnectionsCompanion(
        userToken: Value(await CredentialVault.protect(token)),
        tokenAcquiredAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Mark the row as recently used.
  Future<void> markUsed(String profileId, String connectionId) async {
    await (_db.update(_db.profileConnections)
          ..where((t) => t.profileId.equals(profileId) & t.connectionId.equals(connectionId)))
        .write(ProfileConnectionsCompanion(lastUsedAt: Value(DateTime.now().millisecondsSinceEpoch)));
  }

  Future<void> remove(String profileId, String connectionId) async {
    await (_db.delete(
      _db.profileConnections,
    )..where((t) => t.profileId.equals(profileId) & t.connectionId.equals(connectionId))).go();
    // If we just removed the default, promote the oldest remaining row.
    final remaining = await (_db.select(_db.profileConnections)..where((t) => t.profileId.equals(profileId))).get();
    if (remaining.isNotEmpty && !remaining.any((r) => r.isDefault)) {
      await (_db.update(_db.profileConnections)
            ..where((t) => t.profileId.equals(profileId) & t.connectionId.equals(remaining.first.connectionId)))
          .write(const ProfileConnectionsCompanion(isDefault: Value(true)));
    }
  }

  /// Make [connectionId] the default for [profileId]. Clears the flag on
  /// every other row for the same profile.
  Future<void> setDefault(String profileId, String connectionId) async {
    await _db.transaction(() async {
      await (_db.update(
        _db.profileConnections,
      )..where((t) => t.profileId.equals(profileId))).write(const ProfileConnectionsCompanion(isDefault: Value(false)));
      await (_db.update(_db.profileConnections)
            ..where((t) => t.profileId.equals(profileId) & t.connectionId.equals(connectionId)))
          .write(const ProfileConnectionsCompanion(isDefault: Value(true)));
    });
  }

  /// Remove every join row referencing [connectionId] (e.g. when a Connection
  /// is deleted). Drift's referential integrity isn't enabled by default for
  /// SQLite without `PRAGMA foreign_keys=ON`, so we cascade explicitly.
  Future<int> removeAllForConnection(String connectionId) async {
    return await (_db.delete(_db.profileConnections)..where((t) => t.connectionId.equals(connectionId))).go();
  }

  /// Wipe every join row for [profileId] (e.g. when a Plex Home profile's
  /// parent connection is removed).
  Future<int> removeAllForProfile(String profileId) async {
    return await (_db.delete(_db.profileConnections)..where((t) => t.profileId.equals(profileId))).go();
  }

  /// Wipe the entire join table. Used by sign-out so a fresh sign-in starts
  /// with no stale (profile, connection, token) rows.
  Future<void> clear() async {
    await _db.delete(_db.profileConnections).go();
  }

  Future<ProfileConnection> _rowToModel(ProfileConnectionRow row) async {
    final hasPlaintextToken = row.userToken.isNotEmpty && !CredentialVault.isProtected(row.userToken);
    final userToken = row.userToken.isEmpty ? null : await CredentialVault.reveal(row.userToken);
    if (hasPlaintextToken) {
      unawaited(recordToken(row.profileId, row.connectionId, userToken!));
    }
    return ProfileConnection(
      profileId: row.profileId,
      connectionId: row.connectionId,
      // Drift column is non-nullable with default `''`; the empty string is
      // the on-disk lazy-fetch sentinel — surface it as null in the model.
      userToken: userToken,
      userIdentifier: row.userIdentifier,
      isDefault: row.isDefault,
      tokenAcquiredAt: row.tokenAcquiredAt == null ? null : DateTime.fromMillisecondsSinceEpoch(row.tokenAcquiredAt!),
      lastUsedAt: row.lastUsedAt == null ? null : DateTime.fromMillisecondsSinceEpoch(row.lastUsedAt!),
    );
  }
}

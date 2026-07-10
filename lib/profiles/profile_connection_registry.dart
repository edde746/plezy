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

  /// Reset the stored token to the empty-string lazy-fetch sentinel (used
  /// when the vault can no longer decrypt it).
  Future<void> _clearToken(String profileId, String connectionId) async {
    await (_db.update(_db.profileConnections)
          ..where((t) => t.profileId.equals(profileId) & t.connectionId.equals(connectionId)))
        .write(const ProfileConnectionsCompanion(userToken: Value(''), tokenAcquiredAt: Value(null)));
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
    await _promoteDefaultIfMissing(profileId);
  }

  /// Re-promote a default for [profileId] when it has join rows but none is
  /// flagged default — removing the default row would otherwise leave the
  /// profile defaultless. Deterministic: picks the lowest connectionId,
  /// matching [listForProfile]'s secondary ordering.
  Future<void> _promoteDefaultIfMissing(String profileId) async {
    final rows = await (_db.select(_db.profileConnections)..where((t) => t.profileId.equals(profileId))).get();
    if (rows.isEmpty || rows.any((r) => r.isDefault)) return;
    final pick = rows.map((r) => r.connectionId).reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
    await (_db.update(_db.profileConnections)
          ..where((t) => t.profileId.equals(profileId) & t.connectionId.equals(pick)))
        .write(const ProfileConnectionsCompanion(isDefault: Value(true)));
  }

  /// Repair the "exactly one default per profile" invariant across every
  /// profile. The `connectionId` FK cascade (PRAGMA foreign_keys=ON) deletes
  /// join rows silently when a Connection is removed, so a profile can be left
  /// with surviving rows but no default flag.
  Future<void> promoteMissingDefaults() async {
    final profileIds = (await _db.select(_db.profileConnections).get()).map((r) => r.profileId).toSet();
    for (final profileId in profileIds) {
      await _promoteDefaultIfMissing(profileId);
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
  /// is deleted). The `connectionId` FK (PRAGMA foreign_keys=ON) already
  /// cascades these rows away when the Connection row itself is deleted; this
  /// stays the explicit path for callers that drop the rows first, and either
  /// way repairs any profile the removal left without a default.
  Future<int> removeAllForConnection(String connectionId) async {
    final removed = await (_db.delete(_db.profileConnections)..where((t) => t.connectionId.equals(connectionId))).go();
    await promoteMissingDefaults();
    return removed;
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
    } else if (userToken == null && row.userToken.isNotEmpty) {
      // Vault couldn't decrypt the stored token (key/ciphertext divergence).
      // Clear it to the empty-string lazy-fetch sentinel so the binder
      // re-acquires a token on next use instead of re-failing every boot.
      appLogger.w('ProfileConnectionRegistry: clearing undecryptable token for ${row.profileId}/${row.connectionId}');
      unawaited(_clearToken(row.profileId, row.connectionId));
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

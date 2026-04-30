import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../services/credential_vault.dart';
import '../utils/app_logger.dart';
import 'connection.dart';

/// CRUD over the persisted [Connections] table. The registry is the source
/// of truth for which connections the user has added; the runtime
/// `MultiServerManager` populates per-server clients from these records.
///
/// Single-connection users get a default automatically — power users with
/// multiple connections can override it via [setDefault].
class ConnectionRegistry {
  ConnectionRegistry(this._db);

  final AppDatabase _db;

  /// Emits the current set of connections after every mutation. Drift's
  /// `watch()` provides this for free.
  Stream<List<Connection>> watchConnections() {
    return (_db.select(_db.connections)..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).watch().asyncMap(
      (rows) async => (await Future.wait(rows.map(_rowToConnection))).whereType<Connection>().toList(),
    );
  }

  /// One-shot fetch of all stored connections.
  Future<List<Connection>> list() async {
    final rows = await (_db.select(_db.connections)..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();
    return (await Future.wait(rows.map(_rowToConnection))).whereType<Connection>().toList();
  }

  /// Lookup a connection by id.
  Future<Connection?> get(String id) async {
    final row = await (_db.select(_db.connections)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return _rowToConnection(row);
  }

  /// Returns the user's preferred connection — either the row marked
  /// [Connections.isDefault], or the only row if exactly one exists, or
  /// null when no connections are stored.
  Future<Connection?> getDefault() async {
    final rows = await _db.select(_db.connections).get();
    if (rows.isEmpty) return null;
    final flagged = rows.firstWhereOrNull((r) => r.isDefault);
    final picked = flagged ?? (rows.length == 1 ? rows.single : null);
    return picked == null ? null : _rowToConnection(picked);
  }

  /// Insert or replace [connection]. If this is the first stored connection
  /// it is automatically marked default; re-upserting an existing row keeps
  /// the row's current `isDefault` (so token/metadata refreshes don't clear
  /// the default flag).
  Future<void> upsert(Connection connection) async {
    final existing = await (_db.select(_db.connections)..where((t) => t.id.equals(connection.id))).getSingleOrNull();
    final bool isDefault;
    if (existing != null) {
      isDefault = existing.isDefault;
    } else {
      final any =
          await (_db.selectOnly(_db.connections)
                ..addColumns([_db.connections.id])
                ..limit(1))
              .getSingleOrNull();
      isDefault = any == null;
    }
    final protectedConfig = await CredentialVault.protectConnectionConfig(
      connection.kind.id,
      connection.toConfigJson(),
    );
    final row = ConnectionsCompanion(
      id: Value(connection.id),
      kind: Value(connection.kind.id),
      displayName: Value(connection.displayName),
      configJson: Value(jsonEncode(protectedConfig)),
      isDefault: Value(isDefault),
      createdAt: Value(connection.createdAt.millisecondsSinceEpoch),
      lastAuthenticatedAt: Value(connection.lastAuthenticatedAt?.millisecondsSinceEpoch),
    );
    await _db.into(_db.connections).insertOnConflictUpdate(row);
    appLogger.d('ConnectionRegistry: upserted ${connection.kind.id}/${connection.id}');
  }

  /// Remove a stored connection. If the removed row was the default, the
  /// oldest remaining connection (if any) becomes default.
  Future<void> remove(String id) async {
    await (_db.delete(_db.connections)..where((t) => t.id.equals(id))).go();
    final remaining = await (_db.select(_db.connections)..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();
    if (remaining.isNotEmpty && !remaining.any((r) => r.isDefault)) {
      await (_db.update(
        _db.connections,
      )..where((t) => t.id.equals(remaining.first.id))).write(const ConnectionsCompanion(isDefault: Value(true)));
    }
    appLogger.d('ConnectionRegistry: removed $id');
  }

  /// Set [id] as the default connection. Clears the flag on all others.
  Future<void> setDefault(String id) async {
    await _db.transaction(() async {
      await _db.update(_db.connections).write(const ConnectionsCompanion(isDefault: Value(false)));
      await (_db.update(
        _db.connections,
      )..where((t) => t.id.equals(id))).write(const ConnectionsCompanion(isDefault: Value(true)));
    });
  }

  /// Update only the auth-related metadata on an existing row (token,
  /// `lastAuthenticatedAt`). Used by the auth flow after a successful
  /// silent refresh without touching the rest of the config.
  Future<void> recordAuthSuccess(String id, DateTime at) async {
    await (_db.update(_db.connections)..where((t) => t.id.equals(id))).write(
      ConnectionsCompanion(lastAuthenticatedAt: Value(at.millisecondsSinceEpoch)),
    );
  }

  Future<void> clear() async {
    await _db.delete(_db.connections).go();
  }

  /// All Plex accounts in insertion order. Convenience over
  /// `(await list()).whereType<PlexAccountConnection>()` — cuts ~3 lines from
  /// every caller that needs to filter by backend.
  Future<List<PlexAccountConnection>> listPlexAccounts() async {
    final all = await list();
    return all.whereType<PlexAccountConnection>().toList();
  }

  /// All Jellyfin connections in insertion order. Symmetric helper to
  /// [listPlexAccounts].
  Future<List<JellyfinConnection>> listJellyfin() async {
    final all = await list();
    return all.whereType<JellyfinConnection>().toList();
  }

  /// Lookup a [PlexAccountConnection] by id. Returns `null` if no row
  /// matches OR the row exists but isn't a Plex account.
  Future<PlexAccountConnection?> getPlexAccount(String id) async {
    final c = await get(id);
    return c is PlexAccountConnection ? c : null;
  }

  /// Lookup a [JellyfinConnection] by id. Returns `null` if no row matches
  /// OR the row exists but isn't a Jellyfin connection.
  Future<JellyfinConnection?> getJellyfin(String id) async {
    final c = await get(id);
    return c is JellyfinConnection ? c : null;
  }

  Future<Connection?> _rowToConnection(ConnectionRow row) async {
    try {
      final json = jsonDecode(row.configJson) as Map<String, dynamic>;
      final kind = ConnectionKind.fromId(row.kind);
      final revealed = await CredentialVault.revealConnectionConfig(kind.id, json);
      final createdAt = DateTime.fromMillisecondsSinceEpoch(row.createdAt);
      final lastAuth = row.lastAuthenticatedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.lastAuthenticatedAt!);
      final connection = switch (kind) {
        ConnectionKind.plex => PlexAccountConnection.fromConfigJson(
          id: row.id,
          json: revealed.config,
          status: ConnectionStatus.unknown,
          createdAt: createdAt,
          lastAuthenticatedAt: lastAuth,
        ),
        ConnectionKind.jellyfin => JellyfinConnection.fromConfigJson(
          id: row.id,
          json: revealed.config,
          status: ConnectionStatus.unknown,
          createdAt: createdAt,
          lastAuthenticatedAt: lastAuth,
        ),
      };
      if (revealed.migrated) {
        await upsert(connection);
      }
      return connection;
    } catch (e, st) {
      appLogger.e('ConnectionRegistry: failed to decode connection ${row.id}', error: e, stackTrace: st);
      return null;
    }
  }
}

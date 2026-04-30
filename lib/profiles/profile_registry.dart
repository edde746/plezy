import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../utils/app_logger.dart';
import 'profile.dart';

/// CRUD over the persisted [Profiles] table — local profiles only.
///
/// Plex Home users are NOT stored here; Plex owns those, and
/// [PlexHomeService] fetches them live and caches them in
/// [StorageService] for cold-start UX. UI surfaces should subscribe to
/// both this registry and [PlexHomeService] (typically via [ProfilesView]
/// or [ActiveProfileProvider]) to render the merged picker list.
class ProfileRegistry {
  ProfileRegistry(this._db);

  final AppDatabase _db;

  Stream<List<Profile>> watchProfiles() {
    return (_db.select(_db.profiles)
          ..where((t) => t.kind.equals(ProfileKind.local.id))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(_rowToProfile).whereType<Profile>().toList());
  }

  Future<List<Profile>> list() async {
    final rows =
        await (_db.select(_db.profiles)
              ..where((t) => t.kind.equals(ProfileKind.local.id))
              ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    return rows.map(_rowToProfile).whereType<Profile>().toList();
  }

  Future<Profile?> get(String id) async {
    final row = await (_db.select(_db.profiles)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _rowToProfile(row);
  }

  Future<void> upsert(Profile profile) async {
    final row = ProfilesCompanion(
      id: Value(profile.id),
      kind: Value(profile.kind.id),
      displayName: Value(profile.displayName),
      avatarThumbUrl: Value(profile.avatarThumbUrl),
      configJson: Value(jsonEncode(profile.toConfigJson())),
      sortOrder: Value(profile.sortOrder),
      createdAt: Value(profile.createdAt.millisecondsSinceEpoch),
      lastUsedAt: Value(profile.lastUsedAt?.millisecondsSinceEpoch),
    );
    await _db.into(_db.profiles).insertOnConflictUpdate(row);
    appLogger.d('ProfileRegistry: upserted ${profile.kind.id}/${profile.id}');
  }

  Future<void> remove(String id) async {
    await (_db.delete(_db.profiles)..where((t) => t.id.equals(id))).go();
    appLogger.d('ProfileRegistry: removed $id');
  }

  Future<void> markUsed(String id, DateTime at) async {
    await (_db.update(
      _db.profiles,
    )..where((t) => t.id.equals(id))).write(ProfilesCompanion(lastUsedAt: Value(at.millisecondsSinceEpoch)));
  }

  /// One-shot cleanup: drop any `kind='plex_home'` rows left over from the
  /// pre-refactor data model. Plex Home users are no longer persisted.
  Future<int> dropAllPlexHomeRows() async {
    return (_db.delete(_db.profiles)..where((t) => t.kind.equals(ProfileKind.plexHome.id))).go();
  }

  Future<void> reorder(List<String> idsInOrder) async {
    await _db.transaction(() async {
      for (var i = 0; i < idsInOrder.length; i++) {
        await (_db.update(
          _db.profiles,
        )..where((t) => t.id.equals(idsInOrder[i]))).write(ProfilesCompanion(sortOrder: Value(i)));
      }
    });
  }

  Future<void> clear() async {
    await _db.delete(_db.profiles).go();
  }

  Profile? _rowToProfile(ProfileRow row) {
    try {
      final json = jsonDecode(row.configJson) as Map<String, dynamic>;
      return Profile.fromRow(
        id: row.id,
        kind: row.kind,
        displayName: row.displayName,
        avatarThumbUrl: row.avatarThumbUrl,
        json: json,
        sortOrder: row.sortOrder,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
        lastUsedAt: row.lastUsedAt == null ? null : DateTime.fromMillisecondsSinceEpoch(row.lastUsedAt!),
      );
    } catch (e, st) {
      appLogger.e('ProfileRegistry: failed to decode profile ${row.id}', error: e, stackTrace: st);
      return null;
    }
  }
}

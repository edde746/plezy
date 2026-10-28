import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';

import '../../profiles/profile.dart';
import '../../sources/source_database.dart';
import '../base_shared_preferences_service.dart';
import '../credential_vault.dart';
import 'remote_stream_models.dart';

enum RemoteStreamStoreFailure { unreadable, claimLost }

class RemotePreparationClaim {
  RemotePreparationClaim(this.profile, this.job, this.owner);
  final String profile, job, owner;
  bool active = true;
}

class RemoteStreamStoreException implements Exception {
  const RemoteStreamStoreException(this.reason);
  final RemoteStreamStoreFailure reason;
}

/// Transactional encrypted state shared by UI and headless worker engines.
class RemoteStreamStore {
  static Future<SourceDatabase>? _opening;
  @visibleForTesting
  static void useDatabaseForTesting(SourceDatabase? database) {
    _opening = database == null ? null : Future.value(database);
  }

  static Future<SourceDatabase> get _database => _opening ??= SourceDatabase.open();
  static Future<RemoteStreamSnapshot> _decode(String raw) async {
    final clear = await CredentialVault.reveal(raw);
    if (clear == null) throw const RemoteStreamStoreException(RemoteStreamStoreFailure.unreadable);
    try {
      return RemoteStreamSnapshot.decode(clear);
    } on Object {
      throw const RemoteStreamStoreException(RemoteStreamStoreFailure.unreadable);
    }
  }

  static Future<RemoteStreamSnapshot> load(String profile) async {
    final db = await _database;
    final row = await db
        .customSelect('SELECT payload FROM remote_stream_state WHERE profile=?', variables: [Variable(profile)])
        .getSingleOrNull();
    if (row != null) return _decode(row.read<String>('payload'));
    return update(profile, (snapshot) => snapshot);
  }

  static Future<void> save(String profile, RemoteStreamSnapshot snapshot) async {
    await update(profile, (_) => snapshot);
  }

  static Future<RemoteStreamSnapshot> update(
    String profile,
    RemoteStreamSnapshot Function(RemoteStreamSnapshot) change, {
    RemotePreparationClaim? claim,
  }) async {
    final db = await _database;
    final prefs = await BaseSharedPreferencesService.sharedCache();
    final legacy = prefs.getString(profileScopedPrefsKey(profile, 'remote_streaming_v1'));
    final seed = legacy ?? await CredentialVault.protect(const RemoteStreamSnapshot().encode());
    final next = await db.transaction(() async {
      // Take the writer lock before reading, including on existing rows.
      await db.customStatement('INSERT OR IGNORE INTO remote_stream_state VALUES (?,?)', [profile, seed]);
      await db.customStatement('UPDATE remote_stream_state SET payload=payload WHERE profile=?', [profile]);
      final row = await db
          .customSelect('SELECT payload FROM remote_stream_state WHERE profile=?', variables: [Variable(profile)])
          .getSingle();
      final removed = await db
          .customSelect('SELECT 1 FROM remote_deleted_profiles WHERE profile=?', variables: [Variable(profile)])
          .getSingleOrNull();
      if (removed != null) throw StateError('Profile was removed');
      if (claim != null) {
        final ownership = await db
            .customSelect(
              'SELECT 1 FROM remote_preparation_claims WHERE profile=? AND job=? AND owner=? AND expires>?',
              variables: [
                Variable(profile),
                Variable(claim.job),
                Variable(claim.owner),
                Variable(DateTime.now().millisecondsSinceEpoch),
              ],
            )
            .getSingleOrNull();
        if (!claim.active || claim.profile != profile || ownership == null) {
          claim.active = false;
          throw const RemoteStreamStoreException(RemoteStreamStoreFailure.claimLost);
        }
      }
      final next = change(await _decode(row.read<String>('payload')));
      await db.customStatement('UPDATE remote_stream_state SET payload=? WHERE profile=?', [
        await CredentialVault.protect(next.encode()),
        profile,
      ]);
      return next;
    });
    if (legacy != null) await prefs.remove(profileScopedPrefsKey(profile, 'remote_streaming_v1'));
    return next;
  }

  static Future<List<String>> profiles() async =>
      (await (await _database).customSelect('SELECT profile FROM remote_stream_state').get())
          .map((row) => row.read<String>('profile'))
          .toList();

  /// Keep the idle decision and OS removal ordered before a producer's next
  /// journal commit. That producer then re-enqueues after its commit; cleanup
  /// cannot remove a task installed for a newly committed preparation.
  static Future<void> cancelRecoveryWhenIdle(Future<void> Function() cancel) async {
    final db = await _database;
    await db.transaction(() async {
      await db.customStatement('UPDATE remote_stream_state SET payload=payload');
      for (final row in await db.customSelect('SELECT payload FROM remote_stream_state').get()) {
        final snapshot = await _decode(row.read<String>('payload'));
        if (snapshot.preparations.any(
          (job) =>
              job.canRecoverAutomatically &&
              snapshot.accounts.any((account) => account.id == job.accountId && account.service == job.service),
        )) {
          return;
        }
      }
      await cancel();
    });
  }

  static Future<bool> claim(String profile, String job, String owner) async {
    final db = await _database;
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.transaction(() async {
      await db.customStatement(
        'INSERT INTO remote_preparation_claims SELECT ?,?,?,? WHERE NOT EXISTS '
        '(SELECT 1 FROM remote_deleted_profiles WHERE profile=?) '
        'ON CONFLICT(profile,job) DO UPDATE SET owner=excluded.owner,expires=excluded.expires '
        'WHERE remote_preparation_claims.expires<? OR remote_preparation_claims.owner=?',
        [profile, job, owner, now + const Duration(minutes: 10).inMilliseconds, profile, now, owner],
      );
      final row = await db
          .customSelect(
            'SELECT owner FROM remote_preparation_claims WHERE profile=? AND job=?',
            variables: [Variable(profile), Variable(job)],
          )
          .getSingleOrNull();
      return row?.read<String>('owner') == owner;
    });
  }

  static Future<void> release(String profile, String job, String owner) async => (await _database).customStatement(
    'DELETE FROM remote_preparation_claims WHERE profile=? AND job=? AND owner=?',
    [profile, job, owner],
  );

  static Future<bool> renewClaim(String profile, String job, String owner) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final changed = await (await _database).customUpdate(
      'UPDATE remote_preparation_claims SET expires=? WHERE profile=? AND job=? AND owner=? AND expires>?',
      variables: [
        Variable(now + const Duration(minutes: 10).inMilliseconds),
        Variable(profile),
        Variable(job),
        Variable(owner),
        Variable(now),
      ],
    );
    return changed == 1;
  }
}

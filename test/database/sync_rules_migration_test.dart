import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';

/// Verifies the v14 → v15 migration that adds `SyncRules.random` against a real
/// on-disk database stamped at v14.
///
/// A v15 schema with the `random` column dropped and `user_version` reset to 14
/// is byte-identical to a genuine v14 database, so reopening it through
/// [AppDatabase] exercises the actual `onUpgrade(14, 15)` path rather than a
/// hand-written DDL approximation.
void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('plezy_migration_test');
    dbFile = File('${tempDir.path}/v14.sqlite');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('migrates a v14 database by adding random (default false) without data loss', () async {
    // 1. Create a fresh v15 database on disk, then degrade it to v14: drop the
    //    `random` column and roll `user_version` back to 14.
    final seed = AppDatabase.forTesting(NativeDatabase(dbFile));
    await seed.insertSyncRule(
      serverId: 'srv',
      ratingKey: '10',
      globalKey: 'srv:10',
      targetType: 'show',
      episodeCount: 5,
    );
    await seed.customStatement('ALTER TABLE sync_rules DROP COLUMN random');
    await seed.customStatement('PRAGMA user_version = 14');

    // Sanity: the seeded DB now looks exactly like v14 (no random column).
    final preColumns = await seed
        .customSelect('PRAGMA table_info(sync_rules)')
        .map((row) => row.read<String>('name'))
        .get();
    expect(preColumns, isNot(contains('random')));
    final preVersion = await seed.customSelect('PRAGMA user_version').getSingle();
    expect(preVersion.read<int>('user_version'), 14);
    await seed.close();

    // 2. Reopen through AppDatabase — this runs the real onUpgrade(14, 15).
    final migrated = AppDatabase.forTesting(NativeDatabase(dbFile));
    addTearDown(migrated.close);

    // 3. The pre-existing row survives and gets random = false by default.
    final rule = await migrated.getSyncRule('srv:10');
    expect(rule, isNotNull);
    expect(rule!.episodeCount, 5);
    expect(rule.random, isFalse);

    // 4. The column exists and is writable end-to-end after migration.
    final postColumns = await migrated
        .customSelect('PRAGMA table_info(sync_rules)')
        .map((row) => row.read<String>('name'))
        .get();
    expect(postColumns, contains('random'));

    final postVersion = await migrated.customSelect('PRAGMA user_version').getSingle();
    expect(postVersion.read<int>('user_version'), 15);

    await migrated.insertSyncRule(
      serverId: 'srv',
      ratingKey: '11',
      globalKey: 'srv:11',
      targetType: 'show',
      episodeCount: 3,
      random: true,
    );
    expect((await migrated.getSyncRule('srv:11'))!.random, isTrue);

    // Updating the flag on the migrated row works too.
    await migrated.updateSyncRuleRandom('srv:10', true);
    expect((await migrated.getSyncRule('srv:10'))!.random, isTrue);
  });
}

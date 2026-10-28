import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/sources/source_database.dart';
import 'package:plezy/sources/source_models.dart';

// Reproduce the regular FTS table with the invalid contentless-table commands
// shipped in schema 8. The remaining tables have not changed in schema 9.
class _Version8Database extends SourceDatabase {
  _Version8Database(super.executor);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await super.migration.onCreate(migrator);
      for (final table in [
        'canonical_cards',
        'canonical_aliases',
        'canonical_copies',
        'canonical_redirects',
        'remote_stream_state',
        'remote_preparation_claims',
        'remote_deleted_profiles',
      ]) {
        await customStatement('DROP TABLE $table');
      }
      await customStatement('DROP TRIGGER entries_search_update');
      await customStatement('DROP TRIGGER entries_search_delete');
      await customStatement(
        'CREATE TRIGGER entries_search_update AFTER UPDATE OF search ON entries BEGIN '
        "INSERT INTO entries_search_fts(entries_search_fts,rowid,search) VALUES ('delete',old.rowid,old.search); "
        'INSERT INTO entries_search_fts(rowid,search) VALUES (new.rowid,new.search); END',
      );
      await customStatement(
        'CREATE TRIGGER entries_search_delete AFTER DELETE ON entries BEGIN '
        "INSERT INTO entries_search_fts(entries_search_fts,rowid,search) VALUES ('delete',old.rowid,old.search); END",
      );
    },
  );
}

void main() {
  test('schema 8 migration preserves entries and repairs FTS update and delete', () async {
    final directory = await Directory.systemTemp.createTemp('plezy-schema8-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/publications.sqlite');
    final oldDatabase = _Version8Database(NativeDatabase(file));
    await SourceRepository(oldDatabase).cacheEntries('alice', const [
      SourceEntry(sourceId: 'drive', id: 'book', title: 'Original title', kind: SourceItemKind.ebook),
    ]);
    await oldDatabase.close();

    final database = SourceDatabase(NativeDatabase(file));
    addTearDown(database.close);
    final repository = SourceRepository(database);
    expect((await repository.entries('alice')).single.title, 'Original title');
    final version = await database.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), 11);
    expect(
      await database.customSelect("SELECT rowid FROM entries_search_fts WHERE search MATCH 'Original'").get(),
      hasLength(1),
    );

    await repository.cacheEntries('alice', const [
      SourceEntry(sourceId: 'drive', id: 'book', title: 'Replacement title', kind: SourceItemKind.ebook),
    ]);
    expect((await repository.entries('alice')).single.title, 'Replacement title');
    expect(
      await database.customSelect("SELECT rowid FROM entries_search_fts WHERE search MATCH 'Original'").get(),
      isEmpty,
    );
    expect(
      await database.customSelect("SELECT rowid FROM entries_search_fts WHERE search MATCH 'Replacement'").get(),
      hasLength(1),
    );
    await database.customStatement("DELETE FROM entries WHERE profile='alice'");
    expect(await database.customSelect('SELECT rowid FROM entries_search_fts').get(), isEmpty);
  });
}

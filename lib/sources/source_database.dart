import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../services/credential_vault.dart';
import 'publication_shelf.dart';
import 'source_models.dart';

String _entrySearchText(SourceEntry entry) =>
    '${entry.title} ${entry.onlineTitle ?? ''} ${entry.author} ${entry.narrator} ${entry.series}'.toLowerCase();

/// Separate versioned database: installing file sources does not rewrite or
/// reinterpret the existing server, watched-state or download schemas.
class SourceDatabase extends GeneratedDatabase {
  SourceDatabase(super.executor);
  static Future<SourceDatabase> open() async {
    final directory = await getApplicationSupportDirectory();
    return SourceDatabase(NativeDatabase.createInBackground(File(p.join(directory.path, 'publications.sqlite'))));
  }

  @override
  int get schemaVersion => 10;
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) async {
      for (final sql in [
        'CREATE TABLE sources (profile TEXT NOT NULL, id TEXT NOT NULL, config TEXT NOT NULL, credentials TEXT NOT NULL, PRIMARY KEY(profile,id))',
        'CREATE TABLE entries (profile TEXT NOT NULL, source TEXT NOT NULL, id TEXT NOT NULL, parent TEXT, payload TEXT NOT NULL, scan_generation INTEGER NOT NULL DEFAULT 0, search TEXT NOT NULL DEFAULT \'\', entry_key TEXT NOT NULL DEFAULT \'\', PRIMARY KEY(profile,source,id))',
        'CREATE INDEX entries_profile_source_parent ON entries(profile,source,parent)',
        'CREATE INDEX entries_profile_entry_key ON entries(profile,entry_key)',
        'CREATE INDEX entries_profile_rowid ON entries(profile)',
        'CREATE TABLE entry_shelves (profile TEXT NOT NULL, source TEXT NOT NULL, id TEXT NOT NULL, shelf TEXT NOT NULL, PRIMARY KEY(profile,source,id,shelf))',
        'CREATE INDEX entry_shelves_profile_shelf ON entry_shelves(profile,shelf)',
        'CREATE TABLE source_scans (profile TEXT NOT NULL, source TEXT NOT NULL, generation INTEGER NOT NULL, PRIMARY KEY(profile,source))',
        'CREATE TABLE progress (profile TEXT NOT NULL, key TEXT NOT NULL, payload TEXT NOT NULL, revision INTEGER NOT NULL, pending INTEGER NOT NULL DEFAULT 0, remote TEXT, entry TEXT NOT NULL DEFAULT \'\', PRIMARY KEY(profile,key))',
        'CREATE INDEX progress_profile_entry ON progress(profile,entry)',
        'CREATE TABLE events (profile TEXT NOT NULL, id TEXT NOT NULL, key TEXT NOT NULL, payload TEXT NOT NULL, kind TEXT NOT NULL, created INTEGER NOT NULL, pending INTEGER NOT NULL, PRIMARY KEY(profile,id))',
        'CREATE INDEX events_pending ON events(profile,pending,created)',
        'CREATE TABLE annotations (profile TEXT NOT NULL, id TEXT NOT NULL, entry TEXT NOT NULL, payload TEXT NOT NULL, PRIMARY KEY(profile,id))',
        'CREATE TABLE downloads (profile TEXT NOT NULL, key TEXT NOT NULL, path TEXT NOT NULL, fingerprint TEXT NOT NULL, bytes INTEGER NOT NULL, complete INTEGER NOT NULL, source_id TEXT NOT NULL DEFAULT \'\', file_payload TEXT NOT NULL DEFAULT \'{}\', state TEXT NOT NULL DEFAULT \'completed\', updated INTEGER NOT NULL DEFAULT 0, reserved_bytes INTEGER NOT NULL DEFAULT 0, label TEXT NOT NULL DEFAULT \'\', PRIMARY KEY(profile,key))',
        'CREATE INDEX downloads_profile_state ON downloads(profile,state,updated)',
        'CREATE TABLE preferences (profile TEXT NOT NULL, key TEXT NOT NULL, payload TEXT NOT NULL, PRIMARY KEY(profile,key))',
      ]) {
        await customStatement(sql);
      }
      await _createEntrySearchIndex();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await customStatement('CREATE INDEX entries_profile_source_parent ON entries(profile,source,parent)');
      }
      if (from < 3) {
        await customStatement('ALTER TABLE entries ADD COLUMN scan_generation INTEGER NOT NULL DEFAULT 0');
        await customStatement(
          'CREATE TABLE source_scans (profile TEXT NOT NULL, source TEXT NOT NULL, generation INTEGER NOT NULL, PRIMARY KEY(profile,source))',
        );
      }
      if (from < 4) {
        await customStatement("ALTER TABLE progress ADD COLUMN entry TEXT NOT NULL DEFAULT ''");
        await customStatement("UPDATE progress SET entry=COALESCE(json_extract(payload,'\$.entryKey'),'')");
        await customStatement('CREATE INDEX progress_profile_entry ON progress(profile,entry)');
      }
      if (from < 5) {
        await customStatement("ALTER TABLE entries ADD COLUMN search TEXT NOT NULL DEFAULT ''");
        await customStatement("ALTER TABLE entries ADD COLUMN entry_key TEXT NOT NULL DEFAULT ''");
        await customStatement('CREATE INDEX entries_profile_entry_key ON entries(profile,entry_key)');
        final rows = await customSelect('SELECT profile,source,id,payload FROM entries').get();
        for (final row in rows) {
          final source = row.read<String>('source'), id = row.read<String>('id');
          var search = '';
          try {
            search = _entrySearchText(SourceEntry.fromJson(sourceMap(jsonDecode(row.read<String>('payload')))));
          } on Object {
            // Preserve a corrupt cached row so existing recovery behavior is
            // unchanged; it simply remains unavailable to text search.
          }
          await customStatement('UPDATE entries SET search=?,entry_key=? WHERE profile=? AND source=? AND id=?', [
            search,
            sourceKey(source, id),
            row.read<String>('profile'),
            row.read<String>('source'),
            row.read<String>('id'),
          ]);
        }
      }
      if (from < 6) {
        await customStatement('CREATE INDEX entries_profile_rowid ON entries(profile)');
        await customStatement(
          'CREATE TABLE entry_shelves (profile TEXT NOT NULL, source TEXT NOT NULL, id TEXT NOT NULL, shelf TEXT NOT NULL, PRIMARY KEY(profile,source,id,shelf))',
        );
        await customStatement('CREATE INDEX entry_shelves_profile_shelf ON entry_shelves(profile,shelf)');
        final rows = await customSelect('SELECT profile,source,id,payload FROM entries').get();
        for (final row in rows) {
          try {
            final entry = SourceEntry.fromJson(sourceMap(jsonDecode(row.read<String>('payload'))));
            for (final shelf in PublicationShelf.values.where((shelf) => shelf.includes(entry))) {
              await customStatement('INSERT OR IGNORE INTO entry_shelves(profile,source,id,shelf) VALUES (?,?,?,?)', [
                row.read<String>('profile'),
                row.read<String>('source'),
                row.read<String>('id'),
                shelf.name,
              ]);
            }
          } on Object {
            // Keep corrupt cache rows recoverable without making startup fail.
          }
        }
      }
      if (from >= 7 && from < 9) {
        // Versions 7/8 used a contentless-table delete command on a regular
        // FTS table. Rebuild only the derived index; preserve all source rows.
        for (final statement in const [
          'DROP TRIGGER IF EXISTS entries_search_insert',
          'DROP TRIGGER IF EXISTS entries_search_update',
          'DROP TRIGGER IF EXISTS entries_search_delete',
          'DROP TABLE IF EXISTS entries_search_fts',
        ]) {
          await customStatement(statement);
        }
      }
      if (from < 9) await _createEntrySearchIndex();
      if (from >= 5 && from < 10) await _refreshEntrySearchText();
      if (from < 8) {
        await customStatement("ALTER TABLE downloads ADD COLUMN source_id TEXT NOT NULL DEFAULT ''");
        await customStatement("ALTER TABLE downloads ADD COLUMN file_payload TEXT NOT NULL DEFAULT '{}'");
        await customStatement("ALTER TABLE downloads ADD COLUMN state TEXT NOT NULL DEFAULT 'completed'");
        await customStatement('ALTER TABLE downloads ADD COLUMN updated INTEGER NOT NULL DEFAULT 0');
        await customStatement('ALTER TABLE downloads ADD COLUMN reserved_bytes INTEGER NOT NULL DEFAULT 0');
        await customStatement("ALTER TABLE downloads ADD COLUMN label TEXT NOT NULL DEFAULT ''");
        await customStatement('CREATE INDEX downloads_profile_state ON downloads(profile,state,updated)');
        // Older partial rows have no persisted file descriptor, so they cannot
        // be reconstructed as queue jobs. Leave their partial files available
        // for a later explicit retry but keep them out of the actionable queue.
        await customStatement("UPDATE downloads SET state='legacy',updated=? WHERE complete=0", [
          DateTime.now().millisecondsSinceEpoch,
        ]);
      }
    },
  );

  /// Refresh only the derived search text. Page by rowid so upgrading a large
  /// index does not decode the entire catalogue into memory at startup.
  Future<void> _refreshEntrySearchText() async {
    var after = 0;
    while (true) {
      final rows = await customSelect(
        'SELECT rowid AS row_id,payload FROM entries WHERE rowid>? ORDER BY rowid LIMIT 200',
        variables: [Variable(after)],
      ).get();
      if (rows.isEmpty) return;
      for (final row in rows) {
        after = row.read<int>('row_id');
        SourceEntry entry;
        try {
          entry = SourceEntry.fromJson(sourceMap(jsonDecode(row.read<String>('payload'))));
        } on Object {
          // Preserve a damaged cache row for the existing recovery path.
          continue;
        }
        await customStatement('UPDATE entries SET search=? WHERE rowid=?', [_entrySearchText(entry), after]);
      }
    }
  }

  /// FTS5's trigram tokenizer preserves substring search while avoiding a
  /// full payload decode. Some system SQLite builds omit FTS5, so indexed
  /// search is optional and callers retain the SQL substring fallback.
  Future<void> _createEntrySearchIndex() async {
    try {
      await customStatement("CREATE VIRTUAL TABLE entries_search_fts USING fts5(search, tokenize='trigram')");
      await customStatement('INSERT INTO entries_search_fts(rowid,search) SELECT rowid,search FROM entries');
      await customStatement(
        'CREATE TRIGGER entries_search_insert AFTER INSERT ON entries BEGIN '
        'INSERT INTO entries_search_fts(rowid,search) VALUES (new.rowid,new.search); END',
      );
      await customStatement(
        'CREATE TRIGGER entries_search_update AFTER UPDATE OF search ON entries BEGIN '
        'DELETE FROM entries_search_fts WHERE rowid=old.rowid; '
        'INSERT INTO entries_search_fts(rowid,search) VALUES (new.rowid,new.search); END',
      );
      await customStatement(
        'CREATE TRIGGER entries_search_delete AFTER DELETE ON entries BEGIN '
        'DELETE FROM entries_search_fts WHERE rowid=old.rowid; END',
      );
    } on Object {
      for (final statement in const [
        'DROP TRIGGER IF EXISTS entries_search_insert',
        'DROP TRIGGER IF EXISTS entries_search_update',
        'DROP TRIGGER IF EXISTS entries_search_delete',
        'DROP TABLE IF EXISTS entries_search_fts',
      ]) {
        try {
          await customStatement(statement);
        } on Object {
          // Keep startup available when SQLite does not include FTS5.
        }
      }
    }
  }
}

class SourceRepository {
  SourceRepository(this.database, {this.protect = CredentialVault.protect, this.reveal = CredentialVault.reveal});
  final SourceDatabase database;
  final Future<String> Function(String) protect;
  final Future<String?> Function(String) reveal;
  static const _uuid = Uuid();
  static const defaultDownloadQuotaBytes = 10 * 1024 * 1024 * 1024;
  static const minimumDownloadQuotaBytes = 256 * 1024 * 1024;
  static const maximumDownloadQuotaBytes = 1024 * 1024 * 1024 * 1024;
  final _removedProfiles = <String>{};
  bool? _ftsSearchAvailable;
  void _writable(String profile) {
    if (_removedProfiles.contains(profile)) throw const SourceException(SourceFailure.cancelled);
  }

  Future<void> forgetProfile(String profile) async {
    _removedProfiles.add(profile);
    await database.transaction(() async {
      for (final table in [
        'sources',
        'entries',
        'entry_shelves',
        'source_scans',
        'progress',
        'events',
        'annotations',
        'downloads',
        'preferences',
      ]) {
        await database.customStatement('DELETE FROM $table WHERE profile=?', [profile]);
      }
    });
  }

  Future<List<FileSource>> sources(String profile) async =>
      (await database
              .customSelect(
                'SELECT config FROM sources WHERE profile = ? ORDER BY rowid',
                variables: [Variable(profile)],
              )
              .get())
          .map((r) => FileSource.fromJson(sourceMap(jsonDecode(r.read<String>('config')))))
          .toList();

  Future<void> saveSource(FileSource source, Map<String, String> credentials) async {
    if (const {
      FileSourceKind.webdav,
      FileSourceKind.opds,
      FileSourceKind.s3,
      FileSourceKind.audiobookshelf,
    }.contains(source.kind)) {
      validatePublicSourceUri(Uri.parse(source.endpoint), allowHttp: source.options['allowHttp'] == 'true');
    }
    final encrypted = await protect(jsonEncode(credentials));
    _writable(source.profileId);
    await database.customStatement('INSERT OR REPLACE INTO sources VALUES (?,?,?,?)', [
      source.profileId,
      source.id,
      jsonEncode(source.toJson()),
      encrypted,
    ]);
  }

  Future<Map<String, String>> credentials(FileSource source) async {
    final row = await database
        .customSelect(
          'SELECT credentials FROM sources WHERE profile = ? AND id = ?',
          variables: [Variable(source.profileId), Variable(source.id)],
        )
        .getSingleOrNull();
    if (row == null) throw const SourceException(SourceFailure.authentication);
    final clear = await reveal(row.read<String>('credentials'));
    if (clear == null) throw const SourceException(SourceFailure.authentication);
    return sourceMap(jsonDecode(clear)).map((k, v) => MapEntry(k, '$v'));
  }

  Future<void> updateCredentials(FileSource source, Map<String, String> credentials) async {
    final encrypted = await protect(jsonEncode(credentials));
    // UPDATE cannot resurrect a removed account after an in-flight refresh.
    await database.customStatement('UPDATE sources SET credentials = ? WHERE profile = ? AND id = ?', [
      encrypted,
      source.profileId,
      source.id,
    ]);
  }

  Future<void> removeSource(String profile, String source) => database.transaction(() async {
    _writable(profile);
    final entries = await database
        .customSelect(
          'SELECT id,payload FROM entries WHERE profile=? AND source=?',
          variables: [Variable(profile), Variable(source)],
        )
        .get();
    for (final row in entries) {
      final entry = SourceEntry.fromJson(sourceMap(jsonDecode(row.read<String>('payload'))));
      await database.customStatement('UPDATE entries SET payload=? WHERE profile=? AND source=? AND id=?', [
        jsonEncode(entry.copyWith(unavailable: true).toJson()),
        profile,
        source,
        row.read<String>('id'),
      ]);
    }
    await database.customStatement('DELETE FROM sources WHERE profile = ? AND id = ?', [profile, source]);
    // Retain progress and cache records for a reconnect, but mark them so
    // ordinary shelves do not present network-only media as playable offline.
  });

  Future<void> cacheEntries(String profile, List<SourceEntry> entries) => database.transaction(() async {
    _writable(profile);
    for (final entry in entries) {
      await database.customStatement(
        'INSERT INTO entries (profile,source,id,parent,payload,search,entry_key) VALUES (?,?,?,?,?,?,?) '
        'ON CONFLICT(profile,source,id) DO UPDATE SET parent=excluded.parent,payload=excluded.payload,search=excluded.search,entry_key=excluded.entry_key',
        [
          profile,
          entry.sourceId,
          entry.id,
          entry.parentId,
          jsonEncode(entry.toJson()),
          _entrySearchText(entry),
          entry.key,
        ],
      );
      await database.customStatement('DELETE FROM entry_shelves WHERE profile=? AND source=? AND id=?', [
        profile,
        entry.sourceId,
        entry.id,
      ]);
      for (final shelf in PublicationShelf.values.where((shelf) => shelf.includes(entry))) {
        await database.customStatement('INSERT INTO entry_shelves(profile,source,id,shelf) VALUES (?,?,?,?)', [
          profile,
          entry.sourceId,
          entry.id,
          shelf.name,
        ]);
      }
    }
  });

  Future<bool> hasShelfEntries(String profile, PublicationShelf shelf) async =>
      await database
          .customSelect(
            'SELECT 1 FROM entry_shelves WHERE profile=? AND shelf=? LIMIT 1',
            variables: [Variable(profile), Variable(shelf.name)],
          )
          .getSingleOrNull() !=
      null;

  Future<bool> _hasFullTextSearch() async {
    final cached = _ftsSearchAvailable;
    if (cached != null) return cached;
    try {
      await database.customSelect('SELECT rowid FROM entries_search_fts LIMIT 0').get();
      _ftsSearchAvailable = true;
      return true;
    } on Object {
      _ftsSearchAvailable = false;
      return false;
    }
  }

  Future<int> beginSourceScan(String profile, String source) => database.transaction(() async {
    _writable(profile);
    final row = await database
        .customSelect(
          'SELECT generation FROM source_scans WHERE profile=? AND source=?',
          variables: [Variable(profile), Variable(source)],
        )
        .getSingleOrNull();
    final generation = (row?.read<int>('generation') ?? 0) + 1;
    await database.customStatement('INSERT OR REPLACE INTO source_scans VALUES (?,?,?)', [profile, source, generation]);
    return generation;
  });

  Future<void> markScannedEntries(String profile, int generation, List<SourceEntry> entries) =>
      database.transaction(() async {
        _writable(profile);
        for (final entry in entries) {
          await database.customStatement('UPDATE entries SET scan_generation=? WHERE profile=? AND source=? AND id=?', [
            generation,
            profile,
            entry.sourceId,
            entry.id,
          ]);
        }
      });

  Future<void> finishSourceScan(String profile, String source, int generation, {required bool Function() isCurrent}) =>
      database.transaction(() async {
        _writable(profile);
        if (!isCurrent()) throw const SourceException(SourceFailure.cancelled);
        final active = await database
            .customSelect(
              'SELECT generation FROM source_scans WHERE profile=? AND source=?',
              variables: [Variable(profile), Variable(source)],
            )
            .getSingleOrNull();
        if (active?.read<int>('generation') != generation) {
          throw const SourceException(SourceFailure.cancelled);
        }
        final stale = await database
            .customSelect(
              'SELECT id,payload FROM entries WHERE profile=? AND source=? AND scan_generation<?',
              variables: [Variable(profile), Variable(source), Variable(generation)],
            )
            .get();
        final completed = <String, String>{
          for (final row
              in await database
                  .customSelect(
                    'SELECT key,fingerprint FROM downloads WHERE profile=? AND complete=1',
                    variables: [Variable(profile)],
                  )
                  .get())
            row.read<String>('key'): row.read<String>('fingerprint'),
        };
        if (!isCurrent()) throw const SourceException(SourceFailure.cancelled);
        for (final row in stale) {
          if (!isCurrent()) throw const SourceException(SourceFailure.cancelled);
          final id = row.read<String>('id');
          final entry = SourceEntry.fromJson(sourceMap(jsonDecode(row.read<String>('payload'))));
          final retainedOffline = entry.files.any((file) => completed[sourceKey(source, file.id)] == file.fingerprint);
          if (retainedOffline) {
            await database.customStatement(
              'UPDATE entries SET scan_generation=?,payload=? WHERE profile=? AND source=? AND id=?',
              [generation, jsonEncode(entry.copyWith(unavailable: true).toJson()), profile, source, id],
            );
          } else {
            await database.customStatement('DELETE FROM entry_shelves WHERE profile=? AND source=? AND id=?', [
              profile,
              source,
              id,
            ]);
            await database.customStatement('DELETE FROM entries WHERE profile=? AND source=? AND id=?', [
              profile,
              source,
              id,
            ]);
          }
        }
      });
  Future<List<SourceEntry>> entries(
    String profile, {
    String? source,
    String? parent,
    String? query,
    bool filterParent = false,
  }) async {
    final predicates = <String>['profile = ?'];
    final variables = <Variable<Object>>[Variable(profile)];
    if (source != null) {
      predicates.add('source = ?');
      variables.add(Variable(source));
    }
    if (filterParent) {
      if (parent == null) {
        predicates.add("(parent IS NULL OR parent = '')");
      } else {
        predicates.add('parent = ?');
        variables.add(Variable(parent));
      }
    }
    if (query?.trim().isNotEmpty == true) {
      predicates.add('instr(search,?)>0');
      variables.add(Variable(query!.trim().toLowerCase()));
    }
    final rows = await database
        .customSelect('SELECT payload FROM entries WHERE ${predicates.join(' AND ')}', variables: variables)
        .get();
    return rows
        .map((r) => SourceEntry.fromJson(sourceMap(jsonDecode(r.read<String>('payload')))))
        .where(
          (e) =>
              (source == null || e.sourceId == source) &&
              (!filterParent || (parent == null ? e.parentId == null || e.parentId!.isEmpty : e.parentId == parent)) &&
              (query == null || _entrySearchText(e).contains(query.trim().toLowerCase())),
        )
        .toList();
  }

  /// Returns a bounded source-index slice. Only the selected payloads are
  /// decoded; the stable rowid cursor avoids loading the entire profile index
  /// to satisfy a small first page or a text search.
  Future<({List<SourceEntry> items, String? cursor})> entriesPage(
    String profile, {
    String? source,
    String? parent,
    bool filterParent = false,
    PublicationShelf? shelf,
    String? query,
    String? cursor,
    int limit = 200,
  }) async {
    final safeLimit = limit.clamp(1, 500).toInt();
    final predicates = <String>['profile=?'];
    final variables = <Variable<Object>>[Variable(profile)];
    if (source != null) {
      predicates.add('source=?');
      variables.add(Variable(source));
    }
    if (filterParent) {
      if (parent == null) {
        predicates.add("(parent IS NULL OR parent='')");
      } else {
        predicates.add('parent=?');
        variables.add(Variable(parent));
      }
    }
    if (shelf != null) {
      predicates.add(
        'EXISTS (SELECT 1 FROM entry_shelves es WHERE es.profile=entries.profile AND es.source=entries.source AND es.id=entries.id AND es.shelf=?)',
      );
      variables.add(Variable(shelf.name));
    }
    final normalizedQuery = query?.trim().toLowerCase() ?? '';
    final useFts = normalizedQuery.runes.length >= 3 && await _hasFullTextSearch();
    final after = cursor == null ? 0 : int.tryParse(cursor);
    if (after == null || after < 0) throw const SourceException(SourceFailure.invalidData);
    Future<List<QueryRow>> fetch(bool fts) {
      final pagePredicates = [...predicates];
      final pageVariables = [...variables];
      if (normalizedQuery.isNotEmpty) {
        if (fts) {
          pagePredicates.add('rowid IN (SELECT rowid FROM entries_search_fts WHERE search MATCH ?)');
          pageVariables.add(Variable('"${normalizedQuery.replaceAll('"', '""')}"'));
          // Preserve the original substring predicate even if a tokenizer
          // version returns a broader candidate set.
          pagePredicates.add('instr(search,?)>0');
          pageVariables.add(Variable(normalizedQuery));
        } else {
          pagePredicates.add('instr(search,?)>0');
          pageVariables.add(Variable(normalizedQuery));
        }
      }
      pagePredicates.add('rowid>?');
      pageVariables.add(Variable(after));
      pageVariables.add(Variable(safeLimit + 1));
      return database
          .customSelect(
            'SELECT rowid AS page_id,payload FROM entries WHERE ${pagePredicates.join(' AND ')} ORDER BY rowid LIMIT ?',
            variables: pageVariables,
          )
          .get();
    }

    List<QueryRow> rows;
    if (useFts) {
      try {
        rows = await fetch(true);
      } on Object {
        _ftsSearchAvailable = false;
        rows = await fetch(false);
      }
    } else {
      rows = await fetch(false);
    }
    final hasMore = rows.length > safeLimit;
    final selected = rows.take(safeLimit).toList(growable: false);
    final items = selected
        .map((row) => SourceEntry.fromJson(sourceMap(jsonDecode(row.read<String>('payload')))))
        .toList(growable: false);
    return (items: items, cursor: hasMore && selected.isNotEmpty ? '${selected.last.read<int>('page_id')}' : null);
  }

  /// A small recent-state slice keeps the Files root's Continue rows useful
  /// without decoding every progress record in the profile.
  Future<List<(SourceEntry, PublicationProgress)>> recentProgressEntries(String profile, {int limit = 18}) async {
    final safeLimit = limit.clamp(1, 100).toInt();
    final rows = await database
        .customSelect(
          'SELECT e.payload AS entry_payload,p.payload AS progress_payload '
          'FROM progress p JOIN entries e ON e.profile=p.profile AND e.entry_key=p.entry '
          "WHERE p.profile=? ORDER BY CAST(json_extract(p.payload,'\$.updatedAt') AS INTEGER) DESC LIMIT ?",
          variables: [Variable(profile), Variable(safeLimit)],
        )
        .get();
    return rows
        .map(
          (row) => (
            SourceEntry.fromJson(sourceMap(jsonDecode(row.read<String>('entry_payload')))),
            PublicationProgress.fromJson(sourceMap(jsonDecode(row.read<String>('progress_payload')))),
          ),
        )
        .toList(growable: false);
  }

  /// Bounded recent index slice for lightweight surfaces such as discovery.
  /// Unlike [entries], this puts the bound in SQL and does not materialize a
  /// large profile index merely to select a few candidate cards.
  Future<List<SourceEntry>> recentEntries(String profile, {String? source, int limit = 120}) async {
    final safeLimit = limit.clamp(1, 500).toInt();
    final rows = await database
        .customSelect(
          source == null
              ? 'SELECT payload FROM entries WHERE profile = ? ORDER BY rowid DESC LIMIT ?'
              : 'SELECT payload FROM entries WHERE profile = ? AND source = ? ORDER BY rowid DESC LIMIT ?',
          variables: source == null
              ? [Variable(profile), Variable(safeLimit)]
              : [Variable(profile), Variable(source), Variable(safeLimit)],
        )
        .get();
    return rows.map((row) => SourceEntry.fromJson(sourceMap(jsonDecode(row.read<String>('payload'))))).toList();
  }

  Future<SourceEntry?> entryById(String profile, String source, String id) async {
    final row = await database
        .customSelect(
          'SELECT payload FROM entries WHERE profile = ? AND source = ? AND id = ?',
          variables: [Variable(profile), Variable(source), Variable(id)],
        )
        .getSingleOrNull();
    return row == null ? null : SourceEntry.fromJson(sourceMap(jsonDecode(row.read<String>('payload'))));
  }

  Future<SourceEntry?> entryByKey(String profile, String key) async {
    final row = await database
        .customSelect(
          'SELECT payload FROM entries WHERE profile=? AND entry_key=? LIMIT 1',
          variables: [Variable(profile), Variable(key)],
        )
        .getSingleOrNull();
    return row == null ? null : SourceEntry.fromJson(sourceMap(jsonDecode(row.read<String>('payload'))));
  }

  Future<PublicationProgress?> progress(String profile, String key) async {
    final row = await database
        .customSelect(
          'SELECT payload FROM progress WHERE profile = ? AND key = ?',
          variables: [Variable(profile), Variable(key)],
        )
        .getSingleOrNull();
    return row == null ? null : PublicationProgress.fromJson(sourceMap(jsonDecode(row.read<String>('payload'))));
  }

  Future<bool> isPending(String profile, String key) async =>
      (await database
              .customSelect(
                'SELECT pending FROM progress WHERE profile=? AND key=?',
                variables: [Variable(profile), Variable(key)],
              )
              .getSingleOrNull())
          ?.read<int>('pending') ==
      1;
  Future<void> clearConflict(String profile, String key) =>
      database.customStatement('UPDATE progress SET remote=NULL WHERE profile=? AND key=?', [profile, key]);
  Future<void> importAnnotation(String profile, BookAnnotation annotation) {
    _writable(profile);
    return database.customStatement('INSERT OR IGNORE INTO annotations VALUES (?,?,?,?)', [
      profile,
      annotation.id,
      annotation.entryKey,
      jsonEncode(annotation.toJson()),
    ]);
  }

  /// Applies an annotation pulled from encrypted sync and queues it for the
  /// entry's provider target. The caller runs this inside the same transaction
  /// that commits the cloud sync baseline.
  Future<void> importSyncedAnnotation(String profile, BookAnnotation annotation) async {
    _writable(profile);
    await database.customStatement('INSERT OR REPLACE INTO annotations VALUES (?,?,?,?)', [
      profile,
      annotation.id,
      annotation.entryKey,
      jsonEncode(annotation.toJson()),
    ]);
    for (final event in await pendingEvents(profile)) {
      if (event['kind'] != 'annotation' || event['key'] != annotation.entryKey) continue;
      try {
        final existing = BookAnnotation.fromJson(sourceMap(jsonDecode(event['payload'] as String)));
        if (existing.id == annotation.id) {
          await database.customStatement('UPDATE events SET pending=0 WHERE profile=? AND id=?', [
            profile,
            event['id'],
          ]);
        }
      } on Object {
        // Preserve malformed events for the sync path to report and repair.
      }
    }
    await database.customStatement('INSERT INTO events VALUES (?,?,?,?,?,?,1)', [
      profile,
      _uuid.v4(),
      annotation.entryKey,
      jsonEncode(annotation.toJson()),
      'annotation',
      annotation.updatedAt,
    ]);
  }

  Future<List<PublicationProgress>> allProgress(String profile) async =>
      (await database
              .customSelect(
                'SELECT payload FROM progress WHERE profile = ? ORDER BY rowid DESC',
                variables: [Variable(profile)],
              )
              .get())
          .map((r) => PublicationProgress.fromJson(sourceMap(jsonDecode(r.read<String>('payload')))))
          .toList();

  /// Loads progress for a visible slice without decoding every profile record.
  Future<List<PublicationProgress>> progressForEntries(String profile, Iterable<String> entryKeys) async {
    final keys = entryKeys.toSet().toList(growable: false);
    if (keys.isEmpty) return const [];
    final result = <PublicationProgress>[];
    for (var start = 0; start < keys.length; start += 500) {
      final chunk = keys.skip(start).take(500).toList(growable: false);
      final placeholders = List.filled(chunk.length, '?').join(',');
      final rows = await database
          .customSelect(
            'SELECT payload FROM progress WHERE profile=? AND entry IN ($placeholders) ORDER BY rowid DESC',
            variables: [Variable(profile), ...chunk.map((key) => Variable(key))],
          )
          .get();
      result.addAll(
        rows.map((row) => PublicationProgress.fromJson(sourceMap(jsonDecode(row.read<String>('payload'))))),
      );
    }
    return result;
  }

  /// The caller carries the last committed revision. An old screen cannot
  /// overwrite a newer session or an explicit reset when its final tick lands.
  Future<PublicationProgress> saveProgress(
    String profile,
    PublicationProgress value, {
    String kind = 'position',
  }) => database.transaction(() async {
    _writable(profile);
    final current = await progress(profile, value.key);
    if (current != null && current.revision != value.revision) {
      throw const SourceException(SourceFailure.conflict);
    }
    final next = value.copyWith(
      revision: (current?.revision ?? 0) + 1,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    final payload = jsonEncode(next.toJson());
    await database.customStatement(
      'INSERT INTO progress(profile,key,payload,revision,pending,entry) VALUES (?,?,?,?,1,?) '
      'ON CONFLICT(profile,key) DO UPDATE SET payload=excluded.payload,revision=excluded.revision,pending=1,entry=excluded.entry',
      [profile, next.key, payload, next.revision, next.entryKey],
    );
    await database.customStatement('INSERT INTO events VALUES (?,?,?,?,?,?,1)', [
      profile,
      _uuid.v4(),
      next.key,
      payload,
      kind,
      next.updatedAt,
    ]);
    // The latest absolute snapshot is sufficient for replay. Preserve a
    // bounded undo history without growing one row every five seconds forever.
    await database.customStatement(
      'DELETE FROM events WHERE profile=? AND key=? AND kind != ? AND rowid NOT IN '
      '(SELECT rowid FROM events WHERE profile=? AND key=? AND kind != ? ORDER BY rowid DESC LIMIT 100)',
      [profile, next.key, 'annotation', profile, next.key, 'annotation'],
    );
    return next;
  });

  Future<void> acknowledge(String profile, String key, int revision) => database.transaction(() async {
    await database.customStatement(
      'UPDATE progress SET pending=0,remote=NULL WHERE profile=? AND key=? AND revision=?',
      [profile, key, revision],
    );
    final events = await pendingEvents(profile);
    for (final event in events.where((e) => e['key'] == key)) {
      final payload = sourceMap(jsonDecode(event['payload'] as String));
      if ((sourceInt(payload['revision']) ?? 0) <= revision) {
        await database.customStatement('UPDATE events SET pending=0 WHERE profile=? AND id=?', [profile, event['id']]);
      }
    }
  });

  Future<List<Map<String, dynamic>>> pendingEvents(String profile) async =>
      (await database
              .customSelect(
                'SELECT id,key,payload,kind,created FROM events WHERE profile=? AND pending=1 ORDER BY created,rowid',
                variables: [Variable(profile)],
              )
              .get())
          .map((r) => r.data)
          .toList();

  Future<void> recordRemoteConflict(String profile, PublicationProgress remote) => database.customStatement(
    'UPDATE progress SET remote=? WHERE profile=? AND key=?',
    [jsonEncode(remote.toJson()), profile, remote.key],
  );
  Future<PublicationProgress?> remoteConflict(String profile, String key) async {
    final row = await database
        .customSelect(
          'SELECT remote FROM progress WHERE profile=? AND key=?',
          variables: [Variable(profile), Variable(key)],
        )
        .getSingleOrNull();
    final value = row?.readNullable<String>('remote');
    return value == null ? null : PublicationProgress.fromJson(sourceMap(jsonDecode(value)));
  }

  Future<void> saveAnnotation(String profile, BookAnnotation annotation) => database.transaction(() async {
    _writable(profile);
    await database.customStatement('INSERT OR REPLACE INTO annotations VALUES (?,?,?,?)', [
      profile,
      annotation.id,
      annotation.entryKey,
      jsonEncode(annotation.toJson()),
    ]);
    // Annotation events are absolute snapshots. An older unpushed edit for
    // the same bookmark carries no additional information.
    final events = await pendingEvents(profile);
    for (final event in events.where((e) => e['kind'] == 'annotation' && e['key'] == annotation.entryKey)) {
      final payload = sourceMap(jsonDecode(event['payload'] as String));
      if (payload['id'] == annotation.id) {
        await database.customStatement('UPDATE events SET pending=0 WHERE profile=? AND id=?', [profile, event['id']]);
      }
    }
    await database.customStatement('INSERT INTO events VALUES (?,?,?,?,?,?,1)', [
      profile,
      _uuid.v4(),
      annotation.entryKey,
      jsonEncode(annotation.toJson()),
      'annotation',
      annotation.updatedAt,
    ]);
  });

  Future<void> acknowledgeAnnotation(String profile, BookAnnotation annotation) => database.transaction(() async {
    final events = await pendingEvents(profile);
    for (final event in events.where((e) => e['kind'] == 'annotation' && e['key'] == annotation.entryKey)) {
      final payload = BookAnnotation.fromJson(sourceMap(jsonDecode(event['payload'] as String)));
      if (payload.id == annotation.id && jsonEncode(payload.toJson()) == jsonEncode(annotation.toJson())) {
        await database.customStatement('UPDATE events SET pending=0 WHERE profile=? AND id=?', [profile, event['id']]);
      }
    }
  });
  Future<List<BookAnnotation>> annotations(String profile, String entry) async =>
      (await database
              .customSelect(
                'SELECT payload FROM annotations WHERE profile=? AND entry=?',
                variables: [Variable(profile), Variable(entry)],
              )
              .get())
          .map((r) => BookAnnotation.fromJson(sourceMap(jsonDecode(r.read<String>('payload')))))
          .where((a) => !a.deleted)
          .toList();

  Future<Map<String, dynamic>> preference(String profile, String key) async {
    final row = await database
        .customSelect(
          'SELECT payload FROM preferences WHERE profile=? AND key=?',
          variables: [Variable(profile), Variable(key)],
        )
        .getSingleOrNull();
    return row == null ? {} : sourceMap(jsonDecode(row.read<String>('payload')));
  }

  Future<void> savePreference(String profile, String key, Map<String, dynamic> value) {
    _writable(profile);
    return database.customStatement('INSERT OR REPLACE INTO preferences VALUES (?,?,?)', [
      profile,
      key,
      jsonEncode(value),
    ]);
  }

  Future<Map<String, dynamic>> updatePreferenceAtomically(
    String profile,
    String key,
    Map<String, dynamic> Function(Map<String, dynamic> current) update,
  ) => database.transaction(() async {
    _writable(profile);
    final row = await database
        .customSelect(
          'SELECT payload FROM preferences WHERE profile=? AND key=?',
          variables: [Variable(profile), Variable(key)],
        )
        .getSingleOrNull();
    Map<String, dynamic> current = {};
    if (row != null) {
      try {
        current = sourceMap(jsonDecode(row.read<String>('payload')));
      } on FormatException {
        // A broken preference should not prevent replacing it with a
        // valid state produced by the caller.
      }
    }
    final next = update(current);
    _writable(profile);
    await database.customStatement('INSERT OR REPLACE INTO preferences VALUES (?,?,?)', [
      profile,
      key,
      jsonEncode(next),
    ]);
    return next;
  });

  Future<Map<String, dynamic>> privatePreference(String profile, String key) async {
    final stored = await preference(profile, key);
    if (stored['sealed'] is! String) return {};
    final clear = await reveal(stored['sealed'] as String);
    if (clear == null) throw const SourceException(SourceFailure.authentication);
    return sourceMap(jsonDecode(clear));
  }

  Future<void> savePrivatePreference(String profile, String key, Map<String, dynamic> value) async =>
      savePreference(profile, key, {'sealed': await protect(jsonEncode(value))});

  Future<void> forgetPreference(String profile, String key) =>
      database.customStatement('DELETE FROM preferences WHERE profile=? AND key=?', [profile, key]);

  Future<void> recordDownload(
    String profile,
    String key,
    String path,
    String fingerprint,
    int bytes, {
    bool complete = true,
    int? reservedBytes,
    String sourceId = '',
    PublicationFile? file,
    String label = '',
  }) {
    _writable(profile);
    return database.customStatement(
      'INSERT INTO downloads(profile,key,path,fingerprint,bytes,complete,source_id,file_payload,state,updated,reserved_bytes,label) '
      'VALUES (?,?,?,?,?,?,?,?,?,?,?,?) ON CONFLICT(profile,key) DO UPDATE SET '
      'path=excluded.path,fingerprint=excluded.fingerprint,bytes=excluded.bytes,complete=excluded.complete,'
      'state=excluded.state,updated=excluded.updated,reserved_bytes=MAX(excluded.reserved_bytes,excluded.bytes),'
      'source_id=CASE WHEN excluded.source_id=\'\' THEN downloads.source_id ELSE excluded.source_id END,'
      'file_payload=CASE WHEN excluded.file_payload=\'{}\' THEN downloads.file_payload ELSE excluded.file_payload END,'
      'label=CASE WHEN excluded.label=\'\' THEN downloads.label ELSE excluded.label END',
      [
        profile,
        key,
        path,
        fingerprint,
        bytes,
        complete ? 1 : 0,
        sourceId,
        file == null ? '{}' : jsonEncode(file.toJson()),
        complete ? 'completed' : 'running',
        DateTime.now().millisecondsSinceEpoch,
        reservedBytes ?? bytes,
        label,
      ],
    );
  }

  Future<int> downloadQuota(String profile) async {
    final value = sourceInt((await preference(profile, 'publication-download-quota-v1'))['bytes']);
    return (value ?? defaultDownloadQuotaBytes).clamp(minimumDownloadQuotaBytes, maximumDownloadQuotaBytes).toInt();
  }

  Future<void> setDownloadQuota(String profile, int bytes) async {
    _writable(profile);
    if (bytes < minimumDownloadQuotaBytes || bytes > maximumDownloadQuotaBytes) {
      throw const SourceException(SourceFailure.invalidData);
    }
    await database.transaction(() async {
      _writable(profile);
      final usage = await database
          .customSelect(
            'SELECT COALESCE(SUM(MAX(bytes,reserved_bytes)),0) AS reserved FROM downloads WHERE profile=?',
            variables: [Variable(profile)],
          )
          .getSingle();
      if (usage.read<int>('reserved') > bytes) {
        throw const SourceException(SourceFailure.quotaExceeded);
      }
      await savePreference(profile, 'publication-download-quota-v1', {'bytes': bytes});
    });
  }

  Future<({int usedBytes, int reservedBytes})> downloadStorageUsage(String profile) async {
    final row = await database
        .customSelect(
          'SELECT COALESCE(SUM(bytes),0) AS used,COALESCE(SUM(MAX(bytes,reserved_bytes)),0) AS reserved '
          'FROM downloads WHERE profile=?',
          variables: [Variable(profile)],
        )
        .getSingle();
    return (usedBytes: row.read<int>('used'), reservedBytes: row.read<int>('reserved'));
  }

  /// Atomically reserves quota before a transfer starts or grows its reservation.
  /// Completed copies and concurrent reservations are included in the same cap.
  Future<void> reserveDownload({
    required String profile,
    required String key,
    required String sourceId,
    required PublicationFile file,
    required String path,
    required int reservedBytes,
    required int bytes,
    required String state,
    required String label,
  }) async {
    _writable(profile);
    if (reservedBytes < 0 ||
        bytes < 0 ||
        !const {'queued', 'running', 'paused', 'failed', 'completed', 'importing'}.contains(state)) {
      throw const SourceException(SourceFailure.invalidData);
    }
    await database.transaction(() async {
      _writable(profile);
      final quota = await downloadQuota(profile);
      final row = await database
          .customSelect(
            'SELECT COALESCE(SUM(MAX(bytes,reserved_bytes)),0) AS used FROM downloads WHERE profile=? AND key<>?',
            variables: [Variable(profile), Variable(key)],
          )
          .getSingle();
      if (row.read<int>('used') + math.max(reservedBytes, bytes) > quota) {
        throw const SourceException(SourceFailure.quotaExceeded);
      }
      await database.customStatement(
        'INSERT INTO downloads(profile,key,path,fingerprint,bytes,complete,source_id,file_payload,state,updated,reserved_bytes,label) '
        'VALUES (?,?,?,?,?,0,?,?,?,?,?,?) ON CONFLICT(profile,key) DO UPDATE SET '
        'path=excluded.path,fingerprint=excluded.fingerprint,bytes=excluded.bytes,complete=0,source_id=excluded.source_id,'
        'file_payload=excluded.file_payload,state=excluded.state,updated=excluded.updated,'
        'reserved_bytes=excluded.reserved_bytes,label=excluded.label',
        [
          profile,
          key,
          path,
          file.fingerprint,
          bytes,
          sourceId,
          jsonEncode(file.toJson()),
          state,
          DateTime.now().millisecondsSinceEpoch,
          math.max(reservedBytes, bytes),
          label,
        ],
      );
    });
  }

  Future<void> setDownloadState(String profile, String key, String state) async {
    _writable(profile);
    await database.customStatement('UPDATE downloads SET state=?,updated=? WHERE profile=? AND key=? AND complete=0', [
      state,
      DateTime.now().millisecondsSinceEpoch,
      profile,
      key,
    ]);
  }

  Future<Map<String, dynamic>?> download(String profile, String key) async =>
      (await database
              .customSelect(
                'SELECT * FROM downloads WHERE profile=? AND key=?',
                variables: [Variable(profile), Variable(key)],
              )
              .getSingleOrNull())
          ?.data;
  Future<List<Map<String, dynamic>>> downloads(String profile) async =>
      (await database.customSelect('SELECT * FROM downloads WHERE profile=?', variables: [Variable(profile)]).get())
          .map((r) => r.data)
          .toList();

  /// Remaining bytes reserved by active writers across every profile. The OS
  /// free-space guard is volume-wide even while a profile switch is settling.
  Future<int> activeDownloadReservationBytes() async {
    final row = await database
        .customSelect(
          "SELECT COALESCE(SUM(MAX(reserved_bytes,bytes)-bytes),0) AS remaining "
          "FROM downloads WHERE state IN ('running','importing')",
        )
        .getSingle();
    return sourceInt(row.data['remaining']) ?? 0;
  }

  Future<void> forgetDownload(String profile, String key) =>
      database.customStatement('DELETE FROM downloads WHERE profile=? AND key=?', [profile, key]);
  Future<List<Map<String, dynamic>>> history(String profile, String key) async =>
      (await database
              .customSelect(
                'SELECT payload,kind,created FROM events WHERE profile=? AND key=? ORDER BY created DESC,rowid DESC LIMIT 100',
                variables: [Variable(profile), Variable(key)],
              )
              .get())
          .map((r) => r.data)
          .toList();
}

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../services/credential_vault.dart';
import 'source_models.dart';

/// Separate versioned database: installing file sources does not rewrite or
/// reinterpret the existing server, watched-state or download schemas.
class SourceDatabase extends GeneratedDatabase {
  SourceDatabase(super.executor);
  static Future<SourceDatabase> open() async {
    final directory = await getApplicationSupportDirectory();
    return SourceDatabase(NativeDatabase.createInBackground(File(p.join(directory.path, 'publications.sqlite'))));
  }

  @override
  int get schemaVersion => 4;
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) async {
      for (final sql in [
        'CREATE TABLE sources (profile TEXT NOT NULL, id TEXT NOT NULL, config TEXT NOT NULL, credentials TEXT NOT NULL, PRIMARY KEY(profile,id))',
        'CREATE TABLE entries (profile TEXT NOT NULL, source TEXT NOT NULL, id TEXT NOT NULL, parent TEXT, payload TEXT NOT NULL, scan_generation INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(profile,source,id))',
        'CREATE INDEX entries_profile_source_parent ON entries(profile,source,parent)',
        'CREATE TABLE source_scans (profile TEXT NOT NULL, source TEXT NOT NULL, generation INTEGER NOT NULL, PRIMARY KEY(profile,source))',
        'CREATE TABLE progress (profile TEXT NOT NULL, key TEXT NOT NULL, payload TEXT NOT NULL, revision INTEGER NOT NULL, pending INTEGER NOT NULL DEFAULT 0, remote TEXT, entry TEXT NOT NULL DEFAULT \'\', PRIMARY KEY(profile,key))',
        'CREATE INDEX progress_profile_entry ON progress(profile,entry)',
        'CREATE TABLE events (profile TEXT NOT NULL, id TEXT NOT NULL, key TEXT NOT NULL, payload TEXT NOT NULL, kind TEXT NOT NULL, created INTEGER NOT NULL, pending INTEGER NOT NULL, PRIMARY KEY(profile,id))',
        'CREATE INDEX events_pending ON events(profile,pending,created)',
        'CREATE TABLE annotations (profile TEXT NOT NULL, id TEXT NOT NULL, entry TEXT NOT NULL, payload TEXT NOT NULL, PRIMARY KEY(profile,id))',
        'CREATE TABLE downloads (profile TEXT NOT NULL, key TEXT NOT NULL, path TEXT NOT NULL, fingerprint TEXT NOT NULL, bytes INTEGER NOT NULL, complete INTEGER NOT NULL, PRIMARY KEY(profile,key))',
        'CREATE TABLE preferences (profile TEXT NOT NULL, key TEXT NOT NULL, payload TEXT NOT NULL, PRIMARY KEY(profile,key))',
      ]) {
        await customStatement(sql);
      }
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
        await customStatement("UPDATE progress SET entry=COALESCE(json_extract(payload,'$.entryKey'),'')");
        await customStatement('CREATE INDEX progress_profile_entry ON progress(profile,entry)');
      }
    },
  );
}

class SourceRepository {
  SourceRepository(this.database, {this.protect = CredentialVault.protect, this.reveal = CredentialVault.reveal});
  final SourceDatabase database;
  final Future<String> Function(String) protect;
  final Future<String?> Function(String) reveal;
  static const _uuid = Uuid();
  final _removedProfiles = <String>{};
  void _writable(String profile) {
    if (_removedProfiles.contains(profile)) throw const SourceException(SourceFailure.cancelled);
  }

  Future<void> forgetProfile(String profile) async {
    _removedProfiles.add(profile);
    await database.transaction(() async {
      for (final table in ['sources', 'entries', 'source_scans', 'progress', 'events', 'annotations', 'downloads', 'preferences']) {
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
        .customSelect('SELECT id,payload FROM entries WHERE profile=? AND source=?', variables: [Variable(profile), Variable(source)])
        .get();
    for (final row in entries) {
      final entry = SourceEntry.fromJson(sourceMap(jsonDecode(row.read<String>('payload'))));
      await database.customStatement(
        'UPDATE entries SET payload=? WHERE profile=? AND source=? AND id=?',
        [jsonEncode(entry.copyWith(unavailable: true).toJson()), profile, source, row.read<String>('id')],
      );
    }
    await database.customStatement('DELETE FROM sources WHERE profile = ? AND id = ?', [profile, source]);
    // Retain progress and cache records for a reconnect, but mark them so
    // ordinary shelves do not present network-only media as playable offline.
  });

  Future<void> cacheEntries(String profile, List<SourceEntry> entries) => database.transaction(() async {
    _writable(profile);
    for (final entry in entries) {
      await database.customStatement(
        'INSERT INTO entries (profile,source,id,parent,payload) VALUES (?,?,?,?,?) '
        'ON CONFLICT(profile,source,id) DO UPDATE SET parent=excluded.parent,payload=excluded.payload',
        [
          profile,
          entry.sourceId,
          entry.id,
          entry.parentId,
          jsonEncode(entry.toJson()),
        ],
      );
    }
  });

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

  Future<void> markScannedEntries(String profile, int generation, List<SourceEntry> entries) => database.transaction(() async {
    _writable(profile);
    for (final entry in entries) {
      await database.customStatement(
        'UPDATE entries SET scan_generation=? WHERE profile=? AND source=? AND id=?',
        [generation, profile, entry.sourceId, entry.id],
      );
    }
  });

  Future<void> finishSourceScan(
    String profile,
    String source,
    int generation, {
    required bool Function() isCurrent,
  }) =>
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
          for (final row in await database
              .customSelect('SELECT key,fingerprint FROM downloads WHERE profile=? AND complete=1', variables: [Variable(profile)])
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
            await database.customStatement('DELETE FROM entries WHERE profile=? AND source=? AND id=?', [profile, source, id]);
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
    final rows = await database
        .customSelect('SELECT payload FROM entries WHERE ${predicates.join(' AND ')}', variables: variables)
        .get();
    return rows
        .map((r) => SourceEntry.fromJson(sourceMap(jsonDecode(r.read<String>('payload')))))
        .where(
          (e) =>
              (source == null || e.sourceId == source) &&
              (!filterParent ||
                  (parent == null ? e.parentId == null || e.parentId!.isEmpty : e.parentId == parent)) &&
              (query == null ||
                  '${e.title} ${e.author} ${e.narrator} ${e.series}'.toLowerCase().contains(query.toLowerCase())),
        )
        .toList();
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
      final rows = await database.customSelect(
        'SELECT payload FROM progress WHERE profile=? AND entry IN ($placeholders) ORDER BY rowid DESC',
        variables: [Variable(profile), ...chunk.map((key) => Variable(key))],
      ).get();
      result.addAll(rows.map((row) => PublicationProgress.fromJson(sourceMap(jsonDecode(row.read<String>('payload'))))));
    }
    return result;
  }

  /// The caller carries the last committed revision. An old screen cannot
  /// overwrite a newer session or an explicit reset when its final tick lands.
  Future<PublicationProgress> saveProgress(String profile, PublicationProgress value, {String kind = 'position'}) =>
      database.transaction(() async {
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
  ) =>
      database.transaction(() async {
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
  }) {
    _writable(profile);
    return database.customStatement('INSERT OR REPLACE INTO downloads VALUES (?,?,?,?,?,?)', [
      profile,
      key,
      path,
      fingerprint,
      bytes,
      complete ? 1 : 0,
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


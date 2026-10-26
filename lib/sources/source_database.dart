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
  int get schemaVersion => 1;
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) async {
      for (final sql in [
        'CREATE TABLE sources (profile TEXT NOT NULL, id TEXT NOT NULL, config TEXT NOT NULL, credentials TEXT NOT NULL, PRIMARY KEY(profile,id))',
        'CREATE TABLE entries (profile TEXT NOT NULL, source TEXT NOT NULL, id TEXT NOT NULL, parent TEXT, payload TEXT NOT NULL, PRIMARY KEY(profile,source,id))',
        'CREATE TABLE progress (profile TEXT NOT NULL, key TEXT NOT NULL, payload TEXT NOT NULL, revision INTEGER NOT NULL, pending INTEGER NOT NULL DEFAULT 0, remote TEXT, PRIMARY KEY(profile,key))',
        'CREATE TABLE events (profile TEXT NOT NULL, id TEXT NOT NULL, key TEXT NOT NULL, payload TEXT NOT NULL, kind TEXT NOT NULL, created INTEGER NOT NULL, pending INTEGER NOT NULL, PRIMARY KEY(profile,id))',
        'CREATE INDEX events_pending ON events(profile,pending,created)',
        'CREATE TABLE annotations (profile TEXT NOT NULL, id TEXT NOT NULL, entry TEXT NOT NULL, payload TEXT NOT NULL, PRIMARY KEY(profile,id))',
        'CREATE TABLE downloads (profile TEXT NOT NULL, key TEXT NOT NULL, path TEXT NOT NULL, fingerprint TEXT NOT NULL, bytes INTEGER NOT NULL, complete INTEGER NOT NULL, PRIMARY KEY(profile,key))',
        'CREATE TABLE preferences (profile TEXT NOT NULL, key TEXT NOT NULL, payload TEXT NOT NULL, PRIMARY KEY(profile,key))',
      ]) {
        await customStatement(sql);
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
      for (final table in ['sources', 'entries', 'progress', 'events', 'annotations', 'downloads', 'preferences']) {
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
    await database.customStatement('DELETE FROM sources WHERE profile = ? AND id = ?', [profile, source]);
    // Retain downloaded entries and reading history. A disconnected source has
    // no credentials and cannot issue new network requests.
  });

  Future<void> cacheEntries(String profile, List<SourceEntry> entries) => database.transaction(() async {
    _writable(profile);
    for (final entry in entries) {
      await database.customStatement('INSERT OR REPLACE INTO entries VALUES (?,?,?,?,?)', [
        profile,
        entry.sourceId,
        entry.id,
        entry.parentId,
        jsonEncode(entry.toJson()),
      ]);
    }
  });
  Future<List<SourceEntry>> entries(String profile, {String? source, String? parent, String? query}) async {
    final rows = await database
        .customSelect('SELECT payload FROM entries WHERE profile = ?', variables: [Variable(profile)])
        .get();
    return rows
        .map((r) => SourceEntry.fromJson(sourceMap(jsonDecode(r.read<String>('payload')))))
        .where(
          (e) =>
              (source == null || e.sourceId == source) &&
              (parent == null || e.parentId == parent) &&
              (query == null ||
                  '${e.title} ${e.author} ${e.narrator} ${e.series}'.toLowerCase().contains(query.toLowerCase())),
        )
        .toList();
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
          'INSERT INTO progress(profile,key,payload,revision,pending) VALUES (?,?,?,?,1) '
          'ON CONFLICT(profile,key) DO UPDATE SET payload=excluded.payload,revision=excluded.revision,pending=1',
          [profile, next.key, payload, next.revision],
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
    await database.customStatement('INSERT INTO events VALUES (?,?,?,?,?,?,1)', [
      profile,
      _uuid.v4(),
      annotation.entryKey,
      jsonEncode(annotation.toJson()),
      'annotation',
      annotation.updatedAt,
    ]);
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

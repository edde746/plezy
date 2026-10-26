import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/sources/source_database.dart';
import 'package:plezy/sources/source_models.dart';
import 'package:plezy/sources/sync/publication_sync.dart';
import 'package:plezy/sources/sync/sync_document.dart';
import 'package:plezy/sources/sync/sync_store.dart';

class MemorySyncStore implements SyncStore {
  final files = <String, String>{};
  bool offline = false;
  Future<void> Function()? onRead;
  @override
  Future<List<SyncFile>> list(String namespace) async {
    if (offline) throw const SourceException(SourceFailure.unavailable);
    return files.keys.where((n) => n.contains(namespace)).map((n) => SyncFile(n, n)).toList();
  }

  @override
  Future<String> read(SyncFile file) async {
    await onRead?.call();
    return files[file.id]!;
  }

  @override
  Future<void> create(String name, String text) async {
    if (offline) throw const SourceException(SourceFailure.unavailable);
    files[name] = text;
  }

  @override
  Future<void> delete(SyncFile file) async {
    files.remove(file.id);
  }
}

void main() {
  const audio = PublicationFile(
    id: 'audio-id',
    name: 'book.m4b',
    mimeType: 'audio/mp4',
    size: 500000,
    revision: 'v1',
    durationMs: 300000,
  );
  const ebook = PublicationFile(
    id: 'epub-id',
    name: 'book.epub',
    mimeType: 'application/epub+zip',
    size: 1000,
    revision: 'v1',
  );
  final edition = sourceDigest(jsonEncode([audio.fingerprint]));
  late SourceRepository repoA, repoB;
  late PublicationSync a, b;
  late MemorySyncStore store;
  late PublicationSyncConfig config;
  const sourceA = FileSource(
    id: 'connection-A',
    profileId: 'profile-A',
    kind: FileSourceKind.googleDrive,
    name: 'Books',
  );
  const sourceB = FileSource(
    id: 'connection-B',
    profileId: 'profile-B',
    kind: FileSourceKind.googleDrive,
    name: 'My Drive',
  );
  const entryA = SourceEntry(
    sourceId: 'connection-A',
    id: 'same-provider-book',
    title: 'Book',
    kind: SourceItemKind.audiobook,
    files: [audio, ebook],
  );
  const entryB = SourceEntry(
    sourceId: 'connection-B',
    id: 'same-provider-book',
    title: 'Book',
    kind: SourceItemKind.audiobook,
    files: [audio, ebook],
  );
  String localKey(SourceEntry entry) =>
      PublicationProgress(entryKey: entry.key, edition: edition, mode: PublicationMode.listening, session: '').key;
  Future<void> position(
    SourceRepository repo,
    String profile,
    SourceEntry entry,
    int ms, {
    bool finished = false,
  }) async {
    final old = await repo.progress(profile, localKey(entry));
    await repo.saveProgress(
      profile,
      PublicationProgress(
        entryKey: entry.key,
        edition: edition,
        mode: PublicationMode.listening,
        session: 'session',
        revision: old?.revision ?? 0,
        positionMs: ms,
        filePositionMs: ms,
        fraction: ms / 300000,
        finished: finished,
      ),
    );
  }

  Future<int?> at(SourceRepository repo, String profile, SourceEntry entry) async =>
      (await repo.progress(profile, localKey(entry)))?.positionMs;
  Future<void> runA({Set<String> active = const {}, void Function()? check}) => a.run(
    profile: 'profile-A',
    sources: [sourceA],
    config: config,
    store: store,
    activeKeys: active,
    check: check ?? () {},
  );
  Future<void> runB() =>
      b.run(profile: 'profile-B', sources: [sourceB], config: config, store: store, activeKeys: {}, check: () {});
  setUp(() async {
    SourceRepository repo() =>
        SourceRepository(SourceDatabase(NativeDatabase.memory()), protect: (s) async => s, reveal: (s) async => s);
    repoA = repo();
    repoB = repo();
    a = PublicationSync(repoA);
    b = PublicationSync(repoB);
    store = MemorySyncStore();
    config = PublicationSyncConfig(sourceId: sourceA.id, code: SyncCipher.newCode());
    await repoA.cacheEntries('profile-A', [entryA]);
    await repoB.cacheEntries('profile-B', [entryB]);
  });
  tearDown(() async {
    await repoA.database.close();
    await repoB.database.close();
  });
  test('different local profile and connection IDs resume same provider edition', () async {
    await position(repoA, 'profile-A', entryA, 60000);
    await runA();
    expect(await repoA.pendingEvents('profile-A'), isEmpty);
    await runB();
    expect(await at(repoB, 'profile-B', entryB), 60000);
    expect(await repoB.allProgress('profile-A'), isEmpty);
    expect(store.files.values.join(), isNot(contains('same-provider-book')));
  });
  test('fresh device imports without manufacturing a competing zero position', () async {
    await position(repoA, 'profile-A', entryA, 100000);
    await runA();
    await runB();
    await runA();
    expect(a.conflicts, isEmpty);
    expect(b.conflicts, isEmpty);
  });
  test('explicit rewind and reset are propagated instead of taking max progress', () async {
    await position(repoA, 'profile-A', entryA, 200000);
    await runA();
    await runB();
    await position(repoB, 'profile-B', entryB, 0);
    await runB();
    await runA();
    expect(await at(repoA, 'profile-A', entryA), 0);
    expect(a.conflicts, isEmpty);
  });
  test('offline divergent positions require a choice, then all devices converge', () async {
    await position(repoA, 'profile-A', entryA, 100000);
    await runA();
    await runB();
    await position(repoA, 'profile-A', entryA, 200000);
    await position(repoB, 'profile-B', entryB, 150000);
    await runA();
    await runB();
    await runA();
    expect(a.conflicts.length, 1);
    expect(b.conflicts.length, 1);
    final conflict = b.conflicts.values.single;
    final chosen = conflict.values.firstWhere((v) => sourceMap(v.value['data'])['positionMs'] == 150000);
    await b.resolve(
      profile: 'profile-B',
      config: config,
      key: conflict.key,
      selected: chosen,
      sources: [sourceB],
      activeKeys: {},
      check: () {},
    );
    await runB();
    await runA();
    expect(a.conflicts, isEmpty);
    expect(await at(repoA, 'profile-A', entryA), 150000);
  });
  test('network failure retains local edits across service restart', () async {
    await position(repoA, 'profile-A', entryA, 42000);
    store.offline = true;
    await expectLater(runA(), throwsA(isA<SourceException>()));
    a = PublicationSync(repoA);
    store.offline = false;
    await runA();
    await runB();
    expect(await at(repoB, 'profile-B', entryB), 42000);
  });
  test('active player is never sought underneath; continued local playback conflicts', () async {
    await position(repoA, 'profile-A', entryA, 100000);
    await runA();
    await runB();
    await position(repoB, 'profile-B', entryB, 200000);
    await runB();
    await runA(active: {localKey(entryA)});
    expect(await at(repoA, 'profile-A', entryA), 100000);
    await position(repoA, 'profile-A', entryA, 110000);
    await runA();
    expect(a.conflicts.length, 1);
  });
  test('remote progress applies when paused player releases its cursor', () async {
    await position(repoA, 'profile-A', entryA, 100000);
    await runA();
    await runB();
    await position(repoB, 'profile-B', entryB, 200000);
    await runB();
    await runA(active: {localKey(entryA)});
    await runA();
    expect(await at(repoA, 'profile-A', entryA), 200000);
  });
  test('a tick arriving during pull cannot be overwritten by remote progress', () async {
    await position(repoA, 'profile-A', entryA, 100000);
    await runA();
    await runB();
    await position(repoB, 'profile-B', entryB, 200000);
    await runB();
    store.onRead = () async {
      store.onRead = null;
      await position(repoA, 'profile-A', entryA, 80000);
    };
    await runA();
    expect(a.conflicts.length, 1);
    expect(await at(repoA, 'profile-A', entryA), 80000);
  });
  test('bookmark deletion tombstones do not resurrect on an old device', () async {
    BookAnnotation note(bool deleted) => BookAnnotation(
      id: 'note-1',
      entryKey: entryA.key,
      edition: edition,
      mode: PublicationMode.listening,
      positionMs: 10000,
      fileIndex: 0,
      filePositionMs: 10000,
      note: 'Remember this',
      updatedAt: 1,
      deleted: deleted,
    );
    await repoA.saveAnnotation('profile-A', note(false));
    await runA();
    expect(await repoA.pendingEvents('profile-A'), isEmpty);
    await runB();
    final imported = (await repoB.annotations('profile-B', entryB.key)).single;
    expect(imported.note, 'Remember this');
    expect(imported.fileIndex, 0);
    expect(imported.filePositionMs, 10000);
    await repoA.saveAnnotation('profile-A', note(true));
    await runA();
    expect(await repoA.pendingEvents('profile-A'), isEmpty);
    await runB();
    await runA();
    expect(await repoB.annotations('profile-B', entryB.key), isEmpty);
    expect(a.conflicts, isEmpty);
  });
  test('offline bookmark edits coalesce and only the published snapshot is acknowledged', () async {
    BookAnnotation note(String text, int updatedAt) => BookAnnotation(
      id: 'note-queued',
      entryKey: entryA.key,
      edition: edition,
      mode: PublicationMode.listening,
      positionMs: 10000,
      fileIndex: 0,
      filePositionMs: 10000,
      note: text,
      updatedAt: updatedAt,
    );
    await repoA.saveAnnotation('profile-A', note('first draft', 1));
    await repoA.saveAnnotation('profile-A', note('final note', 2));
    final pending = await repoA.pendingEvents('profile-A');
    expect(pending.length, 1);
    expect(BookAnnotation.fromJson(sourceMap(jsonDecode(pending.single['payload'] as String))).note, 'final note');
    await runA();
    expect(await repoA.pendingEvents('profile-A'), isEmpty);
  });
  test('ebook and listening state coexist without conversion of percentage to time', () async {
    await position(repoA, 'profile-A', entryA, 60000);
    await repoA.saveProgress(
      'profile-A',
      PublicationProgress(
        entryKey: entryA.key,
        edition: ebook.fingerprint,
        mode: PublicationMode.reading,
        session: 'read',
        locator: const ReadingLocator(href: 'chapter.xhtml', cfi: 'epubcfi(/6/2)', progression: .5),
        fraction: .5,
      ),
    );
    await runA();
    await runB();
    final rows = await repoB.allProgress('profile-B');
    expect(rows.length, 2);
    expect(rows.firstWhere((p) => p.mode == PublicationMode.reading).locator!.cfi, 'epubcfi(/6/2)');
    expect(await at(repoB, 'profile-B', entryB), 60000);
  });
  test('replaced edition is retained remotely but never applied to changed media', () async {
    await position(repoA, 'profile-A', entryA, 60000);
    await runA();
    await repoB.cacheEntries('profile-B', [
      const SourceEntry(
        sourceId: 'connection-B',
        id: 'same-provider-book',
        title: 'Book',
        kind: SourceItemKind.audiobook,
        files: [PublicationFile(id: 'audio-id', name: 'book.m4b', mimeType: 'audio/mp4', size: 500000, revision: 'v2')],
      ),
    ]);
    await runB();
    expect(await repoB.allProgress('profile-B'), isEmpty);
  });
  test('retention only prunes own generations and keeps a recovery copy', () async {
    for (var i = 1; i <= 6; i++) {
      await position(repoA, 'profile-A', entryA, i * 1000);
      await runA();
    }
    expect(store.files.length, 2);
    await runB();
    final otherFiles = store.files.keys.toSet();
    await position(repoA, 'profile-A', entryA, 8000);
    await runA();
    expect(store.files.keys.any(otherFiles.contains), isTrue);
    expect(store.files.length, 3);
  });
  test('corrupt encrypted generation prevents publishing over unknown state', () async {
    await position(repoA, 'profile-A', entryA, 1000);
    await runA();
    final name = store.files.keys.single;
    store.files[name] = '{}';
    final before = store.files.length;
    await expectLater(runB(), throwsA(isA<SourceException>()));
    expect(store.files.length, before);
    expect(await repoB.allProgress('profile-B'), isEmpty);
  });
  test('profile retirement during pull cannot import or publish', () async {
    await position(repoB, 'profile-B', entryB, 5000);
    await runB();
    var valid = true;
    store.onRead = () async {
      valid = false;
    };
    await expectLater(
      runA(
        check: () {
          if (!valid) throw const SourceException(SourceFailure.cancelled);
        },
      ),
      throwsA(isA<SourceException>()),
    );
    expect(await repoA.allProgress('profile-A'), isEmpty);
    expect(store.files.length, 1);
  });
}

import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/sources/source_database.dart';
import 'package:plezy/sources/source_models.dart';

void main() {
  late SourceDatabase database;
  late SourceRepository repository;
  const entry = SourceEntry(sourceId: 'drive', id: 'book', title: 'A book', kind: SourceItemKind.ebook);
  PublicationProgress cursor({
    String edition = 'epub',
    PublicationMode mode = PublicationMode.reading,
    int position = 0,
  }) => PublicationProgress(
    entryKey: entry.key,
    edition: edition,
    mode: mode,
    session: 'session-a',
    positionMs: position,
  );
  setUp(() {
    database = SourceDatabase(NativeDatabase.memory());
    repository = SourceRepository(database, protect: (s) async => 'encrypted:$s', reveal: (s) async => s.substring(10));
  });
  tearDown(() async => database.close());
  test('public source configuration rejects URL credentials before storage', () async {
    for (final url in [
      'https://user:password@files.example/books',
      'https://files.example/books?access_token=secret',
      'https://files.example/books?code=one-use',
    ]) {
      final source = FileSource(id: 'bad', profileId: 'alice', kind: FileSourceKind.opds, name: 'Books', endpoint: url);
      await expectLater(repository.saveSource(source, {}), throwsA(isA<SourceException>()));
      expect(await repository.sources('alice'), isEmpty);
    }
  });
  test('source identifiers are not delimiter-concatenated identities', () {
    expect(sourceKey('a:b', 'c'), isNot(sourceKey('a', 'b:c')));
  });
  test('ebook, audio, editions and profiles have independent positions', () async {
    await repository.saveProgress('alice', cursor(position: 10));
    await repository.saveProgress('alice', cursor(mode: PublicationMode.listening, position: 22000));
    await repository.saveProgress('alice', cursor(edition: 'pdf', position: 4));
    await repository.saveProgress('bob', cursor(position: 90));
    expect((await repository.progress('alice', cursor().key))!.positionMs, 10);
    expect((await repository.progress('alice', cursor(mode: PublicationMode.listening).key))!.positionMs, 22000);
    expect((await repository.progress('alice', cursor(edition: 'pdf').key))!.positionMs, 4);
    expect((await repository.progress('bob', cursor().key))!.positionMs, 90);
  });
  test('retired screen cannot overwrite explicit reset', () async {
    final first = await repository.saveProgress('alice', cursor(position: 12000));
    final reset = await repository.saveProgress('alice', first.copyWith(positionMs: 0, finished: false), kind: 'reset');
    await expectLater(
      repository.saveProgress('alice', first.copyWith(positionMs: 30000)),
      throwsA(isA<SourceException>()),
    );
    expect((await repository.progress('alice', first.key))!.positionMs, 0);
    expect(reset.revision, 2);
  });
  test('ack of an old snapshot never clears a newer pending snapshot', () async {
    final a = await repository.saveProgress('alice', cursor(position: 10000));
    final b = await repository.saveProgress('alice', a.copyWith(positionMs: 2000));
    await repository.acknowledge('alice', a.key, a.revision);
    expect(await repository.isPending('alice', a.key), isTrue);
    final pending = await repository.pendingEvents('alice');
    expect(pending.length, 1);
    expect(jsonDecode(pending.single['payload'] as String)['revision'], b.revision);
    await repository.acknowledge('alice', b.key, b.revision);
    expect(await repository.isPending('alice', b.key), isFalse);
  });
  test('removing connection removes encrypted credentials, retains history', () async {
    const source = FileSource(id: 'drive', profileId: 'alice', kind: FileSourceKind.googleDrive, name: 'Books');
    await repository.saveSource(source, {'accessToken': 'not-plaintext'});
    final raw = await database.customSelect('SELECT credentials FROM sources').getSingle();
    expect(raw.read<String>('credentials'), startsWith('encrypted:'));
    await repository.cacheEntries('alice', [entry]);
    await repository.saveProgress('alice', cursor());
    await repository.removeSource('alice', 'drive');
    expect(await repository.sources('alice'), isEmpty);
    expect(await repository.entries('alice'), hasLength(1));
    expect(await repository.progress('alice', cursor().key), isNotNull);
    await repository.updateCredentials(source, {'accessToken': 'late-refresh'});
    expect(await repository.sources('alice'), isEmpty);
  });
  test('annotation tombstone is durable and export omits deleted notes', () async {
    final note = BookAnnotation(
      id: 'note',
      entryKey: entry.key,
      edition: 'epub',
      mode: PublicationMode.reading,
      note: 'hello',
      updatedAt: 1,
    );
    await repository.saveAnnotation('alice', note);
    await repository.saveAnnotation(
      'alice',
      BookAnnotation.fromJson({...note.toJson(), 'deleted': true, 'updatedAt': 2}),
    );
    expect(await repository.annotations('alice', entry.key), isEmpty);
    final event = (await repository.pendingEvents('alice')).last;
    expect(jsonDecode(event['payload'] as String)['deleted'], isTrue);
  });
  test('unknown-duration multipart cursor preserves source and file time', () {
    final value = cursor(
      mode: PublicationMode.listening,
    ).copyWith(positionMs: 65000, filePositionMs: 5000, fileIndex: 1, speed: 1.75);
    final copy = PublicationProgress.fromJson(jsonDecode(jsonEncode(value.toJson())) as Map<String, dynamic>);
    expect(copy.positionMs, 65000);
    expect(copy.filePositionMs, 5000);
    expect(copy.fileIndex, 1);
    expect(copy.speed, 1.75);
  });
}

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/sources/source_database.dart';
import 'package:plezy/sources/source_models.dart';
import 'package:plezy/sources/source_video_session.dart';

import 'fixtures/memory_sources.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late SourceDatabase database;
  late MemorySources sources;
  const first = PublicationFile(id: 'one', name: 'One.mp4', mimeType: 'video/mp4', durationMs: 100000);
  const second = PublicationFile(id: 'two', name: 'Two.mp4', mimeType: 'video/mp4', durationMs: 100000);
  const entry = SourceEntry(
    sourceId: 'cloud',
    id: 'series',
    title: 'Videos',
    kind: SourceItemKind.video,
    files: [first, second],
  );
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('source-shared-video-');
    database = SourceDatabase(NativeDatabase.memory());
    sources = MemorySources(SourceRepository(database), directory);
    for (final file in entry.files) {
      final local = File('${directory.path}/${sourceDigest('alice')}/${file.name}');
      await local.parent.create(recursive: true);
      await local.writeAsBytes([1, 2, 3]);
      await sources.repository.recordDownload(
        'alice',
        sourceKey(entry.sourceId, file.id),
        local.path,
        file.fingerprint,
        3,
      );
    }
  });
  tearDown(() async {
    sources.dispose();
    await database.close();
    await directory.delete(recursive: true);
  });

  test('downloaded multi-file videos resolve without an account or network and resume independently', () async {
    final session = await SourceVideoSession.open(sources, entry, entry.files);
    addTearDown(session.close);
    expect(session.items, hasLength(2));
    expect(session.items.first.serverId, isNull);
    final one = await session.resolve(session.items.first);
    expect(one.isLocal, isTrue);
    await one.onProgress!('paused', const Duration(seconds: 30), const Duration(seconds: 100));
    await Future.wait([one.release(), one.release()]);
    expect(one.isReleased, isTrue);
    final two = await session.resolve(session.items.last);
    expect(two.initialPosition, Duration.zero);
    final repeated = await session.resolve(session.items.first);
    expect(repeated.initialPosition, const Duration(seconds: 30));
    await session.close();
    expect(two.isReleased, isTrue);
    expect(repeated.isReleased, isTrue);
  });

  test('profile switches invalidate queued resolutions and prevent progress leakage', () async {
    final session = await SourceVideoSession.open(sources, entry, entry.files);
    addTearDown(session.close);
    final lease = await session.resolve(session.items.first);
    sources.profileId = 'bob';
    sources.generation++;
    await lease.onProgress!('paused', const Duration(seconds: 50), const Duration(seconds: 100));
    await expectLater(session.resolve(session.items.last), throwsA(isA<SourceException>()));
    expect(await sources.repository.allProgress('bob'), isEmpty);
    expect(await sources.repository.allProgress('alice'), isEmpty);
  });

  test('a session rejects files that do not belong to its entry', () async {
    const foreign = PublicationFile(id: 'other', name: 'Other.mp4', mimeType: 'video/mp4');
    await expectLater(SourceVideoSession.open(sources, entry, [foreign]), throwsA(isA<SourceException>()));
  });
}

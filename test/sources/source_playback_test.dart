import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/sources/source_database.dart';
import 'package:plezy/sources/source_models.dart';
import 'package:plezy/sources/source_playback.dart';
import '../services/music/music_playback_service_test.dart' show FakePlayer, FakeMediaControlsManager;
import 'fixtures/memory_sources.dart';

class _Controls extends FakeMediaControlsManager {
  @override
  Future<void> setBackgroundMode(bool enabled) async {}
  @override
  Future<void> updateFileMetadata({
    required String title,
    String? author,
    String? album,
    Duration? duration,
    Uint8List? artwork,
  }) async {
    metadataTitles.add(title);
  }
}

class _FailingStopPlayer extends FakePlayer {
  @override
  Future<void> stop() async => throw StateError('native stop failure');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late SourceDatabase db;
  late MemorySources sources;
  late SourcePlayback playback;
  late FakePlayer native;
  late _Controls controls;
  const first = PublicationFile(id: 'one', name: '01.m4b', mimeType: 'audio/mp4', durationMs: 180000);
  const second = PublicationFile(id: 'two', name: '02.m4b', mimeType: 'audio/mp4', durationMs: 180000);
  const item = SourceEntry(
    sourceId: 'cloud',
    id: 'book',
    title: 'A book',
    kind: SourceItemKind.audiobook,
    files: [first, second],
  );
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('plezy-source-playback-');
    db = SourceDatabase(NativeDatabase.memory());
    sources = MemorySources(SourceRepository(db), directory);
    native = FakePlayer();
    controls = _Controls();
    playback = SourcePlayback(
      sources,
      playerFactory: (_) => native,
      controlsFactory: () => controls,
      wakelockToggle: (_) async {},
    );
  });
  tearDown(() async {
    await playback.stop();
    playback.dispose();
    await playback.stop();
    controls.closeControllers();
    sources.dispose();
    await db.close();
    await directory.delete(recursive: true);
  });
  Future<void> start() => playback.start(
    item,
    item.audio,
    localOverrides: {'one': Uri.file('${directory.path}/one'), 'two': Uri.file('${directory.path}/two')},
  );
  test('duplicate completion advances one part and persists source-relative resume', () async {
    await start();
    expect(controls.metadataTitles, contains('A book'));
    native.setPosition(const Duration(seconds: 179));
    native.emitCompleted();
    native.emitCompleted();
    await playback.pause(); // Serialize behind completion delivery.
    expect(native.openedUris.length, 2);
    expect(native.openedUris.last, endsWith('/two'));
    native.setPosition(const Duration(seconds: 12));
    await playback.pause();
    final stored = (await db.customSelect('SELECT payload FROM progress').get()).single;
    expect(stored.data.toString(), contains('192000'));
    expect(playback.progress!.filePositionMs, 12000);
    expect(playback.progress!.fileIndex, 1);
  });
  test('explicit reset cannot be overwritten by a late player tick', () async {
    await start();
    native.setPosition(const Duration(seconds: 40));
    await playback.pause();
    final reset = await sources.repository.saveProgress(
      'alice',
      playback.progress!.copyWith(positionMs: 0, filePositionMs: 0, fraction: 0),
      kind: 'reset',
    );
    native.setPosition(const Duration(seconds: 50));
    await playback.pause();
    expect(playback.failure, SourceFailure.conflict);
    expect((await sources.repository.progress('alice', reset.key))!.positionMs, 0);
  });
  test('profile retirement blocks playback commands and releases player', () async {
    await start();
    sources.generation++;
    sources.profileId = 'bob';
    final opened = native.openedUris.length;
    native.emitCompleted();
    await playback.play();
    expect(native.openedUris.length, opened);
    await playback.stop();
    expect(native.disposed, isTrue);
    expect(playback.active, isFalse);
    expect(await sources.repository.allProgress('bob'), isEmpty);
  });
  test('native stop failure still disposes the session and clears ownership', () async {
    native = _FailingStopPlayer();
    await start();
    await expectLater(playback.stop(), throwsStateError);
    expect(native.disposed, isTrue);
    expect(playback.player, isNull);
    expect(playback.active, isFalse);
    expect(playback.files, isEmpty);
  });
  test('finished book restarts explicitly with new progress revision', () async {
    await start();
    await playback.pause();
    final progress = playback.progress!;
    await playback.stop();
    final latest = (await sources.repository.progress('alice', progress.key))!;
    await sources.repository.saveProgress(
      'alice',
      latest.copyWith(positionMs: 360000, fileIndex: 1, filePositionMs: 180000, finished: true),
    );
    native = FakePlayer();
    controls = _Controls();
    await start();
    expect(playback.progress!.finished, isFalse);
    expect(playback.progress!.positionMs, 0);
    expect(native.openStarts.single, Duration.zero);
  });
}

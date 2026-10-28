import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/playback_coordinator.dart';
import 'package:plezy/mpv/player/player_state.dart';
import 'package:plezy/sources/source_database.dart';
import 'package:plezy/sources/source_models.dart';
import 'package:plezy/sources/source_playback.dart';

import '../services/music/music_playback_service_test.dart' show FakePlayer, FakeMediaControlsManager;
import 'fixtures/memory_sources.dart';

class _Controls extends FakeMediaControlsManager {
  bool? canSeek;
  bool? canSkip;

  @override
  Future<void> setBackgroundMode(bool enabled) async {}

  @override
  Future<void> setControlsEnabled({
    bool canPlayPause = false,
    bool canGoNext = false,
    bool canGoPrevious = false,
    bool canSeek = false,
    bool canStop = false,
    bool canSkip = false,
    bool canSetSpeed = false,
    bool preferSkipOverTrackButtons = false,
    Duration? skipInterval,
  }) async {
    this.canSeek = canSeek;
    this.canSkip = canSkip;
  }

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

class _RecordingMpvPlayer extends FakePlayer {
  final properties = <String, String>{};
  final propertyWrites = <(String, String)>[];

  @override
  String get playerType => 'mpv';

  @override
  PlayerState get state => super.state.copyWith(seekable: true);

  @override
  Future<void> setProperty(String name, String value) async {
    propertyWrites.add((name, value));
    properties[name] = value;
  }

  @override
  Future<String?> getProperty(String name) async => properties[name];
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
    PlaybackCoordinator.instance
      ..setWorkspaceVideoSessionCount(0)
      ..setWorkspaceVideoPlayerSlots(const []);
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
    PlaybackCoordinator.instance
      ..setWorkspaceVideoSessionCount(0)
      ..setWorkspaceVideoPlayerSlots(const []);
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
  Future<_RecordingMpvPlayer> startLiveVideo() async {
    final player = _RecordingMpvPlayer();
    native = player;
    const liveFile = PublicationFile(id: 'live-recording', name: 'Live.ts', mimeType: 'video/mp2t', streamOnly: true);
    const liveEntry = SourceEntry(
      sourceId: 'open:session',
      id: 'live-session',
      title: 'Live channel',
      kind: SourceItemKind.video,
      files: [liveFile],
    );
    await playback.start(
      liveEntry,
      const [liveFile],
      playbackMode: PublicationMode.watching,
      localOverrides: {'live-recording': Uri.parse('https://radio.example/live.ts')},
      persistProgress: false,
      liveInput: true,
    );
    return player;
  }

  test('retry preserves the last reliable position after decoder reset and EOF', () async {
    await start();
    native.setPosition(const Duration(seconds: 47));
    native.setPosition(Duration.zero);
    native.emitError('stream failed');
    native.emitCompleted();
    await playback.pause();
    expect(playback.canRetry, isTrue);
    expect(playback.currentFilePositionMs, 47000);
    expect(playback.progress!.filePositionMs, 47000);
    expect(playback.progress!.finished, isFalse);
    expect(native.openedUris, hasLength(1));
    await playback.retry();
    expect(native.openedUris, hasLength(2));
    expect(native.openedUris.last, native.openedUris.first);
    expect(native.openStarts.last, const Duration(seconds: 47));
    expect(playback.failure, isNull);
    expect(playback.currentFilePositionMs, 47000);
  });

  test('an intentional seek to zero remains zero after failure', () async {
    await start();
    native.setPosition(const Duration(seconds: 47));
    await playback.seek(0);
    native.emitError('stream failed');
    await playback.retry();
    expect(native.openStarts.last, Duration.zero);
  });

  test('retry is inert after the source profile changes', () async {
    await start();
    native.setPosition(const Duration(seconds: 47));
    native.emitError('stream failed');
    sources.generation++;
    await playback.retry();
    expect(native.openedUris, hasLength(1));
    expect(playback.canRetry, isFalse);
  });

  test('transient live media disables seeking and never persists progress', () async {
    const liveFile = PublicationFile(
      id: 'live',
      name: 'public-stream.m3u8',
      mimeType: 'application/vnd.apple.mpegurl',
      streamOnly: true,
    );
    const liveEntry = SourceEntry(
      sourceId: 'open:session',
      id: 'session',
      title: 'Live radio',
      kind: SourceItemKind.video,
      files: [liveFile],
    );

    await playback.start(
      liveEntry,
      const [liveFile],
      playbackMode: PublicationMode.watching,
      localOverrides: {'live': Uri.parse('https://radio.example/live.m3u8')},
      persistProgress: false,
      liveInput: true,
    );

    expect(playback.isTransientInput, isTrue);
    expect(playback.isLiveInput, isTrue);
    expect(playback.progress, isNotNull);
    expect(controls.canSeek, isFalse);
    expect(controls.canSkip, isFalse);

    await playback.seek(30000);
    await playback.skip(30);
    expect(native.seeks, isEmpty);

    native.setPosition(const Duration(seconds: 20));
    await playback.pause();
    expect(await sources.repository.allProgress('alice'), isEmpty);
  });
  test('live MPV recording writes privately, then publishes the finished file on stop', () async {
    final player = await startLiveVideo();
    final target = File('${directory.path}/recording.mkv');

    await playback.startStreamRecording(target, replaceExisting: false);

    expect(playback.isRecordingStream, isTrue);
    final partialPath = player.properties['file-local-options/stream-record']!;
    final partial = File(partialPath);
    expect(partial.parent.path, directory.path);
    expect(partial.uri.pathSegments.last, startsWith('.recording.plezy-recording-'));
    await partial.writeAsBytes([1, 2, 3]);

    expect((await playback.stopStreamRecording())?.path, target.path);
    expect(await target.readAsBytes(), [1, 2, 3]);
    expect(playback.isRecordingStream, isFalse);
    expect(partial.existsSync(), isFalse);
    expect(player.propertyWrites, [
      ('file-local-options/stream-record', partial.path),
      ('file-local-options/stream-record', ''),
    ]);
  });
  test('live recording preserves an existing file without consent and restores it after empty output', () async {
    final player = await startLiveVideo();
    final target = File('${directory.path}/recording.ts')..writeAsBytesSync([9, 8, 7]);

    await expectLater(
      playback.startStreamRecording(target, replaceExisting: false),
      throwsA(isA<SourceException>().having((error) => error.reason, 'reason', SourceFailure.conflict)),
    );
    expect(await target.readAsBytes(), [9, 8, 7]);

    await playback.startStreamRecording(target, replaceExisting: true);
    final partial = File(player.properties['file-local-options/stream-record']!);
    expect(target.existsSync(), isFalse);
    await partial.writeAsBytes(const []);

    await expectLater(
      playback.stopStreamRecording(),
      throwsA(isA<SourceException>().having((error) => error.reason, 'reason', SourceFailure.invalidData)),
    );
    expect(await target.readAsBytes(), [9, 8, 7]);
    expect(partial.existsSync(), isFalse);
    expect(playback.isRecordingStream, isFalse);
    expect(playback.active, isTrue);
  });
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
  test('source video retains its native slot until the player is disposed', () async {
    await playback.start(
      item,
      [first],
      playbackMode: PublicationMode.watching,
      localOverrides: {'one': Uri.file('${directory.path}/one')},
    );

    expect(playback.videoPlayerSlot, VideoPlayerSlot.primary);
    expect(PlaybackCoordinator.instance.nextVideoPlayerSlot, VideoPlayerSlot.companion);

    await playback.stop();

    expect(playback.videoPlayerSlot, isNull);
    expect(PlaybackCoordinator.instance.nextVideoPlayerSlot, VideoPlayerSlot.primary);
  });
  test('source companion video starts muted and excluded from native audio focus', () async {
    PlaybackCoordinator.instance
      ..setWorkspaceVideoSessionCount(1)
      ..setWorkspaceVideoPlayerSlots(const [VideoPlayerSlot.primary]);

    await playback.start(
      item,
      [first],
      playbackMode: PublicationMode.watching,
      localOverrides: {'one': Uri.file('${directory.path}/one')},
    );

    expect(playback.videoPlayerSlot, VideoPlayerSlot.companion);
    expect(native.audioFocusEnabled, isFalse);
    expect(native.volumes.first, 0);
  });
  test('end-of-chapter sleep stops at the boundary and does not advance to the next part', () async {
    await start();
    playback.sleepAfterChapter();
    expect(playback.sleepEnabled, isTrue);
    native.setPosition(const Duration(minutes: 3));
    await playback.pause();
    expect(playback.sleepEnabled, isFalse);
    expect(playback.playing, isFalse);
    native.emitCompleted();
    await playback.pause();
    expect(native.openedUris, hasLength(1));
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

  test('capture preview opens only the validated device address as a live transient item', () async {
    final capturePlayer = _RecordingMpvPlayer();
    native = capturePlayer;
    const captureFile = PublicationFile(
      id: 'desktop',
      name: 'Desktop screen',
      mimeType: 'video/avdevice',
      streamOnly: true,
    );
    const captureEntry = SourceEntry(
      sourceId: 'open:capture:test',
      id: 'capture-test',
      title: 'Desktop screen',
      kind: SourceItemKind.video,
      files: [captureFile],
    );

    await playback.start(
      captureEntry,
      const [captureFile],
      playbackMode: PublicationMode.watching,
      persistProgress: false,
      liveInput: true,
      directPlayerAddresses: const {'desktop': 'av://x11grab::0.0+0,0'},
      localPlayerOptions: const {'demuxer-lavf-format': 'x11grab', 'demuxer-lavf-o': 'framerate=30,draw_mouse=1'},
    );

    expect(playback.isCapturePreview, isTrue);
    expect(playback.isTransientInput, isTrue);
    expect(playback.isLiveInput, isTrue);
    expect(capturePlayer.propertyWrites, [
      ('file-local-options/demuxer-lavf-format', 'x11grab'),
      ('file-local-options/demuxer-lavf-o', 'framerate=30,draw_mouse=1'),
    ]);
    expect(native.openedUris, ['av://x11grab::0.0+0,0']);
    expect(controls.canSeek, isFalse);
    expect(await sources.repository.allProgress('alice'), isEmpty);
  }, skip: !(Platform.isWindows || Platform.isLinux || Platform.isMacOS));

  test('capture preview rejects arbitrary MPV input options before opening a device', () async {
    final capturePlayer = _RecordingMpvPlayer();
    native = capturePlayer;
    const captureFile = PublicationFile(id: 'desktop', name: 'Desktop screen', mimeType: 'video/avdevice');
    const captureEntry = SourceEntry(
      sourceId: 'open:capture:test',
      id: 'capture-test',
      title: 'Desktop screen',
      kind: SourceItemKind.video,
      files: [captureFile],
    );

    await expectLater(
      playback.start(
        captureEntry,
        const [captureFile],
        playbackMode: PublicationMode.watching,
        persistProgress: false,
        liveInput: true,
        directPlayerAddresses: const {'desktop': 'av://x11grab::0.0+0,0'},
        localPlayerOptions: const {'demuxer-lavf-format': 'x11grab', 'demuxer-lavf-o': 'framerate=30,format=anything'},
      ),
      throwsA(isA<SourceException>().having((error) => error.reason, 'reason', SourceFailure.unsupported)),
    );
    expect(capturePlayer.propertyWrites, isEmpty);
    expect(capturePlayer.openedUris, isEmpty);
  }, skip: !(Platform.isWindows || Platform.isLinux || Platform.isMacOS));

  test('local video bookmark identity hashes the file URI and is available only while seekable', () async {
    native = _RecordingMpvPlayer();
    const videoFile = PublicationFile(
      id: 'local-movie',
      name: 'A movie.mkv',
      mimeType: 'video/x-matroska',
      durationMs: 180000,
    );
    const videoEntry = SourceEntry(
      sourceId: 'open:session',
      id: 'local-movie',
      title: 'A movie',
      kind: SourceItemKind.video,
      files: [videoFile],
    );
    final uri = Uri.file('${directory.path}/private-movie.mkv');

    await playback.start(
      videoEntry,
      const [videoFile],
      playbackMode: PublicationMode.watching,
      persistProgress: false,
      localOverrides: {'local-movie': uri},
    );

    final key = playback.localMediaBookmarkKey;
    expect(key, startsWith('open-media:'));
    expect(key, isNot(contains(directory.path)));
    expect(key, isNot(contains('private-movie')));
    expect(playback.isLiveInput, isFalse);
  });

  test('seekable transient audio uses an opaque bookmark key and live audio does not', () async {
    native = _RecordingMpvPlayer();
    const audioFile = PublicationFile(
      id: 'local-track',
      name: 'A track.m4a',
      mimeType: 'audio/mp4',
      durationMs: 180000,
    );
    const audioEntry = SourceEntry(
      sourceId: 'open:session',
      id: 'local-track',
      title: 'A track',
      kind: SourceItemKind.music,
      files: [audioFile],
    );
    final uri = Uri.file('${directory.path}/private-track.m4a');

    await playback.start(
      audioEntry,
      const [audioFile],
      playbackMode: PublicationMode.listening,
      persistProgress: false,
      localOverrides: {'local-track': uri},
    );

    final key = playback.localMediaBookmarkKey;
    expect(key, startsWith('open-media:'));
    expect(key, isNot(contains(directory.path)));
    expect(key, isNot(contains('private-track')));

    await playback.stop();
    native = _RecordingMpvPlayer();
    await playback.start(
      audioEntry,
      const [audioFile],
      playbackMode: PublicationMode.listening,
      persistProgress: false,
      liveInput: true,
      localOverrides: {'local-track': Uri.parse('https://radio.example/live.m4a')},
    );
    expect(playback.localMediaBookmarkKey, isNull);
  });

  test('local queue export returns safe sibling entries and refuses a mixed folder', () async {
    const firstVideo = PublicationFile(id: 'one', name: 'First.mkv', mimeType: 'video/x-matroska');
    const secondVideo = PublicationFile(id: 'two', name: 'Second.mkv', mimeType: 'video/x-matroska');
    const videoEntry = SourceEntry(
      sourceId: 'local',
      id: 'local-set',
      title: 'A local set',
      kind: SourceItemKind.video,
      files: [firstVideo, secondVideo],
    );
    final firstFile = File('${directory.path}/First.mkv')..writeAsBytesSync([1]);
    final secondFile = File('${directory.path}/Second.mkv')..writeAsBytesSync([2]);

    await playback.start(
      videoEntry,
      const [firstVideo, secondVideo],
      playbackMode: PublicationMode.watching,
      persistProgress: false,
      localOverrides: {'one': firstFile.uri, 'two': secondFile.uri},
    );

    expect(playback.canExportLocalPlaylist, isTrue);
    final entries = await playback.localPlaylistExportItems();
    expect(entries?.map((item) => item.title), ['First.mkv', 'Second.mkv']);
    expect(entries?.map((item) => item.uri), [firstFile.uri, secondFile.uri]);

    final otherDirectory = Directory('${directory.path}/other')..createSync();
    final other = File('${otherDirectory.path}/Second.mkv')..writeAsBytesSync([2]);
    await playback.start(
      videoEntry,
      const [firstVideo, secondVideo],
      playbackMode: PublicationMode.watching,
      persistProgress: false,
      localOverrides: {'one': firstFile.uri, 'two': other.uri},
    );
    expect(playback.canExportLocalPlaylist, isFalse);
    expect(await playback.localPlaylistExportItems(), isNull);
  }, skip: !(Platform.isWindows || Platform.isLinux || Platform.isMacOS));
}

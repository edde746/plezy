import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/music/music_output.dart';
import 'package:plezy/services/music/music_output_controller.dart';
import 'package:plezy/services/music/music_playback_service.dart';
import 'package:plezy/services/music/routed_music_playback_service.dart';
import 'package:plezy/services/playback_launch_observer.dart';
import 'package:plezy/services/settings_service.dart';

import '../../test_helpers/prefs.dart';
import '../../test_helpers/stub_music_playback_service.dart';

class _RecordingEngine extends StubMusicPlaybackService {
  _RecordingEngine(this.label);

  final String label;
  final List<String> calls = [];
  final StreamController<Duration> positions = StreamController<Duration>.broadcast();
  final StreamController<Object> failures = StreamController<Object>.broadcast();
  final ValueNotifier<double> _volume = ValueNotifier<double>(50);
  MusicPlaybackStatus _status = MusicPlaybackStatus.idle;
  bool disposed = false;
  List<MediaItem> tracks = const [];
  int index = -1;
  Duration at = Duration.zero;

  /// Puts this engine mid-queue, as if the user had been listening on it.
  void listening(List<MediaItem> queue, {required int index, required Duration at, bool playing = true}) {
    tracks = queue;
    this.index = index;
    this.at = at;
    _status = playing ? MusicPlaybackStatus.playing : MusicPlaybackStatus.paused;
  }

  @override
  MusicPlaybackStatus get status => _status;

  @override
  List<MediaItem> get queue => tracks;

  @override
  int get currentIndex => index;

  @override
  MediaItem? get currentTrack => index < 0 ? null : tracks[index];

  @override
  Duration get position => at;

  @override
  Stream<Duration> get positionStream => positions.stream;

  @override
  Stream<Object> get errors => failures.stream;

  @override
  double get volume => _volume.value;

  @override
  ValueListenable<double> get volumeListenable => _volume;

  @override
  Future<void> play() async => calls.add('play');

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> next() async => calls.add('next');

  @override
  Future<void> seek(Duration position) async => calls.add('seek:$position');

  @override
  Future<void> setVolume(double volume, {bool persist = true}) async {
    calls.add('volume:$volume');
    _volume.value = volume;
  }

  @override
  Future<void> playFromList({
    required List<MediaItem> tracks,
    MediaItem? startTrack,
    required MusicPlayContext playContext,
    bool shuffle = false,
    Duration? initialPosition,
    bool offline = false,
    PlaybackLaunchObserver? launchObserver,
  }) async {
    calls.add('playFromList:${tracks.length}');
    if (startTrack != null) calls.add('start:${startTrack.id}');
    this.tracks = tracks;
    index = tracks.isEmpty ? -1 : tracks.indexOf(startTrack ?? tracks.first);
    _status = MusicPlaybackStatus.playing;
    notifyListeners();
  }

  @override
  void setRepeatMode(MusicRepeatMode mode) => calls.add('repeat:${mode.name}');

  @override
  Future<void> stop() async {
    calls.add('stop');
    _status = MusicPlaybackStatus.idle;
    tracks = const [];
    index = -1;
  }

  @override
  void dispose() {
    disposed = true;
    positions.close();
    failures.close();
    _volume.dispose();
    super.dispose();
  }
}

void main() {
  late _RecordingEngine local;
  late List<_RecordingEngine> remotes;
  late MusicOutputController outputs;
  late RoutedMusicPlaybackService routed;

  const speaker = MusicOutput(
    id: 'ma-1|RINCON_1',
    name: 'Kitchen',
    available: true,
    serverId: 'ma-1',
    playerId: 'RINCON_1',
  );

  setUp(() async {
    resetSharedPreferencesForTest();
    local = _RecordingEngine('local');
    remotes = [];
    // No servers, so discovery finds only this device and the controller is
    // driven by `select` alone — which is exactly the routing seam under test.
    outputs = MusicOutputController(serverManager: MultiServerManager(), settingsLoader: SettingsService.getInstance);
    await outputs.start();
    routed = RoutedMusicPlaybackService(
      local: local,
      outputs: outputs,
      remoteFactory: (output) {
        final engine = _RecordingEngine(output.name);
        remotes.add(engine);
        return engine;
      },
    );
  });

  tearDown(() {
    routed.dispose();
    outputs.dispose();
  });

  test('starts on the local engine, so today\'s behaviour is unchanged', () {
    expect(routed.active, same(local));
    expect(routed.isRemote, isFalse);
    expect(routed.routedTo, MusicOutput.thisDevice);
  });

  test('forwards every call to the active engine', () async {
    await routed.play();
    await routed.pause();
    await routed.next();
    await routed.seek(const Duration(seconds: 9));
    await routed.setVolume(30);
    expect(local.calls, ['play', 'pause', 'next', 'seek:0:00:09.000000', 'volume:30.0']);
  });

  test('picking a speaker swaps the engine underneath the same service object', () async {
    final identityBefore = identityHashCode(routed);
    await outputs.select(speaker);
    await pumpEventQueue();

    expect(remotes, hasLength(1));
    expect(routed.active, same(remotes.single));
    expect(routed.isRemote, isTrue);
    expect(routed.routedTo, speaker);
    // The UI holds this by identity; a provider that rebuilt would tear down
    // the session instead of moving it.
    expect(identityHashCode(routed), identityBefore);
  });

  test('stops the outgoing engine, so audio never comes from two places', () async {
    await routed.playFromList(
      tracks: const [],
      playContext: const MusicPlayContext(title: 'x', kind: MusicPlayContextKind.album),
    );
    await outputs.select(speaker);
    await pumpEventQueue();
    expect(local.calls, contains('stop'));
  });

  test('after switching, calls reach the speaker and not the phone', () async {
    await outputs.select(speaker);
    await pumpEventQueue();
    local.calls.clear();
    await routed.play();
    expect(remotes.single.calls, contains('play'));
    expect(local.calls, isEmpty);
  });

  test('switching back to the phone stops the speaker', () async {
    await outputs.select(speaker);
    await pumpEventQueue();
    await outputs.select(MusicOutput.thisDevice);
    await pumpEventQueue();
    expect(remotes.single.calls, contains('stop'));
    expect(routed.active, same(local));
  });

  group('the queue follows the output', () {
    final album = [
      for (final id in ['1', '2', '3']) _plexTrack(id),
    ];

    test('a speaker handed back to the phone carries on from the same place on Plex', () async {
      await outputs.select(speaker);
      await pumpEventQueue();
      remotes.single.listening(album, index: 1, at: const Duration(seconds: 42));
      local.calls.clear();

      await outputs.select(MusicOutput.thisDevice);
      await pumpEventQueue();

      expect(remotes.single.calls, contains('stop'));
      expect(local.calls, ['playFromList:3', 'start:2', 'repeat:off', 'seek:0:00:42.000000']);
    });

    test('the phone handed to a speaker carries on there', () async {
      local.listening(album, index: 0, at: const Duration(minutes: 1));

      await outputs.select(speaker);
      await pumpEventQueue();

      expect(local.calls, contains('stop'));
      expect(remotes.single.calls, ['playFromList:3', 'start:1', 'repeat:off', 'seek:0:01:00.000000']);
    });

    test('a paused queue arrives paused', () async {
      local.listening(album, index: 2, at: const Duration(seconds: 30), playing: false);

      await outputs.select(speaker);
      await pumpEventQueue();

      expect(remotes.single.calls.last, 'pause');
    });

    test('a track just started starts over rather than seeking', () async {
      local.listening(album, index: 0, at: const Duration(seconds: 1));

      await outputs.select(speaker);
      await pumpEventQueue();

      expect(remotes.single.calls, isNot(contains(startsWith('seek'))));
    });

    test('a Music Assistant queue is not carried to the phone, which cannot play it', () async {
      await outputs.select(speaker);
      await pumpEventQueue();
      remotes.single.listening([_maTrack('1')], index: 0, at: const Duration(seconds: 42));
      local.calls.clear();

      await outputs.select(MusicOutput.thisDevice);
      await pumpEventQueue();

      expect(local.calls, isEmpty);
    });

    test('nothing playing, nothing carried', () async {
      await outputs.select(speaker);
      await pumpEventQueue();

      expect(remotes.single.calls, isEmpty);
    });
  });

  test('positions and errors follow the active engine', () async {
    final positions = <Duration>[];
    final failures = <Object>[];
    routed.positionStream.listen(positions.add);
    routed.errors.listen(failures.add);

    local.positions.add(const Duration(seconds: 1));
    await pumpEventQueue();
    expect(positions, [const Duration(seconds: 1)]);

    await outputs.select(speaker);
    await pumpEventQueue();

    // The old engine is detached: its events must not reach the UI any more.
    local.positions.add(const Duration(seconds: 99));
    remotes.single.positions.add(const Duration(seconds: 5));
    remotes.single.failures.add(StateError('speaker trouble'));
    await pumpEventQueue();

    expect(positions, [const Duration(seconds: 1), const Duration(seconds: 5)]);
    expect(failures, hasLength(1));
  });

  test('volume reflects the engine that is playing', () async {
    await outputs.select(speaker);
    await pumpEventQueue();
    await remotes.single.setVolume(12);
    await pumpEventQueue();
    expect(routed.volumeListenable.value, 12);
    expect(routed.volume, 12);
  });

  test('a change on the active engine is republished to the UI', () async {
    var notifications = 0;
    routed.addListener(() => notifications++);
    local.notifyListeners();
    expect(notifications, greaterThan(0));
  });

  test('disposing takes both engines with it', () async {
    await outputs.select(speaker);
    await pumpEventQueue();
    final remote = remotes.single;
    routed.dispose();
    expect(local.disposed, isTrue);
    expect(remote.disposed, isTrue);
    // The tearDown would otherwise dispose it twice.
    routed = RoutedMusicPlaybackService(
      local: _RecordingEngine('replacement'),
      outputs: outputs,
      remoteFactory: (_) => _RecordingEngine('unused'),
    );
  });
}

MediaItem _plexTrack(String id) =>
    MediaItem.plex(id: id, serverId: 'plex-1', kind: MediaKind.track, title: 'Track $id', durationMs: 200000);

MediaItem _maTrack(String id) => MediaItem(
  id: 'library://track/$id',
  backend: MediaBackend.musicAssistant,
  serverId: 'ma-1',
  kind: MediaKind.track,
  title: 'Track $id',
);

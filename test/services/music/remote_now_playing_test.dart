import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:os_media_controls/os_media_controls.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/device_adjustment_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/music/music_output.dart';
import 'package:plezy/services/music/music_output_controller.dart';
import 'package:plezy/services/music/music_playback_service.dart';
import 'package:plezy/services/music/remote_now_playing.dart';

import '../../test_helpers/stub_music_playback_service.dart';
import 'music_playback_service_test.dart' as music_fakes;

const _speaker = MusicOutput(id: 'srv|kitchen', name: 'Kitchen', serverId: 'srv', playerId: 'kitchen', available: true);

class _FakeOutputs extends MusicOutputController {
  _FakeOutputs(this._selected) : super(serverManager: MultiServerManager());

  MusicOutput _selected;

  @override
  MusicOutput get selected => _selected;

  void choose(MusicOutput output) {
    _selected = output;
    notifyListeners();
  }

  @override
  Future<void> refresh() async {}
}

class _FakeDevice extends DeviceAdjustmentService {
  _FakeDevice() : super(channel: const MethodChannel('test/none'));

  bool holding = false;

  @override
  Future<void> startNowPlayingKeepAlive() async => holding = true;

  @override
  Future<void> stopNowPlayingKeepAlive() async => holding = false;
}

class _FakePlayback extends StubMusicPlaybackService {
  MediaItem? track;
  MusicPlaybackStatus _status = MusicPlaybackStatus.idle;
  final List<String> calls = [];

  @override
  MediaItem? get currentTrack => track;

  @override
  MusicPlaybackStatus get status => _status;

  void set(MediaItem? next, MusicPlaybackStatus status) {
    track = next;
    _status = status;
    notifyListeners();
  }

  @override
  Future<void> togglePlayPause() async => calls.add('toggle');

  @override
  Future<void> next() async => calls.add('next');

  @override
  Future<void> pause() async => calls.add('pause');
}

MediaItem _track(String id) =>
    MediaItem.plex(id: id, serverId: 'plex-1', kind: MediaKind.track, title: 'Track $id', durationMs: 200000);

void main() {
  late _FakeOutputs outputs;
  late _FakePlayback playback;
  late _FakeDevice device;
  late music_fakes.FakeMediaControlsManager controls;

  setUp(() {
    outputs = _FakeOutputs(_speaker);
    playback = _FakePlayback();
    device = _FakeDevice();
    controls = music_fakes.FakeMediaControlsManager();
  });

  RemoteNowPlaying build() => RemoteNowPlaying(
    outputs: outputs,
    playback: playback,
    clientFor: (_) => null,
    device: device,
    controlsFactory: () => controls,
  )..start();

  test('a speaker playing claims the lock screen and the headphone controls', () {
    final nowPlaying = build();
    addTearDown(nowPlaying.dispose);
    expect(nowPlaying.isActive, isFalse, reason: 'nothing to show before a track');

    playback.set(_track('1'), MusicPlaybackStatus.playing);

    expect(nowPlaying.isActive, isTrue);
    expect(controls.metadataTitles, ['Track 1']);
    expect(device.holding, isTrue, reason: 'iOS only routes AirPods presses to an app playing audio');
  });

  test('an AirPods press reaches the speaker', () {
    final nowPlaying = build();
    addTearDown(nowPlaying.dispose);
    playback.set(_track('1'), MusicPlaybackStatus.playing);

    controls.eventsCtrl.add(const TogglePlayPauseEvent());
    controls.eventsCtrl.add(const NextTrackEvent());

    expect(playback.calls, ['toggle', 'next']);
  });

  test('a lock-screen stop pauses the speaker rather than clearing its queue', () {
    final nowPlaying = build();
    addTearDown(nowPlaying.dispose);
    playback.set(_track('1'), MusicPlaybackStatus.playing);

    controls.eventsCtrl.add(const StopEvent());

    expect(playback.calls, ['pause']);
  });

  test('playing on the phone leaves the controls to the local engine', () async {
    final nowPlaying = build();
    addTearDown(nowPlaying.dispose);
    playback.set(_track('1'), MusicPlaybackStatus.playing);

    outputs.choose(MusicOutput.thisDevice);
    await Future<void>.delayed(Duration.zero);

    expect(nowPlaying.isActive, isFalse);
    expect(controls.cleared, isTrue);
    expect(device.holding, isFalse);
  });

  test('a paused speaker keeps the session a while, then lets go', () {
    fakeAsync((async) {
      final nowPlaying = build();
      playback.set(_track('1'), MusicPlaybackStatus.playing);
      playback.set(_track('1'), MusicPlaybackStatus.paused);

      async.elapse(RemoteNowPlaying.pausedGrace - const Duration(seconds: 1));
      expect(device.holding, isTrue, reason: 'a press soon after pausing must still resume');

      async.elapse(const Duration(seconds: 2));
      expect(device.holding, isFalse, reason: 'a forgotten pause should not run audio all night');
      expect(nowPlaying.isActive, isTrue, reason: 'the lock screen still shows what is paused');

      playback.set(_track('1'), MusicPlaybackStatus.playing);
      expect(device.holding, isTrue);
      nowPlaying.dispose();
      async.flushMicrotasks();
    });
  });

  test('a new track updates the lock screen once', () {
    final nowPlaying = build();
    addTearDown(nowPlaying.dispose);
    playback.set(_track('1'), MusicPlaybackStatus.playing);
    playback.set(_track('1'), MusicPlaybackStatus.playing);
    playback.set(_track('2'), MusicPlaybackStatus.playing);

    expect(controls.metadataTitles, ['Track 1', 'Track 2']);
  });
}

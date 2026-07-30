import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:os_media_controls/os_media_controls.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/music/music_playback_service.dart';
import 'package:plezy/services/music/music_playback_service_impl.dart';
import 'package:plezy/utils/notification_permission.dart';
import 'package:plezy/utils/platform_detector.dart';

import '../../test_helpers/media_items.dart';
import 'music_playback_service_test.dart' as music_fakes;

MediaItem _track(String id) => testMediaItem(
  id: id,
  backend: MediaBackend.plex,
  kind: MediaKind.track,
  title: 'Track $id',
  durationMs: const Duration(minutes: 3).inMilliseconds,
  serverId: 'srv',
);

class _RecordingMediaControlsManager extends music_fakes.FakeMediaControlsManager {
  final List<bool> backgroundModeCalls = [];

  @override
  Future<void> setBackgroundMode(bool enabled) async {
    backgroundModeCalls.add(enabled);
  }
}

class _Harness {
  _Harness._(this.service, this.controls, this.players, this.serverManager);

  final MusicPlaybackServiceImpl service;
  final _RecordingMediaControlsManager controls;
  final List<music_fakes.FakePlayer> players;
  final MultiServerManager serverManager;

  music_fakes.FakePlayer get player => players.single;

  factory _Harness.create() {
    final controls = _RecordingMediaControlsManager();
    final players = <music_fakes.FakePlayer>[];
    final serverManager = MultiServerManager();
    final service = MusicPlaybackServiceImpl(
      serverManager: serverManager,
      resolver: music_fakes.FakeMusicSourceResolver(),
      audioPlayerFactory: () {
        final player = music_fakes.FakePlayer();
        players.add(player);
        return player;
      },
      mediaControlsFactory: () => controls,
      volumePersistenceWriter: (_) async {},
    );
    return _Harness._(service, controls, players, serverManager);
  }

  Future<void> start(List<MediaItem> tracks) async {
    await service.playFromList(
      tracks: tracks,
      playContext: const MusicPlayContext(title: 'Test', kind: MusicPlayContextKind.album),
    );
    await pumpEventQueue();
  }

  void dispose() {
    service.dispose();
    for (final player in players) {
      player.closeControllers();
    }
    controls.closeControllers();
    serverManager.dispose();
  }
}

void main() {
  // A real binding is required to drive lifecycle state, but the bodies below
  // stay plain `test()` so timers and `pumpEventQueue()` run on the real async
  // queue — inside `testWidgets` the fake-async zone never drains them.
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(TvDetectionService.debugReset);

  tearDown(() {
    TvDetectionService.debugReset();
  });

  test('play is refused while automotive lifecycle is not resumed', () async {
    TvDetectionService.debugSetAutomotiveOverride(true);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    final harness = _Harness.create();
    addTearDown(harness.dispose);
    addTearDown(() => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));

    await harness.start([_track('one')]);
    expect(harness.service.status, MusicPlaybackStatus.paused);
    expect(harness.player.state.playing, isFalse);

    await harness.service.play();

    expect(harness.player.playCalls, 0);
    expect(harness.player.state.playing, isFalse);
    expect(harness.service.status, MusicPlaybackStatus.paused);
    expect(harness.player.setNextCalls.where((media) => media != null), isEmpty);
  });

  test('media-session play is refused while automotive lifecycle is not resumed', () async {
    TvDetectionService.debugSetAutomotiveOverride(true);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    final harness = _Harness.create();
    addTearDown(harness.dispose);
    addTearDown(() => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));
    await harness.start([_track('one')]);

    harness.controls.eventsCtrl.add(const PlayEvent());
    await pumpEventQueue();

    expect(harness.player.playCalls, 0);
    expect(harness.player.state.playing, isFalse);
    expect(harness.service.status, MusicPlaybackStatus.paused);
  });

  test('background mode is explicitly disabled on automotive', () async {
    TvDetectionService.debugSetAutomotiveOverride(true);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    final harness = _Harness.create();
    addTearDown(harness.dispose);
    addTearDown(() => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));

    await harness.start([_track('one')]);

    expect(harness.controls.backgroundModeCalls, [false]);
  });

  test('playback remains unrestricted off automotive', () async {
    TvDetectionService.debugSetAutomotiveOverride(false);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    final harness = _Harness.create();
    addTearDown(harness.dispose);
    addTearDown(() => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));

    await harness.start([_track('one')]);
    expect(harness.player.state.playing, isTrue);
    expect(harness.service.status, MusicPlaybackStatus.playing);
    expect(harness.controls.backgroundModeCalls, [true]);

    await harness.service.pause();
    await harness.service.play();

    expect(harness.player.playCalls, 1);
    expect(harness.player.state.playing, isTrue);
    expect(harness.service.status, MusicPlaybackStatus.playing);
  });

  test('automotive lifecycle restriction pauses and clears the gapless arm', () async {
    TvDetectionService.debugSetAutomotiveOverride(true);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final harness = _Harness.create();
    addTearDown(harness.dispose);
    addTearDown(() => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));
    final second = _track('two');
    await harness.start([_track('one'), second]);
    expect(harness.player.armed?.uri, 'fake://${second.id}');

    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await pumpEventQueue();

    expect(harness.player.pauseCalls, greaterThanOrEqualTo(1));
    expect(harness.player.armed, isNull);
    expect(harness.player.state.playing, isFalse);
    expect(harness.service.status, MusicPlaybackStatus.paused);
  });

  test('a transition racing the automotive pause is adopted but cannot keep playing', () async {
    TvDetectionService.debugSetAutomotiveOverride(true);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final harness = _Harness.create();
    addTearDown(harness.dispose);
    addTearDown(() => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));
    final second = _track('two');
    await harness.start([_track('one'), second]);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    harness.player.emitTransition('fake://${second.id}');
    await pumpEventQueue();

    expect(harness.service.currentTrack?.id, second.id);
    expect(harness.service.status, MusicPlaybackStatus.paused);
    expect(harness.player.state.playing, isFalse);
    expect(harness.player.armed, isNull);
  });

  test('media-session stop remains unconditional while automotive playback is restricted', () async {
    TvDetectionService.debugSetAutomotiveOverride(true);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    final harness = _Harness.create();
    addTearDown(harness.dispose);
    addTearDown(() => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));
    await harness.start([_track('one')]);

    harness.controls.eventsCtrl.add(const StopEvent());
    await pumpEventQueue();

    expect(harness.service.status, MusicPlaybackStatus.idle);
    expect(harness.service.currentTrack, isNull);
    expect(harness.player.stopCalls, 1);
  });

  test('the gapless arm is restored once automotive restrictions lift', () async {
    TvDetectionService.debugSetAutomotiveOverride(true);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final harness = _Harness.create();
    addTearDown(harness.dispose);
    addTearDown(() => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));
    final second = _track('two');
    await harness.start([_track('one'), second]);
    expect(harness.player.armed?.uri, 'fake://${second.id}');

    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await pumpEventQueue();
    expect(harness.player.armed, isNull);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await pumpEventQueue();

    // Gapless playback survives the park-and-resume cycle, but parking must not
    // restart audio on its own.
    expect(harness.player.armed?.uri, 'fake://${second.id}');
    expect(harness.service.status, MusicPlaybackStatus.paused);
    expect(harness.player.state.playing, isFalse);
  });

  test('media-session pause still stops audio while automotive playback is restricted', () async {
    TvDetectionService.debugSetAutomotiveOverride(true);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final harness = _Harness.create();
    addTearDown(harness.dispose);
    addTearDown(() => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));
    await harness.start([_track('one')]);
    expect(harness.player.state.playing, isTrue);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await pumpEventQueue();
    final pausesAfterRestriction = harness.player.pauseCalls;

    // The router consumes a denied event, so gating `canControlPlayback` would
    // silently swallow this and leave the OS unable to stop audio.
    harness.controls.eventsCtrl.add(const PauseEvent());
    await pumpEventQueue();

    expect(harness.player.pauseCalls, greaterThan(pausesAfterRestriction));
    expect(harness.service.status, MusicPlaybackStatus.paused);
  });

  test('automotive never prompts for notifications, so first play keeps its intent', () async {
    TvDetectionService.debugSetAutomotiveOverride(true);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    NotificationPermission.debugReset();
    addTearDown(NotificationPermission.debugReset);
    addTearDown(() => NotificationPermission.debugRequestOverride = null);
    addTearDown(() => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));

    var prompts = 0;
    // A real prompt takes focus, which would leave the app not resumed and make
    // the gate open the track paused, silently dropping the user's play intent.
    NotificationPermission.debugRequestOverride = () async {
      prompts++;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    };

    final harness = _Harness.create();
    addTearDown(harness.dispose);
    await harness.start([_track('one')]);

    // Nothing to authorize: the foreground service never starts on a car.
    expect(prompts, 0);
    expect(harness.controls.backgroundModeCalls, [false]);
    expect(harness.player.state.playing, isTrue);
    expect(harness.service.status, MusicPlaybackStatus.playing);
  });

  test('other platforms still request the notification permission', () async {
    TvDetectionService.debugSetAutomotiveOverride(false);
    NotificationPermission.debugReset();
    addTearDown(NotificationPermission.debugReset);
    addTearDown(() => NotificationPermission.debugRequestOverride = null);

    var prompts = 0;
    NotificationPermission.debugRequestOverride = () async => prompts++;

    final harness = _Harness.create();
    addTearDown(harness.dispose);
    await harness.start([_track('one')]);
    await pumpEventQueue();

    expect(prompts, 1);
    expect(harness.controls.backgroundModeCalls, [true]);
  });
}

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:os_media_controls/os_media_controls.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/car_ux_restrictions_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/music/music_playback_service.dart';
import 'package:plezy/services/music/music_source_resolver.dart';
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

/// Holds a source resolve open, which is the window where the session reads
/// `loading` while the previous track is still coming out of the native player.
class _GatedResolver extends music_fakes.FakeMusicSourceResolver {
  Completer<void>? gate;

  @override
  Future<MusicSource> resolve(MediaItem track) async {
    await gate?.future;
    return super.resolve(track);
  }
}

class _Harness {
  _Harness._(this.service, this.controls, this.players, this.serverManager);

  final MusicPlaybackServiceImpl service;
  final _RecordingMediaControlsManager controls;
  final List<music_fakes.FakePlayer> players;
  final MultiServerManager serverManager;

  music_fakes.FakePlayer get player => players.single;

  factory _Harness.create({_GatedResolver? resolver}) {
    final controls = _RecordingMediaControlsManager();
    final players = <music_fakes.FakePlayer>[];
    final serverManager = MultiServerManager();
    final service = MusicPlaybackServiceImpl(
      serverManager: serverManager,
      resolver: resolver ?? music_fakes.FakeMusicSourceResolver(),
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
    CarUxRestrictionsService.debugSetOverride(null);
    CarUxRestrictionsService.instance.debugReset();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(CarUxRestrictionsService.channel, null);
  });

  /// Answers `getState` only once [gate] completes, so a test can open a track
  /// while the vehicle is still silent — the cold-start ordering that
  /// pre-seeded state cannot reproduce.
  void answerVehicleWhen(Completer<void> gate, {required bool restricted}) {
    CarUxRestrictionsService.instance.debugReset();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(CarUxRestrictionsService.channel, (call) async {
      if (call.method != 'getState') return null;
      await gate.future;
      return <String, Object?>{'supported': true, 'requiresDistractionOptimization': restricted};
    });
  }

  test('an open that beats the vehicle answer still ends up with background audio on', () async {
    TvDetectionService.debugSetAutomotiveOverride(true);
    final gate = Completer<void>();
    answerVehicleWhen(gate, restricted: false);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final harness = _Harness.create();
    addTearDown(harness.dispose);

    final started = harness.start([_track('one')]);
    await pumpEventQueue();
    expect(harness.controls.backgroundModeCalls, isEmpty, reason: 'the open waits for the vehicle');

    gate.complete();
    await started;
    await pumpEventQueue();

    expect(harness.controls.backgroundModeCalls.last, isTrue);
    expect(harness.player.state.playing, isTrue);
  });

  test('a vehicle answer arriving after the open reconfigures the live session', () async {
    TvDetectionService.debugSetAutomotiveOverride(true);
    // Never answers: the open times out into the lifecycle fallback, exactly as
    // a car whose service is not up yet behaves.
    answerVehicleWhen(Completer<void>(), restricted: false);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final harness = _Harness.create();
    addTearDown(harness.dispose);

    await harness.start([_track('one')]).timeout(const Duration(seconds: 10));
    expect(harness.controls.backgroundModeCalls.last, isFalse, reason: 'no signal yet: stay conservative');

    // The platform pushes its first verdict once the car service connects.
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      CarUxRestrictionsService.channel.name,
      CarUxRestrictionsService.channel.codec.encodeMethodCall(
        const MethodCall('onChanged', <String, Object?>{'supported': true, 'requiresDistractionOptimization': false}),
      ),
      (_) {},
    );
    await pumpEventQueue();

    expect(harness.controls.backgroundModeCalls.last, isTrue, reason: 'the live session must be reconfigured');
  });

  test('a session opened while the car service is still connecting still gets background audio', () async {
    TvDetectionService.debugSetAutomotiveOverride(true);
    CarUxRestrictionsService.instance.debugReset();
    // Production shape: `getState` answers immediately with "no verdict yet, one is coming", and the
    // real answer arrives later as a push. A cold start must not conclude the car is mute.
    binding.defaultBinaryMessenger.setMockMethodCallHandler(CarUxRestrictionsService.channel, (call) async {
      if (call.method != 'getState') return null;
      return <String, Object?>{'supported': false, 'pending': true, 'requiresDistractionOptimization': true};
    });
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final harness = _Harness.create();
    addTearDown(harness.dispose);

    final started = harness.start([_track('one')]);
    await pumpEventQueue();
    expect(harness.controls.backgroundModeCalls, isEmpty, reason: 'the open waits for the promised verdict');

    await binding.defaultBinaryMessenger.handlePlatformMessage(
      CarUxRestrictionsService.channel.name,
      CarUxRestrictionsService.channel.codec.encodeMethodCall(
        const MethodCall('onChanged', <String, Object?>{'supported': true, 'requiresDistractionOptimization': false}),
      ),
      (_) {},
    );
    await started;
    await pumpEventQueue();

    expect(harness.controls.backgroundModeCalls.last, isTrue);
    expect(harness.player.state.playing, isTrue);
  });

  test('a parked vehicle keeps music playing while the app is backgrounded', () async {
    // The review complaint: switching to navigation while parked killed audio,
    // because the old gate could not tell "parked" from "not in front".
    TvDetectionService.debugSetAutomotiveOverride(true);
    CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.unrestricted);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final harness = _Harness.create();
    addTearDown(harness.dispose);
    addTearDown(() => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));
    await harness.start([_track('one')]);
    expect(harness.player.state.playing, isTrue);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await pumpEventQueue();

    expect(harness.player.state.playing, isTrue);
    expect(harness.service.status, MusicPlaybackStatus.playing);
    expect(harness.controls.backgroundModeCalls, contains(true));
  });

  test('a driving vehicle stops music and parking again resumes it', () async {
    TvDetectionService.debugSetAutomotiveOverride(true);
    CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.unrestricted);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final harness = _Harness.create();
    addTearDown(harness.dispose);
    await harness.start([_track('one')]);
    expect(harness.player.state.playing, isTrue);

    CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.restricted);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await pumpEventQueue();
    expect(harness.player.state.playing, isFalse, reason: 'DD-2: driving must stop audio');

    CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.unrestricted);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(harness.player.state.playing, isTrue, reason: 'parking again resumes what driving stopped');
  });

  test('a pause taken during the drive is not undone by parking', () async {
    TvDetectionService.debugSetAutomotiveOverride(true);
    CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.unrestricted);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final harness = _Harness.create();
    addTearDown(harness.dispose);
    await harness.start([_track('one')]);

    CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.restricted);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await pumpEventQueue();
    expect(harness.player.state.playing, isFalse);

    // A steering-wheel pause, or an expiring sleep timer, while the vehicle is
    // already holding audio: the car no longer owns this pause.
    await harness.service.pause();

    CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.unrestricted);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await pumpEventQueue();

    expect(harness.player.state.playing, isFalse, reason: 'parking must not restart what someone deliberately stopped');
  });

  test('a car service restart does not silence a background track for good', () async {
    TvDetectionService.debugSetAutomotiveOverride(true);
    CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.unrestricted);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final harness = _Harness.create();
    addTearDown(harness.dispose);
    await harness.start([_track('one')]);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await pumpEventQueue();
    expect(harness.player.state.playing, isTrue, reason: 'parked background audio');

    // The car service dies: no verdict, so the lifecycle fallback stops the
    // backgrounded track.
    CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.unknown);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await pumpEventQueue();
    expect(harness.player.state.playing, isFalse);

    // It comes back and reports a parked vehicle. The gate stopped this track, so
    // the gate resumes it — the user never touched anything.
    CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.unrestricted);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await pumpEventQueue();

    expect(harness.player.state.playing, isTrue, reason: 'a transient service restart must not be permanent');
  });

  test('foregrounding during a car service outage does not forget who paused', () async {
    TvDetectionService.debugSetAutomotiveOverride(true);
    CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.unrestricted);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final harness = _Harness.create();
    addTearDown(harness.dispose);
    await harness.start([_track('one')]);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await pumpEventQueue();

    // The service dies, so the lifecycle fallback stops the backgrounded track.
    CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.unknown);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await pumpEventQueue();
    expect(harness.player.state.playing, isFalse);

    // The user opens Plezy again while the vehicle still cannot answer. Focus is
    // not a verdict, so nothing auto-starts here...
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(harness.player.state.playing, isFalse, reason: 'regaining focus is not a request to play');

    // ...but the gate still owns the pause, so the verdict resumes it.
    CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.unrestricted);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await pumpEventQueue();

    expect(harness.player.state.playing, isTrue);
  });

  test('a restriction landing mid-resume does not strand the track paused', () async {
    TvDetectionService.debugSetAutomotiveOverride(true);
    CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.unrestricted);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final harness = _Harness.create();
    addTearDown(harness.dispose);
    await harness.start([_track('one')]);

    CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.restricted);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await pumpEventQueue();
    expect(harness.player.state.playing, isFalse);

    // Parked again, but the resume is slow — and the car starts moving before it
    // lands, so `play()` refuses on the closed gate.
    final playGate = Completer<void>();
    harness.player.playGate = playGate;
    CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.unrestricted);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await pumpEventQueue();
    CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.restricted);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await pumpEventQueue();
    harness.player.playGate = null;
    playGate.complete();
    await pumpEventQueue();
    expect(harness.player.state.playing, isFalse, reason: 'driving again: it must not be playing');

    // Parking once more must still resume it: the gate never stopped owning this pause.
    CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.unrestricted);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await pumpEventQueue();

    expect(harness.player.state.playing, isTrue);
  });

  test('parking does not start a queue the user never played', () async {
    TvDetectionService.debugSetAutomotiveOverride(true);
    CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.unrestricted);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final harness = _Harness.create();
    addTearDown(harness.dispose);
    await harness.start([_track('one')]);

    CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.restricted);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await pumpEventQueue();
    expect(harness.player.state.playing, isFalse, reason: 'driving stopped the first track');

    // The user stops that session while still driving, then queues something else
    // without asking for playback: on an empty queue this parks on the first track.
    await harness.service.stop();
    harness.service.addToEnd([_track('two')]);
    await pumpEventQueue();
    // A new session builds its own player, so read the latest one.
    expect(harness.players.last.state.playing, isFalse);

    CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.unrestricted);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await pumpEventQueue();

    expect(harness.players.last.state.playing, isFalse, reason: 'the gate never stopped this queue');
    expect(harness.service.status, isNot(MusicPlaybackStatus.playing));
  });

  test('one driving transition pauses once, however many times it is reported', () async {
    TvDetectionService.debugSetAutomotiveOverride(true);
    CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.unrestricted);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final harness = _Harness.create();
    addTearDown(harness.dispose);
    await harness.start([_track('one')]);
    final pausesBefore = harness.player.pauseCalls;

    // A car reports the restriction push and its lifecycle states separately, and
    // the pause is slow: a second one launched meanwhile would clear the in-flight
    // flag out from under the first.
    final pauseGate = Completer<void>();
    harness.player.pauseGate = pauseGate;
    CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.restricted);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await pumpEventQueue();
    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await pumpEventQueue();

    expect(harness.player.pauseCalls - pausesBefore, 1, reason: 'the in-flight pause is the one that lands');

    harness.player.pauseGate = null;
    pauseGate.complete();
    await pumpEventQueue();
    expect(harness.player.state.playing, isFalse);
  });

  test('a lift arriving while the restriction pause is in flight still resumes', () async {
    TvDetectionService.debugSetAutomotiveOverride(true);
    CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.unrestricted);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final harness = _Harness.create();
    addTearDown(harness.dispose);
    await harness.start([_track('one')]);
    expect(harness.player.state.playing, isTrue);

    // Hold the pause the way a slow platform call would.
    final pauseGate = Completer<void>();
    harness.player.pauseGate = pauseGate;

    CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.restricted);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await pumpEventQueue();

    // Stop-and-go: parked again before the pause has even landed, so the lift
    // still reads the track as playing.
    CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.unrestricted);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await pumpEventQueue();

    harness.player.pauseGate = null;
    pauseGate.complete();
    await pumpEventQueue();

    expect(
      harness.player.state.playing,
      isTrue,
      reason: 'a pause landing after the lift must not leave a parked car silent',
    );
  });

  test('a vehicle that cannot report restrictions keeps the conservative opt-out', () async {
    TvDetectionService.debugSetAutomotiveOverride(true);
    CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.unknown);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final harness = _Harness.create();
    addTearDown(harness.dispose);
    await harness.start([_track('one')]);

    expect(harness.controls.backgroundModeCalls, isNot(contains(true)));
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

  test('driving silences audio that is still playing while the next source resolves', () async {
    TvDetectionService.debugSetAutomotiveOverride(true);
    CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.unrestricted);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final resolver = _GatedResolver();
    final harness = _Harness.create(resolver: resolver);
    addTearDown(harness.dispose);
    final second = _track('two');
    await harness.start([_track('one'), second]);
    expect(harness.player.state.playing, isTrue);

    // Skipping holds the session in `loading` until the source resolves, and the
    // previous track keeps sounding on the native player throughout.
    resolver.gate = Completer<void>();
    unawaited(harness.service.next());
    await pumpEventQueue();
    expect(harness.service.status, MusicPlaybackStatus.loading);
    expect(harness.player.state.playing, isTrue, reason: 'the old track is still audible');

    CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.restricted);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await pumpEventQueue();

    expect(harness.player.state.playing, isFalse, reason: 'DD-2: driving must stop audio, resolver or not');

    resolver.gate!.complete();
    await pumpEventQueue();
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

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/mpv/player/platform/player_android.dart';
import 'package:plezy/mpv/player/player_native.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/video_volume_controller.dart';

import '../test_helpers/mock_player_channels.dart';
import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsService settings;

  setUp(() async {
    resetSharedPreferencesForTest(initialAsync: {SettingsService.volume.key: 50.0, SettingsService.maxVolume.key: 100});
    SettingsService.resetForTesting();
    settings = await SettingsService.getInstance();
  });

  test('rapid repeats and wheel deltas accumulate and coalesce against intent', () async {
    final player = _ControlledVolumePlayer(50);
    final persisted = <double>[];
    final desired = <double>[];
    final controller = VideoVolumeController(
      player: player,
      settings: settings,
      initialVolume: 50,
      persistVolume: (volume) async => persisted.add(volume),
    );
    addTearDown(controller.dispose);
    controller.addListener(() => desired.add(controller.value));

    controller.adjust(5);
    controller.adjust(5);
    controller.adjust(5);

    expect(controller.value, 65);
    expect(desired, [55, 60, 65]);
    expect(player.requestedVolumes, [55]);
    expect(player.maxConcurrentWrites, 1);

    player.succeedNext();
    await _flush();
    expect(player.requestedVolumes, [55, 65]);
    expect(persisted, isEmpty);

    player.succeedNext();
    await controller.idle;
    expect(player.volume, 65);
    expect(persisted, [65]);
    expect(player.maxConcurrentWrites, 1);

    // Three wheel ticks using the production -dy/20 conversion are another
    // +15 burst even though native publication is held back.
    controller.adjust(-(-100) / 20);
    controller.adjust(-(-100) / 20);
    controller.adjust(-(-100) / 20);
    expect(controller.value, 80);
    expect(player.requestedVolumes.last, 70);

    player.succeedNext();
    await _flush();
    expect(player.requestedVolumes.last, 80);
    player.succeedNext();
    await controller.idle;
    expect(persisted.last, 80);
  });

  test('alternating deltas preserve order and clamp to configured boundaries', () async {
    final player = _ControlledVolumePlayer(50);
    final persisted = <double>[];
    final controller = VideoVolumeController(
      player: player,
      settings: settings,
      initialVolume: 50,
      persistVolume: (volume) async => persisted.add(volume),
    );
    addTearDown(controller.dispose);

    controller.adjust(5);
    controller.adjust(-10);
    controller.adjust(5);
    expect(controller.value, 50);
    expect(player.requestedVolumes, [55]);

    player.succeedNext();
    await _flush();
    expect(player.requestedVolumes, [55, 50]);
    player.succeedNext();
    await controller.idle;
    expect(persisted, [50]);

    controller.adjust(-500);
    controller.adjust(-5);
    expect(controller.value, 0);
    player.succeedNext();
    await controller.idle;
    expect(player.requestedVolumes.last, 0);
    expect(persisted.last, 0);

    controller.adjust(500);
    controller.adjust(5);
    expect(controller.value, 100);
    player.succeedNext();
    await controller.idle;
    expect(player.requestedVolumes.last, 100);
    expect(persisted.last, 100);
  });

  test('preview bursts commit only the final absolute value', () async {
    final player = _ControlledVolumePlayer(50);
    final persisted = <double>[];
    final controller = VideoVolumeController(
      player: player,
      settings: settings,
      initialVolume: 50,
      persistVolume: (volume) async => persisted.add(volume),
    );
    addTearDown(controller.dispose);

    controller.preview(60);
    controller.preview(65);
    controller.preview(70);
    controller.commit(70);
    expect(controller.value, 70);
    expect(player.requestedVolumes, [60]);

    player.succeedNext();
    await _flush();
    expect(player.requestedVolumes, [60, 70]);
    expect(persisted, isEmpty);
    player.succeedNext();
    await controller.idle;
    expect(persisted, [70]);
  });

  test('rapid mute transitions preserve the exact preferred non-zero volume', () async {
    await settings.write(SettingsService.volume, 37.0);
    final player = _ControlledVolumePlayer(37);
    final persisted = <double>[];
    final controller = VideoVolumeController(
      player: player,
      settings: settings,
      initialVolume: 37,
      persistVolume: (volume) async => persisted.add(volume),
    );
    addTearDown(controller.dispose);

    controller.toggleMute();
    controller.toggleMute();
    expect(controller.value, 37);
    expect(player.requestedVolumes, [0]);

    player.succeedNext();
    await _flush();
    expect(player.requestedVolumes, [0, 37]);
    expect(persisted, isEmpty);
    player.succeedNext();
    await controller.idle;
    expect(persisted, [37]);

    controller.adjust(5);
    controller.toggleMute();
    expect(controller.value, 0);
    player.succeedNext();
    await _flush();
    expect(player.requestedVolumes.last, 0);
    player.succeedNext();
    await controller.idle;
    expect(persisted.last, 42);
  });

  test('obsolete apply failure drains newer intent and current failure rolls back', () async {
    final player = _ControlledVolumePlayer(50);
    final persisted = <double>[];
    final controller = VideoVolumeController(
      player: player,
      settings: settings,
      initialVolume: 50,
      persistVolume: (volume) async => persisted.add(volume),
    );
    addTearDown(controller.dispose);

    controller.adjust(5);
    controller.adjust(10);
    player.failNext(StateError('first apply failed'));
    await _flush();
    expect(controller.value, 65);
    expect(player.requestedVolumes, [55, 65]);

    player.succeedNext();
    await controller.idle;
    expect(persisted, [65]);

    controller.adjust(5);
    expect(controller.value, 70);
    player.failNext(StateError('latest apply failed'));
    await controller.idle;
    expect(controller.value, 65);
    expect(player.volume, 65);
    expect(persisted, [65]);
  });

  test('persistence failure is contained and a later command converges', () async {
    final player = _ControlledVolumePlayer(50);
    final attempts = <double>[];
    var failNextPersistence = true;
    final controller = VideoVolumeController(
      player: player,
      settings: settings,
      initialVolume: 50,
      persistVolume: (volume) async {
        attempts.add(volume);
        if (failNextPersistence) {
          failNextPersistence = false;
          throw StateError('persistence failed');
        }
      },
    );
    addTearDown(controller.dispose);

    controller.adjust(5);
    player.succeedNext();
    await controller.idle;
    expect(controller.value, 55);
    expect(attempts, [55]);

    controller.adjust(5);
    player.succeedNext();
    await controller.idle;
    expect(controller.value, 60);
    expect(attempts, [55, 60]);
    expect(player.maxConcurrentWrites, 1);
  });

  test('idle observations resynchronize but in-flight observations cannot erase intent', () async {
    final player = _ControlledVolumePlayer(50);
    final controller = VideoVolumeController(player: player, settings: settings, initialVolume: 50);
    addTearDown(controller.dispose);

    player.publish(40);
    await _flush();
    expect(controller.value, 40);

    controller.adjust(5);
    player.publish(10);
    await _flush();
    expect(controller.value, 45);

    player.failNext(StateError('apply failed'));
    await controller.idle;
    expect(controller.value, 40);
  });

  test('dispose invalidates pending native and persistence continuations', () async {
    final player = _ControlledVolumePlayer(50);
    final persisted = <double>[];
    final controller = VideoVolumeController(
      player: player,
      settings: settings,
      initialVolume: 50,
      persistVolume: (volume) async => persisted.add(volume),
    );

    controller.adjust(5);
    controller.adjust(5);
    expect(player.requestedVolumes, [55]);
    controller.dispose();
    controller.adjust(50);
    controller.toggleMute();

    player.succeedNext();
    await _flush();
    expect(player.requestedVolumes, [55]);
    expect(persisted, isEmpty);
  });

  for (final adapter in <({String name, String methodChannel, String eventChannel, Player Function() create})>[
    (
      name: 'PlayerNative',
      methodChannel: 'com.plezy/mpv_player',
      eventChannel: 'com.plezy/mpv_player/events',
      create: PlayerNative.new,
    ),
    (
      name: 'PlayerAndroid',
      methodChannel: 'com.plezy/exo_player',
      eventChannel: 'com.plezy/exo_player/events',
      create: PlayerAndroid.new,
    ),
  ]) {
    test('${adapter.name} receives one ordered native volume write at a time', () async {
      final firstWriteStarted = Completer<void>();
      final releaseFirstWrite = Completer<void>();
      final nativeVolumes = <double>[];
      var activeWrites = 0;
      var maxActiveWrites = 0;

      await withMockPlayerChannels(
        methodChannelName: adapter.methodChannel,
        eventChannelName: adapter.eventChannel,
        methodHandler: (MethodCall call) async {
          if (call.method == 'initialize') return true;

          double? volume;
          if (call.method == 'setVolume') {
            volume = ((call.arguments as Map)['volume'] as num).toDouble();
          } else if (call.method == 'setProperty') {
            final arguments = call.arguments as Map;
            if (arguments['name'] == 'volume') {
              volume = double.parse(arguments['value'] as String);
            }
          }
          if (volume == null) return null;

          nativeVolumes.add(volume);
          activeWrites++;
          if (activeWrites > maxActiveWrites) maxActiveWrites = activeWrites;
          if (!firstWriteStarted.isCompleted) {
            firstWriteStarted.complete();
            await releaseFirstWrite.future;
          }
          activeWrites--;
          return null;
        },
        testBody: () async {
          final player = adapter.create();
          final persisted = <double>[];
          final controller = VideoVolumeController(
            player: player,
            settings: settings,
            initialVolume: 50,
            persistVolume: (volume) async => persisted.add(volume),
          );
          try {
            controller.adjust(5);
            controller.adjust(5);
            controller.adjust(5);
            await firstWriteStarted.future;
            expect(nativeVolumes, [55]);

            releaseFirstWrite.complete();
            await controller.idle;
            expect(nativeVolumes, [55, 65]);
            expect(persisted, [65]);
            expect(maxActiveWrites, 1);
            controller.dispose();
            controller.adjust(10);
            controller.toggleMute();
            await _flush();
            expect(nativeVolumes, [55, 65]);
            expect(persisted, [65]);
          } finally {
            if (!releaseFirstWrite.isCompleted) releaseFirstWrite.complete();
            controller.dispose();
            await player.dispose();
          }
        },
      );
    });
  }
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

final class _ControlledVolumePlayer implements Player {
  _ControlledVolumePlayer(this.volume);

  double volume;
  final requestedVolumes = <double>[];
  final _requests = <_VolumeRequest>[];
  final _volumeStream = StreamController<double>.broadcast();
  int _activeWrites = 0;
  int maxConcurrentWrites = 0;

  @override
  PlayerState get state => PlayerState(volume: volume);

  @override
  PlayerStreams get streams => PlayerStreams(
    playing: const Stream<bool>.empty(),
    completed: const Stream<bool>.empty(),
    buffering: const Stream<bool>.empty(),
    position: const Stream<Duration>.empty(),
    duration: const Stream<Duration>.empty(),
    seekable: const Stream<bool>.empty(),
    buffer: const Stream<Duration>.empty(),
    volume: _volumeStream.stream,
    rate: const Stream<double>.empty(),
    tracks: const Stream<Tracks>.empty(),
    track: const Stream<TrackSelection>.empty(),
    log: const Stream<PlayerLog>.empty(),
    error: const Stream<PlayerError>.empty(),
    audioDevice: const Stream<AudioDevice>.empty(),
    audioDevices: const Stream<List<AudioDevice>>.empty(),
    bufferRanges: const Stream<List<BufferRange>>.empty(),
    playbackRestart: const Stream<void>.empty(),
    backendSwitched: const Stream<void>.empty(),
  );

  @override
  Future<void> setVolume(double requested) async {
    requestedVolumes.add(requested);
    _activeWrites++;
    if (_activeWrites > maxConcurrentWrites) maxConcurrentWrites = _activeWrites;
    final request = _VolumeRequest(requested);
    _requests.add(request);
    try {
      await request.completer.future;
      volume = requested;
      _volumeStream.add(requested);
    } finally {
      _activeWrites--;
    }
  }

  void succeedNext() {
    final request = _requests.firstWhere((request) => !request.completer.isCompleted);
    request.completer.complete();
  }

  void failNext(Object error) {
    final request = _requests.firstWhere((request) => !request.completer.isCompleted);
    request.completer.completeError(error);
  }

  void publish(double observed) {
    volume = observed;
    _volumeStream.add(observed);
  }

  @override
  Future<void> dispose({bool preserveDisplayMode = false}) async {
    await _volumeStream.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _VolumeRequest {
  _VolumeRequest(this.volume);

  final double volume;
  final Completer<void> completer = Completer<void>();
}

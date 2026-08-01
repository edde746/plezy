import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/video_volume_controller.dart';
import 'package:plezy/widgets/video_controls/widgets/volume_control.dart';

import '../test_helpers/prefs.dart';

void main() {
  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('mute button keeps and restores the exact non-zero volume', (tester) async {
    final settings = SettingsService.instance;
    await settings.write(SettingsService.volume, 37.0);
    final player = _VolumePlayer(37);
    final controller = VideoVolumeController(player: player, settings: settings, initialVolume: 37);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: VolumeControl(volumeController: controller)),
      ),
    );

    await tester.tap(find.byType(IconButton));
    await controller.idle;
    await tester.pump();

    expect(player.volume, 0);
    expect(settings.read(SettingsService.volume), 37);

    await tester.tap(find.byType(IconButton));
    await controller.idle;
    await tester.pump();

    expect(player.volume, 37);
    expect(settings.read(SettingsService.volume), 37);
    expect(player.volumeChanges, [0, 37]);
  });

  testWidgets('D-pad repeats accumulate before native volume publication', (tester) async {
    final settings = SettingsService.instance;
    await settings.write(SettingsService.volume, 50.0);
    final player = _DelayedVolumePlayer(50);
    final controller = VideoVolumeController(player: player, settings: settings, initialVolume: 50);
    final focusNode = FocusNode();
    addTearDown(() async {
      controller.dispose();
      focusNode.dispose();
      await player.close();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VolumeControl(volumeController: controller, focusNode: focusNode),
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(controller.value, 65);
    expect(tester.widget<Slider>(find.byType(Slider)).value, 65);
    expect(player.volumeChanges, [55]);

    player.completeNext();
    await tester.pump();
    expect(player.volumeChanges, [55, 65]);
    player.completeNext();
    await controller.idle;
    await tester.pump();

    expect(player.volume, 65);
    expect(settings.read(SettingsService.volume), 65);
  });

  testWidgets('slider previews are serialized and only the final drag value persists', (tester) async {
    final settings = SettingsService.instance;
    await settings.write(SettingsService.volume, 50.0);
    final player = _VolumePlayer(50);
    final controller = VideoVolumeController(player: player, settings: settings, initialVolume: 50);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: VolumeControl(volumeController: controller)),
      ),
    );

    await tester.drag(find.byType(Slider), const Offset(40, 0));
    await controller.idle;
    await tester.pump();

    expect(player.volumeChanges, isNotEmpty);
    expect(settings.read(SettingsService.volume), closeTo(controller.value, 0.001));
  });
  testWidgets('one ancestor wheel delta applies over and away from the slider', (tester) async {
    final settings = SettingsService.instance;
    await settings.write(SettingsService.volume, 50.0);
    final player = _VolumePlayer(50);
    final controller = VideoVolumeController(player: player, settings: settings, initialVolume: 50);
    addTearDown(controller.dispose);

    const blankKey = Key('blank-player-area');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                controller.adjust(-event.scrollDelta.dy / 20);
              }
            },
            child: Row(
              children: [
                const SizedBox(key: blankKey, width: 100, height: 100),
                VolumeControl(volumeController: controller),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.sendEventToBinding(
      PointerScrollEvent(position: tester.getCenter(find.byType(Slider)), scrollDelta: const Offset(0, -100)),
    );
    await controller.idle;
    expect(controller.value, 55);
    expect(player.volumeChanges, [55]);

    await tester.sendEventToBinding(
      PointerScrollEvent(position: tester.getCenter(find.byKey(blankKey)), scrollDelta: const Offset(0, -100)),
    );
    await controller.idle;
    expect(controller.value, 60);
    expect(player.volumeChanges, [55, 60]);
  });
}

class _VolumePlayer implements Player {
  _VolumePlayer(this.volume)
    : _streams = PlayerStreams(
        playing: const Stream<bool>.empty(),
        completed: const Stream<bool>.empty(),
        buffering: const Stream<bool>.empty(),
        position: const Stream<Duration>.empty(),
        duration: const Stream<Duration>.empty(),
        seekable: const Stream<bool>.empty(),
        buffer: const Stream<Duration>.empty(),
        volume: const Stream<double>.empty(),
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

  double volume;
  final List<double> volumeChanges = [];
  final PlayerStreams _streams;

  @override
  PlayerState get state => PlayerState(volume: volume);

  @override
  PlayerStreams get streams => _streams;

  @override
  Future<void> setVolume(double volume) async {
    this.volume = volume;
    volumeChanges.add(volume);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _DelayedVolumePlayer extends _VolumePlayer {
  _DelayedVolumePlayer(super.volume);

  final List<Completer<void>> _pending = [];
  final StreamController<double> _volumeController = StreamController<double>.broadcast();

  @override
  PlayerStreams get streams => PlayerStreams(
    playing: const Stream<bool>.empty(),
    completed: const Stream<bool>.empty(),
    buffering: const Stream<bool>.empty(),
    position: const Stream<Duration>.empty(),
    duration: const Stream<Duration>.empty(),
    seekable: const Stream<bool>.empty(),
    buffer: const Stream<Duration>.empty(),
    volume: _volumeController.stream,
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
    volumeChanges.add(requested);
    final completer = Completer<void>();
    _pending.add(completer);
    await completer.future;
    volume = requested;
    _volumeController.add(requested);
  }

  void completeNext() {
    _pending.firstWhere((completer) => !completer.isCompleted).complete();
  }

  Future<void> close() => _volumeController.close();
}

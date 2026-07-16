import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/services/settings_service.dart';
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

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: VolumeControl(player: player)),
      ),
    );

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(player.volume, 0);
    expect(settings.read(SettingsService.volume), 37);

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(player.volume, 37);
    expect(settings.read(SettingsService.volume), 37);
    expect(player.volumeChanges, [0, 37]);
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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/mpv/models.dart';
import 'package:vibe_stream/mpv/player/player.dart';
import 'package:vibe_stream/mpv/player/player_state.dart';
import 'package:vibe_stream/mpv/player/player_streams.dart';
import 'package:vibe_stream/services/settings_service.dart';
import 'package:vibe_stream/theme/mono_tokens.dart';
import 'package:vibe_stream/utils/platform_detector.dart';
import 'package:vibe_stream/widgets/video_controls/sheets/video_settings_sheet.dart';

import '../test_helpers/prefs.dart';

const _testTokens = MonoTokens(
  radiusSm: 4,
  radiusMd: 8,
  space: 8,
  fast: Duration(milliseconds: 100),
  normal: Duration(milliseconds: 200),
  slow: Duration(milliseconds: 300),
  bg: Colors.black,
  surface: Color(0xFF111111),
  outline: Color(0xFF333333),
  text: Colors.white,
  textMuted: Color(0xFFAAAAAA),
  splashFactory: NoSplash.splashFactory,
);

void main() {
  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    TvDetectionService.debugSetAppleTVOverride(null);
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
  });

  testWidgets('shows audio passthrough on supported TV-style surfaces', (tester) async {
    await _pumpSheet(tester);

    await tester.scrollUntilVisible(find.text('Audio Passthrough'), 500, scrollable: find.byType(Scrollable).first);

    expect(find.text('Audio Passthrough'), findsOneWidget);
  });

  testWidgets('hides audio passthrough on Apple TV', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);

    await _pumpSheet(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();

    expect(find.text('Audio Passthrough'), findsNothing);
  });
}

Future<void> _pumpSheet(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: const [_testTokens]),
      home: Scaffold(
        body: SizedBox(
          width: 900,
          height: 700,
          child: VideoSettingsSheet(
            player: _FakeSettingsPlayer(),
            audioSyncOffset: 0,
            subtitleSyncOffset: 0,
            canControl: false,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeSettingsPlayer implements Player {
  _FakeSettingsPlayer()
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

  final PlayerStreams _streams;

  @override
  PlayerState get state => const PlayerState();

  @override
  PlayerStreams get streams => _streams;

  @override
  String get playerType => 'exoplayer';

  @override
  Future<void> setAudioPassthrough(bool enabled) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

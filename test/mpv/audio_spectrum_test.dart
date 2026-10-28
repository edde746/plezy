import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/mpv/player/audio_spectrum.dart';
import 'package:plezy/services/music/music_playback_service.dart';
import 'package:plezy/widgets/music/music_visualizer.dart';
import 'package:plezy/widgets/music/music_visualizer_painter.dart';
import 'package:plezy/widgets/overlay_sheet.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/stub_music_playback_service.dart';
import '../test_helpers/theme.dart';

class _FakeAnalyzer implements AudioSpectrumAnalyzer {
  final StreamController<AudioSpectrumSample?> controller = StreamController<AudioSpectrumSample?>.broadcast(
    sync: true,
  );
  bool enabled = false;
  bool passthrough = false;

  @override
  Stream<AudioSpectrumSample?> get audioSpectrumStream => controller.stream;

  @override
  bool get audioPassthroughActive => passthrough;

  @override
  Future<bool> setAudioSpectrumAnalysisEnabled(bool value) async {
    enabled = value;
    return value && !passthrough;
  }

  Future<void> dispose() => controller.close();
}

class _SpectrumMusicService extends StubMusicPlaybackService
    implements MusicLoudnessProfileService, MusicAudioSpectrumService {
  _SpectrumMusicService({required this.track, required this.profileFuture, required this.analyzer});

  final MediaItem track;
  final Future<AudioLoudnessProfile?> profileFuture;
  final _FakeAnalyzer analyzer;
  final StreamController<Duration> positions = StreamController<Duration>.broadcast(sync: true);
  MusicPlaybackStatus playbackStatus = MusicPlaybackStatus.playing;
  Duration currentPosition = Duration.zero;

  @override
  MediaItem? get currentTrack => track;

  @override
  MusicPlaybackStatus get status => playbackStatus;

  @override
  Duration get position => currentPosition;

  @override
  Stream<Duration> get positionStream => positions.stream;

  @override
  AudioSpectrumAnalyzer get audioSpectrumAnalyzer => analyzer;

  @override
  Future<AudioLoudnessProfile?> loadCurrentTrackLoudnessProfile() => profileFuture;

  @override
  void dispose() {
    unawaited(positions.close());
    super.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));

  test('parses MPV node maps and Android JSON while averaging matched channels', () {
    final sample = AudioSpectrumSample.tryParse({
      'af-metadata/plezy_spectrum': {
        'lavfi.aspectralstats.1.centroid': 2400,
        'lavfi.aspectralstats.1.flatness': 0.2,
        'lavfi.aspectralstats.2.centroid': 4800,
        'lavfi.aspectralstats.2.flatness': 0.6,
      },
    });
    expect(sample?.centroidHz, 3600);
    expect(sample?.flatness, 0.4);
    expect(sample?.normalizedCentroid, closeTo(0.15, 0.0001));

    final jsonSample = AudioSpectrumSample.tryParse(
      jsonEncode({'lavfi.aspectralstats.1.centroid': '12000', 'lavfi.aspectralstats.1.flatness': '1.4'}),
    );
    expect(jsonSample?.centroidHz, 12000);
    expect(jsonSample?.flatness, 1);
  });

  test('rejects malformed and incomplete audio metadata', () {
    expect(AudioSpectrumSample.tryParse(null), isNull);
    expect(AudioSpectrumSample.tryParse('{bad json'), isNull);
    expect(AudioSpectrumSample.tryParse({'lavfi.aspectralstats.1.centroid': 2400}), isNull);
    expect(
      AudioSpectrumSample.tryParse({
        'lavfi.aspectralstats.1.centroid': double.nan,
        'lavfi.aspectralstats.1.flatness': 0.4,
      }),
      isNull,
    );
  });

  testWidgets('uses live derived audio data when Plex analysis is unavailable and disables it on close', (
    tester,
  ) async {
    final track = testMediaItem(
      id: 'live-spectrum',
      kind: .track,
      serverId: 'spectrum-server',
      durationMs: const Duration(minutes: 2).inMilliseconds,
    );
    final analyzer = _FakeAnalyzer();
    final service = _SpectrumMusicService(track: track, profileFuture: Future.value(null), analyzer: analyzer);
    addTearDown(service.dispose);
    addTearDown(analyzer.dispose);

    await tester.pumpWidget(_wrap(service, track));
    await tester.pump();
    expect(analyzer.enabled, isTrue);
    expect(find.text(t.music.visualizerAmbientMotion), findsOneWidget);

    analyzer.controller.add(const AudioSpectrumSample(centroidHz: 9600, flatness: 0.72));
    await tester.pump();
    expect(find.text(t.music.visualizerLiveAudio), findsOneWidget);
    expect(_painter(tester).frame.value.energy, greaterThan(0.5));
    expect(_painter(tester).frame.value.transient, greaterThan(0));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(analyzer.enabled, isFalse);
  });

  testWidgets('keeps Plex loudness as the preferred analysis source', (tester) async {
    final track = testMediaItem(
      id: 'plex-spectrum',
      kind: .track,
      serverId: 'spectrum-server',
      durationMs: const Duration(minutes: 2).inMilliseconds,
    );
    final analyzer = _FakeAnalyzer();
    final service = _SpectrumMusicService(
      track: track,
      profileFuture: Future.value(AudioLoudnessProfile(levelsDb: List.filled(16, -28), totalSamples: 16)),
      analyzer: analyzer,
    );
    addTearDown(service.dispose);
    addTearDown(analyzer.dispose);

    await tester.pumpWidget(_wrap(service, track));
    await tester.pump();
    expect(find.text(t.music.visualizerPlexLoudness), findsOneWidget);
    expect(analyzer.enabled, isFalse);
  });

  testWidgets('falls back and releases an unsupported live filter after a short probe window', (tester) async {
    final track = testMediaItem(
      id: 'unsupported-spectrum',
      kind: .track,
      serverId: 'spectrum-server',
      durationMs: const Duration(minutes: 2).inMilliseconds,
    );
    final analyzer = _FakeAnalyzer();
    final service = _SpectrumMusicService(track: track, profileFuture: Future.value(null), analyzer: analyzer);
    addTearDown(service.dispose);
    addTearDown(analyzer.dispose);

    await tester.pumpWidget(_wrap(service, track));
    await tester.pump();
    expect(analyzer.enabled, isTrue);

    for (var tick = 0; tick < 10; tick++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(analyzer.enabled, isFalse);
    expect(find.text(t.music.visualizerAmbientMotion), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

final _visualizerCanvasFinder = find.byWidgetPredicate(
  (widget) => widget is CustomPaint && widget.painter is MusicVisualizerPainter,
);

MusicVisualizerPainter _painter(WidgetTester tester) =>
    tester.widget<CustomPaint>(_visualizerCanvasFinder).painter! as MusicVisualizerPainter;

Widget _wrap(MusicPlaybackService service, MediaItem track) => TranslationProvider(
  child: MaterialApp(
    theme: ThemeData(extensions: const [testMonoTokens]),
    home: OverlaySheetHost(
      child: Scaffold(
        body: SizedBox(
          width: 320,
          height: 180,
          child: MusicVisualizer(
            service: service,
            trackKey: track.globalKey,
            duration: const Duration(minutes: 2),
            preset: MusicVisualizerPreset.bloom,
            onPresetChanged: (_) {},
          ),
        ),
      ),
    ),
  ),
);

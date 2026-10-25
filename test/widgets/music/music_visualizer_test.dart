import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/services/music/music_playback_service.dart';
import 'package:plezy/widgets/music/music_visualizer.dart';
import 'package:plezy/widgets/music/music_visualizer_painter.dart';
import 'package:plezy/widgets/overlay_sheet.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/stub_music_playback_service.dart';
import '../../test_helpers/theme.dart';

class _VisualizerService extends StubMusicPlaybackService implements MusicLoudnessProfileService {
  _VisualizerService({required this.profileFuture, required this.track}) : super();

  final Future<AudioLoudnessProfile?> profileFuture;
  final StreamController<Duration> positions = StreamController<Duration>.broadcast(sync: true);
  int profileLoads = 0;
  MediaItem? track;
  MusicPlaybackStatus playbackStatus = MusicPlaybackStatus.playing;
  Duration currentPosition = Duration.zero;

  void setSource(MediaItem? value, MusicPlaybackStatus nextStatus) {
    track = value;
    playbackStatus = nextStatus;
    notifyListeners();
  }

  @override
  MediaItem? get currentTrack => track;

  @override
  MusicPlaybackStatus get status => playbackStatus;

  @override
  Duration get position => currentPosition;

  @override
  Stream<Duration> get positionStream => positions.stream;

  @override
  Future<AudioLoudnessProfile?> loadCurrentTrackLoudnessProfile() {
    profileLoads++;
    return profileFuture;
  }

  @override
  void dispose() {
    positions.close();
    super.dispose();
  }
}

class _ControlledVisualizerService extends _VisualizerService {
  _ControlledVisualizerService({required super.track}) : super(profileFuture: Future.value(null));

  final List<Completer<AudioLoudnessProfile?>> profileRequests = [];

  @override
  Future<AudioLoudnessProfile?> loadCurrentTrackLoudnessProfile() {
    profileLoads++;
    final request = Completer<AudioLoudnessProfile?>();
    profileRequests.add(request);
    return request.future;
  }
}

class _AmbientOnlyService extends StubMusicPlaybackService {
  _AmbientOnlyService(this.track);

  final MediaItem track;

  @override
  MediaItem? get currentTrack => track;

  @override
  MusicPlaybackStatus get status => MusicPlaybackStatus.playing;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));

  final track = testMediaItem(
    id: 'visualizer-track',
    kind: .track,
    serverId: 'visualizer-server',
    durationMs: const Duration(minutes: 3).inMilliseconds,
  );

  testWidgets('renders immediately, follows display vsync and reacts to Plex loudness', (tester) async {
    final service = _VisualizerService(
      profileFuture: Future.value(AudioLoudnessProfile(levelsDb: List.filled(512, -24), totalSamples: 50000)),
      track: track,
    );
    addTearDown(service.dispose);
    await tester.pumpWidget(_wrap(service, track));
    await tester.pump();

    expect(service.profileLoads, 1);
    expect(find.text(t.music.visualizerPlexLoudness), findsOneWidget);
    expect(_painter(tester).preset, MusicVisualizerPreset.bloom);

    final firstTime = _painter(tester).frame.value.timeSeconds;
    await tester.pump(const Duration(milliseconds: 8));
    final one120HzFrame = _painter(tester).frame.value.timeSeconds;
    await tester.pump(const Duration(milliseconds: 8));
    final two120HzFrames = _painter(tester).frame.value.timeSeconds;
    expect(one120HzFrame, greaterThan(firstTime));
    expect(two120HzFrames, greaterThan(one120HzFrame));

    service.currentPosition = const Duration(seconds: 90);
    service.positions.add(service.currentPosition);
    await tester.pump(const Duration(milliseconds: 8));
    expect(_painter(tester).frame.value.progress, closeTo(0.5, 0.001));

    await tester.tap(find.byTooltip(t.music.visualizerNextPreset));
    await tester.pump(const Duration(milliseconds: 8));
    expect(_painter(tester).preset, MusicVisualizerPreset.orbitals);
    expect(find.text(t.music.visualizerPresetOrbitals), findsOneWidget);
  });

  testWidgets('cycles through every preset and wraps in a narrow layout', (tester) async {
    final service = _VisualizerService(profileFuture: Future.value(null), track: track);
    addTearDown(service.dispose);
    await tester.pumpWidget(_wrap(service, track, width: 320, height: 180));
    await tester.pump();
    expect(tester.takeException(), isNull);

    for (final preset in MusicVisualizerPreset.values.skip(2)) {
      await tester.tap(find.byTooltip(t.music.visualizerNextPreset));
      await tester.pump(const Duration(milliseconds: 8));
      expect(_painter(tester).preset, preset);
      expect(find.text(_name(preset)), findsOneWidget);
    }
    await tester.tap(find.byTooltip(t.music.visualizerNextPreset));
    await tester.pump(const Duration(milliseconds: 8));
    expect(_painter(tester).preset, MusicVisualizerPreset.aurora);
    await tester.tap(find.byTooltip(t.music.visualizerPreviousPreset));
    await tester.pump(const Duration(milliseconds: 8));
    expect(_painter(tester).preset, MusicVisualizerPreset.trackMap);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps ambient visuals while optional loudness data loads or is absent', (tester) async {
    final completer = Completer<AudioLoudnessProfile?>();
    final service = _VisualizerService(profileFuture: completer.future, track: track);
    addTearDown(service.dispose);

    await tester.pumpWidget(_wrap(service, track));
    expect(find.text(t.music.visualizerProfileLoading), findsOneWidget);
    expect(_visualizerCanvasFinder, findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    completer.complete(null);
    await tester.pump();
    expect(find.text(t.music.visualizerAmbientMotion), findsOneWidget);
    expect(_visualizerCanvasFinder, findsOneWidget);
  });

  testWidgets('loads Plex analysis when the active source becomes ready', (tester) async {
    final service = _VisualizerService(profileFuture: Future.value(null), track: null)
      ..playbackStatus = MusicPlaybackStatus.loading;
    addTearDown(service.dispose);

    await tester.pumpWidget(_wrap(service, track));
    expect(service.profileLoads, 0, reason: 'no analysis request is made until the current track is ready');
    expect(_visualizerCanvasFinder, findsOneWidget);

    service.setSource(track, MusicPlaybackStatus.playing);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 8));

    expect(service.profileLoads, 1);
    expect(find.text(t.music.visualizerAmbientMotion), findsOneWidget);
  });

  testWidgets('uses ambient motion when the playback backend has no loudness capability', (tester) async {
    final service = _AmbientOnlyService(track);
    addTearDown(service.dispose);

    await tester.pumpWidget(_wrap(service, track));
    await tester.pump();

    expect(find.text(t.music.visualizerAmbientMotion), findsOneWidget);
    expect(_visualizerCanvasFinder, findsOneWidget);
  });

  testWidgets('ignores a late profile response after the track changes', (tester) async {
    final nextTrack = testMediaItem(
      id: 'visualizer-next-track',
      kind: .track,
      serverId: 'visualizer-server',
      durationMs: const Duration(minutes: 3).inMilliseconds,
    );
    final service = _ControlledVisualizerService(track: track);
    addTearDown(service.dispose);

    await tester.pumpWidget(_wrap(service, track));
    expect(service.profileRequests, hasLength(1));

    service.setSource(nextTrack, MusicPlaybackStatus.playing);
    await tester.pumpWidget(_wrap(service, nextTrack));
    expect(service.profileRequests, hasLength(2));

    service.profileRequests[0].complete(AudioLoudnessProfile(levelsDb: List.filled(16, -12), totalSamples: 16));
    await tester.pump();
    expect(_painter(tester).profile, isNull);

    service.profileRequests[1].complete(AudioLoudnessProfile(levelsDb: List.filled(16, -34), totalSamples: 16));
    await tester.pump();
    expect(_painter(tester).profile?.levelsDb.first, -34);
  });

  testWidgets('falls back to ambient visuals when Plex analysis fails', (tester) async {
    final completer = Completer<AudioLoudnessProfile?>();
    final service = _VisualizerService(profileFuture: completer.future, track: track);
    addTearDown(service.dispose);

    await tester.pumpWidget(_wrap(service, track));
    completer.completeError(StateError('offline'));
    await tester.pump();

    expect(find.text(t.music.visualizerAmbientMotion), findsOneWidget);
    expect(_visualizerCanvasFinder, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('honors reduced motion while keeping the track map playhead current', (tester) async {
    final service = _VisualizerService(profileFuture: Future.value(null), track: track);
    addTearDown(service.dispose);
    await tester.pumpWidget(_wrap(service, track, reducedMotion: true, preset: MusicVisualizerPreset.trackMap));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_painter(tester).frame.value.timeSeconds, 0);

    service.currentPosition = const Duration(seconds: 60);
    service.positions.add(service.currentPosition);
    await tester.pump();
    expect(_painter(tester).frame.value.progress, closeTo(1 / 3, 0.001));
  });
}

final _visualizerCanvasFinder = find.byWidgetPredicate(
  (widget) => widget is CustomPaint && widget.painter is MusicVisualizerPainter,
  description: 'animated music visualizer canvas',
);

MusicVisualizerPainter _painter(WidgetTester tester) =>
    tester.widget<CustomPaint>(_visualizerCanvasFinder).painter! as MusicVisualizerPainter;

String _name(MusicVisualizerPreset preset) => switch (preset) {
  MusicVisualizerPreset.aurora => t.music.visualizerPresetAurora,
  MusicVisualizerPreset.bloom => t.music.visualizerPresetBloom,
  MusicVisualizerPreset.orbitals => t.music.visualizerPresetOrbitals,
  MusicVisualizerPreset.prism => t.music.visualizerPresetPrism,
  MusicVisualizerPreset.tunnel => t.music.visualizerPresetTunnel,
  MusicVisualizerPreset.trackMap => t.music.visualizerPresetTrackMap,
};

Widget _wrap(
  MusicPlaybackService service,
  MediaItem track, {
  double width = 520,
  double height = 180,
  bool reducedMotion = false,
  MusicVisualizerPreset preset = MusicVisualizerPreset.bloom,
}) => TranslationProvider(
  child: MaterialApp(
    theme: ThemeData(extensions: const [testMonoTokens]),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
      child: child!,
    ),
    home: OverlaySheetHost(
      child: Scaffold(
        body: _VisualizerHarnessWithPreset(
          service: service,
          track: track,
          width: width,
          height: height,
          initialPreset: preset,
        ),
      ),
    ),
  ),
);

class _VisualizerHarnessWithPreset extends StatefulWidget {
  const _VisualizerHarnessWithPreset({
    required this.service,
    required this.track,
    required this.width,
    required this.height,
    required this.initialPreset,
  });

  final MusicPlaybackService service;
  final MediaItem track;
  final double width;
  final double height;
  final MusicVisualizerPreset initialPreset;

  @override
  State<_VisualizerHarnessWithPreset> createState() => _VisualizerHarnessWithPresetState();
}

class _VisualizerHarnessWithPresetState extends State<_VisualizerHarnessWithPreset> {
  late MusicVisualizerPreset preset = widget.initialPreset;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.width,
    height: widget.height,
    child: MusicVisualizer(
      service: widget.service,
      trackKey: widget.track.globalKey,
      duration: const Duration(minutes: 3),
      preset: preset,
      onPresetChanged: (next) => setState(() => preset = next),
    ),
  );
}

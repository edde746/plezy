import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/services/music/music_playback_service.dart';
import 'package:plezy/widgets/music/music_visualizer.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));

  final track = testMediaItem(
    id: 'visualizer-track',
    kind: .track,
    serverId: 'visualizer-server',
    durationMs: const Duration(minutes: 3).inMilliseconds,
  );

  testWidgets('renders the bounded loudness profile and follows playback position', (tester) async {
    final service = _VisualizerService(
      profileFuture: Future.value(AudioLoudnessProfile(levelsDb: List.filled(512, -24), totalSamples: 50000)),
      track: track,
    );
    addTearDown(service.dispose);
    await tester.pumpWidget(_wrap(service, track));
    await tester.pumpAndSettle();

    expect(service.profileLoads, 1);
    final visualizer = _loudnessPainterFinder;
    expect(visualizer, findsOneWidget);
    final initialPainter = tester.widget<CustomPaint>(visualizer).painter;

    service.positions.add(const Duration(seconds: 90));
    await tester.pump();

    expect(tester.widget<CustomPaint>(visualizer).painter, isNot(same(initialPainter)));
  });

  testWidgets('shows loading then an unavailable state when Plex has no profile', (tester) async {
    final completer = Completer<AudioLoudnessProfile?>();
    final service = _VisualizerService(profileFuture: completer.future, track: track);
    addTearDown(service.dispose);

    await tester.pumpWidget(_wrap(service, track));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(null);
    await tester.pumpAndSettle();

    expect(find.text(t.music.visualizerUnavailable), findsOneWidget);
    expect(_loudnessPainterFinder, findsNothing);
  });

  testWidgets('loads when the current source becomes ready', (tester) async {
    final service = _VisualizerService(profileFuture: Future.value(null), track: null)
      ..playbackStatus = MusicPlaybackStatus.loading;
    addTearDown(service.dispose);

    await tester.pumpWidget(_wrap(service, track));
    expect(service.profileLoads, 0, reason: 'no profile request is needed until this track is ready');

    service.setSource(track, MusicPlaybackStatus.playing);
    await tester.pumpAndSettle();

    expect(service.profileLoads, 1);
    expect(find.text(t.music.visualizerUnavailable), findsOneWidget);
  });
}

Widget _wrap(MusicPlaybackService service, MediaItem track) => TranslationProvider(
  child: MaterialApp(
    theme: ThemeData(extensions: const [testMonoTokens]),
    home: Scaffold(
      body: SizedBox(
        width: 520,
        height: 180,
        child: MusicVisualizer(service: service, trackKey: track.globalKey, duration: const Duration(minutes: 3)),
      ),
    ),
  ),
);

final _loudnessPainterFinder = find.byWidgetPredicate(
  (widget) => widget is CustomPaint && widget.child is SizedBox,
  description: 'loudness profile painter',
);

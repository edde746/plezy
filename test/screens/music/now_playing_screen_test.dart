import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/music/now_playing_screen.dart';
import 'package:plezy/services/music/music_playback_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/multi_server_fixtures.dart';

MediaItem _track({required String id, required String title, required String album, required int year}) {
  return testMediaItem(
    id: id,
    backend: MediaBackend.plex,
    kind: MediaKind.track,
    title: title,
    parentId: 'album_$id',
    parentTitle: album,
    grandparentId: 'artist_$id',
    grandparentTitle: 'Artist $id',
    year: year,
    durationMs: const Duration(minutes: 3).inMilliseconds,
    serverId: 'server_1',
  );
}

class _FakeMusicService extends StubMusicPlaybackService {
  MediaItem track;
  final MusicPlayContext context;
  final StreamController<Duration> _positionController = StreamController<Duration>.broadcast(sync: true);
  final List<Duration> seeks = [];
  Duration _position = Duration.zero;

  _FakeMusicService({required this.track, required this.context});

  void advanceTo(MediaItem next) {
    track = next;
    _position = Duration.zero;
    notifyListeners();
  }

  void emitPosition(Duration position) {
    _position = position;
    _positionController.add(position);
  }

  @override
  bool get isAvailable => true;

  @override
  MediaItem get currentTrack => track;

  @override
  MusicPlaybackStatus get status => MusicPlaybackStatus.playing;

  @override
  Duration get position => _position;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Duration get duration => const Duration(minutes: 3);

  @override
  List<MediaItem> get queue => [track];

  @override
  int get currentIndex => 0;

  @override
  MusicPlayContext get playContext => context;

  @override
  Future<void> seek(Duration position) async {
    seeks.add(position);
    _position = position;
  }

  @override
  void dispose() {
    _positionController.close();
    super.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
    TvDetectionService.debugSetAppleTVOverride(false);
    PlatformDetector.debugSetIsDesktopOSOverride(null);
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
    PlatformDetector.debugSetIsDesktopOSOverride(null);
  });

  Future<void> pumpNowPlaying(WidgetTester tester, _FakeMusicService service, {required bool isTv}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    TvDetectionService.debugSetAppleTVOverride(isTv);
    PlatformDetector.debugSetIsDesktopOSOverride(!isTv);

    addTearDown(service.dispose);
    final multiServerProvider = testMultiServer().provider;

    await tester.pumpWidget(
      InputModeTracker(
        child: TranslationProvider(
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
              ChangeNotifierProvider<MusicPlaybackService>.value(value: service),
            ],
            child: MaterialApp(
              theme: monoTheme(dark: true).copyWith(platform: isTv ? TargetPlatform.android : TargetPlatform.windows),
              home: const NowPlayingScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final isTv in [false, true]) {
    testWidgets('${isTv ? 'TV' : 'desktop'} follows the current album when an album queue crosses albums', (
      tester,
    ) async {
      final first = _track(id: 'one', title: 'First Track', album: 'First Album', year: 1973);
      final second = _track(id: 'two', title: 'Second Track', album: 'Second Album', year: 1999);
      final service = _FakeMusicService(
        track: first,
        context: const MusicPlayContext(id: 'album_one', title: 'First Album', kind: MusicPlayContextKind.album),
      );

      await pumpNowPlaying(tester, service, isTv: isTv);

      expect(find.text(t.music.playingFrom(title: 'First Album · 1973')), findsOneWidget);

      service.advanceTo(second);
      await tester.pump();

      expect(find.text(t.music.playingFrom(title: 'First Album · 1973')), findsNothing);
      expect(find.text(t.music.playingFrom(title: 'Second Album · 1999')), findsOneWidget);
    });
  }

  testWidgets('playlist playback retains its queue provenance label', (tester) async {
    final service = _FakeMusicService(
      track: _track(id: 'one', title: 'First Track', album: 'First Album', year: 1973),
      context: const MusicPlayContext(id: 'playlist_1', title: 'Road Trip', kind: MusicPlayContextKind.playlist),
    );

    await pumpNowPlaying(tester, service, isTv: false);

    expect(find.text(t.music.playingFrom(title: 'Road Trip')), findsOneWidget);
    expect(find.text(t.music.playingFrom(title: 'First Album · 1973')), findsNothing);
  });

  testWidgets('pending d-pad seek is discarded when the track changes', (tester) async {
    final first = _track(id: 'one', title: 'First Track', album: 'First Album', year: 1973);
    final second = _track(id: 'two', title: 'Second Track', album: 'Second Album', year: 1999);
    final service = _FakeMusicService(
      track: first,
      context: const MusicPlayContext(title: 'Queue', kind: MusicPlayContextKind.tracks),
    );

    await pumpNowPlaying(tester, service, isTv: true);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);

    service.advanceTo(second);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(service.seeks, isEmpty);
  });

  testWidgets('seek progress resets immediately when the track changes', (tester) async {
    final first = _track(id: 'one', title: 'First Track', album: 'First Album', year: 1973);
    final second = _track(id: 'two', title: 'Second Track', album: 'Second Album', year: 1999);
    final service = _FakeMusicService(
      track: first,
      context: const MusicPlayContext(title: 'Queue', kind: MusicPlayContextKind.tracks),
    );

    await pumpNowPlaying(tester, service, isTv: false);
    service.emitPosition(const Duration(minutes: 2));
    await tester.pump();
    Slider seekSlider() => tester
        .widgetList<Slider>(find.byType(Slider))
        .singleWhere((slider) => slider.max == const Duration(minutes: 3).inMilliseconds);

    expect(seekSlider().value, 120000);

    service.advanceTo(second);
    await tester.pump();

    expect(seekSlider().value, 0);
  });
}

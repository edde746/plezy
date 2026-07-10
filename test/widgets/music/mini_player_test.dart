import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/music/music_playback_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/music/mini_player.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/prefs.dart';

final _track = MediaItem(
  id: 'track_1',
  backend: MediaBackend.plex,
  kind: MediaKind.track,
  title: 'Dawn',
  parentId: 'album_1',
  parentTitle: 'First Light',
  grandparentId: 'artist_1',
  grandparentTitle: 'Test Artist',
  durationMs: 180000,
  serverId: 'server_1',
  serverName: 'Server',
);

/// Fixed-state fake: reports a playing session with a single-track queue.
class _FakeMusicService extends StubMusicPlaybackService {
  MediaItem? track;

  _FakeMusicService({this.track});

  @override
  bool get isAvailable => true;

  @override
  MediaItem? get currentTrack => track;

  @override
  MusicPlaybackStatus get status => track == null ? MusicPlaybackStatus.idle : MusicPlaybackStatus.playing;

  @override
  Duration? get duration => track == null ? null : const Duration(minutes: 3);

  @override
  List<MediaItem> get queue => track == null ? const [] : [track!];

  @override
  int get currentIndex => track == null ? -1 : 0;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
    await SettingsService.getInstance();
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
  });

  Widget wrap({required MusicPlaybackService service, required MusicUiRouteObserver observer}) {
    final manager = MultiServerManager();
    final multiServerProvider = MultiServerProvider(manager, DataAggregationService(manager));
    addTearDown(multiServerProvider.dispose);

    return TranslationProvider(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
          ChangeNotifierProvider<MusicPlaybackService>.value(value: service),
          ChangeNotifierProvider<MiniPlayerInsetController>(create: (_) => MiniPlayerInsetController()),
          Provider<MusicUiRouteObserver>.value(value: observer),
        ],
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: const Stack(
            children: [
              SizedBox.expand(),
              Positioned.fill(child: MusicMiniPlayerOverlay()),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('appears when the service has a current track', (tester) async {
    final service = _FakeMusicService(track: _track);
    final observer = MusicUiRouteObserver();

    await tester.pumpWidget(wrap(service: service, observer: observer));
    await tester.pumpAndSettle();

    expect(find.text('Dawn'), findsOneWidget);
    expect(find.text('Test Artist'), findsOneWidget);
    expect(find.byType(IconButton), findsNWidgets(2)); // play/pause + next (mobile layout)
  });

  testWidgets('stays hidden while the route observer suppresses it', (tester) async {
    final service = _FakeMusicService(track: _track);
    final observer = MusicUiRouteObserver();
    observer.suppress.value = true;

    await tester.pumpWidget(wrap(service: service, observer: observer));
    await tester.pumpAndSettle();

    expect(find.text('Dawn'), findsNothing);

    // Suppression lifting brings it back without a rebuild from the service.
    observer.suppress.value = false;
    await tester.pumpAndSettle();
    expect(find.text('Dawn'), findsOneWidget);
  });

  testWidgets('renders nothing without a current track', (tester) async {
    final service = _FakeMusicService();
    final observer = MusicUiRouteObserver();

    await tester.pumpWidget(wrap(service: service, observer: observer));
    await tester.pumpAndSettle();

    expect(find.text('Dawn'), findsNothing);
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('never renders on TV', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final service = _FakeMusicService(track: _track);
    final observer = MusicUiRouteObserver();

    await tester.pumpWidget(wrap(service: service, observer: observer));
    await tester.pumpAndSettle();

    expect(find.text('Dawn'), findsNothing);
    expect(find.byType(IconButton), findsNothing);
  });
}

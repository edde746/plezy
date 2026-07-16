import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focusable_action_bar.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/music/queue_sheet.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/music/music_playback_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:plezy/widgets/music/track_row.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/prefs.dart';

MediaItem _track(String id, String title) => testMediaItem(
  id: id,
  backend: MediaBackend.plex,
  kind: MediaKind.track,
  title: title,
  parentId: 'album_1',
  parentTitle: 'First Light',
  grandparentId: 'artist_1',
  grandparentTitle: 'Test Artist',
  durationMs: 180000,
  serverId: 'server_1',
  serverName: 'Server',
);

/// Fixed-state fake queue: three tracks, playing the middle one — so the
/// sheet renders history, current, and upcoming rows at once.
class _FakeQueueService extends StubMusicPlaybackService {
  final List<MediaItem> tracks;
  final List<int> jumps = [];

  _FakeQueueService(this.tracks);

  @override
  bool get isAvailable => true;

  @override
  MediaItem? get currentTrack => tracks[1];

  @override
  MusicPlaybackStatus get status => MusicPlaybackStatus.playing;

  @override
  List<MediaItem> get queue => tracks;

  @override
  int get currentIndex => 1;

  @override
  Future<void> jumpTo(int index) async {
    jumps.add(index);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
    await SettingsService.getInstance();
  });

  Widget wrap(MusicPlaybackService service) {
    final manager = MultiServerManager();
    final multiServerProvider = MultiServerProvider(manager, DataAggregationService(manager));
    addTearDown(service.dispose);
    addTearDown(() {
      multiServerProvider.dispose();
      manager.dispose();
    });

    return TranslationProvider(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
          ChangeNotifierProvider<MusicPlaybackService>.value(value: service),
        ],
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: const Scaffold(body: SizedBox(width: 500, height: 700, child: QueueSheet())),
        ),
      ),
    );
  }

  testWidgets('renders header and the full queue including history', (tester) async {
    final service = _FakeQueueService([_track('t1', 'Alpha'), _track('t2', 'Beta'), _track('t3', 'Gamma')]);

    await tester.pumpWidget(wrap(service));
    // pumpAndSettle would never settle: the current-track equalizer animates
    // forever while the fake reports "playing".
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Header: title + total track count.
    expect(find.text(t.music.queue), findsOneWidget);
    expect(find.text(t.music.trackCount(n: 3)), findsOneWidget);

    // The whole queue renders as TrackRows: played, current, and upcoming.
    expect(find.byType(TrackRow), findsNWidgets(3));
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Gamma'), findsOneWidget);
  });

  testWidgets('renders all queue header action icons at 20px', (tester) async {
    final service = _FakeQueueService([_track('t1', 'Alpha'), _track('t2', 'Beta'), _track('t3', 'Gamma')]);

    await tester.pumpWidget(wrap(service));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final headerIcons = tester
        .widgetList<AppIcon>(find.descendant(of: find.byType(FocusableActionBar), matching: find.byType(AppIcon)))
        .toList();

    expect(headerIcons, hasLength(3));
    expect(headerIcons.map((icon) => icon.size), everyElement(20));
  });

  testWidgets('tapping a played or upcoming row jumps to its queue index', (tester) async {
    final service = _FakeQueueService([_track('t1', 'Alpha'), _track('t2', 'Beta'), _track('t3', 'Gamma')]);

    await tester.pumpWidget(wrap(service));
    // pumpAndSettle would never settle: the current-track equalizer animates
    // forever while the fake reports "playing".
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Gamma'));
    await tester.pump();
    await tester.tap(find.text('Alpha'));
    await tester.pump();

    expect(service.jumps, [2, 0]);
  });
}

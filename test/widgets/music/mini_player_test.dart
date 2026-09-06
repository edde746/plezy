import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/focus/focusable_action_bar.dart';
import 'package:plezy/focus/focusable_wrapper.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/download_models.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/providers/download_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/music/music_playback_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/music_navigation.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:plezy/widgets/music/mini_player.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/multi_server_fixtures.dart';
import '../../test_helpers/prefs.dart';
import '../../test_helpers/profile_stack.dart';
import '../../test_helpers/stub_music_playback_service.dart';

final _track = testMediaItem(
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

class _RecordingNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
  }
}

class _FakeDownloadProvider extends ChangeNotifier implements DownloadProvider {
  @override
  DownloadProgress? getProgress(String globalKey) => null;

  @override
  bool hasSyncRule(String globalKey) => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fixed-state fake: reports a playing session with a single-track queue.
class _FakeMusicService extends StubMusicPlaybackService {
  MediaItem? track;
  final StreamController<Duration> _positionController = StreamController<Duration>.broadcast(sync: true);
  Duration _position = Duration.zero;
  int previousCalls = 0;
  int toggleCalls = 0;
  int nextCalls = 0;
  int stopCalls = 0;
  final List<Duration> seekCalls = [];

  _FakeMusicService({this.track});

  @override
  MediaItem? get currentTrack => track;

  @override
  MusicPlaybackStatus get status => track == null ? MusicPlaybackStatus.idle : MusicPlaybackStatus.playing;

  @override
  Duration get position => _position;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Duration? get duration => track == null ? null : const Duration(minutes: 3);

  @override
  List<MediaItem> get queue => track == null ? const [] : [track!];

  @override
  int get currentIndex => track == null ? -1 : 0;

  void emitPosition(Duration position) {
    _position = position;
    _positionController.add(position);
  }

  void advanceTo(MediaItem next) {
    track = next;
    _position = Duration.zero;
    notifyListeners();
  }

  @override
  Future<void> previous() async {
    previousCalls++;
  }

  @override
  Future<void> togglePlayPause() async {
    toggleCalls++;
  }

  @override
  Future<void> next() async {
    nextCalls++;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  @override
  Future<void> seek(Duration position) async {
    seekCalls.add(position);
  }

  @override
  void dispose() {
    _positionController.close();
    super.dispose();
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

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
  });

  Widget wrap({
    required MusicPlaybackService service,
    required MusicUiRouteObserver observer,
    TargetPlatform platform = TargetPlatform.android,
    NavigatorObserver? navigatorObserver,
    ActiveProfileProvider? activeProfileProvider,
    DownloadProvider? downloadProvider,
    MiniPlayerInsetController? insets,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    addTearDown(service.dispose);
    addTearDown(observer.suppress.dispose);
    final multiServerProvider = testMultiServer().provider;

    return TranslationProvider(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
          ChangeNotifierProvider<MusicPlaybackService>.value(value: service),
          if (insets != null)
            ChangeNotifierProvider<MiniPlayerInsetController>.value(value: insets)
          else
            ChangeNotifierProvider<MiniPlayerInsetController>(create: (_) => MiniPlayerInsetController()),
          Provider<MusicUiRouteObserver>.value(value: observer),
          if (activeProfileProvider != null)
            ChangeNotifierProvider<ActiveProfileProvider>.value(value: activeProfileProvider),
          if (downloadProvider != null) ChangeNotifierProvider<DownloadProvider>.value(value: downloadProvider),
        ],
        child: MaterialApp(
          theme: monoTheme(dark: true).copyWith(platform: platform),
          navigatorObservers: [?navigatorObserver],
          builder: (context, child) => Directionality(textDirection: textDirection, child: child!),
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

  testWidgets('floats above the bottom bar in portrait and beside the rail in landscape', (tester) async {
    final service = _FakeMusicService(track: _track);
    final observer = MusicUiRouteObserver();
    final insets = MiniPlayerInsetController();
    addTearDown(insets.dispose);

    await tester.pumpWidget(wrap(service: service, observer: observer, insets: insets));
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('mini_player_card'));
    final screen = tester.getSize(find.byType(MaterialApp));

    insets.setNavInsets(bottom: 80, start: 0);
    await tester.pumpAndSettle();
    var rect = tester.getRect(card);
    expect(rect.left, 12);
    expect(screen.height - rect.bottom, 12 + 80);

    insets.setNavInsets(bottom: 0, start: 80);
    await tester.pumpAndSettle();
    rect = tester.getRect(card);
    expect(rect.left, 12 + 80);
    expect(rect.right, screen.width - 12);
    expect(screen.height - rect.bottom, 12);

    // A pushed route covers the shell: both insets fall away together.
    insets.setNavBarSuspended(true);
    await tester.pumpAndSettle();
    rect = tester.getRect(card);
    expect(rect.left, 12);
    expect(screen.height - rect.bottom, 12);
  });

  for (final direction in TextDirection.values) {
    testWidgets('keeps landscape controls clear of system insets in ${direction.name}', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 410);
      tester.view.padding = const FakeViewPadding(left: 24, right: 48, bottom: 20);
      addTearDown(tester.view.reset);
      final service = _FakeMusicService(track: _track);
      final observer = MusicUiRouteObserver();
      final insets = MiniPlayerInsetController()..setNavInsets(bottom: 0, start: 80);
      addTearDown(insets.dispose);

      await tester.pumpWidget(wrap(service: service, observer: observer, insets: insets, textDirection: direction));
      await tester.pumpAndSettle();
      final card = find.byKey(const ValueKey('mini_player_card'));
      var rect = tester.getRect(card);
      final isLtr = direction == TextDirection.ltr;
      expect(rect.left, 12 + (isLtr ? 80 : 24));
      expect(rect.right, 900 - 12 - (isLtr ? 48 : 80));
      expect(rect.bottom, 410 - 12 - 20);

      // Pushing content hides the rail, not the operating system's insets.
      insets.setNavBarSuspended(true);
      await tester.pumpAndSettle();
      rect = tester.getRect(card);
      expect(rect.left, 12 + 24);
      expect(rect.right, 900 - 12 - 48);
      final next = find.ancestor(
        of: find.byWidgetPredicate((widget) => widget is AppIcon && widget.icon == Symbols.skip_next_rounded),
        matching: find.byType(IconButton),
      );
      final target = tester.getRect(next);
      expect(target.left, greaterThanOrEqualTo(24));
      expect(target.right, lessThanOrEqualTo(900 - 48));
      await tester.tap(next);
      await tester.pump();
      expect(service.nextCalls, 1);

      insets.setNavBarSuspended(false);
      await tester.pumpAndSettle();
      rect = tester.getRect(card);
      expect(rect.left, 12 + (isLtr ? 80 : 24));
      expect(rect.right, 900 - 12 - (isLtr ? 48 : 80));
    });
  }

  testWidgets('details control announces the current title and artist exactly once', (tester) async {
    final semantics = tester.ensureSemantics();
    final service = _FakeMusicService(track: _track);
    final observer = MusicUiRouteObserver();

    await tester.pumpWidget(wrap(service: service, observer: observer));
    await tester.pumpAndSettle();

    var finder = find.bySemanticsLabel('Dawn');
    expect(finder, findsOneWidget);
    expect(tester.getSemantics(finder).getSemanticsData().value, 'Test Artist');
    expect(find.bySemanticsLabel('Test Artist'), findsNothing);

    service.advanceTo(
      testMediaItem(
        id: 'track_2',
        backend: MediaBackend.plex,
        kind: MediaKind.track,
        title: 'Noon',
        grandparentId: 'artist_2',
        grandparentTitle: 'Second Artist',
        durationMs: 180000,
        serverId: 'server_1',
      ),
    );
    await tester.pumpAndSettle();

    finder = find.bySemanticsLabel('Noon');
    expect(finder, findsOneWidget);
    expect(tester.getSemantics(finder).getSemanticsData().value, 'Second Artist');
    expect(find.bySemanticsLabel('Second Artist'), findsNothing);
    semantics.dispose();
  });

  testWidgets('progress resets immediately when the current track changes', (tester) async {
    final nextTrack = testMediaItem(
      id: 'track_2',
      backend: MediaBackend.plex,
      kind: MediaKind.track,
      title: 'Noon',
      durationMs: 180000,
      serverId: 'server_1',
    );
    final service = _FakeMusicService(track: _track);
    final observer = MusicUiRouteObserver();

    await tester.pumpWidget(wrap(service: service, observer: observer));
    await tester.pumpAndSettle();
    service.emitPosition(const Duration(minutes: 2));
    await tester.pump();

    Iterable<double?> progressWidths() => tester
        .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
        .where((box) => box.heightFactor == 1)
        .map((box) => box.widthFactor);

    expect(progressWidths(), contains(closeTo(2 / 3, 0.001)));

    service.advanceTo(nextTrack);
    await tester.pump();

    expect(progressWidths(), contains(0.0));
    expect(progressWidths(), isNot(contains(closeTo(2 / 3, 0.001))));
  });

  testWidgets('tapping the card edge opens the named Now Playing route', (tester) async {
    final service = _FakeMusicService(track: _track);
    final observer = MusicUiRouteObserver();
    final navigatorObserver = _RecordingNavigatorObserver();

    await tester.pumpWidget(wrap(service: service, observer: observer, navigatorObserver: navigatorObserver));
    await tester.pumpAndSettle();

    final cardRect = tester.getRect(find.byKey(const ValueKey('mini_player_dismiss')));
    await tester.tapAt(Offset(cardRect.left + 2, cardRect.center.dy));

    final route = navigatorObserver.pushedRoutes.last;
    expect(route.settings.name, kNowPlayingRouteName);
    expect(service.previousCalls, 0);
    expect(service.toggleCalls, 0);
    expect(service.nextCalls, 0);
    expect(service.stopCalls, 0);

    route.navigator!.removeRoute(route);
  });

  testWidgets('desktop transport buttons own their actions without opening Now Playing', (tester) async {
    final service = _FakeMusicService(track: _track);
    final observer = MusicUiRouteObserver();
    final navigatorObserver = _RecordingNavigatorObserver();

    await tester.pumpWidget(
      wrap(service: service, observer: observer, platform: TargetPlatform.macOS, navigatorObserver: navigatorObserver),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(t.music.previousTrack));
    await tester.tap(find.byTooltip(t.common.pause));
    await tester.tap(find.byTooltip(t.music.nextTrack));
    await tester.tap(find.byTooltip(t.music.stopPlayback));

    expect(service.previousCalls, 1);
    expect(service.toggleCalls, 1);
    expect(service.nextCalls, 1);
    expect(service.stopCalls, 1);
    expect(navigatorObserver.pushedRoutes.where((route) => route.settings.name == kNowPlayingRouteName), isEmpty);
  });

  testWidgets('desktop close icon alone is 20px while transport icons remain 24px', (tester) async {
    final service = _FakeMusicService(track: _track);
    final observer = MusicUiRouteObserver();

    await tester.pumpWidget(wrap(service: service, observer: observer, platform: TargetPlatform.macOS));
    await tester.pumpAndSettle();

    final icons = tester
        .widgetList<AppIcon>(find.descendant(of: find.byType(FocusableActionBar), matching: find.byType(AppIcon)))
        .toList();

    expect(icons, hasLength(4));
    expect(icons.singleWhere((icon) => icon.icon == Symbols.close_rounded).size, 20);
    expect(icons.where((icon) => icon.icon != Symbols.close_rounded).map((icon) => icon.size), everyElement(24));
  });

  testWidgets('keyboard long-press anchors the context menu to the focused card instead of a stale pointer', (
    tester,
  ) async {
    final stack = await ProfileStack.create(withStorage: false);
    final downloadProvider = _FakeDownloadProvider();
    addTearDown(() async {
      await stack.dispose();
      downloadProvider.dispose();
    });
    final service = _FakeMusicService(track: _track);
    final observer = MusicUiRouteObserver();

    await tester.pumpWidget(
      wrap(
        service: service,
        observer: observer,
        activeProfileProvider: stack.active,
        downloadProvider: downloadProvider,
      ),
    );
    await tester.pumpAndSettle();

    final card = find.byKey(const ValueKey('mini_player_dismiss'));
    final cardRect = tester.getRect(card);
    final gesture = await tester.startGesture(Offset(cardRect.left + 4, cardRect.center.dy));
    await tester.pump(const Duration(milliseconds: 150));
    await gesture.cancel();
    await tester.pump();

    tester.widget<FocusableWrapper>(find.byType(FocusableWrapper)).focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 550));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    final playMenuIcon = find.byWidgetPredicate(
      (widget) => widget is AppIcon && widget.icon == Symbols.play_arrow_rounded,
    );
    expect(playMenuIcon, findsOneWidget);
    final menuSurface = find.ancestor(of: playMenuIcon, matching: find.byType(BottomSheet));
    expect(menuSurface, findsOneWidget);
    expect(tester.getCenter(menuSurface).dx, closeTo(cardRect.center.dx, 0.1));

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
  });

  testWidgets('stays hidden while a named suppressing route is active', (tester) async {
    final service = _FakeMusicService(track: _track);
    final observer = MusicUiRouteObserver();

    await tester.pumpWidget(wrap(service: service, observer: observer));
    await tester.pumpAndSettle();
    expect(find.text('Dawn'), findsOneWidget);

    final route = MaterialPageRoute<void>(
      settings: const RouteSettings(name: kNowPlayingRouteName),
      builder: (_) => const SizedBox.shrink(),
    );
    observer.didPush(route, null);
    await tester.pumpAndSettle();
    expect(find.text('Dawn'), findsNothing);

    observer.didRemove(route, null);
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

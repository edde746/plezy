import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/mpv/player/player_base.dart';
import 'package:plezy/providers/account_preferences_controller.dart';
import 'package:plezy/providers/companion_remote_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/providers/shader_provider.dart';
import 'package:plezy/screens/video_player/widgets/player_prompt_overlays.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/music/music_playback_service.dart';
import 'package:plezy/services/offline_watch_sync_service.dart';
import 'package:plezy/services/playback_coordinator.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/video_player_navigation.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import 'package:plezy/widgets/video_controls/video_controls.dart';
import 'package:provider/provider.dart';

import 'hdr_startup.dart';
import 'io_fakes.dart';
import 'mock_player_channels.dart';
import 'multi_server_fixtures.dart';
import 'playback_report_fakes.dart';
import 'pump.dart';
import 'stub_music_playback_service.dart';

/// Per-file setup for widget tests that run a [VideoPlayerScreen] through
/// startup, first frame and shutdown. One player screen per file: a second
/// screen in the same isolate never reaches `initialize` (see
/// [installHdrStartupHarness]).
class PlayerScreenHarness {
  late Directory _tmpRoot;
  late PathProviderPlatform _previousPathProvider;
  late AppDatabase db;

  Future<void> setUp() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await initializeDateFormatting('en');
    _tmpRoot = await Directory.systemTemp.createTemp('player_screen_test_');
    _previousPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = FakePathProvider(_tmpRoot);
    await installHdrStartupHarness();
    DownloadStorageService.resetForTesting();
    await DownloadStorageService.instance.initialize(SettingsService.instance);
    db = AppDatabase.forTesting(NativeDatabase.memory());
  }

  Future<void> tearDown() async {
    await db.close();
    DownloadStorageService.resetForTesting();
    SettingsService.resetForTesting();
    PathProviderPlatform.instance = _previousPathProvider;
    if (await _tmpRoot.exists()) await _tmpRoot.delete(recursive: true);
  }
}

/// The screen a [runPlayerScreen] body drives.
class PlayerScreenRun {
  PlayerScreenRun(this.tester, this.key);

  final WidgetTester tester;
  final GlobalKey<VideoPlayerScreenState> key;

  VideoPlayerScreenState get state => key.currentState!;
  PlayerBase get player => state.player! as PlayerBase;

  /// The buffering overlay's first-frame latch, or null before it is built.
  ValueListenable<bool>? get hasFirstFrame {
    final overlays = find.byType(VideoPlayerBufferingOverlay).evaluate();
    if (overlays.isEmpty) return null;
    return (overlays.single.widget as VideoPlayerBufferingOverlay).hasFirstFrame;
  }

  /// Drives the source switch [start] begins to its outcome.
  Future<PlaybackSourceChangeOutcome?> switchSource(
    Future<PlaybackSourceChangeOutcome> Function(VideoPlayerScreenState state) start,
  ) async {
    PlaybackSourceChangeOutcome? outcome;
    final switching = start(state).then((value) => outcome = value);
    // Drift/database work needs real-event-loop yields.
    for (var i = 0; i < 400 && outcome == null; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (outcome == null) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
      }
    }
    await switching;
    return outcome;
  }
}

/// Pushes [screen] over a browse page, with the providers and platform
/// channels a run through first frame and shutdown needs, and runs [body]
/// against it. [onLoadfile] answers each mpv `loadfile`, with the URL it opens;
/// mpv's `initialize` succeeds and other native calls return nothing.
Future<void> runPlayerScreen(
  WidgetTester tester, {
  required PlayerScreenHarness harness,
  required MediaServerClient client,
  required VideoPlayerScreen Function(GlobalKey<VideoPlayerScreenState> key) screen,
  required void Function(PlayerScreenRun run, String url) onLoadfile,
  required Future<void> Function(PlayerScreenRun run) body,
}) async {
  final multi = testMultiServer(clients: [client]);
  final offlineWatch = OfflineWatchSyncService(database: harness.db, serverManager: multi.manager);
  final accountPreferences = AccountPreferencesController();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const windowChannel = MethodChannel('window_manager');
  // The run goes through first frame and shutdown, which activates and cancels
  // the OS media-controls event stream; an unmocked EventChannel reports its
  // MissingPluginException as a test failure.
  const mediaControlMethods = MethodChannel('com.edde746.os_media_controls/methods');
  const mediaControlEvents = MethodChannel('com.edde746.os_media_controls/events');
  messenger.setMockMethodCallHandler(windowChannel, (call) async => call.method.startsWith('is') ? false : null);
  messenger.setMockMethodCallHandler(mediaControlMethods, (call) async => null);
  messenger.setMockMethodCallHandler(mediaControlEvents, (call) async => null);
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    messenger.setMockMethodCallHandler(windowChannel, null);
    messenger.setMockMethodCallHandler(mediaControlMethods, null);
    messenger.setMockMethodCallHandler(mediaControlEvents, null);
    tester.view.reset();
    offlineWatch.dispose();
    accountPreferences.dispose();
  });

  final navigator = GlobalKey<NavigatorState>();
  final key = GlobalKey<VideoPlayerScreenState>();
  final run = PlayerScreenRun(tester, key);

  await withMockPlayerChannels(
    methodChannelName: 'com.plezy/mpv_player',
    eventChannelName: 'com.plezy/mpv_player/events',
    methodHandler: (call) async {
      if (call.method == 'initialize') return true;
      if (call.method != 'command') return null;
      final args = (call.arguments as Map?)?['args'];
      if (args is! List || args.isEmpty || args.first != 'loadfile') return null;
      onLoadfile(run, args[1] as String);
      return null;
    },
    testBody: () async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => PlaybackStateProvider()),
            ChangeNotifierProvider<MultiServerProvider>.value(value: multi.provider),
            ChangeNotifierProvider<OfflineWatchSyncService>.value(value: offlineWatch),
            ChangeNotifierProvider<AccountPreferencesController>.value(value: accountPreferences),
            ChangeNotifierProvider(create: (_) => CompanionRemoteProvider()),
            ChangeNotifierProvider(create: (_) => WatchTogetherProvider()),
            ChangeNotifierProvider(create: (_) => ShaderProvider()),
            ChangeNotifierProvider<MusicPlaybackService>(create: (_) => StubMusicPlaybackService()),
            Provider<AppDatabase>.value(value: harness.db),
          ],
          child: MaterialApp(
            navigatorKey: navigator,
            home: const Scaffold(body: Text('Browse')),
          ),
        ),
      );
      unawaited(VideoPlayerRoute(builder: (_) => screen(key)).push(navigator.currentState!));

      await body(run);

      var shutdownDone = false;
      final shutdown = PlaybackCoordinator.instance.shutdownVideo().whenComplete(() => shutdownDone = true);
      await pumpUntil(tester, () => shutdownDone);
      await shutdown;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}

/// A Jellyfin server on `srv-1` with no playback extras; subclasses answer the
/// open.
abstract class FakeStreamClient with PlaybackReportRecorder implements MediaServerClient {
  @override
  ServerId get serverId => ServerId('srv-1');
  @override
  String get serverName => 'Server';
  @override
  MediaBackend get backend => MediaBackend.jellyfin;
  @override
  ServerCapabilities get capabilities => ServerCapabilities.jellyfin;
  @override
  double get watchedThreshold => 0.9;
  @override
  bool get marksWatchedOnPlaybackStopped => true;
  @override
  Map<String, String> get streamHeaders => const {};

  @override
  Future<PlaybackExtras> fetchPlaybackExtras(
    String itemId, {
    String? introPattern,
    String? creditsPattern,
    bool forceChapterFallback = false,
    bool forceRefresh = false,
  }) async => PlaybackExtras(chapters: const [], markers: const []);

  @override
  Future<PlaybackExtras?> fetchPlaybackExtrasFromCacheOnly(
    String itemId, {
    String? introPattern,
    String? creditsPattern,
    bool forceChapterFallback = false,
  }) async => null;

  @override
  Future<void> onPlaybackReport(PlaybackReportCall call) async {}

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

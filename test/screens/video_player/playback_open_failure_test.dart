import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
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
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/mpv/player/player_base.dart';
import 'package:plezy/providers/account_preferences_controller.dart';
import 'package:plezy/providers/companion_remote_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/providers/shader_provider.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/music/music_playback_service.dart';
import 'package:plezy/services/offline_watch_sync_service.dart';
import 'package:plezy/services/playback_coordinator.dart';
import 'package:plezy/services/playback_initialization_types.dart';
import 'package:plezy/services/playback_launch_observer.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/video_player_navigation.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/hdr_startup.dart';
import '../../test_helpers/io_fakes.dart';
import '../../test_helpers/media_items.dart';
import '../../test_helpers/mock_player_channels.dart';
import '../../test_helpers/multi_server_fixtures.dart';
import '../../test_helpers/playback_report_fakes.dart';
import '../../test_helpers/pump.dart';
import '../../test_helpers/stub_music_playback_service.dart';

/// The initial open, accepted by the backend and then failed the way a bad
/// stream URL fails: `loadfile` succeeds and mpv ends the file with
/// `reason=error` afterwards. That used to be a 4 s snackbar on the screen
/// underneath while the route popped — nothing a remote could reach, and a
/// receipt that read `stopped`. One test per file: a second screen in the
/// same isolate never reaches `initialize` (see [installHdrStartupHarness]).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpRoot;
  late PathProviderPlatform previousPathProvider;
  late AppDatabase db;

  setUp(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await initializeDateFormatting('en');
    tmpRoot = await Directory.systemTemp.createTemp('playback_open_failure_test_');
    previousPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = FakePathProvider(tmpRoot);
    await installHdrStartupHarness();
    DownloadStorageService.resetForTesting();
    await DownloadStorageService.instance.initialize(SettingsService.instance);
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
    DownloadStorageService.resetForTesting();
    SettingsService.resetForTesting();
    PathProviderPlatform.instance = previousPathProvider;
    if (await tmpRoot.exists()) {
      await tmpRoot.delete(recursive: true);
    }
  });

  testWidgets('a backend-failed open stays on a focused failure view, ends the receipt failed, and Retry reopens', (
    tester,
  ) async {
    final client = _StreamClient();
    final multi = testMultiServer(clients: [client]);
    final offlineWatch = OfflineWatchSyncService(database: db, serverManager: multi.manager);
    final accountPreferences = AccountPreferencesController();
    final observer = PlaybackLaunchObserver(isCurrent: () => true);
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const windowChannel = MethodChannel('window_manager');
    // The recovered playback brings the OS media session up, which activates
    // and cancels its event stream; an unmocked EventChannel reports its
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
    final loadfileUrls = <String>[];
    var stops = 0;

    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        if (call.method == 'initialize') return true;
        if (call.method != 'command') return null;
        final args = (call.arguments as Map?)?['args'];
        if (args is! List || args.isEmpty) return null;
        if (args.first == 'stop') stops++;
        if (args.first != 'loadfile') return null;
        loadfileUrls.add(args[1] as String);
        final player = key.currentState!.player! as PlayerBase;
        player.handlePlayerEvent('start-file', {'sourceId': loadfileUrls.length});
        if (loadfileUrls.length == 1) {
          // The load was accepted; the demuxer refuses the URL afterwards -
          // and keeps refusing: a failed HLS open falls back to mpv's
          // playlist parser, which walks the manifest's entries and fails
          // each in turn, so the same dead load reports more than once.
          for (var i = 0; i < 3; i++) {
            player.handlePlayerEvent('end-file', {
              'sourceId': 1,
              'reason': 4,
              'message': 'Failed to open https://example.invalid/open-failure',
            });
          }
        } else {
          player.handlePlayerEvent('file-loaded', {'sourceId': loadfileUrls.length});
          player.handlePlayerEvent('playback-restart', {'sourceId': loadfileUrls.length, 'positionSeconds': 0.0});
        }
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
              Provider<AppDatabase>.value(value: db),
            ],
            child: MaterialApp(
              navigatorKey: navigator,
              home: const Scaffold(body: Text('Browse')),
            ),
          ),
        );
        unawaited(
          VideoPlayerRoute(
            builder: (_) => VideoPlayerScreen(
              key: key,
              metadata: testMediaItem(
                id: 'open-failure',
                serverId: 'srv-1',
                title: 'Open failure',
                backend: MediaBackend.jellyfin,
              ),
              selectedQualityPreset: TranscodeQualityPreset.original,
              launchObserver: observer,
            ),
          ).push(navigator.currentState!),
        );

        final failureMessage = t.messages.playbackFailedDetail(
          error: 'Failed to open https://example.invalid/open-failure',
        );
        await pumpUntil(
          tester,
          () => find.text(failureMessage).evaluate().isNotEmpty,
          describe: () => 'loadfiles=$loadfileUrls, no failure view',
        );

        expect(find.byType(CircularProgressIndicator), findsNothing, reason: 'the spinner must not cover the view');
        expect(find.byType(SnackBar), findsNothing);
        expect(find.text('Browse'), findsNothing, reason: 'the route must stay so the viewer can act on the failure');
        expect(key.currentState, isNotNull);
        final retry = find.widgetWithText(FilledButton, t.common.retry);
        expect(retry, findsOneWidget);
        await tester.pump();
        expect(
          FocusManager.instance.primaryFocus?.debugLabel,
          'PlayerInitializationErrorAction',
          reason: 'a D-pad user must land on Retry, not on nothing',
        );
        expect(observer.snapshot(), containsPair('stage', 'failed'));
        expect(observer.snapshot(), containsPair('failure', {'code': 'playbackFailed'}));
        expect(observer.ownsPlayback, isTrue, reason: 'the screen still owns the player; only the receipt is terminal');
        expect(
          stops,
          1,
          reason:
              'the failed load is stopped exactly once: a stop halts the playlist walk, and the '
              'repeated errors from the same dead load must not re-run the failure policy',
        );

        expect(
          key.currentState!.debugMediaControlsActiveForTesting,
          isFalse,
          reason: 'a failed open has no playback for the OS media session to describe',
        );

        await tester.tap(retry);
        await pumpUntil(tester, () => loadfileUrls.length == 2, describe: () => 'loadfiles=$loadfileUrls');
        expect(loadfileUrls[1], loadfileUrls[0], reason: 'Retry re-runs the same open');
        await pumpUntil(
          tester,
          () => find.text(failureMessage).evaluate().isEmpty,
          describe: () => 'failure view still up after the retried open rendered',
        );
        expect(find.widgetWithText(FilledButton, t.common.retry), findsNothing);
        await pumpUntil(
          tester,
          () => key.currentState!.debugMediaControlsActiveForTesting,
          describe: () => 'the recovered playback never brought the OS media session up',
        );

        var shutdownDone = false;
        final shutdown = PlaybackCoordinator.instance.shutdownVideo().whenComplete(() => shutdownDone = true);
        await pumpUntil(tester, () => shutdownDone);
        await shutdown;
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  });
}

/// Resolves to a stream URL the mocked mpv plane accepts and then fails.
class _StreamClient with PlaybackReportRecorder implements MediaServerClient {
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
  Future<PlaybackInitializationResult> getPlaybackInitialization(PlaybackInitializationOptions options) async =>
      PlaybackInitializationResult(
        availableVersions: const [],
        videoUrl: 'https://example.invalid/${options.metadata.id}',
      );

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

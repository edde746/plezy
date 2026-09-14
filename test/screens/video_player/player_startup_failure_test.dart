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
import 'package:plezy/mpv/models.dart';
import 'package:plezy/mpv/player/player_base.dart';
import 'package:plezy/providers/account_preferences_controller.dart';
import 'package:plezy/providers/companion_remote_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/offline_watch_sync_service.dart';
import 'package:plezy/services/playback_coordinator.dart';
import 'package:plezy/services/playback_initialization_types.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/hdr_startup.dart';
import '../../test_helpers/io_fakes.dart';
import '../../test_helpers/media_items.dart';
import '../../test_helpers/mock_player_channels.dart';
import '../../test_helpers/multi_server_fixtures.dart';
import '../../test_helpers/playback_report_fakes.dart';
import '../../test_helpers/pump.dart';

/// The initial playback start, failed by a server that answers the stream with
/// an error the way the original report described: mpv ends the file with
/// `reason=error`, the screen latches the fatal error, and the `loadfile` that
/// raised it throws out of the open.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpRoot;
  late PathProviderPlatform previousPathProvider;
  late AppDatabase db;

  setUp(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await initializeDateFormatting('en');
    tmpRoot = await Directory.systemTemp.createTemp('player_startup_failure_test_');
    previousPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = FakePathProvider(tmpRoot);
    // Forces the Linux video plane, which is the only thing that lets a
    // headless test reach `initialize` and therefore the start flow at all.
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

  // Regression for the startup spinner surviving behind the error dialog: the
  // playback-generation predicate used to treat a latched fatal player error
  // as "this attempt is no longer current", which is exactly the state the
  // start flow's own failure handling — hiding the spinner and reporting the
  // failure — is guarded by. This pins the commit that stopped conflating
  // supersession with termination: `!_hasFatalPlaybackError` left
  // `_isCurrentPlaybackGeneration` and is now spelled out on the reload
  // guard alone, because only a reload has a previous session to roll back
  // to instead of an error view to raise.
  testWidgets('a fatal player error during the initial start clears the loading spinner and reports the failure', (
    tester,
  ) async {
    final client = _FailingStreamClient();
    final multi = testMultiServer(clients: [client]);
    final offlineWatch = OfflineWatchSyncService(database: db, serverManager: multi.manager);
    final accountPreferences = AccountPreferencesController();
    // The chrome the cleared spinner reveals is the production one: desktop
    // controls query the real window plugin, and the header renders the clock
    // and the Watch Together indicator.
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const windowChannel = MethodChannel('window_manager');
    messenger.setMockMethodCallHandler(windowChannel, (call) async => call.method.startsWith('is') ? false : null);
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      messenger.setMockMethodCallHandler(windowChannel, null);
      tester.view.reset();
      offlineWatch.dispose();
      accountPreferences.dispose();
    });

    final key = GlobalKey<VideoPlayerScreenState>();
    var loadfileCalls = 0;

    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        if (call.method == 'initialize') return true;
        if (call.method != 'command') return null;
        final args = (call.arguments as Map?)?['args'];
        if (args is! List || args.isEmpty || args.first != 'loadfile') return null;
        loadfileCalls++;
        // The server rejected the stream with HTTP 500, so mpv ends the file
        // with reason=error before the failed `loadfile` reply lands.
        (key.currentState!.player! as PlayerBase).handlePlayerEvent('end-file', {
          'reason': 4,
          'message': 'HTTP 500',
          'cause': PlayerError.serverHttp500,
        });
        throw PlatformException(code: 'COMMAND_FAILED', message: 'loadfile failed');
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
              Provider<AppDatabase>.value(value: db),
            ],
            child: MaterialApp(
              home: VideoPlayerScreen(
                key: key,
                metadata: testMediaItem(
                  id: 'movie-fatal-start',
                  serverId: 'srv-1',
                  title: 'Fatal start',
                  backend: MediaBackend.jellyfin,
                ),
                // Non-null so startup skips the OfflineModeProvider lookup.
                selectedQualityPreset: TranscodeQualityPreset.original,
              ),
            ),
          ),
        );

        await pumpUntil(tester, () => loadfileCalls > 0, describe: () => 'loadfileCalls=$loadfileCalls');
        await pumpUntil(
          tester,
          () => find.text(t.messages.serverLimitTitle).evaluate().isNotEmpty,
          describe: () => 'no server-limit dialog',
        );

        expect(
          find.byType(CircularProgressIndicator),
          findsNothing,
          reason: 'the loading spinner must not survive behind the error dialog',
        );
        // Only the start flow's own failure handling raises a snackbar here —
        // the dialog branch of the error handler shows no message — so this is
        // what says the failure was actually reported and not swallowed.
        expect(
          find.descendant(of: find.byType(SnackBar), matching: find.textContaining('loadfile failed')),
          findsOneWidget,
          reason: 'the failed start owes the user the error it failed on',
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

/// Resolves to a stream URL the mocked mpv plane then refuses.
class _FailingStreamClient with PlaybackReportRecorder implements MediaServerClient {
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

  // Nothing under test reads these, but the screen's extras load runs anyway
  // and a noSuchMethod miss would surface as an unrelated logged error.
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

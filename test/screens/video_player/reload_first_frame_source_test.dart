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
import 'package:plezy/models/transcode_quality_preset.dart';
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
import 'package:plezy/services/playback_initialization_types.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/video_player_navigation.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import 'package:plezy/widgets/video_controls/video_controls.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/hdr_startup.dart';
import '../../test_helpers/io_fakes.dart';
import '../../test_helpers/media_items.dart';
import '../../test_helpers/mock_player_channels.dart';
import '../../test_helpers/multi_server_fixtures.dart';
import '../../test_helpers/playback_report_fakes.dart';
import '../../test_helpers/pump.dart';
import '../../test_helpers/stub_music_playback_service.dart';

/// An in-place reload resets the first-frame latch before `loadfile`, while
/// the outgoing file is still mpv's active source. A `playback-restart` of
/// that file landing in the window used to latch the replacement as rendered
/// before it had decoded anything: the spinner dropped over a stale picture
/// and everything keyed to the first frame ran against the wrong stream. The
/// latch now waits for the attempt's own file. One test per file: a second
/// screen in the same isolate never reaches `initialize` (see
/// [installHdrStartupHarness]).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpRoot;
  late PathProviderPlatform previousPathProvider;
  late AppDatabase db;

  setUp(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await initializeDateFormatting('en');
    tmpRoot = await Directory.systemTemp.createTemp('reload_first_frame_source_test_');
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

  testWidgets('a restart of the outgoing file during a reload does not reveal the replacement early', (tester) async {
    final client = _StreamClient();
    final multi = testMultiServer(clients: [client]);
    final offlineWatch = OfflineWatchSyncService(database: db, serverManager: multi.manager);
    final accountPreferences = AccountPreferencesController();
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const windowChannel = MethodChannel('window_manager');
    // The flow runs through first frame and shutdown, which activates and
    // cancels the OS media-controls event stream; an unmocked EventChannel
    // reports its MissingPluginException as a test failure.
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

    PlayerBase player() => key.currentState!.player! as PlayerBase;

    ValueListenable<bool>? revealed() {
      final overlays = find.byType(VideoPlayerBufferingOverlay).evaluate();
      if (overlays.isEmpty) return null;
      return (overlays.single.widget as VideoPlayerBufferingOverlay).hasFirstFrame;
    }

    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        if (call.method == 'initialize') return true;
        if (call.method != 'command') return null;
        final args = (call.arguments as Map?)?['args'];
        if (args is! List || args.isEmpty || args.first != 'loadfile') return null;
        loadfileUrls.add(args[1] as String);
        if (loadfileUrls.length == 1) {
          player().handlePlayerEvent('start-file', {'sourceId': 1});
          player().handlePlayerEvent('file-loaded', {'sourceId': 1});
          player().handlePlayerEvent('playback-restart', {'sourceId': 1, 'positionSeconds': 0.0});
        } else {
          // The reload has already reset its latch; mpv has not yet ended the
          // outgoing file, so a restart of it (a seek landing late) is still
          // the active source's.
          player().handlePlayerEvent('playback-restart', {'sourceId': 1, 'positionSeconds': 42.0});
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
                id: 'reload-source',
                serverId: 'srv-1',
                title: 'Reload source',
                backend: MediaBackend.jellyfin,
              ),
              selectedQualityPreset: TranscodeQualityPreset.original,
            ),
          ).push(navigator.currentState!),
        );

        await pumpUntil(
          tester,
          () => revealed()?.value == true,
          describe: () => 'loadfiles=$loadfileUrls, first frame never revealed',
        );

        PlaybackSourceChangeOutcome? outcome;
        final switching = key.currentState!
            .debugSwitchPlaybackSourceForTesting(newPreset: TranscodeQualityPreset.p720_2mbps)
            .then((value) => outcome = value);
        // Drift/database work needs real-event-loop yields.
        for (var i = 0; i < 400 && outcome == null; i++) {
          await tester.pump(const Duration(milliseconds: 50));
          if (outcome == null) {
            await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
          }
        }
        await switching;
        expect(outcome, PlaybackSourceChangeOutcome.applied);
        expect(loadfileUrls, hasLength(2));
        expect(loadfileUrls[1], endsWith('/p720_2mbps'));
        await tester.pump();

        expect(
          revealed()?.value,
          isFalse,
          reason: 'the outgoing file\'s restart must not stand in for the replacement\'s first frame',
        );

        player().handlePlayerEvent('end-file', {'sourceId': 1, 'reason': 2});
        player().handlePlayerEvent('start-file', {'sourceId': 2});
        player().handlePlayerEvent('file-loaded', {'sourceId': 2});
        player().handlePlayerEvent('playback-restart', {'sourceId': 2, 'positionSeconds': 0.0});
        await pumpUntil(
          tester,
          () => revealed()?.value == true,
          describe: () => 'the replacement\'s own first frame never revealed',
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

/// Names the requested preset in the URL so each open says which request
/// produced it.
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
        videoUrl: 'https://example.invalid/${options.metadata.id}/${options.qualityPreset.name}',
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

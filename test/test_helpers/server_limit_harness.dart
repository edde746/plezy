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
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/video_player_navigation.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import 'package:provider/provider.dart';

import 'hdr_startup.dart';
import 'io_fakes.dart';
import 'media_items.dart';
import 'mock_player_channels.dart';
import 'multi_server_fixtures.dart';
import 'playback_report_fakes.dart';
import 'pump.dart';
import 'stub_music_playback_service.dart';

/// The raw part URL the fake Plex client hands out at Original quality.
const serverLimitRawUrl = 'https://plex.invalid/library/parts/1/file.mkv';

/// The transcode start URL the fake Plex client hands out for a transcode at
/// [preset]: a capped preset, or any preset with direct play withheld.
String serverLimitTranscodeUrl(TranscodeQualityPreset preset) =>
    'https://plex.invalid/video/:/transcode/universal/start.m3u8?preset=${preset.name}';

/// Text of the HTTP 500 dialog's transcode button.
String get serverLimitPlayLabel => t.messages.serverLimitTranscode;

/// Per-file setup for the server-limit widget tests: one player screen per
/// file, like [installHdrStartupHarness] requires.
class ServerLimitHarness {
  late Directory _tmpRoot;
  late PathProviderPlatform _previousPathProvider;
  late AppDatabase db;

  Future<void> setUp() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await initializeDateFormatting('en');
    _tmpRoot = await Directory.systemTemp.createTemp('server_limit_test_');
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

/// What one server-limit run observed, for the test body to assert on.
class ServerLimitRun {
  ServerLimitRun(this.tester, this.key, this.client);

  final WidgetTester tester;
  final GlobalKey<VideoPlayerScreenState> key;
  final ServerLimitPlexClient client;

  /// Every URL handed to mpv's `loadfile`, in order.
  final List<String> loadfileUrls = [];

  Finder get dialogTitle => find.text(t.messages.serverLimitTitle);
  Finder get playButton => find.text(serverLimitPlayLabel);
}

/// Pumps a Plex-backed on-demand player at [preset] whose opens the server
/// answers with HTTP 500 when [refuses] says so (by 1-based open number and
/// URL), and runs [body] against it.
Future<void> runServerLimitPlayer(
  WidgetTester tester, {
  required ServerLimitHarness harness,
  required TranscodeQualityPreset preset,
  required bool Function(int openNumber, String url) refuses,
  required Future<void> Function(ServerLimitRun run) body,
}) async {
  final client = ServerLimitPlexClient();
  final multi = testMultiServer(clients: [client]);
  final offlineWatch = OfflineWatchSyncService(database: harness.db, serverManager: multi.manager);
  final accountPreferences = AccountPreferencesController();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const windowChannel = MethodChannel('window_manager');
  const mediaControlMethods = MethodChannel('com.edde746.os_media_controls/methods');
  const mediaControlEvents = MethodChannel('com.edde746.os_media_controls/events');
  // Leaving the player on a macOS host restores the window chrome and PiP.
  const macWindowChannel = MethodChannel('com.plezy/window_utils');
  const pipChannel = MethodChannel('com.plezy/pip');
  messenger.setMockMethodCallHandler(windowChannel, (call) async => call.method.startsWith('is') ? false : null);
  messenger.setMockMethodCallHandler(mediaControlMethods, (call) async => null);
  messenger.setMockMethodCallHandler(mediaControlEvents, (call) async => null);
  messenger.setMockMethodCallHandler(macWindowChannel, (call) async => call.method.startsWith('is') ? false : null);
  messenger.setMockMethodCallHandler(pipChannel, (call) async => null);
  messenger.setMockMessageHandler(_wakelockToggleChannel, (message) async => _wakelockCodec.encodeMessage(<Object?>[]));
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    messenger.setMockMethodCallHandler(windowChannel, null);
    messenger.setMockMethodCallHandler(mediaControlMethods, null);
    messenger.setMockMethodCallHandler(mediaControlEvents, null);
    messenger.setMockMethodCallHandler(macWindowChannel, null);
    messenger.setMockMethodCallHandler(pipChannel, null);
    messenger.setMockMessageHandler(_wakelockToggleChannel, null);
    tester.view.reset();
    offlineWatch.dispose();
    accountPreferences.dispose();
  });

  final navigator = GlobalKey<NavigatorState>();
  final key = GlobalKey<VideoPlayerScreenState>();
  final run = ServerLimitRun(tester, key, client);

  await withMockPlayerChannels(
    methodChannelName: 'com.plezy/mpv_player',
    eventChannelName: 'com.plezy/mpv_player/events',
    methodHandler: (call) async {
      if (call.method == 'initialize') return true;
      if (call.method != 'command') return null;
      final args = (call.arguments as Map?)?['args'];
      if (args is! List || args.isEmpty || args.first != 'loadfile') return null;
      final url = args[1] as String;
      run.loadfileUrls.add(url);
      final sourceId = run.loadfileUrls.length;
      final player = key.currentState!.player! as PlayerBase;
      player.handlePlayerEvent('start-file', {'sourceId': sourceId});
      if (refuses(sourceId, url)) {
        // What mpv reports when PMS refuses the request: ffmpeg's warning
        // carrying the status, then the failed load.
        player.handlePlayerEvent('log-message', {
          'prefix': 'ffmpeg',
          'level': 'warn',
          'text': 'https: HTTP error 500 Internal Server Error',
        });
        player.handlePlayerEvent('end-file', {'sourceId': sourceId, 'reason': 4, 'message': 'Failed to open $url'});
      } else {
        player.handlePlayerEvent('file-loaded', {'sourceId': sourceId});
        player.handlePlayerEvent('playback-restart', {'sourceId': sourceId, 'positionSeconds': 0.0});
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
            Provider<AppDatabase>.value(value: harness.db),
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
              id: 'server-limit',
              serverId: 'srv-1',
              title: 'Server limit',
              backend: MediaBackend.plex,
            ),
            selectedQualityPreset: preset,
          ),
        ).push(navigator.currentState!),
      );

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

const _wakelockToggleChannel = 'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle';

/// The wakelock plugin's pigeon codec: its messages ride custom type ids
/// wrapping a plain list of fields.
const _wakelockCodec = _PigeonListCodec();

class _PigeonListCodec extends StandardMessageCodec {
  const _PigeonListCodec();

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) =>
      type >= 128 ? readValue(buffer) : super.readValueOfType(type, buffer);
}

/// A Plex server that can transcode: Original resolves to the raw part URL
/// unless the open forces a transcode, a capped preset to a transcode start
/// URL. Records every request.
class ServerLimitPlexClient with PlaybackReportRecorder implements MediaServerClient {
  final List<PlaybackInitializationOptions> requests = [];

  @override
  ServerId get serverId => ServerId('srv-1');
  @override
  String get serverName => 'Server';
  @override
  MediaBackend get backend => MediaBackend.plex;
  @override
  ServerCapabilities get capabilities => ServerCapabilities.plex;
  @override
  double get watchedThreshold => 0.9;
  @override
  bool get marksWatchedOnPlaybackStopped => true;
  @override
  Map<String, String> get streamHeaders => const {};

  @override
  Future<PlaybackInitializationResult> getPlaybackInitialization(PlaybackInitializationOptions options) async {
    requests.add(options);
    final transcodes = options.forceTranscode || !options.qualityPreset.isOriginal;
    return PlaybackInitializationResult(
      availableVersions: const [],
      videoUrl: transcodes ? serverLimitTranscodeUrl(options.qualityPreset) : serverLimitRawUrl,
      isTranscoding: transcodes,
      playMethod: transcodes ? 'Transcode' : 'DirectPlay',
    );
  }

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

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
import 'package:provider/provider.dart';

import '../../test_helpers/hdr_startup.dart';
import '../../test_helpers/io_fakes.dart';
import '../../test_helpers/media_items.dart';
import '../../test_helpers/mock_player_channels.dart';
import '../../test_helpers/multi_server_fixtures.dart';
import '../../test_helpers/playback_report_fakes.dart';
import '../../test_helpers/pump.dart';
import '../../test_helpers/stub_music_playback_service.dart';

/// The persisted ambient-lighting setting used to be restored right after
/// `loadfile` was issued, when mpv had not decoded anything: `dwidth`/`dheight`
/// answered null and the restore silently did nothing, so the effect only ever
/// came on through the in-player toggle. The mocked core answers the geometry
/// the way mpv does — only once `playback-restart` has been delivered — and
/// the effect must land before that frame is revealed. One test per file: a
/// second screen in the same isolate never reaches `initialize` (see
/// [installHdrStartupHarness]).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpRoot;
  late PathProviderPlatform previousPathProvider;
  late AppDatabase db;

  setUp(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await initializeDateFormatting('en');
    tmpRoot = await Directory.systemTemp.createTemp('ambient_lighting_startup_test_');
    previousPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = FakePathProvider(tmpRoot);
    await installHdrStartupHarness();
    await SettingsService.instance.write(SettingsService.ambientLighting, true);
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

  testWidgets('the persisted ambient lighting setting is applied at the first frame, before it is revealed', (
    tester,
  ) async {
    final client = _StreamClient();
    final multi = testMultiServer(clients: [client]);
    final offlineWatch = OfflineWatchSyncService(database: db, serverManager: multi.manager);
    final accountPreferences = AccountPreferencesController();
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const windowChannel = MethodChannel('window_manager');
    // This flow runs through first frame and shutdown, which activates and
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
    final shaderCommands = <List<String>>[];
    final propertyWrites = <(String, String)>[];
    var loadfiles = 0;
    var firstFrameDelivered = false;
    bool? revealedWhenAmbientShaderLanded;

    ValueListenable<bool>? revealed() {
      final overlays = find.byType(VideoPlayerBufferingOverlay).evaluate();
      if (overlays.isEmpty) return null;
      return (overlays.single.widget as VideoPlayerBufferingOverlay).hasFirstFrame;
    }

    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        switch (call.method) {
          case 'initialize':
            return true;
          case 'getProperty':
            // mpv only knows the displayed picture size once a decoded frame
            // has reached the VO; until then the property is unavailable.
            final name = (call.arguments as Map)['name'];
            if (!firstFrameDelivered) return null;
            return switch (name) {
              'dwidth' => '1920',
              'dheight' => '800',
              _ => null,
            };
          case 'setProperty':
            final args = call.arguments as Map;
            propertyWrites.add((args['name'] as String, args['value'].toString()));
            return null;
          case 'command':
            final args = ((call.arguments as Map)['args'] as List).cast<String>();
            if (args.first == 'loadfile') {
              loadfiles++;
              final player = key.currentState!.player! as PlayerBase;
              player.handlePlayerEvent('start-file', {'sourceId': loadfiles});
              player.handlePlayerEvent('file-loaded', {'sourceId': loadfiles});
            } else if (args.length >= 2 && args[0] == 'change-list' && args[1] == 'glsl-shaders') {
              shaderCommands.add(args);
              if (args[2] == 'append' && args[3].endsWith('ambient_lighting.glsl')) {
                revealedWhenAmbientShaderLanded = revealed()?.value;
              }
            }
            return null;
          default:
            return null;
        }
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
                id: 'ambient-start',
                serverId: 'srv-1',
                title: 'Ambient start',
                backend: MediaBackend.jellyfin,
              ),
              selectedQualityPreset: TranscodeQualityPreset.original,
            ),
          ).push(navigator.currentState!),
        );

        // The start flow applies the saved shader preset (a chain clear) in
        // the same hook that used to restore ambient lighting; once it has
        // landed, any restore attempted there has already read null geometry.
        await pumpUntil(
          tester,
          () => shaderCommands.any((args) => args[2] == 'clr'),
          describe: () => 'loadfiles=$loadfiles shaderCommands=$shaderCommands',
        );
        await tester.pump();
        expect(shaderCommands.where((args) => args[2] == 'append'), isEmpty);
        expect(revealed()?.value, isFalse, reason: 'the frame stays behind the loading UI until mpv presents one');

        firstFrameDelivered = true;
        (key.currentState!.player! as PlayerBase).handlePlayerEvent('playback-restart', {
          'sourceId': 1,
          'positionSeconds': 0.0,
        });

        await pumpUntil(
          tester,
          () => revealed()?.value == true,
          describe: () => 'shaderCommands=$shaderCommands writes=$propertyWrites',
        );

        final appends = shaderCommands.where((args) => args[2] == 'append').toList();
        expect(appends, hasLength(1), reason: 'the persisted setting applies exactly once at start');
        expect(appends.single[3], endsWith('ambient_lighting.glsl'));
        expect(
          revealedWhenAmbientShaderLanded,
          isFalse,
          reason: 'the effect must be in place before the first frame is revealed, or the letterbox flashes',
        );
        // Picture aspect (1920/800) for subtitle placement, then the fill.
        expect(propertyWrites, contains(('sub-video-rect-aspect', '2.4')));
        expect(propertyWrites, contains(('keepaspect', 'no')));

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

/// Resolves to a stream URL the mocked mpv plane accepts.
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

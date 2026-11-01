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
import 'package:plezy/mpv/mpv.dart';
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
import 'package:plezy/services/playback_subtitle_resolver.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/track_selection_service.dart';
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

/// A pick in the player's audio list must survive a reload: the reload
/// carries the committed source stream, which the pick has to move. One test
/// per file: a second screen in the same isolate never reaches `initialize`
/// (see [installHdrStartupHarness]).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpRoot;
  late PathProviderPlatform previousPathProvider;
  late AppDatabase db;

  setUp(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await initializeDateFormatting('en');
    tmpRoot = await Directory.systemTemp.createTemp('reload_keeps_picked_audio_test_');
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

  testWidgets('a reload carries the audio picked in the player, not the stream first opened', (tester) async {
    final client = _StreamClient();
    final multi = testMultiServer(clients: [client]);
    final offlineWatch = OfflineWatchSyncService(database: db, serverManager: multi.manager);
    final accountPreferences = AccountPreferencesController();
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const windowChannel = MethodChannel('window_manager');
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
    var loads = 0;
    // The engine's audio list, in source order; the selected one plays.
    var playing = 'eng';

    PlayerBase player() => key.currentState!.player! as PlayerBase;

    void emitTrackList(int sourceId) => player().handlePropertyChange('track-list', [
      for (final (index, language) in ['eng', 'fre', 'ger'].indexed)
        {'type': 'audio', 'id': '${index + 1}', 'lang': language, 'selected': language == playing},
    ], sourceId: sourceId);

    ValueListenable<bool>? revealed() {
      final overlays = find.byType(VideoPlayerBufferingOverlay).evaluate();
      if (overlays.isEmpty) return null;
      return (overlays.single.widget as VideoPlayerBufferingOverlay).hasFirstFrame;
    }

    Future<PlaybackSourceChangeOutcome?> switchSource(
      Future<PlaybackSourceChangeOutcome> Function(VideoPlayerScreenState state) start,
    ) async {
      PlaybackSourceChangeOutcome? outcome;
      final switching = start(key.currentState!).then((value) => outcome = value);
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

    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        if (call.method == 'initialize') return true;
        if (call.method != 'command') return null;
        final args = (call.arguments as Map?)?['args'];
        if (args is! List || args.isEmpty || args.first != 'loadfile') return null;
        final sourceId = ++loads;
        player().handlePlayerEvent('start-file', {'sourceId': sourceId});
        emitTrackList(sourceId);
        player().handlePlayerEvent('file-loaded', {'sourceId': sourceId});
        player().handlePlayerEvent('playback-restart', {'sourceId': sourceId, 'positionSeconds': 0.0});
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
              metadata: testMediaItem(id: 'film', serverId: 'srv-1', title: 'Film', backend: MediaBackend.jellyfin),
              selectedQualityPreset: TranscodeQualityPreset.original,
              // The account's audio language, which the first open resolves to row 4.
              preferredAudioTrack: const AudioTrack(id: 'pref', language: 'eng'),
            ),
          ).push(navigator.currentState!),
        );
        await pumpUntil(tester, () => revealed()?.value == true, describe: () => 'first frame never revealed');
        expect(client.opens.single.preferredAudioTrack?.language, 'eng');

        // French picked in the player; then a downloaded subtitle reloads.
        playing = 'fre';
        emitTrackList(loads);
        await key.currentState!.debugPickAudioTrackForTesting(player().state.track.audio!);
        final downloaded = MediaSubtitleTrack(id: 9, languageCode: 'ger', codec: 'srt', selected: false, forced: false);
        expect(
          await switchSource(
            (state) => state.debugSwitchPlaybackSourceForTesting(
              newSubtitleChoice: PlaybackSourceSubtitleChoice.downloaded(downloaded),
            ),
          ),
          PlaybackSourceChangeOutcome.applied,
        );
        expect(client.opens, hasLength(2));
        expect(client.opens.last.preferredAudioTrack?.language, 'fre', reason: 'the reload carries the pick');
        expect(client.opens.last.selectedAudioStreamId, isNull, reason: 'the rescan may have renumbered the streams');

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

/// A Jellyfin server whose file has English, French and German audio (rows 4,
/// 5 and 6), recording every open it is asked for. Like [JellyfinClient], it
/// reports as active the stream it was asked for, by id or by intent, or none.
class _StreamClient with PlaybackReportRecorder implements MediaServerClient {
  final opens = <PlaybackInitializationOptions>[];

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
  Future<PlaybackInitializationResult> getPlaybackInitialization(PlaybackInitializationOptions options) async {
    opens.add(options);
    final url = 'https://example.invalid/${options.metadata.id}/${opens.length}';
    final rows = [
      for (final (id, language) in [(4, 'eng'), (5, 'fre'), (6, 'ger')])
        MediaAudioTrack(id: id, languageCode: language, codec: 'aac', channels: 2, selected: id == 4),
    ];
    final preferred = options.preferredAudioTrack;
    return PlaybackInitializationResult(
      availableVersions: const [],
      videoUrl: url,
      activeAudioStreamId:
          options.selectedAudioStreamId ??
          (preferred == null ? null : findSourceAudioTrackForIntent(preferred, rows)?.id),
      mediaInfo: MediaSourceInfo(videoUrl: url, audioTracks: rows, subtitleTracks: const [], chapters: const []),
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

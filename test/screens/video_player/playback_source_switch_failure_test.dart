import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/providers/account_preferences_controller.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/music/music_playback_service.dart';
import 'package:plezy/services/offline_watch_sync_service.dart';
import 'package:plezy/services/playback_coordinator.dart';
import 'package:plezy/services/playback_initialization_types.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/video_player_navigation.dart';
import 'package:plezy/widgets/video_controls/video_controls.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/io_fakes.dart';
import '../../test_helpers/media_items.dart';
import '../../test_helpers/mock_player_channels.dart';
import '../../test_helpers/multi_server_fixtures.dart';
import '../../test_helpers/playback_report_fakes.dart';
import '../../test_helpers/prefs.dart';
import '../../test_helpers/stub_music_playback_service.dart';
import '../../test_helpers/watch_together_fakes.dart';

/// An in-place quality switch commits its replacement session on the
/// `loadfile` reply, before mpv has tried the URL, so the transcode that then
/// fails to open lands on the screen's error handler with the failed session
/// already committed. The viewer gets the failure view and Retry restores the
/// stream that was playing before the switch. Music-session arbitration holds
/// native creation so a deterministic player owns the opens.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpRoot;
  late PathProviderPlatform previousPathProvider;
  late AppDatabase db;

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    DownloadStorageService.resetForTesting();
    await SettingsService.getInstance();
    tmpRoot = await Directory.systemTemp.createTemp('playback_source_switch_failure_test_');
    previousPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = FakePathProvider(tmpRoot);
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

  Future<PlaybackSourceChangeOutcome> switchSource(
    WidgetTester tester,
    GlobalKey<VideoPlayerScreenState> key, {
    int? newAudioStreamId,
    TranscodeQualityPreset? newPreset,
  }) async {
    PlaybackSourceChangeOutcome? outcome;
    final switching = key.currentState!
        .debugSwitchPlaybackSourceForTesting(newAudioStreamId: newAudioStreamId, newPreset: newPreset)
        .then((value) => outcome = value);
    // Drift/database work needs real-event-loop yields.
    for (var i = 0; i < 400 && outcome == null; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (outcome == null) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
      }
    }
    await switching;
    return outcome!;
  }

  testWidgets('a quality switch the backend fails shows the failure view and Retry restores the previous stream', (
    tester,
  ) async {
    final fakePlayer = _SwitchPlayer();
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      testBody: () async {
        final key = await _pushScreen(tester, db: db, fakePlayer: fakePlayer);

        // A proven stream: this is what a failed switch must fall back to.
        expect(await switchSource(tester, key, newAudioStreamId: 2), PlaybackSourceChangeOutcome.applied);
        expect(fakePlayer.openedUrls, ['https://example.invalid/switch/original/audio-2']);

        fakePlayer.failNextOpen = true;
        final outcome = await switchSource(tester, key, newPreset: TranscodeQualityPreset.p720_2mbps);
        expect(outcome, isNot(PlaybackSourceChangeOutcome.applied));
        expect(fakePlayer.openedUrls.last, 'https://example.invalid/switch/p720_2mbps/audio-2');

        final failureMessage = t.messages.playbackFailedDetail(error: 'Failed to open stream');
        expect(find.text(failureMessage), findsOneWidget, reason: 'the failed switch must not be silent');
        final retry = find.widgetWithText(FilledButton, t.common.retry);
        expect(retry, findsOneWidget);
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'PlayerInitializationErrorAction');

        await tester.tap(retry);
        for (var i = 0; i < 400 && fakePlayer.openedUrls.length < 3; i++) {
          await tester.pump(const Duration(milliseconds: 50));
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
        }
        expect(fakePlayer.openedUrls, [
          'https://example.invalid/switch/original/audio-2',
          'https://example.invalid/switch/p720_2mbps/audio-2',
          'https://example.invalid/switch/original/audio-2',
        ], reason: 'Retry restores the request that was playing before the switch');
        await tester.pump();
        expect(find.text(failureMessage), findsNothing);
        expect(find.widgetWithText(FilledButton, t.common.retry), findsNothing);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  });
}

Future<GlobalKey<VideoPlayerScreenState>> _pushScreen(
  WidgetTester tester, {
  required AppDatabase db,
  required _SwitchPlayer fakePlayer,
}) async {
  final client = _SwitchClient();
  final multi = testMultiServer(clients: [client]);
  final offlineWatch = OfflineWatchSyncService(database: db, serverManager: multi.manager);
  final accountPreferences = AccountPreferencesController();
  final initializationHold = Completer<void>();
  Future<void> holdInitialization() => initializationHold.future;
  PlaybackCoordinator.instance.registerMusicSession(stopAndDispose: holdInitialization);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    PlaybackCoordinator.instance.unregisterMusicSession(holdInitialization);
    initializationHold.complete();
    await tester.pump();
    offlineWatch.dispose();
    accountPreferences.dispose();
    await fakePlayer.dispose();
  });
  final navigator = GlobalKey<NavigatorState>();
  final key = GlobalKey<VideoPlayerScreenState>();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlaybackStateProvider()),
        ChangeNotifierProvider<MultiServerProvider>.value(value: multi.provider),
        ChangeNotifierProvider<OfflineWatchSyncService>.value(value: offlineWatch),
        ChangeNotifierProvider<AccountPreferencesController>.value(value: accountPreferences),
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
        metadata: testMediaItem(id: 'switch', serverId: 'srv-1', backend: MediaBackend.jellyfin),
        selectedQualityPreset: TranscodeQualityPreset.original,
        selectedAudioStreamId: 1,
      ),
    ).push(navigator.currentState!),
  );
  await tester.pump();
  key.currentState!.player = fakePlayer;
  await key.currentState!.debugWirePlayerStreamsForTesting();
  fakePlayer.emitPlaybackRestart();
  await tester.pump();
  return key;
}

class _SwitchPlayer extends FakeSyncPlayer {
  _SwitchPlayer() : super(playing: true, position: const Duration(seconds: 121), duration: const Duration(minutes: 40));

  final openedUrls = <String>[];

  /// The next open is accepted and then fails the way a refused transcode
  /// does: the backend reports the error after the open call returned.
  bool failNextOpen = false;

  final _completedController = StreamController<bool>.broadcast();
  final _errorController = StreamController<PlayerError>.broadcast();

  @override
  PlayerStreams get streams {
    final base = super.streams;
    return PlayerStreams(
      playing: base.playing,
      completed: _completedController.stream,
      buffering: base.buffering,
      position: base.position,
      duration: base.duration,
      seekable: base.seekable,
      buffer: base.buffer,
      volume: base.volume,
      rate: base.rate,
      tracks: base.tracks,
      track: base.track,
      log: base.log,
      error: _errorController.stream,
      audioDevice: base.audioDevice,
      audioDevices: base.audioDevices,
      bufferRanges: base.bufferRanges,
      playbackRestart: base.playbackRestart,
      fileStarted: base.fileStarted,
      backendSwitched: base.backendSwitched,
    );
  }

  @override
  Future<void> stop() async {
    setPosition(Duration.zero);
    emitPlaying(false);
  }

  @override
  bool get needsDecoderRefreshAfterDisplaySwitch => false;

  @override
  Future<String?> getProperty(String name) async => null;

  @override
  Future<void> updateFrame() async {}

  @override
  Future<void> awaitDisplayModeSwitch({int extraDelayMs = 0}) async {}

  @override
  Future<bool> requestAudioFocus() async => true;

  @override
  Future<void> open(
    Media media, {
    bool play = true,
    bool isLive = false,
    List<SubtitleTrack>? externalSubtitles,
    Duration? timelineDuration,
  }) async {
    openedUrls.add(media.uri);
    setPosition(media.start ?? Duration.zero);
    setCompleted(false);
    _completedController.add(false);
    if (failNextOpen) {
      failNextOpen = false;
      scheduleMicrotask(() => _errorController.add(const PlayerError('Failed to open stream')));
      return;
    }
    emitPlaying(play);
    emitFileStarted();
    emitPlaybackRestart();
  }

  @override
  Future<void> selectSubtitleTrack(SubtitleTrack track) async {}

  @override
  Future<void> dispose({bool preserveDisplayMode = false}) async {
    if (disposed) return;
    await super.dispose(preserveDisplayMode: preserveDisplayMode);
    await _completedController.close();
    await _errorController.close();
  }
}

/// Names the requested preset and audio stream in the URL so the opens the
/// player receives say which request produced them.
class _SwitchClient with PlaybackReportRecorder implements MediaServerClient {
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
        activeAudioStreamId: options.selectedAudioStreamId,
        videoUrl:
            'https://example.invalid/${options.metadata.id}/${options.qualityPreset.name}'
            '/audio-${options.selectedAudioStreamId}',
      );

  @override
  Future<void> onPlaybackReport(PlaybackReportCall call) async {}

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
import 'package:plezy/services/music/music_playback_service.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/offline_watch_sync_service.dart';
import 'package:plezy/services/episode_navigation_service.dart';
import 'package:plezy/services/playback_initialization_types.dart';
import 'package:plezy/services/playback_coordinator.dart';
import 'package:plezy/services/playback_launch_observer.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/video_player_navigation.dart';
import 'package:plezy/widgets/video_controls/video_controls.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/io_fakes.dart';
import '../../test_helpers/media_items.dart';
import '../../test_helpers/mock_player_channels.dart';
import '../../test_helpers/multi_server_fixtures.dart';
import '../../test_helpers/prefs.dart';
import '../../test_helpers/playback_report_fakes.dart';
import '../../test_helpers/stub_music_playback_service.dart';
import '../../test_helpers/watch_together_fakes.dart';

/// The launch receipt an automation caller polls (`playback.status`) and
/// stops through (`playback.stop`) must keep describing the session across
/// same-item source switches and end with a terminal stage the caller can
/// tell apart from a replaced operation. Music-session arbitration holds
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
    tmpRoot = await Directory.systemTemp.createTemp('playback_launch_observer_test_');
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

  Future<void> switchAudio(WidgetTester tester, GlobalKey<VideoPlayerScreenState> key, int streamId) async {
    PlaybackSourceChangeOutcome? outcome;
    final switching = key.currentState!
        .debugSwitchPlaybackSourceForTesting(newAudioStreamId: streamId)
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
  }

  testWidgets('same-item source switches keep the receipt live; Back ends it stopped', (tester) async {
    final observer = PlaybackLaunchObserver(isCurrent: () => true);
    final fakePlayer = _ObservedPlayer();
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      testBody: () async {
        final screen = await _pushObservedScreen(tester, db: db, fakePlayer: fakePlayer, observer: observer);
        expect(observer.snapshot()['stage'], 'playing');
        expect(observer.ownsPlayback, isTrue);

        // Two switches: the first is the receipt's first attempt either way,
        // the second is where a receipt pinned to one generation goes stale.
        await switchAudio(tester, screen.key, 2);
        await switchAudio(tester, screen.key, 3);
        expect(fakePlayer.openCalls, 2);
        expect(observer.snapshot()['stage'], 'playing');
        expect(observer.ownsPlayback, isTrue);

        await tester.binding.handlePopRoute();
        await tester.pump();
        expect(observer.snapshot()['stage'], 'stopped');
        expect(observer.ownsPlayback, isFalse);
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
        expect(screen.key.currentState, isNull);
        expect(observer.snapshot()['stage'], 'stopped');
        expect(observer.isCurrent, isTrue, reason: 'a stopped receipt is not a replaced operation');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  });

  testWidgets('a fatal player error ends the receipt failed at once, and Back keeps it failed', (tester) async {
    final observer = PlaybackLaunchObserver(isCurrent: () => true);
    final fakePlayer = _ObservedPlayer();
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      testBody: () async {
        final screen = await _pushObservedScreen(tester, db: db, fakePlayer: fakePlayer, observer: observer);
        expect(observer.snapshot()['stage'], 'playing');

        fakePlayer.emitError(const PlayerError('Failed to open stream'));
        await tester.pump();
        // Terminal immediately — not via the route's exit, which a caller
        // that cannot pop never reaches — and the route stays for Retry.
        expect(observer.snapshot(), containsPair('stage', 'failed'));
        expect(observer.snapshot(), containsPair('failure', {'code': 'playbackFailed'}));
        expect(screen.key.currentState, isNotNull);
        expect(find.widgetWithText(FilledButton, t.common.retry), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
        expect(screen.key.currentState, isNull);
        expect(observer.snapshot(), containsPair('stage', 'failed'));
        expect(observer.snapshot(), containsPair('failure', {'code': 'playbackFailed'}));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  });

  testWidgets('a genuine EOF completes the receipt at the duration and the exit keeps it', (tester) async {
    final observer = PlaybackLaunchObserver(isCurrent: () => true);
    final fakePlayer = _ObservedPlayer();
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      testBody: () async {
        final screen = await _pushObservedScreen(tester, db: db, fakePlayer: fakePlayer, observer: observer);
        expect(observer.snapshot()['stage'], 'playing');

        fakePlayer.setPosition(fakePlayer.state.duration);
        fakePlayer.emitCompleted(true);
        await tester.pump();
        expect(observer.snapshot(), containsPair('stage', 'completed'));
        expect(observer.snapshot(), containsPair('positionMs', fakePlayer.state.duration.inMilliseconds));
        expect(observer.snapshot(), containsPair('durationMs', fakePlayer.state.duration.inMilliseconds));

        // A movie with nothing after it exits on its own.
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
        expect(screen.key.currentState, isNull);
        expect(observer.snapshot(), containsPair('stage', 'completed'));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  });

  testWidgets('an auto-advance keeps the receipt live and names the episode now playing', (tester) async {
    // The most-reproduced finding of the 2.20 test round: after an EOF the
    // receipt read `completed` for the launched episode forever while the
    // next one demonstrably played, and a scoped stop no longer owned it.
    final observer = PlaybackLaunchObserver(isCurrent: () => true);
    final fakePlayer = _ObservedPlayer();
    await SettingsService.instance.write(SettingsService.autoPlayNextEpisode, true);
    await SettingsService.instance.write(SettingsService.playNextCountdown, 0);
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      testBody: () async {
        final screen = await _pushObservedScreen(tester, db: db, fakePlayer: fakePlayer, observer: observer);
        expect(observer.snapshot(), containsPair('item', containsPair('itemId', 'observed')));
        screen.key.currentState!.debugCommitAdjacentEpisodesForTesting(
          AdjacentEpisodes(
            next: testMediaItem(id: 'next', serverId: 'srv-1', backend: MediaBackend.jellyfin),
            nextStatus: QueueNavigationStatus.found,
            previousStatus: QueueNavigationStatus.boundary,
          ),
        );

        fakePlayer.setPosition(fakePlayer.state.duration);
        fakePlayer.emitCompleted(true);
        // The in-place reload needs real-event-loop yields for its database
        // work, like the source switches above.
        for (var i = 0; i < 400 && fakePlayer.openCalls == 0; i++) {
          await tester.pump(const Duration(milliseconds: 50));
          if (fakePlayer.openCalls == 0) {
            await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
          }
        }
        await tester.pump();
        expect(fakePlayer.openCalls, 1);
        expect(screen.key.currentState, isNotNull);
        expect(observer.snapshot(), containsPair('stage', 'playing'));
        expect(observer.snapshot(), containsPair('item', containsPair('itemId', 'next')));
        expect(observer.ownsPlayback, isTrue, reason: 'playback.stop must still reach the advanced session');

        // Leaving mid-episode ends the session stopped, on the item it was on.
        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
        expect(screen.key.currentState, isNull);
        expect(observer.snapshot(), containsPair('stage', 'stopped'));
        expect(observer.snapshot(), containsPair('item', containsPair('itemId', 'next')));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  });
}

Future<({GlobalKey<VideoPlayerScreenState> key, GlobalKey<NavigatorState> navigator})> _pushObservedScreen(
  WidgetTester tester, {
  required AppDatabase db,
  required _ObservedPlayer fakePlayer,
  required PlaybackLaunchObserver observer,
}) async {
  final client = _ObservedClient();
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
        metadata: testMediaItem(id: 'observed', serverId: 'srv-1', backend: MediaBackend.jellyfin),
        selectedQualityPreset: TranscodeQualityPreset.original,
        selectedAudioStreamId: 1,
        launchObserver: observer,
      ),
    ).push(navigator.currentState!),
  );
  await tester.pump();
  key.currentState!.player = fakePlayer;
  await key.currentState!.debugWirePlayerStreamsForTesting();
  fakePlayer.emitPlaybackRestart();
  await tester.pump();
  return (key: key, navigator: navigator);
}

class _ObservedPlayer extends FakeSyncPlayer {
  _ObservedPlayer()
    : super(playing: true, position: const Duration(seconds: 121), duration: const Duration(minutes: 40));

  int openCalls = 0;
  final _completedController = StreamController<bool>.broadcast();
  final _errorController = StreamController<PlayerError>.broadcast();

  void emitCompleted(bool value) {
    setCompleted(value);
    _completedController.add(value);
  }

  /// The backend gave up on the file (mpv `end-file reason=error`).
  void emitError(PlayerError error) => _errorController.add(error);

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
  bool get attachesExternalSubtitlesAtOpen => true;

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
    openCalls++;
    setPosition(media.start ?? Duration.zero);
    emitCompleted(false);
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

class _ObservedClient with PlaybackReportRecorder implements MediaServerClient {
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
  Future<void> onPlaybackReport(PlaybackReportCall call) async {}

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

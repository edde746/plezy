import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/media/media_display_criteria.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/providers/account_preferences_controller.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/providers/companion_remote_provider.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/offline_watch_sync_service.dart';
import 'package:plezy/services/playback_initialization_types.dart';
import 'package:plezy/services/playback_coordinator.dart';
import 'package:plezy/services/plex_client.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/utils/active_client_scope.dart';
import 'package:plezy/utils/video_player_navigation.dart';
import 'package:plezy/widgets/video_controls/video_controls.dart';
import 'package:plezy/watch_together/models/playback_state.dart';
import 'package:plezy/watch_together/models/sync_message.dart';
import 'package:plezy/watch_together/models/watch_session.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import 'package:plezy/watch_together/services/watch_together_peer_service.dart';
import 'package:plezy/watch_together/services/watch_together_relay_endpoint.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/io_fakes.dart';
import '../../test_helpers/media_items.dart';
import '../../test_helpers/mock_player_channels.dart';
import '../../test_helpers/multi_server_fixtures.dart';
import '../../test_helpers/prefs.dart';
import '../../test_helpers/playback_report_fakes.dart';
import '../../test_helpers/pump.dart';
import '../../test_helpers/watch_together_fakes.dart';

/// Exercises source reloads through the screen while the room remains live.
/// Music-session arbitration holds native creation so a deterministic player
/// can own subsequent opens, failures, and EOF seeks without a platform decoder.
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
    tmpRoot = await Directory.systemTemp.createTemp('playback_reload_failure_test_');
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

  for (final opens in [false, true]) {
    testWidgets(
      opens
          ? 'successful local next selects only at open and binds the committed item'
          : 'failed next preserves room state and EOF seek reload retains the new intentional target',
      (tester) async {
        final priorItem = testMediaItem(
          id: 'movie-prior',
          serverId: 'srv-1',
          title: 'Prior movie',
          backend: MediaBackend.jellyfin,
        );
        final targetItem = testMediaItem(
          id: 'movie-next',
          serverId: 'srv-1',
          title: 'Next movie',
          backend: MediaBackend.jellyfin,
        );

        final peer = _ScreenPeerService();
        final watchTogether = WatchTogetherProvider(peerServiceFactory: ({endpoint}) => peer);
        await watchTogether.createSession(
          controlMode: ControlMode.anyone,
          relayEndpoint: WatchTogetherRelayEndpoint.defaultEndpoint,
        );
        watchTogether.selectMedia(
          ratingKey: priorItem.id,
          serverId: ServerId('srv-1'),
          mediaTitle: priorItem.displayTitle,
          position: const Duration(seconds: 121),
          rate: 1.25,
          lease: watchTogether.capturePlaybackLease(selection: true),
        );
        addTearDown(watchTogether.dispose);

        final client = _ReloadClient();
        final multi = testMultiServer(clients: [client]);
        final offlineWatch = OfflineWatchSyncService(database: db, serverManager: multi.manager);
        final accountPreferences = AccountPreferencesController();
        addTearDown(() {
          offlineWatch.dispose();
          accountPreferences.dispose();
        });

        final initializationHold = Completer<void>();
        Future<void> holdInitialization() => initializationHold.future;
        PlaybackCoordinator.instance.registerMusicSession(stopAndDispose: holdInitialization);
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox.shrink());
          PlaybackCoordinator.instance.unregisterMusicSession(holdInitialization);
          if (!initializationHold.isCompleted) initializationHold.complete();
          await tester.pump();
        });
        await withMockPlayerChannels(
          methodChannelName: 'com.plezy/mpv_player',
          eventChannelName: 'com.plezy/mpv_player/events',
          testBody: () async {
            final key = GlobalKey<VideoPlayerScreenState>();
            await tester.pumpWidget(
              MultiProvider(
                providers: [
                  ChangeNotifierProvider(create: (_) => PlaybackStateProvider()),
                  ChangeNotifierProvider<MultiServerProvider>.value(value: multi.provider),
                  ChangeNotifierProvider<OfflineWatchSyncService>.value(value: offlineWatch),
                  ChangeNotifierProvider<AccountPreferencesController>.value(value: accountPreferences),
                  ChangeNotifierProvider<WatchTogetherProvider>.value(value: watchTogether),
                  Provider<AppDatabase>.value(value: db),
                ],
                child: MaterialApp(
                  home: VideoPlayerScreen(
                    key: key,
                    metadata: priorItem,
                    selectedQualityPreset: TranscodeQualityPreset.original,
                    watchTogetherLease: watchTogether.capturePlaybackLease(),
                  ),
                ),
              ),
            );
            expect(key.currentState, isNotNull);

            final fakePlayer = _ReloadPlayer(opens: opens);
            addTearDown(fakePlayer.dispose);
            key.currentState!.player = fakePlayer;
            key.currentState!.debugBindWatchTogetherForTesting();
            fakePlayer.emitPlaybackRestart();
            await tester.pump();
            await tester.pump(const Duration(seconds: 1));
            fakePlayer.emitPlaying(false);
            await tester.pump();
            expect(peer.latestState.phase, PlaybackPhase.paused);
            final beforeNext = peer.states.length;

            var navDone = false;
            final nav = key.currentState!.navigateToQueueItem(targetItem).whenComplete(() => navDone = true);
            // Drift/database work needs real-event-loop yields.
            for (var i = 0; i < 400 && !navDone; i++) {
              await tester.pump(const Duration(milliseconds: 50));
              if (!navDone) {
                await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
              }
            }
            expect(navDone, isTrue, reason: 'the in-place reload must settle');
            await nav;

            expect(fakePlayer.openCalls, 1);

            expect(watchTogether.currentMediaRatingKey, opens ? targetItem.id : priorItem.id);
            expect(watchTogether.hasAttachedPlayer, isTrue);
            if (opens) {
              expect(peer.latestState.anchorPositionMs, 0);
            } else {
              expect(peer.states.skip(beforeNext).every((state) => state.ratingKey == priorItem.id), isTrue);
              expect(peer.latestState.phase, PlaybackPhase.paused);
              expect(peer.latestState.anchorPositionMs, 121000);
              fakePlayer.setCompleted(true);
              expect(key.currentState!.debugInterceptEofForTesting(), isTrue);
              for (var i = 0; i < 400 && !key.currentState!.debugPlaybackParkedForTesting; i++) {
                await tester.pump(const Duration(milliseconds: 50));
                await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
              }
              expect(key.currentState!.debugPlaybackParkedForTesting, isTrue);
              expect(fakePlayer.openCalls, 2);
              fakePlayer.opens = true;
              var seekDone = false;
              final seek = key.currentState!
                  .debugSeekPlaybackForTesting(const Duration(seconds: 90))
                  .whenComplete(() => seekDone = true);
              for (var i = 0; i < 400 && !seekDone; i++) {
                await tester.pump(const Duration(milliseconds: 50));
                await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
              }
              expect(seekDone, isTrue);
              await seek;
              await tester.pump(const Duration(milliseconds: 200));
              expect(fakePlayer.openCalls, 3, reason: 'parked EOF seek uses the actual source reload, not native seek');
              expect(watchTogether.currentMediaRatingKey, priorItem.id);
              expect(peer.latestState.anchorPositionMs, 90000);
              expect(peer.latestState.phase, PlaybackPhase.paused);

              final pendingNativeSeek = Completer<void>();
              fakePlayer.nextCommandFuture = pendingNativeSeek.future;
              final olderSeek = key.currentState!.debugSeekPlaybackForTesting(const Duration(seconds: 60));
              final newerSeek = key.currentState!.debugSeekPlaybackForTesting(const Duration(seconds: 70));
              await tester.pump();
              pendingNativeSeek.complete();
              await Future.wait([olderSeek, newerSeek]);
              expect(fakePlayer.currentPosition, const Duration(seconds: 70));
              await tester.pump(const Duration(milliseconds: 200));
              expect(peer.latestState.anchorPositionMs, 70000);
              expect(peer.latestState.phase, PlaybackPhase.paused);
            }

            // Exit after a committed reload must report the item actually
            // loaded, not the route's original metadata or native stop's
            // reset clock. Exercise both playing and paused exits.
            // Startup is held before production stream wiring. Bind the real
            // listeners now so the fake renderer event reaches reporting
            // readiness rather than only the room's independent observer.
            await key.currentState!.debugWirePlayerStreamsForTesting();
            fakePlayer.emitPlaying(opens);
            fakePlayer.emitPlaybackRestart();
            await tester.pump();
            // The room's initial alignment may seek on renderer readiness.
            // Advance the playhead only after that alignment has settled.
            fakePlayer.setPosition(const Duration(seconds: 137));
            final terminalGate = Completer<void>();
            client.stopGate = terminalGate;
            var shutdownDone = false;
            final shutdown = PlaybackCoordinator.instance.shutdownVideo().whenComplete(() => shutdownDone = true);
            final repeatedShutdown = PlaybackCoordinator.instance.shutdownVideo();
            await tester.pump();
            final terminal = client.reports.last;
            expect(terminal.kind, PlaybackReportKind.stopped);
            expect(terminal.itemId, opens ? targetItem.id : priorItem.id);
            expect(terminal.position, const Duration(seconds: 137));
            expect(terminal.duration, const Duration(minutes: 40));
            expect(fakePlayer.currentPosition, Duration.zero);
            expect(fakePlayer.stopCalls, 1);
            expect(shutdownDone, isFalse, reason: 'native stop alone must not release application teardown');
            final reportCount = client.reports.length;
            final openCount = fakePlayer.openCalls;
            // Neither a lifecycle resume nor a pending startup released by
            // music arbitration may reopen after the shutdown latch.
            key.currentState!.didChangeAppLifecycleState(AppLifecycleState.resumed);
            initializationHold.complete();
            await tester.pump(const Duration(seconds: 30));
            expect(fakePlayer.openCalls, openCount);
            expect(client.reports.length, reportCount);
            terminalGate.complete();
            await pumpUntil(tester, () => shutdownDone);
            await Future.wait([shutdown, repeatedShutdown]);
            expect(shutdownDone, isTrue);
            expect(fakePlayer.stopCalls, 1);

            // Let the rollback's failure snackbar run its display timer down so
            // nothing is pending when the tree unmounts.
            await tester.pump(const Duration(seconds: 5));
            await tester.pump(const Duration(seconds: 1));

            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
          },
        );
      },
    );
  }

  for (final blocked in ['pause', 'visibility', 'started', 'stopped', 'system UI', 'orientation']) {
    testWidgets('accepted Back leaves a committed reload while $blocked remains pending', (tester) async {
      final pending = Completer<void>();
      final disposal = Completer<void>();
      final client = _ReloadClient();
      if (blocked == 'started') client.startGate = pending;
      final fakePlayer = _ExitPlayer()..disposalGate = disposal;
      final platformCalls = <MethodCall>[];
      var blockPlatform = false;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await TvDetectionService.getInstance(forceTv: blocked == 'visibility');
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
        TvDetectionService.debugReset();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          platformCalls.add(call);
          if (blockPlatform &&
              ((blocked == 'system UI' && call.method == 'SystemChrome.setEnabledSystemUIMode') ||
                  (blocked == 'orientation' && call.method == 'SystemChrome.setPreferredOrientations'))) {
            await pending.future;
          }
          return null;
        },
      );
      try {
        await withMockPlayerChannels(
          methodChannelName: 'com.plezy/mpv_player',
          eventChannelName: 'com.plezy/mpv_player/events',
          testBody: () async {
            final screen = await _pushExitScreen(tester, db: db, client: client, fakePlayer: fakePlayer);
            if (blocked == 'started') {
              await tester.pump(const Duration(seconds: 10));
              await pumpUntil(tester, () => client.reports.any((call) => call.kind == PlaybackReportKind.started));
            }
            if (blocked == 'pause') fakePlayer.pauseGate = pending;
            if (blocked == 'visibility') fakePlayer.visibilityGate = pending;
            if (blocked == 'stopped') client.stopGate = pending;
            fakePlayer.setPosition(const Duration(seconds: 137));
            final pauseCount = fakePlayer.pauseCalls;
            final openCount = fakePlayer.openCalls;
            blockPlatform = true;

            // Exercise both physical down/repeat/up and the system PopScope
            // path. Repeated Back must not start another accepted exit.
            if (blocked == 'pause' || blocked == 'visibility') {
              await tester.sendKeyDownEvent(LogicalKeyboardKey.goBack, physicalKey: PhysicalKeyboardKey.escape);
              await tester.sendKeyRepeatEvent(LogicalKeyboardKey.goBack, physicalKey: PhysicalKeyboardKey.escape);
              await tester.sendKeyUpEvent(LogicalKeyboardKey.goBack, physicalKey: PhysicalKeyboardKey.escape);
            } else {
              await tester.binding.handlePopRoute();
            }
            await tester.pump();
            await tester.binding.handlePopRoute();
            await tester.pump(const Duration(milliseconds: 999));
            expect(screen.key.currentState, isNotNull, reason: 'the pending cleanup still owns the grace period');
            await tester.pump(const Duration(milliseconds: 1));
            await tester.pump();
            expect(screen.key.currentState, isNull);
            expect(find.text('Browse'), findsOneWidget);
            expect(pending.isCompleted, isFalse);
            expect(fakePlayer.pauseCalls, pauseCount + 1);
            expect(fakePlayer.stopCalls, 0, reason: 'ordinary Back requests pause, not application shutdown stop');
            expect(fakePlayer.disposalStarted, isTrue);
            expect(fakePlayer.disposalFinished, isFalse, reason: 'navigation is not a native release acknowledgement');

            await tester.tap(find.text('Browse'));
            expect(screen.browseTaps(), 1);
            final successorKey = GlobalKey<VideoPlayerScreenState>();
            final successorPlayer = _ExitPlayer();
            unawaited(
              screen.navigator.currentState!.push(
                buildVideoPlayerRoute(
                  builder: (_) => VideoPlayerScreen(
                    key: successorKey,
                    metadata: testMediaItem(id: 'successor'),
                    isOffline: true,
                  ),
                ),
              ),
            );
            await tester.pump();
            successorKey.currentState!.player = successorPlayer;
            final platformCount = platformCalls.length;
            pending.complete();
            disposal.complete();
            await pumpUntil(
              tester,
              () =>
                  fakePlayer.disposalFinished && client.reports.any((call) => call.kind == PlaybackReportKind.stopped),
            );
            await tester.pump(const Duration(seconds: 20));
            final stopped = client.reports.where((call) => call.kind == PlaybackReportKind.stopped).toList();
            expect(stopped, hasLength(1));
            expect(stopped.single.itemId, 'exit-committed');
            expect(stopped.single.position, const Duration(seconds: 137));
            expect(stopped.single.duration, const Duration(minutes: 40));
            expect(successorKey.currentState, isNotNull, reason: 'late cleanup cannot pop the new player');
            expect(successorPlayer.pauseCalls, 0);
            expect(successorPlayer.stopCalls, 0);
            expect(fakePlayer.openCalls, openCount);
            expect(
              platformCalls.length,
              platformCount,
              reason: 'late restoration must not issue successor UI requests',
            );
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
          },
        );
      } finally {
        if (!pending.isCompleted) pending.complete();
        if (!disposal.isCompleted) disposal.complete();
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  testWidgets('guest cancellation stays interactive; confirmed transport leave cannot hold Back', (tester) async {
    final peer = _GuestExitPeer();
    final watchTogether = WatchTogetherProvider(peerServiceFactory: ({endpoint}) => peer);
    await watchTogether.joinSession('SCREEN', relayEndpoint: WatchTogetherRelayEndpoint.defaultEndpoint);
    addTearDown(watchTogether.dispose);
    final fakePlayer = _ExitPlayer();
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      testBody: () async {
        final screen = await _pushExitScreen(
          tester,
          db: db,
          client: _ReloadClient(),
          fakePlayer: fakePlayer,
          watchTogether: watchTogether,
        );
        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.pump(const Duration(seconds: 30));
        expect(screen.key.currentState, isNotNull, reason: 'confirmation has no navigation deadline');
        await tester.tap(find.text('Cancel'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(watchTogether.isInSession, isTrue);
        expect(fakePlayer.pauseCalls, 0);
        expect(peer.releaseCalls, 0);
        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Leave'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
        expect(screen.key.currentState, isNull);
        expect(watchTogether.isInSession, isFalse);
        expect(peer.releaseCalls, 1);
        expect(peer.releaseGate.isCompleted, isFalse);
        peer.releaseGate.complete();
        await tester.pump();
        expect(find.text('Browse'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  });

  // The Plex part's stream selection is a persistence write, not how a source
  // switch is delivered: the reload carries the audio id itself. With
  // "Remember track selections" off there is nothing to write, so a source
  // whose metadata carries no part id must still switch instead of failing on
  // a precondition for a write nobody asked for.
  for (final remember in [true, false]) {
    testWidgets('a Plex audio switch on a part-less source ${remember ? 'fails' : 'proceeds'} '
        'when remembering track selections is ${remember ? 'on' : 'off'}', (tester) async {
      resetSharedPreferencesForTest(initialAsync: {'remember_track_selections': remember});
      SettingsService.resetForTesting();
      await SettingsService.getInstance();

      final client = _PlexStreamSelectClient();
      final multi = testMultiServer(clients: [client]);
      final offlineWatch = OfflineWatchSyncService(database: db, serverManager: multi.manager);
      final accountPreferences = AccountPreferencesController();
      addTearDown(() {
        offlineWatch.dispose();
        accountPreferences.dispose();
      });

      final initializationHold = Completer<void>();
      Future<void> holdInitialization() => initializationHold.future;
      PlaybackCoordinator.instance.registerMusicSession(stopAndDispose: holdInitialization);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        PlaybackCoordinator.instance.unregisterMusicSession(holdInitialization);
        if (!initializationHold.isCompleted) initializationHold.complete();
        await tester.pump();
      });

      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        testBody: () async {
          final key = GlobalKey<VideoPlayerScreenState>();
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => PlaybackStateProvider()),
                ChangeNotifierProvider<MultiServerProvider>.value(value: multi.provider),
                ChangeNotifierProvider<OfflineWatchSyncService>.value(value: offlineWatch),
                ChangeNotifierProvider<AccountPreferencesController>.value(value: accountPreferences),
                Provider<AppDatabase>.value(value: db),
                ChangeNotifierProvider(create: (_) => CompanionRemoteProvider()),
              ],
              child: MaterialApp(
                home: VideoPlayerScreen(
                  key: key,
                  metadata: testMediaItem(id: 'plex-movie', serverId: 'srv-1', backend: MediaBackend.plex),
                  selectedQualityPreset: TranscodeQualityPreset.original,
                  selectedAudioStreamId: 1,
                ),
              ),
            ),
          );
          expect(key.currentState, isNotNull);

          final fakePlayer = _ReloadPlayer(opens: true);
          addTearDown(fakePlayer.dispose);
          key.currentState!.player = fakePlayer;
          fakePlayer.emitPlaybackRestart();
          await tester.pump();

          PlaybackSourceChangeOutcome? outcome;
          final switching = key.currentState!
              .debugSwitchPlaybackSourceForTesting(newAudioStreamId: 2)
              .then((value) => outcome = value);
          for (var i = 0; i < 400 && outcome == null; i++) {
            await tester.pump(const Duration(milliseconds: 50));
            if (outcome == null) {
              await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
            }
          }
          await switching;

          // No part id either way, so the write itself is never reachable —
          // what the setting decides is whether the switch is held hostage to
          // it.
          expect(client.selectStreamsCalls, isEmpty);
          if (remember) {
            expect(outcome, PlaybackSourceChangeOutcome.failed);
            expect(find.textContaining(t.messages.streamSelectionUnavailable), findsOneWidget);
          } else {
            expect(outcome, isNot(PlaybackSourceChangeOutcome.failed));
            expect(find.textContaining(t.messages.streamSelectionUnavailable), findsNothing);
          }
        },
      );
    });
  }
}

class _ReloadPlayer extends FakeSyncPlayer {
  _ReloadPlayer({required this.opens})
    : super(playing: true, position: const Duration(seconds: 121), duration: const Duration(minutes: 40), rate: 1.25);
  bool opens;
  int openCalls = 0;
  int stopCalls = 0;

  @override
  Future<void> stop() async {
    stopCalls++;
    setPosition(Duration.zero);
    emitPlaying(false);
  }

  @override
  String get playerType => 'mpv';

  @override
  bool get attachesExternalSubtitlesAtOpen => true;

  @override
  bool get needsDecoderRefreshAfterDisplaySwitch => false;

  @override
  Future<void> setProperty(String name, String value) async {}

  @override
  Future<String?> getProperty(String name) async => null;

  @override
  Future<void> updateFrame() async {}

  @override
  Future<void> setDisplayCriteria(MediaDisplayCriteria? criteria, {int extraDelayMs = 0}) async {}

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
    if (!opens) throw StateError('open failed before the open boundary');
    setPosition(media.start ?? Duration.zero);
    setCompleted(false);
    emitPlaying(play);
    emitPlaybackRestart();
  }

  @override
  Future<void> selectSubtitleTrack(SubtitleTrack track) async {}
}

class _ScreenPeerService extends WatchTogetherPeerService {
  final states = <PlaybackState>[];
  PlaybackState get latestState => states.last;
  @override
  String get myPeerId => 'host';
  @override
  String get hostPeerId => 'host';
  @override
  bool get isHost => true;
  @override
  Future<String> createSession({String? sessionId}) async => 'SCREEN';
  @override
  void broadcast(SyncMessage message) {
    if (message.state case final state?) states.add(state);
  }

  @override
  Future<void> releaseSession() async {}
  @override
  Future<void> disconnect() async {}
}

class _ReloadClient with PlaybackReportRecorder implements MediaServerClient {
  final reports = <PlaybackReportCall>[];
  Completer<void>? stopGate;
  Completer<void>? startGate;
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
  Future<void> onPlaybackReport(PlaybackReportCall call) async {
    reports.add(call);
    if (call.kind == PlaybackReportKind.started) await startGate?.future;
    if (call.kind == PlaybackReportKind.stopped) await stopGate?.future;
  }

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Plex-typed double so `context.getPlexClientForServer` resolves it and the
/// part-level stream selection write becomes observable.
class _PlexStreamSelectClient with PlaybackReportRecorder implements PlexClient {
  final reports = <PlaybackReportCall>[];
  final selectStreamsCalls = <({int partId, int? audioStreamID, int? subtitleStreamID})>[];

  @override
  ServerId get serverId => ServerId('srv-1');
  @override
  String get serverName => 'Server';
  @override
  MediaBackend get backend => MediaBackend.plex;
  @override
  ServerCapabilities get capabilities => ServerCapabilities.plex;
  @override
  PlexProfileScopeId profileScopeId = buildPlexProfileScopeId(serverId: ServerId('srv-1'), profileId: 'profile-a');
  @override
  String get scopedServerId => profileScopeId;
  @override
  double get watchedThreshold => 0.9;
  @override
  bool get marksWatchedOnPlaybackStopped => false;
  @override
  Map<String, String> get streamHeaders => const {};

  @override
  Future<bool> selectStreams(int partId, {int? audioStreamID, int? subtitleStreamID}) async {
    selectStreamsCalls.add((partId: partId, audioStreamID: audioStreamID, subtitleStreamID: subtitleStreamID));
    return true;
  }

  // A source with no part id: the shape that makes the persistence
  // precondition, and therefore the gate, observable.
  @override
  Future<PlaybackInitializationResult> getPlaybackInitialization(PlaybackInitializationOptions options) async =>
      PlaybackInitializationResult(
        availableVersions: const [],
        videoUrl: 'https://example.invalid/${options.metadata.id}',
      );

  @override
  Future<void> onPlaybackReport(PlaybackReportCall call) async => reports.add(call);

  @override
  Future<void> closeGracefully({Duration drainTimeout = const Duration(seconds: 5)}) async {}

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<({GlobalKey<VideoPlayerScreenState> key, GlobalKey<NavigatorState> navigator, int Function() browseTaps})>
_pushExitScreen(
  WidgetTester tester, {
  required AppDatabase db,
  required _ReloadClient client,
  required _ExitPlayer fakePlayer,
  WatchTogetherProvider? watchTogether,
}) async {
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
  });
  final navigator = GlobalKey<NavigatorState>();
  final key = GlobalKey<VideoPlayerScreenState>();
  var browseTaps = 0;
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlaybackStateProvider()),
        ChangeNotifierProvider<MultiServerProvider>.value(value: multi.provider),
        ChangeNotifierProvider<OfflineWatchSyncService>.value(value: offlineWatch),
        ChangeNotifierProvider<AccountPreferencesController>.value(value: accountPreferences),
        if (watchTogether != null) ChangeNotifierProvider<WatchTogetherProvider>.value(value: watchTogether),
        Provider<AppDatabase>.value(value: db),
      ],
      child: MaterialApp(
        navigatorKey: navigator,
        home: Scaffold(
          body: TextButton(onPressed: () => browseTaps++, child: const Text('Browse')),
        ),
      ),
    ),
  );
  unawaited(
    navigator.currentState!.push(
      buildVideoPlayerRoute(
        builder: (_) => VideoPlayerScreen(
          key: key,
          metadata: testMediaItem(id: 'exit-original', serverId: 'srv-1', backend: MediaBackend.jellyfin),
          selectedQualityPreset: TranscodeQualityPreset.original,
          watchTogetherLease: watchTogether?.capturePlaybackLease(),
        ),
      ),
    ),
  );
  await tester.pump();
  key.currentState!.player = fakePlayer;
  if (watchTogether == null) {
    var committed = false;
    final reload = key.currentState!
        .navigateToQueueItem(testMediaItem(id: 'exit-committed', serverId: 'srv-1', backend: MediaBackend.jellyfin))
        .whenComplete(() => committed = true);
    await pumpUntil(tester, () => committed);
    await reload;
    expect(fakePlayer.openCalls, 1);
    await key.currentState!.debugWirePlayerStreamsForTesting();
    fakePlayer.emitPlaying(true);
    fakePlayer.emitPlaybackRestart();
    await tester.pump();
  }
  return (key: key, navigator: navigator, browseTaps: () => browseTaps);
}

class _ExitPlayer extends _ReloadPlayer {
  _ExitPlayer() : super(opens: true);

  Completer<void>? pauseGate;
  Completer<void>? visibilityGate;
  Completer<void>? disposalGate;
  int pauseCalls = 0;
  bool disposalStarted = false;
  bool disposalFinished = false;

  @override
  Future<void> pause() async {
    pauseCalls++;
    setPosition(Duration.zero);
    await pauseGate?.future;
    if (!disposed) await super.pause();
  }

  @override
  Future<bool> setVisible(bool visible, {bool restoreOnWindowVisible = false}) async {
    if (!visible) await visibilityGate?.future;
    return true;
  }

  @override
  Future<void> dispose({bool preserveDisplayMode = false}) async {
    disposalStarted = true;
    await disposalGate?.future;
    await super.dispose(preserveDisplayMode: preserveDisplayMode);
    disposalFinished = true;
  }
}

class _GuestExitPeer extends _ScreenPeerService {
  final releaseGate = Completer<void>();
  int releaseCalls = 0;

  @override
  String get myPeerId => 'guest';
  @override
  bool get isHost => false;
  @override
  Future<void> joinSession(String sessionId) async {}
  @override
  Future<void> releaseSession() async {
    releaseCalls++;
    await releaseGate.future;
  }
}

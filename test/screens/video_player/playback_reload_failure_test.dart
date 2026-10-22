import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openwatchparty/openwatchparty.dart' as owp;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/play_queue.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/models/livetv_channel.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/providers/account_preferences_controller.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/providers/companion_remote_provider.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/screens/video_player/live_tv_session_args.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/episode_navigation_service.dart';
import 'package:plezy/services/offline_watch_sync_service.dart';
import 'package:plezy/services/playback_initialization_types.dart';
import 'package:plezy/services/playback_coordinator.dart';
import 'package:plezy/services/plex_client.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/sleep_timer_service.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/utils/active_client_scope.dart';
import 'package:plezy/utils/external_ids.dart';
import 'package:plezy/utils/video_player_navigation.dart';
import 'package:plezy/widgets/video_controls/video_controls.dart';
import 'package:plezy/watch_together/models/watch_notice.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/fake_owp_relay.dart';
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

  /// This user hosts a room on an in-process relay where everyone controls;
  /// the files it shares come from [client].
  Future<({WatchTogetherProvider watchTogether, FakeOwpRelay relay})> hostRoom(
    WidgetTester tester,
    MediaServerClient client,
  ) async {
    final relay = FakeOwpRelay();
    final watchTogether = WatchTogetherProvider(
      clientFor: (serverId) => serverId == client.serverId ? client : null,
      partyFactory: relay.party,
      clientName: () async => 'Plezy/1.0',
      displayName: () => 'Anna',
    );
    final created = watchTogether.createRoom();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    expect(await created, FakeOwpRelay.code);
    watchTogether.setControl(owp.Control.everyone);
    await tester.pump(const Duration(milliseconds: 50));
    return (watchTogether: watchTogether, relay: relay);
  }

  /// Unmounts every screen, then leaves the room so no party timer outlives
  /// the test.
  Future<void> closeRooms(WidgetTester tester, List<WatchTogetherProvider> rooms) async {
    await tester.pumpWidget(const SizedBox.shrink());
    for (final room in rooms) {
      room.dispose();
    }
    await tester.pump(const Duration(milliseconds: 500));
  }

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

        final client = _ReloadClient();
        final (:watchTogether, :relay) = await hostRoom(tester, client);
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
            // The host shared the file where it played, and the room drives it.
            expect(relay.sent('setMedia').single['positionMs'], 121000);
            expect(watchTogether.media?.title, priorItem.title);
            expect(watchTogether.isFollowing, isTrue);
            // The viewer pauses the room, which then pauses the player.
            expect(watchTogether.pause(), isTrue);
            await tester.pump(const Duration(milliseconds: 300));
            expect(relay.phase, 'paused');
            expect(fakePlayer.state.playing, isFalse);
            final roomAdapter = key.currentState!.debugWatchTogetherAdapter;

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

            await tester.pump(const Duration(milliseconds: 300));
            expect(relay.sent('clearMedia'), isEmpty, reason: 'the room keeps media between items');
            expect(watchTogether.isFollowing, isTrue);
            if (opens) {
              // The next item is the room's, from its start.
              expect(relay.sent('setMedia'), hasLength(2));
              expect(relay.sent('setMedia').last['positionMs'] ?? 0, 0);
              expect(watchTogether.media?.title, targetItem.title);
              expect(key.currentState!.debugWatchTogetherAdapter?.copy.itemId, targetItem.id);
            } else {
              expect(relay.sent('setMedia'), hasLength(1), reason: 'a failed next leaves the room its media');
              expect(watchTogether.media?.title, priorItem.title);
              expect(key.currentState!.debugWatchTogetherAdapter, same(roomAdapter));
              expect(relay.phase, 'paused');
              fakePlayer.setCompleted(true);
              expect(await key.currentState!.debugInterceptEofForTesting(), isTrue);
              for (var i = 0; i < 400 && !key.currentState!.debugPlaybackParkedForTesting; i++) {
                await tester.pump(const Duration(milliseconds: 50));
                await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
              }
              expect(key.currentState!.debugPlaybackParkedForTesting, isTrue);
              expect(fakePlayer.openCalls, 2);
              fakePlayer.opens = true;
              // The viewer's seek goes to the room; the room's seek of the
              // parked player reloads the source at the target.
              await key.currentState!.debugSeekPlaybackForTesting(const Duration(seconds: 90));
              for (
                var i = 0;
                i < 400 && (fakePlayer.openCalls < 3 || key.currentState!.debugPlaybackParkedForTesting);
                i++
              ) {
                await tester.pump(const Duration(milliseconds: 50));
                await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
              }
              await tester.pump(const Duration(milliseconds: 200));
              expect(fakePlayer.openCalls, 3, reason: 'parked EOF seek uses the actual source reload, not native seek');
              expect(relay.sent('seek').last['positionMs'], 90000);
              expect(relay.phase, 'paused');
              expect(watchTogether.media?.title, priorItem.title);
              expect(relay.sent('setMedia'), hasLength(1), reason: 'the reload is the same file');

              final pendingNativeSeek = Completer<void>();
              fakePlayer.nextCommandFuture = pendingNativeSeek.future;
              await key.currentState!.debugSeekPlaybackForTesting(const Duration(seconds: 60));
              await key.currentState!.debugSeekPlaybackForTesting(const Duration(seconds: 70));
              await tester.pump(const Duration(milliseconds: 100));
              pendingNativeSeek.complete();
              await pumpUntil(tester, () => fakePlayer.currentPosition == const Duration(seconds: 70));
              await tester.pump(const Duration(milliseconds: 200));
              expect(relay.sent('seek').map((seek) => seek['positionMs']), containsAllInOrder([60000, 70000]));
              expect(fakePlayer.currentPosition, const Duration(seconds: 70), reason: 'the later seek wins');
              expect(relay.phase, 'paused');
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
            expect(relay.sent('clearMedia'), hasLength(1), reason: 'the host left the player, so its media stopped');

            // Let the rollback's failure snackbar run its display timer down so
            // nothing is pending when the tree unmounts.
            await tester.pump(const Duration(seconds: 5));
            await tester.pump(const Duration(seconds: 1));

            await closeRooms(tester, [watchTogether]);
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
              VideoPlayerRoute(
                builder: (_) => VideoPlayerScreen(
                  key: successorKey,
                  metadata: testMediaItem(id: 'successor'),
                  isOffline: true,
                ),
              ).push(screen.navigator.currentState!),
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

  for (final target in ['same room', 'download', 'live', 'superseded before build']) {
    testWidgets('replacement by $target only keeps the room media for a player in the room', (tester) async {
      final client = _ReloadClient();
      final (:watchTogether, :relay) = await hostRoom(tester, client);
      final oldPlayer = _ExitPlayer();
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        testBody: () async {
          final screen = await _pushExitScreen(
            tester,
            db: db,
            client: client,
            fakePlayer: oldPlayer,
            watchTogether: watchTogether,
          );
          screen.key.currentState!.debugBindWatchTogetherForTesting();
          oldPlayer.emitPlaybackRestart();
          await tester.pump(const Duration(milliseconds: 300));
          expect(watchTogether.isFollowing, isTrue);
          expect(relay.sent('setMedia'), hasLength(1));
          final continuesRoom = target == 'same room' || target == 'download';
          // Only Live TV stays out of the room.
          final live = !continuesRoom;
          final successorKey = GlobalKey<VideoPlayerScreenState>();
          final successorPlayer = _ExitPlayer();
          if (target == 'superseded before build') {
            unawaited(
              VideoPlayerRoute(
                joinsWatchTogether: true,
                builder: (_) => VideoPlayerScreen(
                  metadata: testMediaItem(id: 'intermediate', serverId: 'srv-1'),
                ),
              ).push(screen.navigator.currentState!),
            );
          }
          unawaited(
            VideoPlayerRoute(
              joinsWatchTogether: continuesRoom,
              builder: (_) => VideoPlayerScreen(
                key: successorKey,
                metadata: testMediaItem(id: 'successor', serverId: 'srv-1', backend: MediaBackend.jellyfin),
                isOffline: target == 'download',
                selectedQualityPreset: TranscodeQualityPreset.original,
                live: live
                    ? LiveTvSessionArgs(
                        channel: LiveTvChannel(key: 'channel', serverId: 'srv-1'),
                      )
                    : null,
              ),
            ).push(screen.navigator.currentState!),
          );
          await tester.pump();
          successorKey.currentState!.player = successorPlayer;
          await pumpUntil(tester, () => screen.key.currentState == null && oldPlayer.disposed);
          await tester.pump(const Duration(milliseconds: 300));
          // A player that takes part in the room keeps the host's media until
          // it shares its own; anything else stops it for everyone.
          expect(relay.sent('clearMedia'), hasLength(continuesRoom ? 0 : 1));
          expect(watchTogether.hasMedia, continuesRoom);
          expect(watchTogether.isFollowing, isFalse);
          // The disposed screen drops its own registration, never the one its
          // successor made in its place.
          expect(watchTogether.debugPlayerOwner, continuesRoom ? same(successorKey.currentState) : isNull);
          if (continuesRoom) {
            successorKey.currentState!.debugBindWatchTogetherForTesting();
            successorPlayer.emitPlaybackRestart();
            await tester.pump(const Duration(milliseconds: 300));
            expect(watchTogether.isFollowing, isTrue);
            expect(relay.sent('setMedia'), hasLength(2), reason: 'the successor shares its own file');
            expect(relay.sent('clearMedia'), isEmpty, reason: 'the media never stopped between the players');
          }
          await closeRooms(tester, [watchTogether]);
        },
      );
    });
  }

  testWidgets('end-of-video sleep pauses the successor after real screen replacement', (tester) async {
    final timer = SleepTimerService();
    timer.cancelTimer();
    addTearDown(timer.cancelTimer);
    final oldPlayer = _ExitPlayer();
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      testBody: () async {
        final screen = await _pushExitScreen(tester, db: db, client: _ReloadClient(), fakePlayer: oldPlayer);
        timer.armEndOfVideo();
        final successorKey = GlobalKey<VideoPlayerScreenState>();
        final successorPlayer = _ExitPlayer();
        unawaited(
          VideoPlayerRoute(
            builder: (_) => VideoPlayerScreen(
              key: successorKey,
              metadata: testMediaItem(id: 'sleep-successor'),
              isOffline: true,
            ),
          ).push(screen.navigator.currentState!),
        );
        await tester.pump();
        successorKey.currentState!.player = successorPlayer;
        await pumpUntil(tester, () => screen.key.currentState == null && oldPlayer.disposed);
        final oldPauses = oldPlayer.pauseCalls;
        expect(timer.isEndOfVideoMode, isTrue);
        timer.notifyVideoCompleted();
        await tester.pump();
        expect(successorPlayer.state.playing, isFalse);
        expect(oldPlayer.pauseCalls, oldPauses, reason: 'completion cannot command the retired player');
        await tester.binding.handlePopRoute();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
        expect(successorKey.currentState, isNull);
        expect(find.text('Browse'), findsOneWidget);
      },
    );
  });

  for (final transferred in [false, true]) {
    testWidgets(
      transferred
          ? 'Back after handing the host on leaves the player and keeps the room its media'
          : "Back as host leaves the player and stops the room's media, without asking",
      (tester) async {
        final client = _ReloadClient();
        final (:watchTogether, :relay) = await hostRoom(tester, client);
        final guest = WatchTogetherProvider(
          partyFactory: relay.party,
          clientName: () async => 'Plezy/1.0',
          displayName: () => 'Ben',
        );
        final joining = guest.joinRoom(FakeOwpRelay.code);
        await tester.pump(const Duration(milliseconds: 100));
        await joining;
        final fakePlayer = _ExitPlayer();
        await withMockPlayerChannels(
          methodChannelName: 'com.plezy/mpv_player',
          eventChannelName: 'com.plezy/mpv_player/events',
          testBody: () async {
            final screen = await _pushExitScreen(
              tester,
              db: db,
              client: client,
              fakePlayer: fakePlayer,
              watchTogether: watchTogether,
            );
            screen.key.currentState!.debugBindWatchTogetherForTesting();
            fakePlayer.emitPlaybackRestart();
            await tester.pump(const Duration(milliseconds: 300));
            expect(watchTogether.isFollowing, isTrue);
            expect(guest.hasMedia, isTrue);
            if (transferred) {
              watchTogether.transferHost(guest.myPeerId!);
              await tester.pump(const Duration(milliseconds: 300));
              expect(watchTogether.isHost, isFalse);
              expect(guest.isHost, isTrue);
            }

            await tester.binding.handlePopRoute();
            await tester.pump();
            expect(find.byType(AlertDialog), findsNothing, reason: 'leaving the player never asks');
            await tester.pump(const Duration(seconds: 1));
            await tester.pump();
            expect(screen.key.currentState, isNull);
            expect(find.text('Browse'), findsOneWidget);
            expect(watchTogether.isInSession, isTrue, reason: 'leaving the player is not leaving the room');
            expect(relay.sent('leave'), isEmpty);
            expect(relay.sent('clearMedia'), hasLength(transferred ? 0 : 1));
            expect(guest.hasMedia, transferred);
            await closeRooms(tester, [watchTogether, guest]);
          },
        );
      },
    );
  }

  testWidgets('a file that fails for good leaves the room, which keeps its media and stops commanding it', (
    tester,
  ) async {
    final client = _ReloadClient();
    final (:watchTogether, :relay) = await hostRoom(tester, client);
    final guest = WatchTogetherProvider(
      partyFactory: relay.party,
      clientName: () async => 'Plezy/1.0',
      displayName: () => 'Ben',
    );
    final joining = guest.joinRoom(FakeOwpRelay.code);
    await tester.pump(const Duration(milliseconds: 100));
    await joining;
    final fakePlayer = _ExitPlayer();
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      testBody: () async {
        final screen = await _pushExitScreen(
          tester,
          db: db,
          client: client,
          fakePlayer: fakePlayer,
          watchTogether: watchTogether,
        );
        final state = screen.key.currentState!;
        await state.debugWirePlayerStreamsForTesting();
        state.debugBindWatchTogetherForTesting();
        fakePlayer.emitPlaybackRestart();
        await tester.pump(const Duration(milliseconds: 300));
        expect(watchTogether.isFollowing, isTrue);
        expect(guest.hasMedia, isTrue);

        fakePlayer.emitError(const PlayerError('the stream died'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(watchTogether.isFollowing, isFalse, reason: 'the room no longer counts on the dead file');
        expect(watchTogether.canJoinPlayback, isTrue, reason: 'the user can join again');
        expect(relay.sent('clearMedia'), isEmpty, reason: 'the room keeps its media');
        expect(guest.hasMedia, isTrue);

        final commands = fakePlayer.commandLog.length;
        await tester.pump(const Duration(seconds: 3));
        expect(fakePlayer.commandLog.skip(commands), isEmpty, reason: 'the room commands nothing on the dead file');
        await closeRooms(tester, [watchTogether, guest]);
      },
    );
  });

  Future<({GlobalKey<VideoPlayerScreenState> key, _ReloadPlayer player})> pumpReloadScreen(
    WidgetTester tester, {
    WatchTogetherProvider? watchTogether,
    _ReloadClient? client,
    bool isOffline = false,
    bool serverOnline = true,
  }) async {
    client ??= _ReloadClient();
    final multi = testMultiServer(clients: [client], offline: [if (!serverOnline) client]);
    final offlineWatch = OfflineWatchSyncService(database: db, serverManager: multi.manager);
    final accountPreferences = AccountPreferencesController();
    final initializationHold = Completer<void>();
    Future<void> holdInitialization() => initializationHold.future;
    PlaybackCoordinator.instance.registerMusicSession(stopAndDispose: holdInitialization);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      PlaybackCoordinator.instance.unregisterMusicSession(holdInitialization);
      if (!initializationHold.isCompleted) initializationHold.complete();
      await tester.pump();
      offlineWatch.dispose();
      accountPreferences.dispose();
    });
    final key = GlobalKey<VideoPlayerScreenState>();
    final item = testMediaItem(id: 'movie-prior', serverId: 'srv-1', backend: MediaBackend.jellyfin);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => PlaybackStateProvider()),
          ChangeNotifierProvider<MultiServerProvider>.value(value: multi.provider),
          ChangeNotifierProvider<OfflineWatchSyncService>.value(value: offlineWatch),
          ChangeNotifierProvider<AccountPreferencesController>.value(value: accountPreferences),
          ChangeNotifierProvider<WatchTogetherProvider>.value(value: watchTogether ?? WatchTogetherProvider()),
          Provider<AppDatabase>.value(value: db),
          ChangeNotifierProvider(create: (_) => CompanionRemoteProvider()),
        ],
        child: MaterialApp(
          home: VideoPlayerScreen(
            key: key,
            metadata: item,
            selectedQualityPreset: TranscodeQualityPreset.original,
            isOffline: isOffline,
          ),
        ),
      ),
    );
    final fakePlayer = _ReloadPlayer(opens: true);
    addTearDown(fakePlayer.dispose);
    key.currentState!.player = fakePlayer;
    return (key: key, player: fakePlayer);
  }

  group('TV background suspend', () {
    testWidgets('a suspend under the Play Next prompt restores the prompt and its countdown', (tester) async {
      TvDetectionService.debugSetAppleTVOverride(true);
      addTearDown(() {
        TvDetectionService.debugSetAppleTVOverride(null);
      });

      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        testBody: () async {
          final screen = await pumpReloadScreen(tester);
          final state = screen.key.currentState!;
          final fakePlayer = screen.player;
          await state.debugWirePlayerStreamsForTesting();
          fakePlayer.emitPlaybackRestart();
          await state.debugMarkPlaybackStartedForTesting();
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          // The restore's reload drops the adjacent episodes and resolves them
          // again, here from the queue the episode was launched in.
          final next = testMediaItem(
            id: 'next',
            title: 'Next episode',
            serverId: 'srv-1',
            backend: MediaBackend.jellyfin,
          );
          Provider.of<PlaybackStateProvider>(
            screen.key.currentContext!,
            listen: false,
          ).setPlaybackFromLocalQueue(LocalPlayQueue(items: [state.widget.metadata, next], currentIndex: 0));
          state.debugCommitAdjacentEpisodesForTesting(
            AdjacentEpisodes(
              next: next,
              nextStatus: QueueNavigationStatus.found,
              previousStatus: QueueNavigationStatus.boundary,
            ),
          );

          fakePlayer.setPosition(fakePlayer.state.duration - const Duration(seconds: 2));
          fakePlayer.emitPlaying(false);
          fakePlayer.setCompleted(true);
          state.debugCompleteVideoForTesting();
          await pumpUntil(tester, () => state.debugPlayNextPromptVisibleForTesting);
          final countdownAtBackground = state.debugAutoPlayCountdownForTesting;
          expect(countdownAtBackground, greaterThan(0));

          // Backgrounded, the countdown holds; the TV grace timer then
          // releases the pipeline.
          tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
          tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
          await tester.pump(const Duration(seconds: 3));
          expect(state.debugAutoPlayCountdownForTesting, countdownAtBackground);
          await state.debugSuspendForTvBackgroundForTesting();
          expect(fakePlayer.stopCalls, 1);

          // Returning restores the finished episode in place, which clears the
          // prompt; it has to come back with the countdown where it held.
          final opensBefore = fakePlayer.openCalls;
          // On the way back the app is no longer backgrounded before the
          // restore runs (a slow stop report can hold it there); the released
          // player must not be advanced from under the restore meanwhile.
          tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
          await tester.pump(Duration(seconds: countdownAtBackground + 2));
          expect(state.debugAutoPlayCountdownForTesting, countdownAtBackground);
          expect(fakePlayer.openCalls, opensBefore, reason: 'the countdown must not start the next episode');
          tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
          for (var i = 0; i < 400 && fakePlayer.openCalls == opensBefore; i++) {
            await tester.pump(const Duration(milliseconds: 50));
            if (fakePlayer.openCalls == opensBefore) {
              await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
            }
          }
          expect(fakePlayer.openCalls, opensBefore + 1, reason: 'the restore reopens the suspended item');
          await pumpUntil(tester, () => state.debugPlayNextPromptVisibleForTesting);
          expect(state.debugAutoPlayCountdownForTesting, countdownAtBackground);

          await tester.pump(const Duration(seconds: 1));
          expect(state.debugAutoPlayCountdownForTesting, countdownAtBackground - 1, reason: 'the countdown resumes');
        },
      );
    });
  });

  group('Windows display-switch hold', () {
    testWidgets('the hold does not reach the Watch Together room', (tester) async {
      final client = _ReloadClient();
      final (:watchTogether, :relay) = await hostRoom(tester, client);

      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        testBody: () async {
          final screen = await pumpReloadScreen(tester, watchTogether: watchTogether, client: client);
          final fakePlayer = screen.player;
          screen.key.currentState!.debugBindWatchTogetherForTesting();
          fakePlayer.emitPlaybackRestart();
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          // The room plays the host's file once everyone is ready.
          expect(relay.phase, 'playing');
          expect(fakePlayer.state.playing, isTrue);
          final adapter = screen.key.currentState!.debugWatchTogetherAdapter;

          var held = false;
          final hold = screen.key.currentState!
              .debugHoldPlaybackForDisplaySwitchForTesting(const Duration(seconds: 2))
              .whenComplete(() => held = true);
          await tester.pump();
          expect(fakePlayer.state.playing, isFalse, reason: 'playback is held through the delay');
          await tester.pump(const Duration(seconds: 3));
          await pumpUntil(tester, () => held);
          await hold;
          await tester.pump(const Duration(milliseconds: 300));

          expect(fakePlayer.state.playing, isTrue);
          expect(relay.sent('pause'), isEmpty, reason: 'the internal hold must not pause the room');
          expect(relay.phase, 'playing');
          expect(screen.key.currentState!.debugWatchTogetherAdapter, same(adapter));
          expect(watchTogether.isFollowing, isTrue, reason: 'the room drives the player again once the hold ends');
          await closeRooms(tester, [watchTogether]);
        },
      );
    });

    testWidgets('a hold outlasted by a room source reload leaves the room waiting for the reload', (tester) async {
      final client = _ReloadClient();
      final (:watchTogether, :relay) = await hostRoom(tester, client);

      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        testBody: () async {
          final screen = await pumpReloadScreen(tester, watchTogether: watchTogether, client: client);
          final fakePlayer = screen.player;
          screen.key.currentState!.debugBindWatchTogetherForTesting();
          fakePlayer.emitPlaybackRestart();
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          expect(watchTogether.isFollowing, isTrue);
          final adapter = screen.key.currentState!.debugWatchTogetherAdapter;

          var held = false;
          final hold = screen.key.currentState!
              .debugHoldPlaybackForDisplaySwitchForTesting(const Duration(seconds: 2))
              .whenComplete(() => held = true);
          await tester.pump();

          // The replacement's open is held past the display delay: the reload
          // is still in flight when the hold's delay runs out.
          final openGate = Completer<void>();
          fakePlayer.openGate = openGate;
          PlaybackSourceChangeOutcome? outcome;
          final switching = screen.key.currentState!
              .debugSwitchPlaybackSourceForTesting(newPreset: TranscodeQualityPreset.p720_2mbps)
              .then((value) => outcome = value);
          for (var i = 0; i < 400 && fakePlayer.openCalls == 0; i++) {
            await tester.pump(const Duration(milliseconds: 50));
            await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
          }
          expect(fakePlayer.openCalls, 1, reason: 'the reload reached its open');
          await tester.pump(const Duration(seconds: 3));

          expect(outcome, isNull);
          expect(held, isFalse, reason: 'the hold waits out the reload in flight');
          expect(watchTogether.state.me?.player, owp.PlayerState.loading, reason: 'the room waits for the reload');

          openGate.complete();
          for (var i = 0; i < 400 && (outcome == null || !held); i++) {
            await tester.pump(const Duration(milliseconds: 50));
            await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
          }
          await switching;
          await hold;
          await tester.pump(const Duration(milliseconds: 300));

          expect(outcome, PlaybackSourceChangeOutcome.applied);
          // Another quality of the same file stays the room's file.
          expect(screen.key.currentState!.debugWatchTogetherAdapter, same(adapter));
          expect(watchTogether.isFollowing, isTrue);
          expect(relay.sent('setMedia'), hasLength(1));
          expect(relay.sent('pause'), isEmpty);
          await closeRooms(tester, [watchTogether]);
        },
      );
    });

    testWidgets("a source reload during the hold owns the replacement's play state", (tester) async {
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        testBody: () async {
          final screen = await pumpReloadScreen(tester);
          final fakePlayer = screen.player;
          fakePlayer.emitPlaybackRestart();
          await tester.pump();

          var held = false;
          final hold = screen.key.currentState!
              .debugHoldPlaybackForDisplaySwitchForTesting(const Duration(seconds: 2))
              .whenComplete(() => held = true);
          await tester.pump();
          expect(fakePlayer.commandLog, ['pause']);

          // A quality change during the delay reuses the player and keeps the
          // play intent, so only the playback generation tells the hold its
          // player now carries another open.
          PlaybackSourceChangeOutcome? outcome;
          final switching = screen.key.currentState!
              .debugSwitchPlaybackSourceForTesting(newPreset: TranscodeQualityPreset.p720_2mbps)
              .then((value) => outcome = value);
          for (var i = 0; i < 400 && (outcome == null || !held); i++) {
            await tester.pump(const Duration(milliseconds: 50));
            await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
          }
          await switching;
          await hold;

          expect(fakePlayer.openCalls, 1, reason: 'the reload opened a replacement');
          expect(
            fakePlayer.commandLog.where((command) => command == 'play'),
            isEmpty,
            reason: 'the superseded hold must not resume the replacement',
          );
        },
      );
    });
  });

  group('a download in the room', () {
    for (final serverOnline in [true, false]) {
      testWidgets(
        serverOnline
            ? 'a host playing from the offline library shares the download while its server is online'
            : "a host's download stays out of the room while its server is offline",
        (tester) async {
          final client = _ReloadClient();
          final (:watchTogether, :relay) = await hostRoom(tester, client);
          final notices = <WatchNotice>[];
          final noticesSubscription = watchTogether.notices.listen(notices.add);
          addTearDown(noticesSubscription.cancel);

          await withMockPlayerChannels(
            methodChannelName: 'com.plezy/mpv_player',
            eventChannelName: 'com.plezy/mpv_player/events',
            testBody: () async {
              final screen = await pumpReloadScreen(
                tester,
                watchTogether: watchTogether,
                client: client,
                isOffline: true,
                serverOnline: serverOnline,
              );
              screen.key.currentState!.debugBindWatchTogetherForTesting();
              screen.player.emitPlaybackRestart();
              await tester.pump();
              await tester.pump(const Duration(seconds: 1));

              if (serverOnline) {
                expect(relay.sent('setMedia'), hasLength(1), reason: 'the room gets the server copy of the download');
                expect(watchTogether.isFollowing, isTrue);
                expect(notices.whereType<NotSharedNotice>(), isEmpty);
              } else {
                expect(relay.sent('setMedia'), isEmpty);
                expect(watchTogether.isFollowing, isFalse, reason: 'the download plays on its own');
                expect(notices.whereType<NotSharedNotice>(), hasLength(1));
              }
              await closeRooms(tester, [watchTogether]);
            },
          );
        },
      );
    }
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

  /// When set, open() waits for it before loading.
  Completer<void>? openGate;
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
  bool get needsDecoderRefreshAfterDisplaySwitch => false;

  @override
  Future<void> setProperty(String name, String value) async {}

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
    Duration timelineOffset = Duration.zero,
  }) async {
    openCalls++;
    final gate = openGate;
    if (gate != null) await gate.future;
    if (!opens) throw StateError('open failed before the open boundary');
    setPosition(media.start ?? Duration.zero);
    setCompleted(false);
    emitPlaying(play);
    emitFileStarted();
    emitPlaybackRestart();
  }

  @override
  Future<void> selectSubtitleTrack(SubtitleTrack track) async {}
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
  Future<ExternalIds> fetchExternalIds(String itemId) async => const ExternalIds();
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
    VideoPlayerRoute(
      joinsWatchTogether: true,
      builder: (_) => VideoPlayerScreen(
        key: key,
        metadata: testMediaItem(id: 'exit-original', serverId: 'srv-1', backend: MediaBackend.jellyfin),
        selectedQualityPreset: TranscodeQualityPreset.original,
      ),
    ).push(navigator.currentState!),
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

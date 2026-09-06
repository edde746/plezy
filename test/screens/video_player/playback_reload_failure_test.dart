import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/media/media_display_criteria.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/providers/account_preferences_controller.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/offline_watch_sync_service.dart';
import 'package:plezy/services/playback_initialization_types.dart';
import 'package:plezy/services/playback_coordinator.dart';
import 'package:plezy/services/settings_service.dart';
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
}

class _ReloadPlayer extends FakeSyncPlayer {
  _ReloadPlayer({required this.opens})
    : super(playing: true, position: const Duration(seconds: 121), duration: const Duration(minutes: 40), rate: 1.25);
  bool opens;
  int openCalls = 0;

  @override
  String get playerType => 'mpv';

  @override
  bool get attachesExternalSubtitlesAtOpen => true;

  @override
  bool get needsDecoderRefreshAfterDisplaySwitch => false;

  @override
  Future<void> setProperty(String name, String value) async {}

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

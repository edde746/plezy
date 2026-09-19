import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/livetv_channel.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/providers/offline_mode_provider.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/screens/video_player/live_tv_session_args.dart';
import 'package:plezy/screens/video_player/media_controls_screen_controller.dart';
import 'package:plezy/screens/video_player/wakelock_controller.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/media_controls_manager.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/offline_watch_sync_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/mock_player_channels.dart';
import '../../test_helpers/multi_server_fixtures.dart';
import '../../test_helpers/player_streams.dart';
import '../../test_helpers/prefs.dart';

/// Regression coverage for #2388: a live channel publishes nothing to the OS
/// media session, so Assistant, the Android TV Now Playing card and AVRCP
/// remotes had no transport to drive. Live TV used to bail out of
/// `_initializeServices` before the media-controls layer existed, which left
/// `MediaControlsManager` unconstructed for the whole screen lifetime.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const mediaControlChannel = MethodChannel('com.edde746.os_media_controls/methods');
  const mediaControlEvents = MethodChannel('com.edde746.os_media_controls/events');
  final calls = <MethodCall>[];

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    calls.clear();
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(mediaControlChannel, (call) async {
      calls.add(call);
      return null;
    });
    messenger.setMockMethodCallHandler(mediaControlEvents, (call) async => null);
  });

  tearDown(() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(mediaControlChannel, null);
    messenger.setMockMethodCallHandler(mediaControlEvents, null);
  });

  testWidgets('a live channel registers a media session titled after the channel', (tester) async {
    final channel = LiveTvChannel(key: 'ch-1', title: 'Channel 5', serverId: 'srv-1');
    final player = _LiveMediaSessionPlayer();
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final serverManager = MultiServerManager();
    final multiServer = testMultiServerProvider(serverManager);
    final offlineWatch = OfflineWatchSyncService(database: db, serverManager: serverManager);
    addTearDown(() async {
      multiServer.dispose();
      offlineWatch.dispose();
      serverManager.dispose();
      await db.close();
    });

    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      // The shell has no live server to tune. Refusing the core keeps the
      // screen's own initialization settling on a short failure instead of a
      // provider error, so the service layer can be driven directly below.
      methodHandler: (call) async => call.method == 'initialize' ? false : null,
      testBody: () async {
        final key = GlobalKey<VideoPlayerScreenState>();
        await tester.pumpWidget(
          _liveScreen(
            key: key,
            channel: channel,
            multiServer: multiServer,
            offlineWatch: offlineWatch,
            serverManager: serverManager,
          ),
        );
        // The shell has no live server, so the screen's own initialization
        // attempt fails and settles before the service layer is driven
        // directly through its testing seam.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        key.currentState!.player = player;
        await key.currentState!.debugInitializeServicesForTesting();
        await tester.pump();

        expect(calls.where((call) => call.method == 'setMetadata').map((call) => (call.arguments as Map)['title']), [
          channel.displayName,
        ], reason: 'the session must carry the tuned channel');

        // A channel with no capture buffer can only play, pause and stop: the
        // OS is told so rather than shown dead ±skip/seek/speed controls.
        expect(calls.where((call) => call.method == 'enableControls').map((call) => call.arguments).toList(), [
          ['play', 'pause', 'stop'],
        ]);
        expect(calls.where((call) => call.method == 'disableControls').map((call) => call.arguments).toList(), [
          ['previous', 'next', 'seek', 'skipForward', 'skipBackward', 'changeSpeed'],
        ]);

        // This player never emits a position tick, so only initialization
        // itself can publish a state — the case a stream paused before the
        // listener attaches would otherwise leave at the default.
        expect(
          calls.where((call) => call.method == 'setPlaybackState').map((call) => (call.arguments as Map)['state']),
          ['paused'],
        );

        // Retire the heartbeat's deferred first report and the periodic timer.
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  });

  test('live skip follows the capture buffer and never rewinds on resume', () async {
    final previousPlatformOverride = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = previousPlatformOverride);

    final player = _LiveMediaSessionPlayer();
    final seeks = <Duration>[];
    final manager = MediaControlsManager();
    addTearDown(manager.dispose);
    var hasSeekWindow = false;
    final controller = MediaControlsScreenController(
      manager: () => manager,
      player: () => player,
      isMounted: () => true,
      isLive: true,
      hasLiveSeekWindow: () => hasSeekWindow,
      shouldSkipForPip: () => false,
      isPlayerInitialized: () => true,
      metadata: () => testMediaItem(kind: MediaKind.clip, title: 'Channel 5'),
      client: () => null,
      isPlaylistActive: () => false,
      canControlPlayback: () => true,
      canNavigateMediaItems: () => true,
      rewindOnResumeSeconds: () => 10,
      seek: (position) async => seeks.add(position),
      play: (_) async {},
      wasPlayingBeforeInactive: () => false,
      clearWasPlayingBeforeInactive: () {},
      wakelock: WakelockController(),
      recordLifecycle: (_, {action}) {},
    );

    await controller.syncAvailability();
    expect(
      calls.firstWhere((call) => call.method == 'disableControls').arguments,
      containsAll(<String>['skipForward', 'skipBackward']),
      reason: 'a live stream with no time-shift window cannot serve a skip',
    );

    calls.clear();
    hasSeekWindow = true;
    await controller.syncAvailability();
    expect(
      calls.firstWhere((call) => call.method == 'enableControls').arguments,
      containsAll(<String>['skipForward', 'skipBackward']),
      reason: 'the capture buffer is what makes ±skip meaningful',
    );

    // Rewind-on-resume is an absolute VOD seek; on live it would drag the
    // playhead off the live edge.
    await controller.seekBackForRewind(player);
    expect(seeks, isEmpty);
  });
}

Widget _liveScreen({
  required GlobalKey<VideoPlayerScreenState> key,
  required LiveTvChannel channel,
  required MultiServerProvider multiServer,
  required OfflineWatchSyncService offlineWatch,
  required MultiServerManager serverManager,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => PlaybackStateProvider()),
      ChangeNotifierProvider<MultiServerProvider>.value(value: multiServer),
      ChangeNotifierProvider<OfflineWatchSyncService>.value(value: offlineWatch),
      // The screen's own initialization reads this while resolving the
      // quality preset; without it the shell fails on a provider error whose
      // message is a paragraph of framework prose.
      ChangeNotifierProvider<OfflineModeProvider>(create: (_) => OfflineModeProvider(serverManager)),
    ],
    child: MaterialApp(
      home: VideoPlayerScreen(
        key: key,
        metadata: testMediaItem(id: channel.key, kind: MediaKind.clip, title: channel.displayName),
        live: LiveTvSessionArgs(channel: channel),
      ),
    ),
  );
}

class _LiveMediaSessionPlayer implements Player {
  _LiveMediaSessionPlayer()
    : _state = const PlayerState(position: Duration.zero, duration: Duration.zero, seekable: false);

  final PlayerState _state;

  @override
  PlayerState get state => _state;

  @override
  PlayerStreams get streams => emptyPlayerStreams();

  @override
  Future<void> dispose({bool preserveDisplayMode = false}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

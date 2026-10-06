import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_part.dart';
import 'package:plezy/media/media_part_timeline.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/providers/account_preferences_controller.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/providers/offline_mode_provider.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/music/music_playback_service.dart';
import 'package:plezy/services/offline_watch_sync_service.dart';
import 'package:plezy/services/playback_coordinator.dart';
import 'package:plezy/services/playback_initialization_types.dart';
import 'package:plezy/services/scrub_preview_source.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/video_player_navigation.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/io_fakes.dart';
import '../../test_helpers/media_items.dart';
import '../../test_helpers/mock_player_channels.dart';
import '../../test_helpers/multi_server_fixtures.dart';
import '../../test_helpers/playback_report_fakes.dart';
import '../../test_helpers/prefs.dart';
import '../../test_helpers/stub_music_playback_service.dart';
import '../../test_helpers/watch_together_fakes.dart';

/// A movie stacked across two files (`Part 1` 50 min, `Part 2` 40 min) plays
/// as one 90-minute item (#2586): the first file playing out opens the second
/// rather than finishing the movie, and a seek past the open file opens the
/// file holding the target. Music-session arbitration holds native creation
/// so a deterministic player owns the opens.
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
    tmpRoot = await Directory.systemTemp.createTemp('stacked_part_playback_test_');
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

  /// Pump until [opens] files have been opened; drift work needs real
  /// event-loop yields.
  Future<void> pumpUntilOpened(WidgetTester tester, _StackedPlayer player, int opens) async {
    for (var i = 0; i < 400 && player.opens.length < opens; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
    }
    await tester.pump();
  }

  /// Opens part 1 through the screen's in-place reload, the way any source
  /// switch does, so a stacked session is committed.
  Future<GlobalKey<VideoPlayerScreenState>> startOnPartOne(
    WidgetTester tester,
    _StackedPlayer player,
    _StackedClient client,
  ) async {
    final key = await _pushScreen(tester, db: db, player: player, client: client);
    unawaited(key.currentState!.debugSwitchPlaybackSourceForTesting(newAudioStreamId: 2));
    await pumpUntilOpened(tester, player, 1);
    expect(player.opens.single, (
      uri: 'https://example.invalid/part-1',
      start: const Duration(minutes: 2),
      offset: Duration.zero,
      duration: const Duration(minutes: 90),
    ));
    return key;
  }

  testWidgets('the first file playing out opens the second instead of finishing the movie', (tester) async {
    final player = _StackedPlayer();
    final client = _StackedClient();
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      testBody: () async {
        await startOnPartOne(tester, player, client);

        player.setPosition(const Duration(minutes: 50));
        player.emitCompleted();
        await pumpUntilOpened(tester, player, 2);

        expect(client.startPositions.last, const Duration(minutes: 50));
        expect(player.opens.last, (
          uri: 'https://example.invalid/part-2',
          start: const Duration(minutes: 50),
          offset: const Duration(minutes: 50),
          duration: const Duration(minutes: 90),
        ));
        expect(find.text('Browse'), findsNothing, reason: 'the movie goes on in its second file');

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  });

  testWidgets('a seek past the open file opens the file holding the target; one inside it seeks natively', (
    tester,
  ) async {
    final player = _StackedPlayer();
    final client = _StackedClient();
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      testBody: () async {
        final key = await startOnPartOne(tester, player, client);

        unawaited(key.currentState!.debugSeekPlaybackForTesting(const Duration(minutes: 70)));
        await pumpUntilOpened(tester, player, 2);
        expect(player.commandLog.where((command) => command.startsWith('seek:')), isEmpty);
        expect(player.opens.last, (
          uri: 'https://example.invalid/part-2',
          start: const Duration(minutes: 70),
          offset: const Duration(minutes: 50),
          duration: const Duration(minutes: 90),
        ));

        await key.currentState!.debugSeekPlaybackForTesting(const Duration(minutes: 75));
        await tester.pump();
        expect(player.opens, hasLength(2));
        expect(player.commandLog.last, 'seek:${const Duration(minutes: 75).inMilliseconds}');

        // Back into the first file.
        unawaited(key.currentState!.debugSeekPlaybackForTesting(const Duration(minutes: 10)));
        await pumpUntilOpened(tester, player, 3);
        expect(player.opens.last.uri, 'https://example.invalid/part-1');
        expect(player.opens.last.offset, Duration.zero);
        expect(player.opens.last.start, const Duration(minutes: 10));

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  });
}

typedef _Open = ({String uri, Duration? start, Duration offset, Duration? duration});

Future<GlobalKey<VideoPlayerScreenState>> _pushScreen(
  WidgetTester tester, {
  required AppDatabase db,
  required _StackedPlayer player,
  required _StackedClient client,
}) async {
  final multi = testMultiServer(clients: [client]);
  final offlineWatch = OfflineWatchSyncService(database: db, serverManager: multi.manager);
  final offlineMode = OfflineModeProvider(multi.manager, multiServerProvider: multi.provider);
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
    offlineMode.dispose();
    accountPreferences.dispose();
    await player.dispose();
  });
  final navigator = GlobalKey<NavigatorState>();
  final key = GlobalKey<VideoPlayerScreenState>();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlaybackStateProvider()),
        ChangeNotifierProvider<MultiServerProvider>.value(value: multi.provider),
        ChangeNotifierProvider<OfflineWatchSyncService>.value(value: offlineWatch),
        ChangeNotifierProvider<OfflineModeProvider>.value(value: offlineMode),
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
        metadata: testMediaItem(
          id: 'stacked',
          serverId: 'srv-1',
          backend: MediaBackend.jellyfin,
          durationMs: const Duration(minutes: 90).inMilliseconds,
        ),
        selectedQualityPreset: TranscodeQualityPreset.original,
        selectedAudioStreamId: 1,
      ),
    ).push(navigator.currentState!),
  );
  await tester.pump();
  key.currentState!.player = player;
  await key.currentState!.debugWirePlayerStreamsForTesting();
  player.emitPlaybackRestart();
  await tester.pump();
  return key;
}

class _StackedPlayer extends FakeSyncPlayer {
  _StackedPlayer() : super(playing: true, position: const Duration(minutes: 2), duration: const Duration(minutes: 50));

  final opens = <_Open>[];

  final _completedController = StreamController<bool>.broadcast();

  void emitCompleted() {
    setCompleted(true);
    _completedController.add(true);
  }

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
      error: base.error,
      audioDevice: base.audioDevice,
      audioDevices: base.audioDevices,
      bufferRanges: base.bufferRanges,
      playbackRestart: base.playbackRestart,
      fileStarted: base.fileStarted,
      backendSwitched: base.backendSwitched,
    );
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
    Duration timelineOffset = Duration.zero,
  }) async {
    opens.add((uri: media.uri, start: media.start, offset: timelineOffset, duration: timelineDuration));
    setPosition(media.start ?? timelineOffset);
    if (timelineDuration != null) emitDuration(timelineDuration);
    setCompleted(false);
    _completedController.add(false);
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
  }
}

/// Resolves the file holding the requested start position, the way the Plex
/// mapper does, and names it in the URL.
class _StackedClient with PlaybackReportRecorder implements MediaServerClient {
  static const _parts = [MediaPart(id: '11', durationMs: 3000000), MediaPart(id: '12', durationMs: 2400000)];

  final startPositions = <Duration?>[];

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
    startPositions.add(options.startPosition);
    final index = MediaPartTimeline.fromParts(_parts)!.indexAt(options.startPosition ?? Duration.zero);
    final url = 'https://example.invalid/part-${index + 1}';
    return PlaybackInitializationResult(
      availableVersions: const [],
      activeAudioStreamId: options.selectedAudioStreamId,
      videoUrl: url,
      mediaInfo: MediaSourceInfo(
        videoUrl: url,
        audioTracks: const [],
        subtitleTracks: const [],
        chapters: const [],
        partId: 11 + index,
        mediaSourceId: 'version-1',
        mediaIndex: 0,
        partIndex: index,
        partTimeline: MediaPartTimeline.fromParts(_parts, currentIndex: index),
      ),
    );
  }

  @override
  Future<ScrubPreviewSource?> createScrubPreviewSource({
    required MediaItem item,
    required MediaSourceInfo mediaSource,
  }) async => null;

  @override
  Future<void> onPlaybackReport(PlaybackReportCall call) async {}

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

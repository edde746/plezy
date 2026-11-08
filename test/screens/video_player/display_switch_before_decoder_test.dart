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

/// An Android mpv VOD open switches the display while the file's video
/// decoder is held, before the decoder exists, as Kodi does (#2998): a Dolby
/// Vision decoder created at 59.94 Hz and carried through the switch to
/// 23.976 Hz left the Fire TV Stick 4K's picture green. The first-frame check
/// that follows switches again only when the presented rate differs.
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
    await SettingsService.instance.write(SettingsService.matchContentFrameRate, true);
    tmpRoot = await Directory.systemTemp.createTemp('display_switch_before_decoder_test_');
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

  for (final (:description, :containerFps, :presentedFps, :expected) in [
    (
      description: 'progressive video switches once, before the decoder opens',
      containerFps: 23.976,
      presentedFps: 23.976,
      expected: [
        'hold',
        'open paused',
        'switch 23.976',
        'release',
        'decoder',
        'frame-step',
        // The first-frame check finds the display already matched; the seek
        // replays the stepped frames.
        'keep 23.976',
        'seek 120000',
        'play',
      ],
    ),
    (
      // mpv exposes no field order before decoding: the declared frame rate
      // is matched first, the field rate the decoder presents after.
      description: 'interlaced video a decoder presents as fields is corrected at the first frame',
      containerFps: 29.97,
      presentedFps: 59.94,
      expected: [
        'hold',
        'open paused',
        'switch 29.970',
        'release',
        'decoder',
        'frame-step',
        'switch 59.940',
        'seek 120000',
        'play',
      ],
    ),
  ]) {
    testWidgets(description, (tester) async {
      final player = _HeldDecoderPlayer(containerFps: containerFps, presentedFps: presentedFps);
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        testBody: () async {
          final key = await _pushScreen(tester, db: db, player: player, client: _MovieClient());
          player.events.clear();

          await tester.runAsync(() => key.currentState!.debugSwitchPlaybackSourceForTesting(newAudioStreamId: 2));

          expect(player.events, expected);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        },
      );
    });
  }
}

Future<GlobalKey<VideoPlayerScreenState>> _pushScreen(
  WidgetTester tester, {
  required AppDatabase db,
  required _HeldDecoderPlayer player,
  required _MovieClient client,
}) async {
  final multi = testMultiServer(clients: [client]);
  final offlineWatch = OfflineWatchSyncService(database: db, serverManager: multi.manager);
  final offlineMode = OfflineModeProvider(multi.manager, multiServerProvider: multi.provider);
  final accountPreferences = AccountPreferencesController();
  // Music-session arbitration holds native creation, so the fake player
  // owns every open.
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
          id: 'movie',
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

/// An Android mpv core with a display: holds the next file's decoder when
/// asked and opens it on release, declares [containerFps] and presents
/// [presentedFps], and switches the display only to a rate it is not
/// already at. Records the opens, holds, display requests, decoder opens and
/// transport, in order.
class _HeldDecoderPlayer extends FakeSyncPlayer {
  _HeldDecoderPlayer({required this.containerFps, required this.presentedFps})
    : super(playing: true, position: const Duration(minutes: 2), duration: const Duration(minutes: 90));

  final double containerFps;
  final double presentedFps;
  final events = <String>[];
  double _displayFps = 59.94;
  bool _decoderOpen = false;
  ({Completer<DemuxedVideoFormat?> format, Completer<void> released})? _armed;

  // Load signals this player never raises. They stay open: the open outcome
  // reads a closed stream as a player that went away.
  final _silent = StreamController<void>.broadcast();

  @override
  PlayerStreams get streams {
    final base = super.streams;
    return PlayerStreams(
      playing: base.playing,
      completed: base.completed,
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
      fileLoaded: _silent.stream,
      fileLoadFailed: _silent.stream,
      primaryMediaReady: _silent.stream,
      backendSwitched: base.backendSwitched,
    );
  }

  @override
  bool get needsDecoderRefreshAfterDisplaySwitch => true;

  @override
  VideoDecoderHold? holdVideoDecoderAtPreload() {
    events.add('hold');
    final armed = (format: Completer<DemuxedVideoFormat?>(), released: Completer<void>());
    _armed = armed;
    return VideoDecoderHold(
      format: armed.format.future,
      release: () async {
        events.add('release');
        if (!armed.released.isCompleted) armed.released.complete();
      },
    );
  }

  @override
  Future<void> open(
    Media media, {
    bool play = true,
    bool isLive = false,
    List<SubtitleTrack>? externalSubtitles,
    Duration? timelineDuration,
    Duration timelineOffset = Duration.zero,
  }) async {
    events.add(play ? 'open playing' : 'open paused');
    beginOpen();
    _decoderOpen = false;
    setPosition(media.start ?? Duration.zero);
    emitPlaying(play);
    emitFileStarted();
    final armed = _armed;
    _armed = null;
    void openDecoder() {
      _decoderOpen = true;
      events.add('decoder');
      emitPlaybackRestart();
    }

    if (armed == null) {
      openDecoder();
      return;
    }
    // The demuxer opened the file; the decoder waits for the release.
    armed.format.complete((fps: containerFps, width: 3840, height: 2160));
    unawaited(armed.released.future.then((_) => openDecoder()));
  }

  @override
  Future<String?> getProperty(String name) async => switch (name) {
    'video-dec-params/w' || 'width' => _decoderOpen ? '3840' : null,
    'height' => _decoderOpen ? '2160' : null,
    'container-fps' => '$containerFps',
    'deinterlace-active' || 'ivtc-active' => 'no',
    'time-pos' => '${state.position.inMicroseconds / Duration.microsecondsPerSecond}',
    'pause' => state.playing ? 'no' : 'yes',
    'mute' => 'no',
    _ => null,
  };

  @override
  Future<void> command(List<String> args) async {
    if (args.first != 'frame-step') return;
    events.add('frame-step');
    final frames = int.parse(args[1]);
    final fps = presentedFps;
    setPosition(state.position + Duration(microseconds: (frames * Duration.microsecondsPerSecond / fps).round()));
    emitPlaying(true);
    emitPlaying(false);
  }

  @override
  Future<bool> setVideoFrameRate(
    double fps,
    int durationMs, {
    int extraDelayMs = 0,
    int videoWidth = 0,
    int videoHeight = 0,
    bool matchResolution = false,
  }) async {
    final label = fps.toStringAsFixed(3);
    if ((fps - _displayFps).abs() < 0.01) {
      events.add('keep $label');
      return false;
    }
    _displayFps = fps;
    events.add('switch $label');
    return true;
  }

  @override
  Future<void> seek(Duration position) async {
    events.add('seek ${position.inMilliseconds}');
    await super.seek(position);
  }

  @override
  Future<void> play() async {
    events.add('play');
    await super.play();
  }

  @override
  Duration get timelineOffset => Duration.zero;

  @override
  Future<void> updateFrame() async {}

  @override
  Future<bool> requestAudioFocus() async => true;

  @override
  Future<void> selectSubtitleTrack(SubtitleTrack track) async {}

  @override
  Future<void> dispose({bool preserveDisplayMode = false}) async {
    if (disposed) return;
    await super.dispose(preserveDisplayMode: preserveDisplayMode);
    await _silent.close();
  }
}

class _MovieClient with PlaybackReportRecorder implements MediaServerClient {
  static const _url = 'https://example.invalid/movie';

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
    return PlaybackInitializationResult(
      availableVersions: const [],
      activeAudioStreamId: options.selectedAudioStreamId,
      videoUrl: _url,
      mediaInfo: MediaSourceInfo(
        videoUrl: _url,
        audioTracks: const [],
        subtitleTracks: const [],
        chapters: const [],
        partId: 11,
        mediaSourceId: 'version-1',
        mediaIndex: 0,
        partIndex: 0,
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

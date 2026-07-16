import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:os_media_controls/os_media_controls.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_display_criteria.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/playback_report_metadata.dart';
import 'package:plezy/mpv/models.dart';
import 'package:plezy/mpv/player/player.dart';
import 'package:plezy/mpv/player/player_state.dart';
import 'package:plezy/mpv/player/player_streams.dart';
import 'package:plezy/services/media_controls_manager.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/music/music_playback_service.dart';
import 'package:plezy/services/music/music_playback_service_impl.dart';
import 'package:plezy/services/music/music_source_resolver.dart';
import 'package:plezy/services/playback_coordinator.dart';
import '../../test_helpers/media_items.dart';

const _trackDuration = Duration(minutes: 3);

MediaItem _track(String id) => testMediaItem(
  id: id,
  backend: MediaBackend.plex,
  kind: MediaKind.track,
  title: 'Track $id',
  parentTitle: 'Album',
  grandparentTitle: 'Artist',
  durationMs: _trackDuration.inMilliseconds,
  serverId: 'srv',
);

String _urlFor(MediaItem track) => 'fake://${track.id}';

/// In-memory audio player: records calls, exposes manual stream controllers
/// so tests drive transitions/completion/errors deterministically.
class FakePlayer implements Player {
  final playingCtrl = StreamController<bool>.broadcast(sync: true);
  final completedCtrl = StreamController<bool>.broadcast(sync: true);
  final bufferingCtrl = StreamController<bool>.broadcast(sync: true);
  final positionCtrl = StreamController<Duration>.broadcast(sync: true);
  final durationCtrl = StreamController<Duration>.broadcast(sync: true);
  final seekableCtrl = StreamController<bool>.broadcast(sync: true);
  final bufferCtrl = StreamController<Duration>.broadcast(sync: true);
  final volumeCtrl = StreamController<double>.broadcast(sync: true);
  final rateCtrl = StreamController<double>.broadcast(sync: true);
  final tracksCtrl = StreamController<Tracks>.broadcast(sync: true);
  final trackCtrl = StreamController<TrackSelection>.broadcast(sync: true);
  final logCtrl = StreamController<PlayerLog>.broadcast(sync: true);
  final errorCtrl = StreamController<PlayerError>.broadcast(sync: true);
  final audioDeviceCtrl = StreamController<AudioDevice>.broadcast(sync: true);
  final audioDevicesCtrl = StreamController<List<AudioDevice>>.broadcast(sync: true);
  final bufferRangesCtrl = StreamController<List<BufferRange>>.broadcast(sync: true);
  final playbackRestartCtrl = StreamController<void>.broadcast(sync: true);
  final fileLoadedCtrl = StreamController<void>.broadcast(sync: true);
  final backendSwitchedCtrl = StreamController<void>.broadcast(sync: true);
  final trackTransitionCtrl = StreamController<String>.broadcast(sync: true);

  late final PlayerStreams _streams = PlayerStreams(
    playing: playingCtrl.stream,
    completed: completedCtrl.stream,
    buffering: bufferingCtrl.stream,
    position: positionCtrl.stream,
    duration: durationCtrl.stream,
    seekable: seekableCtrl.stream,
    buffer: bufferCtrl.stream,
    volume: volumeCtrl.stream,
    rate: rateCtrl.stream,
    tracks: tracksCtrl.stream,
    track: trackCtrl.stream,
    log: logCtrl.stream,
    error: errorCtrl.stream,
    audioDevice: audioDeviceCtrl.stream,
    audioDevices: audioDevicesCtrl.stream,
    bufferRanges: bufferRangesCtrl.stream,
    playbackRestart: playbackRestartCtrl.stream,
    fileLoaded: fileLoadedCtrl.stream,
    backendSwitched: backendSwitchedCtrl.stream,
    trackTransition: trackTransitionCtrl.stream,
  );

  PlayerState _state = const PlayerState();

  final List<String> openedUris = [];
  final List<Media?> setNextCalls = [];
  final List<Duration> seeks = [];
  final List<double> volumes = [];

  /// Arming these URIs throws, simulating a native setNext failure.
  final Set<String> failingSetNextUris = {};
  int playCalls = 0;
  int pauseCalls = 0;
  int stopCalls = 0;
  bool _disposed = false;
  Media? _armedMedia;

  /// Effective armed item, mirroring the native playlist: set by [setNext],
  /// consumed by an auto-advance ([emitTransition]).
  Media? get armed => _armedMedia;

  void emitTransition(String uri) {
    _armedMedia = null; // the backend advanced into the armed entry
    _state = _state.copyWith(position: Duration.zero, duration: _trackDuration);
    trackTransitionCtrl.add(uri);
  }

  void emitCompleted() {
    _state = _state.copyWith(completed: true, position: _trackDuration);
    completedCtrl.add(true);
  }

  void emitError(String message) => errorCtrl.add(PlayerError(message));

  void setPosition(Duration position) {
    _state = _state.copyWith(position: position);
    positionCtrl.add(position);
  }

  void closeControllers() {
    playingCtrl.close();
    completedCtrl.close();
    bufferingCtrl.close();
    positionCtrl.close();
    durationCtrl.close();
    seekableCtrl.close();
    bufferCtrl.close();
    volumeCtrl.close();
    rateCtrl.close();
    tracksCtrl.close();
    trackCtrl.close();
    logCtrl.close();
    errorCtrl.close();
    audioDeviceCtrl.close();
    audioDevicesCtrl.close();
    bufferRangesCtrl.close();
    playbackRestartCtrl.close();
    fileLoadedCtrl.close();
    backendSwitchedCtrl.close();
    trackTransitionCtrl.close();
  }

  @override
  PlayerState get state => _state;

  @override
  PlayerStreams get streams => _streams;

  @override
  Duration get currentPosition => _state.position;

  @override
  bool get audioPassthroughActive => false;

  @override
  int? get textureId => null;

  @override
  String get playerType => 'fake';

  @override
  Future<void> open(
    Media media, {
    bool play = true,
    bool isLive = false,
    List<SubtitleTrack>? externalSubtitles,
    Duration timelineOffset = Duration.zero,
    Duration? timelineDuration,
  }) async {
    openedUris.add(media.uri);
    _state = _state.copyWith(playing: play, completed: false, position: Duration.zero, duration: _trackDuration);
    if (play) playingCtrl.add(true);
  }

  @override
  Future<void> play() async {
    playCalls++;
    _state = _state.copyWith(playing: true, completed: false);
    playingCtrl.add(true);
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
    _state = _state.copyWith(playing: false);
    playingCtrl.add(false);
  }

  @override
  Future<void> playOrPause() => _state.playing ? pause() : play();

  @override
  Future<void> stop() async {
    stopCalls++;
    _state = _state.copyWith(playing: false, position: Duration.zero);
  }

  @override
  Future<void> seek(Duration position) async {
    seeks.add(position);
    _state = _state.copyWith(position: position, completed: false);
  }

  @override
  Future<void> setNext(Media? media) async {
    setNextCalls.add(media);
    if (media != null && failingSetNextUris.contains(media.uri)) {
      throw StateError('setNext failed for ${media.uri}');
    }
    _armedMedia = media;
  }

  @override
  bool get disposed => _disposed;

  @override
  Future<void> dispose({bool preserveDisplayMode = false}) async {
    _disposed = true;
  }

  // Inert surface below — never exercised by the music engine.
  @override
  Future<void> selectAudioTrack(AudioTrack track) async {}

  @override
  Future<void> selectSubtitleTrack(SubtitleTrack track) async {}

  @override
  Future<void> selectSecondarySubtitleTrack(SubtitleTrack track) async {}

  @override
  bool get supportsSecondarySubtitles => false;

  @override
  bool get attachesExternalSubtitlesAtOpen => true;

  @override
  bool get detectsFpsAfterRender => false;

  @override
  bool get needsDecoderRefreshAfterDisplaySwitch => false;

  @override
  bool get providesNativeStats => false;

  @override
  Future<void> addSubtitleTrack({required String uri, String? title, String? language, bool select = false}) async {}

  @override
  Future<void> setVolume(double volume) async => volumes.add(volume);

  @override
  Future<void> setRate(double rate) async {}

  @override
  Future<void> setAudioDevice(AudioDevice device) async {}

  @override
  Future<void> setProperty(String name, String value) async {}

  @override
  Future<String?> getProperty(String name) async => null;

  @override
  Future<void> setLogLevel(String level) async {}

  @override
  Future<void> command(List<String> args) async {}

  @override
  Future<void> setDisplayCriteria(MediaDisplayCriteria? criteria, {int extraDelayMs = 0}) async {}

  @override
  Future<void> configureSubtitleFonts() async {}

  @override
  Future<void> setAudioPassthrough(bool enabled) async {}

  @override
  Future<void> setAudioNormalization(bool enabled) async {}

  @override
  Future<void> setAudioDownmix({required bool enabled, required int centerBoostDb, required bool normalize}) async {}

  @override
  Future<bool> setVisible(bool visible, {bool restoreOnWindowVisible = false}) async => true;

  @override
  Future<void> updateFrame() async {}

  @override
  Future<bool> setVideoFrameRate(
    double fps,
    int durationMs, {
    int extraDelayMs = 0,
    int videoWidth = 0,
    int videoHeight = 0,
  }) async => false;

  @override
  Future<void> clearVideoFrameRate() async {}

  @override
  Future<void> setSubtitleStyle({
    required double fontSize,
    required String textColor,
    required double borderSize,
    required String borderColor,
    required String bgColor,
    required int bgOpacity,
    int subtitlePosition = 100,
    bool bold = false,
    bool italic = false,
  }) async {}

  @override
  Future<void> setBoxFitMode(int mode) async {}

  @override
  Future<void> setVideoZoom(double scale) async {}

  @override
  Future<Map<String, dynamic>> getStats() async => {};

  @override
  Future<String> runtimePlayerType() async => 'fake';

  @override
  Future<bool> requestAudioFocus() async => true;

  @override
  Future<void> abandonAudioFocus() async {}
}

class RecordedReport {
  final String state;
  final String itemId;
  final Duration position;

  const RecordedReport(this.state, this.itemId, this.position);

  @override
  String toString() => '$state($itemId @ ${position.inSeconds}s)';
}

/// Records the progress-report surface; everything else is unimplemented
/// (the engine and tracker never touch it in these tests).
class FakeMediaServerClient extends Fake implements MediaServerClient {
  final List<RecordedReport> reports = [];
  final List<String> markedWatched = [];

  Iterable<RecordedReport> reportsFor(String state) => reports.where((r) => r.state == state);

  @override
  ServerId get serverId => ServerId('srv');

  @override
  double get watchedThreshold => 0.9;

  @override
  bool get marksWatchedOnPlaybackStopped => false;

  @override
  Future<void> markWatched(MediaItem item) async {
    markedWatched.add(item.id);
  }

  @override
  Future<void> reportPlaybackStarted({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? playMethod,
    String? liveStreamId,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) async {
    reports.add(RecordedReport('started', itemId, position));
  }

  @override
  Future<void> reportPlaybackProgress({
    required String itemId,
    required Duration position,
    required Duration duration,
    bool isPaused = false,
    String? playSessionId,
    String? playMethod,
    String? liveStreamId,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) async {
    reports.add(RecordedReport(isPaused ? 'paused' : 'progress', itemId, position));
  }

  @override
  Future<void> reportPlaybackStopped({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? liveStreamId,
    String? mediaSourceId,
    PlaybackReportMetadata report = const PlaybackReportMetadata.live(),
  }) async {
    reports.add(RecordedReport('stopped', itemId, position));
  }
}

class FakeMusicSourceResolver implements MusicSourceResolver {
  FakeMusicSourceResolver({this.client});

  final MediaServerClient? client;
  final Set<String> failingIds = {};
  final Map<String, int> resolveCounts = {};

  /// Per-track URL overrides (e.g. content:// shapes for offline tracks).
  final Map<String, String> urlOverrides = {};

  @override
  Future<MusicSource> resolve(MediaItem track) async {
    resolveCounts[track.id] = (resolveCounts[track.id] ?? 0) + 1;
    if (failingIds.contains(track.id)) {
      throw StateError('resolve failed for ${track.id}');
    }
    return MusicSource(
      url: urlOverrides[track.id] ?? _urlFor(track),
      playSessionId: 'ps-${track.id}',
      playMethod: 'DirectPlay',
      reportingClient: client,
    );
  }
}

/// Keeps the OS media session out of the tests: overrides every platform
/// touchpoint and feeds control events from a local controller.
class FakeMediaControlsManager extends MediaControlsManager {
  final eventsCtrl = StreamController<MediaControlEvent>.broadcast(sync: true);
  final List<String> metadataTitles = [];
  bool cleared = false;

  void closeControllers() {
    eventsCtrl.close();
  }

  @override
  Stream<MediaControlEvent> get controlEvents => eventsCtrl.stream;

  @override
  Future<void> updateMetadata({required MediaItem metadata, MediaServerClient? client, Duration? duration}) async {
    metadataTitles.add(metadata.title ?? '');
  }

  @override
  Future<void> updatePlaybackState({
    required bool isPlaying,
    required Duration position,
    required double speed,
    bool force = false,
  }) async {}

  final List<({bool canGoNext, bool canStop, bool canSkip, bool canSetSpeed})> controlSyncs = [];

  @override
  Future<void> setControlsEnabled({
    bool canGoNext = false,
    bool canGoPrevious = false,
    bool canSeek = false,
    bool canStop = false,
    bool canSkip = false,
    bool canSetSpeed = false,
  }) async {
    controlSyncs.add((canGoNext: canGoNext, canStop: canStop, canSkip: canSkip, canSetSpeed: canSetSpeed));
  }

  @override
  Future<void> clear() async {
    cleared = true;
  }
}

class _GatedVolumeWriter {
  final writes = <double>[];
  final gates = <Completer<void>>[];
  final _writeWaiters = <int, Completer<void>>{};
  var inFlight = 0;
  var maxInFlight = 0;

  Future<void> write(double volume) {
    writes.add(volume);
    inFlight++;
    if (inFlight > maxInFlight) maxInFlight = inFlight;

    final gate = Completer<void>();
    gates.add(gate);
    _writeWaiters.remove(writes.length)?.complete();
    return gate.future.whenComplete(() => inFlight--);
  }

  Future<void> waitForWrites(int count) {
    if (writes.length >= count) return Future<void>.value();
    return (_writeWaiters[count] ??= Completer<void>()).future;
  }
}

class _Harness {
  _Harness._(this.service, this.resolver, this.client, this.controls, this.players);

  final MusicPlaybackServiceImpl service;
  final FakeMusicSourceResolver resolver;
  final FakeMediaServerClient client;
  final FakeMediaControlsManager controls;
  final List<FakePlayer> players;

  /// Seeded into every created FakePlayer — lets a test configure arm
  /// failures before the first player exists.
  final Set<String> failingSetNextUris = {};

  FakePlayer get player => players.last;

  factory _Harness.create({Future<void> Function(double)? volumePersistenceWriter}) {
    final client = FakeMediaServerClient();
    final resolver = FakeMusicSourceResolver(client: client);
    final controls = FakeMediaControlsManager();
    final players = <FakePlayer>[];
    late final _Harness harness;
    final service = MusicPlaybackServiceImpl(
      serverManager: MultiServerManager(),
      resolver: resolver,
      audioPlayerFactory: () {
        final player = FakePlayer();
        player.failingSetNextUris.addAll(harness.failingSetNextUris);
        players.add(player);
        return player;
      },
      mediaControlsFactory: () => controls,
      // Collapse the boundary-pulse confirmation window so completed-driven
      // paths resolve within pumpEventQueue.
      completedConfirmDelay: Duration.zero,
      volumePersistenceWriter: volumePersistenceWriter,
    );
    harness = _Harness._(service, resolver, client, controls, players);
    return harness;
  }

  Future<void> playTracks(List<MediaItem> tracks, {MediaItem? startTrack, bool shuffle = false}) async {
    await service.playFromList(
      tracks: tracks,
      startTrack: startTrack,
      playContext: const MusicPlayContext(title: 'Test', kind: MusicPlayContextKind.album),
      shuffle: shuffle,
    );
    await pumpEventQueue();
  }
}

void main() {
  final t1 = _track('t1');
  final t2 = _track('t2');
  final t3 = _track('t3');

  late _Harness h;
  late Future<void> Function(double) persistenceWriter;

  setUp(() {
    persistenceWriter = (_) async {};
    h = _Harness.create(volumePersistenceWriter: (volume) => persistenceWriter(volume));
  });

  tearDown(() {
    h.service.dispose();
    for (final player in h.players) {
      player.closeControllers();
    }
    h.controls.closeControllers();
  });

  test('volume updates notify only the dedicated volume listenable', () async {
    await h.playTracks([t1]);
    var serviceNotifications = 0;
    var volumeNotifications = 0;
    h.service.addListener(() => serviceNotifications++);
    h.service.volumeListenable.addListener(() => volumeNotifications++);

    await h.service.setVolume(42, persist: false);

    expect(h.service.volume, 42);
    expect(h.player.volumes, [42]);
    expect(volumeNotifications, 1);
    expect(serviceNotifications, 0);
  });

  test('volume persistence keeps one write in flight and coalesces a burst to the latest value', () async {
    final writer = _GatedVolumeWriter();
    persistenceWriter = writer.write;
    var settled = 0;

    final callers = [
      h.service.setVolume(10).whenComplete(() => settled++),
      h.service.setVolume(20).whenComplete(() => settled++),
      h.service.setVolume(30).whenComplete(() => settled++),
    ];

    await writer.waitForWrites(1);
    expect(writer.writes, [10]);
    expect(writer.inFlight, 1);
    expect(writer.maxInFlight, 1);
    expect(settled, 0);

    writer.gates[0].complete();
    await writer.waitForWrites(2);
    expect(writer.writes, [10, 30]);
    expect(writer.inFlight, 1);
    expect(writer.maxInFlight, 1);
    expect(settled, 0);

    writer.gates[1].complete();
    await Future.wait(callers);
    expect(writer.inFlight, 0);
    expect(settled, 3);
  });

  test('volume persistence propagates a drain error and accepts a later write', () async {
    final writer = _GatedVolumeWriter();
    persistenceWriter = writer.write;
    final persistenceError = StateError('persistence failed');
    var firstSettled = false;
    var secondSettled = false;

    final first = h.service
        .setVolume(40)
        .then<void>(
          (_) => fail('first caller unexpectedly succeeded'),
          onError: (Object error, StackTrace stackTrace) {
            firstSettled = true;
            expect(error, same(persistenceError));
          },
        );
    final second = h.service
        .setVolume(50)
        .then<void>(
          (_) => fail('second caller unexpectedly succeeded'),
          onError: (Object error, StackTrace stackTrace) {
            secondSettled = true;
            expect(error, same(persistenceError));
          },
        );

    await writer.waitForWrites(1);
    writer.gates[0].completeError(persistenceError);
    await writer.waitForWrites(2);
    expect(writer.writes, [40, 50]);
    expect(firstSettled, isFalse);
    expect(secondSettled, isFalse);

    writer.gates[1].complete();
    await Future.wait([first, second]);
    expect(firstSettled, isTrue);
    expect(secondSettled, isTrue);
    expect(writer.inFlight, 0);

    final recovered = h.service.setVolume(60);
    await writer.waitForWrites(3);
    expect(writer.writes, [40, 50, 60]);
    writer.gates[2].complete();
    await recovered;
    expect(writer.inFlight, 0);
  });

  test('playFromList opens the first track and arms the second', () async {
    await h.playTracks([t1, t2, t3]);

    expect(h.player.openedUris, [_urlFor(t1)]);
    expect(h.service.status, MusicPlaybackStatus.playing);
    expect(h.service.currentTrack?.id, 't1');
    expect(h.service.currentIndex, 0);
    expect(h.player.armed?.uri, _urlFor(t2));

    // Track services bound: session started + OS metadata pushed.
    expect(h.client.reportsFor('started').map((r) => r.itemId), ['t1']);
    expect(h.controls.metadataTitles, ['Track t1']);
  });

  test('trackTransition advances the cursor, re-arms, and reports the previous track stopped at duration', () async {
    await h.playTracks([t1, t2, t3]);

    h.player.emitTransition(_urlFor(t2));
    await pumpEventQueue();

    expect(h.service.currentTrack?.id, 't2');
    expect(h.service.currentIndex, 1);
    expect(h.service.status, MusicPlaybackStatus.playing);
    expect(h.player.armed?.uri, _urlFor(t3));
    // No second open — the backend advanced gaplessly.
    expect(h.player.openedUris, [_urlFor(t1)]);

    final stopped = h.client.reportsFor('stopped').toList();
    expect(stopped, hasLength(1));
    expect(stopped.single.itemId, 't1');
    expect(stopped.single.position, _trackDuration);
    // Full playout crossed the watched threshold.
    expect(h.client.markedWatched, ['t1']);
    // New session started for the new track.
    expect(h.client.reportsFor('started').map((r) => r.itemId), ['t1', 't2']);
  });

  test('completed with nothing armed parks paused at the end and keeps the track', () async {
    await h.playTracks([t1, t2]);
    h.player.emitTransition(_urlFor(t2));
    await pumpEventQueue();
    expect(h.player.armed, isNull); // last track, repeat off

    h.player.emitCompleted();
    await pumpEventQueue();

    expect(h.service.status, MusicPlaybackStatus.paused);
    expect(h.service.currentTrack?.id, 't2');
    expect(h.service.queue, hasLength(2));
    final stopped = h.client.reportsFor('stopped').toList();
    expect(stopped.map((r) => r.itemId), ['t1', 't2']);
    expect(stopped.last.position, _trackDuration);
  });

  test('completed with a failed arm falls back to opening the next track', () async {
    h.resolver.failingIds.add('t2'); // arming t2 fails silently
    await h.playTracks([t1, t2]);
    expect(h.player.armed, isNull);

    h.resolver.failingIds.clear(); // the explicit open retries the resolve
    h.player.emitCompleted();
    await pumpEventQueue();

    expect(h.player.openedUris, [_urlFor(t1), _urlFor(t2)]);
    expect(h.service.currentTrack?.id, 't2');
    expect(h.service.status, MusicPlaybackStatus.playing);
  });

  test('player error surfaces and auto-skips to the next track', () async {
    await h.playTracks([t1, t2, t3]);
    final errors = <Object>[];
    final sub = h.service.errors.listen(errors.add);

    h.player.emitError('boom');
    await pumpEventQueue();

    expect(errors, hasLength(1));
    expect(h.service.currentTrack?.id, 't2');
    expect(h.player.openedUris, [_urlFor(t1), _urlFor(t2)]);
    expect(h.service.status, MusicPlaybackStatus.playing);
    await sub.cancel();
  });

  test('three consecutive failures stop the session with an error status', () async {
    await h.playTracks([t1, t2, t3]);
    h.resolver.failingIds.addAll(['t2', 't3']);
    final errors = <Object>[];
    final sub = h.service.errors.listen(errors.add);

    // Strike 1: player error on t1 -> skip to t2; strikes 2 and 3: t2/t3
    // resolves fail -> stop as error.
    h.player.emitError('boom');
    await pumpEventQueue();

    expect(errors, hasLength(3));
    expect(h.service.status, MusicPlaybackStatus.error);
    expect(h.service.currentTrack, isNull);
    expect(h.service.queue, isEmpty);
    expect(h.players.single.disposed, isTrue);
    await sub.cancel();
  });

  test('playback progress after an error resets the strike counter', () async {
    await h.playTracks([t1, t2, t3, _track('t4')]);

    h.player.emitError('boom'); // strike 1 -> skips to t2
    await pumpEventQueue();
    h.player.setPosition(const Duration(seconds: 5)); // t2 actually plays -> reset
    h.player.emitError('boom'); // strike 1 again (not 2) -> skips to t3
    await pumpEventQueue();
    h.player.setPosition(const Duration(seconds: 5));
    h.player.emitError('boom'); // still an isolated strike -> skips to t4
    await pumpEventQueue();

    // Without the reset this would have been the third strike (error stop).
    expect(h.service.status, MusicPlaybackStatus.playing);
    expect(h.service.currentTrack?.id, 't4');
  });

  test('claimVideo stops the session and disposes the audio core', () async {
    await h.playTracks([t1, t2]);
    final player = h.player;

    await PlaybackCoordinator.instance.claimVideo();

    expect(player.disposed, isTrue);
    expect(h.service.status, MusicPlaybackStatus.idle);
    expect(h.service.currentTrack, isNull);
    expect(h.service.queue, isEmpty);
    expect(h.controls.cleared, isTrue);
    // The played track's session was closed on the way out.
    expect(h.client.reportsFor('stopped').map((r) => r.itemId), ['t1']);

    // A new playback after the claim recreates the player.
    await h.playTracks([t3]);
    expect(h.players, hasLength(2));
    expect(h.player.openedUris, [_urlFor(t3)]);
    expect(h.service.status, MusicPlaybackStatus.playing);
  });

  test('repeat-one arms the same uri without a new resolve and repeats on transition', () async {
    await h.playTracks([t1, t2]);
    expect(h.player.armed?.uri, _urlFor(t2));

    h.service.setRepeatMode(MusicRepeatMode.one);
    await pumpEventQueue();
    expect(h.player.armed?.uri, _urlFor(t1));
    expect(h.resolver.resolveCounts['t1'], 1); // reused the current source

    h.player.emitTransition(_urlFor(t1));
    await pumpEventQueue();
    expect(h.service.currentTrack?.id, 't1');
    expect(h.service.currentIndex, 0);
    expect(h.player.armed?.uri, _urlFor(t1)); // re-armed for the next loop
    expect(h.resolver.resolveCounts['t1'], 1);
  });

  test('queue edits that keep the same next track do not re-arm or re-resolve', () async {
    await h.playTracks([t1, t2, t3]);
    final armCallsBefore = h.player.setNextCalls.length;

    h.service.addToEnd([_track('t4')]);
    await pumpEventQueue();

    expect(h.player.setNextCalls.length, armCallsBefore);
    expect(h.resolver.resolveCounts['t2'], 1);
  });

  test('previous restarts the track past 3s and steps back before that', () async {
    await h.playTracks([t1, t2]);
    h.player.emitTransition(_urlFor(t2));
    await pumpEventQueue();

    h.player.setPosition(const Duration(seconds: 10));
    await h.service.previous();
    expect(h.player.seeks, [Duration.zero]);
    expect(h.service.currentTrack?.id, 't2');

    h.player.setPosition(const Duration(seconds: 1));
    await h.service.previous();
    await pumpEventQueue();
    expect(h.service.currentTrack?.id, 't1');
    expect(h.player.openedUris, [_urlFor(t1), _urlFor(t1)]);
  });

  test('stop clears the session and notifies', () async {
    await h.playTracks([t1, t2]);
    var notified = 0;
    h.service.addListener(() => notified++);

    await h.service.stop();
    await pumpEventQueue();

    expect(notified, greaterThan(0));
    expect(h.service.status, MusicPlaybackStatus.idle);
    expect(h.service.currentTrack, isNull);
    expect(h.service.queue, isEmpty);
    expect(h.service.playContext, isNull);
    expect(h.player.disposed, isTrue);
    expect(h.controls.cleared, isTrue);
    expect(h.client.reportsFor('stopped').map((r) => r.itemId), ['t1']);
  });

  test('interruption pauses and resumes when the system says shouldResume', () async {
    await h.playTracks([t1, t2]);

    h.controls.eventsCtrl.add(const AudioInterruptionBeganEvent());
    await pumpEventQueue();
    expect(h.service.status, MusicPlaybackStatus.paused);
    expect(h.player.pauseCalls, 1);

    h.controls.eventsCtrl.add(const AudioInterruptionEndedEvent(shouldResume: true));
    await pumpEventQueue();
    expect(h.service.status, MusicPlaybackStatus.playing);
    expect(h.player.playCalls, 1);
  });

  test('OS stop command stops the session', () async {
    await h.playTracks([t1, t2]);
    final player = h.player;

    h.controls.eventsCtrl.add(const StopEvent());
    await pumpEventQueue();

    expect(h.service.status, MusicPlaybackStatus.idle);
    expect(h.service.currentTrack, isNull);
    expect(player.disposed, isTrue);
  });

  test('OS skip commands seek within the track, clamped to its bounds', () async {
    await h.playTracks([t1, t2]);
    h.player.setPosition(const Duration(seconds: 30));

    h.controls.eventsCtrl.add(const SkipForwardEvent(Duration(seconds: 15)));
    await pumpEventQueue();
    expect(h.player.seeks, [const Duration(seconds: 45)]);

    h.controls.eventsCtrl.add(const SkipBackwardEvent(null)); // default interval
    await pumpEventQueue();
    expect(h.player.seeks.last, const Duration(seconds: 30));

    h.player.setPosition(const Duration(seconds: 5));
    h.controls.eventsCtrl.add(const SkipBackwardEvent(Duration(seconds: 15)));
    await pumpEventQueue();
    expect(h.player.seeks.last, Duration.zero);
  });

  test('music advertises stop and skip but never a speed control', () async {
    await h.playTracks([t1, t2]);

    expect(h.controls.controlSyncs, isNotEmpty);
    final last = h.controls.controlSyncs.last;
    expect(last.canStop, isTrue);
    expect(last.canSkip, isTrue);
    expect(last.canSetSpeed, isFalse);
  });

  test('interruption without shouldResume stays paused', () async {
    await h.playTracks([t1]);

    h.controls.eventsCtrl.add(const AudioInterruptionBeganEvent());
    await pumpEventQueue();
    h.controls.eventsCtrl.add(const AudioInterruptionEndedEvent(shouldResume: false));
    await pumpEventQueue();

    expect(h.service.status, MusicPlaybackStatus.paused);
    expect(h.player.playCalls, 0);
  });

  test('removing the current track opens the next one', () async {
    await h.playTracks([t1, t2, t3]);

    h.service.removeAt(0);
    await pumpEventQueue();

    expect(h.service.currentTrack?.id, 't2');
    expect(h.service.queue.map((t) => t.id), ['t2', 't3']);
    expect(h.player.openedUris, [_urlFor(t1), _urlFor(t2)]);
    expect(h.client.reportsFor('stopped').map((r) => r.itemId), ['t1']);
  });

  group('gapless boundary races', () {
    // The sync stream controllers make the race drivable deterministically:
    // a transition emitted between the queue edit (which un-arms the entry
    // synchronously) and the event pump lands exactly like mpv rolling into
    // the armed entry as it is being cleared.

    test('transition raced by a reorder is adopted via the stale-arm memo', () async {
      await h.playTracks([t1, t2, t3]);
      expect(h.player.armed?.uri, _urlFor(t2));

      h.service.reorder(1, 2); // queue [t1, t3, t2] — un-arms t2
      h.player.emitTransition(_urlFor(t2)); // ...but mpv already rolled into it
      await pumpEventQueue();

      expect(h.service.currentTrack?.id, 't2');
      expect(h.service.currentIndex, 2);
      expect(h.service.status, MusicPlaybackStatus.playing);
      expect(h.player.openedUris, [_urlFor(t1)], reason: 'adopted gaplessly, no re-open');
      final stopped = h.client.reportsFor('stopped').toList();
      expect(stopped.single.itemId, 't1');
      expect(stopped.single.position, _trackDuration);
      expect(h.client.reportsFor('started').map((r) => r.itemId), ['t1', 't2']);
    });

    test('transition into a track removed at the boundary advances to the real next', () async {
      final t4 = _track('t4');
      await h.playTracks([t1, t2, t3, t4]);

      h.service.removeAt(1); // queue [t1, t3, t4] — un-arms t2
      h.player.emitTransition(_urlFor(t2)); // mpv rolled into the removed track
      await pumpEventQueue();

      expect(h.service.currentTrack?.id, 't3');
      expect(h.player.openedUris, [_urlFor(t1), _urlFor(t3)]);
      expect(h.player.armed?.uri, _urlFor(t4));
      expect(h.client.reportsFor('stopped').single.itemId, 't1');

      // A stale boundary completed pulse must not double-advance past t3.
      h.player.emitCompleted();
      await pumpEventQueue();
      expect(h.service.currentTrack?.id, 't3');
      expect(h.player.openedUris, [_urlFor(t1), _urlFor(t3)]);
    });

    test('removed-at-boundary with no next parks paused', () async {
      await h.playTracks([t1, t2]);

      h.service.removeAt(1); // queue [t1] — un-arms t2
      h.player.emitTransition(_urlFor(t2));
      await pumpEventQueue();

      expect(h.service.status, MusicPlaybackStatus.paused);
      expect(h.service.currentTrack?.id, 't1');
      expect(h.player.pauseCalls, 1, reason: 'the removed track is audibly playing — silence it');
      expect(h.player.openedUris, [_urlFor(t1)]);
    });

    test('stale transition after a manual advance is dropped', () async {
      await h.playTracks([t1, t2, t3]);

      h.service.removeAt(1); // memo t2
      await h.service.next(); // manual advance clears the memo
      await pumpEventQueue();
      expect(h.service.currentTrack?.id, 't3');

      h.player.emitTransition(_urlFor(t2));
      await pumpEventQueue();

      expect(h.service.currentTrack?.id, 't3');
      expect(h.service.currentIndex, 1);
      expect(h.player.openedUris, [_urlFor(t1), _urlFor(t3)]);
    });

    test('failed native arm falls back to an explicit open at completion', () async {
      h.failingSetNextUris.add(_urlFor(t2));
      await h.playTracks([t1, t2]);
      expect(h.player.armed, isNull);

      h.player.emitCompleted();
      await pumpEventQueue();

      expect(h.player.openedUris, [_urlFor(t1), _urlFor(t2)]);
      expect(h.service.currentTrack?.id, 't2');
      expect(h.service.status, MusicPlaybackStatus.playing);
    });

    test('transition matching is URL-shape agnostic (offline content://)', () async {
      h.resolver.urlOverrides['t2'] = 'content://downloads/t2';
      await h.playTracks([t1, t2]);
      expect(h.player.armed?.uri, 'content://downloads/t2');

      h.player.emitTransition('content://downloads/t2');
      await pumpEventQueue();

      expect(h.service.currentTrack?.id, 't2');
      expect(h.service.status, MusicPlaybackStatus.playing);
    });
  });

  test('timed sleep timer exposes its armed duration for the preset menu', () async {
    await h.playTracks([t1]);

    h.service.setSleepTimer(const Duration(minutes: 30));
    expect(h.service.sleepTimerActive, isTrue);
    expect(h.service.sleepTimerDuration, const Duration(minutes: 30));
    expect(h.service.sleepTimerEndOfTrack, isFalse);

    h.service.setSleepTimer(null, endOfTrack: true);
    expect(h.service.sleepTimerDuration, isNull);
    expect(h.service.sleepTimerActive, isTrue);

    h.service.setSleepTimer(null);
    expect(h.service.sleepTimerActive, isFalse);
    expect(h.service.sleepTimerDuration, isNull);
  });

  test('end-of-track sleep timer suppresses arming and pauses at completion', () async {
    await h.playTracks([t1, t2]);
    expect(h.player.armed?.uri, _urlFor(t2));

    h.service.setSleepTimer(null, endOfTrack: true);
    await pumpEventQueue();
    expect(h.service.sleepTimerActive, isTrue);
    expect(h.player.armed, isNull);

    h.player.emitCompleted();
    await pumpEventQueue();

    expect(h.service.status, MusicPlaybackStatus.paused);
    expect(h.service.currentTrack?.id, 't1');
    expect(h.service.sleepTimerActive, isFalse);
  });
}

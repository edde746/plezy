import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable, visibleForTesting;
import 'package:flutter/widgets.dart';
import 'package:os_media_controls/os_media_controls.dart';

import '../../database/app_database.dart';
import '../../media/ids.dart';
import '../../media/lyrics.dart';
import '../../media/media_item.dart';
import '../../media/media_server_client.dart';
import '../../mpv/models.dart';
import '../../mpv/player/player.dart';
import '../../utils/app_logger.dart';
import '../../utils/notification_permission.dart';
import '../../utils/platform_detector.dart';
import '../media_controls_manager.dart';
import '../multi_server_manager.dart';
import '../offline_watch_sync_service.dart';
import '../playback_coordinator.dart';
import '../playback_progress_tracker.dart';
import '../settings_service.dart';
import 'music_playback_service.dart';
import 'music_queue_controller.dart';
import 'music_source_resolver.dart';

/// A gapless-armed next track: what [Player.setNext] was fed, so the
/// trackTransition event can be mapped back to a queue entry and its
/// already-resolved source reused without a second server round-trip.
class _ArmedTrack {
  final MediaItem track;
  final MusicSource source;

  const _ArmedTrack({required this.track, required this.source});
}

/// Real music playback engine: owns the audio [Player], the queue
/// (via [MusicQueueController]), gapless arming, per-track server progress
/// reporting, and the OS media session.
///
/// ### Advancement paths
/// * **Gapless (normal):** after a track starts, the next queue entry is
///   resolved and armed via [Player.setNext]. When the backend auto-advances
///   it emits `trackTransition(uri)` — treated as the authoritative advance:
///   the finished track's tracker reports `stopped` at its full duration,
///   the cursor moves to the armed entry, services rebind, and the new next
///   is armed.
/// * **Completed fallback:** `completed` with nothing armed means either the
///   queue truly ended (repeat off, last track) — the session parks
///   `paused` at the end, keeping [currentTrack] so the mini-player stays —
///   or arming failed, in which case the next track is opened explicitly.
/// * **Manual:** next/previous/jumpTo/removeAt-current finalize the current
///   tracker at its *current* position and open the target directly.
///
/// ### Errors
/// Player/resolver failures surface on [errors] (for a snackbar) and
/// auto-skip to the next track; three consecutive failures without playback
/// progress stop the session with [MusicPlaybackStatus.error].
class MusicPlaybackServiceImpl extends MusicPlaybackService with WidgetsBindingObserver {
  MusicPlaybackServiceImpl({
    required MultiServerManager serverManager,
    AppDatabase? database,
    this._offlineWatchService,
    MusicSourceResolver? resolver,
    this._audioPlayerFactory = Player.audio,
    this._mediaControlsFactory = MediaControlsManager.new,
    this._completedConfirmDelay = const Duration(milliseconds: 400),
    PlaybackCoordinator? coordinator,
    @visibleForTesting Future<void> Function(double)? volumePersistenceWriter,
  }) : assert(resolver != null || database != null, 'database is required to build the default resolver'),
       _serverManager = serverManager,
       _resolver = resolver ?? ServerMusicSourceResolver(serverManager: serverManager, database: database!),
       _coordinator = coordinator ?? PlaybackCoordinator.instance,
       _volumePersistenceWriter = volumePersistenceWriter ?? _writePersistedVolume {
    _coordinator.registerMusicSession(stopAndDispose: _stopForVideoClaim);
    // tvOS has no background-audio session in v1 — pause on backgrounding so
    // audio doesn't play over other apps / the home screen. Other platforms
    // keep playing under their OS media session.
    if (PlatformDetector.isAppleTV()) {
      _observesLifecycle = true;
      WidgetsBinding.instance.addObserver(this);
    }
  }

  static const _previousRestartThreshold = Duration(seconds: 3);
  static const _maxConsecutiveFailures = 3;

  /// How long a completed (eof-reached) signal must stay uncontradicted
  /// before it is treated as a genuine queue end — long enough for the
  /// boundary pulse's own eof-reached=false / transition to arrive, short
  /// enough to be imperceptible at a real queue end (see [_onCompleted]).
  /// Injectable so tests can collapse the confirmation window.
  final Duration _completedConfirmDelay;

  final MultiServerManager _serverManager;
  final OfflineWatchSyncService? _offlineWatchService;
  final MusicSourceResolver _resolver;
  final Player Function() _audioPlayerFactory;
  final MediaControlsManager Function() _mediaControlsFactory;
  final PlaybackCoordinator _coordinator;
  final Future<void> Function(double) _volumePersistenceWriter;

  final MusicQueueController _queue = MusicQueueController();

  /// Persisted music volume (0–100), applied to every audio player instance
  /// (the core is recreated after video claims playback). Falls back to full
  /// volume when settings aren't bootstrapped (tests).
  double _volume = SettingsService.instanceOrNull?.read(SettingsService.musicVolume) ?? 100.0;
  late final ValueNotifier<double> _volumeNotifier = ValueNotifier<double>(_volume);
  // One settings write stays in flight while rapid updates replace the single
  // pending slot. The drain intentionally survives service disposal.
  double? _pendingVolumeWrite;
  Future<void>? _volumeWriteDrain;

  Player? _player;
  final List<StreamSubscription<Object?>> _playerSubs = [];

  MediaControlsManager? _mediaControls;
  StreamSubscription<MediaControlEvent>? _controlEventsSub;

  MusicPlaybackStatus _status = MusicPlaybackStatus.idle;
  MediaItem? _currentTrack;
  MusicSource? _currentSource;
  MusicPlayContext? _playContext;
  PlaybackProgressTracker? _tracker;
  _ArmedTrack? _armed;

  /// The arm most recently cleared for a re-arm (generation-gated): a queue
  /// edit can un-arm an entry in the same instant mpv rolls into it, so the
  /// resulting transition must stay adoptable — dropping it leaves the
  /// service tracking the finished track for the entire next file.
  _ArmedTrack? _staleArm;
  int _staleArmGeneration = -1;
  Timer? _completedConfirmTimer;

  /// Bumped on every open/advance/stop so stale async continuations
  /// (resolves, opens, arms) drop out instead of acting on the new state.
  int _generation = 0;

  int _consecutiveFailures = 0;
  bool _resumeAfterInterruption = false;
  bool _disposed = false;
  bool _observesLifecycle = false;

  Timer? _sleepTimer;
  DateTime? _sleepTimerEndsAt;
  Duration? _sleepTimerDuration;
  bool _sleepTimerEndOfTrack = false;

  final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();
  final StreamController<Object> _errorsController = StreamController<Object>.broadcast();

  // ---------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------

  @override
  bool get isAvailable => true;

  @override
  MediaItem? get currentTrack => _currentTrack;

  @override
  MusicPlaybackStatus get status => _status;

  @override
  Duration? get duration {
    if (_currentTrack == null) return null;
    final playerDuration = _player?.state.duration ?? Duration.zero;
    if (playerDuration > Duration.zero) return playerDuration;
    final ms = _currentTrack?.durationMs;
    return ms != null ? Duration(milliseconds: ms) : null;
  }

  @override
  Duration get position => _player?.currentPosition ?? Duration.zero;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  List<MediaItem> get queue => _queue.queue;

  @override
  int get currentIndex => _queue.cursor;

  @override
  MusicPlayContext? get playContext => _playContext;

  @override
  bool get shuffled => _queue.shuffled;

  @override
  MusicRepeatMode get repeatMode => _queue.repeatMode;

  @override
  Stream<Object> get errors => _errorsController.stream;

  @override
  bool get sleepTimerActive => _sleepTimer != null || _sleepTimerEndOfTrack;

  @override
  DateTime? get sleepTimerEndsAt => _sleepTimerEndsAt;

  @override
  Duration? get sleepTimerDuration => _sleepTimerDuration;

  @override
  bool get sleepTimerEndOfTrack => _sleepTimerEndOfTrack;

  // ---------------------------------------------------------------------
  // Session start
  // ---------------------------------------------------------------------

  @override
  Future<void> playFromList({
    required List<MediaItem> tracks,
    MediaItem? startTrack,
    required MusicPlayContext playContext,
    bool shuffle = false,
  }) {
    return _startQueue(tracks: tracks, startTrack: startTrack, playContext: playContext, shuffle: shuffle);
  }

  @override
  Future<void> playInstantMix(MediaItem seed) async {
    final client = _clientFor(seed);
    if (client == null) {
      _errorsController.add(StateError('No server available for instant mix'));
      return;
    }
    List<MediaItem> tracks;
    try {
      tracks = await client.fetchInstantMix(seed.id);
    } catch (e, st) {
      appLogger.w('Instant mix fetch failed for ${seed.id}', error: e, stackTrace: st);
      _errorsController.add(e);
      return;
    }
    if (_disposed || tracks.isEmpty) return;
    await _startQueue(
      tracks: tracks,
      playContext: MusicPlayContext(title: seed.displayTitle, kind: MusicPlayContextKind.mix),
    );
  }

  Future<void> _startQueue({
    required List<MediaItem> tracks,
    MediaItem? startTrack,
    required MusicPlayContext playContext,
    bool shuffle = false,
    bool autoplay = true,
  }) async {
    if (tracks.isEmpty || _disposed) return;
    // Android 13+: the background playback notification needs
    // POST_NOTIFICATIONS. Fire-and-forget — playback and the foreground
    // service run regardless; a denial only hides the notification.
    unawaited(ensureNotificationPermission());
    final generation = ++_generation;
    _finalizeCurrentTrack();
    var startIndex = 0;
    if (startTrack != null) {
      startIndex = tracks.indexWhere((t) => t.globalKey == startTrack.globalKey);
      if (startIndex < 0) startIndex = 0;
    }
    _queue.load(tracks, startIndex: startIndex, shuffle: shuffle);
    _playContext = playContext;
    _consecutiveFailures = 0;
    await _openCurrent(generation, play: autoplay);
  }

  // ---------------------------------------------------------------------
  // Opening / advancing
  // ---------------------------------------------------------------------

  /// Resolve and open the queue's current track. All failure handling funnels
  /// through [_handlePlaybackFailure].
  Future<void> _openCurrent(int generation, {bool play = true}) async {
    final track = _queue.current;
    if (track == null) return;
    _currentTrack = track;
    _currentSource = null;
    _armed = null;
    _staleArm = null;
    _setStatus(MusicPlaybackStatus.loading, forceNotify: true);

    await _coordinator.claimMusic();
    if (generation != _generation) return;
    final player = _ensurePlayer();
    _ensureMediaControls();
    // Re-asserted per open (cheap, idempotent): the native side drops the
    // background-mode opt-in when the user swipes the task away, so a
    // session that survives task removal heals itself here.
    unawaited(_mediaControls?.setBackgroundMode(true));

    // Clear any native arm left over from the previous item before the open
    // replaces it, so a stray transition can't fire mid-switch.
    try {
      await player.setNext(null);
    } catch (e) {
      appLogger.d('setNext(null) before open failed', error: e);
    }

    MusicSource source;
    try {
      source = await _resolver.resolve(track);
    } catch (e, st) {
      appLogger.w('Music source resolve failed for ${track.id}', error: e, stackTrace: st);
      if (generation == _generation) _handlePlaybackFailure(e);
      return;
    }
    if (generation != _generation || _player != player) return;
    _currentSource = source;

    // Claim audio focus before audio starts so other media apps pause (mpv
    // has no built-in focus handling; harmless no-op off Android). Result is
    // ignored — mirrors the video screen, playback proceeds either way.
    try {
      await player.requestAudioFocus();
    } catch (e) {
      appLogger.d('Audio focus request failed', error: e);
    }
    if (generation != _generation || _player != player) return;

    try {
      await player.open(Media(source.url, headers: source.headers), play: play);
    } catch (e, st) {
      appLogger.w('Music open failed for ${track.id}', error: e, stackTrace: st);
      if (generation == _generation) _handlePlaybackFailure(e);
      return;
    }
    if (generation != _generation || _player != player) return;

    _setStatus(play ? MusicPlaybackStatus.playing : MusicPlaybackStatus.paused);
    _bindTrackServices(track, source);
    unawaited(_armNext(generation));
  }

  /// Manual advance: finalize the current tracker at its current position and
  /// open the queue entry at [cursor].
  Future<void> _advanceTo(int cursor, {bool play = true}) async {
    final generation = ++_generation;
    _finalizeCurrentTrack();
    _queue.jumpTo(cursor);
    await _openCurrent(generation, play: play);
  }

  /// Arm (or clear) what the backend should auto-advance into. Skips the
  /// resolve round-trip when the desired target is already armed; repeat-one
  /// reuses the current track's resolved source.
  Future<void> _armNext(int generation) async {
    final player = _player;
    if (player == null || generation != _generation) return;

    final targetCursor = _sleepTimerEndOfTrack ? null : _queue.nextIndex();
    final target = targetCursor == null ? null : _queue.trackAt(targetCursor);

    if (target == null) {
      if (_armed == null) return;
      appLogger.d('Music: clearing arm (queue end / end-of-track sleep)');
      _rememberStaleArm();
      await _trySetNext(player, null);
      return;
    }
    if (_armed?.track.globalKey == target.globalKey) return;

    _rememberStaleArm();
    await _trySetNext(player, null);
    if (generation != _generation || _player != player) return;

    MusicSource source;
    if (targetCursor == _queue.cursor && _currentSource != null) {
      // Repeat-one: the same file plays again — reuse the resolved source.
      source = _currentSource!;
    } else {
      try {
        source = await _resolver.resolve(target);
      } catch (e, st) {
        // Fail soft: with nothing armed, the completed event falls back to
        // an explicit open of the next track (which retries the resolve).
        appLogger.w('Gapless arm resolve failed for ${target.id}', error: e, stackTrace: st);
        return;
      }
    }
    if (generation != _generation || _player != player) return;
    _armed = _ArmedTrack(track: target, source: source);
    appLogger.d('Music: arming cursor $targetCursor "${target.title}"');
    final ok = await _trySetNext(player, Media(source.url, headers: source.headers));
    if (!ok && generation == _generation && _player == player) {
      // Nothing is armed natively; clear the record so the confirmed
      // completed fallback can advance explicitly instead of waiting for a
      // transition that can never come.
      _armed = null;
    }
  }

  /// Un-arm bookkeeping: [_armed] is cleared but remembered so
  /// [_onTrackTransition] can adopt a transition that raced the clear.
  void _rememberStaleArm() {
    if (_armed != null) {
      _staleArm = _armed;
      _staleArmGeneration = _generation;
    }
    _armed = null;
  }

  Future<bool> _trySetNext(Player player, Media? media) async {
    try {
      await player.setNext(media);
      return true;
    } catch (e) {
      appLogger.w('setNext failed', error: e);
      return false;
    }
  }

  /// Re-arm only when queue/mode changes altered what plays next — queue
  /// edits that keep the same next track cost no server round-trip.
  void _rearmIfNeeded() {
    if (_player == null || _currentTrack == null) return;
    final targetCursor = _sleepTimerEndOfTrack ? null : _queue.nextIndex();
    final target = targetCursor == null ? null : _queue.trackAt(targetCursor);
    if (target == null && _armed == null) return;
    if (target != null && _armed?.track.globalKey == target.globalKey) return;
    unawaited(_armNext(_generation));
  }

  // ---------------------------------------------------------------------
  // Player events
  // ---------------------------------------------------------------------

  Player _ensurePlayer() {
    final existing = _player;
    if (existing != null && !existing.disposed) return existing;
    final player = _audioPlayerFactory();
    _player = player;
    _wirePlayerStreams(player);
    if (_volume != 100.0) unawaited(player.setVolume(_volume));
    return player;
  }

  void _wirePlayerStreams(Player player) {
    for (final sub in _playerSubs) {
      sub.cancel();
    }
    _playerSubs
      ..clear()
      ..add(player.streams.position.listen(_onPosition))
      ..add(player.streams.playing.listen(_onPlayingChanged))
      ..add(player.streams.trackTransition.listen(_onTrackTransition))
      ..add(player.streams.completed.listen(_onCompleted))
      ..add(player.streams.error.listen(_onPlayerError));
  }

  void _onPosition(Duration position) {
    _positionController.add(position);
    // Real playback progress proves the pipeline recovered — reset the
    // consecutive-failure strike counter.
    if (_consecutiveFailures != 0 && position > Duration.zero && _status == MusicPlaybackStatus.playing) {
      _consecutiveFailures = 0;
    }
    final player = _player;
    if (player != null) {
      _mediaControls?.updatePlaybackState(isPlaying: player.state.isActive, position: position, speed: 1.0);
    }
  }

  void _onPlayingChanged(bool isPlaying) {
    if (_status == MusicPlaybackStatus.playing || _status == MusicPlaybackStatus.paused) {
      _setStatus(isPlaying ? MusicPlaybackStatus.playing : MusicPlaybackStatus.paused);
      unawaited(_tracker?.sendProgress(isPlaying ? 'playing' : 'paused'));
    }
    final player = _player;
    if (player != null) {
      _mediaControls?.updatePlaybackState(
        isPlaying: player.state.isActive,
        position: player.currentPosition,
        speed: 1.0,
        force: true,
      );
    }
  }

  /// The backend auto-advanced into the pre-armed item: authoritative
  /// track change.
  void _onTrackTransition(String uri) {
    var armed = _armed;
    if ((armed == null || armed.source.url != uri) &&
        _staleArm != null &&
        _staleArmGeneration == _generation &&
        _staleArm!.source.url == uri) {
      // mpv rolled into the entry in the same instant a queue edit un-armed
      // it — the transition is still authoritative for what is audibly
      // playing.
      armed = _staleArm;
    }
    _staleArm = null;
    if (armed == null || armed.source.url != uri) {
      appLogger.w('Unexpected track transition to $uri (armed: ${armed?.source.url})');
      return;
    }
    final adopted = armed;
    _armed = null;
    final generation = ++_generation;

    // The finished track played out fully — report stopped at its duration.
    final finishedMs = _currentTrack?.durationMs;
    _finalizeCurrentTrack(positionOverride: finishedMs != null ? Duration(milliseconds: finishedMs) : null);

    // Move the cursor to the armed entry: the expected natural-next when it
    // still matches, otherwise wherever the armed track now sits.
    final expected = _queue.nextIndex();
    if (expected != null && _queue.trackAt(expected)?.globalKey == adopted.track.globalKey) {
      _queue.jumpTo(expected);
    } else {
      final index = _queue.queue.indexWhere((t) => t.globalKey == adopted.track.globalKey);
      if (index < 0) {
        // The track mpv advanced into was removed from the queue at the
        // boundary: don't adopt it — play what the queue says comes next,
        // or park when nothing does.
        appLogger.d('Music: transition into removed track "${adopted.track.title}" — advancing past it');
        final nextCursor = _queue.nextIndex();
        if (nextCursor != null) {
          unawaited(_advanceTo(nextCursor));
        } else {
          unawaited(_player?.pause());
          _parkAtEnd();
        }
        return;
      }
      _queue.jumpTo(index);
    }

    _currentTrack = _queue.current ?? adopted.track;
    _currentSource = adopted.source;
    _consecutiveFailures = 0;
    appLogger.d('Music: transition received "${adopted.track.title}" → cursor ${_queue.cursor}');
    _setStatus(MusicPlaybackStatus.playing, forceNotify: true);
    _bindTrackServices(_currentTrack!, adopted.source);
    unawaited(_armNext(generation));
  }

  /// Completed (eof-reached) is NOT a last-entry-only signal: mpv pulses it
  /// at every gapless boundary (the audio of the finished entry drains
  /// before the armed entry starts), and its delivery order against the
  /// trackTransition event is not guaranteed. A boundary pulse that lands
  /// after the transition already cleared [_armed] (re-arm still resolving)
  /// looks exactly like "queue advanced with nothing armed" — acting on it
  /// immediately double-advanced the queue (skipped a track, cut off the
  /// just-started file; live-captured on Android). So never act on the raw
  /// pulse: confirm it is stable first. A boundary pulse is followed by
  /// eof-reached=false / a transition within milliseconds (which resets
  /// `state.completed` and bumps [_generation]); at a genuine queue end,
  /// sleep-at-end-of-track, or failed arm it stays true, and the confirmed
  /// handler advances explicitly or parks.
  void _onCompleted(bool done) {
    if (!done || _currentTrack == null || _status == MusicPlaybackStatus.idle) return;
    appLogger.d('Music: completed received (armed=${_armed != null}, cursor ${_queue.cursor})');
    if (_armed != null) return; // The backend advances; trackTransition handles it.

    final generation = _generation;
    _completedConfirmTimer?.cancel();
    _completedConfirmTimer = Timer(_completedConfirmDelay, () {
      _completedConfirmTimer = null;
      if (_disposed || generation != _generation || _armed != null) return;
      if (_player?.state.completed != true) return; // stale boundary pulse
      appLogger.d('Music: completed confirmed (cursor ${_queue.cursor})');
      _handleQueueCompleted();
    });
  }

  /// Confirmed end of the current file with nothing armed: queue end,
  /// sleep-at-end-of-track, or a failed arm (fall back to an explicit open).
  void _handleQueueCompleted() {
    if (_sleepTimerEndOfTrack) {
      _sleepTimerEndOfTrack = false;
      _parkAtEnd();
      return;
    }

    final nextCursor = _queue.nextIndex();
    if (nextCursor != null) {
      unawaited(_advanceTo(nextCursor));
      return;
    }
    _parkAtEnd();
  }

  /// Queue played out: report the final track stopped at its duration and
  /// park paused at the end. [currentTrack] stays set so the mini-player
  /// remains; pressing play restarts the current track from the top.
  void _parkAtEnd() {
    _generation++;
    final finishedMs = _currentTrack?.durationMs;
    _finalizeCurrentTrack(positionOverride: finishedMs != null ? Duration(milliseconds: finishedMs) : null);
    _setStatus(MusicPlaybackStatus.paused, forceNotify: true);
    final player = _player;
    if (player != null) {
      _mediaControls?.updatePlaybackState(isPlaying: false, position: player.currentPosition, speed: 1.0, force: true);
    }
  }

  void _onPlayerError(PlayerError error) {
    if (_status == MusicPlaybackStatus.idle || _status == MusicPlaybackStatus.error) return;
    appLogger.w('Music player error: $error');
    _handlePlaybackFailure(error);
  }

  /// Shared recovery for resolve/open/player errors: surface, then skip to
  /// the next track; three consecutive strikes stop the session as failed.
  void _handlePlaybackFailure(Object error) {
    _errorsController.add(error);
    _consecutiveFailures++;
    if (_consecutiveFailures >= _maxConsecutiveFailures) {
      unawaited(_stopSession(endStatus: MusicPlaybackStatus.error));
      return;
    }
    final nextCursor = _queue.nextIndex(manual: true);
    if (nextCursor == null) {
      unawaited(_stopSession(endStatus: MusicPlaybackStatus.error));
      return;
    }
    unawaited(_advanceTo(nextCursor));
  }

  // ---------------------------------------------------------------------
  // Per-track services (progress reporting + OS media controls)
  // ---------------------------------------------------------------------

  /// (Re)bind the per-track progress tracker and media-session metadata —
  /// the music mirror of the video screen's `_wirePerItemPlaybackServices`.
  /// The previous track must already be finalized.
  void _bindTrackServices(MediaItem track, MusicSource source) {
    _tracker?.dispose();
    _tracker = null;
    final player = _player;
    if (player == null) return;

    final client = source.reportingClient;
    if (client != null) {
      _tracker = PlaybackProgressTracker(
        client: client,
        metadata: track,
        player: player,
        offlineWatchService: _offlineWatchService,
        // Local files keep reporting online but queue locally when the
        // server rejects the report — same policy as downloaded video.
        queueOnOnlineFailure: source.isOffline && _offlineWatchService != null,
        playMethod: source.playMethod ?? 'DirectPlay',
        playSessionId: source.playSessionId,
        mediaInfo: source.mediaInfo,
      )..startTracking();
    } else if (source.isOffline && _offlineWatchService != null) {
      _tracker = PlaybackProgressTracker(
        client: null,
        metadata: track,
        player: player,
        isOffline: true,
        offlineWatchService: _offlineWatchService,
      )..startTracking();
    }

    final controls = _mediaControls;
    if (controls != null) {
      unawaited(
        controls.updateMetadata(
          metadata: track,
          client: client ?? _clientFor(track),
          duration: track.durationMs != null ? Duration(milliseconds: track.durationMs!) : null,
        ),
      );
      _syncControlsAvailability();
    }
  }

  /// Stop tracking and fire the final `stopped` report for the current
  /// track (fire-and-forget; report sessions are per track so the next
  /// track's `started` can overlap safely).
  void _finalizeCurrentTrack({Duration? positionOverride}) {
    final tracker = _tracker;
    _tracker = null;
    if (tracker == null) return;
    tracker.stopTracking();
    unawaited(
      tracker.sendStoppedProgressOnce(positionOverride: positionOverride).catchError((Object e) {
        appLogger.d('Final music progress report failed', error: e);
      }),
    );
  }

  void _ensureMediaControls() {
    if (_mediaControls != null) return;
    final controls = _mediaControlsFactory();
    _mediaControls = controls;
    _controlEventsSub = controls.controlEvents.listen(_onControlEvent);
  }

  void _syncControlsAvailability() {
    unawaited(
      _mediaControls?.setControlsEnabled(
        canGoNext: _queue.nextIndex(manual: true) != null,
        // Previous always restarts the track even at queue head.
        canGoPrevious: true,
        canSeek: true,
        canStop: true,
        // In-track skips: Bluetooth/steering-wheel fast-forward and rewind
        // buttons map here on Android. (Never surfaced on iOS/macOS — see
        // MediaControlsManager.setControlsEnabled.)
        canSkip: true,
        // Music always plays at 1.0 — never advertise a speed control.
      ),
    );
  }

  void _onControlEvent(MediaControlEvent event) {
    if (_disposed || _currentTrack == null) return;
    if (event is PlayEvent) {
      unawaited(play());
    } else if (event is PauseEvent) {
      unawaited(pause());
    } else if (event is TogglePlayPauseEvent) {
      unawaited(togglePlayPause());
    } else if (event is NextTrackEvent) {
      unawaited(next());
    } else if (event is PreviousTrackEvent) {
      unawaited(previous());
    } else if (event is SeekEvent) {
      unawaited(seek(event.position));
    } else if (event is StopEvent) {
      unawaited(stop());
    } else if (event is SkipForwardEvent) {
      unawaited(_seekRelative(event.interval ?? _defaultSkipInterval));
    } else if (event is SkipBackwardEvent) {
      unawaited(_seekRelative(-(event.interval ?? _defaultSkipInterval)));
    } else if (event is AudioInterruptionBeganEvent || event is AudioRouteOldDeviceUnavailableEvent) {
      // Remember whether we were playing so interruption-end/route-return
      // can resume. Unlike video, music resumes even while backgrounded —
      // background audio is the product.
      _resumeAfterInterruption = _player?.state.isActive ?? false;
      unawaited(pause());
    } else if (event is AudioInterruptionEndedEvent) {
      if (event.shouldResume && _resumeAfterInterruption) {
        _resumeAfterInterruption = false;
        unawaited(play());
      } else {
        _resumeAfterInterruption = false;
      }
    } else if (event is AudioRouteNewDeviceAvailableEvent) {
      if (_resumeAfterInterruption) {
        _resumeAfterInterruption = false;
        unawaited(play());
      }
    }
    // SetSpeedEvent is deliberately unhandled: music always plays at 1.0 and
    // the control is not advertised — but Linux MPRIS exposes an always-
    // writable Rate property, so the event can still arrive. The periodic
    // playback-state update reasserts speed 1.0.
  }

  static const _defaultSkipInterval = Duration(seconds: 15);

  /// In-track relative seek for OS skip commands, clamped to the track.
  Future<void> _seekRelative(Duration delta) async {
    final player = _player;
    if (player == null) return;
    var target = player.currentPosition + delta;
    if (target < Duration.zero) target = Duration.zero;
    final max = duration;
    if (max != null && target > max) target = max;
    await player.seek(target);
  }

  // ---------------------------------------------------------------------
  // Transport
  // ---------------------------------------------------------------------

  @override
  Future<void> play() async {
    final player = _player;
    if (player == null || _currentTrack == null) return;
    if (player.state.completed) {
      // Parked at queue end: restart the current track.
      await player.seek(Duration.zero);
      final currentTrack = _currentTrack;
      final currentSource = _currentSource;
      if (currentTrack != null && currentSource != null) {
        _bindTrackServices(currentTrack, currentSource);
      }
      unawaited(_armNext(_generation));
    }
    await player.play();
    _setStatus(MusicPlaybackStatus.playing);
  }

  @override
  Future<void> pause() async {
    final player = _player;
    if (player == null) return;
    await player.pause();
    _setStatus(MusicPlaybackStatus.paused);
  }

  @override
  Future<void> togglePlayPause() {
    final player = _player;
    if (player == null) return Future.value();
    return player.state.isActive ? pause() : play();
  }

  /// Apple TV only (observer registered in the constructor): pause when the
  /// app leaves the foreground — tvOS background audio is not attempted in
  /// v1, so playback must not continue under the home screen.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      if (isPlaying) {
        appLogger.d('App backgrounded on Apple TV — pausing music playback');
        unawaited(pause());
      }
    }
  }

  @override
  Future<void> next() async {
    final nextCursor = _queue.nextIndex(manual: true);
    if (nextCursor == null) return;
    await _advanceTo(nextCursor);
  }

  @override
  Future<void> previous() async {
    final player = _player;
    if (player == null) return;
    if (player.currentPosition > _previousRestartThreshold) {
      await player.seek(Duration.zero);
      return;
    }
    final prevCursor = _queue.previousIndex();
    if (prevCursor == null) {
      await player.seek(Duration.zero);
      return;
    }
    await _advanceTo(prevCursor);
  }

  @override
  Future<void> seek(Duration position) async {
    await _player?.seek(position);
  }

  @override
  double get volume => _volume;
  @override
  ValueListenable<double> get volumeListenable => _volumeNotifier;

  @override
  Future<void> setVolume(double volume, {bool persist = true}) async {
    final clamped = volume.clamp(0.0, 100.0);
    Future<void>? playerUpdate;
    if (clamped != _volume) {
      _volume = clamped;
      _volumeNotifier.value = clamped;
      playerUpdate = _player?.setVolume(clamped);
    }

    final persistence = persist ? _persistVolume(clamped) : null;
    if (playerUpdate != null && persistence != null) {
      await Future.wait([playerUpdate, persistence]);
    } else {
      await playerUpdate;
      await persistence;
    }
  }

  static Future<void> _writePersistedVolume(double volume) async {
    final settings = SettingsService.instanceOrNull;
    if (settings != null) await settings.write(SettingsService.musicVolume, volume);
  }

  Future<void> _persistVolume(double volume) {
    _pendingVolumeWrite = volume;
    final activeDrain = _volumeWriteDrain;
    if (activeDrain != null) return activeDrain;

    final completer = Completer<void>();
    _volumeWriteDrain = completer.future;
    unawaited(_drainVolumeWrites(completer));
    return completer.future;
  }

  Future<void> _drainVolumeWrites(Completer<void> completer) async {
    Object? firstError;
    StackTrace? firstStackTrace;

    while (_pendingVolumeWrite != null) {
      final volume = _pendingVolumeWrite!;
      _pendingVolumeWrite = null;
      try {
        await _volumePersistenceWriter(volume);
      } catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }

    _volumeWriteDrain = null;
    if (firstError != null) {
      completer.completeError(firstError, firstStackTrace);
    } else {
      completer.complete();
    }
  }

  @override
  Future<void> jumpTo(int index) async {
    if (index < 0 || index >= _queue.length || index == _queue.cursor) return;
    await _advanceTo(index);
  }

  // ---------------------------------------------------------------------
  // Queue / mode edits
  // ---------------------------------------------------------------------

  @override
  void setRepeatMode(MusicRepeatMode mode) {
    if (_queue.repeatMode == mode) return;
    _queue.repeatMode = mode;
    _rearmIfNeeded();
    _syncControlsAvailability();
    notifyListeners();
  }

  @override
  void toggleShuffle() {
    if (_queue.isEmpty) return;
    _queue.toggleShuffle();
    _rearmIfNeeded();
    _syncControlsAvailability();
    notifyListeners();
  }

  @override
  void removeAt(int index) {
    if (index < 0 || index >= _queue.length) return;
    final wasCurrent = _queue.removeAt(index);
    if (wasCurrent) {
      if (_queue.isEmpty) {
        unawaited(stop());
        return;
      }
      // The cursor already points at what used to be next — open it.
      unawaited(_advanceTo(_queue.cursor));
      return;
    }
    _rearmIfNeeded();
    _syncControlsAvailability();
    notifyListeners();
  }

  @override
  void reorder(int from, int to) {
    if (from == to) return;
    _queue.move(from, to);
    _rearmIfNeeded();
    _syncControlsAvailability();
    notifyListeners();
  }

  @override
  void addNext(List<MediaItem> tracks) => _enqueue(tracks, next: true);

  @override
  void addToEnd(List<MediaItem> tracks) => _enqueue(tracks, next: false);

  /// Queue edits while idle start a session parked on the first added track
  /// (mini-player appears paused) instead of silently dropping the action
  /// or surprising the user with audio.
  void _enqueue(List<MediaItem> tracks, {required bool next}) {
    if (tracks.isEmpty) return;
    if (_queue.isEmpty || _currentTrack == null) {
      final first = tracks.first;
      unawaited(
        _startQueue(
          tracks: tracks,
          playContext: MusicPlayContext(
            title: first.albumTitle ?? first.title ?? '',
            kind: MusicPlayContextKind.tracks,
          ),
          autoplay: false,
        ),
      );
      return;
    }
    if (next) {
      _queue.addNext(tracks);
    } else {
      _queue.addToEnd(tracks);
    }
    _rearmIfNeeded();
    _syncControlsAvailability();
    notifyListeners();
  }

  @override
  void clearUpcoming() {
    if (_queue.isEmpty) return;
    _queue.clearUpcoming();
    _rearmIfNeeded();
    _syncControlsAvailability();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Sleep timer
  // ---------------------------------------------------------------------

  @override
  void setSleepTimer(Duration? duration, {bool endOfTrack = false}) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerEndsAt = null;
    _sleepTimerDuration = null;
    final hadEndOfTrack = _sleepTimerEndOfTrack;
    _sleepTimerEndOfTrack = endOfTrack;
    if (!endOfTrack && duration != null) {
      _sleepTimerEndsAt = DateTime.now().add(duration);
      _sleepTimerDuration = duration;
      _sleepTimer = Timer(duration, _onSleepTimerFired);
    }
    // End-of-track mode suppresses gapless arming (and leaving it restores
    // the arm), so the track genuinely completes instead of transitioning.
    if (hadEndOfTrack != _sleepTimerEndOfTrack) {
      unawaited(_armNext(_generation));
    }
    notifyListeners();
  }

  void _onSleepTimerFired() {
    _sleepTimer = null;
    _sleepTimerEndsAt = null;
    _sleepTimerDuration = null;
    unawaited(pause());
    notifyListeners();
  }

  void _cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerEndsAt = null;
    _sleepTimerDuration = null;
    _sleepTimerEndOfTrack = false;
  }

  // ---------------------------------------------------------------------
  // Stop / teardown
  // ---------------------------------------------------------------------

  @override
  Future<void> stop() => _stopSession(endStatus: MusicPlaybackStatus.idle);

  /// The coordinator's video claim uses the exact same full-stop path, so
  /// the audio core is guaranteed disposed when it resolves.
  Future<void> _stopForVideoClaim() => _stopSession(endStatus: MusicPlaybackStatus.idle);

  Future<void> _stopSession({required MusicPlaybackStatus endStatus}) async {
    _generation++;
    _completedConfirmTimer?.cancel();
    _completedConfirmTimer = null;
    _cancelSleepTimer();
    _finalizeCurrentTrack();
    _queue.clear();
    _currentTrack = null;
    _currentSource = null;
    _armed = null;
    _staleArm = null;
    _playContext = null;
    _resumeAfterInterruption = false;

    final player = _player;
    _player = null;
    for (final sub in _playerSubs) {
      unawaited(sub.cancel());
    }
    _playerSubs.clear();
    if (player != null && !player.disposed) {
      try {
        await player.stop();
      } catch (e) {
        appLogger.d('Audio player stop failed during session teardown', error: e);
      }
      try {
        await player.abandonAudioFocus();
      } catch (e) {
        appLogger.d('Audio focus abandon failed during session teardown', error: e);
      }
      try {
        await player.dispose();
      } catch (e) {
        appLogger.w('Audio player dispose failed during session teardown', error: e);
      }
    }

    unawaited(_controlEventsSub?.cancel());
    _controlEventsSub = null;
    final controls = _mediaControls;
    _mediaControls = null;
    if (controls != null) {
      unawaited(controls.setBackgroundMode(false));
      unawaited(controls.clear());
      controls.dispose();
    }

    _setStatus(endStatus, forceNotify: true);
  }

  @override
  Future<Lyrics?> fetchLyrics(MediaItem track) async {
    final client = _clientFor(track);
    if (client == null) return null;
    return client.fetchLyrics(track);
  }

  MediaServerClient? _clientFor(MediaItem item) {
    final serverId = serverIdOrNull(item.serverId);
    if (serverId == null) return null;
    return _serverManager.getClient(serverId);
  }

  void _setStatus(MusicPlaybackStatus status, {bool forceNotify = false}) {
    if (_disposed) return;
    if (_status == status && !forceNotify) return;
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (_observesLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
      _observesLifecycle = false;
    }
    _coordinator.unregisterMusicSession(_stopForVideoClaim);
    _completedConfirmTimer?.cancel();
    _completedConfirmTimer = null;
    _cancelSleepTimer();
    _finalizeCurrentTrack();
    for (final sub in _playerSubs) {
      unawaited(sub.cancel());
    }
    _playerSubs.clear();
    unawaited(_controlEventsSub?.cancel());
    _controlEventsSub = null;
    final player = _player;
    _player = null;
    if (player != null && !player.disposed) {
      unawaited(
        player.abandonAudioFocus().catchError((Object e) {
          appLogger.d('Audio focus abandon failed during dispose', error: e);
        }),
      );
      unawaited(player.dispose());
    }
    final controls = _mediaControls;
    _mediaControls = null;
    if (controls != null) {
      unawaited(controls.setBackgroundMode(false));
      unawaited(controls.clear());
      controls.dispose();
    }
    unawaited(_positionController.close());
    unawaited(_errorsController.close());
    _volumeNotifier.dispose();
    super.dispose();
  }
}

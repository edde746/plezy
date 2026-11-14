import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../media/lyrics.dart';
import '../../media/media_backend.dart';
import '../../media/media_item.dart';
import '../../utils/app_logger.dart';
import 'music_output.dart';
import 'music_output_controller.dart';
import '../playback_launch_observer.dart';
import 'music_playback_service.dart';

/// The [MusicPlaybackService] the app actually provides: a thin front for
/// whichever engine the chosen output needs.
///
/// ### Why a façade and not two providers
///
/// The UI holds the service — `context.watch<MusicPlaybackService>()` in the
/// mini player, the now-playing screen, the queue sheet, the nav rail — and a
/// `ChangeNotifierProvider` built with `create` never swaps its value. Handing
/// those widgets a different object when the user picks a speaker would mean
/// rebuilding the provider, which tears down the session that is currently
/// playing. So the identity the UI holds stays fixed and the *engine* behind
/// it changes.
///
/// This also keeps the local path exactly as it was. Nothing about
/// [MusicPlaybackServiceImpl] changes; when the output is this device it is
/// simply the delegate, and every call reaches it unaltered.
///
/// ### What switching does
///
/// Stops the outgoing engine, then hands its queue to the new one at the same
/// track and position. Stopping first is deliberate: two engines that both
/// believe they are playing means audio from the phone *and* the speaker,
/// which is the one outcome nobody wants from a control that says "play here
/// instead".
///
/// The handoff works because both engines take the same Plex tracks: the
/// speaker is handed a self-authenticating Plex URL, and the phone streams the
/// same file from Plex itself. A Music Assistant track is the exception — Music
/// Assistant 2.10 cannot play to the phone — so a queue holding one is not
/// carried to it.
class RoutedMusicPlaybackService extends MusicPlaybackService {
  /// Private-named formals: callers pass `local:`, `outputs:` and
  /// `remoteFactory:`, matching the pattern already used by
  /// [MusicPlaybackServiceImpl].
  RoutedMusicPlaybackService({required this._local, required this._outputs, required this._remoteFactory}) {
    _active = _local;
    _attach(_local);
    _outputs.addListener(_onOutputChanged);
    // The controller may already have restored a speaker before this was
    // built, in which case the local engine is not the right delegate.
    _onOutputChanged();
  }

  final MusicPlaybackService _local;
  final MusicOutputController _outputs;
  final MusicPlaybackService Function(MusicOutput output) _remoteFactory;

  late MusicPlaybackService _active;
  MusicPlaybackService? _remote;
  MusicOutput _routedTo = MusicOutput.thisDevice;

  final StreamController<Duration> _positions = StreamController<Duration>.broadcast();
  final StreamController<Object> _errors = StreamController<Object>.broadcast();
  final ValueNotifier<double> _volume = ValueNotifier<double>(100);

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Object>? _errorSubscription;
  VoidCallback? _volumeListener;
  bool _disposed = false;

  /// The engine currently in charge. Exposed for tests and diagnostics.
  @visibleForTesting
  MusicPlaybackService get active => _active;

  /// Where audio is currently routed.
  MusicOutput get routedTo => _routedTo;

  bool get isRemote => _routedTo.isRemote;

  void _onOutputChanged() {
    if (_disposed) return;
    final target = _outputs.selected;
    if (target.id == _routedTo.id) return;
    unawaited(_switchTo(target));
  }

  Future<void> _switchTo(MusicOutput target) async {
    final previous = _active;
    appLogger.i('Routing music from ${_routedTo.name} to ${target.name}');
    _routedTo = target;
    final handoff = _Handoff.take(previous, to: target);

    // Silence the old engine before the new one can start, so the two can
    // never overlap.
    try {
      await previous.stop();
    } catch (e) {
      appLogger.d('Outgoing music engine did not stop cleanly: $e');
    }
    if (_disposed) return;

    _detach();
    if (target.isThisDevice) {
      _active = _local;
    } else {
      // One remote engine at a time: the old one holds a subscription to a
      // queue that is no longer ours.
      final stale = _remote;
      _remote = _remoteFactory(target);
      _active = _remote!;
      stale?.dispose();
    }
    _attach(_active);
    notifyListeners();
    if (handoff != null) await _resume(handoff, on: _active);
  }

  Future<void> _resume(_Handoff handoff, {required MusicPlaybackService on}) async {
    try {
      await on.playFromList(tracks: handoff.tracks, startTrack: handoff.current, playContext: handoff.playContext);
      // Another switch, or the user starting something else, got there first.
      if (_disposed || !identical(on, _active) || on.currentTrack?.globalKey != handoff.current.globalKey) return;
      on.setRepeatMode(handoff.repeatMode);
      if (handoff.position > _Handoff.restartBelow) await on.seek(handoff.position);
      if (!handoff.wasPlaying) await on.pause();
    } catch (e, st) {
      appLogger.w('Could not carry the queue over to ${_routedTo.name}', error: e, stackTrace: st);
    }
  }

  void _attach(MusicPlaybackService service) {
    service.addListener(_bubble);
    _positionSubscription = service.positionStream.listen(
      (position) {
        if (!_positions.isClosed) _positions.add(position);
      },
      onError: (Object error) {
        if (!_positions.isClosed) _positions.addError(error);
      },
    );
    _errorSubscription = service.errors.listen(
      (error) {
        if (!_errors.isClosed) _errors.add(error);
      },
      onError: (Object error) {
        if (!_errors.isClosed) _errors.add(error);
      },
    );
    _volume.value = service.volume;
    void listener() => _volume.value = service.volume;
    _volumeListener = listener;
    service.volumeListenable.addListener(listener);
  }

  void _detach() {
    _active.removeListener(_bubble);
    final listener = _volumeListener;
    if (listener != null) _active.volumeListenable.removeListener(listener);
    _volumeListener = null;
    unawaited(_positionSubscription?.cancel());
    _positionSubscription = null;
    unawaited(_errorSubscription?.cancel());
    _errorSubscription = null;
  }

  void _bubble() {
    if (!_disposed) notifyListeners();
  }

  // ------------------------------------------------------------- forwarding

  @override
  MediaItem? get currentTrack => _active.currentTrack;

  @override
  MusicPlaybackStatus get status => _active.status;

  @override
  Duration? get duration => _active.duration;

  @override
  Duration get position => _active.position;

  @override
  Stream<Duration> get positionStream => _positions.stream;

  @override
  List<MediaItem> get queue => _active.queue;

  @override
  int get currentIndex => _active.currentIndex;

  @override
  MusicPlayContext? get playContext => _active.playContext;

  @override
  bool get shuffled => _active.shuffled;

  @override
  MusicRepeatMode get repeatMode => _active.repeatMode;

  @override
  Stream<Object> get errors => _errors.stream;

  @override
  int beginPlayIntent() => _active.beginPlayIntent();

  @override
  bool isPlayIntentCurrent(int intent) => _active.isPlayIntentCurrent(intent);

  @override
  int get queueSessionRevision => _active.queueSessionRevision;

  @override
  Future<void> playFromList({
    required List<MediaItem> tracks,
    MediaItem? startTrack,
    required MusicPlayContext playContext,
    bool shuffle = false,
    Duration? initialPosition,
    bool offline = false,
    PlaybackLaunchObserver? launchObserver,
  }) => _active.playFromList(
    tracks: tracks,
    startTrack: startTrack,
    playContext: playContext,
    shuffle: shuffle,
    initialPosition: initialPosition,
    offline: offline,
    launchObserver: launchObserver,
  );

  @override
  Future<InstantMixOutcome> playInstantMix(MediaItem seed) => _active.playInstantMix(seed);

  @override
  Future<void> play() => _active.play();

  @override
  Future<void> pause() => _active.pause();

  @override
  Future<void> togglePlayPause() => _active.togglePlayPause();

  @override
  Future<void> next() => _active.next();

  @override
  Future<void> previous() => _active.previous();

  @override
  Future<void> seek(Duration position) => _active.seek(position);

  @override
  double get volume => _active.volume;

  @override
  ValueListenable<double> get volumeListenable => _volume;

  @override
  Future<void> setVolume(double volume, {bool persist = true}) => _active.setVolume(volume, persist: persist);

  @override
  void setRepeatMode(MusicRepeatMode mode) => _active.setRepeatMode(mode);

  @override
  void toggleShuffle() => _active.toggleShuffle();

  @override
  Future<void> jumpTo(int index) => _active.jumpTo(index);

  @override
  void removeAt(int index) => _active.removeAt(index);

  @override
  void reorder(int from, int to) => _active.reorder(from, to);

  @override
  void addNext(List<MediaItem> tracks) => _active.addNext(tracks);

  @override
  void addToEnd(List<MediaItem> tracks) => _active.addToEnd(tracks);

  @override
  void clearUpcoming() => _active.clearUpcoming();

  @override
  Future<void> stop() => _active.stop();

  @override
  bool get sleepTimerActive => _active.sleepTimerActive;

  @override
  Duration? get sleepTimerDuration => _active.sleepTimerDuration;

  @override
  bool get sleepTimerEndOfTrack => _active.sleepTimerEndOfTrack;

  @override
  void setSleepTimer(Duration? duration, {bool endOfTrack = false}) =>
      _active.setSleepTimer(duration, endOfTrack: endOfTrack);

  @override
  Future<Lyrics?> fetchLyrics(MediaItem track) => _active.fetchLyrics(track);

  @override
  void dispose() {
    _disposed = true;
    _outputs.removeListener(_onOutputChanged);
    _detach();
    unawaited(_positions.close());
    unawaited(_errors.close());
    _volume.dispose();
    _remote?.dispose();
    _local.dispose();
    super.dispose();
  }
}

/// What was playing on the engine being switched away from.
class _Handoff {
  const _Handoff({
    required this.tracks,
    required this.current,
    required this.position,
    required this.wasPlaying,
    required this.playContext,
    required this.repeatMode,
  });

  /// Closer to the start than this, the track simply starts over: a seek costs
  /// a speaker a second or two of re-buffering for nothing.
  static const Duration restartBelow = Duration(seconds: 3);

  /// Null when there is nothing to carry over, or nothing [to] can play.
  static _Handoff? take(MusicPlaybackService from, {required MusicOutput to}) {
    final index = from.currentIndex;
    final queue = from.queue;
    // -1 also covers a speaker playing a queue this app did not start.
    if (index < 0 || index >= queue.length) return null;
    if (from.status == MusicPlaybackStatus.idle || from.status == MusicPlaybackStatus.error) return null;
    if (to.isThisDevice && queue.any((t) => t.backend == MediaBackend.musicAssistant)) return null;
    return _Handoff(
      tracks: List.of(queue),
      current: queue[index],
      position: from.position,
      wasPlaying: from.isPlaying || from.status == MusicPlaybackStatus.loading,
      playContext: from.playContext ?? const MusicPlayContext(title: '', kind: MusicPlayContextKind.tracks),
      repeatMode: from.repeatMode,
    );
  }

  final List<MediaItem> tracks;
  final MediaItem current;
  final Duration position;
  final bool wasPlaying;
  final MusicPlayContext playContext;
  final MusicRepeatMode repeatMode;
}

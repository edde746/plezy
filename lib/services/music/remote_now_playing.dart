import 'dart:async';

import 'package:os_media_controls/os_media_controls.dart';

import '../../media/media_item.dart';
import '../../media/media_server_client.dart';
import '../../utils/app_logger.dart';
import '../device_adjustment_service.dart';
import '../media_control_router.dart';
import '../media_controls_manager.dart';
import 'music_output_controller.dart';
import 'music_playback_service.dart';

/// Puts a speaker's playback on the lock screen, Control Center and the
/// headphone controls.
///
/// The local engine does this for itself, but music going to a speaker in
/// another room is played by the server, so nothing on the phone claims the
/// OS media session. iOS then sends an AirPods press to whichever app last
/// played audio, and the lock screen shows nothing to pause.
///
/// ### Why it plays silence
///
/// iOS only routes those commands to the app that is playing audio, and only
/// keeps a backgrounded app alive while it plays. So while a speaker plays,
/// the phone plays silence ([DeviceAdjustmentService.startNowPlayingKeepAlive]).
/// After a pause it holds on for [pausedGrace], so a press on the AirPods can
/// still resume, then lets go so a forgotten pause doesn't run the phone's
/// audio all night.
class RemoteNowPlaying {
  /// Private-named formals: callers pass `outputs:`, `playback:` and
  /// `clientFor:`.
  RemoteNowPlaying({
    required this._outputs,
    required this._playback,
    required this._clientFor,
    DeviceAdjustmentService? device,
    MediaControlsManager Function()? controlsFactory,
  }) : _device = device ?? DeviceAdjustmentService.instance,
       _controlsFactory = controlsFactory ?? MediaControlsManager.new;

  /// How long the session is held after the speaker pauses.
  static const Duration pausedGrace = Duration(minutes: 10);

  static const Duration _skipInterval = Duration(seconds: 15);

  final MusicOutputController _outputs;
  final MusicPlaybackService _playback;
  final MediaServerClient? Function(MediaItem track) _clientFor;
  final DeviceAdjustmentService _device;
  final MediaControlsManager Function() _controlsFactory;

  MediaControlsManager? _controls;
  StreamSubscription<MediaControlEvent>? _events;
  StreamSubscription<Duration>? _positions;
  Timer? _graceTimer;
  bool _holding = false;
  String? _shownTrackKey;
  bool? _shownPlaying;

  bool get isActive => _controls != null;

  /// Whether the phone is currently playing silence for the speaker.
  bool get isHoldingSession => _holding;

  void start() {
    _outputs.addListener(_sync);
    _playback.addListener(_sync);
    _sync();
  }

  Future<void> dispose() async {
    _outputs.removeListener(_sync);
    _playback.removeListener(_sync);
    await _deactivate();
  }

  void _sync() {
    final track = _playback.currentTrack;
    if (!_outputs.selected.isRemote || track == null) {
      if (isActive) unawaited(_deactivate());
      return;
    }
    final controls = _controls ?? _activate();

    final key = track.globalKey;
    if (key != _shownTrackKey) {
      _shownTrackKey = key;
      unawaited(
        controls.updateMetadata(
          metadata: track,
          client: _clientFor(track),
          duration: _playback.duration ?? (track.durationMs != null ? Duration(milliseconds: track.durationMs!) : null),
        ),
      );
    }
    unawaited(
      controls.setControlsEnabled(
        canPlayPause: true,
        canGoNext: _playback.currentIndex < _playback.queue.length - 1,
        canGoPrevious: true,
        canSeek: true,
      ),
    );

    final playing = _playback.isPlaying;
    if (playing != _shownPlaying) {
      _shownPlaying = playing;
      unawaited(
        controls.updatePlaybackState(isPlaying: playing, position: _playback.position, speed: 1.0, force: true),
      );
    }
    _holdFor(playing: playing);
  }

  MediaControlsManager _activate() {
    appLogger.d('Lock screen and headphone controls now drive ${_outputs.selected.name}');
    final controls = _controlsFactory();
    _controls = controls;
    _events = controls.controlEvents.listen(_onEvent);
    _positions = _playback.positionStream.listen((position) {
      _controls?.updatePlaybackState(isPlaying: _playback.isPlaying, position: position, speed: 1.0);
    });
    return controls;
  }

  Future<void> _deactivate() async {
    final controls = _controls;
    _controls = null;
    _shownTrackKey = null;
    _shownPlaying = null;
    await _events?.cancel();
    _events = null;
    await _positions?.cancel();
    _positions = null;
    await _release();
    if (controls != null) {
      await controls.clear();
      controls.dispose();
    }
  }

  void _holdFor({required bool playing}) {
    if (playing) {
      _graceTimer?.cancel();
      _graceTimer = null;
      if (!_holding) {
        _holding = true;
        unawaited(_device.startNowPlayingKeepAlive());
      }
    } else if (_holding && _graceTimer == null) {
      _graceTimer = Timer(pausedGrace, () {
        _graceTimer = null;
        unawaited(_release());
      });
    }
  }

  Future<void> _release() async {
    _graceTimer?.cancel();
    _graceTimer = null;
    if (!_holding) return;
    _holding = false;
    await _device.stopNowPlayingKeepAlive();
  }

  late final _router = MediaControlRouter(
    canControlPlayback: () => true,
    canNavigateMediaItems: () => true,
    onPlay: () => unawaited(_playback.play()),
    onPause: () => unawaited(_playback.pause()),
    onTogglePlayPause: () => unawaited(_playback.togglePlayPause()),
    onSeek: (position) => unawaited(_playback.seek(position)),
    onNext: () => unawaited(_playback.next()),
    onPrevious: () => unawaited(_playback.previous()),
    // Pause, not stop: stopping a speaker clears its queue, which is a lot to
    // lose to a stray lock-screen tap.
    onStop: () => unawaited(_playback.pause()),
    onSkipForward: (interval) => unawaited(_seekBy(interval ?? _skipInterval)),
    onSkipBackward: (interval) => unawaited(_seekBy(-(interval ?? _skipInterval))),
    onSetSpeed: (_) {},
  );

  void _onEvent(MediaControlEvent event) {
    // Interruptions and route changes belong to the phone's own audio. A call
    // coming in is no reason to pause a speaker in another room.
    if (_controls == null) return;
    _router.route(event);
  }

  Future<void> _seekBy(Duration delta) {
    final target = _playback.position + delta;
    return _playback.seek(target < Duration.zero ? Duration.zero : target);
  }
}

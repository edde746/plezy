import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../models.dart';
import 'player.dart';
import 'player_state.dart';
import 'player_stream_controllers.dart';
import 'player_streams.dart';

/// Web-based video player implementation using HTML5 <video> element.
///
/// This player is used on webOS (LG TV) and other web platforms.
/// It wraps the browser's native <video> element and exposes the same
/// interface as MPV/ExoPlayer for seamless integration.
class PlayerWeb with PlayerStreamControllersMixin implements Player {
  PlayerState _state = const PlayerState();
  late final PlayerStreams _streams;
  bool _disposed = false;

  // HTML5 video element
  web.HTMLVideoElement? _videoElement;
  String? _viewId;

  // Track position update timer for smoother updates
  Timer? _positionTimer;

  @override
  PlayerState get state => _state;

  @override
  PlayerStreams get streams => _streams;

  @override
  int? get textureId => null; // Web uses HtmlElementView, not texture

  @override
  String get playerType => 'html5';

  /// The view ID for Flutter's HtmlElementView.
  String? get viewId => _viewId;

  /// The underlying HTML video element.
  web.HTMLVideoElement? get videoElement => _videoElement;

  PlayerWeb() {
    _streams = createStreams();
    _createVideoElement();
  }

  void _createVideoElement() {
    _viewId = 'plezy-video-${DateTime.now().millisecondsSinceEpoch}';
    _videoElement = web.document.createElement('video') as web.HTMLVideoElement;
    _videoElement!
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = 'black'
      ..style.objectFit = 'contain'
      ..setAttribute('playsinline', '')
      ..setAttribute('webkit-playsinline', '')
      ..setAttribute('x-webkit-airplay', 'deny');

    _setupEventListeners();
  }

  void _setupEventListeners() {
    final video = _videoElement!;

    video.addEventListener(
      'play',
      ((web.Event e) {
        _state = _state.copyWith(playing: true);
        playingController.add(true);
      }).toJS,
    );

    video.addEventListener(
      'pause',
      ((web.Event e) {
        _state = _state.copyWith(playing: false);
        playingController.add(false);
      }).toJS,
    );

    video.addEventListener(
      'ended',
      ((web.Event e) {
        _state = _state.copyWith(completed: true);
        completedController.add(true);
      }).toJS,
    );

    video.addEventListener(
      'waiting',
      ((web.Event e) {
        _state = _state.copyWith(buffering: true);
        bufferingController.add(true);
      }).toJS,
    );

    video.addEventListener(
      'playing',
      ((web.Event e) {
        _state = _state.copyWith(buffering: false);
        bufferingController.add(false);
        playbackRestartController.add(null);
      }).toJS,
    );

    video.addEventListener(
      'canplay',
      ((web.Event e) {
        _state = _state.copyWith(buffering: false);
        bufferingController.add(false);
      }).toJS,
    );

    video.addEventListener(
      'durationchange',
      ((web.Event e) {
        final dur = video.duration;
        if (!dur.isNaN && !dur.isInfinite) {
          final duration = Duration(milliseconds: (dur * 1000).toInt());
          _state = _state.copyWith(duration: duration);
          durationController.add(duration);
        }
      }).toJS,
    );

    video.addEventListener(
      'volumechange',
      ((web.Event e) {
        final vol = video.volume * 100;
        _state = _state.copyWith(volume: vol);
        volumeController.add(vol);
      }).toJS,
    );

    video.addEventListener(
      'ratechange',
      ((web.Event e) {
        final rate = video.playbackRate;
        _state = _state.copyWith(rate: rate);
        rateController.add(rate);
      }).toJS,
    );

    video.addEventListener(
      'error',
      ((web.Event e) {
        final error = video.error;
        final message = error != null ? 'Video error: code ${error.code}' : 'Unknown video error';
        errorController.add(message);
      }).toJS,
    );

    video.addEventListener(
      'loadedmetadata',
      ((web.Event e) {
        _parseTracksFromVideo();
      }).toJS,
    );

    // Buffer progress
    video.addEventListener(
      'progress',
      ((web.Event e) {
        _updateBufferProgress();
      }).toJS,
    );
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_videoElement != null && !_disposed) {
        final pos = _videoElement!.currentTime;
        if (!pos.isNaN) {
          final position = Duration(milliseconds: (pos * 1000).toInt());
          _state = _state.copyWith(position: position);
          positionController.add(position);
        }
      }
    });
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  void _updateBufferProgress() {
    final video = _videoElement;
    if (video == null) return;

    final buffered = video.buffered;
    if (buffered.length > 0) {
      final end = buffered.end(buffered.length - 1);
      final buffer = Duration(milliseconds: (end * 1000).toInt());
      _state = _state.copyWith(buffer: buffer);
      bufferController.add(buffer);
    }
  }

  void _parseTracksFromVideo() {
    final video = _videoElement;
    if (video == null) return;

    final audioTracks = <AudioTrack>[];
    final subtitleTracks = <SubtitleTrack>[];

    // Parse audio tracks (if browser exposes them)
    // Note: Browser audio track API support varies
    // Audio tracks are typically limited in web - report at least one default
    audioTracks.add(const AudioTrack(id: '1', title: 'Default', isDefault: true));

    // Parse text/subtitle tracks
    final textTracks = video.textTracks;
    for (var i = 0; i < textTracks.length; i++) {
      final track = textTracks.item(i);
      if (track != null && (track.kind == 'subtitles' || track.kind == 'captions')) {
        subtitleTracks.add(SubtitleTrack(
          id: i.toString(),
          title: track.label.isNotEmpty ? track.label : null,
          language: track.language.isNotEmpty ? track.language : null,
        ));
      }
    }

    final tracks = Tracks(audio: audioTracks, subtitle: subtitleTracks);
    _state = _state.copyWith(tracks: tracks);
    tracksController.add(tracks);
  }

  // ============================================
  // Playback Control
  // ============================================

  @override
  Future<void> open(Media media, {bool play = true}) async {
    if (_disposed) return;

    final video = _videoElement;
    if (video == null) return;

    _state = _state.copyWith(completed: false, position: Duration.zero);
    completedController.add(false);

    // Set headers via fetch if needed (for Plex token auth)
    video.src = media.uri;

    if (media.start != null) {
      video.currentTime = media.start!.inMilliseconds / 1000.0;
    }

    video.load();
    _startPositionTimer();

    if (play) {
      await this.play();
    }
  }

  @override
  Future<void> play() async {
    if (_disposed || _videoElement == null) return;
    try {
      _videoElement!.play();
      _startPositionTimer();
    } catch (e) {
      errorController.add('Play failed: $e');
    }
  }

  @override
  Future<void> pause() async {
    if (_disposed || _videoElement == null) return;
    _videoElement!.pause();
  }

  @override
  Future<void> playOrPause() async {
    if (_state.playing) {
      await pause();
    } else {
      await play();
    }
  }

  @override
  Future<void> stop() async {
    if (_disposed || _videoElement == null) return;
    _videoElement!.pause();
    _videoElement!.currentTime = 0;
    _stopPositionTimer();
    _state = _state.copyWith(playing: false, position: Duration.zero);
    playingController.add(false);
  }

  @override
  Future<void> seek(Duration position) async {
    if (_disposed || _videoElement == null) return;
    _videoElement!.currentTime = position.inMilliseconds / 1000.0;
  }

  // ============================================
  // Track Selection
  // ============================================

  @override
  Future<void> selectAudioTrack(AudioTrack track) async {
    // HTML5 audio track selection is limited
    _state = _state.copyWith(track: _state.track.copyWith(audio: track));
    trackController.add(_state.track);
  }

  @override
  Future<void> selectSubtitleTrack(SubtitleTrack track) async {
    if (_disposed || _videoElement == null) return;

    final textTracks = _videoElement!.textTracks;
    // Disable all tracks first
    for (var i = 0; i < textTracks.length; i++) {
      final tt = textTracks.item(i);
      if (tt != null) {
        tt.mode = 'disabled';
      }
    }

    // Enable selected track
    if (track.id != 'no' && track.id != 'auto') {
      final idx = int.tryParse(track.id);
      if (idx != null && idx < textTracks.length) {
        final tt = textTracks.item(idx);
        if (tt != null) {
          tt.mode = 'showing';
        }
      }
    }

    _state = _state.copyWith(track: _state.track.copyWith(subtitle: track));
    trackController.add(_state.track);
  }

  @override
  Future<void> addSubtitleTrack({
    required String uri,
    String? title,
    String? language,
    bool select = false,
  }) async {
    if (_disposed || _videoElement == null) return;

    final track = web.document.createElement('track') as web.HTMLTrackElement;
    track.kind = 'subtitles';
    track.src = uri;
    if (title != null) track.label = title;
    if (language != null) track.srclang = language;
    if (select) track.default_ = true;

    _videoElement!.appendChild(track);
    _parseTracksFromVideo();
  }

  // ============================================
  // Volume and Rate
  // ============================================

  @override
  Future<void> setVolume(double volume) async {
    if (_disposed || _videoElement == null) return;
    _videoElement!.volume = (volume / 100).clamp(0.0, 1.0);
  }

  @override
  Future<void> setRate(double rate) async {
    if (_disposed || _videoElement == null) return;
    _videoElement!.playbackRate = rate;
  }

  @override
  Future<void> setAudioDevice(AudioDevice device) async {
    // Not supported on web
  }

  // ============================================
  // Properties (mostly no-op on web)
  // ============================================

  @override
  Future<void> setProperty(String name, String value) async {
    // Map common MPV properties to HTML5 equivalents
    switch (name) {
      case 'volume':
        final vol = double.tryParse(value);
        if (vol != null) await setVolume(vol);
      case 'speed':
        final rate = double.tryParse(value);
        if (rate != null) await setRate(rate);
      // Other properties are MPV-specific and don't apply to web
    }
  }

  @override
  Future<String?> getProperty(String name) async {
    switch (name) {
      case 'volume':
        return _videoElement?.volume.toString();
      case 'speed':
        return _videoElement?.playbackRate.toString();
      case 'time-pos':
        return _videoElement?.currentTime.toString();
      case 'duration':
        return _videoElement?.duration.toString();
      default:
        return null;
    }
  }

  @override
  Future<void> command(List<String> args) async {
    // MPV commands are not applicable to web
  }

  @override
  Future<void> setAudioPassthrough(bool enabled) async {
    // Not supported on web
  }

  @override
  Future<bool> setVisible(bool visible) async {
    if (_videoElement != null) {
      _videoElement!.style.visibility = visible ? 'visible' : 'hidden';
      return true;
    }
    return false;
  }

  @override
  Future<void> updateFrame() async {
    // No-op on web
  }

  @override
  Future<void> setVideoFrameRate(double fps, int durationMs) async {
    // Not supported on web
  }

  @override
  Future<void> clearVideoFrameRate() async {
    // Not supported on web
  }

  @override
  Future<bool> requestAudioFocus() async => true;

  @override
  Future<void> abandonAudioFocus() async {}

  // ============================================
  // Lifecycle
  // ============================================

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    _stopPositionTimer();

    if (_videoElement != null) {
      _videoElement!.pause();
      _videoElement!.src = '';
      _videoElement!.load();
      _videoElement = null;
    }

    await closeStreamControllers();
  }
}

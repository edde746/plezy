import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../../../media/media_display_criteria.dart';
import '../../../utils/app_logger.dart';
import '../../models.dart';
import '../player.dart';
import '../player_state.dart';
import '../player_stream_controllers.dart';
import '../player_streams.dart';
import '../subtitle_stream_support.dart';
import '../video_rect_support.dart';

typedef _SubCue = ({int startMs, int endMs, String text});

/// Tizen TV player backend using a native C# hardware overlay (TizenMediaPlayer.cs).
/// Video renders via Display(ElmSharp.Window) on a separate hardware plane, keeping
/// Flutter's GPU free. Video rect updates keep the overlay in sync with the widget.
class PlayerTizen with PlayerStreamControllersMixin implements Player, VideoRectSupport, SubtitleStreamSupport {
  static const _method = MethodChannel('com.plezy/tizen_player');
  static const _event = EventChannel('com.plezy/tizen_player/events');

  PlayerState _state = const PlayerState();
  late final PlayerStreams _streams;
  StreamSubscription<dynamic>? _eventSub;
  bool _disposed = false;
  bool _firstFrameFired = false;

  // Back/d-pad keys intercepted by the ElmSharp window, relayed to Dart.
  final _nativeKeyController = StreamController<String>.broadcast();
  Stream<String> get nativeKeyStream => _nativeKeyController.stream;

  // Throttle position updates to ~4Hz.
  final _throttleSw = Stopwatch()..start();
  int _lastPositionEmitMs = 0;
  Duration _timelineOffset = Duration.zero;
  Duration? _timelineDuration;

  List<AudioTrack> _capiAudioTracks = const [];
  List<SubtitleTrack> _capiSubtitleTracks = const [];
  final List<SubtitleTrack> _dartSubtitleTracks = [];

  final _loadedSubtitles = <String, List<_SubCue>>{};
  List<_SubCue> _activeSubtitleCues = const [];
  // true = embedded via C# SubtitleUpdated; false = external Dart-parsed cues.
  bool _embeddedSubtitleActive = false;
  // Track requested before cues finished loading; activated once ready.
  SubtitleTrack? _pendingSubtitleTrack;
  // Track hidden by sub-visibility:'no'; restored on 'yes'.
  SubtitleTrack? _hiddenSubtitleTrack;
  Timer? _embeddedSubtitleClearTimer;
  Timer? _embeddedSubtitleDelayTimer;
  final _subtitleTextCtrl = StreamController<String>.broadcast();
  StreamSubscription<Duration>? _subtitlePositionSub;
  String _lastSubtitleText = '';
  // Sub-delay in milliseconds. Positive = subtitles appear later.
  int _subDelayMs = 0;

  // Secondary subtitle state (Dart-parsed external only; Capi supports one embedded track).
  final _secondarySubtitleTextCtrl = StreamController<String>.broadcast();
  List<_SubCue> _secondaryActiveSubtitleCues = const [];
  StreamSubscription<Duration>? _secondarySubtitlePositionSub;
  SubtitleTrack? _pendingSecondarySubtitleTrack;
  String _lastSecondarySubtitleText = '';
  int _secondarySubDelayMs = 0;

  @override
  Stream<String> get subtitleTextStream => _subtitleTextCtrl.stream;

  @override
  Stream<String> get secondarySubtitleTextStream => _secondarySubtitleTextCtrl.stream;

  // Populated on 'initialized' event, exposed for the performance overlay.
  int? videoWidth;
  int? videoHeight;
  String? videoCodec;
  String? audioCodec;
  int? audioSampleRate;
  int? audioChannels;
  String? decoderType;

  PlayerTizen() {
    _streams = createStreams();
    _eventSub = _event.receiveBroadcastStream().listen(
      _handleEvent,
      onError: (e) {
        if (!_disposed) errorController.add(PlayerError(e.toString()));
      },
    );
  }

  @override
  PlayerState get state => _state;

  @override
  PlayerStreams get streams => _streams;

  @override
  int? get textureId => null; // video renders in native overlay, not Flutter texture

  @override
  bool get disposed => _disposed;

  @override
  String get playerType => 'tizen';

  @override
  bool get supportsSecondarySubtitles => true;

  void _handleEvent(dynamic raw) {
    if (_disposed || raw is! Map) return;
    final map = raw.cast<String, dynamic>();
    final event = map['event'] as String?;
    if (event == null) return;

    switch (event) {
      case 'initialized':
        final durationMs = map['durationMs'] as int? ?? 0;
        final width = map['width'] as int? ?? 0;
        final height = map['height'] as int? ?? 0;
        videoWidth = width > 0 ? width : null;
        videoHeight = height > 0 ? height : null;
        final rawVideoCodec = map['videoCodec'] as String? ?? '';
        final rawAudioCodec = map['audioCodec'] as String? ?? '';
        videoCodec = rawVideoCodec.isNotEmpty ? rawVideoCodec : null;
        audioCodec = rawAudioCodec.isNotEmpty ? rawAudioCodec : null;
        final sr = map['audioSampleRate'] as int? ?? 0;
        audioSampleRate = sr > 0 ? sr : null;
        final ch = map['audioChannels'] as int? ?? 0;
        audioChannels = ch > 0 ? ch : null;
        final rawDecoder = map['decoderType'] as String? ?? '';
        decoderType = rawDecoder.isNotEmpty ? rawDecoder : null;
        final dur = _timelineDuration ?? _toTimelinePosition(Duration(milliseconds: durationMs));

        _capiAudioTracks = _parseCapiAudioTracks(map['audioTracks']);
        _capiSubtitleTracks = _parseCapiSubtitleTracks(map['embeddedSubtitleTracks']);
        _emitTracks();

        _state = _state.copyWith(duration: dur, seekable: true, buffering: false);
        durationController.add(dur);
        seekableController.add(true);
        bufferingController.add(false);
        if (width > 0 && height > 0) {
          appLogger.d(
            'PlayerTizen: initialized ${width}x$height dur=${durationMs}ms '
            'audio=${_capiAudioTracks.length} sub=${_capiSubtitleTracks.length}',
          );
        }

      case 'subtitle':
        // Embedded subtitle text from the Capi player's SubtitleUpdated callback.
        if (!_embeddedSubtitleActive) break;
        final text = map['text'] as String? ?? '';
        final durationMs2 = map['durationMs'] as int? ?? 3000;
        _embeddedSubtitleClearTimer?.cancel();
        _embeddedSubtitleDelayTimer?.cancel();
        // Apply positive sub-delay via timer; negative delay is not feasible without
        // buffering future events, so emit immediately in that case.
        if (_subDelayMs > 0) {
          _embeddedSubtitleDelayTimer = Timer(Duration(milliseconds: _subDelayMs), () {
            // Guard: if the track was switched or subs turned off during the delay,
            // discard the stale text rather than overwriting the new track's display.
            if (!_embeddedSubtitleActive || _disposed) return;
            _lastSubtitleText = text;
            if (!_subtitleTextCtrl.isClosed) _subtitleTextCtrl.add(text);
            if (text.isNotEmpty) {
              _embeddedSubtitleClearTimer = Timer(Duration(milliseconds: durationMs2), () {
                _lastSubtitleText = '';
                if (!_subtitleTextCtrl.isClosed) _subtitleTextCtrl.add('');
              });
            }
          });
        } else {
          _lastSubtitleText = text;
          if (!_subtitleTextCtrl.isClosed) _subtitleTextCtrl.add(text);
          if (text.isNotEmpty) {
            _embeddedSubtitleClearTimer = Timer(Duration(milliseconds: durationMs2), () {
              _lastSubtitleText = '';
              if (!_subtitleTextCtrl.isClosed) _subtitleTextCtrl.add('');
            });
          }
        }

      case 'position':
        final posMs = map['positionMs'] as int? ?? 0;
        final nowMs = _throttleSw.elapsedMilliseconds;
        if (nowMs - _lastPositionEmitMs >= 250) {
          _lastPositionEmitMs = nowMs;
          final pos = _toTimelinePosition(Duration(milliseconds: posMs));
          _state = _state.copyWith(position: pos);
          positionController.add(pos);
        }

      case 'playing':
        final isPlaying = map['isPlaying'] as bool? ?? false;
        _state = _state.copyWith(playing: isPlaying);
        playingController.add(isPlaying);
        if (isPlaying) {
          if (!_firstFrameFired) _firstFrameFired = true;
          playbackRestartController.add(null);
        }

      case 'buffering':
        final isBuffering = map['isBuffering'] as bool? ?? false;
        final percent = map['percent'] as int? ?? 0;
        // Approximate buffer duration from percent x total duration.
        final bufferDur = _state.duration > Duration.zero
            ? Duration(milliseconds: (_state.duration.inMilliseconds * percent / 100).round())
            : Duration.zero;
        _state = _state.copyWith(buffering: isBuffering, buffer: bufferDur);
        bufferingController.add(isBuffering);
        bufferController.add(bufferDur);

      case 'completed':
        _state = _state.copyWith(completed: true, playing: false);
        completedController.add(true);
        playingController.add(false);

      case 'nativeKey':
        final keyName = map['keyName'] as String?;
        if (keyName != null) _nativeKeyController.add(keyName);

      case 'error':
        final msg = map['message'] as String? ?? 'Unknown error';
        errorController.add(PlayerError(msg));
    }
  }

  /// Called by the Video widget on layout change; forwards physical-pixel rect to C#.
  @override
  Future<void> setVideoRect({
    required int left,
    required int top,
    required int right,
    required int bottom,
    required double devicePixelRatio,
  }) async {
    if (_disposed) return;
    try {
      await _method.invokeMethod<void>('setVideoRect', {
        'left': left,
        'top': top,
        'right': right,
        'bottom': bottom,
        // devicePixelRatio intentionally omitted: C# uses physical pixels directly.
      });
    } catch (e) {
      appLogger.w('PlayerTizen: setVideoRect failed', error: e);
    }
  }

  @override
  Future<void> open(
    Media media, {
    bool play = true,
    bool isLive = false,
    List<SubtitleTrack>? externalSubtitles,
    Duration timelineOffset = Duration.zero,
    Duration? timelineDuration,
  }) async {
    if (_disposed) return;
    _firstFrameFired = false;
    _timelineOffset = timelineOffset;
    _timelineDuration = timelineDuration;

    _capiAudioTracks = const [];
    _capiSubtitleTracks = const [];
    _dartSubtitleTracks.clear();
    _loadedSubtitles.clear();
    _activeSubtitleCues = const [];
    _embeddedSubtitleActive = false;
    _pendingSubtitleTrack = null;
    _hiddenSubtitleTrack = null;
    _embeddedSubtitleClearTimer?.cancel();
    _embeddedSubtitleClearTimer = null;
    _embeddedSubtitleDelayTimer?.cancel();
    _embeddedSubtitleDelayTimer = null;
    _subtitlePositionSub?.cancel();
    _subtitlePositionSub = null;
    _lastSubtitleText = '';
    _subDelayMs = 0;
    if (!_subtitleTextCtrl.isClosed) _subtitleTextCtrl.add('');
    // Reset secondary subtitle state.
    _secondaryActiveSubtitleCues = const [];
    _secondarySubtitlePositionSub?.cancel();
    _secondarySubtitlePositionSub = null;
    _pendingSecondarySubtitleTrack = null;
    _lastSecondarySubtitleText = '';
    _secondarySubDelayMs = 0;
    if (!_secondarySubtitleTextCtrl.isClosed) _secondarySubtitleTextCtrl.add('');

    final startPosition = _toTimelinePosition(media.start ?? Duration.zero);
    _state = PlayerState(position: startPosition, duration: timelineDuration ?? Duration.zero, buffering: true);
    positionController.add(startPosition);
    durationController.add(timelineDuration ?? Duration.zero);
    playingController.add(false);
    completedController.add(false);
    bufferingController.add(true);
    seekableController.add(false);

    try {
      await _method.invokeMethod<void>('open', {
        'url': media.uri,
        if (media.headers != null && media.headers!.isNotEmpty) 'headers': media.headers,
        if (media.start != null) 'startMs': media.start!.inMilliseconds,
        'play': play,
      });
    } catch (e) {
      _state = _state.copyWith(buffering: false);
      bufferingController.add(false);
      errorController.add(PlayerError('Failed to open media: $e'));
    }
  }

  @override
  Future<void> play() async {
    if (_disposed) return;
    try {
      await _method.invokeMethod<void>('play');
    } catch (e) {
      appLogger.w('PlayerTizen: play failed', error: e);
    }
  }

  @override
  Future<void> pause() async {
    if (_disposed) return;
    try {
      await _method.invokeMethod<void>('pause');
    } catch (e) {
      appLogger.w('PlayerTizen: pause failed', error: e);
    }
  }

  @override
  Future<void> playOrPause() async {
    if (_disposed) return;
    if (_state.playing) {
      await pause();
    } else {
      await play();
    }
  }

  @override
  Future<void> stop() async {
    if (_disposed) return;
    try {
      await _method.invokeMethod<void>('stop');
      _state = _state.copyWith(seekable: false, playing: false, buffering: false);
      seekableController.add(false);
      bufferingController.add(false);
      playingController.add(false);
    } catch (e) {
      appLogger.w('PlayerTizen: stop failed', error: e);
    }
  }

  @override
  Future<void> seek(Duration position) async {
    if (_disposed) return;
    try {
      await _method.invokeMethod<void>('seek', {'positionMs': _sourceSeekPosition(position).inMilliseconds});
    } catch (e) {
      appLogger.w('PlayerTizen: seek failed', error: e);
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    if (_disposed) return;
    try {
      await _method.invokeMethod<void>('setVolume', {'volume': volume});
      _state = _state.copyWith(volume: volume);
      volumeController.add(volume);
    } catch (e) {
      appLogger.w('PlayerTizen: setVolume failed', error: e);
    }
  }

  @override
  Future<void> setRate(double rate) async {
    if (_disposed) return;
    try {
      await _method.invokeMethod<void>('setRate', {'rate': rate});
      _state = _state.copyWith(rate: rate);
      rateController.add(rate);
    } catch (e) {
      appLogger.w('PlayerTizen: setRate failed', error: e);
    }
  }

  /// Cycle native display mode (0=contain, 1=cover, 2=fill).
  Future<void> setNativeDisplayMode(int mode) async {
    if (_disposed) return;
    try {
      await _method.invokeMethod<void>('setDisplayMode', {'mode': mode});
    } catch (e) {
      appLogger.w('PlayerTizen: setDisplayMode failed', error: e);
    }
  }

  @override
  Future<void> setProperty(String name, String value) async {
    switch (name) {
      // Sub-delay: shift subtitle timing in milliseconds.
      // Positive = subtitles appear later, negative = earlier.
      // Dart-parsed cues apply the offset in _onSubtitlePosition.
      // Embedded (C# driven) subs support positive delay via Timer.
      case 'sub-delay':
        _subDelayMs = ((double.tryParse(value) ?? 0.0) * 1000).round();

      case 'sub-delay2':
        _secondarySubDelayMs = ((double.tryParse(value) ?? 0.0) * 1000).round();

      // sub-visibility mirrors Android's _hiddenSubtitleTrackId pattern:
      // 'no' remembers and hides the current track; 'yes' restores it.
      case 'sub-visibility':
        if (value == 'no') {
          _hiddenSubtitleTrack = _state.track.subtitle;
          await selectSubtitleTrack(SubtitleTrack.off);
        } else {
          final hidden = _hiddenSubtitleTrack;
          if (hidden != null && hidden.id != 'no') {
            _hiddenSubtitleTrack = null;
            await selectSubtitleTrack(hidden);
          }
        }

      // Subtitle style and all other mpv-specific properties: no-op on Tizen.
      default:
        break;
    }
  }

  @override
  Future<String?> getProperty(String name) async => null;

  @override
  Future<void> command(List<String> args) async {
    if (args.isEmpty) return;
    if (args[0] == 'sub-seek' && args.length >= 2) {
      final offset = int.tryParse(args[1]) ?? 0;
      _handleSubSeek(offset);
    }
    // glsl-shaders, screenshot etc. are mpv-specific; no-op on Tizen.
  }

  @override
  Future<void> selectAudioTrack(AudioTrack track) async {
    if (_disposed) return;
    if (!track.id.startsWith('capi_audio:')) return;
    final index = int.tryParse(track.id.replaceFirst('capi_audio:', ''));
    if (index == null) return;
    try {
      await _method.invokeMethod<void>('selectAudioTrack', {'index': index});
      _state = _state.copyWith(track: _state.track.copyWith(audio: track));
      trackController.add(_state.track);
    } catch (e) {
      appLogger.w('PlayerTizen: selectAudioTrack failed', error: e);
    }
  }

  @override
  Future<void> selectSubtitleTrack(SubtitleTrack track) async {
    _subtitlePositionSub?.cancel();
    _subtitlePositionSub = null;
    _embeddedSubtitleClearTimer?.cancel();
    _embeddedSubtitleClearTimer = null;
    _embeddedSubtitleDelayTimer?.cancel();
    _embeddedSubtitleDelayTimer = null;

    if (track.id == 'no' || track.id == 'auto') {
      // Off: clear both paths.
      _embeddedSubtitleActive = false;
      _activeSubtitleCues = const [];
      _lastSubtitleText = '';
      if (!_subtitleTextCtrl.isClosed) _subtitleTextCtrl.add('');
      _state = _state.copyWith(track: _state.track.copyWith(subtitle: track));
      trackController.add(_state.track);
      return;
    }

    if (track.id.startsWith('capi_sub:')) {
      // Embedded subtitle: let C# SubtitleUpdated drive the display.
      final index = int.tryParse(track.id.replaceFirst('capi_sub:', ''));
      _embeddedSubtitleActive = true;
      _activeSubtitleCues = const [];
      _lastSubtitleText = '';
      if (!_subtitleTextCtrl.isClosed) _subtitleTextCtrl.add('');
      if (index != null) {
        try {
          await _method.invokeMethod<void>('selectSubtitleTrack', {'index': index});
        } catch (e) {
          appLogger.w('PlayerTizen: selectSubtitleTrack (capi) failed', error: e);
        }
      }
      _state = _state.copyWith(track: _state.track.copyWith(subtitle: track));
      trackController.add(_state.track);
      return;
    }

    if (track.isExternal && track.uri != null) {
      // External Dart-parsed subtitle.
      final cues = _loadedSubtitles[track.uri!];
      if (cues == null) {
        // Cues not ready yet; addSubtitleTrack() is still fetching.
        // Store as pending; it will be activated once loading completes.
        _pendingSubtitleTrack = track;
        appLogger.d('PlayerTizen: cues not ready for ${track.uri}, stored as pending');
        return;
      }
      _embeddedSubtitleActive = false;
      _activeSubtitleCues = cues;
      _subtitlePositionSub = _streams.position.listen(_onSubtitlePosition);
      _state = _state.copyWith(track: _state.track.copyWith(subtitle: track));
      trackController.add(_state.track);
    }
  }

  @override
  Future<void> selectSecondarySubtitleTrack(SubtitleTrack track) async {
    _secondarySubtitlePositionSub?.cancel();
    _secondarySubtitlePositionSub = null;

    if (track.id == 'no' || track.id == 'auto') {
      _secondaryActiveSubtitleCues = const [];
      _lastSecondarySubtitleText = '';
      if (!_secondarySubtitleTextCtrl.isClosed) _secondarySubtitleTextCtrl.add('');
      _state = _state.copyWith(track: _state.track.copyWith(secondarySubtitle: track));
      trackController.add(_state.track);
      return;
    }

    if (track.id.startsWith('capi_sub:')) {
      // Capi only supports one embedded text track; secondary embedded is not possible.
      // Still update state so the UI reflects the rejection (shows track as deselected).
      appLogger.w('PlayerTizen: secondary embedded subtitle not supported; use an external track');
      _secondaryActiveSubtitleCues = const [];
      _lastSecondarySubtitleText = '';
      if (!_secondarySubtitleTextCtrl.isClosed) _secondarySubtitleTextCtrl.add('');
      _state = _state.copyWith(track: _state.track.copyWith(secondarySubtitle: SubtitleTrack.off));
      trackController.add(_state.track);
      return;
    }

    if (track.isExternal && track.uri != null) {
      final cues = _loadedSubtitles[track.uri!];
      if (cues == null) {
        _pendingSecondarySubtitleTrack = track;
        appLogger.d('PlayerTizen: secondary cues not ready for ${track.uri}, stored as pending');
        return;
      }
      _secondaryActiveSubtitleCues = cues;
      _secondarySubtitlePositionSub = _streams.position.listen(_onSecondarySubtitlePosition);
      _state = _state.copyWith(track: _state.track.copyWith(secondarySubtitle: track));
      trackController.add(_state.track);
    }
  }

  @override
  Future<void> addSubtitleTrack({required String uri, String? title, String? language, bool select = false}) async {
    try {
      final content = await _fetchText(uri);
      _loadedSubtitles[uri] = _parseSubtitle(content);
      appLogger.d('PlayerTizen: loaded ${_loadedSubtitles[uri]!.length} cues from $uri');

      final dartTrack = SubtitleTrack(
        id: 'external:$uri',
        title: title,
        language: language,
        codec: _inferSubtitleCodec(uri),
        isExternal: true,
        uri: uri,
      );
      if (!_dartSubtitleTracks.any((t) => t.uri == uri)) {
        _dartSubtitleTracks.add(dartTrack);
        _emitTracks();
      }

      if (select) {
        _embeddedSubtitleActive = false;
        _activeSubtitleCues = _loadedSubtitles[uri]!;
        _subtitlePositionSub?.cancel();
        _subtitlePositionSub = _streams.position.listen(_onSubtitlePosition);
        _state = _state.copyWith(track: _state.track.copyWith(subtitle: dartTrack));
        trackController.add(_state.track);
      }

      // If selectSubtitleTrack was called while this URI was still loading,
      // activate it now that cues are ready.
      final pending = _pendingSubtitleTrack;
      if (!select && pending != null && pending.uri == uri) {
        _pendingSubtitleTrack = null;
        _embeddedSubtitleActive = false;
        _activeSubtitleCues = _loadedSubtitles[uri]!;
        _subtitlePositionSub?.cancel();
        _subtitlePositionSub = _streams.position.listen(_onSubtitlePosition);
        _state = _state.copyWith(track: _state.track.copyWith(subtitle: pending));
        trackController.add(_state.track);
        appLogger.d('PlayerTizen: auto-activated pending subtitle $uri');
      }

      // If selectSecondarySubtitleTrack was called while this URI was still loading,
      // activate it now that cues are ready.
      final pendingSecondary = _pendingSecondarySubtitleTrack;
      if (pendingSecondary != null && pendingSecondary.uri == uri) {
        _pendingSecondarySubtitleTrack = null;
        _secondaryActiveSubtitleCues = _loadedSubtitles[uri]!;
        _secondarySubtitlePositionSub?.cancel();
        _secondarySubtitlePositionSub = _streams.position.listen(_onSecondarySubtitlePosition);
        _state = _state.copyWith(track: _state.track.copyWith(secondarySubtitle: pendingSecondary));
        trackController.add(_state.track);
        appLogger.d('PlayerTizen: auto-activated pending secondary subtitle $uri');
      }
    } catch (e) {
      appLogger.w('PlayerTizen: failed to load subtitle from $uri', error: e);
    }
  }

  @override
  Future<void> setAudioDevice(AudioDevice device) async {}

  @override
  Future<void> setAudioPassthrough(bool enabled) async {}

  @override
  Future<void> setLogLevel(String level) async {}

  @override
  Future<void> setDisplayCriteria(MediaDisplayCriteria? criteria) async {}

  @override
  Future<void> configureSubtitleFonts() async {}

  @override
  Future<bool> setVisible(bool visible, {bool restoreOnWindowVisible = false}) async {
    if (_disposed) return true;
    try {
      await _method.invokeMethod<void>('setVisible', {'visible': visible});
    } catch (e) {
      appLogger.w('PlayerTizen: setVisible failed', error: e);
    }
    return true;
  }

  @override
  Future<void> updateFrame() async {}

  @override
  Future<bool> setVideoFrameRate(double fps, int durationMs, {int extraDelayMs = 0}) async => false;

  @override
  Future<void> clearVideoFrameRate() async {}

  @override
  Future<bool> requestAudioFocus() async => true;

  @override
  Future<void> abandonAudioFocus() async {}

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _embeddedSubtitleClearTimer?.cancel();
    _embeddedSubtitleDelayTimer?.cancel();
    await _subtitlePositionSub?.cancel();
    await _subtitleTextCtrl.close();
    await _secondarySubtitlePositionSub?.cancel();
    await _secondarySubtitleTextCtrl.close();
    await _eventSub?.cancel();
    try {
      await _method.invokeMethod<void>('dispose');
    } catch (_) {}
    await _nativeKeyController.close();
    await closeStreamControllers();
  }

  void _emitTracks() {
    final tracks = Tracks(audio: _capiAudioTracks, subtitle: [..._capiSubtitleTracks, ..._dartSubtitleTracks]);
    _state = _state.copyWith(tracks: tracks);
    tracksController.add(tracks);
  }

  Duration _sourceSeekPosition(Duration timelinePosition) {
    final sourcePosition = timelinePosition - _timelineOffset;
    return sourcePosition.isNegative ? Duration.zero : sourcePosition;
  }

  Duration _toTimelinePosition(Duration sourcePosition) => sourcePosition + _timelineOffset;

  List<AudioTrack> _parseCapiAudioTracks(dynamic raw) {
    if (raw is! List) return const [];
    final result = <AudioTrack>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final index = map['index'] as int? ?? result.length;
      final lang = map['language'] as String? ?? '';
      result.add(
        AudioTrack(
          id: 'capi_audio:$index',
          title: lang.isNotEmpty ? lang : 'Track ${index + 1}',
          language: lang.isNotEmpty ? lang : null,
        ),
      );
    }
    return result;
  }

  List<SubtitleTrack> _parseCapiSubtitleTracks(dynamic raw) {
    if (raw is! List) return const [];
    final result = <SubtitleTrack>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final index = map['index'] as int? ?? result.length;
      final lang = map['language'] as String? ?? '';
      // Only set language, not title, to avoid "en · EN" duplication in the label.
      // buildSubtitleLabel will display "EN" from the language code, falling back
      // to "Subtitle N" when the language is absent.
      result.add(SubtitleTrack(id: 'capi_sub:$index', title: null, language: lang.isNotEmpty ? lang : null));
    }
    return result;
  }

  void _handleSubSeek(int offset) {
    if (_activeSubtitleCues.isEmpty) return;
    final posMs = _state.position.inMilliseconds;

    // Find current cue index, or the cue just before current position.
    int currentIndex = -1;
    for (int i = 0; i < _activeSubtitleCues.length; i++) {
      final cue = _activeSubtitleCues[i];
      if (posMs >= cue.startMs && posMs < cue.endMs) {
        currentIndex = i;
        break;
      }
      if (cue.startMs > posMs) {
        currentIndex = i - 1;
        break;
      }
    }

    final targetIndex = (currentIndex + offset).clamp(0, _activeSubtitleCues.length - 1);
    final targetMs = _activeSubtitleCues[targetIndex].startMs;
    seek(Duration(milliseconds: targetMs));
  }

  /// Infers subtitle codec from URI file extension, stripping query params first.
  static String? _inferSubtitleCodec(String uri) {
    final path = uri.toLowerCase().split('?').first;
    if (path.endsWith('.srt')) return 'srt';
    if (path.endsWith('.vtt') || path.endsWith('.webvtt')) return 'webvtt';
    if (path.endsWith('.ass') || path.endsWith('.ssa')) return 'ass';
    return null;
  }

  void _onSubtitlePosition(Duration pos) {
    if (_activeSubtitleCues.isEmpty) return;
    // Shift playback position by delay: positive delay makes subs appear later
    // (we look further back in the cue list relative to current position).
    final posMs = pos.inMilliseconds - _subDelayMs;
    String text = '';
    for (final cue in _activeSubtitleCues) {
      if (posMs >= cue.startMs && posMs < cue.endMs) {
        text = cue.text;
        break;
      }
    }
    if (text != _lastSubtitleText) {
      _lastSubtitleText = text;
      if (!_subtitleTextCtrl.isClosed) _subtitleTextCtrl.add(text);
    }
  }

  void _onSecondarySubtitlePosition(Duration pos) {
    if (_secondaryActiveSubtitleCues.isEmpty) return;
    final posMs = pos.inMilliseconds - _secondarySubDelayMs;
    String text = '';
    for (final cue in _secondaryActiveSubtitleCues) {
      if (posMs >= cue.startMs && posMs < cue.endMs) {
        text = cue.text;
        break;
      }
    }
    if (text != _lastSecondarySubtitleText) {
      _lastSecondarySubtitleText = text;
      if (!_secondarySubtitleTextCtrl.isClosed) _secondarySubtitleTextCtrl.add(text);
    }
  }

  /// Fetches text from a file:// or HTTP URI (15s timeout).
  Future<String> _fetchText(String uri) async {
    if (uri.startsWith('file://')) {
      return File(uri.replaceFirst('file://', '')).readAsString();
    }
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(uri)).timeout(const Duration(seconds: 15));
      final response = await request.close().timeout(const Duration(seconds: 15));
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
      }
      return utf8.decode(bytes, allowMalformed: true);
    } finally {
      client.close();
    }
  }

  /// Dispatches to SRT or VTT parser based on content.
  List<_SubCue> _parseSubtitle(String content) {
    final trimmed = content.trimLeft();
    if (trimmed.startsWith('WEBVTT')) return _parseVtt(content);
    return _parseSrt(content);
  }

  List<_SubCue> _parseSrt(String content) {
    final cues = <_SubCue>[];
    final lines = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
    final timingRe = RegExp(r'(\d{1,2}):(\d{2}):(\d{2})[,.:](\d{3})\s*-->\s*(\d{1,2}):(\d{2}):(\d{2})[,.:](\d{3})');
    int i = 0;
    while (i < lines.length) {
      while (i < lines.length && lines[i].trim().isEmpty) i++;
      if (i >= lines.length) break;
      // Skip optional cue index line (all-digit)
      if (RegExp(r'^\d+$').hasMatch(lines[i].trim())) i++;
      if (i >= lines.length) break;
      final m = timingRe.firstMatch(lines[i]);
      if (m == null) {
        i++;
        continue;
      }
      final startMs = _tsToMs(m, 1);
      final endMs = _tsToMs(m, 5);
      i++;
      final textLines = <String>[];
      while (i < lines.length && lines[i].trim().isNotEmpty) {
        textLines.add(lines[i]);
        i++;
      }
      if (textLines.isNotEmpty) {
        final text = textLines.join('\n').replaceAll(RegExp(r'<[^>]*>'), '').trim();
        if (text.isNotEmpty) cues.add((startMs: startMs, endMs: endMs, text: text));
      }
    }
    return cues;
  }

  List<_SubCue> _parseVtt(String content) {
    final cues = <_SubCue>[];
    final lines = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
    // VTT timestamps use '.' as ms separator; same regex handles both ',' and '.'
    final timingRe = RegExp(
      r'(?:(\d{1,2}):)?(\d{2}):(\d{2})[,.](\d{3})\s*-->\s*(?:(\d{1,2}):)?(\d{2}):(\d{2})[,.](\d{3})',
    );
    int i = 0;
    while (i < lines.length && !lines[i].contains('-->')) i++;
    while (i < lines.length) {
      final m = timingRe.firstMatch(lines[i]);
      if (m != null) {
        final startMs = _vttTsToMs(m, 1);
        final endMs = _vttTsToMs(m, 5);
        i++;
        final textLines = <String>[];
        while (i < lines.length && lines[i].trim().isNotEmpty) {
          textLines.add(lines[i]);
          i++;
        }
        if (textLines.isNotEmpty) {
          final text = textLines.join('\n').replaceAll(RegExp(r'<[^>]*>'), '').trim();
          if (text.isNotEmpty) cues.add((startMs: startMs, endMs: endMs, text: text));
        }
      } else {
        i++;
      }
    }
    return cues;
  }

  static int _tsToMs(RegExpMatch m, int o) =>
      int.parse(m.group(o)!) * 3600000 +
      int.parse(m.group(o + 1)!) * 60000 +
      int.parse(m.group(o + 2)!) * 1000 +
      int.parse(m.group(o + 3)!);

  static int _vttTsToMs(RegExpMatch m, int o) {
    final hours = int.tryParse(m.group(o) ?? '') ?? 0;
    return hours * 3600000 +
        int.parse(m.group(o + 1)!) * 60000 +
        int.parse(m.group(o + 2)!) * 1000 +
        int.parse(m.group(o + 3)!);
  }
}

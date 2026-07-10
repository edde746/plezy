import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' show protected;
import 'package:flutter/services.dart';

import '../../media/media_display_criteria.dart';
import '../../utils/app_logger.dart';
import '../../utils/track_label_builder.dart';
import '../font_loader.dart';
import '../models.dart';
import 'player.dart';
import 'player_state.dart';
import 'player_stream_controllers.dart';
import 'player_streams.dart';

/// Abstract base class for player implementations.
///
/// This class contains shared logic for both [PlayerAndroid] (ExoPlayer)
/// and [PlayerNative] (MPV) implementations, including:
/// - State management
/// - Stream controller setup
/// - Event handling infrastructure
/// - Property change handlers
/// - Track parsing and selection
/// - Common lifecycle methods
abstract class PlayerBase with PlayerStreamControllersMixin implements Player {
  PlayerState _state = const PlayerState();

  @override
  PlayerState get state => _state;

  @override
  Duration get currentPosition => Duration(milliseconds: _positionMs);

  @override
  bool get audioPassthroughActive => false;

  /// Gapless-audio arming — meaningful only on the audio players, which
  /// override this. Video backends ignore it.
  @override
  Future<void> setNext(Media? media) async {}

  late final PlayerStreams _streams;

  @override
  PlayerStreams get streams => _streams;

  @override
  int? get textureId => null;

  StreamSubscription? _eventSubscription;
  StreamSubscription? _logSubscription;
  bool _disposed = false;
  final _throttleSw = Stopwatch()..start();
  int _lastEmitMs = 0;
  int _lastCacheStateMs = 0;
  int _positionMs = 0;
  Duration _timelineOffset = Duration.zero;
  Duration? _timelineDuration;
  int _nextPropId = 0;
  final Map<int, String> _propIdToName = {};
  Map<String, SubtitleTrack> _externalSubtitleMetadataByUri = const {};

  @protected
  bool initialized = false;

  @override
  bool get disposed => _disposed;

  MethodChannel get methodChannel;

  EventChannel get eventChannel;

  String get logPrefix;

  PlayerBase() {
    _streams = createStreams();
    _setupEventListener();
    _logSubscription = logController.stream.listen(_forwardToAppLogger);
  }

  void _forwardToAppLogger(PlayerLog log) {
    final message = '[$logPrefix:${log.prefix}] ${log.text}'.trimRight();
    switch (log.level) {
      case PlayerLogLevel.fatal:
      case PlayerLogLevel.error:
        appLogger.e(message);
      case PlayerLogLevel.warn:
        appLogger.w(message);
      case PlayerLogLevel.info:
      case PlayerLogLevel.verbose:
        appLogger.i(message);
      case PlayerLogLevel.debug:
      case PlayerLogLevel.trace:
        appLogger.d(message);
      case PlayerLogLevel.none:
        break;
    }
  }

  /// Backends expose static per-backend [EventChannel]s, so two overlapping
  /// instances (episode handoff, quick exit/reopen) share one channel name.
  /// The engine allows a single active stream per channel: a newer instance's
  /// listen displaces the older sink, and the older instance's late cancel
  /// would then tear down the *newer* stream — leaving it eventless — while
  /// the final cancel gets an engine "No active stream to cancel" error.
  /// Only the instance recorded here may send the native cancel.
  static final Map<String, PlayerBase> _eventChannelOwners = {};

  void _setupEventListener() {
    _eventChannelOwners[eventChannel.name] = this;
    _eventSubscription = eventChannel.receiveBroadcastStream().listen(
      _handleEvent,
      onError: (error) {
        if (_disposed) return;
        errorController.add(PlayerError(error.toString()));
      },
    );
  }

  /// The (name, format) registrations every backend makes at init — the
  /// properties [handlePropertyChange] needs for core [PlayerState].
  /// `track-list` is registered separately because mpv uses node format on
  /// Apple platforms; backend-specific extras (mpv: secondary-sid /
  /// demuxer-cache-state / audio-device*; ExoPlayer: demuxer-cache-time)
  /// are appended by the subclasses.
  static const List<(String, String)> corePropertyObservations = [
    ('time-pos', 'double'),
    ('duration', 'double'),
    ('seekable', 'flag'),
    ('pause', 'flag'),
    ('paused-for-cache', 'flag'),
    ('eof-reached', 'flag'),
    ('volume', 'double'),
    ('speed', 'double'),
    ('aid', 'string'),
    ('sid', 'string'),
  ];

  /// Register [corePropertyObservations] plus `track-list` in the
  /// backend's preferred format. Called from each subclass's initialize.
  @protected
  Future<void> observeCoreProperties({required String trackListFormat}) async {
    for (final (name, format) in corePropertyObservations) {
      await observeProperty(name, format);
    }
    await observeProperty('track-list', trackListFormat);
  }

  @protected
  Future<void> observeProperty(String name, String format) async {
    final propId = _nextPropId++;
    _propIdToName[propId] = name;
    await invoke('observeProperty', {'name': name, 'format': format, 'id': propId});
  }

  void _handleEvent(dynamic event) {
    if (_disposed) return;
    if (event is List && event.length == 2) {
      final name = _propIdToName[event.first as int];
      if (name != null) {
        handlePropertyChange(name, event[1]);
      }
    } else if (event is Map) {
      final type = event['type'] as String?;
      final name = event['name'] as String?;
      if (type == 'event' && name != null) {
        handlePlayerEvent(name, event['data'] as Map?);
      }
    }
  }

  void handlePropertyChange(String name, dynamic value) {
    if (_disposed) return;
    switch (name) {
      case 'pause':
        final playing = value == false;
        _state = _state.copyWith(playing: playing);
        playingController.add(playing);
        break;

      case 'eof-reached':
        final completed = value == true;
        _state = _state.copyWith(completed: completed);
        completedController.add(completed);
        break;

      case 'paused-for-cache':
        final buffering = value == true;
        _state = _state.copyWith(buffering: buffering);
        bufferingController.add(buffering);
        break;

      case 'time-pos':
        if (value is num) {
          final pos = _toTimelinePosition(Duration(milliseconds: (value * 1000).round()));
          _positionMs = pos.inMilliseconds;
          // Only allocate Duration + copyWith + emit at ~4Hz (250ms).
          // Raw int is stored every tick so synchronous reads via _positionMs stay current.
          final nowMs = _throttleSw.elapsedMilliseconds;
          if (nowMs - _lastEmitMs >= 250) {
            _lastEmitMs = nowMs;
            _state = _state.copyWith(position: pos);
            positionController.add(pos);
          }
        }
        break;

      case 'duration':
        if (value is num) {
          final duration = _timelineDuration ?? _toTimelinePosition(Duration(milliseconds: (value * 1000).toInt()));
          _state = _state.copyWith(duration: duration);
          durationController.add(duration);
        }
        break;

      case 'seekable':
        if (value is bool) {
          setSeekable(value);
        }
        break;

      case 'demuxer-cache-time':
        if (value is num) {
          final nowMs = _throttleSw.elapsedMilliseconds;
          if (nowMs - _lastCacheStateMs < 250) break;
          _lastCacheStateMs = nowMs;
          final buffer = _toTimelinePosition(Duration(milliseconds: (value * 1000).toInt()));
          _state = _state.copyWith(buffer: buffer);
          bufferController.add(buffer);
          // Synthesize a single range for players without demuxer-cache-state (ExoPlayer).
          // ExoPlayer only buffers ahead of the current position, so use position as start.
          final ranges = [BufferRange(start: _state.position, end: buffer)];
          _state = _state.copyWith(bufferRanges: ranges);
          bufferRangesController.add(ranges);
        }
        break;

      case 'demuxer-cache-state':
        _handleDemuxerCacheState(value);
        break;

      case 'volume':
        if (value is num) {
          setVolumeState(value.toDouble());
        }
        break;

      case 'speed':
        if (value is num) {
          final rate = value.toDouble();
          _state = _state.copyWith(rate: rate);
          rateController.add(rate);
        }
        break;

      case 'track-list':
        List? trackList;
        if (value is List) {
          trackList = value;
        } else if (value is String && value.isNotEmpty) {
          try {
            final parsed = jsonDecode(value);
            if (parsed is List) trackList = parsed;
          } catch (e) {
            appLogger.d('Player: track-list parse failed', error: e);
          }
        }
        if (trackList != null) {
          final result = parseTrackList(trackList);
          _state = _state.copyWith(tracks: result.tracks);
          tracksController.add(result.tracks);
          // Derive selection from mpv's "selected" field in the track data.
          // This is the source of truth and handles cases where aid/sid
          // values don't match track IDs (e.g. "auto", "0", "no").
          if (result.selectedAudioId != null) {
            updateSelectedAudioTrack(result.selectedAudioId);
          }
          if (result.selectedSubtitleId != null) {
            updateSelectedSubtitleTrack(result.selectedSubtitleId);
          }
        }
        break;

      case 'aid':
        updateSelectedAudioTrack(value);
        break;

      case 'sid':
        updateSelectedSubtitleTrack(value);
        break;

      case 'secondary-sid':
        updateSelectedSecondarySubtitleTrack(value);
        break;

      case 'audio-device-list':
        List? deviceList;
        if (value is List) {
          deviceList = value;
        } else if (value is String && value.isNotEmpty) {
          try {
            final parsed = jsonDecode(value);
            if (parsed is List) deviceList = parsed;
          } catch (e) {
            appLogger.d('Player: device-list parse failed', error: e);
          }
        }
        if (deviceList != null) {
          final devices = deviceList
              .whereType<Map>()
              .map((d) => AudioDevice(name: d['name'] as String? ?? '', description: d['description'] as String? ?? ''))
              .toList();
          _state = _state.copyWith(audioDevices: devices);
          audioDevicesController.add(devices);
        }
        break;

      case 'audio-device':
        if (value is String && value.isNotEmpty) {
          final device = _state.audioDevices.firstWhereOrNull((d) => d.name == value) ?? AudioDevice(name: value);
          _state = _state.copyWith(audioDevice: device);
          audioDeviceController.add(device);
        }
        break;
    }
  }

  /// Parse demuxer-cache-state property to extract seekable ranges and buffer end.
  void _handleDemuxerCacheState(dynamic value) {
    Map? cacheState;
    if (value is Map) {
      cacheState = value;
    } else if (value is String && value.isNotEmpty) {
      // Throttle JSON parsing to avoid ANR on low-end devices
      final nowMs = _throttleSw.elapsedMilliseconds;
      if (nowMs - _lastCacheStateMs < 250) return;
      _lastCacheStateMs = nowMs;
      try {
        final parsed = jsonDecode(value);
        if (parsed is Map) cacheState = parsed;
      } catch (_) {}
    }
    if (cacheState == null) return;

    // Extract cache-end for the single buffer duration (replaces demuxer-cache-time)
    final cacheEnd = cacheState['cache-end'] as num?;
    if (cacheEnd != null) {
      final buffer = _toTimelinePosition(Duration(milliseconds: (cacheEnd * 1000).toInt()));
      _state = _state.copyWith(buffer: buffer);
      bufferController.add(buffer);
    }

    // Extract seekable-ranges array
    final seekableRanges = cacheState['seekable-ranges'];
    if (seekableRanges is List) {
      final ranges = <BufferRange>[];
      for (final range in seekableRanges) {
        if (range is Map) {
          final start = range['start'] as num?;
          final end = range['end'] as num?;
          if (start != null && end != null) {
            ranges.add(
              BufferRange(
                start: _toTimelinePosition(Duration(milliseconds: (start * 1000).toInt())),
                end: _toTimelinePosition(Duration(milliseconds: (end * 1000).toInt())),
              ),
            );
          }
        }
      }
      _state = _state.copyWith(bufferRanges: ranges);
      bufferRangesController.add(ranges);
    }
  }

  void handlePlayerEvent(String name, Map? data) {
    if (_disposed) return;
    switch (name) {
      case 'end-file':
        setSeekable(false);
        final rawReason = data?['reason'];
        final reason = switch (rawReason) {
          0 => 'eof',
          2 => 'stop',
          3 => 'quit',
          4 => 'error',
          5 => 'redirect',
          final String s => s,
          _ => null,
        };
        if (reason == 'eof') {
          _state = _state.copyWith(completed: true);
          completedController.add(true);
        } else if (reason == 'error') {
          errorController.add(
            PlayerError(data?['message'] as String? ?? 'Playback error', cause: data?['cause'] as String?),
          );
        }
        break;

      case 'file-loaded':
        _state = _state.copyWith(completed: false);
        completedController.add(false);
        fileLoadedController.add(null);
        break;

      case 'playback-restart':
        playbackRestartController.add(null);
        break;

      case 'log-message':
        final prefix = data?['prefix'] as String? ?? '';
        final levelStr = data?['level'] as String? ?? 'info';
        final text = data?['text'] as String? ?? '';
        final level = parseLogLevel(levelStr);
        logController.add(PlayerLog(level: level, prefix: prefix, text: text));
        break;
    }
  }

  PlayerLogLevel parseLogLevel(String level) {
    return switch (level) {
      'fatal' => PlayerLogLevel.fatal,
      'error' => PlayerLogLevel.error,
      'warn' => PlayerLogLevel.warn,
      'info' => PlayerLogLevel.info,
      'v' || 'verbose' => PlayerLogLevel.verbose,
      'debug' => PlayerLogLevel.debug,
      'trace' => PlayerLogLevel.trace,
      _ => PlayerLogLevel.info,
    };
  }

  ({Tracks tracks, String? selectedAudioId, String? selectedSubtitleId}) parseTrackList(List trackList) {
    final audioTracks = <AudioTrack>[];
    final subtitleTracks = <SubtitleTrack>[];
    String? selectedAudioId;
    String? selectedSubtitleId;

    for (final track in trackList) {
      if (track is! Map) continue;

      final type = track['type'] as String?;
      final id = track['id']?.toString() ?? '';
      final selected = track['selected'] as bool? ?? false;

      if (type == 'audio') {
        if (selected) selectedAudioId = id;
        audioTracks.add(
          AudioTrack(
            id: id,
            title: cleanTrackMetadataValue(track['title'] as String?),
            language: cleanTrackMetadataValue(track['lang'] as String?),
            codec: track['codec'] as String?,
            channels: (track['demux-channel-count'] as num?)?.toInt(),
            sampleRate: (track['demux-samplerate'] as num?)?.toInt(),
            isDefault: track['default'] as bool? ?? false,
          ),
        );
      } else if (type == 'sub') {
        if (selected) selectedSubtitleId = id;
        final codec = track['codec'] as String?;
        final externalFilename = track['external-filename'] as String?;
        final externalMetadata = externalFilename == null ? null : _externalSubtitleMetadataByUri[externalFilename];
        subtitleTracks.add(
          SubtitleTrack(
            id: id,
            title: externalMetadata?.title ?? cleanSubtitleTitle(track['title'] as String?, codec: codec),
            language: externalMetadata?.language ?? cleanTrackMetadataValue(track['lang'] as String?),
            codec: externalMetadata?.codec ?? codec,
            isDefault: externalMetadata?.isDefault ?? (track['default'] as bool? ?? false),
            isForced: externalMetadata?.isForced ?? (track['forced'] as bool? ?? false),
            isExternal: track['external'] as bool? ?? false,
            uri: externalFilename,
          ),
        );
      }
    }

    return (
      tracks: Tracks(audio: audioTracks, subtitle: subtitleTracks),
      selectedAudioId: selectedAudioId,
      selectedSubtitleId: selectedSubtitleId,
    );
  }

  void updateSelectedAudioTrack(dynamic trackId) {
    final id = trackId?.toString();
    AudioTrack? selectedTrack;

    if (id != null && id != 'no') {
      selectedTrack = _state.tracks.audio.firstWhereOrNull((t) => t.id == id);
    }

    if (selectedTrack == null) return;
    _state = _state.copyWith(track: _state.track.copyWith(audio: selectedTrack));
    trackController.add(_state.track);
  }

  void updateSelectedSubtitleTrack(dynamic trackId) {
    final id = trackId?.toString();
    final selectedTrack = (id == null || id == 'no')
        ? SubtitleTrack.off
        : _state.tracks.subtitle.firstWhereOrNull((t) => t.id == id);

    if (selectedTrack == null) return;
    _state = _state.copyWith(track: _state.track.copyWith(subtitle: selectedTrack));
    trackController.add(_state.track);
  }

  void updateSelectedSecondarySubtitleTrack(dynamic trackId) {
    final id = trackId?.toString();
    SubtitleTrack? selectedTrack;

    if (id == null || id == 'no') {
      selectedTrack = null;
    } else {
      selectedTrack = _state.tracks.subtitle.firstWhereOrNull((t) => t.id == id);
    }

    _state = _state.copyWith(track: _state.track.copyWith(secondarySubtitle: selectedTrack));
    trackController.add(_state.track);
  }

  @protected
  void clearTracks() {
    const empty = Tracks();
    _state = _state.copyWith(tracks: empty, track: const TrackSelection());
    tracksController.add(empty);
  }

  @protected
  void setExternalSubtitleMetadata(List<SubtitleTrack>? externalSubtitles) {
    final metadataByUri = <String, SubtitleTrack>{};
    for (final subtitle in externalSubtitles ?? const <SubtitleTrack>[]) {
      final uri = subtitle.uri;
      if (uri != null && uri.isNotEmpty) {
        metadataByUri[uri] = subtitle;
      }
    }
    _externalSubtitleMetadataByUri = metadataByUri;
  }

  @protected
  void setVolumeState(double volume) {
    if (_state.volume == volume) return;
    _state = _state.copyWith(volume: volume);
    volumeController.add(volume);
  }

  @protected
  void setSeekable(bool seekable) {
    if (_state.seekable == seekable) return;
    _state = _state.copyWith(seekable: seekable);
    seekableController.add(seekable);
  }

  @protected
  void configureTimeline({Duration offset = Duration.zero, Duration? duration}) {
    _timelineOffset = offset;
    _timelineDuration = duration;
  }

  @protected
  Duration sourceSeekPosition(Duration timelinePosition) {
    final sourcePosition = timelinePosition - _timelineOffset;
    return sourcePosition.isNegative ? Duration.zero : sourcePosition;
  }

  Duration _toTimelinePosition(Duration sourcePosition) {
    return sourcePosition + _timelineOffset;
  }

  @protected
  void resetPlaybackProgress(Duration sourcePosition) {
    final position = _toTimelinePosition(sourcePosition);
    _positionMs = position.inMilliseconds;
    _state = _state.copyWith(
      completed: false,
      position: position,
      duration: _timelineDuration ?? Duration.zero,
      buffer: Duration.zero,
      bufferRanges: const [],
    );
    completedController.add(false);
    positionController.add(position);
    durationController.add(_timelineDuration ?? Duration.zero);
    bufferController.add(Duration.zero);
    bufferRangesController.add(const []);
  }

  @protected
  Future<T?> invoke<T>(String method, [dynamic args]) async {
    if (_disposed) return null;
    return methodChannel.invokeMethod<T>(method, args);
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
  Future<void> setDisplayCriteria(MediaDisplayCriteria? criteria, {int extraDelayMs = 0}) async {}

  @override
  Future<bool> setVisible(bool visible, {bool restoreOnWindowVisible = false}) async {
    if (_disposed) return false;
    try {
      await invoke('setVisible', {'visible': visible, 'restoreOnWindowVisible': restoreOnWindowVisible});
      return true;
    } catch (e) {
      errorController.add(PlayerError('Failed to set visibility: $e'));
      return false;
    }
  }

  @override
  // ignore: no-empty-block - base no-op, overridden by platform subclasses
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
  // ignore: no-empty-block - base no-op, overridden by platform subclasses
  Future<void> clearVideoFrameRate() async {}

  @override
  // ignore: no-empty-block - base no-op, ExoPlayer styles subtitles natively
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
  // ignore: no-empty-block - base no-op, mpv scales via panscan/aspect-override
  Future<void> setBoxFitMode(int mode) async {}

  @override
  // ignore: no-empty-block - base no-op, mpv zooms via the video-zoom property
  Future<void> setVideoZoom(double scale) async {}

  @override
  Future<Map<String, dynamic>> getStats() async => const {};

  @override
  Future<String> runtimePlayerType() async => playerType;

  @override
  Future<bool> requestAudioFocus() async {
    // Default returns true, overridden by Android
    return true;
  }

  @override
  // ignore: no-empty-block - base no-op, overridden by platform subclasses
  Future<void> abandonAudioFocus() async {}

  @override
  // ignore: no-empty-block - base no-op, overridden by platform subclasses
  Future<void> setAudioDevice(AudioDevice device) async {}

  @override
  bool get supportsSecondarySubtitles => true;

  @override
  bool get attachesExternalSubtitlesAtOpen => false;

  @override
  bool get detectsFpsAfterRender => false;

  @override
  bool get needsDecoderRefreshAfterDisplaySwitch => false;

  @override
  bool get providesNativeStats => false;

  @override
  // ignore: no-empty-block - base no-op, overridden by platform subclasses
  Future<void> selectSecondarySubtitleTrack(SubtitleTrack track) async {}

  @override
  // ignore: no-empty-block - base no-op, overridden by platform subclasses
  Future<void> setAudioPassthrough(bool enabled) async {}

  /// mpv loudnorm targeting streaming-style loudness; mirrored by the
  /// Android ExoPlayer effect parameters in AudioNormalizationEffect.kt.
  static const _loudnormFilter = 'loudnorm=I=-14:TP=-3:LRA=4';

  @override
  Future<void> setAudioNormalization(bool enabled) async {
    await setProperty('af', enabled ? _loudnormFilter : '');
  }

  @override
  Future<void> setAudioDownmix({required bool enabled, required int centerBoostDb, required bool normalize}) async {
    if (enabled) {
      // Kodi's mechanism: center coefficient = 10^((-3 + boost)/20); the
      // surround (-3 dB) and LFE (dropped) swresample defaults already match.
      final c = math.pow(10, (-3 + centerBoostDb.clamp(0, 12)) / 20).toStringAsFixed(4);
      // Swresample AVOptions are read once at audio-filter creation, so they
      // must land before audio-channels triggers the chain (re)build.
      await setProperty('audio-swresample-o', 'center_mix_level=$c');
      await setProperty('audio-normalize-downmix', normalize ? 'yes' : 'no');
      // Bounce through auto-safe so boost/normalize changes re-apply while
      // downmix is already active (same-value option sets are no-ops in mpv).
      await setProperty('audio-channels', 'auto-safe');
      await setProperty('audio-channels', 'stereo');
    } else {
      await setProperty('audio-channels', 'auto-safe');
      await setProperty('audio-swresample-o', '');
      await setProperty('audio-normalize-downmix', 'no');
    }
  }

  @override
  // ignore: no-empty-block - base no-op, overridden by platform subclasses
  Future<void> setLogLevel(String level) async {}

  @override
  Future<void> configureSubtitleFonts() async {
    try {
      final fontDir = await SubtitleFontLoader.loadSubtitleFont();
      if (fontDir != null) {
        await setProperty('sub-fonts-dir', fontDir);
        await setProperty('sub-font', SubtitleFontLoader.fontName);
      }
    } catch (e) {
      // Font configuration is not critical - continue without it
      logController.add(
        PlayerLog(prefix: 'fonts', level: PlayerLogLevel.warn, text: 'Failed to configure subtitle fonts: $e'),
      );
    }
  }

  void _setPlaybackPosition(Duration position) {
    _positionMs = position.inMilliseconds;
    _state = _state.copyWith(position: position);
    positionController.add(position);
  }

  /// Run a backend-specific seek call, swallowing the common "not ready" errors
  /// the native channel throws when the engine was torn down mid-seek.
  @protected
  Future<void> runSeek(Duration position, Future<void> Function() seekFn) async {
    if (_disposed) return;

    final previousPosition = Duration(milliseconds: _positionMs);
    _setPlaybackPosition(position);

    void rollbackPosition() {
      // Avoid overwriting a newer native position update if one arrived while
      // the platform seek was in flight.
      if (_positionMs == position.inMilliseconds) {
        _setPlaybackPosition(previousPosition);
      }
    }

    try {
      await seekFn();
    } on PlatformException catch (e) {
      if (e.code == 'COMMAND_FAILED' || e.code == 'NOT_INITIALIZED') {
        rollbackPosition();
        appLogger.w('Seek failed (${e.code}), player not ready');
        return;
      }
      rollbackPosition();
      rethrow;
    } catch (_) {
      rollbackPosition();
      rethrow;
    }
  }

  /// Injects the log + error events that would fire when the server rejects the
  /// stream with HTTP 500 (shared-user bandwidth / transcoding limit). Used by
  /// the in-player debug button to preview the end-to-end detection path
  /// without needing a real misbehaving server.
  void debugSimulateServer500() {
    if (_disposed) return;
    logController.add(
      const PlayerLog(
        level: PlayerLogLevel.warn,
        prefix: 'ffmpeg',
        text: 'https: HTTP error 500 Internal Server Error',
      ),
    );
    errorController.add(const PlayerError('HTTP 500', cause: PlayerError.serverHttp500));
  }

  @override
  Future<void> dispose({bool preserveDisplayMode = false}) async {
    if (_disposed) return;
    _disposed = true;

    if (identical(_eventChannelOwners[eventChannel.name], this)) {
      _eventChannelOwners.remove(eventChannel.name);
      try {
        await _eventSubscription?.cancel();
      } on PlatformException catch (e, st) {
        appLogger.d('Player event stream already detached during dispose', error: e, stackTrace: st);
      } on MissingPluginException catch (e, st) {
        appLogger.d('Player event stream plugin missing during dispose', error: e, stackTrace: st);
      }
    } else {
      // A newer instance owns the channel; cancelling would send a stray
      // native 'cancel' that kills *its* stream. Drop ours without cancelling
      // — the newer listen already replaced this subscription's routing.
      appLogger.d('Player event stream handed off to a newer instance, skipping cancel');
    }
    _eventSubscription = null;
    await _logSubscription?.cancel();
    try {
      await methodChannel.invokeMethod('dispose', {
        'preserveDisplayMode': preserveDisplayMode,
      }); // Direct call — already guarded by _disposed check above
    } on PlatformException catch (e, st) {
      appLogger.w('Player native dispose failed during teardown', error: e, stackTrace: st);
    } on MissingPluginException catch (e, st) {
      appLogger.w('Player native dispose plugin missing during teardown', error: e, stackTrace: st);
    }
    await closeStreamControllers();
  }
}

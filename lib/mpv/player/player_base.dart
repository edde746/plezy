import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier, protected, visibleForTesting;
import 'package:flutter/services.dart';

import '../../media/media_display_criteria.dart';
import '../../utils/app_logger.dart';
import '../../utils/track_label_builder.dart';
import '../font_loader.dart';
import '../models.dart';
import 'mpv_node_decoder.dart';
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

  final ValueNotifier<int?> _textureId = ValueNotifier<int?>(null);

  @override
  int? get textureId => _textureId.value;

  ValueListenable<int?> get textureIdListenable => _textureId;

  @protected
  void setTextureId(int? value) {
    if (!_disposed) _textureId.value = value;
  }

  StreamSubscription? _eventSubscription;
  StreamSubscription? _logSubscription;
  bool _disposed = false;
  late final Future<void>? _nativeOwnershipReady;
  final Completer<void> _nativeRelease = Completer<void>();
  final _throttleSw = Stopwatch()..start();
  int _lastEmitMs = 0;
  int _lastCacheStateMs = 0;
  int _positionMs = 0;
  Duration? _timelineDuration;
  int _nextPropId = 0;
  final Map<int, String> _propIdToName = {};
  Map<String, SubtitleTrack> _externalSubtitleMetadataByUri = const {};
  bool _primaryMediaLoadStarted = false;
  bool _primaryMediaReadyEmitted = false;

  @visibleForTesting
  static Duration debugNativeOwnershipDisposeTimeout = const Duration(seconds: 3);

  static const _maximumDurationMilliseconds = 9223372036854775;

  static double? _finiteDouble(Object? value) {
    if (value is! num) return null;
    final result = value.toDouble();
    return result.isFinite ? result : null;
  }

  static int? _millisecondsFromSeconds(Object? value, {bool round = false}) {
    final seconds = _finiteDouble(value);
    if (seconds == null) return null;
    final milliseconds = seconds * Duration.millisecondsPerSecond;
    if (!milliseconds.isFinite ||
        milliseconds < -_maximumDurationMilliseconds ||
        milliseconds > _maximumDurationMilliseconds) {
      return null;
    }
    return round ? milliseconds.round() : milliseconds.toInt();
  }

  static int? _finiteInt(Object? value) {
    if (value is int) return value;
    final result = _finiteDouble(value);
    if (result == null || result < -9007199254740991 || result > 9007199254740991) return null;
    return result.toInt();
  }

  @protected
  bool initialized = false;

  @override
  bool get disposed => _disposed;

  MethodChannel get methodChannel;

  EventChannel get eventChannel;

  String get logPrefix;

  PlayerBase() {
    _nativeOwnershipReady = _eventChannelOwners[eventChannel.name]?._nativeRelease.future;
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
      final propertyId = event.first;
      if (propertyId is! int) return;
      final name = _propIdToName[propertyId];
      if (name != null) {
        handlePropertyChange(name, event[1]);
      }
    } else if (event is Map) {
      final type = event['type'];
      final name = event['name'];
      if (type == 'event' && name is String) {
        final rawData = event['data'];
        handlePlayerEvent(name, rawData is Map ? rawData : null);
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
        final positionMs = _millisecondsFromSeconds(value, round: true);
        if (positionMs != null) {
          final pos = Duration(milliseconds: positionMs);
          _positionMs = positionMs;
          // Only allocate PlayerState + emit at ~4Hz (250ms). The raw integer
          // remains current for synchronous position reads on every tick.
          final nowMs = _throttleSw.elapsedMilliseconds;
          if (nowMs - _lastEmitMs >= 250) {
            _lastEmitMs = nowMs;
            _state = _state.copyWith(position: pos);
            positionController.add(pos);
          }
        }
        break;

      case 'duration':
        final durationMs = _millisecondsFromSeconds(value);
        if (durationMs != null) {
          final duration = _timelineDuration ?? Duration(milliseconds: durationMs);
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
        final bufferMs = _millisecondsFromSeconds(value);
        if (bufferMs != null) {
          final nowMs = _throttleSw.elapsedMilliseconds;
          if (nowMs - _lastCacheStateMs < 250) break;
          _lastCacheStateMs = nowMs;
          final buffer = Duration(milliseconds: bufferMs);
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
        final volume = _finiteDouble(value);
        if (volume != null) {
          setVolumeState(volume);
        }
        break;

      case 'speed':
        final rate = _finiteDouble(value);
        if (rate != null) {
          _state = _state.copyWith(rate: rate);
          rateController.add(rate);
        }
        break;

      case 'track-list':
        final trackList = MpvNodeDecoder.decodeList(value);
        if (trackList != null) {
          if (_primaryMediaLoadStarted && !_primaryMediaReadyEmitted && _hasPrimaryMediaTrack(trackList)) {
            _primaryMediaReadyEmitted = true;
            primaryMediaReadyController.add(null);
          }
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
        final deviceList = MpvNodeDecoder.decodeList(value);
        if (deviceList != null) {
          final devices = <AudioDevice>[];
          for (final entry in deviceList) {
            if (entry is! Map) continue;
            final name = entry['name'];
            final description = entry['description'];
            if (name is! String) continue;
            devices.add(AudioDevice(name: name, description: description is String ? description : ''));
          }
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
    if (value is String && value.isNotEmpty) {
      // Throttle JSON parsing to avoid ANR on low-end devices
      final nowMs = _throttleSw.elapsedMilliseconds;
      if (nowMs - _lastCacheStateMs < 250) return;
      _lastCacheStateMs = nowMs;
    }
    final cacheState = MpvNodeDecoder.decodeMap(value);
    if (cacheState == null) return;

    // Extract cache-end for the single buffer duration (replaces demuxer-cache-time)
    final cacheEndMs = _millisecondsFromSeconds(cacheState['cache-end']);
    if (cacheEndMs != null) {
      final buffer = Duration(milliseconds: cacheEndMs);
      _state = _state.copyWith(buffer: buffer);
      bufferController.add(buffer);
    }

    // Extract seekable-ranges array
    final seekableRanges = cacheState['seekable-ranges'];
    if (seekableRanges is List) {
      final ranges = <BufferRange>[];
      for (final range in seekableRanges) {
        if (range is! Map) continue;
        final startMs = _millisecondsFromSeconds(range['start']);
        final endMs = _millisecondsFromSeconds(range['end']);
        if (startMs != null && endMs != null) {
          ranges.add(
            BufferRange(
              start: Duration(milliseconds: startMs),
              end: Duration(milliseconds: endMs),
            ),
          );
        }
      }
      _state = _state.copyWith(bufferRanges: ranges);
      bufferRangesController.add(ranges);
    }
  }

  void handlePlayerEvent(String name, Map? data) {
    if (_disposed) return;
    switch (name) {
      case 'start-file':
        _primaryMediaLoadStarted = true;
        _primaryMediaReadyEmitted = false;
        fileStartedController.add(null);
        break;

      case 'end-file':
        _primaryMediaLoadStarted = false;
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
          fileLoadFailedController.add(null);
          final rawMessage = data?['message'];
          final rawCause = data?['cause'];
          errorController.add(
            PlayerError(
              rawMessage is String ? rawMessage : 'Playback error',
              cause: rawCause is String ? rawCause : null,
            ),
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
        final rawPrefix = data?['prefix'];
        final rawLevel = data?['level'];
        final rawText = data?['text'];
        final prefix = rawPrefix is String ? rawPrefix : '';
        final level = parseLogLevel(rawLevel is String ? rawLevel : 'info');
        final text = rawText is String ? rawText : '';
        logController.add(PlayerLog(level: level, prefix: prefix, text: text));
        break;
    }
  }

  bool _hasPrimaryMediaTrack(List trackList) {
    for (final track in trackList) {
      if (track is! Map || track['external'] == true) continue;
      final type = track['type'];
      if (type == 'audio') return true;
      // mpv exposes embedded/external cover art as a video track. It is not
      // evidence that the primary audio file has finished discovery, so it
      // must not start the external-sidecar timeout on its own.
      if (type == 'video' && track['albumart'] != true) return true;
    }
    return false;
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

      final rawType = track['type'];
      if (rawType is! String) continue;
      final type = rawType;
      final rawId = track['id'];
      final id = rawId is String || rawId is num ? rawId.toString() : '';
      final selected = track['selected'] == true;

      if (type == 'audio') {
        if (selected) selectedAudioId = id;
        audioTracks.add(
          AudioTrack(
            id: id,
            title: cleanTrackMetadataValue(track['title'] is String ? track['title'] as String : null),
            language: cleanTrackMetadataValue(track['lang'] is String ? track['lang'] as String : null),
            codec: track['codec'] is String ? track['codec'] as String : null,
            channels: _finiteInt(track['demux-channel-count']),
            sampleRate: _finiteInt(track['demux-samplerate']),
            isDefault: track['default'] == true,
          ),
        );
      } else if (type == 'sub') {
        if (selected) selectedSubtitleId = id;
        final rawCodec = track['codec'];
        final codec = rawCodec is String ? rawCodec : null;
        final rawExternalFilename = track['external-filename'];
        final externalFilename = rawExternalFilename is String ? rawExternalFilename : null;
        final externalMetadata = externalFilename == null ? null : _externalSubtitleMetadataByUri[externalFilename];
        final rawTitle = track['title'];
        final rawLanguage = track['lang'];
        subtitleTracks.add(
          SubtitleTrack(
            id: id,
            title: externalMetadata?.title ?? cleanSubtitleTitle(rawTitle is String ? rawTitle : null, codec: codec),
            language: externalMetadata?.language ?? cleanTrackMetadataValue(rawLanguage is String ? rawLanguage : null),
            codec: externalMetadata?.codec ?? codec,
            isDefault: externalMetadata?.isDefault ?? (track['default'] == true),
            isForced: externalMetadata?.isForced ?? (track['forced'] == true),
            isExternal: track['external'] == true,
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
    final selectedTrack = (id == null || id == 'no')
        ? null
        : _state.tracks.audio.firstWhereOrNull((track) => track.id == id);
    if (id != null && id != 'no' && selectedTrack == null) return;

    _state = _state.copyWith(track: _state.track.copyWith(audio: selectedTrack));
    trackController.add(_state.track);
  }

  void updateSelectedSubtitleTrack(dynamic trackId) {
    final id = trackId?.toString();
    final selectedTrack = (id == null || id == 'no')
        ? SubtitleTrack.off
        : _state.tracks.subtitle.firstWhereOrNull((track) => track.id == id);

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
  Map<String, SubtitleTrack> snapshotExternalSubtitleMetadata() =>
      Map<String, SubtitleTrack>.of(_externalSubtitleMetadataByUri);

  @protected
  void restoreExternalSubtitleMetadata(Map<String, SubtitleTrack> snapshot) {
    _externalSubtitleMetadataByUri = Map<String, SubtitleTrack>.of(snapshot);
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
  void configureTimeline({Duration? duration}) {
    _timelineDuration = duration;
  }

  @protected
  Duration? get configuredTimelineDuration => _timelineDuration;

  @protected
  void resetPlaybackProgress(Duration sourcePosition) {
    final position = sourcePosition;
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
  void restoreTracks(PlayerState snapshot) {
    _state = _state.copyWith(tracks: snapshot.tracks, track: snapshot.track);
    tracksController.add(snapshot.tracks);
    trackController.add(snapshot.track);
  }

  @protected
  void restorePlaybackProgress(PlayerState snapshot, {Duration? position}) {
    final restoredPosition = position ?? snapshot.position;
    _positionMs = restoredPosition.inMilliseconds;
    _state = _state.copyWith(
      completed: snapshot.completed,
      position: restoredPosition,
      duration: snapshot.duration,
      buffer: snapshot.buffer,
      bufferRanges: snapshot.bufferRanges,
    );
    completedController.add(snapshot.completed);
    positionController.add(restoredPosition);
    durationController.add(snapshot.duration);
    bufferController.add(snapshot.buffer);
    bufferRangesController.add(snapshot.bufferRanges);
  }

  @protected
  Future<T?> invoke<T>(String method, [dynamic args]) async {
    if (_disposed) return null;
    if (_nativeOwnershipReady case final ready?) {
      try {
        await ready.timeout(debugNativeOwnershipDisposeTimeout);
      } on TimeoutException {
        return null;
      }
    }
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

  Future<bool> _waitForNativeOwnershipForDispose() async {
    final ready = _nativeOwnershipReady;
    if (ready == null) return true;
    try {
      await ready.timeout(debugNativeOwnershipDisposeTimeout);
      return true;
    } on TimeoutException catch (error, stackTrace) {
      appLogger.w(
        'Timed out waiting for the previous player to release the native channel; skipping native dispose',
        error: error,
        stackTrace: stackTrace,
      );
      if (!_nativeRelease.isCompleted) _nativeRelease.complete(ready);
      return false;
    }
  }

  @override
  Future<void> dispose({bool preserveDisplayMode = false}) async {
    if (_disposed) return;
    _disposed = true;
    _textureId.value = null;

    final channelName = eventChannel.name;
    if (identical(_eventChannelOwners[channelName], this)) {
      // Keep this owner registered while its native release is pending so a
      // player created during disposal inherits the complete release chain.
      // The newer listen cannot interleave before cancel() is invoked on this
      // isolate; after the first await, ownership is checked again at removal.
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
    final ownsNativeChannel = await _waitForNativeOwnershipForDispose();
    try {
      if (ownsNativeChannel) {
        await methodChannel.invokeMethod('dispose', {
          'preserveDisplayMode': preserveDisplayMode,
        }); // Direct call — invoke() is disabled once _disposed is set.
      }
    } on PlatformException catch (e, st) {
      appLogger.w('Player native dispose failed during teardown', error: e, stackTrace: st);
    } on MissingPluginException catch (e, st) {
      appLogger.w('Player native dispose plugin missing during teardown', error: e, stackTrace: st);
    } finally {
      if (ownsNativeChannel && !_nativeRelease.isCompleted) _nativeRelease.complete();
    }

    // A timed-out predecessor is still represented by this release future.
    // Do not expose an empty ownership slot until that chained release settles.
    if (_nativeRelease.isCompleted) {
      unawaited(
        _nativeRelease.future.whenComplete(() {
          if (identical(_eventChannelOwners[channelName], this)) {
            _eventChannelOwners.remove(channelName);
          }
        }),
      );
    }
    await closeStreamControllers();
    _textureId.dispose();
  }
}

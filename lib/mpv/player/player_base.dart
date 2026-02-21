import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show protected;
import 'package:flutter/services.dart';

import '../../utils/app_logger.dart';
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
  int _positionMs = 0;
  int _nextPropId = 0;
  final Map<int, String> _propIdToName = {};

  /// Whether the player has been initialized.
  /// Subclasses should set this to true after initialization.
  @protected
  bool initialized = false;

  /// Whether the player has been disposed.
  bool get disposed => _disposed;

  /// The method channel for platform communication.
  MethodChannel get methodChannel;

  /// The event channel for receiving platform events.
  EventChannel get eventChannel;

  /// The log prefix for this player (e.g., 'MPV', 'ExoPlayer').
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

  void _setupEventListener() {
    _eventSubscription = eventChannel.receiveBroadcastStream().listen(
      _handleEvent,
      onError: (error) {
        if (_disposed) return;
        errorController.add(error.toString());
      },
    );
  }

  /// Observes a property on the native player and assigns it a compact propId
  /// for efficient event channel communication.
  @protected
  Future<void> observeProperty(String name, String format) async {
    final propId = _nextPropId++;
    _propIdToName[propId] = name;
    await methodChannel.invokeMethod('observeProperty', {
      'name': name,
      'format': format,
      'id': propId,
    });
  }

  void _handleEvent(dynamic event) {
    if (_disposed) return;
    if (event is List && event.length == 2) {
      final name = _propIdToName[event[0] as int];
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

  /// Handle a property change event from the platform.
  /// Subclasses can override this to handle platform-specific properties.
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
          _positionMs = (value * 1000).round();
          // Only allocate Duration + copyWith + emit at ~4Hz (250ms).
          // Raw int is stored every tick so synchronous reads via _positionMs stay current.
          final nowMs = _throttleSw.elapsedMilliseconds;
          if (nowMs - _lastEmitMs >= 250) {
            _lastEmitMs = nowMs;
            final pos = Duration(milliseconds: _positionMs);
            _state = _state.copyWith(position: pos);
            positionController.add(pos);
          }
        }
        break;

      case 'duration':
        if (value is num) {
          final duration = Duration(milliseconds: (value * 1000).toInt());
          _state = _state.copyWith(duration: duration);
          durationController.add(duration);
        }
        break;

      case 'demuxer-cache-time':
        if (value is num) {
          final buffer = Duration(milliseconds: (value * 1000).toInt());
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
          final volume = value.toDouble();
          _state = _state.copyWith(volume: volume);
          volumeController.add(volume);
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
          } catch (_) {
            // Ignore parse errors
          }
        }
        if (trackList != null) {
          final tracks = parseTrackList(trackList);
          _state = _state.copyWith(tracks: tracks);
          tracksController.add(tracks);
        }
        break;

      case 'aid':
        updateSelectedAudioTrack(value);
        break;

      case 'sid':
        updateSelectedSubtitleTrack(value);
        break;

      case 'audio-device-list':
        List? deviceList;
        if (value is List) {
          deviceList = value;
        } else if (value is String && value.isNotEmpty) {
          try {
            final parsed = jsonDecode(value);
            if (parsed is List) deviceList = parsed;
          } catch (_) {}
        }
        if (deviceList != null) {
          final devices = deviceList
              .whereType<Map>()
              .map((d) => AudioDevice(
                    name: d['name'] as String? ?? '',
                    description: d['description'] as String? ?? '',
                  ))
              .toList();
          _state = _state.copyWith(audioDevices: devices);
          audioDevicesController.add(devices);
        }
        break;

      case 'audio-device':
        if (value is String && value.isNotEmpty) {
          final device = _state.audioDevices.cast<AudioDevice?>().firstWhere(
                (d) => d?.name == value,
                orElse: () => AudioDevice(name: value),
              ) ??
              AudioDevice(name: value);
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
      try {
        final parsed = jsonDecode(value);
        if (parsed is Map) cacheState = parsed;
      } catch (_) {}
    }
    if (cacheState == null) return;

    // Extract cache-end for the single buffer duration (replaces demuxer-cache-time)
    final cacheEnd = cacheState['cache-end'] as num?;
    if (cacheEnd != null) {
      final buffer = Duration(milliseconds: (cacheEnd * 1000).toInt());
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
            ranges.add(BufferRange(
              start: Duration(milliseconds: (start * 1000).toInt()),
              end: Duration(milliseconds: (end * 1000).toInt()),
            ));
          }
        }
      }
      _state = _state.copyWith(bufferRanges: ranges);
      bufferRangesController.add(ranges);
    }
  }

  /// Handle a player event from the platform.
  /// Subclasses can override this to handle platform-specific events.
  void handlePlayerEvent(String name, Map? data) {
    if (_disposed) return;
    switch (name) {
      case 'end-file':
        final reason = data?['reason'] as String?;
        if (reason == 'eof') {
          _state = _state.copyWith(completed: true);
          completedController.add(true);
        } else if (reason == 'error') {
          errorController.add(data?['message'] as String? ?? 'Playback error');
        }
        break;

      case 'file-loaded':
        _state = _state.copyWith(completed: false);
        completedController.add(false);
        break;

      case 'playback-restart':
        // Clear stale buffer ranges from before the seek; fresh ones will
        // arrive shortly via the next demuxer-cache-state update.
        _state = _state.copyWith(bufferRanges: const []);
        bufferRangesController.add(const []);
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

  /// Parse a log level string to [PlayerLogLevel].
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

  /// Parse a track list from the platform into [Tracks].
  Tracks parseTrackList(List trackList) {
    final audioTracks = <AudioTrack>[];
    final subtitleTracks = <SubtitleTrack>[];

    for (final track in trackList) {
      if (track is! Map) continue;

      final type = track['type'] as String?;
      final id = track['id']?.toString() ?? '';

      if (type == 'audio') {
        audioTracks.add(
          AudioTrack(
            id: id,
            title: track['title'] as String?,
            language: track['lang'] as String?,
            codec: track['codec'] as String?,
            channels: (track['demux-channel-count'] as num?)?.toInt(),
            sampleRate: (track['demux-samplerate'] as num?)?.toInt(),
            isDefault: track['default'] as bool? ?? false,
          ),
        );
      } else if (type == 'sub') {
        subtitleTracks.add(
          SubtitleTrack(
            id: id,
            title: track['title'] as String?,
            language: track['lang'] as String?,
            codec: track['codec'] as String?,
            isExternal: track['external'] as bool? ?? false,
            uri: track['external-filename'] as String?,
          ),
        );
      }
    }

    return Tracks(audio: audioTracks, subtitle: subtitleTracks);
  }

  /// Update the selected audio track.
  void updateSelectedAudioTrack(dynamic trackId) {
    final id = trackId?.toString();
    AudioTrack? selectedTrack;

    if (id != null && id != 'no') {
      selectedTrack = _state.tracks.audio.cast<AudioTrack?>().firstWhere((t) => t?.id == id, orElse: () => null);
    }

    _state = _state.copyWith(track: _state.track.copyWith(audio: selectedTrack));
    trackController.add(_state.track);
  }

  /// Update the selected subtitle track.
  void updateSelectedSubtitleTrack(dynamic trackId) {
    final id = trackId?.toString();
    SubtitleTrack? selectedTrack;

    selectedTrack = (id == null || id == 'no')
        ? SubtitleTrack.off
        : _state.tracks.subtitle.cast<SubtitleTrack?>().firstWhere((t) => t?.id == id, orElse: () => null);

    _state = _state.copyWith(track: _state.track.copyWith(subtitle: selectedTrack));
    trackController.add(_state.track);
  }

  /// Update the internal state.
  void updateState(PlayerState Function(PlayerState) update) {
    _state = update(_state);
  }

  /// Throws if the player has been disposed.
  void checkDisposed() {
    if (_disposed) {
      throw StateError('Player has been disposed');
    }
  }

  // ============================================
  // Default Implementations
  // ============================================

  @override
  Future<void> playOrPause() async {
    checkDisposed();
    if (_state.playing) {
      await pause();
    } else {
      await play();
    }
  }

  @override
  Future<bool> setVisible(bool visible) async {
    checkDisposed();
    try {
      await methodChannel.invokeMethod('setVisible', {'visible': visible});
      return true;
    } catch (e) {
      errorController.add('Failed to set visibility: $e');
      return false;
    }
  }

  @override
  // ignore: no-empty-block - base no-op, overridden by platform subclasses
  Future<void> updateFrame() async {}

  @override
  // ignore: no-empty-block - base no-op, overridden by platform subclasses
  Future<void> setVideoFrameRate(double fps, int durationMs) async {}

  @override
  // ignore: no-empty-block - base no-op, overridden by platform subclasses
  Future<void> clearVideoFrameRate() async {}

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
  // ignore: no-empty-block - base no-op, overridden by platform subclasses
  Future<void> setAudioPassthrough(bool enabled) async {}

  @override
  // ignore: no-empty-block - base no-op, overridden by platform subclasses
  Future<void> setLogLevel(String level) async {}

  // ============================================
  // Lifecycle
  // ============================================

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    await _eventSubscription?.cancel();
    await _logSubscription?.cancel();
    await methodChannel.invokeMethod('dispose');
    await closeStreamControllers();
  }
}

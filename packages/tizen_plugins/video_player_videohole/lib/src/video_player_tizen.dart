// Copyright 2023 Samsung Electronics Co., Ltd. All rights reserved.
// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:isolate' show RawReceivePort;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:tizen_window_manager/tizen_window_manager.dart';

import '../video_player_platform_interface.dart';
import 'ffi_messages.dart';
import 'tracks.dart';

class _SeekOperation {
  _SeekOperation({required this.position, required this.completers});

  Duration position;
  final List<Completer<void>> completers;
}

/// An implementation of [VideoPlayerPlatform] that uses FFI for all methods.
class VideoPlayerTizen extends VideoPlayerPlatform {
  /// Create a new VideoPlayerTizen instance.
  VideoPlayerTizen() : super();

  final VideoPlayerVideoholeFFIApi _ffiApi = VideoPlayerVideoholeFFIApi();

  /// Fetches the window geometry via the tizen_window_manager plugin.
  ///
  /// Returns null if the geometry is not available.
  Future<Map<Object?, Object?>?> _getWindowGeometry() async {
    try {
      final Map<String, int> geometry = await WindowManager.getGeometry();
      return Map<Object?, Object?>.from(geometry);
    } on Exception {
      return null;
    }
  }

  @override
  Future<void> init() async {
    final int result = _ffiApi.initialize();
    if (result != 0) {
      throw PlatformException(
        code: 'FFI_INITIALIZE_FAILED',
        message: 'FFI initialize failed with code: $result',
      );
    }
  }

  @override
  Future<void> dispose(int playerId) async {
    _completeSeeksWithError(
      playerId,
      PlatformException(
        code: 'FFI_SEEK_TO_CANCELLED',
        message: 'seekTo was cancelled because player $playerId was disposed',
      ),
    );

    final StreamController<VideoEvent>? controller = _eventControllers.remove(
      playerId,
    );
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }

    _ffiApi.dispose(playerId);
  }

  @override
  Future<int?> create(DataSource dataSource) async {
    _ensureEventPortRegistered();

    final message = CreateMessage();

    switch (dataSource.sourceType) {
      case DataSourceType.asset:
        message.asset = dataSource.asset;
        message.packageName = dataSource.package;
      case DataSourceType.network:
        message.uri = dataSource.uri;
        message.formatHint = _videoFormatStringMap[dataSource.formatHint];
        message.httpHeaders = dataSource.httpHeaders;
        message.drmConfigs = dataSource.drmConfigs?.toMap();
        message.playerOptions = dataSource.playerOptions;
      case DataSourceType.file:
      case DataSourceType.contentUri:
        message.uri = dataSource.uri;
    }

    message.windowGeometry = await _getWindowGeometry();

    final int playerId = _ffiApi.create(message);

    if (playerId < 0) {
      throw PlatformException(
        code: 'FFI_CREATE_FAILED',
        message: 'FFI create failed with code: $playerId',
      );
    }

    return playerId;
  }

  @override
  Future<void> prepare(int playerId) async {
    final int result = _ffiApi.prepare(playerId);
    if (result < 0) {
      throw PlatformException(
        code: 'FFI_PREPARE_FAILED',
        message: 'FFI prepare failed with code: $result',
      );
    }
  }

  void _ensureEventPortRegistered() {
    if (_eventPort == null) {
      ffiInitializeApiDL();

      _eventPort = RawReceivePort();

      _eventPort!.handler = (dynamic message) {
        try {
          if (message is List && message.length == 2) {
            final receivingPlayerId = message[0] as int;
            final eventJson = message[1] as String;

            final eventMap = jsonDecode(eventJson) as Map<String, dynamic>;

            if (eventMap['event'] == 'seekCompleted') {
              _handleSeekCompleted(receivingPlayerId);
              return;
            }

            // Borrowed from the map; dispose(playerId) owns and closes it.
            // ignore: close_sinks
            final StreamController<VideoEvent>? controller = _eventControllers[receivingPlayerId];

            if (eventMap['event'] == 'error') {
              final exception = PlatformException(
                code: eventMap['code'] as String? ?? 'unknown',
                message: eventMap['message'] as String?,
              );

              _completeSeeksWithError(receivingPlayerId, exception);

              if (controller != null && !controller.isClosed) {
                controller.addError(exception);
              }
              return;
            }

            if (controller != null && !controller.isClosed) {
              final VideoEvent videoEvent = _parseVideoEventFromMap(eventMap);
              controller.add(videoEvent);
            }
          }
        } catch (e, stackTrace) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: PlatformException(
                code: 'FFI_EVENT_PROCESSING_FAILED',
                message: 'Failed to process FFI event',
              ),
              stack: stackTrace,
            ),
          );
        }
      };

      ffiRegisterEventPort(_eventPort!.nativePort);
    }
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {
    final int result = _ffiApi.setLooping(playerId, looping);
    if (result != 0) {
      throw PlatformException(
        code: 'FFI_SET_LOOPING_FAILED',
        message: 'FFI setLooping failed with code: $result',
      );
    }
  }

  @override
  Future<void> play(int playerId) async {
    final int result = _ffiApi.play(playerId);
    if (result != 0) {
      throw PlatformException(
        code: 'FFI_PLAY_FAILED',
        message: 'FFI play failed with code: $result',
      );
    }
  }

  @override
  Future<bool> setActivate(int playerId) async {
    final int result = _ffiApi.setActivate(playerId);
    if (result != 0) {
      throw PlatformException(
        code: 'FFI_SET_ACTIVATE_FAILED',
        message: 'FFI setActivate failed with code: $result',
      );
    }
    return true;
  }

  @override
  Future<bool> setDeactivate(int playerId) async {
    final int result = _ffiApi.setDeactivate(playerId);
    if (result != 0) {
      throw PlatformException(
        code: 'FFI_SET_DEACTIVATE_FAILED',
        message: 'FFI setDeactivate failed with code: $result',
      );
    }
    return true;
  }

  @override
  Future<void> pause(int playerId) async {
    final int result = _ffiApi.pause(playerId);
    if (result != 0) {
      throw PlatformException(
        code: 'FFI_PAUSE_FAILED',
        message: 'FFI pause failed with code: $result',
      );
    }
  }

  @override
  Future<void> setVolume(int playerId, double volume) async {
    final int result = _ffiApi.setVolume(playerId, volume);
    if (result != 0) {
      throw PlatformException(
        code: 'FFI_SET_VOLUME_FAILED',
        message: 'FFI setVolume failed with code: $result',
      );
    }
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {
    assert(speed > 0);
    final int result = _ffiApi.setPlaybackSpeed(playerId, speed);
    if (result != 0) {
      throw PlatformException(
        code: 'FFI_SET_PLAYBACK_SPEED_FAILED',
        message: 'FFI setPlaybackSpeed failed with code: $result',
      );
    }
  }

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    _ensureEventPortRegistered();

    final completer = Completer<void>();

    if (_activeSeeks.containsKey(playerId)) {
      final _SeekOperation pendingSeek = _pendingSeeks.putIfAbsent(
        playerId,
        () => _SeekOperation(position: position, completers: <Completer<void>>[]),
      );
      pendingSeek.position = position;
      pendingSeek.completers.add(completer);
      return completer.future;
    }

    _startSeek(playerId, position, <Completer<void>>[completer]);
    return completer.future;
  }

  @override
  Future<List<VideoTrack>> getVideoTracks(int playerId) async {
    final TrackMessage message = _ffiApi.getTrackInfo(playerId, 'video');

    final videoTracks = <VideoTrack>[];
    for (final Map<Object?, Object?>? trackMap in message.tracks) {
      final trackId = trackMap!['trackId']! as int;
      final bitrate = trackMap['bitrate']! as int;
      final width = trackMap['width']! as int;
      final height = trackMap['height']! as int;

      videoTracks.add(
        VideoTrack(
          trackId: trackId,
          width: width,
          height: height,
          bitrate: bitrate,
        ),
      );
    }

    return videoTracks;
  }

  @override
  Future<List<AudioTrack>> getAudioTracks(int playerId) async {
    final TrackMessage message = _ffiApi.getTrackInfo(playerId, 'audio');

    final audioTracks = <AudioTrack>[];
    for (final Map<Object?, Object?>? trackMap in message.tracks) {
      final trackId = trackMap!['trackId']! as int;
      final language = trackMap['language']! as String;
      final channel = trackMap['channel']! as int;
      final bitrate = trackMap['bitrate']! as int;

      audioTracks.add(
        AudioTrack(
          trackId: trackId,
          language: language,
          channel: channel,
          bitrate: bitrate,
        ),
      );
    }

    return audioTracks;
  }

  @override
  Future<List<TextTrack>> getTextTracks(int playerId) async {
    final TrackMessage message = _ffiApi.getTrackInfo(playerId, 'text');

    final textTracks = <TextTrack>[];
    for (final Map<Object?, Object?>? trackMap in message.tracks) {
      final trackId = trackMap!['trackId']! as int;
      final language = trackMap['language']! as String;

      textTracks.add(TextTrack(trackId: trackId, language: language));
    }

    return textTracks;
  }

  @override
  Future<bool> setTrackSelection(int playerId, Track track) async {
    final int result = _ffiApi.setTrackSelection(
      playerId,
      track.trackId,
      track.trackType.name,
    );
    if (result != 0) {
      throw PlatformException(
        code: 'FFI_SET_TRACK_SELECTION_FAILED',
        message: 'FFI setTrackSelection failed with code: $result',
      );
    }
    return true;
  }

  @override
  Future<DurationRange> getDuration(int playerId) async {
    final DurationMessage message = _ffiApi.duration(playerId);
    return DurationRange(
      Duration(milliseconds: message.durationRange?[0] ?? 0),
      Duration(milliseconds: message.durationRange?[1] ?? 0),
    );
  }

  @override
  Future<Duration> getPosition(int playerId) async {
    final int positionMs = _ffiApi.getPosition(playerId);
    if (positionMs < 0) {
      throw PlatformException(
        code: 'FFI_GET_POSITION_FAILED',
        message: 'FFI getPosition failed with code: $positionMs',
      );
    }
    return Duration(milliseconds: positionMs);
  }

  RawReceivePort? _eventPort;

  final Map<int, StreamController<VideoEvent>> _eventControllers =
      <int, StreamController<VideoEvent>>{};

  final Map<int, _SeekOperation> _activeSeeks = <int, _SeekOperation>{};
  final Map<int, _SeekOperation> _pendingSeeks = <int, _SeekOperation>{};

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    _ensureEventPortRegistered();

    return _eventControllers
        .putIfAbsent(playerId, () => StreamController<VideoEvent>.broadcast())
        .stream;
  }

  VideoEvent _parseVideoEventFromMap(Map<String, dynamic> map) {
    switch (map['event']) {
      case 'initialized':
      case 'restored':
        final durationVal = map['duration'] as List<dynamic>?;
        VideoEventType videoEventType;
        if (map['event'] == 'initialized') {
          videoEventType = VideoEventType.initialized;
        } else {
          videoEventType = VideoEventType.restored;
        }
        return VideoEvent(
          eventType: videoEventType,
          duration: DurationRange(
            Duration(milliseconds: durationVal?[0] as int? ?? 0),
            Duration(milliseconds: durationVal?[1] as int? ?? 0),
          ),
          size: Size(
            (map['width'] as num?)?.toDouble() ?? 0.0,
            (map['height'] as num?)?.toDouble() ?? 0.0,
          ),
        );
      case 'completed':
        return VideoEvent(eventType: VideoEventType.completed);
      case 'bufferingUpdate':
        final value = map['value']! as int;
        return VideoEvent(
          buffered: value,
          eventType: VideoEventType.bufferingUpdate,
        );
      case 'bufferingStart':
        return VideoEvent(eventType: VideoEventType.bufferingStart);
      case 'bufferingEnd':
        return VideoEvent(eventType: VideoEventType.bufferingEnd);
      case 'subtitleUpdate':
        return VideoEvent(
          eventType: VideoEventType.subtitleUpdate,
          text: map['text']! as String,
        );
      case 'isPlayingStateUpdate':
        return VideoEvent(
          eventType: VideoEventType.isPlayingStateUpdate,
          isPlaying: map['isPlaying']! as bool,
        );
      default:
        return VideoEvent(eventType: VideoEventType.unknown);
    }
  }

  @override
  Widget buildView(int playerId) {
    return Texture(textureId: playerId);
  }

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {
    final int result = _ffiApi.setMixWithOthers(mixWithOthers);
    if (result != 0) {
      throw PlatformException(
        code: 'FFI_SET_MIX_WITH_OTHERS_FAILED',
        message: 'FFI setMixWithOthers failed with code: $result',
      );
    }
  }

  @override
  Future<void> setDisplayGeometry(
    int playerId,
    int x,
    int y,
    int width,
    int height,
  ) async {
    final int result = _ffiApi.setDisplayGeometry(
      playerId,
      x,
      y,
      width,
      height,
    );
    if (result != 0) {
      throw PlatformException(
        code: 'FFI_SET_DISPLAY_GEOMETRY_FAILED',
        message: 'FFI setDisplayGeometry failed with code: $result',
      );
    }
  }

  @override
  Future<void> suspend(int playerId) async {
    final int result = _ffiApi.suspend(playerId);
    if (result != 0) {
      throw PlatformException(
        code: 'FFI_SUSPEND_FAILED',
        message: 'FFI suspend failed with code: $result',
      );
    }
  }

  @override
  Future<void> restore(
    int playerId, {
    DataSource? dataSource,
    int resumeTime = -1,
  }) async {
    CreateMessage? message;
    if (dataSource != null) {
      message = CreateMessage();

      switch (dataSource.sourceType) {
        case DataSourceType.asset:
          message.asset = dataSource.asset;
          message.packageName = dataSource.package;
        case DataSourceType.network:
          message.uri = dataSource.uri;
          message.formatHint = _videoFormatStringMap[dataSource.formatHint];
          message.httpHeaders = dataSource.httpHeaders;
          message.drmConfigs = dataSource.drmConfigs?.toMap();
          message.playerOptions = dataSource.playerOptions;
        case DataSourceType.file:
        case DataSourceType.contentUri:
          message.uri = dataSource.uri;
      }
    }
    message?.windowGeometry = await _getWindowGeometry();

    final int result = _ffiApi.restore(playerId, message, resumeTime);
    if (result != 0) {
      throw PlatformException(
        code: 'FFI_RESTORE_FAILED',
        message: 'FFI restore failed with code: $result',
      );
    }
  }

  @override
  Future<bool> setDisplayRotate(int playerId, DisplayRotation rotation) async {
    final int result = _ffiApi.setDisplayRotate(playerId, rotation.index);
    if (result != 0) {
      throw PlatformException(
        code: 'FFI_SET_DISPLAY_ROTATE_FAILED',
        message: 'FFI setDisplayRotate failed with code: $result',
      );
    }
    return true;
  }

  void _startSeek(
    int playerId,
    Duration position,
    List<Completer<void>> completers,
  ) {
    final seek = _SeekOperation(
      position: position,
      completers: completers,
    );

    _activeSeeks[playerId] = seek;

    try {
      final int result = _ffiApi.seekTo(playerId, position.inMilliseconds);
      if (result != 0) {
        if (identical(_activeSeeks[playerId], seek)) {
          _activeSeeks.remove(playerId);
        }

        _completeSeekWithError(
          seek,
          PlatformException(
            code: 'FFI_SEEK_TO_FAILED',
            message: 'FFI seekTo failed with code: $result',
          ),
        );

        _startPendingSeekIfAny(playerId);
        return;
      }
    } catch (e, stackTrace) {
      if (identical(_activeSeeks[playerId], seek)) {
        _activeSeeks.remove(playerId);
      }

      _completeSeekWithError(
        seek,
        e is PlatformException
            ? e
            : PlatformException(
                code: 'FFI_SEEK_TO_FAILED',
                message: 'FFI seekTo failed',
                details: e.toString(),
              ),
        stackTrace,
      );

      _startPendingSeekIfAny(playerId);
    }
  }

  void _handleSeekCompleted(int playerId) {
    final _SeekOperation? completedSeek = _activeSeeks.remove(playerId);
    if (completedSeek == null) {
      return;
    }

    _completeSeek(completedSeek);
    _startPendingSeekIfAny(playerId);
  }

  void _completeSeek(_SeekOperation seek) {
    for (final Completer<void> completer in seek.completers) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  void _completeSeekWithError(
    _SeekOperation seek,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    for (final Completer<void> completer in seek.completers) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    }
  }

  void _completeSeeksWithError(
    int playerId,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    final _SeekOperation? activeSeek = _activeSeeks.remove(playerId);
    if (activeSeek != null) {
      _completeSeekWithError(activeSeek, error, stackTrace);
    }

    final _SeekOperation? pendingSeek = _pendingSeeks.remove(playerId);
    if (pendingSeek != null) {
      _completeSeekWithError(pendingSeek, error, stackTrace);
    }
  }

  void _startPendingSeekIfAny(int playerId) {
    if (_activeSeeks.containsKey(playerId)) {
      return;
    }

    final _SeekOperation? pendingSeek = _pendingSeeks.remove(playerId);
    if (pendingSeek != null) {
      _startSeek(playerId, pendingSeek.position, pendingSeek.completers);
    }
  }

  static const Map<VideoFormat, String> _videoFormatStringMap = <VideoFormat, String>{
    VideoFormat.ss: 'ss',
    VideoFormat.hls: 'hls',
    VideoFormat.dash: 'dash',
    VideoFormat.other: 'other',
  };
}

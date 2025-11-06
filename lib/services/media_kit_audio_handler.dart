import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:media_kit/media_kit.dart';
import '../models/plex_metadata.dart';
import '../utils/app_logger.dart';

/// AudioHandler that bridges media_kit Player with OS media controls
class MediaKitAudioHandler extends BaseAudioHandler with SeekHandler {
  Player? _player;
  VoidCallback? _onNext;
  VoidCallback? _onPrevious;

  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<bool>? _completedSubscription;

  MediaKitAudioHandler({
    required Player? player,
    VoidCallback? onNext,
    VoidCallback? onPrevious,
  })  : _player = player,
        _onNext = onNext,
        _onPrevious = onPrevious {
    if (_player != null) {
      _initializeListeners();
    }
  }

  void _initializeListeners() {
    if (_player == null) return;

    _playingSubscription = _player!.stream.playing.listen((_) {
      _broadcastState();
    });

    _positionSubscription = _player!.stream.position.listen((_) {
      _broadcastState();
    });

    _completedSubscription = _player!.stream.completed.listen((completed) {
      if (completed) {
        _broadcastState();
      }
    });

    _broadcastState();
  }

  /// Update the player reference and callbacks (for video changes)
  Future<void> updatePlayer({
    required Player? player,
    VoidCallback? onNext,
    VoidCallback? onPrevious,
  }) async {
    await _cleanupSubscriptions();

    // Update player and callbacks
    _player = player;
    _onNext = onNext;
    _onPrevious = onPrevious;

    // Set up new subscriptions if player is not null
    if (_player != null) {
      _initializeListeners();
    } else {
      // No player, broadcast idle state
      _broadcastIdleState();
    }
  }

  /// Clean up current subscriptions
  Future<void> _cleanupSubscriptions() async {
    await _playingSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _completedSubscription?.cancel();
    _playingSubscription = null;
    _positionSubscription = null;
    _completedSubscription = null;
  }

  void _broadcastState() {
    if (_player == null || mediaItem.value == null) {
      if (_player == null) {
        _broadcastIdleState();
      }
      return;
    }

    final playing = _player!.state.playing;
    final position = _player!.state.position;
    final duration = _player!.state.duration;
    final rate = _player!.state.rate;

    // Determine processing state
    AudioProcessingState processingState;
    if (_player!.state.completed) {
      processingState = AudioProcessingState.completed;
    } else if (duration.inMilliseconds > 0) {
      processingState = AudioProcessingState.ready;
    } else {
      processingState = AudioProcessingState.loading;
    }

    // Build control list
    final controls = <MediaControl>[
      if (_onPrevious != null) MediaControl.skipToPrevious,
      playing ? MediaControl.pause : MediaControl.play,
      MediaControl.stop,
      if (_onNext != null) MediaControl.skipToNext,
    ];

    final compactIndices = _calculateCompactActionIndices(controls);

    playbackState.add(PlaybackState(
      controls: controls,
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: compactIndices,
      playing: playing,
      updatePosition: position,
      speed: rate,
      processingState: processingState,
    ));
  }

  void _broadcastIdleState() {
    playbackState.add(PlaybackState(
      controls: [],
      systemActions: const {},
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
  }

  /// Calculate compact action indices for Android notification
  /// Returns indices for the most important controls to show in compact view
  List<int> _calculateCompactActionIndices(List<MediaControl> controls) {
    final indices = <int>[];

    // Find indices of key controls
    int? previousIndex;
    int? playPauseIndex;
    int? nextIndex;

    for (int i = 0; i < controls.length; i++) {
      if (controls[i] == MediaControl.skipToPrevious) {
        previousIndex = i;
      } else if (controls[i] == MediaControl.play ||
                 controls[i] == MediaControl.pause) {
        playPauseIndex = i;
      } else if (controls[i] == MediaControl.skipToNext) {
        nextIndex = i;
      }
    }

    // Build compact indices: Previous (if exists), Play/Pause, Next (if exists)
    if (previousIndex != null) indices.add(previousIndex);
    if (playPauseIndex != null) indices.add(playPauseIndex);
    if (nextIndex != null) indices.add(nextIndex);

    // Ensure we have at least the play/pause button
    if (indices.isEmpty && playPauseIndex != null) {
      indices.add(playPauseIndex);
    }

    return indices;
  }

  /// Update the media item shown in OS controls
  void setMediaItemFromMetadata(PlexMetadata metadata, String? thumbnailUrl) {
    final title = metadata.type.toLowerCase() == 'episode'
        ? metadata.title
        : metadata.title;

    final artist = metadata.type.toLowerCase() == 'episode'
        ? metadata.grandparentTitle ?? metadata.year?.toString()
        : metadata.year?.toString();

    final album = metadata.type.toLowerCase() == 'episode'
        ? 'S${metadata.parentIndex} · E${metadata.index} · ${metadata.parentTitle ?? ""}'
        : metadata.studio;

    final duration = metadata.duration != null
        ? Duration(milliseconds: metadata.duration!)
        : Duration.zero;

    mediaItem.add(MediaItem(
      id: metadata.ratingKey,
      title: title,
      artist: artist,
      album: album,
      duration: duration,
      artUri: thumbnailUrl != null ? Uri.parse(thumbnailUrl) : null,
      extras: {
        'ratingKey': metadata.ratingKey,
        'type': metadata.type,
      },
    ));

    appLogger.i('Media item updated: $title${artist != null ? " - $artist" : ""}');
  }

  /// Update whether next/previous actions are available
  void updateNavigationActions({bool? hasNext, bool? hasPrevious}) {
    _broadcastState();
  }

  /// Force an immediate state update
  /// Use this after playback starts to ensure notification appears
  void forceStateUpdate() {
    _broadcastState();
  }

  // BaseAudioHandler implementations
  @override
  Future<void> play() async {
    if (_player == null) return;
    await _player!.play();
  }

  @override
  Future<void> pause() async {
    if (_player == null) return;
    await _player!.pause();
  }

  @override
  Future<void> stop() async {
    if (_player != null) {
      await _player!.pause();
    }

    playbackState.add(PlaybackState(
      controls: [],
      systemActions: const {},
      playing: false,
      processingState: AudioProcessingState.idle,
    ));

    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    if (_player == null) return;
    await _player!.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    _onNext?.call();
  }

  @override
  Future<void> skipToPrevious() async {
    _onPrevious?.call();
  }

  @override
  Future<void> fastForward() async {
    if (_player == null) return;
    final newPosition = _player!.state.position + const Duration(seconds: 15);
    await _player!.seek(newPosition);
  }

  @override
  Future<void> rewind() async {
    if (_player == null) return;
    final newPosition = _player!.state.position - const Duration(seconds: 15);
    await _player!.seek(newPosition > Duration.zero ? newPosition : Duration.zero);
  }

  Future<void> dispose() async {
    appLogger.d('Disposing MediaKitAudioHandler');
    await _cleanupSubscriptions();
    await stop();
  }
}

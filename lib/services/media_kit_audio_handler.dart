import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:media_kit/media_kit.dart';
import 'package:rxdart/rxdart.dart';
import '../models/plex_metadata.dart';
import '../utils/app_logger.dart';

/// Audio handler that bridges media_kit player with OS media controls
class MediaKitAudioHandler extends BaseAudioHandler with SeekHandler {
  Player _player;
  final String plexServerUrl;
  final String authToken;

  // Getter for player
  Player get player => _player;

  // Callback functions for episode navigation
  Future<void> Function()? onSkipToNext;
  Future<void> Function()? onSkipToPrevious;

  // Stream subscriptions
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _bufferSubscription;

  // Queue management
  final BehaviorSubject<List<MediaItem>> _queueSubject = BehaviorSubject.seeded([]);

  MediaKitAudioHandler({
    required Player player,
    required this.plexServerUrl,
    required this.authToken,
    this.onSkipToNext,
    this.onSkipToPrevious,
  }) : _player = player {
    _init();
  }

  void _init() {
    // Map player state to playback state
    _playingSubscription = _player.stream.playing.listen((isPlaying) {
      _updatePlaybackState();
    });

    _positionSubscription = _player.stream.position.listen((_) {
      _updatePlaybackState();
    });

    _durationSubscription = _player.stream.duration.listen((_) {
      _updatePlaybackState();
    });

    _bufferSubscription = _player.stream.buffer.listen((_) {
      _updatePlaybackState();
    });

    // Set initial state
    _updatePlaybackState();
  }

  /// Update media item with current playing content
  void updateCurrentMediaItem(PlexMetadata metadata) {
    final artworkUrl = _getArtworkUrl(metadata);

    final newMediaItem = MediaItem(
      id: metadata.ratingKey,
      title: metadata.title,
      album: _getAlbumName(metadata),
      artist: _getArtistName(metadata),
      duration: metadata.duration != null
          ? Duration(milliseconds: metadata.duration!)
          : null,
      artUri: artworkUrl != null ? Uri.parse(artworkUrl) : null,
      extras: {
        'ratingKey': metadata.ratingKey,
        'type': metadata.type,
      },
    );

    mediaItem.add(newMediaItem);
    appLogger.d('Updated media item: ${metadata.title}');
  }

  /// Update navigation callbacks
  void updateNavigationCallbacks({
    Future<void> Function()? onNext,
    Future<void> Function()? onPrevious,
  }) {
    onSkipToNext = onNext;
    onSkipToPrevious = onPrevious;
    _updatePlaybackState();
  }

  /// Update the queue with episodes
  void updateEpisodeQueue(List<PlexMetadata> episodes, int currentIndex) {
    final items = episodes.map((episode) {
      final artworkUrl = _getArtworkUrl(episode);
      return MediaItem(
        id: episode.ratingKey,
        title: episode.title,
        album: _getAlbumName(episode),
        artist: _getArtistName(episode),
        duration: episode.duration != null
            ? Duration(milliseconds: episode.duration!)
            : null,
        artUri: artworkUrl != null ? Uri.parse(artworkUrl) : null,
        extras: {
          'ratingKey': episode.ratingKey,
          'type': episode.type,
        },
      );
    }).toList();

    _queueSubject.add(items);
    queue.add(items);

    if (currentIndex >= 0 && currentIndex < items.length) {
      mediaItem.add(items[currentIndex]);
    }

    appLogger.d('Updated queue with ${items.length} episodes, current index: $currentIndex');
  }

  String? _getArtworkUrl(PlexMetadata metadata) {
    String? thumbPath;

    // For episodes, prefer show poster over episode thumbnail
    if (metadata.type.toLowerCase() == 'episode') {
      thumbPath = metadata.grandparentThumb ?? metadata.thumb;
    } else {
      thumbPath = metadata.thumb;
    }

    if (thumbPath == null) return null;

    // Build full URL with authentication
    return '$plexServerUrl$thumbPath?X-Plex-Token=$authToken';
  }

  String _getAlbumName(PlexMetadata metadata) {
    // For episodes: "Show Name - Season X"
    if (metadata.type.toLowerCase() == 'episode') {
      final showName = metadata.grandparentTitle ?? '';
      final seasonNum = metadata.parentIndex;
      if (seasonNum != null) {
        return '$showName - Season $seasonNum';
      }
      return showName;
    }

    // For movies: studio or year
    return metadata.studio ?? metadata.year?.toString() ?? '';
  }

  String _getArtistName(PlexMetadata metadata) {
    // For episodes: show episode info
    if (metadata.type.toLowerCase() == 'episode') {
      final seasonNum = metadata.parentIndex;
      final episodeNum = metadata.index;
      if (seasonNum != null && episodeNum != null) {
        return 'S${seasonNum.toString().padLeft(2, '0')}E${episodeNum.toString().padLeft(2, '0')}';
      }
    }

    return '';
  }

  void _updatePlaybackState() {
    final isPlaying = _player.state.playing;
    final position = _player.state.position;
    final bufferedPosition = _player.state.buffer;

    // Determine processing state
    AudioProcessingState processingState;
    if (_player.state.buffering) {
      processingState = AudioProcessingState.buffering;
    } else if (_player.state.completed) {
      processingState = AudioProcessingState.completed;
    } else {
      processingState = AudioProcessingState.ready;
    }

    // Build controls based on state and available navigation
    final controls = <MediaControl>[
      if (onSkipToPrevious != null) MediaControl.skipToPrevious,
      MediaControl.rewind,
      if (isPlaying) MediaControl.pause else MediaControl.play,
      MediaControl.fastForward,
      if (onSkipToNext != null) MediaControl.skipToNext,
    ];

    playbackState.add(PlaybackState(
      controls: controls,
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: [
        if (onSkipToPrevious != null) 0,
        onSkipToPrevious != null ? 2 : 1, // Play/Pause button
        if (onSkipToNext != null)
          onSkipToPrevious != null ? 4 : 3,
      ].where((i) => i < controls.length).toList(),
      processingState: processingState,
      playing: isPlaying,
      updatePosition: position,
      bufferedPosition: bufferedPosition,
      speed: 1.0,
      queueIndex: 0, // TODO: Update based on actual queue position
    ));
  }

  @override
  Future<void> play() async {
    appLogger.d('Audio handler: play');
    await _player.play();
  }

  @override
  Future<void> pause() async {
    appLogger.d('Audio handler: pause');
    await _player.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    appLogger.d('Audio handler: seek to ${position.inSeconds}s');
    await _player.seek(position);
  }

  @override
  Future<void> stop() async {
    appLogger.d('Audio handler: stop');
    await _player.stop();
  }

  @override
  Future<void> fastForward() async {
    appLogger.d('Audio handler: fast forward');
    final newPosition = _player.state.position + const Duration(seconds: 10);
    await _player.seek(newPosition);
  }

  @override
  Future<void> rewind() async {
    appLogger.d('Audio handler: rewind');
    final newPosition = _player.state.position - const Duration(seconds: 10);
    await _player.seek(newPosition > Duration.zero ? newPosition : Duration.zero);
  }

  @override
  Future<void> skipToNext() async {
    appLogger.d('Audio handler: skip to next');
    if (onSkipToNext != null) {
      await onSkipToNext!();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    appLogger.d('Audio handler: skip to previous');
    if (onSkipToPrevious != null) {
      await onSkipToPrevious!();
    }
  }

  /// Update the player reference when switching episodes
  /// This ensures the handler stays in sync with the current player instance
  Future<void> updatePlayer(Player newPlayer) async {
    appLogger.d('Audio handler: updating player reference');

    // Cancel old subscriptions
    await _playingSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _bufferSubscription?.cancel();

    // Update player reference
    _player = newPlayer;

    // Create new subscriptions with the new player
    _playingSubscription = _player.stream.playing.listen((isPlaying) {
      _updatePlaybackState();
    });

    _positionSubscription = _player.stream.position.listen((_) {
      _updatePlaybackState();
    });

    _durationSubscription = _player.stream.duration.listen((_) {
      _updatePlaybackState();
    });

    _bufferSubscription = _player.stream.buffer.listen((_) {
      _updatePlaybackState();
    });

    // Update playback state immediately
    _updatePlaybackState();

    appLogger.d('Audio handler: player reference updated successfully');
  }

  Future<void> dispose() async {
    // Cancel subscriptions
    await _playingSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _bufferSubscription?.cancel();
    await _queueSubject.close();
  }
}

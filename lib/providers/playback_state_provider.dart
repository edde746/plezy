import 'package:flutter/foundation.dart';
import '../models/plex_metadata.dart';

/// Playback mode types
enum PlaybackMode {
  none, // No active playback queue
  sequential, // Normal episode-to-episode playback (uses Plex API)
  shufflePlay, // Shuffle play for shows/seasons
  playlist, // Playlist playback (ordered or shuffled)
}

/// Manages playback state for TV shows, seasons, and playlists.
/// This provider is session-only and does not persist across app restarts.
class PlaybackStateProvider with ChangeNotifier {
  List<PlexMetadata> _queue = [];
  String? _contextKey; // The show/season/playlist ratingKey for this session
  int _currentIndex = 0;
  PlaybackMode _playbackMode = PlaybackMode.none;

  /// Current playback mode
  PlaybackMode get playbackMode => _playbackMode;

  /// Whether shuffle mode is currently active
  bool get isShuffleActive => _playbackMode == PlaybackMode.shufflePlay;

  /// Whether playlist mode is currently active
  bool get isPlaylistActive => _playbackMode == PlaybackMode.playlist;

  /// Whether any queue-based playback is active
  bool get isQueueActive =>
      _queue.isNotEmpty && _playbackMode != PlaybackMode.none;

  /// The context key (show/season/playlist ratingKey) for the current session
  String? get shuffleContextKey => _contextKey;

  /// Sets a new shuffle queue and starts shuffle mode
  void setShuffleQueue(List<PlexMetadata> episodes, String contextKey) {
    _queue = List.from(episodes);
    _contextKey = contextKey;
    _currentIndex = 0;
    _playbackMode = PlaybackMode.shufflePlay;
    notifyListeners();
  }

  /// Sets a playback queue for playlist playback (ordered, not shuffled)
  void setPlaybackQueue(List<PlexMetadata> items, String contextKey) {
    _queue = List.from(items);
    _contextKey = contextKey;
    _currentIndex = 0;
    _playbackMode = PlaybackMode.playlist;
    notifyListeners();
  }

  /// Gets the next item in the playback queue.
  /// Returns null if queue is exhausted or current item is not in queue.
  /// [loopQueue] - If true, restart from beginning when queue is exhausted
  PlexMetadata? getNextEpisode(
    String currentItemKey, {
    bool loopQueue = false,
  }) {
    if (_queue.isEmpty) return null;

    // Find current item in queue
    final currentIndex = _queue.indexWhere(
      (item) => item.ratingKey == currentItemKey,
    );

    if (currentIndex == -1) {
      // Current item not in queue, clear queue
      clearShuffle();
      return null;
    }

    // Check if there's a next item
    if (currentIndex + 1 >= _queue.length) {
      // Queue exhausted
      if (loopQueue && _queue.isNotEmpty) {
        // Loop back to beginning
        _currentIndex = 0;
        return _queue[_currentIndex];
      }
      return null;
    }

    _currentIndex = currentIndex + 1;
    return _queue[_currentIndex];
  }

  /// Gets the previous item in the playback queue.
  /// Returns null if at the beginning of the queue or current item is not in queue.
  PlexMetadata? getPreviousEpisode(String currentItemKey) {
    if (_queue.isEmpty) return null;

    // Find current item in queue
    final currentIndex = _queue.indexWhere(
      (item) => item.ratingKey == currentItemKey,
    );

    if (currentIndex == -1) {
      // Current item not in queue
      return null;
    }

    // Check if there's a previous item
    if (currentIndex <= 0) {
      // At the beginning of queue
      return null;
    }

    _currentIndex = currentIndex - 1;
    return _queue[_currentIndex];
  }

  /// Clears the playback queue and exits queue mode
  void clearShuffle() {
    _queue = [];
    _contextKey = null;
    _currentIndex = 0;
    _playbackMode = PlaybackMode.none;
    notifyListeners();
  }

  /// Gets the total number of items in the current playback queue
  int get queueLength => _queue.length;

  /// Gets the current position in the queue (1-indexed)
  int get currentPosition => _currentIndex + 1;
}

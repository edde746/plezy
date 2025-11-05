import 'package:flutter/foundation.dart';
import '../models/plex_metadata.dart';

/// Manages shuffle playback state for TV shows and seasons.
/// This provider is session-only and does not persist across app restarts.
class PlaybackStateProvider with ChangeNotifier {
  List<PlexMetadata> _shuffleQueue = [];
  String?
  _shuffleContextKey; // The show/season ratingKey for this shuffle session
  int _currentIndex = 0;

  /// Whether shuffle mode is currently active
  bool get isShuffleActive => _shuffleQueue.isNotEmpty;

  /// The context key (show or season ratingKey) for the current shuffle session
  String? get shuffleContextKey => _shuffleContextKey;

  /// Sets a new shuffle queue and starts shuffle mode
  void setShuffleQueue(List<PlexMetadata> episodes, String contextKey) {
    _shuffleQueue = List.from(episodes);
    _shuffleContextKey = contextKey;
    _currentIndex = 0;
    notifyListeners();
  }

  /// Gets the next episode in the shuffle queue.
  /// Returns null if queue is exhausted or current episode is not in queue.
  PlexMetadata? getNextEpisode(String currentEpisodeKey) {
    if (_shuffleQueue.isEmpty) return null;

    // Find current episode in queue
    final currentIndex = _shuffleQueue.indexWhere(
      (ep) => ep.ratingKey == currentEpisodeKey,
    );

    if (currentIndex == -1) {
      // Current episode not in queue, clear shuffle
      clearShuffle();
      return null;
    }

    // Check if there's a next episode
    if (currentIndex + 1 >= _shuffleQueue.length) {
      // Queue exhausted
      return null;
    }

    _currentIndex = currentIndex + 1;
    return _shuffleQueue[_currentIndex];
  }

  /// Clears the shuffle queue and exits shuffle mode
  void clearShuffle() {
    _shuffleQueue = [];
    _shuffleContextKey = null;
    _currentIndex = 0;
    notifyListeners();
  }

  /// Gets the total number of episodes in the current shuffle queue
  int get queueLength => _shuffleQueue.length;

  /// Gets the current position in the queue (1-indexed)
  int get currentPosition => _currentIndex + 1;
}

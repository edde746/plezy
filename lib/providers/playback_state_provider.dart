import 'package:flutter/foundation.dart';
import '../models/plex_metadata.dart';
import '../models/play_queue_response.dart';
import '../services/plex_client.dart';

/// Playback mode types
///
/// All playback now uses Plex play queues.
enum PlaybackMode {
  playQueue, // Play queue-based playback (sequential, shuffle, playlists, collections)
}

/// Result of trying to locate the current queue index.
class _IndexLookupResult {
  final int? index;
  final bool attemptedLoad;
  final bool loadFailed;

  const _IndexLookupResult({this.index, this.attemptedLoad = false, this.loadFailed = false});
}

/// Manages playback state using Plex's play queue API.
/// This provider is session-only and does not persist across app restarts.
class PlaybackStateProvider with ChangeNotifier {
  // Play queue state
  int? _playQueueId;
  int _playQueueTotalCount = 0;
  bool _playQueueShuffled = false;
  int? _currentPlayQueueItemID;

  // Windowed items (loaded around current position)
  List<PlexMetadata> _loadedItems = [];
  final int _windowSize = 50; // Number of items to keep in memory

  // Legacy state for backward compatibility
  String? _contextKey; // The show/season/playlist ratingKey for this session
  PlaybackMode? _playbackMode;

  // Client reference for loading more items
  PlexClient? _client;

  /// Current playback mode (null if no queue active)
  PlaybackMode? get playbackMode => _playbackMode;

  /// Whether shuffle mode is currently active
  bool get isShuffleActive => _playQueueShuffled;

  /// Whether playlist/collection mode is currently active
  bool get isPlaylistActive => _playbackMode == PlaybackMode.playQueue;

  /// Whether any queue-based playback is active
  bool get isQueueActive => _playQueueId != null && _playbackMode == PlaybackMode.playQueue;

  /// The context key (show/season/playlist ratingKey) for the current session
  String? get shuffleContextKey => _contextKey;

  /// Current play queue ID
  int? get playQueueId => _playQueueId;

  /// Total number of items in the play queue
  int get queueLength => _playQueueTotalCount;

  /// Gets the current position in the queue (1-indexed)
  int get currentPosition {
    if (_currentPlayQueueItemID == null || _loadedItems.isEmpty) return 0;
    final index = _loadedItems.indexWhere((item) => item.playQueueItemID == _currentPlayQueueItemID);
    return index != -1 ? index + 1 : 0;
  }

  /// Set the client reference for loading more items
  void setClient(PlexClient client) {
    _client = client;
  }

  /// Update the current play queue item when playing a new item
  void setCurrentItem(PlexMetadata metadata) {
    if (_playbackMode == PlaybackMode.playQueue && metadata.playQueueItemID != null) {
      _currentPlayQueueItemID = metadata.playQueueItemID;
      notifyListeners();
    }
  }

  /// Initialize playback from a play queue
  /// Call this after creating a play queue via the API
  Future<void> setPlaybackFromPlayQueue(
    PlayQueueResponse playQueue,
    String? contextKey, {
    String? serverId,
    String? serverName,
  }) async {
    _playQueueId = playQueue.playQueueID;
    // Use size or items length as fallback if totalCount is null
    _playQueueTotalCount = playQueue.playQueueTotalCount ?? playQueue.size ?? (playQueue.items?.length ?? 0);
    _playQueueShuffled = playQueue.playQueueShuffled;
    _currentPlayQueueItemID = playQueue.playQueueSelectedItemID;

    // Items are already tagged with server info by PlexClient
    _loadedItems = playQueue.items ?? [];

    _contextKey = contextKey;
    _playbackMode = PlaybackMode.playQueue;
    notifyListeners();
  }

  /// Load more items from the play queue if needed
  /// Returns true if more items were loaded
  Future<bool> _ensureItemsLoaded(int targetPlayQueueItemID) async {
    if (_client == null || _playQueueId == null) return false;

    // Check if the target item is already loaded
    final hasItem = _loadedItems.any((item) => item.playQueueItemID == targetPlayQueueItemID);

    if (hasItem) return true;

    // Load a window around the target item
    try {
      final response = await _client!.getPlayQueue(
        _playQueueId!,
        center: targetPlayQueueItemID.toString(),
        window: _windowSize,
      );

      if (response != null && response.items != null) {
        // Items are already tagged with server info by PlexClient
        _loadedItems = response.items!;
        // Use size or items length as fallback if totalCount is null
        _playQueueTotalCount = response.playQueueTotalCount ?? response.size ?? response.items!.length;
        _playQueueShuffled = response.playQueueShuffled;
        notifyListeners();
        return true;
      }
    } catch (e) {
      // Failed to load items
      return false;
    }

    return false;
  }

  Future<_IndexLookupResult> _getCurrentIndex({bool loadIfMissing = false}) async {
    if (_playbackMode != PlaybackMode.playQueue || _loadedItems.isEmpty || _currentPlayQueueItemID == null) {
      return const _IndexLookupResult();
    }

    var currentIndex = _loadedItems.indexWhere((item) => item.playQueueItemID == _currentPlayQueueItemID);

    if (currentIndex != -1) {
      return _IndexLookupResult(index: currentIndex);
    }

    if (!loadIfMissing || _client == null || _playQueueId == null) {
      return const _IndexLookupResult();
    }

    final loaded = await _ensureItemsLoaded(_currentPlayQueueItemID!);
    if (!loaded) {
      return const _IndexLookupResult(attemptedLoad: true, loadFailed: true);
    }

    currentIndex = _loadedItems.indexWhere((item) => item.playQueueItemID == _currentPlayQueueItemID);

    if (currentIndex == -1) {
      return const _IndexLookupResult(attemptedLoad: true, loadFailed: true);
    }

    return _IndexLookupResult(index: currentIndex, attemptedLoad: true);
  }

  /// Gets the next item in the playback queue.
  /// Returns null if queue is exhausted or current item is not in queue.
  /// [loopQueue] - If true, restart from beginning when queue is exhausted
  Future<PlexMetadata?> getNextEpisode(String currentItemKey, {bool loopQueue = false}) async {
    if (_playbackMode != PlaybackMode.playQueue) {
      // For sequential mode, let the video player handle next episode
      return null;
    }

    final indexResult = await _getCurrentIndex(loadIfMissing: true);
    if (indexResult.index == null) {
      if (indexResult.loadFailed) {
        clearShuffle();
      }
      return null;
    }
    final currentIndex = indexResult.index!;

    // Check if there's a next item in the loaded window
    if (currentIndex + 1 < _loadedItems.length) {
      final nextItem = _loadedItems[currentIndex + 1];
      // Don't update _currentPlayQueueItemID here - let setCurrentItem do it when playback starts
      return nextItem;
    }

    // Check if we're at the end of the entire queue
    if (currentIndex + 1 >= _playQueueTotalCount) {
      if (loopQueue && _playQueueTotalCount > 0) {
        // Loop back to beginning - load first item
        if (_client != null && _playQueueId != null) {
          final response = await _client!.getPlayQueue(_playQueueId!);
          if (response != null && response.items != null && response.items!.isNotEmpty) {
            // Items are already tagged with server info by PlexClient
            _loadedItems = response.items!;
            final firstItem = _loadedItems.first;
            // Don't update _currentPlayQueueItemID here - let setCurrentItem do it when playback starts
            return firstItem;
          }
        }
      }
      // At end of queue - return null but keep queue active so user can still go back
      return null;
    }

    // Need to load next window
    if (_client != null && _playQueueId != null) {
      // Load next window centered on the item after current
      final nextItemID = _loadedItems.last.playQueueItemID;
      if (nextItemID != null) {
        final loaded = await _ensureItemsLoaded(nextItemID + 1);
        if (loaded) {
          // Try again with newly loaded items
          return getNextEpisode(currentItemKey, loopQueue: loopQueue);
        }
      }
    }

    return null;
  }

  /// Gets the previous item in the playback queue.
  /// Returns null if at the beginning of the queue or current item is not in queue.
  Future<PlexMetadata?> getPreviousEpisode(String currentItemKey) async {
    if (_playbackMode != PlaybackMode.playQueue) {
      // For sequential mode, let the video player handle previous episode
      return null;
    }

    final currentIndex = (await _getCurrentIndex()).index;
    if (currentIndex == null) return null;

    // Check if there's a previous item in the loaded window
    if (currentIndex > 0) {
      final prevItem = _loadedItems[currentIndex - 1];
      // Don't update _currentPlayQueueItemID here - let setCurrentItem do it when playback starts
      return prevItem;
    }

    // Check if we're at the beginning of the entire queue
    if (currentIndex == 0) {
      return null;
    }

    // Need to load previous window
    if (_client != null && _playQueueId != null) {
      final prevItemID = _loadedItems.first.playQueueItemID;
      if (prevItemID != null && prevItemID > 0) {
        final loaded = await _ensureItemsLoaded(prevItemID - 1);
        if (loaded) {
          return getPreviousEpisode(currentItemKey);
        }
      }
    }

    return null;
  }

  /// Clears the playback queue and exits queue mode
  void clearShuffle() {
    _playQueueId = null;
    _playQueueTotalCount = 0;
    _playQueueShuffled = false;
    _currentPlayQueueItemID = null;
    _loadedItems = [];
    _contextKey = null;
    _playbackMode = null;
    notifyListeners();
  }
}

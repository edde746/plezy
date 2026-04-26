import 'package:flutter/foundation.dart';
import '../media/media_item.dart';
import '../media/play_queue.dart';
import '../models/plex/play_queue_response.dart';
import '../mixins/disposable_change_notifier_mixin.dart';

/// Fetches a window of items from a server-side play queue. Provider calls
/// this when the currently loaded window doesn't contain the next item it
/// needs to surface. Wired to a backend that maintains queues server-side
/// (Plex's `/playQueues`); left null for client-side queues (Jellyfin's
/// [LocalPlayQueue]) where the full list is already resident.
typedef PlayQueueWindowFetcher = Future<PlayQueueResponse?> Function(int playQueueId, {String? center, int window});

/// Result of trying to locate the current queue index.
class _IndexLookupResult {
  final int? index;
  final bool attemptedLoad;
  final bool loadFailed;

  const _IndexLookupResult({this.index, this.attemptedLoad = false, this.loadFailed = false});
}

/// Manages playback state using Plex's play queue API.
/// This provider is session-only and does not persist across app restarts.
class PlaybackStateProvider with ChangeNotifier, DisposableChangeNotifierMixin {
  // Play queue state
  int? _playQueueId;
  int _playQueueTotalCount = 0;
  bool _playQueueShuffled = false;
  int? _currentPlayQueueItemID;

  // Windowed items (loaded around current position)
  List<MediaItem> _loadedItems = [];
  final int _windowSize = 50; // Number of items to keep in memory

  /// Synthetic per-item queue IDs for client-side queues (Jellyfin, etc.).
  /// Parallel to [_loadedItems] — `_syntheticIds[i]` is the queue ID for
  /// `_loadedItems[i]`. Empty when the queue is server-side (Plex), where
  /// the real id lives on [PlexMediaItem.playQueueItemId].
  List<int> _syntheticIds = const [];

  String? _contextKey; // The show/season/playlist ratingKey for this session
  bool _isQueueMode = false;

  // Client reference for loading more items
  PlayQueueWindowFetcher? _windowFetcher;

  /// Returns the queue id for [item] within the current queue. For Plex
  /// items this is the server's `playQueueItemID`; for client-side queues
  /// (Jellyfin) it's a synthetic index assigned in [setPlaybackFromLocalQueue].
  /// Returns null when [item] isn't in the current loaded window.
  int? playQueueItemIdFor(MediaItem item) {
    if (item is PlexMediaItem && item.playQueueItemId != null) {
      return item.playQueueItemId;
    }
    final idx = _loadedItems.indexOf(item);
    if (idx < 0 || idx >= _syntheticIds.length) return null;
    return _syntheticIds[idx];
  }

  /// Whether shuffle mode is currently active
  bool get isShuffleActive => _playQueueShuffled;

  /// Whether playlist/collection mode is currently active
  bool get isPlaylistActive => _isQueueMode;

  /// Whether any queue-based playback is active
  bool get isQueueActive => _playQueueId != null && _isQueueMode;

  /// The context key (show/season/playlist ratingKey) for the current session
  String? get shuffleContextKey => _contextKey;

  /// Current play queue ID
  int? get playQueueId => _playQueueId;

  /// The currently loaded queue items (windowed subset of full queue)
  List<MediaItem> get loadedItems => List.unmodifiable(_loadedItems);

  /// The current play queue item ID
  int? get currentPlayQueueItemID => _currentPlayQueueItemID;

  /// Set the client reference for loading more items
  void setPlayQueueWindowFetcher(PlayQueueWindowFetcher? fetcher) {
    _windowFetcher = fetcher;
  }

  /// Update the current play queue item when playing a new item
  void setCurrentItem(MediaItem metadata) {
    if (!_isQueueMode) return;
    final id = playQueueItemIdFor(metadata);
    if (id != null) {
      _currentPlayQueueItemID = id;
      safeNotifyListeners();
    }
  }

  /// Initialize playback from a play queue
  /// Call this after creating a play queue via the API
  Future<void> setPlaybackFromPlayQueue(PlayQueueResponse playQueue, String? contextKey) async {
    _playQueueId = playQueue.playQueueID;
    // Use size or items length as fallback if totalCount is null
    _playQueueTotalCount = playQueue.playQueueTotalCount ?? playQueue.size ?? (playQueue.items?.length ?? 0);
    _playQueueShuffled = playQueue.playQueueShuffled;
    _currentPlayQueueItemID = playQueue.playQueueSelectedItemID;

    // Items arrive pre-tagged with server info by the producing mapper.
    _loadedItems = playQueue.items ?? [];
    // Plex items carry their own playQueueItemId — no synthetic IDs needed.
    _syntheticIds = const [];

    _contextKey = contextKey;
    _isQueueMode = true;
    safeNotifyListeners();
  }

  /// Initialize playback from a [LocalPlayQueue] (Jellyfin / any backend
  /// without a server-side queue). Synthetic per-item queue IDs are
  /// recorded in [_syntheticIds] (parallel to [_loadedItems]) so the
  /// existing Plex-shaped UI — Queue sheet, content strip, current item
  /// highlight — keeps working without a parallel rendering path. Items
  /// themselves are stored unmutated.
  ///
  /// `playQueueId` is set to a sentinel so [isQueueActive] returns true.
  /// Window-extension paths (`_ensureItemsLoaded`, `getNextEpisode`) consult
  /// `_windowFetcher`, which stays null for client-side queues — JF callers
  /// resolve adjacent items through [EpisodeNavigationService] instead.
  void setPlaybackFromLocalQueue(LocalPlayQueue queue, {String? contextKey}) {
    _playQueueId = -1; // sentinel for "client-side queue"
    _playQueueTotalCount = queue.items.length;
    _playQueueShuffled = queue.shuffled;
    _loadedItems = List.of(queue.items);
    _syntheticIds = [for (var i = 0; i < queue.items.length; i++) i];
    _currentPlayQueueItemID = queue.currentIndex;
    _contextKey = contextKey;
    _isQueueMode = true;
    _windowFetcher = null; // disable server-side window extension
    safeNotifyListeners();
  }

  /// Load more items from the play queue if needed
  /// Returns true if more items were loaded
  Future<bool> _ensureItemsLoaded(int targetPlayQueueItemID) async {
    if (_windowFetcher == null || _playQueueId == null) return false;

    // Plex queues only — items are PlexMediaItem with a real playQueueItemId.
    final hasItem = _loadedItems.whereType<PlexMediaItem>().any(
      (item) => item.playQueueItemId == targetPlayQueueItemID,
    );

    if (hasItem) return true;

    // Load a window around the target item
    try {
      final response = await _windowFetcher!(
        _playQueueId!,
        center: targetPlayQueueItemID.toString(),
        window: _windowSize,
      );

      if (response != null && response.items != null) {
        // Items arrive pre-tagged with server info by the producing mapper.
        _loadedItems = response.items!;
        // Use size or items length as fallback if totalCount is null
        _playQueueTotalCount = response.playQueueTotalCount ?? response.size ?? response.items!.length;
        _playQueueShuffled = response.playQueueShuffled;
        safeNotifyListeners();
        return true;
      }
    } catch (e) {
      // Failed to load items
      return false;
    }

    return false;
  }

  Future<_IndexLookupResult> _getCurrentIndex({bool loadIfMissing = false}) async {
    if (!_isQueueMode || _loadedItems.isEmpty || _currentPlayQueueItemID == null) {
      return const _IndexLookupResult();
    }

    var currentIndex = _findLoadedIndex(_currentPlayQueueItemID!);

    if (currentIndex != -1) {
      return _IndexLookupResult(index: currentIndex);
    }

    if (!loadIfMissing || _windowFetcher == null || _playQueueId == null) {
      return const _IndexLookupResult();
    }

    final loaded = await _ensureItemsLoaded(_currentPlayQueueItemID!);
    if (!loaded) {
      return const _IndexLookupResult(attemptedLoad: true, loadFailed: true);
    }

    currentIndex = _findLoadedIndex(_currentPlayQueueItemID!);

    if (currentIndex == -1) {
      return const _IndexLookupResult(attemptedLoad: true, loadFailed: true);
    }

    return _IndexLookupResult(index: currentIndex, attemptedLoad: true);
  }

  /// Returns the index of the item with [playQueueItemId] in [_loadedItems],
  /// or -1 if absent. Bridges Plex (real id on [PlexMediaItem]) and
  /// client-side (synthetic id in [_syntheticIds]) queues.
  int _findLoadedIndex(int playQueueItemId) {
    for (var i = 0; i < _loadedItems.length; i++) {
      final item = _loadedItems[i];
      if (item is PlexMediaItem && item.playQueueItemId == playQueueItemId) {
        return i;
      }
      if (i < _syntheticIds.length && _syntheticIds[i] == playQueueItemId) {
        return i;
      }
    }
    return -1;
  }

  /// Gets the next item in the playback queue.
  /// Returns null if queue is exhausted or current item is not in queue.
  /// [loopQueue] - If true, restart from beginning when queue is exhausted
  Future<MediaItem?> getNextEpisode(String currentItemKey, {bool loopQueue = false}) async {
    if (!_isQueueMode) {
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
      // Don't update _currentPlayQueueItemID here - let setCurrentItem do it when playback starts
      return _loadedItems[currentIndex + 1];
    }

    // Check if we're at the end of the entire queue
    if (currentIndex + 1 >= _playQueueTotalCount) {
      if (loopQueue && _playQueueTotalCount > 0) {
        // Loop back to beginning - load first item
        if (_windowFetcher != null && _playQueueId != null) {
          final response = await _windowFetcher!(_playQueueId!);
          if (response != null && response.items != null && response.items!.isNotEmpty) {
            // Items arrive pre-tagged with server info by the producing mapper.
            _loadedItems = response.items!;
            // Don't update _currentPlayQueueItemID here - let setCurrentItem do it when playback starts
            return _loadedItems.first;
          }
        }
      }
      // At end of queue - return null but keep queue active so user can still go back
      return null;
    }

    // Need to load next window
    if (_windowFetcher != null && _playQueueId != null && _loadedItems.isNotEmpty) {
      // Load next window centered on the item after current. Plex-only path
      // — _windowFetcher != null implies queue items are PlexMediaItem.
      final last = _loadedItems.last;
      final nextItemID = last is PlexMediaItem ? last.playQueueItemId : null;
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
  Future<MediaItem?> getPreviousEpisode(String currentItemKey) async {
    if (!_isQueueMode) {
      // For sequential mode, let the video player handle previous episode
      return null;
    }

    final currentIndex = (await _getCurrentIndex()).index;
    if (currentIndex == null) return null;

    // Check if there's a previous item in the loaded window
    if (currentIndex > 0) {
      // Don't update _currentPlayQueueItemID here - let setCurrentItem do it when playback starts
      return _loadedItems[currentIndex - 1];
    }

    // Check if we're at the beginning of the entire queue
    if (currentIndex == 0) {
      return null;
    }

    // Need to load previous window
    if (_windowFetcher != null && _playQueueId != null && _loadedItems.isNotEmpty) {
      // Plex-only path — _windowFetcher != null implies items are PlexMediaItem.
      final first = _loadedItems.first;
      final prevItemID = first is PlexMediaItem ? first.playQueueItemId : null;
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
    _syntheticIds = const [];
    _contextKey = null;
    _isQueueMode = false;
    safeNotifyListeners();
  }
}

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

  /// Whether [item] belongs to the currently active queue. True for Plex
  /// items the server-side queue stamped with a `playQueueItemId`, and for
  /// items present in a Jellyfin local queue (synthetic id). Membership for
  /// local queues is by object identity — [MediaItem] is `@Freezed(equal:
  /// false)` — so only the exact instances stored in the queue match.
  /// Gates the player's "preserve vs. wipe launcher-set queue" decision in
  /// [VideoPlayerScreen.initState], `_ensurePlayQueue`, and
  /// [EpisodeNavigationService]'s `_ensureLocalEpisodeQueue`, so a
  /// playlist, collection, or shuffled show queue survives entry into the
  /// player instead of being replaced with a sequential show queue.
  bool isItemInActiveQueue(MediaItem item) => isQueueActive && playQueueItemIdFor(item) != null;

  /// The context key (show/season/playlist ratingKey) for the current session
  String? get shuffleContextKey => _contextKey;

  /// Current play queue ID
  int? get playQueueId => _playQueueId;

  /// The currently loaded queue items (windowed subset of full queue)
  List<MediaItem> get loadedItems => List.unmodifiable(_loadedItems);

  /// The current play queue item ID
  int? get currentPlayQueueItemID => _currentPlayQueueItemID;

  /// The queue item the cursor currently points at, or null when no queue
  /// is active or the cursor is outside the loaded window.
  MediaItem? get currentQueueItem => _currentPlayQueueItemID == null ? null : _findLoadedItem(_currentPlayQueueItemID!);

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
        return _findLoadedIndex(targetPlayQueueItemID) != -1;
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

  MediaItem? _findLoadedItem(int playQueueItemId) {
    final index = _findLoadedIndex(playQueueItemId);
    return index == -1 ? null : _loadedItems[index];
  }

  /// Gets the next item in the playback queue.
  /// Returns null if queue is exhausted or current item is not in queue.
  /// [loopQueue] - If true, restart from beginning when queue is exhausted
  ///
  /// Entries backed by the same file as the one playing are skipped: Plex
  /// lists each episode of a multi-episode file (`S02E24-E25.mkv`) as its
  /// own queue item, and advancing to the sibling would replay the file
  /// from the start (#1500). [playedPartId] pins the comparison to the file
  /// of the part actually playing when known; otherwise any file overlap
  /// with the current item counts.
  Future<MediaItem?> getNextEpisode(String currentItemKey, {bool loopQueue = false, String? playedPartId}) async {
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

    final current = _loadedItems[indexResult.index!];
    var anchor = current;
    // Bounded so a pathological all-same-file looping queue can't spin.
    for (var steps = 0; steps <= _playQueueTotalCount; steps++) {
      final candidate = await _itemAfter(anchor, loopQueue: loopQueue);
      if (candidate == null || !current.sharesFileWith(candidate, playedPartId: playedPartId)) {
        return candidate;
      }
      anchor = candidate;
    }
    return null;
  }

  /// Gets the previous item in the playback queue.
  /// Returns null if at the beginning of the queue or current item is not in queue.
  ///
  /// Mirrors [getNextEpisode]'s multi-episode-file handling (#1500): entries
  /// backed by the file that's playing are skipped, and the result is
  /// collapsed to the first episode of its same-file group so a
  /// multi-episode file is entered at the episode that fronts it.
  Future<MediaItem?> getPreviousEpisode(String currentItemKey, {String? playedPartId}) async {
    if (!_isQueueMode) {
      // For sequential mode, let the video player handle previous episode
      return null;
    }

    final currentIndex = (await _getCurrentIndex()).index;
    if (currentIndex == null) return null;

    final current = _loadedItems[currentIndex];
    MediaItem? candidate = current;
    for (var steps = 0; steps <= _playQueueTotalCount; steps++) {
      candidate = await _itemBefore(candidate!);
      if (candidate == null) return null;
      if (!current.sharesFileWith(candidate, playedPartId: playedPartId)) break;
    }

    // Collapse to the first episode of the candidate's same-file group.
    for (var steps = 0; steps <= _playQueueTotalCount; steps++) {
      final before = await _itemBefore(candidate!);
      if (before == null || !candidate.sharesFileWith(before)) return candidate;
      candidate = before;
    }
    return candidate;
  }

  /// The queue item immediately after [anchor], extending the loaded window
  /// when needed. Returns null at the end of the queue unless [loopQueue].
  /// Does not move the queue cursor — setCurrentItem does that when
  /// playback of the returned item actually starts.
  Future<MediaItem?> _itemAfter(MediaItem anchor, {bool loopQueue = false}) async {
    final anchorId = playQueueItemIdFor(anchor);
    if (anchorId == null) return null;
    final anchorIndex = _findLoadedIndex(anchorId);
    if (anchorIndex == -1) return null;

    // Check if there's a next item in the loaded window
    if (anchorIndex + 1 < _loadedItems.length) {
      return _loadedItems[anchorIndex + 1];
    }

    // Check if we're at the end of the entire queue
    if (anchorIndex + 1 >= _playQueueTotalCount) {
      if (loopQueue && _playQueueTotalCount > 0) {
        // Loop back to beginning - load first item
        if (_windowFetcher != null && _playQueueId != null) {
          final response = await _windowFetcher!(_playQueueId!);
          if (response != null && response.items != null && response.items!.isNotEmpty) {
            // Items arrive pre-tagged with server info by the producing mapper.
            _loadedItems = response.items!;
            return _loadedItems.first;
          }
        }
      }
      // At end of queue - return null but keep queue active so user can still go back
      return null;
    }

    // Need to load next window
    if (_windowFetcher != null && _playQueueId != null && _loadedItems.isNotEmpty) {
      // Load next window centered on the item after the anchor. Plex-only
      // path — _windowFetcher != null implies queue items are PlexMediaItem.
      final last = _loadedItems.last;
      final nextItemID = last is PlexMediaItem ? last.playQueueItemId : null;
      if (nextItemID != null) {
        final targetPlayQueueItemID = nextItemID + 1;
        final loaded = await _ensureItemsLoaded(targetPlayQueueItemID);
        if (loaded) return _findLoadedItem(targetPlayQueueItemID);
      }
    }

    return null;
  }

  /// The queue item immediately before [anchor], extending the loaded
  /// window when needed. Returns null at the beginning of the queue.
  Future<MediaItem?> _itemBefore(MediaItem anchor) async {
    final anchorId = playQueueItemIdFor(anchor);
    if (anchorId == null) return null;
    final anchorIndex = _findLoadedIndex(anchorId);
    if (anchorIndex == -1) return null;

    // Check if there's a previous item in the loaded window
    if (anchorIndex > 0) {
      return _loadedItems[anchorIndex - 1];
    }

    // Need to load previous window. Plex-only path — _windowFetcher != null
    // implies items are PlexMediaItem.
    if (_windowFetcher != null && _playQueueId != null && _loadedItems.isNotEmpty) {
      final first = _loadedItems.first;
      final prevItemID = first is PlexMediaItem ? first.playQueueItemId : null;
      if (prevItemID != null && prevItemID > 0) {
        final targetPlayQueueItemID = prevItemID - 1;
        final loaded = await _ensureItemsLoaded(targetPlayQueueItemID);
        if (loaded) return _findLoadedItem(targetPlayQueueItemID);
      }
    }

    return null;
  }

  /// Queue items backed by the same physical file as [current] — the other
  /// episodes of a Plex multi-episode file (#1500), which should share its
  /// watched state. Scans the loaded window only: in sequential order
  /// same-file episodes are adjacent, so they are always co-resident.
  /// [current] may be a different object instance than the queue's copy;
  /// exclusion is by item id.
  List<MediaItem> sameFileSiblings(MediaItem current, {String? playedPartId}) {
    if (!_isQueueMode) return const [];
    final seenIds = <String>{current.id};
    return [
      for (final item in _loadedItems)
        if (seenIds.add(item.id) && current.sharesFileWith(item, playedPartId: playedPartId)) item,
    ];
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

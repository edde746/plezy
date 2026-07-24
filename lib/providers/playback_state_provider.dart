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

/// Outcome of resolving one direction in the active playback queue.
enum QueueNavigationStatus {
  /// The adjacent queue item was found.
  found,

  /// The active queue was loaded successfully and has no item in this direction.
  boundary,

  /// No active queue or matching current item was available.
  unavailable,

  /// A server-backed queue window could not be loaded or validated.
  failed,
}

@immutable
class QueueNavigationResult {
  const QueueNavigationResult._(this.status, this.item);

  const QueueNavigationResult.found(MediaItem item) : this._(QueueNavigationStatus.found, item);

  const QueueNavigationResult.boundary() : this._(QueueNavigationStatus.boundary, null);

  const QueueNavigationResult.unavailable() : this._(QueueNavigationStatus.unavailable, null);

  const QueueNavigationResult.failed() : this._(QueueNavigationStatus.failed, null);

  final QueueNavigationStatus status;
  final MediaItem? item;
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
    if (!_isQueueMode) return null;
    if (item is PlexMediaItem && item.playQueueItemId != null) {
      final id = item.playQueueItemId!;
      final loadedIndex = _findLoadedIndex(id);
      if (loadedIndex == -1 || _loadedItems[loadedIndex].globalKey != item.globalKey) {
        return null;
      }
      return id;
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

  /// Whether [item] belongs to the currently active queue. Plex membership
  /// requires both the server queue id and media identity to match a loaded
  /// entry. Client-side membership uses the exact stored object because
  /// duplicate media entries in playlists must remain distinguishable.
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

  /// Update the queue cursor after playback of [metadata] starts.
  ///
  /// Items outside the active loaded window are rejected. A server-stamped
  /// queue id alone is not proof that an item belongs to this queue.
  void setCurrentItem(MediaItem metadata) {
    if (!_isQueueMode) return;
    final id = playQueueItemIdFor(metadata);
    if (id == null || id == _currentPlayQueueItemID) return;
    _currentPlayQueueItemID = id;
    safeNotifyListeners();
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

  /// Load a server queue window centered on [centerPlayQueueItemID].
  ///
  /// Returns false for transport errors, malformed/empty responses, or when
  /// the requested center is absent from the returned window.
  Future<bool> _loadServerWindow(int centerPlayQueueItemID) async {
    if (_windowFetcher == null || _playQueueId == null) return false;
    try {
      final response = await _windowFetcher!(
        _playQueueId!,
        center: centerPlayQueueItemID.toString(),
        window: _windowSize,
      );
      final items = response?.items;
      if (response == null || items == null || items.isEmpty) return false;

      _loadedItems = items;
      _playQueueTotalCount = response.playQueueTotalCount ?? response.size ?? items.length;
      _playQueueShuffled = response.playQueueShuffled;
      safeNotifyListeners();
      return _findLoadedIndex(centerPlayQueueItemID) != -1;
    } catch (_) {
      return false;
    }
  }

  /// Load a missing queue item without refetching an item already resident.
  Future<bool> _ensureItemsLoaded(int targetPlayQueueItemID) async {
    if (_findLoadedIndex(targetPlayQueueItemID) != -1) return true;
    return _loadServerWindow(targetPlayQueueItemID);
  }

  Future<_IndexLookupResult> _getCurrentIndex(String currentItemKey, {bool loadIfMissing = false}) async {
    if (!_isQueueMode || _loadedItems.isEmpty || _currentPlayQueueItemID == null) {
      return const _IndexLookupResult();
    }

    int findCurrent() {
      final cursorIndex = _findLoadedIndex(_currentPlayQueueItemID!);
      if (cursorIndex != -1 && _matchesItemKey(_loadedItems[cursorIndex], currentItemKey)) {
        return cursorIndex;
      }

      var matchedIndex = -1;
      for (var i = 0; i < _loadedItems.length; i++) {
        if (!_matchesItemKey(_loadedItems[i], currentItemKey)) continue;
        if (matchedIndex != -1) return -1;
        matchedIndex = i;
      }
      return matchedIndex;
    }

    var currentIndex = findCurrent();
    if (currentIndex != -1) return _IndexLookupResult(index: currentIndex);

    if (!loadIfMissing || _windowFetcher == null || _playQueueId == null) {
      return const _IndexLookupResult();
    }

    final loaded = await _ensureItemsLoaded(_currentPlayQueueItemID!);
    if (!loaded) {
      return const _IndexLookupResult(attemptedLoad: true, loadFailed: true);
    }

    currentIndex = findCurrent();
    if (currentIndex == -1) {
      return const _IndexLookupResult(attemptedLoad: true, loadFailed: true);
    }
    return _IndexLookupResult(index: currentIndex, attemptedLoad: true);
  }

  bool _matchesItemKey(MediaItem item, String currentItemKey) =>
      item.id == currentItemKey || item.globalKey == currentItemKey;

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
  ///
  /// Returns a typed result so a queue-window failure cannot be mistaken for
  /// the confirmed end of the queue. Entries backed by the same file as the
  /// one playing are skipped: Plex lists each episode of a multi-episode file
  /// (`S02E24-E25.mkv`) as its own queue item, and advancing to the sibling
  /// would replay the file from the start (#1500). [playedPartId] pins the
  /// comparison to the file of the part actually playing when known;
  /// otherwise any file overlap with the current item counts.
  Future<QueueNavigationResult> getNextEpisode(String currentItemKey, {String? playedPartId}) async {
    if (!_isQueueMode) return const QueueNavigationResult.unavailable();

    final indexResult = await _getCurrentIndex(currentItemKey, loadIfMissing: true);
    if (indexResult.index == null) {
      return indexResult.loadFailed ? const QueueNavigationResult.failed() : const QueueNavigationResult.unavailable();
    }

    final current = _loadedItems[indexResult.index!];
    var anchor = current;
    // Bounded so a pathological all-same-file queue cannot spin.
    for (var steps = 0; steps <= _playQueueTotalCount; steps++) {
      final result = await _itemAfter(anchor);
      final candidate = result.item;
      if (result.status != QueueNavigationStatus.found || candidate == null) {
        return result;
      }
      if (!current.sharesFileWith(candidate, playedPartId: playedPartId)) {
        return result;
      }
      anchor = candidate;
    }
    return const QueueNavigationResult.failed();
  }

  /// Gets the previous item in the playback queue.
  /// Returns null if at the beginning of the queue or current item is not in queue.
  ///
  /// Mirrors [getNextEpisode]'s multi-episode-file handling (#1500): entries
  /// backed by the file that's playing are skipped, and the result is
  /// collapsed to the first episode of its same-file group so a
  /// multi-episode file is entered at the episode that fronts it.
  Future<QueueNavigationResult> getPreviousEpisode(String currentItemKey, {String? playedPartId}) async {
    if (!_isQueueMode) return const QueueNavigationResult.unavailable();

    final indexResult = await _getCurrentIndex(currentItemKey, loadIfMissing: true);
    if (indexResult.index == null) {
      return indexResult.loadFailed ? const QueueNavigationResult.failed() : const QueueNavigationResult.unavailable();
    }

    final current = _loadedItems[indexResult.index!];
    MediaItem candidate = current;
    for (var steps = 0; steps <= _playQueueTotalCount; steps++) {
      final result = await _itemBefore(candidate);
      final before = result.item;
      if (result.status != QueueNavigationStatus.found || before == null) {
        return result;
      }
      candidate = before;
      if (!current.sharesFileWith(candidate, playedPartId: playedPartId)) break;
    }

    // Collapse to the first episode of the candidate's same-file group.
    for (var steps = 0; steps <= _playQueueTotalCount; steps++) {
      final result = await _itemBefore(candidate);
      final before = result.item;
      if (result.status == QueueNavigationStatus.failed) return result;
      if (result.status != QueueNavigationStatus.found || before == null || !candidate.sharesFileWith(before)) {
        return QueueNavigationResult.found(candidate);
      }
      candidate = before;
    }
    return QueueNavigationResult.found(candidate);
  }

  /// The queue item immediately after [anchor], extending a server-backed
  /// window when needed. The centered response proves whether [anchor] is at
  /// the global boundary; a window-local index is never compared with the
  /// queue's global item count.
  Future<QueueNavigationResult> _itemAfter(MediaItem anchor) async {
    final anchorId = playQueueItemIdFor(anchor);
    if (anchorId == null) return const QueueNavigationResult.unavailable();
    var anchorIndex = _findLoadedIndex(anchorId);
    if (anchorIndex == -1) return const QueueNavigationResult.unavailable();

    if (anchorIndex + 1 < _loadedItems.length) {
      return QueueNavigationResult.found(_loadedItems[anchorIndex + 1]);
    }

    // Local queues are fully resident, so their window edge is the queue edge.
    if (_windowFetcher == null || _playQueueId == null) {
      return const QueueNavigationResult.boundary();
    }
    if (_playQueueTotalCount > 0 && _loadedItems.length >= _playQueueTotalCount) {
      return const QueueNavigationResult.boundary();
    }

    // Refresh around the actual anchor. Queue ids are opaque and need not be
    // consecutive, so never guess `anchorId + 1`.
    if (!await _loadServerWindow(anchorId)) {
      return const QueueNavigationResult.failed();
    }
    anchorIndex = _findLoadedIndex(anchorId);
    if (anchorIndex == -1) return const QueueNavigationResult.failed();
    return anchorIndex + 1 < _loadedItems.length
        ? QueueNavigationResult.found(_loadedItems[anchorIndex + 1])
        : const QueueNavigationResult.boundary();
  }

  /// The queue item immediately before [anchor], extending a server-backed
  /// window when needed.
  Future<QueueNavigationResult> _itemBefore(MediaItem anchor) async {
    final anchorId = playQueueItemIdFor(anchor);
    if (anchorId == null) return const QueueNavigationResult.unavailable();
    var anchorIndex = _findLoadedIndex(anchorId);
    if (anchorIndex == -1) return const QueueNavigationResult.unavailable();

    if (anchorIndex > 0) {
      return QueueNavigationResult.found(_loadedItems[anchorIndex - 1]);
    }

    if (_windowFetcher == null || _playQueueId == null) {
      return const QueueNavigationResult.boundary();
    }
    if (_playQueueTotalCount > 0 && _loadedItems.length >= _playQueueTotalCount) {
      return const QueueNavigationResult.boundary();
    }

    if (!await _loadServerWindow(anchorId)) {
      return const QueueNavigationResult.failed();
    }
    anchorIndex = _findLoadedIndex(anchorId);
    if (anchorIndex == -1) return const QueueNavigationResult.failed();
    return anchorIndex > 0
        ? QueueNavigationResult.found(_loadedItems[anchorIndex - 1])
        : const QueueNavigationResult.boundary();
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

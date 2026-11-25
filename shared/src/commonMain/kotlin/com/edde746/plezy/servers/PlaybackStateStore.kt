package com.edde746.plezy.servers

import com.edde746.plezy.model.LocalPlayQueue
import com.edde746.plezy.model.MediaItem
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/** How resolving one direction in the active queue ended. */
enum class QueueNavigationStatus {
    /** The adjacent queue item was found. */
    FOUND,

    /** The queue loaded and has no item in this direction. */
    BOUNDARY,

    /** No active queue, or the current item is not in it. */
    UNAVAILABLE,

    /** A server queue window could not be loaded or validated. */
    FAILED,
}

data class QueueNavigationResult(val status: QueueNavigationStatus, val item: MediaItem? = null) {
    companion object {
        fun found(item: MediaItem) = QueueNavigationResult(QueueNavigationStatus.FOUND, item)
        val BOUNDARY = QueueNavigationResult(QueueNavigationStatus.BOUNDARY)
        val UNAVAILABLE = QueueNavigationResult(QueueNavigationStatus.UNAVAILABLE)
        val FAILED = QueueNavigationResult(QueueNavigationStatus.FAILED)
    }
}

/**
 * The session's playback queue. [loadedItems] is the window of the queue held in memory; for a client-side queue
 * [syntheticIds] holds each item's queue id (parallel to [loadedItems]), for a server queue the ids live on
 * [MediaItem.playQueueItemId].
 */
data class PlaybackQueueState(
    val playQueueId: Int? = null,
    val totalCount: Int = 0,
    val isShuffled: Boolean = false,
    val currentPlayQueueItemId: Int? = null,
    val loadedItems: List<MediaItem> = emptyList(),
    val syntheticIds: List<Int> = emptyList(),
    /** The show, season or playlist the queue was started from. */
    val contextKey: String? = null,
    val isQueueMode: Boolean = false,
) {
    /** Whether playlist/collection mode is on. */
    val isPlaylistActive: Boolean get() = isQueueMode

    val isQueueActive: Boolean get() = playQueueId != null && isQueueMode
}

/**
 * Session-only playback queue: a server play queue (loaded in windows around the playing item) or a client-side
 * queue fully in memory. Never persisted.
 */
class PlaybackStateStore {
    private val _state = MutableStateFlow(PlaybackQueueState())
    val state: StateFlow<PlaybackQueueState> = _state.asStateFlow()

    private var windowFetcher: PlayQueueWindowFetcher? = null

    private val current: PlaybackQueueState get() = _state.value

    val isQueueActive: Boolean get() = current.isQueueActive
    val isShuffleActive: Boolean get() = current.isShuffled
    val isPlaylistActive: Boolean get() = current.isQueueMode
    val shuffleContextKey: String? get() = current.contextKey
    val playQueueId: Int? get() = current.playQueueId
    val currentPlayQueueItemId: Int? get() = current.currentPlayQueueItemId
    val loadedItems: List<MediaItem> get() = current.loadedItems

    /** The item the cursor points at; null with no queue or a cursor outside the loaded window. */
    val currentQueueItem: MediaItem?
        get() {
            val s = current
            val id = s.currentPlayQueueItemId ?: return null
            return s.loadedItems.getOrNull(s.findLoadedIndex(id))
        }

    fun setPlayQueueWindowFetcher(fetcher: PlayQueueWindowFetcher?) {
        windowFetcher = fetcher
    }

    /**
     * [item]'s queue id in the current queue: for a server queue its stamped id, only when a loaded entry has that id
     * and the same item; for a client-side queue the synthetic id of the equal loaded item. Null outside queue mode
     * or when [item] is not in the loaded window.
     */
    fun playQueueItemIdFor(item: MediaItem): Int? = current.idFor(item)

    /**
     * Whether [item] belongs to the active queue. Decides whether the player keeps a queue set by a playlist,
     * collection or shuffle launch instead of replacing it with a sequential show queue.
     */
    fun isItemInActiveQueue(item: MediaItem): Boolean = isQueueActive && playQueueItemIdFor(item) != null

    /** Moves the cursor to [item] once it plays; items not in the loaded queue are ignored. */
    fun setCurrentItem(item: MediaItem) {
        val s = current
        if (!s.isQueueMode) return
        val id = s.idFor(item)
        if (id == null || id == s.currentPlayQueueItemId) return
        _state.value = s.copy(currentPlayQueueItemId = id)
    }

    /** Starts a server play queue. */
    fun setPlaybackFromPlayQueue(playQueue: ServerPlayQueue, contextKey: String?) {
        _state.value = PlaybackQueueState(
            playQueueId = playQueue.id,
            totalCount = playQueue.totalCount ?: playQueue.size ?: playQueue.items?.size ?: 0,
            isShuffled = playQueue.shuffled,
            currentPlayQueueItemId = playQueue.selectedItemId,
            loadedItems = playQueue.items.orEmpty(),
            contextKey = contextKey,
            isQueueMode = true,
        )
    }

    /** Starts a client-side queue: items get synthetic queue ids 0 until n-1; there are no server windows. */
    fun setPlaybackFromLocalQueue(queue: LocalPlayQueue, contextKey: String? = null) {
        windowFetcher = null
        _state.value = PlaybackQueueState(
            playQueueId = LOCAL_QUEUE_ID,
            totalCount = queue.items.size,
            isShuffled = queue.shuffled,
            currentPlayQueueItemId = queue.currentIndex,
            loadedItems = queue.items.toList(),
            syntheticIds = List(queue.items.size) { it },
            contextKey = contextKey,
            isQueueMode = true,
        )
    }

    /** Clears the queue and leaves queue mode. */
    fun clearShuffle() {
        _state.value = PlaybackQueueState()
    }

    /**
     * The next queue item after the one keyed [currentItemKey] (item id or global key). Entries backed by the same
     * file as the current one are skipped: a multi-episode file (`S02E24-E25.mkv`) is listed once per episode, and
     * advancing to a sibling would replay the file. [playedPartId] pins the comparison to the file being
     * played; otherwise any shared file counts.
     */
    suspend fun getNextEpisode(currentItemKey: String, playedPartId: String? = null): QueueNavigationResult {
        if (!current.isQueueMode) return QueueNavigationResult.UNAVAILABLE
        val index = currentIndex(currentItemKey) ?: return lastLookupFailure()
        val playing = current.loadedItems[index]
        var anchor = playing
        for (step in 0..current.totalCount) {
            val result = itemAtOffset(anchor, 1)
            val candidate = result.item
            if (result.status != QueueNavigationStatus.FOUND || candidate == null) return result
            if (!playing.sharesFileWith(candidate, playedPartId)) return result
            anchor = candidate
        }
        return QueueNavigationResult.FAILED
    }

    /**
     * The previous queue item, skipping entries of the playing file and entering a multi-episode file at its first
     * episode.
     */
    suspend fun getPreviousEpisode(currentItemKey: String, playedPartId: String? = null): QueueNavigationResult {
        if (!current.isQueueMode) return QueueNavigationResult.UNAVAILABLE
        val index = currentIndex(currentItemKey) ?: return lastLookupFailure()
        val playing = current.loadedItems[index]
        var candidate = playing
        for (step in 0..current.totalCount) {
            val result = itemAtOffset(candidate, -1)
            val before = result.item
            if (result.status != QueueNavigationStatus.FOUND || before == null) return result
            candidate = before
            if (!playing.sharesFileWith(candidate, playedPartId)) break
        }
        for (step in 0..current.totalCount) {
            val result = itemAtOffset(candidate, -1)
            if (result.status == QueueNavigationStatus.FAILED) return result
            val before = result.item
            if (result.status != QueueNavigationStatus.FOUND || before == null || !candidate.sharesFileWith(before)) {
                return QueueNavigationResult.found(candidate)
            }
            candidate = before
        }
        return QueueNavigationResult.found(candidate)
    }

    /**
     * The other loaded queue items backed by the same file as [current] (the other episodes of a multi-episode
     * file), which share its watched state. Matched by item id, so [current] may be another instance.
     */
    fun sameFileSiblings(current: MediaItem, playedPartId: String? = null): List<MediaItem> {
        val s = this.current
        if (!s.isQueueMode) return emptyList()
        val seen = mutableSetOf(current.id)
        return s.loadedItems.filter { seen.add(it.id) && current.sharesFileWith(it, playedPartId) }
    }

    private var lastLookupLoadFailed = false

    private fun lastLookupFailure(): QueueNavigationResult =
        if (lastLookupLoadFailed) QueueNavigationResult.FAILED else QueueNavigationResult.UNAVAILABLE

    /**
     * The loaded index of the playing item: the cursor's entry when it matches [key], else the single loaded item
     * matching [key]. When missing and the queue is server-backed, loads a window centered on the cursor.
     */
    private suspend fun currentIndex(key: String): Int? {
        lastLookupLoadFailed = false
        val s = current
        val cursor = s.currentPlayQueueItemId
        if (!s.isQueueMode || s.loadedItems.isEmpty() || cursor == null) return null
        findCurrent(current, cursor, key)?.let { return it }
        if (windowFetcher == null || s.playQueueId == null) return null
        val loaded = current.findLoadedIndex(cursor) != -1 || loadServerWindow(cursor)
        val index = if (loaded) findCurrent(current, cursor, key) else null
        if (index == null) lastLookupLoadFailed = true
        return index
    }

    private fun findCurrent(s: PlaybackQueueState, cursor: Int, key: String): Int? {
        val cursorIndex = s.findLoadedIndex(cursor)
        if (cursorIndex != -1 && s.loadedItems[cursorIndex].matchesKey(key)) return cursorIndex
        var matched = -1
        s.loadedItems.forEachIndexed { i, item ->
            if (!item.matchesKey(key)) return@forEachIndexed
            if (matched != -1) return null
            matched = i
        }
        return matched.takeIf { it != -1 }
    }

    /**
     * The item [delta] steps from [anchor], extending a server window around the anchor's real queue id when needed
     * (queue ids are opaque, never guessed). Retries no further.
     */
    private suspend fun itemAtOffset(anchor: MediaItem, delta: Int): QueueNavigationResult {
        val anchorId = current.idFor(anchor) ?: return QueueNavigationResult.UNAVAILABLE
        var anchorIndex = current.findLoadedIndex(anchorId)
        if (anchorIndex == -1) return QueueNavigationResult.UNAVAILABLE
        var target = anchorIndex + delta
        current.loadedItems.getOrNull(target)?.let { return QueueNavigationResult.found(it) }

        val s = current
        if (windowFetcher == null || s.playQueueId == null) return QueueNavigationResult.BOUNDARY
        if (s.totalCount > 0 && s.loadedItems.size >= s.totalCount) return QueueNavigationResult.BOUNDARY

        if (!loadServerWindow(anchorId)) return QueueNavigationResult.FAILED
        anchorIndex = current.findLoadedIndex(anchorId)
        if (anchorIndex == -1) return QueueNavigationResult.FAILED
        target = anchorIndex + delta
        return current.loadedItems.getOrNull(target)?.let { QueueNavigationResult.found(it) } ?: QueueNavigationResult.BOUNDARY
    }

    /**
     * Loads the server window centered on [center]. False on a transport error, an empty response, a window without
     * [center], or when the queue was cleared or replaced meanwhile: a window never overwrites another queue.
     */
    private suspend fun loadServerWindow(center: Int): Boolean {
        val fetcher = windowFetcher ?: return false
        val queueId = current.playQueueId ?: return false
        return try {
            val response = fetcher.fetch(queueId, center.toString(), WINDOW_SIZE)
            val s = current
            if (s.playQueueId != queueId || !s.isQueueMode || response == null) return false
            val items = response.items
            if (items.isNullOrEmpty()) return false
            val next = s.copy(
                loadedItems = items,
                totalCount = response.totalCount ?: response.size ?: items.size,
                isShuffled = response.shuffled,
            )
            _state.value = next
            next.findLoadedIndex(center) != -1
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            false
        }
    }

    private fun MediaItem.matchesKey(key: String) = id == key || globalKey == key

    private fun PlaybackQueueState.findLoadedIndex(playQueueItemId: Int): Int = loadedItems.indices.firstOrNull { i ->
        loadedItems[i].playQueueItemId == playQueueItemId || syntheticIds.getOrNull(i) == playQueueItemId
    } ?: -1

    private fun PlaybackQueueState.idFor(item: MediaItem): Int? {
        if (!isQueueMode) return null
        val stamped = item.playQueueItemId
        if (stamped != null) {
            val index = findLoadedIndex(stamped)
            if (index == -1 || loadedItems[index].globalKey != item.globalKey) return null
            return stamped
        }
        val index = loadedItems.indexOf(item)
        return syntheticIds.getOrNull(index)
    }

    private companion object {
        /** Queue id of a client-side queue. */
        const val LOCAL_QUEUE_ID = -1
        const val WINDOW_SIZE = 50
    }
}

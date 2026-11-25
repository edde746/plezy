package com.edde746.plezy.music

import com.edde746.plezy.model.MediaItem
import kotlin.random.Random

/**
 * A copy of the queue's whole state, for the persisted session: [order] indexes [items] (canonical order), [cursor]
 * indexes [order].
 */
data class MusicQueueState(
    val items: List<MediaItem>,
    val order: List<Int>,
    val cursor: Int,
    val shuffled: Boolean,
    val repeatMode: MusicRepeatMode,
)

/**
 * The music queue's state, no I/O and no player: the canonical track list (insertion order), the playback order
 * (indexes into it; the identity while unshuffled) and the cursor into the playback order. Every index callers pass
 * ([jumpTo], [removeAt], [move]) is a playback-order index, the list [queue] shows.
 *
 * It only changes state; what to do about it (open a track, re-arm gapless, stop) is the session's job.
 */
class MusicQueueController(private val random: Random = Random.Default) {
    private val items = mutableListOf<MediaItem>()
    private var order = mutableListOf<Int>()

    /** The current entry's position in the playback order; −1 when empty. */
    var cursor = -1
        private set
    var shuffled = false
        private set
    var repeatMode = MusicRepeatMode.OFF

    val isEmpty: Boolean get() = items.isEmpty()
    val length: Int get() = order.size
    val current: MediaItem? get() = trackAt(cursor)

    /** The queue in playback order. */
    val queue: List<MediaItem> get() = order.map { items[it] }

    fun trackAt(queueIndex: Int): MediaItem? = order.getOrNull(queueIndex)?.let { items[it] }

    /** A copy with the canonical order and the shuffle permutation, so a restored queue still unshuffles. */
    fun captureState() = MusicQueueState(items.toList(), order.toList(), cursor, shuffled, repeatMode)

    /**
     * Restores [state]; false, leaving the queue untouched, when it breaks the queue's invariants (empty, the order
     * not a permutation of the items, the cursor out of range): a corrupt snapshot never makes a half-valid session.
     */
    fun restoreState(state: MusicQueueState): Boolean {
        val size = state.items.size
        if (size == 0 || state.order.size != size || state.cursor !in 0 until size) return false
        val seen = BooleanArray(size)
        for (index in state.order) {
            if (index !in 0 until size || seen[index]) return false
            seen[index] = true
        }
        items.clear()
        items += state.items
        order = state.order.toMutableList()
        cursor = state.cursor
        shuffled = state.shuffled
        repeatMode = state.repeatMode
        return true
    }

    /**
     * Replaces the queue with [tracks] starting at [startIndex]. With [shuffle], an explicit [startIndex] plays first
     * and the rest shuffle after it; none shuffles the whole list, head included (no track has to play first).
     */
    fun load(tracks: List<MediaItem>, startIndex: Int? = null, shuffle: Boolean = false) {
        items.clear()
        items += tracks
        order = tracks.indices.toMutableList()
        shuffled = false
        cursor = if (tracks.isEmpty()) -1 else (startIndex ?: 0).coerceIn(0, tracks.size - 1)
        if (!shuffle || tracks.isEmpty()) return
        if (startIndex == null) shuffleAll() else shuffleAnchoringCurrent()
    }

    fun clear() {
        items.clear()
        order = mutableListOf()
        cursor = -1
        shuffled = false
    }

    /**
     * The playback-order position after the current one, or null when playback ends here. A natural advance
     * ([manual] false) repeats the current entry under repeat-one; a manual next always steps on.
     */
    fun nextIndex(manual: Boolean = false): Int? {
        if (order.isEmpty() || cursor < 0) return null
        if (repeatMode == MusicRepeatMode.ONE && !manual) return cursor
        val next = cursor + 1
        if (next < order.size) return next
        return if (repeatMode == MusicRepeatMode.ALL) 0 else null
    }

    /** The playback-order position before the current one, or null (the session restarts the track then). */
    fun previousIndex(): Int? {
        if (order.isEmpty() || cursor < 0) return null
        val previous = cursor - 1
        if (previous >= 0) return previous
        return if (repeatMode == MusicRepeatMode.ALL) order.size - 1 else null
    }

    fun jumpTo(queueIndex: Int) {
        if (queueIndex in order.indices) cursor = queueIndex
    }

    /** Inserts [tracks] right after the current entry. */
    fun addNext(tracks: List<MediaItem>) {
        if (tracks.isEmpty()) return
        order.addAll(if (cursor < 0) 0 else cursor + 1, append(tracks))
        if (cursor < 0) cursor = 0
    }

    fun addToEnd(tracks: List<MediaItem>) {
        if (tracks.isEmpty()) return
        order.addAll(append(tracks))
        if (cursor < 0) cursor = 0
    }

    private fun append(tracks: List<MediaItem>): List<Int> {
        val first = items.size
        items += tracks
        return List(tracks.size) { first + it }
    }

    /**
     * Removes the entry at [queueIndex]; true when it was the current one. The cursor then points at what was next
     * (the new last entry when the current one was last; −1 when the queue emptied) and the caller decides whether to
     * open it.
     */
    fun removeAt(queueIndex: Int): Boolean {
        if (queueIndex !in order.indices) return false
        val wasCurrent = queueIndex == cursor
        val itemIndex = order.removeAt(queueIndex)
        dropItem(itemIndex)
        if (queueIndex < cursor) {
            cursor--
        } else if (cursor >= order.size) {
            cursor = order.size - 1
        }
        return wasCurrent
    }

    /** Moves the entry at [from] to [to] (playback-order indexes); the cursor stays on the current track. */
    fun move(from: Int, to: Int) {
        if (from !in order.indices || to !in order.indices || from == to) return
        order.add(to, order.removeAt(from))
        when {
            from == cursor -> cursor = to
            from < cursor && to >= cursor -> cursor--
            from > cursor && to <= cursor -> cursor++
        }
    }

    /**
     * On: the current track goes first and the rest shuffle after it. Off: the canonical order comes back with the
     * cursor on the current track.
     */
    fun toggleShuffle() {
        if (items.isEmpty()) return
        if (shuffled) {
            val currentItem = order[cursor]
            order = items.indices.toMutableList()
            cursor = currentItem
            shuffled = false
        } else {
            shuffleAnchoringCurrent()
        }
    }

    private fun shuffleAnchoringCurrent() {
        val anchor = order[if (cursor < 0) 0 else cursor]
        val rest = order.filter { it != anchor }.toMutableList().apply { shuffle(random) }
        order = (listOf(anchor) + rest).toMutableList()
        cursor = 0
        shuffled = true
    }

    private fun shuffleAll() {
        order.shuffle(random)
        cursor = 0
        shuffled = true
    }

    /** Drops every entry after the current one, from the canonical list too (unshuffling doesn't bring them back). */
    fun clearUpcoming() {
        if (cursor < 0 || cursor >= order.size - 1) return
        order = order.subList(0, cursor + 1).toMutableList()
        // One pass: compact the kept items in canonical order, then remap the order onto their new indices.
        val newIndex = IntArray(items.size) { -1 }
        for (itemIndex in order) newIndex[itemIndex] = 0
        var kept = 0
        for (itemIndex in items.indices) {
            if (newIndex[itemIndex] < 0) continue
            items[kept] = items[itemIndex]
            newIndex[itemIndex] = kept++
        }
        items.subList(kept, items.size).clear()
        for (i in order.indices) order[i] = newIndex[order[i]]
    }

    private fun dropItem(itemIndex: Int) {
        items.removeAt(itemIndex)
        for (i in order.indices) if (order[i] > itemIndex) order[i]--
    }
}

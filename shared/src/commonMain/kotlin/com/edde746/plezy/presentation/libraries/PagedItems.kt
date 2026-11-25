package com.edde746.plezy.presentation.libraries

import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.presentation.browse.MediaCardUi
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.TimeMark
import kotlin.time.TimeSource

/**
 * A long list loaded page by page into index-addressed slots, so a grid can show any part of it (a skeleton for a slot
 * not loaded yet). Pages load around what is visible, a failed page retries after 1, 2, 4, 8, 8… seconds, distant
 * pages are evicted, and a reset drops whatever was in flight. Main thread only.
 *
 * @param fetchPage the page of [size] items from [start]; throws on failure.
 * @param onChanged called after every change of [items], [total] or [error].
 */
class PagedItems<T>(
    private val scope: CoroutineScope,
    private val fetchPage: suspend (start: Int, size: Int) -> LibraryPage<T>,
    private val onChanged: () -> Unit,
    private val timeSource: TimeSource = TimeSource.Monotonic,
) {
    private val loaded = HashMap<Int, T>()
    private val loading = HashSet<Int>()
    private val jobs = HashSet<Job>()
    private var generation = 0
    private var retryCount = 0
    private var retryJob: Job? = null
    private var scheduledRetry: (suspend () -> Unit)? = null
    private var rangeLoading = false
    private var lastPrefetch: TimeMark? = null

    /** The page size of a full page whose total was a guess (one past what came): the tail asks for a full page. */
    private var openEndedPageSize: Int? = null

    /** The loaded items by index. */
    val items: Map<Int, T> get() = loaded

    /** How many items the list has; 0 before the first page. */
    var total: Int = 0
        private set

    /** The last page fetch's failure, until the next fetch starts. */
    var error: Throwable? = null
        private set

    val isLoading: Boolean get() = loading.isNotEmpty()

    /** Drops every item and whatever is in flight: a fetch that lands after is ignored. */
    fun reset() {
        retire()
        retryCount = 0
        lastPrefetch = null
        error = null
        openEndedPageSize = null
        loaded.clear()
        total = 0
    }

    /**
     * Fetches the first page of [pageSize] and shows it; null when a reset superseded it. Throws the fetch's failure
     * (for the current generation only: a superseded failure returns null).
     */
    suspend fun loadInitial(pageSize: Int): LibraryPage<T>? {
        val asked = generation
        val page = try {
            fetchPage(0, pageSize)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            if (asked != generation) return null
            throw e
        }
        if (asked != generation) return null
        page.items.forEachIndexed { i, item -> loaded[i] = item }
        total = page.totalCount
        trackOpenEndedTotal(0, pageSize, page)
        onChanged()
        return page
    }

    /** Loads every missing slot from [firstIndex] − [buffer] to [firstIndex] + [visibleCount] + [buffer]. */
    suspend fun ensureRangeLoaded(firstIndex: Int, visibleCount: Int, buffer: Int = 100) {
        while (true) {
            if (rangeLoading || total == 0) return
            val from = (firstIndex - buffer).coerceIn(0, total)
            val to = (firstIndex + visibleCount + buffer).coerceIn(0, total)
            val missing = (from until to).filter { it !in loaded && it !in loading }
            if (missing.isEmpty()) return
            retryJob?.cancel()
            scheduledRetry = { ensureRangeLoaded(firstIndex, visibleCount, buffer) }
            rangeLoading = true
            val ok = try {
                fetchRange(missing.first(), missing.last() + 1 - missing.first())
            } finally {
                rangeLoading = false
            }
            if (!ok) return
        }
    }

    /**
     * Fetches ahead of a scroll, at most every 100 ms: the page after the visible span, else the page ending at the
     * first gap behind it.
     */
    fun prefetchAhead(firstIndex: Int, visibleCount: Int, pageSize: Int = 200) {
        if (total == 0) return
        if (lastPrefetch?.let { it.elapsedNow() < PREFETCH_THROTTLE } == true) return
        val aheadStart = (firstIndex + visibleCount).coerceIn(0, total)
        val aheadEnd = (aheadStart + visibleCount).coerceIn(0, total)
        for (i in aheadStart until aheadEnd) {
            if (i !in loaded && i !in loading) {
                lastPrefetch = timeSource.markNow()
                launchFetch(i, pageSize)
                return
            }
        }
        val behindStart = (firstIndex - visibleCount).coerceIn(0, total)
        for (i in firstIndex - 1 downTo behindStart) {
            if (i !in loaded && i !in loading) {
                lastPrefetch = timeSource.markNow()
                val start = (i - pageSize + 1).coerceIn(0, i)
                launchFetch(start, i - start + 1)
                return
            }
        }
    }

    /**
     * Fetches the rest of the page of [pageSize] holding [index], from past the page's loaded prefix (a page that came
     * back short of [index] would come back short again), unless [index] is loaded or loading.
     */
    fun ensureIndexLoaded(index: Int, pageSize: Int = 200) {
        if (total == 0 || index !in 0 until total) return
        if (index in loaded || index in loading) return
        scheduledRetry = { ensureIndexLoaded(index, pageSize) }
        val pageStart = index / pageSize * pageSize
        var start = pageStart
        while (start < index && start in loaded) start++
        launchFetch(start, pageStart + pageSize - start)
    }

    /** Once more than [threshold] items are loaded, keeps only the [maxKeep] around [centerIndex]. */
    fun evictDistant(centerIndex: Int, maxKeep: Int = 500, threshold: Int = 600) {
        if (loaded.size <= threshold) return
        val half = maxKeep / 2
        loaded.keys.removeAll { it < centerIndex - half || it > centerIndex + half }
        onChanged()
    }

    /** Removes the item at [index] (a deletion): the items after it move down one, the total drops by one. */
    fun removeAndShift(index: Int) {
        retire()
        loaded.remove(index)
        val shifted = loaded.mapKeys { (i, _) -> if (i > index) i - 1 else i }
        loaded.clear()
        loaded.putAll(shifted)
        total = (total - 1).coerceAtLeast(0)
        onChanged()
    }

    /** Replaces the item at [index] with [item] if the slot still holds [current]. */
    fun replace(index: Int, current: T, item: T) {
        if (loaded[index] !== current) return
        loaded[index] = item
        onChanged()
    }

    /** Where an item was and is after [repopulate], by [idOf]. */
    data class Anchor(val oldIndex: Int?, val newIndex: Int?)

    /**
     * Fetches the loaded span again in one request and swaps it in place (a server push): nothing clears meanwhile.
     * A span wider than [maxSpan] is first cut to [maxSpan] around [windowCenter]. Null when nothing was loaded, the
     * fetch failed or a reset superseded it.
     */
    suspend fun repopulate(idOf: (T) -> String, anchorId: String? = null, maxSpan: Int? = null, windowCenter: Int? = null): Anchor? {
        if (loaded.isEmpty() || total == 0) return null
        var indices = loaded.keys.sorted()
        if (maxSpan != null && indices.last() - indices.first() + 1 > maxSpan) {
            val center = (windowCenter ?: indices.first()).coerceIn(indices.first(), indices.last())
            val low = center - maxSpan / 2
            loaded.keys.removeAll { it < low || it >= low + maxSpan }
            if (loaded.isEmpty()) return null
            indices = loaded.keys.sorted()
        }
        val start = indices.first()
        val size = indices.last() - start + 1
        val oldIndex = anchorId?.let { id -> loaded.entries.firstOrNull { idOf(it.value) == id }?.key }
        retire()
        val asked = generation
        val page = try {
            fetchPage(start, size)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Refetching the loaded span failed" }
            return null
        }
        if (asked != generation) return null
        val newIndex = anchorId?.let { id -> page.items.indexOfFirst { idOf(it) == id }.takeIf { it >= 0 }?.plus(start) }
        loaded.keys.removeAll { it in start until start + size }
        page.items.forEachIndexed { i, item -> loaded[start + i] = item }
        total = page.totalCount
        loaded.keys.removeAll { it >= total }
        trackOpenEndedTotal(start, size, page)
        onChanged()
        return Anchor(oldIndex, newIndex)
    }

    private fun retire() {
        generation++
        jobs.toList().forEach { it.cancel() }
        jobs.clear()
        retryJob?.cancel()
        retryJob = null
        loading.clear()
        scheduledRetry = null
        rangeLoading = false
    }

    private fun launchFetch(start: Int, size: Int) {
        val job = scope.launch { fetchRange(start, size) }
        jobs += job
        job.invokeOnCompletion { jobs -= job }
    }

    private fun trackOpenEndedTotal(start: Int, requested: Int, page: LibraryPage<T>) {
        val count = page.items.size
        openEndedPageSize = if (requested > 0 && count >= requested && page.totalCount == start + count + 1) requested else null
    }

    private suspend fun fetchRange(start: Int, size: Int): Boolean {
        if (start >= total) return false
        val clamped = size.coerceIn(0, total - start)
        if (clamped == 0) return false
        val indices = start until start + clamped
        if (indices.all { it in loading || it in loaded }) return true
        loading += indices
        error = null
        onChanged()
        val openEnded = openEndedPageSize
        val requestSize = if (openEnded != null && start + clamped >= total) maxOf(size, openEnded) else clamped
        val asked = generation
        try {
            val page = fetchPage(start, requestSize)
            if (asked != generation) return false
            page.items.forEachIndexed { i, item -> loaded[start + i] = item }
            // An empty page means nothing exists from start on, whatever count came with it: a count running ahead of
            // what the server serves (a library mid-scan) would have this range asked for again and again.
            if (page.items.isEmpty()) {
                total = minOf(start, page.totalCount)
                loaded.keys.removeAll { it >= total }
            } else {
                total = page.totalCount
            }
            trackOpenEndedTotal(start, requestSize, page)
            retryCount = 0
            return true
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            if (asked != generation || (e is MediaServerHttpException && e.isCancellation)) return false
            Log.w(TAG, e) { "Loading items $start–${start + requestSize} failed" }
            error = e
            retryCount++
            val retry = scheduledRetry
            retryJob?.cancel()
            retryJob = scope.launch {
                delay(retryDelay(retryCount))
                if (asked != generation) return@launch
                // Cleared first: the retry's own ensureRangeLoaded cancels a pending retryJob.
                retryJob = null
                retry?.invoke()
            }
            return false
        } finally {
            if (asked == generation) {
                loading -= indices
                onChanged()
            }
        }
    }

    companion object {
        private const val TAG = "PagedItems"
        private val PREFETCH_THROTTLE = 100.milliseconds

        /** The wait before the [attempt]th retry: 500 ms × 2^min(attempt, 4). */
        fun retryDelay(attempt: Int): Duration = (500L * (1L shl attempt.coerceIn(0, 4))).milliseconds
    }
}

/**
 * The cards of a [PagedItems]' loaded items, each made once and kept while its slot holds the same item and the cards
 * are made under the same [cards] key (the client, the card settings, the shape): a page that lands makes cards for its
 * own items alone, and an unchanged list gives back equal cards, which a state flow doesn't emit again.
 */
internal class PagedCards<T> {
    private var key: Any? = null
    private var made = HashMap<Int, Pair<T, MediaCardUi>>()

    fun cards(items: Map<Int, T>, key: Any?, make: (T) -> MediaCardUi): Map<Int, MediaCardUi> {
        if (key != this.key) {
            made = HashMap()
            this.key = key
        }
        val next = HashMap<Int, Pair<T, MediaCardUi>>(items.size)
        val cards = HashMap<Int, MediaCardUi>(items.size)
        for ((index, item) in items) {
            val kept = made[index]?.takeIf { it.first === item }
            val card = kept?.second ?: make(item)
            next[index] = item to card
            cards[index] = card
        }
        made = next
        return cards
    }
}

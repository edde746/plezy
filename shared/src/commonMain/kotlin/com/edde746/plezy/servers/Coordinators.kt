package com.edde746.plezy.servers

import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Duration
import kotlin.time.TimeMark
import kotlin.time.TimeSource

/**
 * Coalesces full and targeted delta loads behind one in-flight drain.
 *
 * A full load takes priority and supersedes every queued delta. Requests made while a pass runs share the drain's
 * [Deferred] and are replayed as trailing work: deltas requested during a pass are unioned into one trailing pass. The
 * first pass starts before the request returns. The callbacks own fetch, commit and failure policy; a callback's
 * failure ends the drain and fails the shared [Deferred].
 *
 * Call from one thread (the main dispatcher).
 */
class CoalescedLoadCoordinator<T>(
    private val scope: CoroutineScope,
    private val onFull: suspend () -> Unit,
    private val onDelta: suspend (Set<T>) -> Unit,
) {
    private val pendingDelta = LinkedHashSet<T>()
    private var inFlight: CompletableDeferred<Unit>? = null
    private var pendingFull = false
    private var runningFull = false
    private var disposed = false

    /** A pass is running (or queued behind the running one). */
    val isBusy: Boolean get() = inFlight != null

    /** The busy work includes a full pass, running or queued. A drain of deltas only doesn't cover a full refetch. */
    val isFullActive: Boolean get() = pendingFull || runningFull

    fun requestFull(): Deferred<Unit> {
        if (disposed) return CompletableDeferred(Unit)
        pendingFull = true
        return ensureDrain()
    }

    fun requestDelta(values: Iterable<T>): Deferred<Unit> {
        if (disposed) return CompletableDeferred(Unit)
        pendingDelta.addAll(values)
        if (pendingDelta.isEmpty()) return inFlight ?: CompletableDeferred(Unit)
        return ensureDrain()
    }

    /** Discards trailing work without interrupting the running callback. */
    fun clearPending() {
        if (disposed) return
        pendingFull = false
        pendingDelta.clear()
    }

    /** Prevents new work and discards work queued behind the running callback. */
    fun dispose() {
        disposed = true
        pendingFull = false
        pendingDelta.clear()
    }

    private fun ensureDrain(): Deferred<Unit> {
        inFlight?.let { return it }
        // Installed before a callback runs, so a reentrant request queues behind this drain instead of starting one.
        val drain = CompletableDeferred<Unit>()
        inFlight = drain
        scope.launch(start = CoroutineStart.UNDISPATCHED) {
            val outcome = runCatching { drainPending() }
            if (inFlight === drain) inFlight = null
            outcome.fold({ drain.complete(Unit) }, { drain.completeExceptionally(it) })
        }
        return drain
    }

    private suspend fun drainPending() {
        while ((pendingFull || pendingDelta.isNotEmpty()) && !disposed) {
            if (pendingFull) {
                pendingFull = false
                pendingDelta.clear()
                runningFull = true
                try {
                    onFull()
                } finally {
                    runningFull = false
                }
            } else {
                val values = pendingDelta.toSet()
                pendingDelta.clear()
                onDelta(values)
            }
        }
    }
}

/**
 * One page a [ContinuationPaginationCoordinator] consumed. [consumedCount] is apart from [items]' size: a screen may
 * filter the wire items while the backend cursor still advances by the records the response consumed.
 */
data class ContinuationPage<T>(val items: List<T>, val totalCount: Int, val consumedCount: Int)

enum class ContinuationLoadStatus { COMPLETED, FAILED, STALE, IDLE }

/**
 * Loads the rest of an indexed list page by page. Owns cursor advancement, generation invalidation, retry state,
 * stale-result rejection and request coalescing; the screen owns item mapping through [onPage].
 *
 * Call from one thread (the main dispatcher).
 */
class ContinuationPaginationCoordinator<T>(
    private val scope: CoroutineScope,
    private val loadPage: suspend (startIndex: Int) -> ContinuationPage<T>,
    private val onPage: (ContinuationPage<T>) -> Unit,
    private val onStateChanged: (() -> Unit)? = null,
    private val onError: ((Throwable) -> Unit)? = null,
) {
    private var generation = 0
    private var inFlight: Deferred<ContinuationLoadStatus>? = null
    private var inFlightGeneration: Int? = null
    private var disposed = false

    var nextStartIndex: Int? = null
        private set
    var totalCount: Int? = null
        private set
    var isLoading: Boolean = false
        private set
    var error: Throwable? = null
        private set

    val hasMore: Boolean get() = nextStartIndex != null

    /** Invalidates all prior work, runs [request], and returns whether its result still belongs to the current generation. */
    suspend fun runNewGeneration(request: suspend () -> Unit): Boolean {
        val generation = beginGeneration()
        try {
            request()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Throwable) {
            if (!isCurrent(generation)) return false
            throw e
        }
        return isCurrent(generation)
    }

    /** Seeds the cursor from an accepted first response. */
    fun setContinuation(startIndex: Int, totalCount: Int) {
        if (disposed) return
        this.totalCount = totalCount
        nextStartIndex = if (startIndex < totalCount) startIndex else null
        error = null
        onStateChanged?.invoke()
    }

    /** Loads every remaining page. Calls while this generation loads share one operation and issue no extra requests. */
    fun loadRemaining(): Deferred<ContinuationLoadStatus> {
        inFlight?.let { return it }
        if (disposed || nextStartIndex == null) return CompletableDeferred(ContinuationLoadStatus.IDLE)
        val generation = generation
        inFlightGeneration = generation
        val operation = scope.async(start = CoroutineStart.UNDISPATCHED) { loadRemaining(generation) }
        // A load that settled without suspending has already released its slot.
        if (inFlightGeneration == generation) inFlight = operation
        return operation
    }

    /** Retries from the first cursor that did not complete. */
    fun retry(): Deferred<ContinuationLoadStatus> = loadRemaining()

    /** Invalidates pending results and suppresses later callbacks. */
    fun dispose() {
        if (disposed) return
        disposed = true
        generation++
        resetState()
    }

    private fun beginGeneration(): Int {
        generation++
        resetState()
        if (!disposed) onStateChanged?.invoke()
        return generation
    }

    private fun resetState() {
        nextStartIndex = null
        totalCount = null
        inFlight = null
        inFlightGeneration = null
        isLoading = false
        error = null
    }

    private fun isCurrent(generation: Int): Boolean = !disposed && generation == this.generation

    private suspend fun loadRemaining(generation: Int): ContinuationLoadStatus {
        isLoading = true
        error = null
        onStateChanged?.invoke()
        try {
            while (isCurrent(generation)) {
                val startIndex = nextStartIndex ?: return ContinuationLoadStatus.COMPLETED
                val page = loadPage(startIndex)
                if (!isCurrent(generation)) return ContinuationLoadStatus.STALE
                if (page.consumedCount <= 0) {
                    totalCount = page.totalCount
                    nextStartIndex = null
                    onStateChanged?.invoke()
                    return ContinuationLoadStatus.COMPLETED
                }
                onPage(page)
                totalCount = page.totalCount
                val next = startIndex + page.consumedCount
                nextStartIndex = if (next < page.totalCount) next else null
                onStateChanged?.invoke()
            }
            return ContinuationLoadStatus.STALE
        } catch (e: CancellationException) {
            throw e
        } catch (e: Throwable) {
            if (!isCurrent(generation)) return ContinuationLoadStatus.STALE
            error = e
            onError?.invoke(e)
            return ContinuationLoadStatus.FAILED
        } finally {
            if (isCurrent(generation)) {
                isLoading = false
                onStateChanged?.invoke()
            }
            if (inFlightGeneration == generation) {
                inFlight = null
                inFlightGeneration = null
            }
        }
    }
}

/**
 * Paces push-triggered refreshes behind three windows: a [debounce] that merges an event burst into one pass, a
 * [blockedRetry] loop that waits out a surface the refresh would disturb, and a [cooldown] that bounds pass frequency
 * during sustained streams while deferring the owed pass to the window's trailing edge, so the last change lands.
 *
 * The debounce arms once per burst and later events never push it back: a steady stream of events closer than
 * [debounce] cannot starve the pass. [runPass] returns whether a pass started; a dropped pass does not spend the
 * cooldown. [notePass] credits an equivalent refresh made elsewhere (a pull), restarting the cooldown window.
 *
 * Call from one thread (the main dispatcher).
 */
class RefreshPacer(
    private val scope: CoroutineScope,
    val debounce: Duration,
    val cooldown: Duration,
    val blockedRetry: Duration,
    private val isBlocked: () -> Boolean,
    private val runPass: () -> Boolean,
    private val timeSource: TimeSource = TimeSource.Monotonic,
) {
    /** The debounce, blocked-retry or trailing-edge timer: any of them means a pass is owed. */
    private var timer: Job? = null
    private var lastPassAt: TimeMark? = null
    private var disposed = false

    /** An event arrived. No-op while a pass is already owed. */
    fun schedule() {
        if (disposed) return
        if (timer?.isActive == true) return
        timer = after(debounce)
    }

    /** An equivalent refresh committed elsewhere: the cooldown window restarts now, and an owed pass defers to its edge. */
    fun notePass() {
        if (disposed) return
        lastPassAt = timeSource.markNow()
    }

    fun dispose() {
        disposed = true
        timer?.cancel()
        timer = null
    }

    private fun after(wait: Duration): Job = scope.launch {
        delay(wait)
        timer = null
        fire()
    }

    private fun fire() {
        if (disposed) return
        if (isBlocked()) {
            timer = after(blockedRetry)
            return
        }
        val remaining = lastPassAt?.let { cooldown - it.elapsedNow() }
        if (remaining != null && remaining > Duration.ZERO) {
            // Re-checks the window on fire, in case notePass moved it meanwhile.
            timer = after(remaining)
            return
        }
        if (runPass()) lastPassAt = timeSource.markNow()
    }
}

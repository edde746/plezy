package com.edde746.plezy.seerr

import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.CompletableDeferred

/**
 * Concurrent [run]s share the first one's result or failure; once it settles the next [run] starts afresh. When the
 * first caller is cancelled, the callers waiting on it run the block themselves rather than inherit the cancellation.
 *
 * Not thread-safe: every call stays on one dispatcher that runs a coroutine at a time (the Seerr clients' and accounts'
 * serial dispatcher).
 */
internal class SerialCoalescer<T> {
    private var inFlight: CompletableDeferred<T>? = null

    private class OwnerCancelled : Exception()

    suspend fun run(block: suspend () -> T): T {
        while (true) {
            val shared = inFlight
            if (shared != null) {
                try {
                    return shared.await()
                } catch (_: OwnerCancelled) {
                    continue
                }
            }
            val owned = CompletableDeferred<T>().also { inFlight = it }
            try {
                return block().also { owned.complete(it) }
            } catch (e: Throwable) {
                owned.completeExceptionally(if (e is CancellationException) OwnerCancelled() else e)
                throw e
            } finally {
                if (inFlight === owned) inFlight = null
            }
        }
    }

    /** Detaches the run in flight: it goes on, but the next [run] starts a new one. */
    fun reset() {
        inFlight = null
    }
}

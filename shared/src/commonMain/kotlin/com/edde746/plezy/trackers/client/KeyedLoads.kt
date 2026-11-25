package com.edde746.plezy.trackers.client

import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update

/**
 * One load per key at a time: callers asking for a key while its load runs share that load's answer or failure.
 *
 * With [memoize], a successful answer stays until [remove] or [clear], and only a failure lets the next call load
 * again; without it, every call after a load ended starts a new one. A load whose caller was cancelled hands the
 * key to the next caller waiting on it, which loads again. Safe from any thread.
 */
internal class KeyedLoads<K, V>(private val memoize: Boolean) {
    private val entries = MutableStateFlow<Map<K, CompletableDeferred<V>>>(emptyMap())

    /**
     * [key]'s answer: the memoized or running load's, else [load]'s. [onError] runs once per failed load, before every
     * caller sharing it gets the failure.
     */
    suspend fun run(key: K, onError: (Throwable) -> Unit = {}, load: suspend () -> V): V {
        while (true) {
            val created = CompletableDeferred<V>()
            var entry = created
            entries.update { current ->
                val running = current[key]
                entry = running ?: created
                if (running == null) current + (key to created) else current
            }
            if (entry === created) return loadInto(key, created, onError, load)
            try {
                return entry.await()
            } catch (e: CancellationException) {
                // This caller was cancelled, or the one loading for it was: then load again.
                currentCoroutineContext().ensureActive()
            }
        }
    }

    /** Forgets [key]'s answer; callers of a load still running keep it. */
    fun remove(key: K) {
        entries.update { it - key }
    }

    fun clear() {
        entries.value = emptyMap()
    }

    private suspend fun loadInto(key: K, entry: CompletableDeferred<V>, onError: (Throwable) -> Unit, load: suspend () -> V): V {
        val value = try {
            load()
        } catch (e: Throwable) {
            evict(key, entry)
            if (e !is CancellationException) onError(e)
            entry.completeExceptionally(e)
            throw e
        }
        if (!memoize) evict(key, entry)
        entry.complete(value)
        return value
    }

    /** Drops [entry] while it is still [key]'s: a [remove] or [clear] meanwhile may have let a newer load in. */
    private fun evict(key: K, entry: CompletableDeferred<V>) {
        entries.update { if (it[key] === entry) it - key else it }
    }
}

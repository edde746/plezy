package com.edde746.plezy.servers

import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Clock

/** Where [LocalPlaybackHistory] persists its map (the `local_last_played_at` preference). */
interface LocalPlaybackHistoryStore {
    suspend fun read(): Map<String, Long>

    suspend fun write(history: Map<String, Long>)
}

/**
 * When items were last played on this device (epoch ms), keyed by the item's global key and, for episodes and
 * seasons, the series' too. Servers have no per-version or per-sibling "last played", so this is what lets
 * Continue Watching keep the copy the user actually played.
 */
class LocalPlaybackHistory(private val store: LocalPlaybackHistoryStore, private val clock: Clock = Clock.System) {
    private var lastRecordedKey: String? = null
    private var lastRecordedAtMs = 0L

    /**
     * Records that [item] just started. A repeat for the same item within a minute is skipped (reloads re-commit the
     * same session). Keeps the newest [MAX_ENTRIES]. Best effort: failures are logged, never thrown.
     */
    suspend fun recordPlayback(item: MediaItem) {
        val now = clock.now().toEpochMilliseconds()
        val key = item.globalKey
        if (key == lastRecordedKey && now - lastRecordedAtMs < REWRITE_INTERVAL_MS) return
        try {
            val updated = store.read().toMutableMap()
            updated[key] = now
            item.seriesGlobalKey?.let { updated[it] = now }
            store.write(prune(updated))
            lastRecordedKey = key
            lastRecordedAtMs = now
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "failed to record local playback history for $key" }
        }
    }

    /** The whole history for one dedup pass; empty when it can't be read. */
    suspend fun snapshot(): Map<String, Long> = try {
        store.read()
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "failed to read local playback history" }
        emptyMap()
    }

    private fun prune(history: Map<String, Long>): Map<String, Long> {
        if (history.size <= MAX_ENTRIES) return history
        return history.entries.sortedByDescending { it.value }.take(MAX_ENTRIES).associate { it.key to it.value }
    }

    private companion object {
        const val MAX_ENTRIES = 400
        const val REWRITE_INTERVAL_MS = 60_000L
        const val TAG = "LocalPlaybackHistory"
    }
}

package com.edde746.plezy.servers

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Clock
import kotlin.time.Instant
import kotlinx.coroutines.test.runTest

class LocalPlaybackHistoryTest {
    private var nowMs = 1_000_000L
    private val clock = object : Clock {
        override fun now(): Instant = Instant.fromEpochMilliseconds(nowMs)
    }

    private val store = object : LocalPlaybackHistoryStore {
        var saved: Map<String, Long> = emptyMap()
        override suspend fun read(): Map<String, Long> = saved
        override suspend fun write(history: Map<String, Long>) {
            saved = history
        }
    }

    private val history = LocalPlaybackHistory(store, clock)

    private val movie = MediaItem(id = "movie-1", backend = BackendKind.PLEX, kind = MediaKind.MOVIE, title = "Movie", serverId = "srv-1")

    @Test
    fun recordPlaybackWritesItemAndSeriesKeysForAnEpisode() = runTest {
        val episode = MediaItem(id = "ep-1", backend = BackendKind.PLEX, kind = MediaKind.EPISODE, title = "Episode 1", serverId = "srv-1", grandparentId = "show-1")

        history.recordPlayback(episode)

        val snapshot = history.snapshot()
        assertTrue(snapshot.keys.containsAll(listOf("srv-1:ep-1", "srv-1:show-1")))
        assertEquals(snapshot["srv-1:ep-1"], snapshot["srv-1:show-1"])
    }

    @Test
    fun recordPlaybackWritesOnlyTheItemKeyForAMovie() = runTest {
        history.recordPlayback(movie)

        assertEquals(setOf("srv-1:movie-1"), history.snapshot().keys)
    }

    @Test
    fun repeatWritesForTheSameItemWithinTheRewriteWindowAreSkipped() = runTest {
        history.recordPlayback(movie)
        val first = history.snapshot()["srv-1:movie-1"]
        nowMs += 30_000
        history.recordPlayback(movie)

        assertEquals(first, history.snapshot()["srv-1:movie-1"])
    }

    @Test
    fun prunesTheOldestEntriesPastTheCap() = runTest {
        store.saved = (0 until 400).associate { "srv-1:old-$it" to (it + 1).toLong() }

        history.recordPlayback(movie.copy(id = "fresh", title = "Fresh"))

        val snapshot = history.snapshot()
        assertEquals(400, snapshot.size)
        assertTrue("srv-1:fresh" in snapshot)
        assertFalse("srv-1:old-0" in snapshot)
    }
}

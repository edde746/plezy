package com.edde746.plezy.music

import com.edde746.plezy.data.music.MusicSession
import com.edde746.plezy.data.testData
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

class MusicSessionStoreTest {
    private val data = testData()

    @AfterTest
    fun close() = data.close()

    private fun store(profileId: String = "p1") = MusicSessionStore(data.musicSessions, profileId)

    private fun state(
        items: List<com.edde746.plezy.model.MediaItem>,
        order: List<Int> = items.indices.toList(),
        cursor: Int = 0,
        shuffled: Boolean = false,
        repeatMode: MusicRepeatMode = MusicRepeatMode.OFF,
    ) = MusicQueueState(items, order, cursor, shuffled, repeatMode)

    private fun row(queueJson: String, orderJson: String, repeatMode: String) = MusicSession(
        profileId = "p1", queueJson = queueJson, orderJson = orderJson, cursor = 0, shuffled = false, repeatMode = repeatMode,
        contextTitle = null, contextKind = null, positionMs = 0, updatedAt = 0,
    )

    @Test
    fun roundTripsQueueStateProvenanceAndPosition() = runTest {
        val items = listOf(track("a"), track("b"), track("c"))
        store().save(
            MusicSessionSnapshot(
                state(items, listOf(2, 0, 1), cursor = 1, shuffled = true, repeatMode = MusicRepeatMode.ALL),
                MusicPlayContext("Mixtape", MusicPlayContextKind.PLAYLIST),
                93.seconds,
            ),
        )

        val loaded = assertNotNull(store().load())
        assertEquals(listOf("a", "b", "c"), loaded.queue.items.ids())
        assertEquals(listOf(2, 0, 1), loaded.queue.order)
        assertEquals(1, loaded.queue.cursor)
        assertTrue(loaded.queue.shuffled)
        assertEquals(MusicRepeatMode.ALL, loaded.queue.repeatMode)
        assertEquals(MusicPlayContext("Mixtape", MusicPlayContextKind.PLAYLIST), loaded.playContext)
        assertEquals(93.seconds, loaded.position)
        // The tracks stay playable after the round trip.
        assertEquals("srv", loaded.queue.items.first().serverId)
        assertEquals(180_000L, loaded.queue.items.first().durationMs)
    }

    @Test
    fun aLoadedShuffledStateUnshufflesBackToCanonicalOrderThroughTheController() = runTest {
        val items = listOf(track("a"), track("b"), track("c"))
        store().save(MusicSessionSnapshot(state(items, listOf(2, 0, 1), shuffled = true), null, Duration.ZERO))

        val loaded = assertNotNull(store().load())
        val controller = MusicQueueController()
        assertTrue(controller.restoreState(loaded.queue))
        assertEquals(listOf("c", "a", "b"), controller.queue.ids())

        controller.toggleShuffle()
        assertEquals(listOf("a", "b", "c"), controller.queue.ids())
        assertEquals("c", controller.current?.id)
    }

    @Test
    fun updateProgressRewritesCursorAndPositionWithoutTouchingTheQueue() = runTest {
        store().save(MusicSessionSnapshot(state(listOf(track("a"), track("b"))), null, Duration.ZERO))

        store().updateProgress(cursor = 1, position = 30.seconds)

        val loaded = assertNotNull(store().load())
        assertEquals(1, loaded.queue.cursor)
        assertEquals(30.seconds, loaded.position)
        assertEquals(listOf("a", "b"), loaded.queue.items.ids())
    }

    @Test
    fun updateProgressWithoutASnapshotRowIsANoOp() = runTest {
        store().updateProgress(cursor = 3, position = 5.seconds)
        assertNull(store().load())
    }

    @Test
    fun clearRemovesTheRow() = runTest {
        store().save(MusicSessionSnapshot(state(listOf(track("a"))), null, Duration.ZERO))
        store().clear()
        assertNull(store().load())
    }

    @Test
    fun profilesAreIsolated() = runTest {
        store().save(MusicSessionSnapshot(state(listOf(track("a"))), null, Duration.ZERO))
        assertNull(store("p2").load())
        assertNotNull(store().load())
    }

    @Test
    fun malformedQueueJsonDiscardsTheWholeSnapshot() = runTest {
        data.musicSessions.save(row("not json", "[0]", "off"))
        assertNull(store().load())
    }

    @Test
    fun anUnknownRepeatModeIdDiscardsTheSnapshot() = runTest {
        data.musicSessions.save(row("[]", "[]", "bogus"))
        assertNull(store().load())
    }

    @Test
    fun aNegativePersistedPositionLoadsAsZero() = runTest {
        store().save(MusicSessionSnapshot(state(listOf(track("a"))), null, Duration.ZERO))
        data.musicSessions.updateProgress("p1", cursor = 0, positionMs = -500, updatedAt = 1)
        assertEquals(Duration.ZERO, store().load()?.position)
    }

    @Test
    fun oversizedQueuesPersistAPlaybackOrderWindowAroundTheCursor() = runTest {
        val items = List(1050) { track("i$it") }
        store().save(MusicSessionSnapshot(state(items, cursor = 700), null, Duration.ZERO))

        val loaded = assertNotNull(store().load())
        assertEquals(MusicSessionStore.MAX_PERSISTED_TRACKS, loaded.queue.items.size)
        // Window start = (700 - 250) clamped to [0, 50] = 50; identity permutation.
        assertEquals("i50", loaded.queue.items.first().id)
        assertEquals("i1049", loaded.queue.items.last().id)
        assertEquals(650, loaded.queue.cursor)
        assertEquals(0, loaded.queue.order.first())
        assertEquals(MusicSessionStore.MAX_PERSISTED_TRACKS - 1, loaded.queue.order.last())
        assertTrue(MusicQueueController().restoreState(loaded.queue))
    }

    @Test
    fun progressOnAnOversizedQueueStaysWindowRelativeAndRewindowsWhenTheCursorLeaves() = runTest {
        val items = List(2000) { track("i$it") }
        val session = store()
        session.save(MusicSessionSnapshot(state(items, cursor = 700), null, Duration.ZERO))

        // Window start = 700 - 250 = 450.
        session.updateProgress(cursor = 701, position = 5.seconds)
        var loaded = assertNotNull(store().load())
        assertEquals("i701", loaded.queue.items[loaded.queue.cursor].id)
        assertEquals(5.seconds, loaded.position)

        // Past the window's end (450 + 1000): re-windowed around the cursor.
        session.updateProgress(cursor = 1600, position = 1.seconds)
        loaded = assertNotNull(store().load())
        assertEquals(MusicSessionStore.MAX_PERSISTED_TRACKS, loaded.queue.items.size)
        assertEquals("i1600", loaded.queue.items[loaded.queue.cursor].id)
        assertEquals(1.seconds, loaded.position)
        assertTrue(MusicQueueController().restoreState(loaded.queue))

        session.updateProgress(cursor = 1601, position = Duration.ZERO)
        loaded = assertNotNull(store().load())
        assertEquals("i1601", loaded.queue.items[loaded.queue.cursor].id)
    }

    @Test
    fun repeatModesAndContextKindsPersistAsTheirStableIds() = runTest {
        val cases = listOf(
            Triple(MusicRepeatMode.OFF, MusicPlayContextKind.ALBUM, "off" to "album"),
            Triple(MusicRepeatMode.ALL, MusicPlayContextKind.ARTIST, "all" to "artist"),
            Triple(MusicRepeatMode.ONE, MusicPlayContextKind.PLAYLIST, "one" to "playlist"),
            Triple(MusicRepeatMode.OFF, MusicPlayContextKind.MIX, "off" to "mix"),
            Triple(MusicRepeatMode.ALL, MusicPlayContextKind.TRACKS, "all" to "tracks"),
            Triple(MusicRepeatMode.ONE, MusicPlayContextKind.LIBRARY, "one" to "library"),
        )
        for ((mode, kind, ids) in cases) {
            store().save(MusicSessionSnapshot(state(listOf(track("a")), repeatMode = mode), MusicPlayContext("From", kind), Duration.ZERO))

            val row = assertNotNull(data.musicSessions.load("p1"))
            assertEquals(ids.first, row.repeatMode)
            assertEquals(ids.second, row.contextKind)
            val loaded = assertNotNull(store().load())
            assertEquals(mode, loaded.queue.repeatMode)
            assertEquals(MusicPlayContext("From", kind), loaded.playContext)
        }
    }

    @Test
    fun unshufflingARestoredOversizedQueueKeepsThePersistedOrder() = runTest {
        val items = List(1200) { track("i$it") }
        store().save(MusicSessionSnapshot(state(items, items.indices.reversed().toList(), cursor = 600, shuffled = true), null, Duration.ZERO))

        val controller = MusicQueueController()
        assertTrue(controller.restoreState(assertNotNull(store().load()).queue))
        val persisted = controller.queue.ids()
        assertEquals("i599", controller.current?.id)

        controller.toggleShuffle()
        assertEquals(persisted, controller.queue.ids())
        assertEquals("i599", controller.current?.id)
    }

    @Test
    fun droppingImageTokensClearsEverySavedQueueAndKeepsItRestorable() = runTest {
        // Queues an earlier release saved with Jellyfin's token in the image URLs, in two profiles.
        val album = "http://jf.local:8096/Items/album-1/Images/Primary"
        val tokened = track("a").copy(thumbPath = "$album?api_key=secret", parentThumbPath = "$album?tag=t&api_key=secret")
        for (profile in listOf("p1", "p2")) store(profile).save(MusicSessionSnapshot(state(listOf(tokened), cursor = 0), null, 42.seconds))

        MusicSessionStore.dropImageTokens(data.musicSessions)

        for (profile in listOf("p1", "p2")) {
            assertFalse("secret" in assertNotNull(data.musicSessions.load(profile)).queueJson, profile)
            val restored = assertNotNull(store(profile).load(), profile)
            assertEquals(album, restored.queue.items.single().thumbPath)
            assertEquals("$album?tag=t", restored.queue.items.single().parentThumbPath)
            assertEquals(42.seconds, restored.position)
        }
    }
}

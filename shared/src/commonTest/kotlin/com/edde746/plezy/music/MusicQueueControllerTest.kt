package com.edde746.plezy.music

import com.edde746.plezy.model.MediaItem
import kotlin.random.Random
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class MusicQueueControllerTest {
    private val tracks = List(6) { track("t$it") }

    private fun controller(seed: Int = 42) = MusicQueueController(Random(seed))

    private fun loaded(startIndex: Int? = null, shuffle: Boolean = false, list: List<MediaItem> = tracks) =
        controller().apply { load(list, startIndex, shuffle) }

    // load

    @Test
    fun startsAtStartIndexInCanonicalOrder() {
        val q = loaded(2)
        assertEquals(listOf("t0", "t1", "t2", "t3", "t4", "t5"), q.queue.ids())
        assertEquals(2, q.cursor)
        assertEquals("t2", q.current?.id)
        assertFalse(q.shuffled)
    }

    @Test
    fun shuffleAnchorsTheStartTrackFirst() {
        val q = loaded(3, shuffle = true)
        assertTrue(q.shuffled)
        assertEquals(0, q.cursor)
        assertEquals("t3", q.current?.id)
        assertEquals("t3", q.queue.ids().first())
        assertEquals(tracks.ids().toSet(), q.queue.ids().toSet())
    }

    @Test
    fun shuffleWithoutAStartIndexRandomizesTheHeadToo() {
        val heads = mutableSetOf<String>()
        for (seed in 0 until 8) {
            val q = controller(seed).apply { load(tracks, shuffle = true) }
            assertTrue(q.shuffled)
            assertEquals(0, q.cursor)
            assertEquals(tracks.ids().toSet(), q.queue.ids().toSet())
            heads += q.current!!.id
        }
        assertTrue(heads.size > 1, "head stayed pinned to one track across seeds")
    }

    @Test
    fun emptyLoadLeavesAnIdleQueue() {
        val q = loaded(list = emptyList())
        assertTrue(q.isEmpty)
        assertEquals(-1, q.cursor)
        assertNull(q.current)
        assertNull(q.nextIndex())
    }

    @Test
    fun theQueueKeepsPlayedTracksAndClearingLeavesNoCursor() {
        val q = loaded(0)
        q.jumpTo(3)
        assertEquals(tracks.ids(), q.queue.ids())
        assertEquals(3, q.cursor)

        q.clear()
        assertTrue(q.queue.isEmpty())
        assertEquals(-1, q.cursor)
        assertNull(q.current)
    }

    // advancement

    @Test
    fun repeatOffWalksForwardAndEndsAfterTheLastTrack() {
        val q = loaded(4)
        assertEquals(5, q.nextIndex())
        q.jumpTo(5)
        assertNull(q.nextIndex())
        assertNull(q.nextIndex(manual = true))
    }

    @Test
    fun repeatAllWrapsBothDirections() {
        val q = loaded(5)
        q.repeatMode = MusicRepeatMode.ALL
        assertEquals(0, q.nextIndex())
        q.jumpTo(0)
        assertEquals(5, q.previousIndex())
    }

    @Test
    fun repeatOneRepeatsNaturallyButStepsOnManualNext() {
        val q = loaded(1)
        q.repeatMode = MusicRepeatMode.ONE
        assertEquals(1, q.nextIndex())
        assertEquals(2, q.nextIndex(manual = true))
    }

    @Test
    fun repeatOneOnTheLastTrackEndsOnManualNext() {
        val q = loaded(5)
        q.repeatMode = MusicRepeatMode.ONE
        assertEquals(5, q.nextIndex())
        assertNull(q.nextIndex(manual = true))
    }

    @Test
    fun previousIndexStepsBackAndStopsAtTheHeadWithRepeatOff() {
        val q = loaded(1)
        assertEquals(0, q.previousIndex())
        q.jumpTo(0)
        assertNull(q.previousIndex())
    }

    // jumpTo

    @Test
    fun jumpToMovesTheCursorWithinBoundsOnly() {
        val q = loaded()
        q.jumpTo(4)
        assertEquals("t4", q.current?.id)
        q.jumpTo(99)
        assertEquals(4, q.cursor)
        q.jumpTo(-1)
        assertEquals(4, q.cursor)
    }

    // addNext / addToEnd

    @Test
    fun addNextInsertsDirectlyAfterTheCurrentTrack() {
        val q = loaded(2)
        q.addNext(listOf(track("n1"), track("n2")))
        assertEquals(listOf("t0", "t1", "t2", "n1", "n2", "t3", "t4", "t5"), q.queue.ids())
        assertEquals("t2", q.current?.id)
    }

    @Test
    fun addToEndAppendsAfterEverything() {
        val q = loaded(2)
        q.addToEnd(listOf(track("e1")))
        assertEquals("e1", q.queue.ids().last())
        assertEquals("t2", q.current?.id)
    }

    @Test
    fun addedTracksSurviveAnUnshuffleInCanonicalOrder() {
        val q = loaded(0, shuffle = true)
        q.addToEnd(listOf(track("e1")))
        q.toggleShuffle()
        assertEquals(listOf("t0", "t1", "t2", "t3", "t4", "t5", "e1"), q.queue.ids())
    }

    // removeAt

    @Test
    fun removingBeforeTheCursorShiftsTheCursorBack() {
        val q = loaded(3)
        assertFalse(q.removeAt(1))
        assertEquals("t3", q.current?.id)
        assertEquals(2, q.cursor)
        assertEquals(listOf("t0", "t2", "t3", "t4", "t5"), q.queue.ids())
    }

    @Test
    fun removingAfterTheCursorLeavesTheCursorAlone() {
        val q = loaded(3)
        assertFalse(q.removeAt(5))
        assertEquals("t3", q.current?.id)
        assertEquals(3, q.cursor)
    }

    @Test
    fun removingAtTheCursorKeepsTheCursorOnTheFollowingTrack() {
        val q = loaded(3)
        assertTrue(q.removeAt(3))
        assertEquals(3, q.cursor)
        assertEquals("t4", q.current?.id)
    }

    @Test
    fun removingAtTheCursorOnTheLastTrackClampsBack() {
        val q = loaded(5)
        assertTrue(q.removeAt(5))
        assertEquals(4, q.cursor)
        assertEquals("t4", q.current?.id)
    }

    @Test
    fun removingTheOnlyTrackEmptiesTheQueue() {
        val q = loaded(list = listOf(track("solo")))
        assertTrue(q.removeAt(0))
        assertTrue(q.isEmpty)
        assertEquals(-1, q.cursor)
    }

    // move

    @Test
    fun movingTheCurrentTrackMovesTheCursorWithIt() {
        val q = loaded(2)
        q.move(2, 4)
        assertEquals(4, q.cursor)
        assertEquals("t2", q.current?.id)
        assertEquals(listOf("t0", "t1", "t3", "t4", "t2", "t5"), q.queue.ids())
    }

    @Test
    fun movingAnEntryAcrossTheCursorAdjustsIt() {
        val q = loaded(2)
        q.move(0, 5)
        assertEquals(1, q.cursor)
        assertEquals("t2", q.current?.id)
        q.move(5, 0)
        assertEquals(2, q.cursor)
        assertEquals("t2", q.current?.id)
    }

    @Test
    fun movingEntriesOnOneSideKeepsTheCursor() {
        val q = loaded(2)
        q.move(3, 5)
        assertEquals(2, q.cursor)
        assertEquals("t2", q.current?.id)
    }

    @Test
    fun movingOntoItselfOrOutOfRangeChangesNothing() {
        val q = loaded(2)
        q.move(2, 2)
        q.move(-1, 2)
        q.move(0, 99)
        q.move(99, 0)
        assertEquals(tracks.ids(), q.queue.ids())
        assertEquals(2, q.cursor)
    }

    // toggleShuffle

    @Test
    fun shuffleOnAnchorsTheCurrentTrackFirstAndShufflesTheRest() {
        val q = loaded(2)
        q.toggleShuffle()
        assertTrue(q.shuffled)
        assertEquals(0, q.cursor)
        assertEquals("t2", q.current?.id)
        assertEquals(tracks.ids().toSet(), q.queue.ids().toSet())
    }

    @Test
    fun shuffleOffRestoresCanonicalOrderWithTheCursorOnTheCurrentTrack() {
        val q = loaded(2)
        q.toggleShuffle()
        q.jumpTo(3)
        val current = q.current!!.id
        q.toggleShuffle()
        assertFalse(q.shuffled)
        assertEquals(listOf("t0", "t1", "t2", "t3", "t4", "t5"), q.queue.ids())
        assertEquals(current, q.current?.id)
    }

    @Test
    fun shuffleOnAnEmptyQueueIsANoOp() {
        val q = controller()
        q.toggleShuffle()
        assertFalse(q.shuffled)
        assertEquals(-1, q.cursor)
        assertTrue(q.queue.isEmpty())
    }

    // clearUpcoming

    @Test
    fun clearUpcomingDropsEverythingAfterTheCurrentTrack() {
        val q = loaded(2)
        q.clearUpcoming()
        assertEquals(listOf("t0", "t1", "t2"), q.queue.ids())
        assertEquals("t2", q.current?.id)
        assertNull(q.nextIndex())
    }

    @Test
    fun clearUpcomingWhileShuffledAlsoDropsTheCanonicalItems() {
        val q = loaded(0, shuffle = true)
        val kept = q.queue.subList(0, 2).ids()
        q.jumpTo(1)
        q.clearUpcoming()
        assertEquals(kept, q.queue.ids())
        q.toggleShuffle()
        assertEquals(kept.toSet(), q.queue.ids().toSet())
        assertEquals(kept[1], q.current?.id)
    }

    // captureState / restoreState

    @Test
    fun roundTripsTheShufflePermutationCursorAndRepeatMode() {
        val q = loaded(2, shuffle = true)
        q.repeatMode = MusicRepeatMode.ALL

        val restored = controller(7)
        assertTrue(restored.restoreState(q.captureState()))

        assertEquals(q.queue.ids(), restored.queue.ids())
        assertEquals(q.cursor, restored.cursor)
        assertEquals("t2", restored.current?.id)
        assertTrue(restored.shuffled)
        assertEquals(MusicRepeatMode.ALL, restored.repeatMode)

        restored.toggleShuffle()
        assertEquals(tracks.ids(), restored.queue.ids())
        assertEquals("t2", restored.current?.id)
    }

    @Test
    fun capturedStateIsACopyNotALiveViewOfTheQueue() {
        val q = loaded()
        val state = q.captureState()
        q.removeAt(0)
        assertEquals(tracks.size, state.items.size)
        assertEquals(tracks.size, state.order.size)
    }

    @Test
    fun rejectsCorruptStatesWithoutTouchingTheQueue() {
        val q = loaded(1)
        val before = q.queue.ids()

        fun corrupt(items: List<MediaItem> = tracks, order: List<Int> = tracks.indices.toList(), cursor: Int = 0) =
            MusicQueueState(items, order, cursor, shuffled = false, repeatMode = MusicRepeatMode.OFF)

        assertFalse(q.restoreState(corrupt(items = emptyList())))
        assertFalse(q.restoreState(corrupt(order = listOf(0, 1))), "order length mismatch")
        assertFalse(q.restoreState(corrupt(order = listOf(0, 0, 1, 2, 3, 4))), "duplicate order entry")
        assertFalse(q.restoreState(corrupt(order = listOf(0, 1, 2, 3, 4, 6))), "order index out of range")
        assertFalse(q.restoreState(corrupt(cursor = 6)), "cursor out of range")
        assertFalse(q.restoreState(corrupt(cursor = -1)))

        assertEquals(before, q.queue.ids())
        assertEquals(1, q.cursor)
    }
}

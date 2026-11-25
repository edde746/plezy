package com.edde746.plezy.presentation.player

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * The edge swipes' zones and the tracker that tells a swipe up or down an edge from everything else a finger does, on
 * a 1000 by 600 player: the edge zones are 96 wide (14 % capped), the top and bottom 90 outside them.
 */
class EdgeSwipeTrackerTest {
    private val width = 1000f
    private val height = 600f
    private val all: (LevelKind) -> Boolean = { true }
    private val tracker = EdgeSwipeTracker(slop = 10f, dominance = 1.5f)

    private fun down(pointer: Long, x: Float, y: Float, enabled: (LevelKind) -> Boolean = all) =
        tracker.pointerDown(pointer, x, y, width, height, enabled)

    @Test
    fun classifiesNarrowLeftAndRightEdgeZones() {
        assertEquals(LevelKind.BRIGHTNESS, edgeZone(40f, 300f, width, height))
        assertEquals(LevelKind.VOLUME, edgeZone(960f, 300f, width, height))
        assertNull(edgeZone(200f, 300f, width, height))
        assertEquals(96f, edgeZoneWidth(1000f), "14 % capped at 96")
        assertEquals(48f, edgeZoneWidth(300f), "at least 48")
        assertEquals(20f, edgeZoneWidth(40f), "at most half the player")
    }

    @Test
    fun respectsTopAndBottomExclusionBands() {
        assertNull(edgeZone(40f, 20f, width, height))
        assertNull(edgeZone(960f, 580f, width, height))
    }

    @Test
    fun activatesOnlyAfterVerticallyDominantMovement() {
        assertEquals(EdgeEvent.Candidate(LevelKind.BRIGHTNESS), down(1, 40f, 300f))
        assertEquals(EdgeEvent.None, tracker.pointerMove(1, 43f, 292f), "within the slop")
        val event = assertIs<EdgeEvent.Activated>(tracker.pointerMove(1, 44f, 280f))
        assertEquals(LevelKind.BRIGHTNESS, event.kind)
        assertTrue(event.delta > 0)
    }

    @Test
    fun aDisabledSideNeverBecomesACandidate() {
        assertEquals(EdgeEvent.None, down(1, 40f, 300f) { it != LevelKind.BRIGHTNESS })
        assertEquals(EdgeEvent.None, tracker.pointerMove(1, 40f, 200f))
    }

    @Test
    fun aPointerOnADisabledSideStillBlocksTheEnabledSideAsASecondFinger() {
        val onlyRight: (LevelKind) -> Boolean = { it == LevelKind.VOLUME }
        assertEquals(EdgeEvent.None, down(1, 40f, 300f, onlyRight))
        assertEquals(EdgeEvent.None, down(2, 960f, 300f, onlyRight), "the disabled edge's finger is still down: a chord")
        assertEquals(EdgeEvent.None, tracker.pointerMove(2, 960f, 200f))
        tracker.pointerUp(1, 300f)
        tracker.pointerUp(2, 300f)
        assertEquals(EdgeEvent.Candidate(LevelKind.VOLUME), down(3, 960f, 300f, onlyRight), "with every finger up it tracks again")
    }

    @Test
    fun cancelsHorizontalMovementFromTheEdge() {
        down(1, 40f, 300f)
        assertEquals(EdgeEvent.Cancelled(LevelKind.BRIGHTNESS, wasActive = false), tracker.pointerMove(1, 70f, 304f))
        assertFalse(tracker.active)
    }

    @Test
    fun upwardMovementIncreasesAndDownwardMovementDecreases() {
        down(1, 960f, 300f)
        val up = assertIs<EdgeEvent.Activated>(tracker.pointerMove(1, 958f, 250f))
        assertTrue(up.delta > 0)
        val down = assertIs<EdgeEvent.Update>(tracker.pointerMove(1, 958f, 350f))
        assertTrue(down.delta < 0)
        assertEquals(-50.0 / 420, down.delta, 1e-6, "over the height between the bands")
    }

    @Test
    fun secondPointerCancelsTracking() {
        down(1, 40f, 300f)
        assertEquals(EdgeEvent.Cancelled(LevelKind.BRIGHTNESS, wasActive = false), down(2, 80f, 300f))
        assertFalse(tracker.active)
    }

    @Test
    fun doesNotReactivateAfterMultitouchCancelUntilAllPointersLift() {
        down(1, 40f, 300f)
        down(2, 80f, 300f)
        assertEquals(EdgeEvent.None, down(3, 40f, 300f))
        assertEquals(EdgeEvent.None, tracker.pointerUp(1, 300f))
        assertEquals(EdgeEvent.None, down(4, 40f, 300f))
        assertEquals(EdgeEvent.None, tracker.pointerUp(2, 300f))
        assertEquals(EdgeEvent.None, tracker.pointerUp(3, 300f))
        assertEquals(EdgeEvent.None, tracker.pointerUp(4, 300f))
        assertEquals(EdgeEvent.Candidate(LevelKind.BRIGHTNESS), down(5, 40f, 300f))
    }

    @Test
    fun activatedCancelReportsActiveCancellation() {
        down(1, 40f, 300f)
        assertIs<EdgeEvent.Activated>(tracker.pointerMove(1, 40f, 260f))
        assertEquals(EdgeEvent.Cancelled(LevelKind.BRIGHTNESS, wasActive = true), tracker.cancel())
    }

    @Test
    fun candidatePointerUpWithoutActivationIsIgnored() {
        down(1, 40f, 300f)
        assertEquals(EdgeEvent.None, tracker.pointerUp(1, 302f))
    }
}

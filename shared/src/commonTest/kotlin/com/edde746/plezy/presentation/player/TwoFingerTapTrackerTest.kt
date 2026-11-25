package com.edde746.plezy.presentation.player

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.TestTimeSource

/**
 * The two-finger tap: it takes a deliberate tap of two fingers, at once and every time, and refuses what a viewer does
 * by accident: a pinch, a drag, a palm, two fingers resting on the screen.
 */
class TwoFingerTapTrackerTest {
    private val clock = TestTimeSource()
    private val tracker = TwoFingerTapTracker(clock)

    @Test
    fun detectsATwoFingerTapOnTheLastLift() {
        tracker.pointerDown(1, 100f, 100f)
        tracker.pointerDown(2, 140f, 100f)
        assertFalse(tracker.pointerUp(1, 100f, 100f), "one finger is still down")
        assertTrue(tracker.pointerUp(2, 140f, 100f))
    }

    @Test
    fun everyTwoFingerTapReportsIndependentlyHoweverFastTheyCome() {
        for (pointer in 1L..7L step 2) {
            tracker.pointerDown(pointer, 100f, 100f)
            tracker.pointerDown(pointer + 1, 140f, 100f)
            assertFalse(tracker.pointerUp(pointer, 100f, 100f))
            assertTrue(tracker.pointerUp(pointer + 1, 140f, 100f), "tap $pointer stands alone: no pair is swallowed")
            clock += 20.milliseconds
        }
    }

    @Test
    fun doesNotDetectAOneFingerTap() {
        tracker.pointerDown(1, 100f, 100f)
        assertFalse(tracker.pointerUp(1, 100f, 100f))
        clock += 120.milliseconds
        tracker.pointerDown(2, 100f, 100f)
        assertFalse(tracker.pointerUp(2, 100f, 100f))
    }

    @Test
    fun movementBeyondTheSlopInvalidatesTheTap() {
        tracker.pointerDown(1, 100f, 100f)
        tracker.pointerDown(2, 140f, 100f)
        tracker.pointerMove(1, 180f, 180f)
        assertFalse(tracker.pointerUp(1, 180f, 180f))
        assertFalse(tracker.pointerUp(2, 140f, 100f))
    }

    @Test
    fun movementWithinTheSlopStillTaps() {
        tracker.pointerDown(1, 100f, 100f)
        tracker.pointerDown(2, 140f, 100f)
        tracker.pointerMove(1, 150f, 100f)
        assertFalse(tracker.pointerUp(1, 150f, 100f))
        assertTrue(tracker.pointerUp(2, 140f, 100f))
    }

    @Test
    fun aPinchIsNotATapEvenWhenBothFingersLandBackNearTheirStart() {
        tracker.pointerDown(1, 100f, 100f)
        tracker.pointerDown(2, 140f, 100f)
        tracker.pointerMove(1, -20f, 100f)
        tracker.pointerMove(2, 260f, 100f)
        tracker.pointerMove(1, 100f, 100f)
        tracker.pointerMove(2, 140f, 100f)
        assertFalse(tracker.pointerUp(1, 100f, 100f))
        assertFalse(tracker.pointerUp(2, 140f, 100f))
    }

    @Test
    fun aThirdFingerInvalidatesTheTap() {
        tracker.pointerDown(1, 100f, 100f)
        tracker.pointerDown(2, 140f, 100f)
        tracker.pointerDown(3, 180f, 100f)
        assertFalse(tracker.pointerUp(1, 100f, 100f))
        assertFalse(tracker.pointerUp(2, 140f, 100f))
        assertFalse(tracker.pointerUp(3, 180f, 100f))
    }

    @Test
    fun twoFingersRestingPastTheTapTimeoutDoNotTap() {
        tracker.pointerDown(1, 100f, 100f)
        tracker.pointerDown(2, 140f, 100f)
        clock += 301.milliseconds
        assertFalse(tracker.pointerUp(1, 100f, 100f))
        assertFalse(tracker.pointerUp(2, 140f, 100f))
    }

    @Test
    fun theTimeoutRunsFromTheEarliestFingerDownNotTheLatest() {
        tracker.pointerDown(1, 100f, 100f)
        clock += 280.milliseconds
        tracker.pointerDown(2, 140f, 100f)
        clock += 40.milliseconds
        assertFalse(tracker.pointerUp(1, 100f, 100f))
        assertFalse(tracker.pointerUp(2, 140f, 100f))
    }

    @Test
    fun aCancelledPointerInvalidatesTheTap() {
        tracker.pointerDown(1, 100f, 100f)
        tracker.pointerDown(2, 140f, 100f)
        tracker.pointerCancel(1)
        assertFalse(tracker.pointerUp(2, 140f, 100f))
    }

    @Test
    fun reportsTheChordWhileTwoFingersAreDown() {
        assertFalse(tracker.chordActive)
        tracker.pointerDown(1, 100f, 100f)
        assertFalse(tracker.chordActive, "one finger is no chord")
        tracker.pointerDown(2, 140f, 100f)
        assertTrue(tracker.chordActive)
        tracker.pointerUp(1, 100f, 100f)
        assertTrue(tracker.chordActive, "the tap under way outlives the first lift")
        tracker.pointerUp(2, 140f, 100f)
        assertFalse(tracker.chordActive)
    }
}

package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.InputKey
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.VideoClickAction
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds

/**
 * The skip zones of a touch screen: the left and right 35 % of the player, outside its top and bottom 15 %. A skip
 * costs one full same-direction double tap within 300 ms; a lone tap shows or hides the controls, and nothing left over
 * from an earlier seek arms a tap to seek. The item is 45 minutes long and plays at 10:00; the seek step is 10 s.
 */
class MobileSkipZonesTest {
    private val PlayerHarness.seeks get() = engine.seeks.map { it.first }

    @Test
    fun aDoubleTapInTheForwardZoneSkipsOnce() = touchTest {
        doubleTap(FORWARD)
        assertEquals(listOf(610.0), seeks)
        assertFalse(state.controlsVisible, "skipping doesn't raise the controls")
    }

    @Test
    fun aLiveStreamWithoutACaptureBufferIsNotSeekedByADoubleTap() = touchTest {
        sessionInfo { it.copy(live = true) }
        doubleTap(FORWARD)
        doubleTap(BACKWARD)
        assertEquals(emptyList(), seeks, "there is no window behind the live edge to seek in")
        assertEquals(emptyList(), session.liveSeeks)
    }

    @Test
    fun aDoubleTapInTheBackwardZoneRewindsOnce() = touchTest {
        doubleTap(BACKWARD)
        assertEquals(listOf(590.0), seeks)
    }

    @Test
    fun aLoneTapAfterASkipTogglesTheChromeInsteadOfSkippingAgain() = touchTest {
        doubleTap(FORWARD)
        assertEquals(1, seeks.size)
        loneTap(FORWARD)
        assertEquals(1, seeks.size, "a single tap never seeks")
        assertTrue(state.controlsVisible, "a single tap in a skip zone shows the controls")
    }

    @Test
    fun aSecondTapJustInsideThePairingWindowSkips() = touchTest {
        tap(FORWARD)
        advance(299.milliseconds)
        tap(FORWARD)
        assertEquals(listOf(610.0), seeks)
        assertFalse(state.controlsVisible)
    }

    @Test
    fun aSecondTapJustPastThePairingWindowDoesNotSkip() = touchTest {
        tap(FORWARD)
        advance(301.milliseconds)
        assertTrue(state.controlsVisible, "the window closed: the first tap acted alone")
        tap(FORWARD)
        assertEquals(emptyList(), seeks, "two taps a window apart are two lone taps")
    }

    @Test
    fun anUninterruptedTapStreamPairsIntoOneSkipPerTwoTaps() = touchTest {
        val skipped = (1..6).map {
            val before = seeks.size
            tap(FORWARD)
            seeks.size > before
        }
        assertEquals(listOf(false, true, false, true, false, true), skipped, "pairs never overlap")
        assertEquals(listOf(610.0, 620.0, 630.0), seeks)
        advance(400.milliseconds)
        assertFalse(state.controlsVisible, "the last tap completed a pair: nothing is left to show the controls")
    }

    @Test
    fun aDoubleTapAtTheEndOfTheItemReportsOnlyTheDistanceLeft() = touchTest(position = 2695.0) {
        doubleTap(FORWARD)
        assertEquals(listOf(2700.0), seeks, "five seconds from the end a 10 s skip travels five")
        doubleTap(FORWARD)
        assertEquals(listOf(2700.0), seeks, "a double tap that travels nothing seeks nothing")
    }

    @Test
    fun aBackwardDoubleTapAtTheStartNeitherSeeksNorRaisesABadge() = touchTest(position = 0.0) {
        doubleTap(BACKWARD)
        assertEquals(emptyList(), seeks)
        assertEquals(null, state.skipBadge, "a 0 s badge would describe a seek not happening")
        advance(400.milliseconds)
        assertFalse(state.controlsVisible, "the pair still counts as a skip, not as a lone tap")
    }

    @Test
    fun aPositionReportedPastTheEndCountsAsTheEnd() = touchTest(position = 2700.5) {
        doubleTap(FORWARD)
        assertEquals(emptyList(), seeks, "forward from the end has nowhere to go")
        doubleTap(BACKWARD)
        assertEquals(listOf(2690.0), seeks, "back from the end itself")
    }

    @Test
    fun anOddTapLeftOverByATapStreamTogglesTheChrome() = touchTest {
        repeat(5) { tap(FORWARD) }
        assertEquals(2, seeks.size, "five taps make two skips")
        assertFalse(state.controlsVisible, "the fifth tap still waits for its partner")
        advance(400.milliseconds)
        assertTrue(state.controlsVisible, "the unpaired tap acts alone")
        assertEquals(2, seeks.size)
    }

    @Test
    fun aKeyboardSeekDoesNotArmOneTapSeekingOnTheTouchSurface() = touchTest {
        press(InputKey.RIGHT)
        assertEquals(1, seeks.size)
        loneTap(FORWARD)
        assertEquals(1, seeks.size, "a keyboard's seek doesn't make a lone tap seek")
    }

    @Test
    fun aMediaKeySeekDoesNotArmOneTapSeekingEither() = touchTest {
        press(InputKey.MEDIA_FAST_FORWARD)
        val before = seeks.size
        assertTrue(before > 0)
        loneTap(FORWARD)
        assertEquals(before, seeks.size, "a lone tap is no skip")
    }

    @Test
    fun aDoubleTapKeepsItsOwnReadoutWhileAKeyboardBurstIsPending() = touchTest {
        // A keyboard burst commits its seek as its key comes up; the double tap's seek is its own.
        input(InputEvent.KeyDown(InputKey.RIGHT))
        assertEquals("10s", state.skipBadge?.label)
        doubleTap(FORWARD)
        assertEquals("10s", state.skipBadge?.label, "the tap that just seeked owns the readout and counts only its own step")
        input(InputEvent.KeyUp(InputKey.RIGHT))
        assertEquals(seeks.distinct(), seeks, "no seek goes twice")
    }

    @Test
    fun aLoneTapInTheOppositeZoneDoesNotSkip() = touchTest {
        doubleTap(FORWARD)
        assertEquals(1, seeks.size)
        loneTap(BACKWARD)
        assertEquals(1, seeks.size)
    }

    @Test
    fun tapsSplitAcrossTheTwoZonesNeverPairIntoASkip() = touchTest {
        tap(FORWARD)
        advance(50.milliseconds)
        tap(BACKWARD)
        advance(400.milliseconds)
        assertEquals(emptyList(), seeks, "both halves of a double tap land in one zone")
    }

    @Test
    fun aLoneTapOutsideTheSkipZonesTogglesTheChrome() = touchTest {
        loneTap(CENTRE)
        assertEquals(emptyList(), seeks)
        assertTrue(state.controlsVisible)
    }

    /** With the controls up the zones still take taps; the middle and a lone tap hide them. */
    @Test
    fun withTheControlsUpTheZonesStillSkipAndATapHidesThem() = touchTest {
        tap(CENTRE)
        assertTrue(state.controlsVisible, "a tap in the middle acts at once")
        doubleTap(FORWARD)
        assertEquals(listOf(610.0), seeks)
        assertTrue(state.controlsVisible)
        tap(CENTRE)
        assertFalse(state.controlsVisible)
        tap(CENTRE.first to HEIGHT * 0.1f)
        assertTrue(state.controlsVisible, "the top band is no skip zone: a tap there acts at once")
    }

    /** Where the profile clicks to pause, a tap in the middle with the controls down pauses; one with them up hides them. */
    @Test
    fun aTapInTheMiddlePausesWhereTheProfileHasClicksPause() = touchTest {
        sessionInfo { it.copy(videoClick = VideoClickAction.PAUSE) }
        tap(CENTRE)
        assertEquals(listOf(true), engine.paused)
        dispatch(PlayerCommand.Play)
        dispatch(PlayerCommand.ShowControls)
        tap(CENTRE)
        assertEquals(listOf(true, false), engine.paused, "with the controls up it hides them")
        assertFalse(state.controlsVisible)
        loneTap(FORWARD)
        assertEquals(listOf(true, false), engine.paused, "a lone tap in a skip zone only shows the controls")
        assertTrue(state.controlsVisible)
    }
}

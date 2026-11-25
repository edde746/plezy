package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.input.TouchPhase
import com.edde746.plezy.playback.VideoLayout
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds

/**
 * A two-finger tap on a touch screen toggles playback, the moment it resolves: there is no two-finger double tap to
 * wait for, so it never resets the zoom, and pausing late would pause on the wrong frame.
 */
class TwoFingerTapTest {
    private fun PlayerHarness.zoomed() {
        dispatch(PlayerCommand.SetZoom(1.6))
        dispatch(PlayerCommand.HideControls)
    }

    @Test
    fun aTwoFingerTapPausesAndThePauseBringsTheControlsUp() = touchTest {
        twoFingerTap()
        assertEquals(listOf(true), engine.paused)
        assertEquals(null, state.menu)
        assertTrue(state.controlsVisible, "a paused picture shows its controls")
    }

    @Test
    fun aSecondTwoFingerTapResumesNoPairIsEverSwallowed() = touchTest {
        twoFingerTap()
        twoFingerTap()
        assertEquals(listOf(true, false), engine.paused)
    }

    @Test
    fun aZoomedTapTogglesImmediatelyWithNoWaitingPeriod() = touchTest {
        zoomed()
        twoFingerTap()
        assertEquals(listOf(true), engine.paused, "the zoom neither delays nor disables it")
    }

    @Test
    fun aZoomedTapDispatchesNothingFurtherOnceTheDoubleTapWindowLapses() = touchTest {
        zoomed()
        val layouts = engine.layouts.toList()
        twoFingerTap()
        advance(400.milliseconds)
        assertEquals(listOf(true), engine.paused, "nothing is left waiting")
        assertEquals(layouts, engine.layouts)
    }

    @Test
    fun aTwoFingerDoubleTapNeverResetsTheZoom() = touchTest {
        zoomed()
        twoFingerTap()
        twoFingerTap()
        assertEquals(VideoLayout(zoom = 1.6), engine.layouts.last(), "the zoom resets in the options, by key and by pinching back")
        assertEquals(listOf(true, false), engine.paused, "two toggles are back where they started")
    }

    @Test
    fun aPausedViewerIsNotResumedByAnythingButTheirOwnTap() = touchTest {
        zoomed()
        dispatch(PlayerCommand.Pause)
        twoFingerTap()
        assertEquals(listOf(true, false), engine.paused, "one tap toggles, either way")
        assertEquals(VideoLayout(zoom = 1.6), engine.layouts.last())
    }

    @Test
    fun aTwoFingerDoubleTapWhileUnzoomedDoesNotTouchTheZoom() = touchTest {
        twoFingerTap()
        twoFingerTap()
        assertEquals(emptyList(), engine.layouts)
        assertEquals(null, state.osd, "no zoom message")
    }

    /** In a room this device controls, the tap is the room's pause, as the play button's is. */
    @Test
    fun withoutATransportCallbackTheGestureDrivesThePlayerDirectly() = touchTest {
        val watch = FakeWatch(canControl = true, canChangeEpisode = false)
        store.attachWatch(watch)
        watch.routesControls = true
        twoFingerTap()
        assertEquals(listOf("pause"), watch.presses)
    }

    @Test
    fun aOneFingerTapStillTogglesTheChromeInsteadOfPlayback() = touchTest {
        tap(CENTRE)
        advance(400.milliseconds)
        assertEquals(emptyList(), engine.paused)
        assertTrue(state.controlsVisible)
    }

    @Test
    fun aThreeFingerTapDoesNothing() = touchTest {
        val fingers = listOf(nextPointer(), nextPointer(), nextPointer())
        fingers.forEachIndexed { i, pointer -> touch(TouchPhase.DOWN, pointer, 360f + 40 * i to 300f) }
        fingers.forEachIndexed { i, pointer -> touch(TouchPhase.UP, pointer, 360f + 40 * i to 300f) }
        advance(400.milliseconds)
        assertEquals(emptyList(), engine.paused)
        assertFalse(state.controlsVisible)
    }

    @Test
    fun aPinchDoesNotTogglePlayback() = touchTest {
        val first = nextPointer()
        val second = nextPointer()
        touch(TouchPhase.DOWN, first, 380f to 300f)
        touch(TouchPhase.DOWN, second, 420f to 300f)
        touch(TouchPhase.MOVE, first, 260f to 300f)
        touch(TouchPhase.MOVE, second, 540f to 300f)
        touch(TouchPhase.UP, first, 260f to 300f)
        touch(TouchPhase.UP, second, 540f to 300f)
        assertEquals(emptyList(), engine.paused)
    }

    @Test
    fun theGestureIsInertWhileTheContentStripIsOpen() = touchTest {
        val clear = WIDTH * 0.08f to HEIGHT * 0.3f
        twoFingerTap(clear, spread = 24f)
        assertEquals(listOf(true), engine.paused, "the spot takes the gesture with the strip shut")
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.CONTENT_STRIP))
        twoFingerTap(clear, spread = 24f)
        assertEquals(listOf(true), engine.paused, "browsing chapters or the queue owns the surface")
    }

    @Test
    fun aGuestWithoutPlaybackControlCannotToggle() = touchTest {
        val watch = FakeWatch(canControl = false, canChangeEpisode = false)
        store.attachWatch(watch)
        watch.routesControls = true
        twoFingerTap()
        assertEquals(emptyList(), engine.paused)
        assertEquals(emptyList(), watch.presses)
    }
}

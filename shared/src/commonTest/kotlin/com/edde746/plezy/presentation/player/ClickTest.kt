package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.InputKey
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.input.VideoClickAction
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

class ClickTest {
    @Test
    fun aSingleClickActsAtOnce() = playerTest {
        playing()
        input(InputEvent.Click(x = 0.5f))
        assertEquals(listOf(true), engine.paused)
        assertTrue(state.paused)
    }

    @Test
    fun aDoubleClickPausesOnceAndTogglesFullscreen() = playerTest {
        playing()
        input(InputEvent.Click(x = 0.5f, clickCount = 1))
        advance(200.milliseconds)
        input(InputEvent.Click(x = 0.5f, clickCount = 2))
        assertEquals(listOf(true), host.fullscreenRequests)
        assertTrue(state.fullscreen)
        advance(2.seconds)
        assertEquals(listOf(true), engine.paused, "the first click paused, the second went fullscreen alone")

        // And back: the first click plays, the second leaves fullscreen; a triple click's third starts a new pair.
        input(InputEvent.Click(x = 0.5f, clickCount = 1))
        input(InputEvent.Click(x = 0.5f, clickCount = 2))
        input(InputEvent.Click(x = 0.5f, clickCount = 3))
        advance(2.seconds)
        assertEquals(listOf(true, false), host.fullscreenRequests)
        assertEquals(listOf(true, false, true), engine.paused)
    }

    @Test
    fun platformsThatDontCountClicksGetDoubleClicksToo() = playerTest {
        playing()
        input(InputEvent.Click(x = 0.5f))
        advance(300.milliseconds)
        input(InputEvent.Click(x = 0.5f))
        advance(2.seconds)
        assertEquals(listOf(true), host.fullscreenRequests)
        assertEquals(listOf(true), engine.paused)
    }

    @Test
    fun twoSlowClicksAreTwoClicks() = playerTest {
        playing()
        input(InputEvent.Click(x = 0.5f))
        advance(600.milliseconds)
        input(InputEvent.Click(x = 0.5f))
        advance(600.milliseconds)
        assertEquals(listOf(true, false), engine.paused)
        assertTrue(host.fullscreenRequests.isEmpty())
    }

    @Test
    fun escapeLeavesFullscreenBeforeTheFullscreenToggleIsTouchedAgain() = playerTest {
        playing()
        press(InputKey.F)
        assertTrue(state.fullscreen)
        press(InputKey.ESCAPE)
        assertFalse(state.fullscreen)
        assertEquals(listOf(true, false), host.fullscreenRequests)
        // The platform reports fullscreen changes it made itself.
        store.onFullscreenChanged(true)
        assertTrue(state.fullscreen)
        press(InputKey.F)
        assertEquals(listOf(true, false, false), host.fullscreenRequests)
    }

    @Test
    fun aClickWithAMenuOpenClosesIt() = playerTest {
        playing()
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.SPEED))
        input(InputEvent.Click(x = 0.5f))
        advance(500.milliseconds)
        assertNull(state.menu)
        assertTrue(engine.paused.isEmpty())
    }

    @Test
    fun withTheControlsChosenAClickHidesAndShowsTheControlsAndNeverPauses() = playerTest {
        playing()
        // The profile's setting, changed while the video plays.
        sessionInfo { it.copy(videoClick = VideoClickAction.CONTROLS) }
        assertTrue(state.controlsVisible)
        input(InputEvent.Click(x = 0.5f))
        assertFalse(state.controlsVisible, "hidden at once, not after the auto-hide")

        advance(1.seconds)
        input(InputEvent.Click(x = 0.5f))
        assertTrue(state.controlsVisible)
        advance(2999.milliseconds)
        assertTrue(state.controlsVisible)
        advance(1.milliseconds)
        assertFalse(state.controlsVisible, "shown with the usual auto-hide")
        assertTrue(engine.paused.isEmpty())
        assertFalse(state.paused)
    }

    @Test
    fun withTheControlsChosenADoubleClickTogglesTheControlsOnceAndFullscreen() = playerTest {
        playing()
        sessionInfo { it.copy(videoClick = VideoClickAction.CONTROLS) }
        input(InputEvent.Click(x = 0.5f, clickCount = 1))
        advance(200.milliseconds)
        input(InputEvent.Click(x = 0.5f, clickCount = 2))
        advance(1.seconds)
        assertEquals(listOf(true), host.fullscreenRequests)
        assertFalse(state.controlsVisible, "the first click hid the controls, the second didn't bring them back")
        assertTrue(engine.paused.isEmpty())
    }

    @Test
    fun withTheControlsChosenTheKeysAndThePlayButtonStillPauseAndAClickNeverPlays() = playerTest {
        playing()
        sessionInfo { it.copy(videoClick = VideoClickAction.CONTROLS) }
        press(InputKey.SPACE)
        assertEquals(listOf(true), engine.paused)
        // The click shows or hides the controls; it never plays.
        val shown = state.controlsVisible
        input(InputEvent.Click(x = 0.5f))
        advance(500.milliseconds)
        assertTrue(state.paused)
        assertEquals(!shown, state.controlsVisible)
        // The controls' play button.
        dispatch(PlayerCommand.TogglePause)
        assertEquals(listOf(true, false), engine.paused)

        // A click with a menu open still closes it.
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.SPEED))
        input(InputEvent.Click(x = 0.5f))
        advance(500.milliseconds)
        assertNull(state.menu)
        assertTrue(state.controlsVisible)
        assertEquals(listOf(true, false), engine.paused)
    }

    @Test
    fun aHeldToggleActsOnce() = playerTest {
        playing(position = 100.0)
        input(InputEvent.KeyDown(InputKey.SPACE))
        repeat(3) { input(InputEvent.KeyDown(InputKey.SPACE, repeat = true)) }
        assertTrue(input(InputEvent.KeyUp(InputKey.SPACE)))
        assertEquals(listOf(true), engine.paused)
        // Keys the store doesn't use stay with the platform.
        assertFalse(input(InputEvent.KeyDown(InputKey.Q)))
        assertFalse(input(InputEvent.KeyUp(InputKey.Q)))
    }

    /**
     * The seek shortcut's steps gather into one seek, which goes as the key comes up; a held key's repeats don't add
     * to it (the seek shortcuts act once per press), and the timeline shows the target meanwhile.
     */
    @Test
    fun aSeekShortcutSeeksOnceAsItsKeyComesUp() = playerTest {
        playing(position = 100.0)
        input(InputEvent.KeyDown(InputKey.RIGHT))
        assertTrue(engine.seeks.isEmpty(), "the press only moves the target")
        assertEquals("1:50", timeline.position)
        repeat(3) { input(InputEvent.KeyDown(InputKey.RIGHT, repeat = true)) }
        assertEquals("1:50", timeline.position, "repeats of a seek shortcut add nothing")
        assertTrue(input(InputEvent.KeyUp(InputKey.RIGHT)))
        assertEquals(listOf(110.0 to true), engine.seeks)
        assertEquals(listOf(110.0), session.seeks)
    }

    /** A burst whose release never reaches the store (it went to a menu) lands a moment after its last step. */
    @Test
    fun aSeekBurstWithoutItsReleaseLandsAfterItsLastStep() = playerTest {
        playing(position = 100.0)
        input(InputEvent.KeyDown(InputKey.LEFT))
        advance(799.milliseconds)
        assertTrue(engine.seeks.isEmpty())
        assertEquals("1:30", timeline.position)
        advance(1.milliseconds)
        assertEquals(listOf(90.0), engine.seeks.map { it.first })
    }

    @Test
    fun quickSeeksBuildOnEachOtherBeforeTheEngineReports() = playerTest {
        playing(position = 100.0)
        engine.echo = false
        repeat(3) { press(InputKey.LEFT) }
        assertEquals(listOf(90.0, 80.0, 70.0), engine.seeks.map { it.first })
        assertEquals("1:10", timeline.position)
    }

    /**
     * Keyframes 10.427 s apart (250 frames at 23.976 fps, x264's and x265's default): a keyframe seek 10 s on from just
     * past one lands back on it, and a seek bar's few seconds forward too.
     */
    @Test
    fun aSeekLandsWhereItAsksWhereverTheKeyframesAre() = playerTest {
        engine.keyframeSeconds = 10.427
        playing(position = 10.5)
        press(InputKey.RIGHT)
        advance(2.seconds)
        assertEquals("0:20", timeline.position, "Right: 10 s on")
        dispatch(PlayerCommand.SeekTo(25.0))
        advance(2.seconds)
        assertEquals("0:25", timeline.position, "the system's seek bar")
    }
}

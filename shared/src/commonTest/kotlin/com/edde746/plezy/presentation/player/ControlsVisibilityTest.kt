package com.edde746.plezy.presentation.player

import com.edde746.plezy.downloads.testMediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.InputKey
import com.edde746.plezy.input.InputProfile
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.playback.EngineError
import com.edde746.plezy.playback.PlaybackFailure
import com.edde746.plezy.playback.Chapter
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

class ControlsVisibilityTest {
    @Test
    fun controlsHideAfterTheDelayWhilePlaying() = playerTest {
        playing()
        advance(2999.milliseconds)
        assertTrue(state.controlsVisible)
        advance(1.milliseconds)
        assertFalse(state.controlsVisible)
    }

    @Test
    fun tvAndTouchWaitLonger() = playerTest(InputProfile.TV) {
        playing()
        dispatch(PlayerCommand.ShowControls)
        advance(4999.milliseconds)
        assertTrue(state.controlsVisible)
        advance(1.milliseconds)
        assertFalse(state.controlsVisible)
    }

    @Test
    fun hoverShowsTheControlsAndRestartsTheTimer() = playerTest {
        playing()
        advance(3.seconds)
        assertFalse(state.controlsVisible)
        input(InputEvent.PointerMove)
        assertTrue(state.controlsVisible)
        advance(2.seconds)
        input(InputEvent.PointerMove)
        advance(2999.milliseconds)
        assertTrue(state.controlsVisible)
        advance(1.milliseconds)
        assertFalse(state.controlsVisible)
    }

    @Test
    fun anyKeyWhileTheControlsAreUpRestartsTheTimer() = playerTest(InputProfile.TV) {
        playing()
        dispatch(PlayerCommand.ShowControls)
        advance(4.seconds)
        // Focus navigation among the controls: the store leaves the key to the platform but counts it as activity.
        input(InputEvent.ControlFocus(onControl = true))
        assertFalse(press(InputKey.DOWN))
        advance(4999.milliseconds)
        assertTrue(state.controlsVisible)
        advance(1.milliseconds)
        assertFalse(state.controlsVisible)
    }

    @Test
    fun pausedTheControlsStayUpUntilPlayingAgain() = playerTest {
        playing()
        dispatch(PlayerCommand.TogglePause)
        assertEquals(PlaybackStatus.PAUSED, state.status)
        advance(30.seconds)
        assertTrue(state.controlsVisible)
        dispatch(PlayerCommand.TogglePause)
        advance(2999.milliseconds)
        assertTrue(state.controlsVisible)
        advance(1.milliseconds)
        assertFalse(state.controlsVisible)
    }

    @Test
    fun aPauseFromElsewhereBringsTheControlsUp() = playerTest(InputProfile.TV) {
        playing()
        advance(10.seconds)
        assertFalse(state.controlsVisible)
        engineState { it.copy(paused = true) }
        assertTrue(state.controlsVisible, "a media key, a room or a cast sender paused it")
        advance(30.seconds)
        assertTrue(state.controlsVisible)
    }

    @Test
    fun anOpenMenuKeepsTheControlsUp() = playerTest {
        playing()
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.SUBTITLES))
        advance(30.seconds)
        assertTrue(state.controlsVisible)
        assertEquals(PlayerMenu.SUBTITLES, state.menu)
        dispatch(PlayerCommand.CloseMenu)
        advance(3.seconds)
        assertFalse(state.controlsVisible)
    }

    @Test
    fun scrubbingKeepsTheControlsUp() = playerTest {
        playing()
        advance(3.seconds)
        dispatch(PlayerCommand.ScrubTo(0.5))
        advance(30.seconds)
        assertTrue(state.controlsVisible)
        dispatch(PlayerCommand.CommitScrub)
        advance(3.seconds)
        assertFalse(state.controlsVisible)
    }

    @Test
    fun anErrorKeepsTheControlsUp() = playerTest {
        playing()
        advance(3.seconds)
        sessionInfo { it.copy(failure = PlaybackFailure.Engine(EngineError("HTTP error 404", httpStatus = 404))) }
        advance(30.seconds)
        assertTrue(state.controlsVisible)
    }

    @Test
    fun loadingKeepsTheControlsUp() = playerTest {
        advance(30.seconds)
        assertTrue(state.controlsVisible)
        assertEquals(PlaybackStatus.OPENING, state.status)
        playing()
        advance(3.seconds)
        assertFalse(state.controlsVisible)
    }

    @Test
    fun aPressOnTheControlsKeepsThemUpAndLeavingTheWindowHidesThem() = playerTest {
        playing()
        input(InputEvent.PointerDown(pointer = 1))
        advance(30.seconds)
        assertTrue(state.controlsVisible)
        input(InputEvent.PointerUp(pointer = 1))
        input(InputEvent.PointerExit)
        assertFalse(state.controlsVisible)
    }

    /** The content strip keeps the controls up, and goes with them when the pointer leaving the player hides them. */
    @Test
    fun theContentStripGoesWithTheControls() = playerTest(preferences = PlayerChoices(playerNavigation = true)) {
        playing()
        engineState { it.copy(chapters = listOf(Chapter("Opening", 0.0), Chapter("Part A", 90.0))) }
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.CONTENT_STRIP))
        assertEquals(PlayerMenu.CONTENT_STRIP, state.menu)
        advance(30.seconds)
        assertTrue(state.controlsVisible)
        input(InputEvent.PointerExit)
        assertFalse(state.controlsVisible)
        assertNull(state.menu)
        // Raised again, they come back without it.
        input(InputEvent.PointerMove)
        assertTrue(state.controlsVisible)
        assertNull(state.menu)
    }

    @Test
    fun anAssistiveTechnologyKeepsTheControlsUpUntilItStops() = playerTest {
        playing()
        advance(3.seconds)
        assertFalse(state.controlsVisible)
        store.onAssistiveTechnologyChanged(true)
        assertTrue(state.controlsVisible, "VoiceOver starting brings the controls up")
        advance(30.seconds)
        assertTrue(state.controlsVisible, "past the auto-hide delay while it runs")
        dispatch(PlayerCommand.ToggleControls)
        assertTrue(state.controlsVisible, "a tap on the video doesn't take them away either")
        store.onAssistiveTechnologyChanged(false)
        advance(2999.milliseconds)
        assertTrue(state.controlsVisible, "stopping it restarts the timer")
        advance(1.milliseconds)
        assertFalse(state.controlsVisible)
    }

    @Test
    fun backClosesTheInnermostLayerFirst() = playerTest {
        playing()
        dispatch(PlayerCommand.ToggleInfo)
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.AUDIO))
        dispatch(PlayerCommand.ScrubTo(0.5))

        dispatch(PlayerCommand.Back)
        assertEquals(null, timeline.scrub)
        assertEquals(PlayerMenu.AUDIO, state.menu)
        dispatch(PlayerCommand.Back)
        assertEquals(null, state.menu)
        assertTrue(state.controlsVisible)
        dispatch(PlayerCommand.Back)
        assertFalse(state.controlsVisible)
        assertTrue(preferences.choices.value.showPlaybackInfo, "Back never turns the playback info off: it is no layer")
        assertNotNull(state.playbackInfo)
        assertEquals(0, host.closed)
        dispatch(PlayerCommand.Back)
        assertEquals(1, host.closed)
        // The scrub's seek along went back where it started as Back dropped it; nothing else seeked.
        assertEquals(listOf(300.0 to true, 100.0 to true), engine.seeks)
    }

    @Test
    fun backWhilePausedHidesTheControlsThenLeavesThePlayer() = playerTest {
        playing()
        dispatch(PlayerCommand.Pause)
        dispatch(PlayerCommand.Back)
        assertFalse(state.controlsVisible)
        assertEquals(0, host.closed)
        dispatch(PlayerCommand.Back)
        assertEquals(1, host.closed)
    }

    @Test
    fun subtitlesMoveAboveTheControlsWhileTheyShow() = playerTest {
        playing()
        // Nothing moves before the view has measured the controls.
        assertTrue(engine.subtitleLifts.isEmpty())
        store.onControlsHeightChanged(0.2)
        assertEquals(listOf(0.2), engine.subtitleLifts)
        advance(3.seconds)
        assertFalse(state.controlsVisible)
        assertEquals(listOf(0.2, 0.0), engine.subtitleLifts)
        // Hidden controls keep their measured height: the next show lifts at once.
        input(InputEvent.PointerMove)
        assertEquals(listOf(0.2, 0.0, 0.2), engine.subtitleLifts)
        // Sub-pixel layout changes stay in the view.
        store.onControlsHeightChanged(0.2002)
        assertEquals(3, engine.subtitleLifts.size)
        // No controls drawn (picture-in-picture): subtitles back in place while the store still has the controls up.
        store.onControlsHeightChanged(0.0)
        assertTrue(state.controlsVisible)
        assertEquals(0.0, engine.subtitleLifts.last())
        // Never more than half the player.
        store.onControlsHeightChanged(0.8)
        assertEquals(0.5, engine.subtitleLifts.last())
    }

    @Test
    fun anotherItemShowsTheControlsWithItsTitleForTheUsualTime() = playerTest {
        sessionInfo { it.copy(item = testMediaItem("e1", MediaKind.EPISODE, "srv"), title = "Episode 1") }
        playing()
        advance(3.seconds)
        assertFalse(state.controlsVisible)
        // Autoplay or a remote's Next moves on with the controls down: the next file opens and plays.
        engineState { it.copy(loaded = false, positionSeconds = 0.0) }
        sessionInfo { it.copy(item = testMediaItem("e2", MediaKind.EPISODE, "srv"), title = "Episode 2") }
        assertTrue(state.controlsVisible)
        assertEquals("Episode 2", state.title)
        // Loading takes as long as it takes; the time counts from the first frame.
        advance(10.seconds)
        assertTrue(state.controlsVisible)
        playing(position = 0.0)
        advance(2999.milliseconds)
        assertTrue(state.controlsVisible)
        advance(1.milliseconds)
        assertFalse(state.controlsVisible)
        // The same item again (another version, a reload) leaves them as they are.
        sessionInfo { it.copy(title = "Episode 2 (720p)") }
        assertFalse(state.controlsVisible)
    }
}

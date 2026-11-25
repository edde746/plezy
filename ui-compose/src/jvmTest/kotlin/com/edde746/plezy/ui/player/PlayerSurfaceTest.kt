package com.edde746.plezy.ui.player

import androidx.compose.ui.input.key.Key
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.click
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performMouseInput
import androidx.compose.ui.test.performSemanticsAction
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** The video under the controls as a screen reader and a mouse reach it, and the remote's way off the timeline. */
@OptIn(ExperimentalTestApi::class)
class PlayerSurfaceTest {
    /** A screen reader finds the video as the button that hides the controls while they show, and shows them when not. */
    @Test
    fun aScreenReaderReachesTheVideoAsTheButtonThatShowsOrHidesTheControls() = runComposeUiTest {
        val commands = mutableListOf<PlayerCommand>()
        player(FormFactor.HANDHELD, onCommand = { commands += it }) { testPlayerState() }
        onNodeWithContentDescription(T.videoControls.hidePlaybackControls).performSemanticsAction(SemanticsActions.OnClick)
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.ToggleControls), commands) }
    }

    @Test
    fun withTheControlsDownTheVideoOffersToShowThem() = runComposeUiTest {
        player(FormFactor.DESKTOP) { testPlayerState().copy(controlsVisible = false) }
        onNodeWithContentDescription(T.videoControls.showPlaybackControls).assertExists()
    }

    /**
     * A mouse press held still on the video past the long-press time holds 2× until it lifts, and is no click; a quick
     * one is a click.
     */
    @Test
    fun aHeldMousePressIsAHoldAndNoClick() = runComposeUiTest {
        val events = mutableListOf<InputEvent>()
        player(FormFactor.DESKTOP, onInput = { events += it; true }) { testPlayerState().copy(controlsVisible = false) }
        waitForIdle()
        mainClock.autoAdvance = false
        onRoot().performMouseInput { moveTo(center); press() }
        mainClock.advanceTimeBy(700)
        onRoot().performMouseInput { release() }
        mainClock.autoAdvance = true
        waitForIdle()
        val pointer = events.filter { it is InputEvent.Hold || it is InputEvent.Click }
        assertEquals(listOf<InputEvent>(InputEvent.Hold(held = true), InputEvent.Hold(held = false)), pointer)

        events.clear()
        onRoot().performMouseInput { click(center) }
        waitForIdle()
        assertTrue(events.any { it is InputEvent.Click } && events.none { it is InputEvent.Hold }, "a click: $events")
    }

    /** On TV Down from the timeline goes to Play/Pause and Up, with no prompt button showing, hides the controls. */
    @Test
    fun onTvDownFromTheTimelineIsPlayPauseAndUpHidesTheControls() = runComposeUiTest {
        val probe = PlayerProbe()
        val commands = mutableListOf<PlayerCommand>()
        player(FormFactor.TV, probe = probe, onCommand = { commands += it }) { testPlayerState() }
        waitForIdle()
        assertEquals("player.playPause", probe.focused)
        press(Key.DirectionUp)
        assertEquals("player.scrub", probe.focused)
        press(Key.DirectionDown)
        assertEquals("player.playPause", probe.focused)
        press(Key.DirectionUp)
        press(Key.DirectionUp)
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.HideControls), commands.filter { it == PlayerCommand.HideControls }) }
    }
}

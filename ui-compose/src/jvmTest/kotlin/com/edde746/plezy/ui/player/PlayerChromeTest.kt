package com.edde746.plezy.ui.player

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.longClick
import androidx.compose.ui.test.performMouseInput
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.player.PlaybackStatus
import com.edde746.plezy.presentation.player.ScrubState
import com.edde746.plezy.strings.T
import kotlinx.coroutines.flow.MutableStateFlow
import kotlin.math.abs
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * The header (title, episode line, no time of day), the fullscreen button, the controls before the first frame, their
 * fade and hidden start, and the seek bar's hover tooltip.
 */
@OptIn(ExperimentalTestApi::class)
class PlayerChromeTest {
    /** An episode's header: the series as the title, the episode line under it. */
    @Test
    fun theHeaderShowsTheTitleAndTheEpisodeLine() = runComposeUiTest {
        player(FormFactor.DESKTOP) { testPlayerState() }
        onNodeWithText("Chernobyl").assertExists()
        onNodeWithText("S1E1 · 1:23:45").assertExists()
    }

    /** A title without an episode line (a movie, the store's fallback name) shows alone. */
    @Test
    fun aTitleWithoutAnEpisodeLineShowsAlone() = runComposeUiTest {
        player(FormFactor.DESKTOP) { testPlayerState(episodes = null).copy(title = T.common.unknown, subtitle = null) }
        onNodeWithText(T.common.unknown).assertExists()
        onNodeWithText("S1E1 · 1:23:45").assertDoesNotExist()
    }

    /**
     * No form factor's header shows the time of day: no text on screen but the seek bar's position and length reads as
     * a clock time ("18:00", "6:00 PM").
     */
    @Test
    fun theHeaderShowsNoTimeOfDay() {
        val windows = listOf(
            FormFactor.DESKTOP to DpSize(960.dp, 540.dp),
            FormFactor.TV to DpSize(960.dp, 540.dp),
            FormFactor.HANDHELD to DpSize(800.dp, 380.dp),
            FormFactor.HANDHELD to DpSize(380.dp, 800.dp),
        )
        val timeOfDay = Regex("""\d{1,2}:\d{2}([\s\u202F]?[AP]M)?""")
        for ((formFactor, size) in windows) runComposeUiTest {
            player(formFactor, size = size) { testPlayerState() }
            waitForIdle()
            val texts = onAllNodes(SemanticsMatcher.keyIsDefined(SemanticsProperties.Text), useUnmergedTree = true)
                .fetchSemanticsNodes().flatMap { node -> node.config[SemanticsProperties.Text].map { it.text } }
            val clocks = texts.filter { timeOfDay.matches(it) } - setOf(testTimeline.position, testTimeline.duration)
            assertTrue(clocks.isEmpty(), "$formFactor $size: $clocks")
        }
    }

    /**
     * A phone's top bar keeps the title's room by its width: on its side it has room for every button; upright and
     * narrow the rotation lock moves into the options sheet first, then the fit, the screen lock last, never one out of
     * that order.
     */
    @Test
    fun aNarrowTopBarMovesItsButtonsInTheirOrder() {
        val order = listOf("player.rotation", "player.fit", "player.lock")
        for ((size, roomForAll) in listOf(DpSize(800.dp, 380.dp) to true, DpSize(300.dp, 700.dp) to false)) runComposeUiTest {
            val probe = PlayerProbe()
            player(FormFactor.HANDHELD, probe = probe, size = size) { testPlayerState().copy(rotationLocked = false) }
            waitForIdle()
            val shown = order.map { it in probe.bounds }
            if (roomForAll) {
                assertEquals(listOf(true, true, true), shown, "$size")
            } else {
                assertEquals(false, shown.first(), "$size: the rotation lock moves first")
                assertEquals(shown.sorted(), shown, "$size: a button stays only if those after it do: $order $shown")
            }
        }
    }

    /** On a phone a long press on the rotation lock or the screen lock names it, so the two lock icons tell apart. */
    @Test
    fun onAPhoneALongPressNamesEachLockButton() = runComposeUiTest {
        player(FormFactor.HANDHELD, size = DpSize(800.dp, 380.dp)) { testPlayerState().copy(rotationLocked = false) }
        for (label in listOf(T.videoControls.lockRotation, T.videoControls.lockScreen)) {
            onNodeWithText(label).assertDoesNotExist()
            onNodeWithContentDescription(label).performTouchInput { longClick() }
            waitForIdle()
            onNodeWithText(label).assertExists()
        }
    }

    /** Windowed, the button enters fullscreen; a click asks for it. */
    @Test
    fun windowedTheButtonEntersFullscreen() = runComposeUiTest {
        val commands = mutableListOf<PlayerCommand>()
        player(FormFactor.DESKTOP, onCommand = { commands += it }) { testPlayerState().copy(fullscreen = false) }
        onNodeWithContentDescription(T.videoControls.exitFullscreenButton).assertDoesNotExist()
        onNodeWithContentDescription(T.videoControls.fullscreenButton).performClick()
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.ToggleFullscreen), commands) }
    }

    /** The button follows the window: opened fullscreen it exits, and it flips back as the window leaves fullscreen. */
    @Test
    fun theButtonFollowsTheWindowsFullscreen() = runComposeUiTest {
        var fullscreen by mutableStateOf(true)
        player(FormFactor.DESKTOP) { testPlayerState().copy(fullscreen = fullscreen) }
        onNodeWithContentDescription(T.videoControls.exitFullscreenButton).assertExists()
        onNodeWithContentDescription(T.videoControls.fullscreenButton).assertDoesNotExist()
        fullscreen = false
        onNodeWithContentDescription(T.videoControls.fullscreenButton).assertExists()
        onNodeWithContentDescription(T.videoControls.exitFullscreenButton).assertDoesNotExist()
    }

    /** Before the first frame only the header shows: no timeline or transport until the video opens. */
    @Test
    fun theBottomControlsWaitForTheFirstFrame() = runComposeUiTest {
        val probe = PlayerProbe()
        var status by mutableStateOf(PlaybackStatus.OPENING)
        player(FormFactor.DESKTOP, probe = probe) { testPlayerState().copy(status = status) }
        waitForIdle()
        assertTrue("player.back" in probe.bounds, "the header before the first frame")
        assertTrue("player.scrub" !in probe.bounds && "player.playPause" !in probe.bounds, "controls before the first frame")
        status = PlaybackStatus.PLAYING
        waitForIdle()
        assertTrue("player.scrub" in probe.bounds && "player.playPause" in probe.bounds, "controls after the first frame")
    }

    /** The next item resolving and opening keeps the picture black: the last item's frame never shows under its title. */
    @Test
    fun thePictureStaysCoveredUntilTheItemsFirstFrame() = runComposeUiTest {
        val probe = PlayerProbe()
        var status by mutableStateOf(PlaybackStatus.PLAYING)
        player(FormFactor.HANDHELD, probe = probe) { testPlayerState().copy(status = status) }
        waitForIdle()
        assertTrue("player.videoCover" !in probe.bounds, "covered while playing")
        for (loading in listOf(PlaybackStatus.RESOLVING, PlaybackStatus.OPENING)) {
            status = loading
            waitForIdle()
            assertEquals(probe.bounds["player.video"], probe.bounds["player.videoCover"], "$loading")
        }
        status = PlaybackStatus.BUFFERING
        waitForIdle()
        assertTrue("player.videoCover" !in probe.bounds, "covered while buffering")
    }

    /** The controls fade in and out over 200 ms: halfway through a fade they are still there, after it gone. */
    @Test
    fun theControlsFadeOverTwoHundredMilliseconds() = runComposeUiTest {
        val probe = PlayerProbe()
        var visible by mutableStateOf(true)
        player(FormFactor.DESKTOP, probe = probe) { testPlayerState().copy(controlsVisible = visible) }
        waitForIdle()
        mainClock.autoAdvance = false
        visible = false
        mainClock.advanceTimeBy(100)
        assertTrue("player.playPause" in probe.bounds, "half a fade out")
        mainClock.advanceTimeBy(150)
        assertTrue("player.playPause" !in probe.bounds, "after the fade out")
        visible = true
        mainClock.advanceTimeByFrame()
        mainClock.advanceTimeByFrame()
        assertTrue("player.playPause" in probe.bounds, "the fade in starts at once")
    }

    /** Started hidden (TV), the controls are never laid out through the loading and the first frame. */
    @Test
    fun aHiddenStartNeverLaysTheControlsOut() = runComposeUiTest {
        val probe = PlayerProbe()
        val seen = mutableSetOf<String>()
        var status by mutableStateOf(PlaybackStatus.OPENING)
        player(FormFactor.TV, probe = probe) {
            testPlayerState().copy(status = status, controlsVisible = false, chromeHiddenAtStart = true).also { seen += probe.bounds.keys }
        }
        waitForIdle()
        seen += probe.bounds.keys
        status = PlaybackStatus.PLAYING
        waitForIdle()
        seen += probe.bounds.keys
        assertTrue(seen.none { it == "player.back" || it == "player.playPause" || it == "player.scrub" }, "laid out: $seen")
    }

    /**
     * A mouse over the seek bar tells the store where at each 4 dp step it moves (a move within a step tells nothing),
     * and the bar shows the store's hover tooltip; leaving the bar ends it.
     */
    @Test
    fun aMouseOverTheSeekBarShowsTheHoverTooltip() = runComposeUiTest {
        val probe = PlayerProbe()
        val commands = mutableListOf<PlayerCommand>()
        val timeline = MutableStateFlow(testTimeline)
        player(FormFactor.DESKTOP, probe = probe, onCommand = { commands += it }, timeline = timeline) { testPlayerState() }
        waitForIdle()
        val bar = probe.bounds.getValue("player.scrub")
        val step = with(density) { 4.dp.toPx() }
        fun hovers() = commands.filterIsInstance<PlayerCommand.HoverTimeline>()
        onRoot().performMouseInput { moveTo(Offset(bar.center.x, bar.center.y)) }
        waitForIdle()
        assertEquals(1, hovers().size)
        val fraction = assertNotNull(hovers().single().fraction)
        assertTrue(abs(fraction - 0.5) < 0.02, "half way: $fraction")
        assertTrue("player.scrubTooltip" !in probe.bounds, "the store hasn't answered yet")

        // Within the step: nothing new; a step on: the next one.
        onRoot().performMouseInput { moveBy(Offset(0f, 1f)) }
        waitForIdle()
        assertEquals(1, hovers().size)
        onRoot().performMouseInput { moveBy(Offset(step * 2, 0f)) }
        waitForIdle()
        assertEquals(2, hovers().size)

        timeline.value = testTimeline.copy(hover = ScrubState(seconds = 10.0, progress = 0.5f, position = "0:10", offset = "+0:00", chapter = null))
        waitForIdle()
        assertTrue("player.scrubTooltip" in probe.bounds)
        onRoot().performMouseInput { moveTo(Offset(bar.center.x, bar.top - 200f)) }
        waitForIdle()
        assertNull(hovers().last().fraction)
    }
}

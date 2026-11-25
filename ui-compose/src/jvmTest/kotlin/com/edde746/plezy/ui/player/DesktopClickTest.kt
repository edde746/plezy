package com.edde746.plezy.ui.player

import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.click
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performMouseInput
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.model.FormFactor
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * With the desktop's controls up, a click that misses a control by a little (beside the seek bar, on a time, on a
 * disabled button, between the buttons, on the top bar) is the bar's: it never reaches the video, where it would pause
 * or hide the controls. The video itself and the bars' controls still take their clicks.
 */
@OptIn(ExperimentalTestApi::class)
class DesktopClickTest {
    private val commands = mutableListOf<PlayerCommand>()
    private val clicks = mutableListOf<InputEvent.Click>()
    private val probe = PlayerProbe()

    private fun ComposeUiTest.desktopPlayer() {
        player(FormFactor.DESKTOP, probe = probe, onCommand = { commands += it }, onInput = { if (it is InputEvent.Click) clicks += it; false }) {
            // No chapters: the chapter buttons are off.
            testPlayerState().copy(chapters = emptyList())
        }
        waitForIdle()
    }

    private fun ComposeUiTest.clickAt(at: Offset) {
        onRoot().performMouseInput { click(at) }
        waitForIdle()
    }

    private fun bounds(name: String) = probe.bounds.getValue(name)

    @Test
    fun aClickThatMissesTheBarsControlsNeverReachesTheVideo() = runComposeUiTest {
        desktopPlayer()
        val scrub = bounds("player.scrub")
        val playPause = bounds("player.playPause")
        val missed = mapOf(
            "just above the seek bar" to Offset(scrub.center.x, scrub.top - 3f),
            "just below the seek bar" to Offset(scrub.center.x, scrub.bottom + 3f),
            "the position" to bounds("player.position").center,
            "the disabled next chapter button" to bounds("player.nextChapter").center,
            "the space beside the volume" to Offset(bounds("player.mute").left - 10f, playPause.center.y),
            "the padding under the buttons" to Offset(playPause.center.x, playPause.bottom + 6f),
            "the top bar beside the title" to Offset(bounds("player.title").right + 40f, bounds("player.back").center.y),
        )
        for ((where, at) in missed) {
            clickAt(at)
            assertEquals(emptyList(), clicks, "a click on $where reached the video")
            assertTrue(commands.none { it == PlayerCommand.TogglePause }, "a click on $where paused")
        }

        clickAt(bounds("player.video").center)
        assertEquals(1, clicks.size, "a click on the video itself goes to the video")
    }

    @Test
    fun theBarsControlsStillTakeTheirOwnClicks() = runComposeUiTest {
        desktopPlayer()
        clickAt(bounds("player.playPause").center)
        assertEquals(listOf<PlayerCommand>(PlayerCommand.TogglePause), commands.filter { it !is PlayerCommand.HoverTimeline })

        commands.clear()
        val scrub = bounds("player.scrub")
        clickAt(Offset(scrub.left + scrub.width * 0.75f, scrub.center.y))
        val scrubbedTo = commands.filterIsInstance<PlayerCommand.ScrubTo>().single().fraction
        assertTrue(scrubbedTo in 0.7..0.8, "three quarters along the bar, give or take the track's inset: $scrubbedTo")
        assertTrue(PlayerCommand.CommitScrub in commands)
        assertTrue(PlayerCommand.TogglePause !in commands, "a click on the seek bar also toggled playback")
        assertEquals(emptyList(), clicks)
    }
}

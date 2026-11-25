package com.edde746.plezy.ui.player

import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performMouseInput
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.player.PlaybackMode
import com.edde746.plezy.presentation.player.PlayerUiState
import com.edde746.plezy.presentation.player.TimelineState
import com.edde746.plezy.strings.T
import kotlinx.coroutines.flow.MutableStateFlow
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * The timeline's thumb is centred on the bar's end at a live window's edge (and on its start at 0), so half of it lies
 * past the bar. A press on that half grabs the thumb as a press on the bar does, by mouse and by finger on every form
 * factor: a scrub from the end, the drag's scrub, committed on release, and nothing for the video beneath.
 */
@OptIn(ExperimentalTestApi::class)
class ScrubThumbTest {
    private val window = testPlayerState(episodes = null).copy(mode = PlaybackMode.LIVE_WINDOW, seekable = true)
    private val edge = TimelineState(
        "−1:28", "", "", T.player.live.atEdge, 1f, 1f, emptyList(), positionSeconds = 88.0, durationSeconds = 88.0,
        liveLabel = T.player.live.badge, atLiveEdge = true,
    )
    private val movie = testPlayerState(episodes = null)
    private val start = testTimeline.copy(position = "0:00", remaining = "−0:20", positionLabel = "0:00 / 0:20", progress = 0f, positionSeconds = 0.0)

    @Test
    fun onTheDesktopTheThumbsHalfPastTheLiveEdgeGrabs() = runComposeUiTest { grabs(FormFactor.DESKTOP, window, edge, mouse = true) }

    @Test
    fun onAPhoneTheThumbsHalfPastTheLiveEdgeGrabs() = runComposeUiTest { grabs(FormFactor.HANDHELD, window, edge, mouse = false) }

    @Test
    fun onTvTheThumbsHalfPastTheLiveEdgeGrabs() = runComposeUiTest { grabs(FormFactor.TV, window, edge, mouse = true) }

    @Test
    fun onTheDesktopTheThumbsHalfBeforeTheStartGrabs() = runComposeUiTest { grabs(FormFactor.DESKTOP, movie, start, mouse = true) }

    /** Presses on the thumb's outer half, 3 dp past the bar (a quarter of the thumb at rest), and drags to the middle. */
    private fun ComposeUiTest.grabs(formFactor: FormFactor, state: PlayerUiState, timeline: TimelineState, mouse: Boolean) {
        val probe = PlayerProbe()
        val commands = mutableListOf<PlayerCommand>()
        val clicks = mutableListOf<InputEvent.Click>()
        player(formFactor, probe = probe, onCommand = { commands += it }, onInput = { if (it is InputEvent.Click) clicks += it; false }, timeline = MutableStateFlow(timeline)) { state }
        waitForIdle()
        val bar = probe.bounds.getValue("player.scrub")
        val atEnd = timeline.progress == 1f
        val past = with(density) { 3.dp.toPx() }
        val from = Offset(if (atEnd) bar.right + past else bar.left - past, bar.center.y)
        val to = bar.center
        if (mouse) {
            onRoot().performMouseInput { moveTo(from); press(); moveTo(to); release() }
        } else {
            onRoot().performTouchInput { down(from); moveTo(to); up() }
        }
        runOnIdle {
            val scrub = commands.filter { it is PlayerCommand.ScrubTo || it == PlayerCommand.CommitScrub || it == PlayerCommand.CancelScrub }
            val fractions = scrub.filterIsInstance<PlayerCommand.ScrubTo>().map { it.fraction }
            assertEquals(if (atEnd) 1.0 else 0.0, fractions.firstOrNull(), "$formFactor: the press's scrub, of $scrub")
            assertEquals(0.5, fractions.last(), 0.01, "$formFactor: the drag's scrub, of $scrub")
            assertEquals(PlayerCommand.CommitScrub, scrub.last(), "$formFactor: the release, of $scrub")
            assertEquals(emptyList(), clicks, "$formFactor: the press reaching the video")
        }
    }
}

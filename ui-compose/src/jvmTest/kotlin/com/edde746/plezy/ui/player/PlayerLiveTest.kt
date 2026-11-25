package com.edde746.plezy.ui.player

import androidx.compose.ui.input.key.Key
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.performSemanticsAction
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.player.PlaybackMode
import com.edde746.plezy.presentation.player.TimelineState
import com.edde746.plezy.strings.T
import kotlinx.coroutines.flow.MutableStateFlow
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * A live playback's controls: no timeline row and no rewind or forward, and one LIVE: the top bar's badge, with no
 * time played beside it anywhere. On TV focus goes from play/pause straight to the menus. With a rewind window a screen
 * reader moves the timeline.
 */
@OptIn(ExperimentalTestApi::class)
class PlayerLiveTest {
    private val live = testPlayerState(episodes = null).copy(mode = PlaybackMode.LIVE, seekable = false)
    private val liveTimeline = MutableStateFlow(
        TimelineState("", "", "", T.player.live.atEdge, 0f, 0f, emptyList(), positionSeconds = 120.0, durationSeconds = 0.0, liveLabel = T.player.live.badge),
    )
    private val gone = listOf("player.position", "player.scrub", "player.remaining", "player.rewind", "player.fastForward", "player.live")
    private val menus = listOf("player.options")

    /** On TV focus starts on play/pause and Right goes on to the first menu; the top bar's badge is the only LIVE. */
    @Test
    fun onTvTheTopBarsBadgeIsTheOnlyLive() = runComposeUiTest {
        val probe = PlayerProbe()
        tvPlayer(probe, liveTimeline) { live }
        runOnIdle { assertEquals("player.playPause", probe.focused) }
        assertOneLive(probe)
        press(Key.DirectionRight)
        runOnIdle { assertEquals(menus.first(), probe.focused) }
        press(Key.DirectionLeft)
        runOnIdle { assertEquals("player.playPause", probe.focused) }
    }

    @Test
    fun onAPhoneTheTopBarsBadgeIsTheOnlyLive() = runComposeUiTest {
        val probe = PlayerProbe()
        player(FormFactor.HANDHELD, probe = probe, timeline = liveTimeline) { live }
        waitForIdle()
        assertOneLive(probe)
    }

    @Test
    fun onTheDesktopTheTopBarsBadgeIsTheOnlyLive() = runComposeUiTest {
        val probe = PlayerProbe()
        player(FormFactor.DESKTOP, probe = probe, timeline = liveTimeline) { live }
        waitForIdle()
        assertOneLive(probe)
    }

    /**
     * With a rewind window a screen reader's decrease and increase seek ten seconds back and on, as the bar's
     * semantics do on a video (live has no rewind or forward buttons).
     */
    @Test
    fun aScreenReaderSeeksARewindWindowsTimelineTenSecondsAtATime() = runComposeUiTest {
        val window = testPlayerState(episodes = null).copy(mode = PlaybackMode.LIVE_WINDOW, seekable = true)
        val timeline = MutableStateFlow(
            TimelineState("−1:28", "", "", T.player.live.behind("0:44"), 0.5f, 1f, emptyList(), positionSeconds = 44.0, durationSeconds = 88.0, liveLabel = T.player.live.badge),
        )
        val commands = mutableListOf<PlayerCommand>()
        player(FormFactor.HANDHELD, onCommand = { commands += it }, timeline = timeline) { window }
        val bar = onNodeWithContentDescription(T.player.timeline)
        bar.performSemanticsAction(SemanticsActions.SetProgress) { it(0.45f) }
        bar.performSemanticsAction(SemanticsActions.SetProgress) { it(0.55f) }
        bar.performSemanticsAction(SemanticsActions.SetProgress) { it(0.5f) }
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.SeekBy(-10.0), PlayerCommand.SeekBy(10.0)), commands) }
    }

    /** The badge in the top bar, and no timeline, skips or live label below. */
    private fun assertOneLive(probe: PlayerProbe) {
        assertTrue("player.liveBadge" in probe.bounds, "the top bar's LIVE")
        assertEquals(emptyList(), gone.filter { it in probe.bounds }, "shown while live")
    }
}

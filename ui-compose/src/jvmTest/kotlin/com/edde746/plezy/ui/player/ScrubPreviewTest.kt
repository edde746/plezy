package com.edde746.plezy.ui.player

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.backend.ScrubFrame
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.player.ScrubState
import kotlinx.coroutines.flow.MutableStateFlow
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * The timeline's preview draws its frame at the frame's own shape, never squeezed into the bar's height: a BIF frame
 * (Plex, Emby) at its video's aspect, a trickplay tile (Jellyfin) at the tile's, wide, 4:3, scope or portrait, hovered
 * or scrubbed, on every form factor; the bubble holding it stays above the bar. On a phone, where the preview rises
 * over the centred transport, the transport fades out while the viewer scrubs and comes back when the scrub ends.
 */
@OptIn(ExperimentalTestApi::class)
class ScrubPreviewTest {
    private val frames = listOf(
        ScrubFrame.Bytes(byteArrayOf(1), aspectRatio = 16.0 / 9),
        ScrubFrame.Bytes(byteArrayOf(1), aspectRatio = 2.39),
        ScrubFrame.SheetTile("sheet.jpg", tileColumn = 1, tileRow = 0, sheetColumns = 10, sheetRows = 10, tileWidth = 320, tileHeight = 240),
        ScrubFrame.SheetTile("sheet.jpg", tileColumn = 0, tileRow = 1, sheetColumns = 10, sheetRows = 10, tileWidth = 320, tileHeight = 568),
    )

    @Test
    fun onTheDesktopTheHoveredFrameKeepsItsShape() = runComposeUiTest { keepsShape(FormFactor.DESKTOP, hover = true) }

    @Test
    fun onTheDesktopTheScrubbedFrameKeepsItsShape() = runComposeUiTest { keepsShape(FormFactor.DESKTOP, hover = false) }

    @Test
    fun onAPhoneTheScrubbedFrameKeepsItsShape() = runComposeUiTest { keepsShape(FormFactor.HANDHELD, hover = false) }

    @Test
    fun onTvTheScrubbedFrameKeepsItsShape() = runComposeUiTest { keepsShape(FormFactor.TV, hover = false) }

    @Test
    fun onAPhoneTheCentreTransportStepsAsideWhileScrubbing() = runComposeUiTest {
        val probe = PlayerProbe()
        val timeline = MutableStateFlow(testTimeline)
        var scrubbing by mutableStateOf(false)
        player(FormFactor.HANDHELD, probe = probe, timeline = timeline) { testPlayerState().copy(scrubbing = scrubbing) }
        waitForIdle()
        val centre = listOf("player.previous", "player.rewind", "player.playPause", "player.fastForward", "player.next")
        assertEquals(centre, centre.filter { it in probe.bounds }, "the transport before the scrub")

        scrubbing = true
        timeline.value = testTimeline.copy(scrub = ScrubState(10.0, 0.5f, "0:10", "−0:05", chapter = null, frame = frames.first()))
        waitForIdle()
        assertEquals(emptyList(), centre.filter { it in probe.bounds }, "the transport while scrubbing")
        assertTrue("player.scrubFrame" in probe.bounds && "player.scrub" in probe.bounds, "the preview and the bar while scrubbing")

        scrubbing = false
        timeline.value = testTimeline
        waitForIdle()
        assertEquals(centre, centre.filter { it in probe.bounds }, "the transport after the scrub")
    }

    private fun ComposeUiTest.keepsShape(formFactor: FormFactor, hover: Boolean) {
        val probe = PlayerProbe()
        val timeline = MutableStateFlow(testTimeline)
        player(formFactor, probe = probe, timeline = timeline) { testPlayerState(episodes = null) }
        for (frame in frames) {
            val preview = ScrubState(10.0, 0.5f, "0:10", offset = if (hover) "" else "−0:05", chapter = null, frame = frame)
            timeline.value = if (hover) testTimeline.copy(hover = preview) else testTimeline.copy(scrub = preview)
            waitForIdle()
            val shown = probe.bounds.getValue("player.scrubFrame")
            assertEquals(frame.aspectRatio, (shown.width / shown.height).toDouble(), 0.02, "$formFactor: the frame of aspect ${frame.aspectRatio}, drawn $shown")
            val bubble = probe.bounds.getValue("player.scrubTooltip")
            val bar = probe.bounds.getValue("player.scrub")
            assertTrue(bubble.top <= shown.top && shown.bottom < bubble.bottom, "$formFactor: the frame $shown inside its bubble $bubble")
            assertTrue(bubble.bottom <= bar.top, "$formFactor: the bubble $bubble above the bar $bar")
        }
    }
}

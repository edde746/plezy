package com.edde746.plezy.ui.player

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.model.FormFactor
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** How far the subtitles rise over the bottom controls. */
@OptIn(ExperimentalTestApi::class)
class SubtitleLiftTest {
    /** A docked menu takes the bottom bar away and the subtitles drop to the video's bottom; they rise again as it closes. */
    @Test
    fun aDockedMenuDropsTheSubtitlesAndClosingItLiftsThemAgain() = runComposeUiTest {
        val heights = mutableListOf<Double>()
        var state by mutableStateOf(testPlayerState())
        player(FormFactor.DESKTOP, onControlsHeightChanged = { heights += it }) { state }
        val barHeight = runOnIdle { heights.last() }
        assertTrue(barHeight > 0.0, "the bar lifts the subtitles")
        state = state.copy(menu = PlayerMenu.CHAPTERS)
        runOnIdle { assertEquals(0.0, heights.last()) }
        state = state.copy(menu = null)
        runOnIdle { assertEquals(barHeight, heights.last()) }
    }
}

package com.edde746.plezy.ui.player

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performMouseInput
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.model.FormFactor
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * A drag on the timeline whose gesture ends before the button comes up: when the timeline stops seeking mid-drag (a
 * watch-together host takes control back), which starts the bar's pointer input over, the scrub commits where it was.
 */
@OptIn(ExperimentalTestApi::class)
class ScrubCancelTest {
    @Test
    fun aTimelineThatStopsSeekingMidDragCommitsTheScrub() = runComposeUiTest {
        val probe = PlayerProbe()
        val commands = mutableListOf<PlayerCommand>()
        var state by mutableStateOf(testPlayerState(episodes = null))
        player(FormFactor.DESKTOP, probe = probe, onCommand = { commands += it }) { state }
        waitForIdle()
        val bar = probe.bounds.getValue("player.scrub")
        onRoot().performMouseInput { moveTo(bar.center); press(); moveTo(bar.center + Offset(bar.width / 4, 0f)) }
        waitForIdle()

        state = state.copy(seekable = false)
        runOnIdle {
            val scrub = commands.filter { it is PlayerCommand.ScrubTo || it == PlayerCommand.CommitScrub || it == PlayerCommand.CancelScrub }
            assertEquals(PlayerCommand.CommitScrub, scrub.last(), "of $scrub")
        }
    }
}

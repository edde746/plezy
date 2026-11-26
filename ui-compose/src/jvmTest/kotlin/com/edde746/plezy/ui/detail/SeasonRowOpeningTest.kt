package com.edde746.plezy.ui.detail

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.width
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onFirst
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.detail.DetailActionsUi
import com.edde746.plezy.presentation.detail.MediaDetailUiState
import com.edde746.plezy.presentation.detail.SeasonTabUi
import com.edde746.plezy.presentation.detail.SectionLoad
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertTrue

/**
 * On the desktop a show's season row that opens on a season further along shows it whole, clear of the row's start
 * fade, and the season before it in the fade: the row says there is more before it.
 */
@OptIn(ExperimentalTestApi::class)
class SeasonRowOpeningTest {
    @Test
    fun `the row opens on the selected season with the one before it showing at the start`() = runComposeUiTest {
        val seasons = (1..15).map { SeasonTabUi("s$it", "Season $it", poster = null, watched = false, progress = null) }
        val state = MediaDetailUiState(
            load = SectionLoad.CONTENT, kind = null, hero = null, actions = DetailActionsUi(), seasons = seasons,
            selectedSeason = 8, seasonsLoad = SectionLoad.CONTENT, episodes = null, cast = emptyList(),
            extras = emptyList(), related = emptyList(), info = emptyList(), ready = true,
        )
        setContent {
            PlezyTheme {
                AdaptiveLayout(FormFactor.DESKTOP) {
                    Box(Modifier.width(600.dp)) { SeasonChips(state, rememberFocusMemory(), {}, {}, nameStart = 24.dp) }
                }
            }
        }
        waitForIdle()
        val selected = onAllNodesWithText("Season 9").onFirst().getBoundsInRoot()
        val before = onAllNodesWithText("Season 8").onFirst().getBoundsInRoot()
        assertTrue(selected.left >= 48.dp, "the selected season clear of the fade: $selected")
        assertTrue(before.right > 0.dp, "the season before it in view: $before")
    }
}

package com.edde746.plezy.ui.seerr

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onLast
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.requestFocus
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.navigationevent.NavigationEventDispatcher
import androidx.navigationevent.NavigationEventDispatcherOwner
import androidx.navigationevent.compose.LocalNavigationEventDispatcherOwner
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.seerr.SeerrRequestBody
import com.edde746.plezy.presentation.seerr.SeerrRequestUiState
import com.edde746.plezy.presentation.seerr.SeerrSeasonRow
import com.edde746.plezy.presentation.seerr.SeerrSeasonSection
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.focus.arrowKeyFocus
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals

/** The Seerr request sheet over states built here. */
@OptIn(ExperimentalTestApi::class)
class SeerrRequestSheetTest {
    private val calls = mutableListOf<String>()
    private val dispatcher = NavigationEventDispatcher()

    /** A movie already available offers nothing to request: the message alone, no Request button under it. */
    @Test
    fun anAvailableMovieShowsNothingToRequest() = runComposeUiTest {
        sheet { state(SeerrRequestBody.NothingToRequest(T.seerr.nothingToRequest)) }
        onNodeWithText(T.seerr.nothingToRequest).assertExists()
        onNodeWithText("Arrival").assertExists()
        // "Request" heads the sheet; no button repeats it.
        onAllNodesWithText(T.seerr.request).assertCountEquals(1)
    }

    /** A requestable movie's form submits; a failed load offers Retry. */
    @Test
    fun theFormSubmitsAndAFailedLoadRetries() = runComposeUiTest {
        var state by mutableStateOf(state(form()))
        sheet { state }
        onAllNodesWithText(T.seerr.request).assertCountEquals(2)
        onAllNodesWithText(T.seerr.request).onLast().assertIsEnabled().performClick()
        runOnIdle { assertEquals(listOf("submit"), calls) }

        state = state(SeerrRequestBody.LoadFailed(T.seerr.requestsLoadFailed, T.common.retry))
        onNodeWithText(T.common.retry).performClick()
        runOnIdle { assertEquals(listOf("submit", "retry"), calls) }
    }

    /**
     * A show's seasons run past the sheet's height: Down from the last requestable season goes straight to Request,
     * which comes into view.
     */
    @Test
    fun downFromTheLastSeasonFocusesRequestInView() = runComposeUiTest {
        val rows = (1..20).map { SeerrSeasonRow(it, "Season $it", "10 episodes", blockedLabel = null, checked = false) }
        sheet { state(form().copy(seasons = SeerrSeasonSection("Seasons", "All seasons", allSelected = false, rows), submitJumpSeason = 20)) }
        onNodeWithText("Season 20").performScrollTo().requestFocus()
        onNodeWithText("Season 20").assertIsFocused()
        onRoot().performKeyInput { pressKey(Key.DirectionDown) }
        onAllNodesWithText(T.seerr.request).onLast().assertIsFocused().assertIsDisplayed()
    }

    /**
     * On TV the form opens on All seasons, the seasons' first row, whichever season can be requested, and the D-pad
     * moves on inside the sheet past an available season to the next that can be.
     */
    @Test
    fun aRemoteStartsOnAllSeasons() = runComposeUiTest {
        val available = SeerrSeasonRow(1, "Season 1", null, blockedLabel = "Available", checked = true)
        val open = (2..3).map { SeerrSeasonRow(it, "Season $it", null, blockedLabel = null, checked = false) }
        val rows = listOf(available) + open
        sheet(FormFactor.TV) { state(form().copy(seasons = SeerrSeasonSection("Seasons", "All seasons", allSelected = false, rows))) }
        onNodeWithText("All seasons").assertIsFocused()
        onRoot().performKeyInput { pressKey(Key.DirectionDown) }
        onNodeWithText("Season 2").assertIsFocused()
        onRoot().performKeyInput { pressKey(Key.DirectionUp) }
        onNodeWithText("All seasons").assertIsFocused()
    }

    /** On TV the form opens at its top: its title and the Seasons heading show over All seasons, focused. */
    @Test
    fun aRemoteOpensTheFormAtItsTop() = runComposeUiTest {
        val available = SeerrSeasonRow(1, "Season 1", "10 episodes", blockedLabel = "Available", checked = true)
        val processing = SeerrSeasonRow(2, "Season 2", "10 episodes", blockedLabel = "Processing", checked = true)
        val open = SeerrSeasonRow(3, "Season 3", "10 episodes", blockedLabel = null, checked = false)
        sheet(FormFactor.TV) {
            state(form().copy(seasons = SeerrSeasonSection("Seasons", "All seasons", allSelected = false, listOf(available, processing, open)), canSubmit = false))
        }
        onNodeWithText("All seasons").assertIsFocused()
        waitForIdle()
        onNodeWithText("Arrival").assertIsDisplayed()
        onNodeWithText("Seasons").assertIsDisplayed()
    }

    private fun state(body: SeerrRequestBody) = SeerrRequestUiState(heading = T.seerr.request, title = "Arrival", body = body)

    private fun form() = SeerrRequestBody.Form(
        seasons = null,
        request4k = null,
        request4kLabel = T.seerr.request4k,
        advanced = null,
        error = null,
        submitting = false,
        canSubmit = true,
        submitLabel = T.seerr.request,
        submitJumpSeason = null,
    )

    private fun ComposeUiTest.sheet(formFactor: FormFactor = FormFactor.HANDHELD, state: () -> SeerrRequestUiState) = setContent {
        val owner = remember {
            object : NavigationEventDispatcherOwner {
                override val navigationEventDispatcher = dispatcher
            }
        }
        CompositionLocalProvider(LocalNavigationEventDispatcherOwner provides owner) {
            PlezyTheme {
                Box(Modifier.size(DpSize(411.dp, 900.dp))) {
                    AdaptiveLayout(formFactor, Modifier.arrowKeyFocus()) {
                        OverlayHostBox { SeerrRequestContent(state(), intents(), onDismiss = { calls += "dismiss" }) }
                    }
                }
            }
        }
    }

    private fun intents() = SeerrRequestIntents(
        retry = { calls += "retry" },
        setSeasonSelected = { season, selected -> calls += "season:$season:$selected" },
        setAllSeasons = { calls += "all:$it" },
        set4k = { calls += "4k:$it" },
        select = { kind, id -> calls += "select:$kind:$id" },
        toggleTagsExpanded = { calls += "tags" },
        setTagSelected = { id, selected -> calls += "tag:$id:$selected" },
        submit = { calls += "submit" },
    )
}

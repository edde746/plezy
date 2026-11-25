package com.edde746.plezy.ui.libraries

import androidx.compose.foundation.MutatePriority
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyGridState
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.hasSetTextAction
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.LibraryFilter
import com.edde746.plezy.model.LibraryFilterOperator
import com.edde746.plezy.model.MediaFilter
import com.edde746.plezy.model.MediaFilterUnit
import com.edde746.plezy.ui.TvFrame
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.launch
import kotlin.test.Test
import kotlin.test.assertEquals

/** The number range page's From and To, and the grid's anchor jump after a live refresh. */
@OptIn(ExperimentalTestApi::class)
class LibraryLiveRefreshTest {
    private val duration = MediaFilter("duration", "Duration", unit = MediaFilterUnit.DURATION)

    /** Typed minutes are stored as ms (non-digits dropped), stored ms show back as minutes, and All clears both. */
    @Test
    fun aNumberRangeStoresTypedValuesTimesTheScaleAndShowsThemBackDivided() = runComposeUiTest {
        var staged by mutableStateOf(listOf(LibraryFilter("duration", listOf("1800000"), LibraryFilterOperator.AT_LEAST)))
        setContent { TvFrame { Column { NumberPage(duration, staged) { staged = it } } } }
        onNodeWithText("30").assertExists()
        onAllNodesWithText("min", useUnmergedTree = true).assertCountEquals(2)
        onAllNodes(hasSetTextAction())[1].performTextInput("9a0")
        waitForIdle()
        assertEquals(
            listOf(
                LibraryFilter("duration", listOf("1800000"), LibraryFilterOperator.AT_LEAST),
                LibraryFilter("duration", listOf("5400000"), LibraryFilterOperator.AT_MOST),
            ),
            staged,
        )
        onNodeWithText("90").assertExists()
        onNodeWithText("All").performClick()
        waitForIdle()
        assertEquals(emptyList(), staged)
    }

    private fun grid(jumps: MutableSharedFlow<Int>, onState: (LazyGridState, CoroutineScope) -> Unit): @Composable () -> Unit = {
        val state = rememberLazyGridState()
        val scope = rememberCoroutineScope()
        onState(state, scope)
        LaunchedEffect(state) { state.followAnchorJumps(jumps) }
        Box(Modifier.size(200.dp, 300.dp)) {
            LazyVerticalGrid(GridCells.Fixed(1), state = state) {
                items(500) { Box(Modifier.height(50.dp)) }
            }
        }
    }

    /** With no scroll in between, the anchor's new index is jumped to on the next frame. */
    @Test
    fun theAnchorJumpLandsOnTheNextFrame() = runComposeUiTest {
        val jumps = MutableSharedFlow<Int>(extraBufferCapacity = 8)
        lateinit var state: LazyGridState
        mainClock.autoAdvance = false
        setContent(grid(jumps) { s, _ -> state = s })
        mainClock.advanceTimeByFrame()
        waitForIdle()
        runOnIdle { jumps.tryEmit(120) }
        waitForIdle()
        mainClock.advanceTimeByFrame()
        waitForIdle()
        mainClock.advanceTimeByFrame()
        waitForIdle()
        assertEquals(120, state.firstVisibleItemIndex)
    }

    /** A drag started between the refresh and the frame wins: the jump is dropped, even once the drag ends. */
    @Test
    fun aDragStartedBeforeTheFrameDropsTheAnchorJump() = runComposeUiTest {
        val jumps = MutableSharedFlow<Int>(extraBufferCapacity = 8)
        lateinit var state: LazyGridState
        lateinit var scope: CoroutineScope
        mainClock.autoAdvance = false
        setContent(grid(jumps) { s, c -> state = s; scope = c })
        mainClock.advanceTimeByFrame()
        waitForIdle()
        runOnIdle { jumps.tryEmit(120) }
        waitForIdle()
        val release = CompletableDeferred<Unit>()
        runOnIdle { scope.launch { state.scroll(MutatePriority.UserInput) { release.await() } } }
        waitForIdle()
        mainClock.advanceTimeByFrame()
        waitForIdle()
        release.complete(Unit)
        repeat(3) {
            mainClock.advanceTimeByFrame()
            waitForIdle()
        }
        assertEquals(0, state.firstVisibleItemIndex)
    }
}

package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyGridState
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performScrollToIndex
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlin.test.Test
import kotlin.test.assertEquals

/** A top-level screen asked back to its top (its destination reselected): every list under its header row goes there. */
@OptIn(ExperimentalTestApi::class)
class HeaderScrollToTopTest {
    @Test
    fun theListsUnderTheHeaderGoBackToTheirTopsWhenAsked() = runComposeUiTest {
        val toTop = MutableSharedFlow<Unit>(extraBufferCapacity = 1)
        lateinit var list: LazyListState
        lateinit var grid: LazyGridState
        setContent {
            PlezyTheme {
                Box(Modifier.size(400.dp, 800.dp)) {
                    AdaptiveLayout(FormFactor.HANDHELD) {
                        CompositionLocalProvider(LocalScrollToTop provides toTop) {
                            HeaderScaffold(filters = { _, _ -> }) {
                                Box {
                                    list = rememberHeaderListState()
                                    LazyColumn(Modifier.size(400.dp, 300.dp).testTag("list"), list) {
                                        items(60) { Box(Modifier.fillMaxWidth().height(100.dp)) }
                                    }
                                    grid = rememberHeaderGridState()
                                    LazyVerticalGrid(GridCells.Fixed(2), Modifier.size(400.dp, 300.dp).testTag("grid"), grid) {
                                        items(120) { Box(Modifier.fillMaxWidth().height(100.dp)) }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        onNodeWithTag("list").performScrollToIndex(40)
        onNodeWithTag("grid").performScrollToIndex(90)
        waitForIdle()
        assertEquals(40, list.firstVisibleItemIndex)
        assertEquals(90, grid.firstVisibleItemIndex)

        toTop.tryEmit(Unit)
        waitForIdle()
        assertEquals(0 to 0, list.firstVisibleItemIndex to list.firstVisibleItemScrollOffset, "the list's top")
        assertEquals(0 to 0, grid.firstVisibleItemIndex to grid.firstVisibleItemScrollOffset, "the grid's top")
    }
}

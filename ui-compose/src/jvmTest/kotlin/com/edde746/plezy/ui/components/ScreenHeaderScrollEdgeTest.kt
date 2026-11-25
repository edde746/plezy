package com.edde746.plezy.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.ui.colourAt
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * A pushed screen's heading over a list: at the list's top the rows show right under the heading; once the list has
 * scrolled, the page's background lies behind the heading and fades past its foot, so the rows scrolling up under it
 * fade away instead of being cut at an invisible line.
 */
@OptIn(ExperimentalTestApi::class)
class ScreenHeaderScrollEdgeTest {
    @Test
    fun theHeadingsScrollEdgeShowsOnlyOnceTheListHasScrolled() = runComposeUiTest {
        val list = LazyListState()
        setContent {
            PlezyTheme {
                Column(Modifier.size(300.dp, 500.dp)) {
                    ScreenHeader("Album", Modifier.testTag("header"), onBack = {}, scrolled = { list.canScrollBackward })
                    LazyColumn(state = list) {
                        items(40) { Box(Modifier.fillMaxWidth().height(40.dp).background(Color.Red)) }
                    }
                }
            }
        }
        val foot = onNodeWithTag("header").getBoundsInRoot().bottom.value.toInt()
        assertEquals("red", colourAt(150, foot + 4), "at the list's top, the first row under the heading")
        runOnIdle { list.dispatchRawDelta(400f) }
        waitForIdle()
        assertEquals("none", colourAt(150, foot + 4), "scrolled, the rows under the heading's foot fade into the page")
    }
}

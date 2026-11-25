package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.Text
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.toPixelMap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.click
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performMouseInput
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.swipeDown
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * A list's pull to refresh: a touch pulling down at its top reloads; a mouse wheel scrolling up past the top draws no
 * indicator in (a wheel never lets one go, so it would stay over the content).
 */
@OptIn(ExperimentalTestApi::class)
class TouchPullToRefreshTest {
    private var refreshes = 0

    @Test
    fun aTouchPullAtTheTopRefreshes() = runComposeUiTest {
        list()
        // Out of keyboard mode, where the test starts.
        onNodeWithTag("list").performMouseInput { click(center) }
        onNodeWithTag("list").performTouchInput { swipeDown(startY = top + 10f, endY = bottom) }
        waitForIdle()
        assertEquals(1, refreshes)
    }

    @Test
    fun aMouseWheelPastTheTopLeavesNoIndicatorOverTheList() = runComposeUiTest {
        list()
        onNodeWithTag("list").performMouseInput { click(center) }
        onNodeWithTag("list").performMouseInput { repeat(3) { scroll(120f) } }
        waitForIdle()
        mainClock.advanceTimeBy(1000)
        // Back up, past the top.
        onNodeWithTag("list").performMouseInput { repeat(12) { scroll(-120f) } }
        waitForIdle()
        mainClock.advanceTimeBy(2000)
        // The indicator comes down at the list's top centre; the rows' text stays at its start.
        val image = onRoot().captureToImage().toPixelMap()
        val empty = image[image.width - 1, image.height - 1]
        val drawn = (image.width / 2 - 30..image.width / 2 + 30).flatMap { x -> (0..image.height / 4).map { y -> image[x, y] } }
        assertTrue(drawn.all { it == empty }, "nothing is drawn over the list's top centre")
        assertEquals(0, refreshes)
    }

    private fun ComposeUiTest.list() = setContent {
        PlezyTheme {
            TouchPullToRefresh(refreshing = false, onRefresh = { refreshes++ }, modifier = Modifier.size(400.dp, 600.dp)) {
                LazyColumn(Modifier.testTag("list")) {
                    items(50) { Text("Row $it", Modifier.height(40.dp)) }
                }
            }
        }
    }
}

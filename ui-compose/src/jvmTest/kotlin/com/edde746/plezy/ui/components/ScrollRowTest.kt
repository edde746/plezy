package com.edde746.plezy.ui.components

import androidx.compose.foundation.ScrollState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.verticalScroll
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toPixelMap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.click
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performMouseInput
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.math.roundToInt
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * A row on the desktop as a mouse uses it: its edges fade only where more of it lies beyond them, its buttons page it
 * and hide at its ends, a drag scrolls it without opening the card under the press while a click opens it, and the
 * wheel scrolls it while it can move, the page once it can't or while the wheel is already scrolling the page.
 */
@OptIn(ExperimentalTestApi::class)
class ScrollRowTest {
    private val state = LazyListState()
    private val page = ScrollState(0)
    private val opened = mutableListOf<Int>()

    /** Twenty white cards, 100 dp wide, edge to edge in a 600 dp row over black, under a strip of page above. */
    private fun ComposeUiTest.row() = setContent {
        PlezyTheme {
            AdaptiveLayout(FormFactor.DESKTOP) {
                Column(Modifier.size(600.dp, 400.dp).background(Color.Black).verticalScroll(page).testTag("page")) {
                    Box(Modifier.size(600.dp, 160.dp).testTag("above"))
                    ScrollRow(Modifier.width(600.dp).testTag("row"), state) {
                        items((0 until CARDS).toList()) { card ->
                            Box(Modifier.size(100.dp, 120.dp).background(Color.White).clickable { opened += card })
                        }
                    }
                    Box(Modifier.width(600.dp).height(600.dp).fillMaxHeight())
                }
            }
        }
    }

    /** How bright the row is at [fraction] across it, halfway down: 1 a white card in full, less where it fades. */
    private fun ComposeUiTest.brightness(fraction: Float): Float {
        waitForIdle()
        val bounds = onNodeWithTag("row").getBoundsInRoot()
        val pixels = onRoot().captureToImage().toPixelMap()
        return with(density) {
            val x = (bounds.left.toPx() + ((bounds.right - bounds.left).toPx() - 1f) * fraction).roundToInt()
            pixels[x.coerceIn(0, pixels.width - 1), ((bounds.top + bounds.bottom) / 2).toPx().roundToInt()].red
        }
    }

    private fun ComposeUiTest.hover() {
        onNodeWithTag("row").performMouseInput { moveTo(center) }
        mainClock.advanceTimeBy(500)
        waitForIdle()
    }

    @Test
    fun `edges fade only where more of the row lies beyond them`() = runComposeUiTest {
        row()
        assertTrue(brightness(0f) > 0.99f, "the start, where the row begins")
        assertTrue(brightness(1f) < 0.1f, "the end, with cards past it")
        runOnIdle { state.requestScrollToItem(8) }
        assertTrue(brightness(0f) < 0.1f, "the start, scrolled along")
        assertTrue(brightness(1f) < 0.1f, "the end, scrolled along")
        runOnIdle { state.requestScrollToItem(CARDS - 1) }
        assertTrue(brightness(0f) < 0.1f, "the start, at the row's end")
        assertTrue(brightness(1f) > 0.99f, "the end, where the row ends")
    }

    @Test
    fun `buttons page the row and hide at its ends`() = runComposeUiTest {
        row()
        onNodeWithContentDescription(T.accessibility.scrollForward).assertDoesNotExist()
        hover()
        onNodeWithContentDescription(T.accessibility.scrollBack).assertDoesNotExist()
        onNodeWithContentDescription(T.accessibility.scrollForward).performMouseInput { click(center) }
        waitForIdle()
        // A page is 80 % of the row: 480 dp, four cards and four fifths.
        assertEquals(4, state.firstVisibleItemIndex)
        onNodeWithContentDescription(T.accessibility.scrollBack).performMouseInput { click(center) }
        waitForIdle()
        assertEquals(0 to 0, state.firstVisibleItemIndex to state.firstVisibleItemScrollOffset)
        onNodeWithContentDescription(T.accessibility.scrollBack).assertDoesNotExist()
        repeat(3) {
            onNodeWithContentDescription(T.accessibility.scrollForward).performMouseInput { click(center) }
            waitForIdle()
        }
        assertTrue(!state.canScrollForward)
        onNodeWithContentDescription(T.accessibility.scrollForward).assertDoesNotExist()
        onNodeWithContentDescription(T.accessibility.scrollBack).assertExists()
        assertEquals(emptyList(), opened)
    }

    @Test
    fun `a mouse drag scrolls the row without opening the card`() = runComposeUiTest {
        row()
        onNodeWithTag("row").performMouseInput {
            moveTo(Offset(450.dp.toPx(), centerY))
            press()
            repeat(10) { moveBy(Offset(-30.dp.toPx(), 0f)) }
            release()
        }
        waitForIdle()
        assertTrue(state.firstVisibleItemIndex >= 3, "scrolled to ${state.firstVisibleItemIndex}")
        assertEquals(emptyList(), opened)
    }

    @Test
    fun `a click opens the card under it and leaves the row in place`() = runComposeUiTest {
        row()
        onNodeWithTag("row").performMouseInput { click(Offset(250.dp.toPx(), centerY)) }
        waitForIdle()
        assertEquals(listOf(2), opened)
        assertEquals(0 to 0, state.firstVisibleItemIndex to state.firstVisibleItemScrollOffset)
    }

    @Test
    fun `the wheel scrolls the row and then the page at its end`() = runComposeUiTest {
        row()
        hover()
        onNodeWithTag("row").performMouseInput { scroll(3f) }
        waitForIdle()
        assertTrue(state.firstVisibleItemIndex > 0, "the row scrolled")
        assertEquals(0, page.value, "the page stayed")
        onNodeWithTag("row").performMouseInput { scroll(-3f) }
        waitForIdle()
        assertEquals(0 to 0, state.firstVisibleItemIndex to state.firstVisibleItemScrollOffset, "the row back at its start")
        runOnIdle { state.requestScrollToItem(CARDS - 1) }
        waitForIdle()
        onNodeWithTag("row").performMouseInput { scroll(3f) }
        waitForIdle()
        assertTrue(page.value > 0, "the page scrolled past the row's end")
    }

    @Test
    fun `the wheel scrolling the page goes on over a row it brings under the pointer`() = runComposeUiTest {
        row()
        onNodeWithTag("above").performMouseInput { moveTo(center) }
        mainClock.advanceTimeBy(500)
        onNodeWithTag("page").performMouseInput { scroll(1f) }
        waitForIdle()
        val before = page.value
        assertTrue(before > 0, "the page scrolled")
        onNodeWithTag("row").performMouseInput {
            moveTo(center)
            scroll(1f)
        }
        waitForIdle()
        assertTrue(page.value > before, "the page went on")
        assertEquals(0 to 0, state.firstVisibleItemIndex to state.firstVisibleItemScrollOffset, "the row stayed")
    }

    private companion object {
        const val CARDS = 20
    }
}

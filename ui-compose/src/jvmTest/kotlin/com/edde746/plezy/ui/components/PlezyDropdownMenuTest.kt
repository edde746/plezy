package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.v2.runSkikoComposeUiTest
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.probe.LayoutProbe
import com.edde746.plezy.ui.probe.LocalLayoutProbe
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * Where a [PlezyDropdownMenu] opens against the element it belongs to, in an 800 × 1000 px window (2 px per dp): below
 * the anchor where it fits there 48 dp clear of the window's edges, above it where it doesn't, and inside the window.
 */
@OptIn(ExperimentalTestApi::class)
class PlezyDropdownMenuTest {
    /** The harness names' bounds (window pixels), as the layout probes report them. */
    private val bounds = HashMap<String, Rect>()

    private val probe = object : LayoutProbe {
        override fun place(name: String, bounds: Rect?) {
            if (bounds != null) this@PlezyDropdownMenuTest.bounds[name] = bounds else this@PlezyDropdownMenuTest.bounds.remove(name)
        }

        override fun focus(name: String, focused: Boolean) = Unit
    }

    /** The anchor's top in the window; it is a full-width row ([wide]) or a 40 dp button at the window's end. */
    private var anchorTop by mutableStateOf(0.dp)
    private var wide by mutableStateOf(true)
    private var entries by mutableStateOf(3)
    private var open by mutableStateOf(false)

    @Test
    fun aRowsMenuOpensDownFromTheRowsTopWhileItFitsAndUpFromItsBottomOnceItDoesnt() = window {
        val height = openAt(200f).height
        val lowest = Window - Margin - height
        val below = openAt(lowest)
        assertEquals(lowest, below.top, 1f, "a menu that fits below its row's top doesn't open from there: $below")
        assertEquals(Window - Margin, below.bottom, 1f)
        val above = openAt(lowest + 2f)
        assertEquals(lowest + 2f + Row, above.bottom, 1f, "a menu that doesn't fit below its row's top doesn't end at the row's bottom: $above")
    }

    @Test
    fun aButtonsMenuOpensBelowTheButtonWhileItFitsAndAboveItOnceItDoesnt() = window {
        wide = false
        entries = 2
        val height = openAt(200f).height
        val lowest = Window - Margin - height - Button
        val below = openAt(lowest)
        assertEquals(lowest + Button, below.top, 1f, "a menu that fits below its button doesn't open under it: $below")
        val above = openAt(lowest + 2f)
        assertEquals(lowest + 2f, above.bottom, 1f, "a menu that doesn't fit below its button doesn't end over it: $above")
    }

    @Test
    fun aMenuTallerThanTheWindowStaysInsideIt() = window {
        entries = 40
        for (top in listOf(0f, 400f, Window - Row)) {
            val menu = openAt(top)
            assertTrue(menu.top >= 0f && menu.bottom <= Window, "the menu from a row at $top runs off the window: $menu")
        }
    }

    /** Opens the menu with its anchor's top [top] px down the window and returns the menu's bounds, then closes it. */
    private fun ComposeUiTest.openAt(top: Float): Rect {
        anchorTop = (top / 2).dp
        waitForIdle()
        open = true
        waitForIdle()
        val menu = bounds.getValue("menu")
        assertEquals(top, bounds.getValue("anchor").top, 1f)
        open = false
        waitForIdle()
        return menu
    }

    private fun window(block: ComposeUiTest.() -> Unit) = runSkikoComposeUiTest(size = Size(800f, Window), density = Density(2f)) {
        setContent {
            CompositionLocalProvider(LocalLayoutProbe provides probe) {
                PlezyTheme {
                    AdaptiveLayout(FormFactor.DESKTOP) {
                        Box(Modifier.fillMaxSize()) {
                            val size = if (wide) Modifier.fillMaxWidth().height(dp(Row)) else Modifier.size(dp(Button))
                            Box(Modifier.align(Alignment.TopEnd).padding(top = anchorTop).then(size).layoutProbe("anchor", reportsFocus = false)) {
                                PlezyDropdownMenu(open, onDismiss = { open = false }, Modifier.layoutProbe("menu", reportsFocus = false)) {
                                    repeat(entries) { PlezyMenuItem("Entry $it", onClick = {}) }
                                }
                            }
                        }
                    }
                }
            }
        }
        block()
    }

    private fun dp(px: Float): Dp = (px / 2).dp

    private companion object {
        const val Window = 1000f
        const val Margin = 96f
        const val Row = 112f
        const val Button = 80f
    }
}

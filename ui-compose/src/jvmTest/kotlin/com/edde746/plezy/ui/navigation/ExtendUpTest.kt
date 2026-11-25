package com.edde746.plezy.ui.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.v2.runSkikoComposeUiTest
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.components.PlezyDropdownMenu
import com.edde746.plezy.ui.components.PlezyMenuItem
import com.edde746.plezy.ui.probe.LayoutProbe
import com.edde746.plezy.ui.probe.LocalLayoutProbe
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * A screen under the status bar ([extendUp]) and the menus opened on it.
 *
 * This is also the smallest repro of the Compose bug [extendUp] works around (Compose Multiplatform 1.12.1, androidx
 * compose.ui 1.12.1 on Android): when a recomposition removes the outermost layout modifier of a node's chain (with no
 * layout modifier inserted in the same update), `positionInWindow` of everything under that node keeps the offset the
 * removed modifier gave, while `boundsInWindow` is right; popups anchor at `positionInWindow`. A layout modifier removed
 * behind another one, or added, is fine. After a Compose upgrade, make [extendUp] return `this` for 0 again and run this
 * test: if it passes, the workaround can go.
 */
@OptIn(ExperimentalTestApi::class)
class ExtendUpTest {
    /** The harness names' bounds (window pixels), as the layout probes report them. */
    private val bounds = HashMap<String, Rect>()

    private val probe = object : LayoutProbe {
        override fun place(name: String, bounds: Rect?) {
            if (bounds != null) this@ExtendUpTest.bounds[name] = bounds else this@ExtendUpTest.bounds.remove(name)
        }

        override fun focus(name: String, focused: Boolean) = Unit
    }

    /**
     * A phone's top-level screen reaches up under the status bar; a pushed one doesn't (NavigationScaffold's content
     * box, where [extendUp] is the outermost layout modifier). A menu opened on the pushed screen opens at its row, not
     * the status bar's height above it.
     */
    @Test
    fun aMenuOpensAtItsRowOnceTheScreenStopsReachingUp() = runSkikoComposeUiTest(size = Size(800f, 1000f), density = Density(2f)) {
        var statusBar by mutableStateOf(24.dp)
        var open by mutableStateOf(false)
        setContent {
            CompositionLocalProvider(LocalLayoutProbe provides probe) {
                PlezyTheme {
                    AdaptiveLayout(FormFactor.DESKTOP) {
                        Box(Modifier.extendUp(statusBar)) {
                            Box(Modifier.padding(top = 150.dp).fillMaxWidth().height(56.dp).layoutProbe("row", reportsFocus = false)) {
                                PlezyDropdownMenu(open, onDismiss = { open = false }, Modifier.layoutProbe("menu", reportsFocus = false)) {
                                    repeat(3) { PlezyMenuItem("Entry $it", onClick = {}) }
                                }
                            }
                        }
                    }
                }
            }
        }
        waitForIdle()
        statusBar = 0.dp
        waitForIdle()
        open = true
        waitForIdle()
        val row = bounds.getValue("row")
        val menu = bounds.getValue("menu")
        assertEquals(300f, row.top, 1f)
        assertEquals(row.top, menu.top, 1f, "the menu doesn't open at its row: row $row, menu $menu")
    }
}

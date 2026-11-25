package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Icon
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.DpRect
import androidx.compose.ui.unit.dp
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertTrue

/**
 * A row's value sits beside its title only while the title keeps one line beside it; else the value leads the subtitle.
 * A pattern's code wraps in its own column, what trails it staying beside it.
 */
@OptIn(ExperimentalTestApi::class)
class GroupRowValueTest {
    private fun ComposeUiTest.row(width: Dp, title: String, value: String) = setContent {
        PlezyTheme {
            Box(Modifier.width(width).testTag("row")) {
                GroupRow(title, onClick = {}, value = value, icon = PlezyIcons.Settings, trailing = { Chevron() })
            }
        }
    }

    private fun ComposeUiTest.bounds(text: String): DpRect = onNodeWithText(text, useUnmergedTree = true).getBoundsInRoot()

    @Test
    fun aValueBesideATitleThatWouldWrapMovesUnderIt() = runComposeUiTest {
        // The Pixel's settings row (379 dp).
        row(379.dp, "Default Quality on Cellular", "Use Default")
        val title = bounds("Default Quality on Cellular")
        val value = bounds("Use Default")
        assertTrue(value.top >= title.bottom, "Use Default at $value, beside the title at $title")
        assertTrue(value.left <= title.left + 1.dp, "Use Default at $value doesn't lead the subtitle under $title")
    }

    @Test
    fun aValueThatLeavesTheTitleOneLineStaysBesideIt() = runComposeUiTest {
        row(600.dp, "Default Quality on Cellular", "Use Default")
        val title = bounds("Default Quality on Cellular")
        val value = bounds("Use Default")
        assertTrue(value.left > title.right, "Use Default at $value, not beside the title at $title")
    }

    @Test
    fun windowsWideDownloadLocationMovesItsValueUnderTheTitleInANarrowColumn() = runComposeUiTest {
        // Windows' wide settings column (331 dp).
        row(331.dp, "Download location", "App storage")
        val title = bounds("Download location")
        assertTrue(bounds("App storage").top >= title.bottom, "App storage beside Download location at $title")
    }

    @Test
    fun aPatternWrapsInItsColumnAndItsChevronStaysBesideItCentred() = runComposeUiTest {
        val regex = "(?i)^(intro|opening|recap|previously(?:\\s+on)?|cold\\s*open)$"
        setContent {
            PlezyTheme {
                Box(Modifier.width(300.dp)) {
                    GroupRow(
                        "Credits Marker Pattern", onClick = {}, modifier = Modifier.testTag("row"), subtitle = regex, icon = PlezyIcons.Settings,
                        subtitleMonospace = true, trailing = { Icon(PlezyIcons.ChevronRight, contentDescription = null, Modifier.testTag("chevron")) },
                    )
                }
            }
        }
        val row = onNodeWithTag("row").getBoundsInRoot()
        val chevron = onNodeWithTag("chevron", useUnmergedTree = true).getBoundsInRoot()
        val pattern = onNodeWithText(regex, useUnmergedTree = true).getBoundsInRoot()
        assertTrue(chevron.left >= pattern.right, "the chevron at $chevron under the pattern at $pattern")
        val centre = (row.top + row.bottom) / 2
        val chevronCentre = (chevron.top + chevron.bottom) / 2
        assertTrue((chevronCentre - centre).value in -1f..1f, "the chevron's centre $chevronCentre, the row's $centre")
    }
}

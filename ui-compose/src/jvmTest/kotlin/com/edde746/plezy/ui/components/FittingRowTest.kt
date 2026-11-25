package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** A header's fitted row: the screen's name (its first child) gives way before the controls after it, down to a minimum. */
@OptIn(ExperimentalTestApi::class)
class FittingRowTest {
    @Test
    fun theFirstChildNarrowsWhileTheOthersKeepTheirWidth() = runComposeUiTest {
        setContent {
            FittingRow(Modifier.width(300.dp)) {
                Box(Modifier.height(10.dp).widthIn(min = 260.dp).testTag("name"))
                Box(Modifier.height(10.dp).width(120.dp).testTag("view"))
                Box(Modifier.height(10.dp).width(48.dp).testTag("type"))
            }
        }
        assertEquals(120.dp, width("view"))
        assertEquals(48.dp, width("type"))
        // 300 less the two controls and the two gaps.
        assertEquals(300.dp - 168.dp - FILTER_GAP * 2, width("name"))
    }

    @Test
    fun whereTheOthersDoNotFitBesideItsMinimumTheNameKeepsItAndTheWidestShareTheRest() = runComposeUiTest {
        setContent {
            FittingRow(Modifier.width(220.dp)) {
                Box(Modifier.height(10.dp).widthIn(min = 150.dp).testTag("name"))
                Box(Modifier.height(10.dp).widthIn(min = 150.dp).testTag("view"))
                Box(Modifier.height(10.dp).width(40.dp).testTag("type"))
            }
        }
        assertEquals(NAME_MIN, width("name"))
        assertEquals(40.dp, width("type"))
        assertEquals(220.dp - NAME_MIN - 40.dp - FILTER_GAP * 2, width("view"))
    }

    /**
     * A phone's library header at its narrowest (a foldable's 320 dp cover screen, whose row leaves the chips 248 dp
     * with Shuffle in the ⋮): the menu chips are round icons without the dropdown arrow, and the library chip gives up
     * its icon, never its arrow, before its name, which stays readable.
     */
    @Test
    fun onANarrowPhoneTheLibraryNameStaysReadableBesideRoundIconChips() = runComposeUiTest {
        setContent {
            PlezyTheme {
                Box(Modifier.size(320.dp, 100.dp)) {
                    AdaptiveLayout(FormFactor.HANDHELD) {
                        FittingRow(Modifier.width(248.dp)) {
                            PlezyChip("Codec Samples", selected = false, onClick = {}, leadingIcon = PlezyIcons.Movie, dropdown = true)
                            for (each in listOf("view", "options", "type")) {
                                MenuChip(FilterChip(each, each), emptyList(), onPick = {}, probe = each, modifier = Modifier.testTag(each), leadingIcon = PlezyIcons.Apps, iconOnly = true)
                            }
                        }
                    }
                }
            }
        }
        for (each in listOf("view", "options", "type")) {
            val chip = onNodeWithTag(each).getBoundsInRoot()
            assertEquals(chip.bottom - chip.top, chip.right - chip.left, "the $each chip isn't round")
        }
        val name = size(onNodeWithText("Codec Samples", useUnmergedTree = true))
        assertTrue(name >= 56.dp, "the library's name has $name of the row")
    }

    private fun ComposeUiTest.width(tag: String): Dp = size(onNodeWithTag(tag))

    private fun size(node: SemanticsNodeInteraction): Dp = node.getBoundsInRoot().let { it.right - it.left }
}

package com.edde746.plezy.ui.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assertHeightIsEqualTo
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onAllNodesWithContentDescription
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performSemanticsAction
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.navigation.NavigationTabs
import com.edde746.plezy.presentation.navigation.TopLevelDestination
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.interfaceLanguages
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.math.abs
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

@OptIn(ExperimentalTestApi::class)
class NavigationBarLabelsTest {
    /**
     * Show Navigation Bar Labels off: the phone's bar shows its icons alone (each named for accessibility) in a 56 dp
     * bar, which gives the screen the height the labels took; on again, the labels come back.
     */
    @Test
    fun thePhonesBarHidesItsLabelsWhenTheSettingIsOff() = runComposeUiTest {
        var labels by mutableStateOf(false)
        val home = TopLevelDestination.HOME.label
        setContent {
            PlezyTheme {
                Box(Modifier.size(400.dp, 700.dp)) {
                    AdaptiveLayout(FormFactor.HANDHELD) {
                        NavigationScaffold(TopLevelDestination.entries, TopLevelDestination.HOME, onSelect = {}, showNavigation = true, barLabels = labels) {
                            Box(Modifier.fillMaxSize().testTag("screen"))
                        }
                    }
                }
            }
        }
        assertEquals(0, onAllNodesWithText(home).fetchSemanticsNodes().size, "a label shows with the setting off")
        assertEquals(1, onAllNodesWithContentDescription(home).fetchSemanticsNodes().size, "the icon alone has no name")
        // The window less the 1 dp hairline and the 56 dp bar.
        onNodeWithTag("screen").assertHeightIsEqualTo(643.dp)

        labels = true
        waitForIdle()
        assertEquals(1, onAllNodesWithText(home).fetchSemanticsNodes().size, "the label didn't come back")
        // The labelled bar is 64 dp high.
        onNodeWithTag("screen").assertHeightIsEqualTo(635.dp)
    }

    /**
     * A phone's rail (landscape) follows the setting as the bar does, and shows its labels only while every destination
     * fits with its label (72 dp each): 5 fit in 700 dp, not in 340 dp. Icons alone keep their names.
     */
    @Test
    fun aPhonesRailShowsLabelsOnlyWhenTheSettingIsOnAndTheyFit() {
        val home = TopLevelDestination.HOME.label
        for ((height, labels, shown) in listOf(Triple(700, true, true), Triple(700, false, false), Triple(340, true, false))) runComposeUiTest {
            setContent {
                PlezyTheme {
                    Box(Modifier.size(914.dp, height.dp)) {
                        AdaptiveLayout(FormFactor.HANDHELD) {
                            NavigationScaffold(TopLevelDestination.entries, TopLevelDestination.HOME, onSelect = {}, showNavigation = true, barLabels = labels) {
                                Box(Modifier.fillMaxSize())
                            }
                        }
                    }
                }
            }
            val case = "$height dp, setting ${if (labels) "on" else "off"}"
            assertEquals(if (shown) 1 else 0, onAllNodesWithText(home).fetchSemanticsNodes().size, "$case: labels shown $shown expected")
            assertEquals(if (shown) 0 else 1, onAllNodesWithContentDescription(home).fetchSemanticsNodes().size, "$case: the icon alone has no name")
        }
    }

    /**
     * In every interface language each destination's label shows whole on one line, a long one ("Einstellungen") at a
     * smaller size: in a phone's bar upright (411 dp wide) and in its rail held sideways (411 dp tall).
     */
    @Test
    fun everyLanguagesLabelsShowWholeInAPhonesBarAndRail() {
        val cut = mutableListOf<String>()
        try {
            for (language in interfaceLanguages) {
                T.locale = language
                for ((width, height) in listOf(411 to 891, 891 to 411)) runComposeUiTest {
                    setContent {
                        PlezyTheme {
                            Box(Modifier.size(width.dp, height.dp)) {
                                AdaptiveLayout(FormFactor.HANDHELD) {
                                    NavigationScaffold(TopLevelDestination.entries, TopLevelDestination.HOME, onSelect = {}, showNavigation = true, barLabels = true) {
                                        Box(Modifier.fillMaxSize())
                                    }
                                }
                            }
                        }
                    }
                    // A phone either way up leaves Downloads to Home.
                    for (destination in NavigationTabs.bar(TopLevelDestination.entries)) {
                        val layouts = mutableListOf<TextLayoutResult>()
                        onNode(hasText(destination.label) and SemanticsMatcher.keyIsDefined(SemanticsActions.GetTextLayoutResult), useUnmergedTree = true)
                            .performSemanticsAction(SemanticsActions.GetTextLayoutResult) { it(layouts) }
                        val layout = layouts.single()
                        // A word too long for its box breaks onto a second line that one line's height clips.
                        if (layout.didOverflowHeight || layout.isLineEllipsized(0)) cut += "$language ${width}x$height dp: \"${destination.label}\" is cut"
                    }
                }
            }
        } finally {
            T.locale = "en"
        }
        assertTrue(cut.isEmpty(), cut.joinToString("\n"))
    }

    /**
     * At the largest font scale (2) a label too long for its item even at the smallest size ("Einstellungen" in a
     * 411 dp phone's bar) ends in "…" inside its box, never cut off mid-letter.
     */
    @Test
    fun aLabelTooLongAtItsSmallestSizeEndsInAnEllipsis() {
        T.locale = "de"
        try {
            runComposeUiTest {
                var ellipsis = 0
                bar(fontScale = 2f) { ellipsis = it.measure("…", MaterialTheme.typography.labelMedium.copy(fontSize = NavigationLabelMin)).size.width }
                val label = TopLevelDestination.SETTINGS.label
                val layout = layoutOf(label)
                // The semantics' layout doesn't flag the ellipsis; the letters it shows leave room for it after them, where
                // a clipped line runs to its box's edge.
                val shown = layout.getLineEnd(0, visibleEnd = true)
                val right = layout.getLineRight(0)
                assertTrue(
                    layout.lineCount == 1 && shown < label.length && right + ellipsis <= layout.size.width + 0.5f,
                    "\"$label\": ${layout.lineCount} lines, $shown letters shown, its line to $right px and a $ellipsis px \"…\" in ${layout.size.width}",
                )
            }
        } finally {
            T.locale = "en"
        }
    }

    /**
     * The bar's labels read as one set: one size for all, the one the tightest label needs ("Einstellungen" in German
     * on a 411 dp phone: below full size at font scale 1, the 10 sp floor at 2), not "Start" at full size beside a
     * shrunk "Einstellungen".
     */
    @Test
    fun theBarsLabelsShareOneSize() {
        T.locale = "de"
        val wrong = mutableListOf<String>()
        try {
            for (fontScale in listOf(1f, 2f)) runComposeUiTest {
                // Each label's first letter at 10 sp: its size on screen is that letter's width over this, times 10.
                val reference = HashMap<String, Float>()
                // The bar's labels are Material's labelMedium at full size.
                var full = 0f
                bar(fontScale) { measurer ->
                    full = MaterialTheme.typography.labelMedium.fontSize.value
                    val style = MaterialTheme.typography.labelMedium.copy(fontSize = 10.sp)
                    for (destination in NavigationTabs.bar(TopLevelDestination.entries)) {
                        reference[destination.label] = measurer.measure(destination.label, style).getBoundingBox(0).width
                    }
                }
                val sizes = NavigationTabs.bar(TopLevelDestination.entries).associate { it.label to layoutOf(it.label).getBoundingBox(0).width / reference.getValue(it.label) * 10 }
                val read = sizes.entries.joinToString { (label, size) -> "\"" + label + "\" " + "%.1f".format(size) + " sp" }
                if (sizes.values.max() - sizes.values.min() > 0.3f) wrong += "at font scale $fontScale: $read"
                if (fontScale == 1f && sizes.values.max() > full - 0.3f) wrong += "at font scale 1 the labels keep full size: $read"
                if (fontScale == 2f && sizes.values.any { abs(it - NavigationLabelMin.value) > 0.3f }) wrong += "at font scale 2 the labels aren't at the floor: $read"
            }
        } finally {
            T.locale = "en"
        }
        assertTrue(wrong.isEmpty(), wrong.joinToString("\n"))
    }

    /** Every destination in a 411 dp phone's bar with its labels, at [fontScale]; [measure] gets a text measurer there. */
    private fun ComposeUiTest.bar(fontScale: Float, measure: @Composable (TextMeasurer) -> Unit) = setContent {
        CompositionLocalProvider(LocalDensity provides Density(LocalDensity.current.density, fontScale)) {
            PlezyTheme {
                measure(rememberTextMeasurer())
                Box(Modifier.size(411.dp, 891.dp)) {
                    AdaptiveLayout(FormFactor.HANDHELD) {
                        NavigationScaffold(TopLevelDestination.entries, TopLevelDestination.HOME, onSelect = {}, showNavigation = true, barLabels = true) {
                            Box(Modifier.fillMaxSize())
                        }
                    }
                }
            }
        }
    }

    private fun ComposeUiTest.layoutOf(label: String): TextLayoutResult {
        val layouts = mutableListOf<TextLayoutResult>()
        onNode(hasText(label) and SemanticsMatcher.keyIsDefined(SemanticsActions.GetTextLayoutResult), useUnmergedTree = true)
            .performSemanticsAction(SemanticsActions.GetTextLayoutResult) { it(layouts) }
        return layouts.single()
    }
}

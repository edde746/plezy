package com.edde746.plezy.ui.navigation

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.getUnclippedBoundsInRoot
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.performMouseInput
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.requestFocus
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.DpRect
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.height
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.navigation.NavigationTabs
import com.edde746.plezy.presentation.navigation.TopLevelDestination
import com.edde746.plezy.presentation.probeName
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.focus.LocalScreenFocus
import com.edde746.plezy.ui.focus.RestoreFocus
import com.edde746.plezy.ui.focus.ScreenFocus
import com.edde746.plezy.ui.focus.arrowKeyFocus
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.probe.FocusedProbe
import com.edde746.plezy.ui.probe.LayoutProbe
import com.edde746.plezy.ui.probe.LocalLayoutProbe
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.PlezyTheme
import java.util.concurrent.ConcurrentHashMap
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

@OptIn(ExperimentalTestApi::class)
class NavigationRailTest {
    private val destinations = TopLevelDestination.entries

    /**
     * A phone held upright (412 × 700 dp) gets the bar along the window's foot, every destination but Downloads (Home's
     * shortcut opens it while Libraries shows) named under its icon, side by side.
     */
    @Test
    fun aCompactWindowGetsTheBarAlongItsFoot() = runComposeUiTest {
        rail(FormFactor.HANDHELD, 412, 700)
        val items = (destinations - TopLevelDestination.DOWNLOADS).map { shown(hasText(it.label)) }
        for (item in items) assertTrue(item.bottom <= 700.dp && item.top >= 620.dp, "a destination at ${item.top}–${item.bottom} isn't in the bar")
        for ((a, b) in items.zipWithNext()) assertTrue(a.right <= b.left, "destinations overlap: $a and $b")
        onAllNodes(named(TopLevelDestination.DOWNLOADS.label)).assertCountEquals(0)
    }

    /** The desktop's rail and the TV column offer Downloads, between Libraries and Search. */
    @Test
    fun theDesktopRailAndTheTvColumnOfferDownloadsAfterLibraries() {
        for ((formFactor, size) in listOf(FormFactor.DESKTOP to (1280 to 800), FormFactor.TV to (960 to 540))) runComposeUiTest {
            val placed = ConcurrentHashMap<String, Rect>()
            val probe = LayoutProbe { name, bounds -> if (bounds == null) placed.remove(name) else placed[name] = bounds }
            setContent {
                CompositionLocalProvider(LocalLayoutProbe provides probe) {
                    PlezyTheme {
                        Box(Modifier.size(size.first.dp, size.second.dp)) {
                            AdaptiveLayout(formFactor) {
                                NavigationScaffold(destinations, TopLevelDestination.HOME, onSelect = {}, showNavigation = true) { Box(Modifier.fillMaxSize()) }
                            }
                        }
                    }
                }
            }
            waitForIdle()
            val top = { destination: TopLevelDestination -> checkNotNull(placed["nav.${destination.probeName}"]) { "$formFactor: no ${destination.label} item" }.top }
            assertTrue(top(TopLevelDestination.LIBRARIES) < top(TopLevelDestination.DOWNLOADS), "$formFactor: Downloads isn't under Libraries")
            assertTrue(top(TopLevelDestination.DOWNLOADS) < top(TopLevelDestination.SEARCH), "$formFactor: Downloads isn't above Search")
        }
    }

    /**
     * A phone in landscape (914 × 360 dp) and a tablet held upright (800 × 1280 dp) both get the 80 dp rail: every
     * destination it shows named, one under another, inside the window, and the screen beside the rail. The tablet shows
     * Downloads; the phone, as in its bar, leaves it to Home's shortcut.
     */
    @Test
    fun aWindowFromSixHundredDpGetsTheRailInEitherOrientation() {
        for ((width, height) in listOf(914 to 360, 800 to 1280)) runComposeUiTest {
            rail(FormFactor.HANDHELD, width, height)
            val phone = height < 600
            onAllNodes(named(TopLevelDestination.DOWNLOADS.label)).assertCountEquals(if (phone) 0 else 1)
            val items = (if (phone) NavigationTabs.bar(destinations) else destinations).map { shown(named(it.label)) }
            for (item in items) {
                assertTrue(item.top >= 0.dp && item.bottom <= height.dp, "$width × $height: a destination at ${item.top}–${item.bottom} is cut off")
                assertTrue(item.right <= 80.dp, "$width × $height: a destination reaches ${item.right}, past the rail")
            }
            for ((a, b) in items.zipWithNext()) assertTrue(a.bottom <= b.top, "$width × $height: destinations overlap: $a and $b")
            assertEquals(80f, shown(hasTestTag("content")).left.value, 0.5f, "$width × $height: the screen doesn't start beside the rail")
        }
    }

    /** The desktop's rail never opens: its destinations stay inside its 80 dp under the pointer. */
    @Test
    fun theDesktopRailNeverOpensUnderThePointer() = runComposeUiTest {
        rail(FormFactor.DESKTOP, 1280, 800)
        onNodeWithText(destinations.first().label).performMouseInput { moveTo(center) }
        waitForIdle()
        for (destination in destinations) assertTrue(shown(hasText(destination.label)).right <= 80.dp, "${destination.label} reaches past the rail")
    }

    /**
     * A fold's inner screen in landscape with the keyboard up leaves a short window (914 × 300 dp): the rail drops the
     * profile's avatar and packs its items, so every destination stays inside the window; without the keyboard the
     * avatar is back.
     */
    @Test
    fun withTheKeyboardUpTheRailKeepsItsDestinationsAndDropsItsFooter() {
        for (keyboard in listOf(true, false)) runComposeUiTest {
            setContent {
                CompositionLocalProvider(LocalKeyboardHeight provides { if (keyboard) 600 else 0 }) {
                    PlezyTheme {
                        Box(Modifier.size(914.dp, 300.dp)) {
                            AdaptiveLayout(FormFactor.HANDHELD) {
                                NavigationScaffold(
                                    destinations = destinations,
                                    selected = TopLevelDestination.HOME,
                                    onSelect = {},
                                    showNavigation = true,
                                    footer = { Box(Modifier.size(48.dp).testTag("footer")) },
                                ) {
                                    Box(Modifier.fillMaxSize().testTag("content"))
                                }
                            }
                        }
                    }
                }
            }
            if (keyboard) {
                onAllNodes(hasTestTag("footer")).assertCountEquals(0)
                for (destination in destinations) {
                    val item = shown(named(destination.label))
                    assertTrue(item.top >= 0.dp && item.bottom <= 300.dp, "${destination.label} at ${item.top}–${item.bottom} is out of the window")
                }
            } else {
                onNode(hasTestTag("footer")).assertExists()
            }
        }
    }

    /** On a phone the keyboard hides the bottom bar, so the bar never sits on the keyboard over the screen; down again, the bar is back. */
    @Test
    fun withTheKeyboardUpAPhoneHidesItsBottomBar() {
        for (keyboard in listOf(true, false)) runComposeUiTest {
            setContent {
                CompositionLocalProvider(LocalKeyboardHeight provides { if (keyboard) 600 else 0 }) {
                    PlezyTheme {
                        Box(Modifier.size(412.dp, 700.dp)) {
                            AdaptiveLayout(FormFactor.HANDHELD) {
                                NavigationScaffold(destinations = destinations, selected = TopLevelDestination.HOME, onSelect = {}, showNavigation = true) {
                                    Box(Modifier.fillMaxSize().testTag("content"))
                                }
                            }
                        }
                    }
                }
            }
            onAllNodes(hasText(destinations.first().label)).assertCountEquals(if (keyboard) 0 else 1)
        }
    }

    /**
     * On a 1080p TV (960 × 540 dp) Left from the screen into the column lands on the selected destination, from an
     * element above the destinations, level with them or below them; Right goes back to the screen, and Left again to
     * the destination.
     */
    @Test
    fun onTvLeftLandsOnTheSelectedDestinationWhateverTheElementsHeight() {
        val elements = listOf(
            "above the destinations" to 40,
            "level with the first" to 134,
            "level with the third" to 246,
            "level with the last" to 358,
            "below the destinations" to 460,
        )
        val wrong = mutableListOf<String>()
        for (selected in listOf(TopLevelDestination.HOME)) {
            for ((element, _) in elements) runComposeUiTest {
                val probe = FocusedProbe()
                tvColumn(probe, selected, elements)
                onNodeWithText(element).requestFocus()
                waitForIdle()
                val case = "${selected.probeName} selected, from the element $element"
                press(Key.DirectionLeft)
                val first = probe.focused
                if (first != "nav.${selected.probeName}") wrong += "$case: Left went to $first, not nav.${selected.probeName}"
                press(Key.DirectionRight)
                val screen = probe.focused
                if (screen == null || screen.startsWith("nav.")) {
                    wrong += "$case: Right from $first went to $screen, not back to the screen"
                } else {
                    press(Key.DirectionLeft)
                    if (probe.focused != first) wrong += "$case: Left again from $screen went to ${probe.focused}, not $first"
                }
            }
        }
        assertTrue(wrong.isEmpty(), wrong.joinToString("\n"))
    }

    /**
     * On a TV, a screen whose content arrives late (Home after Back on a TV box): focus walked from the screen into the
     * column and down it stays there as the content arrives, never taken back to the screen's first card; and Left from
     * the chip at the start of the screen's first row, pressed as focus comes back to it while the column still narrows,
     * lands in the column.
     */
    @Test
    fun onTvFocusWalkedIntoTheColumnStaysAsTheContentArrivesAndLeftFromTheChipReachesTheNarrowingColumn() = runComposeUiTest {
        val probe = FocusedProbe()
        var ready by mutableStateOf(false)
        setContent {
            CompositionLocalProvider(LocalLayoutProbe provides probe) {
                PlezyTheme {
                    Box(Modifier.size(960.dp, 540.dp)) {
                        AdaptiveLayout(FormFactor.TV, Modifier.arrowKeyFocus()) {
                            NavigationScaffold(destinations = destinations, selected = TopLevelDestination.HOME, onSelect = {}, showNavigation = true) {
                                val screen = remember { ScreenFocus { true } }
                                Box(Modifier.fillMaxSize().then(screen.modifier)) {
                                    CompositionLocalProvider(LocalScreenFocus provides screen) {
                                        val memory = rememberFocusMemory()
                                        Column(Modifier.padding(start = 48.dp, top = 40.dp), verticalArrangement = Arrangement.spacedBy(24.dp)) {
                                            // Narrower than the open column reaches into the screen.
                                            PlezyButton(CHIP, onClick = {}, modifier = Modifier.width(120.dp).layoutProbe("screen.chip"))
                                            if (ready) PlezyButton(CARD, onClick = {}, modifier = Modifier.width(240.dp).rememberFocus(memory, CARD).layoutProbe("screen.card"))
                                        }
                                        RestoreFocus(memory, ready, fallback = CARD.takeIf { ready })
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        onNodeWithText(CHIP).requestFocus()
        waitForIdle()
        press(Key.DirectionLeft)
        press(Key.DirectionDown)
        val walked = probe.focused
        assertTrue(walked?.startsWith("nav.") == true, "Left, then Down from the chip went to $walked, not down the column")
        ready = true
        waitForIdle()
        assertEquals(walked, probe.focused, "the content arriving took focus from $walked")
        mainClock.autoAdvance = false
        onNodeWithText(CHIP).requestFocus()
        mainClock.advanceTimeByFrame()
        onRoot().performKeyInput { pressKey(Key.DirectionLeft) }
        mainClock.advanceTimeByFrame()
        assertTrue(probe.focused?.startsWith("nav.") == true, "Left from the chip while the column narrows went to ${probe.focused}")
    }

    private fun ComposeUiTest.shown(matcher: SemanticsMatcher): DpRect = onNode(matcher).getBoundsInRoot()

    /** A destination by its label, or by its name where a phone's rail shows icons alone (the labels don't fit). */
    private fun named(label: String): SemanticsMatcher = hasText(label) or hasContentDescription(label)

    private fun ComposeUiTest.rail(formFactor: FormFactor, width: Int, height: Int) = setContent {
        PlezyTheme {
            Box(Modifier.size(width.dp, height.dp)) {
                AdaptiveLayout(formFactor) {
                    NavigationScaffold(
                        destinations = destinations,
                        selected = TopLevelDestination.HOME,
                        onSelect = {},
                        showNavigation = true,
                    ) {
                        Box(Modifier.fillMaxSize().testTag("content"))
                    }
                }
            }
        }
    }

    /**
     * The TV frame of a 1080p TV (960 × 540 dp), the arrow keys as the D-pad, [selected] chosen, around a screen of a
     * button for each of [elements] (its label, its top in dp), 48 dp in from the screen's place.
     */
    private fun ComposeUiTest.tvColumn(probe: FocusedProbe, selected: TopLevelDestination, elements: List<Pair<String, Int>>) = setContent {
        CompositionLocalProvider(LocalLayoutProbe provides probe) {
            PlezyTheme {
                Box(Modifier.size(960.dp, 540.dp)) {
                    AdaptiveLayout(FormFactor.TV, Modifier.arrowKeyFocus()) {
                        NavigationScaffold(destinations = destinations, selected = selected, onSelect = {}, showNavigation = true) {
                            Box(Modifier.fillMaxSize()) {
                                for ((label, top) in elements) {
                                    PlezyButton(label, onClick = {}, modifier = Modifier.padding(start = 48.dp, top = top.dp).width(480.dp).layoutProbe("screen.$label"))
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private fun ComposeUiTest.press(key: Key) {
        onRoot().performKeyInput { pressKey(key) }
        waitForIdle()
    }

    private companion object {
        const val CHIP = "Watch together"
        const val CARD = "card"
    }
}

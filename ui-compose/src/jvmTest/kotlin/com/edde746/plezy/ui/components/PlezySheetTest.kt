package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.assertIsNotFocused
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.swipeDown
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.height
import androidx.navigationevent.DirectNavigationEventInput
import androidx.navigationevent.NavigationEventDispatcher
import androidx.navigationevent.NavigationEventDispatcherOwner
import androidx.navigationevent.NavigationEventInfo
import androidx.navigationevent.compose.LocalNavigationEventDispatcherOwner
import androidx.navigationevent.compose.NavigationBackHandler
import androidx.navigationevent.compose.rememberNavigationEventState
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * An open [PlezySheet] keeps keyboard, D-pad and remote focus, so keys and Back reach it and never the screen under
 * it; once it is closing, focus may leave it for the screen that takes its place. A screen reader reaches only the
 * newest sheet.
 */
@OptIn(ExperimentalTestApi::class)
class PlezySheetTest {
    private val under = FocusRequester()
    private val dispatcher = NavigationEventDispatcher()
    private val back = DirectNavigationEventInput().also { dispatcher.addInput(it) }
    private var visible by mutableStateOf(true)
    private var composed by mutableStateOf(true)
    private var buttons by mutableStateOf(listOf("First", "Second"))
    private var dismissed = 0
    private var screenBacks = 0

    @Test
    fun whenTheFocusedControlGoesAwayTheSheetTakesFocusBack() = runComposeUiTest {
        sheetOverScreen()
        onNodeWithText("First").assertIsFocused()

        buttons = listOf("Second")
        onNodeWithText("Second").assertIsFocused()
        screenButton().assertIsNotFocused()
    }

    @Test
    fun theScreenUnderAnOpenSheetCantTakeFocus() = runComposeUiTest {
        sheetOverScreen()
        onNodeWithText("First").assertIsFocused()

        runOnIdle { under.requestFocus() }
        onNodeWithText("First").assertIsFocused()
        screenButton().assertIsNotFocused()
    }

    @Test
    fun aClosingSheetLetsTheScreenTakeFocusWhileItSlidesAway() = runComposeUiTest {
        sheetOverScreen()
        onNodeWithText("First").assertIsFocused()

        mainClock.autoAdvance = false
        visible = false
        mainClock.advanceTimeByFrame()
        // Still on screen, sliding away: the screen that takes its place (the player after a stream is picked) gets focus.
        onNodeWithText("First").assertExists()
        runOnIdle { under.requestFocus() }
        screenButton().assertIsFocused()
    }

    @Test
    fun backClosesTheSheetNotTheScreenUnderIt() = runComposeUiTest {
        sheetOverScreen()
        onNodeWithText("First").assertIsFocused()

        runOnIdle { back.backCompleted() }
        runOnIdle {
            assertEquals(1, dismissed)
            assertEquals(0, screenBacks)
        }
    }

    /**
     * Once the sheet has closed, focus is back on the control that had it before the sheet opened (a control of the
     * screen's scrolling column), not on the first control of the window, the navigation.
     */
    @Test
    fun aClosedSheetGivesFocusBackToTheControlThatHadIt() = runComposeUiTest {
        visible = false
        sheetOverScreen()
        runOnIdle { under.requestFocus() }
        onNodeWithText("Under").assertIsFocused()

        visible = true
        onNodeWithText("First").assertIsFocused()

        visible = false
        onNodeWithText("First").assertDoesNotExist()
        onNodeWithText("Under").assertIsFocused()
        onNodeWithText("Navigation").assertIsNotFocused()
    }

    /** A sheet closed by no longer composing it (TV Detail's More panel) gives focus back to that control too. */
    @Test
    fun aSheetNoLongerComposedGivesFocusBackToTheControlThatHadIt() = runComposeUiTest {
        composed = false
        sheetOverScreen()
        runOnIdle { under.requestFocus() }
        onNodeWithText("Under").assertIsFocused()

        composed = true
        onNodeWithText("First").assertIsFocused()

        composed = false
        onNodeWithText("First").assertDoesNotExist()
        onNodeWithText("Under").assertIsFocused()
        onNodeWithText("Navigation").assertIsNotFocused()
    }

    /** A sheet with nothing to focus yet (a list still loading) holds focus itself, so Escape still closes it. */
    @Test
    fun escapeClosesASheetWithNothingFocusableInIt() = runComposeUiTest {
        buttons = emptyList()
        sheetOverScreen()
        screenButton().assertIsNotFocused()

        onRoot().performKeyInput { pressKey(Key.Escape) }
        runOnIdle {
            assertEquals(1, dismissed)
            assertEquals(0, screenBacks)
        }
    }

    /**
     * A screen reader reaches only the newest sheet, announced as a pane titled by its title: the screen under an open
     * sheet, and an earlier sheet under a newer one, are hidden from it, as the scrim keeps touch and focus from them.
     */
    @Test
    fun aScreenReaderReachesOnlyTheNewestSheet() = runComposeUiTest {
        var second by mutableStateOf(false)
        setContent {
            PlezyTheme {
                OverlayHostBox(Modifier.fillMaxSize()) {
                    PlezyButton("Under", {})
                    PlezySheet(onDismiss = {}, title = "Sort") {
                        PlezyButton("First", {})
                        if (second) PlezySheet(onDismiss = {}, title = "Filter") { PlezyButton("Second", {}) }
                    }
                }
            }
        }
        onNodeWithText("First").assertExists()
        onNodeWithText("Under").assertDoesNotExist()
        onNode(SemanticsMatcher.expectValue(SemanticsProperties.PaneTitle, "Sort")).assertExists()

        second = true
        onNodeWithText("Second").assertExists()
        onNodeWithText("First").assertDoesNotExist()
        onNodeWithText("Under").assertDoesNotExist()
        onNode(SemanticsMatcher.expectValue(SemanticsProperties.PaneTitle, "Filter")).assertExists()
    }

    /**
     * On TV a menu opened from a control in the sheet (a stream row's, a side panel over the sheet) takes focus from the
     * sheet; picking an entry runs it, and focus goes back to the sheet.
     */
    @Test
    fun onTvAMenuOpenedInTheSheetTakesFocus() = runComposeUiTest {
        var picked = 0
        setContent {
            PlezyTheme {
                AdaptiveLayout(FormFactor.TV) {
                    OverlayHostBox(Modifier.fillMaxSize()) {
                        PlezySheet(onDismiss = { dismissed++ }) {
                            var menu by remember { mutableStateOf(false) }
                            Box {
                                PlezyButton("Row", { menu = true })
                                ItemMenu(menu, { menu = false }, listOf(ItemMenuEntry("Entry") { picked++ }), probe = "menu")
                            }
                        }
                    }
                }
            }
        }
        onNodeWithText("Row").assertIsFocused().performClick()
        onNode(hasClickAction() and hasText("Entry")).assertIsFocused()

        onRoot().performKeyInput { pressKey(Key.Enter) }
        runOnIdle {
            assertEquals(1, picked)
            assertEquals(0, dismissed)
        }
        onNodeWithText("Entry").assertDoesNotExist()
        onNodeWithText("Row").assertIsFocused()
    }

    /**
     * On the desktop the sheet is a panel docked along the window's right edge from its top, which a drag doesn't
     * dismiss; focus enters its content, and its close button dismisses it.
     */
    @Test
    fun onTheDesktopTheSheetDocksAlongTheRightEdge() = runComposeUiTest {
        setContent {
            PlezyTheme {
                AdaptiveLayout(FormFactor.DESKTOP) {
                    OverlayHostBox(Modifier.fillMaxSize().testTag("window")) {
                        PlezySheet(onDismiss = { dismissed++ }, title = "Info") { PlezyButton("First", {}) }
                    }
                }
            }
        }
        assertDocked("Info")

        onNodeWithText("Info").performTouchInput { swipeDown() }
        runOnIdle { assertEquals(0, dismissed) }
        onNodeWithText("First").assertIsFocused()
        onNodeWithContentDescription(T.common.close).performClick()
        runOnIdle { assertEquals(1, dismissed) }
    }

    /** A docked sheet's close button centres on its header line, also on a line taller than the button. */
    @Test
    fun theCloseButtonCentresOnATallHeaderLine() = runComposeUiTest {
        setContent {
            PlezyTheme {
                AdaptiveLayout(FormFactor.DESKTOP) {
                    OverlayHostBox(Modifier.fillMaxSize()) {
                        PlezySheet(onDismiss = {}, header = { Box(Modifier.size(40.dp, 64.dp).testTag("header")) }) { PlezyButton("First", {}) }
                    }
                }
            }
        }
        val header = onNodeWithTag("header").getBoundsInRoot()
        val close = onNodeWithContentDescription(T.common.close).getBoundsInRoot()
        assertEquals((header.top + header.bottom).value / 2, (close.top + close.bottom).value / 2, 0.5f, "the close button $close on the header line $header")
    }

    /** A docked sheet's close button shares its title's line and keeps the title's inset from the panel's other edge. */
    @Test
    fun theCloseButtonSharesTheTitlesCentreAndThePanelsInset() = runComposeUiTest {
        setContent {
            PlezyTheme {
                AdaptiveLayout(FormFactor.DESKTOP) {
                    OverlayHostBox(Modifier.fillMaxSize()) {
                        PlezySheet(onDismiss = {}, Modifier.testTag("panel"), title = "Filters") { PlezyButton("First", {}) }
                    }
                }
            }
        }
        val panel = onNodeWithTag("panel").getBoundsInRoot()
        val title = onNodeWithText("Filters").getBoundsInRoot()
        val close = onNodeWithContentDescription(T.common.close).getBoundsInRoot()
        assertEquals((title.top + title.bottom).value / 2, (close.top + close.bottom).value / 2, 1f, "the close button $close on the title's line $title")
        assertEquals((title.left - panel.left).value, (panel.right - close.right).value, 1f, "the close button $close inset as the title $title in $panel")
    }

    /** On TV the bottom sheet (the music queue) is a card inside the overscan-safe area, a long list scrolling in it. */
    @Test
    fun onTvTheBottomSheetStaysInsideTheSafeArea() = runComposeUiTest {
        setContent {
            PlezyTheme {
                AdaptiveLayout(FormFactor.TV) {
                    OverlayHostBox(Modifier.fillMaxSize().testTag("window")) {
                        PlezySheet(onDismiss = {}, title = "Queue", bottom = true) {
                            Column(Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState()).testTag("list")) {
                                repeat(40) { PlezyButton("Row $it", {}) }
                            }
                        }
                    }
                }
            }
        }
        val window = onNodeWithTag("window").getBoundsInRoot()
        val list = onNodeWithTag("list").getBoundsInRoot()
        assertTrue(list.bottom <= window.bottom - window.height * 0.05f, "the list $list reaches into the bottom 5 % of $window")
        assertTrue(list.top >= window.top + window.height * 0.05f, "the list $list reaches into the top 5 % of $window")
    }

    /** On TV a short bottom sheet's card stands in the middle of the screen, not low on it. */
    @Test
    fun onTvAShortBottomSheetStandsInTheMiddle() = runComposeUiTest {
        setContent {
            PlezyTheme {
                AdaptiveLayout(FormFactor.TV) {
                    OverlayHostBox(Modifier.fillMaxSize().testTag("window")) {
                        PlezySheet(onDismiss = {}, modifier = Modifier.testTag("card"), title = "Queue", bottom = true) {
                            repeat(2) { PlezyButton("Row $it", {}) }
                        }
                    }
                }
            }
        }
        val window = onNodeWithTag("window").getBoundsInRoot()
        val card = onNodeWithTag("card").getBoundsInRoot()
        assertTrue(card.height < window.height / 2, "the card $card holds two rows")
        assertEquals((window.top + window.bottom).value / 2, (card.top + card.bottom).value / 2, 1f, "the card $card centres on $window")
    }

    /** On TV a dialog is no card in the middle of the screen but the sheet's panel along the right edge. */
    @Test
    fun onTvADialogDocksAlongTheRightEdge() = runComposeUiTest {
        setContent {
            PlezyTheme {
                AdaptiveLayout(FormFactor.TV) {
                    OverlayHostBox(Modifier.fillMaxSize().testTag("window")) {
                        ConfirmDialog("Delete", "Sure?", "Delete", onConfirm = {}, onCancel = { dismissed++ }, probe = "ask")
                    }
                }
            }
        }
        assertDocked("Delete")
    }

    /** [title] heads a panel in the window's right half, near its top. */
    private fun ComposeUiTest.assertDocked(title: String) {
        val window = onNodeWithTag("window").fetchSemanticsNode().boundsInRoot
        val heading = onAllNodesWithText(title)[0].fetchSemanticsNode().boundsInRoot
        assertTrue(heading.left > window.center.x, "the title starts at ${heading.left}, left of the window's middle ${window.center.x}")
        assertTrue(heading.top < window.top + window.height / 8, "the title is at ${heading.top}, far below the window's top")
    }

    /** The screen's button under the sheet, which the sheet, while it shows, hides from screen readers, not from focus. */
    private fun ComposeUiTest.screenButton() = onNodeWithTag("under", useUnmergedTree = true)

    /**
     * A screen with its own Back (as the navigation container has) beside the navigation, its button in a scrolling
     * column (a focus group of its own) and part of its focus memory, under a sheet of [buttons].
     */
    private fun ComposeUiTest.sheetOverScreen() = setContent {
        val owner = object : NavigationEventDispatcherOwner {
            override val navigationEventDispatcher = dispatcher
        }
        CompositionLocalProvider(LocalNavigationEventDispatcherOwner provides owner) {
            PlezyTheme {
                OverlayHostBox(Modifier.fillMaxSize()) {
                    NavigationBackHandler(rememberNavigationEventState(NavigationEventInfo.None), isBackEnabled = true, onBackCompleted = { screenBacks++ })
                    Row {
                        PlezyButton("Navigation", {})
                        val memory = rememberFocusMemory()
                        Column(Modifier.verticalScroll(rememberScrollState())) {
                            PlezyButton("Under", {}, Modifier.testTag("under").rememberFocus(memory, "under").focusRequester(under))
                        }
                    }
                    if (composed) {
                        PlezySheet(onDismiss = { dismissed++ }, visible = visible) {
                            for (label in buttons) PlezyButton(label, {})
                        }
                    }
                }
            }
        }
    }
}

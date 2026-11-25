package com.edde746.plezy.ui.downloads

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.semantics.getOrNull
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.isFocused
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.downloads.DownloadsTab
import com.edde746.plezy.presentation.downloads.DownloadsUiState
import com.edde746.plezy.presentation.downloads.downloadCard
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.presentation.theme.AppearanceSettings
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezySheet
import com.edde746.plezy.ui.focus.arrowKeyFocus
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * A controller's shoulder buttons (L1 and R1: Android's key events, the desktop's from its gamepad bridge) on Downloads'
 * tabs: the previous or the next tab, its chip focused, stopping at the ends; wherever focus is, the navigation beside
 * the screen too; never while a sheet is open over the app.
 */
@OptIn(ExperimentalTestApi::class)
class DownloadsTabShouldersTest {
    private var selected by mutableStateOf(DownloadsTab.MANAGE)
    private var sheet by mutableStateOf(false)
    private val navigation = FocusRequester()

    private fun ComposeUiTest.assertFocused(text: String) {
        val focused = onAllNodes(isFocused()).fetchSemanticsNodes().map { it.config.getOrNull(SemanticsProperties.Text)?.joinToString() }
        assertEquals(listOf(text), focused, "focused")
    }

    @Test
    fun r1AndL1StepThroughTheTabsFocusingTheirChipsAndStopAtTheEnds() = runComposeUiTest {
        screen()
        runOnIdle { navigation.requestFocus() }
        assertFocused("Navigation")
        press(Key.ButtonR1)
        assertEquals(DownloadsTab.entries[1], selected)
        assertFocused(DownloadsTab.entries[1].label)
        repeat(DownloadsTab.entries.size) { press(Key.ButtonR1) }
        assertEquals(DownloadsTab.entries.last(), selected)
        repeat(DownloadsTab.entries.size + 1) { press(Key.ButtonL1) }
        assertEquals(DownloadsTab.entries.first(), selected)
        assertFocused(DownloadsTab.entries.first().label)
    }

    @Test
    fun aSheetOverTheAppKeepsTheTab() = runComposeUiTest {
        screen()
        sheet = true
        onNodeWithText("In the sheet").assertIsFocused()
        press(Key.ButtonR1)
        assertEquals(DownloadsTab.MANAGE, selected)
        sheet = false
        waitForIdle()
        press(Key.ButtonR1)
        assertEquals(DownloadsTab.entries[1], selected)
    }

    private fun ComposeUiTest.press(key: Key) {
        onRoot().performKeyInput { pressKey(key) }
        waitForIdle()
    }

    private fun ComposeUiTest.screen() = setContent {
        PlezyTheme {
            Box(Modifier.size(1200.dp, 744.dp).background(Color.Black)) {
                AdaptiveLayout(FormFactor.DESKTOP, Modifier.arrowKeyFocus()) {
                    val appearance = Appearance.of(AppearanceSettings(), FormFactor.DESKTOP, supporterUnlocked = false)
                    CompositionLocalProvider(LocalAppearance provides appearance) {
                        OverlayHostBox {
                            Row {
                                PlezyButton("Navigation", {}, Modifier.focusRequester(navigation))
                                DownloadsContentView(
                                    DownloadsUiState(selected = selected),
                                    { downloadCard(it, null) },
                                    { null },
                                    { null },
                                    DownloadsScreenActions(select = { selected = it }),
                                )
                            }
                            if (sheet) PlezySheet(onDismiss = { sheet = false }) { PlezyButton("In the sheet", {}) }
                        }
                    }
                }
            }
        }
    }
}

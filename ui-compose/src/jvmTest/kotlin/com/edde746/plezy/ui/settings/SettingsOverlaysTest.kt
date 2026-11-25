package com.edde746.plezy.ui.settings

import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.hasSetTextAction
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.performTextReplacement
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.presentation.settings.SettingColorRow
import com.edde746.plezy.presentation.settings.SettingNumberRow
import com.edde746.plezy.presentation.settings.SettingTextRow
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.focus.FocusVisibility
import com.edde746.plezy.ui.focus.LocalFocusVisibility
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** The settings overlays' own behaviour: an input the store refuses keeps its overlay open with the store's error. */
@OptIn(ExperimentalTestApi::class)
class SettingsOverlaysTest {
    private var open by mutableStateOf(true)

    /** Save with a value the store refuses: its error under the field, the overlay open; a value it takes closes it. */
    @Test
    fun aNumberTheStoreRefusesKeepsTheOverlayOpenWithItsError() = runComposeUiTest {
        val saved = mutableListOf<String>()
        overlay {
            NumberOverlay(NUMBER, onSave = { text ->
                saved += text
                if (text == "500") "Duration must be between 1 and 120 seconds" else null
            }, validate = { null }, onDismiss = { open = false })
        }
        onNode(hasSetTextAction()).performTextReplacement("500")
        onNodeWithText(T.common.save).performClick()
        waitForIdle()
        onNodeWithText("Duration must be between 1 and 120 seconds").assertIsDisplayed()
        assertTrue(open, "the overlay closed on a refused value")
        onNode(hasSetTextAction()).performTextReplacement("30")
        onNodeWithText(T.common.save).performClick()
        waitForIdle()
        assertEquals(listOf("500", "30"), saved)
        assertTrue(!open, "the overlay stayed open on a stored value")
    }

    /**
     * A pattern the store refuses keeps the overlay open with the error; Reset to Default fills the default without
     * storing it and clears the error; Save then stores it as typed.
     */
    @Test
    fun aRefusedTextStaysOpenAndResetFillsTheDefault() = runComposeUiTest {
        val saved = mutableListOf<String>()
        overlay {
            TextOverlay(TEXT, onSave = { text ->
                saved += text
                if (text.isBlank()) T.settings.invalidRegex else null
            }, onReset = { "^intro$" }, onDismiss = { open = false })
        }
        onNode(hasSetTextAction()).performTextReplacement("   ")
        onNodeWithText(T.common.save).performClick()
        waitForIdle()
        onNodeWithText(T.settings.invalidRegex).assertIsDisplayed()
        assertTrue(open)
        onNodeWithText(T.settings.resetToDefault).performClick()
        waitForIdle()
        assertEquals(0, onAllNodes(androidx.compose.ui.test.hasText(T.settings.invalidRegex)).fetchSemanticsNodes().size, "the error stayed after Reset")
        assertEquals(listOf("   "), saved, "Reset stored something")
        onNodeWithText(T.common.save).performClick()
        waitForIdle()
        assertEquals(listOf("   ", "^intro$"), saved)
        assertTrue(!open)
    }

    /** Enter in the field saves what it holds and closes the overlay; a reset the store stored itself closes it too. */
    @Test
    fun enterSavesAndAStoredResetCloses() = runComposeUiTest {
        val saved = mutableListOf<String>()
        overlay {
            TextOverlay(TEXT, onSave = { saved += it; null }, onReset = { null }, onDismiss = { open = false })
        }
        onNode(hasSetTextAction()).performClick()
        onNode(hasSetTextAction()).performKeyInput { pressKey(Key.Enter) }
        waitForIdle()
        assertEquals(listOf("^intro$"), saved)
        assertTrue(!open, "Enter left the overlay open")
        open = true
        waitForIdle()
        onNodeWithText(T.settings.resetToDefault).performClick()
        waitForIdle()
        assertTrue(!open, "a stored reset left the overlay open")
        assertEquals(listOf("^intro$"), saved, "the reset saved the field")
    }

    /** Typing shows at once what the check says of the text (the store's rule), and nothing once it passes. */
    @Test
    fun theNumberAndPatternOverlaysSayWhatIsWrongWhileTyping() = runComposeUiTest {
        var pattern by mutableStateOf(false)
        overlay {
            if (pattern) {
                TextOverlay(TEXT, onSave = { null }, onReset = { "" }, onDismiss = {}, validate = { if (it == "intro(") T.settings.invalidRegex else null })
            } else {
                NumberOverlay(NUMBER, onSave = { null }, validate = { if (it == "500") T.settings.validationErrorEnterNumber else null }, onDismiss = {})
            }
        }
        onNode(hasSetTextAction()).performTextReplacement("500")
        waitForIdle()
        onNodeWithText(T.settings.validationErrorEnterNumber).assertIsDisplayed()
        onNode(hasSetTextAction()).performTextReplacement("50")
        waitForIdle()
        assertEquals(0, onAllNodes(androidx.compose.ui.test.hasText(T.settings.validationErrorEnterNumber)).fetchSemanticsNodes().size, "the error stayed")
        pattern = true
        waitForIdle()
        onNode(hasSetTextAction()).performTextReplacement("intro(")
        waitForIdle()
        onNodeWithText(T.settings.invalidRegex).assertIsDisplayed()
    }

    /** Fewer than six typed hex digits leave the colour as it was (Save writes nothing); six are the colour, upper case. */
    @Test
    fun aTypedHexCodeIsTheColourSaved() = runComposeUiTest {
        val saved = mutableListOf<String>()
        var attempt by mutableStateOf(0)
        overlay {
            androidx.compose.runtime.key(attempt) {
                ColorSheet(SettingColorRow("text", "Text Color", "#FFFFFF"), onSave = { saved += it }, onDismiss = { open = false })
            }
        }
        onNode(hasSetTextAction()).performTextReplacement("1a2b")
        waitForIdle()
        onNodeWithText(T.common.save).performClick()
        waitForIdle()
        assertEquals(emptyList(), saved, "a partial code was saved")
        attempt++
        open = true
        waitForIdle()
        onNode(hasSetTextAction()).performTextReplacement("1a2b3c")
        waitForIdle()
        onNodeWithText(T.common.save).performClick()
        waitForIdle()
        assertEquals(listOf("#1A2B3C"), saved)
    }

    /** [content] while [open], in the app's overlay host, by touch. */
    private fun ComposeUiTest.overlay(content: @androidx.compose.runtime.Composable () -> Unit) = setContent {
        PlezyTheme {
            CompositionLocalProvider(LocalFocusVisibility provides remember { FocusVisibility(initial = false) }) {
                OverlayHostBox { if (open) content() }
            }
        }
    }

    private companion object {
        val NUMBER = SettingNumberRow("seek", "Small Skip Duration", "10 seconds", 10, 1, 120, "s", "Enter duration (1-120)")
        val TEXT = SettingTextRow("intro", "Intro pattern", "Chapters matching it count as the intro", "^intro$", T.settings.regex, "", T.settings.resetToDefault, monospace = true)
    }
}

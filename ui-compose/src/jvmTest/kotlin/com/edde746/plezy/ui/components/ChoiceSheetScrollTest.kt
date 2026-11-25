package com.edde746.plezy.ui.components

import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.ui.TvFrame
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * A choice's side panel on TV (a sort's: Clear, the directions, then the fields) opens at its top with the selected
 * option focused while that is on screen, scrolled to it only when it isn't; moving focus to a row already on screen
 * and clear of the fades doesn't scroll it.
 */
@OptIn(ExperimentalTestApi::class)
class ChoiceSheetScrollTest {
    @Test
    fun aSelectedOptionOnScreenOpensThePanelAtItsTop() = runComposeUiTest {
        sortPanel(selectedField = 0)
        onNode(hasText(CLEAR)).assertIsDisplayed()
        onNode(hasText(field(0))).assertIsFocused()
        val top = onNode(hasText(CLEAR)).getBoundsInRoot().top
        onRoot().performKeyInput { pressKey(Key.DirectionUp) }
        waitForIdle()
        onNode(hasText(DESCENDING)).assertIsFocused()
        assertEquals(top, onNode(hasText(CLEAR)).getBoundsInRoot().top, "a row on screen taking focus doesn't scroll the panel")
    }

    @Test
    fun aSelectedOptionOffScreenIsScrolledToAndFocused() = runComposeUiTest {
        sortPanel(selectedField = 25)
        onNode(hasText(field(25))).assertIsFocused()
        onNode(hasText(field(25))).assertIsDisplayed()
    }

    private fun ComposeUiTest.sortPanel(selectedField: Int) {
        setContent {
            TvFrame {
                val directions = listOf(MenuChoice("Ascending", selected = true, heading = ""), MenuChoice(DESCENDING, selected = false))
                val fields = (0 until 30).map { MenuChoice(field(it), selected = it == selectedField, heading = if (it == 0) "Sort by" else null) }
                ChoiceMenu(expanded = true, onDismiss = {}, title = "Sort", choices = listOf(MenuChoice(CLEAR, selected = false)) + directions + fields, onPick = {}, probe = "sort")
            }
        }
        waitForIdle()
    }

    private fun field(index: Int) = "Field ${index.toString().padStart(2, '0')}"

    private companion object {
        const val CLEAR = "Clear"
        const val DESCENDING = "Descending"
    }
}

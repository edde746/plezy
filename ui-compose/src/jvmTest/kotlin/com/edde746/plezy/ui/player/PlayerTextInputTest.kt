package com.edde746.plezy.ui.player

import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasSetTextAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.performTextInputSelection
import androidx.compose.ui.test.performTextReplacement
import androidx.compose.ui.test.requestFocus
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.text.TextRange
import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.InputKey
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.player.SubtitleSearchState
import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * The subtitle search's text field in an open menu, on desktop's panel and in TV's and handheld's sheet: Backspace and
 * Home edit its text and never reach the store as Back (which would close the menu, or the player); elsewhere in the
 * menu Backspace reaches the store, whose Back closes the menu.
 */
@OptIn(ExperimentalTestApi::class)
class PlayerTextInputTest {
    private val formFactors = listOf(FormFactor.DESKTOP, FormFactor.TV, FormFactor.HANDHELD)
    private val search = SubtitleSearchState(
        language = "English",
        languageCode = "en",
        languages = emptyList(),
        title = "",
        searching = false,
        results = emptyList(),
        downloading = null,
        message = null,
    )

    private class Recorder {
        val commands = mutableListOf<PlayerCommand>()
        val keys = mutableListOf<InputEvent>()
        val onInput: (InputEvent) -> Boolean = { event ->
            if (event is InputEvent.KeyDown || event is InputEvent.KeyUp) keys += event
            true
        }
    }

    private fun ComposeUiTest.searchMenu(formFactor: FormFactor, recorder: Recorder) =
        player(formFactor, onCommand = { recorder.commands += it }, onInput = recorder.onInput) {
            testPlayerState(menu = PlayerMenu.SUBTITLE_SEARCH).copy(subtitleSearch = search)
        }

    private fun ComposeUiTest.focusFieldWithText(text: String, caret: Int) {
        onNode(hasSetTextAction()).performTextReplacement(text)
        onNode(hasSetTextAction()).requestFocus().performTextInputSelection(TextRange(caret))
        waitForIdle()
    }

    private fun List<InputEvent>.textKeys() =
        filter { (it as? InputEvent.KeyDown)?.key in TEXT_KEYS || (it as? InputEvent.KeyUp)?.key in TEXT_KEYS }

    @Test
    fun backspaceInTheSearchFieldEditsTextInsteadOfLeaving() {
        for (formFactor in formFactors) runComposeUiTest {
            val recorder = Recorder()
            searchMenu(formFactor, recorder)
            focusFieldWithText("star wars", caret = 5)
            press(Key.Backspace)
            runOnIdle {
                assertEquals(PlayerCommand.SearchSubtitles("en", "starwars"), recorder.commands.last(), "$formFactor")
                assertEquals(emptyList(), recorder.keys.textKeys(), "$formFactor: the keys the store saw")
            }
        }
    }

    @Test
    fun homeInTheSearchFieldStaysWithTheField() {
        for (formFactor in formFactors) runComposeUiTest {
            val recorder = Recorder()
            searchMenu(formFactor, recorder)
            focusFieldWithText("star wars", caret = 5)
            press(Key.MoveHome)
            press(Key.Backspace)
            runOnIdle {
                assertEquals(PlayerCommand.SearchSubtitles("en", "star wars"), recorder.commands.last(), "$formFactor: the caret went home")
                assertEquals(emptyList(), recorder.keys.textKeys(), "$formFactor: the keys the store saw")
            }
        }
    }

    @Test
    fun backspaceOnAMenuRowReachesTheStoreAsOnePress() {
        for (formFactor in formFactors) runComposeUiTest {
            val recorder = Recorder()
            searchMenu(formFactor, recorder)
            onNode(hasText(T.videoControls.language) and hasClickAction()).requestFocus()
            waitForIdle()
            press(Key.Backspace)
            runOnIdle {
                val keys = recorder.keys.textKeys()
                assertEquals(2, keys.size, "$formFactor: $keys")
                assertTrue((keys[0] as InputEvent.KeyDown).let { it.key == InputKey.BACKSPACE && !it.repeat }, "$formFactor: $keys")
                assertEquals(InputEvent.KeyUp(InputKey.BACKSPACE), keys[1], "$formFactor")
            }
        }
    }

    private companion object {
        val TEXT_KEYS = setOf(InputKey.BACKSPACE, InputKey.HOME)
    }
}

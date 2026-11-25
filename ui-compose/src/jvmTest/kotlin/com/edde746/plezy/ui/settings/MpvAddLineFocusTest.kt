package com.edde746.plezy.ui.settings

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.isFocused
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.settings.MpvConfigStore
import com.edde746.plezy.presentation.settings.MpvConfigUiState
import com.edde746.plezy.presentation.settings.SettingsEvent
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.flow.update
import kotlin.test.Test
import kotlin.test.assertEquals

/** On TV, Add line puts focus in the new line's field, editable at once (its keyboard up). */
@OptIn(ExperimentalTestApi::class)
class MpvAddLineFocusTest {
    private class Lines(vararg lines: String) : MpvConfigStore {
        override val state = MutableStateFlow(MpvConfigUiState(lines.joinToString("\n"), lines.toList(), emptyList(), true, null, lineEditor = true))
        override val messages: Flow<SettingsEvent.Message> = emptyFlow()
        val edits = mutableListOf<Pair<Int, String>>()

        override fun edit(text: String) = Unit

        override fun editLine(index: Int, text: String) {
            edits += index to text
            state.update { it.copy(lines = it.lines.toMutableList().also { lines -> lines[index] = text }) }
        }

        override fun addLine() = state.update { it.copy(lines = it.lines + "") }

        override fun removeLine(index: Int) = state.update { it.copy(lines = it.lines.filterIndexed { i, _ -> i != index }) }

        override suspend fun flush() = true

        override fun savePreset(name: String) = Unit

        override fun loadPreset(name: String) = Unit

        override fun deletePreset(name: String) = Unit

        override fun release() = Unit
    }

    @Test
    fun addLineFocusesTheNewLineReadyToType() = runComposeUiTest {
        val store = Lines("vo=gpu")
        setContent {
            PlezyTheme {
                Box(Modifier.size(1280.dp, 720.dp)) {
                    AdaptiveLayout(FormFactor.TV) {
                        val state by store.state.collectAsState()
                        val added = remember { mutableStateOf<Int?>(null) }
                        SettingsList { configLines(state.lines, store, added) }
                    }
                }
            }
        }
        onNode(hasText(T.mpvConfig.addLine)).performClick()
        waitForIdle()
        assertEquals(listOf("vo=gpu", ""), store.state.value.lines)
        onNode(isFocused()).performTextInput("hwdec=auto")
        waitForIdle()
        assertEquals(1 to "hwdec=auto", store.edits.last(), "typed into the new line, without a Select first")
    }
}

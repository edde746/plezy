package com.edde746.plezy.ui.home

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.v2.runSkikoComposeUiTest
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.plex.PlexActivity
import com.edde746.plezy.presentation.home.ServerTasksGroup
import com.edde746.plezy.presentation.home.ServerTasksLoad
import com.edde746.plezy.presentation.home.ServerTasksUiState
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.probe.LayoutProbe
import com.edde746.plezy.ui.probe.LocalLayoutProbe
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * The Server Tasks panel under a 40 dp button at the end of an 800 × 600 dp window (1 px per dp): its states, its
 * place, its cancel buttons and how it closes.
 */
@OptIn(ExperimentalTestApi::class)
class ServerTasksPanelTest {
    private val bounds = HashMap<String, Rect>()
    private val probe = object : LayoutProbe {
        override fun place(name: String, bounds: Rect?) {
            if (bounds != null) this@ServerTasksPanelTest.bounds[name] = bounds else this@ServerTasksPanelTest.bounds.remove(name)
        }

        override fun focus(name: String, focused: Boolean) = Unit
    }

    private var state by mutableStateOf(ServerTasksUiState(shown = true, open = true))
    private val cancelled = mutableListOf<Pair<String, String>>()
    private var closed = 0

    private val tasks = ServerTasksUiState(
        shown = true,
        open = true,
        load = ServerTasksLoad.CONTENT,
        groups = listOf(
            ServerTasksGroup(
                "srv",
                "Living room",
                listOf(
                    PlexActivity("scan", "library.update.section", "Scanning Movies", "Adding files", 40, cancellable = false),
                    PlexActivity("bif", "media.generate.bif", "Generating thumbnails", null, 75, cancellable = true),
                ),
            ),
        ),
    )

    @Test
    fun thePanelSaysWhereTheTasksAre() = panel {
        onNodeWithText(T.serverTasks.failedToLoad).assertDoesNotExist()
        onNodeWithText(T.serverTasks.noTasks).assertDoesNotExist()
        state = state.copy(load = ServerTasksLoad.ERROR)
        onNodeWithText(T.serverTasks.failedToLoad).assertExists()
        state = state.copy(load = ServerTasksLoad.CONTENT)
        onNodeWithText(T.serverTasks.noTasks).assertExists()

        state = tasks
        onNodeWithText("LIVING ROOM").assertExists()
        onNodeWithText("2").assertExists()
        onNodeWithText("Scanning Movies").assertExists()
        onNodeWithText("Adding files").assertExists()
        onNodeWithText("Generating thumbnails").assertExists()
    }

    @Test
    fun thePanelHangsUnderItsButtonAtItsEnd() = panel {
        state = tasks
        waitForIdle()
        val button = bounds.getValue("button")
        val panel = bounds.getValue("home.serverTasks.panel")
        assertEquals(320f, panel.width, 1f)
        assertEquals(button.right, panel.right, 1f)
        assertEquals(button.bottom + 4f, panel.top, 1f)
    }

    @Test
    fun onlyACancellableTaskHasCancelWhichHasFocusAndCancelsIt() = panel {
        state = tasks
        waitForIdle()
        val cancel = onNodeWithContentDescription(T.common.cancel)
        cancel.assertIsFocused()
        assertEquals(null, bounds["home.serverTasks.cancel.scan"])
        cancel.performClick()
        assertEquals(listOf("srv" to "bif"), cancelled)
    }

    @Test
    fun escapeClosesThePanel() = panel {
        state = tasks
        waitForIdle()
        onNodeWithContentDescription(T.common.cancel).performKeyInput { pressKey(Key.Escape) }
        waitForIdle()
        assertEquals(1, closed)
    }

    private fun panel(block: ComposeUiTest.() -> Unit) = runSkikoComposeUiTest(size = Size(800f, 600f), density = Density(1f)) {
        setContent {
            CompositionLocalProvider(LocalLayoutProbe provides probe) {
                PlezyTheme {
                    AdaptiveLayout(FormFactor.DESKTOP) {
                        Box(Modifier.fillMaxSize()) {
                            Box(Modifier.align(Alignment.TopEnd).padding(top = 20.dp, end = 30.dp).size(40.dp).layoutProbe("button", reportsFocus = false)) {
                                ServerTasksPanel(state, onCancel = { server, uuid -> cancelled += server to uuid }, onClose = { closed++ })
                            }
                        }
                    }
                }
            }
        }
        block()
    }
}

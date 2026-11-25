package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update

/**
 * A dialog's or sheet's content follows the screen that shows it, also when that screen is in a composition of its own
 * (a section laid out by its width) and its store answers in the frame the overlay first shows (the players found as
 * the Player page opens): the host composes the content the screen handed it, and must draw what the screen has now.
 */
@OptIn(ExperimentalTestApi::class)
class HostedOverlayTest {
    /** A store's state: whether the overlay is open, and what it shows. */
    private data class Shown(val open: Boolean, val text: String)

    private val store = MutableStateFlow(Shown(open = false, text = "Looking"))

    @Test
    fun aDialogFollowsAScreenWhoseStoreAnswersAsItShows() = runComposeUiTest {
        overScreen { text -> ModalOverlay(title = "Dialog", onDismiss = {}) { Text(text) } }
        assertFollows()
    }

    @Test
    fun aSheetFollowsAScreenWhoseStoreAnswersAsItShows() = runComposeUiTest {
        overScreen { text -> PlezySheet(onDismiss = {}) { Text(text) } }
        assertFollows()
    }

    private fun ComposeUiTest.assertFollows() {
        store.update { it.copy(open = true) }
        onNodeWithText("Found").assertExists()
        onNodeWithText("Looking").assertDoesNotExist()

        store.update { it.copy(text = "Changed") }
        onNodeWithText("Changed").assertExists()
    }

    /** The screen over [store], in a composition of its own under the overlay host, showing [overlay] while open. */
    private fun ComposeUiTest.overScreen(overlay: @Composable (text: String) -> Unit) = setContent {
        PlezyTheme {
            OverlayHostBox(Modifier.fillMaxSize()) {
                BoxWithConstraints {
                    val shown by store.collectAsState()
                    if (shown.open) {
                        overlay(shown.text)
                        // The store answers once the overlay is handed to the host, before the host first draws it.
                        SideEffect { store.update { if (it.text == "Looking") it.copy(text = "Found") else it } }
                    }
                }
            }
        }
    }
}

package com.edde746.plezy.ui.downloads

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsSelected
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.downloads.DownloadDialog
import com.edde746.plezy.presentation.downloads.DownloadDialogIcon
import com.edde746.plezy.presentation.downloads.DownloadDialogOption
import com.edde746.plezy.presentation.downloads.DownloadDialogSwitch
import com.edde746.plezy.presentation.downloads.DownloadDialogs
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.menu.LocalMenuAnchor
import com.edde746.plezy.ui.menu.MenuAnchor
import com.edde746.plezy.ui.menu.anchorsMenus
import com.edde746.plezy.ui.menu.atMenuAnchor
import com.edde746.plezy.ui.menu.trackMenuAnchor
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.async
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** A download's choices ([DownloadDialog.Options]) as a menu: a pick answers the question with the switch as it stands. */
@OptIn(ExperimentalTestApi::class, kotlinx.coroutines.DelicateCoroutinesApi::class, kotlinx.coroutines.ExperimentalCoroutinesApi::class)
class DownloadOptionsMenuTest {
    private val dialogs = DownloadDialogs()
    private val question = DownloadDialog.Options(
        "Download",
        listOf(DownloadDialogOption("All episodes", DownloadDialogIcon.DOWNLOAD), DownloadDialogOption("Unwatched only", DownloadDialogIcon.UNWATCHED)),
        toggle = DownloadDialogSwitch("Include specials", false, DownloadDialogIcon.SPECIALS),
    )

    @Test
    fun theSwitchTurnsOverInTheOpenMenuAndAPickAnswersWithIt() = runComposeUiTest {
        val answer = GlobalScope.async(Dispatchers.Unconfined, CoroutineStart.UNDISPATCHED) { dialogs.pickOption(question) }
        menu()
        entry("Include specials").performClick()
        entry("Include specials").assertIsSelected()
        entry("Unwatched only").performClick()
        waitUntil { answer.isCompleted }
        assertEquals(1 to true, answer.getCompleted())
        onNodeWithText("All episodes").assertDoesNotExist()
    }

    @Test
    fun onTvTheChoicesAreASidePanelAndAPickAnswers() = runComposeUiTest {
        val answer = GlobalScope.async(Dispatchers.Unconfined, CoroutineStart.UNDISPATCHED) { dialogs.pickOption(question) }
        menu(FormFactor.TV)
        entry("All episodes").performClick()
        waitUntil { answer.isCompleted }
        assertEquals(0 to false, answer.getCompleted())
    }

    @Test
    fun theChoicesOpenUnderTheButtonPressedForThem() = runComposeUiTest {
        val anchor = MenuAnchor()
        setContent {
            PlezyTheme {
                AdaptiveLayout(FormFactor.DESKTOP) {
                    OverlayHostBox(Modifier.fillMaxSize().trackMenuAnchor(anchor)) {
                        CompositionLocalProvider(LocalMenuAnchor provides anchor) {
                            PlezyButton(
                                "Download",
                                { GlobalScope.async(Dispatchers.Unconfined, CoroutineStart.UNDISPATCHED) { dialogs.pickOption(question) } },
                                Modifier.padding(start = 200.dp, top = 100.dp).anchorsMenus(),
                            )
                        }
                        val dialog by dialogs.dialog.collectAsState()
                        Box(Modifier.atMenuAnchor(anchor)) { DownloadOptionsMenu(dialog as? DownloadDialog.Options, dialogs) }
                    }
                }
            }
        }
        onNode(hasClickAction() and hasText("Download")).performClick()
        val button = onNode(hasClickAction() and hasText("Download")).fetchSemanticsNode().boundsInWindow
        val first = entry("All episodes").fetchSemanticsNode().boundsInWindow
        assertTrue(first.top >= button.bottom, "the menu's first entry at ${first.top} covers the button, whose bottom is ${button.bottom}")
    }

    private fun ComposeUiTest.entry(label: String) = onNode(hasClickAction() and hasText(label))

    private fun ComposeUiTest.menu(formFactor: FormFactor = FormFactor.DESKTOP) = setContent {
        PlezyTheme {
            AdaptiveLayout(formFactor) {
                OverlayHostBox(Modifier.fillMaxSize()) {
                    val dialog by dialogs.dialog.collectAsState()
                    Box { DownloadOptionsMenu(dialog as? DownloadDialog.Options, dialogs) }
                }
            }
        }
    }
}

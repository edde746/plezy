package com.edde746.plezy.ui.components

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.presentation.downloads.DownloadDialog
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.TvFrame
import com.edde746.plezy.ui.downloads.DownloadDialogView
import kotlin.test.Test
import kotlin.test.assertEquals

/** A question opens on Cancel, so Enter answers no: a destructive step is never one key press away. */
@OptIn(ExperimentalTestApi::class)
class ConfirmDialogTest {
    private val answers = mutableListOf<String>()
    private var open by mutableStateOf(true)

    @Test
    fun aQuestionOpensOnCancelAndEnterCancels() = runComposeUiTest {
        setContent {
            TvFrame {
                if (open) {
                    ConfirmDialog(
                        "Delete preset?",
                        "This can't be undone.",
                        T.common.delete,
                        onConfirm = { answer("confirm") },
                        onCancel = { answer("cancel") },
                        probe = "test.confirm",
                    )
                }
            }
        }
        waitForIdle()
        onNodeWithText(T.common.cancel).assertIsFocused()
        press(Key.Enter)
        assertEquals(listOf("cancel"), answers)
    }

    /** Deleting a download asked first: it opens on Cancel too, and Enter keeps the download. */
    @Test
    fun theDownloadDeleteQuestionOpensOnCancel() = runComposeUiTest {
        val question = DownloadDialog.Confirm(T.downloads.deleteDownload, T.downloads.deleteConfirm(title = "Alien"), T.common.delete, destructive = true)
        setContent {
            TvFrame {
                if (open) DownloadDialogView(question, onToggle = {}, onSubmitCount = {}, onConfirm = { answer("confirm") }, onCancel = { answer("cancel") })
            }
        }
        waitForIdle()
        onNodeWithText(T.common.cancel).assertIsFocused()
        press(Key.Enter)
        assertEquals(listOf("cancel"), answers)
    }

    private fun answer(answer: String) {
        answers += answer
        open = false
    }

    private fun ComposeUiTest.press(key: Key) {
        onRoot().performKeyInput { pressKey(key) }
        waitForIdle()
    }
}

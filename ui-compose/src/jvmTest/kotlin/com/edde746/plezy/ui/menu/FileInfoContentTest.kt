package com.edde746.plezy.ui.menu

import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.platform.ClipboardManager
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.getUnclippedBoundsInRoot
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.performSemanticsAction
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.MediaFileInfo
import com.edde746.plezy.model.MediaFilePart
import com.edde746.plezy.model.MediaFileVersion
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals

@OptIn(ExperimentalTestApi::class)
class FileInfoContentTest {
    private val path = "/media/movies/Example Movie (2026)/Example Movie.mkv"
    private val info = MediaFileInfo(listOf(MediaFileVersion(parts = listOf(MediaFilePart(filePath = path, fileSize = 1_048_576, container = "mkv")))))
    private val clipboard = object : ClipboardManager {
        var text: String? = null

        override fun getText() = text?.let(::AnnotatedString)

        override fun setText(annotatedString: AnnotatedString) {
            text = annotatedString.text
        }
    }

    /** A tap on the path copies all of it and says so. */
    @Test
    fun tappingThePathCopiesItAndConfirms() = runComposeUiTest {
        content(480.dp)
        onNodeWithText(T.fileInfo.pathCopied).assertDoesNotExist()
        onNodeWithText(path).performClick()
        runOnIdle { assertEquals(path, clipboard.text) }
        onNodeWithText(T.fileInfo.pathCopied).assertExists()
    }

    /** Select on the focused path (a keyboard's Enter, a remote's centre) copies it too. */
    @Test
    fun selectOnTheFocusedPathCopiesIt() = runComposeUiTest {
        content(480.dp)
        onNodeWithText(path).performSemanticsAction(SemanticsActions.RequestFocus)
        onNodeWithText(path).performKeyInput { pressKey(Key.Enter) }
        runOnIdle { assertEquals(path, clipboard.text) }
    }

    /** Wide enough for two 220 point columns beside the gap, fields pair up; narrower, they stack. */
    @Test
    fun theFieldGridHasTwoColumnsWhenWide() = runComposeUiTest {
        content(520.dp)
        val name = onNodeWithText(T.fileInfo.fileName).getUnclippedBoundsInRoot()
        val size = onNodeWithText(T.fileInfo.size).getUnclippedBoundsInRoot()
        assertEquals(name.top, size.top, "side by side")
        assertNotEquals(name.left, size.left)
    }

    @Test
    fun theFieldGridHasOneColumnWhenNarrow() = runComposeUiTest {
        content(400.dp)
        val name = onNodeWithText(T.fileInfo.fileName).getUnclippedBoundsInRoot()
        val size = onNodeWithText(T.fileInfo.size).getUnclippedBoundsInRoot()
        assertEquals(name.left, size.left, "one column")
        assertNotEquals(name.top, size.top)
    }

    private fun ComposeUiTest.content(width: Dp) = setContent { Content(width) }

    @Composable
    private fun Content(width: Dp) {
        PlezyTheme {
            CompositionLocalProvider(LocalClipboardManager provides clipboard) {
                FileInfoContent(info, "", "fileInfo", Modifier.width(width))
            }
        }
    }
}

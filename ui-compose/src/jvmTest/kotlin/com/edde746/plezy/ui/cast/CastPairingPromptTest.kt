package com.edde746.plezy.ui.cast

import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.navigationevent.DirectNavigationEventInput
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.cast.CastPairingPrompt
import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * The receiver's pairing question: the sender's name, the code and what to check; on TV Allow has focus first, so
 * Select allows; Don't Allow and Back refuse.
 */
@OptIn(ExperimentalTestApi::class)
class CastPairingPromptTest {
    private val answers = mutableListOf<String>()
    private val back = DirectNavigationEventInput()
    private val prompt = CastPairingPrompt("Pixel 8", "4821", T.cast.pairing.receiverTitle(name = "Pixel 8"), T.cast.pairing.receiverMessage(name = "Pixel 8"))

    private fun answer(it: String) {
        answers += it
    }

    @Test
    fun `the prompt names the sender and shows the code with Allow focused first on TV`() = runComposeUiTest {
        setContent { CastFrame(FormFactor.TV) { CastPairingPromptDialog(prompt, onAllow = { answer("allow") }, onDeny = { answer("deny") }) } }
        onNodeWithText("Allow Pixel 8 to cast?").assertExists()
        onNodeWithText("4821").assertExists()
        onNodeWithText(T.cast.pairing.receiverMessage(name = "Pixel 8")).assertExists()
        onNodeWithText(T.cast.pairing.allow).assertIsFocused()
        onRoot().performKeyInput { pressKey(Key.Enter) }
        runOnIdle { assertEquals(listOf("allow"), answers) }
    }

    @Test
    fun `Dont Allow refuses`() = runComposeUiTest {
        setContent { CastFrame(FormFactor.DESKTOP) { CastPairingPromptDialog(prompt, onAllow = { answer("allow") }, onDeny = { answer("deny") }) } }
        onNodeWithText(T.cast.pairing.deny).performClick()
        runOnIdle { assertEquals(listOf("deny"), answers) }
    }

    @Test
    fun `Back refuses`() = runComposeUiTest {
        setContent { CastFrame(FormFactor.TV, back) { CastPairingPromptDialog(prompt, onAllow = { answer("allow") }, onDeny = { answer("deny") }) } }
        onNodeWithText(T.cast.pairing.allow).assertIsFocused()
        runOnIdle { back.backCompleted() }
        runOnIdle { assertEquals(listOf("deny"), answers) }
    }
}

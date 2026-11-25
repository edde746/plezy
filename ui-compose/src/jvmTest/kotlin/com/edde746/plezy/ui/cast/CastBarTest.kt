package com.edde746.plezy.ui.cast

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.cast.CastLinkStatus
import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * The now-playing bar over states built here: what the receiver plays and where, play or pause, Disconnect and a tap
 * on it reaching the sender; the device over "Ready to cast" while nothing plays; nothing while not casting.
 */
@OptIn(ExperimentalTestApi::class)
class CastBarTest {
    private val sent = SentIntents()

    @Test
    fun `the bar shows what plays where and its buttons and a tap reach the sender`() = runComposeUiTest {
        setContent { CastFrame(FormFactor.HANDHELD) { CastBar(casting(), sent.intents) } }
        onNodeWithText("Maestro Episode 2").assertExists()
        onNodeWithText("Casting to Living Room TV").assertExists()
        onNodeWithContentDescription(T.common.pause).performClick()
        onNodeWithContentDescription(T.cast.controls.disconnect).performClick()
        onNodeWithText("Maestro Episode 2").performClick()
        runOnIdle { assertEquals(listOf("togglePause", "disconnect", "openControls"), sent.sent) }
    }

    @Test
    fun `paused it offers play and with nothing playing it reads ready with no play button`() = runComposeUiTest {
        var state by mutableStateOf(casting(nowPlaying(paused = true)))
        setContent { CastFrame(FormFactor.HANDHELD) { CastBar(state, sent.intents) } }
        onNodeWithContentDescription(T.common.play).assertExists()
        state = casting(playing = null)
        onNodeWithText(T.cast.bar.ready).assertExists()
        onNodeWithText("Living Room TV").assertExists()
        onNodeWithText("Casting to Living Room TV").assertDoesNotExist()
        onNodeWithContentDescription(T.common.play).assertDoesNotExist()
        onNodeWithContentDescription(T.common.pause).assertDoesNotExist()
        onNodeWithContentDescription(T.cast.controls.disconnect).assertExists()
    }

    @Test
    fun `no bar while connecting or on this device`() = runComposeUiTest {
        var state by mutableStateOf(casting().copy(status = CastLinkStatus.CONNECTING))
        setContent { CastFrame(FormFactor.HANDHELD) { CastBar(state, sent.intents) } }
        onNodeWithText("Casting to Living Room TV").assertDoesNotExist()
        state = casting().copy(target = null, status = CastLinkStatus.IDLE)
        onNodeWithText("Casting to Living Room TV").assertDoesNotExist()
    }
}

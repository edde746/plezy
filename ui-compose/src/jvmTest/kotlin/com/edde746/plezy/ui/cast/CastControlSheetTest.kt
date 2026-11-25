package com.edde746.plezy.ui.cast

import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.requestFocus
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.navigationevent.DirectNavigationEventInput
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * The control sheet over states built here: every control the receiver offers and each reaching the sender, the volume
 * only where the receiver has one, the skips only where it can seek, "Ready to cast" with Disconnect while nothing
 * plays, Back closing it.
 */
@OptIn(ExperimentalTestApi::class)
class CastControlSheetTest {
    private val sent = SentIntents()
    private val back = DirectNavigationEventInput()

    @Test
    fun `the transport and Stop and Disconnect reach the sender`() = runComposeUiTest {
        setContent { CastFrame(FormFactor.DESKTOP) { CastControlSheet(livingRoom.name, nowPlaying(), null, sent.intents) } }
        onNodeWithText("Casting to Living Room TV").assertExists()
        onNodeWithText("Maestro Episode 2").assertExists()
        onNodeWithText("1:10").assertExists()
        onNodeWithText("1:30").assertExists()
        onNodeWithContentDescription(T.cast.controls.previous).assertIsNotEnabled()
        onNodeWithContentDescription(T.cast.controls.next).assertIsEnabled().performClick()
        onNodeWithContentDescription(T.cast.controls.seekBack).performClick()
        onNodeWithContentDescription(T.common.pause).performClick()
        onNodeWithContentDescription(T.cast.controls.seekForward).performClick()
        onNodeWithText(T.cast.controls.stop).performScrollTo().performClick()
        onNodeWithText(T.cast.controls.disconnect).performScrollTo().performClick()
        runOnIdle { assertEquals(listOf("next", "seekBy -10.0", "togglePause", "seekBy 10.0", "stop", "disconnect"), sent.sent) }
    }

    @Test
    fun `the track and quality rows show the choice in effect and a pick reaches the sender`() = runComposeUiTest {
        setContent { CastFrame(FormFactor.DESKTOP) { CastControlSheet(livingRoom.name, nowPlaying(), null, sent.intents) } }
        onNodeWithText("Original").assertExists()
        onNodeWithText(T.cast.controls.audio).performScrollTo().performClick()
        onNodeWithText("German").performClick()
        onNodeWithText(T.cast.controls.quality).performScrollTo().performClick()
        onNodeWithText("720p 4 Mbps").performClick()
        runOnIdle { assertEquals(listOf("selectAudio a2", "selectQuality 720"), sent.sent) }
    }

    @Test
    fun `the volume shows only where the receiver has one and the skips only where it can seek`() = runComposeUiTest {
        setContent { CastFrame(FormFactor.HANDHELD) { CastControlSheet(livingRoom.name, nowPlaying(volume = null, canSeek = false), null, sent.intents) } }
        onNodeWithContentDescription(T.cast.controls.volume).assertDoesNotExist()
        onNodeWithContentDescription(T.cast.controls.seekBack).assertDoesNotExist()
        onNodeWithContentDescription(T.cast.controls.seekForward).assertDoesNotExist()
        onNodeWithContentDescription(T.common.pause).assertExists()
    }

    @Test
    fun `Right on the volume raises the receivers volume a step`() = runComposeUiTest {
        setContent { CastFrame(FormFactor.TV) { CastControlSheet(livingRoom.name, nowPlaying(volume = 40), null, sent.intents) } }
        onNodeWithContentDescription(T.common.pause).assertIsFocused()
        onNodeWithContentDescription(T.cast.controls.volume).performScrollTo().requestFocus().performKeyInput { pressKey(Key.DirectionRight) }
        runOnIdle { assertEquals(listOf("setVolume 45"), sent.sent) }
    }

    @Test
    fun `with nothing playing it reads ready with Disconnect focused`() = runComposeUiTest {
        setContent { CastFrame(FormFactor.TV) { CastControlSheet(livingRoom.name, null, T.cast.bar.ready, sent.intents) } }
        onNodeWithText(T.cast.bar.ready).assertExists()
        onNodeWithText(T.cast.controls.stop).assertDoesNotExist()
        onNodeWithText(T.cast.controls.disconnect).assertIsFocused()
    }

    @Test
    fun `Back closes the sheet`() = runComposeUiTest {
        setContent { CastFrame(FormFactor.TV, back) { CastControlSheet(livingRoom.name, nowPlaying(), null, sent.intents) } }
        onNodeWithContentDescription(T.common.pause).assertIsFocused()
        runOnIdle { back.backCompleted() }
        runOnIdle { assertEquals(listOf("closeControls"), sent.sent) }
    }
}

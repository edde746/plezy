package com.edde746.plezy.ui.cast

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.assertIsSelected
import androidx.compose.ui.test.assertIsNotSelected
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.navigationevent.DirectNavigationEventInput
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.cast.CastPairingCode
import com.edde746.plezy.presentation.cast.CastPickerUiState
import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * The device picker over states built here: This device and the receivers found, each with what it says under its
 * name; the look while searching and once nothing was found; the pairing step's code and Cancel; a choice, This device,
 * Back and Cancel reaching the sender.
 */
@OptIn(ExperimentalTestApi::class)
class CastPickerTest {
    private val sent = SentIntents()
    private val back = DirectNavigationEventInput()

    private fun picker(
        devices: List<com.edde746.plezy.presentation.cast.CastDeviceRow> = listOf(row(livingRoom, nowPlaying = "Playing Resume Movie"), row(study)),
        thisDevice: Boolean = true,
        searching: Boolean = false,
        pairing: CastPairingCode? = null,
    ) = CastPickerUiState(fromPlayer = false, devices = devices, thisDeviceSelected = thisDevice, searching = searching, pairing = pairing)

    @Test
    fun `the picker lists this device then each receiver with its platform or what it plays`() = runComposeUiTest {
        setContent { CastFrame(FormFactor.HANDHELD) { CastPicker(picker(), sent.intents) } }
        onNodeWithText(T.cast.picker.title).assertExists()
        onNodeWithText(T.cast.picker.thisDevice).assertIsSelected()
        onNodeWithText("Living Room TV").assertIsNotSelected()
        onNodeWithText("Playing Resume Movie").assertExists()
        onNodeWithText("Study PC").assertExists()
        onNodeWithText("Windows").assertExists()
        onNodeWithText(T.cast.picker.empty).assertDoesNotExist()
    }

    @Test
    fun `a receiver and this device reach the sender as they are chosen`() = runComposeUiTest {
        setContent { CastFrame(FormFactor.DESKTOP) { CastPicker(picker(), sent.intents) } }
        onNodeWithText("Study PC").performClick()
        onNodeWithText(T.cast.picker.thisDevice).performClick()
        runOnIdle { assertEquals(listOf("choose pc1", "chooseThisDevice"), sent.sent) }
    }

    @Test
    fun `a receiver connecting says so and the target carries the check`() = runComposeUiTest {
        var state by mutableStateOf(picker(devices = listOf(row(livingRoom, selected = true, connecting = true)), thisDevice = false))
        // The spinner never stops: the clock moves only as told.
        mainClock.autoAdvance = false
        setContent { CastFrame(FormFactor.HANDHELD) { CastPicker(state, sent.intents) } }
        mainClock.advanceTimeBy(1_000)
        onNodeWithText(T.cast.picker.connecting).assertExists()
        onNodeWithText("Living Room TV").assertIsNotSelected()
        state = picker(devices = listOf(row(livingRoom, selected = true)), thisDevice = false)
        mainClock.advanceTimeBy(1_000)
        onNodeWithText(T.cast.picker.connecting).assertDoesNotExist()
        onNodeWithText("Living Room TV").assertIsSelected()
        onNodeWithText(T.cast.picker.thisDevice).assertIsNotSelected()
    }

    @Test
    fun `while it looks it says so and once it found nothing it says how to make a device show`() = runComposeUiTest {
        var state by mutableStateOf(picker(devices = emptyList(), searching = true))
        mainClock.autoAdvance = false
        setContent { CastFrame(FormFactor.HANDHELD) { CastPicker(state, sent.intents) } }
        mainClock.advanceTimeBy(1_000)
        onNodeWithText(T.cast.picker.searching).assertExists()
        onNodeWithText(T.cast.picker.empty).assertDoesNotExist()
        state = picker(devices = emptyList(), searching = false)
        mainClock.advanceTimeBy(1_000)
        onNodeWithText(T.cast.picker.searching).assertDoesNotExist()
        onNodeWithText(T.cast.picker.empty).assertExists()
        onNodeWithText(T.cast.picker.thisDevice).assertExists()
    }

    @Test
    fun `pairing shows the code with Cancel focused and Cancel closes the picker`() = runComposeUiTest {
        val pairing = CastPairingCode("Living Room TV", "4821", T.cast.pairing.senderTitle(name = "Living Room TV"), T.cast.pairing.senderMessage(name = "Living Room TV"))
        setContent { CastFrame(FormFactor.TV) { CastPicker(picker(devices = listOf(row(livingRoom, connecting = true)), pairing = pairing), sent.intents) } }
        onNodeWithText("Confirm on Living Room TV").assertExists()
        onNodeWithText("4821").assertExists()
        onNodeWithText(T.cast.pairing.senderMessage(name = "Living Room TV")).assertExists()
        onNodeWithText("Living Room TV").assertDoesNotExist()
        onNodeWithText(T.common.cancel).assertIsFocused()
        onRoot().performKeyInput { pressKey(Key.Enter) }
        runOnIdle { assertEquals(listOf("closePicker"), sent.sent) }
    }

    @Test
    fun `a refusal shows in the picker over the devices`() = runComposeUiTest {
        val refused = T.cast.errors.pairingRefused(name = "Living Room TV")
        setContent { CastFrame(FormFactor.HANDHELD) { CastPicker(picker(), sent.intents, notice = refused) } }
        onNodeWithText(refused).assertExists()
        onNodeWithText(T.cast.picker.thisDevice).assertIsSelected()
    }

    @Test
    fun `Back closes the picker`() = runComposeUiTest {
        setContent { CastFrame(FormFactor.TV, back) { CastPicker(picker(), sent.intents) } }
        onNodeWithText(T.cast.picker.thisDevice).assertIsFocused()
        runOnIdle { back.backCompleted() }
        runOnIdle { assertEquals(listOf("closePicker"), sent.sent) }
    }
}

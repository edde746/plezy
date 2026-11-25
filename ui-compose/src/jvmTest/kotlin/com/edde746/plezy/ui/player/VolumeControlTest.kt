package com.edde746.plezy.ui.player

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performMouseInput
import androidx.compose.ui.test.requestFocus
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.player.VolumeState
import com.edde746.plezy.strings.T
import kotlin.math.abs
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** Desktop's volume control: mute and a 100 dp slider, the keys through mute, the wheel through the player. */
@OptIn(ExperimentalTestApi::class)
class VolumeControlTest {
    private val commands = mutableListOf<PlayerCommand>()
    private val sixty = VolumeState(60, 0.6f, muted = false, label = "60%")

    /** Mute asks the store to mute; muted, the slider rests at zero and mute offers Unmute; unmuted, the level is back. */
    @Test
    fun muteKeepsTheLevelAndUnmuteRestoresIt() = runComposeUiTest {
        var volume by mutableStateOf(sixty)
        player(FormFactor.DESKTOP, onCommand = { commands += it }) { testPlayerState().copy(volume = volume) }
        onNodeWithContentDescription(T.videoControls.muteButton).performClick()
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.ToggleMute), commands) }
        volume = VolumeState(60, 0.6f, muted = true, label = "Muted")
        slider().assert(progress(0f))
        onNodeWithContentDescription(T.videoControls.unmuteButton).performClick()
        volume = sixty
        slider().assert(progress(0.6f))
        onNodeWithContentDescription(T.videoControls.muteButton).assertExists()
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.ToggleMute, PlayerCommand.ToggleMute), commands) }
    }

    /**
     * With the keyboard on mute, Enter starts adjusting and each Right steps 5 % from the last step's level, before the
     * store has answered any of them; Enter stops, and Right then moves nothing. Enter never mutes.
     */
    @Test
    fun keyRepeatsAccumulateBeforeTheStoreAnswers() = runComposeUiTest {
        player(FormFactor.DESKTOP, onCommand = { commands += it }) { testPlayerState().copy(volume = sixty) }
        onNodeWithContentDescription(T.videoControls.muteButton).requestFocus()
        press(Key.Enter)
        repeat(3) { press(Key.DirectionRight) }
        runOnIdle { assertEquals(listOf(65.0, 70.0, 75.0), volumes()) }
        press(Key.DirectionLeft)
        press(Key.Enter)
        press(Key.DirectionRight)
        runOnIdle {
            assertEquals(listOf(65.0, 70.0, 75.0, 70.0), volumes(), "Right after Enter stopped adjusting")
            assertTrue(PlayerCommand.ToggleMute !in commands, "Enter adjusts, it doesn't mute")
        }
    }

    /** A drag previews the level at each step, in order, and its last one is where it was let go. */
    @Test
    fun aDragPreviewsEachStepAndEndsWhereItWasLetGo() = runComposeUiTest {
        player(FormFactor.DESKTOP, onCommand = { commands += it }) { testPlayerState().copy(volume = sixty) }
        slider().performMouseInput {
            moveTo(centerLeft)
            press()
            moveTo(center)
            moveTo(percentOffset(0.8f, 0.5f))
            release()
        }
        runOnIdle {
            val sent = volumes()
            assertTrue(sent.size >= 2, "previews $sent")
            assertTrue(sent.first() < sent.last(), "previews in order: $sent")
            assertTrue(sent.last() in 65.0..95.0, "let go at ${sent.last()}")
        }
    }

    /** The wheel over the slider goes to the player once, as over the video; the slider doesn't move for it. */
    @Test
    fun theWheelOverTheSliderGoesToThePlayerOnce() = runComposeUiTest {
        val events = mutableListOf<InputEvent>()
        player(FormFactor.DESKTOP, onCommand = { commands += it }, onInput = { events += it; it is InputEvent.Wheel }) {
            testPlayerState().copy(volume = sixty)
        }
        slider().performMouseInput {
            moveTo(center)
            scroll(-1f)
        }
        runOnIdle {
            assertEquals(1, events.count { it is InputEvent.Wheel }, "$events")
            assertTrue(volumes().isEmpty(), "the slider moved: ${volumes()}")
        }
    }

    private fun volumes() = commands.filterIsInstance<PlayerCommand.SetVolume>().map { it.percent }

    private fun progress(value: Float) = SemanticsMatcher("progress $value") {
        val info = it.config.getOrElseNullable(SemanticsProperties.ProgressBarRangeInfo) { null } ?: return@SemanticsMatcher false
        abs(info.current - value) < 0.01f
    }

    private fun ComposeUiTest.slider() =
        onNode(SemanticsMatcher.keyIsDefined(SemanticsActions.SetProgress) and hasContentDescription(T.videoControls.volumeSlider))
}

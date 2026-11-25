package com.edde746.plezy.ui.player

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.semantics.ProgressBarRangeInfo
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.assertIsNotSelected
import androidx.compose.ui.test.assertIsSelected
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.isFocused
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performSemanticsAction
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals

/** The speed page of the settings and the custom speed's control it opens. */
@OptIn(ExperimentalTestApi::class)
class PlayerSpeedTest {
    private fun row(label: String) = hasText(label) and hasClickAction()

    /**
     * The page lists the six common speeds and Custom, nothing faster than 2×; Normal is checked and takes focus. A
     * preset's pick sends its speed, Custom's opens the custom speed.
     */
    @Test
    fun theSpeedPageOffersSixSpeedsAndCustom() {
        for (formFactor in listOf(FormFactor.HANDHELD, FormFactor.DESKTOP, FormFactor.TV)) runComposeUiTest {
            val commands = mutableListOf<PlayerCommand>()
            player(formFactor, onCommand = { commands += it }) { testPlayerState(menu = PlayerMenu.SPEED).copy(options = listOf(testSpeedOption(1.0))) }
            for (label in listOf("0.5×", "0.75×", T.player.speed.normal, "1.25×", "1.5×", "2×", T.player.speed.custom)) {
                onNode(row(label)).assertIsDisplayed()
            }
            onNode(row("2.5×")).assertDoesNotExist()
            onNode(row(T.player.speed.normal)).assertIsSelected().assertIsFocused()
            onNode(row(T.player.speed.custom)).assertIsNotSelected()
            onNode(row("1.5×")).performClick()
            onNode(row(T.player.speed.custom)).performClick()
            runOnIdle {
                assertEquals(listOf(PlayerCommand.SetSpeed(1.5), PlayerCommand.OpenMenu(PlayerMenu.CUSTOM_SPEED)), commands, "$formFactor")
            }
        }
    }

    /** A speed that is none of the presets shows under Custom, which is checked and takes focus; no preset is. */
    @Test
    fun aSpeedOffThePresetsIsCheckedUnderCustom() = runComposeUiTest {
        player(FormFactor.TV) { testPlayerState(menu = PlayerMenu.SPEED).copy(options = listOf(testSpeedOption(2.4))) }
        onNode(row(T.player.speed.customValue("2.4×"))).assertIsSelected().assertIsFocused()
        onNode(row(T.player.speed.normal)).assertIsNotSelected()
        onNode(row("2×")).assertIsNotSelected()
    }

    /**
     * The control shows the speed and names − and + Slower and Faster, which send a step each way; Normal shows at every
     * speed, disabled at 1× and enabled away from it, where it sends 1×.
     */
    @Test
    fun theCustomSpeedStepsShowsTheSpeedAndGoesBackToNormal() {
        for (formFactor in listOf(FormFactor.HANDHELD, FormFactor.DESKTOP, FormFactor.TV)) runComposeUiTest {
            val commands = mutableListOf<PlayerCommand>()
            var custom by mutableStateOf(testCustomSpeed(1.0, "1×"))
            player(formFactor, onCommand = { commands += it }) { testPlayerState(menu = PlayerMenu.CUSTOM_SPEED).copy(customSpeed = custom) }
            onNodeWithText(T.player.speed.customTitle).assertIsDisplayed()
            onNodeWithText("1×").assertIsDisplayed()
            val normal = onNode(row(T.player.speed.normal))
            normal.assertIsDisplayed().assertIsNotEnabled()
            custom = testCustomSpeed(2.4, "2.4×")
            onNodeWithText("2.4×").assertIsDisplayed()
            onNodeWithContentDescription(T.player.speed.slower).performClick()
            onNodeWithContentDescription(T.player.speed.faster).performClick()
            normal.assertIsEnabled().performClick()
            runOnIdle {
                assertEquals(listOf<PlayerCommand>(PlayerCommand.SetSpeed(2.35), PlayerCommand.SetSpeed(2.45), PlayerCommand.SetSpeed(1.0)), commands, "$formFactor")
            }
        }
    }

    /** The slider spans the player's whole range, half speed to eight times, and sets the speed on its grid as it moves. */
    @Test
    fun theSliderSpansTheWholeRangeAndSetsTheSpeedAsItMoves() = runComposeUiTest {
        val commands = mutableListOf<PlayerCommand>()
        player(FormFactor.DESKTOP, onCommand = { commands += it }) { testPlayerState(menu = PlayerMenu.CUSTOM_SPEED) }
        val slider = onNodeWithContentDescription(T.player.speed.customTitle)
            .assert(SemanticsMatcher.expectValue(SemanticsProperties.ProgressBarRangeInfo, ProgressBarRangeInfo(1f, 0.5f..8f)))
        slider.performSemanticsAction(SemanticsActions.SetProgress) { it(3.02f) }
        slider.performSemanticsAction(SemanticsActions.SetProgress) { it(9f) }
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.SetSpeed(3.0), PlayerCommand.SetSpeed(8.0)), commands) }
    }

    /**
     * On TV the slider takes focus as the control opens and D-pad left and right step the speed; Up reaches − and +, Down
     * Normal, which Select picks.
     */
    @Test
    fun onTvTheSliderHasFocusTheDpadStepsAndReachesTheButtons() = runComposeUiTest {
        val commands = mutableListOf<PlayerCommand>()
        player(FormFactor.TV, onCommand = { commands += it }) { testPlayerState(menu = PlayerMenu.CUSTOM_SPEED).copy(customSpeed = testCustomSpeed(2.4, "2.4×")) }
        onNodeWithContentDescription(T.player.speed.customTitle).assertIsFocused()
        press(Key.DirectionRight)
        press(Key.DirectionLeft)
        press(Key.DirectionUp)
        onNode(isFocused() and (hasContentDescription(T.player.speed.slower) or hasContentDescription(T.player.speed.faster))).assertExists()
        press(Key.DirectionDown)
        press(Key.DirectionDown)
        onNode(row(T.player.speed.normal)).assertIsFocused()
        press(Key.DirectionCenter)
        runOnIdle {
            assertEquals(listOf<PlayerCommand>(PlayerCommand.SetSpeed(2.45), PlayerCommand.SetSpeed(2.35), PlayerCommand.SetSpeed(1.0)), commands)
        }
    }
}

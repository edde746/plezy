package com.edde746.plezy.ui.player

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.semantics.ProgressBarRangeInfo
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.performSemanticsAction
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** The audio and subtitle delay control, a page of its track menu or the settings. */
@OptIn(ExperimentalTestApi::class)
class PlayerDelayTest {
    /**
     * The control (a sheet on phones and TV, the panel on the desktop) names − and + by the way they move the delay,
     * which screen readers say and find them by, and sends the delay's steps; it shows the applied delay. Reset shows at
     * every delay: disabled at zero, enabled once it moved, where it sends the reset.
     */
    @Test
    fun theDelayControlStepsShowsTheDelayAndResetsAwayFromZero() {
        for (formFactor in listOf(FormFactor.HANDHELD, FormFactor.DESKTOP, FormFactor.TV)) {
            for (subtitles in listOf(true, false)) runComposeUiTest {
                val commands = mutableListOf<PlayerCommand>()
                val delay = testDelay(subtitles)
                var moved by mutableStateOf(false)
                player(formFactor, onCommand = { commands += it }) {
                    testPlayerState(menu = delay.menu).copy(subtitleDelay = testDelay(true, moved), audioDelay = testDelay(false, moved))
                }
                onNodeWithText(delay.label).assertIsDisplayed()
                val reset = onNodeWithText(T.player.menu.reset)
                reset.assertIsDisplayed().assertIsNotEnabled()
                onNodeWithContentDescription(delay.decreaseLabel).performClick()
                onNodeWithContentDescription(delay.increaseLabel).performClick()
                moved = true
                onNodeWithText("+0.1 s").assertIsDisplayed()
                reset.assertIsEnabled().performClick()
                runOnIdle { assertEquals(listOf(delay.decrease, delay.increase, delay.reset), commands, "${delay.menu} on $formFactor") }
            }
        }
    }

    /** Held, − steps the offset back a whole second at once and every 200 ms until let go, with no step at its release. */
    @Test
    fun aHeldMinusRepeatsWholeSeconds() = runComposeUiTest {
        val commands = mutableListOf<PlayerCommand>()
        val delay = testDelay(subtitles = false)
        player(FormFactor.HANDHELD, onCommand = { commands += it }) { testPlayerState(menu = delay.menu) }
        val minus = onNodeWithContentDescription(delay.decreaseLabel)
        mainClock.autoAdvance = false
        minus.performTouchInput { down(center) }
        // Past any long-press timeout (500 ms on TV, 400 ms on touch), then three repeats.
        mainClock.advanceTimeBy(1_000 + 3 * RepeatMillis)
        minus.performTouchInput { up() }
        mainClock.autoAdvance = true
        waitForIdle()
        runOnIdle {
            assertEquals(listOf<PlayerCommand>(PlayerCommand.AdjustAudioDelay(-RepeatSeconds)), commands.distinct(), "only whole seconds")
            assertTrue(commands.size >= 3, "repeated: $commands")
        }
    }

    /**
     * On TV the slider takes focus as the control opens; D-pad left and right step the delay by its step (10 ms audio,
     * 50 ms subtitles: the store's [com.edde746.plezy.presentation.player.DelayState.decrease] and increase).
     */
    @Test
    fun onTvTheSliderHasFocusAndTheDpadSteps() = runComposeUiTest {
        val commands = mutableListOf<PlayerCommand>()
        val delay = testDelay(subtitles = true)
        player(FormFactor.TV, onCommand = { commands += it }) { testPlayerState(menu = delay.menu) }
        onNodeWithContentDescription(delay.title).assertIsFocused()
        press(Key.DirectionLeft)
        press(Key.DirectionRight)
        runOnIdle { assertEquals(listOf(delay.decrease, delay.increase), commands) }
    }

    /** The slider spans ±10 s; let go, it sets the delay where it stopped, on the delay's step grid. */
    @Test
    fun theSliderSetsTheDelayWhereItIsLetGo() = runComposeUiTest {
        val commands = mutableListOf<PlayerCommand>()
        val delay = testDelay(subtitles = false)
        player(FormFactor.DESKTOP, onCommand = { commands += it }) { testPlayerState(menu = delay.menu) }
        onNodeWithContentDescription(delay.title)
            .assert(SemanticsMatcher.expectValue(SemanticsProperties.ProgressBarRangeInfo, ProgressBarRangeInfo(0f, -10f..10f)))
            .performSemanticsAction(SemanticsActions.SetProgress) { it(2.503f) }
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.SetAudioDelay(2.5)), commands) }
    }
}

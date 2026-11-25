package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.InputKey
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** The speed menu: its common speeds, Custom, and the custom speed's control. */
class SpeedTest {
    private val PlayerHarness.speedChoices: List<OptionChoice>
        get() = state.options.single { it.id == PlayerOptionId.SPEED }.choices

    @Test
    fun theSpeedMenuOffersSixCommonSpeedsThenCustom() = playerTest {
        playing()
        assertEquals(listOf("0.5×", "0.75×", "Normal", "1.25×", "1.5×", "2×", "Custom"), speedChoices.map { it.label })
        assertEquals("Normal", speedChoices.single { it.selected }.label)
        assertEquals(PlayerCommand.OpenMenu(PlayerMenu.CUSTOM_SPEED), speedChoices.last().command)

        dispatch(PlayerCommand.OpenMenu(PlayerMenu.OPTIONS))
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.SPEED))
        assertEquals(2, state.selectedEntry, "the menu opens on Normal")
        dispatch(speedChoices[4].command)
        assertEquals(1.5, engine.speeds.last())
        assertNull(state.menu, "a preset's pick closes the menu")
        assertEquals("1.5×", speedChoices.single { it.selected }.label)
        assertEquals("Custom", speedChoices.last().label)
    }

    @Test
    fun aSpeedOffThePresetsShowsUnderCustomWhichIsChecked() = playerTest {
        playing()
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.OPTIONS))
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.SPEED))
        dispatch(speedChoices.last().command)
        assertEquals(PlayerMenu.CUSTOM_SPEED, state.menu)
        assertEquals("Custom speed", state.menuTitle(PlayerMenu.CUSTOM_SPEED))
        repeat(8) { dispatch(state.customSpeed.increase) }
        assertEquals(1.4, engine.speeds.last())
        assertEquals("1.4×", state.customSpeed.label)
        assertEquals(PlayerMenu.CUSTOM_SPEED, state.menu, "the control stays open as the speed changes")
        assertNull(state.osd, "the control shows the speed itself")

        dispatch(PlayerCommand.Back)
        assertEquals(PlayerMenu.SPEED, state.menu, "Back returns to the speeds")
        assertEquals("Custom · 1.4×", speedChoices.last().label)
        assertEquals(listOf("Custom · 1.4×"), speedChoices.filter { it.selected }.map { it.label })
        assertEquals(6, state.selectedEntry, "the menu opens on Custom")
        assertEquals("1.4×", state.options.single { it.id == PlayerOptionId.SPEED }.value)

        dispatch(PlayerCommand.OpenMenu(PlayerMenu.CUSTOM_SPEED))
        repeat(3) { dispatch(state.customSpeed.decrease) }
        assertEquals(1.25, engine.speeds.last())
        assertEquals(listOf("1.25×"), speedChoices.filter { it.selected }.map { it.label }, "a preset reached by steps is ticked as itself")
        assertEquals("Custom", speedChoices.last().label)
    }

    @Test
    fun theCustomSpeedStepsATwentiethOnItsGridWithinHalfToEightTimes() = playerTest {
        playing()
        val control = state.customSpeed
        assertEquals(listOf(0.5, 8.0, 0.05), listOf(control.min, control.max, control.step))
        assertEquals(listOf(3.0, 1.35, 2.4, 0.5, 8.0), listOf(3.02, 1.326, 2.39, 0.1, 9.0).map(control::snapped))

        dispatch(PlayerCommand.SetSpeed(0.55))
        assertTrue(state.customSpeed.canDecrease)
        dispatch(state.customSpeed.decrease)
        assertEquals(0.5, engine.speeds.last())
        assertFalse(state.customSpeed.canDecrease, "half speed is the slowest")
        assertTrue(state.customSpeed.canIncrease)

        dispatch(PlayerCommand.SetSpeed(7.95))
        dispatch(state.customSpeed.increase)
        assertEquals(8.0, engine.speeds.last())
        assertFalse(state.customSpeed.canIncrease, "eight times is the fastest")
        assertEquals("8×", state.customSpeed.label)

        assertTrue(state.customSpeed.canReset)
        dispatch(state.customSpeed.reset)
        assertEquals(1.0, engine.speeds.last())
        assertFalse(state.customSpeed.canReset, "Normal is off at Normal")
        assertEquals("1×", state.customSpeed.label, "the control shows the number")
    }

    @Test
    fun theSpeedKeysStopAtHalfAndShowTheSpeed() = playerTest {
        playing()
        press(InputKey.PLUS)
        assertEquals("Speed 1.25×", state.osd)
        assertEquals("1.25×", state.speedLabel)
        repeat(6) { press(InputKey.MINUS) }
        assertEquals(listOf(1.25, 1.0, 0.75, 0.5), engine.speeds, "the speed stops at half")
        press(InputKey.R)
        assertEquals("Normal", state.speedLabel)
    }
}

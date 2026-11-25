package com.edde746.plezy.input

import com.edde746.plezy.input.GamepadAction.Back
import com.edde746.plezy.input.GamepadAction.KeyDown
import com.edde746.plezy.input.GamepadAction.KeyUp
import com.edde746.plezy.input.GamepadAction.NonPointerInput
import com.edde746.plezy.input.GamepadAction.Tab
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals

class GamepadNavigatorTest {
    private val actions = mutableListOf<GamepadAction>()

    private fun TestScope.navigator(engineOwnsNavigation: Boolean = false) =
        GamepadNavigator(backgroundScope, engineOwnsNavigation, { testScheduler.currentTime }) { actions += it }

    private fun keys() = actions.filter { it != NonPointerInput }

    @Test
    fun aHeldDpadRepeatsAfter400MsEvery80MsAndStopsOnRelease() = runTest {
        val pad = navigator()
        pad.button(GamepadButton.DPAD_DOWN, down = true)
        runCurrent()
        assertEquals(listOf(KeyDown(InputKey.DOWN)), keys())
        advanceTimeBy(399)
        assertEquals(1, keys().size)
        advanceTimeBy(2 + 80 * 2)
        assertEquals(List(3) { KeyDown(InputKey.DOWN, repeat = true) }, keys().drop(1))
        pad.button(GamepadButton.DPAD_DOWN, down = false)
        advanceTimeBy(1_000)
        assertEquals(KeyUp(InputKey.DOWN), keys().last())
        assertEquals(5, keys().size)
    }

    @Test
    fun aAndXAreHeldKeysBIsOneBackAndShouldersChangeTabs() = runTest {
        val pad = navigator()
        for (button in listOf(GamepadButton.A, GamepadButton.X, GamepadButton.B, GamepadButton.LEFT_SHOULDER, GamepadButton.RIGHT_SHOULDER)) {
            pad.button(button, down = true)
            pad.button(button, down = false)
        }
        assertEquals(
            listOf(KeyDown(InputKey.SELECT), KeyUp(InputKey.SELECT), KeyDown(InputKey.MENU), KeyUp(InputKey.MENU), Back, Tab(next = false), Tab(next = true)),
            keys(),
        )
    }

    @Test
    fun everyPressAndAStickPastItsDeadZoneShowFocus() = runTest {
        val pad = navigator()
        pad.stick(0.4f, -0.5f)
        assertEquals(emptyList(), actions)
        pad.button(GamepadButton.B, down = true)
        assertEquals(NonPointerInput, actions.first())
        actions.clear()
        pad.stick(0f, -0.6f)
        assertEquals(listOf(NonPointerInput, KeyDown(InputKey.UP)), actions)
    }

    @Test
    fun aStickHeldPastItsDeadZoneRepeatsOnceAndRecentringStops() = runTest {
        val pad = navigator()
        pad.stick(0.7f, 0f)
        pad.stick(0.9f, 0f)
        runCurrent()
        assertEquals(listOf(KeyDown(InputKey.RIGHT)), keys())
        advanceTimeBy(401)
        assertEquals(KeyDown(InputKey.RIGHT, repeat = true), keys().last())
        pad.stick(0.2f, 0f)
        val count = keys().size
        advanceTimeBy(1_000)
        assertEquals(KeyUp(InputKey.RIGHT), keys().last())
        assertEquals(count, keys().size)
    }

    @Test
    fun disconnectStopsHeldDirectionRepeatAndReleasesHeldKeys() = runTest {
        val pad = navigator()
        pad.button(GamepadButton.A, down = true)
        pad.button(GamepadButton.DPAD_RIGHT, down = true)
        runCurrent()
        pad.disconnected()
        assertEquals(listOf(KeyUp(InputKey.RIGHT), KeyUp(InputKey.SELECT)), keys().takeLast(2))
        val count = keys().size
        advanceTimeBy(2_000)
        pad.button(GamepadButton.A, down = false)
        assertEquals(count, keys().size)
    }

    @Test
    fun disconnectClearsStickLatchesSoAReconnectedStickNavigatesAgain() = runTest {
        val pad = navigator()
        pad.stick(0f, 0.9f)
        pad.disconnected()
        actions.clear()
        pad.stick(0f, 0.9f)
        assertEquals(listOf(KeyDown(InputKey.DOWN)), keys())
    }

    @Test
    fun anUnfocusedWindowHearsNothingAndLosingFocusReleasesHeldKeys() = runTest {
        val pad = navigator()
        pad.button(GamepadButton.X, down = true)
        pad.button(GamepadButton.DPAD_UP, down = true)
        runCurrent()
        pad.windowFocused = false
        assertEquals(listOf(KeyUp(InputKey.UP), KeyUp(InputKey.MENU)), keys().takeLast(2))
        actions.clear()
        advanceTimeBy(1_000)
        pad.button(GamepadButton.A, down = true)
        pad.stick(1f, 0f)
        assertEquals(emptyList(), actions)
        pad.windowFocused = true
        pad.button(GamepadButton.A, down = true)
        assertEquals(listOf(KeyDown(InputKey.SELECT)), keys())
    }

    @Test
    fun nativeTextInputPausesTheControllerAndClearsHeldState() = runTest {
        val pad = navigator()
        pad.button(GamepadButton.DPAD_LEFT, down = true)
        pad.textInputActive = true
        actions.clear()
        pad.button(GamepadButton.A, down = true)
        assertEquals(emptyList(), actions)
        pad.textInputActive = false
        pad.button(GamepadButton.DPAD_LEFT, down = true)
        assertEquals(listOf(KeyDown(InputKey.LEFT)), keys())
    }

    @Test
    fun aButtonTheSystemAlsoTypedWithin120MsOrStillHoldsActsOnce() = runTest {
        val pad = navigator()
        pad.nativeKey(InputKey.SELECT, down = true)
        pad.nativeKey(InputKey.SELECT, down = false)
        pad.button(GamepadButton.A, down = true)
        pad.button(GamepadButton.A, down = false)
        pad.nativeKey(InputKey.ESCAPE, down = true)
        advanceTimeBy(500)
        pad.button(GamepadButton.B, down = true)
        pad.button(GamepadButton.B, down = false)
        pad.nativeKey(InputKey.ESCAPE, down = false)
        assertEquals(emptyList(), keys())
        advanceTimeBy(121)
        pad.button(GamepadButton.B, down = true)
        assertEquals(listOf(Back), keys())
    }

    @Test
    fun appleTvsFocusEngineOwnsTheDpadStickAAndB() = runTest {
        val pad = navigator(engineOwnsNavigation = true)
        for (button in listOf(GamepadButton.DPAD_UP, GamepadButton.A, GamepadButton.B)) pad.button(button, down = true)
        pad.stick(1f, 1f)
        assertEquals(emptyList(), actions)
        pad.button(GamepadButton.X, down = true)
        pad.button(GamepadButton.RIGHT_SHOULDER, down = true)
        assertEquals(listOf(KeyDown(InputKey.MENU), Tab(next = true)), keys())
    }

    @Test
    fun `releasing one held direction leaves the other repeating`() = runTest {
        val pad = navigator()
        pad.button(GamepadButton.DPAD_UP, down = true)
        pad.button(GamepadButton.DPAD_RIGHT, down = true)
        pad.button(GamepadButton.DPAD_UP, down = false)
        advanceTimeBy(401)
        assertEquals(
            listOf(KeyDown(InputKey.UP), KeyUp(InputKey.UP), KeyDown(InputKey.RIGHT), KeyDown(InputKey.RIGHT, repeat = true)),
            keys(),
        )
    }

    @Test
    fun `a diagonal stick let back to one axis keeps that axis repeating`() = runTest {
        val pad = navigator()
        pad.stick(-1f, -1f)
        pad.stick(-1f, 0f)
        advanceTimeBy(401)
        assertEquals(
            listOf(KeyDown(InputKey.UP), KeyUp(InputKey.UP), KeyDown(InputKey.LEFT), KeyDown(InputKey.LEFT, repeat = true)),
            keys(),
        )
    }
}

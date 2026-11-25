package com.edde746.plezy.desktop.linux

import com.edde746.plezy.desktop.GamepadEvents
import com.edde746.plezy.input.GamepadButton
import kotlin.test.Test
import kotlin.test.assertEquals

class LinuxJoysticksTest {
    private class Recorder : GamepadEvents {
        val events = mutableListOf<String>()

        override fun button(button: GamepadButton, down: Boolean) {
            events += "$button ${if (down) "down" else "up"}"
        }

        override fun stick(x: Float, y: Float) {
            events += "stick $x $y"
        }

        override fun disconnected() {
            events += "disconnected"
        }
    }

    // An Xbox 360 pad under xpad, as sysfs shows its capabilities: A B X Y TL TR SELECT START MODE THUMBL THUMBR, and
    // X Y Z RX RY RZ HAT0X HAT0Y.
    private val xpad = JoystickLayout.parse(key = "7cdb000000000000 0 0 0 0\n", abs = "3003f\n")

    @Test
    fun joydevNumbersTheButtonsAndAxesInTheOrderOfTheirCodes() {
        assertEquals(listOf(0x130, 0x131, 0x133, 0x134, 0x136, 0x137, 0x13a, 0x13b, 0x13c, 0x13d, 0x13e), xpad.buttons)
        assertEquals(listOf(0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x10, 0x11), xpad.axes)
    }

    @Test
    fun theMiscButtonsComeAfterTheDpads() {
        // BTN_DPAD_UP to BTN_DPAD_RIGHT (0x220 to 0x223: word 8, bits 32 to 35) and BTN_MISC (0x100: word 4, bit 0).
        val layout = JoystickLayout.parse(key = "f00000000 0 0 0 1 0 0 0 0\n", abs = "0\n")
        assertEquals(listOf(0x220, 0x221, 0x222, 0x223, 0x100), layout.buttons)
    }

    @Test
    fun theFaceButtonsAndShouldersArePressedAndReleased() {
        val recorder = Recorder()
        val pad = Joystick(xpad, recorder)
        for (number in listOf(0, 1, 2, 3, 4, 5)) pad.event(0x01, number, 1)
        pad.event(0x01, 0, 0)
        assertEquals(listOf("A down", "B down", "X down", "LEFT_SHOULDER down", "RIGHT_SHOULDER down", "A up"), recorder.events)
    }

    @Test
    fun theHatIsTheDpad() {
        val recorder = Recorder()
        val pad = Joystick(xpad, recorder)
        pad.event(0x02, 7, -32767)
        pad.event(0x02, 7, 32767)
        pad.event(0x02, 7, 0)
        pad.event(0x02, 6, 32767)
        assertEquals(listOf("DPAD_UP down", "DPAD_UP up", "DPAD_DOWN down", "DPAD_DOWN up", "DPAD_RIGHT down"), recorder.events)
    }

    @Test
    fun theLeftStickIsDownPositive() {
        val recorder = Recorder()
        val pad = Joystick(xpad, recorder)
        pad.event(0x02, 1, -32767)
        pad.event(0x02, 0, 32767)
        pad.event(0x02, 3, 32767)
        assertEquals(listOf("stick 0.0 -1.0", "stick 1.0 -1.0"), recorder.events)
    }

    @Test
    fun theStateTheDeviceOpensWithIsNoPress() {
        val recorder = Recorder()
        val pad = Joystick(xpad, recorder)
        pad.event(0x81, 0, 1)
        pad.event(0x82, 7, -32767)
        pad.event(0x82, 1, 32767)
        assertEquals(emptyList(), recorder.events)
        pad.event(0x02, 7, 0)
        assertEquals(listOf("DPAD_UP up"), recorder.events)
    }
}

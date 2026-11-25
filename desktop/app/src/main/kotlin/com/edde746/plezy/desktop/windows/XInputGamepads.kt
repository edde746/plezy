package com.edde746.plezy.desktop.windows

import com.edde746.plezy.desktop.GamepadEvents
import com.edde746.plezy.desktop.GamepadSource
import com.edde746.plezy.desktop.bind
import com.edde746.plezy.desktop.int
import com.edde746.plezy.input.GamepadButton
import java.lang.foreign.Arena
import java.lang.foreign.FunctionDescriptor
import java.lang.foreign.MemorySegment
import java.lang.foreign.SymbolLookup
import java.lang.foreign.ValueLayout.ADDRESS
import java.lang.foreign.ValueLayout.JAVA_INT
import java.lang.foreign.ValueLayout.JAVA_SHORT
import java.lang.invoke.MethodHandle

/** One XInput controller's state ([XInputReader]): its buttons (`XINPUT_GAMEPAD`'s `wButtons`) and its left stick. */
internal data class XInputState(val buttons: Int, val thumbX: Short, val thumbY: Short)

/** The state of XInput's controller [slot] (0 to 3), or null while none is connected there. */
internal fun interface XInputReader {
    fun state(slot: Int): XInputState?
}

/**
 * The XInput controllers of Windows (Xbox controllers, and those Steam Input presents as one), polled about 60 times a
 * second on a thread of their own while resumed: each of the four slots' change of buttons and stick goes to [events],
 * a controller's going away as [GamepadEvents.disconnected]. A slot without a controller is asked again once a second
 * (XInput is slow to answer for those). What a controller holds as reading starts or resumes is where it starts from,
 * not a press. XInput opens no device: pausing stops the polling. [reader] is XInputGetState (xinput1_4.dll), or a
 * test launch's stand-in.
 */
internal class XInputGamepads(private val events: GamepadEvents, private val reader: XInputReader = XInputDll) : GamepadSource {
    @Volatile private var thread: Thread? = null

    @Synchronized
    override fun resume() {
        if (thread != null) return
        // Set before it starts: it polls only while it is the one set, and would stop at once if it looked first.
        val poller = Thread(::poll, "xinput").apply { isDaemon = true }
        thread = poller
        poller.start()
    }

    @Synchronized
    override fun pause() {
        val running = thread ?: return
        thread = null
        running.interrupt()
    }

    private fun poll() {
        val me = Thread.currentThread()
        val last = arrayOfNulls<XInputState>(SLOTS)
        for (slot in 0 until SLOTS) last[slot] = reader.state(slot)
        var tick = 0
        while (thread === me) {
            try {
                Thread.sleep(POLL_MILLIS)
            } catch (_: InterruptedException) {
                return
            }
            tick++
            for (slot in 0 until SLOTS) {
                val before = last[slot]
                if (before == null && tick % EMPTY_SLOT_TICKS != 0) continue
                val now = reader.state(slot)
                if (thread !== me) return
                when {
                    now == null -> if (before != null) events.disconnected()
                    before == null -> Unit
                    else -> now.changesFrom(before, events)
                }
                last[slot] = now
            }
        }
    }

    private companion object {
        const val SLOTS = 4
        const val POLL_MILLIS = 16L
        const val EMPTY_SLOT_TICKS = 60
    }
}

/** What changed from [before] to this state, as [events]: each button that went down or up, the stick that moved. */
internal fun XInputState.changesFrom(before: XInputState, events: GamepadEvents) {
    for ((mask, button) in XINPUT_BUTTONS) {
        val down = buttons and mask != 0
        if (down != (before.buttons and mask != 0)) events.button(button, down)
    }
    // XInput's stick is -32768 to 32767, up positive.
    if (thumbX != before.thumbX || thumbY != before.thumbY) events.stick(axis(thumbX), -axis(thumbY))
}

private fun axis(value: Short) = (value / 32767f).coerceIn(-1f, 1f)

/** `XINPUT_GAMEPAD_*` buttons the app reads. */
private val XINPUT_BUTTONS = listOf(
    0x0001 to GamepadButton.DPAD_UP,
    0x0002 to GamepadButton.DPAD_DOWN,
    0x0004 to GamepadButton.DPAD_LEFT,
    0x0008 to GamepadButton.DPAD_RIGHT,
    0x0100 to GamepadButton.LEFT_SHOULDER,
    0x0200 to GamepadButton.RIGHT_SHOULDER,
    0x1000 to GamepadButton.A,
    0x2000 to GamepadButton.B,
    0x4000 to GamepadButton.X,
)

/** XInputGetState of xinput1_4.dll (Windows 8 and later), loaded on the first call; one caller at a time. */
private object XInputDll : XInputReader {
    private const val ERROR_DEVICE_NOT_CONNECTED = 1167

    private val getState: MethodHandle by lazy {
        SymbolLookup.libraryLookup("xinput1_4", Arena.global()).bind("XInputGetState", FunctionDescriptor.of(JAVA_INT, JAVA_INT, ADDRESS))
    }

    // XINPUT_STATE: DWORD dwPacketNumber, then XINPUT_GAMEPAD: WORD wButtons, BYTE bLeftTrigger, BYTE bRightTrigger,
    // SHORT sThumbLX, SHORT sThumbLY, SHORT sThumbRX, SHORT sThumbRY.
    private val buffer: MemorySegment by lazy { Arena.global().allocate(16, 4) }

    override fun state(slot: Int): XInputState? {
        val result = getState.int(slot, buffer)
        if (result == ERROR_DEVICE_NOT_CONNECTED) return null
        check(result == 0) { "XInputGetState($slot) failed: $result" }
        return XInputState(buffer.get(JAVA_SHORT, 4).toInt() and 0xFFFF, buffer.get(JAVA_SHORT, 8), buffer.get(JAVA_SHORT, 10))
    }
}

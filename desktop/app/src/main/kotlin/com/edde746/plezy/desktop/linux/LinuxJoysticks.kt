package com.edde746.plezy.desktop.linux

import com.edde746.plezy.desktop.GamepadEvents
import com.edde746.plezy.desktop.GamepadSource
import com.edde746.plezy.input.GamepadButton
import java.io.EOFException
import java.io.IOException
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.channels.ClosedChannelException
import java.nio.channels.FileChannel
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardOpenOption
import java.util.concurrent.ConcurrentHashMap
import kotlin.io.path.readText

/**
 * Linux's game controllers through the joystick devices (`/dev/input/js*`, the kernel's joydev): each one's events
 * read on a thread of its own while resumed, the devices looked for again every second (a controller plugged in later),
 * a device that fails (unplugged) going to [events] as [GamepadEvents.disconnected]. Each device's buttons and axes are
 * named by the input device's capabilities in sysfs ([JoystickLayout]). Pausing closes every device, so other apps
 * have them. A device this user may not read is left out, said once on stderr each time reading resumes.
 */
internal class LinuxJoysticks(
    private val events: GamepadEvents,
    private val devices: Path = Path.of("/dev/input"),
    private val sysfs: Path = Path.of("/sys/class/input"),
) : GamepadSource {
    @Volatile private var scanner: Thread? = null
    private val open = ConcurrentHashMap<Path, FileChannel>()

    @Synchronized
    override fun resume() {
        if (scanner != null) return
        // Set before it starts: it scans only while it is the one set, and would stop at once if it looked first.
        val scanning = Thread(::scan, "joysticks").apply { isDaemon = true }
        scanner = scanning
        scanning.start()
    }

    @Synchronized
    override fun pause() {
        val running = scanner ?: return
        scanner = null
        running.interrupt()
        // Closing a channel ends the read its thread is blocked in.
        open.values.forEach { it.close() }
        open.clear()
    }

    private fun scan() {
        val me = Thread.currentThread()
        val refused = mutableSetOf<Path>()
        // A sandbox without the input devices (a Flatpak without --device=input) has no controllers.
        if (!Files.isDirectory(devices)) {
            System.err.println("plezy: no $devices: no game controllers")
            return
        }
        while (scanner === me) {
            val found = Files.newDirectoryStream(devices, "js*").use { it.toList() }
            for (path in found) {
                if (open.containsKey(path) || path in refused) continue
                val (channel, layout) = try {
                    val layout = JoystickLayout.read(sysfs.resolve(path.fileName.toString()).resolve("device").resolve("capabilities"))
                    FileChannel.open(path, StandardOpenOption.READ) to layout
                } catch (e: IOException) {
                    System.err.println("plezy: can't read the game controller $path: $e")
                    refused.add(path)
                    continue
                }
                synchronized(this) {
                    if (scanner !== me) {
                        channel.close()
                        return
                    }
                    open[path] = channel
                }
                Thread({ read(path, channel, layout) }, "joystick ${path.fileName}").apply {
                    isDaemon = true
                    start()
                }
            }
            try {
                Thread.sleep(SCAN_MILLIS)
            } catch (_: InterruptedException) {
                return
            }
        }
    }

    private fun read(path: Path, channel: FileChannel, layout: JoystickLayout) {
        val pad = Joystick(layout, events)
        val buffer = ByteBuffer.allocate(EVENT_SIZE * 64).order(ByteOrder.LITTLE_ENDIAN)
        try {
            while (true) {
                if (channel.read(buffer) < 0) throw EOFException("$path ended")
                buffer.flip()
                // struct js_event: __u32 time, __s16 value, __u8 type, __u8 number.
                while (buffer.remaining() >= EVENT_SIZE) {
                    buffer.getInt()
                    val value = buffer.getShort()
                    val type = buffer.get().toInt() and 0xFF
                    val number = buffer.get().toInt() and 0xFF
                    pad.event(type, number, value)
                }
                buffer.compact()
            }
        } catch (_: ClosedChannelException) {
            // Paused: the channel was closed under the read.
            return
        } catch (e: IOException) {
            System.err.println("plezy: game controller $path gone: $e")
            open.remove(path, channel)
            channel.close()
            events.disconnected()
        }
    }

    private companion object {
        const val EVENT_SIZE = 8
        const val SCAN_MILLIS = 1000L
    }
}

/**
 * The input codes of a joystick device's buttons and axes, in joydev's numbering: the buttons in the order of their
 * codes from BTN_JOYSTICK to KEY_MAX, then those from BTN_MISC up to BTN_JOYSTICK; the axes in the order of theirs.
 */
internal class JoystickLayout(val buttons: List<Int>, val axes: List<Int>) {
    companion object {
        private const val BTN_MISC = 0x100
        private const val BTN_JOYSTICK = 0x120
        private const val KEY_MAX = 0x2ff
        private const val ABS_CNT = 0x40

        /** The layout from an input device's sysfs `capabilities` directory (its `key` and `abs` bitmaps). */
        fun read(capabilities: Path): JoystickLayout = parse(capabilities.resolve("key").readText(), capabilities.resolve("abs").readText())

        /**
         * The layout from the `key` and `abs` bitmaps as sysfs shows them: hexadecimal words of [wordBits] bits (the
         * kernel's long), the highest first.
         */
        fun parse(key: String, abs: String, wordBits: Int = 64): JoystickLayout {
            val keys = bits(key, wordBits)
            val axes = bits(abs, wordBits)
            val buttons = (BTN_JOYSTICK..KEY_MAX).filter { it in keys } + (BTN_MISC until BTN_JOYSTICK).filter { it in keys }
            return JoystickLayout(buttons, (0 until ABS_CNT).filter { it in axes })
        }

        private fun bits(bitmap: String, wordBits: Int): Set<Int> = bitmap.trim().split(' ').reversed().flatMapIndexed { index, word ->
            val value = word.toULong(16)
            (0 until wordBits).filter { (value shr it) and 1uL == 1uL }.map { index * wordBits + it }
        }.toSet()
    }
}

/**
 * One joystick device's events ([event]: joydev's `js_event`) as [events]: the gamepad buttons the app reads (the
 * Xbox layout's A, B and X, as xpad, Steam's controllers and Steam Input report them; a PlayStation pad's X there is its
 * Triangle), the shoulders, the D-pad as buttons or as the hat's axes, and the left stick. The state the device reports
 * as it opens (`JS_EVENT_INIT`) is where it starts from, not a press.
 */
internal class Joystick(private val layout: JoystickLayout, private val events: GamepadEvents) {
    private var x = 0f
    private var y = 0f
    private var hatX: GamepadButton? = null
    private var hatY: GamepadButton? = null

    fun event(type: Int, number: Int, value: Short) {
        val init = type and JS_EVENT_INIT != 0
        when (type and JS_EVENT_INIT.inv()) {
            JS_EVENT_BUTTON -> {
                val button = layout.buttons.getOrNull(number)?.let(BUTTONS::get) ?: return
                if (!init) events.button(button, value.toInt() != 0)
            }
            JS_EVENT_AXIS -> when (layout.axes.getOrNull(number)) {
                ABS_X -> {
                    x = axis(value)
                    if (!init) events.stick(x, y)
                }
                ABS_Y -> {
                    y = axis(value)
                    if (!init) events.stick(x, y)
                }
                ABS_HAT0X -> hatX = hat(value, hatX, GamepadButton.DPAD_LEFT, GamepadButton.DPAD_RIGHT, init)
                ABS_HAT0Y -> hatY = hat(value, hatY, GamepadButton.DPAD_UP, GamepadButton.DPAD_DOWN, init)
            }
        }
    }

    private fun hat(value: Short, held: GamepadButton?, negative: GamepadButton, positive: GamepadButton, init: Boolean): GamepadButton? {
        val now = when {
            value < 0 -> negative
            value > 0 -> positive
            else -> null
        }
        if (now != held && !init) {
            held?.let { events.button(it, false) }
            now?.let { events.button(it, true) }
        }
        return now
    }

    private companion object {
        const val JS_EVENT_BUTTON = 0x01
        const val JS_EVENT_AXIS = 0x02
        const val JS_EVENT_INIT = 0x80
        const val ABS_X = 0x00
        const val ABS_Y = 0x01
        const val ABS_HAT0X = 0x10
        const val ABS_HAT0Y = 0x11

        val BUTTONS = mapOf(
            0x130 to GamepadButton.A, // BTN_SOUTH
            0x131 to GamepadButton.B, // BTN_EAST
            0x133 to GamepadButton.X, // BTN_X
            0x136 to GamepadButton.LEFT_SHOULDER, // BTN_TL
            0x137 to GamepadButton.RIGHT_SHOULDER, // BTN_TR
            0x220 to GamepadButton.DPAD_UP,
            0x221 to GamepadButton.DPAD_DOWN,
            0x222 to GamepadButton.DPAD_LEFT,
            0x223 to GamepadButton.DPAD_RIGHT,
        )

        /** joydev's axes run from -32767 to 32767 (Y down positive, as the app's). */
        fun axis(value: Short) = (value / 32767f).coerceIn(-1f, 1f)
    }
}

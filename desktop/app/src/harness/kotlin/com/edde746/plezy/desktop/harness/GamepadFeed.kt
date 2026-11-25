package com.edde746.plezy.desktop.harness

import com.edde746.plezy.desktop.windows.XInputReader
import com.edde746.plezy.desktop.windows.XInputState
import java.nio.file.Path
import java.nio.file.attribute.FileTime
import kotlin.io.path.exists
import kotlin.io.path.fileSize
import kotlin.io.path.getLastModifiedTime
import kotlin.io.path.readLines

/**
 * `--gamepad-feed`: game controllers a test scripts through [file], read by the app as XInput's are (the machines have
 * none). Each line sets a slot's state: `<slot> <buttons> <x> <y>`, the buttons pressed joined by `+` (A, B, X, UP,
 * DOWN, LEFT, RIGHT, LB, RB) or `-` for none, the left stick's x and y as XInput's (-32768 to 32767, up positive); or
 * `<slot> off`, no controller there. A slot's last line holds; no file, or no line for a slot, no controller there.
 * The file is read again whenever it changes.
 */
internal class GamepadFeed(private val file: Path) : XInputReader {
    private var stamp: Pair<FileTime, Long>? = null
    private var states = emptyMap<Int, XInputState>()

    override fun state(slot: Int): XInputState? {
        refresh()
        return states[slot]
    }

    private fun refresh() {
        if (!file.exists()) {
            stamp = null
            states = emptyMap()
            return
        }
        val now = file.getLastModifiedTime() to file.fileSize()
        if (now == stamp) return
        stamp = now
        val read = mutableMapOf<Int, XInputState?>()
        for (line in file.readLines().map { it.trim() }.filter { it.isNotEmpty() }) {
            val parts = line.split(Regex("\\s+"))
            val slot = parts[0].toIntOrNull()?.takeIf { it in 0..3 } ?: error("--gamepad-feed: bad slot in '$line'")
            read[slot] = if (parts.getOrNull(1) == "off") null else parse(parts, line)
        }
        states = read.mapNotNull { (slot, state) -> state?.let { slot to it } }.toMap()
    }

    private fun parse(parts: List<String>, line: String): XInputState {
        require(parts.size == 4) { "--gamepad-feed: '$line' isn't <slot> <buttons> <x> <y>" }
        val buttons = if (parts[1] == "-") 0 else parts[1].split('+').fold(0) { mask, name -> mask or (BUTTONS[name] ?: error("--gamepad-feed: unknown button $name")) }
        val (x, y) = parts.subList(2, 4).map { it.toIntOrNull()?.takeIf { v -> v in -32768..32767 }?.toShort() ?: error("--gamepad-feed: bad axis in '$line'") }
        return XInputState(buttons, x, y)
    }

    private companion object {
        /** XInput's `XINPUT_GAMEPAD_*` masks. */
        val BUTTONS = mapOf(
            "UP" to 0x0001, "DOWN" to 0x0002, "LEFT" to 0x0004, "RIGHT" to 0x0008,
            "LB" to 0x0100, "RB" to 0x0200, "A" to 0x1000, "B" to 0x2000, "X" to 0x4000,
        )
    }
}

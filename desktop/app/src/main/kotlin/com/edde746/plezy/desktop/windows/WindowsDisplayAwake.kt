package com.edde746.plezy.desktop.windows

import com.edde746.plezy.desktop.DesktopDisplayAwake
import com.edde746.plezy.desktop.bind
import com.edde746.plezy.desktop.int
import java.awt.EventQueue
import java.lang.foreign.Arena
import java.lang.foreign.FunctionDescriptor
import java.lang.foreign.SymbolLookup
import java.lang.foreign.ValueLayout.JAVA_INT
import java.lang.invoke.MethodHandle

/**
 * Keeps the display awake on Windows through the event thread's execution state (`SetThreadExecutionState`): while
 * awake it requires the display and the system, and `powercfg /requests` lists the app's process under DISPLAY and
 * SYSTEM. The state belongs to the thread that set it, so every call comes from the event thread (the main thread),
 * and Windows drops it when that thread or the process ends, however it ends.
 */
internal class WindowsDisplayAwake : DesktopDisplayAwake {
    private var awake = false

    override fun keepAwake(awake: Boolean) {
        check(EventQueue.isDispatchThread()) { "the execution state belongs to the event thread" }
        if (awake == this.awake) return
        val flags = if (awake) ES_CONTINUOUS or ES_DISPLAY_REQUIRED or ES_SYSTEM_REQUIRED else ES_CONTINUOUS
        check(setThreadExecutionState.int(flags) != 0) { "SetThreadExecutionState(0x${flags.toUInt().toString(16)}) failed" }
        this.awake = awake
    }

    /** Nothing to release: the playback's end released it on the event thread, and the process's end would. */
    override fun close() = Unit

    private companion object {
        const val ES_SYSTEM_REQUIRED = 0x1
        const val ES_DISPLAY_REQUIRED = 0x2
        const val ES_CONTINUOUS = Int.MIN_VALUE // 0x80000000

        val setThreadExecutionState: MethodHandle =
            SymbolLookup.libraryLookup("kernel32", Arena.global()).bind("SetThreadExecutionState", FunctionDescriptor.of(JAVA_INT, JAVA_INT))
    }
}

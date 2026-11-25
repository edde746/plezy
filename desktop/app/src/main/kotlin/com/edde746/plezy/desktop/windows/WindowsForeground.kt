package com.edde746.plezy.desktop.windows

import com.edde746.plezy.desktop.bind
import com.edde746.plezy.desktop.int
import java.lang.foreign.Arena
import java.lang.foreign.FunctionDescriptor
import java.lang.foreign.SymbolLookup
import java.lang.foreign.ValueLayout.JAVA_INT
import java.lang.invoke.MethodHandle

/**
 * Windows' foreground lock: only the process the user just started (or the one in front) may bring a window to the
 * front. A later start ([com.edde746.plezy.desktop.SingleInstance]) is that process, so it hands the right to the
 * running app, whose window then comes forward instead of only flashing in the taskbar.
 */
internal object WindowsForeground {
    private val allowSetForegroundWindow: MethodHandle =
        SymbolLookup.libraryLookup("user32", Arena.global()).bind("AllowSetForegroundWindow", FunctionDescriptor.of(JAVA_INT, JAVA_INT))

    /** Lets the process [pid] bring its window to the front (`AllowSetForegroundWindow`); Windows refusing is logged. */
    fun allow(pid: Long) {
        if (allowSetForegroundWindow.int(pid.toInt()) == 0) System.err.println("plezy: Windows didn't let the running app come to the front")
    }
}

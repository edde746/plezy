package com.edde746.plezy.desktop.windows

import com.edde746.plezy.desktop.bind
import com.edde746.plezy.desktop.int
import java.lang.foreign.Arena
import java.lang.foreign.FunctionDescriptor
import java.lang.foreign.MemorySegment
import java.lang.foreign.SymbolLookup
import java.lang.foreign.ValueLayout.ADDRESS
import java.lang.foreign.ValueLayout.JAVA_INT

/**
 * DWM's cloak: a cloaked window is shown and draws (Skiko renders to it) but the desktop doesn't composite it. The
 * window opens cloaked and uncloaks on its first frame, so it never shows blank or before its place is applied.
 */
internal object WindowCloak {
    private const val DWMWA_CLOAK = 13

    private val setAttribute by lazy {
        runCatching {
            SymbolLookup.libraryLookup("dwmapi", Arena.global())
                .bind("DwmSetWindowAttribute", FunctionDescriptor.of(JAVA_INT, ADDRESS, JAVA_INT, ADDRESS, JAVA_INT))
        }.getOrNull()
    }

    /** Cloaks or uncloaks [hwnd]; false when DWM refused (the caller then shows the window as it is). */
    fun set(hwnd: Long, cloaked: Boolean): Boolean {
        val call = setAttribute ?: return false
        return Arena.ofConfined().use { a ->
            val value = a.allocate(JAVA_INT).also { it.set(JAVA_INT, 0, if (cloaked) 1 else 0) }
            call.int(MemorySegment.ofAddress(hwnd), DWMWA_CLOAK, value, 4) == 0
        }
    }
}

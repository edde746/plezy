package com.edde746.plezy.desktop.windows

import com.edde746.plezy.desktop.bind
import com.edde746.plezy.desktop.int
import java.lang.foreign.Arena
import java.lang.foreign.FunctionDescriptor
import java.lang.foreign.Linker
import java.lang.foreign.MemorySegment
import java.lang.foreign.SymbolLookup
import java.lang.foreign.ValueLayout.ADDRESS
import java.lang.foreign.ValueLayout.JAVA_INT
import java.lang.foreign.ValueLayout.JAVA_LONG
import java.lang.invoke.MethodHandle
import java.lang.invoke.MethodHandles
import java.lang.invoke.MethodType
import java.nio.charset.StandardCharsets.UTF_16LE

/**
 * Calls [onChange] on every `WM_DISPLAYCHANGE` (a display's mode changed, or one came or went) and [onResume] on every
 * `WM_POWERBROADCAST` that says the system woke from sleep. Windows broadcasts both to top-level windows only, and AWT
 * keeps its own window procedure, so a hidden top-level window of its own, on a thread of its own with its own message
 * pump, hears them. The callbacks run on that thread: hand the work off.
 */
internal class WindowsDisplayChanges(private val onResume: () -> Unit = {}, private val onChange: () -> Unit = {}) {
    private val upcall: MemorySegment = Linker.nativeLinker().upcallStub(
        MethodHandles.lookup().findVirtual(
            WindowsDisplayChanges::class.java, "windowProc",
            MethodType.methodType(Long::class.javaPrimitiveType, MemorySegment::class.java, Int::class.javaPrimitiveType, Long::class.javaPrimitiveType, Long::class.javaPrimitiveType),
        ).bindTo(this),
        FunctionDescriptor.of(JAVA_LONG, ADDRESS, JAVA_INT, JAVA_LONG, JAVA_LONG),
        Arena.global(),
    )

    init {
        Thread(::run, "display-changes").apply { isDaemon = true; start() }
    }

    @Suppress("unused") // Called from native code through [upcall].
    private fun windowProc(hwnd: MemorySegment, msg: Int, wParam: Long, lParam: Long): Long {
        if (msg == WM_DISPLAYCHANGE) runCatching(onChange)
        if (msg == WM_POWERBROADCAST && (wParam == PBT_APMRESUMEAUTOMATIC || wParam == PBT_APMRESUMESUSPEND)) runCatching(onResume)
        return Api.defWindowProcW.invokeWithArguments(hwnd, msg, wParam, lParam) as Long
    }

    private fun run() = Arena.ofConfined().use { a ->
        val instance = Api.getModuleHandleW.invokeWithArguments(MemorySegment.NULL) as MemorySegment
        val className = a.allocateFrom("PlezyDisplayChanges", UTF_16LE)
        val wc = a.allocate(80) // WNDCLASSEXW
        wc.set(JAVA_INT, 0, 80)
        wc.set(ADDRESS, 8, upcall)
        wc.set(ADDRESS, 24, instance)
        wc.set(ADDRESS, 64, className)
        Api.registerClassExW.invokeWithArguments(wc)
        val hwnd = Api.createWindowExW.invokeWithArguments(
            0, className, className, 0, 0, 0, 0, 0, MemorySegment.NULL, MemorySegment.NULL, instance, MemorySegment.NULL,
        ) as MemorySegment
        if (hwnd.address() == 0L) return@use
        val msg = a.allocate(48) // MSG
        while (Api.getMessageW.int(msg, MemorySegment.NULL, 0, 0) > 0) {
            Api.dispatchMessageW.invokeWithArguments(msg)
        }
    }

    private object Api {
        private val user32 = SymbolLookup.libraryLookup("user32", Arena.global())
        private val kernel32 = SymbolLookup.libraryLookup("kernel32", Arena.global())

        val defWindowProcW: MethodHandle = user32.bind("DefWindowProcW", FunctionDescriptor.of(JAVA_LONG, ADDRESS, JAVA_INT, JAVA_LONG, JAVA_LONG))
        val registerClassExW: MethodHandle = user32.bind("RegisterClassExW", FunctionDescriptor.of(JAVA_INT, ADDRESS))
        val createWindowExW: MethodHandle = user32.bind(
            "CreateWindowExW",
            FunctionDescriptor.of(ADDRESS, JAVA_INT, ADDRESS, ADDRESS, JAVA_INT, JAVA_INT, JAVA_INT, JAVA_INT, JAVA_INT, ADDRESS, ADDRESS, ADDRESS, ADDRESS),
        )
        val getMessageW: MethodHandle = user32.bind("GetMessageW", FunctionDescriptor.of(JAVA_INT, ADDRESS, ADDRESS, JAVA_INT, JAVA_INT))
        val dispatchMessageW: MethodHandle = user32.bind("DispatchMessageW", FunctionDescriptor.of(JAVA_LONG, ADDRESS))
        val getModuleHandleW: MethodHandle = kernel32.bind("GetModuleHandleW", FunctionDescriptor.of(ADDRESS, ADDRESS))
    }

    private companion object {
        const val WM_DISPLAYCHANGE = 0x007E
        const val WM_POWERBROADCAST = 0x0218
        const val PBT_APMRESUMESUSPEND = 0x7L
        const val PBT_APMRESUMEAUTOMATIC = 0x12L
    }
}

package com.edde746.plezy.desktop

import java.lang.foreign.Arena
import java.lang.foreign.FunctionDescriptor
import java.lang.foreign.Linker
import java.lang.foreign.MemorySegment
import java.lang.foreign.SymbolLookup
import java.lang.foreign.ValueLayout

/**
 * Makes an `abort()` in native code (a failed assertion in libmpv or a library it uses, the C library's heap checks) a
 * crash HotSpot's own handler reports ([NativeCrashes]). HotSpot reports faults, not `SIGABRT`, so an abort would end
 * the process without a report. Here `SIGABRT`'s handler is the C library's `strlen`: called with the signal's number
 * as its string, it reads from that address on the aborting thread, inside the abort, and that fault is what HotSpot
 * reports, with the aborting thread's stack. [NativeCrashes.parse] tells it from other faults by that address.
 *
 * Linux: installed with `sigaction` and `SA_RESETHAND`, so the abort HotSpot itself makes after its report (to dump
 * core) ends the process as an abort does. Windows: installed in the Universal C Runtime's signal table, which libmpv
 * shares, through its `signal`; the runtime resets the handler before it calls it.
 */
internal object NativeAborts {
    /** `SIGABRT`: 6 on Linux, 22 in the Windows C runtime. */
    const val LINUX_SIGABRT = 6L
    const val WINDOWS_SIGABRT = 22L

    private const val SA_RESETHAND = 0x80000000.toInt()

    /** glibc's `struct sigaction` on x86_64 and aarch64: handler, 128-byte mask, flags, restorer. */
    private const val SIGACTION_SIZE = 152L
    private const val SIGACTION_FLAGS = 136L

    fun install(windows: Boolean) {
        val linker = Linker.nativeLinker()
        if (windows) {
            val ucrt = SymbolLookup.libraryLookup("ucrtbase.dll", Arena.global())
            val signal = linker.downcallHandle(
                ucrt.find("signal").orElseThrow(),
                FunctionDescriptor.of(ValueLayout.ADDRESS, ValueLayout.JAVA_INT, ValueLayout.ADDRESS),
            )
            val previous = signal.invokeWithArguments(WINDOWS_SIGABRT.toInt(), ucrt.find("strlen").orElseThrow()) as MemorySegment
            check(previous.address() != -1L) { "signal(SIGABRT) failed" }
        } else {
            val libc = linker.defaultLookup()
            val sigaction = linker.downcallHandle(
                libc.find("sigaction").orElseThrow(),
                FunctionDescriptor.of(ValueLayout.JAVA_INT, ValueLayout.JAVA_INT, ValueLayout.ADDRESS, ValueLayout.ADDRESS),
            )
            Arena.ofConfined().use { arena ->
                val action = arena.allocate(SIGACTION_SIZE, 8)
                action.set(ValueLayout.ADDRESS, 0, libc.find("strlen").orElseThrow())
                action.set(ValueLayout.JAVA_INT, SIGACTION_FLAGS, SA_RESETHAND)
                val result = sigaction.invokeWithArguments(LINUX_SIGABRT.toInt(), action, MemorySegment.NULL) as Int
                check(result == 0) { "sigaction(SIGABRT) failed" }
            }
        }
    }
}

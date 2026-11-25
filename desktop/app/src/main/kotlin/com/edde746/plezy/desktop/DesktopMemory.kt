package com.edde746.plezy.desktop

import java.io.IOException
import java.lang.foreign.Arena
import java.lang.foreign.FunctionDescriptor
import java.lang.foreign.SymbolLookup
import java.lang.foreign.ValueLayout.ADDRESS
import java.lang.foreign.ValueLayout.JAVA_INT
import java.lang.foreign.ValueLayout.JAVA_LONG
import java.nio.file.Files
import java.nio.file.Path

/** The process's resident memory, for the memory watchdog ([com.edde746.plezy.crash.RssWatchdog]). */
internal object DesktopMemory {
    private val isWindows = System.getProperty("os.name").startsWith("Windows")

    /**
     * The bytes the process holds in physical memory: the working set on Windows (`GetProcessMemoryInfo`), `VmRSS` of
     * `/proc/self/status` on Linux; null when it can't be read.
     */
    fun residentBytes(): Long? = if (isWindows) Windows.workingSet() else linuxResident()

    private fun linuxResident(): Long? = try {
        Files.readAllLines(Path.of("/proc/self/status")).firstOrNull { it.startsWith("VmRSS:") }
            ?.substringAfter(':')?.trim()?.substringBefore(' ')?.toLongOrNull()?.let { kb -> kb * 1024 }
    } catch (e: IOException) {
        System.err.println("plezy: the process's memory couldn't be read: $e")
        null
    }

    /** kernel32's `K32GetProcessMemoryInfo`, bound on first use. */
    private object Windows {
        private val kernel32 = SymbolLookup.libraryLookup("kernel32", Arena.global())
        private val currentProcess = kernel32.bind("GetCurrentProcess", FunctionDescriptor.of(ADDRESS))
        private val memoryInfo = kernel32.bind("K32GetProcessMemoryInfo", FunctionDescriptor.of(JAVA_INT, ADDRESS, ADDRESS, JAVA_INT))

        /** `PROCESS_MEMORY_COUNTERS` on 64-bit Windows: `cb`, `PageFaultCount`, then eight `SIZE_T`s. */
        private const val COUNTERS_SIZE = 72
        private const val WORKING_SET_OFFSET = 16L

        fun workingSet(): Long? = Arena.ofConfined().use { a ->
            val counters = a.allocate(COUNTERS_SIZE.toLong(), 8).also { it.set(JAVA_INT, 0, COUNTERS_SIZE) }
            if (memoryInfo.int(currentProcess.invokeWithArguments(), counters, COUNTERS_SIZE) == 0) null else counters.get(JAVA_LONG, WORKING_SET_OFFSET)
        }
    }
}

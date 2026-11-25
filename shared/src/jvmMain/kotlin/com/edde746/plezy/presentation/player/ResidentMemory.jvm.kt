package com.edde746.plezy.presentation.player

import java.lang.foreign.Arena
import java.lang.foreign.FunctionDescriptor
import java.lang.foreign.Linker
import java.lang.foreign.MemorySegment
import java.lang.foreign.SymbolLookup
import java.lang.foreign.ValueLayout
import java.lang.invoke.MethodHandle

/** Linux's resident set; on Windows the process's working set (`K32GetProcessMemoryInfo`). */
internal actual fun residentMemoryBytes(): Long? = if (WINDOWS) WindowsMemory.workingSet() else procResidentBytes()

private val WINDOWS = System.getProperty("os.name").startsWith("Windows")

private object WindowsMemory {
    private val kernel32 = SymbolLookup.libraryLookup("kernel32", Arena.global())
    private val linker = Linker.nativeLinker()
    private val currentProcess: MethodHandle =
        linker.downcallHandle(kernel32.findOrThrow("GetCurrentProcess"), FunctionDescriptor.of(ValueLayout.ADDRESS))
    private val processMemoryInfo: MethodHandle = linker.downcallHandle(
        kernel32.findOrThrow("K32GetProcessMemoryInfo"),
        FunctionDescriptor.of(ValueLayout.JAVA_INT, ValueLayout.ADDRESS, ValueLayout.ADDRESS, ValueLayout.JAVA_INT),
    )

    // PROCESS_MEMORY_COUNTERS: DWORD cb, DWORD PageFaultCount, then SIZE_T PeakWorkingSetSize, WorkingSetSize, … (8 in all).
    private const val SIZE = 72
    private const val WORKING_SET_OFFSET = 16L

    fun workingSet(): Long? = Arena.ofConfined().use { arena ->
        val counters = arena.allocate(SIZE.toLong(), 8)
        counters.set(ValueLayout.JAVA_INT, 0, SIZE)
        val process = currentProcess.invokeWithArguments() as MemorySegment
        if (processMemoryInfo.invokeWithArguments(process, counters, SIZE) as Int == 0) return null
        counters.get(ValueLayout.JAVA_LONG, WORKING_SET_OFFSET)
    }
}

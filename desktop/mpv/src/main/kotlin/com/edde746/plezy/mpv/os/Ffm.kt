package com.edde746.plezy.mpv.os

import java.lang.foreign.AddressLayout
import java.lang.foreign.FunctionDescriptor
import java.lang.foreign.Linker
import java.lang.foreign.MemorySegment
import java.lang.foreign.SymbolLookup
import java.lang.foreign.ValueLayout
import java.lang.invoke.MethodHandle

// Small helpers for the handwritten OS glue (Win32, X11, Wayland, EGL, libc). libmpv itself goes through the jextract bindings.

internal val PTR: AddressLayout = ValueLayout.ADDRESS
internal val I32: ValueLayout = ValueLayout.JAVA_INT
internal val I64: ValueLayout = ValueLayout.JAVA_LONG

internal val linker: Linker = Linker.nativeLinker()

internal fun SymbolLookup.fn(name: String, ret: ValueLayout?, vararg args: ValueLayout): MethodHandle {
    val symbol = find(name).orElseThrow { UnsatisfiedLinkError(name) }
    val desc = if (ret == null) FunctionDescriptor.ofVoid(*args) else FunctionDescriptor.of(ret, *args)
    return linker.downcallHandle(symbol, desc)
}

internal fun MethodHandle.call(vararg args: Any?): Any? = invokeWithArguments(*args)

internal fun ptr(address: Long): MemorySegment = MemorySegment.ofAddress(address)

/**
 * Reads a NUL-terminated C string. Decoding replaces malformed UTF-8 with U+FFFD: every string coming out of mpv is
 * sanitized this way (file names, titles and tags are not guaranteed to be valid UTF-8).
 */
internal fun MemorySegment.utf8(): String? =
    if (address() == 0L) null else reinterpret(Long.MAX_VALUE).getString(0)

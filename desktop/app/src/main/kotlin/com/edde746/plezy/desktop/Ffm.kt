package com.edde746.plezy.desktop

import java.lang.foreign.FunctionDescriptor
import java.lang.foreign.Linker
import java.lang.foreign.SymbolLookup
import java.lang.invoke.MethodHandle

// Binding and calling native functions through the JDK's FFM API (Win32, the Windows Runtime, libsecret).

/** The function [name] of this library as a handle; throws [NoSuchElementException] ("Symbol not found: …") without it. */
internal fun SymbolLookup.bind(name: String, descriptor: FunctionDescriptor, vararg options: Linker.Option): MethodHandle =
    Linker.nativeLinker().downcallHandle(findOrThrow(name), descriptor, *options)

/** Calls this handle with [args] and returns its `int` result. */
internal fun MethodHandle.int(vararg args: Any?): Int = invokeWithArguments(*args) as Int

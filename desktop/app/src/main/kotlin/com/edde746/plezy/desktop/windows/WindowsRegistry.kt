package com.edde746.plezy.desktop.windows

import com.edde746.plezy.desktop.bind
import com.edde746.plezy.desktop.int
import java.lang.foreign.Arena
import java.lang.foreign.FunctionDescriptor
import java.lang.foreign.MemorySegment
import java.lang.foreign.SymbolLookup
import java.lang.foreign.ValueLayout.ADDRESS
import java.lang.foreign.ValueLayout.JAVA_BYTE
import java.lang.foreign.ValueLayout.JAVA_INT
import java.nio.charset.StandardCharsets.UTF_16LE

/**
 * String, number and binary values of the Windows registry: read (`RegGetValueW`), as installers and players leave
 * their paths there, and written under the current user (`RegSetKeyValueW`), as the portable app registers its
 * `plezy:` links and keeps its window's place.
 */
internal object WindowsRegistry {
    /** The predefined keys read from; [handle] is the `HKEY` constant, sign-extended as `winreg.h` defines it. */
    enum class Root(val handle: Long) {
        CLASSES_ROOT(0x80000000.toInt().toLong()),
        CURRENT_USER(0x80000001.toInt().toLong()),
        LOCAL_MACHINE(0x80000002.toInt().toLong()),
    }

    /**
     * The string [value] of [key] under [root] (environment variables in it expanded), or its default value when [value]
     * is empty; null when the key or the value isn't there or isn't a string. [key] is read in this process's (64-bit)
     * view; a 32-bit program's keys are under `SOFTWARE\WOW6432Node`. Any other failure throws, as every read here does.
     */
    fun string(root: Root, key: String, value: String): String? = Arena.ofConfined().use { a ->
        val hkey = MemorySegment.ofAddress(root.handle)
        val subKey = a.allocateFrom(key, UTF_16LE)
        val name = a.allocateFrom(value, UTF_16LE)
        val size = a.allocate(JAVA_INT)
        if (!found(Api.regGetValueW.int(hkey, subKey, name, RRF_RT_REG_SZ, MemorySegment.NULL, MemorySegment.NULL, size))) return@use null
        val data = a.allocate(size.get(JAVA_INT, 0).toLong().coerceAtLeast(2))
        if (!found(Api.regGetValueW.int(hkey, subKey, name, RRF_RT_REG_SZ, MemorySegment.NULL, data, size))) return@use null
        data.getString(0, UTF_16LE).takeIf { it.isNotEmpty() }
    }

    /** The `REG_DWORD` [value] of [key] under [root], unsigned; null when it isn't there or isn't a DWORD. */
    fun dword(root: Root, key: String, value: String): Long? = Arena.ofConfined().use { a ->
        val data = a.allocate(JAVA_INT)
        val size = a.allocate(JAVA_INT).also { it.set(JAVA_INT, 0, 4) }
        val result = Api.regGetValueW.int(MemorySegment.ofAddress(root.handle), a.allocateFrom(key, UTF_16LE), a.allocateFrom(value, UTF_16LE), RRF_RT_REG_DWORD, MemorySegment.NULL, data, size)
        if (found(result)) data.get(JAVA_INT, 0).toUInt().toLong() else null
    }

    /** The `REG_BINARY` [value] of [key] under [root]; null when it isn't there or isn't binary. */
    fun binary(root: Root, key: String, value: String): ByteArray? = Arena.ofConfined().use { a ->
        val hkey = MemorySegment.ofAddress(root.handle)
        val subKey = a.allocateFrom(key, UTF_16LE)
        val name = a.allocateFrom(value, UTF_16LE)
        val size = a.allocate(JAVA_INT)
        if (!found(Api.regGetValueW.int(hkey, subKey, name, RRF_RT_REG_BINARY, MemorySegment.NULL, MemorySegment.NULL, size))) return@use null
        val data = a.allocate(size.get(JAVA_INT, 0).toLong().coerceAtLeast(1))
        if (!found(Api.regGetValueW.int(hkey, subKey, name, RRF_RT_REG_BINARY, MemorySegment.NULL, data, size))) return@use null
        data.asSlice(0, size.get(JAVA_INT, 0).toLong()).toArray(JAVA_BYTE)
    }

    /** Whether [value] of [key] under [root] exists, of any type. */
    fun exists(root: Root, key: String, value: String): Boolean = Arena.ofConfined().use { a ->
        found(Api.regGetValueW.int(MemorySegment.ofAddress(root.handle), a.allocateFrom(key, UTF_16LE), a.allocateFrom(value, UTF_16LE), RRF_RT_ANY, MemorySegment.NULL, MemorySegment.NULL, MemorySegment.NULL))
    }

    /** Writes the `REG_DWORD` [value] [data], creating [key]; false when Windows refused. */
    fun setDword(root: Root, key: String, value: String, data: Long): Boolean = Arena.ofConfined().use { a ->
        val bytes = a.allocate(JAVA_INT).also { it.set(JAVA_INT, 0, data.toInt()) }
        Api.regSetKeyValueW.int(MemorySegment.ofAddress(root.handle), a.allocateFrom(key, UTF_16LE), a.allocateFrom(value, UTF_16LE), REG_DWORD, bytes, 4) == ERROR_SUCCESS
    }

    /** Writes the `REG_SZ` [value] [data], creating [key]; false when Windows refused. */
    fun setString(root: Root, key: String, value: String, data: String): Boolean = Arena.ofConfined().use { a ->
        val bytes = a.allocateFrom(data, UTF_16LE)
        Api.regSetKeyValueW.int(MemorySegment.ofAddress(root.handle), a.allocateFrom(key, UTF_16LE), a.allocateFrom(value, UTF_16LE), REG_SZ, bytes, ((data.length + 1) * 2)) == ERROR_SUCCESS
    }

    /** Writes the `REG_BINARY` [value] [data], creating [key]; false when Windows refused. */
    fun setBinary(root: Root, key: String, value: String, data: ByteArray): Boolean = Arena.ofConfined().use { a ->
        val bytes = a.allocate(data.size.toLong().coerceAtLeast(1)).also { MemorySegment.copy(data, 0, it, JAVA_BYTE, 0, data.size) }
        Api.regSetKeyValueW.int(MemorySegment.ofAddress(root.handle), a.allocateFrom(key, UTF_16LE), a.allocateFrom(value, UTF_16LE), REG_BINARY, bytes, data.size) == ERROR_SUCCESS
    }

    /** Deletes [value] of [key]; true when it is gone (or never was), false when Windows refused. */
    fun delete(root: Root, key: String, value: String): Boolean = Arena.ofConfined().use { a ->
        val result = Api.regDeleteKeyValueW.int(MemorySegment.ofAddress(root.handle), a.allocateFrom(key, UTF_16LE), a.allocateFrom(value, UTF_16LE))
        result == ERROR_SUCCESS || result == ERROR_FILE_NOT_FOUND
    }

    /**
     * `RegGetValueW`'s [result]: true for the value, false when the key or the value isn't there or has another type.
     * Anything else (access denied, a value that grew between the size and the read) throws.
     */
    private fun found(result: Int): Boolean = when (result) {
        ERROR_SUCCESS -> true
        ERROR_FILE_NOT_FOUND, ERROR_UNSUPPORTED_TYPE -> false
        else -> error("RegGetValueW failed: $result")
    }

    private const val ERROR_SUCCESS = 0
    private const val ERROR_FILE_NOT_FOUND = 2
    private const val ERROR_UNSUPPORTED_TYPE = 1630
    private const val REG_SZ = 1
    private const val REG_BINARY = 3
    private const val REG_DWORD = 4

    /** `REG_SZ` only; a `REG_EXPAND_SZ` value comes expanded as one. */
    private const val RRF_RT_REG_SZ = 0x2
    private const val RRF_RT_REG_BINARY = 0x8
    private const val RRF_RT_REG_DWORD = 0x10
    private const val RRF_RT_ANY = 0xffff

    /** advapi32's functions, bound on first use. */
    private object Api {
        private val advapi32 = SymbolLookup.libraryLookup("advapi32", Arena.global())

        val regGetValueW = advapi32.bind(
            "RegGetValueW",
            FunctionDescriptor.of(JAVA_INT, ADDRESS, ADDRESS, ADDRESS, JAVA_INT, ADDRESS, ADDRESS, ADDRESS),
        )
        val regSetKeyValueW = advapi32.bind(
            "RegSetKeyValueW",
            FunctionDescriptor.of(JAVA_INT, ADDRESS, ADDRESS, ADDRESS, JAVA_INT, ADDRESS, JAVA_INT),
        )
        val regDeleteKeyValueW = advapi32.bind("RegDeleteKeyValueW", FunctionDescriptor.of(JAVA_INT, ADDRESS, ADDRESS, ADDRESS))
    }
}

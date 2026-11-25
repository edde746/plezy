package com.edde746.plezy.desktop.windows

import com.edde746.plezy.desktop.bind
import com.edde746.plezy.desktop.int
import java.lang.foreign.Arena
import java.lang.foreign.FunctionDescriptor
import java.lang.foreign.MemorySegment
import java.lang.foreign.SymbolLookup
import java.lang.foreign.ValueLayout.ADDRESS
import java.lang.foreign.ValueLayout.JAVA_CHAR
import java.lang.foreign.ValueLayout.JAVA_INT

/**
 * The user's languages and region as Settings → Time & language has them. The JVM's default locale holds only the
 * display language, with that language's region.
 */
internal object WindowsLocale {
    /** The preferred languages as BCP 47 tags (`en-US`), most preferred first (`GetUserPreferredUILanguages`). */
    fun preferredLanguages(): List<String> = Arena.ofConfined().use { a ->
        val count = a.allocate(JAVA_INT)
        val length = a.allocate(JAVA_INT).also { it.set(JAVA_INT, 0, 0) }
        check(Api.getUserPreferredUILanguages.int(MUI_LANGUAGE_NAME, count, MemorySegment.NULL, length) != 0) {
            "GetUserPreferredUILanguages failed to size its list"
        }
        val list = a.allocate(JAVA_CHAR, length.get(JAVA_INT, 0).toLong())
        check(Api.getUserPreferredUILanguages.int(MUI_LANGUAGE_NAME, count, list, length) != 0) {
            "GetUserPreferredUILanguages failed"
        }
        // Each tag ends with a NUL, and the list with another.
        list.toArray(JAVA_CHAR).concatToString().split('\u0000').filter { it.isNotEmpty() }
    }

    /** The country or region (`GetUserDefaultGeoName`): ISO 3166-1 alpha-2, or a UN M.49 area such as `419`. */
    fun region(): String = Arena.ofConfined().use { a ->
        val length = Api.getUserDefaultGeoName.int(MemorySegment.NULL, 0)
        check(length > 0) { "GetUserDefaultGeoName failed to size its name" }
        val name = a.allocate(JAVA_CHAR, length.toLong())
        check(Api.getUserDefaultGeoName.int(name, length) > 0) { "GetUserDefaultGeoName failed" }
        name.toArray(JAVA_CHAR).concatToString().substringBefore('\u0000')
    }

    private const val MUI_LANGUAGE_NAME = 0x8

    /** kernel32's functions, bound on first use. */
    private object Api {
        private val kernel32 = SymbolLookup.libraryLookup("kernel32", Arena.global())

        val getUserPreferredUILanguages = kernel32.bind(
            "GetUserPreferredUILanguages",
            FunctionDescriptor.of(JAVA_INT, JAVA_INT, ADDRESS, ADDRESS, ADDRESS),
        )
        val getUserDefaultGeoName = kernel32.bind("GetUserDefaultGeoName", FunctionDescriptor.of(JAVA_INT, ADDRESS, JAVA_INT))
    }
}

package com.edde746.plezy.ui.components

import androidx.compose.runtime.Composable
import java.lang.foreign.Arena
import java.lang.foreign.FunctionDescriptor
import java.lang.foreign.Linker
import java.lang.foreign.MemorySegment
import java.lang.foreign.SymbolLookup
import java.lang.foreign.ValueLayout.ADDRESS
import java.lang.foreign.ValueLayout.JAVA_CHAR
import java.lang.foreign.ValueLayout.JAVA_INT
import java.lang.invoke.MethodHandle
import java.time.chrono.IsoChronology
import java.time.format.DateTimeFormatterBuilder
import java.time.format.FormatStyle
import java.util.Locale

/**
 * The desktop's clock, read on each pass: on Windows the user's short time format (Settings → Time & language →
 * Region, their own choice included), elsewhere the session's time locale ([posixTimeLocale]), else the JVM's format
 * locale.
 */
@Composable
internal actual fun use24HourClock(): Boolean =
    if (WINDOWS) windowsTimeIs24Hour(WindowsShortTime.read()) else localeIs24Hour(posixTimeLocale(System.getenv()) ?: Locale.getDefault(Locale.Category.FORMAT))

/** A Windows time format (`HH:mm`, `h:mm tt`): `H` is the 24-hour clock's hour. */
internal fun windowsTimeIs24Hour(format: String): Boolean = 'H' in format

/**
 * The locale a Linux session formats times in, as glibc picks it: `LC_ALL`, else `LC_TIME`, else `LANG` (`de_DE.UTF-8`
 * is de-DE); null without one, or for C and POSIX. KDE Plasma's Region settings write `LC_TIME`.
 */
internal fun posixTimeLocale(env: Map<String, String>): Locale? {
    val value = listOf("LC_ALL", "LC_TIME", "LANG").firstNotNullOfOrNull { env[it]?.takeIf(String::isNotEmpty) } ?: return null
    val name = value.substringBefore('.').substringBefore('@')
    return if (name == "C" || name == "POSIX") null else Locale.forLanguageTag(name.replace('_', '-'))
}

/** [locale]'s short time format: 24-hour unless it has a day period (`a`, `B`). */
internal fun localeIs24Hour(locale: Locale): Boolean {
    val pattern = DateTimeFormatterBuilder.getLocalizedDateTimePattern(null, FormatStyle.SHORT, IsoChronology.INSTANCE, locale)
    return 'a' !in pattern && 'B' !in pattern
}

private val WINDOWS = System.getProperty("os.name").startsWith("Windows")

/** The user's short time format (`GetLocaleInfoEx`, `LOCALE_SSHORTTIME`), bound on first use. */
private object WindowsShortTime {
    private const val LOCALE_SSHORTTIME = 0x79
    private const val CAPACITY = 80

    private val getLocaleInfoEx: MethodHandle = Linker.nativeLinker().downcallHandle(
        SymbolLookup.libraryLookup("kernel32", Arena.global()).findOrThrow("GetLocaleInfoEx"),
        FunctionDescriptor.of(JAVA_INT, ADDRESS, JAVA_INT, ADDRESS, JAVA_INT),
    )

    /** A null locale name is the user's own (`LOCALE_NAME_USER_DEFAULT`). */
    fun read(): String = Arena.ofConfined().use { arena ->
        val buffer = arena.allocate(JAVA_CHAR, CAPACITY.toLong())
        val length = getLocaleInfoEx.invokeWithArguments(MemorySegment.NULL, LOCALE_SSHORTTIME, buffer, CAPACITY) as Int
        check(length > 0) { "GetLocaleInfoEx didn't give the short time format" }
        String(buffer.toArray(JAVA_CHAR), 0, length - 1)
    }
}

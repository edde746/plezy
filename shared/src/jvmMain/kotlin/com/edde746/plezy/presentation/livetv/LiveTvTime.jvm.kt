package com.edde746.plezy.presentation.livetv

import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.ZoneOffset
import java.time.chrono.IsoChronology
import java.time.format.DateTimeFormatter
import java.time.format.DateTimeFormatterBuilder
import java.util.Locale

actual fun localUtcOffsetSeconds(epochMillis: Long): Int =
    ZoneId.systemDefault().rules.getOffset(Instant.ofEpochMilli(epochMillis)).totalSeconds

internal actual fun localizedTime(epochMillis: Long, offsetSeconds: Int, skeleton: String, locale: String): String {
    val javaLocale = Locale.forLanguageTag(locale)
    // The JDK's skeletons stop at seconds: a fraction follows them, where ICU and Apple put it.
    val fraction = skeleton.count { it == 'S' }
    val pattern = DateTimeFormatterBuilder.getLocalizedDateTimePattern(skeleton.filter { it != 'S' }, IsoChronology.INSTANCE, javaLocale)
        .let { if (fraction == 0) it else it.replace("ss", "ss." + "S".repeat(fraction)) }
    return DateTimeFormatter.ofPattern(pattern, javaLocale)
        .format(Instant.ofEpochMilli(epochMillis).atOffset(ZoneOffset.ofTotalSeconds(offsetSeconds)))
}

internal actual fun localizedDate(epochDay: Long, skeleton: String, locale: String): String {
    val javaLocale = Locale.forLanguageTag(locale)
    val pattern = DateTimeFormatterBuilder.getLocalizedDateTimePattern(skeleton, IsoChronology.INSTANCE, javaLocale)
    // The JDK may answer `EEEE` with a nearby pattern's abbreviated weekday; ICU and Apple give the full name.
    val widened = if ("EEEE" in skeleton) pattern.replace(Regex("E+"), "EEEE") else pattern
    return DateTimeFormatter.ofPattern(widened, javaLocale).format(LocalDate.ofEpochDay(epochDay))
}

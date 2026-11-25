package com.edde746.plezy.format

import java.time.DateTimeException
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import java.util.Locale

internal actual fun localizedDate(year: Int, month: Int, day: Int, length: DateLength, locale: String): String? {
    val date = try {
        LocalDate.of(year, month, day)
    } catch (_: DateTimeException) {
        return null
    }
    val style = if (length == DateLength.LONG) FormatStyle.LONG else FormatStyle.MEDIUM
    return DateTimeFormatter.ofLocalizedDate(style).withLocale(Locale.forLanguageTag(locale)).format(date)
}

actual fun localToday(): com.edde746.plezy.model.CalendarDate =
    LocalDate.now().let { com.edde746.plezy.model.CalendarDate(it.year, it.monthValue, it.dayOfMonth) }

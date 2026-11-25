package com.edde746.plezy.format

import android.icu.text.DateFormat
import android.icu.util.GregorianCalendar
import android.icu.util.TimeZone
import android.icu.util.ULocale
import java.util.Calendar

// ICU (API 24), not java.time, which Android has from API 26 on: the app runs on API 25.
internal actual fun localizedDate(year: Int, month: Int, day: Int, length: DateLength, locale: String): String? {
    val calendar = GregorianCalendar(TimeZone.GMT_ZONE).apply {
        isLenient = false
        clear()
        set(year, month - 1, day)
    }
    val date = try {
        calendar.time
    } catch (_: IllegalArgumentException) {
        return null
    }
    val style = if (length == DateLength.LONG) DateFormat.LONG else DateFormat.MEDIUM
    return DateFormat.getDateInstance(style, ULocale.forLanguageTag(locale))
        .apply { timeZone = TimeZone.GMT_ZONE }
        .format(date)
}

actual fun localToday(): com.edde746.plezy.model.CalendarDate =
    Calendar.getInstance().let {
        com.edde746.plezy.model.CalendarDate(it.get(Calendar.YEAR), it.get(Calendar.MONTH) + 1, it.get(Calendar.DAY_OF_MONTH))
    }

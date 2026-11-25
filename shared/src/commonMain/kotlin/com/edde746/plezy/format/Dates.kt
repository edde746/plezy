package com.edde746.plezy.format

import com.edde746.plezy.strings.T

/** How long a date is written: [LONG] "March 4, 2021", [MEDIUM] "Mar 4, 2021". */
enum class DateLength { LONG, MEDIUM }

/**
 * A server's `YYYY-MM-DD` date (a time after it is ignored) in [locale]'s words; the text as it is when it is no such
 * date.
 */
fun formatDate(date: String, length: DateLength = DateLength.LONG, locale: String = T.locale): String {
    val match = ISO_DATE.find(date.trim()) ?: return date
    val (year, month, day) = match.destructured
    return localizedDate(year.toInt(), month.toInt(), day.toInt(), length, locale) ?: date
}

/** The platform's CLDR rendering of the date; null for a date that does not exist. */
internal expect fun localizedDate(year: Int, month: Int, day: Int, length: DateLength, locale: String): String?

private val ISO_DATE = Regex("""^(\d{4})-(\d{2})-(\d{2})""")

/** Today's date in the device's time zone. */
expect fun localToday(): com.edde746.plezy.model.CalendarDate

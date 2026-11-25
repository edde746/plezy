package com.edde746.plezy.format

import kotlin.math.abs
import kotlin.time.Instant

// Locale-aware wording of numbers and dates for catalog surfaces (detail chips, card badges), from the platform's CLDR
// data (JDK/ICU, Foundation). [locale] is a BCP 47 tag, usually `T.locale`.

/**
 * [value] in the locale's short compact form with up to three significant digits: `42`, `1.23K`, `12.3K`, `123K`,
 * `4.5M`.
 */
expect fun formatCompactNumber(value: Long, locale: String): String

/** [fraction] (0–1) as a whole percent: `0.25` → `25%`. */
expect fun formatPercent(fraction: Double, locale: String): String

/**
 * [instant]'s UTC day as a medium date: `Jan 2, 2024`. UTC because catalog dates are mostly date-only values stored as
 * UTC midnight, which a zone west of UTC would show as the previous day.
 */
expect fun formatMediumDate(instant: Instant, locale: String): String

/** [amount] US dollars without cents: `$1,000,000`. */
expect fun formatUsd(amount: Long, locale: String): String

/** The full name of ISO-8601 weekday [isoWeekday] (Monday = 1 … Sunday = 7): `Tuesday`. */
expect fun weekdayName(isoWeekday: Int, locale: String): String

/** [value] rounded half away from zero to [digits] significant digits; values already that short are unchanged. */
internal fun roundToSignificantDigits(value: Long, digits: Int): Long {
    var magnitude = abs(value)
    var factor = 1L
    var limit = 1L
    repeat(digits) { limit *= 10 }
    while (magnitude >= limit) {
        magnitude /= 10
        factor *= 10
    }
    if (factor == 1L) return value
    val half = factor / 2
    return if (value < 0) -((-value + half) / factor * factor) else (value + half) / factor * factor
}

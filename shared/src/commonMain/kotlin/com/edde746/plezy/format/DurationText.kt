package com.edde746.plezy.format

import com.edde746.plezy.strings.Locales
import com.edde746.plezy.strings.T
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

/**
 * [duration] as a card, a detail line or a catalog chip writes it: the abbreviated units of [locale]'s strings (an
 * interface language tag, `T.locale` by default, resolved as the strings are, so `zh-TW` is Traditional) from weeks
 * down to minutes, each after its number and a space, the parts joined by spaces (`1 w 2 d 4 h 12 min`, `2 h`,
 * `45 min`, German `1 Std 5 Min`), rounded to the nearest minute, or seconds when under a minute (`30 s`). Units at
 * zero are left out; a negative duration is signed. A language without units of its own (Azerbaijani, Bulgarian,
 * Danish, Hungarian, Kazakh, Uzbek) writes English.
 */
fun formatDurationTextual(duration: Duration, locale: String = T.locale): String {
    val units = DURATION_UNITS[Locales.resolve(locale)] ?: DURATION_UNITS.getValue("en")
    val totalSeconds = duration.absoluteValue.inWholeSeconds
    val parts = if (totalSeconds < 60) {
        listOf(totalSeconds to units.second)
    } else {
        val totalMinutes = (totalSeconds + 30) / 60
        listOf(
            totalMinutes / (7 * 24 * 60) to units.week,
            totalMinutes / (24 * 60) % 7 to units.day,
            totalMinutes / 60 % 24 to units.hour,
            totalMinutes % 60 to units.minute,
        )
    }
    val text = parts.filter { it.first > 0 }.ifEmpty { listOf(0L to parts.last().second) }
        .joinToString(" ") { (value, unit) -> "$value $unit" }
    return if (duration.isNegative()) "-$text" else text
}

/** [formatDurationTextual] of [milliseconds]. */
fun formatDurationTextual(milliseconds: Long, locale: String = T.locale): String = formatDurationTextual(milliseconds.milliseconds, locale)

private class DurationUnits(val week: String, val day: String, val hour: String, val minute: String, val second: String)

/** Each language's abbreviated units, as Plezy has written them. */
private val DURATION_UNITS: Map<String, DurationUnits> = mapOf(
    "en" to DurationUnits("w", "d", "h", "min", "s"),
    "de" to DurationUnits("W", "T", "Std", "Min", "Sek"),
    "es" to DurationUnits("w", "d", "h", "m", "s"),
    "fr" to DurationUnits("sem", "j", "h", "min", "s"),
    "it" to DurationUnits("set", "g", "h", "m", "s"),
    "ja" to DurationUnits("週", "日", "時間", "分", "秒"),
    "ko" to DurationUnits("주", "일", "시간", "분", "초"),
    "nb" to DurationUnits("u", "d", "t", "m", "s"),
    "nl" to DurationUnits("w", "d", "u", "min", "s"),
    "pl" to DurationUnits("t", "d", "h", "m", "s"),
    "pt" to DurationUnits("sem", "d", "h", "m", "s"),
    "pt-PT" to DurationUnits("sem", "d", "h", "m", "s"),
    "ru" to DurationUnits("нед", "д", "ч", "м", "c"),
    "sv" to DurationUnits("w", "d", "h", "m", "s"),
    "tr" to DurationUnits("h", "g", "s", "d", "s"),
    "zh" to DurationUnits("周", "日", "小时", "分", "秒"),
    "zh-Hant" to DurationUnits("週", "日", "小時", "分鐘", "秒"),
)

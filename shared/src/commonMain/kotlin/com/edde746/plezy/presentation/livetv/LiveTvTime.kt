package com.edde746.plezy.presentation.livetv

import com.edde746.plezy.strings.T

/** The device time zone's offset from UTC at [epochMillis] in seconds, summer time included: `7200` for UTC+2. */
expect fun localUtcOffsetSeconds(epochMillis: Long): Int

/**
 * The time of day of [epochMillis] at [offsetSeconds] east of UTC in [locale]'s words and order for the CLDR
 * [skeleton] (`Hm`: "18:00"; `hm`: "6:00 PM"; `HmsSSS`: "18:00:05.123"), from the platform's CLDR data (JDK/ICU,
 * `NSDateFormatter`). [com.edde746.plezy.format.clockTime] picks the skeleton.
 */
internal expect fun localizedTime(epochMillis: Long, offsetSeconds: Int, skeleton: String, locale: String): String

/** The date [epochDay] (days since 1970-01-01) in [locale]'s words for the CLDR [skeleton] (`EEEE`: "Tuesday", `EEE`: "Tue"). */
internal expect fun localizedDate(epochDay: Long, skeleton: String, locale: String): String

/** "Today", "Tomorrow", else the weekday's short name ("Thu") of [epochSeconds]'s local day. */
fun liveTvRelativeDay(epochSeconds: Long, nowEpochSeconds: Long, utcOffset: (Long) -> Int = ::localUtcOffsetSeconds): String {
    val day = localDay(epochSeconds * 1000, utcOffset)
    return when (day - localDay(nowEpochSeconds * 1000, utcOffset)) {
        0L -> T.liveTv.today
        1L -> T.liveTv.tomorrow
        else -> localizedDate(day, "EEE", T.locale)
    }
}

/** "Today", "Tomorrow", else the weekday's full name ("Thursday") of the local day [epochDay]. */
fun liveTvDayName(epochDay: Long, todayEpochDay: Long): String = when (epochDay - todayEpochDay) {
    0L -> T.liveTv.today
    1L -> T.liveTv.tomorrow
    else -> localizedDate(epochDay, "EEEE", T.locale)
}

/** A program's length in hours and minutes, the zero units left out: "1h 30min", "2h", "45min"; "0min" for none. */
fun liveTvDuration(minutes: Int): String {
    val total = minutes.coerceAtLeast(0)
    val hours = total / 60
    val rest = total % 60
    return when {
        hours == 0 -> T.liveTv.durationMinutes(rest.toString())
        rest == 0 -> T.liveTv.durationHours(hours.toString())
        else -> "${T.liveTv.durationHours(hours.toString())} ${T.liveTv.durationMinutes(rest.toString())}"
    }
}

/** The local calendar day (days since 1970-01-01) of [epochMillis]. */
fun localDay(epochMillis: Long, utcOffset: (Long) -> Int): Long = (epochMillis + utcOffset(epochMillis) * 1000L).floorDiv(MILLIS_PER_DAY)

/**
 * The instant the local wall clock reads [minuteOfDay] minutes past midnight on [epochDay]. A time a summer-time change
 * skips resolves an hour later ("2:30" on the spring-forward night is 3:30); a time it repeats resolves to one of them.
 */
fun localWallTime(epochDay: Long, minuteOfDay: Int, utcOffset: (Long) -> Int): Long {
    val wall = epochDay * MILLIS_PER_DAY + minuteOfDay * 60_000L
    val first = wall - utcOffset(wall) * 1000L
    val second = wall - utcOffset(first) * 1000L
    return listOf(first, second).firstOrNull { it + utcOffset(it) * 1000L == wall } ?: maxOf(first, second)
}

/** Minutes past local midnight of [epochMillis]. */
fun localMinuteOfDay(epochMillis: Long, utcOffset: (Long) -> Int): Int =
    ((epochMillis + utcOffset(epochMillis) * 1000L).mod(MILLIS_PER_DAY) / 60_000L).toInt()

private const val MILLIS_PER_DAY = 86_400_000L

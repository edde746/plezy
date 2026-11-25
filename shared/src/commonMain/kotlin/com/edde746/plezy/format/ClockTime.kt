package com.edde746.plezy.format

import com.edde746.plezy.presentation.livetv.localUtcOffsetSeconds
import com.edde746.plezy.presentation.livetv.localizedTime
import com.edde746.plezy.strings.T

/**
 * The time of day of [epochSeconds] in the device's time zone, to the minute, in the app's language, on the clock the
 * platform's 12/24-hour setting picks ([use24HourClock]): "18:00", else "6:00 PM" ("下午6:00" in Chinese), whatever the
 * language's own habit. Every clock time the app shows reads this way: the player's clock and end time, Live TV's
 * times, a file's deletion time, an airing time.
 */
fun clockTime(epochSeconds: Long, use24HourClock: Boolean): String = clockTime(epochSeconds, use24HourClock, ::localUtcOffsetSeconds)

/** [clockTime] in the time zone [utcOffset] gives, in seconds east of UTC at an epoch millisecond. */
internal fun clockTime(epochSeconds: Long, use24HourClock: Boolean, utcOffset: (Long) -> Int): String {
    val millis = epochSeconds * 1000
    return localizedTime(millis, utcOffset(millis), if (use24HourClock) "Hm" else "hm", T.locale)
}

/** A log record's time at [epochMillis]: [clockTime]'s clock to the millisecond ("18:00:05.123", "6:00:05.123 PM"). */
fun logClockTime(epochMillis: Long, use24HourClock: Boolean): String = logClockTime(epochMillis, use24HourClock, ::localUtcOffsetSeconds)

/** [logClockTime] in the time zone [utcOffset] gives. */
internal fun logClockTime(epochMillis: Long, use24HourClock: Boolean, utcOffset: (Long) -> Int): String =
    localizedTime(epochMillis, utcOffset(epochMillis), if (use24HourClock) "HmsSSS" else "hmsSSS", T.locale)

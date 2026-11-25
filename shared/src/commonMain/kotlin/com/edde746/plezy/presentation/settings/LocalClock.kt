package com.edde746.plezy.presentation.settings

/** How far this device's time zone is ahead of UTC at [epochMillis], in milliseconds (daylight saving included). */
internal expect fun localUtcOffsetMillis(epochMillis: Long): Long

/** [epochMillis] as the device's local wall clock, `HH:MM:SS.mmm`: a log record's time. */
internal fun localTimeOfDay(epochMillis: Long): String {
    val local = epochMillis + localUtcOffsetMillis(epochMillis)
    val dayMillis = local.mod(DAY_MILLIS)
    fun pad(value: Long, width: Int) = value.toString().padStart(width, '0')
    return "${pad(dayMillis / 3_600_000, 2)}:${pad(dayMillis / 60_000 % 60, 2)}:${pad(dayMillis / 1000 % 60, 2)}.${pad(dayMillis % 1000, 3)}"
}

/** The local calendar date of [epochMillis] as year, month (1..12) and day. */
internal fun localDate(epochMillis: Long): Triple<Int, Int, Int> {
    val days = (epochMillis + localUtcOffsetMillis(epochMillis)).floorDiv(DAY_MILLIS)
    // Howard Hinnant's civil-from-days.
    val z = days + 719_468
    val era = z.floorDiv(146_097L)
    val doe = z - era * 146_097
    val yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365
    val doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
    val mp = (5 * doy + 2) / 153
    val day = (doy - (153 * mp + 2) / 5 + 1).toInt()
    val month = (if (mp < 10) mp + 3 else mp - 9).toInt()
    val year = (yoe + era * 400 + if (month <= 2) 1 else 0).toInt()
    return Triple(year, month, day)
}

private const val DAY_MILLIS = 86_400_000L

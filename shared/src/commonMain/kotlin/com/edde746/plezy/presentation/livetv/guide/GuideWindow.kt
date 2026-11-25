package com.edde746.plezy.presentation.livetv.guide

import com.edde746.plezy.format.clockTime
import com.edde746.plezy.presentation.livetv.liveTvDayName
import com.edde746.plezy.presentation.livetv.localDay
import com.edde746.plezy.presentation.livetv.localMinuteOfDay
import com.edde746.plezy.presentation.livetv.localWallTime
import com.edde746.plezy.strings.T

// The guide's time window, in epoch seconds, by the device's wall clock (utcOffset: its offset from UTC at an instant
// in epoch milliseconds, in seconds). Calendar days are counted on the wall clock, so a day across a summer-time change
// is 23 or 25 hours.

/** The window the guide opens on: the current half hour's start an hour back. Its end is [GuideLayout.WINDOW_SECONDS] on. */
fun guideNowWindowStart(nowEpochSeconds: Long, utcOffset: (Long) -> Int): Long = halfHourStart(nowEpochSeconds, utcOffset) - 3600

/** The window on local day [epochDay] at [windowStart]'s time of day: a picked day keeps the time shown. */
fun guideDayWindowStart(windowStart: Long, epochDay: Long, utcOffset: (Long) -> Int): Long =
    localWallTime(epochDay, localMinuteOfDay(windowStart * 1000, utcOffset), utcOffset) / 1000

/** The window starting at [hour] o'clock on local day [epochDay]: a time slot. */
fun guideSlotWindowStart(epochDay: Long, hour: Int, utcOffset: (Long) -> Int): Long = localWallTime(epochDay, hour * 60, utcOffset) / 1000

/** The window a search jump to an airing beginning at [beginsAt] opens: one slot before the half hour it begins in. */
fun guideAiringWindowStart(beginsAt: Long, utcOffset: (Long) -> Int): Long = halfHourStart(beginsAt, utcOffset) - GuideLayout.SLOT_SECONDS

/** The start of the local half hour [epochSeconds] falls in, at [epochSeconds]'s own offset: a repeated hour's two halves stay apart. */
private fun halfHourStart(epochSeconds: Long, utcOffset: (Long) -> Int): Long =
    epochSeconds - (epochSeconds + utcOffset(epochSeconds * 1000)).mod(GuideLayout.SLOT_SECONDS)

/** Whether [epochSeconds] falls in the window from [windowStart] ([GuideLayout.WINDOW_SECONDS] long). */
fun guideWindowContains(windowStart: Long, epochSeconds: Long): Boolean =
    epochSeconds >= windowStart && epochSeconds < windowStart + GuideLayout.WINDOW_SECONDS

/** A time slot of the day picker's second menu: the window starts at [hour] o'clock. */
data class GuideTimeSlot(val label: String, val hour: Int)

/** Midnight 0, Overnight 2, Morning 6, Daytime 12, Evening 18, Late night 22. */
fun guideTimeSlots(): List<GuideTimeSlot> = listOf(
    GuideTimeSlot(T.liveTv.midnight, 0),
    GuideTimeSlot(T.liveTv.overnight, 2),
    GuideTimeSlot(T.liveTv.morning, 6),
    GuideTimeSlot(T.liveTv.daytime, 12),
    GuideTimeSlot(T.liveTv.evening, 18),
    GuideTimeSlot(T.liveTv.lateNight, 22),
)

/** The days the day picker offers after "Now": today and the seven after it. */
const val GUIDE_PICKER_DAYS: Int = 8

/** A half-hour mark of the time header: its time ([epochSeconds]), [label] in the device's clock, [left] across the grid. */
data class GuideTimeMark(val epochSeconds: Long, val label: String, val left: Double)

/** The time header of the window from [windowStart]: one mark per slot. */
fun guideTimeMarks(windowStart: Long, use24HourClock: Boolean, utcOffset: (Long) -> Int): List<GuideTimeMark> =
    (windowStart until windowStart + GuideLayout.WINDOW_SECONDS step GuideLayout.SLOT_SECONDS).map {
        GuideTimeMark(it, clockTime(it, use24HourClock, utcOffset), guideOffsetAt(it, windowStart))
    }

/** "Today", "Tomorrow" or the weekday of local day [epochDay] seen at [nowEpochSeconds]. */
fun guideDayLabel(epochDay: Long, nowEpochSeconds: Long, utcOffset: (Long) -> Int): String =
    liveTvDayName(epochDay, localDay(nowEpochSeconds * 1000, utcOffset))

package com.edde746.plezy.format

import com.edde746.plezy.presentation.livetv.liveTvRelativeDay
import com.edde746.plezy.strings.T
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals

/** The platform's own date and clock formats, in the interface language. */
class LocaleFormattingTest {
    @AfterTest
    fun resetLocale() {
        T.locale = "en"
    }

    /** CLDR separates a time from its AM/PM marker by a narrow no-break space on newer platforms. */
    private fun String.plainSpaces() = replace('\u202F', ' ').replace('\u00A0', ' ')

    @Test
    fun serverDatesReadInTheLanguageAndAnythingElseStaysAsItIs() {
        assertEquals("March 4, 2021", formatDate("2021-03-04"))
        assertEquals("Mar 4, 2021", formatDate("2021-03-04T10:00:00Z", DateLength.MEDIUM))
        assertEquals("4. März 2021", formatDate("2021-03-04", locale = "de"))
        assertEquals("not a date", formatDate("not a date"))
        assertEquals("2021-02-30", formatDate("2021-02-30"))
    }

    @Test
    fun theClockFollowsThePlatformsSettingWhateverTheLanguagesHabit() {
        val sixPm = 18 * 3600L
        assertEquals("18:00", clockTime(sixPm, use24HourClock = true) { 0 })
        assertEquals("6:00 PM", clockTime(sixPm, use24HourClock = false) { 0 }.plainSpaces())
        T.locale = "de"
        assertEquals("18:00", clockTime(sixPm, use24HourClock = true) { 0 })
        assertEquals("6:00 PM", clockTime(sixPm, use24HourClock = false) { 0 }.plainSpaces(), "German on a 12-hour clock too")
    }

    @Test
    fun aLogRecordsTimeFollowsTheClockToTheMillisecond() {
        val millis = (18 * 3600L + 5) * 1000 + 123
        assertEquals("18:00:05.123", logClockTime(millis, use24HourClock = true) { 0 })
        assertEquals("6:00:05.123 PM", logClockTime(millis, use24HourClock = false) { 0 }.plainSpaces())
        assertEquals("06:00:05.123", logClockTime(millis - 12 * 3_600_000, use24HourClock = true) { 0 })
    }

    @Test
    fun aSummerTimeChangeOvernightStillReadsTomorrow() {
        val day = 86_400L
        // 23:30 local the evening before clocks go forward an hour at 02:00 (UTC+1, then UTC+2).
        val now = 10 * day + 22 * 3600L + 30 * 60
        val offset = { millis: Long -> if (millis / 1000 < 11 * day + 3600) 3600 else 7200 }
        assertEquals("Today", liveTvRelativeDay(now + 10 * 60, now, offset))
        assertEquals("Tomorrow", liveTvRelativeDay(11 * day + 21 * 3600L + 59 * 60, now, offset))
        assertNotEquals("Tomorrow", liveTvRelativeDay(11 * day + 22 * 3600L, now, offset))
        assertEquals("Tomorrow", liveTvRelativeDay(11 * day + 3 * 3600L, now, offset))
    }
}

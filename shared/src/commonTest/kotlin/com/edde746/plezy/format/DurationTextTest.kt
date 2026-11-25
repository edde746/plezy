package com.edde746.plezy.format

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.time.Duration.Companion.days
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

class DurationTextTest {
    @Test
    fun `durations read as abbreviated units from weeks down to minutes`() {
        assertEquals("2 h 15 min", formatDurationTextual(135.minutes, "en"))
        assertEquals("2 h", formatDurationTextual(2.hours, "en"))
        assertEquals("1 w 2 d 4 h 12 min", formatDurationTextual(9.days + 4.hours + 12.minutes, "en"))
        assertEquals("30 s", formatDurationTextual(30.seconds, "en"))
        assertEquals("0 s", formatDurationTextual(0.seconds, "en"))
        assertEquals("-1 h 5 min", formatDurationTextual(-65.minutes, "en"))
        assertEquals("1 h 24 min", formatDurationTextual(5_025_000L, "en"))
    }

    @Test
    fun `durations round to the nearest minute`() {
        assertEquals("2 min", formatDurationTextual(90.seconds, "en"))
        assertEquals("1 min", formatDurationTextual(89.seconds, "en"))
        assertEquals("45 min", formatDurationTextual(45.minutes + 29.seconds, "en"))
        assertEquals("1 h", formatDurationTextual(59.minutes + 45.seconds, "en"))
    }

    @Test
    fun `chinese durations use their scripts units`() {
        val duration = 1.hours + 2.minutes
        assertEquals("1 小时 2 分", formatDurationTextual(duration, "zh"))
        assertEquals("1 小時 2 分鐘", formatDurationTextual(duration, "zh-Hant"))
    }

    @Test
    fun `chinese regions pick their scripts units as the strings do`() {
        val duration = 1.hours + 2.minutes
        assertEquals("1 小時 2 分鐘", formatDurationTextual(duration, "zh-TW"))
        assertEquals("1 小時 2 分鐘", formatDurationTextual(duration, "zh-HK"))
        assertEquals("1 小时 2 分", formatDurationTextual(duration, "zh-CN"))
    }

    @Test
    fun `european portuguese writes the portuguese units`() {
        assertEquals("1 h 5 m", formatDurationTextual(65.minutes, "pt-PT"))
        assertEquals("2 sem 1 d", formatDurationTextual(15.days, "pt-AO"))
    }

    @Test
    fun `other languages write their own units or english`() {
        assertEquals("1 Std 5 Min", formatDurationTextual(65.minutes, "de"))
        assertEquals("2 нед 1 д", formatDurationTextual(15.days, "ru"))
        assertEquals("1 h 5 min", formatDurationTextual(65.minutes, "da"), "a language without units of its own writes English")
    }
}

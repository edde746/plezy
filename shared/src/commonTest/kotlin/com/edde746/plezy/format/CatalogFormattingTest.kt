package com.edde746.plezy.format

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.time.Duration.Companion.days
import kotlin.time.Instant

class CatalogFormattingTest {
    @Test
    fun compactCountsKeepThreeSignificantDigits() {
        assertEquals(
            listOf("42", "999", "1.2K", "1.23K", "12.3K", "123K", "1M", "4.5M"),
            listOf(42L, 999L, 1_200L, 1_234L, 12_345L, 123_456L, 999_999L, 4_500_000L).map { formatCompactNumber(it, "en") },
        )
    }

    @Test
    fun roundingToSignificantDigitsRoundsHalfUp() {
        assertEquals(listOf(42L, 1_230L, 12_400L, 1_000_000L), listOf(42L, 1_234L, 12_350L, 999_999L).map { roundToSignificantDigits(it, 3) })
    }

    @Test
    fun dateOnlyValuesKeepTheirUtcDay() {
        assertEquals("Jan 2, 2024", formatMediumDate(Instant.parse("2024-01-02T00:00:00Z"), "en"))
    }

    @Test
    fun percentsCurrencyAndWeekdaysFollowTheLocale() {
        assertEquals("25%", formatPercent(0.25, "en"))
        assertEquals("$1,000,000", formatUsd(1_000_000, "en-US"))
        assertEquals(listOf("Monday", "Sunday"), listOf(1, 7).map { weekdayName(it, "en") })
    }
}

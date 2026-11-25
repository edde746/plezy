package com.edde746.plezy.format

import com.edde746.plezy.presentation.player.localizedDecimal
import kotlin.math.abs
import kotlin.time.Instant
import platform.Foundation.NSDate
import platform.Foundation.NSDateFormatter
import platform.Foundation.NSDateFormatterMediumStyle
import platform.Foundation.NSDateFormatterNoStyle
import platform.Foundation.NSLocale
import platform.Foundation.NSNumber
import platform.Foundation.NSNumberFormatter
import platform.Foundation.NSNumberFormatterCurrencyStyle
import platform.Foundation.NSNumberFormatterPercentStyle
import platform.Foundation.NSTimeZone
import platform.Foundation.dateWithTimeIntervalSince1970
import platform.Foundation.timeZoneForSecondsFromGMT

private val compactUnits = listOf(1_000_000_000_000L to "T", 1_000_000_000L to "B", 1_000_000L to "M", 1_000L to "K")

// Foundation has no compact number style outside Swift's FormatStyle: the digits are localized, the suffixes are the
// short English ones.
actual fun formatCompactNumber(value: Long, locale: String): String {
    val rounded = roundToSignificantDigits(value, 3)
    for ((scale, suffix) in compactUnits) {
        if (abs(rounded) >= scale) return localizedDecimal(rounded.toDouble() / scale, 0, 2, locale) + suffix
    }
    return localizedDecimal(rounded.toDouble(), 0, 0, locale)
}

actual fun formatPercent(fraction: Double, locale: String): String {
    val formatter = NSNumberFormatter().apply {
        numberStyle = NSNumberFormatterPercentStyle
        this.locale = NSLocale(localeIdentifier = locale)
    }
    return formatter.stringFromNumber(NSNumber(double = fraction)) ?: "${(fraction * 100).toLong()}%"
}

actual fun formatMediumDate(instant: Instant, locale: String): String {
    val formatter = NSDateFormatter().apply {
        dateStyle = NSDateFormatterMediumStyle
        timeStyle = NSDateFormatterNoStyle
        this.locale = NSLocale(localeIdentifier = locale)
        timeZone = NSTimeZone.timeZoneForSecondsFromGMT(0)
    }
    return formatter.stringFromDate(NSDate.dateWithTimeIntervalSince1970(instant.toEpochMilliseconds() / 1000.0))
}

actual fun formatUsd(amount: Long, locale: String): String {
    val formatter = NSNumberFormatter().apply {
        numberStyle = NSNumberFormatterCurrencyStyle
        this.locale = NSLocale(localeIdentifier = locale)
        currencyCode = "USD"
        minimumFractionDigits = 0u
        maximumFractionDigits = 0u
    }
    return formatter.stringFromNumber(NSNumber(longLong = amount)) ?: "$$amount"
}

// Foundation lists the weekdays Sunday first.
actual fun weekdayName(isoWeekday: Int, locale: String): String {
    val formatter = NSDateFormatter().apply { this.locale = NSLocale(localeIdentifier = locale) }
    return formatter.weekdaySymbols[isoWeekday % 7] as String
}

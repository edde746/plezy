package com.edde746.plezy.format

import java.text.DateFormat
import java.text.DateFormatSymbols
import java.text.NumberFormat
import java.util.Currency
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import kotlin.time.Instant

actual fun formatPercent(fraction: Double, locale: String): String =
    NumberFormat.getPercentInstance(Locale.forLanguageTag(locale)).format(fraction)

actual fun formatMediumDate(instant: Instant, locale: String): String =
    DateFormat.getDateInstance(DateFormat.MEDIUM, Locale.forLanguageTag(locale)).apply {
        timeZone = TimeZone.getTimeZone("UTC")
    }.format(Date(instant.toEpochMilliseconds()))

actual fun formatUsd(amount: Long, locale: String): String =
    NumberFormat.getCurrencyInstance(Locale.forLanguageTag(locale)).apply {
        currency = Currency.getInstance("USD")
        minimumFractionDigits = 0
        maximumFractionDigits = 0
    }.format(amount)

// Calendar numbers Sunday 1 through Saturday 7.
actual fun weekdayName(isoWeekday: Int, locale: String): String =
    DateFormatSymbols.getInstance(Locale.forLanguageTag(locale)).weekdays[isoWeekday % 7 + 1]

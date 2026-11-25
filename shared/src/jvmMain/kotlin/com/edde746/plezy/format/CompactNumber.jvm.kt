package com.edde746.plezy.format

import java.text.NumberFormat
import java.util.Locale

// The JDK's compact form rounds to whole units; rounding to three significant digits first and allowing two decimals
// gives `1.23K` / `12.3K` / `123K`.
actual fun formatCompactNumber(value: Long, locale: String): String =
    NumberFormat.getCompactNumberInstance(Locale.forLanguageTag(locale), NumberFormat.Style.SHORT).apply {
        maximumFractionDigits = 2
    }.format(roundToSignificantDigits(value, 3))

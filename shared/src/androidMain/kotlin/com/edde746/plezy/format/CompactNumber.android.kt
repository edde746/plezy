package com.edde746.plezy.format

import android.icu.text.CompactDecimalFormat
import android.icu.util.ULocale

actual fun formatCompactNumber(value: Long, locale: String): String =
    CompactDecimalFormat.getInstance(ULocale.forLanguageTag(locale), CompactDecimalFormat.CompactStyle.SHORT).apply {
        setSignificantDigitsUsed(true)
        setMaximumSignificantDigits(3)
    }.format(value)

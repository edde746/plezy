package com.edde746.plezy.presentation.player

import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.useContents
import platform.Foundation.NSCaseInsensitiveSearch
import platform.Foundation.NSDiacriticInsensitiveSearch
import platform.Foundation.NSForcedOrderingSearch
import platform.Foundation.NSLocale
import platform.Foundation.NSMakeRange
import platform.Foundation.NSNumber
import platform.Foundation.NSNumberFormatter
import platform.Foundation.NSNumberFormatterDecimalStyle
import platform.Foundation.NSNumberFormatterRoundHalfUp
import platform.Foundation.NSNumericSearch
import platform.Foundation.NSString
import platform.Foundation.NSWidthInsensitiveSearch
import platform.Foundation.compare
import platform.Foundation.rangeOfString

internal actual fun localizedDecimal(value: Double, minFractionDigits: Int, maxFractionDigits: Int, locale: String): String {
    val formatter = NSNumberFormatter().apply {
        numberStyle = NSNumberFormatterDecimalStyle
        this.locale = NSLocale(localeIdentifier = locale)
        minimumFractionDigits = minFractionDigits.toULong()
        maximumFractionDigits = maxFractionDigits.toULong()
        roundingMode = NSNumberFormatterRoundHalfUp
    }
    return formatter.stringFromNumber(NSNumber(double = value)) ?: value.toString()
}

// The Finder's order (localizedStandardCompare's options), in the given locale rather than the system's.
@OptIn(ExperimentalForeignApi::class)
internal actual fun localeOrder(locale: String): Comparator<String> {
    val language = NSLocale(localeIdentifier = locale)
    val options = NSCaseInsensitiveSearch or NSNumericSearch or NSWidthInsensitiveSearch or NSForcedOrderingSearch
    return Comparator { a, b ->
        val whole = NSMakeRange(0u, a.length.toULong())
        (a as NSString).compare(b, options, whole, language).toInt()
    }
}

@OptIn(ExperimentalForeignApi::class)
internal actual fun localeContains(text: String, needle: String, locale: String): Boolean {
    val options = NSCaseInsensitiveSearch or NSDiacriticInsensitiveSearch or NSWidthInsensitiveSearch
    val whole = NSMakeRange(0u, text.length.toULong())
    val found = (text as NSString).rangeOfString(needle, options, whole, NSLocale(localeIdentifier = locale))
    return found.useContents { length > 0u }
}

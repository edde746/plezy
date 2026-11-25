package com.edde746.plezy.presentation.livetv

import platform.Foundation.NSDate
import platform.Foundation.NSDateFormatter
import platform.Foundation.NSLocale
import platform.Foundation.NSTimeZone
import platform.Foundation.dateWithTimeIntervalSince1970
import platform.Foundation.localTimeZone
import platform.Foundation.timeZoneForSecondsFromGMT

actual fun localUtcOffsetSeconds(epochMillis: Long): Int =
    NSTimeZone.localTimeZone.secondsFromGMTForDate(NSDate.dateWithTimeIntervalSince1970(epochMillis / 1000.0)).toInt()

internal actual fun localizedTime(epochMillis: Long, offsetSeconds: Int, skeleton: String, locale: String): String {
    val formatter = NSDateFormatter().apply {
        this.locale = NSLocale(localeIdentifier = locale)
        timeZone = NSTimeZone.timeZoneForSecondsFromGMT(offsetSeconds.toLong())
        setLocalizedDateFormatFromTemplate(skeleton)
    }
    return formatter.stringFromDate(NSDate.dateWithTimeIntervalSince1970(epochMillis / 1000.0))
}

internal actual fun localizedDate(epochDay: Long, skeleton: String, locale: String): String {
    val formatter = NSDateFormatter().apply {
        this.locale = NSLocale(localeIdentifier = locale)
        timeZone = NSTimeZone.timeZoneForSecondsFromGMT(0)
        setLocalizedDateFormatFromTemplate(skeleton)
    }
    return formatter.stringFromDate(NSDate.dateWithTimeIntervalSince1970(epochDay * 86_400.0))
}

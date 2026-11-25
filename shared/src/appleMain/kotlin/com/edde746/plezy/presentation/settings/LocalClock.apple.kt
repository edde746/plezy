package com.edde746.plezy.presentation.settings

import platform.Foundation.NSDate
import platform.Foundation.NSTimeZone
import platform.Foundation.dateWithTimeIntervalSince1970
import platform.Foundation.localTimeZone

internal actual fun localUtcOffsetMillis(epochMillis: Long): Long =
    NSTimeZone.localTimeZone.secondsFromGMTForDate(NSDate.dateWithTimeIntervalSince1970(epochMillis / 1000.0)) * 1000L

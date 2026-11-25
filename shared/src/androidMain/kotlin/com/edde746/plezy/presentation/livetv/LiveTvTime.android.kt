package com.edde746.plezy.presentation.livetv

import android.icu.text.DateFormat
import android.icu.util.TimeZone
import android.icu.util.ULocale
import java.util.Date

actual fun localUtcOffsetSeconds(epochMillis: Long): Int = java.util.TimeZone.getDefault().getOffset(epochMillis) / 1000

internal actual fun localizedTime(epochMillis: Long, offsetSeconds: Int, skeleton: String, locale: String): String =
    DateFormat.getInstanceForSkeleton(skeleton, ULocale.forLanguageTag(locale))
        .apply { timeZone = TimeZone.getTimeZone("GMT").cloneAsThawed().apply { rawOffset = offsetSeconds * 1000 } }
        .format(Date(epochMillis))

internal actual fun localizedDate(epochDay: Long, skeleton: String, locale: String): String =
    DateFormat.getInstanceForSkeleton(skeleton, ULocale.forLanguageTag(locale))
        .apply { timeZone = TimeZone.GMT_ZONE }
        .format(Date(epochDay * 86_400_000L))

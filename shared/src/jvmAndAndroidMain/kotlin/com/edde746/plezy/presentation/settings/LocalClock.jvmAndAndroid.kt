package com.edde746.plezy.presentation.settings

import java.util.TimeZone

internal actual fun localUtcOffsetMillis(epochMillis: Long): Long = TimeZone.getDefault().getOffset(epochMillis).toLong()

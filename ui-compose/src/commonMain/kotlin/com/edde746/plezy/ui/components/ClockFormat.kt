package com.edde746.plezy.ui.components

import androidx.compose.runtime.Composable

/**
 * Whether the platform shows times on a 24-hour clock: Android's 12/24-hour setting, the desktop's time format. Every
 * clock time on screen follows it ([com.edde746.plezy.format.clockTime]).
 */
@Composable
internal expect fun use24HourClock(): Boolean

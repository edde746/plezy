package com.edde746.plezy.ui.components

import android.text.format.DateFormat
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext

/** Android's 12/24-hour setting, read on each pass (a configuration change brings one). */
@Composable
internal actual fun use24HourClock(): Boolean {
    LocalConfiguration.current
    return DateFormat.is24HourFormat(LocalContext.current)
}

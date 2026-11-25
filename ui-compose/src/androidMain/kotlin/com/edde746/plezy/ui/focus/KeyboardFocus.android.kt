package com.edde746.plezy.ui.focus

import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.isImeVisible
import androidx.compose.runtime.Composable

internal actual val desktopApp: Boolean = false

@OptIn(ExperimentalLayoutApi::class)
@Composable
internal actual fun keyboardShows(): Boolean = WindowInsets.isImeVisible

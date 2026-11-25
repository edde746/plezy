package com.edde746.plezy.ui.focus

import androidx.compose.runtime.Composable
import com.edde746.plezy.ui.navigation.LocalKeyboardHeight

internal actual val desktopApp: Boolean = true

@Composable
internal actual fun keyboardShows(): Boolean = LocalKeyboardHeight.current() > 0

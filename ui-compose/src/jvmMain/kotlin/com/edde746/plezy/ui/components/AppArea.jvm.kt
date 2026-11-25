package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.runtime.Composable

actual val WindowInsets.Companion.appArea: WindowInsets
    @Composable get() = safeDrawing

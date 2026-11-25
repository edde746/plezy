package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.systemBarsIgnoringVisibility
import androidx.compose.foundation.layout.union
import androidx.compose.runtime.Composable

@OptIn(ExperimentalLayoutApi::class)
actual val WindowInsets.Companion.appArea: WindowInsets
    @Composable get() = safeDrawing.union(systemBarsIgnoringVisibility)

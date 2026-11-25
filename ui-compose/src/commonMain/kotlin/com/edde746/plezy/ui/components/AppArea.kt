package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.runtime.Composable

/**
 * What the window keeps the app's content clear of: the safe drawing area ([WindowInsets.Companion.safeDrawing]) with
 * the system bars counted shown or hidden (Android), so the app's place stays put as the player hides and shows them.
 * The player reaches out over the hidden bars' share itself.
 */
expect val WindowInsets.Companion.appArea: WindowInsets
    @Composable get

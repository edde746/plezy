package com.edde746.plezy.ui.components

import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEvent
import androidx.compose.ui.input.key.key

internal actual val KeyEvent.isContextMenuKey: Boolean get() = key == Key.Menu || key == Key.ButtonX || key == Key.ButtonY

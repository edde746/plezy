package com.edde746.plezy.ui.components

import androidx.compose.ui.input.key.KeyEvent
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.nativeKeyCode

internal actual val KeyEvent.isContextMenuKey: Boolean get() = key.nativeKeyCode == java.awt.event.KeyEvent.VK_CONTEXT_MENU

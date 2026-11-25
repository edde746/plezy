@file:OptIn(ExperimentalComposeUiApi::class)

package com.edde746.plezy.ui.player

import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.awt.awtEventOrNull
import androidx.compose.ui.input.key.KeyEvent
import androidx.compose.ui.input.pointer.PointerEvent
import androidx.compose.ui.input.pointer.PointerIcon
import com.edde746.plezy.input.KeySource
import java.awt.Point
import java.awt.Toolkit
import java.awt.image.BufferedImage

internal actual fun PointerEvent.platformClickCount(): Int = awtEventOrNull?.clickCount?.coerceAtLeast(1) ?: 1

internal actual val HiddenPointerIcon: PointerIcon by lazy {
    PointerIcon(Toolkit.getDefaultToolkit().createCustomCursor(BufferedImage(1, 1, BufferedImage.TYPE_INT_ARGB), Point(0, 0), "hidden"))
}

// The desktop's keys come from its keyboard.
internal actual fun KeyEvent.inputSource(): KeySource = KeySource.KEYBOARD

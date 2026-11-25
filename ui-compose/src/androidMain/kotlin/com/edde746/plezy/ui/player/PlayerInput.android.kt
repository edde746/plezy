package com.edde746.plezy.ui.player

import android.view.InputDevice
import androidx.compose.ui.input.key.KeyEvent
import androidx.compose.ui.input.pointer.PointerEvent
import androidx.compose.ui.input.pointer.PointerIcon
import com.edde746.plezy.input.KeySource

// Android reports no click count; the player store pairs taps within the double-tap timeout itself.
internal actual fun PointerEvent.platformClickCount(): Int = 1

// Touch and remotes have no cursor to hide; a mouse keeps the system pointer.
internal actual val HiddenPointerIcon: PointerIcon = PointerIcon.Default

// A full (alphabetic) keyboard is a keyboard; a remote, a D-pad, a gamepad and the system's synthesized keys are not.
internal actual fun KeyEvent.inputSource(): KeySource {
    val device = nativeKeyEvent.device ?: return KeySource.REMOTE
    val keyboard = device.keyboardType == InputDevice.KEYBOARD_TYPE_ALPHABETIC && !device.isVirtual &&
        nativeKeyEvent.isFromSource(InputDevice.SOURCE_KEYBOARD) && !nativeKeyEvent.isFromSource(InputDevice.SOURCE_DPAD)
    return if (keyboard) KeySource.KEYBOARD else KeySource.REMOTE
}

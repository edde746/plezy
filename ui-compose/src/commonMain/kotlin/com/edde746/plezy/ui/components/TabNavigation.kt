package com.edde746.plezy.ui.components

import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEvent
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.type
import com.edde746.plezy.input.TabNavigation
import com.edde746.plezy.input.TabScreen
import com.edde746.plezy.ui.focus.LocalScreenFocus

/**
 * A controller's shoulder buttons (L1 and R1: Android's own key events, the desktop's from its gamepad bridge) for the
 * window's [TabNavigation]. A press acts once, however long it is held (Android repeats a held button). Taken at the
 * app's root ([OverlayHostBox]), so they work wherever focus is, the navigation too.
 */
internal class ShoulderKeys(val tabs: TabNavigation) {
    private val held = mutableSetOf<Key>()

    fun onKey(event: KeyEvent): Boolean {
        val next = when (event.key) {
            Key.ButtonL1 -> false
            Key.ButtonR1 -> true
            else -> return false
        }
        return when (event.type) {
            KeyEventType.KeyDown -> if (held.add(event.key)) tabs.dispatch(next) else true
            KeyEventType.KeyUp -> held.remove(event.key)
            else -> false
        }
    }
}

/**
 * Registers this screen's top tabs ([tabs], the [selected] one) for the shoulder buttons while it is composed and
 * [enabled] (its tabs are shown): L1 and R1 [select] the previous or next tab, stopping at the ends, while the screen is
 * the one on view ([LocalScreenFocus]) and no dialog or sheet is open over the app. [select] shows the tab and focuses
 * its chip.
 */
@Composable
internal fun <T> TabNavigationEffect(tabs: List<T>, selected: T, enabled: Boolean = true, select: (T) -> Unit) {
    val host = LocalOverlayHost.current ?: return
    val screen = LocalScreenFocus.current
    val currentTabs by rememberUpdatedState(tabs)
    val currentSelected by rememberUpdatedState(selected)
    val currentEnabled by rememberUpdatedState(enabled)
    val currentSelect by rememberUpdatedState(select)
    DisposableEffect(host, screen) {
        val tab = TabScreen(
            tabs = { currentTabs },
            selected = { currentSelected },
            select = { currentSelect(it) },
            isActive = { currentEnabled && screen?.onView?.invoke() != false && host.entries.isEmpty() && !host.topHasFocus },
        )
        host.shoulderKeys.tabs.register(tab)
        onDispose { host.shoulderKeys.tabs.unregister(tab) }
    }
}

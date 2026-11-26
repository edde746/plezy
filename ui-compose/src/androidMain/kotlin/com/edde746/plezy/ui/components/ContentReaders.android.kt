package com.edde746.plezy.ui.components

import android.accessibilityservice.AccessibilityServiceInfo
import android.os.Build
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityManager
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext

/**
 * The accessibility manager's answer, updated as accessibility, touch exploration or (Android 13 on) the enabled
 * services change.
 */
@Composable
internal actual fun contentReaderOn(): Boolean {
    val context = LocalContext.current
    val manager = remember(context) { context.getSystemService(AccessibilityManager::class.java) } ?: return true
    var on by remember(manager) { mutableStateOf(manager.readsContent()) }
    DisposableEffect(manager) {
        val state = AccessibilityManager.AccessibilityStateChangeListener { on = manager.readsContent() }
        val touch = AccessibilityManager.TouchExplorationStateChangeListener { on = manager.readsContent() }
        manager.addAccessibilityStateChangeListener(state)
        manager.addTouchExplorationStateChangeListener(touch)
        val services = if (Build.VERSION.SDK_INT >= 33) {
            AccessibilityManager.AccessibilityServicesStateChangeListener { on = manager.readsContent() }
                .also(manager::addAccessibilityServicesStateChangeListener)
        } else {
            null
        }
        on = manager.readsContent()
        onDispose {
            manager.removeAccessibilityStateChangeListener(state)
            manager.removeTouchExplorationStateChangeListener(touch)
            if (Build.VERSION.SDK_INT >= 33 && services != null) manager.removeAccessibilityServicesStateChangeListener(services)
        }
    }
    return on
}

private fun AccessibilityManager.readsContent(): Boolean = readsContent(
    isEnabled,
    isTouchExplorationEnabled,
    getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK).map {
        EnabledService(
            speaks = it.feedbackType and READING_FEEDBACK != 0,
            followsContent = it.eventTypes and CONTENT_EVENTS != 0,
        )
    },
)

private const val READING_FEEDBACK =
    AccessibilityServiceInfo.FEEDBACK_SPOKEN or AccessibilityServiceInfo.FEEDBACK_BRAILLE or AccessibilityServiceInfo.FEEDBACK_AUDIBLE

private const val CONTENT_EVENTS = AccessibilityEvent.TYPE_VIEW_SCROLLED or AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED

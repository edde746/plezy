package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.BoxScope
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.InputMode
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.PointerEventType
import androidx.compose.ui.input.pointer.PointerType
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalInputModeManager

/**
 * [content] that a touch pulling down at its top reloads ([onRefresh]); the indicator spins while [refreshing]. Only a
 * finger pulls: a mouse wheel scrolling up past the top would draw the indicator in with nothing to let it go (a wheel
 * never flings), and keys moving focus up to the top would pull it too. A TV, with no touch, never pulls.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun TouchPullToRefresh(refreshing: Boolean, onRefresh: () -> Unit, modifier: Modifier = Modifier, content: @Composable BoxScope.() -> Unit) {
    // Whether the last press over the content was a finger's; a wheel or a mouse press ends it.
    var touch by remember { mutableStateOf(false) }
    val keys = LocalInputModeManager.current.inputMode != InputMode.Touch
    PullToRefreshBox(
        isRefreshing = refreshing,
        onRefresh = onRefresh,
        modifier = modifier.pointerInput(Unit) {
            awaitPointerEventScope {
                while (true) {
                    val event = awaitPointerEvent(PointerEventPass.Initial)
                    when (event.type) {
                        PointerEventType.Press -> touch = event.changes.all { it.type == PointerType.Touch }
                        PointerEventType.Scroll -> touch = false
                    }
                }
            }
        },
        enabled = touch && !keys,
        content = content,
    )
}

package com.edde746.plezy.presentation.livetv

import com.edde746.plezy.servers.childScope
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlin.time.Duration

/** What opened a [LiveTvRefreshGate] again. */
enum class LiveTvRefreshResumeReason { TAB_SELECTED, SCREEN_SHOWN, APP_FOREGROUND }

/**
 * A Live TV tab's periodic refresh: [onTick] every [interval] while the gate is open, that is while the tab is selected
 * ([setSelected], driven by the Live TV screen), the screen is shown ([setShown]: not covered by another screen or
 * another destination) and the app is in the foreground ([appForeground]). [onPaused] runs when one of them closes,
 * [onResumed] when one opens and the others hold, so a tab can catch up on what it missed. Main thread only; [close]
 * with the tab's store.
 */
class LiveTvRefreshGate(
    parentScope: CoroutineScope,
    private val interval: Duration,
    appForeground: StateFlow<Boolean>,
    private val onTick: suspend () -> Unit,
    private val onPaused: () -> Unit = {},
    private val onResumed: (LiveTvRefreshResumeReason) -> Unit = {},
) {
    private val scope = parentScope.childScope()
    private var selected = false
    private var shown = true
    private var foreground = appForeground.value
    private var ticker: Job? = null

    /** Whether all three hold, so the ticks run. */
    val isOpen: Boolean get() = selected && shown && foreground

    init {
        scope.launch {
            appForeground.collect { setGate(foreground, it, LiveTvRefreshResumeReason.APP_FOREGROUND) { value -> foreground = value } }
        }
    }

    /** The Live TV screen selected (true) or left (false) this tab. */
    fun setSelected(selected: Boolean) =
        setGate(this.selected, selected, LiveTvRefreshResumeReason.TAB_SELECTED) { this.selected = it }

    /** The Live TV screen was shown (true) or hidden (false). */
    fun setShown(shown: Boolean) = setGate(this.shown, shown, LiveTvRefreshResumeReason.SCREEN_SHOWN) { this.shown = it }

    fun close() = scope.cancel()

    private inline fun setGate(current: Boolean, value: Boolean, reason: LiveTvRefreshResumeReason, assign: (Boolean) -> Unit) {
        if (current == value) return
        assign(value)
        syncTicker()
        if (!value) {
            onPaused()
        } else if (isOpen) {
            onResumed(reason)
        }
    }

    private fun syncTicker() {
        ticker?.cancel()
        ticker = null
        if (!isOpen) return
        ticker = scope.launch {
            while (true) {
                delay(interval)
                onTick()
            }
        }
    }
}

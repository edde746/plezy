package com.edde746.plezy.presentation.player

import com.edde746.plezy.log.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/**
 * Drives a platform's display-sleep assertion ([com.edde746.plezy.app.PlatformPlayback.keepDisplayAwake]) from the
 * player's [PlayerUiState.keepAwake]: on while the video plays and hasn't ended, off while paused, at the end, on the
 * failure view and once the player closes.
 *
 * Requests are serialized around the latest desired state: one platform call at a time, each queued request settling
 * on whatever is wanted by the time it runs. A failed call is logged and not recorded as effective, and it is not
 * retried on its own: the same state is tried again only by a later request, while an opposing request that arrived
 * during the failed call still gets its attempt.
 */
class KeepAwakeController(
    private val scope: CoroutineScope,
    private val toggle: suspend (Boolean) -> Unit,
) {
    private val queue = Mutex()
    private var effective: Boolean? = null
    private var desired = false
    private var following: Job? = null

    /** Requests [enabled] and returns once this request's reconciliation has run. Never throws a platform failure. */
    suspend fun setEnabled(enabled: Boolean) {
        desired = enabled
        queue.withLock { reconcile() }
    }

    private suspend fun reconcile() {
        while (effective != desired) {
            val target = desired
            try {
                toggle(target)
                effective = target
            } catch (error: Exception) {
                Log.w(TAG, error) { "Keep awake ${if (target) "enable" else "disable"} failed" }
                if (desired == target) return
            }
        }
    }

    /** [setEnabled] without waiting for it. */
    fun request(enabled: Boolean) {
        scope.launch(start = CoroutineStart.UNDISPATCHED) { setEnabled(enabled) }
    }

    /** Follows [state]'s [PlayerUiState.keepAwake] until [release]. */
    fun follow(state: StateFlow<PlayerUiState>) = followAwake(state.map { it.keepAwake })

    internal fun followAwake(awake: Flow<Boolean>) {
        following?.cancel()
        following = scope.launch(start = CoroutineStart.UNDISPATCHED) {
            awake.distinctUntilChanged().collect { request(it) }
        }
    }

    /** The playback ends: stops following and lets the display sleep. */
    fun release() {
        following?.cancel()
        following = null
        request(false)
    }

    private companion object {
        const val TAG = "KeepAwake"
    }
}

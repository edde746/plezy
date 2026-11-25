package com.edde746.plezy.playback.queue

import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.localizedErrorReason
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.async
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/** How a play-queue launch ended. [message] is what the caller shows (a snackbar); null when nothing is shown. */
sealed interface PlayQueueResult {
    val message: String? get() = null

    /** The queue was published and its item handed to the player. */
    data object Success : PlayQueueResult

    /** The server or the client built a queue without items: "Failed to create a play queue — no items". */
    data object Empty : PlayQueueResult {
        override val message: String get() = T.messages.failedToCreatePlayQueueNoItems
    }

    /** The viewer cancelled the launch while it loaded: nothing was published, nothing played, nothing is shown. */
    data object Cancelled : PlayQueueResult

    /** The launch failed with [cause]; [message] says so ("Failed to Play: …", or that no server can play it). */
    data class Error(val cause: Throwable, override val message: String) : PlayQueueResult
}

/**
 * A play-queue launch in progress. While [loading] is true the caller shows a loading dialog titled [title] ("Play" or
 * "Shuffle") with a Cancel button; Cancel and Back call [cancel], which stops the launch before it publishes a queue
 * or plays anything, and [await] then answers [PlayQueueResult.Cancelled]. [loading] turns false just before the item
 * is handed to the player; from then on [cancel] does nothing.
 */
class PlayQueueLaunch internal constructor(
    val title: String,
    scope: CoroutineScope,
    work: suspend PlayQueueLaunch.() -> PlayQueueResult,
) {
    private val _loading = MutableStateFlow(true)
    val loading: StateFlow<Boolean> = _loading.asStateFlow()

    private var cancelled = false

    private val result: Deferred<PlayQueueResult>

    init {
        result = scope.async {
            val attempt = async { attempt(work) }
            try {
                val outcome = attempt.await()
                if (cancelled) PlayQueueResult.Cancelled else outcome
            } catch (e: CancellationException) {
                currentCoroutineContext().ensureActive()
                if (!cancelled) throw e
                PlayQueueResult.Cancelled
            } finally {
                _loading.value = false
            }
        }
    }

    /** Cancel and Back on the loading dialog: stops the launch unless it already left [loading]. */
    fun cancel() {
        if (!_loading.value || cancelled) return
        cancelled = true
        _loading.value = false
        result.children.forEach { it.cancel() }
    }

    suspend fun await(): PlayQueueResult = result.await()

    /** The loading part is over: the item goes to the player next, which [cancel] no longer stops. */
    internal fun finishLoading() {
        if (cancelled) throw CancellationException("Play queue launch cancelled")
        _loading.value = false
    }

    private suspend fun attempt(work: suspend PlayQueueLaunch.() -> PlayQueueResult): PlayQueueResult = try {
        if (cancelled) throw CancellationException("Play queue launch cancelled")
        work()
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        if (cancelled || (e is MediaServerHttpException && e.isCancellation)) {
            PlayQueueResult.Cancelled
        } else {
            PlayQueueResult.Error(e, T.messages.failedPlayback(action = title, error = localizedErrorReason(e)))
        }
    }
}

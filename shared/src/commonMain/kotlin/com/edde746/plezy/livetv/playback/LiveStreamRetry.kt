package com.edde746.plezy.livetv.playback

import kotlinx.coroutines.CancellationException

enum class LiveStreamRetryResult { SUCCEEDED, FAILED, STALE }

/**
 * One live stream recovery while the caller stays current ([isCurrent], checked after every step). A failure of an
 * attempt that went stale is not reported: a newer operation owns the player and its error.
 *
 * A recovery can hand back the session it was asked to recover (Jellyfin and Emby return the receiver), so a failed
 * attempt never discards a recovered session that is still [currentSession]: it plays on and the next retry adopts it.
 */
suspend fun <S : Any> runLiveStreamRetry(
    recover: suspend () -> S?,
    lookupStreamUrl: suspend (S) -> String?,
    open: suspend (streamUrl: String) -> Unit,
    isCurrent: () -> Boolean,
    adoptSession: (S) -> Unit,
    currentSession: () -> S?,
    reportFailure: (Exception) -> Unit,
    discardSession: (S) -> Unit,
    onFinished: () -> Unit,
): LiveStreamRetryResult {
    var recovered: S? = null
    var adopted = false
    try {
        recovered = recover()
        if (!isCurrent()) return LiveStreamRetryResult.STALE
        checkNotNull(recovered) { "live stream recovery returned no session" }
        val streamUrl = lookupStreamUrl(recovered)
        if (!isCurrent()) return LiveStreamRetryResult.STALE
        checkNotNull(streamUrl) { "live stream recovery returned no URL" }
        open(streamUrl)
        if (!isCurrent()) return LiveStreamRetryResult.STALE
        adoptSession(recovered)
        adopted = true
        return LiveStreamRetryResult.SUCCEEDED
    } catch (cancelled: CancellationException) {
        throw cancelled
    } catch (failure: Exception) {
        if (!isCurrent()) return LiveStreamRetryResult.STALE
        reportFailure(failure)
        return LiveStreamRetryResult.FAILED
    } finally {
        val orphan = recovered
        if (orphan != null && !adopted && orphan !== currentSession()) discardSession(orphan)
        onFinished()
    }
}

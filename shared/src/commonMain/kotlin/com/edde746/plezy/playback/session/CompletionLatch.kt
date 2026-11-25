package com.edde746.plezy.playback.session

import com.edde746.plezy.backend.PlaybackFailureReason
import com.edde746.plezy.servers.QueueNavigationStatus

/**
 * The end-of-video latch: the session's end handling (up next, the stopped report at the duration, the sleep timer's
 * end of video) runs once per approach to the end. Latching is the caller's move ([latch]), so an end the caller
 * didn't handle (a reload under way) stays unlatched and the next end report retries it. It re-arms only once the
 * position moves back out past [rearmWindowMillis] from the end, and never while a prompt shows or a countdown runs.
 */
class CompletionLatch(private val rearmWindowMillis: Long = REARM_WINDOW_MILLIS) {
    /** The end handling already ran for this approach to the end. */
    var triggered: Boolean = false
        private set

    fun latch() {
        triggered = true
    }

    /** New media: cleared whatever shows. */
    fun reset() {
        triggered = false
    }

    /** Re-arms, unless a prompt shows or a countdown runs: the caller decides when re-arming is due. */
    fun rearmIfClear(promptVisible: Boolean, countdownActive: Boolean) {
        if (triggered && !promptVisible && !countdownActive) triggered = false
    }

    /** A position report: re-arms once the position is back out past the re-arm window from the end. */
    fun classifyPosition(positionMillis: Long, durationMillis: Long, promptVisible: Boolean, countdownActive: Boolean) {
        if (durationMillis <= 0) return
        if (positionMillis < durationMillis - rearmWindowMillis) rearmIfClear(promptVisible, countdownActive)
    }

    companion object {
        /** The end region the latch stays latched in. */
        const val REARM_WINDOW_MILLIS = 2000L
    }
}

/**
 * Within this much of the best-known duration an end of file is the video's end. Wide enough for a transcode that ends
 * a couple of seconds short of the server's duration; a stream that died inside it lands where servers count the video
 * watched anyway.
 */
const val SPURIOUS_EOF_TOLERANCE_MILLIS = 10_000L

/** What an end of file from the engine means ([classifyEofSignal]). */
enum class EofSignal { GENUINE, SPURIOUS, UNKNOWN }

/**
 * Whether an end of file at [positionMillis] is the video's end: mpv ends a network stream that died mid-file as a
 * clean end, so the position against the best-known duration decides. The engine's duration alone can't be trusted (a
 * chunked transcode's grows with what was read), so the larger of it and the server's [metadataDurationMillis] counts.
 * No duration at all: [EofSignal.UNKNOWN].
 */
fun classifyEofSignal(positionMillis: Long, playerDurationMillis: Long, metadataDurationMillis: Long?): EofSignal {
    val duration = maxOf(playerDurationMillis, metadataDurationMillis ?: 0)
    if (duration <= 0) return EofSignal.UNKNOWN
    return if (positionMillis >= duration - SPURIOUS_EOF_TOLERANCE_MILLIS) EofSignal.GENUINE else EofSignal.SPURIOUS
}

/** What the end of a video leads to ([completionNavigationAction]). */
enum class CompletionAction { PRESENT_NEXT, RETRY_ADJACENT, EXIT }

/** The next item when there is one; a queue whose lookup failed is looked up again; otherwise the player leaves. */
fun completionNavigationAction(hasNext: Boolean, adjacentStatus: QueueNavigationStatus): CompletionAction = when {
    hasNext -> CompletionAction.PRESENT_NEXT
    adjacentStatus == QueueNavigationStatus.FAILED -> CompletionAction.RETRY_ADJACENT
    else -> CompletionAction.EXIT
}

/** How many times up next's countdown retries a next episode that failed to start for a server blip. */
const val MAX_PLAY_NEXT_TRANSIENT_RETRIES = 2

/** How a next episode that failed to start at the end of a video shows again ([playNextRetryPresentation]). */
enum class PlayNextRetry {
    /** The failure shows as any other. */
    NONE,

    /** Up next shows again without a countdown: playing it is the viewer's move. */
    MANUAL,

    /** Up next shows again counting down, so it retries by itself. */
    COUNTDOWN,
}

/**
 * Whether a next episode that failed to start shows up next again: only one started by the end of a video
 * ([wasAtCompletion]) and only for a server that was unavailable (a blip a retry seconds later rides out). It counts
 * down while auto-play is on, outside watch together, for [MAX_PLAY_NEXT_TRANSIENT_RETRIES] retries; then it waits for
 * the viewer.
 */
fun playNextRetryPresentation(
    wasAtCompletion: Boolean,
    failureReason: PlaybackFailureReason?,
    hasNext: Boolean,
    autoPlayEnabled: Boolean,
    inWatchTogether: Boolean,
    autoRetriesUsed: Int,
): PlayNextRetry {
    if (!wasAtCompletion || !hasNext) return PlayNextRetry.NONE
    if (failureReason != PlaybackFailureReason.SERVER_UNAVAILABLE) return PlayNextRetry.NONE
    val auto = autoPlayEnabled && !inWatchTogether && autoRetriesUsed < MAX_PLAY_NEXT_TRANSIENT_RETRIES
    return if (auto) PlayNextRetry.COUNTDOWN else PlayNextRetry.MANUAL
}

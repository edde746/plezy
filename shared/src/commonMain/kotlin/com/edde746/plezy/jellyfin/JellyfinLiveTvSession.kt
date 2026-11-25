package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.livetv.CaptureBuffer
import com.edde746.plezy.livetv.LiveProgramInfo
import com.edde746.plezy.livetv.LiveTimelineState
import com.edde746.plezy.livetv.LiveTimelineUpdate
import com.edde746.plezy.livetv.LiveTvBackgroundPolicy
import com.edde746.plezy.livetv.LiveTvPlaybackSession
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaSubtitleTrack
import com.edde746.plezy.plex.generateSessionIdentifier
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/**
 * A tuned MediaBrowser channel: the one URL its negotiation settled on (direct play, direct stream or HLS transcode)
 * and `/Sessions/Playing*` heartbeats. No program, no time-shift, no server-side subtitle choice (there is no rebuild
 * of the URL to carry one). A TV app stops it in the background.
 */
internal class JellyfinLiveTvPlaybackSession(
    private val support: JellyfinLiveTvSupport,
    private val playback: JellyfinPlayback,
    private val channelKey: String,
    private val quality: TranscodeQualityPreset,
    private val resolution: LiveStreamResolution,
) : LiveTvPlaybackSession {
    private val tracker = JellyfinLiveSessionTracker(
        playback,
        playSessionId = resolution.playSessionId ?: generateSessionIdentifier(),
        mediaSourceId = resolution.mediaSourceId,
        liveStreamId = resolution.liveStreamId,
        playMethod = resolution.playMethod,
    )

    override val program: LiveProgramInfo get() = LiveProgramInfo.NONE
    override val backgroundPolicy: LiveTvBackgroundPolicy get() = LiveTvBackgroundPolicy.STOP_AND_EXIT
    override val captureBuffer: CaptureBuffer? get() = null
    override val subtitleTracks: List<MediaSubtitleTrack> get() = emptyList()
    override val canTimeShift: Boolean get() = false

    override suspend fun streamUrlAt(offsetSeconds: Long?, subtitleTrack: MediaSubtitleTrack?): String? =
        if (offsetSeconds == null && subtitleTrack == null) resolution.url else null

    /** Heartbeats are best effort and learn nothing: always null. */
    override suspend fun reportTimeline(state: LiveTimelineState, positionMs: Long, durationMs: Long): LiveTimelineUpdate? {
        tracker.report(channelKey, state, positionMs.milliseconds, durationMs.milliseconds)
        return null
    }

    override suspend fun discard() = support.release(resolution)

    /**
     * A transcode returns itself: reopening its HLS URL makes the server rebuild the job for the same play session. A
     * direct session asked to drop [directStream] renegotiates a forced transcode; that opens its own live stream and
     * the player adopts it without stop-reporting this one, so this session's stream is closed here. [directStreamAudio]
     * has no lever beyond the transcode.
     */
    override suspend fun recover(directStream: Boolean, directStreamAudio: Boolean): LiveTvPlaybackSession? {
        if (resolution.playMethod == JellyfinLiveTvSupport.TRANSCODE || directStream) return this
        val replacement = try {
            support.resolveStream(channelKey, quality, forceTranscode = true)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Live TV transcode renegotiation failed" }
            null
        } ?: return null
        resolution.liveStreamId?.let(support::closeLiveStreamLater)
        return JellyfinLiveTvPlaybackSession(support, playback, channelKey, quality, replacement)
    }

    private companion object {
        const val TAG = "JellyfinLiveTvSession"
    }
}

/**
 * Orders one live session's `/Sessions/Playing*` reports: the first heartbeat starts the session, later ones report
 * progress, a stop ends it for good. A same-state heartbeat while the start is in flight is dropped; a stop waits for
 * the start in flight and drops queued progress. Failures are logged and dropped; a failed start is retried by the
 * next heartbeat.
 */
internal class JellyfinLiveSessionTracker(
    private val playback: JellyfinPlayback,
    private val playSessionId: String,
    private val mediaSourceId: String?,
    private val liveStreamId: String?,
    private val playMethod: String?,
) {
    private val mutex = Mutex()
    private var startState: LiveTimelineState? = null
    private var started = false
    private var stopRequested = false

    suspend fun report(itemId: String, state: LiveTimelineState, position: Duration, duration: Duration) {
        try {
            send(itemId, state, position, duration)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.d(TAG, e) { "Jellyfin live progress report failed" }
        }
    }

    private suspend fun send(itemId: String, state: LiveTimelineState, position: Duration, duration: Duration) {
        if (state == LiveTimelineState.STOPPED) {
            if (stopRequested) return
            stopRequested = true
            mutex.withLock { playback.reportPlaybackStopped(itemId, position, duration, playSessionId, liveStreamId, mediaSourceId) }
            return
        }
        if (stopRequested) return
        val pendingStart = startState
        if (pendingStart == null) {
            startState = state
            mutex.withLock {
                try {
                    playback.reportPlaybackStarted(itemId, position, duration, playSessionId, playMethod, liveStreamId, mediaSourceId)
                } catch (e: Exception) {
                    startState = null
                    throw e
                }
                started = true
            }
            return
        }
        if (!started && pendingStart == state) return
        mutex.withLock {
            if (stopRequested || !started) return
            playback.reportPlaybackProgress(
                itemId, position, duration, isPaused = state == LiveTimelineState.PAUSED,
                playSessionId = playSessionId, playMethod = playMethod, liveStreamId = liveStreamId, mediaSourceId = mediaSourceId,
            )
        }
    }

    private companion object {
        const val TAG = "JellyfinLiveSession"
    }
}

package com.edde746.plezy.livetv.playback

import com.edde746.plezy.livetv.CaptureBuffer
import com.edde746.plezy.livetv.LiveProgramInfo
import com.edde746.plezy.livetv.LiveTimelineState
import com.edde746.plezy.livetv.LiveTimelineUpdate
import com.edde746.plezy.livetv.LiveTvBackgroundPolicy
import com.edde746.plezy.livetv.LiveTvPlaybackSession
import com.edde746.plezy.model.MediaSubtitleTrack
import kotlinx.coroutines.CompletableDeferred

/**
 * A tuned channel for the player's tests. Heartbeats either answer at once with [timelineAnswer] or, with [holdReports],
 * wait until a test completes them ([completeReport]); every call is recorded.
 */
class FakeLivePlaybackSession(
    val name: String = "session",
    override val captureBuffer: CaptureBuffer? = null,
    override val program: LiveProgramInfo = LiveProgramInfo(durationMs = 999),
    override val backgroundPolicy: LiveTvBackgroundPolicy = LiveTvBackgroundPolicy.RETAIN_SESSION,
    override val subtitleTracks: List<MediaSubtitleTrack> = emptyList(),
    override val canTimeShift: Boolean = captureBuffer != null,
    /** Called as each heartbeat is sent, before it answers. */
    private val onReport: (LiveTimelineState) -> Unit = {},
) : LiveTvPlaybackSession {
    val states = mutableListOf<LiveTimelineState>()
    val positions = mutableListOf<Long>()
    val durations = mutableListOf<Long>()
    val urlRequests = mutableListOf<Pair<Long?, MediaSubtitleTrack?>>()
    val recoveries = mutableListOf<Pair<Boolean, Boolean>>()
    var discarded = 0

    var holdReports = false
    var timelineAnswer: LiveTimelineUpdate? = null
    private val reports = mutableListOf<CompletableDeferred<LiveTimelineUpdate?>>()

    /** The URL for an open at [offset] (null: the edge) with [subtitle]; null refuses. */
    var url: suspend (offset: Long?, subtitle: MediaSubtitleTrack?) -> String? = { offset, subtitle ->
        "https://live.example/$name" + (offset?.let { "?offset=$it" } ?: "") + (subtitle?.let { "#burn=${it.id}" } ?: "")
    }
    var recovered: suspend (directStream: Boolean, directStreamAudio: Boolean) -> LiveTvPlaybackSession? = { _, _ -> this }

    fun completeReport(index: Int, update: LiveTimelineUpdate?) {
        reports[index].complete(update)
    }

    override suspend fun streamUrlAt(offsetSeconds: Long?, subtitleTrack: MediaSubtitleTrack?): String? {
        urlRequests += offsetSeconds to subtitleTrack
        return url(offsetSeconds, subtitleTrack)
    }

    override suspend fun reportTimeline(state: LiveTimelineState, positionMs: Long, durationMs: Long): LiveTimelineUpdate? {
        onReport(state)
        states += state
        positions += positionMs
        durations += durationMs
        if (!holdReports) return timelineAnswer
        val report = CompletableDeferred<LiveTimelineUpdate?>()
        reports += report
        return report.await()
    }

    override suspend fun discard() {
        discarded++
    }

    override suspend fun recover(directStream: Boolean, directStreamAudio: Boolean): LiveTvPlaybackSession? {
        recoveries += directStream to directStreamAudio
        return recovered(directStream, directStreamAudio)
    }

    override fun toString(): String = "FakeLivePlaybackSession($name)"
}

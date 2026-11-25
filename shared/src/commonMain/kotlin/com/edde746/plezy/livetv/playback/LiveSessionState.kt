package com.edde746.plezy.livetv.playback

import com.edde746.plezy.livetv.CaptureBuffer
import com.edde746.plezy.livetv.LiveTvPlaybackSession
import com.edde746.plezy.model.MediaSubtitleTrack
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Deferred
import kotlin.math.roundToLong
import kotlin.time.Clock
import kotlin.time.Instant

/**
 * The mutable state of one live playback: the adopted [LiveTvPlaybackSession], the capture buffer time-shift moves in,
 * the live clock (epoch time of the player's position), the replacement bookkeeping of starts and zaps, and the retry
 * ladder. [LivePlayerSession] owns the logic and reads and writes through this, so the state has one boundary.
 *
 * The live clock: [streamStartEpoch] is the epoch of player position zero for the open stream. An open at the edge
 * anchors it provisionally ([markStreamRestartedAtLiveEdge]); an offset open registers its target epoch
 * ([beginClockOpen]) and calibrates it against the first rendered position of the source the load reported
 * ([bindClockOpen], [calibrateClockSource]); a heartbeat then re-anchors it on the server's own origin for the playback
 * transcode ([adoptPlaybackStreamOrigin]).
 */
class LiveSessionState(private val clock: Clock = Clock.System) {
    /** The session playing. Null until the first start adopts one. */
    var session: LiveTvPlaybackSession? = null
        private set

    /** Reports of [session], in order ([LiveTimelineReportQueue]); a new queue with every adopted session. */
    var timelineReports = LiveTimelineReportQueue()
        private set

    /** Bumped whenever the heartbeat is started or stopped: a report of an older one never commits. */
    var timelineGeneration = 0

    /** When the stream (re)started: heartbeats report the time since as the position. */
    var playbackStartedAt: Instant? = null

    /** The seekable window: from [session] on adoption, then from heartbeats. */
    var captureBuffer: CaptureBuffer? = null

    /**
     * The server-side subtitle the stream delivers (Plex's burn), or null when off. Every rebuild (time-shift, retry)
     * re-applies it; [adoptSession] clears it, as stream ids belong to one tune.
     */
    var selectedSubtitle: MediaSubtitleTrack? = null

    var streamStartEpoch = 0.0
    var atLiveEdge = true

    /** Bumped on every stream open: a heartbeat dispatched before cannot re-anchor its replacement's clock. */
    var streamGeneration = 0

    /** The target epoch of an offset open still calibrating; the clock reads it until then. */
    var pendingStreamEpoch: Double? = null
        private set

    private var nextClockGeneration = 0
    private var latestClockGeneration: Int? = null
    private val clockOpensBySource = mutableMapOf<Long, ClockOpen>()
    private val clockOpensByGeneration = mutableMapOf<Int, ClockOpen>()

    /** Recent source reports no open has claimed, in arrival order, bounded: opens that never register can't grow it. */
    private val unclaimedSources = LinkedHashMap<Long, UnclaimedSource>()

    /** The retry ladder: 0 direct stream and direct stream audio, 1 no direct stream, 2 neither. */
    var fallbackLevel = 0
    var retrying = false
    var retryFailed = false

    /** The heartbeat was running when a TV app went to the background: it restarts on return. */
    var resumeTimelineOnResume = false

    /** A session that can't be kept was stopped while a TV app was in the background: the player leaves on return. */
    var exitOnResume = false

    private var replacementToken = 0
    private var replacementBaseline: Int? = null
    private var deferredFailureGeneration: Int? = null

    /** A start or a zap is about to replace the stream; returns the token [endReplacement] takes. A newer one supersedes it. */
    fun beginReplacement(): Int {
        replacementBaseline = streamGeneration
        deferredFailureGeneration = null
        return ++replacementToken
    }

    /**
     * A stream failed while a replacement holds the transition. Once the replacement opened its stream, the failure is
     * that stream's: parked (true) for [endReplacement] to hand back. A failure of the stream being replaced is false:
     * the replacement supersedes it.
     */
    fun deferReplacementFailure(): Boolean {
        val baseline = replacementBaseline ?: return false
        if (streamGeneration == baseline) return false
        deferredFailureGeneration = streamGeneration
        return true
    }

    /**
     * Ends the replacement [token] began. Whether a failure [deferReplacementFailure] parked must now run recovery:
     * only when the replacement [committed] and the failed stream still plays.
     */
    fun endReplacement(token: Int, committed: Boolean): Boolean {
        if (token != replacementToken) return false
        val deferred = deferredFailureGeneration
        replacementBaseline = null
        deferredFailureGeneration = null
        return committed && deferred != null && deferred == streamGeneration
    }

    /**
     * Registers an offset open before its load: the returned generation is bound to the source the load reports
     * ([bindClockOpen]); until then no source report reaches it. Supersedes every earlier open.
     */
    fun beginClockOpen(targetEpoch: Long): Int {
        (clockOpensByGeneration.values + clockOpensBySource.values).toSet().forEach { open ->
            open.canceled = true
            open.result.complete(false)
        }
        clockOpensByGeneration.clear()
        clockOpensBySource.clear()
        val open = ClockOpen(++nextClockGeneration, targetEpoch)
        clockOpensByGeneration[open.generation] = open
        latestClockGeneration = open.generation
        pendingStreamEpoch = targetEpoch.toDouble()
        return open.generation
    }

    /**
     * Binds [generation] to the source its load reported. Reports that already came for [sourceId] apply now, so a
     * readiness or failure that beat the load's reply isn't lost. Whether the open is still live and keyed by the source.
     */
    fun bindClockOpen(generation: Int, sourceId: Long): Boolean {
        val open = clockOpensByGeneration[generation] ?: return false
        open.sourceId = sourceId
        if (open.canceled) {
            unclaimedSources.remove(sourceId)
            return false
        }
        clockOpensBySource[sourceId] = open
        val observed = unclaimedSources.remove(sourceId) ?: return true
        if (observed.failed) {
            failClockOpen(open)
            return false
        }
        observed.readyPositionSeconds?.let { calibrateClockSource(sourceId, it) }
        return true
    }

    /**
     * Calibrates the clock against the first rendered position of source [sourceId]. The readiness of a source no open
     * claimed yet is kept for a later [bindClockOpen].
     */
    fun calibrateClockSource(sourceId: Long, positionSeconds: Double): Boolean {
        val open = clockOpensBySource.remove(sourceId)
        if (open == null) {
            unclaimedSource(sourceId).readyPositionSeconds = positionSeconds
            return false
        }
        if (open.canceled || open.generation != latestClockGeneration) return false
        streamStartEpoch = open.targetEpoch - positionSeconds
        pendingStreamEpoch = null
        clockOpensByGeneration.remove(open.generation)
        open.result.complete(true)
        return true
    }

    fun failClockSource(sourceId: Long) {
        val open = clockOpensBySource.remove(sourceId)
        if (open == null) {
            unclaimedSource(sourceId).failed = true
            return
        }
        failClockOpen(open)
    }

    fun failClockOpen(generation: Int) {
        clockOpensByGeneration[generation]?.let(::failClockOpen)
    }

    /** Releases an awaiter while the requested epoch stays authoritative: a late readiness can still calibrate. */
    fun timeoutClockOpen(generation: Int) {
        val open = clockOpensByGeneration[generation] ?: return
        if (open.canceled || generation != latestClockGeneration) return
        pendingStreamEpoch = open.targetEpoch.toDouble()
        open.result.complete(false)
    }

    /**
     * True once the open's source is calibrated, false when it was superseded, failed or timed out. A timed-out open
     * stays registered, so a late load reply or readiness can still bind and calibrate it.
     */
    fun clockOpenResult(generation: Int): Deferred<Boolean> =
        clockOpensByGeneration[generation]?.result ?: CompletableDeferred(false)

    fun cancelClockOpens() {
        clockOpensByGeneration.keys.toList().forEach(::failClockOpen)
        clockOpensBySource.clear()
        unclaimedSources.clear()
        latestClockGeneration = null
        pendingStreamEpoch = null
    }

    fun epochForPosition(positionSeconds: Double): Long =
        pendingStreamEpoch?.roundToLong() ?: (streamStartEpoch + positionSeconds).roundToLong()

    /**
     * Re-anchors the clock on the playback transcode's origin: its `timeStamp` is the epoch of stream position zero,
     * which no guess on this side (the wall clock at open, the requested offset) matches once tuner latency and keyframe
     * snapping play in. Skipped while an open calibrates (the heartbeat may describe the transcode being replaced) and
     * for a heartbeat dispatched before the stream's last open. Whether the anchor moved.
     */
    fun adoptPlaybackStreamOrigin(playbackStream: CaptureBuffer, generation: Int): Boolean {
        if (generation != streamGeneration || pendingStreamEpoch != null) return false
        if (streamStartEpoch == playbackStream.startedAt) return false
        streamStartEpoch = playbackStream.startedAt
        return true
    }

    /** Makes [newSession] current and seeds the window from its tune; every start, retry and zap adopts here. */
    fun adoptSession(newSession: LiveTvPlaybackSession) {
        if (session !== newSession) timelineReports = LiveTimelineReportQueue()
        session = newSession
        captureBuffer = newSession.captureBuffer
        selectedSubtitle = null
    }

    /**
     * The stream just (re)started at the live edge. [buffer] is the freshest capture window known for it: an open
     * without an offset starts at the capture's edge, the provisional anchor until a heartbeat reports the transcode's
     * origin. Not the wall clock: the edge trails real time by the tuner's ingest latency, and a skip back from a
     * wall-clock anchor landed on or after the frame shown.
     */
    fun markStreamRestartedAtLiveEdge(buffer: CaptureBuffer?) {
        val now = clock.now()
        playbackStartedAt = now
        streamStartEpoch = buffer?.let { it.startedAt + it.seekEndSeconds } ?: (now.toEpochMilliseconds() / 1000.0)
        atLiveEdge = true
    }

    private fun failClockOpen(open: ClockOpen) {
        open.canceled = true
        val sourceId = open.sourceId
        if (sourceId != null && clockOpensBySource[sourceId] === open) clockOpensBySource.remove(sourceId)
        if (clockOpensByGeneration[open.generation] === open) clockOpensByGeneration.remove(open.generation)
        if (latestClockGeneration == open.generation) {
            latestClockGeneration = null
            pendingStreamEpoch = null
        }
        open.result.complete(false)
    }

    private fun unclaimedSource(sourceId: Long): UnclaimedSource {
        unclaimedSources.remove(sourceId)?.let { existing ->
            unclaimedSources[sourceId] = existing
            return existing
        }
        if (unclaimedSources.size >= MAX_UNCLAIMED_SOURCES) unclaimedSources.remove(unclaimedSources.keys.first())
        return UnclaimedSource().also { unclaimedSources[sourceId] = it }
    }

    private class ClockOpen(val generation: Int, val targetEpoch: Long) {
        val result = CompletableDeferred<Boolean>()
        var sourceId: Long? = null
        var canceled = false
    }

    /** What the player reported of a source no open has claimed yet: the load's reply and its events race. */
    private class UnclaimedSource {
        var readyPositionSeconds: Double? = null
        var failed = false
    }

    companion object {
        private const val MAX_UNCLAIMED_SOURCES = 8

        /**
         * Re-maps a subtitle choice onto a replacement session's tracks. Stream ids belong to one tune, so the
         * equivalent track is found by the same id, else the same language and stream index, else the first track of
         * the same language.
         */
        fun remapSubtitleSelection(tracks: List<MediaSubtitleTrack>, previous: MediaSubtitleTrack?): MediaSubtitleTrack? {
            previous ?: return null
            var languageMatch: MediaSubtitleTrack? = null
            for (track in tracks) {
                if (track.id == previous.id) return track
                if (track.languageCode != previous.languageCode) continue
                if (track.index != null && track.index == previous.index) return track
                if (languageMatch == null) languageMatch = track
            }
            return languageMatch
        }
    }
}

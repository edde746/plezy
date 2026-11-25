package com.edde746.plezy.playback.report

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.PlaybackSessionTerminatedException
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaAudioTrack
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaSourceInfo
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.isWatchedProgress
import com.edde746.plezy.playback.tracks.NativeSubtitleTrack
import com.edde746.plezy.playback.tracks.NativeTracks
import com.edde746.plezy.playback.tracks.findSourceTrackForNativeSubtitle
import com.edde746.plezy.playback.tracks.playingSourceAudioTrack
import com.edde746.plezy.servers.WatchPatchId
import com.edde746.plezy.servers.WatchStateNotifier
import com.edde746.plezy.servers.notifyWatchedFromPlaybackSession
import kotlin.coroutines.cancellation.CancellationException
import kotlin.math.abs
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * What the tracker reads from the player at each report. [isActive]: playing and not at the end. [tracks] (a null or
 * [NativeSubtitleTrack.OFF] subtitle: off) map the selection back to the server's stream indexes; a player without
 * them (music) leaves them empty.
 */
data class PlayerProgress(
    val position: Duration,
    val duration: Duration,
    val isActive: Boolean,
    val tracks: NativeTracks = NativeTracks(),
)

/**
 * Where progress waits for the next sync when no server takes it: the offline watch queue
 * ([com.edde746.plezy.servers.OfflineWatchSyncService.queueProgressUpdate]). Offsets and durations in milliseconds.
 */
fun interface OfflineProgressQueue {
    suspend fun queueProgress(serverId: ServerId, itemId: String, viewOffsetMs: Long, durationMs: Long?)
}

/** The play methods a report names. */
object PlayMethod {
    const val TRANSCODE = "Transcode"
    const val DIRECT_PLAY = "DirectPlay"

    /** The server's own play method when it named one, else by whether the server transcodes. */
    fun of(serverPlayMethod: String?, transcoding: Boolean): String = serverPlayMethod ?: if (transcoding) TRANSCODE else DIRECT_PLAY
}

/**
 * Reports one item's playback progress to its server, or to the offline queue, and settles its watched state.
 *
 * - Every [updateInterval] (10 s) from [startTracking] it reports playing or paused; a paused tick also runs
 *   [onPausedKeepalive] (one at a time). Nothing is reported while the duration is 0 (not ready) or, except stopped,
 *   while [canReportPlayback] says no; positions are clamped to the duration.
 * - Online reports go through one [PlaybackReportSession]. After a failed playing or paused report it skips
 *   `min(2^(n-1), 6)` ticks for n failures in a row; any success resets that. With [queueOnOnlineFailure] (a download
 *   played online) a failed report also queues the position offline. Offline ([isOffline]) every report is queued.
 * - The first report at or past [MediaBackend.watchedThreshold] marks the item watched locally, once. The server's mark
 *   is settled without counting the watch twice: a backend that marks on the stopped report
 *   ([MediaBackend.marksWatchedOnPlaybackStopped]) gets none; one that saw a delivered report below the threshold and
 *   then one past it marked it itself; otherwise [MediaBackend.markWatched] runs when the session ends (retried on the
 *   next delivered report if it fails). Then [onScrobbled] runs, once.
 * - [WatchStateNotifier.notifyProgress] fires as the position moves 30 s from the last one (or first becomes
 *   server-acknowledged), and once on stop; never after the watched mark, never at a zero position or duration.
 * - The server ending the session ([PlaybackSessionTerminatedException]) closes it with one stopped report; it stays
 *   closed (no keepalive) until the viewer pauses then plays again ([stoppedByServer]).
 *
 * Runs its reports in [scope]; call from its thread.
 */
class PlaybackProgressTracker(
    /** The item's server, for the tracker's whole life; null offline. */
    private val backend: MediaBackend?,
    private val item: MediaItem,
    /** Read at each report. */
    private val player: () -> PlayerProgress,
    private val scope: CoroutineScope,
    private val notifier: WatchStateNotifier,
    private val isOffline: Boolean = false,
    private val offlineQueue: OfflineProgressQueue? = null,
    private val queueOnOnlineFailure: Boolean = false,
    /** [PlayMethod]; null when unknown. */
    playMethod: String? = null,
    /** The server's playback session id, echoed in every report (Jellyfin ties transcodes to it). */
    playSessionId: String? = null,
    /** The playing source: its id and tracks give the stream indexes reported. Null reports none. */
    private val mediaInfo: MediaSourceInfo? = null,
    /**
     * The "remember track selections" setting, read per report: off reports only the source id. When it can't be read
     * (it throws) the indexes are reported.
     */
    private val rememberTrackSelections: () -> Boolean = { true },
    /** Runs once after the item's own watched mark is settled on the server (same-file siblings). Failures are logged. */
    private val onScrobbled: (suspend () -> Unit)? = null,
    /** Runs on paused ticks (Plex's transcode keepalive ping). Failures are logged. */
    private val onPausedKeepalive: (suspend () -> Unit)? = null,
    /** Whether the player shows real output now (first frame, no fatal error); playing and paused wait for it. */
    private val canReportPlayback: () -> Boolean = { true },
    /**
     * Whether this item ever showed output. False: a stop still ends the server's session, but at the last reportable
     * position (else the item's resume offset) and without counting as watched. Defaults to [canReportPlayback].
     */
    private val hasRenderedPlayback: (() -> Boolean)? = null,
    /** False when subtitles are off only because a carried choice was declined: then off is not reported as -1. */
    private val subtitleOffIsDeliberate: () -> Boolean = { true },
    /** The source subtitle stream the server burns into the picture, reported while the engine's subtitle is off. */
    private val burnedSubtitleStreamIndex: () -> Int? = { null },
    private val updateInterval: Duration = 10.seconds,
) {
    init {
        require(!isOffline || offlineQueue != null) { "offlineQueue is required offline" }
        require(isOffline || backend != null) { "backend is required online" }
    }

    private val reportSession: PlaybackReportSession? =
        if (isOffline || backend == null) {
            null
        } else {
            PlaybackReportSession(
                backend = backend,
                itemId = item.id,
                scope = scope,
                playSessionId = playSessionId,
                playMethod = playMethod,
                onDelivered = ::onReportDelivered,
            )
        }

    private var ticker: Job? = null
    private var consecutiveFailures = 0
    private var ticksToSkip = 0
    private var pausedKeepaliveInFlight = false

    /** The item counts as watched locally: latched on the first report at or past the threshold. */
    private var scrobbled = false

    /**
     * The server took a report of this session at a position above zero and below the threshold, so a later one at or
     * past it is a crossing it sees. Zero doesn't count: Plex treats it as the session's start, not progress.
     */
    private var deliveredBelow = false

    /** The server took a crossing and marked the item itself; an explicit mark would count the watch twice. */
    private var serverObservedCrossing = false

    /** The stopped report was delivered: nothing later changes what the server saw. */
    private var sessionEnded = false
    private var pendingSettle: Job? = null
    private var serverMarkSettled = false
    private var scrobbledHookRan = false

    /** Whether each delivered playing/paused snapshot made the server keep its position; keyed by identity. */
    private val deliveredAcknowledgements = HashMap<PlaybackReportSnapshot, Boolean>()
    private var hasDeliveredStart = false

    /** The delivered stop reached a session able to act on it (MediaBrowser drops one for a session never opened). */
    private var stoppedReportActedOn = false
    private var stoppedProgressServerAcknowledged = false
    private var lastProgressNotificationServerAcknowledged = false
    private var watchedPatchId: WatchPatchId? = null
    private var stopProgressNotified = false
    private var serverTerminatedSession = false
    private var pausedSinceServerTermination = false
    private var serverTerminationStop: CompletableDeferred<Unit>? = null
    private var stoppedProgress: CompletableDeferred<Unit>? = null
    private var lastProgressNotifiedPosition: Duration? = null
    private var lastReportablePosition: Duration? = null

    /** The stopped report reached the server (offline: always true). Not the same as [sendStoppedProgressOnce] returning. */
    val stoppedReportDelivered: Boolean get() = reportSession?.isStopped ?: true

    /**
     * The server ended this item's session and the viewer hasn't resumed since: buffered playback may still run, but
     * nothing (auto-advance, a rebuilt stream) may start on the viewer's behalf.
     */
    val stoppedByServer: Boolean get() = serverTerminatedSession

    /**
     * Starts the ticks and, when the player plays, reports playing now. [initialPosition] and [initialDuration] stand in
     * for the player's for that first report only (a gapless music advance still reads the previous track). A second
     * call does nothing.
     */
    fun startTracking(initialPosition: Duration? = null, initialDuration: Duration? = null) {
        if (ticker != null) {
            Log.w(TAG) { "progress tracking already started" }
            return
        }
        if (player().isActive) launchReport(PlaybackReportState.PLAYING, initialPosition, initialDuration)
        ticker = scope.launch {
            while (true) {
                delay(updateInterval)
                tick()
            }
        }
    }

    /** Stops the ticks; reports in flight finish. */
    fun stopTracking() {
        ticker?.cancel()
        ticker = null
    }

    /**
     * The engine's audio or subtitle selection changed: online, a report goes now so the server learns it; not while
     * paused before any session started, nor before [startTracking].
     */
    fun onTracksChanged() {
        if (isOffline || ticker == null) return
        val active = player().isActive
        if (!active && (reportSession?.isIdle ?: true)) return
        launchReport(if (active) PlaybackReportState.PLAYING else PlaybackReportState.PAUSED)
    }

    /**
     * Reports [state]. Playing and paused return once sent off; stopped returns once delivered and the watched mark it
     * settles is done. Failures are handled here, never thrown. The overrides stand in for the player's position and
     * duration (a stop retried after the engine was released).
     */
    suspend fun sendProgress(state: PlaybackReportState, positionOverride: Duration? = null, durationOverride: Duration? = null) {
        var attemptedPosition: Duration? = null
        var attemptedDuration: Duration? = null
        try {
            // After the server ended the session, only a viewer resume (playing after a paused) opens a new one:
            // buffered playback carrying on must not undo the stop, and paused heartbeats never re-open it.
            if (serverTerminatedSession) {
                if (state == PlaybackReportState.PAUSED) {
                    pausedSinceServerTermination = true
                } else if (state == PlaybackReportState.PLAYING && pausedSinceServerTermination && stoppedProgress == null) {
                    resumeAfterStoppedReport()
                }
            }
            val canReport = canReportPlayback()
            val hasRenderedOutput = hasRenderedPlayback?.invoke() ?: canReport
            if (state != PlaybackReportState.STOPPED && !canReport) return
            val isSuppressedStop = state == PlaybackReportState.STOPPED && !canReport
            val playback = player()
            val duration = durationOverride ?: playback.duration
            val positionSource = if (isSuppressedStop) {
                lastReportablePosition ?: (item.viewOffsetMs ?: 0L).milliseconds
            } else {
                positionOverride ?: playback.position
            }
            val position = clampPosition(positionSource, duration)
            if (canReport && hasRenderedOutput) lastReportablePosition = position
            val canCommitStoppedProgress = hasRenderedOutput && (!isSuppressedStop || lastReportablePosition != null)
            attemptedPosition = position
            attemptedDuration = duration

            if (duration.inWholeMilliseconds == 0L) return

            if (isOffline) {
                // No server session to end offline, and a run that showed nothing has no progress to queue.
                if (!canCommitStoppedProgress) return
                sendOfflineProgress(position, duration)
                notifyProgressIfNeeded(position, duration, force = state == PlaybackReportState.STOPPED, serverAcknowledged = false)
            } else if (state == PlaybackReportState.STOPPED) {
                val accepted = sendOnlineProgress(state, position, duration, allowScrobble = canCommitStoppedProgress)
                // The explicit mark is decided at session end: it rides the stop, so a caller that awaits the stop
                // before teardown doesn't drop it.
                pendingSettle?.join()
                resetBackoff()
                if (accepted && canCommitStoppedProgress) {
                    notifyProgressIfNeeded(position, duration, force = true, serverAcknowledged = stoppedProgressServerAcknowledged)
                }
            } else {
                scope.launch(start = CoroutineStart.UNDISPATCHED) {
                    try {
                        sendOnlineProgress(state, position, duration)
                        resetBackoff()
                    } catch (e: CancellationException) {
                        throw e
                    } catch (e: PlaybackSessionTerminatedException) {
                        handleServerTermination(e)
                    } catch (e: Exception) {
                        recordProgressFailure(e)
                        queueOnlineFailureProgress(position, duration)
                    }
                }
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            if (!isOffline) {
                recordProgressFailure(e)
                val playback = player()
                queueOnlineFailureProgress(attemptedPosition ?: playback.position, attemptedDuration ?: playback.duration)
            } else {
                Log.d(TAG, e) { "offline progress update failed" }
            }
        }
    }

    /** The stopped report, sent once however often this is called, until [resumeAfterStoppedReport]. */
    suspend fun sendStoppedProgressOnce(positionOverride: Duration? = null) {
        stoppedProgress?.let { return it.await() }
        val deferred = CompletableDeferred<Unit>()
        stoppedProgress = deferred
        if (serverTerminatedSession) {
            scope.complete(deferred) { sendStoppedAfterServerTermination(positionOverride) }
        } else {
            scope.complete(deferred) { sendProgress(PlaybackReportState.STOPPED, positionOverride) }
        }
        deferred.await()
    }

    /**
     * Retries a stopped report that didn't reach the server (a TV suspended in the background, whose purpose is closing
     * the server's session): every [STOP_REPORT_RETRY_DELAY], at most [STOP_REPORT_MAX_RETRIES] times, while
     * [stillSuspended] holds and it isn't delivered. [position] and [duration] are the suspend's: the engine is released.
     */
    suspend fun redeliverStoppedReport(position: Duration, duration: Duration, stillSuspended: () -> Boolean) {
        repeat(STOP_REPORT_MAX_RETRIES) {
            delay(STOP_REPORT_RETRY_DELAY)
            if (!stillSuspended() || stoppedReportDelivered) return
            sendProgress(PlaybackReportState.STOPPED, position, duration)
        }
    }

    /** Opens a new server session after the stopped report (back from picture-in-picture or the background). */
    fun resumeAfterStoppedReport() {
        stoppedProgress = null
        // A termination of the old session doesn't apply to the new one (and its new transcode needs its keepalive).
        serverTerminatedSession = false
        pausedSinceServerTermination = false
        serverTerminationStop = null
        resetReportSession()
    }

    fun dispose() {
        stopTracking()
    }

    private fun tick() {
        // Skip ticks backing off after failures, so an outage isn't flooded with doomed requests.
        if (ticksToSkip > 0) {
            ticksToSkip--
            return
        }
        if (player().isActive) {
            launchReport(PlaybackReportState.PLAYING)
        } else {
            // Paused ticks report too: the heartbeat keeps the server's session and transcoder alive through a long pause.
            launchReport(PlaybackReportState.PAUSED)
            if (!serverTerminatedSession) sendPausedKeepalive()
        }
    }

    private fun launchReport(state: PlaybackReportState, positionOverride: Duration? = null, durationOverride: Duration? = null) {
        scope.launch(start = CoroutineStart.UNDISPATCHED) { sendProgress(state, positionOverride, durationOverride) }
    }

    /** One keepalive at a time: a server that stopped answering doesn't collect a new ping every tick. */
    private fun sendPausedKeepalive() {
        val keepalive = onPausedKeepalive ?: return
        if (pausedKeepaliveInFlight) return
        pausedKeepaliveInFlight = true
        scope.launch(start = CoroutineStart.UNDISPATCHED) {
            try {
                keepalive()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.d(TAG, e) { "paused keepalive failed" }
            } finally {
                pausedKeepaliveInFlight = false
            }
        }
    }

    /** A re-opened session is a new one on the server: it must earn its own below-threshold report. */
    private fun resetReportSession() {
        reportSession?.resetAfterStop()
        deliveredBelow = false
        serverObservedCrossing = false
        sessionEnded = false
        hasDeliveredStart = false
        stoppedReportActedOn = false
        stoppedProgressServerAcknowledged = false
    }

    /**
     * The server ended the session (an admin's stop, paused too long). Heartbeats would re-register it as a session the
     * admin can't clear, so it is closed with one stopped report at the playhead. Not a failure: no backoff, nothing
     * queued.
     */
    private fun handleServerTermination(e: PlaybackSessionTerminatedException) {
        if (serverTerminatedSession) return
        serverTerminatedSession = true
        // Ended while paused (paused too long): unpausing is the resume.
        pausedSinceServerTermination = !player().isActive
        Log.w(TAG, e) { "closing the reporting session of ${item.id}: ended by the server" }
        val deferred = CompletableDeferred<Unit>()
        serverTerminationStop = deferred
        scope.complete(deferred) { sendProgress(PlaybackReportState.STOPPED) }
    }

    /**
     * The item's own stopped report after a termination: buffered playback may have run on, so the server still learns
     * where it ended, as a lone stopped report that records the position (and the watch) without opening a session.
     */
    private suspend fun sendStoppedAfterServerTermination(positionOverride: Duration?) {
        serverTerminationStop?.await()
        if (serverTerminatedSession) {
            resetReportSession()
            stopProgressNotified = false
        }
        sendProgress(PlaybackReportState.STOPPED, positionOverride)
    }

    private fun clampPosition(position: Duration, duration: Duration): Duration = when {
        duration.inWholeMilliseconds <= 0L -> position
        position.isNegative() -> Duration.ZERO
        position > duration -> duration
        else -> position
    }

    private suspend fun queueOnlineFailureProgress(position: Duration, duration: Duration) {
        if (!queueOnOnlineFailure || offlineQueue == null) return
        if (duration.inWholeMilliseconds == 0L) return
        try {
            sendOfflineProgress(clampPosition(position, duration), duration)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.d(TAG, e) { "queueing progress after a failed report failed" }
        }
    }

    private fun recordProgressFailure(e: Exception) {
        consecutiveFailures++
        ticksToSkip = (1 shl (consecutiveFailures - 1).coerceAtMost(30)).coerceIn(1, MAX_TICKS_TO_SKIP)
        Log.d(TAG, e) { "progress update failed ($consecutiveFailures in a row), skipping $ticksToSkip tick(s)" }
    }

    private fun resetBackoff() {
        if (consecutiveFailures > 0) {
            consecutiveFailures = 0
            ticksToSkip = 0
        }
    }

    private fun notifyProgressIfNeeded(position: Duration, duration: Duration, force: Boolean = false, serverAcknowledged: Boolean) {
        if (scrobbled) return
        if (position.inWholeMilliseconds <= 0L || duration.inWholeMilliseconds <= 0L) return
        if (force) {
            if (stopProgressNotified) return
            stopProgressNotified = true
        } else {
            val last = lastProgressNotifiedPosition
            if (last != null && abs((position - last).inWholeMilliseconds) < PROGRESS_NOTIFY_DELTA.inWholeMilliseconds) {
                if (!serverAcknowledged || lastProgressNotificationServerAcknowledged) return
            }
        }
        lastProgressNotifiedPosition = position
        lastProgressNotificationServerAcknowledged = serverAcknowledged
        notifier.notifyProgress(
            item = item,
            viewOffset = position.inWholeMilliseconds,
            duration = duration.inWholeMilliseconds,
            cacheServerId = backend?.cacheServerId,
            watchedThreshold = backend?.watchedThreshold ?: DEFAULT_WATCHED_THRESHOLD,
            serverAcknowledged = serverAcknowledged,
        )
    }

    private suspend fun sendOnlineProgress(
        state: PlaybackReportState,
        position: Duration,
        duration: Duration,
        allowScrobble: Boolean = true,
    ): Boolean {
        val client = backend ?: return false
        val session = reportSession ?: return false
        val snapshot = PlaybackReportSnapshot(state, position, duration, resolveStreamSelection = { currentStreamSelection() })
        val accepted = session.report(snapshot)
        if (accepted && allowScrobble) maybeScrobble(client, position, duration)
        if (!snapshot.isStopped) {
            deliveredAcknowledgements.remove(snapshot)?.let { acknowledged ->
                notifyProgressIfNeeded(position, duration, serverAcknowledged = acknowledged)
            }
        }
        return accepted
    }

    /**
     * Records what the server took, then settles its watched mark again. Every backend marks an item played from a
     * crossing it sees within one session (a report below the threshold, then one at or past it); a session whose
     * every report sits past the threshold is never marked by the server.
     */
    private fun onReportDelivered(snapshot: PlaybackReportSnapshot) {
        val client = backend
        val persistsPositionOnEveryReport = !item.backend.usesMediaBrowserApi
        if (snapshot.isStopped) {
            // MediaBrowser needs an opened session for a stop to keep the position or record the watch; Plex doesn't.
            stoppedReportActedOn = persistsPositionOnEveryReport || hasDeliveredStart
            stoppedProgressServerAcknowledged = stoppedReportActedOn
            if (stoppedReportActedOn && client?.marksWatchedOnPlaybackStopped == true) promoteWatchedPatch()
        } else {
            val isStarted = !hasDeliveredStart
            hasDeliveredStart = true
            // A MediaBrowser start records the play but not the position.
            deliveredAcknowledgements[snapshot] = !isStarted || persistsPositionOnEveryReport
        }

        val threshold = client?.watchedThreshold ?: return
        // An unknown duration is neither below nor past the threshold.
        if (snapshot.duration.inWholeMilliseconds <= 0L) return
        if (snapshot.isStopped) sessionEnded = true
        if (isWatchedProgress(snapshot.position.inWholeMilliseconds, snapshot.duration.inWholeMilliseconds, threshold)) {
            if (deliveredBelow) serverObservedCrossing = true
        } else if (snapshot.position > Duration.ZERO) {
            deliveredBelow = true
        }
        pendingSettle = scope.launch(start = CoroutineStart.UNDISPATCHED) { settleServerMark(client) }
    }

    /** Issues the explicit server mark, only once it is clear the server won't record the watch itself. */
    private suspend fun settleServerMark(client: MediaBackend?) {
        if (client == null || !scrobbled || serverMarkSettled) return
        // The stopped report marks it; an explicit mark on top double-scrobbles through Jellyfin's Trakt plugin.
        if (client.marksWatchedOnPlaybackStopped) {
            serverMarkSettled = true
            if (stoppedReportActedOn) promoteWatchedPatch()
            runScrobbledHook()
            return
        }
        // The server saw the crossing and marked it; marking again counts the watch twice.
        if (serverObservedCrossing) {
            serverMarkSettled = true
            promoteWatchedPatch()
            runScrobbledHook()
            return
        }
        // Never while the session is live: a seek back below the threshold can still make a crossing the server
        // records itself, and an early explicit mark would then count twice.
        if (!sessionEnded) return
        serverMarkSettled = true
        try {
            client.markWatched(item)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "failed to mark ${item.id} watched" }
            serverMarkSettled = false
            return
        }
        promoteWatchedPatch()
        runScrobbledHook()
    }

    /** The server took the watch: its local patch may now be superseded by a server read. At most once. */
    private fun promoteWatchedPatch() {
        val patchId = watchedPatchId ?: return
        watchedPatchId = null
        notifier.promote(patchId)
    }

    /** Runs [onScrobbled] once, after the item's own mark (it marks siblings with real server writes). */
    private suspend fun runScrobbledHook() {
        val hook = onScrobbled ?: return
        if (scrobbledHookRan) return
        scrobbledHookRan = true
        try {
            hook()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "post-watch hook failed for ${item.id}" }
        }
    }

    private suspend fun maybeScrobble(client: MediaBackend, position: Duration, duration: Duration) {
        if (scrobbled) return
        if (!isWatchedProgress(position.inWholeMilliseconds, duration.inWholeMilliseconds, client.watchedThreshold)) return
        scrobbled = true
        // Local state flips on the crossing seen here, delivered or not; the server's mark is settleServerMark's.
        watchedPatchId = client.notifyWatchedFromPlaybackSession(item, notifier)
        Log.d(TAG) { "watched ${item.id} at ${position.inWholeMilliseconds} of ${duration.inWholeMilliseconds} ms" }
        settleServerMark(client)
    }

    /**
     * The engine's selection for every report, stopped included: MediaBrowser learns a track pick only from a report,
     * and one made just before leaving has no other left to ride.
     */
    private fun currentStreamSelection(): PlaybackStreamSelection {
        val info = mediaInfo ?: return PlaybackStreamSelection.NONE
        if (!shouldReportTrackSelections()) return PlaybackStreamSelection(mediaSourceId = info.mediaSourceId)
        val playback = player()
        return PlaybackStreamSelection(
            mediaSourceId = info.mediaSourceId,
            audioStreamIndex = currentAudioStreamIndex(info, playback),
            subtitleStreamIndex = currentSubtitleStreamIndex(info, playback),
        )
    }

    private fun shouldReportTrackSelections(): Boolean = try {
        rememberTrackSelections()
    } catch (e: Exception) {
        Log.d(TAG, e) { "couldn't read the track-selection setting; reporting the selected streams" }
        true
    }

    private fun currentAudioStreamIndex(info: MediaSourceInfo, playback: PlayerProgress): Int? {
        val tracks = playback.tracks
        if (item.backend.usesMediaBrowserApi && (info.audioTracks.any { it.isExternal } || tracks.realAudio.size <= 1)) {
            selectedSourceAudioTrack(info)?.let { return it.id }
        }
        return playingSourceAudioTrack(tracks.selectedAudio, tracks.audio, info.audioTracks)?.id
    }

    private fun selectedSourceAudioTrack(info: MediaSourceInfo): MediaAudioTrack? {
        info.audioTracks.firstOrNull { it.selected }?.let { return it }
        val defaultIndex = info.defaultAudioStreamIndex ?: return null
        return info.audioTracks.firstOrNull { it.id == defaultIndex }
    }

    private fun currentSubtitleStreamIndex(info: MediaSourceInfo, playback: PlayerProgress): Int? {
        val track = playback.tracks.selectedSubtitle
        if (track == null || track.id == NativeSubtitleTrack.OFF.id) {
            burnedSubtitleStreamIndex()?.let { return it }
            // An off that fell out of a declined carry is withheld, not kept as the item's choice.
            return if (subtitleOffIsDeliberate()) -1 else null
        }
        val uri = track.uri
        if (track.isExternal && uri != null) {
            info.subtitleTracks.firstOrNull { row -> row.external && row.key != null && uri.contains(row.key) }?.let { return it.id }
        }
        // Identity, never position: the two lists are ordered independently. An unmatched track is withheld.
        return findSourceTrackForNativeSubtitle(track, info.subtitleTracks, playback.tracks.subtitle)?.id
    }

    private suspend fun sendOfflineProgress(position: Duration, duration: Duration) {
        val serverId = ServerId.tryParse(item.serverId)
        if (serverId == null) {
            Log.w(TAG) { "can't queue offline progress of ${item.id}: no server id" }
            return
        }
        checkNotNull(offlineQueue) { "no offline queue" }.queueProgress(serverId, item.id, position.inWholeMilliseconds, duration.inWholeMilliseconds)
        Log.d(TAG) { "offline progress queued: ${position.inWholeSeconds}s of ${duration.inWholeSeconds}s" }
    }

    companion object {
        /** How long [redeliverStoppedReport] waits before each attempt. */
        val STOP_REPORT_RETRY_DELAY: Duration = 10.seconds

        /** How many times [redeliverStoppedReport] tries. */
        const val STOP_REPORT_MAX_RETRIES: Int = 5

        private val PROGRESS_NOTIFY_DELTA = 30.seconds
        private const val MAX_TICKS_TO_SKIP = 6
        private const val DEFAULT_WATCHED_THRESHOLD = 0.9
        private const val TAG = "PlaybackProgressTracker"
    }
}

package com.edde746.plezy.livetv.playback

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.PlaybackException
import com.edde746.plezy.backend.PlaybackFailureReason
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.backend.localizedErrorReason
import com.edde746.plezy.input.VideoClickAction
import com.edde746.plezy.livetv.CaptureBuffer
import com.edde746.plezy.livetv.LiveTimelineState
import com.edde746.plezy.livetv.LiveTimelineUpdate
import com.edde746.plezy.livetv.LiveTvChannel
import com.edde746.plezy.livetv.LiveTvLaunch
import com.edde746.plezy.livetv.LiveTvPlaybackSession
import com.edde746.plezy.livetv.LiveTvProgram
import com.edde746.plezy.livetv.LiveTvStartPosition
import com.edde746.plezy.livetv.liveTvProgramMatchesChannel
import com.edde746.plezy.livetv.liveTvServerFor
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaFileInfo
import com.edde746.plezy.model.MediaSubtitleTrack
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.playback.EngineError
import com.edde746.plezy.playback.EngineState
import com.edde746.plezy.playback.LoadRequest
import com.edde746.plezy.playback.PlaybackFailure
import com.edde746.plezy.playback.PlaybackOptions
import com.edde746.plezy.playback.PlayerEngine
import com.edde746.plezy.playback.PlayerEngineListener
import com.edde746.plezy.playback.SubtitleStyle
import com.edde746.plezy.playback.TrackKind
import com.edde746.plezy.playback.session.LiveWindow
import com.edde746.plezy.playback.session.NextEpisode
import com.edde746.plezy.playback.session.PlayerSession
import com.edde746.plezy.playback.session.SessionChoice
import com.edde746.plezy.playback.session.SessionInfo
import com.edde746.plezy.playback.session.SessionNotice
import com.edde746.plezy.playback.session.SourceTrack
import com.edde746.plezy.playback.session.SubtitleDownloadOutcome
import com.edde746.plezy.playback.session.SimulatedHttpError
import com.edde746.plezy.playback.session.SubtitleSearchHit
import com.edde746.plezy.playback.tracks.PlaybackSubtitleResolver
import com.edde746.plezy.playback.tracks.SourceSubtitleChoice
import com.edde746.plezy.playback.withoutSecrets
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.servers.LiveTvServerEntry
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.math.roundToLong
import kotlin.time.Clock
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Instant
import kotlin.time.TimeMark
import kotlin.time.TimeSource

/**
 * Plays a tuned Live TV channel ([LiveTvLaunch]): the player's session for live, on Plex, Jellyfin and Emby alike. The
 * channel's server tunes it ([com.edde746.plezy.livetv.LiveTvSupport.startPlayback] at the [quality] cap) and the
 * engine opens the stream it hands back as a live file.
 *
 * - Start: with history in the capture buffer (an airing recorded or a session already running) whose program began
 *   over a minute ago, the viewer is asked whether to watch from the start ([SessionInfo.choice]) unless the launch
 *   answered it ([LiveTvStartPosition]); a fresh tune has no history and opens at the live edge.
 * - Heartbeats: every 10 s, the first 3 s after the open (a report at time 0 right after the open spawned a duplicate
 *   transcode on Plex). Their capture buffer is the rewind window ([SessionInfo.liveWindow]); their playback transcode
 *   re-anchors the live clock ([LiveSessionState]).
 * - Time-shift (Plex): a move in the window reopens the stream at an offset into the capture buffer; relative moves
 *   coalesce ([LiveSeekAccumulator]). The live edge is the last [LIVE_EDGE_SECONDS] of the window.
 * - Channel zap ([playNextEpisode], [playPreviousEpisode]: the keys, the OS media session, a remote; the on-screen
 *   controls show no previous or next on live): the next or previous channel of the launch's list, opened at the live
 *   edge without asking. The new session is tuned and its
 *   stream opened first; only then is the old one reported stopped and the new one adopted.
 * - Stream errors climb a retry ladder (direct stream and its audio, then no direct stream, then neither); a playback
 *   restart refills it. A failure of a replacement stream before its start or zap committed is recovered after.
 * - A start that fails, or an error once the ladder is spent, reports the tune stopped and leaves the player with why
 *   ([leave]): live has no reload to retry through. A recovery that fails says the stream was interrupted instead.
 * - A stream opens paused while the device forbids video ([playbackAllowed]: a car's driving restrictions).
 * - Server subtitles (Plex's DVB bitmap subtitles) are burned in by rebuilding the stream ([selectSourceTrack]).
 * - On a TV, a session that can't be kept ([com.edde746.plezy.livetv.LiveTvBackgroundPolicy.STOP_AND_EXIT]) is stopped
 *   when the app goes to the background and the player leaves when it returns ([close]); anywhere else the heartbeats
 *   pause in the background and resume on return.
 * - The player and the OS media controls are titled by the programme airing (from the server's guide, read again as
 *   it ends), with the channel's name under it, else by the channel's name; they show the channel's logo. Nothing is
 *   scrobbled, bookmarked or queued.
 *
 * Reports that must outlive the player (the last 'stopped', the release of a session nothing adopted) run on
 * [backgroundScope].
 */
class LivePlayerSession(
    private val engine: PlayerEngine,
    private val launch: LiveTvLaunch,
    /** The Live TV servers now, to find the one tuning a zapped channel. */
    private val servers: () -> List<LiveTvServerEntry>,
    /** A connected server's client, or null. */
    private val client: (ServerId) -> MediaBackend?,
    private val playbackOptions: suspend () -> PlaybackOptions,
    /** The quality cap tunes ask for: the default preset, or the cellular one on a cellular-only connection. */
    private val quality: suspend () -> TranscodeQualityPreset,
    subtitleStyle: Flow<SubtitleStyle>,
    /** What a click on the video does (the click-toggles-playback setting), followed as it changes. */
    videoClick: Flow<VideoClickAction>,
    /** Whether the app is in the foreground. */
    foreground: StateFlow<Boolean>,
    /** The device is a TV (Android TV, Apple TV). */
    private val tv: Boolean,
    /** Leaves the player, with the message the app shows over it once it's gone (why the channel stopped), or none. */
    private val leave: (notice: String?) -> Unit,
    /**
     * Whether video may play now (a car's driving restrictions): a stream opens paused while it may not. Nothing gates
     * playback where it isn't given.
     */
    private val playbackAllowed: () -> Boolean = { true },
    parentScope: CoroutineScope,
    private val backgroundScope: CoroutineScope,
    private val clock: Clock = Clock.System,
    private val timeSource: TimeSource = TimeSource.Monotonic,
) : PlayerSession {
    private val scope = parentScope.childScope()
    private val mutableEngineState = MutableStateFlow(EngineState())
    override val engineState: StateFlow<EngineState> = mutableEngineState.asStateFlow()
    private val mutableInfo = MutableStateFlow(SessionInfo(title = launch.channel.displayName, live = true))
    override val info: StateFlow<SessionInfo> = mutableInfo.asStateFlow()
    private val states = Channel<EngineState>(Channel.UNLIMITED)

    private val live = LiveSessionState(clock)
    private val liveSeek = LiveSeekAccumulator(
        scope = scope,
        seek = ::runLiveSeek,
        currentEpoch = ::rawPositionEpoch,
        bounds = { live.captureBuffer?.let { LiveSeekBounds(it.seekableStartEpoch, it.seekableEndEpoch) } },
        onChanged = ::onLiveSeekTargetChanged,
    )

    private var channelIndex = launch.channelIndex
    private var channel: LiveTvChannel = launch.channel

    /** The programme airing on [channel] as last read ([followProgram]); null while none is known. */
    private var airing: LiveTvProgram? = null
    private var programJob: Job? = null

    /** When [LiveSessionState.captureBuffer] was received: the window's edge moves on from then. */
    private var bufferReceivedAt: TimeMark = timeSource.markNow()

    /** The engine load whose reports count, and the loads whose first frame calibrated the clock already. */
    private var loadId = 0L
    private var readyLoadId = 0L
    private var failedLoadId = 0L
    private var playbackRestarts = 0

    private var transition: Transition? = null
    private var transitionLease = 0
    private var heartbeat: Job? = null
    private var choiceAnswer: CompletableDeferred<Int?>? = null

    // One subtitle rebuild at a time: a later pick's stream always opens after an earlier one's.
    private val subtitleSwitches = Mutex()
    private var noticeSerial = 0

    /** The session left the player ([leaveWith]): what is still on its way is ignored. */
    private var leaving = false
    private var closed = false

    init {
        engine.setListener(object : PlayerEngineListener {
            override fun onState(state: EngineState) {
                states.trySend(state)
            }
        })
        scope.launch {
            for (state in states) {
                mutableEngineState.value = state
                follow(state)
            }
        }
        scope.launch { subtitleStyle.distinctUntilChanged().collect(engine::setSubtitleStyle) }
        scope.launch { videoClick.distinctUntilChanged().collect { click -> mutableInfo.update { it.copy(videoClick = click) } } }
        scope.launch { foreground.drop(1).distinctUntilChanged().collect { if (it) onForeground() else onBackground() } }
        publishChannel()
        start()
    }

    // Start

    private fun start() {
        val lease = tryAcquire(Transition.STARTING) ?: return
        mutableInfo.update { it.copy(resolving = true, failure = null) }
        scope.launch {
            val replacement = live.beginReplacement()
            var committed = false
            try {
                val session = startSession(channel) ?: throw PlaybackException(T.liveTv.failedToStartChannel, PlaybackFailureReason.SERVER_UNAVAILABLE)
                if (!owns(lease, Transition.STARTING)) {
                    discard(session)
                    return@launch
                }
                adopt(session, streamOpen = false)
                val offset = startOffset(session)
                if (!owns(lease, Transition.STARTING)) return@launch
                val url = session.streamUrlAt(offset) ?: throw PlaybackException(T.liveTv.failedToBuildStreamUrl, PlaybackFailureReason.NO_PLAYABLE_SOURCE)
                if (!owns(lease, Transition.STARTING)) return@launch
                val buffer = session.captureBuffer
                val targetEpoch = if (offset != null && buffer != null) {
                    live.atLiveEdge = false
                    live.playbackStartedAt = clock.now()
                    (buffer.startedAt + offset).roundToLong()
                } else {
                    live.markStreamRestartedAtLiveEdge(buffer)
                    buffer?.let { live.streamStartEpoch.roundToLong() }
                }
                openStream(url, targetEpoch, timeShifted = offset != null)
                committed = owns(lease, Transition.STARTING)
                if (committed) {
                    mutableInfo.update { it.copy(resolving = false) }
                    startHeartbeat()
                }
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (failure: Exception) {
                // Live has no reload to retry through: the tune is reported stopped and the player leaves with why.
                Log.e(TAG, failure) { "live start failed" }
                sendTimeline(LiveTimelineState.STOPPED)
                mutableInfo.update { it.copy(resolving = false) }
                leaveWith(T.liveTv.playbackStartFailed(localizedErrorReason(failure)))
            } finally {
                finishReplacement(lease, replacement, committed)
            }
        }
    }

    /**
     * Where the start opens, in seconds into the capture buffer; null at the live edge. With a capture buffer and the
     * program's start: from the program's start when the buffer holds it and it began over a minute ago, else from the
     * buffer's start; asked when that is over a minute back, unless the launch answered.
     */
    private suspend fun startOffset(session: LiveTvPlaybackSession): Long? {
        val buffer = session.captureBuffer ?: return null
        val beginsAt = session.program.beginsAt ?: return null
        val now = clock.now().epochSeconds
        val programOffset = beginsAt - buffer.startedAt.roundToLong()
        val fromProgramStart = programOffset > buffer.seekStartSeconds && now - beginsAt > PROMPT_HISTORY_SECONDS
        val start = if (fromProgramStart) beginsAt else buffer.seekableStartEpoch
        if (now - start <= PROMPT_HISTORY_SECONDS) return null
        val fromStart = when (launch.startPosition) {
            LiveTvStartPosition.BEGINNING -> true
            LiveTvStartPosition.LIVE -> false
            LiveTvStartPosition.ASK -> askWatchFromStart(((now - start) / 60.0).roundToLong())
        }
        if (!fromStart) return null
        return if (fromProgramStart) programOffset else buffer.seekStartSeconds.roundToLong()
    }

    /** The watch-from-start question; a dismissal watches live. */
    private suspend fun askWatchFromStart(minutesAgo: Long): Boolean {
        val answer = CompletableDeferred<Int?>()
        choiceAnswer = answer
        mutableInfo.update { it.copy(choice = SessionChoice(T.liveTv.joinSession, listOf(T.liveTv.watchFromStart(minutesAgo.toString()), T.liveTv.watchLive))) }
        try {
            return answer.await() == WATCH_FROM_START
        } finally {
            choiceAnswer = null
            mutableInfo.update { it.copy(choice = null) }
        }
    }

    override fun answerChoice(index: Int?) {
        choiceAnswer?.complete(index)
    }

    /** As the stream's error for [status] would ([onStreamError]). */
    override fun simulateHttpError(status: Int) {
        if (closed) return
        onStreamError(SimulatedHttpError.of(status))
    }

    /** Tunes [channel] on the server it belongs to. */
    private suspend fun startSession(channel: LiveTvChannel): LiveTvPlaybackSession? {
        val server = liveTvServerFor(servers(), channel) ?: run {
            Log.w(TAG) { "no live TV server for ${channel.displayName}" }
            return null
        }
        val backend = client(server.serverId) ?: run {
            Log.w(TAG) { "live TV server ${server.serverId.value} is not connected" }
            return null
        }
        return backend.liveTv.startPlayback(channel.key, server.dvrKey, quality())
    }

    /**
     * Makes [session] the one playing. Its window shows at once when its stream is open already ([streamOpen]: a zap, a
     * recovery) and its clock calibrated; else once it is.
     */
    private fun adopt(session: LiveTvPlaybackSession, streamOpen: Boolean) {
        live.adoptSession(session)
        bufferReceivedAt = timeSource.markNow()
        publishSubtitles()
        mutableInfo.update { it.copy(liveWindow = null) }
        if (streamOpen) publishWindow()
    }

    /** Releases a session nothing adopted, so its server frees the tuner now rather than at an idle timeout. */
    private fun discard(session: LiveTvPlaybackSession) {
        backgroundScope.launch { session.discard() }
    }

    // Opening streams

    /**
     * Opens [url] as the live file. An open with a capture buffer registers its [targetEpoch] before the load and binds
     * it to the load's id, so only that source's first frame calibrates the clock; with [awaitClock] the open succeeds
     * once it has (at most [CLOCK_READY_TIMEOUT]). [timeShifted] starts an offset stream at its first segment.
     */
    private suspend fun openStream(
        url: String,
        targetEpoch: Long?,
        awaitClock: Boolean = false,
        timeShifted: Boolean = false,
        title: String = channel.displayName,
    ): Boolean {
        if (closed) return false
        val options = playbackOptions()
        if (closed) return false
        live.streamGeneration++
        val request = LoadRequest(
            url = url,
            options = options,
            title = title,
            headers = STREAM_HEADERS,
            liveStartIndex = if (timeShifted) 0 else null,
            live = true,
        )
        if (targetEpoch == null) {
            load(request)
            return true
        }
        val generation = live.beginClockOpen(targetEpoch)
        val result = live.clockOpenResult(generation)
        live.bindClockOpen(generation, load(request))
        if (!awaitClock) return true
        return withTimeoutOrNull(CLOCK_READY_TIMEOUT) { result.await() } ?: run {
            live.timeoutClockOpen(generation)
            Log.w(TAG) { "the time-shifted stream reported no first frame" }
            false
        }
    }

    private fun load(request: LoadRequest): Long {
        val id = engine.load(request)
        loadId = id
        // Nothing plays while the device forbids video (a car's driving restrictions): the stream opens paused.
        engine.setPaused(!playbackAllowed())
        return id
    }

    private fun follow(state: EngineState) {
        if (closed) return
        val error = state.error
        if (error != null) {
            live.failClockSource(state.loadId)
            if (state.loadId == loadId && failedLoadId != loadId) {
                failedLoadId = loadId
                onStreamError(error)
            }
            return
        }
        if (state.loaded && state.playbackRestarts > 0 && readyLoadId != state.loadId) {
            readyLoadId = state.loadId
            if (live.calibrateClockSource(state.loadId, state.positionSeconds)) publishWindow()
        }
        if (state.loadId == loadId && state.playbackRestarts > playbackRestarts) {
            // The stream plays again: the ladder's level works.
            live.fallbackLevel = 0
            live.retryFailed = false
        }
        playbackRestarts = if (state.loadId == loadId) state.playbackRestarts else 0
    }

    // Heartbeats

    private fun startHeartbeat() {
        if (closed) return
        val generation = ++live.timelineGeneration
        heartbeat?.cancel()
        heartbeat = scope.launch {
            launch {
                delay(FIRST_HEARTBEAT)
                if (generation == live.timelineGeneration) sendTimeline(playState())
            }
            while (true) {
                delay(HEARTBEAT)
                if (generation == live.timelineGeneration) sendTimeline(playState())
            }
        }
    }

    private fun stopHeartbeat() {
        live.timelineGeneration++
        heartbeat?.cancel()
        heartbeat = null
    }

    private fun playState(): LiveTimelineState = if (engineState.value.paused) LiveTimelineState.PAUSED else LiveTimelineState.PLAYING

    /** One report of the adopted session; 'stopped' is the last it takes. Null without a session. */
    private fun sendTimeline(state: LiveTimelineState): Deferred<Unit>? {
        if (closed && state != LiveTimelineState.STOPPED) return null
        val session = live.session ?: return null
        val generation = live.timelineGeneration
        val stream = live.streamGeneration
        val positionMs = live.playbackStartedAt?.let { (clock.now() - it).inWholeMilliseconds } ?: 0
        val sent = live.timelineReports.send(backgroundScope, stopped = state == LiveTimelineState.STOPPED) {
            runLiveTimelineReport(session, generation, state, positionMs, { live.session }, { live.timelineGeneration }, { !closed }) {
                commitTimeline(it, stream)
            }
        }
        sent.invokeOnCompletion { failure -> if (failure != null) Log.d(TAG, failure) { "live timeline report failed" } }
        return sent
    }

    private fun commitTimeline(update: LiveTimelineUpdate, stream: Int) {
        update.playbackStream?.let { if (live.adoptPlaybackStreamOrigin(it, stream)) Log.d(TAG) { "live clock re-anchored on ${it.startedAt}" } }
        update.captureBuffer?.let {
            live.captureBuffer = it
            bufferReceivedAt = timeSource.markNow()
        }
        live.captureBuffer?.let { live.atLiveEdge = currentPositionEpoch() >= it.seekableEndEpoch - LIVE_EDGE_SECONDS }
        publishWindow()
    }

    // Time-shift

    /**
     * A move to [behindSeconds] behind the edge: the edge itself at once (nothing when the position is there already),
     * anything else through [liveSeek], which coalesces the moves of a burst into one reopen.
     */
    override fun seekLive(behindSeconds: Double) {
        val buffer = live.captureBuffer ?: return
        if (behindSeconds <= 0.0) {
            liveSeek.cancel()
            if (edgeEpoch(buffer) - rawPositionEpoch() <= LIVE_EDGE_SECONDS) return
            scope.launch { runLiveSeek(buffer.seekableEndEpoch) }
            return
        }
        val target = (edgeEpoch(buffer) - behindSeconds).roundToLong()
        liveSeek.seekBy(target - (liveSeek.pendingEpoch ?: rawPositionEpoch()))
    }

    /**
     * Reopens the stream at [targetEpoch], clamped to the window, with the same subtitle burned in. Whether the reopened
     * stream's clock was calibrated. Never on a session that can't time-shift (no capture buffer).
     */
    private suspend fun seekTo(targetEpoch: Long): Boolean {
        val session = live.session ?: return false
        val buffer = live.captureBuffer ?: return false
        val clamped = targetEpoch.coerceIn(buffer.seekableStartEpoch, buffer.seekableEndEpoch)
        val offset = clamped - buffer.startedAt.roundToLong()
        val url = session.streamUrlAt(offset, live.selectedSubtitle) ?: return false
        if (closed || live.session !== session) return false
        live.atLiveEdge = clamped >= buffer.seekableEndEpoch - LIVE_EDGE_SECONDS
        live.playbackStartedAt = clock.now()
        val opened = openStream(url, clamped, awaitClock = true, timeShifted = true)
        publishWindow()
        return opened
    }

    private suspend fun runLiveSeek(targetEpoch: Long): Boolean = try {
        seekTo(targetEpoch).also { if (!it) Log.w(TAG) { "the time-shift seek reached no calibrated stream" } }
    } catch (cancelled: CancellationException) {
        throw cancelled
    } catch (failure: Exception) {
        Log.w(TAG, failure) { "the time-shift seek failed" }
        false
    }

    private fun onLiveSeekTargetChanged() {
        val pending = liveSeek.pendingEpoch ?: return
        val buffer = live.captureBuffer ?: return
        live.atLiveEdge = pending >= buffer.seekableEndEpoch - LIVE_EDGE_SECONDS
    }

    private fun rawPositionEpoch(): Long = live.epochForPosition(engineState.value.positionSeconds)

    /** The position in epoch seconds; a pending skip's target while it settles. */
    private fun currentPositionEpoch(): Long = liveSeek.pendingEpoch ?: rawPositionEpoch()

    /** The live edge now: the window's end as last received, moved on since. */
    private fun edgeEpoch(buffer: CaptureBuffer): Double =
        buffer.startedAt + buffer.seekEndSeconds + bufferReceivedAt.elapsedNow().inWholeMilliseconds / 1000.0

    /**
     * The capture buffer as the player's rewind window: its length, its edge's distance from the open stream's
     * position zero, and the last [LIVE_EDGE_SECONDS] as the edge. Kept as it was while an open's clock calibrates, and
     * while a zap's stream opens (the zap shows its own once adopted).
     */
    private fun publishWindow() {
        if (transition == Transition.SWITCHING) return
        val buffer = live.captureBuffer
        if (buffer == null || buffer.seekEndSeconds <= buffer.seekStartSeconds) {
            mutableInfo.update { it.copy(liveWindow = null) }
            return
        }
        if (live.pendingStreamEpoch != null) return
        val window = LiveWindow(
            windowSeconds = buffer.seekEndSeconds - buffer.seekStartSeconds,
            segmentSeconds = LIVE_EDGE_SECONDS.toDouble() / LiveWindow.EDGE_SEGMENTS,
            joinedBehindSeconds = buffer.startedAt + buffer.seekEndSeconds - live.streamStartEpoch,
            joinedPositionSeconds = 0.0,
            joinedAt = bufferReceivedAt,
        )
        mutableInfo.update { it.copy(liveWindow = window) }
    }

    // Channel zap

    override fun playNextEpisode() = switchChannel(1)

    /** The previous channel; a live stream has no start to go back to. */
    override fun playPreviousEpisode() = switchChannel(-1)

    private fun switchChannel(delta: Int) {
        if (closed) return
        val index = channelIndex + delta
        if (index !in launch.channels.indices) return
        // A zap away from a failing channel doesn't wait out its recovery: it replaces that stream.
        if (transition == Transition.RECOVERING) {
            forceIdle()
            live.retrying = false
        }
        val lease = tryAcquire(Transition.SWITCHING) ?: return
        val target = launch.channels[index]
        liveSeek.cancel()
        // The controls name the channel tuned to from the press on, not the one going away while it opens.
        mutableInfo.update { it.copy(title = target.displayName, subtitle = null) }
        scope.launch {
            val replacement = live.beginReplacement()
            val previous = live.session
            var committed = false
            var session: LiveTvPlaybackSession? = null
            try {
                session = startSession(target)
                if (session == null) {
                    notice(T.liveTv.failedToStartChannel)
                    return@launch
                }
                if (!owns(lease, Transition.SWITCHING)) {
                    discard(session)
                    return@launch
                }
                val url = session.streamUrlAt()
                if (url == null || !owns(lease, Transition.SWITCHING)) {
                    discard(session)
                    return@launch
                }
                live.markStreamRestartedAtLiveEdge(session.captureBuffer)
                openStream(url, session.captureBuffer?.let { live.streamStartEpoch.roundToLong() }, title = target.displayName)
                if (!owns(lease, Transition.SWITCHING)) {
                    discard(session)
                    return@launch
                }
                // The new stream plays: the old session's last report goes out before the new one is adopted.
                stopHeartbeat()
                if (previous != null) sendTimeline(LiveTimelineState.STOPPED)?.join()
                if (!owns(lease, Transition.SWITCHING)) {
                    discard(session)
                    return@launch
                }
                adopt(session, streamOpen = true)
                live.fallbackLevel = 0
                committed = true
                channelIndex = index
                channel = target
                publishChannel()
                startHeartbeat()
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (failure: Exception) {
                session?.let { if (live.session !== it) discard(it) }
                if (!owns(lease, Transition.SWITCHING)) return@launch
                Log.e(TAG, failure) { "the channel switch failed" }
                notice(T.liveTv.channelSwitchFailed(localizedErrorReason(failure)))
            } finally {
                // Not switched (failed, or nothing to switch to) and no other zap since: back to the channel playing.
                if (!committed && owns(lease, Transition.SWITCHING)) publishTitle()
                finishReplacement(lease, replacement, committed)
                if (committed) publishWindow()
            }
        }
    }

    /**
     * The channel playing as the player and the OS media controls show it, with its neighbours as next and previous,
     * and from then the programme airing on it ([followProgram]).
     */
    private fun publishChannel() {
        val channels = launch.channels
        val next = channels.getOrNull(channelIndex + 1)
        val path = channel.thumb ?: channel.art
        val artwork = path?.let { liveTvServerFor(servers(), channel)?.serverId?.let(client)?.thumbnailUrl(it) }
        mutableInfo.update {
            it.copy(
                artworkUrl = artwork,
                nextEpisode = next?.let { channel -> NextEpisode(channel.displayName, autoplay = false) },
                hasPreviousEpisode = channelIndex > 0,
            )
        }
        followProgram()
    }

    /**
     * Titles the player by the programme airing on the channel, read from its server's guide, the channel under it; a
     * channel with no airing known (or one without a title) by its name alone. Read again as the airing ends, and
     * [PROGRAM_RETRY] after a read that found none or failed.
     */
    private fun followProgram() {
        programJob?.cancel()
        airing = null
        publishTitle()
        val followed = channel
        programJob = scope.launch {
            while (true) {
                val now = clock.now().epochSeconds
                val program = try {
                    airingOn(followed, now)
                } catch (cancelled: CancellationException) {
                    throw cancelled
                } catch (failure: Exception) {
                    Log.w(TAG, failure) { "the guide for ${followed.displayName} didn't load" }
                    null
                }
                airing = program
                publishTitle()
                val ends = program?.endsAt
                delay(if (ends != null && ends > now) (ends - now).seconds else PROGRAM_RETRY)
            }
        }
    }

    /** The programme airing on [channel] at [now] (epoch seconds), from its server's guide; null without one. */
    private suspend fun airingOn(channel: LiveTvChannel, now: Long): LiveTvProgram? {
        val server = liveTvServerFor(servers(), channel) ?: return null
        val backend = client(server.serverId) ?: return null
        return backend.liveTv.fetchSchedule(Instant.fromEpochSeconds(now), Instant.fromEpochSeconds(now + 60))
            .firstOrNull { it.isAiringAt(now) && liveTvProgramMatchesChannel(it, channel) }
    }

    /** The programme's title (a series' name for an episode) over the channel's name, else the channel's name alone. */
    private fun publishTitle() {
        val programme = airing?.let { it.grandparentTitle ?: it.title }?.takeIf { it.isNotBlank() }
        mutableInfo.update { it.copy(title = programme ?: channel.displayName, subtitle = programme?.let { channel.displayName }) }
    }

    // Stream errors and the retry ladder

    private fun onStreamError(error: EngineError) {
        if (leaving || mutableInfo.value.failure != null) return
        val shown = error.withoutSecrets()
        Log.w(TAG) { "live stream error (${shown.kind}, HTTP ${shown.httpStatus}): ${shown.message}" }
        when {
            // A server limit refusal isn't something a retry clears.
            shown.httpStatus == 500 -> mutableInfo.update { it.copy(failure = PlaybackFailure.ServerLimit(transcodeOffered = false)) }
            live.retrying -> Unit
            live.fallbackLevel < MAX_FALLBACK_LEVEL -> beginLadderRetry()
            live.retryFailed -> interrupted()
            // A dead live session has nothing to reload: the player leaves with the error.
            else -> leaveWith(T.messages.playbackFailedDetail(shown.message))
        }
    }

    /** Climbs the ladder and retries, unless a start or zap that opened its stream owns it: then after it commits. */
    private fun beginLadderRetry() {
        if (closed) return
        val replacing = transition == Transition.STARTING || transition == Transition.SWITCHING
        if (replacing && live.deferReplacementFailure()) {
            Log.d(TAG) { "live stream failure deferred until the ${transition?.name} commits" }
            return
        }
        live.fallbackLevel++
        live.retrying = true
        scope.launch { retryStream() }
    }

    private suspend fun retryStream() {
        liveSeek.cancel()
        if (closed) return
        val session = live.session
        if (session == null) {
            live.retrying = false
            mutableInfo.update { it.copy(failure = PlaybackFailure.Server(PlaybackFailureReason.UNKNOWN, T.liveTv.liveStreamFailed)) }
            return
        }
        // A start or zap in flight replaces the stream that failed; its own stream reports its own failures.
        val lease = tryAcquire(Transition.RECOVERING)
        if (lease == null) {
            live.retrying = false
            return
        }
        try {
            recover(session, lease)
        } finally {
            release(lease)
        }
    }

    private suspend fun recover(session: LiveTvPlaybackSession, lease: Int) {
        val isCurrent = { !closed && owns(lease, Transition.RECOVERING) }
        val directStream = live.fallbackLevel < 1
        val directStreamAudio = live.fallbackLevel < 2
        Log.i(TAG) { "retrying the live stream: directStream=$directStream directStreamAudio=$directStreamAudio" }
        // Stream ids belong to one tune: the subtitle is re-mapped onto the recovered session's. Recovering the video
        // outranks the subtitle: a burn that can't be applied again is dropped.
        var subtitle: MediaSubtitleTrack? = null
        var buffer: CaptureBuffer? = null
        val result = runLiveStreamRetry(
            recover = { session.recover(directStream, directStreamAudio) },
            lookupStreamUrl = { recovered ->
                buffer = recovered.captureBuffer
                subtitle = LiveSessionState.remapSubtitleSelection(recovered.subtitleTracks, live.selectedSubtitle)
                subtitle?.let { recovered.streamUrlAt(subtitleTrack = it) } ?: run {
                    if (subtitle != null) Log.w(TAG) { "the recovered stream refused the subtitle burn; retrying without subtitles" }
                    subtitle = null
                    recovered.streamUrlAt()
                }
            },
            open = { url ->
                live.markStreamRestartedAtLiveEdge(buffer)
                openStream(url, buffer?.let { live.streamStartEpoch.roundToLong() })
            },
            isCurrent = isCurrent,
            adoptSession = { recovered ->
                // A recovery under a fresh tune: the displaced one's stop goes out through its own queue, freeing its tuner.
                if (recovered !== live.session) sendTimeline(LiveTimelineState.STOPPED)
                adopt(recovered, streamOpen = true)
                live.selectedSubtitle = subtitle
                publishSubtitles()
            },
            currentSession = { live.session },
            reportFailure = { failure ->
                Log.e(TAG, failure) { "the live stream couldn't be recovered" }
                live.retryFailed = true
                interrupted()
            },
            discardSession = ::discard,
            onFinished = { if (isCurrent()) live.retrying = false },
        )
        if (result == LiveStreamRetryResult.SUCCEEDED && isCurrent()) live.retryFailed = false
    }

    /** The stream is gone and the ladder spent: the error says so and its retry tries again. */
    private fun interrupted() {
        mutableInfo.update { it.copy(failure = PlaybackFailure.Server(PlaybackFailureReason.UNKNOWN, T.messages.liveStreamInterrupted)) }
    }

    /** Leaves the player with [notice] shown over the app, once; the heartbeats stop first. */
    private fun leaveWith(notice: String) {
        if (closed || leaving) return
        leaving = true
        stopHeartbeat()
        leave(notice)
    }

    override fun retry() {
        if (closed || leaving || mutableInfo.value.failure == null) return
        mutableInfo.update { it.copy(failure = null) }
        if (!live.retrying) {
            live.retrying = true
            scope.launch { retryStream() }
        }
    }

    private fun finishReplacement(lease: Int, replacement: Int, committed: Boolean) {
        val runDeferred = live.endReplacement(replacement, committed && transitionLease == lease)
        release(lease)
        if (runDeferred && !closed && mutableInfo.value.failure == null) {
            Log.w(TAG) { "the replacement stream failed before its transition committed; recovering now" }
            beginLadderRetry()
        }
    }

    // Server subtitles

    private fun publishSubtitles() {
        val selected = live.selectedSubtitle?.id
        val tracks = live.session?.subtitleTracks.orEmpty().map { track ->
            val label = track.label
            SourceTrack(track.id, label.primary, label.secondary, selected = track.id == selected)
        }
        mutableInfo.update { it.copy(sourceSubtitles = tracks) }
    }

    /**
     * A server subtitle picked ([SessionInfo.sourceSubtitles]; null: off): the stream is rebuilt with it burned in, at
     * the time-shift position when behind the edge, else at the edge. A refusal keeps the previous choice.
     */
    override fun selectSourceTrack(kind: TrackKind, id: Int?) {
        if (kind != TrackKind.SUBTITLE || closed) return
        val session = live.session ?: return
        val target = id?.let { wanted -> session.subtitleTracks.firstOrNull { it.id == wanted } ?: return }
        val previous = live.selectedSubtitle
        if (target?.id == previous?.id) return
        live.selectedSubtitle = target
        publishSubtitles()
        scope.launch {
            val applied = try {
                subtitleSwitches.withLock { switchSubtitle(session, target) }
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (failure: Exception) {
                Log.w(TAG, failure) { "the subtitle rebuild failed" }
                false
            }
            if (!applied && live.session === session && live.selectedSubtitle?.id == target?.id) {
                live.selectedSubtitle = previous
                publishSubtitles()
            }
        }
    }

    /** The next of [off, each server subtitle]; each press rebuilds the stream with its pick at once. */
    override fun cycleSourceSubtitles() {
        val ids = mutableInfo.value.sourceSubtitles.map { it.id }
        if (closed || ids.isEmpty()) return
        val shown = live.selectedSubtitle?.id?.let { SourceSubtitleChoice.Source(it) } ?: SourceSubtitleChoice.Off
        val next = PlaybackSubtitleResolver.advanceSourceChoice(ids, shown, 1)
        selectSourceTrack(TrackKind.SUBTITLE, (next as? SourceSubtitleChoice.Source)?.id)
    }

    /** Rebuilds the stream with [target] burned in; a pick no longer the selected one opens nothing and counts as applied. */
    private suspend fun switchSubtitle(session: LiveTvPlaybackSession, target: MediaSubtitleTrack?): Boolean {
        val superseded = { closed || live.session !== session || live.selectedSubtitle?.id != target?.id }
        if (superseded()) return true
        if (live.captureBuffer != null && !live.atLiveEdge) return seekTo(currentPositionEpoch())
        val url = session.streamUrlAt(subtitleTrack = target)
        if (superseded()) return true
        url ?: return false
        live.markStreamRestartedAtLiveEdge(live.captureBuffer)
        openStream(url, live.captureBuffer?.let { live.streamStartEpoch.roundToLong() })
        return true
    }

    // Background

    private fun onBackground() {
        if (closed) return
        if (shouldStopLiveSessionForTvBackground(tv, live.session?.backgroundPolicy)) {
            live.exitOnResume = true
            live.resumeTimelineOnResume = false
            stopHeartbeat()
            engine.setPaused(true)
            sendTimeline(LiveTimelineState.STOPPED)
            return
        }
        live.resumeTimelineOnResume = heartbeat != null
        stopHeartbeat()
    }

    private fun onForeground() {
        if (closed) return
        if (live.exitOnResume) {
            live.exitOnResume = false
            leave(null)
            return
        }
        val resume = live.resumeTimelineOnResume
        live.resumeTimelineOnResume = false
        if (resume && live.session != null) startHeartbeat()
    }

    // The transition gate: one start, zap or recovery owns the stream at a time.

    private enum class Transition { STARTING, SWITCHING, RECOVERING }

    private fun tryAcquire(wanted: Transition): Int? {
        if (transition != null || closed) return null
        transition = wanted
        return ++transitionLease
    }

    private fun owns(lease: Int, expected: Transition): Boolean = !closed && transitionLease == lease && transition == expected

    private fun release(lease: Int) {
        if (transitionLease == lease) transition = null
    }

    private fun forceIdle() {
        transition = null
        transitionLease++
    }

    private fun notice(text: String) {
        mutableInfo.update { it.copy(notice = SessionNotice(text, ++noticeSerial)) }
    }

    override fun close() {
        if (closed) return
        stopHeartbeat()
        sendTimeline(LiveTimelineState.STOPPED)
        closed = true
        choiceAnswer?.complete(null)
        liveSeek.dispose()
        live.cancelClockOpens()
        engine.setListener(null)
        states.close()
        scope.cancel()
        engine.release()
    }

    // Live has no file info or subtitle search.
    override suspend fun searchSubtitles(language: String, title: String?): List<SubtitleSearchHit> = error("live has no subtitle search")
    override suspend fun downloadSubtitle(key: String): SubtitleDownloadOutcome = error("live has no subtitle search")
    override suspend fun loadFileInfo(): MediaFileInfo? = null

    companion object {
        private const val TAG = "LivePlayer"

        /** The last seconds of the window that count as the live edge. */
        const val LIVE_EDGE_SECONDS = 15

        /** History beyond this, in seconds, asks whether to watch from the start. */
        private const val PROMPT_HISTORY_SECONDS = 60

        /** The highest rung of the retry ladder. */
        private const val MAX_FALLBACK_LEVEL = 2

        /** [SessionChoice.options]' first: watch from the start; the second watches live. */
        private const val WATCH_FROM_START = 0

        private val HEARTBEAT = 10.seconds
        private val FIRST_HEARTBEAT = 3.seconds
        private val CLOCK_READY_TIMEOUT = 15.seconds

        /** How soon the guide is read again after a read that found no airing or failed. */
        private val PROGRAM_RETRY = 5.minutes
        private val STREAM_HEADERS = mapOf("Accept-Language" to "en")
    }
}

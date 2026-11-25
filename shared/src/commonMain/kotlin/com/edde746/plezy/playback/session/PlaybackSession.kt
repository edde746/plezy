package com.edde746.plezy.playback.session

import com.edde746.plezy.backend.AudioTrackPreference
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.PlaybackException
import com.edde746.plezy.backend.PlaybackFailureReason
import com.edde746.plezy.backend.PlaybackInitializationOptions
import com.edde746.plezy.backend.PlaybackInitializationResult
import com.edde746.plezy.backend.SubtitlePreference
import com.edde746.plezy.backend.SubtitleSidecar
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.backend.classifyPlaybackFailure
import com.edde746.plezy.data.settings.SkipMode
import com.edde746.plezy.input.VideoClickAction
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaFileInfo
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaMarker
import com.edde746.plezy.model.MediaVersionPreference
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.playback.EngineError
import com.edde746.plezy.playback.EngineErrorKind
import com.edde746.plezy.playback.EngineState
import com.edde746.plezy.playback.HardwareDecoder
import com.edde746.plezy.playback.LoadRequest
import com.edde746.plezy.playback.PlaybackFailure
import com.edde746.plezy.playback.PlaybackOptions
import com.edde746.plezy.playback.PlayerEngine
import com.edde746.plezy.playback.PlayerEngineListener
import com.edde746.plezy.playback.ServerStream
import com.edde746.plezy.playback.SkipKind
import com.edde746.plezy.playback.SkipSegment
import com.edde746.plezy.playback.SubtitleStyle
import com.edde746.plezy.playback.TrackKind
import com.edde746.plezy.playback.queue.AdjacentEpisodes
import com.edde746.plezy.playback.queue.EpisodeCarry
import com.edde746.plezy.playback.queue.EpisodeQueue
import com.edde746.plezy.playback.report.PlayMethod
import com.edde746.plezy.playback.report.PlaybackProgressTracker
import com.edde746.plezy.playback.report.PlaybackReportState
import com.edde746.plezy.playback.report.PlayerProgress
import com.edde746.plezy.playback.report.markSameFileSiblingsWatched
import com.edde746.plezy.playback.source.PlaybackContext
import com.edde746.plezy.playback.source.PlaybackReportingMode
import com.edde746.plezy.playback.source.PlaybackSource
import com.edde746.plezy.playback.source.QualityChoice as StartupQuality
import com.edde746.plezy.playback.source.resolveOpenResumePosition
import com.edde746.plezy.playback.source.transcodedCopyFileInfo
import com.edde746.plezy.playback.tracks.CARRIED_AUDIO_TRACK_ID
import com.edde746.plezy.playback.tracks.NativeAudioTrack
import com.edde746.plezy.playback.tracks.NativeSubtitleTrack
import com.edde746.plezy.playback.tracks.NativeTracks
import com.edde746.plezy.playback.tracks.PlaybackSubtitleResolver
import com.edde746.plezy.playback.tracks.PlayerSyncOffsets
import com.edde746.plezy.playback.tracks.PlexSubtitleDownloader
import com.edde746.plezy.playback.tracks.PreferredSubtitle
import com.edde746.plezy.playback.tracks.SourceSwitchOutcome
import com.edde746.plezy.playback.tracks.SourceSubtitleChoice
import com.edde746.plezy.playback.tracks.SyncOffsetKind
import com.edde746.plezy.playback.tracks.TrackManager
import com.edde746.plezy.playback.tracks.TrackPlayer
import com.edde746.plezy.playback.tracks.TrackType
import com.edde746.plezy.playback.tracks.engineTrackId
import com.edde746.plezy.playback.tracks.sourceTrackId
import com.edde746.plezy.playback.tracks.toNativeAudioTrack
import com.edde746.plezy.playback.tracks.toNativeSubtitleTrack
import com.edde746.plezy.playback.withoutSecrets
import com.edde746.plezy.plex.PlexClient
import com.edde746.plezy.plex.PlexSubtitleSearchResult
import com.edde746.plezy.plex.pingTranscodeSession
import com.edde746.plezy.plex.searchSubtitles
import com.edde746.plezy.plex.selectStreams
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.ScopedPlayerPrefs
import com.edde746.plezy.settings.json.MediaVersionPreferences
import com.edde746.plezy.strings.T
import com.edde746.plezy.trackers.TrackedPosition
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlin.math.abs
import kotlin.math.roundToLong
import kotlin.random.Random
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

/**
 * Plays a server's items (Plex, Jellyfin, Emby) and their downloads in one engine: the player screen's [PlayerSession].
 *
 * - [start] resolves the request on its server ([com.edde746.plezy.playback.source.PlaybackSourceResolver]); a play the
 *   app launches is [prepare]d before its engine is built, so the resolve runs while the music session stops
 *   ([com.edde746.plezy.music.PlaybackCoordinator.claimVideo], the app's, before it builds the engine) and the engine
 *   starts. The file loads with the server's headers at the resume point ([resolveOpenResumePosition]: the request's
 *   position, the start for a shuffle that starts episodes over, the server's offset). The startup quality is the
 *   request's, else the saved default (the cellular one on a metered network) ([StartupQuality.atStartup]); a
 *   download may replace a default, never a quality picked here. Before the engine opens anything the session
 *   registers as the app's one video ([VideoSessions]).
 * - Tracks: the server's subtitle catalog is resolved before the open ([PlaybackSubtitleResolver]), its sidecars are
 *   fetched to this device ([SidecarFetcher]) and added to the file as they come while it opens and plays (one that
 *   fails or times out is left out), and a [TrackManager] picks the engine's tracks once listed, keeps the viewer's
 *   picks (carried to the next item, demoted to their meaning on another item) and writes them to the server. While the
 *   server transcodes, its own tracks are the choice ([SessionInfo.sourceAudio], [SessionInfo.sourceSubtitles],
 *   [selectSourceTrack]).
 * - Reports: a [PlaybackProgressTracker] reports playing, paused and stopped to the server (or the offline queue for a
 *   download), from the first frame on; an open that showed no frame still ends its server session (stopped at the
 *   resume point, no watched mark); trackers ([com.edde746.plezy.trackers.TrackedPlayback]) hear the start, the
 *   playing changes, each second moved and each seek, and the stop (on leaving, a reload, before the next item, and at
 *   the end with the duration as the position). The local history records each online open.
 * - The next and previous items come from the queue ([com.edde746.plezy.playback.queue.EpisodeQueue]), in the offline
 *   library from the show's downloads ([PlaybackEnvironment.downloadedEpisodes]); up next shows the next one
 *   ([SessionInfo.nextEpisode], offline with the still its download saved) with the settings' auto-play and countdown.
 *   Another item, version, quality or server track reloads in place ([reload]): the old session's stopped report goes
 *   first (Plex may end a transcode sharing its session id), and a reload that fails before its file opens, or whose
 *   load the engine refuses (it plays on the old file), rolls back to the file playing. A next item that failed to
 *   open from the end on a server that didn't answer ([SessionInfo.nextFailures]) is offered again.
 * - The end of the file: an end short of the duration on a stream is the stream dying ([SpuriousEofRecovery]), which
 *   reloads at the position (twice) and then shows the failure; a stacked item's part opens the next part; the real
 *   end reports stopped at the duration once ([CompletionLatch]) and tells the sleep timer. With nothing to play next
 *   (the queue's end, no queue) the video [SessionInfo.ended]; a queue that couldn't be read is read once more, and
 *   if it still can't be, the viewer is told and the player stays.
 * - In the background on a TV, a paused video gives its decoders back ([suspendInBackground]) and opens again where
 *   it was on the way back ([restoreAfterBackground]).
 * - Failures follow [resolvePlaybackFailureAction]: HTTP statuses the engine logged (403, 404, 500) latch per open, a
 *   503 open ends after [Http503Watchdog.PATIENCE], an open that stops progressing after [OpenOutcome.DEADLINE]; the
 *   first fatal one latches until the next open ([retry], a reload).
 *
 * [leave] leaves the player (pops its route, which closes the session): how a stop from outside the player leaves it
 * ([VideoSessions.stopVideoAndExit]).
 *
 * Call everything on the main thread; the engine may call its listener from any thread.
 */
class PlaybackSession(
    engine: PlayerEngine,
    private val hardwareDecoder: HardwareDecoder,
    private val env: PlaybackEnvironment,
    parentScope: CoroutineScope,
    private val leave: () -> Unit,
) : PlayerSession {
    private val output = engine
    private val scope = parentScope.childScope()

    private val mutableEngineState = MutableStateFlow(EngineState())
    override val engineState: StateFlow<EngineState> = mutableEngineState.asStateFlow()

    private val mutableInfo = MutableStateFlow(SessionInfo(title = "", resolving = true))
    override val info: StateFlow<SessionInfo> = mutableInfo.asStateFlow()

    private val mutablePlayingKey = MutableStateFlow<String?>(null)

    /** The global key (`serverId:itemId`) of the item playing; null before one and once closed. */
    val playingKey: StateFlow<String?> = mutablePlayingKey.asStateFlow()

    private val mutableOpened = MutableStateFlow<OpenedFile?>(null)

    /** The file last committed to the engine (a new value for each open, the same file's too); null before one and once closed. */
    val opened: StateFlow<OpenedFile?> = mutableOpened.asStateFlow()

    /**
     * Whether a watch-together room starts this player's files now: it opens them paused and sets the speed, so a reload
     * (another version, quality or track, the next item) doesn't start the file, and the title's saved speed isn't
     * applied. The room's side of the player sets it.
     */
    var roomOwnsStart: () -> Boolean = { false }

    /**
     * The engine the player store commands: seeks are in the item's time, which for a stacked item's part becomes the
     * part's time, and a seek outside the open part opens the part that holds it.
     */
    val engine: PlayerEngine = object : PlayerEngine by output {
        override fun seek(seconds: Double, exact: Boolean) = seekItem(seconds, exact)

        // While a reload runs the old file stays paused: a pause or play then is for the file that opens.
        override fun setPaused(paused: Boolean) {
            if (transition != null) pausedDuringReload = paused else output.setPaused(paused)
        }
    }

    /**
     * Runs before each file's engine open with the server's stream ([LoadRequest.server]): the display's switch to the
     * video's mode where the platform makes it first (`PlaybackOutput.preOpen`), which returns once the display settled.
     */
    var beforeOpen: (suspend (ServerStream?) -> Unit)? = null

    private val states = Channel<EngineState>(Channel.UNLIMITED)
    private val versionPreferences = MediaVersionPreferences(env.settings)
    private val syncOffsets = PlayerSyncOffsets(env.settings) { kind, seconds ->
        if (kind == SyncOffsetKind.AUDIO) output.setAudioDelay(seconds) else output.setSubtitleDelay(seconds)
    }
    private val firstFrame = FirstFrameGate()
    private val latch = CompletionLatch()
    private val eofRecovery = SpuriousEofRecovery(scope, { at -> recover(at) }) {
        fail(PlaybackFailure.Engine(EngineError("the stream was interrupted", kind = EngineErrorKind.CUT_SHORT)))
    }
    private val watchdog = Http503Watchdog(scope) { onOpenFailure(FailureCause.SERVER_HTTP_503, EngineError("HTTP 503 for the whole open", 503, EngineErrorKind.OPEN)) }
    private val trackPlayer = EngineTrackPlayer()
    private var ids = SessionIds()

    private var request: PlayRequest.Item? = null

    /**
     * What a play of the video playing now asks for: the launch's request, moved on to the item, version and quality of
     * each in-place reload that opened its file (a reload that failed leaves it as it was). Null before [start].
     */
    val launched: PlayRequest.Item? get() = request
    private var current: Playing? = null
    private var file: EngineFile? = null
    private var quality: StartupQuality? = null
    private var tracker: PlaybackProgressTracker? = null
    private var trackManager: TrackManager? = null
    private var adjacency: AdjacentEpisodes = AdjacentEpisodes.UNAVAILABLE

    /** The queue sheet's items by their entry keys, as [SessionInfo.queue] shows them ([playQueueItem]). */
    private var queueItems: Map<String, MediaItem> = emptyMap()

    /** The queue's next and previous items loading for the item playing. */
    private var adjacentLoad: Job? = null

    /** Why the last in-place reload failed before its file opened. */
    private var reloadFailure: PlaybackFailureReason? = null

    /** The video given back in the background ([suspendInBackground]), until [restoreAfterBackground]. */
    private var suspended: Suspended? = null

    /** The last reports and the engine's release after [close]. */
    private var retirement: Deferred<Unit>? = null

    /** The last target whose file showed a frame: what [retry] restores after a switch away from it failed. */
    private var workingTarget: Target? = null

    /** The item whose chapters and markers are loading: another load for it meanwhile is skipped. */
    private var extrasLoading: String? = null
    private var attempt: Job? = null

    /** The engine's last load; 0 before the first. */
    private var lastLoadId = 0L

    /** The `remember_track_selections` setting as it last changed: off, reports carry no track picks. */
    private var rememberTrackSelections = true
    private var transition: Job? = null

    /** The pause (true) or play (false) asked for while [transition] runs: how its file opens. Null: none asked. */
    private var pausedDuringReload: Boolean? = null

    /** Subtitle shortcut presses not applied yet ([cycleSourceSubtitles]), and the loop applying them. */
    private var pendingSubtitleCycles = 0
    private var subtitleCycleDrain: Job? = null
    private var serverLimitFallbackUsed = false
    private var fatal = false
    private var registered = false
    private var queueJoined = false
    private var sleepRestarted = false
    private var closed = false

    /** The tracks the viewer chose in this player, carried to every later file. */
    private var audioPreference: NativeAudioTrack? = null
    private var subtitlePreference: PreferredSubtitle? = null
    private var secondarySubtitlePreference: PreferredSubtitle? = null

    // Where trackers were told the video is.
    private var trackedVideo = false
    private var trackedPlaying = false
    private var trackedPositionMillis = 0L

    init {
        output.setListener(object : PlayerEngineListener {
            override fun onState(state: EngineState) {
                states.trySend(state)
            }
        })
        scope.launch {
            for (reported in states) onEngineState(reported)
        }
        scope.launch {
            env.settings.observe().map { SubtitleStyle.of(it.subtitles) }.distinctUntilChanged().collect(output::setSubtitleStyle)
        }
        scope.launch { followSettings() }
        scope.launch { followServers() }
    }

    /** Plays [request]; an item playing in this session is reported stopped and left first, then it resolves. */
    fun start(request: PlayRequest.Item) = start(request) {
        leaveFile(stoppedReport = true)
        val found = Found.of(request, env)
        val playIds = ids
        withContext(env.requests) { prepared(request, env, playIds, found) }
    }

    /** Plays [launch], whose source has been resolving since before this session's engine was built ([prepare]). */
    internal fun start(launch: Launch) {
        ids = launch.ids
        start(launch.request) { launch.prepared.await() }
    }

    private fun start(request: PlayRequest.Item, prepare: suspend () -> Prepared) {
        check(!closed) { "the session is closed" }
        this.request = request
        serverLimitFallbackUsed = false
        workingTarget = null
        mutablePlayingKey.value = request.globalKey
        val item = request.item
        mutableInfo.value.scrubPreview?.dispose()
        mutableInfo.value = SessionInfo(
            title = item?.let(::titleOf).orEmpty(),
            subtitle = item?.let(::subtitleOf),
            resolving = true,
            episode = item?.kind == MediaKind.EPISODE,
            local = request.offline,
            skipping = mutableInfo.value.skipping,
            videoClick = mutableInfo.value.videoClick,
            rewindOnResumeSeconds = mutableInfo.value.rewindOnResumeSeconds,
        )
        audioPreference = carriedAudio(request)
        subtitlePreference = request.subtitleTrack?.let(::preferredOf)
        secondarySubtitlePreference = request.secondarySubtitleTrack?.let(::preferredOf)
        restart { begin(prepare()) }
    }

    private suspend fun begin(prepared: Prepared) {
        when (prepared) {
            Prepared.Unavailable -> fail(PlaybackFailure.Server(PlaybackFailureReason.SERVER_UNAVAILABLE, T.messages.errorLoading(T.messages.serverUnavailableForProfile)))
            is Prepared.Failed -> {
                if (prepared.startup != null) {
                    quality = prepared.startup
                    register()
                }
                failStart(prepared.error)
            }
            is Prepared.Ready -> {
                quality = prepared.startup
                register()
                // A watch-together room starts the file itself, once everyone is ready.
                open(prepared.target.copy(autoStart = prepared.target.autoStart && !roomOwnsStart()), prepared.context)
            }
        }
    }

    private suspend fun resolve(target: Target, offline: Boolean, downloadOutranksQuality: Boolean): PlaybackContext {
        val client = env.resolver.playbackClient(target.item.serverId?.let(::ServerId), offline)
        return resolveSource(env, ids, target, client, offline, downloadOutranksQuality, audioPreference?.toPreference(), subtitlePreference?.toPreference())
    }

    /**
     * Registers as the app's video, once: stopping it from outside closes the session, and a stop that leaves the
     * player pops it and waits for the last reports.
     */
    private fun register() {
        if (registered) return
        registered = true
        env.videoSessions.register(
            this,
            shutdown = { close() },
            stopAndExit = {
                leave()
                retirement?.await()
                closed
            },
        )
    }

    // Opening

    /**
     * Opens [context]'s file for [target]: the source is committed, the engine loads at the target's position (the open
     * part's time for a stacked item), and the tracks, reports and extras of the file follow.
     */
    private suspend fun open(target: Target, context: PlaybackContext, rollback: Rollback? = null) {
        val result = context.result
        val strictMismatch = target.strict && (result.selectedMediaIndex != target.mediaIndex || target.mediaSourceId != null && result.selectedMediaSourceId != target.mediaSourceId)
        if (strictMismatch) return fail(PlaybackFailure.Server(PlaybackFailureReason.NO_PLAYABLE_SOURCE, T.messages.playbackFailed))
        val url = result.videoUrl ?: return fail(PlaybackFailure.Server(PlaybackFailureReason.NO_PLAYABLE_SOURCE, T.messages.fileInfoNotAvailable))
        // The file replaced is no longer the way back for the one before it.
        file?.let { f -> f.rollback?.let(::release); f.rollback = null }
        val previous = current
        val source = PlaybackSource.of(context, target.quality, target.mediaSourceId)
        val sameItem = previous?.item?.globalKey == context.item.globalKey
        val playing = Playing(target, context, source, backend = context.reportingClient ?: target.backend)
        current = playing
        request = request?.let { r ->
            r.copy(
                itemId = context.item.id, item = context.item, mediaIndex = target.mediaIndex, mediaSourceId = target.mediaSourceId,
                qualityPreset = if (quality?.explicit == true) target.quality else r.qualityPreset,
                // A show's Play names its first item only: the next one plays on its own.
                showPlay = r.showPlay && r.itemId == context.item.id,
            )
        }
        latch.reset()
        if (!sameItem) {
            eofRecovery.resetBudget()
            adjacency = AdjacentEpisodes.UNAVAILABLE
            serverLimitFallbackUsed = false
        }
        if (result.fallbackReason != null && !target.quality.isOriginal) showNotice(T.videoControls.transcodeUnavailableFallback)
        if (!context.usesLocalMedia && request?.offline != true) scope.launch { env.history.recordPlayback(context.item) }

        // A local file opens before the account's preferences may have loaded: they pick its tracks, so wait for them.
        if (context.usesLocalMedia) env.awaitProfile()
        val selection = PlaybackSubtitleResolver.resolve(
            metadata = context.item,
            mediaInfo = result.mediaInfo,
            sidecars = result.subtitleSidecars,
            profile = env.profile(),
            preferredAudioTrack = audioPreference,
            preferredSubtitle = subtitlePreference,
            preferredSecondarySubtitle = secondarySubtitlePreference,
            preserveSourceIdentity = sameItem,
            isTranscoding = result.isTranscoding,
        )
        val timeline = result.mediaInfo?.partTimeline
        val partStart = timeline?.current?.start?.inWholeMilliseconds?.let { it / 1000.0 } ?: 0.0
        val startAt = ((target.startPosition?.inWholeMilliseconds ?: 0L) / 1000.0 - partStart).coerceAtLeast(0.0)
        val options = PlaybackOptions.of(env.settings.settings(), hardwareDecoder)
        val sidecars = selection.sidecarsAtOpen
        beforeOpen?.invoke(context.serverStream)

        val newFile = EngineFile(playing, partStart, startAt)
        file?.cancelSidecarFetches()
        file = newFile
        fatal = false
        firstFrame.resetUiForOpen()
        firstFrame.resetRenderedForAttempt()
        watchdog.disarm()
        newFile.outcome = OpenOutcome(scope) { onOpenFailure(FailureCause.OPEN_TIMED_OUT, EngineError("no load progress for ${OpenOutcome.DEADLINE.inWholeSeconds}s", kind = EngineErrorKind.OPEN)) }
        newFile.loadId = output.load(
            LoadRequest(
                url = url,
                options = options,
                title = titleOf(context.item),
                headers = context.streamHeaders.orEmpty(),
                startSeconds = startAt,
                server = context.serverStream,
            ),
        )
        lastLoadId = newFile.loadId
        newFile.outcome.onFileStarted()
        mutableOpened.value = OpenedFile(
            context.item, source.mediaIndex, result.selectedMediaSourceId, offline = context.usesLocalMedia,
            serial = (mutableOpened.value?.serial ?: 0) + 1, loadId = newFile.loadId, startMs = millis(partStart + startAt),
        )
        output.setPaused(!(target.autoStart && env.playbackAllowed()))
        addSidecars(newFile, sidecars)

        if (rollback == null) trackManager?.dispose()
        trackManager = TrackManager(
            player = trackPlayer,
            scope = scope,
            settings = env.settings,
            isActive = { !closed && file === newFile },
            metadata = context.item,
            mediaInfo = result.mediaInfo,
            persistTrackPreference = (playing.backend as? PlexClient)?.let { plex -> { partId, type, streamId -> plexSelect(plex, partId, type, streamId) } },
            // Jellyfin keeps a pick through the progress reports once the account's memory is on; Emby keeps none.
            enableTrackSelectionMemory = playing.backend?.takeIf { it.backend == BackendKind.JELLYFIN }?.let { backend ->
                env.trackSelectionMemory?.let { memory -> { type -> memory(backend, type) } }
            },
            getProfileSettings = env.profile,
            waitForProfileSettings = { if (context.usesLocalMedia) env.awaitProfile() },
            showMessage = ::showNotice,
            preferredAudioTrack = audioPreference,
            preferredSubtitle = if (selection.isOff) selection.declinedPreference ?: PreferredSubtitle.Off else PreferredSubtitle.Native(selection.primaryTrack),
            preferredSecondarySubtitle = selection.secondaryTrack?.let { PreferredSubtitle.Native(it) } ?: secondarySubtitlePreference,
            primarySubtitleIsServerRendered = result.isTranscoding && selection.primarySourceStreamId != null && selection.primarySidecar == null,
            persistAutomaticSubtitleSelection = selection.primaryHonorsPreference,
            // A room's speed is the room's, not the title's saved one.
            playbackRateOwnedExternally = { request?.roomStart == true || roomOwnsStart() },
        ).also { it.applyTrackSelectionWhenReady() }
        playing.subtitleSourceId = selection.primarySourceStreamId
        playing.subtitleOffIsDeliberate = !selection.isOff || selection.declinedPreference == null
        if (rollback == null) tracker?.dispose()
        tracker = progressTracker(playing, newFile)
        // Until its first frame, the reload can still go back to the file it replaced.
        newFile.rollback = rollback
        scope.launch { syncOffsets.applyFor(context.item) }
        // A room's speed is the room's, not the title's saved one.
        if (request?.roomStart != true && !roomOwnsStart()) scope.launch { applySpeed(context.item) }
        // The queue is joined (or left) as the item opens, before its neighbours are looked up in it: the series queue
        // a lookup builds is then never cleared under its result.
        if (!queueJoined) {
            queueJoined = true
            env.queue.onPlayerOpened(context.item)
        } else if (target.itemChanged) {
            env.queue.onItemChanged(context.item)
        }

        updateInfo {
            it.copy(
                title = titleOf(context.item),
                subtitle = subtitleOf(context.item),
                artworkUrl = playing.backend?.let { b -> imageOf(b, context.item.thumbPath ?: context.item.artPath, ARTWORK_PX) },
                posterUrl = playing.backend?.let { b -> imageOf(b, context.item.grandparentThumbPath ?: context.item.thumbPath) },
                item = context.item,
                resolving = false,
                failure = null,
                ended = false,
                episode = context.item.kind == MediaKind.EPISODE,
                local = context.usesLocalMedia,
                versions = result.availableVersions.map { v -> VersionOption(v.displayLabel, v.parts.firstOrNull()?.file?.substringAfterLast('/')) },
                versionIndex = source.mediaIndex,
                quality = qualityChoice(playing),
                transcoding = result.isTranscoding,
                sourceAudio = sourceAudio(playing),
                sourceSubtitles = sourceSubtitles(playing),
                subtitleSearch = playing.backend?.capabilities?.externalSubtitleSearch == true && !context.usesLocalMedia,
                // A transcoded download's file info is known without the server.
                fileInfo = playing.backend != null || !result.downloadedQuality.isOriginal,
                chapters = if (sameItem) it.chapters else null,
                segments = if (sameItem) it.segments else null,
                scrubPreview = if (sameItem && it.scrubPreview != null && previous.result.mediaInfo?.partId == result.mediaInfo?.partId) it.scrubPreview else null.also { _ -> if (rollback == null) it.scrubPreview?.dispose() },
                // Another item's neighbours aren't this one's: until its lookup lands, the queue shown marks it alone.
                nextEpisode = if (sameItem) it.nextEpisode else null,
                hasPreviousEpisode = sameItem && it.hasPreviousEpisode,
                queue = if (sameItem) it.queue else it.queue.map { e -> e.copy(current = queueItems[e.key]?.globalKey == context.item.globalKey) },
            )
        }
        if (!sameItem) {
            scope.launch { loadExtras(playing) }
            adjacentLoad = scope.launch { loadAdjacent(playing) }
        }
    }

    private fun progressTracker(playing: Playing, file: EngineFile): PlaybackProgressTracker {
        val context = playing.context
        val backend = playing.backend.takeUnless { context.reportingMode == PlaybackReportingMode.OFFLINE_QUEUE }
        return PlaybackProgressTracker(
            backend = backend,
            item = context.item,
            player = {
                val state = mutableEngineState.value
                PlayerProgress(state.positionSeconds.seconds, state.durationSeconds.seconds, isActive = !state.paused && !state.eof, tracks = trackPlayer.tracks.value)
            },
            scope = env.reportScope,
            notifier = env.notifier,
            isOffline = backend == null,
            offlineQueue = env.offlineQueue,
            queueOnOnlineFailure = context.shouldQueueOnReportFailure,
            playMethod = PlayMethod.of(context.result.playMethod, context.result.isTranscoding),
            playSessionId = context.result.playSessionId,
            mediaInfo = context.result.mediaInfo,
            rememberTrackSelections = { rememberTrackSelections },
            onScrobbled = backend?.let { b ->
                val marks = env.trackerMarks ?: return@let null
                suspend { markSameFileSiblingsWatched(env.playbackState.sameFileSiblings(context.item, context.result.mediaInfo?.partId?.toString()), b, env.notifier, marks) }
            },
            onPausedKeepalive = (backend as? PlexClient)?.takeIf { context.result.isTranscoding }?.let { plex -> suspend { plex.pingTranscodeSession(ids.transcode) } },
            canReportPlayback = { this.file === file && firstFrame.rendered && !fatal },
            hasRenderedPlayback = { file.rendered },
            subtitleOffIsDeliberate = { playing.subtitleOffIsDeliberate },
            burnedSubtitleStreamIndex = { playing.subtitleSourceId.takeIf { context.result.isTranscoding } },
        )
    }

    // The engine's reports

    private fun onEngineState(reported: EngineState) {
        // The unloaded engine's reports aren't the video's: it stays as it was, paused, until it opens again.
        if (suspended != null) return
        val file = file
        // A load the engine refused before it replaced the file: after the load's error, the file it plays on is current
        // again under its own load id.
        val back = file?.rollback
        val refusal = file?.error
        val outgoing = back?.file
        if (file != null && back != null && refusal != null && outgoing != null && !file.rendered && reported.loadId == outgoing.loadId && !closed) {
            Log.w(TAG) { "the engine refused the load; back to the file it plays" }
            file.rollback = null
            mutableEngineState.value = itemTime(reported, outgoing)
            rollBack(back, refusal.withoutSecrets().message)
            return onEngineState(reported)
        }
        if (file == null || reported.loadId != file.loadId || closed) {
            // Only the engine's state before its first load is the player's; a retired load's (its end, its position)
            // belongs to a file that's gone.
            if (lastLoadId == 0L && !closed) mutableEngineState.value = reported
            return
        }
        if (!reported.eof) file.viewerPlaying = !reported.paused
        followOpen(file, reported)
        val error = reported.error
        if (error != null) {
            mutableEngineState.value = itemTime(reported, file)
            if (file.error == null) {
                file.error = error
                onEngineError(file, error)
            }
            return
        }
        val state = judgeEnd(file, reported)
        mutableEngineState.value = itemTime(state, file)
        trackPlayer.publish(state)
        if (!state.loaded) return
        if (!file.rendered) onFirstFrame(file, state)
        followPosition(file, state)
        followPlaying(file, state)
        if (state.eof) onEnd(file, state)
        followServerStop()
    }

    /** Whether the server ended the reporting session, as the tracker knows it now ([SessionInfo.stoppedByServer]). */
    private fun followServerStop() {
        val stoppedByServer = tracker?.stoppedByServer == true
        if (stoppedByServer != mutableInfo.value.stoppedByServer) updateInfo { it.copy(stoppedByServer = stoppedByServer) }
    }

    /** The open's progress, the HTTP statuses it latches and the 503 watchdog. */
    private fun followOpen(file: EngineFile, state: EngineState) {
        val status = state.httpErrorStatus
        if (status != null && status in FATAL_PLAYBACK_HTTP_STATUSES) file.latchedStatuses += status
        if (state.playbackRestarts > file.restarts) {
            file.restarts = state.playbackRestarts
            file.latchedStatuses.clear()
        }
        if (!file.rendered && status == 503) watchdog.onOpenPhase503()
        if (state.tracks.isNotEmpty() || state.durationSeconds > 0) file.outcome.onFileLoaded()
        val read = state.cacheEndSeconds
        if (read != null && read != file.lastRead) {
            file.lastRead = read
            file.outcome.onProgress()
        }
        if (state.error != null) file.outcome.onFailed()
    }

    private fun onFirstFrame(file: EngineFile, state: EngineState) {
        file.rendered = true
        file.rollback?.let(::release)
        file.rollback = null
        firstFrame.markReady()
        file.outcome.onFirstFrame()
        watchdog.disarm()
        eofRecovery.clearPark()
        val playing = file.playing
        // This request is proven: a later switch that fails restores it ([retry]).
        workingTarget = playing.target
        val item = playing.item
        val position = itemSeconds(state.positionSeconds, file)
        // The first frame's report is the playing one; a change of playing before it wasn't reported, nor is it again.
        file.wasPlaying = !state.paused && !state.eof
        tracker?.startTracking(position.seconds, itemDuration(state, file).seconds)
        val backend = playing.backend
        if (backend != null) trackStart(item, backend, trackedAt(state, file), playing = !state.paused)
        if (!sleepRestarted) {
            sleepRestarted = true
            env.sleepTimer?.bindPlayback(this) { output.setPaused(true) }
            env.sleepTimer?.restartIfNeeded()
        }
        if (mutableInfo.value.scrubPreview == null && backend != null && !playing.context.usesLocalMedia) {
            val mediaInfo = playing.result.mediaInfo
            if (mediaInfo != null) {
                scope.launch {
                    val preview = loading("the scrub previews") { backend.createScrubPreviewSource(item, mediaInfo) }
                    if (current === playing && mutableInfo.value.scrubPreview == null) updateInfo { it.copy(scrubPreview = preview) } else preview?.dispose()
                }
            }
        }
        // The extras the open found empty may have been a stale cached row: the server is asked again.
        if (mutableInfo.value.chapters == null && mutableInfo.value.segments == null) scope.launch { loadExtras(playing, forceRefresh = true) }
    }

    private fun followPosition(file: EngineFile, state: EngineState) {
        val positionMillis = millis(itemSeconds(state.positionSeconds, file))
        val durationMillis = millis(itemDuration(state, file))
        rearming { latch.classifyPosition(positionMillis, durationMillis, promptVisible = false, countdownActive = false) }
        eofRecovery.onPositionAdvanced(positionMillis)
        if (trackedVideo && abs(positionMillis - trackedPositionMillis) >= TRACKED_POSITION_STEP_MILLIS) {
            trackedPositionMillis = positionMillis
            env.trackers?.onPosition(trackedAt(state, file))
        }
    }

    /**
     * Runs [change] to the end latch: once it re-arms (the viewer went back from the end), the video plays on, so the
     * server hears of it again after the end's stopped report, trackers too, and it no longer [SessionInfo.ended].
     */
    private inline fun rearming(change: () -> Unit) {
        val wasTriggered = latch.triggered
        change()
        if (!wasTriggered || latch.triggered) return
        tracker?.resumeAfterStoppedReport()
        val file = file
        val backend = current?.backend
        if (file != null && backend != null) trackStart(file.playing.item, backend, trackedNow(file), playing = isPlaying())
        if (mutableInfo.value.ended) updateInfo { it.copy(ended = false) }
    }

    private fun followPlaying(file: EngineFile, state: EngineState) {
        val playing = !state.paused && !state.eof
        if (playing != file.wasPlaying) {
            file.wasPlaying = playing
            scope.launch {
                tracker?.sendProgress(if (playing) PlaybackReportState.PLAYING else PlaybackReportState.PAUSED)
                // Playing after a pause opens a new session where the server ended the last one.
                followServerStop()
            }
        }
        if (trackedVideo && playing != trackedPlaying) {
            trackedPlaying = playing
            env.trackers?.onPlayingChanged(playing, trackedAt(state, file))
        }
    }

    /**
     * [reported]'s end as the session takes it: an end the recovery handles ([SpuriousEofRecovery]) isn't one, nor is a
     * stacked part's end with a part after it (the next part opens).
     */
    private fun judgeEnd(file: EngineFile, reported: EngineState): EngineState {
        if (!reported.eof || !reported.loaded) {
            file.endJudged = false
            return reported
        }
        if (file.endJudged) return if (file.endIntercepted) reported.copy(eof = false, buffering = true) else reported
        file.endJudged = true
        val playing = file.playing
        val timeline = playing.result.mediaInfo?.partTimeline
        if (timeline != null && timeline.hasNext) {
            file.endIntercepted = true
            val next = timeline.parts[timeline.currentIndex + 1].start
            // Stream ids are the part's: the next part picks its own.
            reload(playing.target.copy(startPosition = next, audioStreamId = null, autoStart = true), "next part", showError = true)
            return reported.copy(eof = false, buffering = true)
        }
        if (playing.context.usesLocalMedia || transition != null) return reported
        val intercepted = eofRecovery.interceptEof(
            EofReport(
                positionMillis = millis(itemSeconds(reported.positionSeconds, file)),
                playerDurationMillis = if (timeline == null) millis(reported.durationSeconds) else 0,
                metadataDurationMillis = playing.item.durationMs,
                partEndMillis = timeline?.current?.end?.inWholeMilliseconds,
                transcoding = playing.result.isTranscoding,
                transportFault = reported.transportFault || reported.httpErrorStatus != null,
                fileSizeBytes = reported.fileSizeBytes,
                fileFormat = reported.fileFormat,
                serverStopped = tracker?.stoppedByServer == true,
            ),
        )
        file.endIntercepted = intercepted
        return if (intercepted) reported.copy(eof = false, buffering = true) else reported
    }

    /**
     * The video's real end: once per approach to the end, the stopped report at the duration, trackers, the sleep timer,
     * and what comes after it ([settleEnd]).
     */
    private fun onEnd(file: EngineFile, state: EngineState) {
        if (latch.triggered || transition != null) return
        latch.latch()
        val duration = itemDuration(state, file)
        scope.launch { tracker?.sendStoppedProgressOnce(duration.seconds) }
        trackStop(TrackedPosition(millis(duration), millis(duration)))
        env.sleepTimer?.notifyVideoCompleted()
        scope.launch { settleEnd(file) }
    }

    /**
     * What follows [file]'s end once the queue answered: up next for a next item; a queue that couldn't be read is read
     * once more, and still failing says so; nothing next: the video [SessionInfo.ended].
     */
    private suspend fun settleEnd(file: EngineFile) {
        adjacentLoad?.join()
        fun stillEnded() = this.file === file && latch.triggered && !closed
        if (!stillEnded()) return
        var action = completionNavigationAction(adjacency.next != null, adjacency.nextStatus)
        if (action == CompletionAction.RETRY_ADJACENT) {
            loadAdjacent(file.playing)
            if (!stillEnded()) return
            action = completionNavigationAction(adjacency.next != null, adjacency.nextStatus)
        }
        when (action) {
            CompletionAction.PRESENT_NEXT -> Unit
            CompletionAction.RETRY_ADJACENT -> showNotice(T.messages.errorLoadingSeries)
            CompletionAction.EXIT -> updateInfo { it.copy(ended = true) }
        }
    }

    // Failures

    private fun onEngineError(file: EngineFile, error: EngineError) {
        val shown = error.withoutSecrets()
        Log.w(TAG) { "engine error (${shown.kind}, HTTP ${shown.httpStatus}): ${shown.message}" }
        val cause = when {
            shown.kind == EngineErrorKind.AUDIO_OUTPUT -> FailureCause.AUDIO_OUTPUT
            shown.httpStatus == 500 -> FailureCause.SERVER_HTTP_500
            shown.httpStatus == 404 -> FailureCause.SERVER_HTTP_404
            shown.kind == EngineErrorKind.DECODE && !file.rendered -> FailureCause.STREAM_INIT
            else -> null
        }
        decide(file, cause, shown)
    }

    /** A failure of the open that the engine never reported: the 503 watchdog's, or the open deadline's. */
    private fun onOpenFailure(cause: FailureCause, error: EngineError) {
        val file = file ?: return
        if (file.rendered && cause == FailureCause.SERVER_HTTP_503) return
        file.outcome.abort(error.message)
        decide(file, cause, error)
    }

    private fun decide(file: EngineFile, cause: FailureCause?, error: EngineError) {
        if (fatal || this.file !== file) return
        val playing = file.playing
        val failure = when (resolvePlaybackFailureAction(cause, file.latchedStatuses.toSet() + listOfNotNull(error.httpStatus?.takeIf { it == 403 }), live = false)) {
            PlaybackFailureAction.PLAYBACK_NOT_ALLOWED -> PlaybackFailure.Server(PlaybackFailureReason.PLAYBACK_NOT_ALLOWED, T.messages.playbackNotAllowedBody)
            PlaybackFailureAction.SERVER_LIMIT -> PlaybackFailure.ServerLimit(
                offersServerLimitTranscode(
                    live = false,
                    plexBacked = playing.item.backend == BackendKind.PLEX,
                    serverSupportsTranscoding = playing.backend?.capabilities?.videoTranscoding == true,
                    requestedPreset = playing.target.quality,
                    fallbackAlreadyUsed = serverLimitFallbackUsed || playing.target.forceTranscode,
                ),
            )
            PlaybackFailureAction.MEDIA_UNREADABLE -> PlaybackFailure.Server(PlaybackFailureReason.NO_PLAYABLE_SOURCE, T.messages.mediaUnreadableBody)
            PlaybackFailureAction.SERVER_BUSY -> PlaybackFailure.Server(PlaybackFailureReason.SERVER_UNAVAILABLE, T.messages.serverBusyBody)
            else -> PlaybackFailure.Engine(error)
        }
        fail(failure)
    }

    /** Shows [failure] and latches it: the engine pauses, reports stop until the next open. */
    private fun fail(failure: PlaybackFailure) {
        fatal = true
        watchdog.disarm()
        file?.outcome?.abort("failed")
        firstFrame.forceUiReadyOnFailure()
        output.setPaused(true)
        tracker?.stopTracking()
        if (trackedVideo && trackedPlaying) {
            trackedPlaying = false
            file?.let { f -> env.trackers?.onPlayingChanged(false, trackedNow(f)) }
        }
        updateInfo { it.copy(resolving = false, failure = failure) }
    }

    private fun failStart(error: Exception) {
        Log.w(TAG, error) { "the playback couldn't start" }
        val classified = error as? PlaybackException ?: classifyPlaybackFailure(error)
        fail(PlaybackFailure.Server(classified.reason, classified.message ?: T.messages.playbackFailed))
    }

    // Actions

    /**
     * Opens again what failed: after a switch away from a file that played (another version, quality or track of the
     * item), that file at the position the switch asked for; else the failed file, from the position when it showed a
     * frame.
     */
    override fun retry() {
        if (closed || mutableInfo.value.failure == null) return
        val playing = current
        val request = request ?: return
        if (playing == null) return start(request)
        val failed = playing.target
        val working = workingTarget
        val target = when {
            working != null && working.item.globalKey == failed.item.globalKey && !working.sameSourceAs(failed) ->
                working.copy(startPosition = failed.startPosition ?: working.startPosition, itemChanged = false)
            file?.rendered == true -> failed.copy(startPosition = currentItemSeconds().seconds)
            else -> failed
        }.copy(autoStart = true)
        val shown = mutableInfo.value.failure
        updateInfo { it.copy(failure = null, resolving = true) }
        reload(target, "retry", showError = false, restoreFailure = shown)
    }

    override fun playNextEpisode() {
        val next = adjacency.next ?: return
        if (closed) return
        // Started by the end of the video (up next, its countdown, picture in picture): a server blip that fails it
        // offers it again.
        val atEnd = latch.triggered
        scope.launch {
            if (playItem(next) != ReloadOutcome.FAILED || !atEnd || reloadFailure != PlaybackFailureReason.SERVER_UNAVAILABLE) return@launch
            if (adjacency.next != null) updateInfo { it.copy(nextFailures = it.nextFailures + 1) }
        }
    }

    /** The item before; with none, this one from its start. Whether past its first seconds it restarts is the store's. */
    override fun playPreviousEpisode() {
        if (closed) return
        val previous = adjacency.previous ?: return engine.seek(0.0, exact = false)
        scope.launch { playItem(previous) }
    }

    override fun playQueueItem(key: String) {
        val item = queueItems[key] ?: return Log.w(TAG) { "queue pick $key: not in the queue shown" }
        if (closed) return
        scope.launch {
            val outcome = playItem(item)
            if (outcome != ReloadOutcome.OPENED) Log.w(TAG) { "queue pick $key: $outcome" }
        }
    }

    /** Another item in place, with the version, quality and tracks carried ([EpisodeCarry]). */
    private suspend fun playItem(item: MediaItem): ReloadOutcome {
        val playing = current ?: return ReloadOutcome.REJECTED
        val follow = env.settings.value(AppSettings.followServerTrackSelections)
        val carry = EpisodeCarry.of(
            playing.result.availableVersions, playing.source.mediaIndex, quality?.preset, audioPreference?.toPreference(),
            subtitlePreference?.toPreference(), secondarySubtitlePreference?.toPreference(), follow,
        )
        if (follow) {
            audioPreference = null
            subtitlePreference = null
            secondarySubtitlePreference = null
        } else {
            subtitlePreference = PreferredSubtitle.demoteToIntent(subtitlePreference)
            secondarySubtitlePreference = PreferredSubtitle.demoteToIntent(secondarySubtitlePreference)
        }
        val shuffleFromStart = env.playbackState.isShuffleActive && env.settings.value(AppSettings.shuffleStartsFromBeginning)
        val target = Target(
            item = item,
            backend = playing.backend,
            mediaIndex = 0,
            mediaSourceId = null,
            versionSignature = carry.versionSignature,
            quality = carry.quality ?: playing.target.quality,
            audioStreamId = null,
            startPosition = resolveOpenResumePosition(null, shuffleFromStart, viewOffsetMs = item.viewOffsetMs),
            forceTranscode = false,
            autoStart = !roomOwnsStart(),
            itemChanged = true,
        )
        return reload(target, "item change").await()
    }

    /**
     * Opens [item]'s version [mediaIndex] ([mediaSourceId]) in place for a watch-together room, once a reload under way
     * is over: paused for the room to start it, at the item's saved position, on its own tracks, with nothing shown when
     * it fails (the file playing stays). SUPERSEDED when the room no longer [wants] it after the wait; REJECTED when the
     * session plays nothing (yet) or closed; FAILED when the item's server is unknown or its file didn't resolve.
     */
    suspend fun openForRoom(item: MediaItem, mediaIndex: Int, mediaSourceId: String?, wants: () -> Boolean): ReloadOutcome {
        while (true) {
            val running = transition ?: break
            running.join()
        }
        val playing = current
        if (closed || playing == null) return ReloadOutcome.REJECTED
        if (!wants()) return ReloadOutcome.SUPERSEDED
        val backend = item.serverId?.let { env.servers.client(ServerId(it)) } ?: return ReloadOutcome.FAILED
        audioPreference = null
        subtitlePreference = null
        secondarySubtitlePreference = null
        val target = Target(
            item = item,
            backend = backend,
            mediaIndex = mediaIndex,
            mediaSourceId = mediaSourceId,
            versionSignature = null,
            quality = playing.target.quality,
            audioStreamId = null,
            startPosition = resolveOpenResumePosition(viewOffsetMs = item.viewOffsetMs),
            forceTranscode = false,
            autoStart = false,
            itemChanged = true,
        )
        return reload(target, "watch together media switch", showError = false).await()
    }

    override fun onSeek(seconds: Double) {
        val file = file ?: return
        if (closed) return
        if (mutableInfo.value.failure != null && eofRecovery.parked) {
            updateInfo { it.copy(failure = null) }
            eofRecovery.retry(seconds)
            return
        }
        val state = mutableEngineState.value
        if (trackedVideo) {
            trackedPositionMillis = millis(seconds)
            env.trackers?.onPosition(TrackedPosition(millis(seconds), millis(itemDuration(state, file))))
        }
        if (seconds < itemDuration(state, file) - CompletionLatch.REARM_WINDOW_MILLIS / 1000.0) rearming { latch.rearmIfClear(promptVisible = false, countdownActive = false) }
    }

    /** The store's seek, in the item's time ([engine]). */
    private fun seekItem(seconds: Double, exact: Boolean) {
        val file = file ?: return output.seek(seconds, exact)
        val timeline = file.playing.result.mediaInfo?.partTimeline
        if (timeline == null || timeline.covers(seconds.seconds)) return output.seek(seconds - file.partStart, exact)
        reload(file.playing.target.copy(startPosition = seconds.seconds, audioStreamId = null, autoStart = !mutableEngineState.value.paused), "part change")
    }

    override fun onTrackSelected(kind: TrackKind, id: Long?) {
        val manager = trackManager ?: return
        val tracks = mutableEngineState.value.tracks
        scope.launch {
            when (kind) {
                TrackKind.AUDIO -> {
                    val track = tracks.firstOrNull { it.kind == kind && it.id == id }?.toNativeAudioTrack() ?: return@launch
                    audioPreference = track
                    manager.onAudioTrackSelectedByUser(track)
                }
                TrackKind.SUBTITLE -> {
                    val track = tracks.firstOrNull { it.kind == kind && it.id == id }?.let { it.toNativeSubtitleTrack(trackPlayer.uriOf(it.id)) } ?: NativeSubtitleTrack.OFF
                    subtitlePreference = if (track == NativeSubtitleTrack.OFF) PreferredSubtitle.Off else PreferredSubtitle.Native(track)
                    current?.subtitleOffIsDeliberate = true
                    manager.onSubtitleTrackSelectedByUser(track)
                }
                TrackKind.VIDEO -> {}
            }
            tracker?.onTracksChanged()
        }
    }

    override fun onSecondSubtitleSelected(id: Long?) {
        val track = mutableEngineState.value.tracks.firstOrNull { it.kind == TrackKind.SUBTITLE && it.id == id }
        secondarySubtitlePreference = track?.let { PreferredSubtitle.Native(it.toNativeSubtitleTrack(trackPlayer.uriOf(it.id))) } ?: PreferredSubtitle.Off
    }

    override fun addSubtitle(url: String) {
        addSidecars(file ?: return, listOf(SubtitleSidecar(url)))
    }

    /**
     * Adds [sidecars] to [file] as each one's local file comes ([SidecarFetcher], with the stream's headers), in the
     * order they come; the file opens and plays meanwhile. One that fails or times out is left out, and none is added
     * once the file is left.
     */
    private fun addSidecars(file: EngineFile, sidecars: List<SubtitleSidecar>) {
        val stream = file.playing.result.videoUrl ?: return
        val headers = file.playing.context.streamHeaders.orEmpty()
        for (sidecar in sidecars) {
            file.sidecarFetches += scope.launch {
                val local = env.sidecars.fetch(sidecar.url, stream, headers) ?: return@launch
                if (closed || this@PlaybackSession.file !== file) return@launch
                file.sidecarUrls[local] = sidecar.url
                output.addSubtitle(local, sidecar.title, sidecar.language)
            }
        }
    }

    override fun setAutoPlayNext(enabled: Boolean) {
        if (closed) return
        updateInfo { it.copy(nextEpisode = it.nextEpisode?.copy(autoplay = enabled)) }
        scope.launch { env.settings.set(AppSettings.autoPlayNextEpisode, enabled) }
    }

    override fun selectVersion(index: Int) {
        val playing = current ?: return
        val version = playing.result.availableVersions.getOrNull(index) ?: return
        if (closed || index == playing.source.mediaIndex) return
        scope.launch { versionPreferences.save(playing.item, MediaVersionPreference.forVersion(version, index, env.clock.now())) }
        val at = currentItemSeconds()
        reload(
            playing.target.copy(mediaIndex = index, mediaSourceId = version.id, versionSignature = null, audioStreamId = null, startPosition = at.seconds, autoStart = resumesAfterReload(), itemChanged = false),
            "version switch",
        )
    }

    override fun selectQuality(preset: TranscodeQualityPreset) {
        val playing = current ?: return
        if (closed || preset == playing.target.quality) return
        quality = (quality ?: StartupQuality(preset, explicit = true)).picked(preset)
        reload(playing.target.copy(quality = preset, forceTranscode = false, startPosition = currentItemSeconds().seconds, autoStart = resumesAfterReload(), itemChanged = false), "quality switch")
    }

    override fun selectSourceTrack(kind: TrackKind, id: Int?) {
        val playing = current ?: return
        if (closed) return
        when (kind) {
            TrackKind.AUDIO -> {
                val streamId = id ?: return
                if (streamId == playing.target.audioStreamId) return
                playing.result.mediaInfo?.audioTracks?.firstOrNull { it.id == streamId }?.let { row ->
                    audioPreference = PlaybackSubtitleResolver.audioTrackForSource(row)
                }
                reload(playing.target.copy(audioStreamId = streamId, startPosition = currentItemSeconds().seconds, autoStart = resumesAfterReload(), itemChanged = false), "audio switch")
            }
            TrackKind.SUBTITLE -> scope.launch { switchSourceSubtitle(id?.let { SourceSubtitleChoice.Source(it) } ?: SourceSubtitleChoice.Off) }
            TrackKind.VIDEO -> {}
        }
    }

    override fun cycleSourceSubtitles() {
        if (closed || current == null) return
        pendingSubtitleCycles++
        if (subtitleCycleDrain != null) return
        subtitleCycleDrain = scope.launch {
            try {
                drainSubtitleCycles()
            } finally {
                pendingSubtitleCycles = 0
                subtitleCycleDrain = null
            }
        }
    }

    /**
     * Applies the pending presses as one switch whenever no transition runs; presses made during it wait for the next.
     * A reload that left no server catalog drops the presses that aimed at it.
     */
    private suspend fun drainSubtitleCycles() {
        while (!closed && pendingSubtitleCycles > 0) {
            var running = transition
            while (running != null && running.isActive) {
                running.join()
                running = transition
            }
            val playing = current ?: return
            val ids = mutableInfo.value.sourceSubtitles.map { it.id }
            if (closed || ids.isEmpty()) return
            val advances = pendingSubtitleCycles
            val shown = playing.subtitleSourceId?.takeIf { it in ids }?.let { SourceSubtitleChoice.Source(it) } ?: SourceSubtitleChoice.Off
            val target = PlaybackSubtitleResolver.advanceSourceChoice(ids, shown, advances)
            if (switchSourceSubtitle(target) == SourceSwitchOutcome.BUSY) continue
            pendingSubtitleCycles -= advances
        }
    }

    override fun forceTranscode() {
        val playing = current ?: return
        val failure = mutableInfo.value.failure as? PlaybackFailure.ServerLimit ?: return
        if (closed || !failure.transcodeOffered) return
        serverLimitFallbackUsed = true
        file?.latchedStatuses?.clear()
        updateInfo { it.copy(failure = null, resolving = true) }
        // A transcode that can't even start shows the server's limit again, without the offer it used.
        reload(playing.target.copy(forceTranscode = true, autoStart = true), "server limit transcode", restoreFailure = PlaybackFailure.ServerLimit(transcodeOffered = false))
    }

    override suspend fun searchSubtitles(language: String, title: String?): List<SubtitleSearchHit> {
        val playing = current ?: return emptyList()
        val plex = playing.backend as? PlexClient ?: error("subtitle search is Plex's")
        val results = plex.searchSubtitles(playing.item.id, language, title)
        playing.searchResults = results.associateBy { it.key }
        return results.map { r ->
            SubtitleSearchHit(r.key, r.title ?: r.language ?: r.key, listOfNotNull(r.providerTitle, r.codec?.uppercase()).joinToString(" · ").ifEmpty { null })
        }
    }

    override suspend fun downloadSubtitle(key: String): SubtitleDownloadOutcome {
        val playing = current ?: return SubtitleDownloadOutcome.NOT_APPLIED
        val plex = playing.backend as? PlexClient ?: error("subtitle download is Plex's")
        val result: PlexSubtitleSearchResult = playing.searchResults[key] ?: error("no search result $key")
        return PlexSubtitleDownloader(plex).downloadAndApply(
            ratingKey = playing.item.id,
            result = result,
            searchLanguage = result.languageCode ?: result.language ?: "en",
            existingSourceIds = playing.result.mediaInfo?.subtitleTracks.orEmpty().map { it.id }.toSet(),
            position = { currentItemSeconds().seconds },
            isCurrent = { current?.item?.globalKey == playing.item.globalKey && !closed },
            switchToSource = { id -> switchSubtitleSource(id) },
        )
    }

    private suspend fun switchSubtitleSource(id: Int): SourceSwitchOutcome {
        val playing = current ?: return SourceSwitchOutcome.UNAVAILABLE
        subtitlePreference = PreferredSubtitle.Native(NativeSubtitleTrack(id = sourceTrackId(id)))
        return reloadForSubtitle(playing, "downloaded subtitle")
    }

    /**
     * The server subtitle [choice] picked: the engine's own track for that stream when it has one (a sidecar added at
     * open, or the file's own track while the server burns nothing in), else a reload with it. A transcode reloads when
     * the change needs a new burn-in: something is burned in now, or the target is embedded. A sidecar the engine
     * hasn't listed yet is selected once it shows up. Picking the current choice again reloads nothing; another switch
     * or a reload running makes it [SourceSwitchOutcome.BUSY].
     */
    private suspend fun switchSourceSubtitle(choice: SourceSubtitleChoice): SourceSwitchOutcome {
        val playing = current ?: return SourceSwitchOutcome.UNAVAILABLE
        if (closed) return SourceSwitchOutcome.UNAVAILABLE
        if (transition != null) return SourceSwitchOutcome.BUSY
        val lease = Job()
        transition = lease
        val selected = try {
            selectSourceSubtitleLocally(playing, choice)
        } finally {
            lease.complete()
            if (transition === lease) transition = null
        }
        if (closed || current !== playing) return SourceSwitchOutcome.SUPERSEDED
        if (selected) return SourceSwitchOutcome.APPLIED
        val shown = playing.subtitleSourceId?.let { SourceSubtitleChoice.Source(it) } ?: SourceSubtitleChoice.Off
        if (choice == shown) return SourceSwitchOutcome.UNCHANGED
        val track = (choice as? SourceSubtitleChoice.Source)?.let { PlaybackSubtitleResolver.preferredTrackForSource(playing.result.mediaInfo, it.id) }
        subtitlePreference = track?.let { PreferredSubtitle.Native(it) } ?: PreferredSubtitle.Off
        return reloadForSubtitle(playing, "subtitle switch")
    }

    /** Applies [choice] to the engine without a reload; false when only a reload can show it. */
    private suspend fun selectSourceSubtitleLocally(playing: Playing, choice: SourceSubtitleChoice): Boolean {
        val manager = trackManager ?: return false
        val result = playing.result
        val rows = result.mediaInfo?.subtitleTracks.orEmpty()
        val shownId = playing.subtitleSourceId
        val targetId = (choice as? SourceSubtitleChoice.Source)?.id
        val target = targetId?.let { id -> rows.firstOrNull { it.id == id } }
        fun sidecarOf(id: Int) = result.subtitleSidecars.firstOrNull { it.sourceStreamId == id }
        fun isCurrent() = !closed && current === playing
        val renegotiate = PlaybackSubtitleResolver.burnRequiresRenegotiation(
            isTranscoding = result.isTranscoding,
            currentSourceStreamId = shownId,
            currentSelectionHasSidecar = shownId != null && sidecarOf(shownId) != null,
            targetIsOff = targetId == null,
            // A file the client fetches itself: Jellyfin marks the row external, Plex gives a real external file a key.
            targetIsExternalFile = target != null && (target.isExternalFile || playing.item.backend == BackendKind.PLEX && !target.key.isNullOrEmpty()),
        )
        if (renegotiate) return false

        if (targetId == null) {
            trackPlayer.selectSecondarySubtitleTrack(NativeSubtitleTrack.OFF)
            secondarySubtitlePreference = PreferredSubtitle.Off
            trackPlayer.selectSubtitleTrack(NativeSubtitleTrack.OFF)
            if (!isCurrent()) return false
            commitSourceSubtitle(playing, manager, NativeSubtitleTrack.OFF, null)
            return true
        }
        target ?: return false
        val sidecar = sidecarOf(targetId)
        val tracks = trackPlayer.tracks.value
        val native = PlaybackSubtitleResolver.nativeTrackForSource(
            source = target,
            nativeTracks = tracks.subtitle,
            allSourceTracks = rows,
            isResolvedSidecar = sidecar != null,
            isContainerSidecar = false,
            currentSourceStreamId = shownId,
            selectedNativeTrack = tracks.selectedSubtitle,
        )
        if (native == null) {
            if (!result.isTranscoding || sidecar == null) return false
            // Added at open but not listed yet: the manager selects it once the engine lists it.
            val deferred = PlaybackSubtitleResolver.subtitleTrackForSource(target, sidecar)
            manager.preferredSubtitle = PreferredSubtitle.Native(deferred)
            commitSourceSubtitle(playing, manager, deferred, targetId)
            if (!isCurrent()) return false
            manager.applyTrackSelectionWhenReady()
            return true
        }
        trackPlayer.selectSubtitleTrack(native)
        if (!isCurrent()) return false
        commitSourceSubtitle(playing, manager, native, targetId)
        return true
    }

    /** Keeps [track] (server stream [sourceId]; null: off) as the viewer's pick, carried on and written to the server. */
    private suspend fun commitSourceSubtitle(playing: Playing, manager: TrackManager, track: NativeSubtitleTrack, sourceId: Int?) {
        val reference = sourceId?.let { PlaybackSubtitleResolver.preferredTrackForSource(playing.result.mediaInfo, it) }
        subtitlePreference = reference?.let { PreferredSubtitle.Native(it) } ?: PreferredSubtitle.Off
        playing.subtitleSourceId = sourceId
        playing.subtitleOffIsDeliberate = true
        updateInfo { it.copy(sourceSubtitles = sourceSubtitles(playing)) }
        manager.onSubtitleTrackSelectedByUser(track, sourceId)
        tracker?.onTracksChanged()
    }

    private suspend fun reloadForSubtitle(playing: Playing, reason: String): SourceSwitchOutcome {
        val refreshed = playing.target.copy(startPosition = currentItemSeconds().seconds, autoStart = resumesAfterReload(), itemChanged = false)
        return when (reload(refreshed, reason).await()) {
            ReloadOutcome.OPENED -> SourceSwitchOutcome.APPLIED
            ReloadOutcome.REJECTED -> SourceSwitchOutcome.BUSY
            ReloadOutcome.SUPERSEDED -> SourceSwitchOutcome.SUPERSEDED
            ReloadOutcome.FAILED -> SourceSwitchOutcome.FAILED
        }
    }

    override suspend fun loadFileInfo(): MediaFileInfo? {
        val playing = current ?: return null
        val server = playing.backend?.getFileInfo(playing.item)
        val quality = playing.result.downloadedQuality
        if (quality.isOriginal) return server
        return transcodedCopyFileInfo(server, playing.result.selectedMediaIndex, quality, playing.item.durationMs)
    }

    override fun onSyncOffsetChanged(audio: Boolean, seconds: Double) {
        val item = current?.item ?: return
        val ms = (seconds * 1000).roundToLong().toInt().coerceIn(ScopedPlayerPrefs.MIN_SYNC_OFFSET_MS, ScopedPlayerPrefs.MAX_SYNC_OFFSET_MS)
        syncOffsets.recordApplied(if (audio) SyncOffsetKind.AUDIO else SyncOffsetKind.SUBTITLE, ms)
        val pref = if (audio) ScopedPlayerPrefs.audioSyncOffset else ScopedPlayerPrefs.subtitleSyncOffset
        scope.launch { ScopedPlayerPrefs.write(env.settings, pref, item, ms, env.clock.now().toEpochMilliseconds()) }
        updateInfo { if (audio) it.copy(audioOffsetSeconds = seconds) else it.copy(subtitleOffsetSeconds = seconds) }
    }

    override fun onSpeedChanged(speed: Double) {
        val item = current?.item ?: return
        scope.launch { ScopedPlayerPrefs.write(env.settings, ScopedPlayerPrefs.playbackSpeed, item, speed, env.clock.now().toEpochMilliseconds()) }
    }

    /** The session asks nothing ([SessionInfo.choice] stays null): an answer only clears what shows. */
    override fun answerChoice(index: Int?) = updateInfo { it.copy(choice = null) }

    /** As the engine's error for [status] would ([onEngineError]), the 503 as its watchdog's: the failure decides. */
    override fun simulateHttpError(status: Int) {
        val file = file ?: return
        decide(file, SimulatedHttpError.cause(status), SimulatedHttpError.of(status))
    }

    override fun close() {
        if (closed) return
        val file = file
        val playhead = currentItemSeconds()
        // Left from its credits (or past 90% without them) the item is finished, as an advance from there finishes it:
        // its end is reported, since the servers mark played only past their own threshold and keep a resume point.
        val duration = file?.let { itemDuration(mutableEngineState.value, it) } ?: 0.0
        val finished = file?.rendered == true && !mutableInfo.value.live &&
            pastCredits(playhead, duration, segmentsCreditsStart()?.let { it / 1000.0 })
        val position = if (finished) duration else playhead
        val tracker = tracker
        file?.let { trackStop(trackedNow(it)) }
        closed = true
        mutablePlayingKey.value = null
        mutableOpened.value = null
        output.setListener(null)
        attempt?.cancel()
        transition?.cancel()
        watchdog.disarm()
        file?.outcome?.abort("the player closed")
        trackManager?.dispose()
        file?.rollback?.let(::release)
        mutableInfo.value.scrubPreview?.dispose()
        env.sleepTimer?.unbindPlayback(this)
        states.close()
        val retirement = env.reportScope.async {
            if (tracker == null) return@async
            // An open that showed no frame still ends its server session (a transcode it started): the tracker
            // reports it at the last reportable position, without a scrobble.
            tracker.sendStoppedProgressOnce(position.seconds)
            tracker.dispose()
        }
        this.retirement = retirement
        env.videoSessions.unregister(this, retirement)
        scope.cancel()
        output.release()
    }

    /**
     * The app sat in the background on a TV: the video, paused, gives the engine's decoders back for other apps (the
     * engine unloads it) and its server session ends (the stopped report, retried while the TV's network wakes), keeping
     * where it was and its tracks for [restoreAfterBackground]. False while a reload or the first frame is on its way:
     * ask again later.
     */
    override fun suspendInBackground(): Boolean {
        val file = file
        if (closed || suspended != null || file == null || fatal) return true
        if (transition != null || !file.rendered) return false
        val position = currentItemSeconds()
        val duration = itemDuration(mutableEngineState.value, file)
        val tracks = trackPlayer.tracks.value
        suspended = Suspended(file.playing.item.globalKey, position, tracks.selectedAudio, tracks.selectedSubtitle, tracks.selectedSecondarySubtitle)
        Log.i(TAG) { "suspending in the background at $position s" }
        trackStop(trackedNow(file))
        val tracker = tracker
        tracker?.stopTracking()
        output.stop()
        if (tracker != null) {
            env.reportScope.launch {
                tracker.sendStoppedProgressOnce(position.seconds)
                tracker.redeliverStoppedReport(position.seconds, duration.seconds) { suspended != null && !closed && this@PlaybackSession.tracker === tracker }
            }
        }
        return true
    }

    /**
     * Back from [suspendInBackground]: the same item opens again where it was, paused, with its tracks, as a fresh
     * playback decision on the server; one that fails shows the failure.
     */
    override suspend fun restoreAfterBackground() {
        val held = suspended ?: return
        suspended = null
        val playing = current ?: return
        if (closed || playing.item.globalKey != held.key) return
        held.audio?.let { audioPreference = it }
        subtitlePreference = held.subtitle?.takeIf { it != NativeSubtitleTrack.OFF }?.let { PreferredSubtitle.Native(it) } ?: PreferredSubtitle.Off
        held.secondarySubtitle?.let { secondarySubtitlePreference = PreferredSubtitle.Native(it) }
        val target = playing.target.copy(startPosition = held.positionSeconds.seconds, autoStart = false, itemChanged = false)
        if (reload(target, "background restore", showError = false).await() == ReloadOutcome.FAILED) {
            fail(PlaybackFailure.Server(PlaybackFailureReason.UNKNOWN, T.messages.playbackFailed))
        }
    }

    // Reloads

    /**
     * Reopens the video as [target] says, in place: refused while another reload runs. The old file is paused, its
     * stopped report delivered (at its end when [target] is another item and the old one was left past its credits,
     * [pastCredits]) and trackers told it stopped before the new one resolves. A pause or play asked for meanwhile is
     * how the new file opens (unless a room starts it). A resolve that fails, or a load the engine refuses, rolls back
     * to the old file ([rollBack]).
     */
    private fun reload(target: Target, reason: String, showError: Boolean = true, restoreFailure: PlaybackFailure? = null): Deferred<ReloadOutcome> {
        if (closed || transition != null) return CompletableDeferred(ReloadOutcome.REJECTED)
        val previous = current ?: return CompletableDeferred(ReloadOutcome.REJECTED)
        val fileBefore = file
        pausedDuringReload = null
        val back = Rollback(
            playing = previous, file = fileBefore, info = mutableInfo.value, key = mutablePlayingKey.value, gate = firstFrame.snapshot(),
            request = request, opened = mutableOpened.value, adjacency = adjacency, tracker = tracker, trackManager = trackManager,
            fatal = fatal, wasPlaying = isPlaying(), showError = showError, restoreFailure = restoreFailure,
        )
        val result = scope.async {
            Log.i(TAG) { "reloading in place: $reason" }
            output.setPaused(true)
            if (target.itemChanged) {
                mutablePlayingKey.value = target.item.globalKey
                updateInfo { it.copy(title = titleOf(target.item), subtitle = subtitleOf(target.item), nextEpisode = null, resolving = true) }
            }
            // Another item from the credits finishes this one: its end is reported, since the servers mark played only
            // past their own threshold (MediaBrowser's MaxResumePct, Plex's percent) and would keep a resume point.
            val leftAt = currentItemSeconds()
            val leftDuration = fileBefore?.let { itemDuration(mutableEngineState.value, it) } ?: 0.0
            val finished = target.itemChanged && pastCredits(leftAt, leftDuration, segmentsCreditsStart()?.let { it / 1000.0 })
            val stoppedAt = if (finished) leftDuration else leftAt
            fileBefore?.let { trackStop(trackedNow(it)) }
            tracker?.sendStoppedProgressOnce(stoppedAt.seconds)
            trackManager?.invalidatePendingSelection()?.await()
            val context = try {
                resolve(target, request?.offline == true, quality?.downloadOutranksQuality ?: false)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "the $reason failed before its file opened" }
                val failure = classify(e)
                reloadFailure = failure.reason
                rollBack(back, failure.message)
                return@async ReloadOutcome.FAILED
            }
            val asked = pausedDuringReload?.takeUnless { roomOwnsStart() }
            open(if (asked == null) target else target.copy(autoStart = !asked), context, back)
            ReloadOutcome.OPENED
        }
        transition = result
        result.invokeOnCompletion { if (transition === result) transition = null }
        return result
    }

    /**
     * Back to the file [back] replaced, after its reload failed: as it was when the reload began, its reports resumed
     * (trackers told it started again), playing again if it was, with a notice of [message] unless the reload was a
     * retry: then the failure it retried ([Rollback.restoreFailure]) shows again. What the new file opened goes.
     */
    private fun rollBack(back: Rollback, message: String) {
        val failed = file
        if (failed !== back.file) failed?.outcome?.abort("rolled back")
        if (tracker !== back.tracker) tracker?.dispose()
        if (trackManager !== back.trackManager) trackManager?.dispose()
        current = back.playing
        file = back.file
        request = back.request
        tracker = back.tracker
        trackManager = back.trackManager
        adjacency = back.adjacency
        fatal = back.fatal
        firstFrame.restore(back.gate)
        mutablePlayingKey.value = back.key
        mutableOpened.value = back.opened
        mutableInfo.value = back.info.copy(failure = back.restoreFailure ?: back.info.failure, resolving = false)
        tracker?.resumeAfterStoppedReport()
        val fileBefore = back.file
        if (fileBefore != null && fileBefore.rendered && !fatal) {
            back.playing.backend?.let { trackStart(back.playing.item, it, trackedNow(fileBefore), playing = back.wasPlaying) }
            if (pausedDuringReload?.not() ?: back.wasPlaying) output.setPaused(false)
        }
        if (back.showError && back.restoreFailure == null) showNotice(T.messages.errorLoading(message))
    }

    /** The file that [back] would go back to is gone for good: what it kept for the way back goes too. */
    private fun release(back: Rollback) {
        back.tracker?.dispose()
        back.trackManager?.dispose()
        back.info.scrubPreview?.takeIf { it !== mutableInfo.value.scrubPreview }?.dispose()
    }

    /**
     * The recovery's reload of a dying stream at [atSeconds], with nothing shown ([SpuriousEofRecovery]): it plays on
     * only if the viewer was playing before the stream died and no room owns the start.
     */
    private suspend fun recover(atSeconds: Double): ReloadOutcome {
        val target = current?.target ?: return ReloadOutcome.REJECTED
        val play = file?.viewerPlaying ?: target.autoStart
        return reload(target.copy(startPosition = atSeconds.seconds, autoStart = play && request?.roomStart != true && !roomOwnsStart()), "stream recovery", showError = false).await()
    }

    private fun classify(error: Exception): PlaybackFailure.Server {
        val classified = error as? PlaybackException ?: classifyPlaybackFailure(error)
        return PlaybackFailure.Server(classified.reason, classified.message ?: T.messages.playbackFailed)
    }

    // What the session learns about the item

    /**
     * The item's chapters and markers: from its server ([forceRefresh] past its cache), the cached ones when the server
     * doesn't answer, and only the cached ones without a server (offline).
     */
    private suspend fun loadExtras(playing: Playing, forceRefresh: Boolean = false) {
        val key = playing.item.globalKey
        if (extrasLoading == key) return
        extrasLoading = key
        try {
            val backend = playing.backend
            val introPattern = env.settings.value(AppSettings.introPattern)
            val creditsPattern = env.settings.value(AppSettings.creditsPattern)
            val force = env.settings.value(AppSettings.forceSkipMarkerFallback)
            val extras = if (backend == null) {
                loading("the cached chapters and markers") { env.resolver.cachedPlaybackExtras(playing.item, introPattern, creditsPattern, force) }
            } else {
                try {
                    backend.fetchPlaybackExtras(playing.item.id, introPattern, creditsPattern, force, forceRefresh)
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    Log.w(TAG, e) { "loading the chapters and markers failed; trying the cached ones" }
                    loading("the cached chapters and markers") { backend.fetchPlaybackExtrasFromCacheOnly(playing.item.id, introPattern, creditsPattern, force) }
                }
            } ?: return
            if (current?.item?.globalKey != key) return
            val durationSeconds = (playing.item.durationMs ?: 0L) / 1000.0
            // A download's saved thumbnail first, then the server's.
            val chapters = extras.chapters.takeIf { c -> c.isNotEmpty() }?.map { c ->
                val image = env.resolver.downloadedArtwork(playing.item, c.thumb) ?: backend?.let { b -> imageOf(b, c.thumb) }
                SessionChapter(c.title, c.startTime.inWholeMilliseconds / 1000.0, c.endTime?.let { e -> e.inWholeMilliseconds / 1000.0 }, image)
            }
            if (current?.item?.globalKey != key) return
            updateInfo {
                it.copy(
                    chapters = chapters,
                    segments = segmentsOf(extras.markers, durationSeconds),
                )
            }
        } finally {
            if (extrasLoading == key) extrasLoading = null
        }
    }

    /**
     * The next and previous items: from the queue, or in the offline library from the show's downloads in watch order
     * (the specials where the settings put them), with or without a server. They and the queue's entries are read from
     * one state of the queue, with nothing between that could change it.
     */
    private suspend fun loadAdjacent(playing: Playing) {
        val item = playing.item
        val offline = request?.offline == true
        val backend = playing.backend.takeUnless { offline }
        val hide = env.settings.value(AppSettings.hideSpoilers)
        val found = when {
            offline -> item.seriesGlobalKey?.let { show ->
                val downloaded = loading("the show's downloads") { env.downloadedEpisodes(show) } ?: return@let AdjacentEpisodes.FAILED
                EpisodeQueue.offlineAdjacent(item, downloaded, env.settings.value(AppSettings.specialsOrdering))
            } ?: AdjacentEpisodes.UNAVAILABLE
            backend != null -> {
                if (item.backend == BackendKind.PLEX && item.kind == MediaKind.EPISODE) env.queue.ensurePlexShowQueue(item)
                env.queue.loadAdjacent(item, playing.result.mediaInfo?.partId?.toString(), showPlay = request?.showPlay == true)
            }
            else -> AdjacentEpisodes.UNAVAILABLE
        }
        if (current?.item?.globalKey != item.globalKey) return
        adjacency = found
        val next = found.next
        if (backend != null) next?.let { scope.launch { env.queue.primeNext(it) } }
        val entries = env.queue.entries(hide) { e -> backend?.let { b -> imageOf(b, e.thumbPath) } }
        queueItems = entries.associate { (entry, item) -> entry.key to item }
        updateInfo {
            it.copy(
                nextEpisode = next?.let { n -> nextEpisodeOf(n, backend) },
                hasPreviousEpisode = found.previous != null,
                queue = entries.map { (entry, _) -> entry },
                shuffled = env.queue.shuffled,
            )
        }
    }

    private suspend fun nextEpisodeOf(next: MediaItem, backend: MediaBackend?): NextEpisode {
        val code = episodeCode(next)
        val title = next.title?.trim()?.takeIf { it.isNotEmpty() }
        return NextEpisode(
            title = title ?: code.orEmpty(),
            subtitle = code.takeIf { title != null },
            autoplay = env.settings.value(AppSettings.autoPlayNextEpisode),
            countdownSeconds = env.settings.value(AppSettings.playNextCountdown),
            // Offline, the still the download saved.
            imageUrl = if (backend != null) imageOf(backend, next.thumbPath) else env.resolver.downloadedArtwork(next, next.thumbPath),
        )
    }

    /** The settings the player follows as they change: skipping, a click on the video, rewind on resume, up next, chapter marks. */
    private suspend fun followSettings() {
        val followed = listOf(
            AppSettings.skipIntroMode, AppSettings.skipCreditsMode, AppSettings.autoSkipDelay, AppSettings.clickVideoTogglesPlayback,
            AppSettings.rewindOnResume, AppSettings.rememberTrackSelections, AppSettings.autoPlayNextEpisode,
            AppSettings.playNextCountdown, AppSettings.showChapterMarkersOnTimeline,
        )
        env.settings.observe(followed).collect { values ->
            val skipping = SkipModes(
                intros = values[0] as SkipMode,
                credits = values[1] as SkipMode,
                autoSkipDelaySeconds = values[2] as Int,
            )
            val click = VideoClickAction.of(values[3] as Boolean)
            val rewind = values[4] as Int
            rememberTrackSelections = values[5] as Boolean
            val autoplay = values[6] as Boolean
            val countdown = values[7] as Int
            val chapterMarks = values[8] as Boolean
            updateInfo {
                it.copy(
                    skipping = skipping,
                    videoClick = click,
                    rewindOnResumeSeconds = rewind,
                    chapterMarks = chapterMarks,
                    nextEpisode = it.nextEpisode?.copy(autoplay = autoplay, countdownSeconds = countdown),
                )
            }
        }
    }

    /** A server back online while the video buffers reconnects the stream; a parked stream retries. */
    private suspend fun followServers() {
        var known: Map<ServerId, Boolean> = emptyMap()
        env.serverStatus.collect { status ->
            val serverId = request?.serverId
            val was = serverId?.let { known[it] }
            known = status
            if (serverId == null || was != false || status[serverId] != true) return@collect
            val state = mutableEngineState.value
            when {
                eofRecovery.parked -> {
                    updateInfo { it.copy(failure = null) }
                    eofRecovery.retry(currentItemSeconds())
                }
                state.buffering && file?.rendered == true -> {
                    latch.rearmIfClear(promptVisible = false, countdownActive = false)
                    output.seek(state.positionSeconds - (file?.partStart ?: 0.0), exact = true)
                }
            }
        }
    }

    private suspend fun applySpeed(item: MediaItem) {
        val speed = ScopedPlayerPrefs.resolve(env.settings, ScopedPlayerPrefs.playbackSpeed, item)
        if (speed != mutableEngineState.value.speed) output.setSpeed(speed)
    }

    // Helpers

    private fun restart(block: suspend CoroutineScope.() -> Unit) {
        attempt?.cancel()
        attempt = scope.launch(block = block)
    }

    /** Leaves the file playing before another starts: its stopped report, trackers. */
    private suspend fun leaveFile(stoppedReport: Boolean) {
        val file = file ?: return
        trackStop(trackedNow(file))
        if (stoppedReport) tracker?.sendStoppedProgressOnce(currentItemSeconds().seconds)
        tracker?.dispose()
        tracker = null
        trackManager?.dispose()
        trackManager = null
        file.cancelSidecarFetches()
        file.rollback?.let(::release)
        file.rollback = null
        this.file = null
        current = null
    }

    private suspend fun plexSelect(plex: PlexClient, partId: Int, type: TrackType, streamId: Int): Boolean = when (type) {
        TrackType.AUDIO -> plex.selectStreams(partId, audioStreamId = streamId)
        TrackType.SUBTITLE -> plex.selectStreams(partId, subtitleStreamId = streamId)
    }

    private fun qualityChoice(playing: Playing): QualityChoice? {
        if (playing.context.usesLocalMedia || playing.backend?.capabilities?.videoTranscoding != true) return null
        val version = playing.result.selectedVersion
        return QualityChoice(playing.source.qualityPreset, version?.bitrate, playing.item.durationMs, version?.resolutionHeight)
    }

    private fun sourceAudio(playing: Playing): List<SourceTrack> {
        if (!playing.result.isTranscoding) return emptyList()
        val active = playing.result.activeAudioStreamId
        return playing.result.mediaInfo?.audioTracks.orEmpty().map { SourceTrack(it.id, it.label.primary, it.label.secondary, selected = it.id == active || active == null && it.selected) }
    }

    private fun sourceSubtitles(playing: Playing): List<SourceTrack> {
        if (!playing.result.isTranscoding) return emptyList()
        val selected = playing.subtitleSourceId
        return playing.result.mediaInfo?.subtitleTracks.orEmpty().map { SourceTrack(it.id, it.label.primary, it.label.secondary, selected = it.id == selected) }
    }

    private fun isPlaying(): Boolean = mutableEngineState.value.let { !it.paused && !it.eof }

    /** A reload resumes a file that was playing, unless a watch-together room starts it ([roomOwnsStart]). */
    private fun resumesAfterReload(): Boolean = isPlaying() && !roomOwnsStart()

    private fun currentItemSeconds(): Double {
        val file = file ?: return 0.0
        return mutableEngineState.value.positionSeconds.takeIf { it.isFinite() && it >= 0 } ?: itemSeconds(file.startAt, file)
    }

    /** [state] in the item's time: a stacked item's part moves by its start, and the duration is the whole item's. */
    private fun itemTime(state: EngineState, file: EngineFile?): EngineState {
        if (file == null || file.partStart == 0.0 && file.playing.result.mediaInfo?.partTimeline == null) return state
        val timeline = file.playing.result.mediaInfo?.partTimeline ?: return state
        return state.copy(
            positionSeconds = state.positionSeconds + file.partStart,
            durationSeconds = timeline.duration.inWholeMilliseconds / 1000.0,
            cacheEndSeconds = state.cacheEndSeconds?.plus(file.partStart),
            cacheStartSeconds = state.cacheStartSeconds?.plus(file.partStart),
        )
    }

    private fun itemSeconds(engineSeconds: Double, file: EngineFile): Double = engineSeconds + file.partStart

    private fun itemDuration(state: EngineState, file: EngineFile): Double {
        file.playing.result.mediaInfo?.partTimeline?.let { return it.duration.inWholeMilliseconds / 1000.0 }
        return state.durationSeconds.takeIf { it > 0 } ?: ((file.playing.item.durationMs ?: 0L) / 1000.0)
    }

    /** Where trackers are told [state] is: [state] is the engine's, in the open part's time. */
    private fun trackedAt(state: EngineState, file: EngineFile): TrackedPosition =
        TrackedPosition(millis(itemSeconds(state.positionSeconds, file)), millis(itemDuration(state, file)), segmentsCreditsStart())

    /** Where trackers are told the video is now: the published state, already in the item's time. */
    private fun trackedNow(file: EngineFile): TrackedPosition {
        val state = mutableEngineState.value
        return TrackedPosition(millis(state.positionSeconds), millis(itemDuration(state, file)), segmentsCreditsStart())
    }

    /** Tells trackers [item] started at [at]; nothing while they follow a video already, or without trackers. */
    private fun trackStart(item: MediaItem, backend: MediaBackend, at: TrackedPosition, playing: Boolean) {
        val trackers = env.trackers
        if (trackedVideo || trackers == null) return
        trackedVideo = true
        trackedPlaying = playing
        trackedPositionMillis = at.positionMillis
        trackers.onVideoStarted(item, backend, at, playing = playing, live = false)
    }

    /** Tells trackers the video stopped at [at]; nothing unless they follow one. */
    private fun trackStop(at: TrackedPosition) {
        if (!trackedVideo) return
        trackedVideo = false
        env.trackers?.onVideoStopped(at)
    }

    private fun segmentsCreditsStart(): Long? = mutableInfo.value.segments?.lastOrNull { it.toEnd }?.let { millis(it.startSeconds) }

    /** Shows [text] as the player's toast ([SessionInfo.notice]): a fallback taken, a reload that failed. */
    private fun showNotice(text: String) {
        updateInfo { it.copy(notice = SessionNotice(text, (it.notice?.serial ?: 0) + 1)) }
    }

    private inline fun updateInfo(change: (SessionInfo) -> SessionInfo) {
        mutableInfo.value = change(mutableInfo.value)
    }

    private suspend fun <T> loading(what: String, load: suspend () -> T): T? = try {
        load()
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "loading $what failed" }
        null
    }

    /**
     * The engine as the track selection sees it ([TrackPlayer]): its track lists, with each sidecar's URL, and the
     * commands that pick from them.
     */
    private inner class EngineTrackPlayer : TrackPlayer {
        private val mutableTracks = MutableStateFlow(NativeTracks())
        override val tracks: StateFlow<NativeTracks> = mutableTracks.asStateFlow()
        override val rate: Double get() = mutableEngineState.value.speed
        override val disposed: Boolean get() = closed
        override val supportsSecondarySubtitles: Boolean get() = true

        /** The sidecar URL subtitle track [id] was added from, by the local file the engine opened for it. */
        fun uriOf(id: Long): String? {
            val file = file ?: return null
            val local = mutableEngineState.value.tracks.firstOrNull { it.kind == TrackKind.SUBTITLE && it.id == id }?.externalFilename
            return local?.let { file.sidecarUrls[it] }
        }

        fun publish(state: EngineState) {
            val audio = state.tracks.filter { it.kind == TrackKind.AUDIO }.map { it.toNativeAudioTrack() }
            val subtitles = state.tracks.filter { it.kind == TrackKind.SUBTITLE }.map { it.toNativeSubtitleTrack(if (it.external) uriOf(it.id) else null) }
            val next = NativeTracks(
                audio = audio,
                subtitle = subtitles,
                selectedAudio = state.tracks.firstOrNull { it.kind == TrackKind.AUDIO && it.selected }?.toNativeAudioTrack(),
                selectedSubtitle = subtitles.firstOrNull { s -> state.tracks.any { it.kind == TrackKind.SUBTITLE && it.selected && it.id.toString() == s.id } } ?: NativeSubtitleTrack.OFF,
                selectedSecondarySubtitle = subtitles.firstOrNull { s -> state.tracks.any { it.kind == TrackKind.SUBTITLE && it.secondary && it.id.toString() == s.id } },
            )
            if (next != mutableTracks.value) mutableTracks.value = next
        }

        override suspend fun selectAudioTrack(track: NativeAudioTrack) {
            engineTrackId(track.id)?.let { output.selectTrack(TrackKind.AUDIO, it) }
        }

        override suspend fun selectSubtitleTrack(track: NativeSubtitleTrack) {
            output.selectTrack(TrackKind.SUBTITLE, if (track == NativeSubtitleTrack.OFF || track.id == NativeSubtitleTrack.OFF.id) null else engineTrackId(track.id) ?: return)
        }

        override suspend fun selectSecondarySubtitleTrack(track: NativeSubtitleTrack) {
            output.selectSecondSubtitle(if (track.id == NativeSubtitleTrack.OFF.id) null else engineTrackId(track.id) ?: return)
        }

        override suspend fun setRate(rate: Double) = output.setSpeed(rate)
    }

    /**
     * What plays and how it was asked for: [target] the request (another version, quality, track, item or position
     * reloads it), [context] what the server answered, [source] the effective selections.
     */
    private class Playing(val target: Target, val context: PlaybackContext, val source: PlaybackSource, val backend: MediaBackend?) {
        val item: MediaItem get() = context.item
        val result: PlaybackInitializationResult get() = context.result

        /** The server subtitle stream shown (a sidecar or burned in); null for none. */
        var subtitleSourceId: Int? = null
        var subtitleOffIsDeliberate = true
        var searchResults: Map<String, PlexSubtitleSearchResult> = emptyMap()
    }

    /** What [suspendInBackground] kept: the item ([key]), where it was and its tracks. */
    private class Suspended(
        val key: String,
        val positionSeconds: Double,
        val audio: NativeAudioTrack?,
        val subtitle: NativeSubtitleTrack?,
        val secondarySubtitle: NativeSubtitleTrack?,
    )

    /**
     * One load in the engine and what the session saw of it; [partStart] is where its part starts in the item. Its
     * sidecars' URLs are by the local file the engine got for each ([addSidecars]), which it lists as the track's.
     */
    private class EngineFile(val playing: Playing, val partStart: Double, val startAt: Double) {
        val sidecarUrls = mutableMapOf<String, String>()
        val sidecarFetches = mutableListOf<Job>()

        fun cancelSidecarFetches() = sidecarFetches.forEach(Job::cancel)

        var loadId = 0L
        lateinit var outcome: OpenOutcome
        var rendered = false
        var error: EngineError? = null
        var wasPlaying = false

        /** Whether the viewer had it playing before its end: what a recovery of a dying stream keeps. */
        var viewerPlaying = playing.target.autoStart
        var restarts = 0
        var lastRead: Double? = null
        val latchedStatuses = mutableSetOf<Int>()
        var endJudged = false
        var endIntercepted = false

        /** What a reload replaced, kept until this file's first frame: the way back when the engine refuses its load. */
        var rollback: Rollback? = null
    }

    /** What a reload replaces, as it was when the reload began: what [rollBack] restores. */
    private class Rollback(
        val playing: Playing,
        val file: EngineFile?,
        val info: SessionInfo,
        val key: String?,
        val gate: FirstFrameGate.Snapshot,
        val request: PlayRequest.Item?,
        val opened: OpenedFile?,
        val adjacency: AdjacentEpisodes,
        val tracker: PlaybackProgressTracker?,
        val trackManager: TrackManager?,
        val fatal: Boolean,
        val wasPlaying: Boolean,
        val showError: Boolean,
        val restoreFailure: PlaybackFailure?,
    )

    /** What to open: the item, its version, quality and server tracks, where, and whether it plays at once. */
    internal data class Target(
        val item: MediaItem,
        val backend: MediaBackend?,
        val mediaIndex: Int,
        val mediaSourceId: String?,
        val versionSignature: String?,
        val quality: TranscodeQualityPreset,
        val audioStreamId: Int?,
        val startPosition: Duration?,
        val forceTranscode: Boolean,
        val autoStart: Boolean,
        val strict: Boolean = false,
        val itemChanged: Boolean = false,
    ) {
        /** The same file of the same item: version, quality, server audio track and transcode alike. */
        fun sameSourceAs(other: Target): Boolean =
            item.globalKey == other.item.globalKey && mediaIndex == other.mediaIndex && mediaSourceId == other.mediaSourceId &&
                quality == other.quality && audioStreamId == other.audioStreamId && forceTranscode == other.forceTranscode
    }

    /** The ids a playback's server sessions go by, kept across its reloads (Plex ends a transcode by them). */
    internal class SessionIds(val playback: String = randomId(), val transcode: String = randomId())

    /** A play's start as resolved before it opens: its server's item, quality and source, or why it can't play. */
    internal sealed interface Prepared {
        /** No client of the item's server: the profile can't reach it. */
        data object Unavailable : Prepared

        /** The item or its source couldn't be read; [startup] when it failed resolving the source. */
        class Failed(val error: Exception, val startup: StartupQuality?) : Prepared

        class Ready(val target: Target, val startup: StartupQuality, val context: PlaybackContext) : Prepared
    }

    /**
     * A server item's play from before its engine exists: its source is resolving while the music session stops and
     * the engine is built, then [start] opens it ([prepare]).
     */
    internal class Launch(val request: PlayRequest.Item, val ids: SessionIds, val prepared: Deferred<Prepared>)

    /**
     * What a play's start reads of state that changes on the main thread, read there before the rest of the start runs
     * on [PlaybackEnvironment.requests]: the server manager's clients and their status (health checks change them), the
     * server's capabilities, the play queue's shuffle and the network.
     */
    private class Found(
        val backend: MediaBackend?,
        val client: MediaBackend?,
        val transcoding: Boolean,
        val shuffleActive: Boolean,
        val metered: Boolean,
    ) {
        companion object {
            fun of(request: PlayRequest.Item, env: PlaybackEnvironment): Found {
                val backend = if (request.offline) null else env.servers.client(request.serverId)
                val serverId = if (request.item != null) request.item.serverId?.let(::ServerId) else request.serverId
                return Found(
                    backend = backend,
                    client = env.resolver.playbackClient(serverId, request.offline),
                    transcoding = backend?.capabilities?.videoTranscoding ?: false,
                    shuffleActive = env.playbackState.isShuffleActive,
                    metered = env.meteredNetwork(),
                )
            }
        }
    }

    internal companion object {
        private const val TAG = "session"

        /** Trackers hear the position once it moved this much. */
        const val TRACKED_POSITION_STEP_MILLIS = 1000L

        fun millis(seconds: Double): Long = if (seconds.isFinite() && seconds > 0) (seconds * 1000).roundToLong() else 0

        private fun randomId(): String = buildString { repeat(24) { append("0123456789abcdefghijklmnopqrstuvwxyz"[Random.nextInt(36)]) } }

        /**
         * Starts resolving [request] before anything else waits (the music session's stop, the engine's construction):
         * its server, its item, the startup quality (the request's, else the saved default; the cellular one on a
         * metered network) and the source. The servers are looked up here, on the caller's thread; the rest runs in
         * [scope] on [PlaybackEnvironment.requests]. [PlaybackSession.start] opens it.
         */
        fun prepare(request: PlayRequest.Item, env: PlaybackEnvironment, scope: CoroutineScope): Launch {
            val ids = SessionIds()
            val found = Found.of(request, env)
            return Launch(request, ids, scope.async(env.requests) { prepared(request, env, ids, found) })
        }

        private suspend fun prepared(request: PlayRequest.Item, env: PlaybackEnvironment, ids: SessionIds, found: Found): Prepared {
            val backend = found.backend
            if (!request.offline && backend == null) return Prepared.Unavailable
            val item = try {
                request.item ?: backend?.fetchItem(request.itemId) ?: throw PlaybackException(T.messages.playbackFailed, PlaybackFailureReason.NO_PLAYABLE_SOURCE)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                return Prepared.Failed(e, startup = null)
            }
            val startup = StartupQuality.atStartup(
                requested = request.qualityPreset,
                offlineLibraryMode = request.offline,
                live = false,
                serverSupportsTranscoding = found.transcoding,
                onCellularOnly = found.metered,
                cellularDefault = env.settings.value(AppSettings.cellularQualityPreset),
                generalDefault = env.settings.value(AppSettings.defaultQualityPreset),
            )
            val shuffleFromStart = found.shuffleActive && env.settings.value(AppSettings.shuffleStartsFromBeginning)
            val target = Target(
                item = item,
                backend = backend,
                mediaIndex = request.mediaIndex,
                mediaSourceId = request.mediaSourceId,
                versionSignature = request.preferredVersionSignature,
                quality = startup.preset,
                audioStreamId = request.audioStreamId,
                startPosition = resolveOpenResumePosition(request.startPosition, shuffleFromStart, viewOffsetMs = item.viewOffsetMs),
                forceTranscode = false,
                // A watch-together room starts the file itself, once everyone is ready.
                autoStart = !request.roomStart,
                strict = request.strictMediaSelection,
            )
            val context = try {
                resolveSource(
                    env, ids, target, found.client, request.offline, startup.downloadOutranksQuality,
                    carriedAudio(request)?.toPreference(), request.subtitleTrack?.let(::preferredOf)?.toPreference(),
                )
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                return Prepared.Failed(e, startup)
            }
            return Prepared.Ready(target, startup, context)
        }

        private suspend fun resolveSource(
            env: PlaybackEnvironment,
            ids: SessionIds,
            target: Target,
            client: MediaBackend?,
            offline: Boolean,
            downloadOutranksQuality: Boolean,
            audio: AudioTrackPreference?,
            subtitle: SubtitlePreference?,
        ): PlaybackContext {
            val options = PlaybackInitializationOptions(
                metadata = target.item,
                selectedMediaIndex = target.mediaIndex,
                selectedMediaSourceId = target.mediaSourceId,
                preferredVersionSignature = target.versionSignature,
                qualityPreset = target.quality,
                selectedAudioStreamId = target.audioStreamId.takeIf { !target.quality.isOriginal },
                preferredAudioTrack = audio,
                preferredSubtitleTrack = subtitle,
                sessionIdentifier = ids.playback,
                transcodeSessionId = ids.transcode,
                startPosition = target.startPosition,
                forceTranscode = target.forceTranscode,
            )
            return env.resolver.resolve(options, client, offline, downloadOutranksQuality)
        }

        private fun carriedAudio(request: PlayRequest.Item): NativeAudioTrack? =
            request.audioTrack?.let { NativeAudioTrack(id = CARRIED_AUDIO_TRACK_ID, title = it.title, language = it.language, codec = it.codec, channels = it.channels) }

        private fun preferredOf(preference: SubtitlePreference): PreferredSubtitle = when (preference) {
            SubtitlePreference.Off -> PreferredSubtitle.Off
            is SubtitlePreference.Track -> PreferredSubtitle.Intent(preference)
        }

        /** An episode's series, else the item's own title. */
        fun titleOf(item: MediaItem): String =
            (if (item.kind == MediaKind.EPISODE) item.grandparentTitle else null) ?: item.title.orEmpty()

        /** An episode's code and title (`S1E2 · Pilot`); null for other items. */
        fun subtitleOf(item: MediaItem): String? {
            if (item.kind != MediaKind.EPISODE) return null
            return listOfNotNull(episodeCode(item), item.title?.takeIf { it.isNotBlank() }).joinToString(" · ").ifEmpty { null }
        }

        fun episodeCode(item: MediaItem): String? {
            val season = item.parentIndex ?: return null
            val episode = item.index ?: return null
            return "S${season}E$episode"
        }

        /** [path] on [backend], scaled down to fit [maxPx] square when given. */
        private fun imageOf(backend: MediaBackend, path: String?, maxPx: Int? = null): String? =
            path?.takeIf { it.isNotBlank() }?.let { backend.thumbnailUrl(it, maxPx, maxPx, cover = false) }

        /**
         * The OS media controls' artwork fits in this square: the largest any of them shows, Android's session metadata
         * at 320 dp on a 4x screen.
         */
        private const val ARTWORK_PX = 1280

        /**
         * The server's intro and credits markers as skip segments; credits that run to within [CREDITS_TO_END_SECONDS]
         * of the end are the credits to the end (up next and the watched mark start there). Null without markers.
         */
        fun segmentsOf(markers: List<MediaMarker>, durationSeconds: Double): List<SkipSegment>? {
            if (markers.isEmpty()) return null
            return markers.mapNotNull { marker ->
                val kind = when (marker.type) {
                    MediaMarker.INTRO -> SkipKind.INTRO
                    MediaMarker.CREDITS -> SkipKind.CREDITS
                    else -> return@mapNotNull null
                }
                val start = marker.startTimeOffset / 1000.0
                val end = marker.endTimeOffset / 1000.0
                SkipSegment(kind, start, end, toEnd = kind == SkipKind.CREDITS && durationSeconds > 0 && end >= durationSeconds - CREDITS_TO_END_SECONDS)
            }.sortedBy { it.startSeconds }
        }

        private const val CREDITS_TO_END_SECONDS = 1.0
    }
}

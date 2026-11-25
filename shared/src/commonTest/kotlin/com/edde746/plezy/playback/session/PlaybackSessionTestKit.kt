package com.edde746.plezy.playback.session

import com.edde746.plezy.app.testData
import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.InMemoryApiCacheStore
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.PlaybackInitializationOptions
import com.edde746.plezy.backend.PlaybackInitializationResult
import com.edde746.plezy.backend.PlaybackReportMetadata
import com.edde746.plezy.backend.ScrubFrame
import com.edde746.plezy.backend.ScrubPreviewSource
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaServerUserProfile
import com.edde746.plezy.model.MediaSourceInfo
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.model.PlaybackExtras
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.playback.HardwareDecoder
import com.edde746.plezy.playback.queue.EpisodeQueue
import com.edde746.plezy.playback.report.OfflineProgressQueue
import com.edde746.plezy.playback.report.ReportCall
import com.edde746.plezy.playback.report.ReportKind
import com.edde746.plezy.playback.source.FakeDownloads
import com.edde746.plezy.playback.source.FakePlaybackServers
import com.edde746.plezy.playback.source.PlaybackSourceResolver
import com.edde746.plezy.playback.source.cachedMetadata
import com.edde746.plezy.playback.tracks.TrackType
import com.edde746.plezy.servers.LocalPlaybackHistory
import com.edde746.plezy.servers.LocalPlaybackHistoryStore
import com.edde746.plezy.servers.OnlineServers
import com.edde746.plezy.servers.PlaybackStateStore
import com.edde746.plezy.servers.WatchStateNotifier
import com.edde746.plezy.trackers.TrackedPlayback
import com.edde746.plezy.trackers.TrackedPosition
import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.MockEngineConfig
import io.ktor.client.engine.mock.MockRequestHandleScope
import io.ktor.client.request.HttpRequestData
import io.ktor.client.request.HttpResponseData
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.yield
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.files.SystemTemporaryDirectory
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.uuid.Uuid

/**
 * A media server as the playback session uses it: [initialize] answers each playback initialization (recorded in
 * [initializations]; held while [initializationGate] is open), every report lands in [reports], [extras] are the item's
 * chapters and markers ([refreshedExtras] past the cache; [extrasFail] fails the request, leaving [cachedExtras]),
 * [scrubPreviews] what each scrub preview request gets and [episodes] the series' episodes.
 */
internal class SessionBackend(
    serverId: String = "srv",
    backend: BackendKind = BackendKind.PLEX,
) : FakeMediaBackend(serverId, backend) {
    val initializations = mutableListOf<PlaybackInitializationOptions>()
    var initialize: (PlaybackInitializationOptions) -> PlaybackInitializationResult = { options -> streamOf(options) }
    var initializationGate: CompletableDeferred<Unit>? = null
    val reports = mutableListOf<ReportCall>()
    var extras = PlaybackExtras(emptyList(), emptyList())
    var refreshedExtras: PlaybackExtras? = null
    var extrasFail = false
    var cachedExtras: PlaybackExtras? = null
    val extrasRequests = mutableListOf<Boolean>()
    var scrubPreviews: () -> ScrubPreviewSource? = { null }
    var scrubPreviewRequests = 0
    var episodes: List<MediaItem>? = null
    var episodeQueueFetches = 0

    /** Holds the series' episode queue fetch while open. */
    var episodeQueueGate: CompletableDeferred<Unit>? = null
    val watched = mutableListOf<String>()

    /** An error the next reports of a kind fail with instead of landing in [reports] (null: they land). */
    var refuseReports: (ReportKind) -> Exception? = { null }

    /** Every report sent, landed or refused. */
    val attempts = mutableListOf<ReportKind>()

    /** How the server builds an image's URL ([thumbnailUrl]); the path itself by default. */
    var images: (path: String?, width: Int?, height: Int?, cover: Boolean) -> String = { path, _, _, _ -> path.orEmpty() }

    override fun thumbnailUrl(path: String?, width: Int?, height: Int?, cover: Boolean): String = images(path, width, height, cover)

    private fun attempt(kind: ReportKind) {
        attempts += kind
        refuseReports(kind)?.let { throw it }
    }

    init {
        streamHeaders = mapOf("X-Plex-Token" to "t0ken")
        markWatchedHandler = { watched += it.id }
        // The queue primes the next episode's metadata while the current one plays.
        items = { id -> episodes?.firstOrNull { it.id == id } }
    }

    val states: List<String> get() = reports.map { it.state }

    override suspend fun getPlaybackInitialization(options: PlaybackInitializationOptions): PlaybackInitializationResult {
        yield()
        initializationGate?.await()
        initializations += options
        return initialize(options)
    }

    override suspend fun reportPlaybackStarted(
        itemId: String, position: Duration, duration: Duration?, playSessionId: String?, playMethod: String?, liveStreamId: String?,
        mediaSourceId: String?, audioStreamIndex: Int?, subtitleStreamIndex: Int?,
    ) {
        attempt(ReportKind.STARTED)
        reports += ReportCall(
            ReportKind.STARTED, itemId, position.inWholeMilliseconds, duration?.inWholeMilliseconds, playMethod = playMethod,
            mediaSourceId = mediaSourceId, audioStreamIndex = audioStreamIndex, subtitleStreamIndex = subtitleStreamIndex,
        )
    }

    override suspend fun reportPlaybackProgress(
        itemId: String, position: Duration, duration: Duration, isPaused: Boolean, playSessionId: String?, playMethod: String?,
        liveStreamId: String?, mediaSourceId: String?, audioStreamIndex: Int?, subtitleStreamIndex: Int?,
    ) {
        attempt(ReportKind.PROGRESS)
        reports += ReportCall(
            ReportKind.PROGRESS, itemId, position.inWholeMilliseconds, duration.inWholeMilliseconds, isPaused, playMethod = playMethod,
            mediaSourceId = mediaSourceId, audioStreamIndex = audioStreamIndex, subtitleStreamIndex = subtitleStreamIndex,
        )
    }

    override suspend fun reportPlaybackStopped(
        itemId: String, position: Duration, duration: Duration?, playSessionId: String?, liveStreamId: String?, mediaSourceId: String?,
        audioStreamIndex: Int?, subtitleStreamIndex: Int?, report: PlaybackReportMetadata,
    ) {
        attempt(ReportKind.STOPPED)
        reports += ReportCall(
            ReportKind.STOPPED, itemId, position.inWholeMilliseconds, duration?.inWholeMilliseconds,
            mediaSourceId = mediaSourceId, audioStreamIndex = audioStreamIndex, subtitleStreamIndex = subtitleStreamIndex,
        )
    }

    override suspend fun fetchPlaybackExtras(itemId: String, introPattern: String?, creditsPattern: String?, forceChapterFallback: Boolean, forceRefresh: Boolean): PlaybackExtras {
        extrasRequests += forceRefresh
        if (extrasFail) throw MediaServerHttpException(MediaServerHttpErrorType.CONNECTION_ERROR, "unreachable")
        return if (forceRefresh) refreshedExtras ?: extras else extras
    }

    override suspend fun fetchPlaybackExtrasFromCacheOnly(itemId: String, introPattern: String?, creditsPattern: String?, forceChapterFallback: Boolean) = cachedExtras

    override suspend fun createScrubPreviewSource(item: MediaItem, mediaSource: MediaSourceInfo): ScrubPreviewSource? {
        scrubPreviewRequests++
        return scrubPreviews()
    }

    override suspend fun fetchClientSideEpisodeQueue(seriesId: String): List<MediaItem>? {
        episodeQueueFetches++
        episodeQueueGate?.await()
        return episodes
    }

    companion object {
        val VERSIONS = listOf(MediaVersion(id = "v1080", videoResolution = "1080", videoCodec = "h264", container = "mkv"), MediaVersion(id = "v4k", videoResolution = "4k", videoCodec = "hevc", container = "mkv"))

        /** A direct play of the requested version at `https://srv/<item>/<version>`; a capped quality transcodes. */
        fun streamOf(options: PlaybackInitializationOptions): PlaybackInitializationResult {
            val index = options.selectedMediaIndex.coerceIn(VERSIONS.indices)
            val transcoding = !options.qualityPreset.isOriginal || options.forceTranscode
            val path = if (transcoding) "transcode/${options.qualityPreset.name}" else VERSIONS[index].id
            return PlaybackInitializationResult(
                availableVersions = VERSIONS,
                videoUrl = "https://srv/${options.metadata.id}/$path",
                mediaInfo = MediaSourceInfo(videoUrl = "https://srv/${options.metadata.id}/$path", audioTracks = emptyList(), subtitleTracks = emptyList(), chapters = emptyList(), partId = 7),
                isTranscoding = transcoding,
                selectedMediaIndex = index,
                selectedMediaSourceId = VERSIONS[index].id,
            )
        }
    }
}

/** Seek-bar thumbnails that remember being disposed. */
internal class FakeScrubPreview : ScrubPreviewSource {
    var disposed = false
    override val isAvailable: Boolean get() = true
    override fun frameAt(time: Duration): ScrubFrame? = null
    override fun dispose() {
        disposed = true
    }
}

/** What trackers heard, one line per event. */
internal class RecordingTrackers : TrackedPlayback {
    val events = mutableListOf<String>()

    override fun onVideoStarted(item: MediaItem, backend: MediaBackend, at: TrackedPosition, playing: Boolean, live: Boolean) {
        events += "started ${item.id} @${at.positionMillis} playing=$playing"
    }

    override fun onPlayingChanged(playing: Boolean, at: TrackedPosition) {
        events += "playing=$playing @${at.positionMillis}"
    }

    override fun onPosition(at: TrackedPosition) {
        events += "position @${at.positionMillis}"
    }

    override fun onVideoStopped(at: TrackedPosition) {
        events += "stopped @${at.positionMillis}"
    }
}

private class MemoryHistory : LocalPlaybackHistoryStore {
    var history: Map<String, Long> = emptyMap()
    override suspend fun read() = history
    override suspend fun write(history: Map<String, Long>) {
        this.history = history
    }
}

private class Online(private val backend: MediaBackend) : OnlineServers {
    override val visibleOnlineClients: Map<ServerId, MediaBackend> get() = mapOf(backend.serverId to backend)
    override val onlineClients: Map<ServerId, MediaBackend> get() = visibleOnlineClients
    override fun client(serverId: ServerId): MediaBackend? = backend.takeIf { it.serverId == serverId }
    override val changes: Flow<Unit> = emptyFlow()
}

/**
 * One [PlaybackSession] over [backend] and a [ScriptedEngine], with what it reports to. [subtitleServer] answers the
 * sidecar subtitles' fetches (recorded in [subtitleRequests]) on the test's clock, which the session saves under
 * [subtitleDirectory]. [queueServer] answers the queue's requests (a Plex show's server queue); [backend] by default.
 */
internal class SessionRig(scope: TestScope, val backend: SessionBackend = SessionBackend(), queueServer: MediaBackend = backend) {
    var subtitleServer: suspend MockRequestHandleScope.(HttpRequestData) -> HttpResponseData = { error("no subtitle fetch expected") }
    val subtitleRequests = mutableListOf<HttpRequestData>()
    val subtitleDirectory = Path(SystemTemporaryDirectory, "plezy-session-test-${Uuid.random()}")
    private val subtitleHttp = HttpClient(
        MockEngine(
            MockEngineConfig().apply {
                dispatcher = StandardTestDispatcher(scope.testScheduler)
                addHandler { request ->
                    subtitleRequests += request
                    subtitleServer(request)
                }
            },
        ),
    )
    val engine = ScriptedEngine()
    val trackers = RecordingTrackers()
    val videoSessions = VideoSessions()
    val serverStatus = MutableSharedFlow<Map<ServerId, Boolean>>(extraBufferCapacity = 4)
    val playbackState = PlaybackStateStore()
    val settings = scope.testData().deviceSettings
    val downloads = FakeDownloads()

    /** The servers the session resolves on; [FakePlaybackServers.online] says which answer. */
    val servers = FakePlaybackServers(backend)

    /** The completed downloads of every show ([PlaybackEnvironment.downloadedEpisodes] picks the show's). */
    var downloadedEpisodes: List<MediaItem> = emptyList()

    /** Video may play now ([PlaybackEnvironment.playbackAllowed]). */
    var allowed = true

    /** Whether the device is on a metered network. */
    var metered = false

    /** The account's preferences playback sees, and what [PlaybackEnvironment.awaitProfile] waits on. */
    var profile: MediaServerUserProfile? = null
    var profileLoad: CompletableDeferred<Unit>? = null

    /** Each Jellyfin account memory request ([PlaybackEnvironment.trackSelectionMemory]), and its answer. */
    val memoryRequests = mutableListOf<TrackType>()
    var remembers = true
    val env = PlaybackEnvironment(
        servers = servers,
        serverStatus = serverStatus,
        resolver = PlaybackSourceResolver(servers, downloads, cachedMetadata(InMemoryApiCacheStore())),
        queue = EpisodeQueue(playbackState, Online(queueServer)),
        playbackState = playbackState,
        settings = settings,
        notifier = WatchStateNotifier(),
        offlineQueue = OfflineProgressQueue { _, _, _, _ -> },
        history = LocalPlaybackHistory(MemoryHistory()),
        trackers = trackers,
        trackerMarks = null,
        videoSessions = videoSessions,
        sleepTimer = null,
        reportScope = scope.backgroundScope,
        sidecars = SidecarFetcher(subtitleHttp, subtitleDirectory, SystemFileSystem, StandardTestDispatcher(scope.testScheduler)),
        playbackAllowed = { allowed },
        downloadedEpisodes = { show -> downloadedEpisodes.filter { it.seriesGlobalKey == show } },
        profile = { profile },
        awaitProfile = { profileLoad?.await() },
        trackSelectionMemory = { _, type ->
            memoryRequests += type
            remembers
        },
        meteredNetwork = { metered },
    )
    /** How often the session left the player; [onLeave] is what leaving does (the app's route pop closes the session). */
    var left = 0
    var onLeave: () -> Unit = {}
    val session = PlaybackSession(engine, HardwareDecoder.APPLE, env, scope.backgroundScope) {
        left++
        onLeave()
    }

    /** Plays [item] and lets the session resolve and load it. */
    fun TestScope.play(item: MediaItem, request: (PlayRequest.Item) -> PlayRequest.Item = { it }) {
        session.start(request(PlayRequest.Item(ServerId(backend.serverId.value), item.id, item = item)))
        runCurrent()
    }

    /** The last load's file opens ([duration] long) and plays. */
    fun TestScope.open(duration: Double) {
        engine.open(duration)
        runCurrent()
    }

    fun TestScope.at(position: Double) {
        engine.play(position)
        runCurrent()
    }

    fun TestScope.elapse(duration: Duration) {
        advanceTimeBy(duration)
        runCurrent()
    }

    fun TestScope.idle() = elapse(1.seconds)
}

internal fun movie(id: String = "m1", backend: BackendKind = BackendKind.PLEX, viewOffsetMs: Long? = null, durationMs: Long? = 600_000) =
    MediaItem(id = id, backend = backend, kind = MediaKind.MOVIE, title = "Movie $id", serverId = "srv", viewOffsetMs = viewOffsetMs, durationMs = durationMs)

internal fun episode(id: String, index: Int, backend: BackendKind = BackendKind.JELLYFIN, durationMs: Long? = 1_200_000) = MediaItem(
    id = id, backend = backend, kind = MediaKind.EPISODE, title = "Episode $index", serverId = "srv", durationMs = durationMs,
    parentIndex = 1, index = index, grandparentId = "show", grandparentTitle = "The Show", parentId = "season1",
)

package com.edde746.plezy.presentation.detail

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.backend.ItemWithOnDeck
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.format.formatDurationTextual
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.MediaHub
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.model.MediaRole
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.playback.session.PlayRequest
import com.edde746.plezy.presentation.browse.CardOptions
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.player.PlayerStates
import com.edde746.plezy.servers.DeletionNotifier
import com.edde746.plezy.servers.FakeOfflineWatchDownloads
import com.edde746.plezy.servers.FakeWatchClients
import com.edde746.plezy.servers.InMemoryOfflineWatchQueue
import com.edde746.plezy.servers.OfflineWatchProvider
import com.edde746.plezy.servers.OfflineWatchSyncService
import com.edde746.plezy.servers.RecordingTrackers
import com.edde746.plezy.servers.ToggleOfflineMode
import com.edde746.plezy.servers.WatchActions
import com.edde746.plezy.servers.WatchStateNotifier
import com.edde746.plezy.servers.WatchStateStore
import com.edde746.plezy.servers.WatchedThresholdSource
import com.edde746.plezy.model.SpecialsOrdering
import kotlinx.coroutines.CompletableDeferred
import com.edde746.plezy.downloads.DownloadFeedback
import com.edde746.plezy.model.MediaRatingSource
import com.edde746.plezy.presentation.downloads.DownloadButtonIcon
import com.edde746.plezy.presentation.downloads.DownloadButtonSpec
import com.edde746.plezy.playback.queue.PlayQueueLaunch
import com.edde746.plezy.playback.queue.PlayQueueResult
import com.edde746.plezy.strings.T
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration
import com.edde746.plezy.plex.jsonResponse
import com.edde746.plezy.plex.testPlexClient
import kotlin.time.Duration.Companion.minutes

class MediaDetailStoreTest {
    private val serverId = ServerId("jf")

    private class Backend : FakeMediaBackend("jf", BackendKind.JELLYFIN) {
        var detail: suspend (String, ((MediaItem) -> Unit)?) -> ItemWithOnDeck = { _, _ -> ItemWithOnDeck(null, null) }
        var extrasOf: suspend (String) -> List<MediaItem> = { emptyList() }
        var relatedOf: suspend (String) -> List<MediaHub> = { emptyList() }
        override suspend fun fetchItemWithOnDeck(id: String, onItemReady: ((MediaItem) -> Unit)?) = detail(id, onItemReady)
        override suspend fun fetchExtras(id: String) = extrasOf(id)
        override suspend fun fetchRelatedHubs(id: String, count: Int) = relatedOf(id)

        init {
            // A refetch after a watch change finds nothing new unless a test scripts it.
            items = { null }
        }
    }

    private val backend = Backend()
    private var communityRatings: ((MediaItem, com.edde746.plezy.backend.MediaBackend) -> Flow<List<MediaRatingSource>>)? = null
    private var downloads: DetailDownloads? = null
    private var previewTracks: (suspend (MediaItem, com.edde746.plezy.backend.MediaBackend) -> TrackStatusUi?)? = null
    private var savedVersion: (suspend (MediaItem) -> Int?)? = null
    private var currentQuality: (suspend () -> TranscodeQualityPreset)? = null
    private var offlineSource: OfflineDetailSource? = null
    private val notifier = WatchStateNotifier()
    private val deletions = DeletionNotifier()

    /** The watch actions of the last store made, as the item menus mark items. */
    private lateinit var actions: WatchActions
    private val plays = mutableListOf<PlayRequest>()
    private val edits = MutableSharedFlow<com.edde746.plezy.presentation.metadata.EditedItem>(extraBufferCapacity = 4)
    private var pruneDistantSeasons = false

    /** The global key of the item playing now ([DetailDeps.playingKey]). */
    private var playing: String? = null

    /** The client every server resolves to in place of [backend]. */
    private var otherClient: com.edde746.plezy.backend.MediaBackend? = null

    private fun item(id: String, kind: MediaKind, block: MediaItem.() -> MediaItem = { this }) =
        MediaItem(id = id, backend = BackendKind.JELLYFIN, kind = kind, title = id, serverId = "jf").block()

    private fun episodes(season: MediaItem, count: Int, watched: Int = 0) = (1..count).map { n ->
        item("${season.id}e$n", MediaKind.EPISODE) { copy(index = n, parentIndex = season.index, parentId = season.id, viewCount = if (n <= watched) 1 else 0) }
    }

    private fun TestScope.store(
        id: String,
        tv: Boolean = false,
        seasonId: String? = null,
        offline: Boolean = false,
        episodeId: String? = null,
        options: CardOptions = CardOptions(),
        seed: MediaItem? = null,
        extra: (DetailDeps) -> DetailDeps = { it },
    ): MediaDetailStore {
        val clients = FakeWatchClients().apply { register(backend) }
        // An offline detail's session is offline too: its watch marks queue for the server.
        val offlineMode = ToggleOfflineMode(offline)
        val sync = OfflineWatchSyncService(
            InMemoryOfflineWatchQueue(), FakeOfflineWatchDownloads(), clients, notifier, RecordingTrackers(),
            thresholds = object : WatchedThresholdSource {
                override fun reportsServerThreshold(client: com.edde746.plezy.backend.MediaBackend) = false
                override fun cachedPercent(serverId: ServerId): Int? = null
            },
            offlineMode = offlineMode,
            scope = backgroundScope,
            minSyncInterval = Duration.ZERO,
            forceSyncOnResume = false,
            timeSource = testScheduler.timeSource,
        )
        val offlineWatch = OfflineWatchProvider(sync, FakeOfflineWatchDownloads(), notifier, backgroundScope, { SpecialsOrdering.SPECIALS_LAST }, { false })
        val deps = DetailDeps(
            client = { otherClient ?: if (it == serverId) backend else null },
            watchActions = WatchActions(clients, offlineMode, offlineWatch, notifier, RecordingTrackers(), backgroundScope).also { actions = it },
            watchState = WatchStateStore(notifier, backgroundScope),
            watchEvents = notifier.events,
            deletions = deletions.events,
            play = { plays += it },
            cardOptions = { options },
            tv = tv,
            communityRatings = communityRatings,
            downloads = downloads,
            previewTracks = previewTracks,
            savedVersion = savedVersion,
            currentQuality = currentQuality,
            offline = offlineSource,
            edited = edits,
            pruneDistantSeasons = pruneDistantSeasons,
            playingKey = { playing },
        )
        val route = Route.MediaDetail(serverId, id, initialSeasonId = seasonId, initialEpisodeId = episodeId, offline = offline)
        return MediaDetailStore(seed?.let(route::seeded) ?: route, extra(deps), backgroundScope)
    }

    private val show = item("show", MediaKind.SHOW)
    private val s1 = item("s1", MediaKind.SEASON) { copy(index = 1, parentId = "show") }
    private val s2 = item("s2", MediaKind.SEASON) { copy(index = 2, parentId = "show") }

    private fun scriptShow(failSeason: String? = null, hold: Map<String, CompletableDeferred<Unit>> = emptyMap(), watched: Int = 0) {
        backend.detail = { _, _ -> ItemWithOnDeck(show, null) }
        backend.children = { listOf(s1, s2) }
        backend.childrenPage = { id, _, _ ->
            hold[id]?.await()
            if (id == failSeason) error("boom")
            val season = if (id == "s1") s1 else s2
            val rows = episodes(season, 3, watched)
            LibraryPage(rows, rows.size, 0)
        }
    }

    @Test
    fun `a failed season switch shows its error not the previous season episodes`() = runTest {
        scriptShow(failSeason = "s2")
        val store = store("show")
        runCurrent()
        assertEquals(listOf("s1e1", "s1e2", "s1e3"), store.state.value.episodes!!.rows.map { it.id })
        store.selectSeason(1)
        runCurrent()
        val episodes = store.state.value.episodes!!
        assertEquals(SectionLoad.ERROR, episodes.load)
        assertTrue(episodes.rows.isEmpty())
    }

    @Test
    fun `a jellyfin show with one season lists its episodes directly and two seasons show tabs`() = runTest {
        scriptShow()
        backend.children = { listOf(s1) }
        val single = store("show")
        runCurrent()
        assertTrue(single.state.value.seasons.isEmpty())
        assertEquals(listOf("s1e1", "s1e2", "s1e3"), single.state.value.episodes!!.rows.map { it.id })

        backend.children = { listOf(s1, s2) }
        val two = store("show")
        runCurrent()
        assertEquals(2, two.state.value.seasons.size)
    }

    @Test
    fun `a jellyfin item drops its edition title`() = runTest {
        backend.detail = { _, _ -> ItemWithOnDeck(item("movie", MediaKind.MOVIE) { copy(editionTitle = "Director's Cut") }, null) }
        val store = store("movie")
        runCurrent()
        assertEquals(null, store.state.value.hero!!.edition)
    }

    @Test
    fun `returning to a season whose load is still running shows its episodes when it lands`() = runTest {
        val gate = CompletableDeferred<Unit>()
        scriptShow(hold = mapOf("s2" to gate))
        val store = store("show")
        runCurrent()
        store.selectSeason(1)
        runCurrent()
        assertEquals(SectionLoad.LOADING, store.state.value.episodes!!.load)
        store.selectSeason(0)
        store.selectSeason(1)
        gate.complete(Unit)
        runCurrent()
        assertEquals(listOf("s2e1", "s2e2", "s2e3"), store.state.value.episodes!!.rows.map { it.id })
    }

    @Test
    fun `a requested season opens first`() = runTest {
        scriptShow()
        val store = store("show", seasonId = "s2")
        runCurrent()
        assertEquals(1, store.state.value.selectedSeason)
        assertEquals("s2e1", store.state.value.episodes!!.rows.first().id)
    }

    @Test
    fun `without an on deck episode the first unwatched one is played and labelled`() = runTest {
        scriptShow(watched = 1)
        val store = store("show")
        runCurrent()
        assertEquals("S1E2", store.state.value.actions.playLabel)
        assertTrue(store.state.value.episodes!!.rows.single { it.onDeck }.id == "s1e2")
        store.play()
        assertEquals("s1e2", (plays.single() as PlayRequest.Item).itemId)
    }

    @Test
    fun `a shows play plays its next episode as the shows play and an episode plays on its own`() = runTest {
        scriptShow(watched = 1)
        val store = store("show", tv = true)
        runCurrent()
        store.play()
        store.playEpisode("s1e3")
        store.focusEpisode("s1e3")
        store.play()
        assertEquals(listOf("s1e2" to true, "s1e3" to false, "s1e3" to false), plays.map { (it as PlayRequest.Item).let { r -> r.itemId to r.showPlay } })
    }

    @Test
    fun `movie with several versions offers the split and plays the picked one`() = runTest {
        val movie = item("m", MediaKind.MOVIE) {
            copy(mediaVersions = listOf(MediaVersion("a", videoResolution = "1080"), MediaVersion("b", videoResolution = "4k")))
        }
        backend.detail = { _, _ -> ItemWithOnDeck(movie, null) }
        val store = store("m")
        runCurrent()
        assertEquals(2, store.state.value.actions.versions.size)
        assertNull(store.state.value.actions.playLabel)
        store.playVersion(1)
        val request = plays.single() as PlayRequest.Item
        assertEquals(1, request.mediaIndex)
        assertEquals("b", request.mediaSourceId)
        assertTrue(request.strictMediaSelection)
    }

    @Test
    fun `the saved version is the current one and a quality plays it`() = runTest {
        val movie = item("m", MediaKind.MOVIE) {
            copy(mediaVersions = listOf(MediaVersion("a", videoResolution = "1080"), MediaVersion("b", videoResolution = "4k")))
        }
        backend.detail = { _, _ -> ItemWithOnDeck(movie, null) }
        backend.capabilities = backend.capabilities.copy(videoTranscoding = true)
        savedVersion = { 1 }
        val store = store("m")
        runCurrent()

        val actions = store.state.value.actions
        assertEquals(1, actions.version)
        assertEquals(TranscodeQualityPreset.displayOrder.size, actions.qualities.size)
        store.playQuality(2)
        val request = plays.single() as PlayRequest.Item
        assertEquals(1, request.mediaIndex)
        assertEquals("b", request.mediaSourceId)
        assertEquals(TranscodeQualityPreset.displayOrder[2], request.qualityPreset)
        assertTrue(request.strictMediaSelection)
    }

    @Test
    fun `without a saved version the first is current and no transcoding lists no quality`() = runTest {
        val movie = item("m", MediaKind.MOVIE) { copy(mediaVersions = listOf(MediaVersion("a"), MediaVersion("b"))) }
        backend.detail = { _, _ -> ItemWithOnDeck(movie, null) }
        backend.capabilities = backend.capabilities.copy(videoTranscoding = false)
        val store = store("m")
        runCurrent()

        assertEquals(0, store.state.value.actions.version)
        assertTrue(store.state.value.actions.qualities.isEmpty())
    }

    @Test
    fun `single version movie keeps the plain play button`() = runTest {
        backend.detail = { _, _ -> ItemWithOnDeck(item("m", MediaKind.MOVIE) { copy(mediaVersions = listOf(MediaVersion("a"))) }, null) }
        val store = store("m")
        runCurrent()
        assertTrue(store.state.value.actions.versions.isEmpty())
    }

    @Test
    fun `a single version movie on a transcoding server lists its qualities with the current one`() = runTest {
        backend.detail = { _, _ -> ItemWithOnDeck(item("m", MediaKind.MOVIE) { copy(mediaVersions = listOf(MediaVersion("a"))) }, null) }
        backend.capabilities = backend.capabilities.copy(videoTranscoding = true)
        currentQuality = { TranscodeQualityPreset.displayOrder[3] }
        val store = store("m")
        runCurrent()

        val actions = store.state.value.actions
        assertTrue(actions.versions.isEmpty())
        val expected = PlayerStates.qualities(null, TranscodeQualityPreset.displayOrder[3])
        assertEquals(expected.map { it.label }, actions.qualities, "the list every version and quality choice shows")
        assertEquals(expected.indexOfFirst { it.selected }, actions.quality)
        assertEquals(3, actions.quality)
        store.playQuality(1)
        val request = plays.single() as PlayRequest.Item
        assertEquals(0, request.mediaIndex)
        assertEquals(TranscodeQualityPreset.displayOrder[1], request.qualityPreset)
    }

    @Test
    fun `the quality list hides presets the source fits under and plays the row picked`() = runTest {
        val small = MediaVersion("a", height = 480, bitrate = 1200)
        backend.detail = { _, _ -> ItemWithOnDeck(item("m", MediaKind.MOVIE) { copy(mediaVersions = listOf(small)) }, null) }
        backend.capabilities = backend.capabilities.copy(videoTranscoding = true)
        val store = store("m")
        runCurrent()

        val offered = PlayerStates.offeredQualities(1200, 480, TranscodeQualityPreset.ORIGINAL)
        assertEquals(offered.map { it.label }, store.state.value.actions.qualities)
        assertTrue(offered.size < TranscodeQualityPreset.displayOrder.size)
        store.playQuality(1)
        assertEquals(offered[1].preset, (plays.single() as PlayRequest.Item).qualityPreset)
    }

    @Test
    fun `play from start starts at zero and play resumes`() = runTest {
        backend.detail = { _, _ -> ItemWithOnDeck(item("m", MediaKind.MOVIE) { copy(viewOffsetMs = 60_000, durationMs = 600_000) }, null) }
        val store = store("m")
        runCurrent()
        assertTrue(store.state.value.actions.resume)
        store.play()
        store.playFromStart()
        assertEquals(listOf(null, Duration.ZERO), plays.map { (it as PlayRequest.Item).startPosition })
    }

    @Test
    fun `the item paints before the on deck lookup settles`() = runTest {
        val gate = CompletableDeferred<Unit>()
        backend.detail = { _, ready ->
            ready?.invoke(show)
            gate.await()
            ItemWithOnDeck(show, null)
        }
        backend.children = { emptyList() }
        backend.playableDescendants = { emptyList() }
        val store = store("show")
        runCurrent()
        assertEquals(SectionLoad.CONTENT, store.state.value.load)
        assertTrue(!store.state.value.ready)
    }

    @Test
    fun `a failed fetch without a seed shows the error and Retry fetches again`() = runTest {
        backend.detail = { _, _ -> error("gone") }
        val store = store("m")
        runCurrent()
        assertEquals(SectionLoad.ERROR, store.state.value.load)
        assertTrue(store.state.value.canRetry)
        backend.detail = { _, _ -> ItemWithOnDeck(item("m", MediaKind.MOVIE) { copy(title = "Fetched") }, null) }
        store.retry()
        runCurrent()
        assertEquals(SectionLoad.CONTENT, store.state.value.load)
        assertEquals("Fetched", store.state.value.hero?.title)
        assertFalse(store.state.value.canRetry)
    }

    @Test
    fun `a failed fetch with a seed shows the seed and loads its seasons and episodes`() = runTest {
        scriptShow()
        backend.detail = { _, _ -> error("gone") }
        val store = store("show", seed = show.copy(title = "From the card"))
        runCurrent()
        val state = store.state.value
        assertEquals(SectionLoad.CONTENT, state.load)
        assertEquals("From the card", state.hero?.title)
        assertEquals(listOf("s1", "s2"), state.seasons.map { it.id })
        assertEquals(listOf("s1e1", "s1e2", "s1e3"), state.episodes!!.rows.map { it.id })
        assertTrue(state.ready)
    }

    @Test
    fun `a fetch that finds nothing shows the seed`() = runTest {
        backend.detail = { _, _ -> ItemWithOnDeck(null, null) }
        val store = store("m", seed = item("m", MediaKind.MOVIE) { copy(title = "From the card") })
        runCurrent()
        assertEquals(SectionLoad.CONTENT, store.state.value.load)
        assertEquals("From the card", store.state.value.hero?.title)
    }

    @Test
    fun `a seed of another item is not shown`() = runTest {
        backend.detail = { _, _ -> error("gone") }
        val store = store("m", seed = item("other", MediaKind.MOVIE))
        runCurrent()
        assertEquals(SectionLoad.ERROR, store.state.value.load)
    }

    @Test
    fun `an episode marked watched from its menu shows watched`() = runTest {
        scriptShow()
        backend.markWatchedHandler = {}
        val store = store("show")
        runCurrent()
        backend.detail = { _, _ -> ItemWithOnDeck(show, null) }
        actions.setWatched(store.episodeItem("s1e1")!!, true)
        runCurrent()
        assertTrue(store.state.value.episodes!!.rows.first().watched)
    }

    @Test
    fun `a newer season mark overrides an older episode mark across a season round trip`() = runTest {
        scriptShow()
        val store = store("show")
        runCurrent()
        val (first) = episodes(s1, 3)
        notifier.notifyWatched(first, isNowWatched = false)
        runCurrent()
        assertFalse(store.state.value.episodes!!.rows.first().watched)

        notifier.notifyWatched(s1)
        runCurrent()
        assertTrue(store.state.value.episodes!!.rows.all { it.watched }, "the season's mark is newer than the episode's")
        store.selectSeason(1)
        runCurrent()
        store.selectSeason(0)
        runCurrent()
        assertTrue(store.state.value.episodes!!.rows.all { it.watched })
    }

    @Test
    fun `an episode changed elsewhere is fetched again and patched in place`() = runTest {
        scriptShow()
        val store = store("show")
        runCurrent()
        val second = episodes(s1, 3)[1]
        backend.items = { id -> if (id == second.id) second.copy(title = "Renamed") else null }
        notifier.notifyWatched(second)
        runCurrent()
        assertEquals("2. Renamed", store.state.value.episodes!!.rows[1].title)

        val third = episodes(s1, 3)[2]
        backend.items = { id -> if (id == third.id) third.copy(title = "Edited") else null }
        edits.emit(com.edde746.plezy.presentation.metadata.EditedItem(serverId, third.id))
        runCurrent()
        assertEquals("3. Edited", store.state.value.episodes!!.rows[2].title)
    }

    @Test
    fun `an edit of the item itself fetches it again`() = runTest {
        scriptShow()
        val store = store("show")
        runCurrent()
        assertEquals("show", store.state.value.hero!!.title)
        backend.detail = { _, _ -> ItemWithOnDeck(show.copy(title = "Edited show"), null) }
        edits.emit(com.edde746.plezy.presentation.metadata.EditedItem(serverId, "show"))
        runCurrent()
        assertEquals("Edited show", store.state.value.hero!!.title)
    }

    @Test
    fun `a low end tv keeps only the selected season and its neighbours`() = runTest {
        val seasons = (1..4).map { n -> item("s$n", MediaKind.SEASON) { copy(index = n, parentId = "show") } }
        val fetches = mutableMapOf<String, Int>()
        backend.detail = { _, _ -> ItemWithOnDeck(show, null) }
        backend.children = { seasons }
        backend.childrenPage = { id, _, _ ->
            fetches[id] = (fetches[id] ?: 0) + 1
            val rows = episodes(seasons.first { it.id == id }, 2)
            LibraryPage(rows, rows.size, 0)
        }
        pruneDistantSeasons = true
        val store = store("show", tv = true)
        runCurrent()
        store.selectSeason(3)
        runCurrent()
        store.selectSeason(0)
        runCurrent()
        assertEquals(2, fetches["s1"], "season 1 fell out of the window and loads again")
    }

    @Test
    fun `the trailer shows when extras hold one`() = runTest {
        val trailer = item("t", MediaKind.CLIP) { copy(raw = kotlinx.serialization.json.buildJsonObject { put("ExtraType", kotlinx.serialization.json.JsonPrimitive("Trailer")) }) }
        backend.detail = { _, _ -> ItemWithOnDeck(item("m", MediaKind.MOVIE), null) }
        backend.extrasOf = { listOf(trailer) }
        val store = store("m")
        runCurrent()
        assertTrue(store.state.value.actions.trailer)
        store.playTrailer()
        assertEquals("t", (plays.single() as PlayRequest.Item).itemId)
    }
    @Test
    fun `community scores join the items own`() = runTest {
        backend.detail = { _, _ -> ItemWithOnDeck(item("m", MediaKind.MOVIE) { copy(ratings = listOf(MediaRatingSource("imdb", 7.8))) }, null) }
        communityRatings = { _, _ -> flowOf(listOf(MediaRatingSource("trakt", 8.1))) }
        val store = store("m")
        runCurrent()
        assertEquals(listOf("imdb", "trakt"), store.state.value.hero!!.ratings.map { it.source })
    }

    @Test
    fun `the download button follows its download and hides offline`() = runTest {
        val specs = MutableStateFlow(DownloadButtonSpec(DownloadButtonIcon.entries.first(), "Download"))
        downloads = object : DetailDownloads {
            override fun spec(item: MediaItem) = specs
            override val changes = flowOf(Unit)
            override fun episodeStatus(episode: MediaItem): EpisodeDownloadUi? = null
            override suspend fun press(item: MediaItem, client: com.edde746.plezy.backend.MediaBackend, fallbackVersions: List<MediaVersion>?) =
                DownloadFeedback("Download queued", isError = false)
        }
        backend.detail = { _, _ -> ItemWithOnDeck(item("m", MediaKind.MOVIE), null) }
        val store = store("m")
        runCurrent()
        assertEquals("Download", store.state.value.download?.tooltip)
        specs.value = specs.value.copy(tooltip = "Queued")
        runCurrent()
        assertEquals("Queued", store.state.value.download?.tooltip)
    }

    @Test
    fun `track status is probed at once and for a focused episode once it rests`() = runTest {
        scriptShow(watched = 1)
        val probed = mutableListOf<String>()
        previewTracks = { item, _ ->
            probed += item.id
            TrackStatusUi(listOf("1080p"), item.id, null, "Off", null)
        }
        val store = store("show", tv = true)
        runCurrent()
        assertEquals("s1e2", store.state.value.tracks?.audio)
        assertFalse(store.state.value.tracksLoading)
        store.focusEpisode("s1e3")
        assertEquals("S1E3", store.state.value.actions.playLabel)
        assertEquals("s1e3", store.state.value.hero!!.episodeTitle)
        assertTrue(store.state.value.tracksLoading)
        advanceTimeBy(349)
        assertNull(store.state.value.tracks)
        advanceTimeBy(2)
        assertEquals("s1e3", store.state.value.tracks?.audio)
        store.focusEpisode(null)
        assertEquals("s1e2", store.state.value.tracks?.audio)
        assertEquals(listOf("s1e2", "s1e3"), probed)
    }

    @Test
    fun `the track status keeps its room until the probe answers`() = runTest {
        backend.detail = { _, _ -> ItemWithOnDeck(item("m", MediaKind.MOVIE), null) }
        val answer = CompletableDeferred<TrackStatusUi?>()
        previewTracks = { _, _ -> answer.await() }
        val store = store("m")
        runCurrent()
        assertNull(store.state.value.tracks)
        assertTrue(store.state.value.tracksLoading)
        answer.complete(TrackStatusUi(listOf("1080p"), "English", null, "Off", null))
        runCurrent()
        assertEquals("English", store.state.value.tracks?.audio)
        assertFalse(store.state.value.tracksLoading)
    }

    @Test
    fun `a probe that finds nothing gives the track status room back to the facts quality`() = runTest {
        backend.detail = { _, _ -> ItemWithOnDeck(item("m", MediaKind.MOVIE) { copy(mediaVersions = listOf(MediaVersion("a", videoResolution = "1080"))) }, null) }
        previewTracks = { _, _ -> null }
        val store = store("m")
        runCurrent()
        assertNull(store.state.value.tracks)
        assertFalse(store.state.value.tracksLoading)
        assertEquals(listOf("1080p"), store.state.value.hero!!.qualityLabels)
    }

    @Test
    fun `the card shows while the item loads and its tracks wait for the fetched item`() = runTest {
        val gate = CompletableDeferred<Unit>()
        backend.detail = { _, _ ->
            gate.await()
            ItemWithOnDeck(item("m", MediaKind.MOVIE) { copy(title = "Fetched") }, null)
        }
        val probed = mutableListOf<String?>()
        previewTracks = { item, _ ->
            probed += item.title
            TrackStatusUi(emptyList(), "English", null, "Off", null)
        }
        val store = store("m", seed = item("m", MediaKind.MOVIE) { copy(title = "From the card") })
        runCurrent()
        assertEquals(SectionLoad.CONTENT, store.state.value.load)
        assertEquals("From the card", store.state.value.hero?.title)
        assertFalse(store.state.value.actions.playEnabled)
        assertFalse(store.state.value.ready)
        assertTrue(store.state.value.itemLoading)
        assertTrue(store.state.value.tracksLoading)
        assertEquals(emptyList(), probed)
        gate.complete(Unit)
        runCurrent()
        assertEquals("Fetched", store.state.value.hero?.title)
        assertTrue(store.state.value.actions.playEnabled)
        assertFalse(store.state.value.itemLoading)
        assertEquals(listOf<String?>("Fetched"), probed)
        assertEquals("English", store.state.value.tracks?.audio)
    }

    @Test
    fun `the item and the tv page wait for its download button to come in with it`() = runTest {
        val specs = MutableSharedFlow<DownloadButtonSpec>()
        downloads = object : DetailDownloads {
            override fun spec(item: MediaItem) = specs
            override val changes = flowOf(Unit)
            override fun episodeStatus(episode: MediaItem): EpisodeDownloadUi? = null
            override suspend fun press(item: MediaItem, client: com.edde746.plezy.backend.MediaBackend, fallbackVersions: List<MediaVersion>?) = null
        }
        backend.detail = { _, _ -> ItemWithOnDeck(item("m", MediaKind.MOVIE), null) }
        val store = store("m", seed = item("m", MediaKind.MOVIE))
        runCurrent()
        assertTrue(store.state.value.actions.playEnabled)
        assertTrue(store.state.value.itemLoading)
        assertFalse(store.state.value.ready)
        specs.emit(DownloadButtonSpec(DownloadButtonIcon.entries.first(), "Download"))
        runCurrent()
        assertEquals("Download", store.state.value.download?.tooltip)
        assertFalse(store.state.value.itemLoading)
        assertTrue(store.state.value.ready)
    }

    @Test
    fun `a movie card asks for its extras while the item loads and shows them once it has`() = runTest {
        val gate = CompletableDeferred<Unit>()
        backend.detail = { _, _ ->
            gate.await()
            ItemWithOnDeck(item("m", MediaKind.MOVIE), null)
        }
        var asked = false
        backend.extrasOf = {
            asked = true
            listOf(item("trailer", MediaKind.CLIP))
        }
        val store = store("m", seed = item("m", MediaKind.MOVIE))
        runCurrent()
        assertTrue(asked)
        assertEquals(emptyList(), store.state.value.extras)
        gate.complete(Unit)
        runCurrent()
        assertEquals(1, store.state.value.extras.size)
    }

    @Test
    fun `a movie cards related titles reach the page while the item loads and it shows them once ready`() = runTest {
        val gate = CompletableDeferred<Unit>()
        backend.detail = { _, _ ->
            gate.await()
            ItemWithOnDeck(item("m", MediaKind.MOVIE), null)
        }
        backend.relatedOf = { listOf(MediaHub("similar", "More Like This", "mixed", listOf(item("other", MediaKind.MOVIE)))) }
        val store = store("m", seed = item("m", MediaKind.MOVIE))
        runCurrent()
        assertEquals(listOf("similar"), store.state.value.related.map { it.id })
        assertFalse(store.state.value.ready)
        gate.complete(Unit)
        runCurrent()
        assertEquals(listOf("similar"), store.state.value.related.map { it.id })
        assertTrue(store.state.value.ready)
    }

    @Test
    fun `a failed fetch drops the related titles that came in while it ran`() = runTest {
        val gate = CompletableDeferred<Unit>()
        backend.detail = { _, _ ->
            gate.await()
            error("offline")
        }
        backend.relatedOf = { listOf(MediaHub("similar", "More Like This", "mixed", listOf(item("other", MediaKind.MOVIE)))) }
        val store = store("m", seed = item("m", MediaKind.MOVIE))
        runCurrent()
        assertEquals(1, store.state.value.related.size)
        gate.complete(Unit)
        runCurrent()
        assertEquals(emptyList(), store.state.value.related)
        assertTrue(store.state.value.ready)
    }

    @Test
    fun `the facts leave the quality to the track status while it is probed and once it shows`() = runTest {
        backend.detail = { _, _ -> ItemWithOnDeck(item("m", MediaKind.MOVIE) { copy(mediaVersions = listOf(MediaVersion("a", videoResolution = "1080"))) }, null) }
        val gate = CompletableDeferred<Unit>()
        previewTracks = { item, _ ->
            gate.await()
            TrackStatusUi(listOf("1080p"), item.id, null, "Off", null)
        }
        val store = store("m")
        runCurrent()
        assertTrue(store.state.value.tracksLoading)
        assertEquals(emptyList(), store.state.value.hero!!.qualityLabels)
        gate.complete(Unit)
        runCurrent()
        assertEquals(listOf("1080p"), store.state.value.tracks?.video)
        assertEquals(emptyList(), store.state.value.hero!!.qualityLabels)
    }

    @Test
    fun `a focused episode without a summary shows the shows but a spoiler none`() = runTest {
        scriptShow()
        backend.detail = { _, _ -> ItemWithOnDeck(show.copy(summary = "Show summary"), null) }
        val plain = store("show", tv = true)
        runCurrent()
        plain.focusEpisode("s1e1")
        assertEquals("Show summary", plain.state.value.hero!!.summary)
        val store = store("show", tv = true, extra = { DetailDeps(it.client, it.watchActions, it.watchState, it.watchEvents, it.deletions, it.play, { CardOptions(hideSpoilers = true) }, true) })
        runCurrent()
        store.focusEpisode("s1e1")
        assertNull(store.state.value.hero!!.summary)
    }

    @Test
    fun `with spoilers hidden only an unwatched episode thumbnail blurs`() = runTest {
        scriptShow(watched = 1)
        val hidden = store("show", options = CardOptions(hideSpoilers = true))
        runCurrent()
        assertEquals(listOf(false, true, true), hidden.state.value.episodes!!.rows.map { it.blurThumb })
        val shown = store("show")
        runCurrent()
        assertEquals(listOf(false, false, false), shown.state.value.episodes!!.rows.map { it.blurThumb })
    }

    @Test
    fun `an offline show lists its downloaded seasons and episodes without the server`() = runTest {
        val downloaded = episodes(s1, 2) + episodes(s2, 1)
        offlineSource = object : OfflineDetailSource {
            override suspend fun metadata(serverId: ServerId, itemId: String) = show
            override fun seasons(show: MediaItem) = listOf(s1, s2)
            override fun episodes(show: MediaItem) = downloaded.reversed()
            override suspend fun onDeck(show: MediaItem) = downloaded[2]
            override fun artwork(serverId: ServerId, path: String?) = path?.let { "/files/$it" }
            override suspend fun downloadedVersion(item: MediaItem) = DownloadedVersion(mediaIndex = 1, mediaSourceId = "b").takeIf { item.id == "s2e1" }
        }
        val store = store("show", offline = true)
        runCurrent()
        val state = store.state.value
        assertEquals(1, state.selectedSeason)
        assertEquals(listOf("s2e1"), state.episodes!!.rows.map { it.id })
        assertTrue(!state.actions.more && state.download == null)
        store.selectSeason(0)
        runCurrent()
        assertEquals(listOf("s1e1", "s1e2"), store.state.value.episodes!!.rows.map { it.id })
        store.play()
        assertTrue((plays.single() as PlayRequest.Item).offline)
        assertTrue(backend.calls.none { it.startsWith("fetch") })
    }

    @Test
    fun `an offline episode row has its menu and marks that one episode watched`() = runTest {
        val downloaded = episodes(s1, 2)
        offlineSource = object : OfflineDetailSource {
            override suspend fun metadata(serverId: ServerId, itemId: String) = show
            override fun seasons(show: MediaItem) = listOf(s1)
            override fun episodes(show: MediaItem) = downloaded
            override suspend fun onDeck(show: MediaItem) = null
            override fun artwork(serverId: ServerId, path: String?) = null
            override suspend fun downloadedVersion(item: MediaItem) = null
        }
        val store = store("show", offline = true)
        runCurrent()
        actions.setWatched(store.episodeItem("s1e2")!!, true)
        runCurrent()
        assertEquals(listOf(false, true), store.state.value.episodes!!.rows.map { it.watched })
        assertTrue(backend.calls.none { it.startsWith("mark") })
    }

    /** An offline show with every image kind; [stored] are the paths whose files are on disk, at `/files<path>`. */
    private fun TestScope.offlineArtworkShow(stored: Set<String>): MediaDetailStore {
        val artShow = show.copy(thumbPath = "/show/poster", clearLogoPath = "/show/logo", backdropPaths = listOf("/show/backdrop"), artPath = "/show/art")
        val seasons = listOf(s1.copy(thumbPath = "/s1/poster"), s2.copy(thumbPath = "/s2/poster"))
        val downloaded = episodes(seasons[0], 2).map { it.copy(thumbPath = "/${it.id}/thumb") }
        offlineSource = object : OfflineDetailSource {
            override suspend fun metadata(serverId: ServerId, itemId: String) = artShow
            override fun seasons(show: MediaItem) = seasons
            override fun episodes(show: MediaItem) = downloaded
            override suspend fun onDeck(show: MediaItem) = null
            override fun artwork(serverId: ServerId, path: String?) = path?.takeIf { it in stored }?.let { "/files$it" }
            override suspend fun downloadedVersion(item: MediaItem) = null
        }
        return store("show", offline = true).also { runCurrent() }
    }

    @Test
    fun `an offline detail draws its hero logo season posters and episode thumbs from the downloaded files`() = runTest {
        val state = offlineArtworkShow(setOf("/show/poster", "/show/logo", "/show/backdrop", "/show/art", "/s1/poster", "/s2/poster", "/s1e1/thumb", "/s1e2/thumb")).state.value
        assertEquals(listOf("/files/show/backdrop", "/files/show/art"), state.hero!!.backdrops.map { it.path })
        assertEquals("/files/show/logo", state.hero!!.logo?.path)
        assertEquals("/files/show/poster", state.hero!!.poster?.path)
        assertEquals(listOf("/files/s1/poster", "/files/s2/poster"), state.seasons.map { it.poster?.path })
        assertEquals(listOf("/files/s1e1/thumb", "/files/s1e2/thumb"), state.episodes!!.rows.map { it.thumb?.path })
        assertTrue(backend.calls.none { it.startsWith("fetch") })
    }

    @Test
    fun `an offline image whose file is missing draws the placeholder and the backdrop falls back to the stored art`() = runTest {
        val state = offlineArtworkShow(setOf("/show/art", "/s2/poster", "/s1e2/thumb")).state.value
        assertEquals(listOf("/files/show/art"), state.hero!!.backdrops.map { it.path })
        assertNull(state.hero!!.logo)
        assertNull(state.hero!!.poster)
        assertEquals(listOf(null, "/files/s2/poster"), state.seasons.map { it.poster?.path })
        assertEquals(listOf(null, "/files/s1e2/thumb"), state.episodes!!.rows.map { it.thumb?.path })
    }

    @Test
    fun `cast members without a name are skipped and the rest open their own screens`() = runTest {
        val roles = listOf(MediaRole("a", "Ann"), MediaRole("b", " "), MediaRole("c", ""), MediaRole("d", "Dee"))
        backend.detail = { _, _ -> ItemWithOnDeck(item("m", MediaKind.MOVIE) { copy(roles = roles) }, null) }
        val store = store("m")
        runCurrent()
        assertEquals(listOf("Ann", "Dee"), store.state.value.cast.map { it.name })
        assertEquals("d", store.castRoute(1)?.personId)
    }

    @Test
    fun `shuffle offline says it needs the server`() = runTest {
        offlineSource = object : OfflineDetailSource {
            override suspend fun metadata(serverId: ServerId, itemId: String) = show
            override fun seasons(show: MediaItem) = emptyList<MediaItem>()
            override fun episodes(show: MediaItem) = emptyList<MediaItem>()
            override suspend fun onDeck(show: MediaItem) = null
            override fun artwork(serverId: ServerId, path: String?) = null
            override suspend fun downloadedVersion(item: MediaItem) = null
        }
        val store = store("show", offline = true)
        runCurrent()
        store.shuffle()
        runCurrent()
        assertEquals(T.mediaMenu.shuffleNotAvailableOffline, store.state.value.message)
        store.messageShown()
        assertNull(store.state.value.message)
    }

    @Test
    fun `shuffle shows its loading title until the queue settles and reports an empty queue`() = runTest {
        scriptShow()
        val gate = CompletableDeferred<Unit>()
        val shuffled = mutableListOf<String>()
        val store = store("show", extra = { deps ->
            DetailDeps(
                deps.client, deps.watchActions, deps.watchState, deps.watchEvents, deps.deletions, deps.play, deps.cardOptions, deps.tv,
                shuffle = { item ->
                    shuffled += item.id
                    PlayQueueLaunch("Shuffle", backgroundScope) {
                        gate.await()
                        PlayQueueResult.Empty
                    }
                },
            )
        })
        runCurrent()
        assertTrue(store.state.value.actions.shuffle)
        store.shuffle()
        runCurrent()
        assertEquals("Shuffle", store.state.value.launching)
        gate.complete(Unit)
        runCurrent()
        assertNull(store.state.value.launching)
        assertEquals(listOf("show"), shuffled)
        assertEquals(T.messages.failedToCreatePlayQueueNoItems, store.state.value.message)
    }

    @Test
    fun `a title deleted while its page is covered leaves when the page shows again`() = runTest {
        backend.detail = { _, _ -> ItemWithOnDeck(item("m", MediaKind.MOVIE), null) }
        val store = store("m")
        runCurrent()
        assertFalse(store.state.value.gone)
        // Nothing collects the store while another screen covers the page.
        deletions.notifyDeletedItem(item("m", MediaKind.MOVIE))
        runCurrent()
        assertTrue(store.state.value.gone)
    }

    /** s1 holds [count] episodes, served [AppendPager.PAGE_SIZE] at a time; s2 three. */
    private fun scriptPagedShow(count: Int, requests: MutableList<Int>) {
        scriptShow()
        val long = episodes(s1, count)
        backend.childrenPage = { id, start, size ->
            if (id == "s1") {
                val from = start ?: 0
                requests.add(from)
                LibraryPage(long.drop(from).take(size ?: long.size), long.size, from)
            } else {
                LibraryPage(episodes(s2, 3), 3, 0)
            }
        }
    }

    @Test
    fun `a deep linked episode is paged to and then focused`() = runTest {
        val requests = mutableListOf<Int>()
        scriptPagedShow(450, requests)
        val store = store("show", seasonId = "s1", episodeId = "s1e420")
        runCurrent()
        assertEquals(listOf(0, 200, 400), requests)
        assertEquals(450, store.state.value.episodes!!.rows.size)
        assertEquals(DetailInitialFocus(episodeId = "s1e420"), store.state.value.initialFocus)
    }

    @Test
    fun `a deep linked episode that never shows falls back to its season tab`() = runTest {
        val requests = mutableListOf<Int>()
        scriptPagedShow(250, requests)
        val store = store("show", seasonId = "s1", episodeId = "gone")
        runCurrent()
        assertEquals(listOf(0, 200), requests)
        assertEquals(DetailInitialFocus(seasonIndex = 0), store.state.value.initialFocus)
        assertNull(store(id = "show").also { runCurrent() }.state.value.initialFocus)
    }

    @Test
    fun `season chips show a check once watched and the watched share while partly watched`() = runTest {
        scriptShow(watched = 1)
        val partly = s1.copy(leafCount = 3, viewedLeafCount = 1)
        val done = s2.copy(leafCount = 2, viewedLeafCount = 2)
        val unstarted = item("s3", MediaKind.SEASON) { copy(index = 3, parentId = "show", leafCount = 2, viewedLeafCount = 0) }
        val uncounted = item("s4", MediaKind.SEASON) { copy(index = 4, parentId = "show") }
        backend.children = { listOf(partly, done, unstarted, uncounted) }
        val shown = store("show")
        runCurrent()
        assertTrue(shown.state.value.episodes!!.rows.first().watched)
        assertEquals(listOf(false, true, false, false), shown.state.value.seasons.map { it.watched })
        assertEquals(listOf(1.0 / 3, null, null, null), shown.state.value.seasons.map { it.progress })
        val hidden = store("show", options = CardOptions(showWatchedIndicators = false))
        runCurrent()
        assertTrue(hidden.state.value.episodes!!.rows.none { it.watched })
        assertTrue(hidden.state.value.seasons.none { it.watched || it.progress != null }, "${hidden.state.value.seasons}")
    }

    @Test
    fun `an episode marked watched or unwatched moves its season chip`() = runTest {
        scriptShow()
        var serverSeasons = listOf(s1.copy(leafCount = 3, viewedLeafCount = 0), s2)
        backend.children = { serverSeasons }
        val store = store("show")
        runCurrent()
        assertNull(store.state.value.seasons.first().progress)
        val (first, second, third) = episodes(s1, 3)

        serverSeasons = listOf(s1.copy(leafCount = 3, viewedLeafCount = 1), s2)
        notifier.notifyWatched(first)
        runCurrent()
        assertEquals(1.0 / 3, store.state.value.seasons.first().progress)

        serverSeasons = listOf(s1.copy(leafCount = 3, viewedLeafCount = 3), s2)
        notifier.notifyWatched(second)
        notifier.notifyWatched(third)
        runCurrent()
        assertTrue(store.state.value.seasons.first().watched)
        assertNull(store.state.value.seasons.first().progress)

        serverSeasons = listOf(s1.copy(leafCount = 3, viewedLeafCount = 2), s2)
        notifier.notifyWatched(third, isNowWatched = false)
        runCurrent()
        assertFalse(store.state.value.seasons.first().watched)
        assertEquals(2.0 / 3, store.state.value.seasons.first().progress)
        assertEquals(0, store.state.value.selectedSeason)
    }

    @Test
    fun `episode rows follow their downloads`() = runTest {
        scriptShow()
        val ticks = MutableStateFlow(0)
        val statuses = HashMap<String, EpisodeDownloadUi>()
        downloads = object : DetailDownloads {
            override fun spec(item: MediaItem) = flowOf(DownloadButtonSpec(DownloadButtonIcon.entries.first(), null))
            override val changes = ticks
            override fun episodeStatus(episode: MediaItem) = statuses[episode.id]
            override suspend fun press(item: MediaItem, client: com.edde746.plezy.backend.MediaBackend, fallbackVersions: List<MediaVersion>?) = null
        }
        val store = store("show")
        runCurrent()
        assertTrue(store.state.value.episodes!!.rows.all { it.download == null })
        statuses["s1e2"] = EpisodeDownloadUi(DownloadedMediaStatus.DOWNLOADING, 0.4f, queueing = false)
        ticks.value = 1
        runCurrent()
        assertEquals(0.4f, store.state.value.episodes!!.rows[1].download?.progress)
        assertNull(store.state.value.episodes!!.rows[0].download)
    }

    @Test
    fun `a downloaded episode shows its resume progress`() = runTest {
        val halfway = episodes(s1, 1).single().copy(durationMs = 40 * 60_000, viewOffsetMs = 20 * 60_000)
        offlineSource = object : OfflineDetailSource {
            override suspend fun metadata(serverId: ServerId, itemId: String) = show
            override fun seasons(show: MediaItem) = listOf(s1)
            override fun episodes(show: MediaItem) = listOf(halfway)
            override suspend fun onDeck(show: MediaItem) = null
            override fun artwork(serverId: ServerId, path: String?) = null
            override suspend fun downloadedVersion(item: MediaItem) = null
        }
        val store = store("show", offline = true)
        runCurrent()
        assertEquals(0.5, store.state.value.episodes!!.rows.single().progress)
    }

    @Test
    fun `a route naming a season opens its show with that season selected`() = runTest {
        scriptShow()
        val fetched = mutableListOf<String>()
        backend.detail = { id, ready ->
            fetched += id
            val found = if (id == "s2") s2 else show
            ready?.invoke(found)
            ItemWithOnDeck(found, null)
        }
        val store = store("s2", seed = s2)
        runCurrent()
        val state = store.state.value
        assertEquals(MediaKind.SHOW, state.kind)
        assertEquals("show", state.hero!!.title)
        assertEquals(1, state.selectedSeason)
        assertEquals(listOf("s2e1", "s2e2", "s2e3"), state.episodes!!.rows.map { it.id })
        assertEquals(listOf("s2", "show"), fetched)
        assertEquals("show", store.seriesId())
    }

    @Test
    fun `an episode naming only its season opens the show at that season and episode`() = runTest {
        scriptShow()
        backend.detail = { id, _ -> ItemWithOnDeck(if (id == "s2") s2 else show, null) }
        val store = store("s2", episodeId = "s2e2")
        runCurrent()
        val state = store.state.value
        assertEquals(MediaKind.SHOW, state.kind)
        assertEquals(1, state.selectedSeason)
        assertEquals("s2e2", state.initialFocus?.episodeId)
    }

    @Test
    fun `a downloaded season opens its downloaded show at that season`() = runTest {
        val rows = episodes(s1, 1) + episodes(s2, 2)
        offlineSource = object : OfflineDetailSource {
            override suspend fun metadata(serverId: ServerId, itemId: String) = if (itemId == "s2") s2 else show
            override fun seasons(show: MediaItem) = listOf(s1, s2)
            override fun episodes(show: MediaItem) = rows
            override suspend fun onDeck(show: MediaItem) = null
            override fun artwork(serverId: ServerId, path: String?) = null
            override suspend fun downloadedVersion(item: MediaItem) = null
        }
        val store = store("s2", offline = true)
        runCurrent()
        val state = store.state.value
        assertEquals(MediaKind.SHOW, state.kind)
        assertEquals(1, state.selectedSeason)
        assertEquals(listOf("s2e1", "s2e2"), state.episodes!!.rows.map { it.id })
    }

    @Test
    fun `a jellyfin show of one season lists its episodes without season tabs`() = runTest {
        backend.detail = { _, _ -> ItemWithOnDeck(show, null) }
        backend.children = { listOf(s1) }
        backend.childrenPage = { _, _, _ ->
            val rows = episodes(s1, 2)
            LibraryPage(rows, rows.size, 0)
        }
        val single = store("show")
        runCurrent()
        assertTrue(single.state.value.seasons.isEmpty())
        assertEquals(listOf("s1e1", "s1e2"), single.state.value.episodes!!.rows.map { it.id })

        scriptShow()
        val two = store("show")
        runCurrent()
        assertEquals(2, two.state.value.seasons.size)
    }

    @Test
    fun `on tv the seasons beside the selected one load their first page and elsewhere only the selected one does`() = runTest {
        val s3 = item("s3", MediaKind.SEASON) { copy(index = 3, parentId = "show") }
        val requested = mutableListOf<String>()
        backend.detail = { _, _ -> ItemWithOnDeck(show, null) }
        backend.children = { listOf(s1, s2, s3) }
        backend.childrenPage = { id, _, _ ->
            requested += id
            val rows = episodes(listOf(s1, s2, s3).single { it.id == id }, 2)
            LibraryPage(rows, rows.size, 0)
        }
        store("show", seasonId = "s2", tv = true)
        runCurrent()
        assertEquals(setOf("s1", "s2", "s3"), requested.toSet())

        requested.clear()
        store("show", seasonId = "s2")
        runCurrent()
        assertEquals(listOf("s2"), requested)
    }

    @Test
    fun `the hero drops the ratings region and shows an edition only for plex`() = runTest {
        val movie = item("m", MediaKind.MOVIE) { copy(contentRating = "us/PG-13", durationMs = 5_400_000, year = 1999, editionTitle = "Director's Cut") }
        backend.detail = { _, _ -> ItemWithOnDeck(movie, null) }
        val jellyfin = store("m")
        runCurrent()
        val hero = jellyfin.state.value.hero!!
        assertEquals(listOf("1999", "PG-13", formatDurationTextual(5_400_000L)), hero.metadata)
        assertNull(hero.edition)

        backend.detail = { _, _ -> ItemWithOnDeck(movie.copy(backend = BackendKind.PLEX), null) }
        val plex = store("m")
        runCurrent()
        assertEquals("Director's Cut", plex.state.value.hero!!.edition)
    }

    @Test
    fun `a season mark fetches the show and its seasons again and keeps the selected season`() = runTest {
        scriptShow()
        var detailFetches = 0
        var seasonFetches = 0
        backend.detail = { _, _ ->
            detailFetches++
            ItemWithOnDeck(if (detailFetches > 1) show.copy(title = "Fresh") else show, null)
        }
        backend.children = {
            seasonFetches++
            listOf(s1, s2)
        }
        val store = store("show", seasonId = "s2")
        runCurrent()

        notifier.notifyWatched(s1)
        runCurrent()
        assertEquals(2, detailFetches)
        assertEquals(2, seasonFetches)
        assertEquals("Fresh", store.state.value.hero!!.title)
        assertEquals(1, store.state.value.selectedSeason)
    }

    @Test
    fun `a season marked watched elsewhere clears its episodes progress`() = runTest {
        backend.detail = { _, _ -> ItemWithOnDeck(show, null) }
        backend.children = { listOf(s1, s2) }
        backend.childrenPage = { id, _, _ ->
            val season = if (id == "s1") s1 else s2
            val rows = episodes(season, 2).map { it.copy(durationMs = 40 * 60_000, viewOffsetMs = 10 * 60_000) }
            LibraryPage(rows, rows.size, 0)
        }
        val store = store("show")
        runCurrent()
        assertEquals(0.25, store.state.value.episodes!!.rows.first().progress)

        notifier.notifyWatched(s1)
        runCurrent()
        val rows = store.state.value.episodes!!.rows
        assertTrue(rows.all { it.watched && (it.progress ?: 0.0) == 0.0 }, "$rows")
    }

    @Test
    fun `a movie the server marked watched when its playback stopped shows watched not resume`() = runTest {
        // The server turns a short item watched wherever it stops; the playback's last report said 44 s of 60.
        val movie = item("m", MediaKind.MOVIE) { copy(durationMs = 60_000) }
        var server = movie
        var reads = 0
        backend.detail = { _, _ ->
            reads++
            ItemWithOnDeck(server, null)
        }
        val store = store("m")
        runCurrent()

        playing = movie.globalKey
        notifier.notifyProgress(movie, viewOffset = 30_000, duration = 60_000, serverAcknowledged = true)
        runCurrent()
        assertTrue(store.state.value.actions.resume)
        assertEquals(1, reads, "nothing is read again while it plays")

        playing = null
        server = movie.copy(viewCount = 1)
        notifier.notifyProgress(movie, viewOffset = 44_000, duration = 60_000, serverAcknowledged = true)
        runCurrent()
        assertEquals(2, reads)
        assertFalse(store.state.value.actions.resume)
        assertTrue(store.state.value.actions.watched)
    }

    @Test
    fun `back from playing an episode its rows and seasons show what the server holds`() = runTest {
        val (first, second, third) = episodes(s1, 3).map { it.copy(durationMs = 90_000) }
        var serverRows = listOf(first.copy(viewCount = 1), second, third.copy(viewCount = 1))
        val season1 = s1.copy(leafCount = 3, viewedLeafCount = 2)
        var serverSeasons = listOf(season1, s2.copy(leafCount = 2, viewedLeafCount = 0))
        var reads = 0
        backend.detail = { _, _ -> ItemWithOnDeck(show, null) }
        backend.children = { serverSeasons }
        backend.childrenPage = { id, _, _ ->
            val rows = if (id == "s1") serverRows.also { reads++ } else episodes(s2, 2)
            LibraryPage(rows, rows.size, 0)
        }
        val store = store("show")
        runCurrent()

        playing = third.globalKey
        notifier.notifyProgress(third, viewOffset = 20_000, duration = 90_000, serverAcknowledged = true)
        runCurrent()
        assertEquals(1, reads, "nothing is read again while the episode plays")

        // The server kept Episode 3 watched (it is short); Episode 2 and Season 2 changed elsewhere meanwhile.
        serverRows = listOf(serverRows[0], second.copy(viewOffsetMs = 45_000), serverRows[2])
        serverSeasons = listOf(season1, s2.copy(leafCount = 2, viewedLeafCount = 2))
        playing = null
        notifier.notifyProgress(third, viewOffset = 20_000, duration = 90_000, serverAcknowledged = true)
        runCurrent()
        val rows = store.state.value.episodes!!.rows
        assertTrue(rows[2].watched && rows[2].progress == null, "$rows")
        assertEquals(0.5, rows[1].progress)
        assertTrue(store.state.value.seasons[1].watched)
        assertEquals(0, store.state.value.selectedSeason)
    }

    @Test
    fun `a plex show asks for its seasons and its library prefs together and failed prefs still list the seasons`() = runTest {
        val prefsGate = CompletableDeferred<Unit>()
        val asked = mutableListOf<String>()
        otherClient = testPlexClient({ request ->
            val path = request.url.encodedPath
            asked += path
            when (path) {
                "/library/metadata/show" -> jsonResponse(
                    """{"MediaContainer":{"Metadata":[{"ratingKey":"show","key":"/library/metadata/show/children","type":"show","title":"Show",
                      "librarySectionID":4,"librarySectionTitle":"TV","childCount":2}]}}""",
                )
                "/library/metadata/show/children" -> jsonResponse(
                    """{"MediaContainer":{"size":2,"Metadata":[{"ratingKey":"s1","type":"season","title":"Season 1","index":1,"parentRatingKey":"show"},
                      {"ratingKey":"s2","type":"season","title":"Season 2","index":2,"parentRatingKey":"show"}]}}""",
                )
                "/library/sections/4/prefs" -> {
                    prefsGate.await()
                    jsonResponse("{}", status = 500)
                }
                else -> jsonResponse("""{"MediaContainer":{}}""")
            }
        })
        val store = store("show")
        runCurrent()
        assertTrue("/library/metadata/show/children" in asked, "$asked")
        assertTrue("/library/sections/4/prefs" in asked, "$asked")
        assertTrue(store.state.value.seasons.isEmpty(), "the seasons wait for the prefs")

        prefsGate.complete(Unit)
        advanceTimeBy(1.minutes)
        runCurrent()
        assertEquals(2, store.state.value.seasons.size)
        val season = store.seasonItem("s1")!!
        assertEquals("server-1", season.serverId)
        assertEquals("Test Server", season.serverName)
        assertEquals("4", season.libraryId)
        assertEquals("TV", season.libraryTitle)
    }

    @Test
    fun `seasons that fail to load say so and a retry loads them`() = runTest {
        scriptShow()
        var fail = true
        backend.children = { if (fail) error("down") else listOf(s1, s2) }
        val store = store("show")
        runCurrent()
        assertEquals(SectionLoad.ERROR, store.state.value.seasonsLoad)
        assertTrue(store.state.value.seasons.isEmpty())

        fail = false
        store.retrySeasons()
        runCurrent()
        assertEquals(SectionLoad.CONTENT, store.state.value.seasonsLoad)
        assertEquals(2, store.state.value.seasons.size)
        assertEquals(listOf("s1e1", "s1e2", "s1e3"), store.state.value.episodes!!.rows.map { it.id })
    }
}

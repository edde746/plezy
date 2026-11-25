package com.edde746.plezy.downloads

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.COMPLETED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.FAILED
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.OfflineModeSource
import com.edde746.plezy.servers.PlexProfileScopeId
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.yield
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class DownloadsControllerLibraryTest {
    private var harness: ControllerHarness? = null

    @AfterTest
    fun close() {
        harness?.close()
    }

    private suspend fun harness(
        dms: DmsHarness? = null,
        managerOf: ((FakeDownloadServers) -> DownloadManagerService)? = null,
        retryOnManager: (suspend (String, MediaBackend) -> Unit)? = null,
        configure: ControllerHarness.() -> Unit = {},
    ) = ControllerHarness(dms ?: DmsHarness.create(), managerOf = managerOf, retryOnManager = retryOnManager)
        .also { harness = it; it.configure(); it.controller.ensureInitialized() }

    private fun progress(key: String, status: DownloadedMediaStatus = COMPLETED, at: Long? = null, total: Long = 0) =
        DownloadProgress(key, status, totalBytes = total, downloadedAt = at)

    private fun completed(vararg keys: String) = keys.associateWith { progress(it) }

    private fun episode(
        id: String,
        showId: String = "show-1",
        seasonId: String = "season-1",
        seasonIndex: Int = 1,
        index: Int = 1,
        viewCount: Int = 0,
        libraryId: String? = null,
        libraryTitle: String? = null,
        serverName: String? = null,
    ) = testMediaItem(
        id, MediaKind.EPISODE, "srv", title = "Episode $id", parentId = seasonId, parentTitle = "Season $seasonIndex", parentIndex = seasonIndex,
        index = index, grandparentId = showId, grandparentTitle = "Show $showId",
    ).copy(viewCount = viewCount, libraryId = libraryId, libraryTitle = libraryTitle, serverName = serverName)

    private fun item(id: String, kind: MediaKind, backend: BackendKind = BackendKind.PLEX, title: String? = "Item $id") =
        testMediaItem(id, kind, "srv", backend, title = title)

    // Grouping and library identity

    @Test
    fun downloadedEpisodesListsOnlyOwnedCompletedEpisodes() = runTest {
        val h = harness()
        val c = h.controller
        h.seed(
            downloads = completed("srv:e1", "srv:m1", "srv:e3") + ("srv:e2" to progress("srv:e2", DownloadedMediaStatus.DOWNLOADING)),
            metadata = mapOf("srv:e1" to episode("e1"), "srv:e2" to episode("e2"), "srv:m1" to item("m1", MediaKind.MOVIE), "srv:e3" to episode("e3")),
            owned = setOf("srv:e1", "srv:e2", "srv:m1"),
        )

        assertEquals(listOf("e1"), c.downloadedEpisodes.map { it.id })
    }

    @Test
    fun downloadedEpisodesInheritMissingLibraryIdentityFromTheStoredShow() = runTest {
        val h = harness()
        val c = h.controller
        h.seed(
            downloads = completed("srv:e1"),
            metadata = mapOf("srv:e1" to episode("e1"), "srv:show-1" to item("show-1", MediaKind.SHOW).copy(libraryId = "lib-9", libraryTitle = "Shows")),
        )

        val ep = c.downloadedEpisodes.single()
        assertEquals("lib-9", ep.libraryId)
        assertEquals("Shows", ep.libraryTitle)
    }

    @Test
    fun downloadedTracksInheritMissingLibraryIdentityFromTheStoredAlbum() = runTest {
        val h = harness()
        val c = h.controller
        h.seed(
            downloads = completed("srv:t1"),
            metadata = mapOf(
                "srv:t1" to testMediaItem("t1", MediaKind.TRACK, "srv", BackendKind.JELLYFIN, title = "Track", parentId = "album-1"),
                "srv:album-1" to item("album-1", MediaKind.ALBUM, BackendKind.JELLYFIN).copy(libraryId = "lib-m", libraryTitle = "Music"),
            ),
        )

        val track = c.downloadedTracks.single()
        assertEquals("lib-m", track.libraryId)
        assertEquals("Music", track.libraryTitle)
    }

    @Test
    fun downloadedSeasonsGroupEpisodesAcrossShowsWithCountsAndLibrary() = runTest {
        val h = harness()
        val c = h.controller
        h.seed(
            downloads = completed("srv:e1", "srv:e2", "srv:e3"),
            metadata = mapOf(
                "srv:e1" to episode("e1", viewCount = 1, libraryId = "lib-9", libraryTitle = "Shows"),
                "srv:e2" to episode("e2", index = 2, libraryId = "lib-9", libraryTitle = "Shows"),
                "srv:e3" to episode("e3", seasonId = "season-2", seasonIndex = 2),
            ),
        )

        val seasons = c.downloadedSeasons
        assertEquals(listOf(1, 2), seasons.map { it.index })
        val first = seasons[0]
        assertTrue(first.isSeason)
        assertEquals(2, first.leafCount)
        assertEquals(1, first.viewedLeafCount)
        assertEquals("lib-9", first.libraryId)
        assertEquals("Shows", first.libraryTitle)
        assertEquals(1, seasons[1].leafCount)
        assertEquals(0, seasons[1].viewedLeafCount)
    }

    @Test
    fun syntheticSeasonsCarryTheShowTitle() = runTest {
        val h = harness()
        h.seed(downloads = completed("srv:e1"), metadata = mapOf("srv:e1" to episode("e1")))
        val c = h.controller

        // No stored season row: the made-up season still names its show.
        assertEquals("Show show-1", c.downloadedSeasons.single().parentTitle)
    }

    @Test
    fun downloadedAlbumsDeriveLibraryIdentityFromStampedTracks() = runTest {
        val h = harness()
        val c = h.controller
        fun track(id: String) = testMediaItem(
            id, MediaKind.TRACK, "srv", BackendKind.JELLYFIN, title = id, parentId = "album-1", parentTitle = "Album", grandparentId = "artist-1",
            grandparentTitle = "Artist",
        ).copy(libraryId = "lib-m", libraryTitle = "Music")
        h.seed(
            downloads = completed("srv:t1", "srv:t2"),
            // A MediaBrowser album fetched as a parent carries no library.
            metadata = mapOf("srv:album-1" to item("album-1", MediaKind.ALBUM, BackendKind.JELLYFIN, title = "Album"), "srv:t1" to track("t1"), "srv:t2" to track("t2")),
        )

        val album = c.downloadedAlbums.single()
        assertEquals("lib-m", album.libraryId)
        assertEquals("Music", album.libraryTitle)
    }

    @Test
    fun downloadSortExtrasAggregateShowsAndSeasonsOverTheirOwnLeaves() = runTest {
        val h = harness()
        val c = h.controller
        h.seed(
            downloads = mapOf(
                "srv:e1" to progress("srv:e1", at = 100, total = 10),
                "srv:e2" to progress("srv:e2", at = 300, total = 20),
                "srv:e3" to progress("srv:e3", at = 200, total = 30),
                "srv:m1" to progress("srv:m1", at = 50, total = 99),
            ),
            metadata = mapOf(
                "srv:e1" to episode("e1", index = 1),
                "srv:e2" to episode("e2", index = 2),
                "srv:e3" to episode("e3", seasonId = "season-2", seasonIndex = 2),
                "srv:m1" to item("m1", MediaKind.MOVIE),
            ),
        )

        val extras = c.downloadSortExtras(c.downloadedShows + c.downloadedSeasons + c.downloadedMovies)

        assertEquals(300L to 60L, extras["srv:show-1"]?.let { it.downloadedAt to it.totalBytes })
        assertEquals(300L to 30L, extras["srv:season-1"]?.let { it.downloadedAt to it.totalBytes })
        assertEquals(200L to 30L, extras["srv:season-2"]?.let { it.downloadedAt to it.totalBytes })
        assertEquals(50L to 99L, extras["srv:m1"]?.let { it.downloadedAt to it.totalBytes })
    }

    @Test
    fun downloadedSeasonsForShowPreferTheStoredSeasonAndScopeToTheShow() = runTest {
        val h = harness()
        val c = h.controller
        h.seed(
            downloads = completed("srv:e1", "srv:e2", "srv:other"),
            metadata = mapOf(
                "srv:e1" to episode("e1", viewCount = 1),
                "srv:e2" to episode("e2", index = 2),
                "srv:other" to episode("other", showId = "show-2"),
                "srv:season-1" to testMediaItem("season-1", MediaKind.SEASON, "srv", title = "Stored Season Title", index = 1, parentId = "show-1")
                    .copy(leafCount = 24, viewedLeafCount = 24),
            ),
        )

        val season = c.downloadedSeasonsForShow("srv:show-1").single()
        assertEquals("Stored Season Title", season.title)
        // Counts are the downloaded episodes', not the stored server totals.
        assertEquals(2, season.leafCount)
        assertEquals(1, season.viewedLeafCount)
    }

    @Test
    fun downloadedShowsOverrideLeafCountsAndDeriveLibraryFromEpisodes() = runTest {
        val h = harness()
        val c = h.controller
        h.seed(
            downloads = completed("srv:e1", "srv:e2"),
            metadata = mapOf(
                "srv:e1" to episode("e1", viewCount = 1, libraryId = "lib-9", libraryTitle = "Shows"),
                "srv:e2" to episode("e2", index = 2, libraryId = "lib-9", libraryTitle = "Shows"),
                "srv:show-1" to item("show-1", MediaKind.SHOW, title = "Show 1").copy(leafCount = 24, viewedLeafCount = 24),
            ),
        )

        val show = c.downloadedShows.single()
        assertEquals(2, show.leafCount)
        assertEquals(1, show.viewedLeafCount)
        assertEquals("lib-9", show.libraryId)
        assertEquals("Shows", show.libraryTitle)
    }

    @Test
    fun downloadedLibrariesListDistinctLibrariesWithTheServerNameAsFallback() = runTest {
        val h = harness()
        val c = h.controller
        h.seed(
            downloads = completed("srv:e1", "srv:e2", "srv:m1", "srv:e3"),
            metadata = mapOf(
                "srv:e1" to episode("e1", libraryId = "lib-9", libraryTitle = "Shows"),
                "srv:e2" to episode("e2", index = 2, libraryId = "lib-9", libraryTitle = "Shows"),
                "srv:m1" to item("m1", MediaKind.MOVIE).copy(libraryId = "lib-3", libraryTitle = "Movies"),
                // Downloaded before library stamping: named after its server.
                "srv:e3" to episode("e3", showId = "show-2", serverName = "My Plex"),
            ),
        )

        assertEquals(
            setOf(Triple("srv", "lib-3", "Movies"), Triple("srv", "lib-9", "Shows"), Triple("srv", null, "My Plex")),
            c.downloadedLibraries.map { Triple(it.serverId, it.libraryId, it.title) }.toSet(),
        )
        assertEquals(3, c.downloadedLibraries.size)
    }

    private suspend fun stampedHydration(rowLibrary: Pair<String, String>, vararg pinnedLibrary: Pair<String, Any?>): ControllerHarness {
        val key = "srv:movie-1"
        val dms = DmsHarness.create()
        dms.connection("srv", "plex")
        dms.data.insertDownload("srv", "movie-1", status = COMPLETED, libraryId = rowLibrary.first, libraryTitle = rowLibrary.second)
        dms.library.addDownloadOwner("test-profile", key)
        val scope = PlexProfileScopeId.of(ServerId("srv"), "test-profile").value
        dms.putPlexMetadata(scope, "movie-1", plexFields("ratingKey" to "movie-1", "type" to "movie", "title" to "Hydrated Movie", *pinnedLibrary))
        dms.plexCache.pinForOffline(scope, "movie-1")
        val h = harness(dms) { servers.register(FakeMediaBackend("srv")) }
        h.load()
        h.controller.refreshMetadataFromCache()
        return h
    }

    @Test
    fun hydrationMergesTheStampedLibraryIntoMetadataThatLacksIt() = runTest {
        val h = stampedHydration("lib-7" to "Movies")

        val meta = assertNotNull(h.controller.getMetadata("srv:movie-1"))
        assertEquals("Hydrated Movie", meta.title)
        assertEquals("lib-7", meta.libraryId)
        assertEquals("Movies", meta.libraryTitle)
        assertEquals("lib-7", h.controller.downloadedLibraries.single().libraryId)
    }

    @Test
    fun hydrationKeepsTheLibraryTheMetadataAlreadyHas() = runTest {
        val h = stampedHydration("lib-stale" to "Stale Library", "librarySectionID" to 42, "librarySectionTitle" to "Fresh Library")

        val meta = h.controller.getMetadata("srv:movie-1")
        assertEquals("42", meta?.libraryId)
        assertEquals("Fresh Library", meta?.libraryTitle)
    }

    /** A server that stamps a fixed library ([stampFailure] makes the stamp throw) and fails every other fetch. */
    private class StampingBackend(private val stampFailure: Exception? = null) : FakeMediaBackend("srv") {
        var stampCalls = 0

        init {
            items = { throw IllegalStateException("fetchItem is unreachable") }
        }

        override suspend fun stampLibrary(item: MediaItem): MediaItem {
            stampCalls++
            stampFailure?.let { throw it }
            return item.copy(libraryId = "lib-7", libraryTitle = "Movies")
        }

        override fun resolveDownloadArtwork(item: MediaItem) = emptyList<com.edde746.plezy.backend.DownloadArtworkSpec>()

        override suspend fun fetchCollectionMemberships(itemIds: Set<String>) = emptyList<com.edde746.plezy.model.CollectionMembership>()
    }

    private suspend fun stampingHarness(): ControllerHarness {
        val dms = DmsHarness.create()
        return harness(dms, managerOf = { servers ->
            dms.manager(clientResolver = { id, _ -> servers.client(id) }, downloader = FakeNativeDownloader(), queueProcessorOverride = {})
        })
    }

    @Test
    fun queueDownloadStampsTheLibraryThroughTheClientAndToleratesFailures() = runTest {
        val h = stampingHarness()
        val stamping = StampingBackend().apply { cacheHandle = h.dms.plexCache }

        assertEquals(1, h.controller.queueDownload(item("1", MediaKind.MOVIE, title = "Stamped"), stamping))
        val row = h.dms.library.getDownloadedMedia("srv:1")
        assertEquals("lib-7", row?.library_id)
        assertEquals("Movies", row?.library_title)
        assertEquals("lib-7", h.controller.getMetadata("srv:1")?.libraryId)

        // A client that cannot resolve the library does not block the enqueue.
        val failing = StampingBackend(IllegalStateException("no library")).apply { cacheHandle = h.dms.plexCache }
        assertEquals(1, h.controller.queueDownload(item("2", MediaKind.MOVIE, title = "Unstamped"), failing))
        val unstamped = assertNotNull(h.dms.library.getDownloadedMedia("srv:2"))
        assertNull(unstamped.library_id)
        assertNull(unstamped.library_title)
    }

    @Test
    fun queueDownloadSkipsLibraryStampingWhileOffline() = runTest {
        val h = stampingHarness()
        h.controller.setOfflineSource(object : OfflineModeSource {
            override val isOffline = MutableStateFlow(true)
        })
        val client = StampingBackend().apply { cacheHandle = h.dms.plexCache }

        assertEquals(1, h.controller.queueDownload(item("1", MediaKind.MOVIE, title = "Offline"), client))

        assertEquals(0, client.stampCalls)
        assertNull(h.dms.library.getDownloadedMedia("srv:1")?.library_id)
    }

    // Retrying failed downloads

    private class RecordingRetries {
        val retried = mutableListOf<String>()
        val failing = mutableSetOf<String>()
        var gate: CompletableDeferred<Unit>? = null

        suspend fun retry(globalKey: String, @Suppress("UNUSED_PARAMETER") client: MediaBackend) {
            retried += globalKey
            gate?.await()
            if (globalKey in failing) throw IllegalStateException("retry of $globalKey fails")
        }
    }

    private val unreachable = FakeMediaBackend("srv")

    @Test
    fun retriesOwnedFailuresInTheGivenOrderAndSkipsEverythingElse() = runTest {
        val retries = RecordingRetries()
        val h = harness(retryOnManager = retries::retry)
        val c = h.controller
        h.seed(
            downloads = mapOf(
                "srv:1" to progress("srv:1", FAILED),
                "srv:2" to progress("srv:2", COMPLETED),
                "srv:3" to progress("srv:3", FAILED),
                "offline:4" to progress("offline:4", FAILED),
                "srv:5" to progress("srv:5", FAILED),
            ),
            owned = setOf("srv:1", "srv:2", "srv:3", "offline:4"),
        )

        assertTrue(c.hasFailedDownloads)
        // srv:5 is another profile's.
        assertEquals(setOf("srv:1", "srv:3", "offline:4"), c.failedDownloadKeys.toSet())

        c.retryDownloads(listOf("srv:3", "srv:2", "offline:4", "srv:5", "srv:1")) { key -> unreachable.takeIf { key.startsWith("srv:") } }

        assertEquals(listOf("srv:3", "srv:1"), retries.retried)
    }

    @Test
    fun oneFailedRetryDoesNotStopTheRestOfTheBatch() = runTest {
        val retries = RecordingRetries().apply { failing += "srv:1" }
        val h = harness(retryOnManager = retries::retry)
        val c = h.controller
        h.seed(downloads = mapOf("srv:1" to progress("srv:1", FAILED), "srv:2" to progress("srv:2", FAILED)))

        c.retryDownloads(listOf("srv:1", "srv:2")) { unreachable }

        assertEquals(listOf("srv:1", "srv:2"), retries.retried)
    }

    @Test
    fun aRetryStillInFlightIsNotStartedAgain() = runTest {
        val retries = RecordingRetries()
        val h = harness(retryOnManager = retries::retry)
        val c = h.controller
        h.seed(downloads = mapOf("srv:1" to progress("srv:1", FAILED)))
        val gate = CompletableDeferred<Unit>().also { retries.gate = it }

        val first = async { c.retryDownload("srv:1", unreachable) }
        while (retries.retried.isEmpty()) yield()
        c.retryDownloads(listOf("srv:1")) { unreachable }
        assertEquals(listOf("srv:1"), retries.retried)

        gate.complete(Unit)
        first.await()
        // The guard releases once the first retry settles.
        c.retryDownload("srv:1", unreachable)
        assertEquals(listOf("srv:1", "srv:1"), retries.retried)
    }

    // Lifecycle

    @Test
    fun aRefreshEvictsStaleQueueingAndDeletionProgress() = runTest {
        val dms = DmsHarness.create()
        val held = CompletableDeferred<Unit>()
        // The deletion holds at its document's storage grant, its first progress out.
        val documents = DocumentTreeFake(resolveOverride = { held.await(); null })
        val h = harness(dms, managerOf = { servers ->
            dms.manager(clientResolver = { id, _ -> servers.client(id) }, downloader = FakeNativeDownloader(), safStorage = documents)
        })
        dms.putPlexMetadata("srv", "deleting", plexFields("ratingKey" to "deleting", "type" to "movie", "title" to "Deleting"))
        h.seed(downloads = mapOf("srv:deleting" to progress("srv:deleting")))
        dms.library.updateVideoFilePath("srv:deleting", "content://deleting.mkv")
        // The queueing holds at the notification permission prompt.
        h.permission.gate = held
        val queueing = async { h.controller.queueDownload(item("queueing", MediaKind.MOVIE), FakeMediaBackend("srv")) }
        val deleting = async { h.controller.deleteDownload("srv:deleting") }
        until { h.controller.isQueueing("srv:queueing") && h.controller.getDeletionProgress("srv:deleting") != null }

        h.controller.refresh()

        assertFalse(h.controller.isQueueing("srv:queueing"))
        assertNull(h.controller.getDeletionProgress("srv:deleting"))
        queueing.cancel()
        deleting.cancel()
    }

    @Test
    fun recoverySkipsNativeRecoveryEntirelyWhenDownloadsAreUnsupported() = runTest {
        val dms = DmsHarness.create()
        var nativeRecoveries = 0
        val unsupported = dms.manager(downloader = null, nativeRecoveryOverride = { nativeRecoveries++ })

        unsupported.recoverInterruptedDownloads()

        assertEquals(0, nativeRecoveries)
        dms.close()
    }

    @Test
    fun isDisposedFlipsOnDispose() = runTest {
        val c = harness().controller
        assertFalse(c.isDisposed)
        c.dispose()
        assertTrue(c.isDisposed)
    }
}

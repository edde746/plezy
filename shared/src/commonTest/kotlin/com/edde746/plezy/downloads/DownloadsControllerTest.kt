package com.edde746.plezy.downloads

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.COMPLETED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.DOWNLOADING
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.QUEUED
import com.edde746.plezy.data.downloads.SyncRuleFilter
import com.edde746.plezy.data.downloads.SyncRuleTarget
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.CollectionMembership
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.SpecialsOrdering
import com.edde746.plezy.servers.FakeWatchClients
import com.edde746.plezy.servers.InMemoryOfflineWatchQueue
import com.edde746.plezy.servers.OfflineWatchProvider
import com.edde746.plezy.servers.OfflineWatchSyncService
import com.edde746.plezy.servers.RecordingTrackers
import com.edde746.plezy.servers.ToggleOfflineMode
import com.edde746.plezy.servers.WatchStateChangeType
import com.edde746.plezy.servers.WatchStateEvent
import com.edde746.plezy.servers.WatchStateNotifier
import com.edde746.plezy.servers.WatchedThresholdSource
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.yield
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration

class DownloadsControllerTest {
    private var harness: ControllerHarness? = null

    @AfterTest
    fun close() {
        harness?.close()
    }

    private suspend fun harness(downloader: NativeDownloader? = FakeNativeDownloader()) = ControllerHarness.create(downloader).also { harness = it }

    private val srv = ServerId("srv")

    private fun progress(key: String, status: DownloadedMediaStatus, percent: Int = 0, bytes: Long = 0, total: Long = 0, at: Long? = null) =
        DownloadProgress(key, status, progress = percent, downloadedBytes = bytes, totalBytes = total, downloadedAt = at)

    private fun movie(id: String) = testMediaItem(id, MediaKind.MOVIE, "srv", title = id)

    private fun episode(id: String, show: String, season: String, seasonIndex: Int = 1, viewCount: Int? = null) =
        testMediaItem(id, MediaKind.EPISODE, "srv", grandparentId = show, parentId = season, parentIndex = seasonIndex).copy(viewCount = viewCount)

    private fun DownloadsController.changeCount() = changes.value

    // Initial state

    @Test
    fun startsWithEmptyDownloadsMetadataAndNoSyncRules() = runTest {
        val c = harness().controller
        assertTrue(c.downloads.isEmpty())
        assertTrue(c.metadata.isEmpty())
        assertTrue(c.syncRules.isEmpty())
        assertTrue(c.downloadedShows.isEmpty())
        assertTrue(c.downloadedMovies.isEmpty())
        assertNull(c.getMetadata("srv:none"))
        assertNull(c.getProgress("srv:none"))
        assertFalse(c.isDownloaded("srv:none"))
        assertFalse(c.isDownloading("srv:none"))
        assertFalse(c.isQueued("srv:none"))
        assertFalse(c.isQueueing("srv:none"))
        assertFalse(c.hasSyncRule("srv:none"))
        assertNull(c.getSyncRule("srv:none"))
    }

    @Test
    fun logoutDetachesOwnershipWithoutDeletingPhysicalDownloads() = runTest {
        val h = harness()
        h.dms.data.insertDownload("srv", "preserved", status = COMPLETED)
        h.dms.library.addDownloadOwner("test-profile", "srv:preserved")
        h.load()
        assertTrue("srv:preserved" in h.controller.downloads)

        h.controller.detachDownloadsForLogout()

        assertNotNull(h.dms.library.getDownloadedMedia("srv:preserved"))
        assertTrue(h.dms.library.getValidDownloadOwnersForKey("srv:preserved").isEmpty())
        assertTrue(h.controller.downloads.isEmpty())
    }

    @Test
    fun aProfileSwitchClearsVisibleOwnershipAndRulesBeforeStartingTheReload() = runTest {
        val h = harness()
        h.dms.data.insertDownload("srv", "owned-a", status = COMPLETED)
        h.dms.library.addDownloadOwner("test-profile", "srv:owned-a")
        h.controller.createSyncRule(srv, "show-a", SyncRuleTarget.SHOW, 1)
        h.load()
        val before = h.controller.changeCount()

        h.controller.setActiveProfileId("profile-b")

        assertTrue(h.controller.downloads.isEmpty())
        assertTrue(h.controller.syncRules.isEmpty())
        assertEquals(before + 1, h.controller.changeCount())
        h.idle()
    }

    // Sync rule CRUD

    @Test
    fun createSyncRuleStoresTheRuleAndNotifiesOnce() = runTest {
        val c = harness().controller
        val before = c.changeCount()
        c.createSyncRule(srv, "10", SyncRuleTarget.SHOW, 5, includeSpecials = false)
        val key = c.syncRuleKeyFor(srv, "10")

        val rule = assertNotNull(c.getSyncRule(key))
        assertEquals("test-profile", rule.profileId)
        assertEquals(SyncRuleTarget.SHOW, rule.target)
        assertEquals(5, rule.episodeCount)
        assertTrue(rule.enabled)
        assertEquals(SyncRuleFilter.UNWATCHED, rule.downloadFilter)
        assertFalse(rule.includeSpecials)
        assertEquals(false, harness!!.dms.data.syncRules.rule(key)?.includeSpecials)
        assertEquals(before + 1, c.changeCount())
    }

    @Test
    fun updatingARulesCountFilterAndEnabledFlagPersistsAndNotifies() = runTest {
        val h = harness()
        val c = h.controller
        c.createSyncRule(srv, "10", SyncRuleTarget.SHOW, 5)
        c.createSyncRule(srv, "11", SyncRuleTarget.COLLECTION, 0)
        val show = c.syncRuleKeyFor(srv, "10")
        val list = c.syncRuleKeyFor(srv, "11")
        val before = c.changeCount()

        c.updateSyncRuleOptions(show, episodeCount = 12)
        assertEquals(12, c.getSyncRule(show)!!.episodeCount)
        assertEquals(12, h.dms.data.syncRules.rule(show)!!.episodeCount)
        assertEquals(before + 1, c.changeCount())

        c.updateSyncRuleOptions(list, downloadFilter = SyncRuleFilter.ALL)
        assertEquals(SyncRuleFilter.ALL, c.getSyncRule(list)!!.downloadFilter)

        c.updateSyncRuleOptions(show, enabled = false)
        assertFalse(c.getSyncRule(show)!!.enabled)
        assertFalse(h.dms.data.syncRules.rule(show)!!.enabled)
        c.updateSyncRuleOptions(show, enabled = true)
        assertTrue(c.getSyncRule(show)!!.enabled)
    }

    @Test
    fun deleteSyncRuleRemovesTheRuleButKeepsItsDownloads() = runTest {
        val h = harness()
        val c = h.controller
        c.createSyncRule(srv, "10", SyncRuleTarget.SHOW, 5)
        val playlist = c.createSyncRule(srv, "playlist", SyncRuleTarget.PLAYLIST, 0)
        h.dms.data.insertDownload("srv", "episode", type = "episode", status = COMPLETED)
        h.dms.library.addDownloadOwner("test-profile", "srv:episode")
        h.dms.data.syncRules.linkDownload(playlist, "srv:episode")
        val before = c.changeCount()

        c.deleteSyncRule(playlist.globalKey)

        assertFalse(c.hasSyncRule(playlist.globalKey))
        assertTrue(c.hasSyncRule(c.syncRuleKeyFor(srv, "10")))
        assertNull(h.dms.data.syncRules.rule(playlist.globalKey))
        assertNotNull(h.dms.library.getDownloadedMedia("srv:episode"))
        assertNotNull(h.dms.library.getDownloadOwner("test-profile", "srv:episode"))
        assertEquals(before + 1, c.changeCount())
    }

    @Test
    fun addingToAListWithARuleRunsThatRuleNow() = runTest {
        val h = harness()
        val fetched = mutableListOf<String>()
        h.servers.register(
            object : FakeMediaBackend("srv", BackendKind.JELLYFIN) {
                init {
                    items = { null }
                }

                override suspend fun fetchPlaylistPage(id: String, start: Int?, size: Int?): LibraryPage<MediaItem> {
                    fetched += id
                    return LibraryPage(emptyList(), 0, start ?: 0)
                }
            },
        )
        h.controller.createSyncRule(srv, "pl-1", SyncRuleTarget.PLAYLIST, 0)

        h.controller.onAddedToList(srv, "pl-2")
        assertEquals(emptyList(), fetched)

        h.controller.onAddedToList(srv, "pl-1")
        assertEquals(listOf("pl-1"), fetched)
    }

    @Test
    fun deleteSyncRuleReleasesTargetMetadataOnlyWhenNoDownloadHoldsIt() = runTest {
        val h = harness()
        val c = h.controller
        c.createSyncRule(srv, "20", SyncRuleTarget.COLLECTION, 0, targetMetadata = testMediaItem("20", MediaKind.COLLECTION, "srv"))
        assertNotNull(c.getMetadata("srv:20"))
        c.deleteSyncRule(c.syncRuleKeyFor(srv, "20"))
        assertNull(c.getMetadata("srv:20"))

        h.seed(downloads = mapOf("srv:30" to progress("srv:30", QUEUED)))
        c.createSyncRule(srv, "30", SyncRuleTarget.SHOW, 5, targetMetadata = testMediaItem("30", MediaKind.SHOW, "srv"))
        c.deleteSyncRule(c.syncRuleKeyFor(srv, "30"))
        assertNotNull(c.getMetadata("srv:30"))
    }

    @Test
    fun watchEventsTargetActiveProfileParentSyncRules() = runTest {
        val c = harness().controller
        val keys = c.syncRuleKeysForWatchEvent(
            WatchStateEvent(
                itemId = "episode-1",
                serverId = ServerId("jf-machine"),
                changeType = WatchStateChangeType.WATCHED,
                parentChain = listOf("season-1", "show-1"),
                cacheServerId = "jf-machine/user-a",
                isNowWatched = true,
            ),
        )
        assertEquals(setOf("test-profile|jf-machine:episode-1", "test-profile|jf-machine:season-1", "test-profile|jf-machine:show-1"), keys)
    }

    @Test
    fun theLoadReadsPreExistingSyncRules() = runTest {
        val dms = DmsHarness.create()
        dms.data.syncRules.upsert("test-profile", srv, "99", SyncRuleTarget.SHOW, 7)
        val h = ControllerHarness(dms).also { harness = it }
        h.controller.ensureInitialized()
        assertEquals(7, h.controller.getSyncRule("test-profile|srv:99")?.episodeCount)
    }

    @Test
    fun ruleOptionValidationRejectsOptionsAKindDoesNotUse() = runTest {
        val c = harness().controller
        val list = c.createSyncRule(srv, "l", SyncRuleTarget.PLAYLIST, 0)
        val season = c.createSyncRule(srv, "s", SyncRuleTarget.SEASON, 0)
        kotlin.test.assertFails { DownloadsController.validateSyncRuleOptions(list, episodeCount = 3) }
        kotlin.test.assertFails { DownloadsController.validateSyncRuleOptions(list, mediaIndex = 1) }
        kotlin.test.assertFails { DownloadsController.validateSyncRuleOptions(season, downloadFilter = SyncRuleFilter.ALL) }
        kotlin.test.assertFails { DownloadsController.validateSyncRuleOptions(season, includeSpecials = false) }
        kotlin.test.assertFails { DownloadsController.validateSyncRuleOptions(season, episodeCount = -1) }
        DownloadsController.validateSyncRuleOptions(list, downloadFilter = SyncRuleFilter.ALL)
        DownloadsController.validateSyncRuleOptions(season, episodeCount = 0, mediaIndex = 2)
    }

    // Ownership and queueing

    @Test
    fun queueDownloadIsANoOpWhenDownloadsAreUnsupported() = runTest {
        val h = harness(downloader = null)
        val client = FakeMediaBackend("srv")
        assertEquals(0, h.controller.queueDownload(movie("m"), client))
        assertTrue(client.calls.isEmpty())
        assertEquals(0, h.permission.asks)
    }

    @Test
    fun gettersExposeOnlyActiveProfileOwnedRows() = runTest {
        val h = harness()
        val c = h.controller
        h.seed(
            downloads = mapOf("srv:mine" to progress("srv:mine", COMPLETED), "srv:theirs" to progress("srv:theirs", COMPLETED)),
            metadata = mapOf("srv:mine" to movie("mine"), "srv:theirs" to movie("theirs")),
            owned = setOf("srv:mine"),
        )
        assertEquals(setOf("srv:mine"), c.downloads.keys)
        assertEquals(listOf("mine"), c.downloadedMovies.map { it.id })
        assertNull(c.getProgress("srv:theirs"))
        assertNull(c.getVideoFilePath("srv:theirs"))
    }

    @Test
    fun queueDownloadClaimsAnExistingPhysicalDownloadInsteadOfDuplicatingIt() = runTest {
        val h = harness()
        val downloader = h.downloader as FakeNativeDownloader
        h.dms.data.insertDownload("srv", "m", status = COMPLETED)
        h.dms.library.addDownloadOwner("other-profile", "srv:m")
        h.load()
        // The claim refreshes the server's collection membership in the background.
        val client = CollectionsBackend(emptyList())

        assertEquals(1, h.controller.queueDownload(movie("m"), client))

        assertTrue("srv:m" in h.controller.downloads)
        assertNotNull(h.dms.library.getDownloadOwner("test-profile", "srv:m"))
        assertTrue(downloader.calls.none { it.startsWith("enqueue") })
    }

    @Test
    fun queueDownloadLeavesPausedDownloadsPausedInsteadOfRequeueingThem() = runTest {
        val h = harness()
        h.dms.data.insertDownload("srv", "m", status = DownloadedMediaStatus.PAUSED)
        h.dms.library.addDownloadOwner("test-profile", "srv:m")
        h.load()
        assertEquals(0, h.controller.queueDownload(movie("m"), FakeMediaBackend("srv").apply { items = { null } }))
        assertEquals(DownloadedMediaStatus.PAUSED, h.controller.downloads["srv:m"]?.status)
    }

    @Test
    fun containerQueueOwnershipRemainsClaimedUntilExpansionFinishes() = runTest {
        val h = harness()
        val gate = CompletableDeferred<Unit>()
        val started = CompletableDeferred<Unit>()
        val client = FakeMediaBackend("srv").apply {
            playableDescendants = { started.complete(Unit); gate.await(); emptyList() }
        }
        val album = testMediaItem("album", MediaKind.ALBUM, "srv")
        val first = async { h.controller.queueDownload(album, client) }
        started.await()

        assertTrue(h.controller.isQueueing("srv:album"))
        assertEquals(0, h.controller.queueDownload(album, client))
        gate.complete(Unit)
        assertEquals(0, first.await())
        assertFalse(h.controller.isQueueing("srv:album"))
        assertEquals(1, client.calls.count { it.startsWith("fetchPlayableDescendants") })
    }

    @Test
    fun aProfileSwitchInvalidatesContainerExpansionBeforeItCanClaimTheNewProfile() = runTest {
        val h = harness()
        val gate = CompletableDeferred<Unit>()
        val started = CompletableDeferred<Unit>()
        val client = FakeMediaBackend("srv").apply {
            playableDescendants = { started.complete(Unit); gate.await(); listOf(testMediaItem("t1", MediaKind.TRACK, "srv", parentId = "album")) }
        }
        val queued = async { h.controller.queueDownload(testMediaItem("album", MediaKind.ALBUM, "srv"), client) }
        started.await()
        h.controller.setActiveProfileId("profile-b")
        gate.complete(Unit)

        assertEquals(0, queued.await())
        assertNull(h.dms.library.getDownloadOwner("profile-b", "srv:t1"))
        assertFalse(h.controller.isQueueing("srv:album"))
        h.idle()
    }

    @Test
    fun queueDownloadAsksForTheNotificationPermissionOncePerCallWhileHoldingTheClaim() = runTest {
        val h = harness()
        val gate = CompletableDeferred<Unit>()
        h.permission.gate = gate
        val client = FakeMediaBackend("srv").apply { playableDescendants = { emptyList() } }
        val album = testMediaItem("album", MediaKind.ALBUM, "srv")
        val first = async { h.controller.queueDownload(album, client) }
        while (h.permission.asks == 0) yield()

        assertEquals(0, h.controller.queueDownload(album, client))
        assertEquals(1, h.permission.asks)
        gate.complete(Unit)
        first.await()
        assertEquals(1, h.permission.asks)
    }

    @Test
    fun queueingIsBlockedOnCellularWhenWifiOnlyIsOn() = runTest {
        val h = harness()
        h.dms.data.deviceSettings.set(AppSettings.downloadOnWifiOnly, true)
        h.connectivity = com.edde746.plezy.servers.Connectivity.of(com.edde746.plezy.servers.ConnectivityLink.MOBILE)
        kotlin.test.assertFailsWith<CellularDownloadBlockedException> { h.controller.queueDownload(movie("m"), FakeMediaBackend("srv")) }
        assertFalse(h.controller.isQueueing("srv:m"))
    }

    @Test
    fun aFailedSeasonExpansionRollsBackItsStashedMetadata() = runTest {
        val h = harness()
        val client = FakeMediaBackend("srv").apply { playableDescendants = { throw IllegalStateException("boom") } }
        val season = testMediaItem("season", MediaKind.SEASON, "srv")
        kotlin.test.assertFails { h.controller.queueDownload(season, client) }
        assertNull(h.controller.getMetadata("srv:season"))

        // The season's stored row, loaded for a downloaded episode.
        val previous = season.copy(title = "Kept")
        h.seed(downloads = mapOf("srv:e1" to progress("srv:e1", COMPLETED)), metadata = mapOf("srv:e1" to episode("e1", "show", "season"), "srv:season" to previous))
        kotlin.test.assertFails { h.controller.queueDownload(season, client) }
        assertEquals("Kept", h.controller.getMetadata("srv:season")?.title)
    }

    // Deletion and ownership release

    @Test
    fun deleteAndCancelAreNoOpsForUnownedRows() = runTest {
        val h = harness()
        h.dms.data.insertDownload("srv", "m", status = COMPLETED)
        h.dms.library.addDownloadOwner("other-profile", "srv:m")
        h.load()
        h.controller.deleteDownload("srv:m")
        h.controller.cancelDownload("srv:m")
        assertNotNull(h.dms.library.getDownloadedMedia("srv:m"))
        assertNotNull(h.dms.library.getDownloadOwner("other-profile", "srv:m"))
    }

    @Test
    fun deleteDownloadRemovesOnlyThisProfilesOwnershipWhenAnotherOwnerRemains() = runTest {
        val h = harness()
        h.dms.profile("test-profile")
        h.dms.profile("other-profile")
        h.seed(downloads = mapOf("srv:m" to progress("srv:m", COMPLETED)), metadata = mapOf("srv:m" to movie("m")))
        h.dms.library.addDownloadOwner("other-profile", "srv:m")
        val events = mutableListOf<String>()
        val job = h.dms.scope.async { h.deletionNotifier.events.collect { events += it.globalKey } }
        yield()

        h.controller.deleteDownload("srv:m")

        assertNotNull(h.dms.library.getDownloadedMedia("srv:m"))
        assertNull(h.dms.library.getDownloadOwner("test-profile", "srv:m"))
        assertNotNull(h.dms.library.getDownloadOwner("other-profile", "srv:m"))
        assertTrue("srv:m" !in h.controller.downloads)
        job.cancel()
    }

    @Test
    fun cancelDownloadRemovesDownloadMetadataAndArtwork() = runTest {
        val h = harness()
        h.seed(downloads = mapOf("srv:m" to progress("srv:m", DOWNLOADING).copy(thumbPath = "/thumb")), metadata = mapOf("srv:m" to movie("m")))
        assertEquals("/thumb", h.controller.getArtworkPath("srv:m"))
        h.controller.cancelDownload("srv:m")
        assertTrue("srv:m" !in h.controller.downloads)
        assertNull(h.controller.getMetadata("srv:m"))
        assertNull(h.controller.getArtworkPath("srv:m"))
    }

    @Test
    fun cancelDownloadIsANoOpWhenTheDownloadIsAbsent() = runTest {
        val c = harness().controller
        val before = c.changeCount()
        c.cancelDownload("srv:none")
        assertEquals(before, c.changeCount())
    }

    @Test
    fun deletingAShowWhoseMetadataIsMissingRemovesItsOwnedEpisodes() = runTest {
        val h = harness()
        for (id in listOf("e1", "e2")) {
            h.dms.data.insertDownload("srv", id, type = "episode", status = COMPLETED, parentRatingKey = "season", grandparentRatingKey = "show")
            h.dms.library.addDownloadOwner("test-profile", "srv:$id")
        }
        h.load()

        h.controller.deleteDownload("srv:show")

        assertNull(h.dms.library.getDownloadedMedia("srv:e1"))
        assertNull(h.dms.library.getDownloadedMedia("srv:e2"))
        assertTrue(h.controller.downloads.isEmpty())
    }

    // Aggregates and grouping

    @Test
    fun aggregateProgressCoversOnlyQueuedLeavesAndStaysBelowFullUntilAllComplete() = runTest {
        val h = harness()
        val c = h.controller
        h.seed(
            downloads = mapOf("srv:e1" to progress("srv:e1", COMPLETED), "srv:e2" to progress("srv:e2", DOWNLOADING, percent = 99)),
            metadata = mapOf("srv:e1" to episode("e1", "show", "season"), "srv:e2" to episode("e2", "show", "season")),
        )
        val show = assertNotNull(c.getProgress("srv:show"))
        assertEquals(DOWNLOADING, show.status)
        assertEquals(99, show.progress)
        assertEquals("1/2 episodes", show.currentFile)

        c.onProgressUpdate(progress("srv:e2", COMPLETED))
        assertEquals(COMPLETED, c.getAggregateProgressForSeason(srv, "season")?.status)
        assertEquals(100, c.getAggregateProgressForSeason(srv, "season")?.progress)

        c.onProgressUpdate(progress("srv:e2", DownloadedMediaStatus.FAILED))
        assertEquals(DownloadedMediaStatus.PARTIAL, c.getProgress("srv:show")?.status)
    }

    @Test
    fun albumAggregatesDownloadedAlbumsAndTrackOrderComeFromTrackDownloads() = runTest {
        val h = harness()
        val c = h.controller
        fun track(id: String, disc: Int, number: Int) =
            testMediaItem(id, MediaKind.TRACK, "srv", parentId = "album", parentTitle = "Album", grandparentId = "artist", parentIndex = disc, index = number)
        h.seed(
            downloads = mapOf("srv:t1" to progress("srv:t1", COMPLETED), "srv:t2" to progress("srv:t2", COMPLETED), "srv:t3" to progress("srv:t3", QUEUED)),
            metadata = mapOf("srv:t1" to track("t1", 2, 1), "srv:t2" to track("t2", 1, 2), "srv:t3" to track("t3", 1, 1)),
        )
        assertEquals(QUEUED, c.getAggregateProgressForAlbum(srv, "album")?.status)
        assertEquals("2/3 tracks", c.getAggregateProgressForArtist(srv, "artist")?.currentFile)
        assertEquals(listOf("album"), c.downloadedAlbums.map { it.id })
        assertEquals(listOf("t2", "t1"), c.getDownloadedTracksForAlbum("srv:album").map { it.id })
    }

    @Test
    fun downloadedSeasonsGroupEpisodesAndDeriveCountsAndLibrary() = runTest {
        val h = harness()
        val c = h.controller
        val show = testMediaItem("show", MediaKind.SHOW, "srv").copy(libraryId = "lib", libraryTitle = "Shows")
        h.seed(
            downloads = listOf("e1", "e2", "e3").associate { "srv:$it" to progress("srv:$it", COMPLETED) },
            metadata = mapOf(
                "srv:show" to show,
                "srv:e1" to episode("e1", "show", "s2", seasonIndex = 2),
                "srv:e2" to episode("e2", "show", "s1", seasonIndex = 1, viewCount = 1),
                "srv:e3" to episode("e3", "show", "s1", seasonIndex = 1),
            ),
            owned = setOf("srv:e1", "srv:e2", "srv:e3"),
        )
        val seasons = c.downloadedSeasonsForShow("srv:show")
        assertEquals(listOf("s1", "s2"), seasons.map { it.id })
        assertEquals(2, seasons[0].leafCount)
        assertEquals(1, seasons[0].viewedLeafCount)
        assertEquals("lib", seasons[0].libraryId)
        val shows = c.downloadedShows
        assertEquals(3, shows.single().leafCount)
        assertEquals("Shows", shows.single().libraryTitle)
    }

    @Test
    fun downloadSortExtrasAggregateContainersOverTheirDownloadedLeaves() = runTest {
        val h = harness()
        val c = h.controller
        h.seed(
            downloads = mapOf("srv:e1" to progress("srv:e1", COMPLETED, total = 100, at = 5), "srv:e2" to progress("srv:e2", COMPLETED, total = 50, at = 9)),
            metadata = mapOf("srv:e1" to episode("e1", "show", "season"), "srv:e2" to episode("e2", "show", "season")),
        )
        val extras = c.downloadSortExtras(listOf(testMediaItem("show", MediaKind.SHOW, "srv")))
        assertEquals(9L, extras["srv:show"]?.downloadedAt)
        assertEquals(150L, extras["srv:show"]?.totalBytes)
        assertEquals(100L, extras["srv:e1"]?.totalBytes)
    }

    // Progress events

    @Test
    fun downloadedAtIsStampedOnCompletionCarriedThroughAndFreshOnReDownload() = runTest {
        val h = harness()
        val c = h.controller
        h.seed(downloads = mapOf("srv:m" to progress("srv:m", DOWNLOADING)))
        h.now = 1_000
        c.onProgressUpdate(progress("srv:m", COMPLETED))
        assertEquals(1_000L, c.downloads["srv:m"]?.downloadedAt)
        h.now = 2_000
        c.onProgressUpdate(progress("srv:m", COMPLETED, percent = 100))
        assertEquals(1_000L, c.downloads["srv:m"]?.downloadedAt)
        c.onProgressUpdate(progress("srv:m", QUEUED))
        c.onProgressUpdate(progress("srv:m", COMPLETED))
        assertEquals(2_000L, c.downloads["srv:m"]?.downloadedAt)
    }

    @Test
    fun terminalStatusOnlyEventsPreserveBytesButARetryResetsProgress() = runTest {
        val h = harness()
        val c = h.controller
        h.seed(downloads = mapOf("srv:m" to progress("srv:m", DOWNLOADING, percent = 40, bytes = 400, total = 1000)))
        c.onProgressUpdate(progress("srv:m", DownloadedMediaStatus.FAILED))
        assertEquals(400L, c.downloads["srv:m"]?.downloadedBytes)
        assertEquals(40, c.downloads["srv:m"]?.progress)
        c.onProgressUpdate(progress("srv:m", QUEUED))
        assertEquals(0L, c.downloads["srv:m"]?.downloadedBytes)
    }

    @Test
    fun theActivitySnapshotCountsInFlightWorkAndEveryDownloadedByte() = runTest {
        val h = harness()
        val c = h.controller
        h.seed(
            downloads = mapOf(
                "srv:a" to progress("srv:a", DOWNLOADING, percent = 30, bytes = 300),
                "srv:b" to progress("srv:b", COMPLETED, percent = 100, bytes = 1000),
                "srv:c" to progress("srv:c", DownloadedMediaStatus.FAILED, bytes = 5),
            ),
            owned = emptySet(),
        )
        val snapshot = c.downloadActivitySnapshot()
        assertEquals(1, snapshot.activeTasks)
        assertEquals(1, snapshot.completedTasks)
        assertEquals(1, snapshot.failedTasks)
        assertEquals(1305L, snapshot.downloadedBytes)
        assertEquals(130, snapshot.progressUnits)
        assertNull(snapshot.networkAvailable)
    }

    @Test
    fun activitySnapshotsRecordOfflineSourceTransitions() = runTest {
        val c = harness().controller
        val offline = kotlinx.coroutines.flow.MutableStateFlow(false)
        // Hands on each value the controller has taken.
        val taken = kotlinx.coroutines.channels.Channel<Boolean>(kotlinx.coroutines.channels.Channel.UNLIMITED)
        c.setOfflineSource(object : com.edde746.plezy.servers.OfflineModeSource {
            override val isOffline = object : kotlinx.coroutines.flow.StateFlow<Boolean> by offline {
                override suspend fun collect(collector: kotlinx.coroutines.flow.FlowCollector<Boolean>): Nothing =
                    offline.collect { collector.emit(it); taken.send(it) }
            }
        })
        val first = c.downloadActivitySnapshot()
        assertEquals(true, first.networkAvailable)
        offline.value = true
        kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.Default) {
            kotlinx.coroutines.withTimeout(5_000) { while (!taken.receive()) Unit }
        }
        val second = c.downloadActivitySnapshot()
        assertEquals(false, second.networkAvailable)
        assertTrue(second.networkStateGeneration > first.networkStateGeneration)
    }

    // Auto-delete

    @Test
    fun autoDeleteKeepsResumableItemsAndProtectsOnlyTheActiveKey() = runTest {
        val h = harness()
        val watched = { id: String -> movie(id).copy(viewCount = 1) }
        h.seed(
            downloads = listOf("a", "b", "resume").associate { "srv:$it" to progress("srv:$it", COMPLETED) },
            metadata = mapOf("srv:a" to watched("a"), "srv:b" to watched("b"), "srv:resume" to watched("resume").copy(viewOffsetMs = 60_000, durationMs = 600_000)),
        )

        val deleted = h.controller.autoDeleteWatchedDownloads(activeGlobalKey = "srv:a")

        assertEquals(listOf("b"), deleted)
        assertEquals(setOf("srv:a", "srv:resume"), h.controller.downloads.keys)
    }

    // Retry

    @Test
    fun aRetryOfAnUnownedOrNonFailedDownloadDoesNothing() = runTest {
        val h = harness()
        h.seed(
            downloads = mapOf("srv:ok" to progress("srv:ok", COMPLETED), "srv:other" to progress("srv:other", DownloadedMediaStatus.FAILED)),
            owned = setOf("srv:ok"),
        )
        val client = FakeMediaBackend("srv")
        h.controller.retryDownloads(listOf("srv:ok", "srv:other", "srv:missing")) { client }
        assertTrue(client.calls.isEmpty())
    }

    // Collections

    private class CollectionsBackend(var memberships: List<CollectionMembership>) : FakeMediaBackend("srv") {
        var failure: Exception? = null
        val lookups = mutableListOf<Set<String>>()

        init {
            items = { id -> memberships.firstOrNull { it.collection.id == id }?.collection }
        }

        override suspend fun fetchCollectionMemberships(itemIds: Set<String>): List<CollectionMembership> {
            lookups += itemIds
            failure?.let { throw it }
            return memberships
        }

        override fun resolveDownloadArtwork(item: MediaItem) = emptyList<com.edde746.plezy.backend.DownloadArtworkSpec>()
    }

    private suspend fun collectionsHarness(): Pair<ControllerHarness, CollectionsBackend> {
        val h = harness()
        val client = CollectionsBackend(listOf(CollectionMembership(testMediaItem("dune", MediaKind.COLLECTION, "srv", title = "dune"), listOf("dune-1", "dune-2"))))
        h.servers.register(client)
        return h to client
    }

    private suspend fun ControllerHarness.seedMovies(ids: List<String>) = seed(
        downloads = ids.associate { "srv:$it" to progress("srv:$it", COMPLETED) },
        metadata = ids.associate { "srv:$it" to movie(it) },
    )

    private suspend fun ControllerHarness.sync() = controller.syncDownloadCollections(listOf(srv))

    @Test
    fun aRefreshFoldsACollectionsDownloadedMoviesAndStoresTheMembership() = runTest {
        val (h, client) = collectionsHarness()
        h.seedMovies(listOf("dune-1", "dune-2", "other"))

        h.sync()

        assertEquals(setOf("dune-1", "dune-2", "other"), client.lookups.single())
        assertEquals(listOf("dune", "other"), h.controller.groupDownloadsByCollection(h.controller.downloadedMovies).map { it.id }.sorted())
        assertEquals(listOf("dune-1", "dune-2"), h.controller.downloadedCollectionItems("srv:dune").map { it.id })
        val stored = h.dms.data.downloadCollections.collections("test-profile").single()
        assertEquals("dune", stored.collectionId)
        assertEquals(listOf("dune-1", "dune-2"), stored.memberIds)
    }

    @Test
    fun aFreshRefreshIsSkippedUntilATitleItDidNotCoverIsDownloaded() = runTest {
        val (h, client) = collectionsHarness()
        h.seedMovies(listOf("dune-1", "dune-2"))
        h.sync()
        h.sync()
        assertEquals(1, client.lookups.size)

        h.seedMovies(listOf("dune-3"))
        h.sync()

        assertEquals(2, client.lookups.size)
        assertTrue("dune-3" in client.lookups.last())
    }

    @Test
    fun aFailedRefreshKeepsTheStoredMembership() = runTest {
        val (h, client) = collectionsHarness()
        h.seedMovies(listOf("dune-1", "dune-2"))
        h.sync()
        h.seedMovies(listOf("dune-3"))
        client.failure = IllegalStateException("server went away")
        h.sync()

        assertEquals(listOf("dune-1", "dune-2"), h.controller.downloadedCollectionItems("srv:dune").map { it.id })
        assertEquals(listOf("dune-1", "dune-2"), h.dms.data.downloadCollections.collections("test-profile").single().memberIds)
        client.failure = null
        h.sync()
        assertEquals(3, client.lookups.size)
    }

    @Test
    fun deletingAFolderDeletesEveryDownloadedTitleInIt() = runTest {
        val (h, _) = collectionsHarness()
        h.seedMovies(listOf("dune-1", "dune-2", "other"))
        h.sync()

        h.controller.deleteCollectionDownloads("srv:dune")

        assertEquals(listOf("other"), h.controller.downloadedMovies.map { it.id })
    }

    // Offline watch adapter

    @Test
    fun theOfflineWatchViewListsOwnedDownloadsAndDeletesOnlyCompletedLeaves() = runTest {
        val h = harness()
        h.dms.data.insertDownload("srv", "e1", type = "episode", status = COMPLETED, parentRatingKey = "season", grandparentRatingKey = "show", clientScopeId = "scope")
        h.dms.data.insertDownload("srv", "e2", type = "episode", status = COMPLETED)
        h.dms.profile("test-profile")
        h.dms.profile("other-profile")
        h.dms.library.addDownloadOwner("test-profile", "srv:e1")
        h.dms.library.addDownloadOwner("other-profile", "srv:e2")
        val items = DownloadOfflineWatchItems(h.dms.library) { h.controller }

        val owned = items.ownedDownloads("test-profile")
        assertEquals(listOf("e1"), owned.map { it.itemId })
        assertEquals(MediaKind.EPISODE, owned.single().kind)
        assertEquals("season", owned.single().parentId)
        assertEquals("scope", items.downloadedClientScopeId("srv:e1"))
        items.deleteWatchedDownload("srv:show")
        assertEquals(setOf("srv:e1", "srv:e2"), h.dms.library.getAllDownloads().map { it.global_key }.toSet())
    }

    @Test
    fun `marking a downloaded episode watched offline removes it and names it`() = runTest {
        val h = harness()
        h.seed(
            downloads = mapOf("srv:e1" to DownloadProgress("srv:e1", COMPLETED, progress = 100)),
            metadata = mapOf("srv:e1" to testMediaItem(id = "e1", kind = MediaKind.EPISODE, serverId = "srv", title = "Pilot", grandparentId = "show")),
        )
        val messages = FlowRecorder(h.controller.autoRemovedMessages, backgroundScope)
        val items = DownloadOfflineWatchItems(h.dms.library) { h.controller }
        val notifier = WatchStateNotifier()
        val sync = OfflineWatchSyncService(
            queue = InMemoryOfflineWatchQueue(),
            downloads = items,
            clients = FakeWatchClients(),
            notifier = notifier,
            trackers = RecordingTrackers(),
            thresholds = object : WatchedThresholdSource {
                override fun reportsServerThreshold(client: MediaBackend): Boolean = false
                override fun cachedPercent(serverId: ServerId): Int? = null
            },
            offlineMode = ToggleOfflineMode(offline = true),
            scope = backgroundScope,
            minSyncInterval = Duration.ZERO,
            forceSyncOnResume = false,
            timeSource = testScheduler.timeSource,
        )
        val provider = OfflineWatchProvider(sync, items, notifier, backgroundScope, { SpecialsOrdering.SPECIALS_LAST }, { true })

        provider.markAsWatched(srv, "e1")

        assertEquals(listOf(T.messages.autoRemovedWatchedDownload(title = "Pilot")), messages.take(1))
        assertNull(h.dms.library.getDownloadedMedia("srv:e1"))
    }

    @Test
    fun theOfflineWatchViewReadsTheProfilesCompletedEpisodesFromTheController() = runTest {
        val h = harness()
        val episode = testMediaItem(id = "e1", kind = MediaKind.EPISODE, serverId = "srv", title = "Pilot", grandparentId = "show")
        val queued = testMediaItem(id = "e2", kind = MediaKind.EPISODE, serverId = "srv", title = "Second", grandparentId = "show")
        h.seed(
            downloads = mapOf(
                "srv:e1" to DownloadProgress("srv:e1", COMPLETED, progress = 100),
                "srv:e2" to DownloadProgress("srv:e2", DownloadedMediaStatus.QUEUED),
            ),
            metadata = mapOf("srv:e1" to episode, "srv:e2" to queued),
        )
        val items = DownloadOfflineWatchItems(h.dms.library) { h.controller }

        assertEquals(listOf("e1"), items.downloadedEpisodesForShow("srv:show").map { it.id })
        assertEquals("Pilot", items.metadata("srv:e1")?.title)
    }
}

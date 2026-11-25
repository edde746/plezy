package com.edde746.plezy.downloads

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.COMPLETED
import com.edde746.plezy.data.downloads.SyncRuleTarget
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.DeletionEvent
import com.edde746.plezy.servers.PlexProfileScopeId
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import kotlinx.io.buffered
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.writeString
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

class DownloadsControllerOwnershipTest {
    private val harnesses = mutableListOf<ControllerHarness>()

    @AfterTest
    fun close() {
        harnesses.forEach { it.controller.dispose() }
        harnesses.firstOrNull()?.dms?.close()
    }

    private val srv = ServerId("srv")

    private suspend fun harness(dms: DmsHarness? = null, profile: String? = "test-profile", managerOf: ((FakeDownloadServers) -> DownloadManagerService)? = null) =
        ControllerHarness(dms ?: DmsHarness.create(), activeProfileId = profile, managerOf = managerOf)
            .also { harnesses += it; it.controller.ensureInitialized() }

    private fun progress(key: String, status: DownloadedMediaStatus = COMPLETED) = DownloadProgress(key, status)

    private val ownedMovie = testMediaItem("1", MediaKind.MOVIE, "srv", title = "Owned Movie")

    private fun track(id: String, album: String = "album-1", server: String = "srv") =
        testMediaItem(id, MediaKind.TRACK, server, title = id, parentId = album)

    /** A backend that fails every fetch (a claim's network work is best effort) and has no artwork or collections. */
    private class ClaimOnlyBackend(serverId: String = "srv", backend: BackendKind = BackendKind.PLEX, scopeId: String? = null) :
        FakeMediaBackend(serverId, backend, scopeId = scopeId) {
        init {
            items = { throw IllegalStateException("fetchItem is unreachable") }
        }

        override fun resolveDownloadArtwork(item: MediaItem) = emptyList<com.edde746.plezy.backend.DownloadArtworkSpec>()

        override suspend fun fetchCollectionMemberships(itemIds: Set<String>) = emptyList<com.edde746.plezy.model.CollectionMembership>()
    }

    // Local file selection

    @Test
    fun aCallerWithoutASourceIdSelectsTheFileByMediaIndex() = runTest {
        val h = harness()
        h.dms.data.insertDownload("srv", "movie-1", status = COMPLETED, mediaIndex = 0, mediaSourceId = "source-a")
        val file = Path(h.dms.storage.baseAppDirectoryPath(), "movie-1-v1.mp4")
        SystemFileSystem.sink(file).buffered().use { it.writeString("video") }
        h.dms.library.updateVideoFilePath("srv:movie-1", file.toString())
        h.dms.library.addDownloadOwner("test-profile", "srv:movie-1")
        h.load()

        assertNull(h.controller.getVideoFilePath("srv:movie-1", mediaIndex = 1))
        assertEquals(file.toString(), h.controller.getVideoFilePath("srv:movie-1", mediaIndex = 0))
    }

    @Test
    fun getCompletedDownloadExposesTheDownloadedVersionOfOwnedCompletedRows() = runTest {
        val h = harness()
        h.dms.data.insertDownload("srv", "movie-1", status = COMPLETED, mediaIndex = 1, mediaSourceId = "source-b")
        h.dms.library.addDownloadOwner("test-profile", "srv:movie-1")
        h.load()

        val row = assertNotNull(h.controller.getCompletedDownload("srv:movie-1"))
        assertEquals(1L, row.media_index)
        assertEquals("source-b", row.media_source_id)
    }

    @Test
    fun getCompletedDownloadIsNullForUnownedOrIncompleteRows() = runTest {
        val dms = DmsHarness.create()
        dms.data.insertDownload("srv", "unowned", status = COMPLETED)
        // Owned by another profile: an ownerless row would be adopted by the active profile on load.
        dms.library.addDownloadOwner("profile-b", "srv:unowned")
        dms.data.insertDownload("srv", "partial", status = DownloadedMediaStatus.DOWNLOADING)
        val h = harness(dms)
        dms.library.addDownloadOwner("test-profile", "srv:partial")
        h.load()

        assertNull(h.controller.getCompletedDownload("srv:unowned"))
        assertNull(h.controller.getCompletedDownload("srv:partial"))
    }

    // Removing a rule with its downloads

    @Test
    fun deleteSyncRuleAndDownloadsRemovesOnlyDownloadsExclusiveToTheRuleAndActiveProfile() = runTest {
        val h = harness()
        val c = h.controller
        val target = c.createSyncRule(srv, "playlist-a", SyncRuleTarget.PLAYLIST, 0)
        val sibling = c.createSyncRule(srv, "playlist-b", SyncRuleTarget.PLAYLIST, 0)
        c.markSyncRuleDownloadLinksInitialized(target.globalKey)
        c.markSyncRuleDownloadLinksInitialized(sibling.globalKey)
        val items = listOf("exclusive", "rule-shared", "profile-shared").associate { "srv:$it" to testMediaItem(it, MediaKind.EPISODE, "srv", title = it) }
        h.seed(downloads = items.keys.associateWith { progress(it) }, metadata = items)
        for (key in items.keys) h.dms.data.syncRules.linkDownload(target, key)
        h.dms.data.syncRules.linkDownload(sibling, "srv:rule-shared")
        h.dms.library.addDownloadOwner("profile-b", "srv:profile-shared")

        c.deleteSyncRuleAndDownloads(target.globalKey)

        val rules = h.dms.data.syncRules
        assertNull(rules.rule(target.globalKey))
        assertNotNull(rules.rule(sibling.globalKey))
        assertNull(h.dms.library.getDownloadedMedia("srv:exclusive"))
        assertNotNull(h.dms.library.getDownloadedMedia("srv:rule-shared"))
        assertNotNull(h.dms.library.getDownloadOwner("test-profile", "srv:rule-shared"))
        assertNotNull(h.dms.library.getDownloadedMedia("srv:profile-shared"))
        assertNull(h.dms.library.getDownloadOwner("test-profile", "srv:profile-shared"))
        assertNotNull(h.dms.library.getDownloadOwner("profile-b", "srv:profile-shared"))
    }

    @Test
    fun deleteSyncRuleAndDownloadsKeepsEpisodesAnInitializedShowRuleCovers() = runTest {
        val h = harness()
        val c = h.controller
        val target = c.createSyncRule(srv, "playlist", SyncRuleTarget.PLAYLIST, 0)
        val show = c.createSyncRule(srv, "show-1", SyncRuleTarget.SHOW, 1)
        c.markSyncRuleDownloadLinksInitialized(target.globalKey)
        c.markSyncRuleDownloadLinksInitialized(show.globalKey)
        val key = "srv:ep-watched"
        h.seed(downloads = mapOf(key to progress(key)), metadata = mapOf(key to testMediaItem("ep-watched", MediaKind.EPISODE, "srv", grandparentId = "show-1")))
        h.dms.data.syncRules.linkDownload(target, key)

        c.deleteSyncRuleAndDownloads(target.globalKey)

        assertNotNull(h.dms.library.getDownloadedMedia(key))
        assertEquals(1, h.dms.data.db.read { syncRuleQueries.selectLinkedKeys(show.id).executeAsList() }.size)
    }

    @Test
    fun deleteSyncRuleAndDownloadsKeepsAnUnresolvableLegacyListRuleIntact() = runTest {
        val h = harness()
        val c = h.controller
        val rule = c.createSyncRule(ServerId("missing-server"), "deleted-playlist", SyncRuleTarget.PLAYLIST, 0)

        val error = assertFailsWith<SyncRuleCleanupUnavailableException> { c.deleteSyncRuleAndDownloads(rule.globalKey) }

        assertEquals(rule.globalKey, error.ruleGlobalKey)
        assertEquals(true, h.dms.data.syncRules.rule(rule.globalKey)?.enabled)
        assertTrue(c.hasSyncRule(rule.globalKey))
    }

    // Claiming and queueing

    @Test
    fun claimingAnExistingDownloadLoadsItsMetadataForTheClaimingProfile() = runTest {
        val h = harness()
        val c = h.controller
        // Another profile's physical download: nothing about it is loaded here.
        h.seed(downloads = mapOf("srv:1" to progress("srv:1")), owned = emptySet())
        assertTrue(c.downloadedMovies.isEmpty())

        assertEquals(1, c.queueDownload(ownedMovie, ClaimOnlyBackend()))

        assertEquals(listOf("Owned Movie"), c.downloadedMovies.map { it.title })
    }

    @Test
    fun claimingAnExistingEpisodeDownloadAlsoLoadsItsShowAndSeason() = runTest {
        val h = harness()
        val episode = testMediaItem("ep-1", MediaKind.EPISODE, "srv", title = "Pilot", parentId = "season-1", grandparentId = "show-1", grandparentTitle = "Show")
        val client = ClaimOnlyBackend().apply {
            items = { id ->
                when (id) {
                    "show-1" -> testMediaItem("show-1", MediaKind.SHOW, "srv", title = "Show")
                    "season-1" -> testMediaItem("season-1", MediaKind.SEASON, "srv", title = "Season 1")
                    else -> null
                }
            }
        }
        h.servers.register(client)
        h.seed(downloads = mapOf("srv:ep-1" to progress("srv:ep-1")), owned = emptySet())

        assertEquals(1, h.controller.queueDownload(episode, client))

        assertEquals("Pilot", h.controller.getMetadata("srv:ep-1")?.title)
        assertEquals("Show", h.controller.getMetadata("srv:show-1")?.title)
        assertEquals("Season 1", h.controller.getMetadata("srv:season-1")?.title)
    }

    @Test
    fun queueDownloadAppliesTheClientServerIdBeforeCheckingExistingDownloads() = runTest {
        val h = harness()
        h.seed(downloads = mapOf("srv:1" to progress("srv:1")), owned = emptySet())

        assertEquals(1, h.controller.queueDownload(ownedMovie.copy(serverId = null), ClaimOnlyBackend()))

        assertEquals(setOf("srv:1"), h.controller.downloads.keys)
        assertEquals(setOf("srv:1"), h.dms.library.getDownloadOwnerKeysForProfile("test-profile"))
    }

    @Test
    fun queueDownloadExpandsAnAlbumIntoItsTracks() = runTest {
        val h = harness()
        // The rows exist already (another profile's), so each track is claimed without the network.
        h.seed(downloads = mapOf("srv:t1" to progress("srv:t1"), "srv:t2" to progress("srv:t2")), owned = emptySet())
        val client = ClaimOnlyBackend().apply { playableDescendants = { listOf(track("t1"), track("t2")) } }

        assertEquals(2, h.controller.queueDownload(testMediaItem("album-1", MediaKind.ALBUM, "srv", title = "Album"), client))

        assertEquals(listOf("fetchPlayableDescendants:album-1"), client.calls.filter { it.startsWith("fetchPlayableDescendants") })
        assertEquals(setOf("srv:t1", "srv:t2"), h.dms.library.getDownloadOwnerKeysForProfile("test-profile"))
    }

    @Test
    fun aContainerQueueClaimsItsTracksOnceTheHeldExpansionFinishes() = runTest {
        val h = harness()
        val album = testMediaItem("album-1", MediaKind.ALBUM, "srv", title = "Album")
        h.seed(downloads = mapOf("srv:t1" to progress("srv:t1")), owned = emptySet())
        val started = CompletableDeferred<Unit>()
        val release = CompletableDeferred<Unit>()
        val client = ClaimOnlyBackend().apply { playableDescendants = { started.complete(Unit); release.await(); listOf(track("t1")) } }

        val first = async { h.controller.queueDownload(album, client) }
        started.await()
        assertEquals(0, h.controller.queueDownload(album, client))
        release.complete(Unit)

        assertEquals(1, first.await())
        assertEquals(1, client.calls.count { it.startsWith("fetchPlayableDescendants") })
    }

    @Test
    fun aProfileSwitchDuringContainerExpansionLeavesNoTraceInEitherProfile() = runTest {
        val h = harness(profile = "profile-a")
        val album = testMediaItem("album-1", MediaKind.ALBUM, "srv", title = "Profile A Album")
        val track = track("track-1")
        // Another profile's download, still queued.
        h.seed(downloads = mapOf(track.globalKey to progress(track.globalKey, DownloadedMediaStatus.QUEUED)), owned = emptySet())
        val started = CompletableDeferred<Unit>()
        val release = CompletableDeferred<Unit>()
        val client = ClaimOnlyBackend().apply { playableDescendants = { started.complete(Unit); release.await(); listOf(track) } }

        val queued = async { h.controller.queueDownload(album, client) }
        started.await()
        h.controller.setActiveProfileId("profile-b")
        assertFalse(h.controller.isQueueing(album.globalKey))
        release.complete(Unit)

        assertEquals(0, queued.await())
        h.idle()
        assertTrue(h.dms.library.getDownloadOwnerKeysForProfile("profile-a").isEmpty())
        assertTrue(h.dms.library.getDownloadOwnerKeysForProfile("profile-b").isEmpty())
        assertTrue(h.dms.library.getAllDownloads().none { it.status == COMPLETED.code })
        assertNull(h.controller.getMetadata(album.globalKey))
        assertNull(h.controller.getMetadata(track.globalKey))
        assertTrue(h.controller.downloads.isEmpty())
        assertTrue(h.dms.data.syncRules.rules("profile-b").isEmpty())
    }

    @Test
    fun staleQueueCleanupDoesNotRemoveTheNewProfilesQueueClaim() = runTest {
        val h = harness(profile = "profile-a")
        val album = testMediaItem("album-1", MediaKind.ALBUM, "srv", title = "Album")
        fun gatedClient(started: CompletableDeferred<Unit>, release: CompletableDeferred<Unit>) =
            ClaimOnlyBackend().apply { playableDescendants = { started.complete(Unit); release.await(); emptyList() } }
        val firstStarted = CompletableDeferred<Unit>()
        val releaseFirst = CompletableDeferred<Unit>()
        val first = async { h.controller.queueDownload(album, gatedClient(firstStarted, releaseFirst)) }
        firstStarted.await()

        h.controller.setActiveProfileId("profile-b")
        val secondStarted = CompletableDeferred<Unit>()
        val releaseSecond = CompletableDeferred<Unit>()
        val second = async { h.controller.queueDownload(album, gatedClient(secondStarted, releaseSecond)) }
        secondStarted.await()
        assertTrue(h.controller.isQueueing(album.globalKey))

        releaseFirst.complete(Unit)
        assertEquals(0, first.await())
        assertTrue(h.controller.isQueueing(album.globalKey))

        releaseSecond.complete(Unit)
        assertEquals(0, second.await())
        assertFalse(h.controller.isQueueing(album.globalKey))
        h.idle()
    }

    // Deletion

    @Test
    fun deletingAnAlbumNotifiesOnceAndEmitsADeletionEventPerTrackAndTheAlbum() = runTest {
        val h = harness()
        val album = testMediaItem("album-1", MediaKind.ALBUM, "srv", title = "Album")
        h.seed(
            downloads = mapOf("srv:t1" to progress("srv:t1"), "srv:t2" to progress("srv:t2")),
            metadata = mapOf("srv:album-1" to album, "srv:t1" to track("t1"), "srv:t2" to track("t2")),
        )
        val events = FlowRecorder(h.deletionNotifier.events, h.dms.scope)
        val before = h.controller.changes.value

        h.controller.deleteDownload(album.globalKey)

        assertEquals(before + 1, h.controller.changes.value)
        assertTrue(h.controller.downloads.isEmpty())
        assertEquals(setOf("t1", "t2", "album-1"), events.take(3).map { it.itemId }.toSet())
        events.cancel()
    }

    @Test
    fun deletingAShowWhoseMetadataIsMissingKeepsOtherShowsEpisodes() = runTest {
        val h = harness()
        for ((id, season, show) in listOf(Triple("ep-1", "season-1", "show-1"), Triple("ep-2", "season-2", "show-1"), Triple("other-ep", "season-9", "show-9"))) {
            h.dms.data.insertDownload("srv", id, type = "episode", status = COMPLETED, parentRatingKey = season, grandparentRatingKey = show)
            h.dms.library.addDownloadOwner("test-profile", "srv:$id")
        }
        h.load()

        h.controller.deleteDownload("srv:show-1")

        assertEquals(setOf("srv:other-ep"), h.controller.downloads.keys)
        assertNull(h.dms.library.getDownloadedMedia("srv:ep-1"))
        assertNull(h.dms.library.getDownloadedMedia("srv:ep-2"))
        assertNotNull(h.dms.library.getDownloadedMedia("srv:other-ep"))

        h.controller.deleteDownload("srv:season-9")

        assertTrue(h.controller.downloads.isEmpty())
    }

    @Test
    fun containersWithTheSameNativeIdOnTwoServersStaySeparate() = runTest {
        val h = harness()
        val c = h.controller
        fun episode(server: String, id: String) = testMediaItem(
            id, MediaKind.EPISODE, server, title = id, parentId = "season-1", grandparentId = "42", grandparentTitle = "Show on $server", index = 1,
        )
        fun albumTrack(server: String, id: String) = testMediaItem(
            id, MediaKind.TRACK, server, title = id, parentId = "album-1", parentTitle = "Album on $server", grandparentId = "artist-1",
            grandparentTitle = "Artist", parentIndex = 1, index = 1,
        )
        h.seed(
            downloads = listOf("srv-a:e1", "srv-b:e2", "srv-a:t1", "srv-b:t2").associateWith { progress(it) },
            metadata = mapOf(
                "srv-a:e1" to episode("srv-a", "e1"),
                "srv-b:e2" to episode("srv-b", "e2"),
                "srv-a:t1" to albumTrack("srv-a", "t1"),
                "srv-b:t2" to albumTrack("srv-b", "t2"),
            ),
        )

        assertEquals(setOf("srv-a:42", "srv-b:42"), c.downloadedShows.map { it.globalKey }.toSet())
        assertEquals(setOf("srv-a:album-1", "srv-b:album-1"), c.downloadedAlbums.map { it.globalKey }.toSet())
        assertEquals(listOf("e1"), c.getDownloadedEpisodesForShow("srv-a:42").map { it.id })
        assertEquals(listOf("t2"), c.getDownloadedTracksForAlbum("srv-b:album-1").map { it.id })
        // The other server's copy does not inflate this show's queued count.
        assertEquals("1/1 episodes", c.getProgress("srv-a:42")?.currentFile)
        assertEquals("1/1 tracks", c.getAggregateProgressForArtist(ServerId("srv-a"), "artist-1")?.currentFile)
    }

    // Ownership release

    @Test
    fun releasingAQueuedSharedOwnerRebindsTheRowAndKeepsItsQueueIntentForTheSurvivor() = runTest {
        val dms = DmsHarness.create()
        val key = "srv:shared-queued"
        val itemId = "shared-queued"
        val scopeA = PlexProfileScopeId.of(srv, "profile-a").value
        val scopeB = PlexProfileScopeId.of(srv, "profile-b").value
        dms.connection("srv", "plex")
        dms.profile("profile-a")
        dms.profile("profile-b")
        dms.data.insertDownload("srv", itemId, status = DownloadedMediaStatus.QUEUED, clientScopeId = scopeA)
        dms.library.addToQueue(key, priority = 37)
        dms.library.addDownloadOwner("profile-a", key, BackendKind.PLEX.id, scopeA)
        dms.library.addDownloadOwner("profile-b", key, BackendKind.PLEX.id, scopeB)
        dms.putPlexMetadata(scopeB, itemId, plexFields("ratingKey" to itemId, "type" to "movie", "title" to "Profile B snapshot"))
        dms.plexCache.pinForOffline(scopeB, itemId)
        val itemB = ownedMovie.copy(id = itemId, title = "Profile B snapshot")
        val clientB = ClaimOnlyBackend(scopeId = scopeB).apply { items = { itemB } }
        val resolvedScopes = mutableListOf<String?>()
        val queueResumed = CompletableDeferred<MediaBackend>()
        val h = harness(dms, profile = "profile-b") {
            dms.manager(
                clientResolver = { id, scope -> resolvedScopes += scope; clientB.takeIf { id == srv && scope == scopeB } },
                downloader = FakeNativeDownloader(),
                queueProcessorOverride = { queueResumed.complete(it) },
            )
        }
        h.load()

        h.controller.releaseDownloadsForProfileServers("profile-a", setOf("srv"))

        assertEquals(scopeB, dms.library.getDownloadedMedia(key)?.client_scope_id)
        assertTrue(dms.library.getDownloadOwnerKeysForProfile("profile-a").isEmpty())
        assertEquals(setOf(key), dms.library.getDownloadOwnerKeysForProfile("profile-b"))
        assertTrue(h.controller.isQueued(key))

        resolvedScopes.clear()
        assertEquals("Profile B snapshot", h.manager.lookupMetadata(srv, itemId)?.title)
        assertTrue(scopeB in resolvedScopes)
        assertFalse(scopeA in resolvedScopes)

        // The surviving owner does not duplicate the row.
        assertEquals(0, h.controller.queueDownload(itemB, clientB))
        val queue = dms.library.getQueue()
        assertEquals(listOf(key to 37L), queue.map { it.media_global_key to it.priority })
        assertEquals(key, dms.library.getNextQueueItem()?.media_global_key)

        h.manager.resumeQueuedDownloads(clientB)
        assertSame(clientB, withContext(kotlinx.coroutines.Dispatchers.Default) { withTimeout(2.seconds) { queueResumed.await() } })
        assertEquals(listOf(key to 37L), dms.library.getQueue().map { it.media_global_key to it.priority })
    }

    @Test
    fun deletingOneOwnerDoesNotMigrateACompletedSharedRow() = runTest {
        val dms = DmsHarness.create()
        val key = "srv:shared-completed"
        val scopeA = PlexProfileScopeId.of(srv, "profile-a").value
        val scopeB = PlexProfileScopeId.of(srv, "profile-b").value
        dms.connection("srv", "plex")
        dms.profile("profile-a")
        dms.profile("profile-b")
        dms.data.insertDownload("srv", "shared-completed", status = COMPLETED, clientScopeId = scopeA)
        dms.library.addDownloadOwner("profile-a", key, BackendKind.PLEX.id, scopeA)
        dms.library.addDownloadOwner("profile-b", key, BackendKind.PLEX.id, scopeB)
        val h = harness(dms, profile = "profile-b")

        h.controller.deleteDownloadsForProfile("profile-a")

        assertEquals(scopeA, dms.library.getDownloadedMedia(key)?.client_scope_id)
        assertTrue(dms.library.getDownloadOwnerKeysForProfile("profile-a").isEmpty())
        assertEquals(setOf(key), dms.library.getDownloadOwnerKeysForProfile("profile-b"))
    }

    @Test
    fun releaseDownloadsForProfileServersRemovesOnlyTheRemovedConnectionsDownloads() = runTest {
        val dms = DmsHarness.create()
        dms.library.addDownloadOwner("test-profile", "srv:1")
        dms.library.addDownloadOwner("profile-b", "srv:1")
        dms.library.addDownloadOwner("test-profile", "other:2")
        val h = harness(dms)
        h.seed(
            downloads = mapOf("srv:1" to progress("srv:1"), "other:2" to progress("other:2")),
            metadata = mapOf("srv:1" to ownedMovie, "other:2" to ownedMovie.copy(id = "2", serverId = "other")),
        )

        h.controller.releaseDownloadsForProfileServers("test-profile", setOf("srv"))

        assertEquals(setOf("other:2"), dms.library.getDownloadOwnerKeysForProfile("test-profile"))
        assertEquals(setOf("srv:1"), dms.library.getDownloadOwnerKeysForProfile("profile-b"))
        assertEquals(setOf("other:2"), h.controller.downloads.keys)
    }

    private suspend fun releaseEvents(owners: List<String>, active: String, releasing: String): Pair<ControllerHarness, List<DeletionEvent>> {
        val dms = DmsHarness.create()
        for (owner in owners) {
            dms.profile(owner)
            dms.library.addDownloadOwner(owner, "srv:1")
        }
        val h = harness(dms, profile = active)
        h.seed(downloads = mapOf("srv:1" to progress("srv:1")), metadata = mapOf("srv:1" to ownedMovie))
        val events = FlowRecorder(h.deletionNotifier.events, dms.scope)
        h.controller.releaseDownloadsForProfileServers(releasing, setOf("srv"))
        return h to events.drain().also { events.cancel() }
    }

    @Test
    fun releasingASharedDownloadForTheActiveProfileEmitsOneDownloadOnlyDeletionEvent() = runTest {
        val (h, events) = releaseEvents(listOf("test-profile", "profile-b"), active = "test-profile", releasing = "test-profile")

        assertEquals(setOf("srv:1"), h.dms.library.getDownloadOwnerKeysForProfile("profile-b"))
        assertTrue(h.controller.downloads.isEmpty())
        assertEquals(listOf("srv:1"), events.map { it.globalKey })
        assertTrue(events.single().isDownloadOnly)
    }

    @Test
    fun releasingASharedDownloadForANonActiveProfileEmitsNoDeletionEvent() = runTest {
        val (h, events) = releaseEvents(listOf("profile-a", "test-profile"), active = "test-profile", releasing = "profile-a")

        assertTrue(h.dms.library.getDownloadOwnerKeysForProfile("profile-a").isEmpty())
        assertEquals(setOf("srv:1"), h.controller.downloads.keys)
        assertTrue(events.isEmpty())
    }

    @Test
    fun releasingTheSoleOwnerDeletesPhysicallyAndEmitsExactlyOneDeletionEvent() = runTest {
        val (h, events) = releaseEvents(listOf("test-profile"), active = "test-profile", releasing = "test-profile")

        assertTrue(h.dms.library.getDownloadOwnerKeysForProfile("test-profile").isEmpty())
        assertTrue(h.controller.downloads.isEmpty())
        assertEquals(listOf("srv:1"), events.map { it.globalKey })
        assertTrue(events.single().isDownloadOnly)
    }
}

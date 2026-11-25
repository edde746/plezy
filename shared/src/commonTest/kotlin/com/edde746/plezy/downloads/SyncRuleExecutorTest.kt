package com.edde746.plezy.downloads

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.data.TestClock
import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.data.downloads.SyncRuleFilter
import com.edde746.plezy.data.downloads.SyncRuleTarget
import com.edde746.plezy.data.testData
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.SpecialsOrdering
import com.edde746.plezy.servers.Connectivity
import com.edde746.plezy.servers.ConnectivityLink
import com.edde746.plezy.servers.OfflineWatchActionType
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertSame
import kotlin.test.assertTrue
import kotlin.test.fail

class SyncRuleExecutorTest {
    private val clock = TestClock()
    private val data = testData(clock)
    private var links = Connectivity.of(ConnectivityLink.WIFI)
    private var wifiOnly = false
    private val executor = SyncRuleExecutor(
        rules = data.syncRules,
        watchQueue = data.offlineWatch,
        connectivity = { links },
        cellularBlocked = { it.isCellularOnly && wifiOnly },
        ordering = { SpecialsOrdering.SPECIALS_LAST },
        clock = { clock.now },
    )

    @AfterTest
    fun close() = data.close()

    private class Servers(vararg clients: MediaBackend, val offline: Set<String> = emptySet()) : SyncRuleServers {
        private val byId = clients.associateBy { it.serverId }
        override fun client(serverId: ServerId) = byId[serverId]
        override fun isServerOnline(serverId: ServerId) = serverId in byId && serverId.value !in offline
    }

    private fun item(id: String, kind: MediaKind, backend: BackendKind = BackendKind.PLEX, viewCount: Int = 0, season: Int? = null, index: Int? = null, aired: String? = null) =
        MediaItem(id = id, backend = backend, kind = kind, title = id, viewCount = viewCount, parentIndex = season, index = index, originallyAvailableAt = aired)

    private fun episode(id: String, season: Int, index: Int, aired: String? = null, played: Boolean = false) =
        item(id, MediaKind.EPISODE, viewCount = if (played) 1 else 0, season = season, index = index, aired = aired)

    private suspend fun run(
        profileId: String,
        servers: SyncRuleServers,
        downloads: Map<String, DownloadedMediaStatus> = emptyMap(),
        metadata: Map<String, MediaItem> = emptyMap(),
        associated: MutableList<String> = mutableListOf(),
        queue: QueueSyncRuleDownload = { _, _, _, _ -> true },
        force: Boolean = true,
    ) = executor.executeSyncRules(profileId, servers, downloads, metadata, { _, key -> associated += key }, queue, isOffline = false, force = force)

    private fun jellyfinShow(scope: String): FakeMediaBackend = FakeMediaBackend("jf-machine", BackendKind.JELLYFIN, scopeId = scope).apply {
        items = { id -> item(id, MediaKind.SHOW, BackendKind.JELLYFIN) }
        playableDescendants = { listOf(item("ep-1", MediaKind.EPISODE, BackendKind.JELLYFIN)) }
    }

    @Test
    fun aProfileScopedRuleExecutesThroughTheActiveClient() = runTest {
        val userA = jellyfinShow("jf-machine/user-a")
        data.syncRules.upsert("profile-a", ServerId("jf-machine"), "show-1", SyncRuleTarget.SHOW, 1)
        // Another scope's and another profile's watched marks don't hide the episode.
        data.offlineWatch.insertMark(null, ServerId("jf-machine"), "jf-machine/user-b", "ep-1", OfflineWatchActionType.WATCHED)
        data.offlineWatch.insertMark("profile-b", ServerId("jf-machine"), "jf-machine/user-a", "ep-1", OfflineWatchActionType.WATCHED)

        val queued = mutableListOf<Pair<MediaItem, MediaBackend>>()
        val results = run("profile-a", Servers(userA), queue = { item, client, _, _ -> queued += item to client; true })

        assertEquals(1, results.single().queuedCount)
        assertSame(userA, queued.single().second)
        assertTrue("fetchPlayableDescendants:show-1" in userA.calls)
    }

    @Test
    fun aShowRuleQueuesLaterEpisodesAtTheRulesQuality() = runTest {
        val userA = jellyfinShow("jf-machine/user-a")
        data.syncRules.upsert("profile-a", ServerId("jf-machine"), "show-1", SyncRuleTarget.SHOW, 1, transcodeQuality = TranscodeQualityPreset.P720_2MBPS)

        val qualities = mutableListOf<TranscodeQualityPreset>()
        run("profile-a", Servers(userA), queue = { _, _, _, quality -> qualities += quality; true })

        assertEquals(listOf(TranscodeQualityPreset.P720_2MBPS), qualities)
    }

    @Test
    fun aProfileScopedRuleExcludesOnlyTheActiveProfilesLocalWatchedActions() = runTest {
        val userA = jellyfinShow("jf-machine/user-a")
        data.syncRules.upsert("profile-a", ServerId("jf-machine"), "show-1", SyncRuleTarget.SHOW, 1)
        data.offlineWatch.insertMark("profile-a", ServerId("jf-machine"), "jf-machine/user-a", "ep-1", OfflineWatchActionType.WATCHED)

        val queued = mutableListOf<MediaItem>()
        val results = run("profile-a", Servers(userA), queue = { item, _, _, _ -> queued += item; true })

        assertTrue(results.isEmpty())
        assertTrue(queued.isEmpty())
        assertTrue("fetchPlayableDescendants:show-1" in userA.calls)
    }

    @Test
    fun aProfileScopedRuleDoesNotExecuteForAnotherProfile() = runTest {
        val userB = FakeMediaBackend("jf-machine", BackendKind.JELLYFIN, scopeId = "jf-machine/user-b")
        data.syncRules.upsert("profile-a", ServerId("jf-machine"), "show-1", SyncRuleTarget.SHOW, 1)

        val results = run("profile-b", Servers(userB))

        assertTrue(results.isEmpty())
        assertTrue(userB.calls.isEmpty())
    }

    @Test
    fun aProfileScopedRuleCountsSharedPublicDownloadsAsAlreadyPresent() = runTest {
        val userB = jellyfinShow("jf-machine/user-b")
        val rule = data.syncRules.upsert("profile-b", ServerId("jf-machine"), "show-1", SyncRuleTarget.SHOW, 1)
        val associated = mutableListOf<String>()
        val queued = mutableListOf<MediaItem>()

        val results = run(
            "profile-b",
            Servers(userB),
            downloads = mapOf("jf-machine:ep-1" to DownloadedMediaStatus.COMPLETED),
            associated = associated,
            queue = { item, _, _, _ -> queued += item; true },
        )

        assertTrue(results.isEmpty())
        assertTrue(queued.isEmpty())
        assertEquals(listOf("jf-machine:ep-1"), associated)
        assertTrue(data.syncRules.rule(rule.globalKey)!!.downloadLinksInitialized)
    }

    @Test
    fun aShowRuleRespectsIncludeSpecialsOffWhenExpandingEpisodes() = runTest {
        val client = FakeMediaBackend("plex-machine").apply {
            playableDescendants = {
                listOf(
                    episode("s1e1", 1, 1, "2022-10-05"),
                    episode("s0e1", 0, 1, "2022-10-27"),
                    episode("s1e2", 1, 2, "2022-11-02"),
                )
            }
        }
        val rule = data.syncRules.upsert("profile-a", ServerId("plex-machine"), "show-1", SyncRuleTarget.SHOW, 0, includeSpecials = false)
        val queued = mutableListOf<MediaItem>()

        val results = run(
            "profile-a",
            Servers(client),
            metadata = mapOf(rule.globalKey to item("show-1", MediaKind.SHOW)),
            queue = { item, _, _, _ -> queued += item; true },
        )

        assertEquals(2, results.single().queuedCount)
        assertEquals(listOf("s1e1", "s1e2"), queued.map { it.id })
        assertEquals(listOf("fetchPlayableDescendants:show-1"), client.calls)
    }

    private class ListClient(serverId: String, backend: BackendKind, private val collection: List<MediaItem> = emptyList(), private val playlist: List<MediaItem> = emptyList()) :
        FakeMediaBackend(serverId, backend) {
        val pageCalls = mutableListOf<Pair<Int?, Int?>>()

        init {
            items = { null }
        }

        override suspend fun fetchPlaylistPage(id: String, start: Int?, size: Int?): LibraryPage<MediaItem> {
            assertEquals("playlist-1", id)
            pageCalls += start to size
            return LibraryPage(playlist, playlist.size, start ?: 0)
        }

        override suspend fun fetchCollectionPage(collectionId: String, start: Int?, size: Int?, libraryId: String?, libraryTitle: String?): LibraryPage<MediaItem> {
            assertEquals("collection-1", collectionId)
            pageCalls += start to size
            return LibraryPage(collection, collection.size, start ?: 0)
        }
    }

    @Test
    fun aJellyfinPlaylistSyncAssociatesAnAlreadyDownloadedMember() = runTest {
        val client = ListClient("jf-machine", BackendKind.JELLYFIN, playlist = listOf(item("episode-1", MediaKind.EPISODE, BackendKind.JELLYFIN)))
        val rule = data.syncRules.upsert("profile-a", ServerId("jf-machine"), "playlist-1", SyncRuleTarget.PLAYLIST, 0, downloadFilter = SyncRuleFilter.ALL)
        val associated = mutableListOf<String>()

        val results = run(
            "profile-a",
            Servers(client),
            downloads = mapOf("jf-machine:episode-1" to DownloadedMediaStatus.COMPLETED),
            associated = associated,
            queue = { _, _, _, _ -> fail("an already-downloaded playlist member must not be queued") },
        )

        assertTrue(results.isEmpty())
        assertEquals(listOf("jf-machine:episode-1"), associated)
        assertEquals(listOf<Pair<Int?, Int?>>(0 to 200), client.pageCalls)
        assertTrue(data.syncRules.rule(rule.globalKey)!!.downloadLinksInitialized)
    }

    @Test
    fun aCollectionRulePagesThroughTheCollectionApiInsteadOfMetadataChildren() = runTest {
        val client = ListClient("plex-machine", BackendKind.PLEX, collection = listOf(item("movie-1", MediaKind.MOVIE)))
        val rule = data.syncRules.upsert("profile-a", ServerId("plex-machine"), "collection-1", SyncRuleTarget.COLLECTION, 0, downloadFilter = SyncRuleFilter.ALL)
        val queued = mutableListOf<MediaItem>()
        val associated = mutableListOf<String>()

        val results = run(
            "profile-a",
            Servers(client),
            metadata = mapOf(rule.globalKey to item("collection-1", MediaKind.COLLECTION)),
            associated = associated,
            queue = { item, _, _, _ -> queued += item; true },
        )

        assertEquals(1, results.single().queuedCount)
        assertEquals("movie-1", queued.single().id)
        assertEquals(listOf("plex-machine:movie-1"), associated)
        assertTrue(data.syncRules.rule(rule.globalKey)!!.downloadLinksInitialized)
        assertEquals(listOf<Pair<Int?, Int?>>(0 to 100), client.pageCalls)
        assertFalse(client.calls.any { it.startsWith("fetchChildren") })
    }

    @Test
    fun anUnwatchedCollectionRuleExpandsEachMemberOnceAndKeepsWatchedMembersInMembership() = runTest {
        val client = ListClient("plex-machine", BackendKind.PLEX, collection = listOf(item("show-1", MediaKind.SHOW))).apply {
            playableDescendants = { listOf(episode("ep-1", 1, 1), episode("ep-2", 1, 2, played = true)) }
        }
        val rule = data.syncRules.upsert("profile-a", ServerId("plex-machine"), "collection-1", SyncRuleTarget.COLLECTION, 0, downloadFilter = SyncRuleFilter.UNWATCHED)
        val queued = mutableListOf<MediaItem>()
        val associated = mutableListOf<String>()

        val results = run(
            "profile-a",
            Servers(client),
            downloads = mapOf("plex-machine:ep-2" to DownloadedMediaStatus.COMPLETED),
            metadata = mapOf(rule.globalKey to item("collection-1", MediaKind.COLLECTION)),
            associated = associated,
            queue = { item, _, _, _ -> queued += item; true },
        )

        assertEquals(listOf("fetchPlayableDescendants:show-1"), client.calls.filter { it.startsWith("fetchPlayableDescendants") })
        assertEquals(listOf("ep-1"), queued.map { it.id })
        // The watched member stays associated, so removing the rule removes it too.
        assertEquals(listOf("plex-machine:ep-2", "plex-machine:ep-1"), associated)
        assertEquals(1, results.single().queuedCount)
    }

    @Test
    fun aLegacyListBackfillAssociatesActiveMembersWithoutQueueing() = runTest {
        val client = ListClient("plex-machine", BackendKind.PLEX, collection = listOf(item("movie-1", MediaKind.MOVIE)))
        val rule = data.syncRules.upsert("profile-a", ServerId("plex-machine"), "collection-1", SyncRuleTarget.COLLECTION, 0, downloadFilter = SyncRuleFilter.ALL)
        val associated = mutableListOf<String>()

        val backfilled = executor.backfillListRuleDownloadLinks(
            rule,
            Servers(client),
            mapOf("plex-machine:movie-1" to DownloadedMediaStatus.COMPLETED),
            mapOf(rule.globalKey to item("collection-1", MediaKind.COLLECTION)),
        ) { _, key -> associated += key }

        assertTrue(backfilled)
        assertEquals(listOf("plex-machine:movie-1"), associated)
        assertTrue(data.syncRules.rule(rule.globalKey)!!.downloadLinksInitialized)
    }

    @Test
    fun aBackgroundPassWaitsOutTheCooldownAndCellularWaitsLonger() = runTest {
        val client = jellyfinShow("jf-machine/user-a")
        data.syncRules.upsert("profile-a", ServerId("jf-machine"), "show-1", SyncRuleTarget.SHOW, 0)
        var queued = 0
        val queue: QueueSyncRuleDownload = { _, _, _, _ -> queued++; true }

        run("profile-a", Servers(client), queue = queue, force = false)
        assertEquals(1, queued)
        clock.now += 29 * 60_000L
        run("profile-a", Servers(client), queue = queue, force = false)
        assertEquals(1, queued)
        // A forced run ignores the cooldown; a pass for another profile has its own.
        run("profile-a", Servers(client), queue = queue, force = true)
        assertEquals(2, queued)
        links = Connectivity.of(ConnectivityLink.MOBILE)
        clock.now += 60 * 60_000L
        run("profile-a", Servers(client), queue = queue, force = false)
        assertEquals(2, queued)
        wifiOnly = true
        run("profile-a", Servers(client), queue = queue, force = true)
        assertEquals(2, queued)
    }
}

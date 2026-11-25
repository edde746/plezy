package com.edde746.plezy.downloads

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.COMPLETED
import com.edde746.plezy.jellyfin.JellyfinApiCache
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.profiles.plexHomeProfileId
import com.edde746.plezy.servers.OfflineWatchActionType
import com.edde746.plezy.servers.PlexProfileScopeId
import com.edde746.plezy.servers.PlexTransferScopeId
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class DownloadsControllerMetadataTest {
    private val harnesses = mutableListOf<ControllerHarness>()
    private var dmsHarness: DmsHarness? = null

    @AfterTest
    fun close() {
        harnesses.forEach { it.controller.dispose() }
        dmsHarness?.close()
    }

    private suspend fun dms(wrapDriver: ((app.cash.sqldelight.db.SqlDriver) -> app.cash.sqldelight.db.SqlDriver)? = null) =
        DmsHarness.create(wrapDriver = wrapDriver).also { dmsHarness = it }

    private suspend fun controller(dms: DmsHarness, profile: String? = "test-profile", configure: ControllerHarness.() -> Unit = {}) =
        ControllerHarness(dms, activeProfileId = profile).also { harnesses += it; it.configure(); it.controller.ensureInitialized() }

    private fun completed(vararg keys: String) = keys.associateWith { DownloadProgress(it, COMPLETED) }

    private fun obj(json: String) = Json.parseToJsonElement(json) as JsonObject

    // Jellyfin

    private val jf = ServerId("jf-machine")

    private fun DmsHarness.jellyfinUser(user: String) = connection(
        "jf-machine/$user",
        "jellyfin",
        obj(
            """{"baseUrl":"https://jf.example.com","serverName":"Shared JF","serverMachineId":"jf-machine","userId":"$user",
            |"userName":"$user","accessToken":"token-$user","deviceId":"device"}""".trimMargin(),
        ),
    )

    private suspend fun DmsHarness.pinJellyfin(user: String, id: String, json: String) {
        data.apiCache.put("jf-machine/$user", "/Users/$user/Items/$id", obj(json))
        jellyfinCache.pinForOffline("jf-machine/$user", id)
    }

    private suspend fun DmsHarness.jellyfinDownload(id: String, owners: List<String> = listOf("test-profile"), type: String = "episode", backendId: String? = null) {
        val episode = type == "episode"
        data.insertDownload(
            "jf-machine", id, type = type, status = COMPLETED, clientScopeId = "jf-machine/user-a",
            parentRatingKey = if (episode) "season-1" else null, grandparentRatingKey = if (episode) "show-1" else null,
        )
        for (owner in owners) library.addDownloadOwner(owner, "jf-machine:$id", backendId, if (backendId != null) "jf-machine/user-a" else null)
    }

    private fun jellyfinClient(user: String) = FakeMediaBackend("jf-machine", BackendKind.JELLYFIN, scopeId = "jf-machine/$user")

    private fun episodeJson(id: String, name: String, played: Boolean = false) =
        """{"Id":"$id","Type":"Episode","Name":"$name","SeriesId":"show-1","SeasonId":"season-1","UserData":{"PlayCount":${if (played) 1 else 0}${if (played) ",\"Played\":true" else ""}}}"""

    @Test
    fun parentMetadataLoadsFromTheExactActiveJellyfinUserScope() = runTest {
        val dms = dms()
        dms.jellyfinUser("user-a")
        dms.jellyfinUser("user-b")
        dms.pinJellyfin("user-a", "show-1", """{"Id":"show-1","Type":"Series","Name":"Scoped Show A","RecursiveItemCount":1,"UserData":{"UnplayedItemCount":1}}""")
        dms.pinJellyfin("user-a", "season-1", """{"Id":"season-1","Type":"Season","Name":"Season A","SeriesId":"show-1","SeriesName":"Scoped Show A","UserData":{"UnplayedItemCount":1}}""")
        dms.pinJellyfin(
            "user-a", "ep-1",
            """{"Id":"ep-1","Type":"Episode","Name":"Episode A","SeriesId":"show-1","SeriesName":"Scoped Show A","SeasonId":"season-1","SeasonName":"Season A","UserData":{"PlayCount":0}}""",
        )
        dms.pinJellyfin("user-b", "show-1", """{"Id":"show-1","Type":"Series","Name":"Wrong User Show","RecursiveItemCount":1,"UserData":{"UnplayedItemCount":0}}""")
        dms.jellyfinDownload("ep-1")
        val h = controller(dms) { servers.register(jellyfinClient("user-a")) }
        h.load()

        h.controller.refreshMetadataFromCache()

        assertEquals("Episode A", h.controller.getMetadata("jf-machine:ep-1")?.title)
        assertEquals("Scoped Show A", h.controller.getMetadata("jf-machine:show-1")?.title)
        assertEquals("Season A", h.controller.getMetadata("jf-machine:season-1")?.title)
    }

    @Test
    fun refreshMetadataFromCachePrefersTheActiveJellyfinUserScope() = runTest {
        val dms = dms()
        dms.jellyfinUser("user-a")
        dms.jellyfinUser("user-b")
        dms.pinJellyfin("user-a", "ep-1", episodeJson("ep-1", "Wrong User Episode"))
        dms.pinJellyfin("user-b", "ep-1", episodeJson("ep-1", "Active User Episode", played = true))
        dms.jellyfinDownload("ep-1")
        val h = controller(dms) { servers.register(jellyfinClient("user-b")) }
        h.load()

        h.controller.refreshMetadataFromCache()

        assertEquals("Active User Episode", h.controller.getMetadata("jf-machine:ep-1")?.title)
        assertEquals(true, h.controller.getMetadata("jf-machine:ep-1")?.isWatched)
    }

    @Test
    fun refreshMetadataFromCacheAppliesTheScopedJellyfinOfflineWatchOverlay() = runTest {
        val dms = dms()
        dms.jellyfinUser("user-a")
        dms.jellyfinUser("user-b")
        dms.pinJellyfin("user-b", "ep-1", episodeJson("ep-1", "Active User Episode"))
        dms.jellyfinDownload("ep-1")
        dms.data.offlineWatch.insertMark("test-profile", jf, "jf-machine/user-b", "ep-1", OfflineWatchActionType.WATCHED)
        val h = controller(dms) { servers.register(jellyfinClient("user-b")) }
        h.load()

        h.controller.refreshMetadataFromCache()

        assertEquals(true, h.controller.getMetadata("jf-machine:ep-1")?.isWatched)
    }

    @Test
    fun aColdJellyfinProfileRestoresItsPersistedScopedQueuedWatchAction() = runTest {
        val dms = dms()
        dms.jellyfinUser("user-a")
        dms.jellyfinUser("user-b")
        dms.binding("test-profile", "jf-machine/user-b", "user-b")
        dms.pinJellyfin("user-b", "ep-1", episodeJson("ep-1", "Offline User B Episode"))
        dms.jellyfinDownload("ep-1")
        dms.data.offlineWatch.insertMark("test-profile", jf, "jf-machine/user-b", "ep-1", OfflineWatchActionType.WATCHED)
        val h = controller(dms)
        h.load()

        h.controller.refreshMetadataFromCache()

        assertEquals("Offline User B Episode", h.controller.getMetadata("jf-machine:ep-1")?.title)
        assertEquals(true, h.controller.getMetadata("jf-machine:ep-1")?.isWatched)
    }

    @Test
    fun coldJellyfinHydrationIssuesAConstantNumberOfSelectsAsDownloadsGrow() = runTest {
        var selects = 0
        val dms = dms(wrapDriver = { ObservedDriver(it) { _, _ -> selects++ } })
        dms.jellyfinUser("user-a")
        dms.jellyfinUser("user-b")
        dms.binding("test-profile", "jf-machine/user-b", "user-b")
        dms.pinJellyfin("user-b", "show-1", """{"Id":"show-1","Type":"Series","Name":"Show B","UserData":{"UnplayedItemCount":1}}""")
        dms.pinJellyfin("user-b", "season-1", """{"Id":"season-1","Type":"Season","Name":"Season B","SeriesId":"show-1","UserData":{"UnplayedItemCount":1}}""")
        suspend fun addEpisode(index: Int) {
            dms.pinJellyfin("user-b", "ep-$index", episodeJson("ep-$index", "Episode $index"))
            dms.jellyfinDownload("ep-$index")
        }
        suspend fun selectsToHydrate(episodes: Int): Int {
            val h = controller(dms)
            h.load()
            selects = 0
            h.controller.refreshMetadataFromCache()
            val counted = selects
            for (i in 1..episodes) assertEquals("Episode $i", h.controller.getMetadata("jf-machine:ep-$i")?.title)
            assertEquals("Show B", h.controller.getMetadata("jf-machine:show-1")?.title)
            assertEquals("Season B", h.controller.getMetadata("jf-machine:season-1")?.title)
            h.controller.dispose()
            return counted
        }

        addEpisode(1)
        val oneEpisode = selectsToHydrate(1)
        for (i in 2..40) addEpisode(i)

        assertEquals(oneEpisode, selectsToHydrate(40))
    }

    @Test
    fun offlineWatchHydrationReadsTheDownloadsTakenBeforeItsDatabaseReads() = runTest {
        val dms = dms()
        val h = controller(dms)
        val item = testMediaItem("1", MediaKind.MOVIE, "srv", title = "Movie").copy(viewCount = 0)
        h.seed(downloads = completed("srv:1", "srv:2", "srv:3"), metadata = mapOf(item.globalKey to item), owned = setOf("srv:1", "srv:2"))
        dms.data.offlineWatch.insertMark("test-profile", srv, plexScope("test-profile"), "1", OfflineWatchActionType.WATCHED)

        // Claims another download while the hydration waits on the database.
        val claimant = object : FakeMediaBackend("srv") {
            override suspend fun fetchCollectionMemberships(itemIds: Set<String>) = emptyList<com.edde746.plezy.model.CollectionMembership>()
        }.apply { items = { null } }
        launch { h.controller.queueDownload(testMediaItem("3", MediaKind.MOVIE, "srv"), claimant) }
        h.controller.refreshMetadataFromCache()

        assertEquals(true, h.controller.getMetadata(item.globalKey)?.isWatched)
    }

    @Test
    fun aProfileSwitchDiscardsAnInFlightMetadataRefreshFromTheOldScope() = runTest {
        val dms = dms()
        dms.jellyfinUser("user-a")
        dms.data.insertDownload("jf-machine", "movie-1", status = COMPLETED, clientScopeId = "jf-machine/user-a")
        dms.library.addDownloadOwner("profile-a", "jf-machine:movie-1")
        dms.library.addDownloadOwner("profile-b", "jf-machine:movie-1")
        val fetchStarted = CompletableDeferred<Unit>()
        val releaseFetch = CompletableDeferred<Unit>()
        fun movie(id: String, title: String) = testMediaItem(id, MediaKind.MOVIE, "jf-machine", BackendKind.JELLYFIN, title = title)
        val clientA = jellyfinClient("user-a").apply { items = { id -> fetchStarted.complete(Unit); releaseFetch.await(); movie(id, "Profile A") } }
        val h = controller(dms, "profile-a") { servers.register(clientA) }
        h.load()

        val staleRefresh = async { h.controller.refreshMetadataFromCache() }
        fetchStarted.await()
        // The new profile's server client is in place before its reload can run (the reload runs on another thread).
        h.servers.register(jellyfinClient("user-b").apply { items = { id -> movie(id, "Profile B") } })
        h.controller.setActiveProfileId("profile-b")
        releaseFetch.complete(Unit)
        staleRefresh.await()

        assertNotEquals("Profile A", h.controller.getMetadata("jf-machine:movie-1")?.title)
        until { h.controller.getMetadata("jf-machine:movie-1")?.title == "Profile B" }
    }

    @Test
    fun aSharedJellyfinCacheScopeSurvivesUntilItsFinalDownloadOwnerIsReleased() = runTest {
        val dms = dms()
        val scope = "jf-machine/user-a"
        dms.jellyfinUser("user-a")
        dms.profile("profile-a")
        dms.profile("profile-b")
        dms.jellyfinDownload("movie-1", owners = listOf("profile-a", "profile-b"), type = "movie", backendId = BackendKind.JELLYFIN.id)
        dms.data.apiCache.put(scope, "/Users/user-a/Items/movie-1", obj("""{"Id":"movie-1","Type":"Movie","Name":"Shared offline movie"}"""))
        val segments = JellyfinApiCache.mediaSegmentsEndpoint("movie-1")
        dms.data.apiCache.put(scope, segments, obj("""{"Items":[]}"""))
        dms.jellyfinCache.pinForOffline(scope, "movie-1")
        val h = controller(dms, "profile-a")

        h.controller.deleteDownloadsForProfile("profile-a")

        assertEquals(setOf("jf-machine:movie-1"), dms.library.getDownloadOwnerKeysForProfile("profile-b"))
        assertEquals("Shared offline movie", dms.jellyfinCache.getMetadata(scope, "movie-1")?.title)
        assertNotNull(dms.data.apiCache.get(scope, segments))

        h.controller.deleteDownloadsForProfile("profile-b")

        assertNull(dms.jellyfinCache.getMetadata(scope, "movie-1"))
        assertNull(dms.data.apiCache.get(scope, segments))
    }

    @Test
    fun lookupOfflineMetadataResolvesTheActiveProfileScopeNotTheDownloadCreatorScope() = runTest {
        val dms = dms()
        for ((profile, user) in listOf("profile-a" to "user-a", "profile-b" to "user-b")) {
            dms.jellyfinUser(user)
            dms.profile(profile)
            dms.binding(profile, "jf-machine/$user", user)
        }
        // Created under user A's scope; cached only in A's namespace.
        dms.jellyfinDownload("movie-1", owners = listOf("profile-a", "profile-b"), type = "movie", backendId = BackendKind.JELLYFIN.id)
        dms.pinJellyfin("user-a", "movie-1", """{"Id":"movie-1","Type":"Movie","Name":"User A Movie"}""")

        // Profile B never inherits the creator's scope: its own namespace has nothing cached.
        assertNull(controller(dms, "profile-b").controller.lookupOfflineMetadata(jf, "movie-1"))
        assertEquals("User A Movie", controller(dms, "profile-a").controller.lookupOfflineMetadata(jf, "movie-1")?.title)
    }

    // Plex

    private val srv = ServerId("srv")
    private val key = "srv:123"
    private fun plexScope(profile: String) = PlexProfileScopeId.of(srv, profile).value

    private suspend fun DmsHarness.pinPlex(scope: String, title: String, viewCount: Int, viewOffset: Long, id: String = "123", vararg extra: Pair<String, Any?>) {
        putPlexMetadata(scope, id, plexFields("ratingKey" to id, "title" to title, "type" to "movie", "viewCount" to viewCount, "viewOffset" to viewOffset, *extra))
        plexCache.pinForOffline(scope, id)
    }

    private suspend fun DmsHarness.seedPlexDownload(owners: List<String>) {
        connection("srv", "plex")
        owners.forEach(::profile)
        data.insertDownload("srv", "123", status = COMPLETED, clientScopeId = plexScope(owners.first()))
        for (owner in owners) library.addDownloadOwner(owner, key)
    }

    private suspend fun ControllerHarness.switchProfile(profile: String, settled: () -> Boolean) {
        controller.setActiveProfileId(profile)
        until { settled() }
    }

    @Test
    fun offlineProfileSwitchesSelectOnlyExactPlexOwnerSnapshotsAndKeepOnePhysicalRow() = runTest {
        val dms = dms()
        dms.seedPlexDownload(listOf("profile-a", "profile-b"))
        dms.pinPlex(plexScope("profile-a"), "Profile A snapshot", viewCount = 0, viewOffset = 12000)
        dms.pinPlex(plexScope("profile-b"), "Profile B snapshot", viewCount = 1, viewOffset = 0)
        val h = controller(dms, "profile-a")
        h.load()
        h.controller.refreshMetadataFromCache()

        assertEquals("Profile A snapshot", h.controller.getMetadata(key)?.title)
        assertEquals(12000L, h.controller.getMetadata(key)?.viewOffsetMs)

        h.switchProfile("profile-b") { h.controller.getMetadata(key)?.title == "Profile B snapshot" }
        assertEquals(true, h.controller.getMetadata(key)?.isWatched)

        h.switchProfile("profile-a") { h.controller.getMetadata(key)?.title == "Profile A snapshot" }
        assertEquals(false, h.controller.getMetadata(key)?.isWatched)
        assertNotNull(dms.library.getDownloadedMedia(key))
        assertEquals(2, dms.library.getValidDownloadOwnersForKey(key).size)
        for ((profile, title) in listOf("profile-a" to "Profile A snapshot", "profile-b" to "Profile B snapshot")) {
            assertTrue(dms.data.apiCache.isPinned(plexScope(profile), "/library/metadata/123"))
            assertEquals(title, dms.plexCache.getMetadata(plexScope(profile), "123")?.title)
        }
    }

    @Test
    fun aFullLogoutTransfersPlexMetadataToTheNextProfileWithoutPrivateState() = runTest {
        val dms = dms()
        dms.seedPlexDownload(listOf("profile-a", "profile-old-co-owner"))
        val transferScope = PlexTransferScopeId.of(srv).value
        val scopeB = plexScope("profile-b")
        dms.pinPlex(plexScope("profile-old-co-owner"), "Preserved download", viewCount = 1, viewOffset = 12000)
        val h = controller(dms, "profile-a")

        h.controller.detachDownloadsForLogout()

        assertEquals(transferScope, dms.library.getDownloadedMedia(key)?.client_scope_id)
        assertTrue(dms.library.getValidDownloadOwnersForKey(key).isEmpty())
        assertNull(dms.plexCache.getMetadata(plexScope("profile-a"), "123"))
        assertNull(dms.plexCache.getMetadata(plexScope("profile-old-co-owner"), "123"))
        val transferred = assertNotNull(dms.plexCache.getMetadata(transferScope, "123"))
        assertEquals("Preserved download", transferred.title)
        assertNull(transferred.viewCount)
        assertNull(transferred.viewOffsetMs)

        dms.sql("DELETE FROM profiles")
        dms.sql("DELETE FROM connections")
        dms.profile("profile-b")
        dms.connection("srv", "plex")
        val adopted = controller(dms, "profile-b")

        val owner = dms.library.getDownloadOwner("profile-b", key)
        assertEquals(scopeB, dms.library.getDownloadedMedia(key)?.client_scope_id)
        assertEquals(scopeB, owner?.client_scope_id)
        assertEquals(BackendKind.PLEX.id, owner?.backend)
        assertNull(dms.plexCache.getMetadata(transferScope, "123"))
        assertEquals("Preserved download", dms.plexCache.getMetadata(scopeB, "123")?.title)
        assertNull(adopted.controller.getMetadata(key)?.viewCount)
        assertNull(adopted.controller.getMetadata(key)?.viewOffsetMs)
    }

    @Test
    fun logoutRecoversLegacyPlexOwnershipWhenRowAndOwnerScopesAreAbsent() = runTest {
        val dms = dms()
        dms.seedPlexDownload(listOf("profile-a", "profile-b"))
        dms.data.db.write { q.downloadedMediaQueries.setClientScope(null, key) }
        val transferScope = PlexTransferScopeId.of(srv).value
        dms.pinPlex(plexScope("profile-b"), "Legacy owner snapshot", viewCount = 1, viewOffset = 4000)
        val h = controller(dms, "profile-a")

        h.manager.preparePlexMetadataForLogoutTransfer()

        assertTrue(dms.library.getValidDownloadOwnersForKey(key).isNotEmpty())
        assertEquals(transferScope, dms.library.getDownloadedMedia(key)?.client_scope_id)
        val transferred = assertNotNull(dms.plexCache.getMetadata(transferScope, "123"))
        assertEquals("Legacy owner snapshot", transferred.title)
        assertNull(transferred.viewCount)
        assertNull(transferred.viewOffsetMs)
    }

    @Test
    fun aMissingActivePlexOwnerScopeClearsThePriorProfileSnapshotWithoutBareFallback() = runTest {
        val dms = dms()
        dms.seedPlexDownload(listOf("profile-a", "profile-b"))
        dms.pinPlex(plexScope("profile-a"), "Profile A snapshot", viewCount = 0, viewOffset = 12000)
        dms.pinPlex("srv", "Legacy bare snapshot", viewCount = 1, viewOffset = 0)
        val h = controller(dms, "profile-a")
        h.load()
        h.controller.refreshMetadataFromCache()
        assertEquals("Profile A snapshot", h.controller.getMetadata(key)?.title)

        h.switchProfile("profile-b") { h.controller.getMetadata(key) == null }
        h.idle()
        h.controller.refreshMetadataFromCache()

        assertNull(h.controller.getMetadata(key))
        assertNotNull(dms.library.getDownloadedMedia(key))
    }

    @Test
    fun aDownloadKeptThroughPlexSignOutStaysWithItsPlexHomeUserUntilTheAccountReturns() = runTest {
        val dms = dms()
        val account = "plex-account"
        val homeProfile = plexHomeProfileId(account, "aaaaaaaaaaaaaaaa")
        val homeScope = plexScope(homeProfile)
        fun addAccount() = dms.connection(account, "plex", obj("""{"servers":[{"clientIdentifier":"srv"}]}"""))
        addAccount()
        dms.profile("profile-b")
        dms.data.insertDownload("srv", "123", status = COMPLETED, clientScopeId = homeScope)
        dms.library.addDownloadOwner(homeProfile, key, BackendKind.PLEX.id, homeScope)
        dms.pinPlex(homeScope, "Kept download", viewCount = 1, viewOffset = 0)
        // Signing out while keeping downloads removes the account, not the owner row or the pinned snapshot.
        dms.sql("DELETE FROM connections WHERE id = '$account'")

        val h = controller(dms, "profile-b")
        h.load()
        h.controller.refreshMetadataFromCache()
        assertTrue(h.controller.downloads.isEmpty())
        assertTrue(dms.library.getDownloadOwnerKeysForProfile("profile-b").isEmpty())

        addAccount()
        h.switchProfile(homeProfile) { h.controller.getMetadata(key)?.title == "Kept download" }
        assertEquals(setOf(key), h.controller.downloads.keys)
        assertEquals(true, h.controller.getMetadata(key)?.isWatched)
    }

    @Test
    fun aMissingEpisodeLeafDoesNotEvictParentsLoadedForADownloadedSibling() = runTest {
        val dms = dms()
        dms.connection("srv", "plex")
        dms.profile("profile-a")
        val scope = plexScope("profile-a")
        for (id in listOf("ep-1", "ep-2")) {
            dms.data.insertDownload("srv", id, type = "episode", status = COMPLETED, clientScopeId = scope, parentRatingKey = "season-1", grandparentRatingKey = "show-1")
            dms.library.addDownloadOwner("profile-a", "srv:$id")
        }
        suspend fun pin(id: String, vararg fields: Pair<String, Any?>) {
            dms.putPlexMetadata(scope, id, plexFields("ratingKey" to id, *fields))
            dms.plexCache.pinForOffline(scope, id)
        }
        pin("show-1", "type" to "show", "title" to "Shared Show")
        pin("season-1", "type" to "season", "title" to "Season 1", "parentRatingKey" to "show-1")
        pin("ep-1", "type" to "episode", "title" to "Available Episode", "parentRatingKey" to "season-1", "grandparentRatingKey" to "show-1")
        pin("ep-2", "type" to "episode", "title" to "Missing Episode", "parentRatingKey" to "season-1", "grandparentRatingKey" to "show-1")
        val h = controller(dms, "profile-a")
        h.load()
        assertEquals("Missing Episode", h.controller.getMetadata("srv:ep-2")?.title)
        dms.plexCache.deleteForItem(scope, "ep-2")

        h.controller.refreshMetadataFromCache()

        assertEquals("Available Episode", h.controller.getMetadata("srv:ep-1")?.title)
        assertNull(h.controller.getMetadata("srv:ep-2"))
        assertEquals("Shared Show", h.controller.getMetadata("srv:show-1")?.title)
        assertEquals("Season 1", h.controller.getMetadata("srv:season-1")?.title)
    }

    @Test
    fun scopedWatchWritebackMutatesOnlyTheActivePlexOwnerRowDespiteCoOwnership() = runTest {
        val dms = dms()
        dms.seedPlexDownload(listOf("profile-a", "profile-b"))
        val scopeA = plexScope("profile-a")
        val scopeB = plexScope("profile-b")
        dms.pinPlex(scopeA, "Profile A snapshot", viewCount = 0, viewOffset = 12000)
        dms.pinPlex(scopeB, "Profile B snapshot", viewCount = 0, viewOffset = 34000)
        val h = controller(dms, "profile-a") { servers.register(FakeMediaBackend("srv", scopeId = scopeA)) }
        h.load()
        h.controller.refreshMetadataFromCache()
        val item = assertNotNull(h.controller.getMetadata(key))

        h.watchNotifier.notifyWatched(item, cacheServerId = scopeA)
        until { dms.plexCache.getMetadata(scopeA, "123")?.isWatched == true }
        assertEquals(false, dms.plexCache.getMetadata(scopeB, "123")?.isWatched)

        h.watchNotifier.notifyWatched(item, cacheServerId = scopeB)
        // The writes land in event order: once a later event's write to the active row lands, the one before has run.
        h.watchNotifier.notifyWatched(item, isNowWatched = false, cacheServerId = scopeA)
        until { dms.plexCache.getMetadata(scopeA, "123")?.isWatched == false }
        assertEquals(false, dms.plexCache.getMetadata(scopeB, "123")?.isWatched)
    }

    @Test
    fun claimAndOwnerReleasePinAndDeleteMetadataPerPlexOwnerReference() = runTest {
        val dms = dms()
        dms.seedPlexDownload(listOf("profile-a", "profile-b"))
        dms.library.removeDownloadOwner("profile-b", key)
        val scopeA = plexScope("profile-a")
        val scopeB = plexScope("profile-b")
        dms.pinPlex(scopeA, "Profile A snapshot", viewCount = 0, viewOffset = 12000)
        val profileBItem = testMediaItem("123", MediaKind.MOVIE, "srv", title = "Profile B snapshot").copy(viewCount = 1)
        val clientB = object : FakeMediaBackend("srv", scopeId = scopeB) {
            override fun resolveDownloadArtwork(item: MediaItem) = emptyList<com.edde746.plezy.backend.DownloadArtworkSpec>()

            override suspend fun fetchCollectionMemberships(itemIds: Set<String>) = emptyList<com.edde746.plezy.model.CollectionMembership>()
        }.apply {
            items = { id ->
                dms.putPlexMetadata(scopeB, id, plexFields("ratingKey" to id, "title" to "Profile B snapshot", "type" to "movie", "viewCount" to 1, "viewOffset" to 0))
                profileBItem
            }
        }
        val h = controller(dms, "profile-b") { servers.register(clientB) }
        h.load()

        assertEquals(1, h.controller.queueDownload(profileBItem, clientB))
        assertEquals(2, dms.library.getValidDownloadOwnersForKey(key).size)
        assertEquals(1, dms.library.getAllDownloads().count { it.status == COMPLETED.code })
        assertTrue(dms.data.apiCache.isPinned(scopeA, "/library/metadata/123"))
        assertTrue(dms.data.apiCache.isPinned(scopeB, "/library/metadata/123"))

        h.controller.deleteDownloadsForProfile("profile-a")
        assertEquals(1, dms.library.getValidDownloadOwnersForKey(key).size)
        assertNotNull(dms.library.getDownloadedMedia(key))
        assertNull(dms.plexCache.getMetadata(scopeA, "123"))
        assertEquals("Profile B snapshot", dms.plexCache.getMetadata(scopeB, "123")?.title)

        h.controller.deleteDownload(key)
        assertTrue(dms.library.getValidDownloadOwnersForKey(key).isEmpty())
        assertNull(dms.library.getDownloadedMedia(key))
        assertNull(dms.plexCache.getMetadata(scopeB, "123"))
    }

    private suspend fun twoServerWatchedCopies(): ControllerHarness {
        val dms = dms()
        dms.profile("profile-a")
        val items = listOf("A", "B").map { server -> testMediaItem("123", MediaKind.MOVIE, server, title = "$server watched").copy(viewCount = 1) }
        val h = controller(dms, "profile-a")
        h.seed(downloads = completed("A:123", "B:123"), metadata = items.associateBy { it.globalKey })
        return h
    }

    @Test
    fun autoDeleteProtectsOnlyTheExactActiveGlobalKey() = runTest {
        val h = twoServerWatchedCopies()

        assertEquals(listOf("B watched"), h.controller.autoDeleteWatchedDownloads(activeGlobalKey = "A:123"))

        assertEquals(setOf("A:123"), h.controller.downloads.keys)
        assertNotNull(h.dms.library.getDownloadedMedia("A:123"))
        assertNull(h.dms.library.getDownloadedMedia("B:123"))
    }

    @Test
    fun autoDeleteRemovesBothSameIdDownloadsWithoutAnActiveKey() = runTest {
        val h = twoServerWatchedCopies()

        assertEquals(setOf("A watched", "B watched"), h.controller.autoDeleteWatchedDownloads().toSet())

        assertTrue(h.controller.downloads.isEmpty())
        assertNull(h.dms.library.getDownloadedMedia("A:123"))
        assertNull(h.dms.library.getDownloadedMedia("B:123"))
    }

    // Watch state of downloaded metadata

    private fun movie42(offset: Long, viewCount: Int) =
        testMediaItem("42", MediaKind.MOVIE, "srv", title = "Movie").copy(durationMs = 100_000, viewOffsetMs = offset, viewCount = viewCount)

    @Test
    fun watchedProgressEventsMarkDownloadedMetadataWatchedAndClearResume() = runTest {
        val h = controller(dms())
        val item = movie42(offset = 12_000, viewCount = 0)
        h.seed(downloads = completed("srv:42"), metadata = mapOf("srv:42" to item))

        h.watchNotifier.notifyProgress(item, viewOffset = 95_000, duration = 100_000, watchedThreshold = 0.9)

        until { h.controller.getMetadata("srv:42")?.isWatched == true }
        assertEquals(0L, h.controller.getMetadata("srv:42")?.viewOffsetMs)
    }

    @Test
    fun subThresholdProgressEventsUpdateDownloadedMetadataResume() = runTest {
        val h = controller(dms())
        val item = movie42(offset = 0, viewCount = 1)
        h.seed(downloads = completed("srv:42"), metadata = mapOf("srv:42" to item))

        h.watchNotifier.notifyProgress(item, viewOffset = 50_000, duration = 100_000, watchedThreshold = 0.9)

        until { h.controller.getMetadata("srv:42")?.viewOffsetMs == 50_000L }
        assertEquals(true, h.controller.getMetadata("srv:42")?.isWatched)
    }

    @Test
    fun showSeasonAndEpisodeEventsResolveByHierarchicalFreshness() = runTest {
        val h = controller(dms())
        val c = h.controller
        val show = testMediaItem("show-1", MediaKind.SHOW, "srv").copy(leafCount = 3, viewedLeafCount = 0)
        val season1 = testMediaItem("season-1", MediaKind.SEASON, "srv", parentId = "show-1").copy(leafCount = 2, viewedLeafCount = 0)
        val episode1 = testMediaItem("episode-1", MediaKind.EPISODE, "srv", parentId = "season-1", grandparentId = "show-1").copy(viewCount = 0, viewOffsetMs = 40_000)
        val episode2 = episode1.copy(id = "episode-2", viewOffsetMs = 50_000)
        val episode3 = episode1.copy(id = "episode-3", parentId = "season-2", viewOffsetMs = 60_000)
        h.seed(
            downloads = completed(episode1.globalKey, episode2.globalKey, episode3.globalKey),
            metadata = listOf(show, season1, episode1, episode2, episode3).associateBy { it.globalKey },
        )
        fun watched(item: MediaItem) = c.getMetadata(item.globalKey)?.isWatched

        h.watchNotifier.notifyWatched(show)
        until { watched(episode3) == true }
        assertEquals(true, watched(episode1))
        assertEquals(0L, c.getMetadata(episode2.globalKey)?.viewOffsetMs)

        h.watchNotifier.notifyWatched(season1, isNowWatched = false)
        until { watched(episode1) == false }
        assertEquals(false, watched(episode2))
        assertEquals(true, watched(episode3))

        h.watchNotifier.notifyWatched(episode1)
        until { watched(episode1) == true }
        assertEquals(false, watched(episode2))

        h.watchNotifier.notifyWatched(show, isNowWatched = false)
        until { watched(episode1) == false && watched(episode3) == false }
        assertEquals(false, watched(episode2))
        assertEquals(0L, c.getMetadata(episode3.globalKey)?.viewOffsetMs)
    }

    @Test
    fun queuedParentAndEpisodeOverridesSurviveAReload() = runTest {
        val dms = dms()
        dms.data.offlineWatch.insertMark("profile-a", srv, plexScope("profile-a"), "show-1", OfflineWatchActionType.WATCHED)
        dms.data.offlineWatch.insertMark("profile-a", srv, plexScope("profile-a"), "episode-1", OfflineWatchActionType.UNWATCHED)
        val episode1 = testMediaItem("episode-1", MediaKind.EPISODE, "srv", parentId = "season-1", grandparentId = "show-1").copy(viewCount = 0, viewOffsetMs = 45_000)
        val episode2 = episode1.copy(id = "episode-2", viewOffsetMs = 55_000)
        suspend fun hydrate(): DownloadsController {
            val h = controller(dms, "profile-a")
            h.seed(downloads = completed(episode1.globalKey, episode2.globalKey), metadata = mapOf(episode1.globalKey to episode1, episode2.globalKey to episode2))
            h.controller.refreshMetadataFromCache()
            return h.controller
        }

        var c = hydrate()
        assertEquals(false, c.getMetadata(episode1.globalKey)?.isWatched)
        assertEquals(0L, c.getMetadata(episode1.globalKey)?.viewOffsetMs)
        assertEquals(true, c.getMetadata(episode2.globalKey)?.isWatched)
        assertEquals(0L, c.getMetadata(episode2.globalKey)?.viewOffsetMs)
        c.dispose()

        c = hydrate()
        assertEquals(false, c.getMetadata(episode1.globalKey)?.isWatched)
        assertEquals(true, c.getMetadata(episode2.globalKey)?.isWatched)
    }

    @Test
    fun queuedOverlaysAreIsolatedToTheActiveProfile() = runTest {
        val dms = dms()
        dms.data.offlineWatch.insertMark("profile-a", srv, plexScope("profile-a"), "show-1", OfflineWatchActionType.WATCHED)
        dms.data.offlineWatch.insertMark("profile-b", srv, plexScope("profile-b"), "show-1", OfflineWatchActionType.UNWATCHED)
        val episode = testMediaItem("episode-1", MediaKind.EPISODE, "srv", parentId = "season-1", grandparentId = "show-1").copy(viewCount = 0)
        val h = controller(dms, "profile-a")
        h.seed(downloads = completed(episode.globalKey), metadata = mapOf(episode.globalKey to episode))

        h.controller.refreshMetadataFromCache()
        assertEquals(true, h.controller.getMetadata(episode.globalKey)?.isWatched)

        h.controller.setActiveProfileId("profile-b")
        h.controller.refreshMetadataFromCache()
        assertNull(h.controller.getMetadata(episode.globalKey))
        h.idle()
    }

    @Test
    fun queuedOverlaysAreIsolatedToTheActiveJellyfinClientScope() = runTest {
        val dms = dms()
        dms.data.offlineWatch.insertMark("test-profile", jf, "jf-machine/user-a", "show-1", OfflineWatchActionType.WATCHED)
        dms.data.offlineWatch.insertMark("test-profile", jf, "jf-machine/user-b", "show-1", OfflineWatchActionType.UNWATCHED)
        val episode = testMediaItem("episode-1", MediaKind.EPISODE, "jf-machine", BackendKind.JELLYFIN, parentId = "season-1", grandparentId = "show-1").copy(viewCount = 0)
        val h = controller(dms) { servers.register(jellyfinClient("user-a")) }
        h.seed(downloads = completed(episode.globalKey), metadata = mapOf(episode.globalKey to episode))

        h.controller.refreshMetadataFromCache()
        assertEquals(true, h.controller.getMetadata(episode.globalKey)?.isWatched)

        h.servers.register(jellyfinClient("user-b"))
        h.controller.refreshMetadataFromCache()
        assertEquals(false, h.controller.getMetadata(episode.globalKey)?.isWatched)
    }
}

package com.edde746.plezy.downloads

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.artworkStorageKey
import com.edde746.plezy.backend.buildArtworkSpecs
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.COMPLETED
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.PlexProfileScopeId
import com.edde746.plezy.servers.PlexTransferScopeId
import io.ktor.client.engine.mock.respond
import io.ktor.http.HttpStatusCode
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

internal fun plexFields(vararg pairs: Pair<String, Any?>): JsonObject = JsonObject(
    pairs.mapNotNull { (key, value) ->
        when (value) {
            null -> null
            is Number -> key to JsonPrimitive(value)
            else -> key to JsonPrimitive(value.toString())
        }
    }.toMap(),
)

/** A server whose items are [items]; it records each fetch in [FakeMediaBackend.calls] and builds artwork URLs. */
internal class ArtworkRepairBackend(serverId: String, private val known: Map<String, MediaItem>, scopeId: String? = null) :
    FakeMediaBackend(serverId, BackendKind.PLEX, scopeId = scopeId) {
    init {
        items = { id -> known[id] }
    }

    override fun resolveDownloadArtwork(item: MediaItem) = buildArtworkSpecs(item) { "https://example.test$it" }
}

class DownloadManagerServiceMetadataTest {
    private lateinit var harness: DmsHarness

    @AfterTest
    fun close() = harness.close()

    private fun jellyfinConfig(userId: String) = buildJsonObject {
        put("baseUrl", "https://jf.example")
        put("serverName", "Jellyfin")
        put("serverMachineId", "jf-machine")
        put("userId", userId)
        put("userName", userId)
        put("accessToken", "token-$userId")
        put("deviceId", "device")
    }

    private fun jellyfinItem(name: String) = buildJsonObject {
        put("Id", "item-1")
        put("Type", "Movie")
        put("Name", name)
    }

    @Test
    fun `active Jellyfin lookup does not fall back to the downloaded foreign user scope`() = runTest {
        harness = DmsHarness.create()
        harness.connection("jf-machine/user-a", "jellyfin", jellyfinConfig("user-a"))
        harness.data.insertDownload("jf-machine", "item-1", status = COMPLETED, clientScopeId = "jf-machine/user-a")
        harness.data.apiCache.put("jf-machine/user-a", "/Users/user-a/Items/item-1", jellyfinItem("Cached for User A"))
        harness.data.apiCache.pin("jf-machine/user-a", "/Users/user-a/Items/item-1")
        val manager = harness.manager({ serverId, scope -> FakeMediaBackend(serverId.value, BackendKind.JELLYFIN, scopeId = scope ?: "jf-machine/user-b") })

        assertNull(manager.lookupMetadata(ServerId("jf-machine"), "item-1", preferActiveScope = true))
    }

    @Test
    fun `cold Jellyfin hydration resolves the active profile binding instead of the shared download scope`() = runTest {
        harness = DmsHarness.create()
        for (user in listOf("user-a", "user-b")) {
            harness.connection("jf-machine/$user", "jellyfin", jellyfinConfig(user))
            harness.binding("profile-${user.last()}", "jf-machine/$user", user)
            harness.data.apiCache.put("jf-machine/$user", "/Users/$user/Items/item-1", jellyfinItem("Cached for $user"))
            harness.jellyfinCache.pinForOffline("jf-machine/$user", "item-1")
        }
        harness.data.insertDownload("jf-machine", "item-1", status = COMPLETED, clientScopeId = "jf-machine/user-a")
        harness.library.addDownloadOwner("profile-a", "jf-machine:item-1")
        harness.library.addDownloadOwner("profile-b", "jf-machine:item-1")
        val manager = harness.manager()

        val all = manager.getAllPinnedMetadata("profile-b")
        val item = manager.lookupMetadata(ServerId("jf-machine"), "item-1", preferActiveScope = true, activeProfileId = "profile-b")

        assertEquals(listOf("Cached for user-b"), all.items.values.map { it.title })
        assertEquals(mapOf("jf-machine" to "jf-machine/user-b"), all.scopesByServer)
        assertEquals("Cached for user-b", item?.title)
    }

    @Test
    fun `cold Plex hydration finds a server inside its persisted account configuration`() = runTest {
        harness = DmsHarness.create()
        val scope = PlexProfileScopeId.of(ServerId("plex-machine"), "profile-b").value
        harness.connection(
            "plex-account-uuid",
            "plex",
            kotlinx.serialization.json.Json.parseToJsonElement("""{"servers":[{"clientIdentifier":"plex-machine"}]}""") as JsonObject,
        )
        harness.data.insertDownload("plex-machine", "item-1", status = COMPLETED, clientScopeId = "plex-machine")
        harness.library.addDownloadOwner("profile-b", "plex-machine:item-1")
        harness.putPlexMetadata(scope, "item-1", plexFields("ratingKey" to "item-1", "type" to "movie", "title" to "Offline Plex"))
        harness.plexCache.pinForOffline(scope, "item-1")
        val manager = harness.manager()

        val all = manager.getAllPinnedMetadata("profile-b")
        val item = manager.lookupMetadata(ServerId("plex-machine"), "item-1", preferActiveScope = true, activeProfileId = "profile-b")

        assertEquals("Offline Plex", all.items["plex-machine:item-1"]?.title)
        assertEquals(mapOf("plex-machine" to scope), all.scopesByServer)
        assertEquals("Offline Plex", item?.title)
    }

    @Test
    fun `active Plex lookup selects the exact profile namespace without bare fallback`() = runTest {
        harness = DmsHarness.create()
        val serverId = ServerId("plex-machine")
        for ((scope, title) in listOf(
            PlexProfileScopeId.of(serverId, "profile-a").value to "Profile A",
            PlexProfileScopeId.of(serverId, "profile-b").value to "Profile B",
            "plex-machine" to "Legacy bare",
        )) {
            harness.putPlexMetadata(scope, "item-1", plexFields("ratingKey" to "item-1", "type" to "movie", "title" to title))
        }
        val manager = harness.manager({ id, _ -> ArtworkRepairBackend(id.value, emptyMap()) })

        assertEquals("Profile A", manager.lookupMetadata(serverId, "item-1", preferActiveScope = true, activeProfileId = "profile-a")?.title)
        assertNull(manager.lookupMetadata(serverId, "item-1", preferActiveScope = true, activeProfileId = "profile-missing"))
    }

    @Test
    fun `the show year comes from the cached show not the episode`() = runTest {
        harness = DmsHarness.create()
        harness.putPlexMetadata("srv-1", "show-1", plexFields("ratingKey" to "show-1", "type" to "show", "title" to "The Show", "year" to 2008))
        val scopes = DownloadMetadataScopes(harness.library, { _, _ -> null }, harness.caches, harness.resolver)

        assertEquals(2008, scopes.showYear(ServerId("srv-1"), "show-1", clientScopeId = null))
    }

    @Test
    fun `interrupted Plex logout transfer recovers from the physical row transfer scope`() = runTest {
        harness = DmsHarness.create()
        val serverId = ServerId("plex-machine")
        val profileScope = PlexProfileScopeId.of(serverId, "profile-a").value
        val transferScope = PlexTransferScopeId.of(serverId).value
        harness.data.insertDownload("plex-machine", "item-1", status = COMPLETED, clientScopeId = profileScope)
        harness.library.addDownloadOwner("profile-a", "plex-machine:item-1", BackendKind.PLEX.id, profileScope)
        harness.putPlexMetadata(profileScope, "item-1", plexFields("ratingKey" to "item-1", "type" to "movie", "title" to "Recovered transfer"))
        harness.plexCache.pinForOffline(profileScope, "item-1")
        val manager = harness.manager()

        manager.preparePlexMetadataForLogoutTransfer()

        assertEquals(transferScope, harness.library.getDownloadedMedia("plex-machine:item-1")?.client_scope_id)
        assertEquals(profileScope, harness.library.getDownloadOwner("profile-a", "plex-machine:item-1")?.client_scope_id)
        assertEquals("Recovered transfer", harness.plexCache.getMetadata(transferScope, "item-1")?.title)

        manager.adoptTransferredPlexMetadataForProfile("profile-a")

        val owner = harness.library.getDownloadOwner("profile-a", "plex-machine:item-1")
        assertEquals(profileScope, harness.library.getDownloadedMedia("plex-machine:item-1")?.client_scope_id)
        assertEquals(BackendKind.PLEX.id, owner?.backend)
        assertEquals(profileScope, owner?.client_scope_id)
        assertNull(harness.plexCache.getMetadata(transferScope, "item-1"))
        assertEquals("Recovered transfer", harness.plexCache.getMetadata(profileScope, "item-1")?.title)
    }

    @Test
    fun `missing Plex leaf survives full logout and rehydrates after replacement adoption`() = runTest {
        harness = DmsHarness.create()
        val serverId = ServerId("plex-machine")
        val globalKey = "plex-machine:item-1"
        val originalScope = PlexProfileScopeId.of(serverId, "profile-a").value
        val transferScope = PlexTransferScopeId.of(serverId).value
        val destinationScope = PlexProfileScopeId.of(serverId, "profile-b").value
        harness.profile("profile-a")
        harness.profile("profile-b")
        harness.data.insertDownload("plex-machine", "item-1", status = COMPLETED, clientScopeId = originalScope, mediaIndex = 2, mediaSourceId = "source-a")
        harness.library.updateDownloadProgress(globalKey, 100, 900, 900)
        harness.library.updateVideoFilePath(globalKey, "downloads/plex-machine/item-1/video.mp4")
        harness.library.addToQueue(globalKey, 7, downloadSubtitles = false, downloadArtwork = true)
        harness.library.addDownloadOwner("profile-a", globalKey, BackendKind.PLEX.id, originalScope)
        val before = harness.library.getDownloadedMedia(globalKey)!!
        val queueBefore = harness.library.getQueue().single()
        assertNull(harness.plexCache.getMetadata(originalScope, "item-1"))

        val transferManager = harness.manager()
        transferManager.preparePlexMetadataForLogoutTransfer()

        assertEquals(transferScope, harness.library.getDownloadedMedia(globalKey)?.client_scope_id)
        assertEquals(originalScope, harness.library.getDownloadOwner("profile-a", globalKey)?.client_scope_id)
        assertNull(harness.plexCache.getMetadata(transferScope, "item-1"))

        harness.library.clearAllDownloadOwners()
        assertTrue(harness.library.getValidDownloadOwnersForKey(globalKey).isEmpty())
        harness.library.adoptLegacyDownloadsForProfile("profile-b")
        transferManager.adoptTransferredPlexMetadataForProfile("profile-b")

        val adopted = harness.library.getDownloadedMedia(globalKey)!!
        val adoptedOwner = harness.library.getDownloadOwner("profile-b", globalKey)
        val queueAfter = harness.library.getQueue().single()
        assertEquals(destinationScope, adopted.client_scope_id)
        assertEquals(BackendKind.PLEX.id, adoptedOwner?.backend)
        assertEquals(destinationScope, adoptedOwner?.client_scope_id)
        assertEquals(before.copy(client_scope_id = destinationScope), adopted)
        assertEquals(queueBefore, queueAfter)
        assertNull(harness.plexCache.getMetadata(destinationScope, "item-1"))

        val hydrated = testMediaItem("item-1", MediaKind.MOVIE, "plex-machine", title = "Rehydrated for profile B")
        val client = object : FakeMediaBackend("plex-machine", BackendKind.PLEX, scopeId = destinationScope) {}
        client.items = { id ->
            if (id != hydrated.id) {
                null
            } else {
                harness.putPlexMetadata(destinationScope, id, plexFields("ratingKey" to id, "type" to "movie", "title" to hydrated.title))
                hydrated
            }
        }
        val hydrationManager = harness.manager({ id, scope -> client.takeIf { id == serverId && (scope == null || scope == destinationScope) } })

        val result = hydrationManager.fetchAndPinMetadata(serverId, "item-1", preferActiveScope = true, activeProfileId = "profile-b")

        assertEquals("Rehydrated for profile B", result?.title)
        assertEquals("Rehydrated for profile B", harness.plexCache.getMetadata(destinationScope, "item-1")?.title)
        assertEquals(listOf(globalKey), harness.plexCache.getAllPinnedMetadata(setOf(destinationScope)).keys.toList())
        assertNull(harness.plexCache.getMetadata(transferScope, "item-1"))
    }

    @Test
    fun `Jellyfin offline pinning keeps media segment cache rows with metadata`() = runTest {
        harness = DmsHarness.create()
        val scope = "jf-machine/user-a"
        val segments = "/MediaSegments/item-1"
        harness.data.apiCache.put(scope, "/Users/user-a/Items/item-1", buildJsonObject { put("Id", "item-1"); put("Type", "Episode"); put("Name", "Episode") })
        harness.data.apiCache.put(scope, segments, kotlinx.serialization.json.Json.parseToJsonElement("""{"Items":[{"Type":"Intro","StartTicks":10000000,"EndTicks":20000000}]}""") as JsonObject)

        harness.jellyfinCache.pinForOffline(scope, "item-1")
        assertTrue(harness.data.apiCache.isPinned(scope, segments))

        harness.jellyfinCache.deleteForItem(scope, "item-1")
        assertNull(harness.data.apiCache.get(scope, "/Users/user-a/Items/item-1"))
        assertNull(harness.data.apiCache.get(scope, segments))
    }

    @Test
    fun `adopted Jellyfin ownership cleans only the adopting user cache scope`() = runTest {
        harness = DmsHarness.create()
        harness.profile("profile-b")
        harness.connection("jf-machine/user-b", "jellyfin", buildJsonObject { put("serverMachineId", "jf-machine"); put("userId", "user-b") })
        harness.binding("profile-b", "jf-machine/user-b", "user-b")
        harness.data.insertDownload("jf-machine", "item-1", status = COMPLETED, clientScopeId = "jf-machine/user-a")
        for (user in listOf("user-a", "user-b")) harness.data.apiCache.put("jf-machine/$user", "/Users/$user/Items/item-1", jellyfinItem(user))
        val manager = harness.manager()

        harness.library.adoptLegacyDownloadsForProfile("profile-b")
        val owner = harness.library.getDownloadOwner("profile-b", "jf-machine:item-1")
        assertEquals("jf-machine/user-b", harness.library.getDownloadedMedia("jf-machine:item-1")?.client_scope_id)
        assertEquals(BackendKind.JELLYFIN.id, owner?.backend)
        assertEquals("jf-machine/user-b", owner?.client_scope_id)

        harness.library.removeDownloadOwner("profile-b", "jf-machine:item-1")
        manager.deleteMetadataForOwner("jf-machine:item-1", ServerId("jf-machine"), "item-1", "profile-b", owner?.backend, owner?.client_scope_id)

        assertNull(harness.data.apiCache.get("jf-machine/user-b", "/Users/user-b/Items/item-1"))
        assertNotNull(harness.data.apiCache.get("jf-machine/user-a", "/Users/user-a/Items/item-1"))
    }

    @Test
    fun `artwork repair fetches full parent metadata and backfills thumb path`() = runTest {
        harness = DmsHarness.create()
        harness.data.insertDownload("srv", "ep-1", type = "episode", status = COMPLETED, parentRatingKey = "season-1", grandparentRatingKey = "show-1")
        harness.putPlexMetadata(
            "srv",
            "ep-1",
            plexFields(
                "ratingKey" to "ep-1", "type" to "episode", "title" to "Episode", "thumb" to "/ep-thumb", "parentRatingKey" to "season-1",
                "parentTitle" to "Season 1", "parentIndex" to 1, "grandparentRatingKey" to "show-1", "grandparentTitle" to "Show",
            ),
        )
        harness.putPlexMetadata("srv", "show-1", plexFields("ratingKey" to "show-1", "type" to "show", "title" to "Show", "thumb" to "/show-thumb"))
        val client = ArtworkRepairBackend(
            "srv",
            mapOf(
                "show-1" to testMediaItem(
                    "show-1", MediaKind.SHOW, "srv", title = "Show", thumbPath = "/show-thumb", clearLogoPath = "/show-logo",
                    artPath = "/show-art", backgroundSquarePath = "/show-square",
                ),
            ),
        )
        val manager = harness.manager({ _, _ -> client }, http = DmsHarness.httpClient { respond("image bytes", HttpStatusCode.OK) })

        real { manager.repairMissingArtworkForDownloads() }

        assertTrue("fetchItem:show-1" in client.calls)
        assertTrue(exists(harness.storage.getArtworkPathFromThumb(ServerId("srv"), artworkStorageKey("/show-logo"))))
        assertEquals(artworkStorageKey("/ep-thumb"), harness.library.getDownloadedMedia("srv:ep-1")?.thumb_path)
    }
}

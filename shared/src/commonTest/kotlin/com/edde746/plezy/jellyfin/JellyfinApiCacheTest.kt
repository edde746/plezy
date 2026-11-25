package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.ApiCacheRow
import com.edde746.plezy.model.MediaBrowserDialect
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Instant
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.boolean
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.long

class JellyfinApiCacheTest {
    private val machineId = "jf-machine"
    private val store = InMemoryApiCacheStore()
    private val connections = mutableListOf<JellyfinConnection>()
    private val bindings = mutableListOf<JellyfinProfileBinding>()
    private val cache = JellyfinApiCache(store, JellyfinCacheResolver(store, { connections.toList() }, { bindings.toList() }))

    private fun insertConnection(
        userId: String,
        serverName: String = "Shared JF",
        baseUrl: String = "http://example.lan",
        dialect: MediaBrowserDialect = MediaBrowserDialect.JELLYFIN,
    ) {
        connections += JellyfinConnection(
            id = "$machineId/$userId", baseUrl = baseUrl, serverName = serverName, serverMachineId = machineId,
            userId = userId, userName = "someone", accessToken = "token", deviceId = "device", dialect = dialect, createdAt = 0,
        )
    }

    private fun item(id: String = "item-1", name: String = "Hello", userData: String? = null, extra: String = "") =
        """{"Id":"$id","Type":"Movie","Name":"$name"""" + (userData?.let { ""","UserData":$it""" } ?: "") + extra + "}"

    private fun putItemRow(scopeId: String, userId: String, itemId: String, data: String = item(itemId), pinned: Boolean = false) {
        val key = "$scopeId:/Users/$userId/Items/$itemId"
        store.rows[key] = ApiCacheRow(key, data, 0, pinned)
    }

    private fun userData(key: String): JsonObject =
        Json.parseToJsonElement(store.rows.getValue(key).data).jsonObject.getValue("UserData").jsonObject

    private fun pinnedKeys() = store.rows.values.filter { it.pinned }.map { it.key }.toSet()

    // getMetadata

    @Test fun resolvesServerNameViaTheCompoundConnectionId() = runTest {
        insertConnection("jf-user", serverName = "My Jellyfin")
        putItemRow(machineId, "jf-user", "item-1", item("item-1", "A Movie"))

        val meta = assertNotNull(cache.getMetadata(machineId, "item-1"))
        assertEquals("A Movie", meta.title)
        assertEquals(machineId, meta.serverId)
        assertEquals("My Jellyfin", meta.serverName)
    }

    @Test fun returnsNullWhenTheConnectionIsMissing() = runTest {
        putItemRow("orphan", "u", "item-1")
        assertNull(cache.getMetadata("orphan", "item-1"))
    }

    @Test fun returnsNullWhenTheConnectionHasNoBaseUrl() = runTest {
        insertConnection("jf-user", baseUrl = "")
        putItemRow(machineId, "jf-user", "item-1")
        assertNull(cache.getMetadata(machineId, "item-1"))
    }

    @Test fun returnsNullForAMalformedRow() = runTest {
        insertConnection("jf-user")
        putItemRow(machineId, "jf-user", "item-1", "not json")
        assertNull(cache.getMetadata(machineId, "item-1"))
    }

    @Test fun absolutizesImagePathsAgainstTheConnectionBaseUrlWithoutTheToken() = runTest {
        insertConnection("jf-user")
        putItemRow(machineId, "jf-user", "item-1", item("item-1", extra = ""","ImageTags":{"Primary":"tag-abc","Logo":"tag-logo"}"""))

        val meta = assertNotNull(cache.getMetadata(machineId, "item-1"))
        assertEquals("http://example.lan/Items/item-1/Images/Primary?tag=tag-abc", meta.thumbPath)
        assertEquals("http://example.lan/Items/item-1/Images/Logo?tag=tag-logo", meta.clearLogoPath)
    }

    @Test fun usesTheConnectionsCurrentBaseUrlNotTheOneAtWriteTime() = runTest {
        insertConnection("jf-user", baseUrl = "https://new.example")
        putItemRow(machineId, "jf-user", "item-1", item("item-1", extra = ""","ImageTags":{"Primary":"t"}"""))

        assertEquals("https://new.example/Items/item-1/Images/Primary?tag=t", cache.getMetadata(machineId, "item-1")?.thumbPath)
    }

    @Test fun scopesUserDataByCompoundConnectionId() = runTest {
        insertConnection("user-a")
        insertConnection("user-b")
        putItemRow("$machineId/user-a", "user-a", "item-1", item("item-1", "For A", """{"Played":false,"PlayCount":0}"""))
        putItemRow("$machineId/user-b", "user-b", "item-1", item("item-1", "For B", """{"Played":true,"PlayCount":1}"""))

        val a = assertNotNull(cache.getMetadata("$machineId/user-a", "item-1"))
        val b = assertNotNull(cache.getMetadata("$machineId/user-b", "item-1"))

        assertEquals(machineId, a.serverId)
        assertFalse(a.isWatched)
        assertEquals("For A", a.title)
        assertEquals(machineId, b.serverId)
        assertTrue(b.isWatched)
        assertEquals("For B", b.title)
    }

    @Test fun stampsTheConnectionDialect() = runTest {
        insertConnection("jf-user", dialect = MediaBrowserDialect.EMBY)
        putItemRow(machineId, "jf-user", "item-1")

        assertEquals(MediaBrowserDialect.EMBY.backend, cache.getMetadata(machineId, "item-1")?.backend)
    }

    // getAllPinnedMetadata

    @Test fun aggregatesPinnedItemsKeyedByGlobalKeyAcrossUsersOnTheSameServer() = runTest {
        insertConnection("user-a")
        insertConnection("user-b")
        putItemRow(machineId, "user-a", "item-1", pinned = true)
        putItemRow(machineId, "user-b", "item-2", pinned = true)
        putItemRow(machineId, "user-a", "item-3")

        val pinned = cache.getAllPinnedMetadata()

        assertEquals(setOf("$machineId:item-1", "$machineId:item-2"), pinned.keys)
        assertEquals("Shared JF", pinned.getValue("$machineId:item-1").serverName)
    }

    @Test fun compoundScopeFilteringSelectsOnlyThatUserFromLegacyBareScopeRows() = runTest {
        insertConnection("user-a")
        insertConnection("user-b")
        putItemRow(machineId, "user-a", "item-a", item("item-a", "For A"), pinned = true)
        putItemRow(machineId, "user-b", "item-b", item("item-b", "For B"), pinned = true)

        val pinned = cache.getAllPinnedMetadata(setOf("$machineId/user-b"))

        assertEquals(listOf("$machineId:item-b"), pinned.keys.toList())
        assertEquals("For B", pinned.values.single().title)
    }

    @Test fun skipsPinnedRowsWithoutAConnection() = runTest {
        putItemRow("orphan-machine", "u", "lost", pinned = true)
        assertTrue(cache.getAllPinnedMetadata().isEmpty())
    }

    @Test fun oneMalformedPinnedRowDoesNotDropItsSiblings() = runTest {
        insertConnection("user-a")
        putItemRow("$machineId/user-a", "user-a", "bad", "not json", pinned = true)
        putItemRow("$machineId/user-a", "user-a", "good", pinned = true)

        assertEquals(setOf("$machineId/user-a:good"), cache.getAllPinnedMetadata().keys)
    }

    @Test fun keepsSameServerUsersAddressableByCompoundPinnedKeys() = runTest {
        insertConnection("user-a")
        insertConnection("user-b")
        putItemRow("$machineId/user-a", "user-a", "item-1", item("item-1", "For A", """{"Played":false,"PlayCount":0}"""), pinned = true)
        putItemRow("$machineId/user-b", "user-b", "item-1", item("item-1", "For B", """{"Played":true,"PlayCount":1}"""), pinned = true)

        val pinned = cache.getAllPinnedMetadata()

        assertNull(pinned["$machineId:item-1"])
        assertEquals("For A", pinned.getValue("$machineId/user-a:item-1").title)
        assertEquals("For B", pinned.getValue("$machineId/user-b:item-1").title)
        assertEquals(machineId, pinned.getValue("$machineId/user-a:item-1").serverId)
        assertEquals(machineId, pinned.getValue("$machineId/user-b:item-1").serverId)
    }

    // pinForOffline / deleteForItem

    @Test fun pinsByUserSegmentWildcardSoOneCallCoversAnyUser() = runTest {
        putItemRow(machineId, "user-a", "item-1")
        putItemRow(machineId, "user-b", "item-1")
        putItemRow(machineId, "user-a", "item-2")

        cache.pinForOffline(machineId, "item-1")

        assertEquals(setOf("$machineId:/Users/user-a/Items/item-1", "$machineId:/Users/user-b/Items/item-1"), pinnedKeys())
    }

    @Test fun pinsOnlyTheRequestedCompoundUserScope() = runTest {
        putItemRow("$machineId/user-a", "user-a", "item-1")
        putItemRow("$machineId/user-b", "user-b", "item-1")

        cache.pinForOffline("$machineId/user-a", "item-1")

        assertEquals(setOf("$machineId/user-a:/Users/user-a/Items/item-1"), pinnedKeys())
    }

    @Test fun pinsTheMediaSegmentsRowWithTheItem() = runTest {
        val scope = "$machineId/user-a"
        putItemRow(scope, "user-a", "item 1")
        store.put(scope, "/MediaSegments/item%201", JsonObject(mapOf("Items" to JsonPrimitive(0))))

        cache.pinForOffline(scope, "item 1")

        assertEquals(setOf("$scope:/Users/user-a/Items/item 1", "$scope:/MediaSegments/item%201"), pinnedKeys())
    }

    @Test fun deleteForItemRemovesItemRowsAndSegmentsOnly() = runTest {
        val scope = "$machineId/user-a"
        putItemRow(scope, "user-a", "item-1")
        putItemRow(machineId, "user-a", "item-1")
        putItemRow(scope, "user-a", "item-2")
        putItemRow("$machineId/user-b", "user-b", "item-1")
        store.put(scope, "/MediaSegments/item-1", JsonObject(emptyMap()))

        cache.deleteForItem(scope, "item-1")

        assertEquals(
            setOf("$scope:/Users/user-a/Items/item-2", "$machineId/user-b:/Users/user-b/Items/item-1"),
            store.rows.keys,
        )
    }

    // applyWatchState

    @Test fun watchStateMutatesOnlyTheRequestedCompoundUserScope() = runTest {
        putItemRow("$machineId/user-a", "user-a", "item-1", item(userData = """{"Played":false,"PlayCount":0}"""))
        putItemRow("$machineId/user-b", "user-b", "item-1", item(userData = """{"Played":false,"PlayCount":0}"""))

        cache.applyWatchState("$machineId/user-a", "item-1", isWatched = true)

        assertTrue(userData("$machineId/user-a:/Users/user-a/Items/item-1").getValue("Played").jsonPrimitive.boolean)
        assertFalse(userData("$machineId/user-b:/Users/user-b/Items/item-1").getValue("Played").jsonPrimitive.boolean)
    }

    @Test fun bareServerIdUpdatesTheOnlyCachedUserScope() = runTest {
        putItemRow(machineId, "user-a", "item-1", item(userData = """{"Played":false,"PlayCount":0}"""))

        cache.applyWatchState(machineId, "item-1", isWatched = true)

        val userData = userData("$machineId:/Users/user-a/Items/item-1")
        assertTrue(userData.getValue("Played").jsonPrimitive.boolean)
        assertEquals(1, userData.getValue("PlayCount").jsonPrimitive.int)
        assertEquals(0, userData.getValue("PlaybackPositionTicks").jsonPrimitive.long)
        assertNotNull(Instant.parse(userData.getValue("LastPlayedDate").jsonPrimitive.content))
    }

    @Test fun bareServerIdSkipsAmbiguousMultiUserUpdates() = runTest {
        for (user in listOf("user-a", "user-b")) putItemRow(machineId, user, "item-1", item(userData = """{"Played":false,"PlayCount":0}"""))

        cache.applyWatchState(machineId, "item-1", isWatched = true)

        for (user in listOf("user-a", "user-b")) {
            assertFalse(userData("$machineId:/Users/$user/Items/item-1").getValue("Played").jsonPrimitive.boolean)
        }
    }

    private val watchDto = item(userData = """{"Played":false,"PlayCount":0,"PlaybackPositionTicks":990000}""")
    private val watchKey = "jf-srv:/Users/user-a/Items/item-1"

    @Test fun convertsViewOffsetMsTo100NsTicks() = runTest {
        putItemRow("jf-srv", "user-a", "item-1", watchDto)

        cache.applyWatchState("jf-srv", "item-1", isWatched = true, viewOffsetMs = 5000)

        assertEquals(5000L * 10000, userData(watchKey).getValue("PlaybackPositionTicks").jsonPrimitive.long)
    }

    @Test fun convertsEpochSecondsLastViewedAtToIsoLastPlayedDate() = runTest {
        putItemRow("jf-srv", "user-a", "item-1", watchDto)

        cache.applyWatchState("jf-srv", "item-1", isWatched = true, lastViewedAt = 1_700_000_000)

        assertEquals(
            Instant.fromEpochSeconds(1_700_000_000),
            Instant.parse(userData(watchKey).getValue("LastPlayedDate").jsonPrimitive.content),
        )
    }

    @Test fun watchedPreservesAnExistingPlayCountAndUnwatchedZeroesIt() = runTest {
        putItemRow("jf-srv", "user-a", "item-1", item(userData = """{"Played":false,"PlayCount":4}"""))

        cache.applyWatchState("jf-srv", "item-1", isWatched = true)
        assertEquals(4, userData(watchKey).getValue("PlayCount").jsonPrimitive.int)

        cache.applyWatchState("jf-srv", "item-1", isWatched = false)
        val userData = userData(watchKey)
        assertEquals(0, userData.getValue("PlayCount").jsonPrimitive.int)
        assertFalse(userData.getValue("Played").jsonPrimitive.boolean)
    }

    @Test fun unwatchedSetsLastPlayedDateOnlyWhenGiven() = runTest {
        putItemRow("jf-srv", "user-a", "item-1", watchDto)

        cache.applyWatchState("jf-srv", "item-1", isWatched = false, viewOffsetMs = 12)
        assertNull(userData(watchKey)["LastPlayedDate"])
        assertEquals(120_000L, userData(watchKey).getValue("PlaybackPositionTicks").jsonPrimitive.long)

        cache.applyWatchState("jf-srv", "item-1", isWatched = false, lastViewedAt = 60)
        assertEquals(Instant.fromEpochSeconds(60), Instant.parse(userData(watchKey).getValue("LastPlayedDate").jsonPrimitive.content))
        assertEquals(0L, userData(watchKey).getValue("PlaybackPositionTicks").jsonPrimitive.long)
    }

    @Test fun viewedLeafCountIsIgnored() = runTest {
        putItemRow("jf-srv", "user-a", "item-1", watchDto)

        cache.applyWatchState("jf-srv", "item-1", isWatched = true, viewedLeafCount = 9)

        val userData = userData(watchKey)
        assertFalse("UnplayedItemCount" in userData)
        assertFalse(userData.values.any { it == JsonPrimitive(9) })
    }

    @Test fun createsUserDataWhenTheRowHasNone() = runTest {
        putItemRow("jf-srv", "user-a", "item-1")

        cache.applyWatchState("jf-srv", "item-1", isWatched = true)

        assertTrue(userData(watchKey).getValue("Played").jsonPrimitive.boolean)
    }

    @Test fun malformedCachedRowsAreSkippedAndLeftUntouched() = runTest {
        putItemRow("jf-srv", "user-a", "item-1", "not json")

        cache.applyWatchState("jf-srv", "item-1", isWatched = true)

        assertEquals("not json", store.rows.getValue(watchKey).data)
    }

    @Test fun noCachedRowWritesNothing() = runTest {
        cache.applyWatchState("jf-srv", "item-1", isWatched = true)
        assertTrue(store.rows.isEmpty())
    }
}

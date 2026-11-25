package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.ApiCacheRow
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlinx.coroutines.test.runTest

class JellyfinCacheResolverTest {
    private val store = InMemoryApiCacheStore()
    private val connections = mutableListOf<JellyfinConnection>()
    private val bindings = mutableListOf<JellyfinProfileBinding>()
    private var connectionLoads = 0
    private var bindingLoads = 0
    private val resolver = JellyfinCacheResolver(
        store,
        connections = { connectionLoads++; connections.toList() },
        bindings = { bindingLoads++; bindings.toList() },
    )

    private fun connection(machineId: String, userId: String, id: String = "$machineId/$userId") = JellyfinConnection(
        id = id, baseUrl = "http://jf.lan", serverName = "JF", serverMachineId = machineId, userId = userId,
        userName = userId, accessToken = "token", deviceId = "device", createdAt = 0,
    )

    private fun insertConnection(machineId: String, userId: String, profileId: String? = null) {
        connections += connection(machineId, userId)
        if (profileId != null) bindings += JellyfinProfileBinding(profileId, "$machineId/$userId", userId)
    }

    private fun insertItem(scopeId: String, userId: String, itemId: String, pinned: Boolean = false) {
        val key = "$scopeId:/Users/$userId/Items/$itemId"
        store.rows[key] = ApiCacheRow(key, """{"Id":"$itemId","Name":"$userId"}""", 0, pinned)
    }

    @Test fun bareServerIdResolvesItsCompoundCacheRowAndConnection() = runTest {
        insertConnection("server", "user-a")
        insertItem("server/user-a", "user-a", "item-1")

        val match = resolver.findResolvedItem("server", "item-1")

        assertEquals("server/user-a", match?.key?.scopeId)
        assertEquals("server/user-a", match?.connection?.id)
    }

    @Test fun bareScopeSpanningTwoUsersRefusesToResolveAnyCacheRow() = runTest {
        insertConnection("server", "user-a")
        insertConnection("server", "user-b")
        insertItem("server/user-a", "user-a", "item-1")
        insertItem("server/user-b", "user-b", "item-1")

        assertNull(resolver.findItem("server", "item-1"))
        assertNull(resolver.findResolvedItem("server", "item-1"))
    }

    @Test fun bareScopeWithASingleUserStillResolvesTheItemAndItsConnection() = runTest {
        insertConnection("server", "user-a")
        insertItem("server/user-a", "user-a", "item-1")

        assertEquals("user-a", resolver.findItem("server", "item-1")?.key?.userId)
        assertEquals("server/user-a", resolver.findResolvedItem("server", "item-1")?.connection?.id)
    }

    @Test fun bareScopeResolvesALegacyBareRowToTheUsersCompoundConnection() = runTest {
        insertConnection("server", "user-a")
        insertItem("server", "user-a", "item-1")

        val match = resolver.findResolvedItem("server", "item-1")

        assertEquals("server", match?.key?.scopeId)
        assertEquals("server/user-a", match?.connection?.id)
    }

    @Test fun compoundScopeSelectsTheSameUserCacheRowConnectionAndProfileBinding() = runTest {
        insertConnection("server", "user-a", profileId = "profile-a")
        insertConnection("server", "user-b", profileId = "profile-b")
        insertItem("server/user-a", "user-a", "item-1")
        insertItem("server/user-b", "user-b", "item-1")

        val match = resolver.findResolvedItem("server/user-b", "item-1")

        assertEquals("user-b", match?.key?.userId)
        assertEquals("server/user-b", match?.connection?.id)
    }

    @Test fun compoundScopePrefersItsOwnRowOverTheLegacyBareRow() = runTest {
        insertConnection("server", "user-a")
        insertItem("server", "user-a", "item-1")
        insertItem("server/user-a", "user-a", "item-1")

        assertEquals("server/user-a", resolver.findItem("server/user-a", "item-1")?.key?.scopeId)
    }

    @Test fun rejectsACacheRowWhoseCompoundScopeAndUserSegmentDisagree() = runTest {
        insertConnection("server", "user-a")
        insertConnection("server", "user-b")
        insertItem("server/user-a", "user-b", "item-1")

        assertNull(resolver.findItem("server/user-a", "item-1"))
    }

    @Test fun returnsNoMatchWhenTheExactUserConnectionIsAbsent() = runTest {
        insertConnection("server", "user-a")
        insertItem("server/user-b", "user-b", "item-1")

        assertNull(resolver.findResolvedItem("server/user-b", "item-1"))
    }

    @Test fun rejectsAConnectionBoundToADifferentJellyfinUser() = runTest {
        insertConnection("server", "user-a")
        bindings += JellyfinProfileBinding("profile-b", "server/user-a", "user-b")
        insertItem("server/user-a", "user-a", "item-1")

        assertNull(resolver.findResolvedItem("server/user-a", "item-1"))
    }

    @Test fun treatsWildcardCharactersInServerAndItemIdsLiterally() = runTest {
        insertConnection("server_%", "user-a")
        insertConnection("server-xx", "user-a")
        insertItem("server_%/user-a", "user-a", "item_%")
        insertItem("server-xx/user-a", "user-a", "item-zz")

        val match = resolver.findResolvedItem("server_%", "item_%")

        assertEquals("server_%/user-a", match?.key?.scopeId)
        assertEquals("item_%", match?.key?.itemId)
        assertNull(resolver.findItem("server_%", "item-zz"))
    }

    @Test fun parseItemKeyRejectsItemIdsWithSlashOrQuery() {
        assertNull(JellyfinCacheResolver.parseItemKey("server:/Users/u/Items/a/b"))
        assertNull(JellyfinCacheResolver.parseItemKey("server:/Users/u/Items/a?x=1"))
        assertNull(JellyfinCacheResolver.parseItemKey("server:/Users/u/Items/"))
        assertNull(JellyfinCacheResolver.parseItemKey("server/u:/Users/v/Items/a"))
        assertEquals(
            JellyfinItemCacheKey("server/u", "server", "u", "a"),
            JellyfinCacheResolver.parseItemKey("server/u:/Users/u/Items/a"),
        )
    }

    @Test fun resolvesPinnedRowsAgainstEachExactSameServerUserConnection() = runTest {
        insertConnection("server", "user-a", profileId = "profile-a")
        insertConnection("server", "user-b", profileId = "profile-b")
        insertItem("server/user-a", "user-a", "item-a", pinned = true)
        insertItem("server/user-b", "user-b", "item-b", pinned = true)

        val matches = resolver.findPinnedItems()

        assertEquals(setOf("server/user-a", "server/user-b"), matches.map { it.connection.id }.toSet())
    }

    @Test fun pinnedLegacyRowResolvesToABareConnectionOnlyWhenItsBindingNamesTheUser() = runTest {
        connections += connection("server", "user-a", id = "server")
        bindings += JellyfinProfileBinding("profile-a", "server", "user-a")
        insertItem("server", "user-a", "item-a", pinned = true)
        insertItem("server", "user-b", "item-b", pinned = true)

        assertEquals(listOf("item-a"), resolver.findPinnedItems().map { it.key.itemId })
    }

    @Test fun pinnedResolutionLoadsConnectionsAndBindingsOnceAsRowsGrow() = runTest {
        insertConnection("server", "user-a", profileId = "profile-a")
        insertItem("server/user-a", "user-a", "item-1", pinned = true)

        assertEquals(1, resolver.findPinnedItems().size)
        assertEquals(1 to 1, connectionLoads to bindingLoads)

        for (i in 2..100) insertItem("server/user-a", "user-a", "item-$i", pinned = true)
        connectionLoads = 0
        bindingLoads = 0

        assertEquals(100, resolver.findPinnedItems().size)
        assertEquals(1 to 1, connectionLoads to bindingLoads)
    }

    @Test fun profileScopeTakesTheDefaultThenMostRecentBindingOnTheMachine() = runTest {
        insertConnection("server", "user-a")
        insertConnection("server", "user-b")
        insertConnection("server", "user-c")
        insertConnection("other", "user-d")
        bindings += JellyfinProfileBinding("p", "other/user-d", "user-d", isDefault = true, lastUsedAt = 9)
        bindings += JellyfinProfileBinding("p", "server/user-a", "user-a", lastUsedAt = 1)
        bindings += JellyfinProfileBinding("p", "server/user-b", "user-b", lastUsedAt = 5)
        bindings += JellyfinProfileBinding("q", "server/user-c", "user-c", isDefault = true)

        assertEquals("server/user-b", resolver.findProfileScopeId("server", "p"))
        assertEquals("server/user-b", resolver.findProfileScopeId("server/user-a", "p"))

        bindings += JellyfinProfileBinding("p", "server/user-c", "user-c", isDefault = true)
        assertEquals("server/user-c", resolver.findProfileScopeId("server", "p"))
    }

    @Test fun profileScopeSkipsBindingsNamingAnotherUserThanTheConnection() = runTest {
        insertConnection("server", "user-a")
        bindings += JellyfinProfileBinding("p", "server/user-a", "user-b")

        assertNull(resolver.findProfileScopeId("server", "p"))
        assertNull(resolver.findProfileScopeId("server", ""))
        assertNull(resolver.findProfileScopeId("server", "nobody"))
    }

    @Test fun profileScopeUsesTheBindingUserForALegacyBareConnection() = runTest {
        connections += connection("server", "", id = "server")
        bindings += JellyfinProfileBinding("p", "server", "user-a")

        assertEquals("server/user-a", resolver.findProfileScopeId("server", "p"))
    }
}

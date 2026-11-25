package com.edde746.plezy.profiles

import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class PlexHomeServiceTest {
    private val alice = homeUser("aaaaaaaaaaaaaaaa", title = "Alice")
    private val bob = homeUser("bbbbbbbbbbbbbbbb", title = "Bob")

    /** A service whose fetches come from [fetch], by account token. */
    private fun TestScope.service(h: ProfileHarness, fetch: suspend (String) -> List<PlexHomeUser>) =
        PlexHomeService(h.connections, h.bindings, h.identity, fetch, backgroundScope)

    @Test
    fun refreshFetchesCachesAndStoresTheUsers() = profileTest { h ->
        h.store(plexAccount())
        val home = service(h) { listOf(alice) }

        assertTrue(home.refresh(plexAccount()))

        assertEquals(mapOf("plex.account" to listOf(alice)), home.users.value)
        assertEquals(listOf(alice), h.identity.plexHomeUsers("plex.account"))
    }

    @Test
    fun hydrateLoadsTheStoredUsersWithoutFetching() = profileTest { h ->
        h.store(plexAccount())
        h.cacheHomeUsers("plex.account", alice)
        var fetches = 0
        val home = service(h) {
            fetches++
            listOf(bob)
        }

        home.hydrate()

        assertEquals(listOf(alice), home.users.value["plex.account"])
        assertEquals(0, fetches)
    }

    @Test
    fun hydrateSkipsAnAccountWhoseServerDoesNotReadAndLoadsItsSibling() = profileTest { h ->
        h.store(plexAccount())
        h.cacheHomeUsers("plex.account", alice)
        val broken = plexAccount(id = "plex.broken").stored()
        val server = (broken.config["servers"] as JsonArray).single().jsonObject - "clientIdentifier"
        h.connections.upsert(broken.copy(config = JsonObject(broken.config + ("servers" to JsonArray(listOf(JsonObject(server)))))))
        h.cacheHomeUsers("plex.broken", bob)
        val home = service(h) { error("no fetch while hydrating") }

        home.hydrate()

        assertEquals(mapOf("plex.account" to listOf(alice)), home.users.value)
    }

    @Test
    fun startHydratesThenRefreshesEveryAccount() = profileTest { h ->
        h.store(plexAccount())
        h.cacheHomeUsers("plex.account", alice)
        val home = service(h) { listOf(bob) }

        home.start()

        assertEquals(listOf(bob), home.users.first { it["plex.account"] == listOf(bob) }["plex.account"])
        assertEquals(listOf(bob), h.identity.plexHomeUsers("plex.account"))
    }

    @Test
    fun aFailedRefreshKeepsTheCache() = profileTest { h ->
        h.store(plexAccount())
        h.cacheHomeUsers("plex.account", alice)
        val home = service(h) { throw IllegalStateException("plex.tv down") }
        home.hydrate()

        assertFalse(home.refresh(plexAccount()))

        assertEquals(listOf(alice), home.users.value["plex.account"])
        assertEquals(listOf(alice), h.identity.plexHomeUsers("plex.account"))
    }

    @Test
    fun aLaterExplicitRefreshWinsWhateverOrderTheyLandIn() = profileTest { h ->
        h.store(plexAccount())
        val gates = mapOf("first" to CompletableDeferred<List<PlexHomeUser>>(), "second" to CompletableDeferred())
        var calls = 0
        val home = service(h) { gates.getValue(if (calls++ == 0) "first" else "second").await() }

        val first = async { home.refresh(plexAccount()) }
        runCurrent()
        val second = async { home.refresh(plexAccount()) }
        runCurrent()
        gates.getValue("second").complete(listOf(bob))
        assertTrue(second.await())
        gates.getValue("first").complete(listOf(alice))

        assertFalse(first.await())
        assertEquals(listOf(bob), home.users.value["plex.account"])
        assertEquals(listOf(bob), h.identity.plexHomeUsers("plex.account"))
    }

    @Test
    fun overlappingRefreshesOfTwoAccountsStayApart() = profileTest { h ->
        h.store(plexAccount("plex.a", token = "token-a"))
        h.store(plexAccount("plex.b", token = "token-b"))
        val home = service(h) { token -> if (token == "token-a") listOf(alice) else listOf(bob) }

        val a = async { home.refresh(plexAccount("plex.a", token = "token-a")) }
        val b = async { home.refresh(plexAccount("plex.b", token = "token-b")) }

        assertTrue(a.await() && b.await())
        assertEquals(mapOf("plex.a" to listOf(alice), "plex.b" to listOf(bob)), home.users.value)
    }

    @Test
    fun aFetchLandingAfterTheAccountWentIsDropped() = profileTest { h ->
        h.store(plexAccount())
        val gate = CompletableDeferred<List<PlexHomeUser>>()
        val home = service(h) { gate.await() }

        val refresh = async { home.refresh(plexAccount()) }
        runCurrent()
        h.connections.remove("plex.account")
        gate.complete(listOf(alice))

        assertFalse(refresh.await())
        assertNull(home.users.value["plex.account"])
        assertNull(h.identity.plexHomeUsers("plex.account"))
    }

    @Test
    fun aFetchMadeWithAReplacedTokenIsDroppedAndFetchedAgainWithTheNewOne() = profileTest { h ->
        h.store(plexAccount())
        h.cacheHomeUsers("plex.account", alice)
        val gate = CompletableDeferred<List<PlexHomeUser>>()
        val home = service(h) { token -> if (token == "new-token") listOf(alice, bob) else gate.await() }
        home.hydrate()

        val refresh = async { home.refresh(plexAccount()) }
        runCurrent()
        h.store(plexAccount(token = "new-token"))
        gate.complete(listOf(bob))

        assertFalse(refresh.await())
        assertEquals(listOf(alice, bob), home.users.first { it["plex.account"]?.size == 2 }["plex.account"])
        assertEquals(listOf(alice, bob), h.identity.plexHomeUsers("plex.account"))
    }

    @Test
    fun removingAPlexAccountClearsItsCacheAndBindings() = profileTest { h ->
        h.store(plexAccount())
        h.bindings.upsert(ProfileConnection(plexHomeProfileId("plex.account", alice.uuid), "plex.account", "user-token", alice.uuid))
        val home = service(h) { listOf(alice) }
        home.start()
        home.users.first { it.containsKey("plex.account") }

        h.connections.remove("plex.account")

        home.users.first { !it.containsKey("plex.account") }
        runCurrent()
        assertNull(h.identity.plexHomeUsers("plex.account"))
        assertEquals(emptyList(), h.bindings.listForConnection("plex.account"))
    }

    @Test
    fun removeThenReAddDuringABlockedRefreshKeepsTheReplacementsUsers() = profileTest { h ->
        h.store(plexAccount())
        val gates = ArrayDeque(listOf(CompletableDeferred<List<PlexHomeUser>>(), CompletableDeferred()))
        val used = mutableListOf<CompletableDeferred<List<PlexHomeUser>>>()
        val home = service(h) { gates.removeFirst().also { used += it }.await() }
        home.start()
        runCurrent()

        h.connections.remove("plex.account")
        runCurrent()
        h.store(plexAccount())
        runCurrent()
        used.first().complete(listOf(alice))
        runCurrent()
        used.last().complete(listOf(bob))

        assertEquals(listOf(bob), home.users.first { it["plex.account"] == listOf(bob) }["plex.account"])
        assertEquals(listOf(bob), h.identity.plexHomeUsers("plex.account"))
    }

    @Test
    fun clearAllWipesMemoryAndStorage() = profileTest { h ->
        h.store(plexAccount())
        h.cacheHomeUsers("plex.account", alice)
        val home = service(h) { listOf(alice) }
        home.hydrate()

        home.clearAll()

        assertEquals(emptyMap(), home.users.value)
        assertNull(h.identity.plexHomeUsers("plex.account"))
    }

    @Test
    fun closeDropsARefreshInFlight() = profileTest { h ->
        h.store(plexAccount())
        val gate = CompletableDeferred<List<PlexHomeUser>>()
        val home = service(h) { gate.await() }
        home.start()
        runCurrent()

        home.close()
        gate.complete(listOf(alice))
        runCurrent()

        assertEquals(emptyMap(), home.users.value)
        assertNull(h.identity.plexHomeUsers("plex.account"))
    }
}

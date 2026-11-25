package com.edde746.plezy.profiles

import com.edde746.plezy.data.TestClock
import com.edde746.plezy.data.testData
import com.edde746.plezy.data.withConnections
import com.edde746.plezy.secrets.MemorySecretStore
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ProfileConnectionRegistryTest {
    private val clock = TestClock()
    private val data = testData(clock).withConnections("c1", "c2", "c3")
    private val secrets = MemorySecretStore()
    private val registry = ProfileConnectionRegistry(data, secrets)

    @AfterTest
    fun close() = data.close()

    private fun binding(profileId: String, connectionId: String, token: String? = "t", user: String = "u") =
        ProfileConnection(profileId, connectionId, token, user)

    private suspend fun defaults(profileId: String) = registry.listForProfile(profileId).filter { it.isDefault }.map { it.connectionId }

    @Test
    fun aBindingRoundTripsWithItsTokenKeptOutOfTheDatabase() = runTest {
        registry.upsert(binding("p1", "c1", token = "secret-tok", user = "uid-1"))
        val stored = registry.listForProfile("p1").single()
        assertEquals("secret-tok", stored.userToken)
        assertEquals("uid-1", stored.userIdentifier)
        val raw = data.db.read { profileQueries.selectAllBindings().executeAsList() }.toString()
        assertFalse("secret-tok" in raw)
        assertEquals(listOf("secret-tok"), secrets.entries.values.map { it.decodeToString() })
    }

    @Test
    fun anEmptyTokenIsNone() = runTest {
        registry.upsert(binding("p1", "c1", token = ""))
        assertNull(registry.get("p1", "c1")!!.userToken)
        assertTrue(secrets.entries.isEmpty())
    }

    @Test
    fun theFirstBindingIsTheDefaultAndLaterOnesDoNotTakeIt() = runTest {
        registry.upsert(binding("p1", "c1"))
        registry.upsert(binding("p1", "c2"))
        assertEquals(listOf("c1"), defaults("p1"))
    }

    @Test
    fun upsertingAgainKeepsTheStoredDefaultFlag() = runTest {
        registry.upsert(binding("p1", "c1"))
        registry.upsert(binding("p1", "c2"))
        registry.upsert(binding("p1", "c1", token = "refreshed"))
        registry.upsert(binding("p1", "c2", token = "refreshed"))
        assertEquals(listOf("c1"), defaults("p1"))
        assertEquals("refreshed", registry.get("p1", "c1")!!.userToken)
    }

    @Test
    fun makeDefaultTakesTheFlagFromTheOthers() = runTest {
        registry.upsert(binding("p1", "c1"))
        registry.upsert(binding("p1", "c2"), makeDefault = true)
        assertEquals(listOf("c2"), defaults("p1"))
        registry.upsert(binding("p1", "c1").copy(isDefault = true))
        assertEquals(listOf("c1"), defaults("p1"))
    }

    @Test
    fun setDefaultFlipsTheFlagExclusively() = runTest {
        registry.upsert(binding("p1", "c1"))
        registry.upsert(binding("p1", "c2"))
        registry.setDefault("p1", "c2")
        assertEquals(listOf("c2"), defaults("p1"))
        assertFailsWith<IllegalStateException> { registry.setDefault("p1", "missing") }
        assertEquals(listOf("c2"), defaults("p1"))
    }

    @Test
    fun listForProfilePutsTheDefaultFirstThenConnectionIds() = runTest {
        registry.upsert(binding("p1", "c3"))
        registry.upsert(binding("p1", "c2"))
        registry.upsert(binding("p1", "c1"))
        assertEquals(listOf("c3", "c1", "c2"), registry.listForProfile("p1").map { it.connectionId })
    }

    @Test
    fun recordTokenKeepsTheTokenAndStampsIt() = runTest {
        registry.upsert(binding("p1", "c1", token = null))
        clock.now = 5_000
        registry.recordToken("p1", "c1", "fresh-token")
        val stored = registry.get("p1", "c1")!!
        assertEquals("fresh-token", stored.userToken)
        assertEquals(5_000, stored.tokenAcquiredAt)
        registry.recordToken("p1", "missing", "orphan")
        assertEquals(listOf("fresh-token"), secrets.entries.values.map { it.decodeToString() }, "no token is kept for a binding that doesn't exist")
    }

    @Test
    fun invalidateTokenLeavesTheBindingToMintANewOne() = runTest {
        registry.upsert(binding("p1", "c1"))
        registry.recordToken("p1", "c1", "tok")
        registry.invalidateToken("p1", "c1")
        val stored = registry.get("p1", "c1")!!
        assertNull(stored.userToken)
        assertNull(stored.tokenAcquiredAt)
        assertTrue(secrets.entries.isEmpty(), "the dropped token went")
    }

    @Test
    fun markUsedStampsTheBinding() = runTest {
        registry.upsert(binding("p1", "c1"))
        clock.now = 7_000
        registry.markUsed("p1", "c1")
        assertEquals(7_000, registry.get("p1", "c1")!!.lastUsedAt)
    }

    @Test
    fun removingTheDefaultPromotesTheLowestConnectionId() = runTest {
        registry.upsert(binding("p1", "c1"))
        registry.upsert(binding("p1", "c3"))
        registry.upsert(binding("p1", "c2"))
        registry.remove("p1", "c1")
        assertEquals(listOf("c2"), defaults("p1"))
        assertEquals(2, secrets.entries.size, "the removed binding's token went")
    }

    @Test
    fun removeAllForConnectionCascadesAndRepromotes() = runTest {
        registry.upsert(binding("p1", "c1"), makeDefault = true)
        registry.upsert(binding("p1", "c2"))
        registry.upsert(binding("p2", "c1"))
        assertEquals(2, registry.removeAllForConnection("c1"))
        assertEquals(emptyList(), registry.listForConnection("c1"))
        assertEquals(listOf("c2"), defaults("p1"))
    }

    @Test
    fun aVirtualPlexHomeProfileCanBeBound() = runTest {
        val id = "plex-home-plex.acc-uuid-1234"
        registry.upsert(binding(id, "c1", token = "home-tok", user = "uuid-1234"))
        assertEquals("home-tok", registry.listForProfile(id).single().userToken)
    }

    @Test
    fun clearRemovesEveryBindingAndToken() = runTest {
        registry.upsert(binding("p1", "c1"))
        registry.upsert(binding("p2", "c2"))
        registry.clear()
        assertEquals(emptyList(), registry.listAll())
        assertTrue(secrets.entries.isEmpty())
    }
}

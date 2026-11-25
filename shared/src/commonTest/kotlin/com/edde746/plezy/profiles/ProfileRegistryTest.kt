package com.edde746.plezy.profiles

import com.edde746.plezy.data.TestClock
import com.edde746.plezy.data.db.Profiles
import com.edde746.plezy.data.testData
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class ProfileRegistryTest {
    private val data = testData(TestClock())
    private val registry = data.profiles

    @AfterTest
    fun close() = data.close()

    private fun local(id: String, sortOrder: Long = 0, createdAt: Long = 1_000) =
        LocalProfile(id, "Name $id", sortOrder = sortOrder, createdAt = createdAt)

    private suspend fun insertRaw(id: String, kind: String, configJson: String) {
        data.db.write { q.profileQueries.insertRow(Profiles(id, kind, id, null, configJson, 0, 1_000, null)) }
    }

    @Test
    fun aLocalProfileRoundTripsWithItsPin() = runTest {
        val profile = LocalProfile("local-1", "Kids", "https://a", computePinHash("1234"), 3, 1_000, 2_000)
        registry.upsert(profile)
        assertEquals(listOf(profile), registry.list())
        registry.upsert(profile.copy(pinHash = null))
        assertEquals(listOf(profile.copy(pinHash = null)), registry.list())
        assertEquals("""{"pinHash":null}""", data.db.read { profileQueries.selectLocal().executeAsOne().config_json })
    }

    @Test
    fun retiredPlexHomeRowsAreNeverListed() = runTest {
        registry.upsert(local("local-1"))
        insertRaw("plex-home-acct-aaaaaaaaaaaaaaaa", "plex_home", """{"parentConnectionId":"acct","protected":true}""")
        assertEquals(listOf("local-1"), registry.list().map { it.id })
    }

    @Test
    fun aRowWhoseConfigDoesNotDecodeIsSkippedNotDeleted() = runTest {
        insertRaw("local-bad", "local", "not json")
        insertRaw("local-wrong", "local", """{"pinHash":5}""")
        registry.upsert(local("local-good"))
        assertEquals(listOf("local-good"), registry.list().map { it.id })
        assertEquals(3, data.db.read { profileQueries.selectLocal().executeAsList().size })
    }

    @Test
    fun listOrdersBySortOrderThenCreation() = runTest {
        registry.upsert(local("c", sortOrder = 2, createdAt = 1))
        registry.upsert(local("b", sortOrder = 1, createdAt = 9))
        registry.upsert(local("a", sortOrder = 1, createdAt = 5))
        assertEquals(listOf("a", "b", "c"), registry.list().map { it.id })
    }

    @Test
    fun removeAndClearDeleteProfiles() = runTest {
        registry.upsert(local("a"))
        registry.upsert(local("b"))
        registry.remove("a")
        assertEquals(listOf("b"), registry.list().map { it.id })
        registry.clear()
        assertEquals(emptyList(), registry.list())
    }

    @Test
    fun markUsedRecordsTheTime() = runTest {
        registry.upsert(local("a"))
        registry.markUsed("a", 42)
        assertEquals(42, registry.list().single().lastUsedAt)
    }

    @Test
    fun renameTrimsAndTouchesOnlyTheName() = runTest {
        registry.upsert(local("a").copy(pinHash = computePinHash("1111")))
        registry.rename("a", "  New name ")
        val renamed = registry.list().single()
        assertEquals("New name", renamed.displayName)
        assertEquals(computePinHash("1111"), renamed.pinHash)
    }

    @Test
    fun renameRefusesABlankNameAndAMissingOrRetiredProfile() = runTest {
        registry.upsert(local("a"))
        insertRaw("plex-home-acct-aaaaaaaaaaaaaaaa", "plex_home", "{}")
        assertFailsWith<IllegalArgumentException> { registry.rename("a", "   ") }
        assertFailsWith<IllegalStateException> { registry.rename("missing", "Name") }
        assertFailsWith<IllegalStateException> { registry.rename("plex-home-acct-aaaaaaaaaaaaaaaa", "Name") }
    }
}

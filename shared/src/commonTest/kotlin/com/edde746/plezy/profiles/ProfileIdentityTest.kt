package com.edde746.plezy.profiles

import com.edde746.plezy.data.TestClock
import com.edde746.plezy.data.testData
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.storedJson
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonArray
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ProfileIdentityTest {
    private val data = testData(TestClock())
    private val identity = ProfileIdentity(data)

    @AfterTest
    fun close() = data.close()

    @Test
    fun theClientIdentifierIsMadeOnceAsALowercaseUuid() = runTest {
        val generated = identity.getOrCreateClientIdentifier()
        assertTrue(Regex("[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}").matches(generated), generated)
        assertEquals(generated, identity.getOrCreateClientIdentifier())
        identity.clearClientIdentifier()
        assertNotEquals(generated, identity.getOrCreateClientIdentifier())
    }

    @Test
    fun aStoredClientIdentifierIsKeptAndAnEmptyOneReplaced() = runTest {
        data.deviceSettings.set(AppSettings.clientIdentifier, "preset-id")
        assertEquals("preset-id", identity.getOrCreateClientIdentifier())
        data.deviceSettings.set(AppSettings.clientIdentifier, "")
        assertTrue(identity.getOrCreateClientIdentifier().isNotEmpty())
    }

    @Test
    fun theActiveMarkerIsSetAndCleared() = runTest {
        assertNull(identity.activeProfileId())
        identity.setActiveProfileId("plex-home-plex.a-aaaaaaaaaaaaaaaa")
        assertEquals("plex-home-plex.a-aaaaaaaaaaaaaaaa", identity.activeProfileId())
        identity.clearActiveProfileId()
        assertNull(identity.activeProfileId())
    }

    @Test
    fun recencyIsKeptPerProfileAndClearedOneOrAll() = runTest {
        identity.markProfileUsed("local-1", 10)
        identity.markProfileUsed("plex-home-plex.a-aaaaaaaaaaaaaaaa", 20)
        assertEquals(mapOf("local-1" to 10L, "plex-home-plex.a-aaaaaaaaaaaaaaaa" to 20L), identity.profilesLastUsed(listOf("local-1", "plex-home-plex.a-aaaaaaaaaaaaaaaa", "never")))
        identity.clearProfileLastUsed("local-1")
        assertNull(identity.profileLastUsed("local-1"))
        identity.clearAllProfileLastUsed()
        assertNull(identity.profileLastUsed("plex-home-plex.a-aaaaaaaaaaaaaaaa"))
    }

    @Test
    fun plexHomeUsersAreCachedPerAccount() = runTest {
        val users = listOf(PlexHomeUser(id = 1, uuid = "aaaaaaaaaaaaaaaa", title = "Owner", thumb = "", admin = true))
        identity.savePlexHomeUsers("plex.a", users)
        identity.savePlexHomeUsers("plex.b", users)
        assertEquals(users, identity.plexHomeUsers("plex.a"))
        assertEquals(JsonArray(users.map { it.toJson() }), data.deviceSettings.value(AppSettings.plexHomeUsers("plex.a")))
        identity.clearPlexHomeUsers("plex.a")
        assertNull(identity.plexHomeUsers("plex.a"))
        assertEquals(users, identity.plexHomeUsers("plex.b"))
        identity.clearAllPlexHomeUsers()
        assertNull(identity.plexHomeUsers("plex.b"))
    }

    @Test
    fun plexHomeUsersAreKeptUnderTheAccountsKeyAndClearingThemAllLeavesOtherSettings() = runTest {
        val users = listOf(PlexHomeUser(id = 1, uuid = "aaaaaaaaaaaaaaaa", title = "Owner", thumb = "", admin = true))
        identity.savePlexHomeUsers("plex.a", users)
        identity.markProfileUsed("local-1", 10)
        data.deviceSettings.set(AppSettings.seekTimeSmall, 30)
        assertEquals(JsonArray(users.map { it.toJson() }).toString(), data.storedJson("plex_home_users_plex.a"))

        identity.clearAllPlexHomeUsers()

        assertNull(data.storedJson("plex_home_users_plex.a"))
        assertEquals(10L, identity.profileLastUsed("local-1"))
        assertEquals(30, data.deviceSettings.value(AppSettings.seekTimeSmall))
    }
}

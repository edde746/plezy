package com.edde746.plezy.profiles

import com.edde746.plezy.data.connections.StoredConnection
import com.edde746.plezy.model.BackendKind
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class ProfileMergeTest {
    private fun homeUser(uuid: String, protected: Boolean = false) =
        PlexHomeUser(id = 1, uuid = uuid, title = "Home $uuid", thumb = "", protected = protected)

    private fun local(id: String, lastUsedAt: Long? = null) = LocalProfile(id, id, createdAt = 1, lastUsedAt = lastUsedAt)

    private fun plexAccount(id: String, createdAt: Long = 1) = StoredConnection(
        id,
        BackendKind.PLEX,
        Json.parseToJsonElement("""{"accountToken":"owner-$id","clientIdentifier":"c","accountLabel":"Plex","servers":[]}""").jsonObject,
        createdAt,
    )

    private fun jellyfin(id: String) = StoredConnection(id, BackendKind.JELLYFIN, Json.parseToJsonElement("{}").jsonObject, 1)

    @Test
    fun localAndPlexHomeProfilesSortByMostRecentUse() {
        val plexId = plexHomeProfileId("plex-1", "home-1")
        val profiles = mergeLocalWithPlexHome(
            locals = listOf(local("local-older"), local("local-never")),
            plexHomeByConnectionId = mapOf("plex-1" to listOf(homeUser("home-1"))),
            connectionIds = setOf("plex-1"),
            storedLastUsed = mapOf("local-older" to 2, plexId to 3),
        )
        assertEquals(listOf(plexId, "local-older", "local-never"), profiles.map { it.id })
        assertEquals(3, profiles.first().lastUsedAt)
    }

    @Test
    fun neverUsedProfilesKeepTheirFallbackOrder() {
        val profiles = mergeLocalWithPlexHome(
            locals = listOf(local("local-a"), local("local-b")),
            plexHomeByConnectionId = mapOf("plex-1" to listOf(homeUser("home-1"), homeUser("home-2"))),
            connectionIds = setOf("plex-1"),
        )
        assertEquals(
            listOf("local-a", "local-b", plexHomeProfileId("plex-1", "home-1"), plexHomeProfileId("plex-1", "home-2")),
            profiles.map { it.id },
        )
    }

    @Test
    fun aLocalProfileWasLastUsedAtTheLaterOfItsTwoTimes() {
        val profiles = mergeLocalWithPlexHome(
            locals = listOf(local("local-db-newer", lastUsedAt = 3), local("local-storage-newer")),
            plexHomeByConnectionId = emptyMap(),
            connectionIds = emptySet(),
            storedLastUsed = mapOf("local-storage-newer" to 4, "local-db-newer" to 2),
        )
        assertEquals(listOf("local-storage-newer" to 4L, "local-db-newer" to 3L), profiles.map { it.id to it.lastUsedAt })
    }

    @Test
    fun homeUsersOfAnAccountThatIsGoneAreLeftOut() {
        val profiles = mergeLocalWithPlexHome(emptyList(), mapOf("gone" to listOf(homeUser("home-1"))), setOf("plex-1"))
        assertEquals(emptyList(), profiles)
    }

    @Test
    fun theActiveProfileIsTheStoredIdOnlyWhileItResolves() {
        val profiles = listOf(local("a"), local("b"))
        assertEquals("b", resolveActiveProfile(profiles, "b")?.id)
        assertNull(resolveActiveProfile(profiles, null), "no stored id never picks the first profile")
        assertNull(resolveActiveProfile(profiles, "gone"))
        assertNull(resolveActiveProfile(emptyList(), "a"))
    }

    @Test
    fun aLocalProfileShowsAllItsBindings() {
        val rows = listOf(ProfileConnection("local-1", "plex-1", userIdentifier = "u1"), ProfileConnection("local-1", "jellyfin-1", userIdentifier = "u2"))
        assertEquals(rows, visibleProfileConnections(local("local-1"), rows))
    }

    @Test
    fun aPlexHomeProfileHidesItsOwnAccountsTokenBinding() {
        val profile = PlexHomeProfile.virtualPlexHome("plex-1", homeUser("aaaaaaaaaaaaaaaa"))
        val rows = listOf(
            ProfileConnection(profile.id, "plex-1", userIdentifier = "aaaaaaaaaaaaaaaa"),
            ProfileConnection(profile.id, "jellyfin-1", userIdentifier = "user-2"),
        )
        assertEquals(listOf("jellyfin-1"), visibleProfileConnections(profile, rows).map { it.connectionId })
    }

    @Test
    fun aPlexHomeProfileActsAsItsOwnAccountAndUser() {
        val profile = PlexHomeProfile.virtualPlexHome("plex-2", homeUser("aaaaaaaaaaaaaaaa"))
        val identity = resolveActivePlexIdentity(profile, emptyList(), listOf(plexAccount("plex-1"), plexAccount("plex-2")))
        assertEquals("plex-2", identity?.account?.id)
        assertEquals("aaaaaaaaaaaaaaaa", identity?.userUuid)
    }

    @Test
    fun aLocalProfileActsAsItsFirstPlexBinding() {
        val connections = listOf(jellyfin("jf"), plexAccount("plex-1"))
        val bindings = listOf(ProfileConnection("local-1", "jf", userIdentifier = "x"), ProfileConnection("local-1", "plex-1", userIdentifier = ""))
        val identity = resolveActivePlexIdentity(local("local-1"), bindings, connections)
        assertEquals("plex-1", identity?.account?.id)
        assertNull(identity?.userUuid)
        assertNull(resolveActivePlexIdentity(local("local-1"), bindings.take(1), connections), "a local profile without a Plex binding has none")
        assertEquals("plex-1", resolveActivePlexIdentity(null, emptyList(), connections)?.account?.id)
    }

    @Test
    fun theProfilesOwnTokenWinsAndTheOwnersIsAFallback() {
        val account = plexAccount("plex-1")
        val home = PlexHomeProfile.virtualPlexHome("plex-1", homeUser("aaaaaaaaaaaaaaaa"))
        val identity = ActivePlexIdentity(account, "aaaaaaaaaaaaaaaa")
        val withToken = listOf(ProfileConnection(home.id, "plex-1", "switched", "aaaaaaaaaaaaaaaa"))
        assertEquals("switched", resolveActivePlexToken(identity, home, withToken, false)?.token)
        assertNull(resolveActivePlexToken(identity, home, emptyList(), false))
        assertEquals("owner-plex-1", resolveActivePlexToken(identity, home, emptyList(), true)?.token)
        assertEquals("owner-plex-1", resolveActivePlexToken(ActivePlexIdentity(account, null), local("local-1"), emptyList(), false)?.token)
    }
}

package com.edde746.plezy.profiles

import com.edde746.plezy.data.TestClock
import com.edde746.plezy.data.connections.ConnectionStore
import com.edde746.plezy.data.connections.StoredConnection
import com.edde746.plezy.data.downloads.SyncRuleTarget
import com.edde746.plezy.data.music.MusicSession
import com.edde746.plezy.data.testData
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.secrets.MemorySecretStore
import com.edde746.plezy.servers.OfflineWatchActionType
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.ProfileSettings
import com.edde746.plezy.settings.ServerSettings
import com.edde746.plezy.settings.store
import com.edde746.plezy.settings.storedJson
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonObject
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ProfileTeardownTest {
    private val data = testData(TestClock())
    private val secrets = MemorySecretStore()
    private val connections = ConnectionStore(data, secrets)
    private val bindings = ProfileConnectionRegistry(data, secrets)
    private val identity = ProfileIdentity(data)
    private val teardown = ProfileTeardown(data, connections, bindings)

    @AfterTest
    fun close() = data.close()

    private val uuid = "aaaaaaaaaaaaaaaa"

    private fun jellyfin(userId: String = "user-a") = StoredConnection(
        "jf-machine/$userId",
        BackendKind.JELLYFIN,
        Json.parseToJsonElement("""{"baseUrl":"https://jellyfin.local","serverMachineId":"jf-machine","userId":"$userId","accessToken":"token-$userId"}""").jsonObject,
        1_000_000,
    )

    private fun plex(id: String = "plex-account", machine: String = "plex-machine") = StoredConnection(
        id,
        BackendKind.PLEX,
        Json.parseToJsonElement("""{"accountToken":"account-token","servers":[{"name":"Server","clientIdentifier":"$machine","accessToken":"server-token","connections":[{"protocol":"https","address":"10.0.0.2","port":32400,"uri":"https://10-0-0-2.example.invalid:32400","local":true,"relay":false,"IPv6":false}]}]}""").jsonObject,
        1_000_000,
    )

    private fun homeUser(uuid: String) = PlexHomeUser(id = 1, uuid = uuid, title = "User $uuid", thumb = "")

    private suspend fun bind(profileId: String, connection: StoredConnection, user: String = "user") =
        bindings.upsert(ProfileConnection(profileId, connection.id, "t", user))

    @Test
    fun removingTheLastLinkToAJellyfinConnectionRemovesIt() = runTest {
        val jf = jellyfin()
        connections.upsert(jf)
        bind("p1", jf)
        teardown.removeProfileConnection("p1", jf)
        assertEquals(emptyList(), bindings.listForConnection(jf.id))
        assertNull(connections.get(jf.id))
    }

    @Test
    fun removingOneLinkKeepsASharedJellyfinConnection() = runTest {
        val jf = jellyfin()
        connections.upsert(jf)
        bind("p1", jf)
        bind("p2", jf)
        teardown.removeProfileConnection("p1", jf)
        assertNotNull(connections.get(jf.id))
        assertEquals(listOf("p2"), bindings.listForConnection(jf.id).map { it.profileId })
    }

    @Test
    fun unlinkingAPlexAccountKeepsTheAccount() = runTest {
        val account = plex()
        connections.upsert(account)
        bind("p1", account, "home-user")
        teardown.removeProfileConnection("p1", account)
        assertNotNull(connections.get(account.id))
        assertEquals(emptyList(), bindings.listForConnection(account.id))
    }

    @Test
    fun pruningRemovesOnlyUnreferencedJellyfinConnections() = runTest {
        val orphan = jellyfin("user-a")
        val shared = jellyfin("user-b")
        connections.upsert(orphan)
        connections.upsert(shared)
        connections.upsert(plex())
        bind("p2", shared)
        assertEquals(1, teardown.pruneUnreferencedJellyfinConnections())
        assertEquals(setOf(shared.id, "plex-account"), connections.list().map { it.id }.toSet())
    }

    @Test
    fun signingOutRemovesTheAccountItsHomeProfilesAndWhatTheyBorrowed() = runTest {
        val account = plex()
        val jf = jellyfin()
        val home = plexHomeProfileId(account.id, uuid)
        connections.upsert(account)
        connections.upsert(jf)
        bind(home, account, uuid)
        bind(home, jf)
        identity.savePlexHomeUsers(account.id, listOf(homeUser(uuid)))
        identity.markProfileUsed(home, 2_000_000)
        val planned = teardown.planPlexAccountRemoval(account.id)
        assertEquals(PlexAccountRemoval(setOf(home), emptySet()), planned)
        assertEquals(2, bindings.listAll().size, "planning changes nothing")

        val removal = teardown.signOutPlexAccount(account, planned)

        assertEquals(planned, removal)
        assertEquals(emptyList(), connections.list())
        assertEquals(emptyList(), bindings.listAll())
        assertNull(identity.plexHomeUsers(account.id))
        assertNull(identity.profileLastUsed(home))
        assertTrue(secrets.entries.isEmpty(), "every token went with them")
    }

    @Test
    fun signingOutKeepsAJellyfinConnectionAnotherProfileUses() = runTest {
        val account = plex()
        val jf = jellyfin()
        val home = plexHomeProfileId(account.id, uuid)
        connections.upsert(account)
        connections.upsert(jf)
        bind(home, account, uuid)
        bind(home, jf)
        bind("local-1", jf)
        teardown.signOutPlexAccount(account)
        assertNotNull(connections.get(jf.id))
        assertEquals(listOf("local-1"), bindings.listAll().map { it.profileId })
    }

    @Test
    fun aLocalBorrowerKeepsItsOtherConnections() = runTest {
        val account = plex()
        val jf = jellyfin()
        connections.upsert(account)
        connections.upsert(jf)
        bind("local-1", account)
        bind("local-1", jf)
        val removal = teardown.signOutPlexAccount(account)
        assertEquals(PlexAccountRemoval(emptySet(), setOf("local-1")), removal)
        assertEquals(listOf(jf.id), connections.list().map { it.id })
        assertEquals(listOf(jf.id), bindings.listAll().map { it.connectionId })
        assertTrue(bindings.listAll().single().isDefault)
    }

    @Test
    fun signingOutLeavesAnotherAccountAlone() = runTest {
        val first = plex()
        val second = plex("plex-account-2", "plex-machine-2")
        val v1 = plexHomeProfileId(first.id, uuid)
        val v2 = plexHomeProfileId(second.id, "bbbbbbbbbbbbbbbb")
        connections.upsert(first)
        connections.upsert(second)
        bind(v1, first, uuid)
        bind(v2, second, "bbbbbbbbbbbbbbbb")
        identity.savePlexHomeUsers(second.id, listOf(homeUser("bbbbbbbbbbbbbbbb")))
        assertEquals(setOf(v1), teardown.signOutPlexAccount(first).removedVirtualProfileIds)
        assertNotNull(connections.get(second.id))
        assertEquals(listOf(v2), bindings.listAll().map { it.profileId })
        assertNotNull(identity.plexHomeUsers(second.id))
    }

    @Test
    fun signingOutTwiceIsHarmless() = runTest {
        val account = plex()
        val jf = jellyfin()
        val home = plexHomeProfileId(account.id, uuid)
        connections.upsert(account)
        connections.upsert(jf)
        bind(home, account, uuid)
        bind(home, jf)
        teardown.signOutPlexAccount(account)
        assertEquals(emptySet(), teardown.signOutPlexAccount(account).removedVirtualProfileIds)
        assertEquals(emptyList(), connections.list())
    }

    @Test
    fun deletingALocalProfileRemovesItsRowBindingsAndRecency() = runTest {
        val jf = jellyfin()
        connections.upsert(jf)
        data.profiles.upsert(LocalProfile("local-1", "Me", createdAt = 1))
        bind("local-1", jf)
        identity.markProfileUsed("local-1", 5)
        teardown.deleteLocalProfile("local-1")
        assertEquals(emptyList(), data.profiles.list())
        assertEquals(emptyList(), connections.list(), "the Jellyfin connection only it used went too")
        assertNull(identity.profileLastUsed("local-1"))
    }

    @Test
    fun noConnectionsLeftSignsOut() = runTest {
        identity.setActiveProfileId("local-1")
        assertNull(teardown.resolvePostRemovalState(emptyMap()))
        assertEquals(PostRemovalOutcome.SignedOut, teardown.settleAfterRemoval(emptyMap()))
        assertNull(identity.activeProfileId())
    }

    @Test
    fun anOrphanedJellyfinConnectionIsPrunedAndSignsOut() = runTest {
        connections.upsert(jellyfin())
        assertNull(teardown.resolvePostRemovalState(emptyMap()))
        assertEquals(emptyList(), connections.list())
    }

    @Test
    fun anAccountWithCachedHomeUsersStaysSignedIn() = runTest {
        val account = plex()
        connections.upsert(account)
        val profiles = teardown.resolvePostRemovalState(mapOf(account.id to listOf(homeUser(uuid))))
        assertTrue(profiles!!.single() is PlexHomeProfile)
    }

    @Test
    fun anAccountWithoutResolvableProfilesSignsOut() = runTest {
        val account = plex()
        connections.upsert(account)
        bind(plexHomeProfileId(account.id, uuid), account)
        assertNull(teardown.resolvePostRemovalState(emptyMap()))
    }

    @Test
    fun aLocalProfileSurvivesAnOrphanBeingPruned() = runTest {
        val orphan = jellyfin("user-a")
        val referenced = jellyfin("user-b")
        connections.upsert(orphan)
        connections.upsert(referenced)
        data.profiles.upsert(LocalProfile("local-1", "Me", createdAt = 1))
        bind("local-1", referenced)
        assertEquals(listOf("local-1"), teardown.resolvePostRemovalState(emptyMap())!!.map { it.id })
        assertNull(connections.get(orphan.id))
        assertNotNull(connections.get(referenced.id))
    }

    @Test
    fun settlingKeepsTheActiveProfileOrHandsOverToOneWithoutAPin() = runTest {
        val jf = jellyfin()
        connections.upsert(jf)
        data.profiles.upsert(LocalProfile("local-pin", "Pin", pinHash = computePinHash("1234"), createdAt = 1))
        data.profiles.upsert(LocalProfile("local-open", "Open", createdAt = 2))
        bind("local-open", jf)
        identity.markProfileUsed("local-pin", 10)
        identity.setActiveProfileId("local-open")
        assertEquals("local-open", (teardown.settleAfterRemoval(emptyMap()) as PostRemovalOutcome.KeepActive).profile.id)

        identity.setActiveProfileId("gone")
        assertEquals("local-open", (teardown.settleAfterRemoval(emptyMap()) as PostRemovalOutcome.Activate).profile.id)

        data.profiles.remove("local-open")
        bind("local-pin", jf)
        assertEquals(PostRemovalOutcome.PickProfile, teardown.settleAfterRemoval(emptyMap()))
        assertNull(identity.activeProfileId())
    }

    @Test
    fun loggingOutForgetsEveryServersEndpointAndTheOldServerOrder() = runTest {
        data.serverSettings.save(ServerId("plex-machine"), "https://10-0-0-2.example.invalid:32400")
        data.serverSettings.save(ServerId("jf-machine"), "https://jellyfin.local")
        data.deviceSettings.set(AppSettings.serverOrder, JsonArray(listOf(JsonPrimitive("plex-machine"))))

        teardown.logOutAll()

        assertEquals(emptyMap(), data.serverSettings.values(ServerSettings.serverEndpoint))
        assertNull(data.deviceSettings.value(AppSettings.serverOrder))
    }

    /** A sync rule, a download collection, a queued watch action, a music session and a profile setting of [profileId]. */
    private suspend fun seedProfileRows(profileId: String) {
        data.syncRules.upsert(profileId, ServerId("srv"), "10", SyncRuleTarget.SHOW, 5)
        data.downloadCollections.replace(profileId, "srv", mapOf("dune" to listOf("dune-1")), setOf("dune-1"), syncedAt = 1)
        data.offlineWatch.insertMark(profileId, ServerId("srv"), null, "42", OfflineWatchActionType.WATCHED)
        data.musicSessions.save(MusicSession(profileId, "[]", "[]", 0, false, "off", null, null, 0, 1))
        data.profileSettings.set(profileUserScope(profileId), ProfileSettings.catalogActiveSource, "trakt")
    }

    /** Which of [seedProfileRows]' rows [profileId] still has, by table. */
    private suspend fun rowsOf(profileId: String) = mapOf(
        "sync rule" to data.syncRules.rules(profileId).isNotEmpty(),
        "collection" to data.downloadCollections.collections(profileId).isNotEmpty(),
        "watch action" to data.offlineWatch.pendingActions(profileId).isNotEmpty(),
        "music session" to (data.musicSessions.load(profileId) != null),
        "setting" to (data.profileSettings.value(profileUserScope(profileId), ProfileSettings.catalogActiveSource) != null),
    )

    private fun rows(present: Boolean) = mapOf(
        "sync rule" to present,
        "collection" to present,
        "watch action" to present,
        "music session" to present,
        "setting" to present,
    )

    @Test
    fun deletingALocalProfileTakesItsRowsInEveryTableAndLeavesAnotherProfilesAlone() = runTest {
        for (id in listOf("local-1", "local-2")) {
            data.profiles.upsert(LocalProfile(id, "Me", createdAt = 1))
            seedProfileRows(id)
        }

        teardown.deleteLocalProfile("local-1")

        assertEquals(rows(false), rowsOf("local-1"))
        assertEquals(rows(true), rowsOf("local-2"))
    }

    @Test
    fun signingOutTakesTheHomeProfilesRowsAndSettingsAndLeavesTheBorrowersAlone() = runTest {
        val account = plex()
        val home = plexHomeProfileId(account.id, uuid)
        connections.upsert(account)
        bind(home, account, uuid)
        data.profiles.upsert(LocalProfile("local-1", "Me", createdAt = 1))
        bind("local-1", account)
        seedProfileRows(home)
        seedProfileRows("local-1")

        teardown.signOutPlexAccount(account)

        assertEquals(rows(false), rowsOf(home))
        assertEquals(rows(true), rowsOf("local-1"))
        assertEquals(emptyList(), bindings.listAll())
    }

    @Test
    fun unlinkingAServerAnotherProfileStillReachesClearsOnlyThisProfilesChoicesForIt() = runTest {
        val jf = jellyfin()
        connections.upsert(jf)
        bind("p1", jf)
        bind("p2", jf)
        identity.setActiveProfileId("p1")
        data.libraryPrefs.setHiddenLibraries(setOf("jf-machine:movies", "other:shows"), "p1")
        data.libraryPrefs.setHiddenLibraries(setOf("jf-machine:movies"), "p2")
        data.store("hidden_libraries", """["jf-machine:legacy","other:legacy"]""")

        teardown.removeProfileConnection("p1", jf)

        assertEquals(setOf("other:shows"), data.libraryPrefs.hiddenLibraries("p1"))
        assertEquals(setOf("jf-machine:movies"), data.libraryPrefs.hiddenLibraries("p2"))
        assertEquals("""["other:legacy"]""", data.storedJson("hidden_libraries"), "the active profile's unscoped choices too")
        assertNotNull(connections.get(jf.id))
    }

    @Test
    fun aJellyfinServerNoProfileReachesLosesItsChoicesEverywhereAndAPlexServerOnlyForTheProfile() = runTest {
        val jf = jellyfin()
        val account = plex()
        connections.upsert(jf)
        connections.upsert(account)
        bind("p1", jf)
        bind("p1", account)
        for (profileId in listOf("p1", "p2")) data.libraryPrefs.setHiddenLibraries(setOf("jf-machine:movies", "plex-machine:films"), profileId)

        teardown.removeProfileConnection("p1", jf)
        assertEquals(setOf("plex-machine:films"), data.libraryPrefs.hiddenLibraries("p1"))
        assertEquals(setOf("plex-machine:films"), data.libraryPrefs.hiddenLibraries("p2"), "no profile reaches the Jellyfin server any more")
        assertNull(connections.get(jf.id))

        teardown.removeProfileConnection("p1", account)
        assertEquals(emptySet(), data.libraryPrefs.hiddenLibraries("p1"))
        assertEquals(setOf("plex-machine:films"), data.libraryPrefs.hiddenLibraries("p2"), "a Plex account stays, so do other profiles' choices")
    }

    @Test
    fun loggingOutOfEverythingWipesAccountsProfilesAndTheirDataAndKeepsTheDevicesSettings() = runTest {
        val account = plex()
        val jf = jellyfin()
        val home = plexHomeProfileId(account.id, uuid)
        connections.upsert(account)
        connections.upsert(jf)
        data.profiles.upsert(LocalProfile("local-1", "Me", createdAt = 1))
        bind(home, account, uuid)
        bind("local-1", jf)
        identity.savePlexHomeUsers(account.id, listOf(homeUser(uuid)))
        identity.setActiveProfileId("local-1")
        identity.markProfileUsed(home, 1)
        identity.markProfileUsed("local-1", 2)
        identity.getOrCreateClientIdentifier()
        for (profileId in listOf(home, "local-1")) seedProfileRows(profileId)
        data.libraryPrefs.setHiddenLibraries(setOf("jf-machine:movies"), "local-1")
        data.store("hidden_libraries", """["jf-machine:legacy"]""")
        data.deviceSettings.set(AppSettings.seekTimeSmall, 30)

        teardown.logOutAll()

        assertEquals(emptyList(), connections.list())
        assertEquals(emptyList(), bindings.listAll())
        assertEquals(emptyList(), data.profiles.list())
        assertTrue(secrets.entries.isEmpty(), "every token went")
        assertNull(identity.plexHomeUsers(account.id))
        assertNull(identity.activeProfileId())
        assertNull(identity.profileLastUsed(home))
        assertNull(identity.profileLastUsed("local-1"))
        assertNull(data.deviceSettings.value(AppSettings.clientIdentifier))
        assertNull(data.storedJson("hidden_libraries"))
        assertEquals(emptySet(), data.libraryPrefs.hiddenLibraries("local-1"))
        // Music sessions are left as the earlier releases left them.
        for (profileId in listOf(home, "local-1")) assertEquals(rows(false) + ("music session" to true), rowsOf(profileId), profileId)
        assertEquals(30, data.deviceSettings.value(AppSettings.seekTimeSmall), "the device's settings stay")
    }
}

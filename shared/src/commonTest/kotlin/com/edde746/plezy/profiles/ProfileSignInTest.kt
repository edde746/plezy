package com.edde746.plezy.profiles

import com.edde746.plezy.model.ServerId
import com.edde746.plezy.plex.tv.jsonResponse
import io.ktor.client.engine.mock.MockRequestHandleScope
import io.ktor.client.request.HttpRequestData
import io.ktor.client.request.HttpResponseData
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFails
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ProfileSignInTest {
    private val aliceUuid = "aaaaaaaaaaaaaaaa"

    private fun homeUserJson(uuid: String, protected: Boolean = false) =
        """{"id":1,"uuid":"$uuid","title":"User $uuid","thumb":"","protected":$protected,"admin":true}"""

    /** plex.tv for account `acct-uuid` (user "owner") with [users] in its Home and [servers]. */
    private fun MockRequestHandleScope.plexAccountTv(
        request: HttpRequestData,
        users: List<String> = listOf(homeUserJson(aliceUuid)),
        servers: String = resources(serverJson()),
    ): HttpResponseData {
        val path = request.url.encodedPath
        return when {
            path.endsWith("/user") -> jsonResponse("""{"uuid":"acct-uuid","username":"owner","email":"owner@example.com"}""")
            path.endsWith("/home/users") -> jsonResponse("""{"id":1,"users":[${users.joinToString(",")}]}""")
            else -> plexTvAnswer(request, switchToken = "user-token", resourcesBody = servers)
        }
    }

    @Test
    fun registeringStoresTheAccountByUuidAndFoldsTheClientIdRow() = profileTest { h ->
        h.plexTv = { plexAccountTv(it) }
        h.store(plexAccount("plex.client-id"))
        h.data.profiles.upsert(local("local-a"))
        h.bindings.upsert(ProfileConnection("local-a", "plex.client-id", "kept", aliceUuid))
        h.cacheHomeUsers("plex.client-id", homeUser())

        val registration = h.services.registerPlexAccountFromToken("new-token")

        assertEquals("plex.acct-uuid", registration.connection.id)
        assertEquals("owner", registration.connection.accountLabel)
        assertTrue(registration.existedBefore)
        assertTrue(registration.homeUsersFetched)
        assertEquals(h.clock.now, registration.connection.createdAt)
        assertNull(h.connections.get("plex.client-id"))
        assertNull(h.identity.plexHomeUsers("plex.client-id"))
        assertEquals(listOf("plex.acct-uuid"), h.bindings.listForProfile("local-a").map { it.connectionId })
        assertEquals("new-token", h.connections.get("plex.acct-uuid")?.plexAccount()?.accountToken)
        assertEquals(listOf(aliceUuid), h.services.plexHomeUsers.value["plex.acct-uuid"]?.map { it.uuid })
    }

    @Test
    fun aSingleUnprotectedHomeUserBecomesActive() = profileTest { h ->
        h.plexTv = { plexAccountTv(it) }

        val result = assertIs<PlexSignInResult.SignedIn>(h.services.signInWithPlex("token"))

        assertFalse(result.pickProfile)
        assertEquals(plexHomeProfileId("plex.acct-uuid", aliceUuid), h.services.active.value?.id)
        assertTrue(h.services.awaitBindingSettle())
        assertEquals(listOf(ServerId("srv-1")), h.manager.onlineServerIds)
    }

    @Test
    fun aProtectedOrSecondHomeUserGoesThroughThePicker() = profileTest { h ->
        h.plexTv = { plexAccountTv(it, users = listOf(homeUserJson(aliceUuid, protected = true))) }

        val result = assertIs<PlexSignInResult.SignedIn>(h.services.signInWithPlex("token"))

        assertTrue(result.pickProfile)
        assertNull(h.services.active.value)
        assertNull(h.identity.activeProfileId())
    }

    @Test
    fun anAccountWithoutServersSaysSo() = profileTest { h ->
        h.plexTv = { plexAccountTv(it, servers = "[]") }

        assertEquals(PlexSignInResult.NoServers("owner", "owner@example.com"), h.services.signInWithPlex("token"))
        assertNull(h.services.active.value)
    }

    @Test
    fun theFirstJellyfinSignInMakesALocalProfile() = profileTest { h ->
        val jf = jellyfin()

        val added = assertIs<MediaBrowserAddResult.Added>(h.services.addMediaBrowserConnection(jf))

        val profile = assertIs<LocalProfile>(added.profile)
        assertTrue(profile.id.startsWith("local-"))
        assertEquals("User user-a", profile.displayName)
        assertEquals(h.clock.now, profile.sortOrder)
        assertNull(profile.pinHash)
        assertEquals(profile.id, h.identity.activeProfileId())
        assertEquals(profile.id, h.services.active.value?.id)
        val row = assertNotNull(h.bindings.get(profile.id, jf.id))
        assertEquals(jf.accessToken, row.userToken)
        assertEquals(jf.userId, row.userIdentifier)
        assertEquals(h.clock.now, row.tokenAcquiredAt)
        assertNotNull(h.connections.get(jf.id))
    }

    @Test
    fun aFailureStoringTheBindingLeavesNeitherTheProfileNorTheConnection() = profileTest { h ->
        h.data.driver.execute(null, "CREATE TRIGGER refuse_binding BEFORE INSERT ON profile_connections BEGIN SELECT RAISE(ABORT, 'refused'); END", 0)

        assertFails { h.services.addMediaBrowserConnection(jellyfin()) }

        assertEquals(emptyList(), h.data.profiles.list())
        assertNull(h.connections.get(jellyfin().id))
        assertTrue(h.secrets.entries.isEmpty(), "the token written for it went")
        assertNull(h.identity.activeProfileId())
    }

    @Test
    fun profilesButNoneActiveAsksForOneFirst() = profileTest { h ->
        h.data.profiles.upsert(local("local-a"))

        assertEquals(MediaBrowserAddResult.PickProfile, h.services.addMediaBrowserConnection(jellyfin()))

        assertNull(h.connections.get(jellyfin().id))
    }

    @Test
    fun aJellyfinUserAddedToAnotherProfileLeavesTheActiveOne() = profileTest { h ->
        h.data.profiles.upsert(local("local-a"))
        h.data.profiles.upsert(local("local-b"))
        h.identity.setActiveProfileId("local-a")
        h.startAndSettle()
        val jf = jellyfin()

        h.services.addMediaBrowserConnection(jf, targetProfile = local("local-b"))

        assertEquals("local-a", h.services.active.value?.id)
        assertEquals(listOf(jf.id), h.bindings.listForProfile("local-b").map { it.connectionId })
        assertEquals(emptyList(), h.bindings.listForProfile("local-a"))
    }

    @Test
    fun aNewLocalProfileIsStoredNotActivated() = profileTest { h ->
        val profile = h.services.createLocalProfile("  Kid  ", pin = "1234")

        assertTrue(Regex("local-[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}").matches(profile.id))
        assertEquals("Kid", profile.displayName)
        assertEquals(h.clock.now, profile.sortOrder)
        assertEquals(h.clock.now, profile.createdAt)
        assertEquals(computePinHash("1234"), profile.pinHash)
        assertEquals(listOf(profile), h.data.profiles.list())
        assertNull(h.identity.activeProfileId())
        assertFailsWith<IllegalArgumentException> { h.services.createLocalProfile("   ") }
    }

    @Test
    fun borrowingAJellyfinUserChecksTheSourcesPinAndCopiesItsToken() = profileTest { h ->
        val jf = jellyfin()
        h.store(jf)
        h.data.profiles.upsert(local("local-a", pin = "1234"))
        h.data.profiles.upsert(local("local-b"))
        h.bindings.upsert(ProfileConnection("local-a", jf.id, "source-token", jf.userId))
        h.identity.setActiveProfileId("local-b")
        h.startAndSettle()
        val target = local("local-b")
        val candidate = h.services.borrowCandidates(target).single()

        h.pins = mutableListOf("0000")
        assertEquals(BorrowResult.INCORRECT_PIN, h.services.borrow(target, candidate, h.pinPrompt))
        h.pins = mutableListOf("1234")
        assertEquals(BorrowResult.BORROWED, h.services.borrow(target, candidate, h.pinPrompt))

        val row = assertNotNull(h.bindings.get("local-b", jf.id))
        assertEquals("source-token", row.userToken)
        assertEquals(jf.userId, row.userIdentifier)
        assertEquals(emptyList(), h.services.borrowCandidates(target))
    }

    @Test
    fun borrowingAHomeUserMintsTheBorrowersOwnToken() = profileTest { h ->
        h.plexTv = { plexTvAnswer(it, switchToken = "borrowed-token") }
        h.store(plexAccount())
        h.cacheHomeUsers("plex.account", homeUser())
        h.data.profiles.upsert(local("local-b"))
        h.identity.setActiveProfileId("local-b")
        h.startAndSettle()
        val target = local("local-b")
        val candidate = h.services.borrowCandidates(target).single()

        assertEquals(plexHomeProfileId("plex.account", aliceUuid), candidate.source.id)
        assertEquals(BorrowResult.BORROWED, h.services.borrow(target, candidate, h.pinPrompt))

        val row = assertNotNull(h.bindings.get("local-b", "plex.account"))
        assertEquals("borrowed-token", row.userToken)
        assertEquals(aliceUuid, row.userIdentifier)
    }

    @Test
    fun bootPrunesUnusedJellyfinConnectionsAndSignsIn() = profileTest { h ->
        h.store(jellyfin())

        h.services.start()

        assertEquals(BootRoute.SIGN_IN, h.services.bootRoute())
        assertNull(h.connections.get(jellyfin().id))
    }

    @Test
    fun bootSignsInWhenConnectionsLeaveNoProfile() = profileTest { h ->
        h.store(plexAccount())

        h.services.start()

        assertEquals(BootRoute.SIGN_IN, h.services.bootRoute())
    }

    @Test
    fun bootGoesToThePickerWithoutAnActiveProfileAndToMainWithOne() = profileTest { h ->
        h.store(plexAccount())
        h.cacheHomeUsers("plex.account", homeUser())
        h.services.start()
        assertEquals(BootRoute.PICK_PROFILE, h.services.bootRoute())
        val second = ProfileHarness(this)
        try {
            second.store(plexAccount())
            second.cacheHomeUsers("plex.account", homeUser())
            second.identity.setActiveProfileId(plexHomeProfileId("plex.account", aliceUuid))
            second.services.start()
            assertEquals(BootRoute.MAIN, second.services.bootRoute())
        } finally {
            second.close()
        }
    }

    @Test
    fun settlingAfterTheActiveProfileWentActivatesTheNextWithoutAPin() = profileTest { h ->
        h.data.profiles.upsert(local("local-a"))
        h.data.profiles.upsert(local("local-kid", pin = "1234", lastUsedAt = 9_000))
        h.data.profiles.upsert(local("local-c", lastUsedAt = 5_000))
        h.store(jellyfin())
        h.bindings.upsert(ProfileConnection("local-c", jellyfin().id, "t", "user-a"))
        h.identity.setActiveProfileId("local-a")
        h.startAndSettle()

        h.services.teardown.deleteLocalProfile("local-a")
        val outcome = h.services.settleAfterRemoval()

        assertEquals("local-c", assertIs<PostRemovalOutcome.Activate>(outcome).profile.id)
        assertEquals("local-c", h.services.active.value?.id)
        assertTrue(h.services.awaitBindingSettle())
        assertEquals(setOf(ServerId("jf-machine")), h.manager.visibleServerIds)
    }

    @Test
    fun settlingWithNothingLeftSignsOut() = profileTest { h ->
        h.data.profiles.upsert(local("local-a"))
        h.identity.setActiveProfileId("local-a")
        h.startAndSettle()

        h.services.teardown.deleteLocalProfile("local-a")

        assertEquals(PostRemovalOutcome.SignedOut, h.services.settleAfterRemoval())
        assertNull(h.services.active.value)
        assertNull(h.identity.activeProfileId())
    }
}

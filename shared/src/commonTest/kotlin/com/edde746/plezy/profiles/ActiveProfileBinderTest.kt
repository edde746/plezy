package com.edde746.plezy.profiles

import com.edde746.plezy.backend.HealthStatus
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.plex.tv.jsonResponse
import com.edde746.plezy.settings.AppSettings
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.io.IOException
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.test.fail
import kotlin.time.Duration.Companion.seconds

/** Lets the background work run until [condition] holds. */
internal suspend fun TestScope.eventually(condition: suspend () -> Boolean) {
    repeat(200) {
        if (condition()) return
        runCurrent()
        advanceTimeBy(10)
    }
    fail("condition not met")
}

class ActiveProfileBinderTest {
    private val srv1 = ServerId("srv-1")
    private val user = homeUser()
    private val homeId = plexHomeProfileId("plex.account", user.uuid)

    /** The account's Home user, active, with a kept token equal to its stored server's own token. */
    private suspend fun ProfileHarness.activePlexHome(protected: Boolean = false, servers: List<com.edde746.plezy.plex.PlexServer> = listOf(plexServer(accessToken = "home-user-token"))) {
        store(plexAccount(servers = servers))
        cacheHomeUsers("plex.account", homeUser(protected = protected))
        bindings.upsert(ProfileConnection(homeId, "plex.account", "home-user-token", user.uuid))
        identity.setActiveProfileId(homeId)
    }

    /** A local profile, active, bound to the Plex account as the Home user with [token]. */
    private suspend fun ProfileHarness.activeLocalPlex(token: String?, servers: List<com.edde746.plezy.plex.PlexServer> = emptyList()) {
        store(plexAccount(servers = servers))
        data.profiles.upsert(local("local-a"))
        bindings.upsert(ProfileConnection("local-a", "plex.account", token, user.uuid))
        identity.setActiveProfileId("local-a")
    }

    private suspend fun ProfileHarness.activeLocalJellyfin(health: HealthStatus) {
        val jf = jellyfin()
        store(jf)
        mediaBrowser.health[jf.id] = health
        data.profiles.upsert(local("local-a"))
        bindings.upsert(ProfileConnection("local-a", jf.id, jf.accessToken, jf.userId))
        identity.setActiveProfileId("local-a")
    }

    @Test
    fun aLocalProfileWithoutConnectionsBindsNoServer() = profileTest { h ->
        h.data.profiles.upsert(local("local-a"))
        h.identity.setActiveProfileId("local-a")

        assertTrue(h.startAndSettle())

        assertEquals(emptySet(), h.manager.visibleServerIds)
    }

    @Test
    fun theServersAreUnsettledUntilTheFirstBindFinishes() = profileTest { h ->
        h.activeLocalJellyfin(HealthStatus.ONLINE)
        // Before the binder starts nothing runs, yet the servers aren't the profile's: Home must not load then.
        assertFalse(h.services.bindState.value.binding)
        assertTrue(h.services.bindState.value.unsettled)

        assertTrue(h.startAndSettle())

        assertFalse(h.services.bindState.value.unsettled)
    }

    @Test
    fun aReachableJellyfinUserShows() = profileTest { h ->
        h.activeLocalJellyfin(HealthStatus.ONLINE)

        assertTrue(h.startAndSettle())

        assertEquals(setOf(ServerId("jf-machine")), h.manager.visibleServerIds)
    }

    @Test
    fun aProfilesServersAreListedInItsOrderWhicheverAnswersFirst() = profileTest { h ->
        // The profile's default binding is Jellyfin; Emby answers its probe first.
        val jellyfin = jellyfin(machineId = "jellyfin-machine")
        val emby = jellyfin(machineId = "emby-machine")
        h.store(jellyfin)
        h.store(emby)
        h.mediaBrowser.healthDelay[jellyfin.id] = 2.seconds
        h.data.profiles.upsert(local("local-a"))
        h.bindings.upsert(ProfileConnection("local-a", jellyfin.id, jellyfin.accessToken, jellyfin.userId))
        h.bindings.upsert(ProfileConnection("local-a", emby.id, emby.accessToken, emby.userId))
        h.identity.setActiveProfileId("local-a")

        assertTrue(h.startAndSettle())

        val order = listOf(ServerId("jellyfin-machine"), ServerId("emby-machine"))
        assertEquals(order, h.manager.serverOrder)
        assertEquals(order, h.manager.onlineServerIds)
        assertEquals(order, h.manager.visibleOnlineClients.keys.toList(), "what every cross-server list fans out over")
    }

    @Test
    fun anUnreachableServerIsAConnectivityOnlyFailure() = profileTest { h ->
        h.activeLocalJellyfin(HealthStatus.OFFLINE)

        assertFalse(h.startAndSettle())

        assertTrue(h.services.bindState.value.connectivityOnlyFailure)
    }

    @Test
    fun aRefusingServerStaysVisibleForItsBanner() = profileTest { h ->
        h.activeLocalJellyfin(HealthStatus.AUTH_ERROR)

        assertTrue(h.startAndSettle())

        assertFalse(h.services.bindState.value.connectivityOnlyFailure)
        assertEquals(setOf(ServerId("jf-machine")), h.manager.visibleServerIds)
    }

    @Test
    fun theFirstBindWaitsForThePickerWhenAskedToOnOpen() = profileTest { h ->
        h.activeLocalJellyfin(HealthStatus.ONLINE)
        h.data.profiles.upsert(local("local-b"))
        h.data.deviceSettings.set(AppSettings.requireProfileSelectionOnOpen, true)

        h.services.start()
        assertEquals(BootRoute.PICK_PROFILE, h.services.bootRoute())
        assertTrue(h.services.awaitBindingSettle())
        assertEquals(emptyList(), h.manager.registeredServerIds)

        assertEquals(ProfileSwitchResult.SWITCHED, h.services.switchProfile(h.services.active.value!!, h.pinPrompt))
        assertEquals(setOf(ServerId("jf-machine")), h.manager.visibleServerIds)
    }

    @Test
    fun aProfileALaunchLinkNamesIsActivatedInPlaceOfThePickerAndThePreviousProfile() = profileTest { h ->
        h.activeLocalJellyfin(HealthStatus.ONLINE)
        h.data.profiles.upsert(local("local-b"))
        h.data.deviceSettings.set(AppSettings.requireProfileSelectionOnOpen, true)
        val settled = mutableListOf<Boolean>()

        h.services.start(startupProfile = { profiles -> profiles.single { it.id == "local-b" } }, settleStartupProfile = { settled += it })

        assertEquals(BootRoute.MAIN, h.services.bootRoute())
        assertEquals("local-b", h.services.active.value?.id)
        assertEquals(listOf(true), settled)
    }

    @Test
    fun aColdStartBindsTheKeptTokenAtOnceThenAppliesPlexTvsAnswer() = profileTest { h ->
        val gate = CompletableDeferred<Unit>()
        h.plexTv = {
            gate.await()
            plexTvAnswer(it)
        }
        h.activePlexHome()

        assertTrue(h.startAndSettle())
        assertEquals("home-user-token", h.plex.clients.getValue(srv1).token)
        assertTrue(h.requestsTo("/switch").isEmpty())

        gate.complete(Unit)

        eventually { h.plex.clients.getValue(srv1).token == "server-token" }
        eventually { h.connections.get("plex.account")?.plexAccount()?.servers?.single()?.accessToken == "server-token" }
    }

    @Test
    fun plexTvUnreachableBindsTheStoredServers() = profileTest { h ->
        h.plexTv = { throw IOException("DNS failed") }
        h.activePlexHome()

        assertTrue(h.startAndSettle())

        assertEquals(listOf(srv1), h.manager.onlineServerIds)
    }

    @Test
    fun aServerThatAnswersSecondsAfterTheBindComesOnlineWithoutAReconnect() = profileTest { h ->
        h.plexTv = { throw IOException("DNS failed") }
        h.activePlexHome()
        h.plex.offline = setOf(srv1)

        assertFalse(h.startAndSettle())
        h.plex.offline = emptySet()
        advanceTimeBy(2.seconds)
        runCurrent()

        assertEquals(listOf(srv1), h.manager.onlineServerIds)
    }

    @Test
    fun aKeptTokenPlexTvRefusesIsDroppedAndTheAccountFlagged() = profileTest { h ->
        h.plexTv = { jsonResponse("""{"errors":[]}""", 401) }
        h.activePlexHome(protected = true)

        assertTrue(h.startAndSettle())

        eventually { h.bindings.get(homeId, "plex.account")?.userToken == null }
        eventually { srv1 in h.manager.authErrorServerIds }
        assertTrue(h.requestsTo("/switch").isEmpty())
    }

    @Test
    fun aKeptTokenListingNoServerIsMintedAgain() = profileTest { h ->
        var resourceCalls = 0
        h.plexTv = { request ->
            if (request.url.encodedPath.endsWith("/resources")) resourceCalls++
            plexTvAnswer(request, switchToken = "fresh-user-token", resourcesBody = if (resourceCalls == 1) "[]" else resources(serverJson()))
        }
        h.activeLocalPlex("stale-user-token", servers = listOf(plexServer(accessToken = "stale-server-token")))

        assertTrue(h.startAndSettle())

        assertEquals(2, resourceCalls)
        assertEquals(1, h.requestsTo("/switch").size)
        assertEquals("fresh-user-token", h.bindings.get("local-a", "plex.account")?.userToken)
        assertEquals(listOf(srv1), h.manager.onlineServerIds)
    }

    @Test
    fun aMissingTokenIsMintedOnceAndKept() = profileTest { h ->
        h.plexTv = { plexTvAnswer(it, switchToken = "fresh-user-token") }
        h.activeLocalPlex(null)

        assertTrue(h.startAndSettle())

        assertEquals(1, h.requestsTo("/switch").size)
        assertEquals(1, h.requestsTo("/resources").size)
        assertEquals("fresh-user-token", h.bindings.get("local-a", "plex.account")?.userToken)
    }

    @Test
    fun aRefusedKeptTokenIsMintedAgainButAServerErrorIsNot() = profileTest { h ->
        h.plexTv = { request ->
            when {
                request.url.encodedPath.endsWith("/switch") -> jsonResponse("""{"authToken":"replacement-token"}""", 201)
                h.requestsTo("/resources").size == 1 -> jsonResponse("{}", 401)
                else -> jsonResponse("{}", 500)
            }
        }
        h.activeLocalPlex("rejected-token")

        assertFalse(h.startAndSettle())

        assertEquals(2, h.requestsTo("/resources").size)
        assertEquals(1, h.requestsTo("/switch").size)
        assertEquals("replacement-token", h.bindings.get("local-a", "plex.account")?.userToken)
    }

    @Test
    fun aPassiveRebindOfAProtectedHomeUserNeverAsksForThePin() = profileTest { h ->
        h.plexTv = { plexTvAnswer(it, switchToken = "fresh", resourcesBody = resources(serverJson(accessToken = "home-user-token"))) }
        h.services.pinPrompt = h.pinPrompt
        h.pins = mutableListOf("1234")
        h.activePlexHome(protected = true)
        assertTrue(h.startAndSettle())

        h.services.rebindActive()

        assertEquals(emptyList(), h.prompts)
        assertTrue(h.requestsTo("/switch").isEmpty())
    }

    @Test
    fun changedServersFromPlexTvBindAgain() = profileTest { h ->
        val gate = CompletableDeferred<Unit>()
        h.plexTv = {
            gate.await()
            plexTvAnswer(it, resourcesBody = resources(serverJson("srv-2")))
        }
        h.activePlexHome()
        assertTrue(h.startAndSettle())
        assertEquals(listOf(srv1), h.manager.onlineServerIds)

        gate.complete(Unit)

        eventually { h.manager.onlineServerIds == listOf(ServerId("srv-2")) }
        assertEquals(listOf("srv-2"), h.connections.get("plex.account")?.plexAccount()?.servers?.map { it.clientIdentifier })
        assertTrue(srv1 !in h.manager.registeredServerIds)
        assertTrue(h.requestsTo("/switch").isEmpty())
    }

    @Test
    fun plexTvAnsweringAfterSignOutDoesNotStoreTheAccountAgain() = profileTest { h ->
        val gate = CompletableDeferred<Unit>()
        h.plexTv = {
            gate.await()
            plexTvAnswer(it)
        }
        h.activePlexHome()
        assertTrue(h.startAndSettle())

        h.connections.remove("plex.account")
        gate.complete(Unit)
        repeat(5) {
            runCurrent()
            advanceTimeBy(10)
        }

        assertNull(h.connections.get("plex.account"))
    }

    @Test
    fun refreshingAnAccountsServersUsesTheTokenItWasBoundWith() = profileTest { h ->
        h.plexTv = { plexTvAnswer(it, resourcesBody = resources(serverJson(accessToken = "home-user-token"))) }
        h.activePlexHome()
        assertTrue(h.startAndSettle())
        eventually { h.requestsTo("/resources").size == 1 }

        h.services.refreshPlexServers("plex.account")

        assertEquals(2, h.requestsTo("/resources").size)
        assertEquals("home-user-token", h.requestsTo("/resources").last().headers["X-Plex-Token"])
    }

    @Test
    fun theTokenCachePolicy() {
        assertTrue(shouldUsePlexHomeTokenCache(preVerified = false, hasBoundOnce = false))
        assertTrue(shouldUsePlexHomeTokenCache(preVerified = true, hasBoundOnce = true))
        assertFalse(shouldUsePlexHomeTokenCache(preVerified = false, hasBoundOnce = true))
    }
}

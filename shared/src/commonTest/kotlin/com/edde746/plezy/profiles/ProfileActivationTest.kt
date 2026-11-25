package com.edde746.plezy.profiles

import com.edde746.plezy.backend.HealthStatus
import com.edde746.plezy.plex.tv.jsonResponse
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.hours

class ProfileActivationTest {
    private val user = homeUser(protected = true)
    private val homeId = plexHomeProfileId("plex.account", user.uuid)

    /** local-a (no connections) active and bound; local-b reaches a Jellyfin server that is [health]. */
    private suspend fun ProfileHarness.twoLocals(health: HealthStatus, bPin: String? = null) {
        data.profiles.upsert(local("local-a"))
        data.profiles.upsert(local("local-b", pin = bPin))
        val jf = jellyfin()
        store(jf)
        mediaBrowser.health[jf.id] = health
        bindings.upsert(ProfileConnection("local-b", jf.id, jf.accessToken, jf.userId))
        identity.setActiveProfileId("local-a")
        assertTrue(startAndSettle())
    }

    private fun ProfileHarness.profile(id: String): Profile = services.profiles.value.single { it.id == id }

    @Test
    fun aLocalPinIsAskedUntilRight() = profileTest { h ->
        h.twoLocals(HealthStatus.ONLINE, bPin = "1234")
        h.pins = mutableListOf("0000", "1234")

        assertEquals(ProfileSwitchResult.SWITCHED, h.services.switchProfile(h.profile("local-b"), h.pinPrompt))

        assertEquals(listOf("local-b" to false, "local-b" to true), h.prompts)
        assertEquals("local-b", h.services.active.value?.id)
    }

    @Test
    fun cancellingThePinChangesNothing() = profileTest { h ->
        h.twoLocals(HealthStatus.ONLINE, bPin = "1234")

        assertEquals(ProfileSwitchResult.CANCELLED, h.services.switchProfile(h.profile("local-b"), h.pinPrompt))

        assertEquals("local-a", h.services.active.value?.id)
        assertEquals("local-a", h.identity.activeProfileId())
    }

    /** Each value [ProfileServices.switching] takes from now on, the current one first. */
    private fun TestScope.switchingSeen(h: ProfileHarness): List<Boolean> {
        val seen = mutableListOf<Boolean>()
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { h.services.switching.collect { seen += it } }
        return seen
    }

    @Test
    fun switchingHoldsFromTheAcceptedPinUntilTheSwitchHasEnded() = profileTest { h ->
        h.twoLocals(HealthStatus.ONLINE, bPin = "1234")
        h.pins = mutableListOf("0000", "1234")
        val atPrompt = mutableListOf<Boolean>()
        val seen = switchingSeen(h)

        val result = h.services.switchProfile(h.profile("local-b")) { profile, incorrect ->
            atPrompt += h.services.switching.value
            h.pinPrompt(profile, incorrect)
        }

        assertEquals(ProfileSwitchResult.SWITCHED, result)
        assertEquals(listOf(false, false), atPrompt)
        assertEquals(listOf(false, true, false), seen)
    }

    @Test
    fun aFailedSwitchEndsSwitching() = profileTest { h ->
        h.twoLocals(HealthStatus.OFFLINE)
        val seen = switchingSeen(h)

        assertEquals(ProfileSwitchResult.FAILED, h.services.switchProfile(h.profile("local-b"), h.pinPrompt))

        assertEquals(listOf(false, true, false), seen)
    }

    @Test
    fun aCancelledPinNeverStartsSwitching() = profileTest { h ->
        h.twoLocals(HealthStatus.ONLINE, bPin = "1234")
        val seen = switchingSeen(h)

        assertEquals(ProfileSwitchResult.CANCELLED, h.services.switchProfile(h.profile("local-b"), h.pinPrompt))

        assertEquals(listOf(false), seen)
    }

    @Test
    fun aSwitchStoppedWhileItBindsEndsSwitching() = profileTest { h ->
        h.twoLocals(HealthStatus.ONLINE)
        h.mediaBrowser.healthDelay[jellyfin().id] = 1.hours
        val switch = async { h.services.switchProfile(h.profile("local-b"), h.pinPrompt) }
        h.services.switching.first { it }

        switch.cancelAndJoin()

        assertFalse(h.services.switching.value)
    }

    @Test
    fun aHomeUsersPinBeingCheckedByPlexTvIsNotSwitchingYet() = profileTest { h ->
        val switchAsked = CompletableDeferred<Unit>()
        val switchAnswered = CompletableDeferred<Unit>()
        h.plexTv = { request ->
            if (request.url.encodedPath.endsWith("/switch")) {
                switchAsked.complete(Unit)
                switchAnswered.await()
            }
            plexTvAnswer(request, switchToken = "fresh-user-token", resourcesBody = resources(serverJson(accessToken = "fresh-user-token")))
        }
        h.store(plexAccount(servers = listOf(plexServer(accessToken = "fresh-user-token"))))
        h.cacheHomeUsers("plex.account", user)
        h.data.profiles.upsert(local("local-a"))
        h.identity.setActiveProfileId("local-a")
        assertTrue(h.startAndSettle())
        h.pins = mutableListOf("1234")
        val seen = switchingSeen(h)
        val switch = async { h.services.switchProfile(h.profile(homeId), h.pinPrompt) }
        switchAsked.await()

        assertFalse(h.services.switching.value)
        switchAnswered.complete(Unit)

        assertEquals(ProfileSwitchResult.SWITCHED, switch.await())
        assertEquals(listOf(false, true, false), seen)
    }

    @Test
    fun aProtectedHomeUsersPinIsCheckedByPlexTvOnceAndItsTokenUsed() = profileTest { h ->
        h.plexTv = { plexTvAnswer(it, switchToken = "fresh-user-token", resourcesBody = resources(serverJson(accessToken = "fresh-user-token"))) }
        h.store(plexAccount(servers = listOf(plexServer(accessToken = "fresh-user-token"))))
        h.cacheHomeUsers("plex.account", user)
        h.data.profiles.upsert(local("local-a"))
        h.identity.setActiveProfileId("local-a")
        assertTrue(h.startAndSettle())
        h.pins = mutableListOf("1234")

        assertEquals(ProfileSwitchResult.SWITCHED, h.services.switchProfile(h.profile(homeId), h.pinPrompt))

        assertEquals(1, h.prompts.size)
        assertEquals(listOf("1234"), h.requestsTo("/switch").map { it.url.parameters["pin"] })
        assertEquals("fresh-user-token", h.bindings.get(homeId, "plex.account")?.userToken)
        assertEquals(listOf(com.edde746.plezy.model.ServerId("srv-1")), h.manager.onlineServerIds)
    }

    @Test
    fun cancellingAHomeUsersPinLeavesTheActiveProfile() = profileTest { h ->
        h.plexTv = { plexTvAnswer(it) }
        h.store(plexAccount())
        h.cacheHomeUsers("plex.account", user)
        h.data.profiles.upsert(local("local-a"))
        h.identity.setActiveProfileId("local-a")
        assertTrue(h.startAndSettle())

        assertEquals(ProfileSwitchResult.CANCELLED, h.services.switchProfile(h.profile(homeId), h.pinPrompt))

        assertEquals("local-a", h.services.active.value?.id)
        assertTrue(h.requestsTo("/switch").isEmpty())
    }

    @Test
    fun anOfflineProfileOwningDownloadsStaysActive() = profileTest { h ->
        h.twoLocals(HealthStatus.OFFLINE)
        h.data.downloadLibrary.addDownloadOwner("local-b", "jf-machine:item-1")

        assertEquals(ProfileSwitchResult.SWITCHED, h.services.switchProfile(h.profile("local-b"), h.pinPrompt))

        assertEquals("local-b", h.services.active.value?.id)
        assertEquals("local-b", h.identity.activeProfileId())
    }

    @Test
    fun anOfflineProfileWithoutDownloadsRollsBack() = profileTest { h ->
        h.twoLocals(HealthStatus.OFFLINE)

        assertEquals(ProfileSwitchResult.FAILED, h.services.switchProfile(h.profile("local-b"), h.pinPrompt))

        assertEquals("local-a", h.services.active.value?.id)
        assertEquals("local-a", h.identity.activeProfileId())
        assertTrue(h.services.bindState.value.succeeded)
    }

    @Test
    fun aFailureOtherThanConnectivityRollsBackDespiteDownloads() = profileTest { h ->
        h.plexTv = { request ->
            if (request.url.encodedPath.endsWith("/switch")) plexTvAnswer(request, switchToken = "user-token") else jsonResponse("{}", 500)
        }
        h.store(plexAccount(servers = emptyList()))
        h.data.profiles.upsert(local("local-a"))
        h.data.profiles.upsert(local("local-b"))
        h.bindings.upsert(ProfileConnection("local-b", "plex.account", null, homeUser().uuid))
        h.data.downloadLibrary.addDownloadOwner("local-b", "srv-1:item-1")
        h.identity.setActiveProfileId("local-a")
        assertTrue(h.startAndSettle())

        // plex.tv fails with no server known: not an offline profile.
        assertEquals(ProfileSwitchResult.FAILED, h.services.switchProfile(h.profile("local-b"), h.pinPrompt))
        assertEquals("local-a", h.services.active.value?.id)
    }

    @Test
    fun goingBackToAPlexHomeProfileUsesItsTokenWithoutItsPin() = profileTest { h ->
        h.plexTv = { plexTvAnswer(it, resourcesBody = resources(serverJson(accessToken = "home-user-token"))) }
        h.services.pinPrompt = h.pinPrompt
        h.store(plexAccount(servers = listOf(plexServer(accessToken = "home-user-token"))))
        h.cacheHomeUsers("plex.account", user)
        h.bindings.upsert(ProfileConnection(homeId, "plex.account", "home-user-token", user.uuid))
        h.data.profiles.upsert(local("local-b"))
        val jf = jellyfin()
        h.store(jf)
        h.mediaBrowser.health[jf.id] = HealthStatus.OFFLINE
        h.bindings.upsert(ProfileConnection("local-b", jf.id, jf.accessToken, jf.userId))
        h.identity.setActiveProfileId(homeId)
        assertTrue(h.startAndSettle())

        assertEquals(ProfileSwitchResult.FAILED, h.services.switchProfile(h.profile("local-b"), h.pinPrompt))

        assertEquals(homeId, h.services.active.value?.id)
        assertTrue(h.services.bindState.value.succeeded)
        assertEquals(emptyList(), h.prompts)
        assertTrue(h.requestsTo("/switch").isEmpty())
        assertEquals(listOf(com.edde746.plezy.model.ServerId("srv-1")), h.manager.onlineServerIds)
    }

    @Test
    fun aSwitchAskedForWhileAnotherWaitsForItsPinStaysActive() = profileTest { h ->
        h.data.profiles.upsert(local("local-c"))
        h.twoLocals(HealthStatus.ONLINE, bPin = "1234")
        val asked = CompletableDeferred<Unit>()
        val typed = CompletableDeferred<String?>()
        val first = async {
            h.services.switchProfile(h.profile("local-b")) { _, _ ->
                asked.complete(Unit)
                typed.await()
            }
        }
        asked.await()

        assertEquals(ProfileSwitchResult.SWITCHED, h.services.switchProfile(h.profile("local-c"), h.pinPrompt))
        typed.complete("1234")

        assertEquals(ProfileSwitchResult.CANCELLED, first.await())
        assertEquals("local-c", h.services.active.value?.id)
        assertEquals("local-c", h.identity.activeProfileId())
    }

    @Test
    fun aSwitchAskedForWhilePlexTvChecksAHomeUsersPinStaysActive() = profileTest { h ->
        val switchAsked = CompletableDeferred<Unit>()
        val switchAnswered = CompletableDeferred<Unit>()
        h.plexTv = { request ->
            if (request.url.encodedPath.endsWith("/switch")) {
                switchAsked.complete(Unit)
                switchAnswered.await()
            }
            plexTvAnswer(request, switchToken = "fresh-user-token", resourcesBody = resources(serverJson(accessToken = "fresh-user-token")))
        }
        h.store(plexAccount(servers = listOf(plexServer(accessToken = "fresh-user-token"))))
        h.cacheHomeUsers("plex.account", user)
        h.data.profiles.upsert(local("local-a"))
        h.data.profiles.upsert(local("local-b"))
        h.identity.setActiveProfileId("local-a")
        assertTrue(h.startAndSettle())
        h.pins = mutableListOf("1234")
        val first = async { h.services.switchProfile(h.profile(homeId), h.pinPrompt) }
        switchAsked.await()

        assertEquals(ProfileSwitchResult.SWITCHED, h.services.switchProfile(h.profile("local-b"), h.pinPrompt))
        switchAnswered.complete(Unit)

        assertEquals(ProfileSwitchResult.CANCELLED, first.await())
        assertEquals("local-b", h.services.active.value?.id)
        assertEquals("local-b", h.identity.activeProfileId())
    }

    @Test
    fun verifyProfilePinChecksOnlyLocalProfiles() {
        assertTrue(verifyProfilePin(local("local-a"), "anything"))
        assertTrue(verifyProfilePin(local("local-a", pin = "1234"), "1234"))
        assertEquals(false, verifyProfilePin(local("local-a", pin = "1234"), "0000"))
        assertEquals(false, verifyProfilePin(PlexHomeProfile.virtualPlexHome("plex.account", user), "1234"))
    }
}

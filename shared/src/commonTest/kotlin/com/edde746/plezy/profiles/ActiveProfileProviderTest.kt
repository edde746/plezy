package com.edde746.plezy.profiles

import kotlinx.coroutines.async
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.TestScope
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Clock
import kotlin.time.Instant

class ActiveProfileProviderTest {
    private class Setup(val h: ProfileHarness, val home: PlexHomeService, val provider: ActiveProfileProvider)

    private fun TestScope.setup(h: ProfileHarness): Setup {
        val home = PlexHomeService(h.connections, h.bindings, h.identity, { emptyList() }, backgroundScope)
        val clock = object : Clock {
            override fun now(): Instant = Instant.fromEpochMilliseconds(h.clock.now)
        }
        return Setup(h, home, ActiveProfileProvider(h.data.profiles, h.connections, h.identity, home, backgroundScope, clock))
    }

    @Test
    fun noProfilesLeavesNoneActive() = profileTest { h ->
        val s = setup(h)
        h.identity.setActiveProfileId("local-gone")

        s.provider.initialize()

        assertTrue(s.provider.hydrated.value)
        assertEquals(emptyList(), s.provider.profiles.value)
        assertNull(s.provider.active.value)
    }

    @Test
    fun noStoredIdLeavesNoneActiveInsteadOfPickingTheFirst() = profileTest { h ->
        h.data.profiles.upsert(local("local-a"))
        val s = setup(h)

        s.provider.initialize()

        assertEquals(listOf("local-a"), s.provider.profiles.value.map { it.id })
        assertNull(s.provider.active.value)
    }

    @Test
    fun aStoredIdNoProfileMatchesIsKept() = profileTest { h ->
        h.data.profiles.upsert(local("local-a"))
        h.identity.setActiveProfileId("plex-home-plex.account-aaaaaaaaaaaaaaaa")
        val s = setup(h)

        s.provider.initialize()

        assertNull(s.provider.active.value)
        assertEquals("plex-home-plex.account-aaaaaaaaaaaaaaaa", h.identity.activeProfileId())
    }

    @Test
    fun theStoredIdResolves() = profileTest { h ->
        h.data.profiles.upsert(local("local-a"))
        h.data.profiles.upsert(local("local-b"))
        h.identity.setActiveProfileId("local-b")
        val s = setup(h)

        s.provider.initialize()

        assertEquals("local-b", s.provider.active.value?.id)
        assertTrue(s.provider.hasMultipleProfiles)
    }

    @Test
    fun reloadResolvesAPlexHomeProfileImportedAfterInitialize() = profileTest { h ->
        val s = setup(h)
        s.provider.initialize()
        val user = homeUser()
        h.store(plexAccount())
        h.cacheHomeUsers("plex.account", user)
        h.identity.setActiveProfileId(plexHomeProfileId("plex.account", user.uuid))

        s.provider.reloadFromStorage()

        assertEquals(plexHomeProfileId("plex.account", user.uuid), s.provider.active.value?.id)
    }

    @Test
    fun activateRecordsUseThenStoresTheIdAndMovesTheProfileFirst() = profileTest { h ->
        h.data.profiles.upsert(local("local-a", lastUsedAt = 500))
        h.data.profiles.upsert(local("local-b"))
        val s = setup(h)
        s.provider.initialize()
        val b = s.provider.profiles.value.single { it.id == "local-b" }

        assertTrue(s.provider.activate(b))

        assertEquals("local-b", s.provider.active.value?.id)
        assertEquals("local-b", h.identity.activeProfileId())
        assertEquals(h.clock.now, h.identity.profileLastUsed("local-b"))
        assertEquals(listOf("local-b", "local-a"), s.provider.profiles.value.map { it.id })
        assertEquals(h.clock.now, h.data.profiles.list().single { it.id == "local-b" }.lastUsedAt)
    }

    @Test
    fun aProtectedLocalProfileNeedsItsPin() = profileTest { h ->
        val protected = local("local-kid", pin = "1234")
        h.data.profiles.upsert(protected)
        val s = setup(h)
        s.provider.initialize()

        assertFalse(s.provider.activate(protected))
        assertFalse(s.provider.activate(protected, pin = "0000"))
        assertNull(s.provider.active.value)
        assertNull(h.identity.activeProfileId())
        assertNull(h.identity.profileLastUsed("local-kid"))

        assertTrue(s.provider.activate(protected, pin = "1234"))
        assertEquals("local-kid", s.provider.active.value?.id)
    }

    @Test
    fun aNewerActivationSupersedesOneStillWaiting() = profileTest { h ->
        h.data.profiles.upsert(local("local-a"))
        h.data.profiles.upsert(local("local-b"))
        val s = setup(h)
        s.provider.initialize()

        val first = async { s.provider.activate(local("local-a")) }
        val second = async { s.provider.activate(local("local-b")) }

        assertFalse(first.await())
        assertTrue(second.await())
        assertEquals("local-b", s.provider.active.value?.id)
        assertEquals("local-b", h.identity.activeProfileId())
        assertEquals(s.provider.mutationGeneration, s.provider.committedGeneration)
    }

    @Test
    fun clearActiveProfileClearsStorageAndMemory() = profileTest { h ->
        h.data.profiles.upsert(local("local-a"))
        h.identity.setActiveProfileId("local-a")
        val s = setup(h)
        s.provider.initialize()

        s.provider.clearActiveProfile()

        assertNull(s.provider.active.value)
        assertNull(h.identity.activeProfileId())
    }

    @Test
    fun restoreAfterAFailedActivationOnlyWhileTheFailedProfileIsStillActive() = profileTest { h ->
        h.data.profiles.upsert(local("local-a"))
        h.data.profiles.upsert(local("local-b"))
        h.data.profiles.upsert(local("local-c"))
        val s = setup(h)
        s.provider.initialize()
        s.provider.activate(local("local-a"))
        s.provider.activate(local("local-b"))
        val failed = s.provider.committedGeneration

        s.provider.activate(local("local-c"))
        assertNull(s.provider.restoreAfterFailedActivation(local("local-a"), "local-b", failed))
        assertEquals("local-c", s.provider.active.value?.id)

        val committed = s.provider.committedGeneration
        val restored = s.provider.restoreAfterFailedActivation(local("local-a"), "local-c", committed)
        assertEquals(s.provider.committedGeneration, restored)
        assertEquals("local-a", s.provider.active.value?.id)
        assertEquals("local-a", h.identity.activeProfileId())
    }

    @Test
    fun theListFollowsNewProfiles() = profileTest { h ->
        val s = setup(h)
        s.provider.initialize()

        h.data.profiles.upsert(local("local-new"))

        assertEquals(listOf("local-new"), s.provider.profiles.first { it.isNotEmpty() }.map { it.id })
    }
}

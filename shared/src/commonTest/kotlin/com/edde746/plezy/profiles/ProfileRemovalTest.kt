package com.edde746.plezy.profiles

import com.edde746.plezy.trackers.TrackerService
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ProfileRemovalTest {
    private val uuid = "aaaaaaaaaaaaaaaa"
    private val home = plexHomeProfileId("plex.account", uuid)

    private suspend fun ProfileHarness.bind(profileId: String, connectionId: String, user: String = "user") =
        bindings.upsert(ProfileConnection(profileId, connectionId, "token", user))

    /** A local profile `p` bound to a Jellyfin user. */
    private suspend fun ProfileHarness.localWithJellyfin() {
        data.profiles.upsert(local("p"))
        store(jellyfin())
        bind("p", jellyfin().id)
    }

    /** The Plex account (server `srv-1`) with its Home profile and the local profile `b` borrowing it. */
    private suspend fun ProfileHarness.accountWithHomeProfileAndBorrower() {
        store(plexAccount())
        cacheHomeUsers("plex.account", homeUser(uuid))
        bind(home, "plex.account", uuid)
        data.profiles.upsert(local("b"))
        bind("b", "plex.account", uuid)
    }

    private suspend fun ProfileHarness.account() = checkNotNull(connections.get("plex.account"))

    /** A tracker connection with a queued write, and a Seerr session, for [profileId]. */
    private suspend fun ProfileHarness.integrations(profileId: String) {
        data.trackerAccounts.connect(profileId, TrackerService.TRAKT, "alex", 1)
        data.db.write { q.trackerQueries.insertQueued(profileId, TrackerService.TRAKT.id, "trakt|movie|imdb=tt1", true, "{}", null, 1, 0) }
        secrets.put("seerr_session.${profileUserScope(profileId)}", "{}".encodeToByteArray())
    }

    /** Whether [profileId] still has a tracker connection, a queued tracker write, a Seerr session. */
    private suspend fun ProfileHarness.integrationsOf(profileId: String) = Triple(
        data.trackerAccounts.connections().any { it.first == profileId },
        data.db.read { trackerQueries.selectQueued(profileId).executeAsList() }.isNotEmpty(),
        secrets.get("seerr_session.${profileUserScope(profileId)}") != null,
    )

    private val none = Triple(false, false, false)
    private val all = Triple(true, true, true)

    @Test
    fun deletingAProfileDeletesItsDownloadsWhileItIsStillThere() = profileTest { h ->
        h.localWithJellyfin()

        h.removal.deleteLocalProfile("p")

        assertEquals(listOf("delete p"), h.downloads.calls)
        assertTrue(h.data.profiles.list().isEmpty())
    }

    @Test
    fun aFailedDownloadDeletionLeavesTheProfileForARetry() = profileTest { h ->
        h.localWithJellyfin()
        h.downloads.failure = IllegalStateException("the disk refused")

        assertFailsWith<IllegalStateException> { h.removal.deleteLocalProfile("p") }

        assertEquals(listOf("p"), h.data.profiles.list().map { it.id })
        assertEquals(listOf(jellyfin().id), h.bindings.listForProfile("p").map { it.connectionId })
        h.downloads.failure = null
        h.removal.deleteLocalProfile("p")
        assertTrue(h.data.profiles.list().isEmpty())
    }

    @Test
    fun unlinkingReleasesOnlyTheServersTheProfileNoLongerReaches() = profileTest { h ->
        h.localWithJellyfin()
        val sameServer = jellyfin(userId = "user-b")
        h.store(sameServer)
        h.bind("p", sameServer.id)
        h.store(plexAccount())
        h.bind("p", "plex.account")

        h.removal.removeProfileConnection("p", checkNotNull(h.connections.get(jellyfin().id)))
        assertEquals(emptyList(), h.downloads.calls, "the Jellyfin server is still reached through its other user")

        h.removal.removeProfileConnection("p", h.account())
        assertEquals(listOf("release p srv-1"), h.downloads.calls)
        assertTrue(h.bindings.listForProfile("p").none { it.connectionId == "plex.account" })
    }

    @Test
    fun unlinkingKeepsTheServersAHomeProfileReachesThroughItsOwnAccount() = profileTest { h ->
        h.accountWithHomeProfileAndBorrower()
        h.store(plexAccount(id = "plex.other", servers = listOf(plexServer(), plexServer("srv-2"))))
        h.bind(home, "plex.other")

        h.removal.removeProfileConnection(home, checkNotNull(h.connections.get("plex.other")))

        assertEquals(listOf("release $home srv-2"), h.downloads.calls)
    }

    @Test
    fun signingOutAndDeletingDownloadsReleasesThemBeforeTheAccountGoes() = profileTest { h ->
        h.accountWithHomeProfileAndBorrower()

        h.removal.signOutPlexAccount(h.account(), deleteDownloads = true)

        assertEquals(listOf("delete $home", "release b srv-1"), h.downloads.calls)
        assertNull(h.connections.get("plex.account"))
    }

    @Test
    fun signingOutAndKeepingDownloadsReleasesNone() = profileTest { h ->
        h.accountWithHomeProfileAndBorrower()

        h.removal.signOutPlexAccount(h.account(), deleteDownloads = false)

        assertEquals(emptyList(), h.downloads.calls)
        assertNull(h.connections.get("plex.account"))
    }

    @Test
    fun aFailedDownloadDeletionKeepsTheAccountForARetry() = profileTest { h ->
        h.accountWithHomeProfileAndBorrower()
        h.downloads.failure = IllegalStateException("the disk refused")

        assertFailsWith<IllegalStateException> { h.removal.signOutPlexAccount(h.account(), deleteDownloads = true) }

        assertNotNull(h.connections.get("plex.account"))
        assertEquals(setOf(home, "b"), h.bindings.listForConnection("plex.account").map { it.profileId }.toSet())
    }

    @Test
    fun aSignOutOffersToDeleteWhatTheHomeProfilesOwnAndWhatBorrowersOwnFromTheAccountsServers() = profileTest { h ->
        h.accountWithHomeProfileAndBorrower()
        assertFalse(h.removal.plexSignOutOwnsDownloads(h.account()))

        h.data.downloadLibrary.addDownloadOwner("b", "other-server:1")
        assertFalse(h.removal.plexSignOutOwnsDownloads(h.account()), "a borrower's download from another server stays")

        h.data.downloadLibrary.addDownloadOwner("b", "srv-1:2")
        assertTrue(h.removal.plexSignOutOwnsDownloads(h.account()))

        h.data.downloadLibrary.removeDownloadOwner("b", "srv-1:2")
        h.data.downloadLibrary.addDownloadOwner(home, "other-server:3")
        assertTrue(h.removal.plexSignOutOwnsDownloads(h.account()))
    }

    @Test
    fun deletingAProfileForgetsItsTrackersQueuedWritesAndSeerrSession() = profileTest { h ->
        h.localWithJellyfin()
        h.data.profiles.upsert(local("q"))
        h.integrations("p")
        h.integrations("q")

        h.removal.deleteLocalProfile("p")

        assertEquals(none, h.integrationsOf("p"))
        assertEquals(all, h.integrationsOf("q"))
    }

    @Test
    fun signingOutForgetsTheHomeUsersIntegrationsOnEveryAccountAndKeepsTheBorrowers() = profileTest { h ->
        h.accountWithHomeProfileAndBorrower()
        val sameUserElsewhere = plexHomeProfileId("plex.other", uuid)
        h.integrations(home)
        h.integrations(sameUserElsewhere)
        h.integrations("b")

        h.removal.signOutPlexAccount(h.account(), deleteDownloads = false)

        assertEquals(none, h.integrationsOf(home))
        assertEquals(none, h.integrationsOf(sameUserElsewhere))
        assertEquals(all, h.integrationsOf("b"))
    }

    @Test
    fun loggingOutForgetsEveryProfilesIntegrations() = profileTest { h ->
        h.accountWithHomeProfileAndBorrower()
        h.localWithJellyfin()
        h.integrations(home)
        h.integrations("b")
        h.integrations("p")

        h.removal.logOutAll()

        for (profileId in listOf(home, "b", "p")) assertEquals(none, h.integrationsOf(profileId), profileId)
    }
}

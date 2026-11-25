package com.edde746.plezy.trackers

import com.edde746.plezy.data.db.Tracker_account
import com.edde746.plezy.trackers.TrackerService.TRAKT
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

/**
 * A Plex Home user's tracker connections are the user's: its profile on every Plex account that has it in its Home
 * shares one connection, session and write queue, kept under the Home user's uuid.
 */
class TrackerProfileScopeTest {
    private val fixtures = mutableListOf<TrackerFixture>()

    @AfterTest
    fun close() = fixtures.forEach { it.close() }

    private fun TestScope.fixture() = TrackerFixture(this).also { fixtures += it }

    private val homeUser = "379704d0c6601309"
    private val viaFirstAccount = "plex-home-plex.acct1-$homeUser"
    private val viaSecondAccount = "plex-home-plex.acct2-$homeUser"

    /** A connection as earlier builds kept it: the row, the session and a queued write under the full profile id. */
    private fun TrackerFixture.keepAsEarlierBuilds(profileId: String, connectedAt: Long, imdb: String) {
        data.db.database.trackerQueries.upsertAccount(Tracker_account(profileId, TRAKT.id, "alex", connectedAt))
        data.db.database.trackerQueries.insertQueued(profileId, TRAKT.id, "movie:$imdb", true, """{"kind":"MOVIE","ids":{"imdb":"$imdb"}}""", null, 2, 0)
    }

    private suspend fun TrackerFixture.keepSessionAsEarlierBuilds(profileId: String, connectedAt: Long, accessToken: String) {
        val session = """{"access_token":"$accessToken","refresh_token":"r0","expires_at":$FAR_FUTURE,"username":"alex","created_at":1}"""
        store.memory.put("tracker.trakt.$profileId", """{"connectedAt":$connectedAt,"session":$session}""".encodeToByteArray())
    }

    private suspend fun TrackerFixture.indexAsEarlierBuilds(vararg profileIds: String) {
        val entries = profileIds.joinToString(",") { """{"profileId":"$it","service":"trakt"}""" }
        store.memory.put("tracker.index", "[$entries]".encodeToByteArray())
    }

    @Test
    fun aHomeUsersProfilesOnEveryAccountShareItsConnectionSessionAndQueuedWrites() = runTest {
        val f = fixture()
        f.hub.accounts.connect(viaFirstAccount, TRAKT, TrackerSession("a0", "r0", FAR_FUTURE, "alex", 1))
        f.settle()
        val connectedAt = f.data.trackerAccounts.account(viaFirstAccount, TRAKT)!!.connectedAt
        f.data.trackerWriteQueue.enqueue(viaFirstAccount, TRAKT, connectedAt, listOf(movieWrite(TRAKT)), 1)

        val binding = f.hub.accounts.bindings(viaSecondAccount).first().single()
        assertEquals("a0", binding.credentials.accessToken())
        assertEquals(listOf(movieWrite(TRAKT).coalesceKey), f.data.trackerWriteQueue.pending(viaSecondAccount).map { it.coalesceKey })
        assertNotNull(f.store.memory.get("tracker.trakt.$homeUser"), "the session is the Home user's")
    }

    @Test
    fun aSessionIsKeptUnderTheHomeUsersUuidInEitherFormAndUnderAnyOtherProfilesId() = runTest {
        val f = fixture()
        val dashed = "a1b2c3d4-e5f6-7890-abcd-ef0123456789"
        val viaDashedUuid = "plex-home-plex.client-id-123-$dashed"
        f.hub.accounts.connect(viaFirstAccount, TRAKT, TrackerSession("a0", "r0", FAR_FUTURE, "alex", 1))
        f.hub.accounts.connect(viaDashedUuid, TrackerService.SIMKL, TrackerSession("s0", "r0", FAR_FUTURE, "sam", 1))
        f.hub.accounts.connect("local-1", TrackerService.ANILIST, TrackerSession("l0", "r0", FAR_FUTURE, "lee", 1))
        f.settle()

        assertEquals(setOf(homeUser to TRAKT, dashed to TrackerService.SIMKL, "local-1" to TrackerService.ANILIST), f.tokens.stored())
        assertNotNull(f.store.memory.get("tracker.simkl.$dashed"))
        assertNotNull(f.store.memory.get("tracker.anilist.local-1"))
        for (fullId in listOf(viaFirstAccount, viaDashedUuid)) {
            assertNull(f.store.memory.get("tracker.trakt.$fullId"), "nothing under the full id $fullId")
            assertNull(f.store.memory.get("tracker.simkl.$fullId"), "nothing under the full id $fullId")
        }
        // The same Home user's profile on another account loads the same session.
        assertEquals("s0", f.hub.accounts.bindings("plex-home-plex.acct9-$dashed").first().single().credentials.accessToken())
    }

    @Test
    fun connectionsKeptUnderAFullHomeProfileIdMoveToTheHomeUserWithoutASignIn() = runTest {
        val f = fixture()
        f.keepAsEarlierBuilds(viaFirstAccount, connectedAt = 5, imdb = "tt1")
        f.keepSessionAsEarlierBuilds(viaFirstAccount, connectedAt = 5, accessToken = "a0")
        f.indexAsEarlierBuilds(viaFirstAccount)
        // The app starts on them.
        f.settle()

        val binding = f.hub.accounts.bindings(viaSecondAccount).first().single()
        assertEquals("a0", binding.credentials.accessToken(), "the same session: no sign-in again")
        assertEquals(listOf("movie:tt1"), f.data.trackerWriteQueue.pending(viaSecondAccount).map { it.coalesceKey })
        assertNull(f.store.memory.get("tracker.trakt.$viaFirstAccount"))
        assertEquals(setOf(homeUser to TRAKT), f.tokens.stored())
    }

    @Test
    fun theNewestSignInWinsWhenTheHomeUsersProfilesEachHadTheirOwn() = runTest {
        val f = fixture()
        f.keepAsEarlierBuilds(viaFirstAccount, connectedAt = 5, imdb = "tt1")
        f.keepSessionAsEarlierBuilds(viaFirstAccount, connectedAt = 5, accessToken = "older")
        f.keepAsEarlierBuilds(viaSecondAccount, connectedAt = 9, imdb = "tt2")
        f.keepSessionAsEarlierBuilds(viaSecondAccount, connectedAt = 9, accessToken = "newer")
        f.indexAsEarlierBuilds(viaFirstAccount, viaSecondAccount)
        f.settle()

        assertEquals("newer", f.hub.accounts.bindings(viaFirstAccount).first().single().credentials.accessToken())
        assertEquals(listOf("movie:tt2"), f.data.trackerWriteQueue.pending(viaFirstAccount).map { it.coalesceKey }, "the older sign-in's writes go with it")
        assertEquals(setOf(homeUser to TRAKT), f.tokens.stored())
    }
}

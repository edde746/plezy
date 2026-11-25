package com.edde746.plezy.trackers

import com.edde746.plezy.secrets.MemorySecretStore
import com.edde746.plezy.trackers.client.TokenAnswers
import com.edde746.plezy.trackers.client.parse
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * A tracker session as this device keeps it: the five snake_case keys the earlier releases stored, a five-minute
 * refresh window, per-profile storage that survives restarts, and a stored session that couldn't renew read as none.
 */
class TrackerSessionTest {
    @Test
    fun aTokenNeedsRefreshFiveMinutesBeforeItExpires() {
        val session = TrackerSession("a", "r", expiresAt = 400, createdAt = 0)
        assertTrue(session.needsRefresh(100))
        assertFalse(session.needsRefresh(99))
        assertFalse(TrackerSession("a", createdAt = 0).needsRefresh(Long.MAX_VALUE), "no expiry: never refreshed ahead")
    }

    @Test
    fun aKeptSessionUsesTheEarlierReleasesKeys() = runTest {
        val secrets = MemorySecretStore()
        TrackerTokenStore(secrets).save("p1", TrackerService.TRAKT, StoredSession(7, TrackerSession("trakt-at", "trakt-rt", 2000, createdAt = 1000)))
        val stored = Json.parseToJsonElement(secrets.get(TrackerTokenStore.key("p1", TrackerService.TRAKT))!!.decodeToString()).jsonObject
        assertEquals(
            parse("""{"access_token":"trakt-at","refresh_token":"trakt-rt","expires_at":2000,"username":null,"created_at":1000}"""),
            stored["session"],
        )
    }

    @Test
    fun sessionsArePerProfileAndSurviveARestart() = runTest {
        val secrets = MemorySecretStore()
        val session = TrackerSession("a", "r", 2000, "alex", 1000)
        TrackerTokenStore(secrets).save("profile-1", TrackerService.TRAKT, StoredSession(1, session))

        val relaunched = TrackerTokenStore(secrets)
        assertEquals(session, relaunched.load("profile-1", TrackerService.TRAKT)?.session)
        assertNull(relaunched.load("profile-2", TrackerService.TRAKT), "another profile's slot is empty")
        assertNull(relaunched.load("profile-1", TrackerService.SIMKL))

        relaunched.clear("profile-1", TrackerService.TRAKT)
        assertNull(TrackerTokenStore(secrets).load("profile-1", TrackerService.TRAKT))
    }

    /** What each service's earlier releases stored loads; a blob missing what the service's sessions need doesn't. */
    @Test
    fun aStoredSessionLoadsOnlyWithWhatItsServiceNeeds() = runTest {
        val secrets = MemorySecretStore()
        val store = TrackerTokenStore(secrets)
        suspend fun load(service: TrackerService, session: String): TrackerSession? {
            secrets.put(TrackerTokenStore.key("p", service), """{"connectedAt":1,"session":$session}""".encodeToByteArray())
            return store.load("p", service)?.session
        }

        // Legacy Simkl (V1): neither expiry nor refresh token.
        assertEquals("simkl-at", load(TrackerService.SIMKL, """{"access_token":"simkl-at","username":"carol","created_at":1000}""")?.accessToken)
        // AniList: no refresh token.
        assertNotNull(load(TrackerService.ANILIST, """{"access_token":"anilist-at","expires_at":2000,"username":"alice","created_at":1000}"""))
        for (service in listOf(TrackerService.MYANIMELIST, TrackerService.TRAKT, TrackerService.MDBLIST)) {
            assertNotNull(load(service, """{"access_token":"at","refresh_token":"rt","expires_at":2000,"created_at":1000}"""), "$service")
            assertNull(load(service, """{"access_token":"at","expires_at":2000,"created_at":1000}"""), "$service without a refresh token")
            assertNull(load(service, """{"access_token":"at","refresh_token":"","expires_at":2000,"created_at":1000}"""), "$service with an empty one")
            assertNull(load(service, """{"access_token":"at","refresh_token":"rt","created_at":1000}"""), "$service without an expiry")
        }
        assertNull(load(TrackerService.ANILIST, """{"access_token":"at","created_at":1000}"""), "AniList without an expiry")

        // Simkl AUTH V2 needs both.
        assertNotNull(load(TrackerService.SIMKL, """{"access_token":"simkl_at_x","refresh_token":"simkl_rt_x","expires_at":2000,"created_at":1000}"""))
        assertNull(load(TrackerService.SIMKL, """{"access_token":"simkl_at_x","expires_at":2000,"created_at":1000}"""))
        assertNull(load(TrackerService.SIMKL, """{"access_token":"simkl_at_x","refresh_token":"","expires_at":2000,"created_at":1000}"""))
        assertNull(load(TrackerService.SIMKL, """{"access_token":"simkl_at_x","refresh_token":"simkl_rt_x","created_at":1000}"""))

        // A truncated or corrupt blob is none, not a failure.
        assertNull(load(TrackerService.TRAKT, """{"access_token":"at","refresh_tok"""))
        assertNull(load(TrackerService.TRAKT, """{"refresh_token":"rt","expires_at":2000,"created_at":1000}"""))
    }

    @Test
    fun aTokenAnswerBecomesASessionAndOneWithoutARefreshTokenOrExpiryFails() {
        val trakt = TokenAnswers.session(
            TrackerService.TRAKT,
            parse("""{"access_token":"trakt-at","refresh_token":"trakt-rt","expires_in":1000,"created_at":1000}""").jsonObject,
            nowEpochSeconds = 5,
            refreshable = true,
        )
        assertEquals(TrackerSession("trakt-at", "trakt-rt", 2000, null, 1000), trakt)

        val simkl = TokenAnswers.session(
            TrackerService.SIMKL,
            parse("""{"access_token":"simkl_at_new","refresh_token":"simkl_rt_new","expires_in":604800,"token_type":"Bearer","scope":"media:read media:write"}""").jsonObject,
            nowEpochSeconds = 1000,
            refreshable = true,
        )
        assertEquals(TrackerSession("simkl_at_new", "simkl_rt_new", 1000 + 604800, null, 1000), simkl, "created now when the answer names no time")

        val missing = assertFailsWith<TrackerException.Auth> {
            TokenAnswers.session(TrackerService.SIMKL, parse("""{"access_token":"simkl_at_new","expires_in":604800}""").jsonObject, 1000, refreshable = true)
        }
        assertTrue(missing.permanent)
        assertFailsWith<TrackerException.SignIn> {
            TokenAnswers.signInSession(TrackerService.MDBLIST, parse("""{"access_token":"at","refresh_token":"","expires_in":1}""").jsonObject, 1000)
        }
        assertFailsWith<TrackerException.SignIn>("no expiry: never refreshed ahead") {
            TokenAnswers.signInSession(TrackerService.TRAKT, parse("""{"access_token":"at","refresh_token":"rt"}""").jsonObject, 1000)
        }
    }
}

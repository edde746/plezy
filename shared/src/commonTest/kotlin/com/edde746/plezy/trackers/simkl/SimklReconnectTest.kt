package com.edde746.plezy.trackers.simkl

import com.edde746.plezy.trackers.TrackerFixture
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.TrackerSession
import com.edde746.plezy.trackers.client.Answer
import com.edde746.plezy.trackers.client.ScriptedService
import com.edde746.plezy.trackers.client.json
import com.edde746.plezy.trackers.movieWrite
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

/**
 * Moving a legacy (AUTH V1) Simkl connection onto AUTH V2: offered only while the connection is legacy, it replaces the
 * session in place, and the writes queued under the old session survive only when both tokens are the same account.
 */
class SimklReconnectTest {
    private val legacyToken = "ab".repeat(32)

    /**
     * Simkl's device flow approving `simkl_at_new`, with [accountIds] saying whose each token is (a token missing there
     * answers its settings lookup with 401).
     */
    private fun TestScope.simkl(accountIds: Map<String, Int>) = ScriptedService(this) { request ->
        when (request.path) {
            "/oauth2/device" -> json("""{"device_code":"dev-code","user_code":"BDWP-HQPK","verification_uri":"https://simkl.com/pin","expires_in":900,"interval":5}""")
            "/oauth2/token" -> json("""{"access_token":"simkl_at_new","refresh_token":"simkl_rt_new","expires_in":604800,"scope":"media:read media:write"}""")
            "/users/settings" -> accountIds[request.headers["Authorization"]?.removePrefix("Bearer ")]
                ?.let { json("""{"user":{"name":"user-$it"},"account":{"id":$it}}""") }
                ?: Answer(401)
            // A replay of the queued writes: Simkl is down, so they stay queued.
            else -> Answer(503)
        }
    }

    private suspend fun TestScope.connected(service: ScriptedService, session: TrackerSession): TrackerFixture {
        lateinit var f: TrackerFixture
        val simkl = SimklProvider(service.http(TrackerService.SIMKL), "v2-client", "v1-client", "2.26.0", Duration.ZERO) { f.clock.now().epochSeconds }
        f = TrackerFixture(this, services = emptyList(), realProviders = listOf(simkl))
        f.hub.accounts.connect(f.profileId, TrackerService.SIMKL, session)
        f.settle()
        return f
    }

    private suspend fun TrackerFixture.queueWrites() {
        for (service in listOf(TrackerService.SIMKL, TrackerService.TRAKT)) {
            if (data.trackerAccounts.account(profileId, service) == null) hub.accounts.connect(profileId, service, TrackerSession("t", "r", 4_102_444_800, null, 1))
            val binding = data.trackerAccounts.account(profileId, service)!!.connectedAt
            data.trackerWriteQueue.enqueue(profileId, service, binding, listOf(movieWrite(service)), 1)
        }
    }

    private suspend fun TrackerFixture.reconnect() = scope.async { hub.accounts.reconnect(profileId, TrackerService.SIMKL) {} }.also { advance(30.seconds) }.await()

    @Test
    fun aReconnectOnlyRunsWhileALegacySessionIsBound() = runTest {
        val service = simkl(mapOf("simkl_at_new" to 7))
        lateinit var f: TrackerFixture
        val simklProvider = SimklProvider(service.http(TrackerService.SIMKL), "v2-client", "v1-client", "2.26.0", Duration.ZERO) { f.clock.now().epochSeconds }
        f = TrackerFixture(this, services = emptyList(), realProviders = listOf(simklProvider))
        assertNull(f.reconnect(), "nothing connected")

        f.hub.accounts.connect(f.profileId, TrackerService.SIMKL, TrackerSession("simkl_at_v2", "simkl_rt", 4_102_444_800, "carol", 1))
        f.settle()
        assertEquals(emptySet(), f.hub.accounts.legacy(f.profileId).first())
        assertNull(f.reconnect(), "an AUTH V2 connection")
        assertEquals(emptyList(), service.to("/oauth2/device"))
        f.close()
    }

    @Test
    fun reconnectingToTheSameAccountReplacesTheSessionAndKeepsQueuedWrites() = runTest {
        val service = simkl(mapOf(legacyToken to 7, "simkl_at_new" to 7))
        val f = connected(service, TrackerSession(legacyToken, createdAt = 1, username = "carol"))
        f.queueWrites()
        assertEquals(setOf(TrackerService.SIMKL), f.hub.accounts.legacy(f.profileId).first())

        val account = assertNotNull(f.reconnect())
        assertEquals("user-7", account.username)
        assertEquals(setOf(legacyToken, "simkl_at_new"), service.to("/users/settings").map { it.headers["Authorization"]?.removePrefix("Bearer ") }.toSet())
        assertEquals(2, service.to("/users/settings").size, "one lookup per token")
        assertEquals("simkl_at_new", f.stored(TrackerService.SIMKL)?.accessToken)
        assertEquals("simkl_at_new", f.hub.accounts.bindings(f.profileId).first().first { it.service == TrackerService.SIMKL }.credentials.accessToken())
        assertEquals(emptySet(), f.hub.accounts.legacy(f.profileId).first())
        assertEquals(
            listOf("simkl simkl|movie|imdb=tt1 watched=true attempts=0", "trakt trakt|movie|imdb=tt1 watched=true attempts=0"),
            f.queued().sorted(),
        )
        f.close()
    }

    @Test
    fun reconnectingToAnotherOrAnUnverifiableAccountDropsTheLegacyQueuedWrites() = runTest {
        for (accounts in listOf(mapOf(legacyToken to 7, "simkl_at_new" to 8), mapOf("simkl_at_new" to 8))) {
            val f = connected(simkl(accounts), TrackerSession(legacyToken, createdAt = 1, username = "carol"))
            f.queueWrites()
            assertNotNull(f.reconnect())
            assertEquals("simkl_at_new", f.stored(TrackerService.SIMKL)?.accessToken)
            assertEquals(listOf("trakt trakt|movie|imdb=tt1 watched=true attempts=0"), f.queued(), "$accounts")
            f.close()
        }
    }
}

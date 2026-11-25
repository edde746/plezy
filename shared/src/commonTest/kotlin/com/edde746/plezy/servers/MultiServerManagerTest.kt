@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.edde746.plezy.servers

import com.edde746.plezy.backend.HealthStatus
import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.model.ServerId
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.consumeAsFlow
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.currentTime
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withContext
import kotlin.coroutines.ContinuationInterceptor
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

class MultiServerManagerTest {
    private val jf = ServerId("jf-machine")

    private fun status(vararg entries: Pair<String, Boolean>): Map<ServerId, Boolean> = entries.associate { ServerId(it.first) to it.second }

    private fun <T> TestScope.collected(flow: Flow<T>): MutableList<T> {
        val list = mutableListOf<T>()
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { flow.collect { list += it } }
        return list
    }

    private fun scope(serverId: String, profileId: String) = PlexProfileScopeId.of(ServerId(serverId), profileId)

    private fun plexServer(id: String, url: String = localEndpoint(id), token: String = "token-$id") =
        FakePlexServer(id, mapOf(url to EndpointNetworkClass.LOCAL), races = listOf(raceOf(url)), accessToken = token)

    // Initial state.

    @Test
    fun aFreshManagerHasNoServersClientsOrStatus() = runTest {
        val m = ManagerHarness(this).manager
        assertTrue(m.serverIds.isEmpty())
        assertTrue(m.onlineServerIds.isEmpty())
        assertTrue(m.offlineServerIds.isEmpty())
        assertTrue(m.onlineClients.isEmpty())
    }

    @Test
    fun unknownIdsHaveNoClientAndAreOffline() = runTest {
        val m = ManagerHarness(this).manager
        assertNull(m.client(ServerId("nope")))
        assertFalse(m.isServerOnline(ServerId("nope")))
    }

    // Status snapshots.

    @Test
    fun aSnapshotGoesOutWhenATrackedServerFlips() = runTest {
        val m = ManagerHarness(this).manager
        val emitted = collected(m.statusUpdates)

        m.updateServerStatus(ServerId("srv-1"), true)
        m.updateServerStatus(ServerId("srv-2"), false)
        m.updateServerStatus(ServerId("srv-1"), false)
        runCurrent()

        assertEquals(
            listOf(status("srv-1" to true), status("srv-1" to true, "srv-2" to false), status("srv-1" to false, "srv-2" to false)),
            emitted,
        )
    }

    @Test
    fun aRepeatedIdenticalStatusEmitsNothing() = runTest {
        val m = ManagerHarness(this).manager
        val emitted = collected(m.statusUpdates)

        repeat(3) { m.updateServerStatus(ServerId("srv-1"), true) }
        runCurrent()

        assertEquals(listOf(status("srv-1" to true)), emitted)
    }

    @Test
    fun onlineAndOfflineIdsFollowTheStatus() = runTest {
        val m = ManagerHarness(this).manager
        m.updateServerStatus(ServerId("a"), true)
        m.updateServerStatus(ServerId("b"), false)
        m.updateServerStatus(ServerId("c"), true)

        assertEquals(setOf(ServerId("a"), ServerId("c")), m.onlineServerIds.toSet())
        assertEquals(setOf(ServerId("b")), m.offlineServerIds.toSet())
        assertTrue(m.isServerOnline(ServerId("a")))
        assertFalse(m.isServerOnline(ServerId("b")))
    }

    // Endpoint exhaustion.

    @Test
    fun contentRouteExhaustionKeepsAnAuthenticatedServerOnline() = runTest {
        val h = ManagerHarness(this)
        val client = h.addJellyfin("user-a")
        val emitted = collected(h.manager.statusUpdates)

        client.events.onAllEndpointsExhausted()
        advanceTimeBy(5.seconds)
        runCurrent()

        assertTrue(h.manager.isServerOnline(jf))
        assertTrue(h.manager.authErrorServerIds.isEmpty())
        assertEquals(emptyList(), emitted, "a successful probe publishes no offline transition")
    }

    @Test
    fun exhaustionWaitsOutItsDebounceBeforeProbing() = runTest {
        val h = ManagerHarness(this)
        val client = h.addJellyfin("user-a")
        client.health = { HealthStatus.OFFLINE }

        client.events.onAllEndpointsExhausted()
        advanceTimeBy(4.seconds)
        client.events.onAllEndpointsExhausted()
        advanceTimeBy(4.seconds)
        runCurrent()
        assertTrue(h.manager.isServerOnline(jf), "each failure restarts the 5 s debounce")

        advanceTimeBy(1.seconds)
        runCurrent()
        assertFalse(h.manager.isServerOnline(jf))
    }

    @Test
    fun anAuthRejectionIsPublishedWithoutReconnecting() = runTest {
        val h = ManagerHarness(this)
        val client = h.addJellyfin("user-a")
        client.health = { HealthStatus.AUTH_ERROR }
        val emitted = collected(h.manager.statusUpdates)

        client.events.onAllEndpointsExhausted()
        advanceTimeBy(5.seconds)
        runCurrent()

        assertFalse(h.manager.isServerOnline(jf))
        assertEquals(setOf(jf), h.manager.authErrorServerIds)
        assertEquals(listOf(status("jf-machine" to false)), emitted)
        assertEquals(2, client.calls.count { it == "checkHealth" }, "the add probe and the confirmation, no reconnect probe")
    }

    @Test
    fun anAccountRefusalIsPublishedAsAccessDeniedNotAsASignInPrompt() = runTest {
        val h = ManagerHarness(this)
        val client = h.addJellyfin("user-a")
        client.health = { HealthStatus.ACCESS_DENIED }
        val emitted = collected(h.manager.statusUpdates)

        client.events.onAllEndpointsExhausted()
        advanceTimeBy(5.seconds)
        runCurrent()

        assertFalse(h.manager.isServerOnline(jf))
        assertEquals(setOf(jf), h.manager.accessDeniedServerIds)
        assertTrue(h.manager.authErrorServerIds.isEmpty(), "a new sign-in gets the same refusal")
        assertEquals(listOf(status("jf-machine" to false)), emitted)
        assertEquals(2, client.calls.count { it == "checkHealth" })
    }

    @Test
    fun aConfirmedOfflineProbePublishesOfflineOnceAndSchedulesAReconnection() = runTest {
        val h = ManagerHarness(this)
        val client = h.addJellyfin("user-a")
        client.health = { HealthStatus.OFFLINE }
        val emitted = collected(h.manager.statusUpdates)

        client.events.onAllEndpointsExhausted()
        advanceTimeBy(5.seconds)
        runCurrent()

        assertFalse(h.manager.isServerOnline(jf))
        assertEquals(3, client.calls.count { it == "checkHealth" }, "the add probe, the confirmation, the reconnection probe")
        assertEquals(listOf(status("jf-machine" to false)), emitted, "the reconnection probe repeating offline publishes nothing")
    }

    @Test
    fun probeRaisedExhaustionReArmsTheRetryLoopAndRecoversWhenTheServerReturns() = runTest {
        val h = ManagerHarness(this)
        val client = h.addJellyfin("user-a")
        var healthy = false
        // As the real client does: the probe's own failed request raises exhaustion.
        client.health = {
            if (healthy) {
                HealthStatus.ONLINE
            } else {
                client.events.onAllEndpointsExhausted()
                HealthStatus.OFFLINE
            }
        }
        val emitted = collected(h.manager.statusUpdates)

        client.events.onAllEndpointsExhausted()
        advanceTimeBy(5.seconds)
        runCurrent()
        assertFalse(h.manager.isServerOnline(jf))

        healthy = true
        advanceTimeBy(6.seconds)
        runCurrent()
        assertTrue(h.manager.isServerOnline(jf))
        assertEquals(listOf(status("jf-machine" to false), status("jf-machine" to true)), emitted)
    }

    // Profile binds.

    @Test
    fun aSuccessfulInPlaceTokenRefreshClearsTheAuthError() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val id = ServerId("server-1")
        m.refreshTokensForProfile(FakePlexAccount("account-1", listOf(plexServer("server-1"))), "profile-1")
        val client = h.plex.clients.getValue(id)
        m.markPlexConnectionAuthError(FakePlexAccount("account-1", listOf(plexServer("server-1"))), "profile-1")
        assertEquals(setOf(id), m.authErrorServerIds)

        val bound = m.refreshTokensForProfile(FakePlexAccount("account-1", listOf(plexServer("server-1", token = "new-token"))), "profile-1")

        assertEquals(setOf(id), bound)
        assertTrue(id !in m.authErrorServerIds)
        assertTrue(m.isServerOnline(id))
        assertEquals("new-token", client.token)
        assertSame(client, m.client(id), "the client moved in place")
    }

    @Test
    fun anInPlaceRefreshCommitsTheTokenScopeAndAccount() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val id = ServerId("server-1")
        m.refreshTokensForProfile(FakePlexAccount("account-0", listOf(plexServer("server-1"))), "old-profile")
        val client = h.plex.clients.getValue(id)

        val bound = m.refreshTokensForProfile(FakePlexAccount("account-1", listOf(plexServer("server-1", token = "new-token"))), "new-profile")

        assertEquals(setOf(id), bound)
        assertTrue(m.isServerOnline(id))
        assertEquals("new-token", client.token)
        assertEquals(scope("server-1", "new-profile"), client.scope)
        assertEquals("account-1", client.accountId, "Live TV favorites are keyed by the owning account")
        assertEquals(1, h.plex.calls.size)
    }

    @Test
    fun theNewestOverlappingRefreshOwnsTheClient() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val id = ServerId("server-1")
        m.refreshTokensForProfile(FakePlexAccount("account-1", listOf(plexServer("server-1"))), "old-profile")
        val client = h.plex.clients.getValue(id)
        val gates = mapOf("token-a" to CompletableDeferred<Unit>(), "token-b" to CompletableDeferred<Unit>())
        var latest: String? = null
        client.profileUpdate = { token, newScope ->
            latest = token
            gates.getValue(token).await()
            if (latest == token) client.commit(token, newScope) else false
        }

        val earlier = async { m.refreshTokensForProfile(FakePlexAccount("account-1", listOf(plexServer("server-1", token = "token-a"))), "profile-a") }
        runCurrent()
        val later = async { m.refreshTokensForProfile(FakePlexAccount("account-1", listOf(plexServer("server-1", token = "token-b"))), "profile-b") }
        runCurrent()

        gates.getValue("token-b").complete(Unit)
        assertEquals(setOf(id), later.await())
        gates.getValue("token-a").complete(Unit)
        assertEquals(emptySet(), earlier.await())

        assertEquals("token-b", client.token)
        assertEquals(scope("server-1", "profile-b"), client.scope)
    }

    @Test
    fun aRefreshedTokenRejectedWith401Or403StaysOfflineWithThatRefusal() = runTest {
        for ((code, expected) in listOf(401 to HealthStatus.AUTH_ERROR, 403 to HealthStatus.ACCESS_DENIED)) {
            val h = ManagerHarness(this)
            val m = h.manager
            val id = ServerId("server-1")
            m.refreshTokensForProfile(FakePlexAccount("account-1", listOf(plexServer("server-1"))), "old-profile")
            val client = h.plex.clients.getValue(id)
            client.profileUpdate = { _, _ -> throw MediaServerHttpException(MediaServerHttpErrorType.UNKNOWN, "rejected", statusCode = code) }

            val bound = m.refreshTokensForProfile(FakePlexAccount("account-1", listOf(plexServer("server-1", token = "rejected"))), "profile-b")

            assertEquals(emptySet(), bound, "HTTP $code")
            assertFalse(m.isServerOnline(id), "HTTP $code")
            val (refusedAs, notRefusedAs) =
                if (expected == HealthStatus.AUTH_ERROR) m.authErrorServerIds to m.accessDeniedServerIds else m.accessDeniedServerIds to m.authErrorServerIds
            assertEquals(setOf(id), refusedAs, "HTTP $code")
            assertTrue(notRefusedAs.isEmpty(), "HTTP $code")
            assertEquals("token-server-1", client.token, "HTTP $code")
            assertEquals(scope("server-1", "old-profile"), client.scope, "HTTP $code")
            m.dispose()
        }
    }

    @Test
    fun aProbeAnsweredByAnotherServerCommitsNothing() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val id = ServerId("server-1")
        m.refreshTokensForProfile(FakePlexAccount("account-1", listOf(plexServer("server-1"))), "old-profile")
        val client = h.plex.clients.getValue(id)
        client.profileUpdate = { _, _ -> throw IllegalStateException("answered by different-server") }

        val bound = m.refreshTokensForProfile(FakePlexAccount("account-1", listOf(plexServer("server-1", token = "wrong"))), "profile-b")

        assertEquals(emptySet(), bound)
        assertFalse(m.isServerOnline(id))
        assertTrue(m.refusedServerIds.isEmpty())
        assertEquals("token-server-1", client.token)
        assertEquals(scope("server-1", "old-profile"), client.scope)
    }

    @Test
    fun concurrentRefreshesOfDifferentAccountsDoNotInvalidateEachOther() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        m.refreshTokensForProfile(FakePlexAccount("account-a", listOf(plexServer("server-a"))), "profile-a")
        m.refreshTokensForProfile(FakePlexAccount("account-b", listOf(plexServer("server-b"))), "profile-b")

        val a = async { m.refreshTokensForProfile(FakePlexAccount("account-a", listOf(plexServer("server-a", token = "new-a"))), "profile-a") }
        val b = async { m.refreshTokensForProfile(FakePlexAccount("account-b", listOf(plexServer("server-b", token = "new-b"))), "profile-b") }

        assertEquals(setOf(ServerId("server-a")), a.await())
        assertEquals(setOf(ServerId("server-b")), b.await())
        assertEquals("new-a", h.plex.clients.getValue(ServerId("server-a")).token)
        assertEquals("new-b", h.plex.clients.getValue(ServerId("server-b")).token)
    }

    @Test
    fun aFreshBindRegistersTheScopedClientAndPromotesALaterEndpoint() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val id = ServerId("fresh-server")
        val first = localEndpoint("first")
        val promoted = localEndpoint("promoted")
        val discoveries = Channel<RacedEndpoint>(Channel.UNLIMITED)
        val server = FakePlexServer(
            "fresh-server",
            mapOf(first to EndpointNetworkClass.LOCAL, promoted to EndpointNetworkClass.LOCAL),
            races = listOf({ discoveries.consumeAsFlow() }),
        )
        val progress = collected(m.connectProgress)

        val refresh = async { m.refreshTokensForProfile(FakePlexAccount("fresh-account", listOf(server)), "profile-a") }
        runCurrent()
        discoveries.send(RacedEndpoint(first, transcoderVideo = true))
        val bound = refresh.await()
        runCurrent()

        val expectedScope = scope("fresh-server", "profile-a")
        val client = h.plex.clients.getValue(id)
        assertEquals(setOf(id), bound)
        assertSame(client, m.client(id))
        assertEquals(expectedScope.value, client.cacheServerId)
        assertTrue(m.isServerOnline(id))
        assertTrue(ConnectProgress(id, online = true) in progress)
        assertEquals(first, h.endpoints.saved[id])

        val call = h.plex.calls.single()
        assertEquals(id, call.serverId)
        assertEquals(expectedScope, call.profileScopeId)
        assertEquals(first, call.endpoint.url)
        assertEquals(true, call.endpoint.transcoderVideo)
        assertEquals(first, call.failoverEndpoints.first())

        discoveries.send(RacedEndpoint(promoted))
        discoveries.close()
        runCurrent()

        assertEquals(promoted, client.baseUrl)
        assertEquals(promoted, h.endpoints.saved[id])
    }

    @Test
    fun aFreshBindIsolatesASiblingFailureAndPublishesBothOutcomes() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val good = ServerId("good-server")
        val bad = ServerId("bad-server")
        h.plex.failingServerIds = setOf(bad)
        val progress = collected(m.connectProgress)
        val statuses = collected(m.statusUpdates)

        val bound = m.refreshTokensForProfile(FakePlexAccount("mixed-account", listOf(plexServer("good-server"), plexServer("bad-server"))), "profile-a")
        runCurrent()

        assertEquals(setOf(good), bound)
        assertSame(h.plex.clients.getValue(good), m.client(good))
        assertNull(m.client(bad))
        assertTrue(m.isServerOnline(good))
        assertFalse(m.isServerOnline(bad))
        assertTrue(progress.containsAll(listOf(ConnectProgress(good, true), ConnectProgress(bad, false))))
        assertEquals(status("good-server" to true, "bad-server" to false), statuses.last())
        assertEquals(1, h.connectivity.subscriptionCount.value)
    }

    @Test
    fun aLateEndpointPromotionCannotMutatePersistenceOrAReplacementAfterRemoval() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val id = ServerId("stale-server")
        val first = localEndpoint("stale-first")
        val late = localEndpoint("stale-late")
        val replacementUrl = localEndpoint("replacement")
        val discoveries = Channel<RacedEndpoint>(Channel.UNLIMITED)
        val server = FakePlexServer(
            "stale-server",
            mapOf(first to EndpointNetworkClass.LOCAL, late to EndpointNetworkClass.LOCAL),
            races = listOf({ discoveries.consumeAsFlow() }),
        )

        val refresh = async { m.refreshTokensForProfile(FakePlexAccount("stale-account", listOf(server)), "profile-a") }
        runCurrent()
        discoveries.send(RacedEndpoint(first))
        assertEquals(setOf(id), refresh.await())
        assertEquals(first, h.endpoints.saved[id])

        m.removeServer(id)
        m.refreshTokensForProfile(FakePlexAccount("stale-account", listOf(plexServer("stale-server", url = replacementUrl))), "profile-b")
        val replacement = h.plex.clients.getValue(id)

        discoveries.send(RacedEndpoint(late))
        discoveries.close()
        runCurrent()

        assertSame(replacement, m.client(id))
        assertEquals(replacementUrl, replacement.baseUrl)
        assertEquals(replacementUrl, h.endpoints.saved[id])
        assertTrue(h.endpoints.writes.none { it.second == late })
    }

    @Test
    fun connectivityMonitoringIsLazySingularAndCoalescesEveryChangeNoneIncludedForTwoSeconds() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val id = ServerId("monitor-server")
        val server = plexServer("monitor-server")

        assertEquals(0, h.connectivity.subscriptionCount.value)
        assertEquals(setOf(id), m.refreshTokensForProfile(FakePlexAccount("monitor-account", listOf(server)), "profile-a"))
        assertEquals(1, h.connectivity.subscriptionCount.value)
        assertEquals(1, server.raceCalls)

        assertEquals(setOf(id), m.refreshTokensForProfile(FakePlexAccount("monitor-account", listOf(server)), "profile-a"))
        assertEquals(1, h.connectivity.subscriptionCount.value)
        assertEquals(1, h.plex.calls.size)
        val client = h.plex.clients.getValue(id)
        fun healthProbes() = client.calls.count { it == "checkHealth" }
        assertEquals(0, healthProbes())

        // Losing the network re-probes like any other change: it is how an unreachable server goes offline.
        h.connectivity.emit(Connectivity.of(ConnectivityLink.NONE))
        h.connectivity.emit(Connectivity.of(ConnectivityLink.WIFI))
        h.connectivity.emit(Connectivity.of(ConnectivityLink.MOBILE))
        runCurrent()
        advanceTimeBy(1999.milliseconds)
        runCurrent()
        assertEquals(1, server.raceCalls)
        assertEquals(0, healthProbes())

        advanceTimeBy(1.milliseconds)
        runCurrent()
        assertEquals(2, server.raceCalls)
        assertEquals(1, healthProbes())

        h.connectivity.emit(Connectivity.of(ConnectivityLink.NONE))
        runCurrent()
        advanceTimeBy(2.seconds)
        runCurrent()
        assertEquals(3, server.raceCalls)
        assertEquals(2, healthProbes())
        assertEquals(1, h.connectivity.subscriptionCount.value)

        m.dispose()
        runCurrent()
        assertEquals(0, h.connectivity.subscriptionCount.value)
    }

    @Test
    fun losingTheNetworkKeepsAReachableServerOnlineAndDropsAnUnreachableOne() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        h.addJellyfin("user", machineId = "jf-loopback")
        val remote = h.addJellyfin("user", machineId = "jf-remote")
        assertTrue(m.isServerOnline(ServerId("jf-loopback")))
        assertTrue(m.isServerOnline(ServerId("jf-remote")))
        assertEquals(1, h.connectivity.subscriptionCount.value)

        // The adapter goes down: the remote server loses its route, the loopback one does not.
        remote.health = { HealthStatus.OFFLINE }
        h.connectivity.emit(Connectivity.of(ConnectivityLink.NONE))
        runCurrent()
        advanceTimeBy(2.seconds)
        runCurrent()

        assertFalse(m.isServerOnline(ServerId("jf-remote")))
        assertTrue(m.isServerOnline(ServerId("jf-loopback")))
    }

    @Test
    fun aServerRecoveredByAHealthProbeIsReprobedWhenTheNetworkDrops() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        // The session started with the server unreachable; the health probe brings it online.
        val client = h.addJellyfin("user-a", health = HealthStatus.OFFLINE)
        assertEquals(0, h.connectivity.subscriptionCount.value)
        client.health = { HealthStatus.ONLINE }
        m.checkServerHealth()
        assertTrue(m.isServerOnline(jf))
        assertEquals(1, h.connectivity.subscriptionCount.value)

        client.health = { HealthStatus.OFFLINE }
        h.connectivity.emit(Connectivity.of(ConnectivityLink.NONE))
        runCurrent()
        advanceTimeBy(2.seconds)
        runCurrent()

        assertFalse(m.isServerOnline(jf))
    }

    @Test
    fun aClientThatConnectsAfterTheTimeoutIsClosedInsteadOfLeaked() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val id = ServerId("late-server")
        val gate = CompletableDeferred<Unit>()
        h.plex.createGate = gate

        val bound = m.refreshTokensForProfile(FakePlexAccount("late-account", listOf(plexServer("late-server"))), "profile-a", timeout = 10.milliseconds)
        assertEquals(emptySet(), bound)
        assertFalse(m.isServerOnline(id))

        gate.complete(Unit)
        runCurrent()

        val late = h.plex.clients.getValue(id)
        assertNull(m.client(id))
        assertEquals(1, late.closed)
    }

    @Test
    fun anOfflineClientOfAnotherProfileIsDroppedWhenThisProfileCannotConnect() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val id = ServerId("server-1")
        val url = localEndpoint("server-1")
        val server = FakePlexServer("server-1", mapOf(url to EndpointNetworkClass.LOCAL), races = listOf(raceOf(url), { emptyFlow() }))
        m.refreshTokensForProfile(FakePlexAccount("account", listOf(server)), "profile-a")
        val previous = h.plex.clients.getValue(id)
        m.updateServerStatus(id, false)

        val bound = m.refreshTokensForProfile(FakePlexAccount("account", listOf(server)), "profile-b")
        runCurrent()

        assertEquals(emptySet(), bound)
        assertNull(m.client(id))
        assertEquals(1, previous.closed)
        // Still registered, for profile B: a reconnect retries it with B's token.
        assertEquals(listOf(id), m.registeredServerIds)
        assertFalse(m.isRegisteredForOtherProfile(id, "profile-b"))
        assertTrue(m.isRegisteredForOtherProfile(id, "profile-a"))
    }

    @Test
    fun disposeCancelsAPendingConnectivityDebounceWithNoLaterMutation() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val id = ServerId("pending-server")
        val server = plexServer("pending-server")
        assertEquals(setOf(id), m.refreshTokensForProfile(FakePlexAccount("pending-account", listOf(server)), "profile-a"))
        val client = h.plex.clients.getValue(id)

        h.connectivity.emit(Connectivity.of(ConnectivityLink.WIFI))
        runCurrent()
        advanceTimeBy(1.seconds)
        m.dispose()
        runCurrent()
        val racesAfterDispose = server.raceCalls
        val callsAfterDispose = client.calls.size
        val writesAfterDispose = h.endpoints.writes.size

        advanceTimeBy(10.seconds)
        runCurrent()

        assertEquals(0, h.connectivity.subscriptionCount.value)
        assertEquals(racesAfterDispose, server.raceCalls)
        assertEquals(callsAfterDispose, client.calls.size)
        assertEquals(writesAfterDispose, h.endpoints.writes.size)
        assertTrue(m.serverIds.isEmpty())
        assertTrue(m.onlineServerIds.isEmpty())
    }

    @Test
    fun aBindReportsEachServerAndPublishesOneSnapshot() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val account = FakePlexAccount("plex.account", listOf(plexServer("srv-1"), plexServer("srv-2")))
        m.refreshTokensForProfile(account, "profile-a")
        val progress = collected(m.connectProgress)
        val statuses = collected(m.statusUpdates)

        val bound = m.refreshTokensForProfile(account, "profile-a")
        runCurrent()

        assertEquals(setOf(ServerId("srv-1"), ServerId("srv-2")), bound)
        assertEquals(setOf(ServerId("srv-1"), ServerId("srv-2")), progress.map { it.serverId }.toSet())
        assertTrue(progress.all { it.online })
        assertEquals(1, statuses.size, "one snapshot per bind: the first one means the first connect pass finished")
    }

    @Test
    fun aDisconnectVoidsABindInFlightAndClosesItsClient() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val id = ServerId("server-1")
        val gate = CompletableDeferred<Unit>()
        h.plex.createGate = gate

        val refresh = async { m.refreshTokensForProfile(FakePlexAccount("account", listOf(plexServer("server-1"))), "profile-a") }
        runCurrent()
        m.disconnectAll()
        gate.complete(Unit)

        assertEquals(emptySet(), refresh.await())
        runCurrent()
        assertNull(m.client(id))
        assertEquals(1, h.plex.clients.getValue(id).closed)
    }

    // Health checks.

    @Test
    fun aProbeResultFromAClientReplacedMidProbeIsNotApplied() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val id = ServerId("server-1")
        m.refreshTokensForProfile(FakePlexAccount("account", listOf(plexServer("server-1"))), "profile-a")
        val original = h.plex.clients.getValue(id)
        val probeStarted = CompletableDeferred<Unit>()
        val release = CompletableDeferred<Unit>()
        original.health = {
            probeStarted.complete(Unit)
            release.await()
            HealthStatus.OFFLINE
        }

        val health = async { m.checkServerHealth() }
        runCurrent()
        assertTrue(probeStarted.isCompleted)
        // A profile switch: the old client goes and the new profile's client is bound under the same id.
        m.removeServer(id)
        m.refreshTokensForProfile(FakePlexAccount("account", listOf(plexServer("server-1"))), "profile-b")
        val replacement = h.plex.clients.getValue(id)
        release.complete(Unit)
        health.await()

        assertSame(replacement, m.client(id))
        assertTrue(m.isServerOnline(id))
    }

    @Test
    fun concurrentHealthChecksShareOnePass() = runTest {
        val h = ManagerHarness(this)
        val client = h.addJellyfin("user-a")
        val release = CompletableDeferred<Unit>()
        client.health = {
            release.await()
            HealthStatus.ONLINE
        }

        val first = async { h.manager.checkServerHealth() }
        val second = async { h.manager.checkServerHealth() }
        runCurrent()
        release.complete(Unit)
        first.await()
        second.await()

        assertEquals(2, client.calls.count { it == "checkHealth" }, "the add probe and one shared pass")
    }

    // Relay endpoints.

    @Test
    fun aRelayFirstWinnerIsNeverPersistedALaterDirectPromotionIs() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val id = ServerId("relay-server")
        val direct = localEndpoint("direct")
        val relay = relayEndpoint("relay")
        val discoveries = Channel<RacedEndpoint>(Channel.UNLIMITED)
        val server = FakePlexServer(
            "relay-server",
            mapOf(direct to EndpointNetworkClass.LOCAL, relay to EndpointNetworkClass.RELAY),
            races = listOf({ discoveries.consumeAsFlow() }),
        )

        val refresh = async { m.refreshTokensForProfile(FakePlexAccount("relay-account", listOf(server)), "profile-a") }
        runCurrent()
        discoveries.send(RacedEndpoint(relay))
        assertEquals(setOf(id), refresh.await())
        runCurrent()

        val client = h.plex.clients.getValue(id)
        assertEquals(relay, client.baseUrl)
        assertEquals("relay-account", client.accountId)
        assertNull(h.endpoints.saved[id])

        discoveries.send(RacedEndpoint(direct))
        discoveries.close()
        runCurrent()

        assertEquals(direct, client.baseUrl)
        assertEquals(direct, h.endpoints.saved[id])
        // Off the relay: no escape probe runs any more.
        advanceTimeBy(10.minutes)
        runCurrent()
        assertEquals(1, server.raceCalls)
    }

    @Test
    fun failoverOntoARelayNeverOverwritesThePreferredEndpoint() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val id = ServerId("failover-server")
        val direct = localEndpoint("failover-direct")
        val relay = relayEndpoint("failover-relay")
        val server = FakePlexServer(
            "failover-server",
            mapOf(direct to EndpointNetworkClass.LOCAL, relay to EndpointNetworkClass.RELAY),
            races = listOf(raceOf(direct)),
        )
        assertEquals(setOf(id), m.refreshTokensForProfile(FakePlexAccount("failover-account", listOf(server)), "profile-a"))
        runCurrent()
        assertEquals(direct, h.endpoints.saved[id])

        // Mid-session failover walks onto the relay: the client may use it, the next bind must not start from it.
        val events = h.plex.calls.single().events
        events.onEndpointChanged(relay)
        assertEquals(direct, h.endpoints.saved[id])

        // A refresh rotates the relay URL away; the old relay URL reports a late failover. The live server no longer
        // lists it, the connect-time entry still knows it is a relay.
        val rotated = FakePlexServer(
            "failover-server",
            mapOf(direct to EndpointNetworkClass.LOCAL, relayEndpoint("rotated-relay") to EndpointNetworkClass.RELAY),
            races = listOf(raceOf(direct)),
        )
        assertEquals(setOf(id), m.refreshTokensForProfile(FakePlexAccount("failover-account", listOf(rotated)), "profile-a"))
        events.onEndpointChanged(relay)
        assertEquals(direct, h.endpoints.saved[id])
    }

    @Test
    fun aFailoverReportedFromABackgroundRequestIsAppliedOnTheManagersThread() = runTest {
        val h = ManagerHarness(this)
        val id = ServerId("background-server")
        val direct = localEndpoint("background-direct")
        val other = remoteEndpoint("background-other")
        val server = FakePlexServer(
            "background-server",
            mapOf(direct to EndpointNetworkClass.LOCAL, other to EndpointNetworkClass.REMOTE),
            races = listOf(raceOf(direct)),
        )
        h.manager.refreshTokensForProfile(FakePlexAccount("background-account", listOf(server)), "profile-a")
        runCurrent()
        val managerThread = currentCoroutineContext()[ContinuationInterceptor]

        // Detail and playback requests run on a background dispatcher; their failover reports from there.
        withContext(Dispatchers.Default) { h.plex.calls.single().events.onEndpointChanged(other) }

        assertEquals(other, h.endpoints.saved[id])
        assertEquals(listOf(managerThread, managerThread), h.endpoints.writeDispatchers)
    }

    @Test
    fun exhaustionReportedFromABackgroundRequestIsConfirmedOnTheManagersThread() = runTest {
        val h = ManagerHarness(this)
        val client = h.addJellyfin("user-a")
        client.health = { HealthStatus.OFFLINE }

        withContext(Dispatchers.Default) { client.events.onAllEndpointsExhausted() }
        advanceTimeBy(5.seconds)
        runCurrent()

        assertFalse(h.manager.isServerOnline(jf))
    }

    @Test
    fun aRelaySessionReprobesOnBackoffAndPromotesAReturningDirectEndpoint() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val id = ServerId("escape-server")
        val direct = localEndpoint("escape-direct")
        val relay = relayEndpoint("escape-relay")
        val server = FakePlexServer(
            "escape-server",
            mapOf(direct to EndpointNetworkClass.LOCAL, relay to EndpointNetworkClass.RELAY),
            // Bind: only the relay answers; first escape: still relay only; second escape: direct is back.
            races = listOf(raceOf(relay), raceOf(relay), raceOf(direct)),
        )
        assertEquals(setOf(id), m.refreshTokensForProfile(FakePlexAccount("escape-account", listOf(server)), "profile-a"))
        runCurrent()
        val client = h.plex.clients.getValue(id)
        assertEquals(relay, client.baseUrl)
        assertEquals(1, server.raceCalls)

        // The first probe comes 15 to 30 s in.
        advanceTimeBy(15.seconds - 1.milliseconds)
        runCurrent()
        assertEquals(1, server.raceCalls)
        advanceTimeBy(15.seconds + 1.milliseconds)
        runCurrent()
        assertEquals(2, server.raceCalls)
        assertEquals(relay, client.baseUrl)

        // Still relay only: the next probe comes 30 to 60 s after that one.
        advanceTimeBy(15.seconds - 1.milliseconds)
        runCurrent()
        assertEquals(2, server.raceCalls)
        advanceTimeBy(45.seconds + 1.milliseconds)
        runCurrent()
        assertEquals(3, server.raceCalls)
        assertEquals(direct, client.baseUrl)
        assertEquals(direct, h.endpoints.saved[id])

        advanceTimeBy(10.minutes)
        runCurrent()
        assertEquals(3, server.raceCalls, "off the relay, the prober stays stopped")
    }

    @Test
    fun aRelaySessionKeepsProbingWithAWaitThatDoublesUpTo120Seconds() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val relay = relayEndpoint("stuck-relay")
        val probedAt = mutableListOf<Long>()
        val server = FakePlexServer(
            "stuck-server",
            mapOf(relay to EndpointNetworkClass.RELAY),
            races = listOf({
                probedAt += currentTime
                raceOf(relay)()
            }),
        )
        m.refreshTokensForProfile(FakePlexAccount("stuck-account", listOf(server)), "profile-a")
        runCurrent()

        advanceTimeBy(10.minutes)
        runCurrent()

        val waits = probedAt.zipWithNext { a, b -> (b - a).milliseconds }
        assertTrue(waits.size >= 5, "probes at $probedAt")
        for ((attempt, wait) in waits.withIndex()) {
            val bound = minOf(30.seconds * (1 shl minOf(attempt, 2)), 120.seconds)
            assertTrue(wait in bound / 2..bound, "probe ${attempt + 1} after $wait, outside half of $bound to $bound")
        }
    }

    @Test
    fun removingARelayConnectedServerCancelsItsEscapeProber() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val relay = relayEndpoint("removed-relay")
        val server = FakePlexServer(
            "removed-server",
            mapOf(localEndpoint("removed-direct") to EndpointNetworkClass.LOCAL, relay to EndpointNetworkClass.RELAY),
            races = listOf(raceOf(relay)),
        )
        m.refreshTokensForProfile(FakePlexAccount("removed-account", listOf(server)), "profile-a")
        runCurrent()

        m.removeServer(ServerId("removed-server"))
        advanceTimeBy(10.minutes)
        runCurrent()

        assertEquals(1, server.raceCalls)
    }

    // Demoted sessions.

    @Test
    fun reRacesAServerSittingOnRemoteWhileItPublishesALocalConnection() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val id = ServerId("demoted-server")
        val local = localEndpoint("demoted")
        val remote = remoteEndpoint("demoted")
        val server = FakePlexServer(
            "demoted-server",
            mapOf(local to EndpointNetworkClass.LOCAL, remote to EndpointNetworkClass.REMOTE),
            // Bind: the LAN was unreachable; resume: it is back.
            races = listOf(raceOf(remote), raceOf(local)),
        )
        m.refreshTokensForProfile(FakePlexAccount("demoted-account", listOf(server)), "profile-a")
        runCurrent()
        val client = h.plex.clients.getValue(id)
        assertEquals(remote, client.baseUrl)
        assertEquals(remote, h.endpoints.saved[id])

        m.reoptimizeDemotedServers("resume")
        runCurrent()

        assertEquals(2, server.raceCalls)
        assertEquals(local, client.baseUrl)
        assertEquals(local, h.endpoints.saved[id])

        m.reoptimizeDemotedServers("resume")
        assertEquals(2, server.raceCalls, "back on local: nothing to do")
    }

    @Test
    fun leavesAloneAServerOnLocalAndARemoteOnlyServer() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val lan = localEndpoint("on-local")
        val onLocal = FakePlexServer(
            "on-local",
            mapOf(lan to EndpointNetworkClass.LOCAL, remoteEndpoint("on-local") to EndpointNetworkClass.REMOTE),
            races = listOf(raceOf(lan)),
        )
        val wan = remoteEndpoint("remote-only")
        val remoteOnly = FakePlexServer("remote-only", mapOf(wan to EndpointNetworkClass.REMOTE), races = listOf(raceOf(wan)))
        assertEquals(
            setOf(ServerId("on-local"), ServerId("remote-only")),
            m.refreshTokensForProfile(FakePlexAccount("mixed-account", listOf(onLocal, remoteOnly)), "p"),
        )
        runCurrent()

        m.reoptimizeDemotedServers("resume")

        assertEquals(1, onLocal.raceCalls)
        assertEquals(1, remoteOnly.raceCalls)
    }

    @Test
    fun skipsOfflineServersWhichTheReconnectPathOwns() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val local = localEndpoint("offline")
        val remote = remoteEndpoint("offline")
        val server = FakePlexServer(
            "offline-server",
            mapOf(local to EndpointNetworkClass.LOCAL, remote to EndpointNetworkClass.REMOTE),
            races = listOf(raceOf(remote)),
        )
        m.refreshTokensForProfile(FakePlexAccount("offline-account", listOf(server)), "p")
        runCurrent()
        m.updateServerStatus(ServerId("offline-server"), false)

        m.reoptimizeDemotedServers("resume")

        assertEquals(1, server.raceCalls)
    }

    // Reconnects and resume.

    @Test
    fun aFailedReconnectRefetchesTheServerListAtMostEvery30SecondsUnlessForced() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val id = ServerId("server-1")
        val url = localEndpoint("server-1")
        val server = FakePlexServer("server-1", mapOf(url to EndpointNetworkClass.LOCAL), races = listOf(raceOf(url), { emptyFlow() }))
        m.refreshTokensForProfile(FakePlexAccount("plex.account", listOf(server)), "profile-a")
        m.updateServerStatus(id, false)

        m.reconnectOfflineServers()
        assertEquals(listOf("plex.account"), h.plex.serverListRefreshes)
        m.reconnectOfflineServers()
        assertEquals(1, h.plex.serverListRefreshes.size, "throttled")

        m.reconnectOfflineServers(forceRediscovery = true)
        assertNull(h.endpoints.saved[id], "a forced reconnect races from scratch")
        assertEquals(2, h.plex.serverListRefreshes.size)

        advanceTimeBy(30.seconds)
        m.reconnectOfflineServers()
        assertEquals(3, h.plex.serverListRefreshes.size)
        assertFalse(m.isServerOnline(id))
    }

    @Test
    fun aReconnectKeepsTheClientWhoseTokenAndScopeStillApply() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val id = ServerId("server-1")
        val local = localEndpoint("server-1")
        val remote = remoteEndpoint("server-1")
        val server = FakePlexServer(
            "server-1",
            mapOf(local to EndpointNetworkClass.LOCAL, remote to EndpointNetworkClass.REMOTE),
            races = listOf(raceOf(local), raceOf(remote)),
        )
        m.refreshTokensForProfile(FakePlexAccount("account", listOf(server)), "profile-a")
        val client = h.plex.clients.getValue(id)
        m.updateServerStatus(id, false)

        m.reconnectOfflineServers()
        runCurrent()

        assertSame(client, m.client(id), "playback reports and downloads still hold it")
        assertEquals(0, client.closed)
        assertEquals(1, h.plex.calls.size)
        assertTrue(m.isServerOnline(id))
        assertEquals(remote, client.baseUrl, "on the endpoint that answered")
        assertEquals(remote, h.endpoints.saved[id])
    }

    @Test
    fun aReconnectReplacesAClientWhoseTokenChanged() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val id = ServerId("server-1")
        val url = localEndpoint("server-1")
        m.refreshTokensForProfile(FakePlexAccount("account", listOf(plexServer("server-1", token = "token-1"))), "profile-a")
        val old = h.plex.clients.getValue(id)
        m.updateServerStatus(id, false)
        // Bound again with a new token while unreachable: the client with the old token stays registered.
        val rotated = FakePlexServer("server-1", mapOf(url to EndpointNetworkClass.LOCAL), races = listOf({ emptyFlow() }, raceOf(url)), accessToken = "token-2")
        assertEquals(emptySet(), m.refreshTokensForProfile(FakePlexAccount("account", listOf(rotated)), "profile-a"))
        assertSame(old, m.client(id))

        m.reconnectOfflineServers()
        runCurrent()

        val fresh = h.plex.clients.getValue(id)
        assertTrue(fresh !== old)
        assertSame(fresh, m.client(id))
        assertEquals("token-2", fresh.token)
        assertEquals(scope("server-1", "profile-a").value, fresh.cacheServerId)
        assertTrue(m.isServerOnline(id))
        assertEquals(1, old.closed)
    }

    // Offline retries.

    private fun unreachableServer(id: String, race: () -> Flow<RacedEndpoint> = { emptyFlow() }) =
        FakePlexServer(id, mapOf(localEndpoint(id) to EndpointNetworkClass.LOCAL), races = listOf(race))

    @Test
    fun anUnreachableServerIsRetriedFiveTimesOnAGrowingBackoffThenLeftAlone() = runTest {
        val h = ManagerHarness(this)
        val attempts = mutableListOf<Long>()
        val server = unreachableServer("sleepy") {
            attempts += currentTime
            emptyFlow()
        }
        h.manager.refreshTokensForProfile(FakePlexAccount("account", listOf(server)), "profile-a")

        h.manager.retryOfflinePlexServers()
        advanceTimeBy(10.minutes)

        assertEquals(listOf(0L, 2_000L, 6_000L, 14_000L, 29_000L, 59_000L), attempts, "the bind, then 2, 4, 8, 15 and 30 s after each attempt")
    }

    @Test
    fun aServerThatAnswersSecondsAfterTheBindComesOnlineByItself() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val id = ServerId("sleepy")
        val url = localEndpoint("sleepy")
        val server = FakePlexServer("sleepy", mapOf(url to EndpointNetworkClass.LOCAL), races = listOf({ emptyFlow() }, { emptyFlow() }, raceOf(url)))
        assertEquals(emptySet(), m.refreshTokensForProfile(FakePlexAccount("account", listOf(server)), "profile-a"))

        m.retryOfflinePlexServers()
        advanceTimeBy(2.seconds)
        runCurrent()
        assertFalse(m.isServerOnline(id))

        advanceTimeBy(4.seconds)
        runCurrent()
        assertTrue(m.isServerOnline(id))

        advanceTimeBy(10.minutes)
        assertEquals(3, server.raceCalls, "an online server is not retried")
    }

    @Test
    fun aServerThatRefusesTheAccountIsNotRetried() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val id = ServerId("refusing")
        val server = plexServer("refusing")
        m.refreshTokensForProfile(FakePlexAccount("account", listOf(server)), "profile-a")
        h.plex.clients.getValue(id).health = { HealthStatus.ACCESS_DENIED }
        m.checkServerHealth()
        assertEquals(setOf(id), m.accessDeniedServerIds)

        m.retryOfflinePlexServers()
        advanceTimeBy(10.minutes)

        assertEquals(1, server.raceCalls)
    }

    @Test
    fun aRetryDuringAProfileRefreshLeavesTheConnectToTheRefresh() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val server = FakePlexServer(
            "sleepy",
            mapOf(localEndpoint("sleepy") to EndpointNetworkClass.LOCAL),
            races = listOf({ emptyFlow() }, { flow { awaitCancellation() } }, { emptyFlow() }),
        )
        val account = FakePlexAccount("account", listOf(server))
        m.refreshTokensForProfile(account, "profile-a")
        m.retryOfflinePlexServers()

        val refresh = async { m.refreshTokensForProfile(account, "profile-a", timeout = 10.seconds) }
        runCurrent()
        advanceTimeBy(9.seconds)
        assertEquals(2, server.raceCalls, "the retries at 2 and 6 s fall during the refresh")

        refresh.await()
        advanceTimeBy(5.seconds)
        assertEquals(3, server.raceCalls, "the next one, 8 s later, runs")
    }

    @Test
    fun aDisconnectCancelsTheRetries() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val server = unreachableServer("sleepy")
        val account = FakePlexAccount("account", listOf(server))
        m.refreshTokensForProfile(account, "profile-a")
        m.retryOfflinePlexServers()
        advanceTimeBy(1.seconds)

        m.disconnectAll()
        // Bound again, still unreachable, without asking for retries.
        m.refreshTokensForProfile(account, "profile-a")
        advanceTimeBy(10.minutes)

        assertEquals(2, server.raceCalls)
    }

    @Test
    fun aBindThatReachesNoServerStillReprobesWhenTheNetworkChanges() = runTest {
        val h = ManagerHarness(this)
        val server = unreachableServer("sleepy")
        assertEquals(emptySet(), h.manager.refreshTokensForProfile(FakePlexAccount("account", listOf(server)), "profile-a"))
        assertEquals(1, h.connectivity.subscriptionCount.value)

        h.connectivity.emit(Connectivity.of(ConnectivityLink.WIFI))
        runCurrent()
        advanceTimeBy(2.seconds)
        runCurrent()

        assertEquals(2, server.raceCalls)
    }

    @Test
    fun aResumeProbesHealthThenReconnectsOfflineServersWithinACooldown() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val client = h.addJellyfin("user-a")
        client.health = { HealthStatus.OFFLINE }
        fun probes() = client.calls.count { it == "checkHealth" }

        m.probeAfterResume()
        assertEquals(3, probes(), "the add probe, the health pass that finds it offline, the reconnect probe")

        m.probeAfterResume()
        assertEquals(3, probes(), "inside the cooldown")

        advanceTimeBy(MultiServerManager.RESUME_PROBE_COOLDOWN_MOBILE)
        m.probeAfterResume()
        assertEquals(5, probes())
    }

    @Test
    fun aResumeKeepsRetryingAPlexServerStillOffline() = runTest {
        val h = ManagerHarness(this)
        val server = unreachableServer("sleepy")
        h.manager.refreshTokensForProfile(FakePlexAccount("account", listOf(server)), "profile-a")

        h.manager.probeAfterResume()
        assertEquals(2, server.raceCalls, "the bind and the resume's reconnect")
        advanceTimeBy(2.seconds)
        runCurrent()

        assertEquals(3, server.raceCalls)
    }

    @Test
    fun aResumeAlsoReRacesADemotedServer() = runTest {
        val h = ManagerHarness(this)
        val local = localEndpoint("demoted")
        val remote = remoteEndpoint("demoted")
        val server = FakePlexServer(
            "demoted-server",
            mapOf(local to EndpointNetworkClass.LOCAL, remote to EndpointNetworkClass.REMOTE),
            races = listOf(raceOf(remote), raceOf(local)),
        )
        h.manager.refreshTokensForProfile(FakePlexAccount("account", listOf(server)), "profile-a")
        runCurrent()

        h.manager.probeAfterResume()

        assertEquals(local, h.plex.clients.getValue(ServerId("demoted-server")).baseUrl)
    }

    // MediaBrowser connections.

    @Test
    fun aConnectionUpdateReportedDuringAHealthCheckIsPersistedBeforeTheCheckEnds() = runTest {
        val h = ManagerHarness(this)
        val persistStarted = CompletableDeferred<Unit>()
        val allowPersist = CompletableDeferred<Unit>()
        h.mediaBrowser.persist = {
            persistStarted.complete(Unit)
            allowPersist.await()
            h.mediaBrowser.persisted += it
        }
        val client = h.addJellyfin("user-a")
        val updated = (client.connection as FakeMediaBrowserConnection).copy(isAdministrator = true)
        client.health = {
            client.events.onConnectionUpdated(updated)
            HealthStatus.ONLINE
        }

        val health = async { h.manager.checkServerHealth() }
        runCurrent()
        assertTrue(persistStarted.isCompleted)
        assertTrue(h.mediaBrowser.persisted.isEmpty())
        assertFalse(health.isCompleted)

        allowPersist.complete(Unit)
        health.await()
        assertEquals(listOf<MediaBrowserConnection>(updated), h.mediaBrowser.persisted)
    }

    @Test
    fun healthStaysOnlineWhenPersistingAConnectionUpdateFails() = runTest {
        val h = ManagerHarness(this)
        h.mediaBrowser.persist = { throw IllegalStateException("disk full") }
        val client = h.addJellyfin("user-a")
        client.health = {
            val updated = (client.connection as FakeMediaBrowserConnection).copy(isAdministrator = true)
            client.connection = updated
            client.events.onConnectionUpdated(updated)
            HealthStatus.ONLINE
        }

        h.manager.checkServerHealth()

        assertTrue(h.manager.isServerOnline(jf))
        assertTrue(h.manager.isOwnerOrAdmin(jf))
    }

    @Test
    fun aConnectionUpdateFromAReplacedClientIsIgnored() = runTest {
        val h = ManagerHarness(this)
        val old = h.addJellyfin("user-a")
        val started = CompletableDeferred<Unit>()
        val release = CompletableDeferred<Unit>()
        old.health = {
            started.complete(Unit)
            release.await()
            old.events.onConnectionUpdated((old.connection as FakeMediaBrowserConnection).copy(isAdministrator = true))
            HealthStatus.ONLINE
        }

        val health = async { h.manager.checkServerHealth() }
        runCurrent()
        assertTrue(started.isCompleted)
        val replacement = h.addJellyfin("user-a", accessToken = "new-token")
        release.complete(Unit)
        health.await()

        assertTrue(h.mediaBrowser.persisted.isEmpty())
        assertSame(replacement, h.manager.mediaBrowserClient("jf-machine/user-a"))
    }

    @Test
    fun aStaleHealthResultIsIgnoredWhenTheActiveUserChangesMidCheck() = runTest {
        val h = ManagerHarness(this)
        val userA = h.addJellyfin("user-a")
        val started = CompletableDeferred<Unit>()
        val release = CompletableDeferred<Unit>()
        userA.health = {
            started.complete(Unit)
            release.await()
            HealthStatus.ACCESS_DENIED
        }

        val health = async { h.manager.checkServerHealth() }
        runCurrent()
        assertTrue(started.isCompleted)
        val userB = h.addJellyfin("user-b")
        release.complete(Unit)
        health.await()

        assertSame(userB, h.manager.client(jf))
        assertTrue(h.manager.isServerOnline(jf))
        assertTrue(jf !in h.manager.refusedServerIds)
    }

    /** Adds [userId] on the shared machine whose health probe waits for the returned gate, then answers [health]. */
    private fun TestScope.addWithGatedHealth(h: ManagerHarness, userId: String, health: HealthStatus, accessToken: String = "token-$userId"): Pair<Deferred<Boolean>, CompletableDeferred<Unit>> {
        val release = CompletableDeferred<Unit>()
        h.mediaBrowser.configure = { client ->
            client.health = {
                release.await()
                health
            }
        }
        val add = async { h.manager.addMediaBrowserConnection(FakeMediaBrowserConnection("jf-machine", userId, accessToken = accessToken)) }
        runCurrent()
        h.mediaBrowser.configure = {}
        return add to release
    }

    @Test
    fun aFreshAddsLateHealthDoesNotOverrideTheUserThatBecameActive() = runTest {
        val h = ManagerHarness(this)
        val (addA, releaseA) = addWithGatedHealth(h, "user-a", HealthStatus.AUTH_ERROR)
        val userB = h.addJellyfin("user-b")
        assertTrue(h.manager.isServerOnline(jf))

        releaseA.complete(Unit)
        assertFalse(addA.await())

        assertSame(userB, h.manager.client(jf))
        assertTrue(h.manager.isServerOnline(jf))
        assertTrue(jf !in h.manager.refusedServerIds)
    }

    @Test
    fun aReplacedClientsLateHealthIsIgnored() = runTest {
        val h = ManagerHarness(this)
        val (addOld, releaseOld) = addWithGatedHealth(h, "user-a", HealthStatus.OFFLINE, accessToken = "old-token")
        val replacement = h.addJellyfin("user-a", accessToken = "new-token")

        releaseOld.complete(Unit)
        addOld.await()

        assertSame(replacement, h.manager.client(jf))
        assertTrue(h.manager.isServerOnline(jf))
    }

    @Test
    fun aRemovedClientsLateHealthLeavesNoStatusBehind() = runTest {
        val h = ManagerHarness(this)
        val (add, release) = addWithGatedHealth(h, "user-a", HealthStatus.ACCESS_DENIED)
        h.manager.removeMediaBrowserConnection(FakeMediaBrowserConnection("jf-machine", "user-a"))

        release.complete(Unit)
        add.await()

        assertNull(h.manager.client(jf))
        assertTrue(jf !in h.manager.refusedServerIds)
        assertFalse(h.manager.isServerOnline(jf))
    }

    @Test
    fun reAddingAnIdenticalConnectionReusesTheLiveClient() = runTest {
        val h = ManagerHarness(this)
        val client = h.addJellyfin("user-a")

        val healthy = h.manager.addMediaBrowserConnection(FakeMediaBrowserConnection("jf-machine", "user-a"))

        assertTrue(healthy)
        assertSame(client, h.manager.mediaBrowserClient("jf-machine/user-a"))
        assertSame(client, h.manager.client(jf))
        assertEquals(1, h.mediaBrowser.clients.size, "no new client")
        assertEquals(2, client.calls.count { it == "checkHealth" }, "one fresh probe on the live client")
    }

    @Test
    fun reuseRebindsAnInactiveUserWithoutClosingTheActiveOne() = runTest {
        val h = ManagerHarness(this)
        val userA = h.addJellyfin("user-a")
        val userB = h.addJellyfin("user-b")
        assertSame(userB, h.manager.client(jf))
        val emitted = collected(h.manager.statusUpdates)

        h.manager.addMediaBrowserConnection(FakeMediaBrowserConnection("jf-machine", "user-a"))
        runCurrent()

        assertSame(userA, h.manager.client(jf))
        assertSame(userA, h.manager.mediaBrowserClient("jf-machine/user-a"))
        assertSame(userB, h.manager.mediaBrowserClient("jf-machine/user-b"))
        assertEquals(0, userB.closed)
        assertEquals(1, emitted.size, "the swap of the active user is published")
    }

    @Test
    fun aScopedLookupResolvesOnlyTheExactUser() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val plexId = ServerId("plex-1")
        m.refreshTokensForProfile(FakePlexAccount("account", listOf(plexServer("plex-1"))), "profile-a")
        val plexClient = h.plex.clients.getValue(plexId)
        val userA = h.addJellyfin("user-a")
        h.addJellyfin("user-b")

        assertSame(plexClient, m.clientByScope(scope("plex-1", "profile-a").value))
        assertNull(m.clientByScope(scope("plex-1", "profile-b").value))
        assertSame(userA, m.clientByScope("jf-machine/user-a"))
        m.updateServerStatus(jf, false)
        assertTrue(m.isClientOnline(jf, "jf-machine/user-a"), "user A's own last probe, not the machine's status")
        assertFalse(m.isClientOnline(jf))
        assertNull(m.resolveDownloadClient(plexId, "jf-machine/user-a"), "a scope of another server")
        assertSame(userA, m.resolveDownloadClient(jf, "jf-machine/user-a"))

        m.setVisibleServerIds(setOf(jf))
        assertNull(m.resolveDownloadClient(plexId), "hidden from the profile")
    }

    @Test
    fun ownershipFollowsThePlexServersOwnedFlag() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val owned = plexServer("owned")
        val shared = FakePlexServer("shared", mapOf(localEndpoint("shared") to EndpointNetworkClass.LOCAL), races = listOf(raceOf(localEndpoint("shared"))), owned = false)
        m.refreshTokensForProfile(FakePlexAccount("account", listOf(owned, shared)), "profile-a")

        assertTrue(m.isOwnerOrAdmin(ServerId("owned")))
        assertFalse(m.isOwnerOrAdmin(ServerId("shared")))
        assertFalse(m.isOwnerOrAdmin(ServerId("unknown")))
    }

    @Test
    fun anAuthErrorMarksEveryAccountServerRefusedDropsOtherProfilesAndEmitsOnce() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val one = ServerId("server-1")
        val two = ServerId("server-2")
        m.refreshTokensForProfile(FakePlexAccount("account", listOf(plexServer("server-1"))), "profile-b")
        val otherProfiles = h.plex.clients.getValue(one)
        val emitted = collected(m.statusUpdates)

        m.markPlexConnectionAuthError(FakePlexAccount("account", listOf(plexServer("server-1"), plexServer("server-2"))), "profile-a")
        runCurrent()

        assertEquals(1, otherProfiles.closed)
        assertNull(m.client(one))
        assertNull(m.client(two))
        assertFalse(m.isRegisteredForOtherProfile(one, "profile-a"))
        assertEquals(setOf(one, two), m.offlineServerIds.toSet())
        assertEquals(setOf(one, two), m.authErrorServerIds)
        assertEquals(listOf(status("server-1" to false, "server-2" to false)), emitted)
    }

    @Test
    fun aServerRunsOneReconnectTaskAtATime() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val a = ServerId("server-a")
        val b = ServerId("server-b")
        val gate = CompletableDeferred<Unit>()
        fun gatedServer(id: String): FakePlexServer {
            val url = localEndpoint(id)
            val gatedRace = {
                flow {
                    gate.await()
                    emit(RacedEndpoint(url, transcoderVideo = true))
                }
            }
            return FakePlexServer(id, mapOf(url to EndpointNetworkClass.LOCAL), races = listOf(raceOf(url), gatedRace))
        }
        val serverA = gatedServer("server-a")
        val serverB = gatedServer("server-b")
        m.refreshTokensForProfile(FakePlexAccount("account", listOf(serverA, serverB)), "profile-a")
        fun exhaust(id: ServerId) = h.plex.calls.last { it.serverId == id }.events.onAllEndpointsExhausted()
        h.plex.clients.getValue(a).health = { HealthStatus.OFFLINE }
        h.plex.clients.getValue(b).health = { HealthStatus.OFFLINE }
        m.updateServerStatus(a, false)

        val reconnect = async { m.reconnectOfflineServers() }
        runCurrent()
        assertEquals(2, serverA.raceCalls, "the bind and the running reconnect")

        exhaust(a)
        exhaust(b)
        advanceTimeBy(6.seconds)
        assertEquals(2, serverA.raceCalls, "a second task for a busy server does not run")
        assertEquals(2, serverB.raceCalls, "another server still runs its own")

        gate.complete(Unit)
        reconnect.await()
        runCurrent()
        exhaust(a)
        advanceTimeBy(6.seconds)
        assertEquals(3, serverA.raceCalls, "free again once the first task ended")
    }

    @Test
    fun concurrentReconnectsShareOnePassAndAHangingServerIsCutAt15Seconds() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val hangs = FakePlexServer(
            "hangs",
            mapOf(localEndpoint("hangs") to EndpointNetworkClass.LOCAL),
            races = listOf(raceOf(localEndpoint("hangs")), { flow { awaitCancellation() } }),
        )
        val returns = plexServer("returns")
        m.refreshTokensForProfile(FakePlexAccount("account", listOf(hangs, returns)), "profile-a")
        m.updateServerStatus(ServerId("hangs"), false)
        m.updateServerStatus(ServerId("returns"), false)
        val start = currentTime

        val first = async { m.reconnectOfflineServers() }
        val second = async { m.reconnectOfflineServers() }
        runCurrent()
        assertEquals(2, hangs.raceCalls, "the bind and one shared pass")
        assertTrue(m.isServerOnline(ServerId("returns")))

        first.await()
        second.await()
        assertEquals(15.seconds.inWholeMilliseconds, currentTime - start)
        assertFalse(m.isServerOnline(ServerId("hangs")))
    }

    @Test
    fun aForcedReconnectForgetsOnlyOfflineServersPreferredEndpoints() = runTest {
        val h = ManagerHarness(this)
        val m = h.manager
        val offline = FakePlexServer(
            "offline",
            mapOf(localEndpoint("offline") to EndpointNetworkClass.LOCAL),
            races = listOf(raceOf(localEndpoint("offline")), { emptyFlow() }),
        )
        m.refreshTokensForProfile(FakePlexAccount("account", listOf(offline, plexServer("online"))), "profile-a")
        runCurrent()
        assertEquals(localEndpoint("offline"), h.endpoints.saved[ServerId("offline")])
        assertEquals(localEndpoint("online"), h.endpoints.saved[ServerId("online")])
        m.updateServerStatus(ServerId("offline"), false)

        m.reconnectOfflineServers(forceRediscovery = true)

        assertNull(h.endpoints.saved[ServerId("offline")])
        assertEquals(localEndpoint("online"), h.endpoints.saved[ServerId("online")])
    }

    // Removal and teardown.

    @Test
    fun removingATrackedServerEmitsTheRest() = runTest {
        val m = ManagerHarness(this).manager
        m.updateServerStatus(ServerId("srv-1"), true)
        m.updateServerStatus(ServerId("srv-2"), true)
        val emitted = collected(m.statusUpdates)

        m.removeServer(ServerId("srv-1"))
        runCurrent()

        assertEquals(status("srv-2" to true), emitted.last())
    }

    @Test
    fun removingAnUnknownIdStillEmitsASnapshot() = runTest {
        val m = ManagerHarness(this).manager
        val emitted = collected(m.statusUpdates)

        m.removeServer(ServerId("never-added"))
        runCurrent()

        assertTrue(m.serverIds.isEmpty())
        assertEquals(listOf(emptyMap()), emitted)
    }

    @Test
    fun removingAJellyfinMachineClosesEveryUserClient() = runTest {
        val h = ManagerHarness(this)
        val userA = h.addJellyfin("user-a")
        val userB = h.addJellyfin("user-b")

        h.manager.removeServer(jf)
        runCurrent()

        assertNull(h.manager.client(jf))
        assertNull(h.manager.mediaBrowserClient("jf-machine/user-a"))
        assertNull(h.manager.mediaBrowserClient("jf-machine/user-b"))
        assertEquals(1, userA.closed)
        assertEquals(1, userB.closed)
    }

    @Test
    fun disconnectAllClearsTheStatusAndEmitsAnEmptySnapshot() = runTest {
        val m = ManagerHarness(this).manager
        m.updateServerStatus(ServerId("a"), true)
        m.updateServerStatus(ServerId("b"), false)
        val emitted = collected(m.statusUpdates)

        m.disconnectAll()
        runCurrent()

        assertTrue(m.serverIds.isEmpty())
        assertTrue(m.onlineServerIds.isEmpty())
        assertTrue(m.offlineServerIds.isEmpty())
        assertEquals(emptyMap(), emitted.last())
    }

    @Test
    fun disconnectAllClosesInactiveUserClients() = runTest {
        val h = ManagerHarness(this)
        val userA = h.addJellyfin("user-a")
        val userB = h.addJellyfin("user-b")

        h.manager.disconnectAll()
        runCurrent()

        assertNull(h.manager.client(jf))
        assertNull(h.manager.mediaBrowserClient("jf-machine/user-a"))
        assertNull(h.manager.mediaBrowserClient("jf-machine/user-b"))
        assertEquals(1, userA.closed)
        assertEquals(1, userB.closed)
    }

    @Test
    fun shutdownClearsEverythingWithoutASnapshotAndCompletesTheFlow() = runTest {
        val m = ManagerHarness(this).manager
        m.updateServerStatus(ServerId("a"), true)
        m.updateServerStatus(ServerId("b"), false)
        val emitted = mutableListOf<Map<ServerId, Boolean>>()
        val collector = backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { m.statusUpdates.collect { emitted += it } }

        m.shutdown()
        runCurrent()

        // An empty snapshot would flip the still-visible UI to offline while the app exits.
        assertTrue(m.serverIds.isEmpty())
        assertTrue(m.onlineServerIds.isEmpty())
        assertTrue(m.offlineServerIds.isEmpty())
        assertEquals(emptyList(), emitted)
        assertTrue(collector.isCompleted)
    }

    @Test
    fun disconnectingGivesTheClientsTwoSecondsToDrainAndShuttingDownFive() = runTest {
        val h = ManagerHarness(this)
        val disconnected = h.addJellyfin("user-a")
        h.manager.disconnectAll()
        runCurrent()
        assertEquals(listOf(2.seconds), disconnected.drains)

        val shutDown = h.addJellyfin("user-b")
        h.manager.shutdown()
        assertEquals(listOf(5.seconds), shutDown.drains)
    }

    @Test
    fun aHealthResultLandingAfterShutdownIsASilentNoOp() = runTest {
        val m = ManagerHarness(this).manager
        m.updateServerStatus(ServerId("a"), true)
        m.shutdown()

        m.updateServerStatus(ServerId("a"), false)
    }

    @Test
    fun disposeCompletesTheStatusFlowForItsCollectors() = runTest {
        val m = ManagerHarness(this).manager
        val collector = backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { m.statusUpdates.collect { } }

        m.dispose()
        runCurrent()

        assertTrue(collector.isCompleted)
    }
}

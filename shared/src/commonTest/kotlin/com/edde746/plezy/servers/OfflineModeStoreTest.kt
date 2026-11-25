@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.edde746.plezy.servers

import com.edde746.plezy.backend.HealthStatus
import com.edde746.plezy.model.ServerId
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class OfflineModeStoreTest {
    private class FakeConnectivity : ConnectivitySource {
        var reported: Connectivity = Connectivity.NOT_REPORTED
        override val changes = MutableSharedFlow<Connectivity>(extraBufferCapacity = 16)

        override suspend fun current(): Connectivity = reported
    }

    private class Setup(
        val h: ManagerHarness,
        val servers: MultiServerStore?,
        val connectivity: FakeConnectivity,
        val binding: MutableStateFlow<Boolean>,
        val offline: OfflineModeStore,
    )

    private suspend fun TestScope.setup(withProfile: Boolean, prepare: suspend (ManagerHarness) -> Unit = {}): Setup {
        val h = ManagerHarness(this)
        prepare(h)
        val servers = if (withProfile) MultiServerStore(h.manager, { emptyList() }, backgroundScope) else null
        val connectivity = FakeConnectivity()
        val binding = MutableStateFlow(false)
        return Setup(h, servers, connectivity, binding, OfflineModeStore(h.manager, servers, ConnectivityProbe(connectivity), binding, backgroundScope))
    }

    /** A profile with no servers bound: no profile yet (a first run) or the sign-in screen after a sign-out. */
    private fun TestScope.boundToNothing(s: Setup) {
        s.servers!!.setExpectedVisibleServerIds(emptySet())
        s.servers.setVisibleServerIds(emptySet())
        runCurrent()
        assertEquals(OfflineModeReason.NO_KNOWN_VISIBLE_SERVERS, s.offline.state.value.reason)
    }

    /** The state changes after this call (the current state excluded). */
    private fun <T> TestScope.changes(flow: Flow<T>): MutableList<T> {
        val list = mutableListOf<T>()
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { flow.collect { list += it } }
        list.clear()
        return list
    }

    @Test
    fun anEmptyManagerKeepsTheAppOnlineDuringWarmUp() = runTest {
        val s = setup(withProfile = false)
        val state = s.offline.state.value

        // Until the first status snapshot nobody knows whether the bind will connect anything: no offline flash.
        assertTrue(state.connectivity.hasNetwork)
        assertEquals(OfflineModeReason.WAITING_FOR_SERVER_STATUS, state.reason)
        assertFalse(s.offline.isOffline.value)
    }

    @Test
    fun aServerAlreadyOnlineAtConstructionSkipsTheWarmUp() = runTest {
        // A known server (one with a client) already online: no warm-up window.
        val s = setup(withProfile = false) { it.addJellyfin("user-a") }

        assertEquals(OfflineModeReason.ONLINE, s.offline.state.value.reason)
        assertFalse(s.offline.isOffline.value)
    }

    @Test
    fun serversAllOfflineAtConstructionStayWarmUpOptimisticUntilAStatusArrives() = runTest {
        val s = setup(withProfile = false) {
            it.manager.updateServerStatus(ServerId("srv-1"), false)
            it.manager.updateServerStatus(ServerId("srv-2"), false)
        }

        assertEquals(OfflineModeReason.WAITING_FOR_SERVER_STATUS, s.offline.state.value.reason)
        assertFalse(s.offline.isOffline.value)
    }

    @Test
    fun afterDisposeTheStateNoLongerMoves() = runTest {
        val s = setup(withProfile = false)
        s.offline.initialize()

        s.offline.dispose()
        s.h.manager.updateServerStatus(ServerId("srv-1"), false)
        runCurrent()

        assertEquals(OfflineModeReason.WAITING_FOR_SERVER_STATUS, s.offline.state.value.reason)
    }

    @Test
    fun refusedOnlyVisibleServersDoNotCollapseToGenericOffline() = runTest {
        for (refusal in listOf(HealthStatus.AUTH_ERROR, HealthStatus.ACCESS_DENIED)) {
            val s = setup(withProfile = true)
            s.offline.initialize()

            s.h.addJellyfin("user-a", health = refusal)
            runCurrent()

            assertEquals(listOf(ServerId("jf-machine")), s.servers!!.state.value.refusedServerIds, "$refusal")
            assertEquals(OfflineModeReason.ONLY_REFUSED_SERVERS, s.offline.state.value.reason, "$refusal")
            assertFalse(s.offline.isOffline.value, "$refusal")
            s.offline.dispose()
            s.servers.dispose()
            s.h.manager.dispose()
        }
    }

    @Test
    fun expectedButUnreachableVisibleServersEnterOfflineWithoutLiveClients() = runTest {
        val s = setup(withProfile = true)
        val servers = s.servers!!
        s.offline.initialize()
        s.h.manager.updateServerStatus(ServerId("plex-server"), false)
        runCurrent()
        assertFalse(s.offline.isOffline.value)
        val changes = changes(s.offline.state)

        servers.setExpectedVisibleServerIds(setOf(ServerId("plex-server")))
        servers.setVisibleServerIds(emptySet())
        runCurrent()

        assertTrue(s.offline.isOffline.value)
        assertEquals(1, changes.size)
    }

    @Test
    fun expectedButUnreachableProfileServersEnterOfflineOnceVisibilitySettles() = runTest {
        val s = setup(withProfile = true)
        val servers = s.servers!!
        assertFalse(s.offline.isOffline.value)
        val changes = changes(s.offline.state)

        servers.setExpectedVisibleServerIds(setOf(ServerId("jf-machine")))
        runCurrent()
        assertFalse(s.offline.isOffline.value)
        assertEquals(0, changes.size)

        servers.setVisibleServerIds(emptySet())
        runCurrent()
        assertTrue(s.offline.isOffline.value)
        assertEquals(1, changes.size)
    }

    @Test
    fun plexAuthErrorsWithoutLiveClientsStayOutOfGenericOffline() = runTest {
        val s = setup(withProfile = true)
        val servers = s.servers!!
        s.offline.initialize()

        servers.setExpectedVisibleServerIds(setOf(ServerId("plex-server")))
        s.h.manager.markPlexConnectionAuthError(
            FakePlexAccount("plex-account", listOf(FakePlexServer("plex-server", mapOf(localEndpoint("plex") to EndpointNetworkClass.LOCAL)))),
            "profile-a",
        )
        runCurrent()

        assertEquals(listOf(ServerId("plex-server")), servers.state.value.authErrorServerIds)
        assertEquals("plex-server", servers.state.value.authErrorServers.single().displayName)
        assertFalse(s.offline.isOffline.value)
    }

    // Connecting.

    @Test
    fun aSignInShowsNoOfflineWhileItsServerConnects() = runTest {
        val s = setup(withProfile = true)
        s.offline.initialize()
        boundToNothing(s)
        val changes = changes(s.offline.state)

        // The sign-in's bind: the new server is expected before its first connection attempt has answered.
        s.binding.value = true
        runCurrent()
        s.servers!!.setExpectedVisibleServerIds(setOf(ServerId("jf-machine")))
        runCurrent()
        assertEquals(OfflineModeReason.WAITING_FOR_SERVER_STATUS, s.offline.state.value.reason)

        s.h.addJellyfin("user-a")
        s.servers.setVisibleServerIds(setOf(ServerId("jf-machine")))
        s.binding.value = false
        runCurrent()

        assertEquals(OfflineModeReason.ONLINE, s.offline.state.value.reason)
        assertTrue(changes.none { it.isOffline })
    }

    @Test
    fun aSignInWhoseServerFailsGoesOfflineOnceItsBindSettles() = runTest {
        val s = setup(withProfile = true)
        s.offline.initialize()
        boundToNothing(s)

        s.binding.value = true
        runCurrent()
        s.servers!!.setExpectedVisibleServerIds(setOf(ServerId("jf-machine")))
        s.h.addJellyfin("user-a", health = HealthStatus.OFFLINE)
        s.servers.setVisibleServerIds(emptySet())
        runCurrent()
        assertFalse(s.offline.isOffline.value, "still connecting")

        s.binding.value = false
        runCurrent()
        assertTrue(s.offline.isOffline.value)
    }

    @Test
    fun aBindStartedOfflineKeepsTheAppOfflineUntilAServerConnects() = runTest {
        val s = setup(withProfile = true)
        s.offline.initialize()
        s.servers!!.setExpectedVisibleServerIds(setOf(ServerId("jf-machine")))
        val client = s.h.addJellyfin("user-a", health = HealthStatus.OFFLINE)
        s.servers.setVisibleServerIds(emptySet())
        runCurrent()
        assertTrue(s.offline.isOffline.value)
        val changes = changes(s.offline.state)

        // Reconnect binds the profile again: the app it started offline stays offline while it runs.
        s.binding.value = true
        runCurrent()
        assertTrue(s.offline.isOffline.value)
        assertEquals(0, changes.size)

        client.health = { HealthStatus.ONLINE }
        s.h.manager.updateServerStatus(ServerId("jf-machine"), true)
        runCurrent()
        assertFalse(s.offline.isOffline.value)
    }

    // Connectivity.

    @Test
    fun regainingAnyNetworkMovesTheStateWhileServersStayUnreachable() = runTest {
        val s = setup(withProfile = true)
        val servers = s.servers!!
        s.connectivity.reported = Connectivity.of(ConnectivityLink.NONE)
        s.offline.initialize()
        // Visibility settled with nothing reachable: offline is owned by the servers, not the network or the warm-up.
        servers.setExpectedVisibleServerIds(setOf(ServerId("plex-server")))
        servers.setVisibleServerIds(setOf(ServerId("plex-server")))
        runCurrent()
        assertFalse(s.offline.state.value.connectivity.hasNetwork)
        assertTrue(s.offline.isOffline.value)
        val changes = changes(s.offline.state)

        // Cellular returns, no server is reachable: consumers that only need the internet still hear it.
        s.connectivity.changes.emit(Connectivity.of(ConnectivityLink.MOBILE))
        runCurrent()

        val state = s.offline.state.value
        assertTrue(state.connectivity.hasNetwork)
        assertFalse(state.hasWifiOrEthernet)
        assertTrue(state.isOffline, "servers are still unreachable")
        assertEquals(1, changes.size)
    }

    @Test
    fun aReachableServerKeepsTheAppOnlineWhileTheOsReportsNoNetwork() = runTest {
        val s = setup(withProfile = true)
        val servers = s.servers!!
        s.offline.initialize()
        servers.setExpectedVisibleServerIds(setOf(ServerId("loopback-server")))
        servers.setVisibleServerIds(setOf(ServerId("loopback-server")))
        s.h.manager.updateServerStatus(ServerId("loopback-server"), true)
        runCurrent()
        assertFalse(s.offline.isOffline.value)
        val changes = changes(s.offline.state)

        // A server on 127.0.0.1, or on a LAN without internet, stays reachable when the OS reports no network.
        s.connectivity.changes.emit(Connectivity.of(ConnectivityLink.NONE))
        runCurrent()
        assertFalse(s.offline.state.value.connectivity.hasNetwork)
        assertFalse(s.offline.isOffline.value)
        assertEquals(1, changes.size, "internet-only consumers still hear the loss")

        // Only the server becoming unreachable takes the app offline.
        s.h.manager.updateServerStatus(ServerId("loopback-server"), false)
        runCurrent()
        assertTrue(s.offline.isOffline.value)
    }

    @Test
    fun anUnchangedConnectivityReportChangesNothing() = runTest {
        val s = setup(withProfile = false)
        s.offline.initialize()
        s.connectivity.changes.emit(Connectivity.of(ConnectivityLink.WIFI))
        runCurrent()
        val changes = changes(s.offline.state)

        s.connectivity.changes.emit(Connectivity.of(ConnectivityLink.WIFI))
        runCurrent()

        assertEquals(0, changes.size)
    }

    @Test
    fun cellularOnlyHoldsOnlyForCellularWithoutWifiOrEthernet() = runTest {
        val s = setup(withProfile = false)
        // Not reported yet: not cellular, so playback keeps the general default quality.
        assertFalse(s.offline.state.value.isCellularOnly)
        s.offline.initialize()

        suspend fun report(vararg links: ConnectivityLink): Boolean {
            s.connectivity.changes.emit(Connectivity.of(*links))
            runCurrent()
            return s.offline.state.value.isCellularOnly
        }

        assertTrue(report(ConnectivityLink.MOBILE))
        assertFalse(report(ConnectivityLink.MOBILE, ConnectivityLink.WIFI))
        assertFalse(report(ConnectivityLink.MOBILE, ConnectivityLink.ETHERNET))
        assertFalse(report(ConnectivityLink.WIFI))
        assertFalse(report(ConnectivityLink.NONE))
    }
}

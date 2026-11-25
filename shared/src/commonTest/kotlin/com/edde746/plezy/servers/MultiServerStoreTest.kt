@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.edde746.plezy.servers

import com.edde746.plezy.backend.HealthStatus
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.model.ServerId
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue

class MultiServerStoreTest {
    private val srv1 = ServerId("srv-1")
    private val srv2 = ServerId("srv-2")

    private fun <T> TestScope.collected(flow: Flow<T>): MutableList<T> {
        val list = mutableListOf<T>()
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { flow.collect { list += it } }
        return list
    }

    private class LiveTvScript {
        var failure: Exception? = null
        var duringProbe: (suspend () -> Unit)? = null
        val answer: suspend (MediaBackend) -> List<LiveTvServerEntry> = { client ->
            duringProbe?.let {
                duringProbe = null
                it()
            }
            failure?.let { throw it }
            listOf(LiveTvServerEntry(client.serverId, "dvr-${client.serverId}"))
        }
    }

    private fun TestScope.store(h: ManagerHarness, liveTv: LiveTvScript = LiveTvScript()) =
        MultiServerStore(h.manager, liveTv.answer, backgroundScope)

    @Test
    fun startsWithNoServersAndNoLiveTv() = runTest {
        val state = store(ManagerHarness(this)).state.value
        assertTrue(state.serverIds.isEmpty())
        assertTrue(state.onlineServerIds.isEmpty())
        assertEquals(0, state.onlineServerCount)
        assertEquals(0, state.totalServerCount)
        assertFalse(state.hasConnectedServers)
        assertFalse(state.hasLiveTv)
        assertTrue(state.liveTvServers.isEmpty())
    }

    @Test
    fun unknownIdsAreOfflineWithNoClient() = runTest {
        val store = store(ManagerHarness(this))
        assertFalse(store.state.value.isServerOnline(ServerId("nope")))
        assertNull(store.client(ServerId("nope")))
    }

    @Test
    fun followsTheManagersStatus() = runTest {
        val h = ManagerHarness(this)
        val store = store(h)

        h.manager.updateServerStatus(srv1, true)
        runCurrent()

        assertEquals(listOf(srv1), store.state.value.onlineServerIds)
    }

    @Test
    fun onlineServerChangesCarryTheVisibilityFilteredOnlineSet() = runTest {
        val h = ManagerHarness(this)
        val store = store(h)
        val calls = collected(store.onlineServersChanges)

        h.manager.updateServerStatus(srv1, true)
        runCurrent()
        assertEquals(setOf(srv1), calls.last())

        // Online in the manager, outside the profile's filter: not in the payload.
        store.setVisibleServerIds(setOf(srv1))
        h.manager.updateServerStatus(srv2, true)
        runCurrent()
        assertEquals(setOf(srv1), calls.last())
    }

    @Test
    fun eachStatusSnapshotReachesEachCollectorOnce() = runTest {
        val h = ManagerHarness(this)
        val store = store(h)
        val calls = collected(store.onlineServersChanges)

        h.manager.updateServerStatus(srv1, true)
        runCurrent()

        assertEquals(1, calls.size)
    }

    @Test
    fun setVisibleServerIdsReplacesTheFilterAndIgnoresAnEqualSet() = runTest {
        val store = store(ManagerHarness(this))
        val states = collected(store.state)
        assertFalse(store.state.value.hasExplicitVisibleServerFilter)

        // Empty is a filter, unlike null: the profile has servers, none of them visible.
        store.setVisibleServerIds(emptySet())
        runCurrent()
        assertEquals(2, states.size)
        assertTrue(store.state.value.hasExplicitVisibleServerFilter)

        store.setVisibleServerIds(setOf(ServerId("a"), ServerId("b")))
        runCurrent()
        assertEquals(3, states.size)

        store.setVisibleServerIds(setOf(ServerId("b"), ServerId("a")))
        runCurrent()
        assertEquals(3, states.size)

        store.setVisibleServerIds(null)
        runCurrent()
        assertEquals(4, states.size)
        assertFalse(store.state.value.hasExplicitVisibleServerFilter)
    }

    @Test
    fun expectedServersAreCopiedAndAnEqualSetIsIgnored() = runTest {
        val store = store(ManagerHarness(this))
        val states = collected(store.state)
        val expected = mutableSetOf(ServerId("a"), ServerId("b"))

        store.setExpectedVisibleServerIds(expected)
        expected += ServerId("c")
        store.setExpectedVisibleServerIds(setOf(ServerId("b"), ServerId("a")))
        runCurrent()

        assertEquals(2, states.size)
        assertEquals(setOf(ServerId("a"), ServerId("b")), store.state.value.expectedServerIds.toSet())
    }

    @Test
    fun onlineServerIdsRespectTheVisibilityFilter() = runTest {
        val h = ManagerHarness(this)
        val store = store(h)
        h.manager.updateServerStatus(srv1, true)
        h.manager.updateServerStatus(srv2, true)
        h.manager.updateServerStatus(ServerId("srv-3"), false)
        runCurrent()
        assertEquals(setOf(srv1, srv2), store.state.value.onlineServerIds.toSet())

        store.setVisibleServerIds(setOf(srv1))
        assertEquals(listOf(srv1), store.state.value.onlineServerIds)
        assertFalse(store.state.value.isServerOnline(srv2), "filtered out though the manager reports it online")

        store.setVisibleServerIds(emptySet())
        assertTrue(store.state.value.onlineServerIds.isEmpty())
    }

    @Test
    fun setVisibleServerIdsHidesLiveTvOutsideTheFilterAtOnce() = runTest {
        val h = ManagerHarness(this)
        h.addJellyfin("u", machineId = "srv-1")
        h.addJellyfin("u", machineId = "srv-2")
        val store = store(h)
        store.checkLiveTvAvailability()
        assertEquals(setOf(srv1, srv2), store.state.value.liveTvServers.map { it.serverId }.toSet())

        store.setVisibleServerIds(setOf(srv1))

        assertTrue(store.state.value.hasLiveTv)
        assertEquals(listOf(LiveTvServerEntry(srv1, "dvr-srv-1")), store.state.value.liveTvServers)
    }

    @Test
    fun anEmptyVisibilityFilterClearsLiveTvAtOnce() = runTest {
        val h = ManagerHarness(this)
        h.addJellyfin("u", machineId = "srv-1")
        val store = store(h)
        store.checkLiveTvAvailability()
        assertTrue(store.state.value.hasLiveTv)

        store.setVisibleServerIds(emptySet())

        assertFalse(store.state.value.hasLiveTv)
        assertTrue(store.state.value.liveTvServers.isEmpty())
    }

    /** Live TV is known once every online server was asked: none online is nothing to ask. */
    @Test
    fun liveTvIsCheckedOnceEveryOnlineServerWasAsked() = runTest {
        assertTrue(store(ManagerHarness(this)).state.value.liveTvChecked)
        val h = ManagerHarness(this)
        h.addJellyfin("u", machineId = "srv-1")
        val store = store(h)
        assertFalse(store.state.value.liveTvChecked)
        store.checkLiveTvAvailability()
        assertTrue(store.state.value.liveTvChecked)
    }

    @Test
    fun expectedServersBecomeVisibleWhenTheyReconnect() = runTest {
        val h = ManagerHarness(this)
        val store = store(h)
        val onlineCalls = collected(store.onlineServersChanges)
        store.setVisibleServerIds(setOf(srv1))
        store.setExpectedVisibleServerIds(setOf(srv1, srv2))

        h.manager.updateServerStatus(srv1, true)
        runCurrent()
        assertEquals(listOf(srv1), store.state.value.onlineServerIds)

        h.manager.updateServerStatus(srv2, true)
        runCurrent()
        assertEquals(listOf(srv1, srv2), store.state.value.onlineServerIds)
        assertTrue(store.state.value.isServerOnline(srv2))
        assertEquals(setOf(srv1, srv2), onlineCalls.last())
    }

    @Test
    fun refusalsAreListedForTheExpectedServersWithTheirNames() = runTest {
        val h = ManagerHarness(this)
        val store = store(h)
        val account = FakePlexAccount(
            "plex-account",
            listOf(
                FakePlexServer("plex-server", mapOf(localEndpoint("plex") to EndpointNetworkClass.LOCAL)),
                FakePlexServer("other-server", mapOf(localEndpoint("other") to EndpointNetworkClass.LOCAL)),
            ),
        )
        store.setExpectedVisibleServerIds(setOf(ServerId("plex-server")))
        h.addJellyfin("u", machineId = "denied", health = HealthStatus.ACCESS_DENIED)

        h.manager.markPlexConnectionAuthError(account, "profile-a")
        runCurrent()

        val state = store.state.value
        assertEquals(listOf(NamedServer(ServerId("plex-server"), "plex-server")), state.authErrorServers)
        assertTrue(state.accessDeniedServers.isEmpty(), "not one of the profile's servers")
        assertEquals(listOf(ServerId("plex-server")), state.refusedServerIds)
    }

    // Live TV re-probe failures.

    private suspend fun TestScope.storeWithFoundDvr(h: ManagerHarness, liveTv: LiveTvScript): Pair<MultiServerStore, FakeMediaBrowserClient> {
        val client = h.addJellyfin("u", machineId = "srv-1")
        val store = store(h, liveTv)
        store.checkLiveTvAvailability()
        assertEquals(listOf("dvr-srv-1"), store.state.value.liveTvServers.map { it.dvrKey })
        return store to client
    }

    private fun httpFailure(status: Int) = MediaServerHttpException(MediaServerHttpErrorType.UNKNOWN, "failed", statusCode = status)

    @Test
    fun aTransientFailureKeepsTheDvrTheLastCheckFound() = runTest {
        val liveTv = LiveTvScript()
        val (store, _) = storeWithFoundDvr(ManagerHarness(this), liveTv)

        liveTv.failure = httpFailure(503)
        store.checkLiveTvAvailability()

        assertTrue(store.state.value.hasLiveTv)
        assertEquals(listOf("dvr-srv-1"), store.state.value.liveTvServers.map { it.dvrKey })
    }

    @Test
    fun aTimeoutKeepsTheDvrTheLastCheckFound() = runTest {
        val liveTv = LiveTvScript()
        val (store, _) = storeWithFoundDvr(ManagerHarness(this), liveTv)

        liveTv.failure = MediaServerHttpException(MediaServerHttpErrorType.CONNECTION_TIMEOUT, "timed out")
        store.checkLiveTvAvailability()

        assertTrue(store.state.value.hasLiveTv)
    }

    @Test
    fun anAuthorizationFailureDropsTheDvr() = runTest {
        val liveTv = LiveTvScript()
        val (store, _) = storeWithFoundDvr(ManagerHarness(this), liveTv)

        liveTv.failure = httpFailure(403)
        store.checkLiveTvAvailability()

        assertFalse(store.state.value.hasLiveTv)
        assertTrue(store.state.value.liveTvServers.isEmpty())
    }

    @Test
    fun aTransientFailureOnAReplacedClientDropsTheDvr() = runTest {
        val h = ManagerHarness(this)
        val liveTv = LiveTvScript()
        val (store, _) = storeWithFoundDvr(h, liveTv)

        liveTv.failure = httpFailure(503)
        h.addJellyfin("u", machineId = "srv-1", accessToken = "rotated")
        store.checkLiveTvAvailability()

        assertFalse(store.state.value.hasLiveTv)
        assertTrue(store.state.value.liveTvServers.isEmpty())
    }

    @Test
    fun aTransientFailureAfterAnInPlaceProfileSwitchDropsTheDvr() = runTest {
        val liveTv = LiveTvScript()
        val (store, client) = storeWithFoundDvr(ManagerHarness(this), liveTv)

        client.authenticationSessionId = Any()
        liveTv.failure = httpFailure(503)
        store.checkLiveTvAvailability()

        assertFalse(store.state.value.hasLiveTv)
        assertTrue(store.state.value.liveTvServers.isEmpty())
    }

    @Test
    fun aProbeAnsweredAcrossAnInPlaceProfileSwitchIsDiscarded() = runTest {
        val liveTv = LiveTvScript()
        val (store, client) = storeWithFoundDvr(ManagerHarness(this), liveTv)

        liveTv.duringProbe = { client.authenticationSessionId = Any() }
        store.checkLiveTvAvailability()
        assertFalse(store.state.value.hasLiveTv)
        assertTrue(store.state.value.liveTvServers.isEmpty())

        // The new session's own failed probe cannot bring the previous session's DVR back.
        liveTv.failure = httpFailure(503)
        store.checkLiveTvAvailability()
        assertTrue(store.state.value.liveTvServers.isEmpty())
    }

    // Live TV after an in-place Plex Home switch: the server answers by user, only token-dvr has Live TV.

    private class PlexHomeLiveTv {
        val probedTokens = mutableListOf<String>()
        var refuseOthers = false
        val answer: suspend (MediaBackend) -> List<LiveTvServerEntry> = { client ->
            val token = (client as FakePlexClient).token
            probedTokens += token
            when {
                token == "token-dvr" -> listOf(LiveTvServerEntry(client.serverId, "dvr-1"))
                refuseOthers -> throw MediaServerHttpException(MediaServerHttpErrorType.UNKNOWN, "refused", statusCode = 403)
                else -> emptyList()
            }
        }
    }

    private fun homeServer(token: String) =
        FakePlexServer("srv-1", mapOf(localEndpoint("srv-1") to EndpointNetworkClass.LOCAL), races = listOf(raceOf(localEndpoint("srv-1"))), accessToken = token)

    /** Binds the Plex server as [profileId]: the first bind connects, later ones switch the online client in place. */
    private suspend fun TestScope.bindAs(h: ManagerHarness, profileId: String, token: String) {
        assertEquals(setOf(srv1), h.manager.refreshTokensForProfile(FakePlexAccount("account", listOf(homeServer(token))), profileId))
        runCurrent()
    }

    @Test
    fun switchingToAUserWithoutLiveTvHidesIt() = runTest {
        val h = ManagerHarness(this)
        val store = MultiServerStore(h.manager, PlexHomeLiveTv().answer, backgroundScope)
        bindAs(h, "profile-a", "token-dvr")
        assertTrue(store.state.value.hasLiveTv)
        val client = h.manager.client(srv1)

        bindAs(h, "profile-b", "token-no-dvr")

        assertSame(client, h.manager.client(srv1), "switched in place")
        assertFalse(store.state.value.hasLiveTv)
        assertTrue(store.state.value.liveTvServers.isEmpty())
    }

    @Test
    fun switchingToAUserWithLiveTvShowsIt() = runTest {
        val h = ManagerHarness(this)
        val store = MultiServerStore(h.manager, PlexHomeLiveTv().answer, backgroundScope)
        bindAs(h, "profile-a", "token-no-dvr")
        assertFalse(store.state.value.hasLiveTv)

        bindAs(h, "profile-b", "token-dvr")

        assertTrue(store.state.value.hasLiveTv)
        assertEquals(listOf("dvr-1"), store.state.value.liveTvServers.map { it.dvrKey })
    }

    @Test
    fun aRefusedUserIsNotAskedAgainOnEveryStatusChange() = runTest {
        val h = ManagerHarness(this)
        val liveTv = PlexHomeLiveTv().apply { refuseOthers = true }
        val store = MultiServerStore(h.manager, liveTv.answer, backgroundScope)
        bindAs(h, "profile-a", "token-dvr")
        bindAs(h, "profile-b", "token-no-dvr")
        assertFalse(store.state.value.hasLiveTv)
        val probes = liveTv.probedTokens.size

        h.manager.updateServerStatus(srv2, false)
        runCurrent()

        assertEquals(probes, liveTv.probedTokens.size)
    }

    @Test
    fun disposeStopsFollowingTheManager() = runTest {
        val h = ManagerHarness(this)
        val store = store(h)
        h.manager.updateServerStatus(ServerId("a"), true)
        runCurrent()
        assertEquals(listOf(ServerId("a")), store.state.value.onlineServerIds)

        store.dispose()
        h.manager.updateServerStatus(ServerId("b"), true)
        runCurrent()

        assertEquals(listOf(ServerId("a")), store.state.value.onlineServerIds)
    }
}

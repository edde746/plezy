package com.edde746.plezy.livetv

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.LiveTvServerEntry
import com.edde746.plezy.servers.ManagerHarness
import com.edde746.plezy.servers.MultiServerStore
import com.edde746.plezy.strings.T
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.currentTime
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNull

class LiveLinkTest {
    private val channels = listOf(
        LiveTvChannel(key = "k1", identifier = "004.1", number = "4.1", callSign = "KNTVDT"),
        LiveTvChannel(key = "k2", identifier = "011.1", number = "11.1", callSign = "KNTVDT2"),
        LiveTvChannel(key = "k3", identifier = "036.1", number = "4.1", callSign = "KICU"),
    )

    private fun select(channel: String): LiveTvChannel? = LiveLink(channel).selectChannel(channels)

    @Test
    fun matchesKeyIdentifierUniqueNumberAndCaseInsensitiveCallSign() {
        assertEquals("k2", select("k2")?.key)
        assertEquals("k3", select("036.1")?.key)
        assertEquals("k2", select("11.1")?.key)
        assertEquals("k1", select("kntvdt")?.key)
    }

    @Test
    fun ambiguousOrUnknownChannelsAreNotFound() {
        assertNull(select("4.1"))
        assertNull(select("999"))
    }

    @Test
    fun theFirstRuleWithAMatchDecidesEvenWhenItIsAmbiguous() {
        val crossed = listOf(
            LiveTvChannel(key = "7", identifier = "a", number = "1", callSign = "B"),
            LiveTvChannel(key = "x", identifier = "7", number = "a", callSign = "7"),
            LiveTvChannel(key = "y", identifier = "z", number = "7", callSign = "A"),
        )
        // The key beats an identifier, number or call sign on another channel.
        assertEquals("7", LiveLink("7").selectChannel(crossed)?.key)
        // The identifier beats a number on another channel.
        assertEquals("7", LiveLink("a").selectChannel(crossed)?.key)
        // Two numbers match: the link is ambiguous though one call sign would match alone.
        val twoNumbers = listOf(
            LiveTvChannel(key = "c1", number = "5"),
            LiveTvChannel(key = "c2", number = "5"),
            LiveTvChannel(key = "c3", callSign = "5"),
        )
        assertNull(LiveLink("5").selectChannel(twoNumbers))
    }

    // Launch.

    private fun TestScope.store(h: ManagerHarness): MultiServerStore = MultiServerStore(
        h.manager,
        { client: MediaBackend -> listOf(LiveTvServerEntry(client.serverId, "dvr-${client.serverId}", lineup = "lineup-1")) },
        backgroundScope,
    )

    @Test
    fun aLinkOpenedBeforeLiveTvIsKnownWaitsForTheServerAndChecksAgain() = runTest {
        val h = ManagerHarness(this)
        val store = store(h)
        val client = h.addJellyfin("u", machineId = "srv-1")
        val liveTv = client.liveTv as FakeLiveTv
        liveTv.channels = { lineup ->
            assertEquals("lineup-1", lineup)
            listOf(LiveTvChannel(key = "c1", callSign = "ONE"), LiveTvChannel(key = "c2", callSign = "TWO"))
        }

        val result = LiveLink("two", startPosition = LiveTvStartPosition.LIVE).resolve(store, isOffline = false)

        val launch = assertIs<LiveTvLaunchResult.Ready>(result).launch
        assertEquals(ServerId("srv-1"), launch.serverId)
        assertEquals("dvr-srv-1", launch.dvrKey)
        assertEquals(LiveTvChannel(key = "c2", callSign = "TWO", serverId = "srv-1", liveDvrKey = "dvr-srv-1"), launch.channel)
        assertEquals(listOf("c1", "c2"), launch.channels.map { it.key })
        assertEquals(LiveTvStartPosition.LIVE, launch.startPosition)
    }

    @Test
    fun withoutLiveTvOfflineTheLinkFailsAtOnce() = runTest {
        val h = ManagerHarness(this)
        val store = store(h)

        val result = LiveLink("4").resolve(store, isOffline = true)

        assertEquals(LiveTvLaunchResult.Failed(T.deepLinks.noLiveTv), result)
        assertEquals(0, currentTime)
    }

    @Test
    fun withoutAServerOnlineTheLinkWaitsTwentySecondsThenFails() = runTest {
        val h = ManagerHarness(this)
        val store = store(h)

        val result = LiveLink("4", serverId = ServerId("srv-9")).resolve(store, isOffline = false)

        assertEquals(LiveTvLaunchResult.Failed(T.deepLinks.noLiveTv), result)
        assertEquals(20_000, currentTime)
    }

    @Test
    fun aChannelNoSourceHasIsNotFoundAndAFailingSourceIsSkipped() = runTest {
        val h = ManagerHarness(this)
        val good = h.addJellyfin("u", machineId = "srv-1")
        val bad = h.addJellyfin("v", machineId = "srv-2")
        val store = store(h)
        store.checkLiveTvAvailability()
        (good.liveTv as FakeLiveTv).channels = { listOf(LiveTvChannel(key = "c1", number = "4.1"), LiveTvChannel(key = "c2", number = "4.1")) }
        (bad.liveTv as FakeLiveTv).channels = { error("channels unavailable") }

        assertEquals(LiveTvLaunchResult.Failed(T.deepLinks.channelNotFound(channel = "4.1")), LiveLink("4.1").resolve(store, isOffline = false))
        val launch = assertIs<LiveTvLaunchResult.Ready>(LiveLink("c1").resolve(store, isOffline = false)).launch
        assertEquals(ServerId("srv-1"), launch.serverId)
    }

    @Test
    fun aLinkNamingAServerTunesOnlyThatServersChannel() = runTest {
        val h = ManagerHarness(this)
        val first = h.addJellyfin("u", machineId = "srv-1")
        val second = h.addJellyfin("v", machineId = "srv-2")
        val store = store(h)
        store.checkLiveTvAvailability()
        (first.liveTv as FakeLiveTv).channels = { listOf(LiveTvChannel(key = "c1", callSign = "NEWS")) }
        (second.liveTv as FakeLiveTv).channels = { listOf(LiveTvChannel(key = "c2", callSign = "NEWS")) }

        assertEquals(LiveTvLaunchResult.Failed(T.deepLinks.channelNotFound(channel = "news")), LiveLink("news").resolve(store, isOffline = false))
        val launch = assertIs<LiveTvLaunchResult.Ready>(LiveLink("news", serverId = ServerId("srv-2")).resolve(store, isOffline = false)).launch
        assertEquals(ServerId("srv-2"), launch.serverId)
        assertEquals("c2", launch.channel.key)
    }
}

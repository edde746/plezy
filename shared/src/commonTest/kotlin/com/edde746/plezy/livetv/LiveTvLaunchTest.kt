package com.edde746.plezy.livetv

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.LiveTvServerEntry
import com.edde746.plezy.strings.T
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertSame

class LiveTvLaunchTest {
    private val aDvr = LiveTvServerEntry(ServerId("server-a"), "dvr-a")
    private val aOtherDvr = LiveTvServerEntry(ServerId("server-a"), "dvr-other")
    private val bDvr = LiveTvServerEntry(ServerId("server-b"), "dvr-b")

    @AfterTest
    fun resetLocale() {
        T.locale = "en"
    }

    @Test
    fun scopedSelectionFailsClosedAndUnscopedSelectionKeepsTheFallback() {
        val scoped = LiveTvChannel(key = "channel-a", serverId = "server-a", liveDvrKey = "dvr-a")
        assertNull(liveTvServerFor(listOf(bDvr), scoped))
        assertNull(liveTvServerFor(listOf(aOtherDvr, bDvr), scoped), "an explicit DVR never relaxes to another DVR on the same server")
        assertSame(aOtherDvr, liveTvServerFor(listOf(aOtherDvr, bDvr), LiveTvChannel(key = "channel-a", serverId = "server-a")))
        assertSame(aDvr, liveTvServerFor(listOf(bDvr, aDvr), scoped))
        assertSame(bDvr, liveTvServerFor(listOf(bDvr, aDvr), LiveTvChannel(key = "legacy-channel")))
        assertNull(liveTvServerFor(emptyList(), LiveTvChannel(key = "legacy-channel")))
    }

    @Test
    fun aMissingScopedServerIsNotReplacedByAnOnlineServer() {
        T.locale = "bg"
        val clients = mapOf(ServerId("server-b") to FakeMediaBackend("server-b", BackendKind.JELLYFIN))
        val channel = LiveTvChannel(key = "channel-a", title = "Channel A", serverId = "server-a", liveDvrKey = "dvr-a")

        val result = liveTvLaunch(listOf(bDvr), clients::get, channel, listOf(channel))

        assertEquals(LiveTvLaunchResult.Failed("Сървърът за телевизия на живо не е наличен."), result)
    }

    @Test
    fun noLiveTvServerSaysUnavailableInTheActiveLocale() {
        T.locale = "bg"
        val channel = LiveTvChannel(key = "channel-1", title = "Channel")

        assertEquals(LiveTvLaunchResult.Failed("Сървърът за телевизия на живо не е наличен."), liveTvLaunch(emptyList(), { null }, channel, listOf(channel)))
    }

    @Test
    fun aDisconnectedServerSaysNotConnectedInTheActiveLocale() {
        T.locale = "bg"
        val channel = LiveTvChannel(key = "channel-1", title = "Channel", serverId = "server-1", liveDvrKey = "dvr-1")
        val servers = listOf(LiveTvServerEntry(ServerId("server-1"), "dvr-1"))

        assertEquals(LiveTvLaunchResult.Failed("Сървърът за телевизия на живо не е свързан."), liveTvLaunch(servers, { null }, channel, listOf(channel)))
    }

    @Test
    fun theLaunchCarriesTheSourceThePlaceholderAndTheChannelList() {
        val client: MediaBackend = FakeMediaBackend("server-a", BackendKind.PLEX)
        val one = LiveTvChannel(key = "1", callSign = "ONE", thumb = "/logo/1", serverId = "server-a", liveDvrKey = "dvr-a")
        val two = LiveTvChannel(key = "2", serverId = "server-a", liveDvrKey = "dvr-a")

        val launch = assertIs<LiveTvLaunchResult.Ready>(
            liveTvLaunch(listOf(aDvr), { client }, two, listOf(one, two), LiveTvStartPosition.BEGINNING),
        ).launch

        assertEquals(ServerId("server-a"), launch.serverId)
        assertEquals("dvr-a", launch.dvrKey)
        assertEquals(listOf(one, two), launch.channels)
        assertEquals(1, launch.channelIndex)
        assertEquals(LiveTvStartPosition.BEGINNING, launch.startPosition)
        assertEquals("2", launch.item.id)
        assertEquals(MediaKind.CLIP, launch.item.kind)
        assertEquals(BackendKind.PLEX, launch.item.backend)
        assertEquals("server-a", launch.item.serverId)
        assertEquals(T.liveTv.unknownChannel, launch.item.title)
    }

    @Test
    fun aLaunchChannelMissingFromTheListIsPutFirst() {
        val client: MediaBackend = FakeMediaBackend("server-a", BackendKind.JELLYFIN)
        val listed = LiveTvChannel(key = "1", serverId = "server-a", liveDvrKey = "dvr-a")
        val missing = LiveTvChannel(key = "9", callSign = "NINE", thumb = null, art = "/art/9", serverId = "server-a", liveDvrKey = "dvr-a")

        val launch = assertIs<LiveTvLaunchResult.Ready>(liveTvLaunch(listOf(aDvr), { client }, missing, listOf(listed))).launch

        assertEquals(listOf(missing, listed), launch.channels)
        assertEquals(0, launch.channelIndex)
        assertEquals("NINE", launch.item.title)
        assertEquals("/art/9", launch.item.thumbPath)
    }
}

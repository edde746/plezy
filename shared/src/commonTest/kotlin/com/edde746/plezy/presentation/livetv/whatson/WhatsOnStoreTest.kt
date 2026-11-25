package com.edde746.plezy.presentation.livetv.whatson

import com.edde746.plezy.app.testData
import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.livetv.FakeLiveTv
import com.edde746.plezy.livetv.LiveTvChannel
import com.edde746.plezy.livetv.LiveTvHub
import com.edde746.plezy.livetv.LiveTvHubEntry
import com.edde746.plezy.livetv.LiveTvLaunch
import com.edde746.plezy.livetv.LiveTvProgram
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.livetv.LiveTvServers
import com.edde746.plezy.servers.LiveTvServerEntry
import com.edde746.plezy.strings.T
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Instant

class WhatsOnStoreTest {
    private val plexTv = FakeLiveTv(hasWhatsOn = true)
    private val plex = FakeMediaBackend("plex-a", BackendKind.PLEX).also { it.liveTv = plexTv }
    private val jellyfin = FakeMediaBackend("jf-a", BackendKind.JELLYFIN).also { it.liveTv = FakeLiveTv(hasWhatsOn = false) }
    private val launches = mutableListOf<LiveTvLaunch>()
    private val schedules = mutableListOf<Pair<String, ServerId>>()
    private val channel = LiveTvChannel(key = "ch-1", identifier = "station-a", serverId = "plex-a", liveDvrKey = "dvr-1")

    private val servers = object : LiveTvServers {
        override val entries = listOf(
            LiveTvServerEntry(ServerId("plex-a"), "dvr-1"),
            LiveTvServerEntry(ServerId("plex-a"), "dvr-2"),
            LiveTvServerEntry(ServerId("jf-a"), "jellyfin"),
        )
        override fun client(serverId: ServerId): MediaBackend? = listOf(plex, jellyfin).firstOrNull { it.serverId == serverId }
    }

    private fun TestScope.open(): WhatsOnStore {
        val store = WhatsOnStore(
            servers = servers,
            serverSettings = testData().serverSettings,
            play = { launches += it },
            openShowSchedule = { title, serverId -> schedules += title to serverId },
            use24HourClock = true,
            appForeground = MutableStateFlow(true),
            parentScope = backgroundScope,
            now = { Instant.fromEpochSeconds(NOW) },
            utcOffset = { 0 },
        )
        store.setChannels(listOf(channel))
        runCurrent()
        return store
    }

    @Test
    fun loadsEachPlexServersHubsOnceAndRefreshesEveryMinuteWhileShown() = runTest {
        var loads = 0
        plexTv.hubs = {
            loads++
            listOf(LiveTvHub("On Now", "hub-1", listOf(entry("Pilot", MediaKind.EPISODE, NOW - 600))))
        }
        val store = open()

        assertEquals(1, loads)
        assertEquals(listOf("On Now"), store.state.value.hubs.map { it.title })
        assertEquals(listOf("Pilot"), store.state.value.hubs.single().items.map { it.title })

        store.refresh.setSelected(true)
        advanceTimeBy(60.seconds)
        runCurrent()
        assertEquals(2, loads)
    }

    @Test
    fun noHubsSaysNoPrograms() = runTest {
        plexTv.hubs = { emptyList() }

        assertEquals(T.liveTv.noPrograms, open().state.value.emptyText)
    }

    @Test
    fun tappingTunesAnAiringOpensAShowsScheduleAndElseTheDetails() = runTest {
        plexTv.hubs = {
            listOf(
                LiveTvHub(
                    "Mixed",
                    "hub-1",
                    listOf(entry("Pilot", MediaKind.EPISODE, NOW - 600), entry("Example Show", MediaKind.SHOW, NOW + 3_600), entry("Film", MediaKind.MOVIE, NOW + 3_600)),
                ),
            )
        }
        val store = open()
        val hubId = store.state.value.hubs.single().id

        store.tap(hubId, 0)
        assertEquals(channel, launches.single().channel)

        store.tap(hubId, 1)
        assertEquals(listOf("Example Show" to ServerId("plex-a")), schedules)

        store.tap(hubId, 2)
        assertEquals("Film", assertNotNull(store.state.value.details).state.value.title)

        store.longPress(hubId, 0)
        assertEquals("Pilot", assertNotNull(store.state.value.details).state.value.title)
        assertEquals(1, launches.size)
    }

    private fun entry(title: String, kind: MediaKind, beginsAt: Long) = LiveTvHubEntry(
        metadata = MediaItem(id = title, backend = BackendKind.PLEX, kind = kind, title = title, serverId = "plex-a"),
        program = LiveTvProgram(title = title, beginsAt = beginsAt, endsAt = beginsAt + 3_600, channelIdentifier = "station-a", serverId = "plex-a"),
    )

    private companion object {
        // 2026-11-06 23:20 UTC.
        const val NOW = 1_794_007_200L
    }
}

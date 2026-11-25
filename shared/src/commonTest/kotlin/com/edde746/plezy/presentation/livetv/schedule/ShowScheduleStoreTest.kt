package com.edde746.plezy.presentation.livetv.schedule

import com.edde746.plezy.app.testData
import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.livetv.FakeLiveTv
import com.edde746.plezy.livetv.LiveTvChannel
import com.edde746.plezy.livetv.LiveTvLaunch
import com.edde746.plezy.livetv.LiveTvProgram
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.livetv.LiveTvMessage
import com.edde746.plezy.presentation.livetv.LiveTvServers
import com.edde746.plezy.presentation.livetv.details.ProgramActionKind
import com.edde746.plezy.presentation.livetv.liveTvRelativeDay
import com.edde746.plezy.servers.LiveTvServerEntry
import com.edde746.plezy.strings.T
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.time.Instant

class ShowScheduleStoreTest {
    private val liveTv = FakeLiveTv()
    private val client = FakeMediaBackend("server-a", BackendKind.PLEX).also { it.liveTv = liveTv }
    private val launches = mutableListOf<LiveTvLaunch>()
    private val channel = LiveTvChannel(key = "ch-1", identifier = "station-a", callSign = "KABC", serverId = "server-a", liveDvrKey = "dvr-a")

    private val servers = object : LiveTvServers {
        override val entries = listOf(LiveTvServerEntry(ServerId("server-a"), "dvr-a"))
        override fun client(serverId: ServerId): MediaBackend? = client.takeIf { serverId == it.serverId }
    }

    private fun TestScope.open(programs: List<LiveTvProgram>, channels: Flow<List<LiveTvChannel>> = flowOf(emptyList())): ShowScheduleStore {
        liveTv.schedule = { from, to ->
            assertEquals(Instant.fromEpochSeconds(NOW - 3_600), from)
            assertEquals(Instant.fromEpochSeconds(NOW + 48 * 3_600), to)
            programs
        }
        val store = ShowScheduleStore(
            showTitle = "Example Show",
            serverId = ServerId("server-a"),
            channels = channels,
            servers = servers,
            serverSettings = testData().serverSettings,
            play = { launches += it },
            use24HourClock = true,
            parentScope = backgroundScope,
            now = { Instant.fromEpochSeconds(NOW) },
            utcOffset = { 0 },
        )
        runCurrent()
        return store
    }

    @Test
    fun theRecordActionRecordsTheFirstRecordableAiringOnce() = runTest {
        val guids = mutableListOf<String>()
        liveTv.template = {
            guids += it
            emptyList()
        }
        val store = open(listOf(program(guid = null), program(guid = "plex://episode/recordable", beginsAt = NOW + 7_200)))

        assertEquals(T.liveTv.recordShow, store.state.value.recordShowLabel)
        store.recordShow()
        runCurrent()

        assertEquals(listOf("plex://episode/recordable"), guids)
        assertEquals(LiveTvMessage(T.liveTv.recordNotAvailable, isError = true), store.state.value.message)
    }

    @Test
    fun aScheduleThatCannotBeRecordedHasNoRecordAction() = runTest {
        assertNull(open(listOf(program(guid = null), program(guid = ""))).state.value.recordShowLabel)
        liveTv.hasDvr = false
        assertNull(open(listOf(program(guid = "plex://episode/unsupported"))).state.value.recordShowLabel)
    }

    @Test
    fun listsTheShowsAiringsByStartWithWhenTheyAir() = runTest {
        val store = open(
            listOf(
                program(title = "Later", beginsAt = NOW + 2 * 86_400, season = 1, episode = 3),
                program(title = "Other show", beginsAt = NOW, show = "Another Show"),
                LiveTvProgram(title = "Example Show", beginsAt = NOW + 1_800, endsAt = NOW + 3_600, summary = "Special"),
                program(title = "Pilot", beginsAt = NOW - 600, season = 1, episode = 1, premiere = true),
            ),
            channels = flowOf(listOf(channel)),
        )

        val rows = store.state.value.rows
        assertEquals(listOf("S1 · E1 — Pilot", "Example Show", "S1 · E3 — Later"), rows.map { it.title })
        assertEquals(listOf(true, false, false), rows.map { it.live })
        assertEquals(T.liveTv.premiereBadge, rows[0].premiereBadge)
        assertEquals(T.discover.minutesLeft(minutes = "50"), rows[0].subtitle)
        assertEquals("KABC", rows[0].channelName)
        assertEquals("${T.liveTv.startingInMinutes(minutes = "30")} — Special", rows[1].subtitle)
        assertNull(rows[1].channelName)
        assertEquals(T.liveTv.dayAtTime(day = liveTvRelativeDay(NOW + 2 * 86_400, NOW) { 0 }, time = "23:20"), rows[2].subtitle)
    }

    @Test
    fun anEmptyScheduleSaysSo() = runTest {
        val store = open(listOf(program(title = "Other", show = "Another Show")))

        assertEquals(T.liveTv.noPrograms, store.state.value.emptyText)
    }

    @Test
    fun tappingAnAiringOnNowTunesItsChannelAndAnyOtherOpensItsDetails() = runTest {
        val store = open(listOf(program(title = "Pilot", beginsAt = NOW - 600), program(title = "Next", beginsAt = NOW + 3_000)), channels = flowOf(listOf(channel)))

        store.tap(0)
        assertEquals(channel, launches.single().channel)

        store.tap(1)
        val details = assertNotNull(store.state.value.details)
        assertEquals("Next", details.state.value.title)
        details.act(ProgramActionKind.WATCH_CHANNEL)
        assertNull(store.state.value.details)
        assertEquals(2, launches.size)
    }

    @Test
    fun channelsThatLoadAfterTheScheduleNameAndTuneItsAirings() = runTest {
        val channels = MutableStateFlow(emptyList<LiveTvChannel>())
        val store = open(listOf(program(title = "Pilot", beginsAt = NOW - 600)), channels = channels)
        assertNull(store.state.value.rows.single().channelName, "the Live TV screen has no channels yet")

        channels.value = listOf(channel)
        runCurrent()
        assertEquals("KABC", store.state.value.rows.single().channelName)
        store.tap(0)
        assertEquals(channel, launches.single().channel)
    }

    private fun program(
        title: String = "Pilot",
        guid: String? = null,
        beginsAt: Long = NOW + 3_600,
        show: String = "Example Show",
        season: Int? = null,
        episode: Int? = null,
        premiere: Boolean? = null,
    ) = LiveTvProgram(
        guid = guid,
        title = title,
        grandparentTitle = show,
        parentIndex = season,
        index = episode,
        beginsAt = beginsAt,
        endsAt = beginsAt + 3_600,
        channelIdentifier = "station-a",
        premiere = premiere,
        serverId = "server-a",
        liveDvrKey = "dvr-a",
    )

    private companion object {
        // 2026-11-06 23:20 UTC.
        const val NOW = 1_794_007_200L
    }
}

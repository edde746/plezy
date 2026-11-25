package com.edde746.plezy.presentation.livetv.guide

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.input.InputKey
import com.edde746.plezy.livetv.FakeLiveTv
import com.edde746.plezy.livetv.LiveTvChannel
import com.edde746.plezy.livetv.LiveTvProgram
import com.edde746.plezy.livetv.groupLiveTvChannelsBySource
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.livetv.LiveTvServers
import com.edde746.plezy.servers.LiveTvServerEntry
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlin.time.Instant

/** 2026-11-06 18:40 UTC: 19:40 at [CET], so the window opens at 18:30 local (17:30 UTC) and its third slot airs now. */
internal const val NOW_MILLIS = 1_793_990_400_000L

/** Central European Time all year: UTC+1. */
internal val CET: (Long) -> Int = { 3600 }

/** The live window's start at [NOW_MILLIS] in [CET]: 17:30 UTC. */
internal const val NOW_WINDOW_START = NOW_MILLIS / 1000 - 70 * 60

/** One schedule request a fake server received: answer it with [complete]. */
internal class ScheduleRequest(val from: Instant, val to: Instant) {
    val answer = CompletableDeferred<List<LiveTvProgram>>()
}

/** A server whose schedule requests wait until the test answers them, with programs on [stationId]. */
internal class GuideServer(val id: String, val stationId: String, hasDvr: Boolean = false) {
    val liveTv = FakeLiveTv(hasDvr = hasDvr)
    val backend = FakeMediaBackend(id).also { it.liveTv = liveTv }
    val requests = mutableListOf<ScheduleRequest>()

    init {
        liveTv.schedule = { from, to ->
            val request = ScheduleRequest(checkNotNull(from), checkNotNull(to))
            requests += request
            request.answer.await()
        }
    }

    fun complete(index: Int, title: String) {
        val beginsAt = requests[index].from.epochSeconds + 600
        requests[index].answer.complete(
            listOf(LiveTvProgram(ratingKey = "$id-$index", title = title, beginsAt = beginsAt, endsAt = beginsAt + 3600, channelIdentifier = stationId, serverId = id)),
        )
    }

    fun completeEmpty(index: Int) {
        requests[index].answer.complete(emptyList())
    }

    /** [count] half-hour airings from the window's start, "Slot 1" onwards. */
    fun completeSlots(index: Int, count: Int) {
        val start = requests[index].from.epochSeconds
        requests[index].answer.complete(slots(index, start, count))
    }

    fun slots(index: Int, start: Long, count: Int): List<LiveTvProgram> = (0 until count).map { slot ->
        LiveTvProgram(
            ratingKey = "$id-$index-$slot",
            title = "Slot ${slot + 1}",
            beginsAt = start + slot * 1800L,
            endsAt = start + (slot + 1) * 1800L,
            channelIdentifier = stationId,
            serverId = id,
        )
    }
}

internal class FakeLiveTvServers(private val servers: List<GuideServer>) : LiveTvServers {
    override val entries: List<LiveTvServerEntry> get() = servers.map { LiveTvServerEntry(it.backend.serverId, "dvr-${it.id}") }
    override fun client(serverId: ServerId): MediaBackend? = servers.firstOrNull { it.backend.serverId == serverId }?.backend
}

internal fun guideChannel(serverId: String, stationId: String, callSign: String, number: String? = null) = LiveTvChannel(
    key = "channel-$stationId",
    identifier = stationId,
    callSign = callSign,
    serverId = serverId,
    liveDvrKey = "dvr-$serverId",
    number = number,
)

/** A guide over [servers] showing [channels], its events collected into [events]. Time is the test's virtual clock. */
internal class GuideHarness(
    private val test: TestScope,
    val servers: List<GuideServer>,
    val channels: List<LiveTvChannel>,
    isTv: Boolean = false,
    utcOffset: (Long) -> Int = CET,
    nowMillis: Long = NOW_MILLIS,
) {
    val foreground = MutableStateFlow(true)
    val store = GuideStore(
        servers = FakeLiveTvServers(servers),
        parentScope = test.backgroundScope,
        appForeground = foreground,
        isTv = isTv,
        use24HourClock = true,
        now = { Instant.fromEpochMilliseconds(nowMillis + test.testScheduler.currentTime) },
        utcOffset = utcOffset,
    )
    val events = mutableListOf<GuideEvent>()
    val state: GuideUiState get() = store.state.value

    init {
        test.backgroundScope.launch { store.events.collect { events += it } }
        store.setChannels(channels, groupLiveTvChannelsBySource(channels), emptySet())
        test.runCurrent()
    }

    val serverA: GuideServer get() = servers[0]
    val serverB: GuideServer get() = servers[1]

    fun down(key: InputKey) {
        store.onKeyDown(key)
        test.runCurrent()
    }

    /** A key pressed and released. */
    fun press(key: InputKey) {
        store.onKeyDown(key)
        store.onKeyUp(key)
        test.runCurrent()
    }

    /** The first load answered: "Initial A" (and "Initial B"). */
    fun completeInitial() {
        serverA.complete(0, "Initial A")
        test.runCurrent()
        if (servers.size > 1) {
            check(serverB.requests.size == 1)
            serverB.complete(0, "Initial B")
            test.runCurrent()
        }
    }

    /** The first load answered with no airings. */
    fun completeInitialEmpty() {
        serverA.completeEmpty(0)
        test.runCurrent()
        if (servers.size > 1) {
            serverB.completeEmpty(0)
            test.runCurrent()
        }
    }

    /** The grid's focused cell: the channel's call sign, or the airing's title. */
    fun focusedCell(): String? {
        val focus = state.focus
        if (focus.zone != GuideZone.GRID) return null
        return if (focus.column == GuideColumn.CHANNEL) channels[focus.channelIndex].callSign else focus.program?.title
    }

    /** Every block title on [callSign]'s row. */
    fun titles(callSign: String): List<String> =
        state.rows.filterIsInstance<GuideRow.Channel>().first { it.channel.callSign == callSign }.programs.map { it.title }

    fun cell(title: String): Pair<GuideRow.Channel, GuideProgramCell> =
        state.rows.filterIsInstance<GuideRow.Channel>().firstNotNullOf { row -> row.programs.firstOrNull { it.title == title }?.let { row to it } }

    companion object {
        fun oneServer(test: TestScope, isTv: Boolean = false): GuideHarness {
            val a = GuideServer("server-a", "station-a")
            return GuideHarness(test, listOf(a), listOf(guideChannel("server-a", "station-a", "A")), isTv)
        }

        fun twoServers(test: TestScope, channels: List<LiveTvChannel>? = null): GuideHarness {
            val a = GuideServer("server-a", "station-a")
            val b = GuideServer("server-b", "station-b")
            return GuideHarness(
                test,
                listOf(a, b),
                channels ?: listOf(guideChannel("server-a", "station-a", "A"), guideChannel("server-b", "station-b", "B")),
            )
        }
    }
}

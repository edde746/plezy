package com.edde746.plezy.presentation.livetv.details

import com.edde746.plezy.app.testData
import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.livetv.FakeLiveTv
import com.edde746.plezy.livetv.LiveTvChannel
import com.edde746.plezy.livetv.LiveTvProgram
import com.edde746.plezy.livetv.MediaSubscription
import com.edde746.plezy.livetv.SubscriptionTemplate
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.presentation.livetv.LiveTvMessage
import com.edde746.plezy.presentation.livetv.liveTvDuration
import com.edde746.plezy.presentation.livetv.recordings.deleteRuleConfirmation
import com.edde746.plezy.strings.T
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.time.Instant

class ProgramDetailsStoreTest {
    private class Host : ProgramDetailsHost {
        val tuned = mutableListOf<LiveTvChannel>()
        val recording = mutableListOf<Pair<LiveTvProgram, Boolean>>()
        val messages = mutableListOf<LiveTvMessage>()
        var closed = 0

        override fun tune(channel: LiveTvChannel) {
            tuned += channel
        }

        override fun recordingChanged(program: LiveTvProgram, scheduled: Boolean) {
            recording += program to scheduled
        }

        override fun showMessage(message: LiveTvMessage) {
            messages += message
        }

        override fun closeDetails() {
            closed++
        }
    }

    private val liveTv = FakeLiveTv()
    private val client = FakeMediaBackend("server-a", BackendKind.PLEX).also { it.liveTv = liveTv }
    private val host = Host()
    private val channel = LiveTvChannel(key = "channel-station-a", identifier = "station-a", callSign = "A", serverId = "server-a", liveDvrKey = "dvr-a")

    private fun TestScope.open(program: LiveTvProgram, channel: LiveTvChannel? = this@ProgramDetailsStoreTest.channel): ProgramDetailsStore {
        val store = ProgramDetailsStore(
            program = program,
            channel = channel,
            client = client,
            posterThumb = null,
            serverSettings = testData().serverSettings,
            host = host,
            use24HourClock = true,
            parentScope = backgroundScope,
            now = { Instant.fromEpochSeconds(NOW) },
            utcOffset = { 0 },
        )
        runCurrent()
        return store
    }

    private fun ProgramDetailsStore.kinds() = state.value.actions.map { it.kind }

    @Test
    fun aTaggedAiringShowsManageRecordingWithoutAMappingCall() = runTest {
        val store = open(episode(grandparentSubscriptionId = "1106"))

        assertEquals(listOf(ProgramActionKind.PLAY, ProgramActionKind.MANAGE), store.kinds())
        assertEquals(T.liveTv.manageRecording, store.state.value.actions.last().label)
        assertEquals(emptyList(), liveTv.calls.filter { it.startsWith("fetchSubscriptionMapping") })
    }

    @Test
    fun anUntaggedAiringFallsBackToTheMappingEndpoint() = runTest {
        val asked = mutableListOf<Pair<String, List<String>>>()
        liveTv.mapping = { provider, keys ->
            asked += provider to keys
            listOf(MediaSubscription(key = "1106", title = "All Episodes"))
        }

        val store = open(episode())

        assertEquals(listOf(PROVIDER to listOf(RATING_KEY)), asked)
        assertEquals(listOf(ProgramActionKind.PLAY, ProgramActionKind.MANAGE), store.kinds())
    }

    @Test
    fun aFailingMappingReadsAsNotScheduled() = runTest {
        liveTv.mapping = { _, _ -> error("403") }

        assertEquals(listOf(ProgramActionKind.PLAY, ProgramActionKind.RECORD), open(episode()).kinds())
    }

    @Test
    fun cancellingFromTheSheetReportsTheAiringUnscheduled() = runTest {
        val deleted = mutableListOf<String>()
        liveTv.delete = { deleted += it }
        val program = episode(grandparentSubscriptionId = "1106")
        val store = open(program)

        store.act(ProgramActionKind.MANAGE)
        assertEquals(deleteRuleConfirmation(program.grandparentTitle), store.state.value.confirmation)
        store.confirm()
        runCurrent()

        assertEquals(listOf("1106"), deleted)
        assertEquals(listOf(program to false), host.recording)
        assertEquals(listOf(LiveTvMessage(T.liveTv.recordingRuleDeleted)), host.messages)
        assertEquals(1, host.closed)
    }

    @Test
    fun aRecordingScheduledFromTheSheetReportsTheAiringScheduled() = runTest {
        liveTv.mapping = { _, _ -> emptyList() }
        liveTv.template = { listOf(SubscriptionTemplate(listOf(MediaSubscription(key = "", type = 4, title = "Record Episode", selected = true)))) }
        val requests = mutableListOf<String>()
        liveTv.create = {
            requests += "create"
            null
        }
        client.libraries = { emptyList() }
        val program = episode()
        val store = open(program)

        store.act(ProgramActionKind.RECORD)
        runCurrent()
        val options = assertNotNull(store.state.value.recordOptions)
        assertEquals(T.liveTv.recordOptions, options.state.value.title)
        options.save()
        runCurrent()

        assertEquals(listOf("create"), requests)
        assertEquals(listOf(program to true), host.recording)
        assertEquals(listOf(LiveTvMessage(T.liveTv.recordingScheduled)), host.messages)
        assertEquals(1, host.closed)
    }

    @Test
    fun anAiringNotOnAirOffersTheChannelAndTuningClosesTheSheet() = runTest {
        liveTv.mapping = { _, _ -> emptyList() }
        val later = episode(beginsAt = NOW + 3_600)
        val store = open(later)

        assertEquals(T.liveTv.watchChannel, store.state.value.actions.first().label)
        assertEquals(null, store.state.value.liveBadge)
        assertEquals("A · 00:20 - 01:20 · ${liveTvDuration(60)}", store.state.value.info)
        store.act(ProgramActionKind.WATCH_CHANNEL)

        assertEquals(listOf(channel), host.tuned)
        assertEquals(1, host.closed)
    }

    @Test
    fun anEndedAiringSaysItEndedAndOffersOnlyTheChannel() = runTest {
        liveTv.mapping = { _, _ -> emptyList() }
        val store = open(episode(beginsAt = NOW - 2 * 3_600))

        assertEquals(T.liveTv.endedBadge, store.state.value.endedBadge)
        assertEquals(null, store.state.value.liveBadge)
        assertEquals(listOf(ProgramActionKind.WATCH_CHANNEL), store.kinds(), "an aired programme can't be recorded")
        assertEquals(null, open(episode()).state.value.endedBadge)
    }

    @Test
    fun withoutAGuidOrADvrNothingCanBeRecorded() = runTest {
        assertEquals(listOf(ProgramActionKind.PLAY), open(episode().copy(guid = null)).kinds())
        liveTv.hasDvr = false
        assertEquals(emptyList(), open(episode(grandparentSubscriptionId = "1106"), channel = null).kinds())
    }

    private fun episode(grandparentSubscriptionId: String? = null, beginsAt: Long = NOW - 600) = LiveTvProgram(
        key = "/tv.plex.providers.epg.cloud:2/metadata/$RATING_KEY",
        ratingKey = RATING_KEY,
        guid = "plex://episode/6a7fba88cb8a706b4d3047bb",
        title = "Motorway Cops: Catching Britain's Speeders",
        grandparentTitle = "Motorway Cops",
        type = "episode",
        beginsAt = beginsAt,
        endsAt = beginsAt + 3_600,
        channelIdentifier = "station-a",
        grandparentSubscriptionId = grandparentSubscriptionId,
        serverId = "server-a",
        providerIdentifier = PROVIDER,
    )

    private companion object {
        // 2026-11-06 23:20 UTC.
        const val NOW = 1_794_007_200L
        const val RATING_KEY = "plex%3A%2F%2Fepisode%2F6a7fba88cb8a706b4d3047bb"
        const val PROVIDER = "tv.plex.providers.epg.cloud:2"
    }
}

package com.edde746.plezy.presentation.livetv.recordings

import com.edde746.plezy.app.testData
import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.livetv.FakeLiveTv
import com.edde746.plezy.livetv.MediaGrabOperation
import com.edde746.plezy.livetv.MediaSubscription
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.livetv.LiveTvMessage
import com.edde746.plezy.presentation.livetv.LiveTvServers
import com.edde746.plezy.presentation.livetv.liveTvDuration
import com.edde746.plezy.servers.LiveTvServerEntry
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Instant

class RecordingsStoreTest {
    private class Server(id: String) {
        val liveTv = FakeLiveTv()
        val client = FakeMediaBackend(id).also { it.liveTv = liveTv }
        val entry = LiveTvServerEntry(ServerId(id), "dvr-$id")
    }

    private fun servers(vararg servers: Server) = object : LiveTvServers {
        override val entries = servers.map { it.entry }
        override fun client(serverId: ServerId): MediaBackend? = servers.firstOrNull { it.entry.serverId == serverId }?.client
    }

    private fun TestScope.store(vararg servers: Server) = RecordingsStore(
        servers = servers(*servers),
        serverSettings = testData().serverSettings,
        use24HourClock = true,
        appForeground = MutableStateFlow(true),
        parentScope = backgroundScope,
        now = { Instant.fromEpochSeconds(NOW) },
        utcOffset = { 0 },
    )

    private fun lists(store: RecordingsStore) = assertIs<RecordingsBody.Lists>(store.state.value.body)

    @Test
    fun coalescesConcurrentRefreshesAndCommitsCompletedLoadsInOrder() = runTest {
        val server = Server("server-a")
        val grabRequests = mutableListOf<CompletableDeferred<List<MediaGrabOperation>>>()
        val ruleRequests = mutableListOf<CompletableDeferred<List<MediaSubscription>>>()
        server.liveTv.scheduled = { CompletableDeferred<List<MediaGrabOperation>>().also { grabRequests += it }.await() }
        server.liveTv.rules = { _, _ -> CompletableDeferred<List<MediaSubscription>>().also { ruleRequests += it }.await() }
        val store = store(server)
        runCurrent()

        assertEquals(1, grabRequests.size)
        assertEquals(RecordingsBody.Loading, store.state.value.body)
        store.reload()
        store.reload()
        runCurrent()
        assertEquals(1, grabRequests.size)

        grabRequests[0].complete(emptyList())
        runCurrent()
        ruleRequests[0].complete(listOf(RULE))
        runCurrent()

        assertEquals(listOf(RULE.title), lists(store).rules.map { it.title })
        assertEquals(2, grabRequests.size)

        store.reload()
        runCurrent()
        assertEquals(2, grabRequests.size)

        grabRequests[1].complete(emptyList())
        runCurrent()
        ruleRequests[1].complete(listOf(RULE))
        runCurrent()

        assertEquals(listOf(RULE.title), lists(store).rules.map { it.title })
        assertEquals(3, grabRequests.size)

        grabRequests[2].complete(emptyList())
        runCurrent()
        ruleRequests[2].complete(emptyList())
        runCurrent()

        assertEquals(3, grabRequests.size)
        assertEquals(3, ruleRequests.size)
        assertEquals(RecordingsBody.Empty(T.liveTv.noScheduledRecordings), store.state.value.body)
    }

    @Test
    fun selectingTheTabReloadsAtOnceAndTheGateRefreshesEveryThirtySeconds() = runTest {
        val server = Server("server-a")
        var loads = 0
        server.liveTv.scheduled = {
            loads++
            emptyList()
        }
        server.liveTv.rules = { _, _ -> emptyList() }
        val store = store(server)
        runCurrent()
        assertEquals(1, loads)

        advanceTimeBy(31.seconds)
        assertEquals(1, loads, "an unselected tab does not refresh")

        store.refresh.setSelected(true)
        runCurrent()
        assertEquals(2, loads)

        advanceTimeBy(30.seconds)
        runCurrent()
        assertEquals(3, loads)
    }

    @Test
    fun whenEveryServerFailsTheTabSaysWhy() = runTest {
        val admin = Server("server-a")
        admin.liveTv.scheduled = { throw MediaServerHttpException(MediaServerHttpErrorType.UNKNOWN, "forbidden", statusCode = 403) }
        val adminStore = store(admin)
        runCurrent()
        assertEquals(RecordingsBody.Empty(T.liveTv.dvrAdminRequired), adminStore.state.value.body)

        val broken = Server("server-b")
        broken.liveTv.scheduled = { error("unreachable") }
        val brokenStore = store(broken)
        runCurrent()
        assertEquals(RecordingsBody.Empty(T.liveTv.recordingFailed), brokenStore.state.value.body)

        val healthy = Server("server-c")
        healthy.liveTv.scheduled = { emptyList() }
        healthy.liveTv.rules = { _, _ -> listOf(RULE) }
        val partStore = store(admin, healthy)
        runCurrent()
        assertEquals(listOf(RULE.title), lists(partStore).rules.map { it.title }, "a server that answered is shown")
    }

    @Test
    fun recordingsSortByStartAndRulesBySeriesThenTitle() = runTest {
        val a = Server("server-a")
        val b = Server("server-b")
        a.liveTv.scheduled = { listOf(grab("late", NOW + 7_200, status = "error")) }
        a.liveTv.rules = { _, _ -> listOf(MediaSubscription(key = "e", type = 4, title = "Alpha"), MediaSubscription(key = "s2", type = 2, title = "Zulu")) }
        b.liveTv.scheduled = { listOf(grab("now", NOW - 600, status = "grabbing")) }
        b.liveTv.rules = { _, _ ->
            listOf(MediaSubscription(key = "s1", type = 2, title = "Bravo", airingsType = "New airings", grabOperations = listOf(grab("x", NOW))))
        }
        val store = store(a, b)
        runCurrent()

        val body = lists(store)
        assertEquals(listOf("now", "late"), body.grabs.map { it.title })
        assertEquals(listOf(true, false), body.grabs.map { it.recording })
        assertEquals(listOf(T.liveTv.recordingInProgress, T.common.error), body.grabs.map { it.pill })
        assertEquals("${T.liveTv.today} · 23:10 · ${liveTvDuration(60)} · KABC", body.grabs[0].subtitle)
        assertEquals(listOf("Bravo", "Zulu", "Alpha"), body.rules.map { it.title })
        assertEquals("${T.liveTv.recordSeries} · New airings · ${T.liveTv.recordingsCount(count = "1")}", body.rules[0].subtitle)
        assertEquals(T.liveTv.recordEpisode, body.rules[2].subtitle)
        // The tab itself is "Scheduled": its recordings' group is headed apart from it.
        assertEquals("Upcoming" to "Recording Rules", store.state.value.scheduledTitle to store.state.value.rulesTitle)
    }

    @Test
    fun cancellingARecordingAsksFirstThenReloads() = runTest {
        val server = Server("server-a")
        var loads = 0
        server.liveTv.scheduled = {
            loads++
            listOf(grab("Pilot", NOW + 600, key = "/media/grabbers/operations/op-1"))
        }
        server.liveTv.rules = { _, _ -> emptyList() }
        val cancelled = mutableListOf<String>()
        server.liveTv.cancel = { cancelled += it }
        val store = store(server)
        runCurrent()

        store.tapGrab(lists(store).grabs.single().id)
        assertEquals(cancelGrabConfirmation(grab("Pilot", NOW + 600)), store.state.value.confirmation)
        assertEquals(emptyList(), cancelled)

        store.confirm()
        runCurrent()

        assertEquals(listOf("/media/grabbers/operations/op-1"), cancelled)
        assertEquals(LiveTvMessage(T.liveTv.recordingCancelled), store.state.value.message)
        assertEquals(2, loads)
    }

    @Test
    fun aRuleOffersEditAndDelete() = runTest {
        val server = Server("server-a")
        server.liveTv.scheduled = { emptyList() }
        server.liveTv.rules = { _, _ -> listOf(RULE) }
        val deleted = mutableListOf<String>()
        server.liveTv.delete = { deleted += it }
        val store = store(server)
        runCurrent()
        val ruleId = lists(store).rules.single().id

        store.tapRule(ruleId)
        assertEquals(listOf(RuleAction.EDIT, RuleAction.DELETE), store.state.value.ruleMenu?.actions?.map { it.action })
        store.chooseRuleAction(RuleAction.EDIT)
        val options = assertNotNull(store.state.value.recordOptions)
        assertEquals(T.liveTv.editRule, options.state.value.title)
        options.cancel()
        assertEquals(null, store.state.value.recordOptions)

        store.tapRule(ruleId)
        store.chooseRuleAction(RuleAction.DELETE)
        assertEquals(deleteRuleConfirmation(RULE.title), store.state.value.confirmation)
        store.confirm()
        runCurrent()

        assertEquals(listOf("rule-1"), deleted)
        assertEquals(LiveTvMessage(T.liveTv.recordingRuleDeleted), store.state.value.message)
    }

    private fun grab(title: String, beginsAt: Long, status: String = "scheduled", key: String? = null) = MediaGrabOperation(
        id = "op-$title",
        key = key,
        status = status,
        metadata = buildJsonObject {
            put("title", JsonPrimitive(title))
            put("beginsAt", JsonPrimitive(beginsAt))
            put("endsAt", JsonPrimitive(beginsAt + 3_600))
            put("channelCallSign", JsonPrimitive("KABC"))
        },
    )

    private companion object {
        // 2026-11-06 23:20 UTC.
        const val NOW = 1_794_007_200L
        val RULE = MediaSubscription(key = "rule-1", type = 2, title = "Obsolete series rule")
    }
}

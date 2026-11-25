package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.RecordingConflictException
import com.edde746.plezy.livetv.MediaSubscription
import com.edde746.plezy.livetv.MediaSubscriptionCreateRequest
import com.edde746.plezy.model.MediaBrowserDialect
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Instant
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonObject

/** The timer adapter in Plex's recording shapes, shared by Jellyfin and Emby. */
class JellyfinLiveTvDvrTest {
    /** `GET /LiveTv/Timers/Defaults`: the whole timer the server pre-fills; creates post it back mutated. */
    private val timerDefaults = """{"Id":"synthetic-defaults-id","Type":"SeriesTimer","ServerId":"srv-1","ServiceName":"Emby",
        "ChannelId":"chan-1","ChannelName":"HBO","ProgramId":"prog-1","ExternalProgramId":"ext-prog-1","Name":"The Show",
        "Overview":"Pilot","StartDate":"2026-08-23T20:00:00.0000000Z","EndDate":"2026-08-23T21:00:00.0000000Z","Priority":0,
        "PrePaddingSeconds":60,"PostPaddingSeconds":120,"IsPrePaddingRequired":false,"IsPostPaddingRequired":false,
        "KeepUntil":"UntilDeleted","RecordAnyTime":true,"SkipEpisodesInLibrary":true,"RecordAnyChannel":false,"KeepUpTo":0,
        "RecordNewOnly":true,"Days":["Sunday"],"DayPattern":"Daily"}"""

    private fun templateServer(isSeries: Boolean?) = JellyfinTestServer { request ->
        when (request.path) {
            "/LiveTv/Timers/Defaults" -> FakeResponse(body = timerDefaults)
            "/LiveTv/Programs/prog-1" -> if (isSeries == null) FakeResponse(status = 500, body = "boom") else FakeResponse(body = """{"Id":"prog-1","IsSeries":$isSeries}""")
            else -> error("Unexpected request ${request.path}")
        }
    }

    private suspend fun TestScope.template(): Pair<MediaSubscription, MediaSubscription> {
        val entries = templateServer(isSeries = true).liveTv(this).getSubscriptionTemplate("prog-1").single().subscriptions
        return entries.first() to entries.last()
    }

    private fun RecordedRequest.json(): JsonObject = Json.parseToJsonElement(body).jsonObject

    @Test fun aSeriesProgramOffersEpisodeAndSeriesEntriesCarryingTheDefaults() = runTest {
        val server = templateServer(isSeries = true)
        val entries = server.liveTv(this).getSubscriptionTemplate("prog-1").single().subscriptions

        assertEquals("/LiveTv/Timers/Defaults", server.requests.first().path)
        assertEquals("prog-1", server.requests.first().query["programId"])
        assertEquals(mapOf("userId" to "user-1"), server.single("/LiveTv/Programs/prog-1").query)
        assertEquals(2, entries.size)
        val episode = entries.first()
        assertEquals(MediaSubscription.TYPE_EPISODE, episode.type)
        assertEquals(true, episode.selected)
        assertEquals(listOf("PrePaddingSeconds", "PostPaddingSeconds"), episode.settings.map { it.id })
        assertEquals(60, episode.settings.first().value)
        assertEquals(0, episode.settings.first().minimum)
        assertEquals(Json.parseToJsonElement(timerDefaults), Json.parseToJsonElement(episode.parameters!!))

        val series = entries.last()
        assertEquals(MediaSubscription.TYPE_SERIES, series.type)
        assertEquals(
            listOf("PrePaddingSeconds", "PostPaddingSeconds", "RecordNewOnly", "RecordAnyChannel", "RecordAnyTime", "SkipEpisodesInLibrary", "KeepUpTo"),
            series.settings.map { it.id },
        )
        assertEquals(true, series.settings.single { it.id == "RecordNewOnly" }.value)
        assertEquals(false, series.settings.single { it.id == "RecordAnyChannel" }.value)
        assertEquals("int", series.settings.single { it.id == "KeepUpTo" }.type)
    }

    @Test fun aNonSeriesProgramOrAFailedProbeOffersTheEpisodeOnly() = runTest {
        for (isSeries in listOf(false, null)) {
            val entries = templateServer(isSeries).liveTv(this).getSubscriptionTemplate("prog-1").single().subscriptions
            assertEquals(listOf(MediaSubscription.TYPE_EPISODE), entries.map { it.type }, "series=$isSeries")
        }
    }

    @Test fun aOneOffCreatePostsTheMutatedDefaultsToTimers() = runTest {
        val (episode, _) = template()
        val server = JellyfinTestServer { FakeResponse(status = 204, body = "") }
        val created = server.liveTv(this).createRecordingRule(MediaSubscriptionCreateRequest.fromTemplate(episode, prefs = mapOf("PrePaddingSeconds" to 300)))

        assertNull(created)
        val post = server.requests.single()
        assertEquals("POST", post.method)
        assertEquals("/LiveTv/Timers", post.path)
        val body = post.json()
        assertEquals(JsonPrimitive(300), body["PrePaddingSeconds"])
        assertEquals(JsonPrimitive("Emby"), body["ServiceName"])
        assertEquals(JsonPrimitive("prog-1"), body["ProgramId"])
        assertEquals(JsonPrimitive(true), body["RecordNewOnly"])
    }

    @Test fun aSeriesCreatePostsToSeriesTimersAndAcceptsABare200() = runTest {
        val (_, series) = template()
        val server = JellyfinTestServer { FakeResponse(status = 200, body = "") }
        server.liveTv(this).createRecordingRule(MediaSubscriptionCreateRequest.fromTemplate(series, prefs = mapOf("RecordNewOnly" to false)))

        val post = server.requests.single()
        assertEquals("/LiveTv/SeriesTimers", post.path)
        assertEquals(JsonPrimitive(false), post.json()["RecordNewOnly"])
        assertEquals(JsonPrimitive(true), post.json()["SkipEpisodesInLibrary"])
    }

    @Test fun aDuplicateOneOffIsAConflictWhileASeries400StaysAnHttpError() = runTest {
        val (episode, series) = template()
        val server = JellyfinTestServer { FakeResponse(status = 400, body = "") }
        assertFailsWith<RecordingConflictException> { server.liveTv(this).createRecordingRule(MediaSubscriptionCreateRequest.fromTemplate(episode)) }
        val error = assertFailsWith<MediaServerHttpException> { server.liveTv(this).createRecordingRule(MediaSubscriptionCreateRequest.fromTemplate(series)) }
        assertEquals(400, error.statusCode)
        assertFailsWith<IllegalArgumentException> { server.liveTv(this).createRecordingRule(MediaSubscriptionCreateRequest(type = MediaSubscription.TYPE_EPISODE)) }
    }

    @Test fun activeTimersBecomeGrabsWithoutCancelledOrCompletedTombstones() = runTest {
        val server = JellyfinTestServer {
            FakeResponse(
                body = """{"Items":[
                    {"Id":"t-new","Name":"Pilot","Overview":"First","ProgramId":"prog-1","ChannelId":"chan-1","ChannelName":"HBO",
                     "SeriesTimerId":"s-1","Status":"New","StartDate":"2026-08-23T20:00:00.0000000Z","EndDate":"2026-08-23T21:00:00.0000000Z",
                     "ProgramInfo":{"SeriesName":"The Show","IndexNumber":1,"ParentIndexNumber":2}},
                    {"Id":"t-live","Name":"Live","Status":"InProgress"},
                    {"Id":"t-bad","Name":"Broken","Status":"Error"},
                    {"Id":"t-conflict","Name":"Clash","Status":"ConflictedNotOk"},
                    {"Id":"t-skip","Name":"Skipped","Status":"Cancelled"},
                    {"Id":"t-done","Name":"Done","Status":"Completed"}
                ]}""",
            )
        }
        val grabs = server.liveTv(this).fetchScheduledRecordings()

        assertEquals("/LiveTv/Timers", server.requests.single().path)
        assertEquals(listOf("timer:t-new", "timer:t-live", "timer:t-bad", "timer:t-conflict"), grabs.map { it.operationKey })
        assertEquals(listOf("scheduled", "grabbing", "error", "error"), grabs.map { it.status })
        val program = grabs.first().program!!
        assertEquals("Pilot", program.title)
        assertEquals("First", program.summary)
        assertEquals("The Show", program.grandparentTitle)
        assertEquals(1, program.index)
        assertEquals(2, program.parentIndex)
        assertEquals("prog-1", program.ratingKey)
        assertEquals("prog-1", program.guid)
        assertEquals("chan-1", program.channelIdentifier)
        assertEquals("HBO", program.channelCallSign)
        assertEquals(Instant.parse("2026-08-23T20:00:00Z").epochSeconds, program.beginsAt)
        assertEquals(Instant.parse("2026-08-23T21:00:00Z").epochSeconds, program.endsAt)
        assertEquals("timer:t-new", program.subscriptionId)
        assertEquals("series:s-1", program.grandparentSubscriptionId)
        assertNull(grabs[1].program!!.grandparentSubscriptionId)
    }

    @Test fun seriesTimersBecomeRulesWithTheirActiveChildren() = runTest {
        val server = JellyfinTestServer { request ->
            when (request.path) {
                "/LiveTv/SeriesTimers" -> FakeResponse(
                    body = """{"Items":[{"Id":"s-1","Name":"The Show","PrePaddingSeconds":60,"PostPaddingSeconds":120,"RecordNewOnly":false,
                        "RecordAnyChannel":true,"RecordAnyTime":true,"SkipEpisodesInLibrary":true,"KeepUpTo":5}]}""",
                )
                "/LiveTv/Timers" -> FakeResponse(
                    body = """{"Items":[{"Id":"t-1","Name":"Ep 1","SeriesTimerId":"s-1","Status":"New"},
                        {"Id":"t-2","Name":"Ep 2","SeriesTimerId":"s-1","Status":"Cancelled"},{"Id":"t-3","Name":"One-off","Status":"New"}]}""",
                )
                else -> error("Unexpected request ${request.path}")
            }
        }
        val rule = server.liveTv(this).fetchRecordingRules().single()

        assertEquals(mapOf("sortBy" to "SortName", "sortOrder" to "Ascending"), server.single("/LiveTv/SeriesTimers").query)
        assertEquals("series:s-1", rule.key)
        assertEquals(MediaSubscription.TYPE_SERIES, rule.type)
        assertEquals("The Show", rule.title)
        assertEquals(false, rule.settings.single { it.id == "RecordNewOnly" }.value)
        assertEquals(5, rule.settings.single { it.id == "KeepUpTo" }.value)
        assertEquals(listOf("timer:t-1"), rule.grabOperations.map { it.operationKey })
    }

    @Test fun rulesWithoutGrabsSkipTheTimerFetch() = runTest {
        val server = JellyfinTestServer { FakeResponse(body = """{"Items":[{"Id":"s-1","Name":"The Show"}]}""") }
        server.liveTv(this).fetchRecordingRules(includeGrabs = false)
        assertEquals(listOf("/LiveTv/SeriesTimers"), server.requests.map { it.path })
    }

    @Test fun deletesDispatchOnTheKeyPrefixAndCancelGrabDeletesTheTimer() = runTest {
        val server = JellyfinTestServer { FakeResponse(status = 204, body = "") }
        val dvr = server.liveTv(this)
        dvr.deleteRecordingRule("series:s-1")
        dvr.deleteRecordingRule("timer:t-1")
        dvr.cancelGrab("timer:t-9")
        assertTrue(server.requests.all { it.method == "DELETE" })
        assertEquals(listOf("/LiveTv/SeriesTimers/s-1", "/LiveTv/Timers/t-1", "/LiveTv/Timers/t-9"), server.requests.map { it.path })
        assertFailsWith<IllegalArgumentException> { dvr.deleteRecordingRule("naked-id") }
        assertEquals(3, server.requests.size)
    }

    @Test fun anUpdateRefetchesTheRuleOverlaysThePrefsAndPostsItBackWhole() = runTest {
        var saved = false
        val server = JellyfinTestServer { request ->
            if (request.method == "GET") {
                FakeResponse(body = """{"Id":"s-1","Name":"The Show","ServiceName":"Emby","RecordNewOnly":${!saved},"KeepUpTo":${if (saved) 7 else 0},"PrePaddingSeconds":60}""")
            } else {
                saved = true
                FakeResponse(status = 204, body = "")
            }
        }
        val updated = server.liveTv(this).updateRecordingRule("series:s-1", mapOf("RecordNewOnly" to false))

        assertEquals(listOf("GET", "POST", "GET"), server.requests.map { it.method })
        assertTrue(server.requests.all { it.path == "/LiveTv/SeriesTimers/s-1" })
        val body = server.requests[1].json()
        assertEquals(JsonPrimitive(false), body["RecordNewOnly"])
        assertEquals(JsonPrimitive("Emby"), body["ServiceName"])
        assertEquals(JsonPrimitive(60), body["PrePaddingSeconds"])
        assertEquals(7, updated!!.settings.single { it.id == "KeepUpTo" }.value)
        assertEquals("series:s-1", updated.key)
    }

    @Test fun anUpdateRejectsOneOffKeysAndUnknownOptions() = runTest {
        val server = JellyfinTestServer { FakeResponse(body = """{"Id":"s-1","RecordNewOnly":true}""") }
        assertFailsWith<IllegalArgumentException> { server.liveTv(this).updateRecordingRule("timer:t-1", emptyMap()) }
        assertTrue(server.requests.isEmpty())
        assertFailsWith<UnsupportedOperationException> { server.liveTv(this).updateRecordingRule("series:s-1", mapOf("Priority" to 1)) }
        assertEquals(listOf("GET"), server.requests.map { it.method })
    }

    @Test fun mappingIsEmptyWithoutARequest() = runTest {
        val server = JellyfinTestServer { error("no request") }
        assertEquals(emptyList(), server.liveTv(this).fetchSubscriptionMapping("provider", listOf("1")))
    }

    // Emby shares the adapter: the same routes, no status query, tombstones filtered here.
    @Test fun embyListsTimersWithoutStatusFilters() = runTest {
        val server = JellyfinTestServer {
            FakeResponse(body = """{"Items":[{"Id":"t-1","Name":"Ep 1","Status":"New"},{"Id":"t-2","Name":"Old","Status":"Completed"}],"TotalRecordCount":2}""")
        }
        val grabs = server.liveTv(this, MediaBrowserDialect.EMBY).fetchScheduledRecordings()
        val request = server.requests.single()
        assertEquals("/LiveTv/Timers", request.path)
        assertTrue(request.query.isEmpty())
        assertEquals(listOf("timer:t-1"), grabs.map { it.operationKey })
    }
}

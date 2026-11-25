package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.MediaServerTimeouts
import com.edde746.plezy.backend.PlaybackException
import com.edde746.plezy.backend.PlaybackFailureReason
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.livetv.LiveTimelineState
import com.edde746.plezy.livetv.LiveTvBackgroundPolicy
import com.edde746.plezy.livetv.LiveTvPlaybackSession
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.model.MediaSubtitleTrack
import com.edde746.plezy.strings.T
import io.ktor.http.Url
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNotSame
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.delay
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject

/** Tuning a MediaBrowser channel and the session it yields. */
class JellyfinLiveTvPlaybackTest {
    private val hlsSource = """{"Id":"source-1","Container":"ts","LiveStreamId":"live-1","TranscodingUrl":"/Videos/channel-1/live.m3u8?PlaySessionId=play-1"}"""
    private val directPlaySource = """{"Id":"source-1","Container":"ts","LiveStreamId":"live-1","SupportsDirectPlay":true}"""

    /** What Emby answers for an HDHomeRun channel: direct stream only, no transcode URL. */
    private fun embyDirectStreamSource(liveStreamId: String) = """{"Id":"native_1","Container":"ts","LiveStreamId":"$liveStreamId",
        "IsInfiniteStream":true,"SupportsDirectPlay":false,"SupportsDirectStream":true,"SupportsTranscoding":true,
        "DirectStreamUrl":"/videos/channel-1/original.ts?MediaSourceId=native_1&LiveStreamId=$liveStreamId"}"""

    private fun negotiation(vararg sources: String, playSessionId: String? = "play-1") =
        FakeResponse(body = """{${playSessionId?.let { "\"PlaySessionId\":\"$it\"," } ?: ""}"MediaSources":[${sources.joinToString(",")}]}""")

    /** Answers `PlaybackInfo` with [negotiations] in turn (the last repeats) and everything else with 204. */
    private fun server(vararg negotiations: FakeResponse) = JellyfinTestServer().apply {
        var count = 0
        handler = { request ->
            if (request.path.endsWith("/PlaybackInfo")) negotiations[minOf(count++, negotiations.lastIndex)] else FakeResponse(status = 204, body = "")
        }
    }

    private fun JellyfinTestServer.negotiations() = requests.filter { it.path.endsWith("/PlaybackInfo") }

    private fun JellyfinTestServer.closes() = requests.filter { it.path == "/LiveStreams/Close" }

    private fun RecordedRequest.json(): JsonObject = Json.parseToJsonElement(body).jsonObject

    private fun JsonObject.text(key: String) = (this[key] as? JsonPrimitive)?.content

    private suspend fun LiveTvPlaybackSession.url() = Url(assertNotNull(streamUrlAt()))

    private suspend fun heartbeat(server: JellyfinTestServer, session: LiveTvPlaybackSession): JsonObject {
        session.reportTimeline(LiveTimelineState.PLAYING, 1000, 0)
        return server.requests.last { it.path == "/Sessions/Playing" }.json()
    }

    @Test fun startingNegotiatesALiveStreamAndAdoptsTheHlsTranscode() = runTest {
        val server = server(negotiation("""{"Id":"source-1","Container":"ts","LiveStreamId":"open-stream-1","TranscodingUrl":"/Videos/channel-1/live.m3u8?PlaySessionId=live-session-1"}""", playSessionId = "live-session-1"))
        val session = assertNotNull(server.liveTv(this).startPlayback("channel-1"))

        val request = server.negotiations().single()
        assertEquals("/Items/channel-1/PlaybackInfo", request.path)
        for (key in listOf("AutoOpenLiveStream", "EnableTranscoding", "EnableDirectPlay", "EnableDirectStream", "AllowVideoStreamCopy", "AllowAudioStreamCopy")) {
            assertEquals("true", request.query[key], key)
            assertEquals(JsonPrimitive(true), request.json()[key], key)
        }
        val url = session.url()
        assertEquals("/Videos/channel-1/live.m3u8", url.encodedPath)
        assertEquals("live-session-1", url.parameters["PlaySessionId"])
        assertEquals("tok-abc", url.parameters["ApiKey"])

        val heartbeat = heartbeat(server, session)
        assertEquals("channel-1", heartbeat.text("ItemId"))
        assertEquals("live-session-1", heartbeat.text("PlaySessionId"))
        assertEquals("source-1", heartbeat.text("MediaSourceId"))
        assertEquals("open-stream-1", heartbeat.text("LiveStreamId"))
        assertEquals("Transcode", heartbeat.text("PlayMethod"))
    }

    @Test fun aTranscodeUrlSuppliesTheIdentityTheAnswerLacks() = runTest {
        val server = server(
            negotiation(
                """{"Container":"ts","TranscodingUrl":"/Videos/channel-1/live.m3u8?MediaSourceId=source-url&LiveStreamId=live-url&PlaySessionId=play-url"}""",
                playSessionId = null,
            ),
        )
        val heartbeat = heartbeat(server, assertNotNull(server.liveTv(this).startPlayback("channel-1")))
        assertEquals("play-url", heartbeat.text("PlaySessionId"))
        assertEquals("source-url", heartbeat.text("MediaSourceId"))
        assertEquals("live-url", heartbeat.text("LiveStreamId"))
        assertEquals("Transcode", heartbeat.text("PlayMethod"))
    }

    @Test fun aSessionPlaysOneUrlWithoutTimeShiftOrSubtitlesAndATranscodeRecoversToItself() = runTest {
        val session = assertNotNull(server(negotiation(hlsSource)).liveTv(this).startPlayback("channel-1"))
        assertNull(session.program.id)
        assertNull(session.captureBuffer)
        assertFalse(session.canTimeShift)
        assertEquals(LiveTvBackgroundPolicy.STOP_AND_EXIT, session.backgroundPolicy)
        assertTrue(session.subtitleTracks.isEmpty())
        assertNull(session.streamUrlAt(offsetSeconds = 60))
        assertNull(session.streamUrlAt(subtitleTrack = MediaSubtitleTrack(id = 1, selected = false, forced = false)))
        assertSame(session, session.recover(directStream = false, directStreamAudio = false))
        assertSame(session, session.recover(directStream = true, directStreamAudio = true))
    }

    @Test fun discardingStopsATranscodesEncodingThenClosesTheStreamWithoutAStopReport() = runTest {
        for ((source, expected) in listOf(
            hlsSource to listOf("DELETE /Videos/ActiveEncodings deviceId=dev-1 playSessionId=play-1", "POST /LiveStreams/Close liveStreamId=live-1"),
            directPlaySource to listOf("POST /LiveStreams/Close liveStreamId=live-1"),
        )) {
            val server = server(negotiation(source))
            assertNotNull(server.liveTv(this).startPlayback("channel-1")).discard()
            val calls = server.requests.drop(1).map { request ->
                (listOf(request.method, request.path) + listOf("deviceId", "playSessionId", "liveStreamId").mapNotNull { key -> request.query[key]?.let { "$key=$it" } })
                    .joinToString(" ")
            }
            assertEquals(expected, calls)
        }
    }

    @Test fun failedNegotiationsThrowAndOnlyAValidEmptyAnswerIsNoStream() = runTest {
        for (status in listOf(401, 500)) {
            val error = assertFailsWith<MediaServerHttpException> { server(FakeResponse(status = status)).liveTv(this).startPlayback("channel-1") }
            assertEquals(status, error.statusCode)
        }
        val missing = assertFailsWith<MediaServerHttpException> {
            server(FakeResponse(body = """{"PlaySessionId":"play-1"}""")).liveTv(this).startPlayback("channel-1")
        }
        assertEquals(200, missing.statusCode)
        assertNull(missing.responseData)

        val malformed = assertFailsWith<PlaybackException> { server(negotiation("\"invalid\"")).liveTv(this).startPlayback("channel-1") }
        assertEquals(PlaybackFailureReason.INVALID_PLAYBACK_DATA, malformed.reason)
        assertEquals(T.liveTv.invalidPlaybackData(product = "Jellyfin"), malformed.message)

        assertNull(server(negotiation()).liveTv(this).startPlayback("channel-1"))
    }

    @Test fun originalQualityDirectPlaysTheServerProxiedStreamWhenGranted() = runTest {
        val server = server(negotiation(directPlaySource))
        val session = assertNotNull(server.liveTv(this).startPlayback("channel-1"))

        val request = server.negotiations().single()
        val body = request.json()
        assertEquals(JsonPrimitive(true), body["EnableDirectPlay"])
        assertEquals(JsonPrimitive(true), body["EnableDirectStream"])
        assertEquals("100000000", request.query["MaxStreamingBitrate"])
        assertEquals(JsonPrimitive(100_000_000), body["MaxStreamingBitrate"])
        assertEquals(JsonPrimitive(100_000_000), body["DeviceProfile"]!!.jsonObject["MaxStreamingBitrate"])

        val url = session.url()
        assertEquals("http://jf.local:8096/Videos/channel-1/stream.ts", url.toString().substringBefore('?'))
        assertEquals("true", url.parameters["Static"])
        assertEquals("source-1", url.parameters["MediaSourceId"])
        assertEquals("live-1", url.parameters["LiveStreamId"])
        assertEquals("dev-1", url.parameters["DeviceId"])
        assertEquals("tok-abc", url.parameters["ApiKey"])

        val heartbeat = heartbeat(server, session)
        assertEquals("DirectPlay", heartbeat.text("PlayMethod"))
        assertEquals("live-1", heartbeat.text("LiveStreamId"))
    }

    @Test fun aCappedPresetIsACeilingTheServerAppliesNotAForcedTranscode() = runTest {
        for ((source, path) in listOf(hlsSource to "/Videos/channel-1/live.m3u8", directPlaySource to "/Videos/channel-1/stream.ts")) {
            val server = server(negotiation(source))
            val session = assertNotNull(server.liveTv(this).startPlayback("channel-1", quality = TranscodeQualityPreset.P720_2MBPS))
            val body = server.negotiations().single().json()
            assertEquals(JsonPrimitive(2_000_000), body["MaxStreamingBitrate"])
            assertEquals(JsonPrimitive(true), body["EnableDirectPlay"])
            assertEquals(JsonPrimitive(true), body["EnableDirectStream"])
            assertEquals(path, session.url().encodedPath)
        }
    }

    @Test fun embyDirectStreamsASourceItWillNotDirectPlayAndKeepsItsStreamOpen() = runTest {
        val server = server(negotiation(embyDirectStreamSource("live-1")))
        val session = assertNotNull(server.liveTv(this, MediaBrowserDialect.EMBY).startPlayback("channel-1"))
        val url = session.url()
        assertEquals("/Videos/channel-1/stream.ts", url.encodedPath)
        assertEquals("true", url.parameters["Static"])
        assertEquals("native_1", url.parameters["MediaSourceId"])
        assertEquals("live-1", url.parameters["LiveStreamId"])
        val heartbeat = heartbeat(server, session)
        assertEquals("DirectStream", heartbeat.text("PlayMethod"))
        assertEquals("live-1", heartbeat.text("LiveStreamId"))
        runCurrent()
        assertTrue(server.closes().isEmpty())
    }

    @Test fun anHlsTranscodeOutranksADirectStreamGrant() = runTest {
        val source = """{"Id":"source-1","Container":"ts","LiveStreamId":"live-1","SupportsDirectPlay":false,"SupportsDirectStream":true,
            "TranscodingUrl":"/Videos/channel-1/live.m3u8?PlaySessionId=play-1"}"""
        val session = assertNotNull(server(negotiation(source)).liveTv(this).startPlayback("channel-1"))
        assertEquals("/Videos/channel-1/live.m3u8", session.url().encodedPath)
    }

    @Test fun aNegotiationWithoutAPlayableStreamClosesTheStreamItOpened() = runTest {
        val server = server(negotiation("""{"Id":"source-1","LiveStreamId":"live-1","TranscodingUrl":"/Videos/channel-1/stream"}"""))
        assertNull(server.liveTv(this).startPlayback("channel-1"))
        runCurrent()
        val close = server.closes().single()
        assertEquals("POST", close.method)
        assertEquals("live-1", close.query["liveStreamId"])

        assertNull(server(negotiation("""{"DirectStreamUrl":"/Videos/channel-1/stream.ts"}""")).liveTv(this).startPlayback("channel-1"))
    }

    @Test fun recoveringADirectSessionRenegotiatesAForcedTranscodeAndReleasesItsStream() = runTest {
        val transcode = negotiation("""{"Id":"source-1","Container":"ts","LiveStreamId":"live-2","TranscodingUrl":"/Videos/channel-1/live.m3u8?PlaySessionId=play-2"}""", playSessionId = "play-2")
        for ((dialect, source) in listOf(MediaBrowserDialect.JELLYFIN to directPlaySource, MediaBrowserDialect.EMBY to embyDirectStreamSource("live-1"))) {
            val server = server(negotiation(source), transcode)
            val session = assertNotNull(server.liveTv(this, dialect).startPlayback("channel-1"))
            val recovered = assertNotNull(session.recover(directStream = false, directStreamAudio = true))

            assertNotSame(session, recovered)
            assertTrue(recovered.url().encodedPath.endsWith(".m3u8"))
            val retry = server.negotiations()[1].json()
            assertEquals(JsonPrimitive(false), retry["EnableDirectPlay"])
            assertEquals(JsonPrimitive(false), retry["EnableDirectStream"])
            assertEquals(JsonPrimitive(100_000_000), retry["MaxStreamingBitrate"])
            assertEquals(JsonPrimitive(true), retry["AllowVideoStreamCopy"])
            assertEquals(JsonPrimitive(true), retry["AllowAudioStreamCopy"])
            runCurrent()
            assertEquals(listOf("live-1"), server.closes().map { it.query["liveStreamId"] })
            assertSame(recovered, recovered.recover(directStream = false, directStreamAudio = false))
        }
    }

    // Emby live needs MPEG-TS; Jellyfin keeps fMP4 first and TS as the fallback for TS-only tuners.
    @Test fun liveNegotiationsOfferTheDialectsHlsContainers() = runTest {
        fun containers(request: RecordedRequest) = request.json()["DeviceProfile"]!!.jsonObject["TranscodingProfiles"]!!.jsonArray
            .map { it.jsonObject }
            .filter { it.text("Type") == "Video" && it.text("Protocol") == "hls" }
            .map { it.text("Container") }
        for ((dialect, expected) in listOf(MediaBrowserDialect.JELLYFIN to listOf("mp4", "ts"), MediaBrowserDialect.EMBY to listOf("ts"))) {
            val server = server(negotiation(directPlaySource), negotiation(hlsSource))
            val liveTv = server.liveTv(this, dialect)
            val direct = assertNotNull(liveTv.startPlayback("channel-1"))
            assertNotNull(direct.recover(directStream = false, directStreamAudio = true))
            liveTv.startPlayback("channel-1", quality = TranscodeQualityPreset.P720_2MBPS)
            val negotiations = server.negotiations()
            assertEquals(3, negotiations.size)
            negotiations.forEach { assertEquals(expected, containers(it), dialect.name) }

            val vod = JellyfinPlayback(server.core(dialect), fetchItem = { null }, fetchItemFreshCacheFirst = { null }, cachedItem = { null })
            vod.getPlaybackInfo("movie-1", autoOpenLiveStream = true)
            assertEquals(listOf("mp4", "ts"), containers(server.negotiations().last()))
        }
    }

    // A cold tuner may take longer than the connect budget: the tune and the recovery both wait, neither is replayed.
    @Test fun aColdTuneAndItsRecoveryMayTakeLongerThanTenSeconds() = runTest {
        for (dialect in MediaBrowserDialect.entries) {
            var count = 0
            val server = JellyfinTestServer(StandardTestDispatcher(testScheduler)) { request ->
                if (!request.path.endsWith("/PlaybackInfo")) return@JellyfinTestServer FakeResponse(status = 204, body = "")
                count++
                delay(11.seconds)
                negotiation(
                    """{"Id":"source-1","Container":"ts","LiveStreamId":"live-$count","SupportsDirectPlay":${count == 1},"TranscodingUrl":"/Videos/channel-1/live.m3u8"}""",
                    playSessionId = "play-$count",
                )
            }
            val liveTv = server.liveTv(backgroundScope, dialect)
            val session = assertNotNull(liveTv.startPlayback("channel-1"))
            assertEquals("/Videos/channel-1/stream.ts", session.url().encodedPath)
            val recovered = assertNotNull(session.recover(directStream = false, directStreamAudio = true))
            assertEquals("/Videos/channel-1/live.m3u8", recovered.url().encodedPath)
            assertEquals(2, count)
        }
    }

    @Test fun aStuckTuneFailsAtTheTuneTimeoutWithoutAReplay() = runTest {
        val server = JellyfinTestServer(StandardTestDispatcher(testScheduler)) { awaitCancellation() }
        val liveTv = server.liveTv(backgroundScope)
        val start = async { runCatching { liveTv.startPlayback("channel-1") } }
        advanceTimeBy(MediaServerTimeouts.TUNE - 1.seconds)
        runCurrent()
        assertFalse(start.isCompleted)
        advanceTimeBy(1.seconds)
        runCurrent()
        assertTrue(start.isCompleted)
        val failure = start.await().exceptionOrNull()
        assertEquals(MediaServerHttpErrorType.CONNECTION_TIMEOUT, (failure as MediaServerHttpException).type)
        advanceTimeBy(MediaServerTimeouts.TUNE_TRANSPORT)
        runCurrent()
        assertEquals(1, server.requests.size)
    }

    @Test fun aTuneAnsweringAfterItsCallerGaveUpHasItsStreamClosedOnce() = runTest {
        for ((answerAfter, expectedCloses) in listOf(45.seconds to listOf("live-1"), 29.seconds to emptyList())) {
            for (dialect in MediaBrowserDialect.entries) {
                val server = lateServer(answerAfter)
                val liveTv = server.liveTv(backgroundScope, dialect)
                val start = async { runCatching { liveTv.startPlayback("channel-1") } }
                advanceTimeBy(MediaServerTimeouts.TUNE_TRANSPORT)
                runCurrent()
                assertTrue(start.isCompleted)
                assertEquals(expectedCloses, server.closes().map { it.query["liveStreamId"] }, "answer after $answerAfter on $dialect")
                assertTrue(server.requests.all { it.path.endsWith("/PlaybackInfo") || it.path == "/LiveStreams/Close" })
            }
        }
    }

    private fun TestScope.lateServer(answerAfter: Duration) = JellyfinTestServer(StandardTestDispatcher(testScheduler)) { request ->
        if (!request.path.endsWith("/PlaybackInfo")) return@JellyfinTestServer FakeResponse(status = 204, body = "")
        delay(answerAfter)
        negotiation("""{"Id":"source-1","Container":"ts","LiveStreamId":"live-1","TranscodingUrl":"/Videos/channel-1/live.m3u8?LiveStreamId=live-1"}""")
    }

    // The session tracker: one start, progress only after it, a stop that waits for it and ends the session.
    @Test fun duplicateStartsCoalesceAndAStopFollowsTheStartInFlight() = runTest {
        val gate = CompletableDeferred<Unit>()
        val delivered = mutableListOf<String>()
        val server = JellyfinTestServer { request ->
            if (request.path == "/Sessions/Playing") gate.await()
            val body = request.json()
            delivered += listOf(request.path, "ItemId", "PlaySessionId", "MediaSourceId", "LiveStreamId", "PlayMethod", "IsPaused")
                .mapIndexed { i, key -> if (i == 0) key else body.text(key) ?: "-" }.joinToString(":")
            FakeResponse(status = 204, body = "")
        }
        val tracker = tracker(server, playMethod = "Transcode")
        val first = async { tracker.report("channel-1", LiveTimelineState.PLAYING, Duration.ZERO, Duration.ZERO) }
        val second = async { tracker.report("channel-1", LiveTimelineState.PLAYING, 1.seconds, Duration.ZERO) }
        runCurrent()
        val stopped = async { tracker.report("channel-1", LiveTimelineState.STOPPED, 2.seconds, Duration.ZERO) }
        runCurrent()
        assertEquals(emptyList(), delivered)

        gate.complete(Unit)
        awaitAll(first, second, stopped)
        tracker.report("channel-1", LiveTimelineState.PAUSED, 3.seconds, Duration.ZERO)
        assertEquals(
            listOf(
                "/Sessions/Playing:channel-1:live-session-1:source-1:live-stream-1:Transcode:false",
                "/Sessions/Playing/Stopped:channel-1:live-session-1:source-1:live-stream-1:-:-",
            ),
            delivered,
        )
    }

    @Test fun aStopBeforeTheFirstHeartbeatCarriesTheNegotiatedIdentity() = runTest {
        val server = JellyfinTestServer { FakeResponse(status = 204, body = "") }
        tracker(server, playMethod = null).report("channel-1", LiveTimelineState.STOPPED, Duration.ZERO, Duration.ZERO)
        val stop = server.requests.single()
        assertEquals("/Sessions/Playing/Stopped", stop.path)
        assertEquals(listOf("channel-1", "live-session-1", "source-1", "live-stream-1"), listOf("ItemId", "PlaySessionId", "MediaSourceId", "LiveStreamId").map { stop.json().text(it) })
    }

    @Test fun progressFollowsTheStartAndFailuresAreSwallowedAndRetried() = runTest {
        var fail = true
        val server = JellyfinTestServer { if (fail) FakeResponse(status = 500) else FakeResponse(status = 204, body = "") }
        val tracker = tracker(server, playMethod = "DirectPlay")
        tracker.report("channel-1", LiveTimelineState.PLAYING, Duration.ZERO, Duration.ZERO)
        fail = false
        tracker.report("channel-1", LiveTimelineState.PLAYING, 10.seconds, Duration.ZERO)
        tracker.report("channel-1", LiveTimelineState.PAUSED, 20.seconds, Duration.ZERO)
        assertEquals(listOf("/Sessions/Playing", "/Sessions/Playing", "/Sessions/Playing/Progress"), server.requests.map { it.path })
        assertEquals("true", server.requests.last().json().text("IsPaused"))
    }

    private fun tracker(server: JellyfinTestServer, playMethod: String?) = JellyfinLiveSessionTracker(
        JellyfinPlayback(server.core(), fetchItem = { null }, fetchItemFreshCacheFirst = { null }, cachedItem = { null }),
        playSessionId = "live-session-1",
        mediaSourceId = "source-1",
        liveStreamId = "live-stream-1",
        playMethod = playMethod,
    )
}

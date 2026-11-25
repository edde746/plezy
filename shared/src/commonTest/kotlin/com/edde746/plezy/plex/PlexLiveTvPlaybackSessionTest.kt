package com.edde746.plezy.plex

import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.MediaServerTimeouts
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.livetv.LiveTimelineState
import com.edde746.plezy.livetv.LiveTvBackgroundPolicy
import com.edde746.plezy.livetv.LiveTvPlaybackSession
import io.ktor.client.engine.mock.MockRequestHandleScope
import io.ktor.client.engine.mock.respond
import io.ktor.client.request.HttpRequestData
import io.ktor.client.request.HttpResponseData
import io.ktor.http.HttpMethod
import io.ktor.http.HttpStatusCode
import io.ktor.http.Parameters
import io.ktor.http.Url
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.io.IOException
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class PlexLiveTvPlaybackSessionTest {
    private val decisionPath = "/video/:/transcode/universal/decision"

    private val tuneResponse = """
        {"MediaContainer":{
          "MediaSubscription":[{"MediaGrabOperation":[{"Metadata":{
            "ratingKey":"prog-1","key":"/livetv/sessions/session-abc","type":"clip","duration":1800000,
            "Media":[{"beginsAt":"1700000000","Part":[{"id":"42","Stream":[
              {"id":"90","streamType":1,"codec":"h264"},
              {"id":"91","streamType":2,"codec":"ac3","languageCode":"mul"},
              {"id":"92","streamType":3,"codec":"dvb_subtitle","language":"Finnish","languageCode":"fin"},
              {"id":"93","streamType":3,"codec":"eia_608","language":"English","languageCode":"eng"},
              {"id":"94","streamType":3,"codec":"srt","key":"/library/streams/94","languageCode":"eng"}
            ]}]}]
          }}]}],
          "TranscodeSession":[{"timeStamp":"1700000100","minOffsetAvailable":"0","maxOffsetAvailable":"120"}]
        }}
    """.trimIndent()

    /** A Plex client whose tunes outlive their callers in the test's background scope; HEVC is decodable. */
    private fun TestScope.liveTv(
        prioritizedEndpoints: List<String> = emptyList(),
        handler: suspend MockRequestHandleScope.(HttpRequestData) -> HttpResponseData,
    ): Pair<PlexClient, PlexLiveTvSupport> {
        val client = testPlexClient(
            handler,
            prioritizedEndpoints = prioritizedEndpoints,
            environment = PlexClientEnvironment(transcodeVideoCodecIds = { listOf("hevc", "h264") }),
        )
        return client to PlexLiveTvSupport(client, backgroundScope)
    }

    /** Tunes answer [tuneResponse], decisions `ok`, everything else an empty object; every request is recorded. */
    private fun TestScope.tunedLiveTv(requests: MutableList<HttpRequestData> = mutableListOf()) = liveTv { request ->
        requests += request
        when {
            request.url.encodedPath.endsWith("/tune") -> jsonResponse(tuneResponse)
            request.url.encodedPath == decisionPath -> respond("ok", HttpStatusCode.OK)
            else -> jsonResponse("{}")
        }
    }.second

    private suspend fun PlexLiveTvSupport.tune(quality: TranscodeQualityPreset = TranscodeQualityPreset.ORIGINAL): LiveTvPlaybackSession =
        assertNotNull(startPlayback("ch-1", "dvr-1", quality))

    private suspend fun LiveTvPlaybackSession.url(offsetSeconds: Long? = null) = Url(assertNotNull(streamUrlAt(offsetSeconds)))

    @Test
    fun startPlaybackWithoutADvrKeyReturnsNull() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        assertNull(tunedLiveTv(requests).startPlayback("ch-1", dvrKey = null))
        assertTrue(requests.isEmpty())
    }

    @Test
    fun startPlaybackTunesAndExposesProgramAndCaptureBufferBuildingTheUrlLazily() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val session = tunedLiveTv(requests).tune()

        assertEquals("prog-1", session.program.id)
        assertEquals(1_800_000L, session.program.durationMs)
        assertEquals(1_700_000_000L, session.program.beginsAt)
        assertEquals(1_700_000_100.0, session.captureBuffer?.startedAt)
        assertEquals(120.0, session.captureBuffer?.seekEndSeconds)
        assertTrue(session.canTimeShift)
        assertEquals(LiveTvBackgroundPolicy.RETAIN_SESSION, session.backgroundPolicy)
        // Tune only: no transcode decision until the caller asks for a URL (a watch-from-start prompt sits between).
        assertEquals(listOf("/livetv/dvrs/dvr-1/channels/ch-1/tune"), requests.map { it.url.encodedPath })
        assertEquals(HttpMethod.Post, requests.single().method)
        assertNotNull(requests.single().url.parameters["X-Plex-Session-Identifier"])
    }

    @Test
    fun aTuneTheServerRefusesIsNull() = runTest {
        var reply = """{"MediaContainer":{"status":"-1","message":"No tuners available"}}"""
        var status = 200
        val (_, liveTv) = liveTv { jsonResponse(reply, status) }

        assertNull(liveTv.startPlayback("ch-1", "dvr-1"))
        reply = """{"MediaContainer":{"Metadata":[{"ratingKey":"prog-1"}]}}"""
        assertNull(liveTv.startPlayback("ch-1", "dvr-1"), "a tune without a session key")
        reply = tuneResponse
        status = 500
        assertNull(liveTv.startPlayback("ch-1", "dvr-1"))
    }

    @Test
    fun discardingATuneStopsItsSessionWithoutWaitingForTheIdleExpiry() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val session = tunedLiveTv(requests).tune()

        session.discard()

        val timelineRequest = requests.single { it.url.encodedPath == "/:/timeline" }
        assertEquals(HttpMethod.Post, timelineRequest.method)
        val timeline = timelineRequest.url.parameters
        assertEquals("stopped", timeline["state"])
        assertEquals("/livetv/sessions/session-abc", timeline["key"])
        assertEquals(requests.first().url.parameters["X-Plex-Session-Identifier"], timeline["X-Plex-Session-Identifier"])
    }

    @Test
    fun discardNeverThrows() = runTest {
        val (_, liveTv) = liveTv { request ->
            if (request.url.encodedPath.endsWith("/tune")) jsonResponse(tuneResponse) else throw IOException("unreachable")
        }
        liveTv.tune().discard()
    }

    @Test
    fun aTuneThatAnswersAfterItsCallerGaveUpIsStoppedNotReplayed() = runTest {
        val answer = CompletableDeferred<Unit>()
        val tuneSessions = mutableListOf<String?>()
        val timelines = mutableListOf<Parameters>()
        val (_, liveTv) = liveTv { request ->
            when {
                request.url.encodedPath.endsWith("/tune") -> {
                    tuneSessions += request.url.parameters["X-Plex-Session-Identifier"]
                    answer.await()
                    jsonResponse(tuneResponse)
                }
                else -> {
                    if (request.url.encodedPath == "/:/timeline") timelines += request.url.parameters
                    jsonResponse("{}")
                }
            }
        }

        val start = async { liveTv.startPlayback("ch-1", "dvr-1") }
        advanceTimeBy(MediaServerTimeouts.TUNE)
        runCurrent()
        assertTrue(start.isCompleted, "the caller stops waiting at the tune budget")
        assertNull(start.await())
        assertTrue(timelines.isEmpty())

        answer.complete(Unit)
        runCurrent()
        assertEquals(1, tuneSessions.size, "a tune that may already be tuning is never replayed")
        val timeline = timelines.single()
        assertEquals("stopped", timeline["state"])
        assertEquals("/livetv/sessions/session-abc", timeline["key"])
        assertEquals(tuneSessions.single(), timeline["X-Plex-Session-Identifier"])
    }

    @Test
    fun aTuneStuckPastTheTransportCeilingIsAbandonedWithoutAReplay() = runTest {
        var tunes = 0
        var aborted = false
        val (_, liveTv) = liveTv {
            tunes++
            try {
                awaitCancellation()
            } finally {
                aborted = true
            }
        }

        val start = async { liveTv.startPlayback("ch-1", "dvr-1") }
        advanceTimeBy(MediaServerTimeouts.TUNE)
        runCurrent()
        assertNull(start.await())
        assertFalse(aborted, "the server may still be tuning")

        advanceTimeBy(MediaServerTimeouts.TUNE_TRANSPORT)
        runCurrent()
        assertTrue(aborted)
        assertEquals(1, tunes)
    }

    @Test
    fun aTuneWhoseConnectionDroppedIsRetriedOnce() = runTest {
        var tunes = 0
        val (_, liveTv) = liveTv {
            tunes++
            if (tunes == 1) throw IOException("Connection reset by peer")
            jsonResponse(tuneResponse)
        }

        assertNotNull(liveTv.startPlayback("ch-1", "dvr-1"))
        assertEquals(2, tunes)
    }

    @Test
    fun tuneExposesOnlyEmbeddedBitmapSubtitleStreamsAsBurnTargets() = runTest {
        val session = tunedLiveTv().tune()

        // The in-band caption rides the copied video and the sidecar can't be burned: only the DVB bitmap is listed.
        val track = session.subtitleTracks.single()
        assertEquals(92, track.id)
        assertEquals("dvb_subtitle", track.codec)
        assertEquals("fin", track.languageCode)
    }

    @Test
    fun streamUrlAtWithASubtitleTrackSelectsItOnTheTunedPartAndAsksForABurn() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val session = tunedLiveTv(requests).tune()
        val track = session.subtitleTracks.single()

        val burning = Url(assertNotNull(session.streamUrlAt(subtitleTrack = track)))
        assertEquals("burn", burning.parameters["subtitles"])
        // The burned stream is the part's server-side selection, not a `subtitleStreamID` the transcoder ignores.
        assertFalse("subtitleStreamID" in burning.parameters.names())

        fun selections() = requests.filter { it.method == HttpMethod.Put && it.url.encodedPath == "/library/parts/42" }
        assertEquals("92", selections().single().url.parameters["subtitleStreamID"])
        assertEquals("burn", requests.single { it.url.encodedPath == decisionPath }.url.parameters["subtitles"])

        // A time-shift rebuild of the same track keeps the burn without another selection.
        val shifted = Url(assertNotNull(session.streamUrlAt(offsetSeconds = 30, subtitleTrack = track)))
        assertEquals("burn", shifted.parameters["subtitles"])
        assertEquals(1, selections().size)

        // Dropping the track goes back to `none`.
        assertEquals("none", session.url().parameters["subtitles"])
    }

    @Test
    fun streamUrlAtReturnsNullWhenTheServerRefusesTheBurnSelection() = runTest {
        val decisions = mutableListOf<HttpRequestData>()
        val (_, liveTv) = liveTv { request ->
            when {
                request.url.encodedPath.endsWith("/tune") -> jsonResponse(tuneResponse)
                request.method == HttpMethod.Put && request.url.encodedPath == "/library/parts/42" -> jsonResponse("{}", status = 500)
                request.url.encodedPath == decisionPath -> {
                    decisions += request
                    respond("ok", HttpStatusCode.OK)
                }
                else -> jsonResponse("{}")
            }
        }
        val session = liveTv.tune()

        // Burning against an unconfirmed selection would weld whatever the server had stored into the picture.
        assertNull(session.streamUrlAt(subtitleTrack = session.subtitleTracks.single()))
        assertTrue(decisions.isEmpty())

        // The session stays usable without subtitles.
        assertEquals("none", session.url().parameters["subtitles"])
    }

    @Test
    fun streamUrlAtBuildsLiveEdgeAndOffsetHlsUrlsAgainstOneTranscodeSession() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val session = tunedLiveTv(requests).tune()

        val liveEdge = session.url()
        val shifted = session.url(offsetSeconds = 90)

        assertTrue(liveEdge.toString().startsWith("$TEST_BASE_URL/video/:/transcode/universal/start.m3u8?"), liveEdge.toString())
        val params = liveEdge.parameters
        assertEquals("/livetv/sessions/session-abc", params["path"])
        assertEquals("hls", params["protocol"])
        assertEquals("1", params["X-Plex-Incomplete-Segments"])
        assertFalse("X-Plex-Chunked" in params.names())
        // Live keeps the TS target with the broadcast codecs: live sessions copy HEVC and MPEG-2 channels.
        val profile = params["X-Plex-Client-Profile-Extra"]!!
        assertTrue("protocol=hls&container=mpegts" in profile, profile)
        assertTrue("videoCodec=h264%2Chevc%2Cmpeg2video" in profile, profile)
        assertEquals("none", params["subtitles"])
        assertFalse("subtitleStreamID" in params.names())
        assertFalse("advancedSubtitles" in params.names())
        assertEquals(TEST_TOKEN, params["X-Plex-Token"])
        assertFalse("offset" in params.names())
        listOf(
            "hasMDE" to "1", "mediaIndex" to "0", "partIndex" to "0", "fastSeek" to "1", "subtitleSize" to "100",
            "audioBoost" to "100", "location" to "lan", "addDebugOverlay" to "0", "autoAdjustQuality" to "0",
            "mediaBufferSize" to "157286", "copyts" to "0", "Accept-Language" to "en", "X-Plex-Platform" to "Generic",
            "X-Plex-Client-Profile-Name" to "Generic", "X-Plex-Client-Identifier" to "client-1",
        ).forEach { (name, value) -> assertEquals(value, params[name], name) }
        assertEquals(requests.first().url.parameters["X-Plex-Session-Identifier"], params["X-Plex-Session-Identifier"])

        assertEquals("90", shifted.parameters["offset"])
        // One transcode session across rebuilds, so the server reuses its capture buffer.
        assertEquals(params["session"], shifted.parameters["session"])

        // The decision carries everything in its query, none of the client's default headers.
        val decision = requests.first { it.url.encodedPath == decisionPath }
        assertNull(decision.headers["X-Plex-Token"])
        assertNull(decision.headers["X-Plex-Client-Identifier"])
        assertEquals("en", decision.headers["Accept-Language"])
        assertEquals(TEST_TOKEN, decision.url.parameters["X-Plex-Token"])
        assertEquals("/livetv/sessions/session-abc", decision.url.parameters["path"])
    }

    @Test
    fun aRefusedDecisionOrAnOffsetWithoutTimeShiftHasNoUrl() = runTest {
        var tune = tuneResponse
        val (_, liveTv) = liveTv { request ->
            when {
                request.url.encodedPath.endsWith("/tune") -> jsonResponse(tune)
                request.url.encodedPath == decisionPath -> respond("bad", HttpStatusCode.BadRequest)
                else -> jsonResponse("{}")
            }
        }
        assertNull(liveTv.tune().streamUrlAt())

        tune = tuneResponse.replace(""""TranscodeSession":[{"timeStamp":"1700000100","minOffsetAvailable":"0","maxOffsetAvailable":"120"}]""", """"size":1""")
        val withoutBuffer = liveTv.tune()
        assertFalse(withoutBuffer.canTimeShift)
        assertNull(withoutBuffer.streamUrlAt(offsetSeconds = 30))
    }

    @Test
    fun reportTimelineTargetsTheTunedProgramAndGrowsDurationToThePosition() = runTest {
        var timeline: Parameters? = null
        val (_, liveTv) = liveTv { request ->
            when (request.url.encodedPath) {
                "/:/timeline" -> {
                    timeline = request.url.parameters
                    // Once the stream plays, the top-level session is the playback transcode and the capture buffer
                    // sits under its wrapper.
                    jsonResponse(
                        """{"MediaContainer":{"TranscodeSession":[{"timeStamp":"1700000230.5","minOffsetAvailable":"0.033","maxOffsetAvailable":"12"}],""" +
                            """"CaptureBuffer":[{"TranscodeSession":[{"timeStamp":"1700000100","minOffsetAvailable":"0","maxOffsetAvailable":"300"}]}]}}""",
                    )
                }
                else -> jsonResponse(tuneResponse)
            }
        }
        val session = liveTv.tune()

        // Past the program's duration: Plex answers 400 when time > duration (short synthetic programs).
        val updated = assertNotNull(session.reportTimeline(LiveTimelineState.PLAYING, positionMs = 2_000_000, durationMs = 1_800_000))

        val params = timeline!!
        assertEquals("prog-1", params["ratingKey"])
        assertEquals("/livetv/sessions/session-abc", params["key"])
        assertEquals("playing", params["state"])
        assertEquals("1", params["hasMDE"])
        assertEquals("2000000", params["time"])
        assertEquals("2000000", params["duration"])
        assertEquals("2000000", params["playbackTime"])
        assertEquals(300.0, updated.captureBuffer?.seekEndSeconds)
        assertEquals(1_700_000_100.0, updated.captureBuffer?.startedAt)
        // The playback transcode's origin is the clock anchor; it must not be mistaken for the capture window.
        assertEquals(1_700_000_230.5, updated.playbackStream?.startedAt)
    }

    @Test
    fun reportTimelineReadsALoneTopLevelSessionAsTheCaptureBuffer() = runTest {
        val (_, liveTv) = liveTv { request ->
            when (request.url.encodedPath) {
                "/:/timeline" -> jsonResponse("""{"MediaContainer":{"TranscodeSession":[{"timeStamp":"1700000100","minOffsetAvailable":"0","maxOffsetAvailable":"300"}]}}""")
                else -> jsonResponse(tuneResponse)
            }
        }

        val updated = assertNotNull(liveTv.tune().reportTimeline(LiveTimelineState.PLAYING, positionMs = 1000, durationMs = 1_800_000))

        assertEquals(300.0, updated.captureBuffer?.seekEndSeconds)
        assertNull(updated.playbackStream)
    }

    @Test
    fun reportTimelineDoesNotFailOverBecauseItKeepsTheActiveLiveSessionAlive() = runTest {
        val paths = mutableListOf<String>()
        val (client, liveTv) = liveTv(prioritizedEndpoints = listOf(TEST_BASE_URL, "https://fallback.example.com")) { request ->
            paths += request.url.encodedPath
            when (request.url.encodedPath) {
                "/:/timeline" -> throw IOException("temporary timeline DNS failure")
                else -> jsonResponse(tuneResponse)
            }
        }
        val session = liveTv.tune()

        assertFailsWith<MediaServerHttpException> { session.reportTimeline(LiveTimelineState.PLAYING, positionMs = 10_000, durationMs = 1_800_000) }

        assertEquals(1, paths.count { it == "/:/timeline" })
        assertEquals(TEST_BASE_URL, client.config.baseUrl)
    }

    @Test
    fun recoverReTunesAndTheFreshSessionBuildsDegradedUrls() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val session = tunedLiveTv(requests).tune()

        val recovered = assertNotNull(session.recover(directStream = false, directStreamAudio = false))

        assertEquals(2, requests.count { it.url.encodedPath.endsWith("/tune") })
        val params = recovered.url().parameters
        assertEquals("0", params["directStream"])
        assertEquals("0", params["directStreamAudio"])
    }

    @Test
    fun originalQualityAsksForARemuxWithNoCeiling() = runTest {
        val params = tunedLiveTv().tune().url().parameters

        // A tuned session is reachable only through the transcoder's HLS output: no re-encode is a remux.
        assertEquals("0", params["directPlay"])
        assertEquals("1", params["directStream"])
        assertEquals("1", params["directStreamAudio"])
        assertFalse("videoResolution" in params.names())
        assertFalse("videoQuality" in params.names())
        assertFalse("add-limitation" in params["X-Plex-Client-Profile-Extra"]!!)
    }

    @Test
    fun aCappedPresetAsksForARemuxUnderABitrateCeilingAndSurvivesRecovery() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val session = tunedLiveTv(requests).tune(TranscodeQualityPreset.P720_2MBPS)

        val params = session.url().parameters

        // A ceiling, not a re-encode: the remux is still asked for so a channel that fits is copied.
        assertEquals("0", params["directPlay"])
        assertEquals("1", params["directStream"])
        assertEquals("1280x720", params["videoResolution"])
        assertEquals("60", params["videoQuality"])
        val profile = params["X-Plex-Client-Profile-Extra"]!!
        assertTrue("name=video.bitrate&value=2000" in profile, profile)
        // The ceiling can force an encode, so HEVC (broken in a TS encode) leaves the target.
        assertTrue("container=mpegts&videoCodec=h264&" in profile, profile)
        assertFalse("hevc" in profile, profile)
        val decision = requests.single { it.url.encodedPath == decisionPath }.url.parameters
        assertEquals("1280x720", decision["videoResolution"])
        assertTrue("value=2000" in decision["X-Plex-Client-Profile-Extra"]!!)

        // A re-tune keeps the cap.
        val recovered = assertNotNull(session.recover(directStream = true, directStreamAudio = true)).url().parameters
        assertEquals("1", recovered["directStream"])
        assertTrue("value=2000" in recovered["X-Plex-Client-Profile-Extra"]!!)
    }
}

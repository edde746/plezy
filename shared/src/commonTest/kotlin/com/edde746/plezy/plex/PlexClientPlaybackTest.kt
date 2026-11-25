package com.edde746.plezy.plex

import com.edde746.plezy.backend.AudioQualityPreset
import com.edde746.plezy.backend.AudioTrackPreference
import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.PlaybackException
import com.edde746.plezy.backend.PlaybackFailureReason
import com.edde746.plezy.backend.PlaybackInitializationOptions
import com.edde746.plezy.backend.PlaybackInitializationResult
import com.edde746.plezy.backend.SubtitlePreference
import com.edde746.plezy.backend.TranscodeFallbackReason
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaSubtitleTrack
import io.ktor.client.engine.mock.MockRequestHandleScope
import io.ktor.client.engine.mock.respond
import io.ktor.client.request.HttpRequestData
import io.ktor.client.request.HttpResponseData
import io.ktor.http.HttpMethod
import io.ktor.http.HttpStatusCode
import io.ktor.http.Url
import io.ktor.http.headersOf
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

class PlexClientPlaybackTest {
    private val decisionPath = "/video/:/transcode/universal/decision"

    private fun item(id: String = "42", kind: MediaKind = MediaKind.MOVIE) = MediaItem(id = id, backend = BackendKind.PLEX, kind = kind)

    private val HttpRequestData.path: String get() = url.encodedPath

    private fun HttpRequestData.query(name: String): String? = url.parameters[name]

    private fun MockRequestHandleScope.unexpected(): HttpResponseData = jsonResponse("{}", 500)

    private fun decisionBody(transcodeCode: Int = 1001, generalCode: Int? = 1001, container: String? = "mp4"): String {
        val media = container?.let { ""","Metadata":[{"Media":[{"container":"$it","protocol":"hls","selected":true}]}]""" } ?: ""
        val general = generalCode?.let { """"generalDecisionCode":$it,""" } ?: ""
        return """{"MediaContainer":{$general"transcodeDecisionCode":$transcodeCode$media}}"""
    }

    private fun metadataBody(media: String, extra: String = """"type":"movie","title":"Movie","""): String =
        """{"MediaContainer":{"Metadata":[{"ratingKey":"42",$extra"Media":$media}]}}"""

    private fun options(
        item: MediaItem = item(),
        preset: TranscodeQualityPreset = TranscodeQualityPreset.P720_3MBPS,
        selectedMediaIndex: Int = 0,
        selectedAudioStreamId: Int? = null,
        preferredAudioTrack: AudioTrackPreference? = null,
        preferredSubtitleTrack: SubtitlePreference? = null,
        forceTranscode: Boolean = false,
        audioQualityPreset: AudioQualityPreset? = null,
    ) = PlaybackInitializationOptions(
        metadata = item,
        selectedMediaIndex = selectedMediaIndex,
        qualityPreset = preset,
        audioQualityPreset = audioQualityPreset,
        selectedAudioStreamId = selectedAudioStreamId,
        preferredAudioTrack = preferredAudioTrack,
        preferredSubtitleTrack = preferredSubtitleTrack,
        sessionIdentifier = "session-id",
        transcodeSessionId = "transcode-id",
        forceTranscode = forceTranscode,
    )

    // Stream selection and burn aiming.

    @Test
    fun `selectStreams sends audio stream selection with allParts`() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ requests += it; jsonResponse("", 200) })

        assertTrue(client.selectStreams(99, audioStreamId = 301))

        val put = requests.single()
        assertEquals(HttpMethod.Put, put.method)
        assertEquals("/library/parts/99", put.path)
        assertEquals("301", put.query("audioStreamID"))
        assertEquals("1", put.query("allParts"))
        assertNull(put.query("subtitleStreamID"))
    }

    @Test
    fun `selectStreams with nothing to select sends no request`() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ requests += it; jsonResponse("", 200) })

        assertTrue(client.selectStreams(99))
        assertTrue(requests.isEmpty())
    }

    private val embeddedAss = MediaSubtitleTrack(id = 401, index = 3, codec = "ass", selected = true, forced = false)

    @Test
    fun `a burn aims at the caller track by selecting it on the part first`() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ requests += it; jsonResponse("", 200) })

        client.selectSubtitleStreamForBurn(partId = 99, track = embeddedAss)

        val put = requests.single { it.method == HttpMethod.Put }
        assertEquals("/library/parts/99", put.path)
        assertEquals("401", put.query("subtitleStreamID"))
    }

    @Test
    fun `a sidecarred external file leaves the server selection untouched`() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ requests += it; jsonResponse("", 200) })

        client.selectSubtitleStreamForBurn(
            partId = 99,
            track = MediaSubtitleTrack(id = 403, codec = "srt", selected = true, forced = false, key = "/library/streams/403", external = true),
        )
        client.selectSubtitleStreamForBurn(partId = 99, track = null)

        assertTrue(requests.isEmpty())
    }

    @Test
    fun `an unaimable burn refuses rather than letting the server pick`() = runTest {
        val client = testPlexClient({ jsonResponse("", 200) })
        assertFailsWith<IllegalStateException> { client.selectSubtitleStreamForBurn(partId = null, track = embeddedAss) }
    }

    @Test
    fun `a selection the server did not commit refuses the burn too`() = runTest {
        val client = testPlexClient({ jsonResponse("", 204) })
        assertFailsWith<IllegalStateException> { client.selectSubtitleStreamForBurn(partId = 99, track = embeddedAss) }
    }

    @Test
    fun `a burn that cannot be aimed never reaches the decision endpoint`() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ request ->
            requests += request
            jsonResponse(decisionBody(), if (request.method == HttpMethod.Put) 403 else 200)
        })

        val result = client.buildTranscodeStartPath(
            ratingKey = "42",
            mediaIndex = 0,
            preset = TranscodeQualityPreset.P720_3MBPS,
            sessionIdentifier = "session-id",
            transcodeSessionId = "transcode-id",
            partId = 99,
            selectedSubtitleTrack = embeddedAss,
        )

        assertEquals(TranscodeDecisionOutcome.FAILED, result.outcome)
        assertNull(result.startPath)
        assertTrue(requests.none { "/transcode/universal" in it.path })
    }

    // Transcode decision container gate.

    private suspend fun runGuardedDecision(containerFor: (decisionNumber: Int) -> String): Pair<PlexTranscodeStart, List<HttpRequestData>> {
        val decisions = mutableListOf<HttpRequestData>()
        val client = testPlexClient(
            { request ->
                decisions += request
                jsonResponse(decisionBody(generalCode = null, container = containerFor(decisions.size)))
            },
            environment = PlexClientEnvironment(transcodeVideoCodecIds = { listOf("av1", "hevc", "h264") }),
        )
        val result = client.buildTranscodeStartPath(
            ratingKey = "42",
            mediaIndex = 0,
            preset = TranscodeQualityPreset.P720_3MBPS,
            sessionIdentifier = "session-id",
            transcodeSessionId = "transcode-id",
        )
        return result to decisions
    }

    private fun startPathProfile(startPath: String): String = Url("https://plex.test$startPath").parameters["X-Plex-Client-Profile-Extra"]!!

    @Test
    fun `a decision that honours the fMP4 container is used without a retry`() = runTest {
        val (result, decisions) = runGuardedDecision { "mp4" }

        assertEquals(TranscodeDecisionOutcome.TRANSCODE_OK, result.outcome)
        assertEquals(1, decisions.size)
        assertEquals(decisionPath, decisions.single().path)
        assertEquals("application/json", decisions.single().headers["Accept"])
        assertTrue("container=mp4&videoCodec=av1%2Chevc%2Ch264" in startPathProfile(result.startPath!!))
        assertTrue(result.startPath!!.startsWith("/video/:/transcode/universal/start.m3u8?"))
        assertFalse("X-Plex-Token" in result.startPath!!)
    }

    @Test
    fun `the server is asked in the app language but transcode decisions and starts stay in English`() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient(
            { request ->
                requests += request
                if (request.path == decisionPath) jsonResponse(decisionBody(generalCode = null)) else jsonResponse("""{"MediaContainer":{"Stream":[]}}""")
            },
            languageCode = "de",
        )

        client.searchSubtitles("item-1", language = "en")
        assertEquals("de", requests.last().headers["Accept-Language"])
        assertEquals("de", requests.last().headers["X-Plex-Language"])

        val result = client.buildTranscodeStartPath(
            ratingKey = "42", mediaIndex = 0, preset = TranscodeQualityPreset.P720_3MBPS, sessionIdentifier = "s", transcodeSessionId = "t",
        )
        // Plezy reads the decision's text: it must be English whatever the app's language.
        val decision = requests.last()
        assertEquals(decisionPath, decision.path)
        assertEquals(listOf("en"), decision.headers.getAll("Accept-Language"))
        assertEquals("en", decision.query("X-Plex-Language"))
        val start = Url("https://plex.test${result.startPath!!}").parameters
        assertEquals("en", start["Accept-Language"])
        assertEquals("en", start["X-Plex-Language"])

        // A language switch reaches the live client's next request.
        client.applyLanguage("zh-TW")
        client.searchSubtitles("item-1", language = "en")
        assertEquals("zh-TW", requests.last().headers["Accept-Language"])
        assertEquals("zh-TW", requests.last().headers["X-Plex-Language"])
    }

    @Test
    fun `a decision that ignores the fMP4 container is retried once with the TS h264 profile`() = runTest {
        val (result, decisions) = runGuardedDecision { if (it == 1) "mkv" else "mpegts" }

        assertEquals(TranscodeDecisionOutcome.TRANSCODE_OK, result.outcome)
        assertEquals(2, decisions.size)
        assertTrue("container=mpegts&videoCodec=h264&audioCodec" in decisions[1].query("X-Plex-Client-Profile-Extra")!!)
        // The start path carries the profile the server honoured, not the ignored fMP4 one.
        assertTrue("container=mpegts&videoCodec=h264&audioCodec" in startPathProfile(result.startPath!!))
    }

    @Test
    fun `a server honouring neither container falls back to direct play instead of a mis mux`() = runTest {
        val (result, decisions) = runGuardedDecision { "mkv" }

        assertEquals(TranscodeDecisionOutcome.FAILED, result.outcome)
        assertNull(result.startPath)
        assertEquals(2, decisions.size)
    }

    @Test
    fun `a direct play only decision passes through without a container retry`() = runTest {
        val decisions = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ decisions += it; jsonResponse(decisionBody(transcodeCode = 1000, generalCode = null, container = "mkv")) })

        val result = client.buildTranscodeStartPath(
            ratingKey = "42",
            mediaIndex = 0,
            preset = TranscodeQualityPreset.P720_3MBPS,
            sessionIdentifier = "session-id",
            transcodeSessionId = "transcode-id",
        )

        assertEquals(TranscodeDecisionOutcome.DIRECT_PLAY_ONLY, result.outcome)
        assertEquals(1, decisions.size)
    }

    @Test
    fun `a non 200 decision fails without a path`() = runTest {
        val client = testPlexClient({ jsonResponse("{}", 400) })

        val result = client.buildTranscodeStartPath(
            ratingKey = "42",
            mediaIndex = 0,
            preset = TranscodeQualityPreset.P720_3MBPS,
            sessionIdentifier = "session-id",
            transcodeSessionId = "transcode-id",
        )

        assertEquals(PlexTranscodeStart(null, TranscodeDecisionOutcome.FAILED), result)
    }

    // Transcode audio and subtitles.

    private val audioMedia = """[{"id":7,"container":"mkv","Part":[{"id":99,"key":"/library/parts/99/file.mkv","Stream":[
        {"streamType":1,"id":300,"codec":"h264"},
        {"streamType":2,"id":301,"index":0,"codec":"aac","languageCode":"eng","title":"Original","selected":true},
        {"streamType":2,"id":305,"index":1,"codec":"flac","languageCode":"jpn","title":"Main"}]}]}]"""

    private suspend fun initializeTranscodeAudio(
        selectedAudioStreamId: Int? = null,
        preferredAudioTrack: AudioTrackPreference? = null,
    ): Pair<PlaybackInitializationResult, HttpRequestData> {
        var decision: HttpRequestData? = null
        val client = testPlexClient({ request ->
            when (request.path) {
                "/library/metadata/42" -> jsonResponse(metadataBody(audioMedia, """"type":"episode","title":"Episode","""))
                decisionPath -> {
                    decision = request
                    jsonResponse(decisionBody())
                }
                else -> unexpected()
            }
        })
        val result = client.getPlaybackInitialization(
            options(item(kind = MediaKind.EPISODE), selectedAudioStreamId = selectedAudioStreamId, preferredAudioTrack = preferredAudioTrack),
        )
        return result to decision!!
    }

    @Test
    fun `semantic carried audio is sent to the Plex transcode decision`() = runTest {
        val (result, decision) = initializeTranscodeAudio(
            preferredAudioTrack = AudioTrackPreference(language = "jpn", title = "Main", codec = "flac"),
        )

        assertEquals("305", decision.query("audioStreamID"))
        assertEquals(305, result.activeAudioStreamId)
    }

    @Test
    fun `explicit Plex audio stream wins over a conflicting semantic carry`() = runTest {
        val (result, decision) = initializeTranscodeAudio(
            selectedAudioStreamId = 301,
            preferredAudioTrack = AudioTrackPreference(language = "jpn", title = "Main", codec = "flac"),
        )

        assertEquals("301", decision.query("audioStreamID"))
        assertEquals(301, result.activeAudioStreamId)
    }

    @Test
    fun `unresolvable semantic audio carry lets the Plex transcoder choose the stream`() = runTest {
        val (result, decision) = initializeTranscodeAudio(preferredAudioTrack = AudioTrackPreference(language = "swe"))

        assertNull(decision.query("audioStreamID"))
        assertNull(result.activeAudioStreamId)
    }

    private val subtitleMedia = """[{"id":7,"container":"mkv","Part":[{"id":99,"key":"/library/parts/99/file.mkv","Stream":[
        {"streamType":1,"id":300,"codec":"h264"},
        {"streamType":2,"id":301,"index":0,"languageCode":"jpn","selected":true},
        {"streamType":3,"id":401,"index":1,"codec":"ass","languageCode":"eng","selected":true},
        {"streamType":3,"id":402,"index":2,"codec":"srt","languageCode":"swe","key":"/library/streams/402","external":true}]}]}]"""

    @Test
    fun `transcode initialization burns the selected embedded stream and sidecars only the external file`() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ request ->
            requests += request
            when {
                request.path == "/library/metadata/42" -> jsonResponse(metadataBody(subtitleMedia))
                request.path == decisionPath -> jsonResponse(decisionBody())
                request.method == HttpMethod.Put && request.path == "/library/parts/99" -> jsonResponse("", 200)
                else -> unexpected()
            }
        })

        val result = client.getPlaybackInitialization(options())

        val decision = requests.single { it.path == decisionPath }
        assertEquals("burn", decision.query("subtitles"))
        assertNull(decision.query("offset"))
        assertNull(decision.query("subtitleStreamID"))
        assertEquals("1", decision.query("X-Plex-Incomplete-Segments"))
        val selection = requests.single { it.method == HttpMethod.Put }
        assertEquals("401", selection.query("subtitleStreamID"))
        assertNull(selection.query("audioStreamID"))
        assertTrue(result.isTranscoding)
        assertEquals("Transcode", result.playMethod)
        assertEquals("session-id", result.playSessionId)
        assertTrue(result.videoUrl!!.startsWith("$TEST_BASE_URL/video/:/transcode/universal/start.m3u8?"))
        assertTrue(result.videoUrl!!.endsWith("X-Plex-Token=$TEST_TOKEN"))
        assertEquals(listOf(402), result.subtitleSidecars.map { it.sourceStreamId })
        assertTrue(result.subtitleSidecars.single().preload)
        assertEquals("$TEST_BASE_URL/library/streams/402.srt?encoding=utf-8&X-Plex-Token=$TEST_TOKEN", result.subtitleSidecars.single().track.url)
    }

    @Test
    fun `tokenless transcode still sidecars the external subtitle file`() = runTest {
        val client = testPlexClient(
            { request ->
                when {
                    request.path == "/library/metadata/42" -> jsonResponse(metadataBody(subtitleMedia))
                    request.path == decisionPath -> jsonResponse(decisionBody())
                    request.method == HttpMethod.Put -> jsonResponse("", 200)
                    else -> unexpected()
                }
            },
            token = null,
        )

        val result = client.getPlaybackInitialization(options())

        assertTrue(result.isTranscoding)
        assertEquals("$TEST_BASE_URL/library/streams/402.srt?encoding=utf-8", result.subtitleSidecars.single().track.url)
    }

    @Test
    fun `direct play preloads every external subtitle file not just the selected one`() = runTest {
        val media = """[{"id":7,"container":"mp4","Part":[{"id":99,"key":"/library/parts/99/file.mp4","Stream":[
            {"streamType":1,"id":300,"codec":"h264"},
            {"streamType":3,"id":401,"index":1,"codec":"srt","languageCode":"deu","key":"/library/streams/401","external":true,"selected":true},
            {"streamType":3,"id":402,"index":2,"codec":"srt","languageCode":"fra","key":"/library/streams/402","external":true},
            {"streamType":3,"id":403,"index":3,"codec":"ass","languageCode":"eng"}]}]}]"""
        val client = testPlexClient({ if (it.path == "/library/metadata/42") jsonResponse(metadataBody(media)) else unexpected() })

        val result = client.getPlaybackInitialization(options(preset = TranscodeQualityPreset.ORIGINAL))

        assertEquals("DirectPlay", result.playMethod)
        assertNull(result.fallbackReason)
        assertEquals(listOf(401, 402), result.subtitleSidecars.map { it.sourceStreamId })
        assertTrue(result.subtitleSidecars.all { it.preload })
        assertEquals(listOf(true, false), result.subtitleSidecars.map { it.track.isDefault })
    }

    private val teletextMedia = """[{"id":1,"Part":[{"id":11,"key":"/library/parts/11/file.mkv","Stream":[
        {"id":31,"streamType":3,"index":2,"codec":"dvb_teletext","language":"English"}]}]}]"""

    private suspend fun initializeTeletext(decision: String): PlaybackInitializationResult {
        val client = testPlexClient({ request ->
            when (request.path) {
                "/library/metadata/42" -> jsonResponse(metadataBody(teletextMedia))
                decisionPath -> jsonResponse(decision)
                else -> unexpected()
            }
        })
        return client.getPlaybackInitialization(
            options(preferredSubtitleTrack = SubtitlePreference.Track(codec = "dvb_teletext", sourceStreamId = 31)),
        )
    }

    @Test
    fun `an embedded subtitle this server cannot burn falls back as a failure`() = runTest {
        val result = initializeTeletext("""{"MediaContainer":{"generalDecisionCode":1000,"transcodeDecisionCode":1000}}""")

        assertEquals("DirectPlay", result.playMethod)
        assertNotNull(result.fallbackReason)
    }

    @Test
    fun `a valid transcode is refused when it cannot carry the selected subtitle`() = runTest {
        val result = initializeTeletext("""{"MediaContainer":{"generalDecisionCode":1001,"transcodeDecisionCode":1001}}""")

        assertFalse(result.isTranscoding)
        assertEquals("DirectPlay", result.playMethod)
    }

    @Test
    fun `the transcode decision targets the resolved media and part not the first ones`() = runTest {
        val media = """[
            {"id":7,"container":"mkv","bitrate":13137,"height":1080,"Part":[{"id":10,"key":"/library/parts/10/file.mkv"}]},
            {"id":8,"container":"mkv","bitrate":13137,"height":1080,"Part":[
                {"id":20,"key":"/library/parts/20/file.mkv","exists":0,"accessible":1},
                {"id":21,"key":"/library/parts/21/file.mkv","exists":1,"accessible":1}]}]"""
        var decision: HttpRequestData? = null
        val client = testPlexClient({ request ->
            when (request.path) {
                "/library/metadata/42" -> jsonResponse(metadataBody(media))
                decisionPath -> {
                    decision = request
                    jsonResponse(decisionBody(generalCode = null))
                }
                else -> unexpected()
            }
        })

        val result = client.getPlaybackInitialization(options(preset = TranscodeQualityPreset.P1080_10MBPS, selectedMediaIndex = 1))

        assertEquals("Transcode", result.playMethod)
        assertEquals(1, result.selectedMediaIndex)
        assertEquals("1", decision!!.query("mediaIndex"))
        assertEquals("1", decision!!.query("partIndex"))
    }

    // Preset coverage, forced transcode, refused codecs.

    private class CappedRun(val result: PlaybackInitializationResult, val paths: List<String>, val decisions: List<HttpRequestData>)

    private suspend fun initializeCappedPlayback(
        preset: TranscodeQualityPreset,
        bitrateKbps: Int,
        height: Int,
        videoCodec: String? = null,
        forceTranscode: Boolean = false,
        transcodeDecisionCode: Int = 1001,
        environment: PlexClientEnvironment = PlexClientEnvironment(),
    ): CappedRun {
        val paths = mutableListOf<String>()
        val decisions = mutableListOf<HttpRequestData>()
        val codec = videoCodec?.let { """"videoCodec":"$it",""" } ?: ""
        val media = """[{"id":7,"container":"mkv","bitrate":$bitrateKbps,"height":$height,$codec"Part":[{"id":99,"key":"/library/parts/99/file.mkv"}]}]"""
        val client = testPlexClient(
            { request ->
                paths += request.path
                when (request.path) {
                    "/library/metadata/42" -> jsonResponse(metadataBody(media, ""))
                    decisionPath -> {
                        decisions += request
                        jsonResponse(decisionBody(transcodeCode = transcodeDecisionCode, generalCode = null))
                    }
                    else -> unexpected()
                }
            },
            environment = environment,
        )
        val result = client.getPlaybackInitialization(options(preset = preset, forceTranscode = forceTranscode))
        return CappedRun(result, paths, decisions)
    }

    @Test
    fun `a preset the source already fits under plays the file itself issue 2152`() = runTest {
        val run = initializeCappedPlayback(TranscodeQualityPreset.P1080_10MBPS, bitrateKbps = 6206, height = 1080)

        assertFalse(decisionPath in run.paths)
        assertFalse(run.result.isTranscoding)
        assertEquals("DirectPlay", run.result.playMethod)
        assertTrue("/library/parts/99/file.mkv" in run.result.videoUrl!!)
        assertNull(run.result.fallbackReason)
    }

    @Test
    fun `a source the preset would actually reduce still transcodes`() = runTest {
        val overBitrate = initializeCappedPlayback(TranscodeQualityPreset.P1080_10MBPS, bitrateKbps = 13137, height = 1080)
        assertTrue(decisionPath in overBitrate.paths)
        assertEquals("Transcode", overBitrate.result.playMethod)

        val overResolution = initializeCappedPlayback(TranscodeQualityPreset.P1080_10MBPS, bitrateKbps = 6534, height = 2160)
        assertTrue(decisionPath in overResolution.paths)
        assertEquals("Transcode", overResolution.result.playMethod)
    }

    @Test
    fun `turning the covered source direct play off keeps the requested transcode issue 2193`() = runTest {
        val run = initializeCappedPlayback(
            TranscodeQualityPreset.P1080_20MBPS,
            bitrateKbps = 15900,
            height = 1080,
            environment = PlexClientEnvironment(directPlayCoveredQuality = { false }),
        )

        assertTrue(decisionPath in run.paths)
        assertTrue(run.result.isTranscoding)
        assertEquals("Transcode", run.result.playMethod)
    }

    @Test
    fun `a forced transcode at Original withholds direct play and leaves the output to the server`() = runTest {
        val run = initializeCappedPlayback(TranscodeQualityPreset.ORIGINAL, bitrateKbps = 32123, height = 2160, forceTranscode = true)

        assertEquals("Transcode", run.result.playMethod)
        assertTrue(run.result.isTranscoding)
        assertTrue("/video/:/transcode/universal/start.m3u8" in run.result.videoUrl!!)
        val decision = run.decisions.single()
        assertEquals("0", decision.query("directPlay"))
        assertEquals("1", decision.query("directStream"))
        assertNull(decision.query("videoResolution"))
        assertNull(decision.query("videoQuality"))
        assertFalse("add-limitation" in decision.query("X-Plex-Client-Profile-Extra")!!)
    }

    @Test
    fun `a forced transcode the server refuses throws instead of handing back the file`() = runTest {
        val error = assertFailsWith<PlaybackException> {
            initializeCappedPlayback(TranscodeQualityPreset.ORIGINAL, bitrateKbps = 32123, height = 2160, forceTranscode = true, transcodeDecisionCode = 4002)
        }
        assertEquals(PlaybackFailureReason.NO_PLAYABLE_SOURCE, error.reason)
    }

    @Test
    fun `an unforced Original stays on direct play`() = runTest {
        val run = initializeCappedPlayback(TranscodeQualityPreset.ORIGINAL, bitrateKbps = 32123, height = 2160)

        assertTrue(run.decisions.isEmpty())
        assertEquals("DirectPlay", run.result.playMethod)
        assertTrue("/library/parts/99/file.mkv" in run.result.videoUrl!!)
    }

    @Test
    fun `an unforced refused transcode still falls back to the file`() = runTest {
        val run = initializeCappedPlayback(TranscodeQualityPreset.P1080_8MBPS, bitrateKbps = 49138, height = 2160, transcodeDecisionCode = 4002)

        assertEquals(1, run.decisions.size)
        assertEquals("DirectPlay", run.result.playMethod)
        assertEquals(TranscodeFallbackReason.DECISION_FAILED, run.result.fallbackReason)
    }

    private val refusingHevc = PlexClientEnvironment(
        transcodeVideoCodecIds = { listOf("av1", "h264") },
        isVideoCodecRefused = { it == "hevc" || it == "h265" },
    )

    @Test
    fun `a codec refused in settings is transcoded at Original quality instead of played from the file issue 2443`() = runTest {
        val run = initializeCappedPlayback(TranscodeQualityPreset.ORIGINAL, bitrateKbps = 3029, height = 1080, videoCodec = "hevc", environment = refusingHevc)

        assertEquals("Transcode", run.result.playMethod)
        assertTrue(run.result.isTranscoding)
        val decision = run.decisions.single()
        assertEquals("0", decision.query("directPlay"))
        assertEquals("1", decision.query("directStream"))
        assertNull(decision.query("videoResolution"))
        val profile = decision.query("X-Plex-Client-Profile-Extra")!!
        assertTrue("container=mp4&videoCodec=av1%2Ch264&" in profile)
        assertFalse("video.bitrate" in profile)
    }

    @Test
    fun `a refused codec is transcoded even under a preset that covers the source`() = runTest {
        val run = initializeCappedPlayback(TranscodeQualityPreset.P1080_10MBPS, bitrateKbps = 6206, height = 1080, videoCodec = "h265", environment = refusingHevc)

        assertEquals("Transcode", run.result.playMethod)
        assertFalse("hevc" in run.decisions.single().query("X-Plex-Client-Profile-Extra")!!)
    }

    @Test
    fun `a codec refusal leaves every other codec on direct play`() = runTest {
        val run = initializeCappedPlayback(TranscodeQualityPreset.ORIGINAL, bitrateKbps = 12514, height = 1080, videoCodec = "h264", environment = refusingHevc)

        assertTrue(run.decisions.isEmpty())
        assertEquals("DirectPlay", run.result.playMethod)
    }

    // Music.

    private val trackBody = """{"MediaContainer":{"Metadata":[{"ratingKey":"9669","type":"track","title":"Track","Media":[{"id":7,"container":"flac",
        "Part":[{"id":99,"key":"/library/parts/99/1700000000/file.flac","Stream":[{"streamType":2,"id":301,"codec":"flac","selected":true}]}]}]}]}}"""

    @Test
    fun `a direct play track names its playback session in the stream URL`() = runTest {
        val client = testPlexClient({ if (it.path == "/library/metadata/9669") jsonResponse(trackBody) else unexpected() })

        val result = client.getPlaybackInitialization(
            options(item("9669", MediaKind.TRACK), preset = TranscodeQualityPreset.ORIGINAL, audioQualityPreset = AudioQualityPreset.ORIGINAL),
        )

        val url = Url(result.videoUrl!!)
        assertEquals("/library/parts/99/1700000000/file.flac", url.encodedPath)
        assertEquals("session-id", url.parameters["X-Plex-Session-Identifier"])
        assertEquals(TEST_TOKEN, url.parameters["X-Plex-Token"])
    }

    @Test
    fun `a capped track transcodes through the music decision`() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ request ->
            requests += request
            when (request.path) {
                "/library/metadata/9669" -> jsonResponse(trackBody)
                "/music/:/transcode/universal/decision" -> jsonResponse("""{"MediaContainer":{"generalDecisionCode":1001}}""")
                else -> unexpected()
            }
        })

        val result = client.getPlaybackInitialization(options(item("9669", MediaKind.TRACK), audioQualityPreset = AudioQualityPreset.LOW))

        assertEquals("Transcode", result.playMethod)
        assertTrue(result.videoUrl!!.startsWith("$TEST_BASE_URL/music/:/transcode/universal/start.mp3?"))
        assertEquals("128", requests.last().query("musicBitrate"))
    }

    // Playback metadata.

    private val streamDetailedMedia = """[{"id":7,"container":"mkv","Part":[{"id":99,"key":"/library/parts/99/file.mkv","exists":true,"accessible":true,
        "Stream":[{"streamType":1,"id":300,"codec":"h264"},{"streamType":3,"id":401,"index":1,"codec":"ass","languageCode":"eng","selected":true}]}]}]"""

    private suspend fun MemoryApiCacheStore.seed(body: String, endpoint: String = "/library/metadata/42") =
        put(testProfileScope.value, endpoint, Json.parseToJsonElement(body).jsonObject)

    @Test
    fun `playback metadata request includes streams for transcode sidecar subtitles`() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ requests += it; jsonResponse(metadataBody(subtitleMedia)) })

        val data = client.getVideoPlaybackData("42")

        val request = requests.single()
        assertEquals("1", request.query("includeStreams"))
        assertEquals("1", request.query("checkFiles"))
        assertEquals("1", request.query("includeMarkers"))
        assertEquals("1", request.query("includeChapters"))
        assertNull(request.query("checkFileAvailability"))
        assertEquals(listOf(401, 402), data.mediaInfo?.subtitleTracks?.map { it.id })
    }

    @Test
    fun `fresh stream rich cached row is served with zero network requests`() = runTest {
        val store = MemoryApiCacheStore().apply { seed(metadataBody(streamDetailedMedia)) }
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ requests += it; jsonResponse(metadataBody(streamDetailedMedia)) }, store = store)

        val data = client.getVideoPlaybackData("42")

        assertTrue(requests.isEmpty())
        assertTrue("/library/parts/99/file.mkv" in data.videoUrl!!)
        assertEquals(401, data.mediaInfo?.subtitleTracks?.single()?.id)
    }

    @Test
    fun `forceRefresh bypasses a fresh stream rich cached row`() = runTest {
        val store = MemoryApiCacheStore().apply { seed(metadataBody(streamDetailedMedia)) }
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ requests += it; jsonResponse(metadataBody(streamDetailedMedia)) }, store = store)

        client.getVideoPlaybackData("42", forceRefresh = true)

        assertEquals("1", requests.single().query("includeStreams"))
    }

    @Test
    fun `fresh but stream less cached row still fetches from the network`() = runTest {
        val store = MemoryApiCacheStore().apply {
            seed(metadataBody("""[{"id":7,"container":"mkv","Part":[{"id":99,"key":"/library/parts/99/file.mkv"}]}]"""))
        }
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ requests += it; jsonResponse(metadataBody(streamDetailedMedia)) }, store = store)

        val data = client.getVideoPlaybackData("42")

        assertEquals(1, requests.size)
        assertEquals(401, data.mediaInfo?.subtitleTracks?.single()?.id)
    }

    @Test
    fun `cached row older than the freshness window fetches from the network`() = runTest {
        val store = MemoryApiCacheStore().apply { seed(metadataBody(streamDetailedMedia)) }
        store.now = { (5.minutes + 1.seconds).inWholeMilliseconds }
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ requests += it; jsonResponse(metadataBody(streamDetailedMedia)) }, store = store)

        assertTrue(client.getVideoPlaybackData("42").hasValidVideoUrl)
        assertEquals(1, requests.size)
    }

    @Test
    fun `playback uses metadata availability flags without probing part URLs`() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val media = """[{"id":7,"container":"mkv","Part":[
            {"id":10,"key":"/library/parts/10/file.mkv","exists":0,"accessible":1},
            {"id":20,"key":"/library/parts/20/file.mkv","exists":1,"accessible":1}]}]"""
        val client = testPlexClient({ requests += it; jsonResponse(metadataBody(media)) })

        val data = client.getVideoPlaybackData("42")

        assertEquals(1, requests.size)
        assertEquals("$TEST_BASE_URL/library/parts/20/file.mkv?X-Plex-Token=$TEST_TOKEN", data.videoUrl)
        assertEquals(0, data.selectedMediaIndex)
        assertEquals(1, data.selectedPartIndex)
    }

    @Test
    fun `network failure falls back to profile scoped lean cached playback metadata`() = runTest {
        val store = MemoryApiCacheStore().apply {
            seed(
                metadataBody(
                    """[{"id":7,"Part":[{"id":10,"key":"/library/parts/10/stale.mkv"}]},{"id":8,"Part":[{"id":20,"key":"/library/parts/20/current.mkv"}]}]""",
                ),
            )
        }
        var requests = 0
        val client = testPlexClient({ requests++; throw IllegalStateException("offline") }, store = store)

        val data = client.getVideoPlaybackData("42")

        assertEquals(1, requests)
        assertEquals("$TEST_BASE_URL/library/parts/10/stale.mkv?X-Plex-Token=$TEST_TOKEN", data.videoUrl)
        assertEquals(2, data.availableVersions.size)
    }

    @Test
    fun `playback initialization exposes effective selected media index`() = runTest {
        val media = """[
            {"id":7,"Part":[{"id":10,"key":"/library/parts/10/stale.mkv","exists":false,"accessible":false}]},
            {"id":8,"Part":[{"id":20,"key":"/library/parts/20/current.mkv","exists":true,"accessible":true}]}]"""
        val client = testPlexClient({ jsonResponse(metadataBody(media)) })

        val result = client.getPlaybackInitialization(options(preset = TranscodeQualityPreset.ORIGINAL))

        assertEquals("$TEST_BASE_URL/library/parts/20/current.mkv?X-Plex-Token=$TEST_TOKEN", result.videoUrl)
        assertEquals(1, result.selectedMediaIndex)
    }

    // Playback metadata failure contract.

    private val playableBody = metadataBody("""[{"id":7,"Part":[{"id":10,"key":"/library/parts/10/file.mkv"}]}]""")
    private val noPartBody = metadataBody("""[{"id":7,"Part":[]}]""")

    private suspend fun PlexClient.initializationFailure(): PlaybackException =
        assertFailsWith<PlaybackException> { getPlaybackInitialization(options(preset = TranscodeQualityPreset.ORIGINAL)) }

    @Test
    fun `raw helper preserves 401 while initialization classifies authentication`() = runTest {
        val client = testPlexClient({ jsonResponse("""{"error":"body-canary"}""", 401) })

        assertEquals(401, assertFailsWith<MediaServerHttpException> { client.getVideoPlaybackData("42") }.statusCode)
        val failure = client.initializationFailure()
        assertEquals(PlaybackFailureReason.AUTHENTICATION_REQUIRED, failure.reason)
        assertFalse("body-canary" in failure.message.orEmpty())
    }

    @Test
    fun `raw timeout survives and initialization classifies server unavailable`() = runTest {
        val client = testPlexClient({ throw MediaServerHttpException(MediaServerHttpErrorType.RECEIVE_TIMEOUT, "timeout-canary") })

        assertEquals(MediaServerHttpErrorType.RECEIVE_TIMEOUT, assertFailsWith<MediaServerHttpException> { client.getVideoPlaybackData("42") }.type)
        val failure = client.initializationFailure()
        assertEquals(PlaybackFailureReason.SERVER_UNAVAILABLE, failure.reason)
        assertFalse("timeout-canary" in failure.message.orEmpty())
    }

    @Test
    fun `successful malformed envelope Media and Part collections are invalid data`() = runTest {
        val bodies = listOf(
            """{"notMediaContainer":true}""",
            """{"MediaContainer":{"Metadata":[{"Media":"payload-canary"}]}}""",
            """{"MediaContainer":{"Metadata":[{"Media":[{"Part":"payload-canary"}]}]}}""",
        )
        for (body in bodies) {
            val client = testPlexClient({ jsonResponse(body) })
            assertFailsWith<IllegalArgumentException> { client.getVideoPlaybackData("42") }
            val failure = client.initializationFailure()
            assertEquals(PlaybackFailureReason.INVALID_PLAYBACK_DATA, failure.reason, body)
            assertFalse("payload-canary" in failure.toString())
        }
    }

    @Test
    fun `playback validation preserves singleton and mixed valid Media and Part shapes`() = runTest {
        val bodies = listOf(
            """{"MediaContainer":{"Metadata":[{"Media":{"id":7,"Part":{"id":10,"key":"/library/parts/10/singleton.mkv"}}}]}}""",
            """{"MediaContainer":{"Metadata":[{"Media":["ignored",{"id":7,"Part":["ignored",{"id":10,"key":"/library/parts/10/mixed.mkv"}]}]}]}}""",
        )
        for (body in bodies) {
            val data = testPlexClient({ jsonResponse(body) }).getVideoPlaybackData("42")
            assertTrue("/library/parts/10/" in data.videoUrl.orEmpty(), body)
        }
    }

    @Test
    fun `invalid JSON and non object top level data classify as invalid playback data`() = runTest {
        for (body in listOf("{", "[]")) {
            val failure = testPlexClient({ jsonResponse(body) }).initializationFailure()
            assertEquals(PlaybackFailureReason.INVALID_PLAYBACK_DATA, failure.reason, body)
        }
    }

    @Test
    fun `valid metadata without a part remains noPlayableSource`() = runTest {
        val client = testPlexClient({ jsonResponse(noPartBody) })

        assertFalse(client.getVideoPlaybackData("42").hasValidVideoUrl)
        assertEquals(PlaybackFailureReason.NO_PLAYABLE_SOURCE, client.initializationFailure().reason)
    }

    @Test
    fun `auth server malformed and no source failures expose distinct reasons and messages`() = runTest {
        val failures = listOf(
            testPlexClient({ jsonResponse("{}", 401) }),
            testPlexClient({ jsonResponse("{}", 500) }),
            testPlexClient({ jsonResponse("""{"MediaContainer":"invalid"}""") }),
            testPlexClient({ jsonResponse(noPartBody) }),
        ).map { it.initializationFailure() }

        assertEquals(
            setOf(
                PlaybackFailureReason.AUTHENTICATION_REQUIRED,
                PlaybackFailureReason.SERVER_UNAVAILABLE,
                PlaybackFailureReason.INVALID_PLAYBACK_DATA,
                PlaybackFailureReason.NO_PLAYABLE_SOURCE,
            ),
            failures.map { it.reason }.toSet(),
        )
        assertEquals(4, failures.map { it.message }.toSet().size)
    }

    @Test
    fun `500 and connection failure never become no source`() = runTest {
        val server = testPlexClient({ jsonResponse("{}", 500) })
        val connection = testPlexClient({ throw MediaServerHttpException(MediaServerHttpErrorType.CONNECTION_ERROR, "unavailable") })

        assertEquals(PlaybackFailureReason.SERVER_UNAVAILABLE, server.initializationFailure().reason)
        assertEquals(PlaybackFailureReason.SERVER_UNAVAILABLE, connection.initializationFailure().reason)
    }

    @Test
    fun `status failure still serves a valid cached playable row`() = runTest {
        val store = MemoryApiCacheStore().apply { seed(playableBody) }
        val client = testPlexClient({ jsonResponse("{}", 500) }, store = store)

        val data = client.getVideoPlaybackData("42")

        assertTrue("/library/parts/10/file.mkv" in data.videoUrl!!)
    }

    @Test
    fun `external URL and download resolution propagate typed request failures`() = runTest {
        val client = testPlexClient({ jsonResponse("{}", 401) })

        assertFailsWith<MediaServerHttpException> { client.resolveExternalPlayback(item(), 0, null, null) }
        assertFailsWith<MediaServerHttpException> { client.resolveDownload(item(), 0, null) }
    }

    // External players and downloads.

    @Test
    fun `external players get every sidecar file with the selected one enabled issue 2464`() = runTest {
        val media = """[{"id":7,"container":"mkv","Part":[{"id":99,"key":"/library/parts/99/file.mkv","Stream":[
            {"streamType":1,"id":300,"codec":"h264"},
            {"streamType":3,"id":400,"index":2,"codec":"ass","languageCode":"jpn"},
            {"streamType":3,"id":401,"codec":"srt","languageCode":"deu","key":"/library/streams/401","external":true},
            {"streamType":3,"id":402,"codec":"ass","languageCode":"eng","key":"/library/streams/402","external":true,"selected":true}]}]}]"""
        val client = testPlexClient({ if (it.path == "/library/metadata/42") jsonResponse(metadataBody(media)) else unexpected() })

        val target = client.resolveExternalPlayback(item(), 0, null, null)!!

        assertTrue("/library/parts/99/file.mkv" in target.url)
        val urls = target.subtitles.map { Url(it.url) }
        assertEquals(listOf("/library/streams/401.srt", "/library/streams/402.ass"), urls.map { it.encodedPath })
        // An external player cannot send the auth header.
        assertTrue(urls.all { it.parameters["X-Plex-Token"] == TEST_TOKEN })
        assertEquals(listOf(false, true), target.subtitles.map { it.isDefault })
    }

    @Test
    fun `a download rejects a requested source that is no longer selected`() = runTest {
        val client = testPlexClient({ jsonResponse(playableBody) })

        assertFailsWith<IllegalStateException> { client.resolveDownload(item(), 0, "999") }
        assertEquals("$TEST_BASE_URL/library/parts/10/file.mkv?X-Plex-Token=$TEST_TOKEN", client.resolveDownload(item(), 0, null).videoUrl)
    }

    // Subtitle search.

    @Test
    fun `searchSubtitles throws on HTTP 500 instead of reporting no results`() = runTest {
        val client = testPlexClient({ jsonResponse("{}", 500) })

        assertEquals(500, assertFailsWith<MediaServerHttpException> { client.searchSubtitles("item-1", language = "en") }.statusCode)
    }

    @Test
    fun `searchSubtitles sends the search and reads flexible results`() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({
            requests += it
            jsonResponse(
                """{"MediaContainer":{"Stream":[{"id":"7","key":"/sub/7","codec":"srt","languageCode":"en","score":"8.5",
                    "providerTitle":"OpenSubtitles","hearingImpaired":"1","perfectMatch":true}]}}""",
            )
        })

        val results = client.searchSubtitles("item-1", language = "en", title = "")

        val request = requests.single()
        assertEquals("/library/metadata/item-1/subtitles", request.path)
        assertEquals("en", request.query("language"))
        assertNull(request.query("title"))
        assertEquals("0", request.query("hearingImpaired"))
        assertEquals("0", request.query("forced"))
        assertEquals(
            PlexSubtitleSearchResult(
                id = 7,
                key = "/sub/7",
                codec = "srt",
                languageCode = "en",
                score = 8.5,
                providerTitle = "OpenSubtitles",
                hearingImpaired = true,
                perfectMatch = true,
            ),
            results.single(),
        )
    }

    @Test
    fun `downloadSubtitle puts the chosen result on the item`() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ requests += it; jsonResponse("", 200) })

        assertTrue(client.downloadSubtitle("42", key = "/sub/7", codec = "srt", language = "en", hearingImpaired = true, forced = false, providerTitle = "OS"))

        val put = requests.single()
        assertEquals(HttpMethod.Put, put.method)
        assertEquals("/library/metadata/42/subtitles", put.path)
        assertEquals("1", put.query("hearingImpaired"))
        assertEquals("0", put.query("forced"))
        assertEquals("OS", put.query("providerTitle"))
    }

    // Transcode keepalive.

    @Test
    fun `transcode keepalive pings the session and swallows failures`() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ requests += it; jsonResponse("{}", 500) })

        client.pingTranscodeSession("transcode-id")

        assertEquals("/video/:/transcode/universal/ping", requests.single().path)
        assertEquals("transcode-id", requests.single().query("session"))
    }

    // Instant mix.

    @Test
    fun `fetchInstantMix propagates a failed station play queue as a typed error issue 2141`() = runTest {
        val client = testPlexClient({ respond("boom", HttpStatusCode.InternalServerError) }, machineIdentifier = "machine-1")

        assertEquals(500, assertFailsWith<MediaServerHttpException> { client.fetchInstantMix("track-1", 100) }.statusCode)
    }

    // Lyrics.

    @Test
    fun `lyrics parse Plex structured responses with singleton media shapes`() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ request ->
            requests += request
            when (request.path) {
                "/library/metadata/track-1" -> jsonResponse(
                    """{"MediaContainer":{"Metadata":[{"ratingKey":"track-1","type":"track","Media":{"Part":{"Stream":
                        {"id":"501","key":"/library/streams/501","streamType":"4","codec":"lrc","format":"lrc"}}}}]}}""",
                )
                "/library/streams/501" -> respond(
                    """<?xml version="1.0" encoding="UTF-8"?>
                    <MediaContainer size="1"><Lyrics timed="1">
                    <Line startOffset="500"><Span text="First line" /></Line>
                    <Line startOffset="4000"><Span text="Second " /><Span text="line" /></Line>
                    </Lyrics></MediaContainer>""",
                    HttpStatusCode.OK,
                    headersOf("Content-Type", "application/xml"),
                )
                else -> jsonResponse("{}", 404)
            }
        })

        val lyrics = client.fetchLyrics(item("track-1", MediaKind.TRACK))!!

        assertTrue(lyrics.synced)
        assertEquals(listOf("First line", "Second line"), lyrics.lines.map { it.text })
        assertEquals(listOf(500L, 4000L), lyrics.lines.map { it.startMs })
        assertEquals(listOf("/library/metadata/track-1", "/library/streams/501"), requests.map { it.path })
        assertEquals("xml", requests.last().query("format"))
        assertEquals("application/xml", requests.last().headers["Accept"])
    }

    @Test
    fun `lyrics refresh incomplete cached metadata and prefer LRC streams`() = runTest {
        val store = MemoryApiCacheStore().apply {
            seed("""{"MediaContainer":{"Metadata":[{"ratingKey":"track-1","type":"track"}]}}""", "/library/metadata/track-1")
        }
        val paths = mutableListOf<String>()
        val client = testPlexClient(
            { request ->
                paths += request.path
                when (request.path) {
                    "/library/metadata/track-1" -> jsonResponse(
                        """{"MediaContainer":{"Metadata":[{"ratingKey":"track-1","type":"track","Media":[{"Part":[{"Stream":[
                            {"id":501,"key":"/library/streams/501","streamType":4,"codec":"txt"},
                            {"id":502,"key":"/library/streams/502","streamType":4,"codec":"lrc"}]}]}]}]}}""",
                    )
                    "/library/streams/502" -> respond("[00:01.00]Preferred timed line", HttpStatusCode.OK, headersOf("Content-Type", "text/plain"))
                    else -> jsonResponse("{}", 404)
                }
            },
            store = store,
        )

        val lyrics = client.fetchLyrics(item("track-1", MediaKind.TRACK))!!

        assertTrue(lyrics.synced)
        assertEquals("Preferred timed line", lyrics.lines.single().text)
        assertEquals(listOf("/library/metadata/track-1", "/library/streams/502"), paths)
    }

    @Test
    fun `lyrics are none when the lyric stream request fails`() = runTest {
        val client = testPlexClient({ request ->
            when (request.path) {
                "/library/metadata/track-1" -> jsonResponse(
                    """{"MediaContainer":{"Metadata":[{"ratingKey":"track-1","type":"track","Media":[{"Part":[{"Stream":[
                        {"id":501,"key":"/library/streams/501","streamType":4,"codec":"lrc"}]}]}]}]}}""",
                )
                else -> respond("boom", HttpStatusCode.InternalServerError)
            }
        })

        assertNull(client.fetchLyrics(item("track-1", MediaKind.TRACK)))
    }

    @Test
    fun `lyrics are none when the refetch of a cached row without streams fails and it asks for files and streams`() = runTest {
        val store = MemoryApiCacheStore().apply {
            seed("""{"MediaContainer":{"Metadata":[{"ratingKey":"track-1","type":"track"}]}}""", "/library/metadata/track-1")
        }
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ request ->
            requests += request
            respond("boom", HttpStatusCode.InternalServerError)
        }, store = store)

        assertNull(client.fetchLyrics(item("track-1", MediaKind.TRACK)))
        val refetch = requests.first()
        assertEquals("/library/metadata/track-1", refetch.url.encodedPath)
        assertEquals("1", refetch.query("checkFiles"))
        assertEquals("1", refetch.query("includeStreams"))
    }

    @Test
    fun `offline lyrics read the cached row only and never refetch it`() = runTest {
        val store = MemoryApiCacheStore().apply {
            seed("""{"MediaContainer":{"Metadata":[{"ratingKey":"track-1","type":"track"}]}}""", "/library/metadata/track-1")
        }
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ request ->
            requests += request
            jsonResponse("{}", 404)
        }, store = store)
        client.isOfflineMode = true

        assertNull(client.fetchLyrics(item("track-1", MediaKind.TRACK)))
        assertEquals(emptyList(), requests.map { it.url.encodedPath })
    }

    // Playback extras and credits detection.

    private fun chapter(id: Int, tag: String, start: Int, end: Int) =
        """{"id":$id,"tag":"$tag","index":$id,"startTimeOffset":$start,"endTimeOffset":$end}"""

    private val reporterChapters = listOf(
        chapter(1, "Intro", 0, 52520),
        chapter(2, "Scene 1", 52520, 311080),
        chapter(3, "Credits", 311080, 351280),
    )

    private fun episodeResponse(chapters: List<String>, markers: List<String> = emptyList()): String {
        val chapterField = if (chapters.isEmpty()) "" else ""","Chapter":[${chapters.joinToString(",")}]"""
        val markerField = if (markers.isEmpty()) "" else ""","Marker":[${markers.joinToString(",")}]"""
        return """{"MediaContainer":{"Metadata":[{"ratingKey":"ep-1","grandparentRatingKey":"show-1","type":"episode","title":"Episode",""" +
            """"duration":351338$chapterField$markerField}]}}"""
    }

    private fun showResponse(enableCreditsMarkerGeneration: Int?): String {
        val pref = enableCreditsMarkerGeneration?.let { ""","enableCreditsMarkerGeneration":$it""" } ?: ""
        return """{"MediaContainer":{"Metadata":[{"ratingKey":"show-1","type":"show","title":"Show"$pref}]}}"""
    }

    private val episodeEndpoint = "/library/metadata/ep-1"
    private val showEndpoint = "/library/metadata/show-1"

    private fun extrasClient(requested: MutableList<String>, responses: Map<String, String>, store: MemoryApiCacheStore = MemoryApiCacheStore()) =
        testPlexClient(
            { request ->
                requested += request.path
                responses[request.path]?.let { jsonResponse(it) } ?: jsonResponse("{}", 404)
            },
            store = store,
        )

    private suspend fun PlexClient.extras() = fetchPlaybackExtras("ep-1", null, null, false, false)

    @Test
    fun `drops the chapter derived credits marker when the show disables credits detection`() = runTest {
        val requested = mutableListOf<String>()
        val client = extrasClient(requested, mapOf(episodeEndpoint to episodeResponse(reporterChapters), showEndpoint to showResponse(0)))

        val extras = client.extras()

        assertEquals(listOf("intro"), extras.markers.map { it.type })
        assertEquals(3, extras.chapters.size)
        assertEquals(listOf(episodeEndpoint, showEndpoint), requested)
    }

    @Test
    fun `the extras request stays lean`() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ requests += it; jsonResponse(episodeResponse(emptyList())) })

        client.extras()

        val query = requests.single().url.parameters
        assertEquals("1", query["includeChapters"])
        assertEquals("1", query["includeMarkers"])
        assertNull(query["includeStreams"])
        assertNull(query["checkFiles"])
    }

    @Test
    fun `keeps the chapter derived credits marker when the show has no preference attribute`() = runTest {
        val client = extrasClient(mutableListOf(), mapOf(episodeEndpoint to episodeResponse(reporterChapters), showEndpoint to showResponse(null)))

        assertTrue(client.extras().markers.map { it.type }.containsAll(listOf("intro", "credits")))
    }

    @Test
    fun `keeps credits markers when the show preference is minus 1 library default`() = runTest {
        val client = extrasClient(mutableListOf(), mapOf(episodeEndpoint to episodeResponse(reporterChapters), showEndpoint to showResponse(-1)))

        assertTrue(client.extras().markers.any { it.isCredits })
    }

    @Test
    fun `never requests the show row when the episode yields no credits marker`() = runTest {
        val requested = mutableListOf<String>()
        val client = extrasClient(requested, mapOf(episodeEndpoint to episodeResponse(listOf(chapter(1, "Scene 1", 0, 351280)))))

        assertTrue(client.extras().markers.isEmpty())
        assertEquals(listOf(episodeEndpoint), requested)
    }

    @Test
    fun `serves the show preference from the shared cache row without network`() = runTest {
        val store = MemoryApiCacheStore().apply { seed(showResponse(0), showEndpoint) }
        val requested = mutableListOf<String>()
        val client = extrasClient(requested, mapOf(episodeEndpoint to episodeResponse(reporterChapters)), store)

        assertTrue(client.extras().markers.none { it.isCredits })
        assertEquals(listOf(episodeEndpoint), requested)
    }

    @Test
    fun `a movie reads its own attribute and needs no second request`() = runTest {
        val movie = """{"MediaContainer":{"Metadata":[{"ratingKey":"ep-1","type":"movie","title":"Movie","duration":351338,""" +
            """"enableCreditsMarkerGeneration":0,"Chapter":[${chapter(9, "End Credits", 300000, 351280)}]}]}}"""
        val requested = mutableListOf<String>()
        val client = extrasClient(requested, mapOf(episodeEndpoint to movie))

        assertTrue(client.extras().markers.isEmpty())
        assertEquals(listOf(episodeEndpoint), requested)
    }

    @Test
    fun `also drops detected credits markers from a stale row when the show disables detection`() = runTest {
        val store = MemoryApiCacheStore().apply {
            seed(
                episodeResponse(
                    emptyList(),
                    listOf("""{"id":5,"type":"credits","startTimeOffset":311080,"endTimeOffset":351280,"final":true}"""),
                ),
                episodeEndpoint,
            )
        }
        val client = extrasClient(mutableListOf(), mapOf(showEndpoint to showResponse(0)), store)

        assertTrue(client.extras().markers.isEmpty())
    }

    @Test
    fun `fails open when the show lookup errors`() = runTest {
        val client = extrasClient(mutableListOf(), mapOf(episodeEndpoint to episodeResponse(reporterChapters)))

        assertTrue(client.extras().markers.any { it.isCredits })
    }

    @Test
    fun `extras failures are empty extras`() = runTest {
        val client = testPlexClient({ jsonResponse("{}", 500) })

        val extras = client.extras()

        assertTrue(extras.chapters.isEmpty() && extras.markers.isEmpty())
    }

    @Test
    fun `cache only readers never touch the network`() = runTest {
        val store = MemoryApiCacheStore().apply { seed(metadataBody(streamDetailedMedia)) }
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ requests += it; unexpected() }, store = store)

        assertEquals(99, client.fetchCachedMediaSourceInfo("42", 0, null, null)?.partId)
        assertNotNull(client.fetchPlaybackExtrasFromCacheOnly("42", null, null, false))
        assertNull(client.fetchCachedMediaSourceInfo("missing", 0, null, null))
        assertNull(client.fetchPlaybackExtrasFromCacheOnly("missing", null, null, false))
        assertTrue(requests.isEmpty())
    }
}

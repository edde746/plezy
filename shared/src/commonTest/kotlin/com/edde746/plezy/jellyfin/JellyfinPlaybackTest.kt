package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.AudioQualityPreset
import com.edde746.plezy.backend.AudioTrackPreference
import com.edde746.plezy.backend.BifScrubPreviewSource
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.PlaybackException
import com.edde746.plezy.backend.PlaybackFailureReason
import com.edde746.plezy.backend.PlaybackInitializationOptions
import com.edde746.plezy.backend.PlaybackInitializationResult
import com.edde746.plezy.backend.ScrubFrame
import com.edde746.plezy.backend.SubtitlePreference
import com.edde746.plezy.backend.TranscodeFallbackReason
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.backend.artworkStorageKey
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaSourceInfo
import io.ktor.http.Url
import io.ktor.utils.io.errors.IOException
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

/**
 * A [JellyfinPlayback] over the fake server. Item lookups GET `/Users/user-1/Items/{id}`; [cached] stands in for the
 * persisted detail rows, and [lookups] records which item lookup each call took.
 */
internal class PlaybackFixture(
    dialect: MediaBrowserDialect = MediaBrowserDialect.JELLYFIN,
    accessToken: String = "tok-abc",
    baseUrl: String = "http://jf.local:8096",
    codecs: VideoCodecSupport = VideoCodecSupport(),
) {
    val server = JellyfinTestServer()
    val core = JellyfinCore(
        server.connection(dialect).copy(accessToken = accessToken, baseUrl = baseUrl),
        server.http,
        JellyfinDeviceIdentity("Plezy Linux", "Test Box", "1.2.3", "dev-1"),
        codecs,
        server.store,
    )
    val cached = mutableMapOf<String, MediaItem>()
    val lookups = mutableListOf<String>()

    private suspend fun network(id: String): MediaItem? =
        core.get("/Users/${core.userId}/Items/${JellyfinCore.segment(id)}").throwIfError().obj?.let(core::mapItem)

    val playback = JellyfinPlayback(
        core,
        fetchItem = { lookups += "network:$it"; network(it) },
        fetchItemFreshCacheFirst = { lookups += "fresh:$it"; cached[it] ?: network(it) },
        cachedItem = { lookups += "cache:$it"; cached[it] },
    )

    val backend = dialect.backend

    fun item(id: String = "item-1", kind: MediaKind = MediaKind.MOVIE, viewOffsetMs: Long? = null) =
        MediaItem(id = id, backend = backend, kind = kind, serverId = "machine-1", viewOffsetMs = viewOffsetMs)

    fun mapped(json: String): MediaItem = core.mapItem(Json.parseToJsonElement(json).jsonObject)!!

    /** Answers each path from [routes]; anything else is a 404. */
    fun routes(vararg routes: Pair<String, (RecordedRequest) -> FakeResponse>) {
        val table = routes.toMap()
        server.handler = { req -> table[req.path]?.invoke(req) ?: FakeResponse(404, "not found") }
    }

    /** The movie `item-1` with [sources] and a `PlaybackInfo` answered by [playbackInfo]. */
    fun movie(sources: String = DEFAULT_SOURCES, extra: String = "", playbackInfo: (RecordedRequest) -> FakeResponse) = routes(
        "/Users/user-1/Items/item-1" to { _ -> FakeResponse(body = """{"Id":"item-1","Type":"Movie","Name":"Movie"$extra,"MediaSources":$sources}""") },
        "/Items/item-1/PlaybackInfo" to playbackInfo,
    )

    suspend fun initialize(
        selectedMediaIndex: Int = 0,
        qualityPreset: TranscodeQualityPreset = TranscodeQualityPreset.ORIGINAL,
        item: MediaItem = item(),
        selectedMediaSourceId: String? = null,
        selectedAudioStreamId: Int? = null,
        preferredAudioTrack: AudioTrackPreference? = null,
        preferredSubtitleTrack: SubtitlePreference? = null,
        audioQualityPreset: AudioQualityPreset? = null,
    ): PlaybackInitializationResult = playback.getPlaybackInitialization(
        PlaybackInitializationOptions(
            metadata = item,
            selectedMediaIndex = selectedMediaIndex,
            selectedMediaSourceId = selectedMediaSourceId,
            qualityPreset = qualityPreset,
            audioQualityPreset = audioQualityPreset,
            selectedAudioStreamId = selectedAudioStreamId,
            preferredAudioTrack = preferredAudioTrack,
            preferredSubtitleTrack = preferredSubtitleTrack,
        ),
    )

    fun playbackInfoRequests() = server.requests.filter { it.path.endsWith("/PlaybackInfo") }

    companion object {
        const val DEFAULT_SOURCES = """[{"Id":"src-1","Container":"mkv","MediaStreams":[{"Index":0,"Type":"Video"}]}]"""
    }
}

internal fun ok(json: String) = FakeResponse(body = json)
internal fun RecordedRequest.json(): JsonObject = Json.parseToJsonElement(body).jsonObject
internal fun params(url: String) = JellyfinImageAbsolutizer.queryParams(url)
internal fun path(url: String) = Url(url).encodedPath

class JellyfinPlaybackTest {
    private val capped = TranscodeQualityPreset.P720_2MBPS

    private fun JsonObject.profile() = this["DeviceProfile"]!!.jsonObject
    private fun JsonObject.subtitleProfiles() = profile()["SubtitleProfiles"]!!.jsonArray.map { it.jsonObject }
    private fun List<JsonObject>.formats(method: String) = filter { it["Method"]!!.jsonPrimitive.content == method }.map { it["Format"]!!.jsonPrimitive.content }
    private fun JsonObject.firstCodecs(key: String) = profile()[key]!!.jsonArray.first().jsonObject["VideoCodec"]!!.jsonPrimitive.content

    // PlaybackInfo request.

    @Test fun playbackInfoPathEncodesReservedItemIdCharacters() = runTest {
        val f = PlaybackFixture()
        f.server.handler = { ok("""{"MediaSources":[]}""") }
        f.playback.getPlaybackInfo("folder/item #1?x")
        assertEquals("/Items/folder%2Fitem%20%231%3Fx/PlaybackInfo", f.server.requests.single().path)
    }

    @Test fun playbackInfoSendsNegotiationInQueryAndBodyWithEmbedAndTextExternalProfiles() = runTest {
        val f = PlaybackFixture()
        f.server.handler = { ok("""{"MediaSources":[]}""") }
        f.playback.getPlaybackInfo("item-1", maxStreamingBitrate = 5_000_000, mediaSourceId = "src-1", audioStreamIndex = 1, subtitleStreamIndex = 2)

        val req = f.server.requests.single()
        assertEquals("POST", req.method)
        assertEquals(
            mapOf("userId" to "user-1", "MaxStreamingBitrate" to "5000000", "MediaSourceId" to "src-1", "AudioStreamIndex" to "1", "SubtitleStreamIndex" to "2"),
            req.query,
        )
        val body = req.json()
        assertEquals("user-1", body["UserId"]!!.jsonPrimitive.content)
        assertEquals(5_000_000, body["MaxStreamingBitrate"]!!.jsonPrimitive.intOrNull)
        assertEquals(1, body["AudioStreamIndex"]!!.jsonPrimitive.intOrNull)
        assertFalse("AutoOpenLiveStream" in body)
        val profile = body.profile()
        assertEquals("Plezy", profile["Name"]!!.jsonPrimitive.content)
        assertEquals(5_000_000, profile["MaxStreamingBitrate"]!!.jsonPrimitive.intOrNull)
        assertEquals(JsonArray(emptyList()), profile["CodecProfiles"])
        val directPlay = profile["DirectPlayProfiles"]!!.jsonArray.first().jsonObject
        assertTrue("mpeg2video" in directPlay["VideoCodec"]!!.jsonPrimitive.content)
        // An omitted AudioCodec means any codec: audio never blocks direct play.
        assertFalse("AudioCodec" in directPlay)
        val subtitles = body.subtitleProfiles()
        assertEquals(listOf("srt", "ass", "ssa", "vtt", "pgssub", "dvdsub", "dvbsub"), subtitles.formats("Embed"))
        // Image formats are never External: with no match the server burns them into a transcode.
        assertEquals(listOf("srt", "ass", "ssa", "vtt"), subtitles.formats("External"))
        assertTrue(subtitles.indexOfFirst { it["Method"]!!.jsonPrimitive.content == "Embed" } < subtitles.indexOfFirst { it["Method"]!!.jsonPrimitive.content == "External" })
        assertEquals("application/json", req.headers["Content-Type"])
    }

    @Test fun playbackInfoNegotiatesFmp4HlsWithTsFallback() = runTest {
        val f = PlaybackFixture()
        f.server.handler = { ok("""{"MediaSources":[]}""") }
        f.playback.getPlaybackInfo("item-1")
        val body = f.server.requests.single().json()
        assertEquals(100_000_000, body["MaxStreamingBitrate"]!!.jsonPrimitive.intOrNull)
        val video = body.profile()["TranscodingProfiles"]!!.jsonArray.map { it.jsonObject }.filter { it["Type"]!!.jsonPrimitive.content == "Video" }
        assertEquals(2, video.size)
        fun JsonObject.s(key: String) = this[key]!!.jsonPrimitive.content
        assertEquals(listOf("mp4", "hls", "av1,hevc,h264", "aac,mp3,ac3,eac3,flac,opus,dts,truehd"), listOf(video[0].s("Container"), video[0].s("Protocol"), video[0].s("VideoCodec"), video[0].s("AudioCodec")))
        assertEquals(listOf("ts", "hls", "hevc,h264", "aac,mp3,ac3,eac3,opus,dts"), listOf(video[1].s("Container"), video[1].s("Protocol"), video[1].s("VideoCodec"), video[1].s("AudioCodec")))
        // The server echoes both lists into the transcode URL and validates them.
        val serverPattern = Regex("^[a-zA-Z0-9\\-._,|]{0,40}$")
        for (profile in video) for (key in listOf("VideoCodec", "AudioCodec")) assertTrue(serverPattern.matches(profile.s(key)), profile.s(key))
        assertFalse(body.profile()["TranscodingProfiles"]!!.jsonArray.any { it.jsonObject["Type"]!!.jsonPrimitive.content == "Audio" })
    }

    @Test fun decoderProbeNarrowsBothVideoCodecLists() = runTest {
        suspend fun profileFor(hevc: Boolean, av1: Boolean): JsonObject {
            val f = PlaybackFixture(codecs = VideoCodecSupport(hevc = hevc, av1 = av1))
            f.server.handler = { ok("""{"MediaSources":[]}""") }
            f.playback.getPlaybackInfo("item-1")
            return f.server.requests.single().json()
        }
        val none = profileFor(hevc = false, av1 = false)
        assertEquals("h264", none.firstCodecs("TranscodingProfiles"))
        assertEquals("h264,vp8,vp9,mpeg4,mpeg2video", none.firstCodecs("DirectPlayProfiles"))
        val hevcOnly = profileFor(hevc = true, av1 = false)
        assertEquals("hevc,h264", hevcOnly.firstCodecs("TranscodingProfiles"))
        assertEquals("hevc,h264,h265,vp8,vp9,mpeg4,mpeg2video", hevcOnly.firstCodecs("DirectPlayProfiles"))
    }

    @Test fun embyNeverLeadsTheTranscodeListWithAv1() = runTest {
        // Emby takes the first entry verbatim and has no AV1 encoder; an AV1 source still direct-plays.
        val f = PlaybackFixture(MediaBrowserDialect.EMBY, codecs = VideoCodecSupport(hevc = true, av1 = true))
        f.server.handler = { ok("""{"MediaSources":[]}""") }
        f.playback.getPlaybackInfo("item-1")
        val body = f.server.requests.single().json()
        assertEquals("hevc,h264", body.firstCodecs("TranscodingProfiles"))
        assertEquals("hevc,h264,h265,vp8,vp9,av1,mpeg4,mpeg2video", body.firstCodecs("DirectPlayProfiles"))
    }

    @Test fun playbackInfoPreservesStatusFailures() = runTest {
        for (status in listOf(401, 403, 500)) {
            val f = PlaybackFixture()
            f.server.handler = { FakeResponse(status, """{"error":"redacted"}""") }
            val error = assertFailsWith<MediaServerHttpException> { f.playback.getPlaybackInfo("item-1") }
            assertEquals(status, error.statusCode)
        }
    }

    @Test fun playbackInfoRejectsMalformedSuccessWithoutRetainingThePayload() = runTest {
        for (body in listOf("{", "[]")) {
            val f = PlaybackFixture()
            f.server.handler = { ok(body) }
            assertFailsWith<MediaServerHttpException>(body) { f.playback.getPlaybackInfo("item-1") }
        }
        for (body in listOf("""{"unrelated":"payload-canary"}""", """{"MediaSources":"payload-canary"}""")) {
            val f = PlaybackFixture()
            f.server.handler = { ok(body) }
            val error = assertFailsWith<MediaServerHttpException> { f.playback.getPlaybackInfo("item-1") }
            assertEquals(200, error.statusCode, body)
            assertNull(error.responseData)
            assertNull(error.requestUri)
            assertFalse("payload-canary" in error.toString())
        }
    }

    // Playback start.

    @Test fun staticPlaybackAfterNonAuthNegotiationFailures() = runTest {
        for ((name, answer) in listOf("server error" to FakeResponse(500), "client error" to FakeResponse(400), "malformed" to ok("""{"MediaSources":"invalid"}"""))) {
            val f = PlaybackFixture()
            f.movie { answer }
            val result = f.initialize()
            assertEquals("/Videos/item-1/stream", path(result.videoUrl!!), name)
            assertEquals("DirectPlay", result.playMethod, name)
            assertEquals(TranscodeFallbackReason.DECISION_FAILED, result.fallbackReason, name)
        }
    }

    @Test fun negotiationAuthRefusalsBecomePlaybackFailures() = runTest {
        for ((status, reason) in listOf(401 to PlaybackFailureReason.AUTHENTICATION_REQUIRED, 403 to PlaybackFailureReason.PLAYBACK_NOT_ALLOWED)) {
            val f = PlaybackFixture()
            f.movie { FakeResponse(status) }
            assertEquals(reason, assertFailsWith<PlaybackException> { f.initialize() }.reason)
        }
    }

    @Test fun itemWithoutSourcesIsNoPlayableSource() = runTest {
        val f = PlaybackFixture()
        f.movie(sources = "[]") { ok("""{"MediaSources":[]}""") }
        assertEquals(PlaybackFailureReason.NO_PLAYABLE_SOURCE, assertFailsWith<PlaybackException> { f.initialize() }.reason)
        assertTrue(f.playbackInfoRequests().isEmpty())
    }

    @Test fun itemFetchFailuresAreClassified() = runTest {
        val f = PlaybackFixture()
        f.server.handler = { FakeResponse(401) }
        assertEquals(PlaybackFailureReason.AUTHENTICATION_REQUIRED, assertFailsWith<PlaybackException> { f.initialize() }.reason)
    }

    @Test fun itemFetchRetriesAnImmediateConnectionError() = runTest {
        val f = PlaybackFixture()
        var attempts = 0
        f.routes(
            "/Users/user-1/Items/item-1" to { _ ->
                attempts++
                if (attempts == 1) throw IOException("connection reset")
                ok("""{"Id":"item-1","Type":"Movie","MediaSources":[{"Id":"src-1","Container":"mkv"}]}""")
            },
            "/Items/item-1/PlaybackInfo" to { ok("""{"MediaSources":[{"Id":"src-1","SupportsDirectPlay":true}]}""") },
        )
        val result = f.initialize()
        assertEquals(2, attempts)
        assertEquals("src-1", params(result.videoUrl!!)["MediaSourceId"])
    }

    @Test fun cappedPresetSendsResumeTicksAndPlaysTheTranscodingUrl() = runTest {
        val f = PlaybackFixture()
        f.movie(sources = """[{"Id":"src-1","Container":"mp4","MediaStreams":[]}]""") {
            ok(
                """{"MediaSources":[{"Id":"src-1","TranscodingUrl":"/Videos/item-1/master.m3u8?MediaSourceId=src-1&PlaySessionId=play-session-1","MediaStreams":[
                  {"Index":0,"Type":"Audio","Codec":"aac","Language":"eng","DisplayTitle":"English - AAC"},
                  {"Index":2,"Type":"Subtitle","Codec":"srt","Language":"eng","DisplayTitle":"English - SRT","DeliveryMethod":"External",
                   "DeliveryUrl":"/Videos/item-1/src-1/Subtitles/2/Stream.srt"}]}]}""",
            )
        }
        val result = f.initialize(qualityPreset = capped, item = f.item(viewOffsetMs = 143_894))

        assertTrue(result.isTranscoding)
        assertEquals("Transcode", result.playMethod)
        assertEquals("play-session-1", result.playSessionId)
        val req = f.playbackInfoRequests().single()
        assertEquals("1438940000", req.query["StartTimeTicks"])
        assertEquals("2000000", req.query["MaxStreamingBitrate"])
        assertEquals(1438940000L, req.json()["StartTimeTicks"]!!.jsonPrimitive.content.toLong())
        val url = result.videoUrl!!
        assertEquals("/Videos/item-1/master.m3u8", path(url))
        assertEquals("src-1", params(url)["MediaSourceId"])
        assertEquals("play-session-1", params(url)["PlaySessionId"])
        assertEquals("tok-abc", params(url)["ApiKey"])
        assertFalse("StartTimeTicks" in params(url))
        assertFalse(result.mediaInfo!!.subtitleTracks.single().isExternalFile)
        // Nothing selected or defaulted: nothing burned, and the embedded row stays fetchable, lazily.
        val sidecar = result.subtitleSidecars.single()
        assertEquals(2, sidecar.sourceStreamId)
        assertFalse(sidecar.preload)
        assertEquals("English", sidecar.track.title)
        assertEquals("eng", sidecar.track.language)
        assertEquals("/Videos/item-1/src-1/Subtitles/2/Stream.srt", path(sidecar.track.url))
    }

    @Test fun subtitleProfileWithholdsExternalOnlyWhenTranscoding() = runTest {
        suspend fun profiles(preset: TranscodeQualityPreset): List<JsonObject> {
            val f = PlaybackFixture()
            f.movie { ok("""{"MediaSources":[{"Id":"src-1","Container":"mkv","MediaStreams":[]}]}""") }
            f.initialize(qualityPreset = preset)
            return f.playbackInfoRequests().single().json().subtitleProfiles()
        }
        val transcode = profiles(capped)
        assertTrue(transcode.formats("External").isEmpty())
        assertTrue(transcode.formats("Embed").isNotEmpty())
        assertEquals(listOf("srt", "ass", "ssa", "vtt"), profiles(TranscodeQualityPreset.ORIGINAL).formats("External"))
    }

    private val externalSrt =
        """{"Index":3,"Type":"Subtitle","Codec":"srt","Language":"eng","DisplayTitle":"English - SRT","IsExternal":true,"DeliveryMethod":"External","DeliveryUrl":"/Videos/item-1/src-1/Subtitles/3/Stream.srt"}"""

    private fun transcodeOf(source: String) = ok("""{"MediaSources":[${source.trimEnd().removeSuffix("}")},"TranscodingUrl":"/Videos/item-1/master.m3u8?MediaSourceId=src-1&PlaySessionId=s1"}]}""")

    @Test fun selectedExternalFileKeepsExternalAndStaysASidecarOnTranscode() = runTest {
        val f = PlaybackFixture()
        val source = """{"Id":"src-1","Container":"mkv","MediaStreams":[$externalSrt]}"""
        f.movie(sources = "[$source]") { transcodeOf(source) }
        val result = f.initialize(
            qualityPreset = capped,
            preferredSubtitleTrack = SubtitlePreference.Track(language = "eng", forced = false, title = "English - SRT", codec = "srt", isExternal = true),
        )
        assertTrue(result.isTranscoding)
        assertTrue(f.playbackInfoRequests().single().json().subtitleProfiles().formats("External").isNotEmpty())
        assertEquals(3, result.subtitleSidecars.single().sourceStreamId)
    }

    @Test fun defaultedExternalFileIsNeitherBurnedNorDuplicated() = runTest {
        val f = PlaybackFixture()
        val source = """{"Id":"src-1","Container":"mkv","DefaultSubtitleStreamIndex":3,"MediaStreams":[$externalSrt]}"""
        f.movie(sources = "[$source]") { transcodeOf(source) }
        val result = f.initialize(qualityPreset = capped)
        assertTrue(result.isTranscoding)
        assertTrue(f.playbackInfoRequests().single().json().subtitleProfiles().formats("External").isNotEmpty())
        assertEquals(listOf(3), result.subtitleSidecars.map { it.sourceStreamId })
    }

    @Test fun externalBitmapFileIsBurnedNotFetched() = runTest {
        val f = PlaybackFixture()
        val bitmap = """{"Index":3,"Type":"Subtitle","Codec":"pgssub","Language":"eng","DisplayTitle":"English - PGS","IsExternal":true,"DeliveryMethod":"External","DeliveryUrl":"/Videos/item-1/src-1/Subtitles/3/Stream.sup"}"""
        val source = """{"Id":"src-1","Container":"mkv","DefaultSubtitleStreamIndex":3,"MediaStreams":[$bitmap]}"""
        f.movie(sources = "[$source]") { transcodeOf(source) }
        val result = f.initialize(qualityPreset = capped)
        assertTrue(result.isTranscoding)
        assertTrue(f.playbackInfoRequests().single().json().subtitleProfiles().formats("External").isEmpty())
        assertTrue(result.subtitleSidecars.isEmpty())
    }

    @Test fun unburnedEmbeddedBitmapIsNotOfferedAsSidecar() = runTest {
        val f = PlaybackFixture()
        val source = """{"Id":"src-1","Container":"mkv","DefaultSubtitleStreamIndex":2,"MediaStreams":[
            {"Index":2,"Type":"Subtitle","Codec":"ass","Language":"eng","DisplayTitle":"English - ASS"},
            {"Index":3,"Type":"Subtitle","Codec":"pgssub","Language":"swe","DisplayTitle":"Swedish - PGS"}]}"""
        f.movie(sources = "[$source]") { transcodeOf(source) }
        val result = f.initialize(qualityPreset = capped)
        assertTrue(result.isTranscoding)
        // 2 is burned in, 3 is a bitmap nothing could draw beside a transcode.
        assertTrue(result.subtitleSidecars.isEmpty())
    }

    @Test fun extractedRowUsesTheEndpointFormatNotTheCodecName() = runTest {
        val f = PlaybackFixture()
        val source = """{"Id":"src-1","Container":"mkv","DefaultSubtitleStreamIndex":2,"MediaStreams":[
            {"Index":2,"Type":"Subtitle","Codec":"ass","Language":"eng","DisplayTitle":"English - ASS"},
            {"Index":3,"Type":"Subtitle","Codec":"subrip","Language":"swe","DisplayTitle":"Swedish - SRT"}]}"""
        f.movie(sources = "[$source]") { transcodeOf(source) }
        val result = f.initialize(qualityPreset = capped)
        assertEquals(3, result.subtitleSidecars.single().sourceStreamId)
        assertEquals("/Videos/item-1/src-1/Subtitles/3/Stream.srt", path(result.externalSubtitles.single().url))
    }

    @Test fun directPlayStripsSidecarIdentityFromEmbeddedRows() = runTest {
        // A text `External` profile makes the server hand delivery URLs even for streams the player reads from the
        // Container; those rows must not wait for a sidecar.
        val f = PlaybackFixture()
        f.movie(sources = """[{"Id":"src-1","Container":"mkv","MediaStreams":[]}]""") {
            ok(
                """{"MediaSources":[{"Id":"src-1","Container":"mkv","SupportsDirectPlay":true,"DefaultSubtitleStreamIndex":3,"MediaStreams":[
                  {"Index":1,"Type":"Audio","Codec":"flac","Language":"jpn","IsDefault":true},
                  {"Index":3,"Type":"Subtitle","Codec":"ass","Language":"eng","DisplayTitle":"English Forced - ASS","IsDefault":true,"IsForced":true,
                   "IsExternal":false,"DeliveryMethod":"External","DeliveryUrl":"/Videos/item-1/src-1/Subtitles/3/0/Stream.ass"},
                  {"Index":4,"Type":"Subtitle","Codec":"ass","Language":"eng","DisplayTitle":"English - ASS","IsExternal":false,
                   "DeliveryMethod":"External","DeliveryUrl":"/Videos/item-1/src-1/Subtitles/4/0/Stream.ass"},
                  {"Index":5,"Type":"Subtitle","Codec":"srt","Language":"swe","DisplayTitle":"Swedish - SRT","IsExternal":true,
                   "DeliveryMethod":"External","DeliveryUrl":"/Videos/item-1/src-1/Subtitles/5/0/Stream.srt"}]}]}""",
            )
        }
        val result = f.initialize()
        assertFalse(result.isTranscoding)
        assertEquals("DirectPlay", result.playMethod)
        val tracks = result.mediaInfo!!.subtitleTracks
        assertEquals(listOf(3, 4, 5), tracks.map { it.id })
        for (track in tracks.filter { it.id != 5 }) {
            assertNull(track.key)
            assertFalse(track.usesExternalDelivery)
            assertFalse(track.isExternal)
        }
        val file = tracks.single { it.id == 5 }
        assertEquals("/Videos/item-1/src-1/Subtitles/5/0/Stream.srt", file.key)
        assertTrue(file.isExternalFile)
        assertEquals(listOf(5), result.subtitleSidecars.map { it.sourceStreamId })
        // A real file loads with the media so it stays selectable as secondary.
        assertTrue(result.subtitleSidecars.single().preload)
        assertEquals(3, result.mediaInfo!!.defaultSubtitleStreamIndex)
        assertTrue(tracks.single { it.id == 3 }.selected)
    }

    @Test fun originalPlaybackUsesTheStaticStreamWithoutABitrateCap() = runTest {
        val f = PlaybackFixture()
        f.movie(sources = """[{"Id":"src-1","Container":"mp4","MediaStreams":[{"Index":1,"Type":"Audio","Codec":"aac","Language":"eng"}]}]""") {
            ok(
                """{"PlaySessionId":"play-session-direct","MediaSources":[{"Id":"src-1","Container":"mp4","DefaultAudioStreamIndex":1,
                  "TranscodingUrl":"/Videos/item-1/master.m3u8?MediaSourceId=src-1&PlaySessionId=play-session-transcode","MediaStreams":[
                  {"Index":1,"Type":"Audio","Codec":"aac","Language":"eng","DisplayTitle":"English - AAC"},
                  {"Index":3,"Type":"Subtitle","Codec":"srt","Language":"eng","DisplayTitle":"English - SRT","IsExternal":true,"DeliveryMethod":"External",
                   "DeliveryUrl":"/Videos/item-1/src-1/Subtitles/3/Stream.srt"}]}]}""",
            )
        }
        val result = f.initialize()
        val req = f.playbackInfoRequests().single()
        assertFalse("MaxStreamingBitrate" in req.query)
        assertFalse("StartTimeTicks" in req.query)
        assertEquals("src-1", req.query["MediaSourceId"])
        val body = req.json()
        assertFalse("MaxStreamingBitrate" in body)
        assertFalse("StartTimeTicks" in body)
        assertFalse("MaxStreamingBitrate" in body.profile())

        assertFalse(result.isTranscoding)
        assertEquals("DirectPlay", result.playMethod)
        assertNull(result.playSessionId)
        assertNull(result.activeAudioStreamId)
        assertTrue(result.mediaInfo!!.audioTracks.single().selected)
        val url = result.videoUrl!!
        assertEquals("/Videos/item-1/stream", path(url))
        assertEquals(mapOf("Static" to "true", "ApiKey" to "tok-abc", "DeviceId" to "dev-1", "Container" to "mp4", "MediaSourceId" to "src-1"), params(url))
        val sidecar = result.subtitleSidecars.single()
        assertEquals(3, sidecar.sourceStreamId)
        assertTrue(sidecar.preload)
        assertEquals("English", sidecar.track.title)
        assertEquals("/Videos/item-1/src-1/Subtitles/3/Stream.srt", path(sidecar.track.url))
        assertEquals("tok-abc", params(sidecar.track.url)["ApiKey"])
    }

    // Subtitle preference.

    @Test fun keepsThePickedRowAmongIdenticalSameLanguageFiles() = runTest {
        suspend fun pick(row: Int): String? {
            val f = PlaybackFixture()
            f.movie(
                sources = """[{"Id":"src-1","MediaStreams":[
                  {"Index":3,"Type":"Subtitle","Codec":"srt","Language":"eng","Title":"Full"},
                  {"Index":4,"Type":"Subtitle","Codec":"srt","Language":"eng","Title":"Full"},
                  {"Index":5,"Type":"Subtitle","Codec":"pgs","Language":"eng","Title":"Signs & Songs"}]}]""",
            ) { ok("""{"MediaSources":[{"Id":"src-1"}]}""") }
            f.initialize(preferredSubtitleTrack = SubtitlePreference.Track(language = "eng", title = "Full", codec = "srt", sourceStreamId = row))
            return f.playbackInfoRequests().single().query["SubtitleStreamIndex"]
        }
        assertEquals("4", pick(4))
        // A stale pick that the intent ranks below the tied pair declines.
        assertNull(pick(5))
    }

    @Test fun subtitlePreferencesMapToTheCurrentSourceRows() = runTest {
        val f = PlaybackFixture()
        f.movie(
            sources = """[{"Id":"src-1","Container":"mkv","MediaStreams":[{"Index":0,"Type":"Video"},
              {"Index":3,"Type":"Subtitle","Codec":"srt","Language":"eng"},{"Index":4,"Type":"Subtitle","Codec":"srt","Language":"fra"},
              {"Index":5,"Type":"Subtitle","Codec":"srt","Language":"eng","IsForced":true}]}]""",
        ) {
            ok(
                """{"PlaySessionId":"play-session-direct","MediaSources":[{"Id":"src-1","Container":"mkv","DefaultSubtitleStreamIndex":4,
                  "TranscodingUrl":"/Videos/item-1/master.m3u8?MediaSourceId=src-1&PlaySessionId=play-session-direct","MediaStreams":[
                  {"Index":0,"Type":"Video"},
                  {"Index":3,"Type":"Subtitle","Codec":"srt","Language":"eng","DisplayTitle":"English - SRT","DeliveryMethod":"External","DeliveryUrl":"/Videos/item-1/src-1/Subtitles/3/Stream.srt"},
                  {"Index":4,"Type":"Subtitle","Codec":"srt","Language":"fra","DisplayTitle":"French - SRT","DeliveryMethod":"External","DeliveryUrl":"/Videos/item-1/src-1/Subtitles/4/Stream.srt"},
                  {"Index":5,"Type":"Subtitle","Codec":"srt","Language":"eng","DisplayTitle":"English Forced - SRT","IsForced":true,"DeliveryMethod":"External","DeliveryUrl":"/Videos/item-1/src-1/Subtitles/5/Stream.srt"}]}]}""",
            )
        }
        suspend fun requested(preference: SubtitlePreference): Pair<String?, PlaybackInitializationResult> {
            val result = f.initialize(qualityPreset = capped, preferredSubtitleTrack = preference)
            val req = f.playbackInfoRequests().last()
            assertEquals(req.query["SubtitleStreamIndex"], req.json()["SubtitleStreamIndex"]?.jsonPrimitive?.content)
            return req.query["SubtitleStreamIndex"] to result
        }
        val (french, result) = requested(SubtitlePreference.Track(language = "fra", title = "French - SRT", codec = "srt", sourceStreamId = 4))
        assertEquals("4", french)
        assertEquals("3", requested(SubtitlePreference.Track(language = "eng", title = "English - SRT", codec = "srt")).first)
        // A source pick whose language contradicts its row is re-derived by intent.
        assertEquals("4", requested(SubtitlePreference.Track(language = "fra", title = "French - SRT", codec = "srt", sourceStreamId = 3)).first)
        assertEquals("5", requested(SubtitlePreference.Track(language = "eng", forced = true, title = "English Forced - SRT", codec = "srt", sourceStreamId = 3)).first)
        assertEquals("-1", requested(SubtitlePreference.Off).first)
        assertNull(requested(SubtitlePreference.Track(language = "jpn", title = "Japanese - SRT", codec = "srt")).first)

        assertEquals("Transcode", result.playMethod)
        assertEquals(3, result.mediaInfo!!.subtitleTracks.size)
        // The burned row (4) is the one not fetched; the rest stay renderable as secondaries, lazily.
        assertEquals(listOf(3, 5), result.subtitleSidecars.map { it.sourceStreamId })
        assertTrue(result.subtitleSidecars.none { it.preload })
    }

    @Test fun originalPlaybackIgnoresTheTranscodingUrl() = runTest {
        val f = PlaybackFixture()
        f.movie {
            ok("""{"MediaSources":[{"Id":"src-1","TranscodingUrl":"/Videos/item-1/master.m3u8?MediaSourceId=src-1&PlaySessionId=play-session-transcode","MediaStreams":[{"Index":0,"Type":"Video"}]}]}""")
        }
        val result = f.initialize()
        assertFalse(result.isTranscoding)
        assertEquals("DirectPlay", result.playMethod)
        assertNull(result.playSessionId)
        assertNull(result.fallbackReason)
        val url = result.videoUrl!!
        assertEquals("/Videos/item-1/stream", path(url))
        assertEquals(mapOf("Static" to "true", "ApiKey" to "tok-abc", "DeviceId" to "dev-1", "Container" to "mkv", "MediaSourceId" to "src-1"), params(url))
    }

    @Test fun singleSourceDirectPlayStillPinsMediaSourceIdEqualToTheItemId() = runTest {
        val f = PlaybackFixture()
        f.movie(sources = """[{"Id":"item-1","Container":"mkv","MediaStreams":[{"Index":0,"Type":"Video"}]}]""") {
            ok("""{"MediaSources":[{"Id":"item-1","Container":"mkv","MediaStreams":[{"Index":0,"Type":"Video"}]}]}""")
        }
        val url = f.initialize(item = f.item(kind = MediaKind.EPISODE)).videoUrl!!
        assertEquals("item-1", params(url)["MediaSourceId"])
        assertEquals("mkv", params(url)["Container"])
    }

    // Audio stream.

    @Test fun selectedExternalAudioIsNegotiatedButLeftOutOfTheStaticUrl() = runTest {
        val f = PlaybackFixture()
        f.movie(
            sources = """[{"Id":"src-1","Container":"mkv","MediaStreams":[{"Index":0,"Type":"Video"},
              {"Index":1,"Type":"Audio","Codec":"aac","Language":"eng","IsDefault":true},
              {"Index":4,"Type":"Audio","Codec":"flac","Language":"jpn","DeliveryMethod":"External"}]}]""",
        ) { ok("""{"MediaSources":[{"Id":"src-1"}]}""") }
        val result = f.initialize(selectedAudioStreamId = 4)
        val req = f.playbackInfoRequests().single()
        assertEquals("4", req.query["AudioStreamIndex"])
        assertEquals(4, req.json()["AudioStreamIndex"]!!.jsonPrimitive.intOrNull)
        assertEquals("DirectPlay", result.playMethod)
        assertEquals(4, result.activeAudioStreamId)
        val selected = result.mediaInfo!!.audioTracks.single { it.id == 4 }
        assertTrue(selected.isExternal)
        assertTrue(selected.selected)
        assertFalse("AudioStreamIndex" in params(result.videoUrl!!))
    }

    private suspend fun audioCarry(selectedAudioStreamId: Int? = null, preferred: AudioTrackPreference? = null): Pair<RecordedRequest, PlaybackInitializationResult> {
        val f = PlaybackFixture()
        f.movie(
            sources = """[{"Id":"src-1","Container":"mkv","MediaStreams":[{"Index":0,"Type":"Video"},
              {"Index":1,"Type":"Audio","Codec":"aac","Language":"eng","IsDefault":true},
              {"Index":4,"Type":"Audio","Codec":"flac","Language":"jpn","Title":"Main"}]}]""",
        ) { ok("""{"MediaSources":[{"Id":"src-1"}]}""") }
        val result = f.initialize(item = f.item(kind = MediaKind.EPISODE), selectedAudioStreamId = selectedAudioStreamId, preferredAudioTrack = preferred)
        return f.playbackInfoRequests().single() to result
    }

    @Test fun carriedAudioResolvesAgainstTheSelectedSourceBeforeNegotiation() = runTest {
        val (req, result) = audioCarry(preferred = AudioTrackPreference(language = "jpn", title = "Main", codec = "flac"))
        assertEquals("4", req.query["AudioStreamIndex"])
        assertEquals(4, req.json()["AudioStreamIndex"]!!.jsonPrimitive.intOrNull)
        assertEquals(4, result.activeAudioStreamId)
        assertTrue(result.mediaInfo!!.audioTracks.single { it.id == 4 }.selected)
    }

    @Test fun explicitAudioStreamWinsOverACarry() = runTest {
        val (req, result) = audioCarry(selectedAudioStreamId = 1, preferred = AudioTrackPreference(language = "jpn", title = "Main", codec = "flac"))
        assertEquals("1", req.query["AudioStreamIndex"])
        assertEquals(1, result.activeAudioStreamId)
    }

    @Test fun unresolvableCarryLetsTheServerChoose() = runTest {
        val (req, result) = audioCarry(preferred = AudioTrackPreference(language = "swe"))
        assertFalse("AudioStreamIndex" in req.query)
        assertFalse("AudioStreamIndex" in req.json())
        assertNull(result.activeAudioStreamId)
    }

    @Test fun staleSelectedAudioStreamIsNotSentForAnotherSource() = runTest {
        val f = PlaybackFixture()
        f.movie(
            sources = """[{"Id":"src-1","Container":"mkv","MediaStreams":[{"Index":1,"Type":"Audio","Codec":"aac","Language":"eng"},{"Index":4,"Type":"Audio","Codec":"flac","Language":"jpn"}]},
              {"Id":"src-2","Container":"mp4","DefaultAudioStreamIndex":8,"MediaStreams":[{"Index":8,"Type":"Audio","Codec":"aac","Language":"eng"}]}]""",
        ) { ok("""{"MediaSources":[{"Id":"src-2"}]}""") }
        val result = f.initialize(selectedMediaIndex = 1, selectedAudioStreamId = 4)
        val req = f.playbackInfoRequests().single()
        assertFalse("AudioStreamIndex" in req.query)
        assertFalse("AudioStreamIndex" in req.json())
        assertNull(result.activeAudioStreamId)
        assertTrue(result.mediaInfo!!.audioTracks.single().selected)
        assertEquals("src-2", params(result.videoUrl!!)["MediaSourceId"])
    }

    @Test fun trackPlaybackNegotiatesWithTheAudioProfileAndPreset() = runTest {
        val f = PlaybackFixture()
        f.routes(
            "/Users/user-1/Items/track-1" to { ok("""{"Id":"track-1","Type":"Audio","MediaSources":[{"Id":"src-1","Container":"flac","MediaStreams":[]}]}""") },
            "/Items/track-1/PlaybackInfo" to { ok("""{"MediaSources":[{"Id":"src-1","SupportsDirectPlay":true}]}""") },
        )
        val result = f.initialize(item = f.item(id = "track-1", kind = MediaKind.TRACK), qualityPreset = capped, audioQualityPreset = AudioQualityPreset.HIGH)
        val body = f.playbackInfoRequests().single().json()
        assertEquals(320_000, body["MaxStreamingBitrate"]!!.jsonPrimitive.intOrNull)
        val audioTranscode = body.profile()["TranscodingProfiles"]!!.jsonArray.map { it.jsonObject }.single { it["Type"]!!.jsonPrimitive.content == "Audio" }
        assertEquals("mp3", audioTranscode["Container"]!!.jsonPrimitive.content)
        assertTrue(body.profile()["DirectPlayProfiles"]!!.jsonArray.any { it.jsonObject["Type"]!!.jsonPrimitive.content == "Audio" })
        assertEquals("/Audio/track-1/stream", path(result.videoUrl!!))
        assertTrue(result.subtitleSidecars.isEmpty())
    }

    // Source pinning and decisions.

    @Test fun pinsTheSelectedMediaSourceIdOverTheIndex() = runTest {
        val f = PlaybackFixture()
        f.movie(
            sources = """[{"Id":"src-4k","Container":"mkv","MediaStreams":[{"Index":0,"Type":"Video","Codec":"hevc","Height":1608,"Width":3840}]},
              {"Id":"src-1080","Container":"mp4","MediaStreams":[{"Index":0,"Type":"Video","Codec":"h264","Height":804,"Width":1920}]}]""",
        ) { ok("""{"MediaSources":[{"Id":"src-1080"}]}""") }
        val result = f.initialize(selectedMediaSourceId = "src-1080")
        val req = f.playbackInfoRequests().single()
        assertEquals("src-1080", req.query["MediaSourceId"])
        assertEquals("src-1080", req.json()["MediaSourceId"]!!.jsonPrimitive.content)
        assertEquals(listOf("src-4k", "src-1080"), result.availableVersions.map { it.id })
        assertEquals(1, result.selectedMediaIndex)
        assertEquals("src-1080", params(result.videoUrl!!)["MediaSourceId"])
        assertEquals("mp4", params(result.videoUrl!!)["Container"])
    }

    @Test fun pinsThePrimarySourceIdForMultiSourceDirectFallback() = runTest {
        val f = PlaybackFixture()
        f.movie(
            sources = """[{"Id":"item-1","Container":"mp4","MediaStreams":[{"Index":0,"Type":"Video","Codec":"h264","Height":1080,"Width":1920}]},
              {"Id":"src-4k","Container":"mkv","MediaStreams":[{"Index":0,"Type":"Video","Codec":"hevc","Height":2160,"Width":3840}]}]""",
        ) { ok("""{"MediaSources":[{"Id":"item-1"}]}""") }
        val result = f.initialize(selectedMediaSourceId = "item-1")
        assertEquals("item-1", f.playbackInfoRequests().single().query["MediaSourceId"])
        assertEquals("item-1", params(result.videoUrl!!)["MediaSourceId"])
        assertEquals("mp4", params(result.videoUrl!!)["Container"])
    }

    @Test fun mismatchedNegotiatedSourceKeepsTheSelectedStaticStream() = runTest {
        val f = PlaybackFixture()
        f.movie(
            sources = """[{"Id":"src-1080","Container":"mp4","MediaStreams":[{"Index":0,"Type":"Video","Codec":"h264","Height":1080,"Width":1920}]},
              {"Id":"src-4k","Container":"mkv","MediaStreams":[{"Index":0,"Type":"Video","Codec":"hevc","Height":2160,"Width":3840}]}]""",
        ) { ok("""{"PlaySessionId":"wrong-session","MediaSources":[{"Id":"src-4k","Container":"mkv","DirectStreamUrl":"/Videos/item-1/stream?MediaSourceId=src-4k&PlaySessionId=wrong-session"}]}""") }
        val result = f.initialize(selectedMediaSourceId = "src-1080")
        assertEquals(TranscodeFallbackReason.DECISION_FAILED, result.fallbackReason)
        assertEquals("src-1080", params(result.videoUrl!!)["MediaSourceId"])
        assertNull(params(result.videoUrl!!)["PlaySessionId"])
    }

    @Test fun emptySuccessfulNegotiationFallsBackToTheStaticStream() = runTest {
        val f = PlaybackFixture()
        f.movie { ok("""{"MediaSources":[]}""") }
        val result = f.initialize()
        assertEquals(TranscodeFallbackReason.DECISION_FAILED, result.fallbackReason)
        assertEquals("src-1", params(result.videoUrl!!)["MediaSourceId"])
    }

    @Test fun cappedRequestWithoutTranscodeOrDirectPlayIsARefusal() = runTest {
        for (source in listOf("""{"Id":"src-1"}""", """{"Id":"src-1","Bitrate":8000000}""")) {
            val f = PlaybackFixture()
            f.movie { ok("""{"MediaSources":[$source]}""") }
            val result = f.initialize(qualityPreset = capped)
            assertFalse(result.isTranscoding)
            assertEquals(TranscodeFallbackReason.DIRECT_PLAY_ONLY, result.fallbackReason, source)
            assertEquals("src-1", params(result.videoUrl!!)["MediaSourceId"])
        }
    }

    @Test fun sourceThatDirectPlaysWithinTheCapIsNotARefusal() = runTest {
        val f = PlaybackFixture()
        f.movie { ok("""{"MediaSources":[{"Id":"src-1","Bitrate":1500000,"SupportsDirectPlay":true}]}""") }
        val result = f.initialize(qualityPreset = capped)
        assertFalse(result.isTranscoding)
        assertNull(result.fallbackReason)
    }

    @Test fun transcodeUrlTokenIsQueryEncoded() = runTest {
        val f = PlaybackFixture(accessToken = "tok+with spaces/?&")
        f.movie(sources = """[{"Id":"src-1","Container":"mp4","MediaStreams":[]}]""") {
            ok("""{"MediaSources":[{"Id":"src-1","TranscodingUrl":"/Videos/item-1/master.m3u8?MediaSourceId=src-1"}]}""")
        }
        val url = f.initialize(qualityPreset = capped).videoUrl!!
        assertTrue("ApiKey=tok%2Bwith+spaces%2F%3F%26" in url, url)
        assertEquals("tok+with spaces/?&", params(url)["ApiKey"])
        assertFalse("api_key" in params(url))
    }

    @Test fun bareRelativeTranscodingUrlKeepsTheReverseProxySubpath() = runTest {
        val f = PlaybackFixture(baseUrl = "https://jf.example.com/jellyfin")
        f.routes(
            "/jellyfin/Users/user-1/Items/item-1" to { ok("""{"Id":"item-1","Type":"Movie","MediaSources":[{"Id":"src-1","Container":"mp4","MediaStreams":[]}]}""") },
            "/jellyfin/Items/item-1/PlaybackInfo" to {
                ok("""{"PlaySessionId":"play-session-direct","MediaSources":[{"Id":"src-1","TranscodingUrl":"Videos/item-1/stream?MediaSourceId=src-1&PlaySessionId=play-session-direct"}]}""")
            },
        )
        val url = f.initialize(qualityPreset = capped).videoUrl!!
        assertEquals("/jellyfin/Videos/item-1/stream", path(url))
        assertEquals("play-session-direct", params(url)["PlaySessionId"])
        assertEquals("tok-abc", params(url)["ApiKey"])
    }

    // Sidecar URLs.

    @Test fun externalSubtitleWithoutDeliveryUrlGetsTheStreamRoute() = runTest {
        val f = PlaybackFixture()
        f.movie(sources = """[{"Id":"src-1","Container":"mp4","MediaStreams":[{"Index":3,"Type":"Subtitle","Codec":"srt","Language":"eng","IsExternal":true}]}]""") {
            ok("""{"MediaSources":[{"Id":"src-1"}]}""")
        }
        val result = f.initialize()
        assertEquals("DirectPlay", result.playMethod)
        val url = result.externalSubtitles.single().url
        assertEquals("/Videos/item-1/src-1/Subtitles/3/Stream.srt", path(url))
        assertEquals("tok-abc", params(url)["ApiKey"])
    }

    @Test fun subtitleUrlsOnAnotherHostNeverGetTheToken() = runTest {
        val f = PlaybackFixture()
        f.movie(
            sources = """[{"Id":"src-1","Container":"mp4","MediaStreams":[
              {"Index":3,"Type":"Subtitle","Codec":"srt","Language":"eng","IsExternal":true,"DeliveryUrl":"https://subs.example.org/files/3.srt?sig=1"},
              {"Index":4,"Type":"Subtitle","Codec":"srt","Language":"swe","IsExternal":true,"DeliveryUrl":"http://jf.local:8096/Videos/item-1/src-1/Subtitles/4/Stream.srt"}]}]""",
        ) { ok("""{"MediaSources":[{"Id":"src-1"}]}""") }
        val byStream = f.initialize().subtitleSidecars.associate { it.sourceStreamId to it.track.url }
        assertEquals("https://subs.example.org/files/3.srt?sig=1", byStream[3])
        assertEquals("tok-abc", params(byStream[4]!!)["ApiKey"])
    }

    @Test fun selectedSourceNeverInheritsAnotherSourcesNestedTrickplay() = runTest {
        val f = PlaybackFixture()
        f.routes(
            "/Users/user-1/Items/item-trickplay" to {
                ok(
                    """{"Id":"item-trickplay","Type":"Movie","MediaSources":[{"Id":"src-a","Container":"mkv","MediaStreams":[]},{"Id":"src-b","Container":"mp4","MediaStreams":[]}],
                      "Trickplay":{"src-a":{"160":{"Width":160,"Height":90,"TileWidth":4,"TileHeight":4,"ThumbnailCount":16,"Interval":10000}}}}""",
                )
            },
            "/Items/item-trickplay/PlaybackInfo" to { ok("""{"PlaySessionId":"play-b","MediaSources":[{"Id":"src-b","Container":"mp4","MediaStreams":[]}]}""") },
        )
        val item = f.item(id = "item-trickplay")
        val result = f.initialize(item = item, selectedMediaIndex = 1, selectedMediaSourceId = "src-b")
        assertEquals("src-b", result.mediaInfo?.mediaSourceId)
        assertNull(result.mediaInfo?.trickplayByWidth)
        assertEquals("src-b", result.selectedVersion?.id)
        assertEquals("src-b", params(result.videoUrl!!)["MediaSourceId"])
        assertNull(f.playback.createScrubPreviewSource(item, result.mediaInfo!!))
    }

    // External players.

    @Test fun externalPlaybackGetsTheExtensionHintedStreamUrl() = runTest {
        // The extension is an external player's only payload hint; ISO is unplayable without it.
        val f = PlaybackFixture()
        f.movie(sources = """[{"Id":"src-1","Container":"iso","VideoType":"Iso","MediaStreams":[]}]""") { ok("""{"MediaSources":[]}""") }
        val url = f.playback.resolveExternalPlayback(f.item())!!.url
        assertEquals("/Videos/item-1/stream.iso", path(url))
        assertEquals("true", params(url)["Static"])
        assertEquals("src-1", params(url)["MediaSourceId"])
        assertTrue(f.playbackInfoRequests().isEmpty())
    }

    @Test fun externalPlaybackUsesTheAudioEndpointForTracks() = runTest {
        val f = PlaybackFixture()
        f.routes("/Users/user-1/Items/track-1" to { ok("""{"Id":"track-1","Type":"Audio","MediaSources":[{"Id":"src-1","Container":"flac","MediaStreams":[]}]}""") })
        assertEquals("/Audio/track-1/stream.flac", path(f.playback.resolveExternalPlayback(f.item(id = "track-1", kind = MediaKind.TRACK))!!.url))
    }

    @Test fun externalPlaybackCarriesExternalSubtitleFilesWithTheServerDefault() = runTest {
        // External players take subtitles only from the launch; embedded rows stay in the container.
        val f = PlaybackFixture()
        f.movie(
            sources = """[{"Id":"src-1","Container":"mkv","DefaultSubtitleStreamIndex":4,"MediaStreams":[{"Index":0,"Type":"Video"},
              {"Index":2,"Type":"Subtitle","Codec":"ass","Language":"jpn"},
              {"Index":3,"Type":"Subtitle","Codec":"subrip","Language":"swe","DisplayTitle":"Swedish - SRT","IsExternal":true},
              {"Index":4,"Type":"Subtitle","Codec":"subrip","Language":"eng","DisplayTitle":"English - SRT","IsExternal":true}]}]""",
        ) { ok("""{"MediaSources":[]}""") }
        val subtitles = f.playback.resolveExternalPlayback(f.item())!!.subtitles
        assertEquals(listOf("/Videos/item-1/src-1/Subtitles/3/Stream.srt", "/Videos/item-1/src-1/Subtitles/4/Stream.srt"), subtitles.map { path(it.url) })
        assertTrue(subtitles.all { params(it.url)["ApiKey"] == "tok-abc" })
        assertEquals(listOf(false, true), subtitles.map { it.isDefault })
    }

    @Test fun externalPlaybackPinsThePrimarySourceIdWhenAlternatesExist() = runTest {
        val f = PlaybackFixture()
        f.routes(
            "/Users/user-1/Items/item-1" to {
                ok("""{"Id":"item-1","Type":"Movie","MediaSources":[{"Id":"item-1","Container":"mp4","MediaStreams":[]},{"Id":"src-alt","Container":"mkv","MediaStreams":[]}]}""")
            },
        )
        val url = f.playback.resolveExternalPlayback(f.item(), mediaIndex = 0, mediaSourceId = "item-1")!!.url
        assertEquals("item-1", params(url)["MediaSourceId"])
        assertEquals("mp4", params(url)["Container"])
    }

    @Test fun externalPlaybackWithoutSourcesFallsBackToTheBareStream() = runTest {
        val f = PlaybackFixture()
        f.routes("/Users/user-1/Items/item-1" to { ok("""{"Id":"item-1","Type":"Movie"}""") })
        val url = f.playback.resolveExternalPlayback(f.item())!!.url
        assertEquals("/Videos/item-1/stream", path(url))
        assertNull(params(url)["MediaSourceId"])
    }

    @Test fun streamHeadersAreEmptyBecauseUrlsCarryTheToken() = assertTrue(PlaybackFixture().playback.streamHeaders.isEmpty())

    // Session reports.

    @Test fun progressSendsSourceAndStreamIndexes() = runTest {
        val f = PlaybackFixture()
        f.server.handler = { FakeResponse(204, "") }
        f.playback.reportPlaybackProgress(
            itemId = "item-1", position = 12.seconds, duration = 100.seconds, isPaused = true, playSessionId = "play-1",
            playMethod = "Transcode", mediaSourceId = "source-1", audioStreamIndex = 2, subtitleStreamIndex = -1,
        )
        val req = f.server.requests.single()
        assertEquals("/Sessions/Playing/Progress", req.path)
        assertEquals("application/json", req.headers["Content-Type"])
        assertEquals(
            Json.parseToJsonElement(
                """{"ItemId":"item-1","MediaSourceId":"source-1","AudioStreamIndex":2,"SubtitleStreamIndex":-1,"PositionTicks":120000000,"CanSeek":true,
                   "IsPaused":true,"IsMuted":false,"PlayMethod":"Transcode","RepeatMode":"RepeatNone","PlaybackOrder":"Default","PlaySessionId":"play-1"}""",
            ),
            req.json(),
        )
    }

    @Test fun stoppedSendsStreamIndexesAndOmitsWithheldOnes() = runTest {
        val f = PlaybackFixture()
        f.server.handler = { FakeResponse(204, "") }
        f.playback.reportPlaybackStopped("item-1", 40.seconds, playSessionId = "play-1", mediaSourceId = "source-1", audioStreamIndex = 2, subtitleStreamIndex = 3)
        val first = f.server.requests.single()
        assertEquals("/Sessions/Playing/Stopped", first.path)
        assertEquals(2, first.json()["AudioStreamIndex"]!!.jsonPrimitive.intOrNull)
        assertEquals(3, first.json()["SubtitleStreamIndex"]!!.jsonPrimitive.intOrNull)
        // A present null would overwrite the server's remembered choice.
        f.playback.reportPlaybackStopped("item-1", 40.seconds, playSessionId = "play-1", mediaSourceId = "source-1", audioStreamIndex = 2)
        assertFalse("SubtitleStreamIndex" in f.server.requests.last().json())
    }

    @Test fun liveReportsKeepTheSameSessionIdentity() = runTest {
        val f = PlaybackFixture()
        f.server.handler = { FakeResponse(204, "") }
        f.playback.reportPlaybackStarted("channel-1", Duration.ZERO, playSessionId = "play-1", liveStreamId = "live-1", mediaSourceId = "source-1")
        f.playback.reportPlaybackProgress("channel-1", 10.seconds, Duration.ZERO, playSessionId = "play-1", liveStreamId = "live-1", mediaSourceId = "source-1")
        f.playback.reportPlaybackStopped("channel-1", 20.seconds, playSessionId = "play-1", liveStreamId = "live-1", mediaSourceId = "source-1")
        assertEquals(listOf("/Sessions/Playing", "/Sessions/Playing/Progress", "/Sessions/Playing/Stopped"), f.server.requests.map { it.path })
        for (req in f.server.requests) {
            val body = req.json()
            assertEquals(listOf("channel-1", "play-1", "live-1", "source-1"), listOf("ItemId", "PlaySessionId", "LiveStreamId", "MediaSourceId").map { body[it]!!.jsonPrimitive.content })
        }
    }

    @Test fun reportFailuresSurface() = runTest {
        val f = PlaybackFixture()
        f.server.handler = { FakeResponse(500) }
        assertEquals(500, assertFailsWith<MediaServerHttpException> { f.playback.reportPlaybackStarted("item-1", Duration.ZERO) }.statusCode)
    }

    private suspend fun replayTriple(f: PlaybackFixture, playSessionId: String? = null): List<JsonObject> {
        f.server.handler = { FakeResponse(204, "") }
        f.playback.reportPlaybackStarted("item-1", 1.seconds, playSessionId = playSessionId)
        f.playback.reportPlaybackProgress("item-1", 2.seconds, 1.minutes, playSessionId = playSessionId)
        f.playback.reportPlaybackStopped("item-1", 3.seconds, playSessionId = playSessionId)
        assertEquals(listOf("POST /Sessions/Playing", "POST /Sessions/Playing/Progress", "POST /Sessions/Playing/Stopped"), f.server.requests.map { "${it.method} ${it.path}" })
        assertTrue(f.server.requests.all { it.query.isEmpty() })
        return f.server.requests.map { it.json() }
    }

    @Test fun embySynthesizesOneItemDerivedPlaySessionIdForAReplay() = runTest {
        val bodies = replayTriple(PlaybackFixture(MediaBrowserDialect.EMBY))
        assertEquals(List(3) { "plezy-replay-item-1" }, bodies.map { it["PlaySessionId"]!!.jsonPrimitive.content })
        assertTrue(bodies.all { it["ItemId"]!!.jsonPrimitive.content == "item-1" })
    }

    @Test fun embyKeepsAnExplicitPlaySessionId() = runTest {
        val bodies = replayTriple(PlaybackFixture(MediaBrowserDialect.EMBY), playSessionId = "caller-session")
        assertEquals(List(3) { "caller-session" }, bodies.map { it["PlaySessionId"]!!.jsonPrimitive.content })
    }

    @Test fun jellyfinLeavesPlaySessionIdOutWhenNoneIsGiven() = runTest {
        val bodies = replayTriple(PlaybackFixture())
        fun playing(ticks: Long) = Json.parseToJsonElement(
            """{"ItemId":"item-1","PositionTicks":$ticks,"CanSeek":true,"IsPaused":false,"IsMuted":false,"PlayMethod":"DirectPlay","RepeatMode":"RepeatNone","PlaybackOrder":"Default"}""",
        )
        assertEquals(listOf(playing(10_000_000), playing(20_000_000), Json.parseToJsonElement("""{"ItemId":"item-1","PositionTicks":30000000,"Failed":false}""")), bodies)
    }

    @Test fun embyDirectStreamsUseLowercaseApiKey() = runTest {
        val f = PlaybackFixture(MediaBrowserDialect.EMBY)
        f.routes("/Users/user-1/Items/item-1" to { ok("""{"Id":"item-1","Type":"Movie","MediaSources":[{"Id":"src-1","Container":"mkv"}]}""") })
        val url = f.playback.resolveExternalPlayback(f.item())!!.url
        assertEquals("tok-abc", params(url)["api_key"])
        assertFalse("ApiKey" in params(url))
    }

    // Downloads.

    @Test fun downloadPinsStreamAndSubtitlesToTheSelectedSource() = runTest {
        val f = PlaybackFixture()
        f.movie(sources = """[{"Id":"src-1","Container":"mp4","MediaStreams":[]},{"Id":"src-2","Container":"mkv","MediaStreams":[]}]""") {
            ok(
                """{"MediaSources":[{"Id":"src-1","MediaStreams":[]},{"Id":"src-2","MediaStreams":[
                  {"Index":3,"Type":"Subtitle","Codec":"srt","Language":"eng","DisplayLanguage":"English","DisplayTitle":"English - SRT","IsExternal":true,
                   "DeliveryMethod":"External","DeliveryUrl":"/Videos/item-1/src-2/Subtitles/3/Stream.srt"},
                  {"Index":4,"Type":"Subtitle","Codec":"srt","Language":"fra","DisplayLanguage":"French","DisplayTitle":"French - SRT",
                   "DeliveryMethod":"External","DeliveryUrl":"/Videos/item-1/src-2/Subtitles/4/Stream.srt"}]}]}""",
            )
        }
        val resolution = f.playback.resolveDownload(f.item(), mediaIndex = 1)
        assertEquals("/Videos/item-1/stream", path(resolution.videoUrl!!))
        assertEquals("src-2", params(resolution.videoUrl!!)["MediaSourceId"])
        assertEquals("mkv", params(resolution.videoUrl!!)["Container"])
        assertEquals("src-2", resolution.mediaSourceId)
        val req = f.playbackInfoRequests().single()
        assertEquals("src-2", req.query["MediaSourceId"])
        assertEquals("src-2", req.json()["MediaSourceId"]!!.jsonPrimitive.content)
        // Only the real file: the extracted embedded row isn't a file to keep.
        val subtitle = resolution.externalSubtitles.single()
        assertEquals(3, subtitle.id)
        assertEquals("srt", subtitle.codec)
        assertEquals("English", subtitle.language)
        assertEquals("eng", subtitle.languageCode)
        assertEquals("English - SRT", subtitle.displayTitle)
        assertEquals("/Videos/item-1/src-2/Subtitles/3/Stream.srt", path(subtitle.url))
        assertEquals("tok-abc", params(subtitle.url)["ApiKey"])
        assertTrue(resolution.externalSubtitlesResolved)

        f.server.requests.clear()
        val pinned = f.playback.resolveDownload(f.item(), mediaIndex = 0, mediaSourceId = "src-2")
        assertEquals("src-2", params(pinned.videoUrl!!)["MediaSourceId"])
        assertEquals("src-2", f.playbackInfoRequests().single().query["MediaSourceId"])
    }

    @Test fun downloadOfARemovedSourceFails() = runTest {
        val f = PlaybackFixture()
        f.movie { ok("""{"MediaSources":[]}""") }
        assertFailsWith<IllegalStateException> { f.playback.resolveDownload(f.item(), mediaSourceId = "gone") }
    }

    @Test fun downloadSidecarsUseTheEndpointFormatButKeepServerDeliveryUrls() = runTest {
        val f = PlaybackFixture()
        f.movie {
            ok(
                """{"MediaSources":[{"Id":"src-1","MediaStreams":[
                  {"Index":3,"Type":"Subtitle","Codec":"subrip","Language":"swe","DisplayTitle":"Swedish - SRT","IsExternal":true},
                  {"Index":4,"Type":"Subtitle","Codec":"subrip","Language":"eng","DisplayTitle":"English - SRT","IsExternal":true,
                   "DeliveryUrl":"/Videos/item-1/src-1/Subtitles/4/Stream.subrip"}]}]}""",
            )
        }
        val byIndex = f.playback.resolveDownload(f.item()).externalSubtitles.associate { it.id to path(it.url) }
        assertEquals("/Videos/item-1/src-1/Subtitles/3/Stream.srt", byIndex[3])
        assertEquals("/Videos/item-1/src-1/Subtitles/4/Stream.subrip", byIndex[4])
    }

    @Test fun downloadKeepsTheStaticStreamAfterNonAuthEnrichmentFailures() = runTest {
        for (answer in listOf(FakeResponse(500), FakeResponse(400), ok("""{"MediaSources":"invalid"}"""), ok("""{"MediaSources":[{"Id":"src-1"}]}"""))) {
            val f = PlaybackFixture()
            f.movie { answer }
            val resolution = f.playback.resolveDownload(f.item())
            assertEquals("/Videos/item-1/stream", path(resolution.videoUrl!!))
            assertEquals("true", params(resolution.videoUrl!!)["Static"])
            assertTrue(resolution.externalSubtitles.isEmpty())
            assertFalse(resolution.externalSubtitlesResolved)
        }
    }

    @Test fun downloadSurfacesPlaybackInfoAuthFailures() = runTest {
        val f = PlaybackFixture()
        f.movie { FakeResponse(401) }
        assertEquals(401, assertFailsWith<MediaServerHttpException> { f.playback.resolveDownload(f.item()) }.statusCode)
    }

    @Test fun downloadKeepsTheStaticStreamForUnusableNegotiationSources() = runTest {
        val idless = """[{"Container":"mkv","MediaStreams":[]}]"""
        val cases = listOf(
            Triple("""{"MediaSources":[]}""", idless, null),
            Triple("""{"MediaSources":["invalid"]}""", idless, null),
            Triple("""{"MediaSources":[{"Id":"other","MediaStreams":[]}]}""", PlaybackFixture.DEFAULT_SOURCES, "src-1"),
        )
        for ((answer, sources, expectedSourceId) in cases) {
            val f = PlaybackFixture()
            f.movie(sources = sources) { ok(answer) }
            val resolution = f.playback.resolveDownload(f.item())
            assertEquals(expectedSourceId, params(resolution.videoUrl!!)["MediaSourceId"], answer)
            assertTrue(resolution.externalSubtitles.isEmpty())
            assertFalse(resolution.externalSubtitlesResolved)
        }
    }

    @Test fun matchingDownloadSourceWithNoStreamsIsACompleteEmptyPlan() = runTest {
        val f = PlaybackFixture()
        f.movie { ok("""{"MediaSources":[{"Id":"src-1","MediaStreams":[]}]}""") }
        val resolution = f.playback.resolveDownload(f.item())
        assertNotNull(resolution.videoUrl)
        assertTrue(resolution.externalSubtitles.isEmpty())
        assertTrue(resolution.externalSubtitlesResolved)
    }

    @Test fun trackDownloadsBypassPlaybackInfo() = runTest {
        val f = PlaybackFixture()
        f.movie { FakeResponse(500) }
        val resolution = f.playback.resolveDownload(f.item(kind = MediaKind.TRACK))
        assertEquals("/Audio/item-1/stream", path(resolution.videoUrl!!))
        assertTrue(resolution.externalSubtitles.isEmpty())
        assertTrue(f.playbackInfoRequests().isEmpty())
    }

    // Skip segments.

    @Test fun extrasLoadNativeSegmentsAndCacheThem() = runTest {
        val f = PlaybackFixture()
        f.routes(
            "/Users/user-1/Items/item-1" to { ok("""{"Id":"item-1","Type":"Episode","Name":"Episode","Chapters":[]}""") },
            "/MediaSegments/item-1" to {
                ok("""{"Items":[{"Type":"Intro","StartTicks":50000000,"EndTicks":450000000},{"Type":"Outro","StartTicks":900000000,"EndTicks":1000000000}]}""")
            },
        )
        val extras = f.playback.fetchPlaybackExtras("item-1")
        assertEquals(listOf("GET /Users/user-1/Items/item-1", "GET /MediaSegments/item-1"), f.server.requests.map { "${it.method} ${it.path}" })
        assertTrue(f.server.requests.last().query.isEmpty())
        assertEquals(listOf("intro", "credits"), extras.markers.map { it.type })
        assertEquals(5000L to 45_000L, extras.markers.first().startTimeOffset to extras.markers.first().endTimeOffset)
        assertNotNull(f.server.store.get("machine-1/user-1", "/MediaSegments/item-1"))
    }

    private val opEdEpisode =
        """{"Id":"item-1","Type":"Episode","Name":"Episode","RunTimeTicks":1200000000,"Chapters":[
           {"Name":"OP","StartPositionTicks":100000000},{"Name":"Episode","StartPositionTicks":450000000},{"Name":"ED","StartPositionTicks":900000000}]}"""

    @Test fun extrasFallBackToOpEdChaptersWhenSegmentsAreMissing() = runTest {
        val f = PlaybackFixture()
        f.routes("/Users/user-1/Items/item-1" to { ok(opEdEpisode) })
        val extras = f.playback.fetchPlaybackExtras("item-1")
        assertEquals(listOf("intro", "credits"), extras.markers.map { it.type })
        assertEquals(45_000L, extras.markers.first().endTimeOffset)
        assertEquals(120_000L, extras.markers.last().endTimeOffset)
        assertNull(f.server.store.get("machine-1/user-1", "/MediaSegments/item-1"))
    }

    @Test fun embyDerivesMarkersFromChaptersWithoutAskingForSegments() = runTest {
        val f = PlaybackFixture(MediaBrowserDialect.EMBY)
        f.routes("/Users/user-1/Items/item-1" to { ok(opEdEpisode) })
        val extras = f.playback.fetchPlaybackExtras("item-1")
        assertEquals(listOf("GET /Users/user-1/Items/item-1"), f.server.requests.map { "${it.method} ${it.path}" })
        assertEquals(listOf("intro", "credits"), extras.markers.map { it.type })
        assertEquals(10_000L to 45_000L, extras.markers.first().startTimeOffset to extras.markers.first().endTimeOffset)
        assertEquals(90_000L to 120_000L, extras.markers.last().startTimeOffset to extras.markers.last().endTimeOffset)
    }

    @Test fun failedSegmentRequestServesTheCachedSegments() = runTest {
        val f = PlaybackFixture()
        f.server.store.put("machine-1/user-1", "/MediaSegments/item-1", Json.parseToJsonElement("""{"Items":[{"Type":"Intro","StartTicks":0,"EndTicks":300000000}]}""").jsonObject)
        f.routes(
            "/Users/user-1/Items/item-1" to { ok("""{"Id":"item-1","Type":"Episode","Chapters":[]}""") },
            "/MediaSegments/item-1" to { FakeResponse(500) },
        )
        assertEquals(listOf(0L to 30_000L), f.playback.fetchPlaybackExtras("item-1").markers.map { it.startTimeOffset to it.endTimeOffset })
    }

    @Test fun extrasRideTheFreshRowUnlessForcedToRefresh() = runTest {
        val f = PlaybackFixture()
        f.routes("/Users/user-1/Items/item-1" to { ok(opEdEpisode) }, "/MediaSegments/item-1" to { FakeResponse(404) })
        f.playback.fetchPlaybackExtras("item-1")
        f.playback.fetchPlaybackExtras("item-1", forceRefresh = true)
        assertEquals(listOf("fresh:item-1", "network:item-1"), f.lookups)
    }

    @Test fun cacheOnlyExtrasReadTheCachedRowAndSegmentsWithoutNetwork() = runTest {
        val f = PlaybackFixture()
        f.server.handler = { error("no network expected") }
        assertNull(f.playback.fetchPlaybackExtrasFromCacheOnly("item-1"))
        f.cached["item-1"] = f.mapped(opEdEpisode)
        f.server.store.put("machine-1/user-1", "/MediaSegments/item-1", Json.parseToJsonElement("""{"Items":[{"Type":"Intro","StartTicks":0,"EndTicks":300000000}]}""").jsonObject)
        val extras = f.playback.fetchPlaybackExtrasFromCacheOnly("item-1")!!
        assertEquals(3, extras.chapters.size)
        assertEquals(listOf("intro", "credits"), extras.markers.map { it.type })
        assertEquals(0L, extras.markers.first().startTimeOffset)
        assertTrue(f.server.requests.isEmpty())
    }

    // Scrub previews.

    private val noTracks = MediaSourceInfo(videoUrl = "", audioTracks = emptyList(), subtitleTracks = emptyList(), chapters = emptyList())

    @Test fun jellyfinScrubPreviewTilesComeFromTheSourceManifest() = runTest {
        val f = PlaybackFixture()
        val info = noTracks.copy(mediaSourceId = "src-1", trickplayByWidth = mapOf(320 to com.edde746.plezy.model.TrickplayInfo(320, 180, 10, 10, 250, 1000, 0)))
        val source = f.playback.createScrubPreviewSource(f.item(), info)
        val tile = assertIs<ScrubFrame.SheetTile>(source!!.frameAt(150.seconds))
        assertEquals("/Videos/item-1/Trickplay/320/1.jpg", path(tile.sheetUrl))
        assertEquals(mapOf("ApiKey" to "tok-abc", "DeviceId" to "dev-1", "MediaSourceId" to "src-1"), params(tile.sheetUrl))
        assertNull(f.playback.createScrubPreviewSource(f.item(), noTracks))
        assertTrue(f.server.requests.isEmpty())
    }

    @Test fun embyScrubPreviewFetchesAndParsesTheBif() = runTest {
        val f = PlaybackFixture(MediaBrowserDialect.EMBY)
        f.server.handler = { FakeResponse(bytes = bif(listOf(0 to byteArrayOf(0xFF.toByte(), 0xD8.toByte(), 0xFF.toByte(), 0xD9.toByte())))) }
        val source = f.playback.createScrubPreviewSource(f.item(), noTracks)
        assertIs<BifScrubPreviewSource>(source)
        assertTrue(source.isAvailable)
        assertNotNull(source.frameAt(Duration.ZERO))
        val req = f.server.requests.single()
        assertEquals("GET", req.method)
        assertEquals("/Videos/item-1/index.bif", req.path)
        // Auth rides the headers, not a query token.
        assertEquals(mapOf("Width" to "320"), req.query)
        assertEquals("tok-abc", req.headers["X-Emby-Token"])
    }

    @Test fun headerOnlyBifLeavesEmbyPreviewsUnavailable() = runTest {
        // Emby's answer for an item whose extraction never ran: valid magic, zero frames.
        val f = PlaybackFixture(MediaBrowserDialect.EMBY)
        f.server.handler = { FakeResponse(bytes = bif(emptyList())) }
        val source = f.playback.createScrubPreviewSource(f.item(), noTracks)
        assertIs<BifScrubPreviewSource>(source)
        assertFalse(source.isAvailable)
        assertNull(source.frameAt(Duration.ZERO))
    }

    @Test fun failedBifDownloadLeavesEmbyPreviewsUnavailableWithoutThrowing() = runTest {
        val f = PlaybackFixture(MediaBrowserDialect.EMBY)
        f.server.handler = { FakeResponse(404, "") }
        val source = f.playback.createScrubPreviewSource(f.item(), noTracks)
        assertIs<BifScrubPreviewSource>(source)
        assertFalse(source.isAvailable)
    }

    /** A Roku BIF: 64-byte header, (count + 1) index entries of (timestamp, offset), then the images. */
    private fun bif(frames: List<Pair<Int, ByteArray>>): ByteArray {
        val indexBytes = (frames.size + 1) * 8
        val out = ByteArray(64 + indexBytes + frames.sumOf { it.second.size })
        fun u32(at: Int, value: Long) { for (i in 0 until 4) out[at + i] = (value shr (8 * i)).toByte() }
        byteArrayOf(0x89.toByte(), 0x42, 0x49, 0x46, 0x0D, 0x0A, 0x1A, 0x0A).copyInto(out)
        u32(12, frames.size.toLong())
        u32(16, 1000)
        var offset = 64 + indexBytes
        frames.forEachIndexed { i, (timestamp, image) ->
            u32(64 + i * 8, timestamp.toLong())
            u32(64 + i * 8 + 4, offset.toLong())
            image.copyInto(out, offset)
            offset += image.size
        }
        u32(64 + frames.size * 8, 0xFFFFFFFFL)
        u32(64 + frames.size * 8 + 4, offset.toLong())
        return out
    }

    // Image URLs. Item images load without a token, so none rides in their URLs.

    @Test fun thumbnailUrlResolvesRelativePathsWithoutAToken() {
        val url = PlaybackFixture().playback.thumbnailUrl("/Items/item-99/Images/Primary?tag=abc")
        assertEquals("http://jf.local:8096/Items/item-99/Images/Primary", url.substringBefore('?'))
        assertEquals(mapOf("tag" to "abc"), params(url))
    }

    @Test fun thumbnailUrlKeepsTheReverseProxySubpath() {
        val url = PlaybackFixture(baseUrl = "https://jf.example.com/jellyfin").playback.thumbnailUrl("/Items/item-99/Images/Primary?tag=abc")
        assertEquals("/jellyfin/Items/item-99/Images/Primary", path(url))
        assertEquals(mapOf("tag" to "abc"), params(url))
    }

    @Test fun thumbnailUrlAddsSizeHints() {
        val url = PlaybackFixture().playback.thumbnailUrl("/Items/x/Images/Primary", width = 200, height = 300)
        assertEquals(mapOf("maxWidth" to "200", "maxHeight" to "300"), params(url))
    }

    @Test fun thumbnailUrlSizesTheServersOwnAbsoluteUrls() {
        val url = PlaybackFixture().playback.thumbnailUrl("http://jf.local:8096/Items/x/Images/Primary?tag=abc", width = 200)
        assertEquals("http://jf.local:8096/Items/x/Images/Primary", url.substringBefore('?'))
        assertEquals(mapOf("tag" to "abc", "maxWidth" to "200"), params(url))
    }

    @Test fun thumbnailUrlKeepsAnImagesOwnSize() {
        val url = PlaybackFixture().playback.thumbnailUrl("http://jf.local:8096/Items/x/Images/Primary?MaxWidth=100&height=50", width = 200, height = 300)
        assertEquals(mapOf("MaxWidth" to "100", "height" to "50"), params(url))
    }

    @Test fun thumbnailUrlLeavesAnotherOriginsImageAlone() {
        val playback = PlaybackFixture().playback
        assertEquals("https://other.example/a.png", playback.thumbnailUrl("https://other.example/a.png", width = 200, height = 300))
        assertEquals("http://jf.local:9000/a.png", playback.thumbnailUrl("http://jf.local:9000/a.png", width = 200))
    }

    @Test fun thumbnailUrlIsEmptyForMissingPathsAndExternalUrlsPassThrough() {
        val playback = PlaybackFixture().playback
        assertEquals("", playback.thumbnailUrl(null))
        assertEquals("", playback.thumbnailUrl(""))
        assertEquals("https://img.example/a.jpg", playback.externalImageUrl("https://img.example/a.jpg", width = 100))
    }

    @Test fun anUntaggedAlbumImageIsDownloadedAndKeyedWithoutTheToken() {
        val f = PlaybackFixture()
        val track = f.mapped("""{"Id":"track-1","Type":"Audio","AlbumId":"album-1"}""")
        val spec = f.playback.resolveDownloadArtwork(track).single()
        assertEquals("http://jf.local:8096/Items/album-1/Images/Primary", spec.url)
        // The key is what the download row stores and the offline lookup of the track's image computes.
        assertEquals(spec.url, spec.localKey)
        assertEquals(spec.localKey, artworkStorageKey(track.thumbPath!!))
    }

    // File info.

    @Test fun fileInfoUsesInlineSourcesAndFetchesWhenARowLacksThem() = runTest {
        val f = PlaybackFixture()
        f.routes("/Users/user-1/Items/item-1" to { ok("""{"Id":"item-1","Type":"Movie","MediaSources":[{"Id":"src-1","Container":"mkv"}]}""") })
        val inline = f.mapped("""{"Id":"item-1","Type":"Movie","MediaSources":[{"Id":"inline","Container":"mp4"}]}""")
        assertEquals("inline", f.playback.getFileInfo(inline)!!.versions.single().id)
        assertTrue(f.server.requests.isEmpty())
        val row = f.mapped("""{"Id":"item-1","Type":"Movie"}""")
        assertEquals("src-1", f.playback.getFileInfo(row)!!.versions.single().id)
        assertEquals(listOf("network:item-1"), f.lookups)
    }

    @Test fun downloadArtworkKeysCarryNoToken() {
        val f = PlaybackFixture()
        val item = f.mapped("""{"Id":"item-1","Type":"Movie","ImageTags":{"Primary":"p"}}""")
        val specs = f.playback.resolveDownloadArtwork(item)
        assertTrue(specs.isNotEmpty())
        assertTrue(specs.any { it.url.startsWith("http://jf.local:8096/Items/item-1/Images/Primary") })
        assertTrue(specs.none { "tok-abc" in it.localKey })
    }
}

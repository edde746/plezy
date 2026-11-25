package com.edde746.plezy.plex

import com.edde746.plezy.model.MediaSourceInfo
import com.edde746.plezy.model.MediaStreamKind
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

private fun obj(text: String): JsonObject = Json.parseToJsonElement(text).jsonObject

class PlexPlaybackMapperTest {
    // parsePlexVideoPlaybackDataFromJson

    @Test
    fun `cache prediction resolves the same id signature playable version and part as playback`() {
        fun part(id: Int, language: String, accessible: Boolean = true) =
            """{"id":$id,"key":"/library/parts/$id/file.mkv","accessible":$accessible,
               "Stream":[{"id":${id * 10},"streamType":2,"languageCode":"$language","selected":true}]}"""
        val first = """{"id":1,"videoResolution":"1080","videoCodec":"h264","container":"mkv","Part":[${part(10, "eng")}]}"""
        val alternate = """{"id":2,"videoResolution":"4k","videoCodec":"hevc","container":"mkv",
            "Part":[${part(20, "fre", accessible = false)},${part(21, "jpn")}]}"""
        val unavailable = """{"id":2,"videoResolution":"4k","videoCodec":"hevc","container":"mkv",
            "Part":[${part(20, "jpn", accessible = false)}]}"""

        fun expectSelection(media: List<String>, id: String? = null, signature: String? = null, language: String, index: Int) {
            val raw = obj("""{"Media":[${media.joinToString(",")}]}""")
            val cached = plexMediaSourceInfoFromCacheJson(raw, mediaSourceId = id, preferredVersionSignature = signature)!!
            val playback = parsePlexVideoPlaybackDataFromJson(
                raw,
                baseUrl = "http://plex",
                token = null,
                selectedMediaSourceId = id,
                preferredVersionSignature = signature,
            )
            assertEquals(language, cached.audioTracks.single().languageCode)
            assertEquals(language, playback.mediaInfo!!.audioTracks.single().languageCode)
            assertEquals(index, cached.mediaIndex)
            assertEquals(playback.mediaInfo!!.partId, cached.partId)
            assertEquals(playback.selectedPartIndex, cached.partIndex)
            assertEquals(playback.mediaInfo!!.mediaSourceId, cached.mediaSourceId)
        }

        expectSelection(listOf(first, alternate), id = "2", signature = "1080:h264:mkv", language = "jpn", index = 1)
        expectSelection(listOf(alternate, first), id = "2", language = "jpn", index = 0)
        expectSelection(listOf(first, alternate), id = "sibling-source", signature = "4k:hevc:mkv", language = "jpn", index = 1)
        expectSelection(listOf(first, unavailable), id = "2", language = "eng", index = 0)
        expectSelection(listOf(unavailable, first), language = "eng", index = 1)
        expectSelection(listOf(first), id = "2", signature = "4k:hevc:mkv", language = "eng", index = 0)
        // Offline source metadata stays pinned even when the server says the downloaded version is gone.
        val raw = obj("""{"Media":[$first,$unavailable]}""")
        val downloaded = resolvePlexPlaybackSelection(raw, mediaIndex = 1, preferPlayable = false)!!
        assertEquals("jpn", plexMediaSourceInfoForSelection(raw, downloaded)!!.audioTracks.single().languageCode)
    }

    @Test
    fun `falls back from inaccessible selected version to playable version`() {
        var fallback: Pair<Int, Int>? = null
        val result = parsePlexVideoPlaybackDataFromJson(
            obj(
                """{"Media":[
                  {"id":1,"videoResolution":"2160","Part":[{"id":10,"key":"/library/parts/10/file.mkv","accessible":0,"exists":1}]},
                  {"id":2,"videoResolution":"1080","Part":[{"id":20,"key":"/library/parts/20/file.mkv","accessible":1,"exists":1,
                    "Stream":[{"streamType":1,"frameRate":23.976},{"streamType":2,"id":201,"index":0,"languageCode":"eng","selected":1}]}]}
                ]}""",
            ),
            baseUrl = "http://plex:32400",
            token = "tok",
            onVersionFallback = { requested, selected -> fallback = requested to selected },
        )
        assertEquals(0 to 1, fallback)
        assertEquals("http://plex:32400/library/parts/20/file.mkv?X-Plex-Token=tok", result.videoUrl)
        assertEquals(2, result.availableVersions.size)
        assertFalse(result.availableVersions.first().isPlayable)
        assertEquals(20, result.mediaInfo?.partId)
        assertEquals(23.976, result.mediaInfo?.displayCriteria?.fps)
        assertEquals("eng", result.mediaInfo?.audioTracks?.single()?.languageCode)
        assertEquals(1, result.selectedMediaIndex)
        assertEquals(0, result.selectedPartIndex)
    }

    @Test
    fun `falls back when first Plex media has unavailable part flags`() {
        val result = parsePlexVideoPlaybackDataFromJson(
            obj(
                """{"Media":[
                  {"id":9773,"videoResolution":"1080","Part":[{"id":9815,"key":"/library/parts/9815/1774877382/file.mp4","accessible":false,"exists":false}]},
                  {"id":9766,"videoResolution":"720","Part":[{"id":9808,"key":"/library/parts/9808/1775431760/file.mp4","accessible":true,"exists":true}]}
                ]}""",
            ),
            baseUrl = "http://plex:32400",
            token = "tok",
        )
        assertEquals("http://plex:32400/library/parts/9808/1775431760/file.mp4?X-Plex-Token=tok", result.videoUrl)
        assertEquals(1, result.selectedMediaIndex)
        assertEquals(0, result.selectedPartIndex)
        assertFalse(result.availableVersions.first().isPlayable)
        assertTrue(result.availableVersions.last().isPlayable)
    }

    @Test
    fun `uses playable part when the first part is unavailable`() {
        val result = parsePlexVideoPlaybackDataFromJson(
            obj(
                """{"Media":[{"id":1,"videoResolution":"1080","Part":[
                  {"id":10,"key":"/library/parts/10/file.mkv","accessible":0,"exists":1},
                  {"id":20,"key":"/library/parts/20/file.mkv","accessible":1,"exists":1,
                   "Stream":[{"streamType":1,"frameRate":24},{"streamType":2,"id":201,"index":0,"languageCode":"eng","selected":1}]}
                ]}]}""",
            ),
            baseUrl = "http://plex:32400",
            token = "tok",
        )
        assertEquals("http://plex:32400/library/parts/20/file.mkv?X-Plex-Token=tok", result.videoUrl)
        assertEquals(0, result.selectedMediaIndex)
        assertEquals(1, result.selectedPartIndex)
        assertEquals(20, result.mediaInfo?.partId)
        assertEquals(24.0, result.mediaInfo?.displayCriteria?.fps)
        val parts = result.availableVersions.single().parts
        assertEquals(2, parts.size)
        assertFalse(parts.first().isPlayable)
        assertTrue(parts.last().isPlayable)
    }

    private val twoPlayableVersions = obj(
        """{"Media":[
          {"id":101,"videoResolution":"1080","videoCodec":"h264","container":"mkv","Part":[{"id":10,"key":"/library/parts/10/file.mkv","accessible":1,"exists":1}]},
          {"id":102,"videoResolution":"4k","videoCodec":"hevc","container":"mkv","Part":[{"id":20,"key":"/library/parts/20/file.mkv","accessible":1,"exists":1}]}
        ]}""",
    )

    @Test
    fun `selects version by media source id over the requested index`() {
        val result = parsePlexVideoPlaybackDataFromJson(
            twoPlayableVersions,
            baseUrl = "http://plex:32400",
            token = "tok",
            mediaIndex = 0,
            selectedMediaSourceId = "102",
        )
        assertEquals(1, result.selectedMediaIndex)
        assertEquals("http://plex:32400/library/parts/20/file.mkv?X-Plex-Token=tok", result.videoUrl)
        assertEquals("102", result.mediaInfo?.mediaSourceId)
    }

    @Test
    fun `selects version by preferred signature when the id misses`() {
        val result = parsePlexVideoPlaybackDataFromJson(
            twoPlayableVersions,
            baseUrl = "http://plex:32400",
            token = "tok",
            mediaIndex = 0,
            // A sibling episode's id, meaningless here: the signature decides.
            selectedMediaSourceId = "999",
            preferredVersionSignature = "4k:hevc:mkv",
        )
        assertEquals(1, result.selectedMediaIndex)
        assertEquals("102", result.mediaInfo?.mediaSourceId)
    }

    @Test
    fun `keeps the requested index when id and signature both miss`() {
        val result = parsePlexVideoPlaybackDataFromJson(
            obj(
                """{"Media":[
                  {"id":301,"videoResolution":"1080","Part":[{"id":10,"key":"/library/parts/10/file.mkv","accessible":1,"exists":1}]},
                  {"id":302,"videoResolution":"720","Part":[{"id":20,"key":"/library/parts/20/file.mkv","accessible":1,"exists":1}]}
                ]}""",
            ),
            baseUrl = "http://plex:32400",
            token = "tok",
            mediaIndex = 1,
            preferredVersionSignature = "4k:av1:mp4",
        )
        assertEquals(1, result.selectedMediaIndex)
        assertEquals("302", result.mediaInfo?.mediaSourceId)
    }

    @Test
    fun `signature resolved version still falls back when unplayable`() {
        var fallback: Pair<Int, Int>? = null
        val result = parsePlexVideoPlaybackDataFromJson(
            obj(
                """{"Media":[
                  {"id":401,"videoResolution":"1080","videoCodec":"h264","container":"mkv","Part":[{"id":10,"key":"/library/parts/10/file.mkv","accessible":1,"exists":1}]},
                  {"id":402,"videoResolution":"4k","videoCodec":"hevc","container":"mkv","Part":[{"id":20,"key":"/library/parts/20/file.mkv","accessible":0,"exists":0}]}
                ]}""",
            ),
            baseUrl = "http://plex:32400",
            token = "tok",
            mediaIndex = 0,
            preferredVersionSignature = "4k:hevc:mkv",
            onVersionFallback = { requested, selected -> fallback = requested to selected },
        )
        assertEquals(1 to 0, fallback)
        assertEquals(0, result.selectedMediaIndex)
    }

    @Test
    fun `maps server display criteria from selected video stream`() {
        val result = parsePlexVideoPlaybackDataFromJson(
            obj(
                """{"Media":[{"id":1,"width":3840,"height":2160,"videoResolution":"4k","Part":[
                  {"id":10,"key":"/library/parts/10/file.mkv","accessible":1,"exists":1,"Stream":[
                    {"streamType":1,"frameRate":"23.976","DOVIProfile":"7","DOVILevel":"6","DOVIBLCompatID":"6",
                     "colorTrc":"smpte2084","colorPrimaries":"bt2020","colorSpace":"bt2020nc"}]}]}]}""",
            ),
            baseUrl = "http://plex:32400",
            token = null,
        )
        val criteria = assertNotNull(result.mediaInfo?.displayCriteria)
        assertEquals(23.976, criteria.fps!!, 0.001)
        assertEquals(3840, criteria.width)
        assertEquals(2160, criteria.height)
        assertEquals(7, criteria.doviProfile)
        assertEquals(6, criteria.doviLevel)
        assertEquals(6, criteria.doviCompatibilityId)
        assertEquals("smpte2084", criteria.transfer)
        assertEquals("bt2020", criteria.primaries)
        assertEquals("bt2020nc", criteria.matrix)
    }

    @Test
    fun `fills missing HDR color tags from partial Plex transfer metadata`() {
        val result = parsePlexVideoPlaybackDataFromJson(
            obj(
                """{"Media":[{"id":1,"width":3840,"height":2160,"Part":[
                  {"id":10,"key":"/library/parts/10/file.mkv","accessible":1,"exists":1,
                   "Stream":[{"streamType":1,"frameRate":23.976,"colorTrc":"smpte2084"}]}]}]}""",
            ),
            baseUrl = "http://plex:32400",
            token = null,
        )
        val criteria = assertNotNull(result.mediaInfo?.displayCriteria)
        assertEquals("smpte2084", criteria.transfer)
        assertEquals("bt2020", criteria.primaries)
        assertEquals("bt2020nc", criteria.matrix)
    }

    @Test
    fun `skips unidentifiable subtitle streams without blocking playback`() {
        val result = parsePlexVideoPlaybackDataFromJson(
            obj(
                """{"Media":[{"id":1,"Part":[{"id":10,"key":"/library/parts/10/file.mp4","accessible":1,"exists":1,"Stream":[
                  {"streamType":1,"id":100},
                  {"streamType":2,"id":301,"selected":true},
                  {"streamType":3,"languageCode":"eng"},
                  {"streamType":3,"id":"cc1","languageCode":"eng"},
                  {"streamType":3,"id":"401","languageCode":"spa","selected":true}
                ]}]}]}""",
            ),
            baseUrl = "http://plex:32400",
            token = "token",
        )
        assertEquals("http://plex:32400/library/parts/10/file.mp4?X-Plex-Token=token", result.videoUrl)
        val info = assertNotNull(result.mediaInfo)
        assertEquals(listOf(301), info.audioTracks.map { it.id })
        assertEquals(listOf(401), info.subtitleTracks.map { it.id })
        assertTrue(info.subtitleTracks.single().selected)
    }

    @Test
    fun `no metadata or no Media yields no URL and no versions`() {
        val none = parsePlexVideoPlaybackDataFromJson(null, baseUrl = "http://plex", token = null)
        assertNull(none.videoUrl)
        assertFalse(none.hasValidVideoUrl)
        assertTrue(parsePlexVideoPlaybackDataFromJson(obj("{}"), baseUrl = "http://plex", token = null).availableVersions.isEmpty())
    }

    // parsePlexFileInfoFromJson

    @Test
    fun `maps media part and stream fields`() {
        val info = parsePlexFileInfoFromJson(
            obj(
                """{"Media":[{"container":"mkv","videoCodec":"h264","videoResolution":"1080","width":"1920","height":"1080",
                  "aspectRatio":"1.78","bitrate":"8000","duration":"120000","audioCodec":"aac","audioChannels":"2",
                  "optimizedForStreaming":"1","has64bitOffsets":0,"Part":[{"file":"/media/movie.mkv","size":"123456","Stream":[
                    {"streamType":"1","frameRate":"24","colorSpace":"bt709","bitDepth":"8","bitrate":"7000"},
                    {"streamType":"2","id":"301","index":"0","language":"English","languageCode":"eng","channels":"2",
                     "selected":true,"audioChannelLayout":"stereo"},
                    {"streamType":"3","id":"401","index":"0","languageCode":"eng","forced":0,"key":"/subtitles/401"}
                  ]}]}]}""",
            ),
        )
        val version = info!!.versions.single()
        val part = version.parts.single()
        assertEquals("mkv", version.container)
        assertEquals("h264", version.videoCodec)
        assertEquals("/media/movie.mkv", part.filePath)
        assertEquals(123456L, part.fileSize)
        assertEquals(true, version.optimizedForStreaming)
        assertEquals(false, version.has64bitOffsets)

        val video = part.streamsOfKind(MediaStreamKind.VIDEO).single()
        assertEquals(24.0, video.frameRate)
        assertEquals(8, video.bitDepth)
        assertEquals("bt709", video.colorSpace)

        val audio = part.streamsOfKind(MediaStreamKind.AUDIO).single()
        assertEquals("301", audio.id)
        assertEquals(true, audio.isSelected)
        assertEquals("stereo", audio.channelLayout)

        val subtitle = part.streamsOfKind(MediaStreamKind.SUBTITLE).single()
        assertEquals("401", subtitle.id)
        assertEquals(true, subtitle.isExternal)
    }

    @Test
    fun `keeps subtitle streams that the playback reader would reject`() {
        // Playback needs a numeric stream id; the file-info view is descriptive and keeps every caption track.
        val info = parsePlexFileInfoFromJson(
            obj(
                """{"Media":[{"container":"mp4","Part":[{"file":"/media/movie.mp4","Stream":[
                  {"streamType":1,"id":100},
                  {"streamType":3,"id":null,"languageCode":"eng"},
                  {"streamType":3,"id":"cea-608","languageCode":"eng"},
                  {"streamType":3,"id":402,"languageCode":"spa"}
                ]}]}]}""",
            ),
        )
        val part = assertNotNull(info).versions.single().parts.single()
        assertEquals("/media/movie.mp4", part.filePath)
        val subtitles = part.streamsOfKind(MediaStreamKind.SUBTITLE)
        assertEquals(listOf(null, "cea-608", "402"), subtitles.map { it.id })
        assertEquals(listOf(1, 2, 3), subtitles.map { it.ordinal })
    }

    @Test
    fun `optimized versions and deletion times map from Plex fields`() {
        val info = parsePlexFileInfoFromJson(
            obj(
                """{"Media":[
                  {"id":1,"proxyType":42,"target":"Optimized for Mobile","deletedAt":1700000000,
                   "Part":[{"id":5,"failureBIFResultCode":3}]},
                  {"id":2}
                ]}""",
            ),
        )!!
        val optimized = info.versions[0]
        assertEquals(true, optimized.isOptimizedVersion)
        assertEquals("Optimized for Mobile", optimized.optimizationTarget)
        assertEquals(1700000000L, optimized.deletedAt?.epochSeconds)
        assertEquals(3, optimized.parts.single().previewFailureCode)
        assertNull(info.versions[1].isOptimizedVersion)
        assertNull(parsePlexFileInfoFromJson(obj("{}")))
    }

    @Test
    fun `the display offset preview retries part flags and per kind stream numbers map and a malformed stream is skipped`() {
        val info = parsePlexFileInfoFromJson(
            obj(
                """{"Media":[{"id":1,"displayOffset":"50","Part":[{"id":5,"exists":0,"accessible":"1","failureBIFRetryCount":"2","Stream":[
                  {"streamType":2,"id":1},"junk",{"streamType":3,"id":2},{"streamType":2,"id":3},{"streamType":1,"id":4}
                ]}]}]}""",
            ),
        )
        val version = assertNotNull(info).versions.single()
        assertEquals(50, version.displayOffsetPercent)
        val part = version.parts.single()
        assertEquals(false, part.exists)
        assertEquals(true, part.accessible)
        assertEquals(2, part.previewRetryCount)
        assertEquals(listOf("1" to 1, "2" to 1, "3" to 2, "4" to 1), part.streams.map { it.id to it.ordinal })
    }

    // stacked parts: `Movie - Part 1/2/3`, 50, 40 and 30 minutes, each with its own external subtitle stream.

    private fun stacked(secondExists: Boolean = true, thirdHasDuration: Boolean = true): JsonObject {
        val parts = listOf(1 to 3000000, 2 to 2400000, 3 to 1800000).joinToString(",") { (index, durationMs) ->
            val duration = if (index != 3 || thirdHasDuration) "\"duration\":$durationMs," else ""
            val exists = if (index == 2 && !secondExists) 0 else 1
            """{"id":${10 + index},"key":"/library/parts/${10 + index}/file.mkv",$duration"exists":$exists,"Stream":[
                {"streamType":1,"id":${100 + index}},
                {"streamType":3,"id":${300 + index},"key":"/library/streams/${300 + index}","codec":"srt","languageCode":"eng"}]}"""
        }
        return obj("""{"duration":7200000,"Media":[{"id":1,"duration":7200000,"Part":[$parts]}]}""")
    }

    private class OpenedPart(val url: String?, val partIndex: Int, val info: MediaSourceInfo)

    private fun open(raw: JsonObject, position: Duration? = null): OpenedPart {
        val data = parsePlexVideoPlaybackDataFromJson(raw, baseUrl = "http://plex", token = null, position = position)
        return OpenedPart(data.videoUrl, data.selectedPartIndex, data.mediaInfo!!)
    }

    @Test
    fun `opens the file holding the start position placed on the item timeline`() {
        val first = open(stacked())
        assertEquals("http://plex/library/parts/11/file.mkv", first.url)
        val timeline = first.info.partTimeline!!
        assertEquals(0, timeline.currentIndex)
        assertEquals(120.minutes, timeline.duration)
        assertEquals(listOf(Duration.ZERO, 50.minutes, 90.minutes), timeline.parts.map { it.start })

        // A boundary belongs to the file that starts there, and that file's own streams describe the source.
        val second = open(stacked(), position = 50.minutes)
        assertEquals("http://plex/library/parts/12/file.mkv", second.url)
        assertEquals(1, second.partIndex)
        assertEquals(12, second.info.partId)
        assertEquals(50.minutes, second.info.partTimeline!!.current.start)
        assertEquals(302, second.info.subtitleTracks.single().id)

        assertEquals(1, open(stacked(), position = 89.minutes + 59.seconds).partIndex)
        // Past the end is still the last file.
        assertEquals(2, open(stacked(), position = 3.hours).partIndex)
    }

    @Test
    fun `a file that is gone plays on from the next one that is there`() {
        val opened = open(stacked(secondExists = false), position = 60.minutes)
        assertEquals("http://plex/library/parts/13/file.mkv", opened.url)
        assertEquals(2, opened.info.partTimeline!!.currentIndex)

        // A downloaded copy is on disk whatever the server says.
        val cached = resolvePlexPlaybackSelection(stacked(secondExists = false), preferPlayable = false, position = 60.minutes)!!
        assertEquals(1, cached.partIndex)
    }

    @Test
    fun `a part without a duration leaves the version unstacked`() {
        val opened = open(stacked(thirdHasDuration = false), position = 60.minutes)
        assertEquals("http://plex/library/parts/11/file.mkv", opened.url)
        assertNull(opened.info.partTimeline)
    }
}

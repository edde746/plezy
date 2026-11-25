package com.edde746.plezy.plex

import kotlinx.serialization.json.Json
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class PlexTranscodeTest {
    private val config = PlexConfig(
        baseUrl = "http://pms:32400", token = "tok", clientIdentifier = "cid", version = "2.26.0", platform = "Android",
        device = "Pixel", deviceName = "Phone",
    )

    private fun music(bitrate: Int?, mediaIndex: Int = 0, partIndex: Int = 0) = PlexTranscode.musicParams(
        config, ratingKey = "9669", mediaIndex = mediaIndex, partIndex = partIndex, bitrateKbps = bitrate,
        sessionIdentifier = "session-id", transcodeSessionId = "transcode-id",
    )

    private fun video(useTs: Boolean = false, isOriginal: Boolean = false, burn: Boolean = false) = PlexTranscode.videoParams(
        config, ratingKey = "42", mediaIndex = 0, isOriginal = isOriginal,
        maxVideoBitrateKbps = if (isOriginal) null else 3000, videoResolution = if (isOriginal) null else "1280x720",
        videoQuality = if (isOriginal) null else 100, sessionIdentifier = "session-id", transcodeSessionId = "transcode-id",
        transcodeVideoCodecIds = listOf("av1", "hevc", "h264"), burnSubtitle = burn, useTsFallbackTarget = useTs,
    )

    @Test
    fun `music transcode params cap bitrate and carry the musicProfile target`() {
        val p = music(192)
        assertEquals("1", p["hasMDE"])
        assertEquals("/library/metadata/9669", p["path"])
        assertEquals("0", p["mediaIndex"])
        assertEquals("0", p["partIndex"])
        assertEquals("http", p["protocol"])
        assertEquals("0", p["directPlay"])
        assertEquals("0", p["directStream"])
        assertEquals("192", p["musicBitrate"])
        assertEquals("transcode-id", p["session"])
        assertEquals("session-id", p["X-Plex-Session-Identifier"])
        assertEquals(
            "add-transcode-target(type=musicProfile&context=streaming&protocol=http&container=mp3&audioCodec=mp3)",
            p["X-Plex-Client-Profile-Extra"],
        )
        assertEquals("Generic", p["X-Plex-Platform"])
    }

    @Test
    fun `music transcode params carry no video or subtitle params`() {
        val p = music(320)
        for (videoOnly in listOf("subtitles", "subtitleStreamID", "advancedSubtitles", "copyts", "maxVideoBitrate")) {
            assertFalse(videoOnly in p, videoOnly)
        }
        assertFalse("videoProfile" in p.getValue("X-Plex-Client-Profile-Extra"))
    }

    @Test
    fun `original music preset omits musicBitrate`() {
        assertFalse("musicBitrate" in music(null))
    }

    @Test
    fun `music start path uses the mp3 start endpoint without token`() {
        val path = PlexTranscode.startPath(music(192, mediaIndex = 1, partIndex = 2), PlexTranscode.MUSIC_START_ENDPOINT)
        assertTrue(path.startsWith("/music/:/transcode/universal/start.mp3?"))
        assertTrue("musicBitrate=192" in path)
        assertTrue("mediaIndex=1" in path)
        assertTrue("partIndex=2" in path)
        assertTrue(
            "X-Plex-Client-Profile-Extra=add-transcode-target%28type%3DmusicProfile%26context%3Dstreaming" +
                "%26protocol%3Dhttp%26container%3Dmp3%26audioCodec%3Dmp3%29" in path,
        )
        assertFalse("X-Plex-Token" in path)
    }

    @Test
    fun `the TS fallback profile offers only H264 never HEVC in TS`() {
        val profile = video(useTs = true).getValue("X-Plex-Client-Profile-Extra")
        assertTrue(
            "add-transcode-target(type=videoProfile&context=streaming&protocol=hls&container=mpegts&videoCodec=h264" +
                "&audioCodec=aac%2Cac3%2Ceac3%2Cmp3)" in profile,
        )
        assertFalse("hevc" in profile)
        assertFalse("container=mp4" in profile)
    }

    @Test
    fun `primary profile offers the ranked codecs in fMP4 with the bitrate cap and webvtt subtitles`() {
        assertEquals(
            "add-settings(DirectPlayStreamSelection=true)" +
                "+add-limitation(scope=videoCodec&scopeName=*&type=upperBound&name=video.bitrate&value=3000&replace=true)" +
                "+add-transcode-target(type=videoProfile&context=streaming&protocol=hls&container=mp4" +
                "&videoCodec=av1%2Chevc%2Ch264&audioCodec=aac%2Cac3%2Ceac3%2Cmp3)" +
                "+add-transcode-target(type=subtitleProfile&context=streaming&protocol=hls&container=webvtt&subtitleCodec=webvtt)",
            video().getValue("X-Plex-Client-Profile-Extra"),
        )
        assertFalse("video.bitrate" in video(isOriginal = true).getValue("X-Plex-Client-Profile-Extra"))
    }

    @Test
    fun `direct play is offered only for an unburned original`() {
        assertEquals("1", video(isOriginal = true)["directPlay"])
        assertEquals("1", video(isOriginal = true)["directStream"])
        assertEquals("0", video(isOriginal = true, burn = true)["directPlay"])
        assertEquals("burn", video(isOriginal = true, burn = true)["subtitles"])
        assertEquals("0", video()["directPlay"])
        assertEquals("0", video()["directStream"])
        assertFalse("videoResolution" in video(isOriginal = true))
        assertEquals("1280x720", video()["videoResolution"])
    }

    @Test
    fun `transcode start path uses the HLS manifest endpoint without token`() {
        val path = PlexTranscode.startPath(video())
        assertTrue(path.startsWith("/video/:/transcode/universal/start.m3u8?"))
        assertTrue("protocol=hls" in path)
        assertFalse("offset=" in path)
        assertFalse("X-Plex-Token" in path)
        assertEquals("/video/:/transcode/universal/decision", PlexTranscode.decisionEndpoint(PlexTranscode.VIDEO_START_ENDPOINT))
    }

    @Test
    fun `plexEncode escapes what encodeURIComponent leaves literal`() {
        assertEquals("%28a%29%2A%27%21%20b", PlexTranscode.plexEncode("(a)*'! b"))
    }

    @Test
    fun `decision outcome follows the decision codes`() {
        fun outcome(body: String, original: Boolean = false) =
            PlexTranscode.parseDecisionOutcome(Json.parseToJsonElement(body), original)
        assertEquals(TranscodeDecisionOutcome.FAILED, outcome("""{"MediaContainer":{"generalDecisionCode":2000}}"""))
        assertEquals(TranscodeDecisionOutcome.FAILED, outcome("""{"MediaContainer":{"mdeDecisionCode":"3000"}}""", true))
        assertEquals(TranscodeDecisionOutcome.TRANSCODE_OK, outcome("""{"MediaContainer":{"transcodeDecisionCode":1000}}""", true))
        assertEquals(TranscodeDecisionOutcome.DIRECT_PLAY_ONLY, outcome("""{"MediaContainer":{"transcodeDecisionCode":1000}}"""))
        assertEquals(TranscodeDecisionOutcome.TRANSCODE_OK, outcome("""{"MediaContainer":{"transcodeDecisionCode":1001,"generalDecisionCode":1000}}"""))
        assertEquals(TranscodeDecisionOutcome.DIRECT_PLAY_ONLY, outcome("""{"generalDecisionCode":1000}"""))
        assertEquals(TranscodeDecisionOutcome.TRANSCODE_OK, outcome("""{"MediaContainer":{}}"""))
        assertEquals(TranscodeDecisionOutcome.FAILED, outcome("""[1]"""))
        assertEquals(
            "mpegts",
            PlexTranscode.decisionSelectedContainer(
                Json.parseToJsonElement("""{"MediaContainer":{"Metadata":[{"Media":[{"container":"mpegts"}]}]}}"""),
            ),
        )
    }
}

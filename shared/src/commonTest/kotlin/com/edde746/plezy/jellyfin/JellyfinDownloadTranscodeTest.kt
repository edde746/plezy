package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.model.MediaKind
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

class JellyfinDownloadTranscodeTest {
    /** A PlaybackInfo answer whose transcode URL burns subtitle 2 in, with an extracted text track and an image one. */
    private fun answer(maxWidth: Int, maxHeight: Int, videoBitrate: Long) = FakeResponse(
        body = """{"MediaSources":[{"Id":"src-1","RunTimeTicks":600000000,
          "TranscodingUrl":"/videos/item-1/stream.ts?MediaSourceId=src-1&VideoCodec=h264&AudioCodec=aac&AudioStreamIndex=1&VideoBitrate=$videoBitrate&AudioBitrate=192000&MaxWidth=$maxWidth&MaxHeight=$maxHeight&SubtitleStreamIndex=2&SubtitleMethod=Encode&SubtitleCodec=pgssub&PlaySessionId=ps-1",
          "MediaStreams":[
            {"Index":0,"Type":"Video"},{"Index":1,"Type":"Audio"},
            {"Index":2,"Type":"Subtitle","Codec":"pgssub","IsForced":true},
            {"Index":3,"Type":"Subtitle","Codec":"subrip","Language":"eng","DisplayTitle":"English","DeliveryMethod":"External","DeliveryUrl":"/Videos/item-1/src-1/Subtitles/3/0/Stream.srt"}]}]}""",
    )

    @Test fun eachPresetNegotiatesAProgressiveTsTranscodeInsideItsFrame() = runTest {
        for ((preset, frame) in listOf(TranscodeQualityPreset.P720_2MBPS to (1280 to 720), TranscodeQualityPreset.P1080_8MBPS to (1920 to 1080))) {
            val f = PlaybackFixture()
            val bitrate = preset.videoBitrateKbps!! * 1000L
            f.movie { answer(frame.first, frame.second, bitrate - 192_000) }

            val resolution = f.playback.resolveTranscodedDownload(f.item(), 0, null, preset)

            val request = f.playbackInfoRequests().single()
            assertEquals(bitrate.toString(), request.query["MaxStreamingBitrate"])
            assertEquals("false", request.query["EnableDirectPlay"])
            assertEquals("false", request.query["EnableDirectStream"])
            val profile = request.json()["DeviceProfile"]!!.jsonObject
            assertTrue(profile["DirectPlayProfiles"]!!.jsonArray.isEmpty())
            val transcoding = profile["TranscodingProfiles"]!!.jsonArray.single().jsonObject
            assertEquals(listOf("ts", "http", "h264", "aac"), listOf("Container", "Protocol", "VideoCodec", "AudioCodec").map { transcoding[it]!!.jsonPrimitive.content })
            val limits = profile["CodecProfiles"]!!.jsonArray.single().jsonObject["Conditions"]!!.jsonArray.associate {
                it.jsonObject["Property"]!!.jsonPrimitive.content to it.jsonObject["Value"]!!.jsonPrimitive.content
            }
            assertEquals(mapOf("Width" to frame.first.toString(), "Height" to frame.second.toString()), limits)

            val url = resolution.videoUrl!!
            assertEquals("/videos/item-1/stream.ts", path(url))
            val query = params(url)
            assertEquals("ps-1", query["PlaySessionId"])
            assertEquals("tok-abc", query["ApiKey"])
            // The image subtitle the server would burn in stays out.
            assertFalse(listOf("SubtitleStreamIndex", "SubtitleMethod", "SubtitleCodec").any { it in query })
            // 60 s at the URL's video and audio bitrates.
            assertEquals(preset, resolution.transcode!!.quality)
            assertEquals(bitrate * 60 / 8, resolution.transcode!!.expectedBytes)
            assertEquals(60_000L, resolution.transcode!!.durationMs)
            val subtitle = resolution.externalSubtitles.single()
            assertEquals(3, subtitle.id)
            assertEquals("srt", subtitle.codec)
            assertEquals("/Videos/item-1/src-1/Subtitles/3/0/Stream.srt", path(subtitle.url))
        }
    }

    @Test fun aServerThatDeclinesToTranscodeFailsTheDownload() = runTest {
        val f = PlaybackFixture()
        f.movie { FakeResponse(body = """{"MediaSources":[{"Id":"src-1","MediaStreams":[]}]}""") }
        assertFailsWith<IllegalStateException> { f.playback.resolveTranscodedDownload(f.item(), 0, null, TranscodeQualityPreset.P720_2MBPS) }
    }

    @Test fun onlyMoviesAndEpisodesTranscode() = runTest {
        val f = PlaybackFixture()
        f.movie { answer(1280, 720, 1_808_000) }
        assertFailsWith<IllegalArgumentException> {
            f.playback.resolveTranscodedDownload(f.item(kind = MediaKind.TRACK), 0, null, TranscodeQualityPreset.P720_2MBPS)
        }
    }

    @Test fun stoppingADownloadEndsItsEncodeByPlaySession() = runTest {
        val f = PlaybackFixture()
        f.routes("/Videos/ActiveEncodings" to { FakeResponse(204, "") })

        f.playback.stopDownloadTranscode("http://jf.local:8096/videos/item-1/stream.ts?PlaySessionId=ps-1&ApiKey=tok-abc")

        val request = f.server.requests.single()
        assertEquals("DELETE", request.method)
        assertEquals("/Videos/ActiveEncodings", request.path)
        assertEquals(mapOf("deviceId" to "dev-1", "playSessionId" to "ps-1"), request.query)
    }
}

package com.edde746.plezy.playback.mpv

import com.edde746.plezy.playback.LoadRequest
import com.edde746.plezy.playback.PlaybackOptions
import com.edde746.plezy.playback.ServerStream
import com.edde746.plezy.settings.DeinterlaceMode
import kotlin.test.Test
import kotlin.test.assertEquals

class MpvLoadTest {
    private val options = PlaybackOptions(hwdec = "videotoolbox", demuxerMaxBytes = 150 * MIB, demuxerMaxBackBytes = 50 * MIB)

    private fun request(
        title: String? = null,
        startSeconds: Double = 0.0,
        demuxerFormat: String? = null,
        liveStartIndex: Int? = null,
        live: Boolean = false,
        server: ServerStream? = null,
    ) = LoadRequest(URL, options, title, emptyMap(), startSeconds, demuxerFormat, liveStartIndex, live, server)

    @Test
    fun aPlainFileClearsTheLastFilesProperties() {
        assertEquals(
            mapOf(
                "force-media-title" to "", "start" to "none", "demuxer-lavf-format" to "", "demuxer-lavf-o" to "",
                "cache-pause-initial" to "no", "cache-pause-wait" to "1", "demuxer-hysteresis-secs" to "0",
                "stream-lavf-o" to "", "network-timeout" to "60", "stream-buffer-size" to "131072",
            ),
            MpvLoad.fileProperties(request()),
        )
    }

    @Test
    fun aFileOpensWhereAskedUnderItsTitleWithItsDemuxer() {
        assertEquals(
            mapOf(
                "force-media-title" to "Plezy, Live", "start" to "61.500", "demuxer-lavf-format" to "hls", "demuxer-lavf-o" to "",
                "cache-pause-initial" to "no", "cache-pause-wait" to "1", "demuxer-hysteresis-secs" to "0",
                "stream-lavf-o" to "", "network-timeout" to "60", "stream-buffer-size" to "131072",
            ),
            MpvLoad.fileProperties(request(title = "Plezy, Live", startSeconds = 61.5, demuxerFormat = "hls")),
        )
    }

    @Test
    fun aDownloadReadUncachedRefillsItsReadAheadHalfASecondAtATime() {
        fun hysteresis(url: String, roots: List<String>, cacheForced: Boolean = false) =
            MpvLoad.fileProperties(request().copy(url = url), uncachedRoots = roots, cacheForced = cacheForced)["demuxer-hysteresis-secs"]
        val android = MpvLoad.ANDROID_UNCACHED_ROOTS
        val ios = MpvLoad.IOS_UNCACHED_ROOTS
        assertEquals("0.5", hysteresis("file:///data/user/0/com.edde746.plezy/files/downloads/a.mkv", android))
        assertEquals("0", hysteresis("file:///storage/emulated/0/Movies/Plezy/a.mkv", android), "shared storage is cached")
        assertEquals("0", hysteresis("content://com.android.externalstorage.documents/document/a.mkv", android))
        assertEquals("0", hysteresis("file:///mnt/data/a.mkv", android), "a folder merely named data")
        assertEquals("0.5", hysteresis("file:///var/mobile/Containers/Data/Application/ABC/Documents/a.mkv", ios))
        assertEquals("0.5", hysteresis("file:///private/var/mobile/Containers/Data/Application/ABC/Documents/a.mkv", ios))
        assertEquals("0", hysteresis("file:///Users/me/Movies/a.mkv", ios))
        assertEquals("0", hysteresis("file:///data/a.mkv", emptyList()), "the desktop never")
        assertEquals("0", hysteresis(URL, android), "a stream")
        assertEquals("0", hysteresis("file:///data/user/0/com.edde746.plezy/files/a.mkv", android, cacheForced = true), "under cache=yes")
    }

    @Test
    fun aServersStreamReconnectsForTenMinutesOnA503Too() {
        val direct = MpvLoad.fileProperties(request(server = ServerStream(transcode = false, container = "mkv", bitrateKbps = 8_000)))
        assertEquals(RECONNECT, direct["stream-lavf-o"])
        assertEquals("60", direct["network-timeout"])
        assertEquals("", direct["demuxer-lavf-o"])
        assertEquals("131072", direct["stream-buffer-size"], "a common Matroska file keeps mpv's ring")
    }

    /** A transcode's segments come through lavf's hls demuxer: a stalled read gives up at 20 s and is asked again. */
    @Test
    fun aTranscodesSegmentsTimeOutAndReconnectInTheDemuxer() {
        val transcode = MpvLoad.fileProperties(request(server = ServerStream(transcode = true, container = "mp4", bitrateKbps = 100_000)))
        assertEquals(RECONNECT, transcode["stream-lavf-o"])
        assertEquals("20", transcode["network-timeout"])
        assertEquals("reconnect=1,reconnect_streamed=1,reconnect_on_network_error=1", transcode["demuxer-lavf-o"])
        assertEquals("131072", transcode["stream-buffer-size"], "the ring reads only the playlist")
    }

    @Test
    fun theRingHoldsSixSecondsOfAQuickTimeOrHighBitrateMatroskaStream() {
        assertEquals(16 * MIB, MpvLoad.streamBufferBytes("mp4", 10_000), "7.5 MB rounds to 8 MiB, at least 16")
        assertEquals(64 * MIB, MpvLoad.streamBufferBytes("mov,mp4,m4a,3gp,3g2,mj2", 60_000), "45 MB rounds up to 64 MiB")
        assertEquals(128 * MIB, MpvLoad.streamBufferBytes("mp4", 400_000), "at most 128 MiB")
        assertEquals(64 * MIB, MpvLoad.streamBufferBytes("MOV", null), "a QuickTime file of unknown bitrate")
        assertEquals(null, MpvLoad.streamBufferBytes("mkv", null))
        assertEquals(null, MpvLoad.streamBufferBytes("mkv", 39_999), "under 40 Mb/s Matroska keeps mpv's")
        assertEquals(32 * MIB, MpvLoad.streamBufferBytes("matroska,webm", 40_000))
        assertEquals(null, MpvLoad.streamBufferBytes("avi", 80_000))
        assertEquals(null, MpvLoad.streamBufferBytes(null, 80_000))
        assertEquals(32 * MIB, MpvLoad.streamBufferBytes("mp4", 400_000, cap = 32 * MIB), "within the engine's cap")
        assertEquals(16 * MIB, MpvLoad.streamBufferBytes("mp4", 400_000, cap = MIB), "never under 16 MiB")
        assertEquals(
            (32 * MIB).toString(),
            MpvLoad.fileProperties(request(server = ServerStream(transcode = false, container = "mp4", bitrateKbps = 400_000)), streamBufferCap = 32 * MIB)["stream-buffer-size"],
        )
    }

    /** Live broadcasts mix telecined film with field-rate video, which inverse telecine makes stutter. */
    @Test
    fun aLiveFilePlaysFilmDeinterlacingAsPlainDeinterlacing() {
        val film = options.copy(deinterlace = DeinterlaceMode.FILM)
        assertEquals("ivtc", MpvLoad.decodingOptions(film, live = false)["deinterlace"])
        assertEquals("auto", MpvLoad.decodingOptions(film, live = true)["deinterlace"])
        assertEquals("auto", MpvLoad.decodingOptions(options.copy(deinterlace = DeinterlaceMode.VIDEO), live = false)["deinterlace"])
        assertEquals("no", MpvLoad.decodingOptions(options, live = true)["deinterlace"])
    }

    /** A rewind in a live window reopens the stream at a segment counted from the playlist's end. */
    @Test
    fun aLiveRewindOpensAtItsSegment() {
        assertEquals("live_start_index=-30", MpvLoad.fileProperties(request(liveStartIndex = -30))["demuxer-lavf-o"])
    }

    /**
     * A live file goes on after a stall only with 6 s buffered, and starts so unless it joins its playlist three or more
     * segments before the end, the hold-back read at once; a first open (lavf's own join, or no HLS at all) and a join
     * closer to the end wait.
     */
    @Test
    fun aLiveFileStartsAtItsFirstFrameOnlyWhenItJoinsWithTheHoldBack() {
        fun buffering(liveStartIndex: Int?) = MpvLoad.fileProperties(request(liveStartIndex = liveStartIndex, live = true))
            .let { it["cache-pause-initial"] to it["cache-pause-wait"] }
        assertEquals("yes" to "6", buffering(null), "a first open")
        assertEquals("yes" to "6", buffering(-2), "two segments before the end")
        assertEquals("no" to "6", buffering(-3), "three segments before the end")
        assertEquals("no" to "6", buffering(-20), "a rewind")
    }

    @Test
    fun headersAreOneListWithEscapedCommas() {
        val headers = mapOf("User-Agent" to "Plezy/1, like mpv", "X-Path" to "a\\b")
        assertEquals("""User-Agent: Plezy/1\, like mpv,X-Path: a\b""", MpvLoad.headerFields(headers))
    }

    @Test
    fun noHeadersClearTheLastFilesList() {
        assertEquals("", MpvLoad.headerFields(emptyMap()))
    }

    @Test
    fun aPqOrHlgSourceOnAnHdrDisplayGetsAPqSurface() {
        val pq = mapOf("android-surface-colorspace" to "bt2020-pq", "target-trc" to "pq", "target-prim" to "bt.2020")
        assertEquals(pq, MpvLoad.hdrSurfaceOptions("smpte2084", displayTakesHdr = true, hdrOutput = true))
        assertEquals(pq, MpvLoad.hdrSurfaceOptions("arib-std-b67", displayTakesHdr = true, hdrOutput = true))
    }

    @Test
    fun sdrUnknownOrTranscodedSourcesAnSdrDisplayOrHdrOutputOffKeepTheDefaultSurface() {
        assertEquals(emptyMap(), MpvLoad.hdrSurfaceOptions("bt709", displayTakesHdr = true, hdrOutput = true))
        assertEquals(emptyMap(), MpvLoad.hdrSurfaceOptions(null, displayTakesHdr = true, hdrOutput = true))
        assertEquals(emptyMap(), MpvLoad.hdrSurfaceOptions("smpte2084", displayTakesHdr = false, hdrOutput = true))
        assertEquals(emptyMap(), MpvLoad.hdrSurfaceOptions("smpte2084", displayTakesHdr = true, hdrOutput = false))
    }

    /**
     * Where the file starts is a playback default: mpv refusing it starts the file at its beginning, and the file opens.
     * Every other value the load sets is the file's own, and mpv refusing one refuses the load.
     */
    @Test
    fun onlyARefusedStartLeavesTheLoadStanding() {
        val values = MpvLoad.decodingOptions(options, live = false) + MpvLoad.fileProperties(request(title = "A", startSeconds = 61.5)) + ("http-header-fields" to "")
        assertEquals(setOf("start"), values.keys.filterNot(MpvLoad::refusalFailsLoad).toSet())
    }

    private companion object {
        const val URL = "http://host/a.mkv"
        const val MIB = 1024L * 1024
        const val RECONNECT = "reconnect=1,reconnect_on_network_error=1,reconnect_on_http_error=503,reconnect_streamed=1,reconnect_delay_max=600"
    }
}

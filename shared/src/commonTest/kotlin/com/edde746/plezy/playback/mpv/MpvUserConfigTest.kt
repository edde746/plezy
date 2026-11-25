package com.edde746.plezy.playback.mpv

import com.edde746.plezy.data.settings.DeviceSettings
import com.edde746.plezy.log.Log
import com.edde746.plezy.playback.HardwareDecoder
import com.edde746.plezy.playback.LoadRequest
import com.edde746.plezy.playback.PlaybackOptions
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** The user's mpv.conf for an engine: the names it may set, and that a line wins over every kind of app write. */
class MpvUserConfigTest {
    private val originalSink = Log.sink
    private val warnings = mutableListOf<String>()

    @BeforeTest
    fun captureLog() {
        Log.sink = Log.Sink { level, _, message, _ -> if (level == Log.Level.WARN) warnings += message }
    }

    @AfterTest
    fun restoreLog() {
        Log.sink = originalSink
    }

    private val hdrConfig = "hdr-enabled=no\nhdr-tone-mapping=compositor\ntarget-trc=pq\ntarget-prim=bt.2020\n" +
        "target-peak=4000\ntone-mapping=bt.2390\nsub-scale=1.5\n"

    @Test
    fun theHdrSettingsAreNeverAppliedFromTheConfig() {
        assertEquals(
            listOf("target-trc" to "pq", "target-prim" to "bt.2020", "target-peak" to "4000", "tone-mapping" to "bt.2390", "sub-scale" to "1.5"),
            MpvUserConfig.of(hdrConfig, linuxPlane = false).options,
        )
        assertEquals(2, warnings.size, "$warnings")
        assertTrue(warnings.all { "HDR settings" in it }, "$warnings")
    }

    @Test
    fun onTheLinuxPlaneTheVideoOutputAndHdrStayWithThePlane() {
        assertEquals(listOf("sub-scale" to "1.5"), MpvUserConfig.of(hdrConfig + "vo=gpu-next\ngpu-api=vulkan\n", linuxPlane = true).options)
        assertEquals(8, warnings.size, "$warnings")
    }

    /**
     * An engine's writes in their order: its startup options, then the user's lines, then each later write through
     * its helper ([MpvUserConfig.appWrites]): a file's values, its decoding, the HDR surface, `volume-max`. Each name
     * a line sets ends with the line's value; the file's own title and start still change.
     */
    @Test
    fun theUsersLineWinsOverEveryKindOfAppWrite() {
        val config = MpvUserConfig.of(
            "msg-level=all=v\ncache-pause-wait=5\nnetwork-timeout=7\ntarget-trc=hlg\nvolume-max=150\nstart=10\n",
            linuxPlane = false,
        )
        val mpv = linkedMapOf<String, String>()
        fun appSet(name: String, value: String) {
            if (config.appWrites(name)) mpv[name] = value
        }
        for ((name, value) in MpvStartup.properties(DeviceSettings.DEFAULT, desktop = true)) mpv[name] = value
        for ((name, value) in config.options) mpv[name] = value
        val request = LoadRequest(url = "http://srv/video.mkv", options = PlaybackOptions.of(DeviceSettings.DEFAULT, HardwareDecoder.LINUX), title = "Film", startSeconds = 30.0)
        for ((name, value) in MpvLoad.fileProperties(request)) appSet(name, value)
        for ((name, value) in MpvLoad.hdrSurfaceOptions("smpte2084", displayTakesHdr = true, hdrOutput = true)) appSet(name, value)
        appSet("volume-max", "130")

        assertEquals("all=v", mpv["msg-level"], "startup")
        assertEquals("5", mpv["cache-pause-wait"], "per file")
        assertEquals("7", mpv["network-timeout"], "per file, network")
        assertEquals("hlg", mpv["target-trc"], "HDR surface")
        assertEquals("bt2020-pq", mpv["android-surface-colorspace"], "the HDR surface's other values still go")
        assertEquals("150", mpv["volume-max"], "volume-max")
        assertEquals("30.000", mpv["start"], "the file's start is its own")
        assertEquals("Film", mpv["force-media-title"])
        assertEquals(mapOf("demuxer-lavf-format" to ""), config.yielding(mapOf("cache-pause-wait" to "1", "demuxer-lavf-format" to "")))
    }

    /** The per-file decoder operating rate and frame-drop policy are app writes: a mpv.conf line pins each. */
    @Test
    fun aUserLinePinsTheDecoderOperatingRateAndFramedrop() {
        val pinned = MpvUserConfig.of("hwdec-mediacodec-operating-rate=120\nframedrop=no\n", linuxPlane = false)
        val mpv = linkedMapOf<String, String>()
        for ((name, value) in pinned.options) mpv[name] = value
        fun appSet(name: String, value: String) {
            if (pinned.appWrites(name)) mpv[name] = value
        }
        appSet("hwdec-mediacodec-operating-rate", DecoderOperatingRate.of(24.0, 2.0, null).toString())
        appSet("framedrop", "decoder+vo")
        assertEquals("120", mpv["hwdec-mediacodec-operating-rate"])
        assertEquals("no", mpv["framedrop"])

        val unset = MpvUserConfig.of("", linuxPlane = false)
        assertTrue(unset.appWrites("hwdec-mediacodec-operating-rate"))
        assertTrue(unset.appWrites("framedrop"))
    }

    @Test
    fun aDecoderOptionsLineWinsPerKeyAndTheAppKeysItDoesNotNameStay() {
        fun effective(options: String) = options.split(',').associate { it.substringBefore('=') to it.substringAfter('=') }
        val config = MpvUserConfig.of("vd-lavc-o=threads=2,async=0\n", linuxPlane = false)
        assertEquals(
            mapOf("ndk_codec" to "0", "async" to "0", "priority" to "0", "dolby_vision" to "0", "threads" to "2"),
            effective(config.decoderOptions("ndk_codec=0,async=1,priority=0,dolby_vision=0")),
        )
        assertEquals("ndk_codec=0", MpvUserConfig.of("vd-lavc-o=  \n", linuxPlane = false).decoderOptions("ndk_codec=0"))
        assertEquals("threads=2", MpvUserConfig.of("vd-lavc-o=threads=2", linuxPlane = false).decoderOptions(""))
    }
}

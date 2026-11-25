package com.edde746.plezy.playback

import com.edde746.plezy.data.settings.DeviceSettings
import kotlin.test.Test
import kotlin.test.assertEquals

class PlaybackOptionsTest {
    private val mib = 1024L * 1024

    @Test
    fun hardwareDecodingOffIsSoftwareOnEveryPlatform() {
        val off = DeviceSettings.DEFAULT.copy(hardwareDecoding = false)
        for (decoder in HardwareDecoder.entries) {
            assertEquals(decoder.hwdec, PlaybackOptions.of(DeviceSettings.DEFAULT, decoder).hwdec, "on: $decoder's own")
            assertEquals("no", PlaybackOptions.of(off, decoder).hwdec, "off: software on $decoder")
        }
        assertEquals("no", PlaybackOptions.of(DeviceSettings.DEFAULT, HardwareDecoder.APPLE_SIMULATOR).hwdec, "a simulator has no hardware decoder")
    }

    @Test
    fun theCacheIsTheSettingAheadAndAThirdOfItBehindWithMpvsOwnWhileAutomatic() {
        val automatic = PlaybackOptions.of(DeviceSettings.DEFAULT, HardwareDecoder.WINDOWS)
        assertEquals(150 * mib, automatic.demuxerMaxBytes, "mpv's default demuxer-max-bytes")
        assertEquals(50 * mib, automatic.demuxerMaxBackBytes, "mpv's default demuxer-max-back-bytes")

        val large = PlaybackOptions.of(DeviceSettings.DEFAULT.copy(cacheSizeMegabytes = 4096), HardwareDecoder.WINDOWS)
        assertEquals(4096 * mib, large.demuxerMaxBytes, "the largest size doesn't overflow")
        assertEquals(4096 * mib / 3, large.demuxerMaxBackBytes)

        val small = PlaybackOptions.of(DeviceSettings.DEFAULT.copy(cacheSizeMegabytes = 16), HardwareDecoder.WINDOWS)
        assertEquals(16 * mib, small.demuxerMaxBytes)
        assertEquals(16 * mib / 3, small.demuxerMaxBackBytes)
    }
}

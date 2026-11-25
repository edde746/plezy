package com.edde746.plezy.playback.mpv

import com.edde746.plezy.data.settings.DeviceSettings
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class MpvStartupTest {
    private val settings = DeviceSettings.DEFAULT

    @Test
    fun debugLoggingOpensEveryModuleButFfmpegsVideoDecoders() {
        assertEquals(listOf("msg-level" to "all=error"), MpvStartup.properties(settings, desktop = false))
        assertEquals("all=debug,ffmpeg/video=warn", MpvStartup.properties(settings.copy(debugLogging = true), desktop = false).toMap()["msg-level"])
        assertEquals("v", MpvStartup.logLevel(debugLogging = true))
        assertEquals("warn", MpvStartup.logLevel(debugLogging = false))
    }

    @Test
    fun aDesktopSavesScreenshotsInThePictures() {
        assertEquals("~/Pictures", MpvStartup.properties(settings, desktop = true).toMap()["screenshot-directory"])
    }

    @Test
    fun theStoredOutputPlaysOnlyWhileMpvListsIt() {
        val stored = settings.copy(audioOutputDevice = "wasapi/{abc}")
        val list = """[{"name":"auto","description":"Autoselect device"},{"name":"wasapi/{abc}","description":"Speakers"}]"""
        assertEquals("wasapi/{abc}", MpvStartup.preferredAudioDevice(stored, list))
        assertNull(MpvStartup.preferredAudioDevice(settings.copy(audioOutputDevice = "wasapi/{def}"), list), "unplugged: the system's choice")
        assertNull(MpvStartup.preferredAudioDevice(settings, list), "auto is the system's choice")
        assertNull(MpvStartup.preferredAudioDevice(stored, null), "no list yet")
    }

    @Test
    fun thePlayerOpensAtTheLastVolumeWithinTheTop() {
        assertEquals(250.0, MpvStartup.volumeMax(settings.copy(maxVolume = 250)))
        assertEquals(80.0, MpvStartup.volume(settings.copy(volume = 80.0)))
        assertEquals(100.0, MpvStartup.volume(settings.copy(volume = 180.0, maxVolume = 100)), "a lowered top caps it")
        assertEquals(180.0, MpvStartup.volume(settings.copy(volume = 180.0, maxVolume = 200)))
    }
}

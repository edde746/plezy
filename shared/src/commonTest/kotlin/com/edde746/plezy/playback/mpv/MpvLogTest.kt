package com.edde746.plezy.playback.mpv

import com.edde746.plezy.log.Log
import kotlin.test.Test
import kotlin.test.assertEquals

class MpvLogTest {
    @Test
    fun mpvsLevelsMapToTheAppsAsMpvAndMpvAndroidNameThem() {
        val levels = listOf("fatal", "error", "warn", "info", "v", "debug", "trace", "Fatal", "Verbose", "Trace", "new").associateWith(MpvLog::level)
        assertEquals(
            mapOf(
                "fatal" to Log.Level.ERROR, "error" to Log.Level.ERROR, "warn" to Log.Level.WARN, "info" to Log.Level.INFO,
                "v" to Log.Level.INFO, "debug" to Log.Level.DEBUG, "trace" to Log.Level.DEBUG, "Fatal" to Log.Level.ERROR,
                "Verbose" to Log.Level.INFO, "Trace" to Log.Level.DEBUG, "new" to Log.Level.DEBUG,
            ),
            levels,
        )
    }

    @Test
    fun aLineGoesToTheAppsLogUnderMpvWithItsModuleAndRedacted() {
        val original = Log.sink
        val written = mutableListOf<Triple<Log.Level, String, String>>()
        Log.sink = Log.Sink { level, tag, message, _ -> written += Triple(level, tag, message) }
        try {
            MpvLog.write(Log.Level.ERROR, "ffmpeg", "Failed to open https://example.invalid/library/parts/1/file.mkv?X-Plex-Token=secret123\n")
            val (level, tag, message) = written.single()
            assertEquals(Log.Level.ERROR to "mpv", level to tag)
            assertEquals(true, message.startsWith("[ffmpeg] Failed to open "), message)
            assertEquals(false, "secret123" in message, message)
        } finally {
            Log.sink = original
        }
    }
}

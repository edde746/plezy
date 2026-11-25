package com.edde746.plezy.mpv.core

import com.edde746.plezy.mpv.ffi.MpvFfi
import com.edde746.plezy.playback.COMMON_MPV_OPTIONS
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/** The desktop's mpv handle, on this machine's libmpv: it holds every engine's options and runs none of mpv's scripts. */
class MpvCoreTest {
    private val core = MpvCore.create(mapOf("vo" to "null", "ao" to "null"))

    @AfterTest
    fun destroy() = core.terminateDestroy()

    @Test
    fun theCoreHoldsEveryEnginesOptions() {
        for ((name, value) in COMMON_MPV_OPTIONS) {
            val held = assertNotNull(core.getString(name), name)
            // mpv writes a number back in a format of its own (130.000000).
            val number = value.toDoubleOrNull()
            if (number != null) assertEquals(number, held.toDouble(), name) else assertEquals(value, held, name)
        }
    }

    /** libmpv's own profile keeps the core idle without a file and takes no input of its own; nothing here undoes it. */
    @Test
    fun theCoreIdlesWithoutAFileAndTakesNoInputOfItsOwn() {
        assertEquals("yes", core.getString("idle"))
        assertEquals("no", core.getString("input-default-bindings"))
        assertEquals("no", core.getString("input-vo-keyboard"))
        assertEquals("no", core.getString("osc"))
    }

    @Test
    fun noneOfMpvsScriptsRuns() {
        // A message reaches a client that exists: this handle's own, "main".
        assertTrue(core.command("script-message-to", "main", "probe") >= 0)
        for (script in BUILTIN_SCRIPTS) {
            assertTrue(core.command("script-message-to", script, "probe") < 0, "mpv's $script script runs")
        }
    }

    /**
     * The engine sets a file's lavf options as a property before its loadfile
     * ([com.edde746.plezy.playback.mpv.MpvLoad.fileProperties]); the next file's clears them.
     */
    @Test
    fun aFilesLavfOptionsHoldUntilTheNextFileClearsThem() {
        assertTrue(core.setString("demuxer-lavf-o", "live_start_index=-30") >= 0)
        assertEquals("live_start_index=-30", core.getString("demuxer-lavf-o"))
        assertTrue(core.setString("demuxer-lavf-o", "") >= 0)
        assertEquals("", core.getString("demuxer-lavf-o"))
    }

    /** An observation mpv refuses throws: the engine's core then fails instead of playing without that property. */
    @Test
    fun anObservationMpvRefusesThrows() {
        // mpv observes nothing as an OSD string.
        assertFailsWith<IllegalStateException> { core.observe(1, "time-pos", MpvFfi.MPV_FORMAT_OSD_STRING()) }
    }

    /** A log level mpv refuses throws: the engine's core then fails instead of playing without mpv's warnings. */
    @Test
    fun aLogLevelMpvRefusesThrows() {
        assertFailsWith<IllegalStateException> { core.requestLogMessages("chatty") }
    }

    private companion object {
        /** The scripts mpv 0.41 builds in (`player/lua/`), by the client names they run under. */
        val BUILTIN_SCRIPTS = listOf(
            "osc", "ytdl_hook", "stats", "console", "auto_profiles", "select", "positioning", "commands", "context_menu",
        )
    }
}

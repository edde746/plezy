package com.edde746.plezy

import android.app.ApplicationExitInfo
import com.edde746.plezy.PreviousExit.Device
import com.edde746.plezy.PreviousExit.Exit
import com.edde746.plezy.PreviousExit.Launch
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

class PreviousExitTest {
    private val shield = Device("NVIDIA Shield", 35, "arm64-v8a", lowRam = false)

    private fun report(timestamp: Long, launch: Launch = Launch()) = PreviousExit.map(Exit(reason = 4, status = 1, importance = 100, timestamp = timestamp), shield, launch)

    @Test
    fun `only failures and exits the viewer noticed become crash reports one per reason`() {
        // Routine background kills (cached 400, service 300) stay in the log.
        assertNull(PreviousExit.messageFor("low_memory", 400))
        assertNull(PreviousExit.messageFor("user_requested", 400))
        assertNull(PreviousExit.messageFor("other", 300))
        // Failures, wherever the process was.
        assertEquals("Previous Android application exit: anr", PreviousExit.messageFor("anr", 400))
        assertEquals("Previous Android application exit: native_crash", PreviousExit.messageFor("native_crash", 400))
        // Any exit the viewer could see (foreground 100) or hear (perceptible 230).
        assertEquals("Previous Android application exit: other", PreviousExit.messageFor("other", 100))
        assertEquals("Previous Android application exit: low_memory", PreviousExit.messageFor("low_memory", 230))
    }

    @Test
    fun `exit reasons map deterministically`() {
        mapOf(
            ApplicationExitInfo.REASON_EXIT_SELF to "exit_self",
            ApplicationExitInfo.REASON_SIGNALED to "signaled",
            ApplicationExitInfo.REASON_LOW_MEMORY to "low_memory",
            ApplicationExitInfo.REASON_CRASH to "crash",
            ApplicationExitInfo.REASON_CRASH_NATIVE to "native_crash",
            ApplicationExitInfo.REASON_ANR to "anr",
            ApplicationExitInfo.REASON_INITIALIZATION_FAILURE to "initialization_failure",
            ApplicationExitInfo.REASON_PERMISSION_CHANGE to "permission_change",
            ApplicationExitInfo.REASON_EXCESSIVE_RESOURCE_USAGE to "excessive_resource_usage",
            ApplicationExitInfo.REASON_USER_REQUESTED to "user_requested",
            ApplicationExitInfo.REASON_USER_STOPPED to "user_requested",
            ApplicationExitInfo.REASON_DEPENDENCY_DIED to "dependency_died",
            ApplicationExitInfo.REASON_FREEZER to "freezer",
            ApplicationExitInfo.REASON_PACKAGE_STATE_CHANGE to "package_state_change",
            ApplicationExitInfo.REASON_PACKAGE_UPDATED to "package_updated",
            ApplicationExitInfo.REASON_OTHER to "other",
            ApplicationExitInfo.REASON_UNKNOWN to "other",
            999 to "other",
        ).forEach { (code, reason) -> assertEquals(reason, PreviousExit.reasonName(code), "code $code") }
    }

    @Test
    fun `a duplicate exit is suppressed and a newer one reported`() {
        var stored: String? = null
        fun take(report: PreviousExit.Report) = PreviousExit.takeIfNew(report, { stored }, { stored = it; true })
        val first = report(100)

        assertNotNull(take(first))
        assertNull(take(first))
        assertNotNull(take(report(101)))
    }

    @Test
    fun `an exit whose key cannot be committed is not reported`() {
        assertNull(PreviousExit.takeIfNew(report(100), { null }, { false }))
    }

    @Test
    fun `the dedupe key uses the exits stable fields and is not reported`() {
        assertEquals(report(100).dedupeKey, report(100).dedupeKey)
        assertNotEquals(report(100).dedupeKey, report(101).dedupeKey)
        assertEquals(64, report(100).dedupeKey.length)
        assertEquals(setOf("reason", "status", "importance", "timestamp", "deviceModel", "apiLevel", "abi", "lowRam"), report(100).details.keys)
    }

    @Test
    fun `the startup phase is attached without changing the dedupe key`() {
        val firstFrame = report(100, Launch(startupPhase = "first_frame"))
        val mainScreen = report(100, Launch(startupPhase = "main_screen"))
        val invalid = report(100, Launch(startupPhase = "profile-name"))

        assertEquals(firstFrame.dedupeKey, mainScreen.dedupeKey)
        assertEquals("first_frame", firstFrame.details["startupPhase"])
        assertEquals("main_screen", mainScreen.details["startupPhase"])
        assertFalse("startupPhase" in invalid.details)
    }

    @Test
    fun `the ui state reaches the report only from the fixed vocabulary`() {
        assertEquals("player", report(100, Launch(uiState = "player")).details["uiState"])
        assertFalse("uiState" in report(100, Launch(uiState = "server-name")).details)
    }

    @Test
    fun `the description is masked to fixed characters without identifiers`() {
        assertEquals("[FORCE STOP] stop <pkg> due to from pid #", PreviousExit.description("[FORCE STOP] stop com.edde746.plezy due to from pid 6092"))
        assertEquals("excessive cpu # during # dur=# limit=#", PreviousExit.description("excessive cpu 1234 during 300000 dur=300000 limit=2"))
        assertEquals("kill server", PreviousExit.description("kill\u0000 ü\n server"))
        assertNull(PreviousExit.description("ü\u0000"))
        assertNull(PreviousExit.description(null))
        assertEquals(120, PreviousExit.description("a".repeat(500))!!.length)
    }

    @Test
    fun `the description and only plausible memory figures are reported`() {
        val details = PreviousExit.map(Exit(reason = 3, status = 0, importance = 400, timestamp = 100, description = "too many cached", pssKb = 204_800, rssKb = 0), shield).details

        assertEquals("too many cached", details["description"])
        assertEquals(204_800L, details["pssKb"])
        assertFalse("rssKb" in details)
    }

    @Test
    fun `device fields are normalised and no arbitrary abi accepted`() {
        val details = PreviousExit.map(Exit(reason = 6, status = 0, importance = 100, timestamp = 100), Device("  Shield\u0000   Pro  ", 35, "user-supplied", false)).details

        assertEquals("Shield Pro", details["deviceModel"])
        assertEquals("unknown", details["abi"])
        assertEquals("unknown", PreviousExit.deviceModel(" \t\u0000"))
        assertEquals(80, PreviousExit.deviceModel("x".repeat(200)).length)
    }

    @Test
    fun `the previous playback diagnostics are reported with the ui state`() {
        val playback = mapOf<String, Any>("codecContext" to "audio:truehd", "channelCount" to 8, "passthroughEnabled" to true, "playerActive" to true)
        val details = PreviousExit.map(Exit(reason = 5, status = 0, importance = 100, timestamp = 100), shield, Launch(uiState = "player", playback = playback)).details

        assertEquals("audio:truehd", details["codecContext"])
        assertEquals(8, details["channelCount"])
        assertEquals(true, details["passthroughEnabled"])
        assertEquals(true, details["playerActive"])
        assertEquals("player", details["uiState"])
    }
}

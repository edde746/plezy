package com.edde746.plezy.desktop.harness

import androidx.compose.runtime.MonotonicFrameClock
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withContext
import kotlin.io.path.createTempDirectory
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** The report's startup watch asks the window for a frame only to mark a milestone it shows, never while it waits. */
class StartupWatchTest {
    /**
     * Before the app is up the window shows its first frame alone: the watch asks for one frame to mark it, then none
     * for the rest of its 30 seconds. Asking for every frame while it waited drew the window at the display's rate for
     * those 30 seconds whenever a run started off Home.
     */
    @Test
    fun theWatchAsksForOneFrameToMarkTheFirstAndNoneWhileItWaits() = runTest {
        val dir = createTempDirectory("startup")
        try {
            val report = TestReport(dir.resolve("report.jsonl"))
            var frames = 0
            val clock = object : MonotonicFrameClock {
                override suspend fun <R> withFrameNanos(onFrame: (Long) -> R): R {
                    frames++
                    return onFrame(0L)
                }
            }
            withContext(clock) { report.watchStartup() }
            assertEquals(1, frames, "frames asked for")
            assertTrue(testScheduler.currentTime >= 30_000, "it waited its 30 seconds for Home")
        } finally {
            dir.toFile().deleteRecursively()
        }
    }
}

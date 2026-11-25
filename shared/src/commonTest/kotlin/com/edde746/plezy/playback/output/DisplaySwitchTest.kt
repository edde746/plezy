@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.edde746.plezy.playback.output

import kotlinx.coroutines.async
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TestTimeSource

/**
 * A display switch: when the switch the app asked for is done (the settle clock starts only when the display lands on
 * the mode asked for, and a display that never lands is given up on), the window around it in which the system's
 * pauses aren't the viewer's, and a desktop's restore that keeps what the platform didn't confirm.
 */
class DisplaySwitchTest {
    private val hz60 = DisplayMode(0, 1920, 1080, 60.0)
    private val hz23976 = DisplayMode(1, 1920, 1080, 23.976)
    private val hz2997 = DisplayMode(2, 1920, 1080, 29.97)

    /** A switch from [start] to [target] for [fps], the display's mode in [display], running in the test. */
    private fun TestScope.switch(display: MutableStateFlow<DisplayMode?>, target: DisplayMode, fps: Double, start: DisplayMode = hz60) =
        async { ModeSwitch.await(display, target, start.id, fps, extraDelayMs = 0) }

    @Test
    fun unrelatedDisplayChangesLeaveTheSwitchPending() = runTest {
        val display = MutableStateFlow<DisplayMode?>(hz60)
        val done = switch(display, hz23976, 23.976)
        runCurrent()
        // The display reports itself again, still on the mode the switch started from: no settle starts.
        display.value = hz60.copy()
        advanceTimeBy(2_500)
        assertFalse(done.isCompleted)

        display.value = hz23976
        advanceTimeBy(1_900)
        assertFalse(done.isCompleted)
        advanceTimeBy(200)
        assertTrue(done.isCompleted)
        assertTrue(done.await())
    }

    @Test
    fun aLateSwitchStillGetsItsFullSettle() = runTest {
        val display = MutableStateFlow<DisplayMode?>(hz60)
        val done = switch(display, hz23976, 23.976)
        advanceTimeBy(4_900)
        display.value = hz23976
        // The watchdog would have given up at 5 s; the settle decides now.
        advanceTimeBy(1_000)
        assertFalse(done.isCompleted)
        advanceTimeBy(1_100)
        assertTrue(done.await())
    }

    @Test
    fun aDisplayThatIgnoresTheRequestCompletesUnswitchedFromTheWatchdog() = runTest {
        val display = MutableStateFlow<DisplayMode?>(hz60)
        val done = switch(display, hz23976, 23.976)
        advanceTimeBy(4_900)
        assertFalse(done.isCompleted)
        advanceTimeBy(200)
        assertFalse(done.await())
    }

    @Test
    fun theStartModeNeverCountsAsSwitchedEvenAtAMultipleOfTheRate() = runTest {
        // 29.97 fps on 60 Hz with an exact 29.97 mode: the switch exists because exact beat 2×.
        val display = MutableStateFlow<DisplayMode?>(hz60)
        val done = switch(display, hz2997, 29.97)
        display.value = hz60.copy()
        advanceTimeBy(2_500)
        assertFalse(done.isCompleted)
        advanceTimeBy(3_000)
        assertFalse(done.await())
    }

    @Test
    fun anEquivalentModeChosenByTheDisplayCountsAsSwitched() = runTest {
        val alternative = DisplayMode(3, 1920, 1080, 23.976)
        val display = MutableStateFlow<DisplayMode?>(hz60)
        val done = switch(display, hz23976, 23.976)
        runCurrent()
        display.value = alternative
        advanceTimeBy(2_100)
        assertTrue(done.await())
    }

    @Test
    fun theDisplaySwitchDelayLengthensTheSettle() = runTest {
        val display = MutableStateFlow<DisplayMode?>(hz60)
        val done = async { ModeSwitch.await(display, hz23976, hz60.id, 23.976, extraDelayMs = 3_000) }
        runCurrent()
        display.value = hz23976
        advanceTimeBy(4_900)
        assertFalse(done.isCompleted)
        advanceTimeBy(200)
        assertTrue(done.await())
    }

    @Test
    fun aSingleSuppressionWindowLastsThroughItsDeadline() {
        val time = TestTimeSource()
        val suppression = PauseSuppression(time)
        suppression.begin(delaySeconds = 2)
        assertTrue(suppression.active)
        time += 4_999.milliseconds
        assertTrue(suppression.active)
        time += 1.milliseconds
        assertFalse(suppression.active)
    }

    @Test
    fun overlappingSuppressionWindowsLastUntilTheNewestDeadline() {
        val time = TestTimeSource()
        val suppression = PauseSuppression(time)
        suppression.begin(delaySeconds = 0)
        time += 2.seconds
        suppression.begin(delaySeconds = 0)
        time += 1.seconds
        assertTrue(suppression.active, "the older window doesn't close the newer one")
        time += 1_999.milliseconds
        assertTrue(suppression.active)
        time += 1.milliseconds
        assertFalse(suppression.active)
    }

    @Test
    fun clearingEndsAnActiveWindow() {
        val time = TestTimeSource()
        val suppression = PauseSuppression(time)
        suppression.begin(delaySeconds = 0)
        suppression.clear()
        assertFalse(suppression.active)
        time += 10.seconds
        assertFalse(suppression.active)
    }

    @Test
    fun aRefusedModeRestoreIsKeptForTheNextRestore() {
        val restore = DisplayRestore().apply { modeChanged = true }
        val calls = mutableListOf<String>()
        var accepted = false
        val mode = { calls += "mode"; accepted }
        restore.restoreAll(restoreHdr = { calls += "hdr"; true }, restoreMode = mode)
        assertTrue(restore.anyChanged)
        accepted = true
        restore.restoreAll(restoreHdr = { calls += "hdr"; true }, restoreMode = mode)
        assertEquals(listOf("mode", "mode"), calls)
        assertFalse(restore.anyChanged)
    }

    @Test
    fun aRefusedHdrRestoreIsKeptForTheNextRestore() {
        val restore = DisplayRestore().apply { hdrChanged = true }
        var accepted = false
        restore.restoreAll(restoreHdr = { accepted }, restoreMode = { error("nothing to restore") })
        assertTrue(restore.hdrChanged)
        accepted = true
        restore.restoreAll(restoreHdr = { accepted }, restoreMode = { error("nothing to restore") })
        assertFalse(restore.anyChanged)
    }

    @Test
    fun anHdrFailureDoesNotKeepTheModeFromItsRestore() {
        val restore = DisplayRestore().apply { modeChanged = true; hdrChanged = true }
        val calls = mutableListOf<String>()
        var hdrAccepted = false
        val hdr = { calls += "hdr"; hdrAccepted }
        val mode = { calls += "mode"; true }
        restore.restoreAll(hdr, mode)
        assertEquals(listOf("hdr", "mode"), calls, "HDR first, then the mode")
        assertTrue(restore.hdrChanged)
        assertFalse(restore.modeChanged)

        calls.clear()
        hdrAccepted = true
        restore.restoreAll(hdr, mode)
        assertEquals(listOf("hdr"), calls)
        assertFalse(restore.anyChanged)
    }

    @Test
    fun aModeFailureDoesNotKeepHdrFromItsRestore() {
        val restore = DisplayRestore().apply { modeChanged = true; hdrChanged = true }
        val calls = mutableListOf<String>()
        var modeAccepted = false
        val hdr = { calls += "hdr"; true }
        val mode = { calls += "mode"; modeAccepted }
        restore.restoreAll(hdr, mode)
        assertEquals(listOf("hdr", "mode"), calls)
        assertFalse(restore.hdrChanged)
        assertTrue(restore.anyChanged)

        calls.clear()
        modeAccepted = true
        restore.restoreAll(hdr, mode)
        assertEquals(listOf("mode"), calls)
        assertFalse(restore.anyChanged)
    }

    @Test
    fun aThrowingRestoreKeepsOnlyItsOwnRecord() {
        val restore = DisplayRestore().apply { modeChanged = true; hdrChanged = true }
        val calls = mutableListOf<String>()
        restore.restoreAll(restoreHdr = { calls += "hdr"; error("restore failed") }, restoreMode = { calls += "mode"; true })
        assertEquals(listOf("hdr", "mode"), calls)
        assertTrue(restore.hdrChanged)
        assertFalse(restore.modeChanged)
    }
}

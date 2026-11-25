package com.edde746.plezy.mpv

import com.edde746.plezy.mpv.AudioRecovery.Action
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class AudioRecoveryTest {
    @Test
    fun aWakeFromSleepReloadsTwiceAfterOneAndAHalfAndThenFourAndAHalfSeconds() {
        val r = AudioRecovery()
        r.setFileLoaded(true, 0)
        r.requestResume()
        assertNull(r.next(0))
        assertNull(r.next(1_499))
        assertEquals(Action.Reload("resume", 1), r.next(1_500))
        assertNull(r.next(5_999))
        assertEquals(Action.Reload("resume", 2), r.next(6_000))
        assertNull(r.next(60_000))
    }

    @Test
    fun noFileNoResumeReload() {
        val r = AudioRecovery()
        r.requestResume()
        r.setFileLoaded(true, 0)
        assertNull(r.next(10_000))
    }

    @Test
    fun aNullOutputReloadsWithADoublingWaitFiveTimesThenGivesUpOneWaitLater() {
        val r = AudioRecovery()
        r.setFileLoaded(true, 0)
        r.setOutput("wasapi", 0)
        r.setOutput("null", 0)
        val reloads = mutableListOf<Long>()
        var giveUp: Long? = null
        for (t in 0L..60_000L step 50) {
            when (r.next(t)) {
                is Action.Reload -> reloads += t
                Action.GiveUp -> giveUp = t
                null -> Unit
            }
        }
        assertEquals(listOf(500L, 1_000L, 2_000L, 4_000L, 8_000L), reloads)
        assertEquals(16_000L, giveUp, "the last reload gets its wait too")
    }

    @Test
    fun anOutputThatComesBackStopsTheReloads() {
        val r = AudioRecovery()
        r.setFileLoaded(true, 0)
        r.setOutput("wasapi", 0)
        r.setOutput("null", 0)
        assertEquals(Action.Reload("null output", 1), r.next(500))
        r.setOutput("wasapi", 600)
        assertNull(r.next(20_000))
    }

    @Test
    fun aFlapWithinTenSecondsIsTheSameOutageAndALaterOneANewBudget() {
        val r = AudioRecovery()
        r.setFileLoaded(true, 0)
        r.setOutput("wasapi", 0)
        r.setOutput("null", 0)
        assertEquals(Action.Reload("null output", 1), r.next(500))
        r.setOutput("wasapi", 600)
        r.setOutput("null", 5_000)
        assertNull(r.next(5_500), "same outage: its doubled wait")
        assertEquals(Action.Reload("null output", 2), r.next(6_000))
        r.setOutput("wasapi", 6_100)
        r.setOutput("null", 30_000)
        assertEquals(Action.Reload("null output", 1), r.next(30_500), "a new outage starts over")
    }

    @Test
    fun aNewDeviceRestartsTheBudgetAfterADebounce() {
        val r = AudioRecovery()
        r.setFileLoaded(true, 0)
        r.setOutput("wasapi", 0)
        r.setOutput("null", 0)
        for (t in 0L..20_000L step 50) if (r.next(t) == Action.GiveUp) break
        r.onDeviceListChanged(30_000)
        assertNull(r.next(30_200))
        assertEquals(Action.Reload("null output", 1), r.next(30_250))
    }

    @Test
    fun anOutageCarriesAcrossFilesWithItsBudget() {
        val r = AudioRecovery()
        r.setFileLoaded(true, 0)
        r.setOutput("wasapi", 0)
        r.setOutput("null", 0)
        assertEquals(Action.Reload("null output", 1), r.next(500))
        r.setFileLoaded(false, 600)
        assertNull(r.next(5_000), "no file, no reload")
        r.setFileLoaded(true, 5_000)
        assertNull(r.next(5_500), "the same outage: its doubled wait")
        assertEquals(Action.Reload("null output", 2), r.next(6_000))
    }

    @Test
    fun withoutAnOutputEverANullOutputPlaysOnWithoutReloadsOrAGiveUp() {
        val r = AudioRecovery()
        r.setOutput(null, 0)
        r.setFileLoaded(true, 0)
        r.setOutput("null", 0)
        for (t in 0L..120_000L step 50) assertNull(r.next(t), "at $t ms")
    }

    @Test
    fun withoutAnOutputEverANewDeviceIsTriedButNeverFailsTheFile() {
        val r = AudioRecovery()
        r.setFileLoaded(true, 0)
        r.setOutput("null", 0)
        r.onDeviceListChanged(30_000)
        val actions = (30_000L..90_000L step 50).mapNotNull { r.next(it) }
        assertEquals((1..AudioRecovery.NULL_BUDGET).map { Action.Reload("null output", it) }, actions)
    }

    @Test
    fun anOutputThatPlayedAndThenWentNullStillFailsTheFileAfterItsReloads() {
        val r = AudioRecovery()
        r.setFileLoaded(true, 0)
        r.setOutput("wasapi", 0)
        r.setOutput("null", 1_000)
        val actions = (1_000L..60_000L step 50).mapNotNull { r.next(it) }
        assertEquals(Action.GiveUp, actions.last())
        assertEquals(AudioRecovery.NULL_BUDGET + 1, actions.size)
    }
}

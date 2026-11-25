package com.edde746.plezy.playback.session

import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

class Http503WatchdogTest {
    private var fired = 0

    private fun TestScope.watchdog() = Http503Watchdog(backgroundScope) { fired++ }

    private fun TestScope.elapse(duration: Duration) {
        advanceTimeBy(duration)
        runCurrent()
    }

    @Test
    fun firesOncePatienceElapsedAfterTheFirstOpenPhase503() = runTest {
        val watchdog = watchdog()
        watchdog.onOpenPhase503()
        elapse(Http503Watchdog.PATIENCE - 1.milliseconds)
        assertEquals(0, fired)
        elapse(1.milliseconds)
        assertEquals(1, fired)
        elapse(Http503Watchdog.PATIENCE * 2)
        assertEquals(1, fired, "it fails the open once")
    }

    @Test
    fun repeated503sFromTheReconnectLoopKeepTheFirstDeadline() = runTest {
        val watchdog = watchdog()
        watchdog.onOpenPhase503()
        elapse(Http503Watchdog.PATIENCE - 1.seconds)
        watchdog.onOpenPhase503()
        watchdog.onOpenPhase503()
        elapse(1.seconds)
        assertEquals(1, fired)
    }

    @Test
    fun disarmingBeforeTheDeadlinePreventsTheFailure() = runTest {
        val watchdog = watchdog()
        watchdog.onOpenPhase503()
        elapse(Http503Watchdog.PATIENCE - 1.seconds)
        watchdog.disarm()
        elapse(Http503Watchdog.PATIENCE * 2)
        assertEquals(0, fired)
    }

    @Test
    fun a503AfterDisarmReArmsWithAFreshDeadline() = runTest {
        val watchdog = watchdog()
        watchdog.onOpenPhase503()
        elapse(Http503Watchdog.PATIENCE - 1.seconds)
        watchdog.disarm()
        watchdog.onOpenPhase503()
        elapse(Http503Watchdog.PATIENCE - 1.seconds)
        assertEquals(0, fired)
        elapse(1.seconds)
        assertEquals(1, fired)
    }

    @Test
    fun neverFiresWithoutAn503() = runTest {
        watchdog()
        elapse(Http503Watchdog.PATIENCE * 3)
        assertEquals(0, fired)
    }
}

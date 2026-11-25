package com.edde746.plezy.playback.session

import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class VideoSessionsTest {
    private val sessions = VideoSessions()
    private val old = Any()
    private val active = Any()

    @Test
    fun aStaleReleaseKeepsTheActiveOwnerAndAStopWaitsForIt() = runTest {
        val stopped = CompletableDeferred<Unit>()
        var oldStops = 0
        sessions.register(old, { oldStops++ })
        sessions.register(active, { stopped.await() })
        sessions.unregister(old)

        val shutdown = async { sessions.shutdownVideo() }
        runCurrent()
        assertFalse(shutdown.isCompleted)
        stopped.complete(Unit)
        shutdown.await()

        sessions.unregister(active)
        sessions.shutdownVideo()
        assertEquals(0, oldStops)
    }

    @Test
    fun lateStopsWaitForTheRetiredSessionsReportsAndNativeCleanup() = runTest {
        val report = CompletableDeferred<Unit>()
        val nativeDisposal = CompletableDeferred<Unit>()
        val retirement = async { report.await(); nativeDisposal.await() }
        sessions.register(old, {})
        sessions.unregister(old, retirement)

        val shutdown = async { sessions.shutdownVideo() }
        val stop = async { sessions.stopVideoAndExit() }
        runCurrent()
        assertFalse(shutdown.isCompleted)
        assertFalse(stop.isCompleted)
        report.complete(Unit)
        runCurrent()
        assertFalse(shutdown.isCompleted)
        assertFalse(stop.isCompleted)

        nativeDisposal.complete(Unit)
        shutdown.await()
        assertTrue(stop.await())
        assertTrue(sessions.stopVideoAndExit())
    }

    @Test
    fun aPredecessorsRetirementSurvivesItsReplacementAndStaleUnregisters() = runTest {
        val retirement = CompletableDeferred<Unit>()
        val activeStopped = CompletableDeferred<Unit>()
        var activeStops = 0
        var activeExits = 0
        sessions.register(old, {})
        sessions.unregister(old, retirement)
        sessions.register(active, { activeStops++; activeStopped.await() }, stopAndExit = { activeExits++; false })
        sessions.unregister(old, retirement)

        val shutdown = async { sessions.shutdownVideo() }
        val stop = async { sessions.stopVideoAndExit() }
        activeStopped.complete(Unit)
        runCurrent()
        assertEquals(1 to 1, activeStops to activeExits)
        assertFalse(shutdown.isCompleted)
        assertFalse(stop.isCompleted)

        retirement.complete(Unit)
        shutdown.await()
        assertFalse(stop.await())
        sessions.unregister(old)
        assertFalse(sessions.stopVideoAndExit())
        assertEquals(2, activeExits)
        sessions.unregister(active)
        assertTrue(sessions.stopVideoAndExit())
        assertEquals(2, activeExits)
    }

    @Test
    fun aReplacedOwnerCanHandOverItsRetirementWithoutReleasingItsSuccessor() = runTest {
        val retirement = CompletableDeferred<Unit>()
        var activeStops = 0
        sessions.register(old, {})
        sessions.register(active, { activeStops++ })
        sessions.unregister(old, retirement)

        val shutdown = async { sessions.shutdownVideo() }
        runCurrent()
        assertEquals(1, activeStops)
        assertFalse(shutdown.isCompleted)
        retirement.complete(Unit)
        shutdown.await()
        sessions.shutdownVideo()
        assertEquals(2, activeStops)
    }

    @Test
    fun aFailedRetirementReachesWaitingCallersAndIsReleased() = runTest {
        val retirement = CompletableDeferred<Unit>()
        val failure = IllegalStateException("native retirement failed")
        sessions.register(old, {})
        sessions.unregister(old, retirement)

        val shutdown = async { runCatching { sessions.shutdownVideo() }.exceptionOrNull() }
        val stop = async { runCatching { sessions.stopVideoAndExit() }.exceptionOrNull() }
        runCurrent()
        retirement.completeExceptionally(failure)
        assertEquals(failure.message, shutdown.await()?.message)
        assertEquals(failure.message, stop.await()?.message)
        sessions.shutdownVideo()
        assertTrue(sessions.stopVideoAndExit())
    }

    @Test
    fun aFailedRetirementIsReleasedWithoutAWaiter() = runTest {
        val retirement = CompletableDeferred<Unit>()
        sessions.register(old, {})
        sessions.unregister(old, retirement)
        retirement.completeExceptionally(IllegalStateException("retirement failed after the player left"))
        assertTrue(sessions.stopVideoAndExit())
        assertFailsWith<IllegalStateException> { retirement.await() }
    }
}

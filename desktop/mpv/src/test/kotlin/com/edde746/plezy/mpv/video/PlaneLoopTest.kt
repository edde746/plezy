package com.edde746.plezy.mpv.video

import java.util.Collections
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Semaphore
import java.util.concurrent.TimeUnit
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotSame
import kotlin.test.assertTrue

class PlaneLoopTest {
    private val signal = Semaphore(0)
    private val loops = mutableListOf<PlaneLoop>()

    private fun loop(turn: () -> Int = { -1 }) = PlaneLoop(
        "plane-test",
        turn = turn,
        wait = { timeout -> if (timeout < 0) signal.acquire() else signal.tryAcquire(timeout.toLong(), TimeUnit.MILLISECONDS); signal.drainPermits() },
        wake = { signal.release() },
    ).also { loops += it; it.start() }

    @AfterTest
    fun stop() {
        loops.forEach { it.shutdownAndJoin(1000) }
    }

    @Test
    fun aJobRunsOnTheLoopsOwnThread() {
        val loop = loop()
        val ran = CountDownLatch(1)
        var jobThread: Thread? = null
        var onLoop = false
        assertTrue(loop.post { jobThread = Thread.currentThread(); onLoop = loop.isLoopThread; ran.countDown() })
        assertTrue(ran.await(5, TimeUnit.SECONDS))
        assertNotSame(Thread.currentThread(), jobThread)
        assertTrue(onLoop)
    }

    @Test
    fun aJobThatFailsLeavesTheLoopRunningTheNext() {
        val loop = loop()
        val ran = CountDownLatch(1)
        loop.post { error("render failed") }
        loop.post { ran.countDown() }
        assertTrue(ran.await(5, TimeUnit.SECONDS))
    }

    @Test
    fun jobsRunInTheOrderTheyWerePosted() {
        val loop = loop()
        val order = Collections.synchronizedList(mutableListOf<Int>())
        val done = CountDownLatch(3)
        for (i in 0 until 3) loop.post { order += i; done.countDown() }
        assertTrue(done.await(5, TimeUnit.SECONDS))
        assertEquals(listOf(0, 1, 2), order)
    }

    @Test
    fun shutdownRunsWhatWasQueuedAndRefusesAnythingAfter() {
        val loop = loop()
        val gate = CountDownLatch(1)
        var secondRan = false
        loop.post { gate.await() }
        loop.post { secondRan = true }
        Thread { Thread.sleep(50); gate.countDown() }.start()
        assertTrue(loop.shutdownAndJoin(5000))
        assertTrue(secondRan)
        assertFalse(loop.post {})
    }

    @Test
    fun aJobThatNeverReturnsIsAbandonedNotJoined() {
        val loop = loop()
        val stuck = CountDownLatch(1)
        val entered = CountDownLatch(1)
        loop.post { entered.countDown(); stuck.await() }
        assertTrue(entered.await(5, TimeUnit.SECONDS))
        val started = System.nanoTime()
        assertFalse(loop.shutdownAndJoin(200))
        assertTrue(TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - started) < 2000)
        stuck.countDown()
    }

    @Test
    fun thePlanesTurnRunsBetweenJobsAndItsTimeoutBoundsTheWait() {
        val turns = CountDownLatch(3)
        loop(turn = { turns.countDown(); 10 })
        assertTrue(turns.await(5, TimeUnit.SECONDS))
    }
}

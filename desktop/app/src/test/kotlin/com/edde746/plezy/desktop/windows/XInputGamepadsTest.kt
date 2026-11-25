package com.edde746.plezy.desktop.windows

import com.edde746.plezy.desktop.GamepadEvents
import com.edde746.plezy.input.GamepadButton
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.Semaphore
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class XInputGamepadsTest {
    private class Recorder : GamepadEvents {
        val events = LinkedBlockingQueue<String>()

        override fun button(button: GamepadButton, down: Boolean) {
            events += "$button ${if (down) "down" else "up"}"
        }

        override fun stick(x: Float, y: Float) {
            events += "stick $x $y"
        }

        override fun disconnected() {
            events += "disconnected"
        }

        fun drain(): List<String> = buildList { events.drainTo(this) }

        fun next(): String? = events.poll(10, TimeUnit.SECONDS)
    }

    private val neutral = XInputState(0, 0, 0)

    @Test
    fun eachButtonThatChangesIsAPressOrARelease() {
        val recorder = Recorder()
        XInputState(0x1000 or 0x0002 or 0x0100, 0, 0).changesFrom(neutral, recorder)
        assertEquals(setOf("A down", "DPAD_DOWN down", "LEFT_SHOULDER down"), recorder.drain().toSet())
        XInputState(0x0002, 0, 0).changesFrom(XInputState(0x1000 or 0x0002, 0, 0), recorder)
        assertEquals(listOf("A up"), recorder.drain())
        XInputState(0x4000 or 0x2000 or 0x0200, 0, 0).changesFrom(XInputState(0x4000 or 0x2000 or 0x0200, 0, 0), recorder)
        assertEquals(emptyList(), recorder.drain())
    }

    @Test
    fun theStickIsUpNegative() {
        val recorder = Recorder()
        XInputState(0, 32767, 32767).changesFrom(neutral, recorder)
        XInputState(0, -32768, -32767).changesFrom(neutral, recorder)
        assertEquals(listOf("stick 1.0 -1.0", "stick -1.0 1.0"), recorder.drain())
    }

    @Test
    fun aButtonHeldAsReadingStartsIsNoPressAndAControllerGoingAwayIsDisconnected() {
        val recorder = Recorder()
        val state = AtomicReference<XInputState?>(XInputState(0x1000, 0, 0))
        val reads = Semaphore(0)
        val pads = XInputGamepads(recorder) { slot -> if (slot == 0) state.get().also { reads.release() } else null }
        pads.resume()
        try {
            // The held button is where reading starts (the first read), and a poll after it has seen it held.
            assertTrue(reads.tryAcquire(2, 10, TimeUnit.SECONDS), "read while resumed")
            assertEquals(emptyList(), recorder.drain())
            state.set(XInputState(0x1000 or 0x0001, 0, 0))
            assertEquals("DPAD_UP down", recorder.next())
            state.set(null)
            assertEquals("disconnected", recorder.next())
        } finally {
            pads.pause()
        }
    }

    @Test
    fun pausedNothingIsRead() {
        val recorder = Recorder()
        val reads = Semaphore(0)
        val poller = AtomicReference<Thread>()
        // A connected controller, asked every poll while reading.
        val pads = XInputGamepads(recorder) {
            poller.set(Thread.currentThread())
            reads.release()
            neutral
        }
        pads.resume()
        // The four slots as reading starts, then a poll.
        assertTrue(reads.tryAcquire(5, 10, TimeUnit.SECONDS), "polled while resumed")
        pads.pause()
        // Pausing ends the polling thread: a read it was in as it paused is its last.
        poller.get().join(10_000)
        assertFalse(poller.get().isAlive, "polled while paused")
        assertNull(recorder.events.poll())
    }

    @Test
    fun resumedOnAMachineWithNoCoreFreeItReads() {
        // With no core free, the scheduler favours the poll thread resume() starts over a caller that has been running a
        // while: the poll thread can run before resume() returns, and must read then too.
        val cores = Runtime.getRuntime().availableProcessors()
        val busy = AtomicBoolean(true)
        // Every core busy with short-lived threads, each new one ahead of the threads that have been running.
        fun occupy() {
            Thread {
                spin(20)
                if (busy.get()) occupy()
            }.apply { isDaemon = true }.start()
        }
        repeat(cores * 2) { occupy() }
        val reads = List(cores * 2) { Semaphore(0) }
        val pads = reads.map { read -> XInputGamepads(Recorder()) { slot -> if (slot == 0) neutral.also { read.release() } else null } }
        try {
            pads.map { pad -> Thread { spin(50); pad.resume() }.apply { start() } }.forEach { it.join() }
            busy.set(false)
            val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(10)
            assertEquals(0, reads.count { !it.tryAcquire(2, deadline - System.nanoTime(), TimeUnit.NANOSECONDS) }, "sources that stopped reading")
        } finally {
            busy.set(false)
            pads.forEach { it.pause() }
        }
    }

    private fun spin(millis: Long) {
        val end = System.nanoTime() + TimeUnit.MILLISECONDS.toNanos(millis)
        while (System.nanoTime() < end) continue
    }
}

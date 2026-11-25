package com.edde746.plezy.mpv.os

import java.lang.foreign.Arena
import java.lang.foreign.ValueLayout
import kotlin.test.AfterTest
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import org.junit.Test

class QueueWaitTest {
    private val fds = mutableListOf<Int>()

    /** A connected AF_UNIX stream pair, as a Wayland connection's socket is. */
    private fun socketPair(): Pair<Int, Int> = Arena.ofConfined().use { a ->
        val pair = a.allocate(8)
        val rc = linker.defaultLookup().fn("socketpair", I32, I32, I32, I32, PTR).call(AF_UNIX, SOCK_STREAM, 0, pair) as Int
        check(rc == 0) { "socketpair failed" }
        val ends = pair.get(ValueLayout.JAVA_INT, 0) to pair.get(ValueLayout.JAVA_INT, 4)
        fds += ends.first
        fds += ends.second
        ends
    }

    @AfterTest
    fun closeAll() = fds.forEach(Posix::close)

    /** libwayland's side of a queue: a read on a closed socket and every dispatch after it fail, as a dead connection does. */
    private class FakeQueue(override val fd: Int, private val eventsQueued: Boolean = false) : EventQueue {
        var calls = 0
        var error = 0

        override fun prepareRead(): Int {
            calls++
            return if (eventsQueued) -1 else 0
        }

        override fun readEvents(): Int {
            calls++
            error = EPIPE
            return -1
        }

        override fun cancelRead() {
            calls++
        }

        override fun dispatchPending(): Int {
            calls++
            return if (eventsQueued || error != 0) -1 else 0
        }

        override fun flush(): Int {
            calls++
            return 0
        }

        override fun error(): Int = error
    }

    @Test(timeout = 10_000)
    fun `a connection whose peer closed is reported and the wait returns without touching it again`() {
        val (connection, compositor) = socketPair()
        val (wake, _) = socketPair()
        Posix.close(compositor)
        fds.remove(compositor)
        val queue = FakeQueue(connection)
        val wait = QueueWait(queue, wake, "test")

        wait.await(-1)
        assertTrue(wait.lost)
        val calls = queue.calls
        wait.await(50)
        assertEquals(calls, queue.calls)
    }

    @Test(timeout = 10_000)
    fun `a dead connection with events still queued ends the wait instead of spinning`() {
        val (connection, _) = socketPair()
        val (wake, _) = socketPair()
        val wait = QueueWait(FakeQueue(connection, eventsQueued = true), wake, "test")

        wait.await(-1)
        assertTrue(wait.lost)
    }

    private companion object {
        const val AF_UNIX = 1
        const val SOCK_STREAM = 1
        const val EPIPE = 32
    }
}

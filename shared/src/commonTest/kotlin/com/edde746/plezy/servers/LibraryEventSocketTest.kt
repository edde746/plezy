package com.edde746.plezy.servers

import com.edde746.plezy.model.LibraryChangeEvent
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

@OptIn(ExperimentalCoroutinesApi::class)
class LibraryEventSocketTest {
    private val connector = FakeLibraryEventConnector()

    private fun TestScope.socket(
        debounce: Duration = 100.milliseconds,
        retryBaseDelay: Duration = 5.seconds,
        maxConnectAttempts: Int = 5,
        connectTimeout: Duration = 10.seconds,
    ) = TestLibraryEventSocket(connector, backgroundScope, testScheduler.timeSource, debounce, retryBaseDelay, maxConnectAttempts, connectTimeout)

    private fun TestScope.collect(socket: LibraryEventSocket): List<LibraryChangeEvent> {
        val events = mutableListOf<LibraryChangeEvent>()
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { socket.events.collect { events += it } }
        return events
    }

    private fun TestScope.elapse(duration: Duration) {
        advanceTimeBy(duration)
        runCurrent()
    }

    @Test
    fun firstSettledEntryEmitsImmediatelyAndTheRestOfTheFloodCoalesces() = runTest {
        val channel = socket()
        val events = collect(channel)
        channel.start()
        runCurrent()
        val connection = connector.connections.single()

        connection.push("add:1")
        connection.push("add:1")
        connection.push("add:2")
        runCurrent()

        // Leading edge: the first change surfaces without waiting out the window.
        val first = events.single()
        assertEquals("plex_1", first.serverId.value)
        assertEquals(setOf("1"), first.libraryIds)
        assertTrue(first.itemsAdded)
        assertTrue(first.itemsUpdated)
        assertFalse(first.itemsRemoved)

        // The rest merges into exactly one trailing event.
        elapse(300.milliseconds)
        assertEquals(2, events.size)
        assertEquals(setOf("1", "2"), events[1].libraryIds)
        channel.dispose()
    }

    @Test
    fun anEntryWithoutALibraryAbsorbsTheNamedOnesInItsWindowInEitherOrder() = runTest {
        for (unnamedFirst in listOf(true, false)) {
            val channel = socket()
            val events = collect(channel)
            channel.start()
            runCurrent()
            val connection = connector.connections.last()

            // Prime the window so everything below coalesces into one trailing event.
            connection.push("add:9")
            runCurrent()
            assertEquals(1, events.size)

            connection.push(if (unnamedFirst) "add:" else "add:1")
            connection.push(if (unnamedFirst) "add:1" else "add:")
            connection.push("add:2")
            elapse(300.milliseconds)
            assertEquals(2, events.size, "unnamedFirst=$unnamedFirst")
            assertTrue(events[1].targetsWholeServer, "unnamedFirst=$unnamedFirst")

            // The absorbed scope doesn't leak into the next window.
            connection.push("add:3")
            elapse(200.milliseconds)
            assertEquals(3, events.size, "unnamedFirst=$unnamedFirst")
            assertEquals(setOf("3"), events[2].libraryIds, "unnamedFirst=$unnamedFirst")
            channel.dispose()
        }
    }

    @Test
    fun aSustainedStreamEmitsOncePerWindowInsteadOfStarving() = runTest {
        val channel = socket(debounce = 150.milliseconds)
        val events = collect(channel)
        channel.start()
        runCurrent()
        val connection = connector.connections.single()

        // A trailing-reset debounce would emit nothing until the stream stops.
        repeat(15) {
            connection.push("add:1")
            elapse(80.milliseconds)
        }

        assertTrue(events.size >= 2, "must not starve while frames keep arriving")
        assertTrue(events.size <= 10, "at most one event per window, not per frame")
        channel.dispose()
    }

    @Test
    fun removalsInOneWindowUnionTheirItemIds() = runTest {
        val channel = socket()
        val events = collect(channel)
        channel.start()
        runCurrent()
        val connection = connector.connections.single()

        connection.push("remove:1:10141")
        connection.push("remove:1:10142")
        connection.push("remove:1:10143")
        elapse(300.milliseconds)

        assertTrue(events[0].itemsRemoved)
        assertFalse(events[0].itemsAdded)
        assertEquals(setOf("10141"), events[0].removedItemIds)
        assertEquals(setOf("10142", "10143"), events[1].removedItemIds)
        channel.dispose()
    }

    @Test
    fun aMalformedFrameDoesNotKillTheChannel() = runTest {
        val channel = socket()
        val events = collect(channel)
        channel.start()
        runCurrent()
        val connection = connector.connections.single()

        connection.push("this is not json")
        connection.push("[1,2,3]")
        connection.push("add:1")
        runCurrent()

        assertTrue(events.single().itemsAdded)
        channel.dispose()
    }

    @Test
    fun reconnectsAfterTheServerDropsTheConnection() = runTest {
        val channel = socket()
        val events = collect(channel)
        channel.start()
        runCurrent()

        connector.connections.single().drop()
        runCurrent()
        elapse(5.seconds)
        assertEquals(2, connector.connections.size, "the second connection arrives on its own after the backoff")

        connector.connections[1].push("add:1")
        runCurrent()
        assertTrue(events.single().itemsAdded)
        channel.dispose()
    }

    @Test
    fun stopPreventsReconnecting() = runTest {
        val channel = socket()
        channel.start()
        runCurrent()

        channel.stop()
        elapse(5.minutes)

        assertEquals(1, connector.attempts, "no reconnect after stop")
        assertFalse(channel.isRunning)
        assertTrue(connector.connections.single().closed)
    }

    @Test
    fun stopWhileTheConnectIsPendingReleasesTheTransport() = runTest {
        var released = false
        connector.connect = {
            try {
                awaitCancellation()
            } finally {
                released = true
            }
        }
        val channel = socket(connectTimeout = 30.seconds)
        channel.start()
        runCurrent()

        channel.stop()
        runCurrent()

        assertTrue(released, "the pending connect was not cancelled by stop()")
        assertFalse(channel.isRunning)
    }

    @Test
    fun aConnectMissingItsDeadlineIsReleasedAndCountsAsAFailedAttempt() = runTest {
        var released = false
        connector.connect = {
            try {
                delay(30.seconds)
                FakeLibraryEventConnection()
            } finally {
                released = true
            }
        }
        val channel = socket(maxConnectAttempts = 0, connectTimeout = 200.milliseconds)
        channel.start()
        runCurrent()

        elapse(200.milliseconds)

        assertTrue(released)
        assertFalse(channel.isRunning, "with no retries left the socket gives up")
        assertTrue(connector.connections.isEmpty())
    }

    /** The gaps between [connector]'s connect attempts, each recorded at the scheduler's time. */
    private fun TestScope.refuseAndTimeAttempts(): List<Long> {
        val times = mutableListOf<Long>()
        connector.connect = {
            times += testScheduler.currentTime
            connector.refuse()
        }
        return times
    }

    private fun List<Long>.gaps() = zipWithNext { a, b -> (b - a).milliseconds }

    @Test
    fun failedConnectsBackOffExponentiallyWithJitterAndGiveUpAfterTheAttemptBudget() = runTest {
        val times = refuseAndTimeAttempts()
        val channel = socket()
        channel.start()
        runCurrent()
        assertEquals(1, connector.attempts)

        elapse(10.minutes)
        assertEquals(6, connector.attempts)
        assertFalse(channel.isRunning, "five retries, then quiet")
        for ((gap, bound) in times.gaps().zip(listOf(5.seconds, 10.seconds, 20.seconds, 40.seconds, 80.seconds))) {
            assertTrue(gap in bound / 2..bound, "a retry after $gap, outside half of $bound to $bound")
        }

        // start() re-arms an exhausted channel.
        channel.start()
        runCurrent()
        assertEquals(7, connector.attempts)
        channel.dispose()
    }

    @Test
    fun theBackoffIsCappedAtTwoMinutes() = runTest {
        val times = refuseAndTimeAttempts()
        val channel = socket(retryBaseDelay = 1.minutes, maxConnectAttempts = 3)
        channel.start()
        runCurrent()

        elapse(10.minutes)
        assertEquals(4, connector.attempts)
        assertTrue(times.gaps().last() <= 2.minutes, "the third delay is capped at 2 min, not 4")
        channel.dispose()
    }

    @Test
    fun theAttemptCountResetsOnConnect() = runTest {
        val channel = socket(maxConnectAttempts = 1)
        channel.start()
        runCurrent()

        connector.connections[0].drop()
        runCurrent()
        elapse(5.seconds)
        assertEquals(2, connector.connections.size)

        connector.connections[1].drop()
        runCurrent()
        elapse(5.seconds)
        assertEquals(3, connector.connections.size, "a connection reset the budget, so the drop retries again")
        assertTrue(channel.isRunning)
        channel.dispose()
    }
}

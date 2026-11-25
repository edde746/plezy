package com.edde746.plezy.servers

import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertSame

@OptIn(ExperimentalCoroutinesApi::class)
class CoalescedLoadCoordinatorTest {
    @Test
    fun fullRequestsShareOneDrainAndScheduleOneTrailingPass() = runTest {
        val gates = listOf(CompletableDeferred<Unit>(), CompletableDeferred<Unit>())
        var fullCalls = 0
        val coordinator = CoalescedLoadCoordinator<String>(
            backgroundScope,
            onFull = { gates[fullCalls++].await() },
            onDelta = {},
        )

        val first = coordinator.requestFull()
        val second = coordinator.requestFull()
        val third = coordinator.requestFull()

        assertSame(first, second)
        assertSame(first, third)
        assertEquals(1, fullCalls)

        gates[0].complete(Unit)
        runCurrent()
        assertEquals(2, fullCalls)

        gates[1].complete(Unit)
        first.await()
        assertEquals(2, fullCalls)
    }

    @Test
    fun deltaRequestsUnionBehindTheActivePass() = runTest {
        val gate = CompletableDeferred<Unit>()
        val passes = mutableListOf<Set<String>>()
        val coordinator = CoalescedLoadCoordinator<String>(
            backgroundScope,
            onFull = {},
            onDelta = { values ->
                passes += values
                if (passes.size == 1) gate.await()
            },
        )

        val drain = coordinator.requestDelta(setOf("a"))
        coordinator.requestDelta(setOf("b"))
        coordinator.requestDelta(setOf("b", "c"))
        assertEquals(listOf(setOf("a")), passes)

        gate.complete(Unit)
        drain.await()
        assertEquals(listOf(setOf("a"), setOf("b", "c")), passes)
    }

    @Test
    fun queuedFullTakesPriorityAndSupersedesQueuedDeltas() = runTest {
        val gate = CompletableDeferred<Unit>()
        val passes = mutableListOf<Any>()
        val coordinator = CoalescedLoadCoordinator<String>(
            backgroundScope,
            onFull = { passes += "full" },
            onDelta = { values ->
                passes.add(values)
                if (passes.size == 1) gate.await()
            },
        )

        val drain = coordinator.requestDelta(setOf("a"))
        coordinator.requestDelta(setOf("b"))
        coordinator.requestFull()
        gate.complete(Unit)
        drain.await()

        assertEquals(listOf<Any>(setOf("a"), "full"), passes)
    }

    @Test
    fun disposeCancelsTrailingAndFutureRequests() = runTest {
        val gate = CompletableDeferred<Unit>()
        var fullCalls = 0
        val coordinator = CoalescedLoadCoordinator<String>(
            backgroundScope,
            onFull = {
                fullCalls++
                gate.await()
            },
            onDelta = {},
        )

        val drain = coordinator.requestFull()
        coordinator.requestFull()
        coordinator.dispose()
        gate.complete(Unit)
        drain.await()
        coordinator.requestFull().await()
        coordinator.requestDelta(setOf("a")).await()

        assertEquals(1, fullCalls)
    }

    @Test
    fun clearPendingDiscardsTrailingWorkButRemainsReusable() = runTest {
        val gate = CompletableDeferred<Unit>()
        var fullCalls = 0
        val coordinator = CoalescedLoadCoordinator<String>(
            backgroundScope,
            onFull = {
                fullCalls++
                if (fullCalls == 1) gate.await()
            },
            onDelta = {},
        )

        val drain = coordinator.requestFull()
        coordinator.requestFull()
        coordinator.clearPending()
        gate.complete(Unit)
        drain.await()
        assertEquals(1, fullCalls)

        coordinator.requestFull().await()
        assertEquals(2, fullCalls)
    }
}

package com.edde746.plezy.trackers.client

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest

/** [KeyedLoads]: concurrent callers share one load; a memo keeps successes and drops failures. */
class KeyedLoadsTest {
    @Test
    fun callersOfOneKeyShareTheLoadInFlight() = runTest {
        val loads = KeyedLoads<String, Int>(memoize = false)
        val answer = CompletableDeferred<Int>()
        var calls = 0
        val first = async { loads.run("a") { calls++; answer.await() } }
        val second = async { loads.run("a") { calls++; answer.await() } }
        runCurrent()
        assertEquals(1, calls)

        answer.complete(42)
        assertEquals(42 to 42, first.await() to second.await())
    }

    @Test
    fun aNewLoadStartsOnceTheLastOneEnded() = runTest {
        val loads = KeyedLoads<String, Int>(memoize = false)
        var next = 0
        assertEquals(1, loads.run("a") { ++next })
        assertEquals(2, loads.run("a") { ++next })
    }

    @Test
    fun aMemoKeepsSuccessesAndEvictsFailures() = runTest {
        val loads = KeyedLoads<String, Int>(memoize = true)
        val errors = mutableListOf<Throwable>()
        var calls = 0
        suspend fun load(fail: Boolean): Int {
            calls++
            if (fail) throw IllegalStateException("boom")
            return calls
        }

        assertFailsWith<IllegalStateException> { loads.run("a", onError = { errors += it }) { load(fail = true) } }
        assertEquals(1, errors.size)

        assertEquals(2, loads.run("a") { load(fail = false) })
        assertEquals(2, loads.run("a") { load(fail = false) })
        assertEquals(2, calls)

        loads.clear()
        assertEquals(3, loads.run("a") { load(fail = false) })
        loads.remove("a")
        assertEquals(4, loads.run("a") { load(fail = false) })
    }

    @Test
    fun aCallerWaitingOnACancelledLoadLoadsAgain() = runTest {
        val loads = KeyedLoads<String, Int>(memoize = true)
        val never = CompletableDeferred<Int>()
        val owner = async { loads.run("a") { never.await() } }
        runCurrent()
        val waiter = async { loads.run("a") { 7 } }
        runCurrent()
        owner.cancel()
        assertEquals(7, waiter.await())
    }
}

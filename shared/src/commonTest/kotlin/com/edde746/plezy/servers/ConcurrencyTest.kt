@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.edde746.plezy.servers

import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineExceptionHandler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

class ConcurrencyTest {
    @Test
    fun aNamedTimeoutNamesTheOperation() = runTest {
        val error = assertFailsWith<OperationTimeoutException> {
            namedTimeout(10.milliseconds, "fetchThing") { awaitCancellation() }
        }
        assertTrue(error.message!!.contains("fetchThing"))
        assertTrue(error.message!!.contains("timed out"))
        assertEquals(10.milliseconds, error.timeLimit)
    }

    @Test
    fun aNamedTimeoutPassesAValueInTimeThrough() = runTest {
        assertEquals(42, namedTimeout(1.seconds, "fast") { 42 })
        assertNull(namedTimeout(1.seconds, "nothing") { null })
    }

    @Test
    fun aNamedTimeoutPropagatesOtherErrorsUnchanged() = runTest {
        assertFailsWith<IllegalStateException> { namedTimeout(1.seconds, "op") { throw IllegalStateException("boom") } }
    }

    @Test
    fun aValueArrivingAfterTheTimeoutIsReleased() = runTest {
        val released = mutableListOf<String>()
        val gate = CompletableDeferred<Unit>()

        assertFailsWith<OperationTimeoutException> {
            timeoutReleasingLate(10.milliseconds, "tune", backgroundScope, releaseLate = { released += it }) {
                gate.await()
                "tuner-1"
            }
        }
        assertTrue(released.isEmpty())

        gate.complete(Unit)
        runCurrent()
        assertEquals(listOf("tuner-1"), released)
    }

    @Test
    fun aValueInTimeIsReturnedAndNotReleased() = runTest {
        val released = mutableListOf<String>()

        val value = timeoutReleasingLate(1.seconds, "tune", backgroundScope, releaseLate = { released += it }) { "tuner-1" }
        runCurrent()

        assertEquals("tuner-1", value)
        assertTrue(released.isEmpty())
    }

    @Test
    fun aLateFailureIsDropped() = runTest {
        val released = mutableListOf<String>()
        val gate = CompletableDeferred<Unit>()

        assertFailsWith<OperationTimeoutException> {
            timeoutReleasingLate<String>(10.milliseconds, "tune", backgroundScope, releaseLate = { released += it }) {
                gate.await()
                throw IllegalStateException("late failure")
            }
        }
        gate.complete(Unit)
        runCurrent()

        assertTrue(released.isEmpty())
    }

    @Test
    fun aChildScopeFailsAloneAndIsCancelledWithItsParent() {
        val parentJob = Job()
        val parent = CoroutineScope(parentJob + Dispatchers.Unconfined + CoroutineExceptionHandler { _, _ -> })
        val child = parent.childScope()

        child.launch { throw IllegalStateException("boom") }
        assertTrue(parentJob.isActive)
        assertTrue(child.isActive)

        val running = child.launch { awaitCancellation() }
        parentJob.cancel()
        assertTrue(running.isCancelled)
        assertFalse(child.isActive)
    }
}

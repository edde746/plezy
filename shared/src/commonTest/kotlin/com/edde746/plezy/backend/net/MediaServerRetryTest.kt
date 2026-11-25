package com.edde746.plezy.backend.net

import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.async
import kotlinx.coroutines.delay
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.currentTime
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.days
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

@OptIn(ExperimentalCoroutinesApi::class)
class MediaServerRetryTest {
    private fun error(type: MediaServerHttpErrorType) = MediaServerHttpException(type, type.name)

    @Test
    fun runsTheCallOnceWithTheWholeDeadlineAsItsBudget() = runTest {
        val seenTimeouts = mutableListOf<Duration>()

        val result = retryTransientMediaServerCall("test operation", 20.seconds) { timeout ->
            seenTimeouts += timeout
            "ok"
        }

        assertEquals("ok", result)
        assertEquals(listOf(20.seconds), seenTimeouts)
    }

    // The regression this policy exists for: a slow-but-alive server surfaces as a connection timeout, and replaying
    // it made the server re-run the same query, turning an 11 s answer into an empty row after 23 s.
    @Test
    fun aTimeoutIsNeverReplayed() = runTest {
        var attempts = 0

        val failure = assertFailsWith<MediaServerHttpException> {
            retryTransientMediaServerCall<Unit>("test operation", 20.seconds) {
                attempts++
                throw error(MediaServerHttpErrorType.CONNECTION_TIMEOUT)
            }
        }

        assertEquals(MediaServerHttpErrorType.CONNECTION_TIMEOUT, failure.type)
        assertEquals(1, attempts)
    }

    @Test
    fun aSlowResponseLandingInsideTheDeadlineResolvesAndIsRequestedOnce() = runTest {
        var attempts = 0
        val result = async {
            retryTransientMediaServerCall("test operation", 20.seconds) {
                attempts++
                delay(11.seconds)
                "late but fine"
            }
        }

        advanceTimeBy(10.seconds + 900.milliseconds)
        runCurrent()
        assertFalse(result.isCompleted, "still in flight")
        assertEquals(1, attempts)

        advanceTimeBy(200.milliseconds)
        runCurrent()
        assertEquals("late but fine", result.await())
        assertEquals(1, attempts, "never replayed")
    }

    @Test
    fun anImmediateConnectionErrorIsRetried() = runTest {
        var attempts = 0

        val result = retryTransientMediaServerCall("test operation", 20.seconds) {
            attempts++
            delay(1.seconds)
            if (attempts < 3) throw error(MediaServerHttpErrorType.CONNECTION_ERROR)
            "ok"
        }

        assertEquals("ok", result)
        assertEquals(3, attempts)
        assertEquals(3_000L, currentTime)
    }

    @Test
    fun connectionErrorsStopAfterTwoRetries() = runTest {
        var attempts = 0

        val failure = assertFailsWith<MediaServerHttpException> {
            retryTransientMediaServerCall<Unit>("test operation", 20.seconds) {
                attempts++
                throw error(MediaServerHttpErrorType.CONNECTION_ERROR)
            }
        }

        assertEquals(MediaServerHttpErrorType.CONNECTION_ERROR, failure.type)
        assertEquals(3, attempts)
    }

    @Test
    fun givesUpAtTheDeadlineAndAbortsTheInFlightRequest() = runTest {
        var attempts = 0
        var aborted = false

        val failure = assertFailsWith<MediaServerHttpException> {
            retryTransientMediaServerCall<Unit>("test operation", 10.seconds) {
                attempts++
                try {
                    // Never answers: the request the deadline has to cut off.
                    delay(1.days)
                } catch (e: CancellationException) {
                    aborted = true
                    throw e
                }
            }
        }

        assertEquals(1, attempts, "a timeout is never replayed")
        assertEquals(10_000L, currentTime)
        assertTrue(aborted, "the in-flight request is torn down")
        assertEquals(MediaServerHttpErrorType.CONNECTION_TIMEOUT, failure.type)
        assertTrue("exceeded its 10s budget" in failure.message.orEmpty(), failure.message)
    }

    @Test
    fun totalWallTimeIsBoundedByTheDeadlineNotAttemptsTimesTimeout() = runTest {
        // Every attempt burns most of the budget before failing in a retryable way: a retry loop's worst case.
        assertFailsWith<MediaServerHttpException> {
            retryTransientMediaServerCall<Unit>("test operation", 15.seconds) {
                delay(6.seconds)
                throw error(MediaServerHttpErrorType.CONNECTION_ERROR)
            }
        }

        assertTrue(currentTime <= 15_000L, "settled at ${currentTime}ms")
    }

    @Test
    fun nonTransientFailuresAreNotRetried() = runTest {
        var attempts = 0

        val failure = assertFailsWith<MediaServerHttpException> {
            retryTransientMediaServerCall<Unit>("test operation", 20.seconds) {
                attempts++
                throw MediaServerHttpException(MediaServerHttpErrorType.UNKNOWN, "HTTP 404", statusCode = 404)
            }
        }

        assertEquals(404, failure.statusCode)
        assertEquals(1, attempts)
    }

    @Test
    fun aCancellationIsNotSwallowedAsARetryableFailure() = runTest {
        var attempts = 0

        val failure = assertFailsWith<MediaServerHttpException> {
            retryTransientMediaServerCall<Unit>("test operation", 20.seconds) {
                attempts++
                throw error(MediaServerHttpErrorType.CANCELLED)
            }
        }

        assertTrue(failure.isCancellation)
        assertEquals(1, attempts)
    }

    @Test
    fun aDeadlineThatIsNotPositiveIsRejected() = runTest {
        assertFailsWith<IllegalArgumentException> { retryTransientMediaServerCall("test operation", Duration.ZERO) { "never" } }
    }
}

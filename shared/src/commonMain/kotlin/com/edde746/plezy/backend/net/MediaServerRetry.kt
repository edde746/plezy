package com.edde746.plezy.backend.net

import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.log.Log
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.withTimeout
import kotlin.time.Duration

/**
 * Runs [call] within one [deadline] for every attempt together, retrying it after a connection error up to
 * [maxConnectionRetries] times; each attempt gets the whole [deadline] as its own request timeout. Running out of time
 * throws a connection-timeout [MediaServerHttpException] naming [operation]'s budget; other failures rethrow at once.
 */
suspend fun <T> retryTransientMediaServerCall(
    operation: String,
    deadline: Duration,
    maxConnectionRetries: Int = 2,
    call: suspend (timeout: Duration) -> T,
): T {
    require(deadline.isPositive()) { "deadline must be positive" }
    try {
        return withTimeout(deadline) {
            var attempt = 0
            while (true) {
                try {
                    return@withTimeout call(deadline)
                } catch (e: MediaServerHttpException) {
                    if (e.type != MediaServerHttpErrorType.CONNECTION_ERROR || attempt >= maxConnectionRetries) throw e
                    attempt++
                    Log.w(TAG) { "Retrying $operation after a connection error (attempt $attempt of ${maxConnectionRetries + 1})" }
                }
            }
            @Suppress("UNREACHABLE_CODE")
            error("unreachable")
        }
    } catch (e: TimeoutCancellationException) {
        throw MediaServerHttpException(
            MediaServerHttpErrorType.CONNECTION_TIMEOUT,
            "$operation exceeded its ${deadline.inWholeSeconds}s budget",
            cause = e,
        )
    }
}

private const val TAG = "MediaServerRetry"

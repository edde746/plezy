package com.edde746.plezy.servers

import com.edde746.plezy.log.Log
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.async
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.time.Duration

/** A scope that inherits this one's context and is cancelled with it, but whose failing children leave this one running. */
fun CoroutineScope.childScope(): CoroutineScope = CoroutineScope(coroutineContext + SupervisorJob(coroutineContext[Job]))

private const val TAG = "Concurrency"

/**
 * [operation] ran past its [timeLimit]. An ordinary failure, not a cancellation: callers catch it like any other
 * error, and the message names the call for crash reports.
 */
class OperationTimeoutException(val operation: String, val timeLimit: Duration) : Exception("$operation timed out")

// Distinguishes a block that returned null from a timeout.
private class Settled<T>(val value: T)

/** [block]'s result, or [OperationTimeoutException] naming [operation] once [timeLimit] passes (the block is cancelled). */
suspend fun <T> namedTimeout(timeLimit: Duration, operation: String, block: suspend () -> T): T =
    (withTimeoutOrNull(timeLimit) { Settled(block()) } ?: throw OperationTimeoutException(operation, timeLimit)).value

/**
 * Like [namedTimeout], but the work runs on in [scope] when the caller stops waiting (at [timeLimit], or because the
 * caller was cancelled): a value that still arrives is handed to [releaseLate]. For work whose success allocates
 * something only the result can name (a connected client, a tuner a live tune opened), which would otherwise belong to
 * nobody. Late failures, [releaseLate]'s included, are logged at debug and dropped.
 */
suspend fun <T> timeoutReleasingLate(
    timeLimit: Duration,
    operation: String,
    scope: CoroutineScope,
    releaseLate: suspend (T) -> Unit,
    block: suspend () -> T,
): T {
    // Own supervisor: the work's failure reaches the caller through await, never the scope's other children.
    val supervisor = SupervisorJob(scope.coroutineContext[Job])
    val work = scope.async(supervisor) { block() }
    supervisor.complete()
    val settled = try {
        withTimeoutOrNull(timeLimit) { Settled(work.await()) }
    } catch (e: CancellationException) {
        releaseWhenDone(work, operation, scope, releaseLate)
        throw e
    }
    if (settled != null) return settled.value
    releaseWhenDone(work, operation, scope, releaseLate)
    throw OperationTimeoutException(operation, timeLimit)
}

private fun <T> releaseWhenDone(work: Deferred<T>, operation: String, scope: CoroutineScope, releaseLate: suspend (T) -> Unit) {
    scope.launch {
        try {
            releaseLate(work.await())
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.d(TAG, e) { "$operation finished after its caller stopped waiting" }
        }
    }
}

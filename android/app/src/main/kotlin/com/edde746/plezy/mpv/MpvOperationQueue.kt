package com.edde746.plezy.mpv

import java.util.concurrent.CancellationException
import java.util.concurrent.atomic.AtomicBoolean
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

internal class MpvOperationTimeout(operation: String) : Exception("MPV $operation did not respond")

/**
 * Serializes whole operations, including their suspensions. The waiter and deadline
 * do not belong to the worker: canceling a JNI call cannot interrupt native code.
 * Failure closes admission and answers every waiter while the worker retains its
 * resources until the admitted call actually returns.
 *
 * The deadline measures the admitted call, not the wait for one. It starts when the
 * worker picks the operation up, so a backlog behind a slow core can never be
 * mistaken for a native call that never returned.
 *
 * [timeoutIsFatal] decides what an expiry means. A write that never returns leaves
 * mpv's state unknown, so that queue condemns the session and quarantines it. A read
 * blocking on a saturated core is not a wedge - `mpv_get_property` waits on the core
 * thread, and a core decoding 4K in software can legitimately hold one for seconds -
 * so that queue expires the single operation and stays open. Reads going quiet costs
 * a stats panel; killing the session costs the viewer their playback.
 */
internal class MpvOperationQueue(
  private val timeoutMs: Long = 6_000L,
  private val timeoutIsFatal: Boolean = true,
  private val onTimeout: (Exception) -> Unit = {}
) {
  private class Operation<T>(val name: String, val block: suspend CoroutineScope.() -> T) {
    val result = CompletableDeferred<T>()
    val job = Job()
    var deadline: Job? = null
    private val completionClaimed = AtomicBoolean()

    fun claimCompletion(): Boolean = completionClaimed.compareAndSet(false, true)

    suspend fun execute(armDeadline: (Operation<T>) -> Job) {
      deadline = armDeadline(this)
      try {
        val value = withContext(job) { block(this) }
        if (claimCompletion()) result.complete(value)
      } catch (error: Throwable) {
        // Errors settle the waiter too. An UnsatisfiedLinkError or OOM out of a
        // JNI call would otherwise escape the worker loop, whose `finally`
        // cancels the deadline scope on the way out: this caller and every
        // later one would park with no deadline left to answer them.
        if (claimCompletion()) result.completeExceptionally(error)
      } finally {
        deadline?.cancel()
        job.complete()
      }
    }

    fun fail(error: Exception) {
      if (claimCompletion()) publishFailure(error)
    }

    fun publishFailure(error: Exception) {
      result.completeExceptionally(error)
      job.cancel()
      deadline?.cancel()
    }
  }

  private val lock = Any()
  private val workerScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
  private val deadlineScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
  private val queue = Channel<Operation<*>>(Channel.UNLIMITED)
  private val pending = mutableSetOf<Operation<*>>()
  private var failure: Exception? = null

  init {
    workerScope.launch {
      try {
        for (operation in queue) {
          val admitted = synchronized(lock) { failure == null && !operation.result.isCompleted }
          if (admitted) operation.execute(::armDeadline)
          synchronized(lock) { pending.remove(operation) }
        }
      } finally {
        workerScope.cancel()
        deadlineScope.cancel()
      }
    }
  }

  suspend fun <T> run(name: String, block: suspend CoroutineScope.() -> T): T {
    val operation = Operation(name, block)
    synchronized(lock) {
      failure?.let { throw it }
      pending += operation
      check(queue.trySend(operation).isSuccess)
    }
    try {
      return operation.result.await()
    } catch (error: CancellationException) {
      operation.fail(error)
      throw error
    }
  }

  fun close(error: Exception = CancellationException("MPV core unavailable")) {
    fail(error)
  }

  private fun <T> armDeadline(operation: Operation<T>): Job = deadlineScope.launch {
    delay(timeoutMs)
    val error = MpvOperationTimeout(operation.name)
    if (timeoutIsFatal) fail(error, operation) else expire(operation, error)
  }

  /**
   * Answer one overdue caller and keep serving. The worker is still inside the
   * JNI call; cancelling [Operation.job] only takes effect once it returns, and
   * the claim it already lost stops it double-settling the waiter.
   */
  private fun <T> expire(operation: Operation<T>, error: Exception) {
    if (!operation.claimCompletion()) return
    synchronized(lock) { pending.remove(operation) }
    operation.publishFailure(error)
  }

  private fun fail(error: Exception, expired: Operation<*>? = null): Boolean {
    val abandoned = synchronized(lock) {
      if (failure != null || (expired != null && !expired.claimCompletion())) return false
      failure = error
      queue.close()
      pending.filter { it === expired || it.claimCompletion() }.also { pending.clear() }
    }
    // Quarantine before publishing timeout replies: a caller can immediately
    // dispose and initialize a successor after its reply is settled.
    if (expired != null) onTimeout(error)
    abandoned.forEach { it.publishFailure(error) }
    deadlineScope.cancel()
    return true
  }
}

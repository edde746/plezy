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
 */
internal class MpvOperationQueue(
  private val timeoutMs: Long = 6_000L,
  private val onTimeout: (Exception) -> Unit = {}
) {
  private class Operation<T>(val name: String, val block: suspend CoroutineScope.() -> T) {
    val result = CompletableDeferred<T>()
    val job = Job()
    var deadline: Job? = null
    private val completionClaimed = AtomicBoolean()

    fun claimCompletion(): Boolean = completionClaimed.compareAndSet(false, true)

    suspend fun execute() {
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
          if (admitted) operation.execute()
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
      operation.deadline = deadlineScope.launch {
        delay(timeoutMs)
        val error = MpvOperationTimeout(name)
        fail(error, operation)
      }
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

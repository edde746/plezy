package com.edde746.plezy.mpv

import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class MpvOperationQueueTest {
  @Test
  fun suspendingTransactionFinishesBeforeTheNextOperationStarts() = runBlocking {
    val queue = MpvOperationQueue()
    val entered = CompletableDeferred<Unit>()
    val release = CompletableDeferred<Unit>()
    val writes = mutableListOf<String>()
    try {
      withTimeout(3_000) {
        val first = async(start = CoroutineStart.UNDISPATCHED) {
          queue.run("first") {
            writes += "first property"
            entered.complete(Unit)
            release.await()
            withContext(Dispatchers.IO) { writes += "second property" }
          }
        }
        entered.await()
        val second = async(start = CoroutineStart.UNDISPATCHED) {
          queue.run("second") { writes += "command" }
        }
        assertFalse(second.isCompleted)
        release.complete(Unit)
        first.await()
        second.await()
        assertEquals(listOf("first property", "second property", "command"), writes)
      }
    } finally {
      release.complete(Unit)
      queue.close()
    }
  }

  @Test
  fun blockedNativeCallFailsWaitersAndClosesAdmissionWithoutReleasingItsResources() = runBlocking {
    val nativeEntered = CompletableDeferred<Unit>()
    val nativeRelease = CountDownLatch(1)
    val nativeReturned = CountDownLatch(1)
    val poisoned = CompletableDeferred<Unit>()
    val calls = AtomicInteger()
    val queue = MpvOperationQueue(timeoutMs = 100, onTimeout = { poisoned.complete(Unit) })
    try {
      withTimeout(3_000) {
        val first = async(start = CoroutineStart.UNDISPATCHED) {
          runCatching {
            queue.run("blocked native call") {
              calls.incrementAndGet()
              nativeEntered.complete(Unit)
              try {
                nativeRelease.await()
                "late success"
              } finally {
                nativeReturned.countDown()
              }
            }
          }
        }
        nativeEntered.await()
        val second = async(start = CoroutineStart.UNDISPATCHED) {
          runCatching { queue.run("queued command") { calls.incrementAndGet() } }
        }
        assertTrue(first.await().exceptionOrNull() is MpvOperationTimeout)
        assertTrue(second.await().exceptionOrNull() is MpvOperationTimeout)
        poisoned.await()
        assertEquals(1L, nativeReturned.count)
        assertTrue(runCatching { queue.run("rejected command") { calls.incrementAndGet() } }.isFailure)
        assertEquals(1, calls.get())
        nativeRelease.countDown()
        assertTrue(withContext(Dispatchers.IO) { nativeReturned.await(2, TimeUnit.SECONDS) })
        assertTrue(first.await().exceptionOrNull() is MpvOperationTimeout)
      }
    } finally {
      nativeRelease.countDown()
      queue.close()
    }
  }

  @Test
  fun timeoutQuarantinesBeforeTheCallerCanStartAReplacement() = runBlocking {
    val entered = CompletableDeferred<Unit>()
    val quarantineEntered = CompletableDeferred<Unit>()
    val quarantineRelease = CountDownLatch(1)
    val nativeRelease = CountDownLatch(1)
    val queue = MpvOperationQueue(timeoutMs = 100, onTimeout = {
      quarantineEntered.complete(Unit)
      quarantineRelease.await()
    })
    try {
      withTimeout(3_000) {
        val result = async(start = CoroutineStart.UNDISPATCHED) {
          runCatching {
            queue.run("native call") {
              entered.complete(Unit)
              nativeRelease.await()
            }
          }
        }
        entered.await()
        quarantineEntered.await()
        assertFalse(result.isCompleted)
        assertTrue(runCatching { queue.run("new work") { error("Must not run") } }.isFailure)
        quarantineRelease.countDown()
        assertTrue(result.await().exceptionOrNull() is MpvOperationTimeout)
        assertEquals(1L, nativeRelease.count)
      }
    } finally {
      quarantineRelease.countDown()
      nativeRelease.countDown()
      queue.close()
    }
  }

  @Test
  fun disposalSettlesTheCallerWhileNativeRetirementIsStillPending() = runBlocking {
    val queue = MpvOperationQueue()
    val entered = CompletableDeferred<Unit>()
    val release = CountDownLatch(1)
    try {
      withTimeout(3_000) {
        val result = async(start = CoroutineStart.UNDISPATCHED) {
          runCatching {
            queue.run("native call") {
              entered.complete(Unit)
              release.await()
            }
          }
        }
        entered.await()
        queue.close()
        assertTrue(result.await().isFailure)
        assertEquals(1L, release.count)
      }
    } finally {
      release.countDown()
      queue.close()
    }
  }

  /**
   * `System.loadLibrary` failures and OOM arrive as [Error]. They must settle
   * their own caller and leave the queue usable: escaping the worker loop
   * cancels the deadline scope, so every later caller would park unanswered.
   */
  @Test
  fun anErrorSettlesItsCallerAndLeavesTheQueueUsable() = runBlocking {
    val queue = MpvOperationQueue()
    try {
      withTimeout(3_000) {
        val failed = runCatching {
          queue.run<Unit>("native init") { throw UnsatisfiedLinkError("no mpv in java.library.path") }
        }
        assertTrue(failed.exceptionOrNull() is UnsatisfiedLinkError)
        assertEquals("still serving", queue.run("later property") { "still serving" })
      }
    } finally {
      queue.close()
    }
  }
}

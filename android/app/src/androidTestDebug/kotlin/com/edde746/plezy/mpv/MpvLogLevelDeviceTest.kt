package com.edde746.plezy.mpv

import android.app.Instrumentation
import android.os.SystemClock
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.edde746.plezy.shared.PlayerDelegate
import java.io.File
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class MpvLogLevelDeviceTest {
  @Test
  fun normalLoggingPreservesErrorsAndCanToggleVerboseOffAgain() = withCore { instrumentation, core, logs ->
    assertLogPhase(instrumentation, core, logs, "normal", expectInfo = false)
    setLogLevel(instrumentation, core, "v")
    assertLogPhase(instrumentation, core, logs, "verbose", expectInfo = true)
    setLogLevel(instrumentation, core, "warn")
    assertLogPhase(instrumentation, core, logs, "normal-again", expectInfo = false)
  }

  @Test
  fun verboseLoggingCanBeSelectedBeforeNativeInitialization() = withCore(initialLogLevel = "v") { instrumentation, core, logs ->
    assertLogPhase(instrumentation, core, logs, "initial-verbose", expectInfo = true)
  }

  @Test
  fun rejectedInitialLogLevelDoesNotBlockTheNextPlayer() {
    withCore(initialLogLevel = "not-a-level", initializationSucceeds = false) { _, _, _ -> }
    withCore { instrumentation, core, logs ->
      assertLogPhase(instrumentation, core, logs, "after-rejected-init", expectInfo = false)
    }
  }

  private fun withCore(
    initialLogLevel: String = "warn",
    initializationSucceeds: Boolean = true,
    block: (Instrumentation, MpvPlayerCore, LinkedBlockingQueue<Pair<String, String>>) -> Unit
  ) {
    val instrumentation = InstrumentationRegistry.getInstrumentation()
    val logs = LinkedBlockingQueue<Pair<String, String>>()
    val initialized = CountDownLatch(1)
    val success = AtomicReference<Boolean>()
    val core = AtomicReference<MpvPlayerCore>()
    instrumentation.runOnMainSync {
      core.set(MpvPlayerCore(instrumentation.targetContext, audioOnly = true, initialLogLevel = initialLogLevel))
      core.get().delegate = object : PlayerDelegate {
        override fun onPropertyChange(name: String, value: Any?) = Unit

        override fun onEvent(name: String, data: Map<String, Any>?) {
          if (name == "log-message") {
            logs.add((data?.get("level") as? String ?: "") to (data?.get("text") as? String ?: ""))
          }
        }
      }
      core.get().initialize {
        success.set(it)
        initialized.countDown()
      }
    }
    try {
      assertCompletes(initialized, "initialization")
      assertEquals("Native MPV initialization result", initializationSucceeds, success.get())
      block(instrumentation, core.get(), logs)
    } finally {
      val disposed = CountDownLatch(1)
      instrumentation.runOnMainSync { core.get().dispose(disposed::countDown) }
      assertCompletes(disposed, "teardown")
    }
  }

  private fun setLogLevel(instrumentation: Instrumentation, core: MpvPlayerCore, level: String) {
    val completed = CountDownLatch(1)
    val result = AtomicReference<Result<Unit>>()
    instrumentation.runOnMainSync {
      core.setLogLevel(level) {
        result.set(it)
        completed.countDown()
      }
    }
    assertCompletes(completed, "setLogLevel($level)")
    result.get().getOrThrow()
  }

  private fun command(instrumentation: Instrumentation, core: MpvPlayerCore, vararg args: String) {
    val completed = CountDownLatch(1)
    val success = AtomicReference<Boolean>()
    instrumentation.runOnMainSync {
      core.command(arrayOf(*args)) {
        success.set(it)
        completed.countDown()
      }
    }
    assertCompletes(completed, args.first())
    assertTrue("MPV command failed: ${args.first()}", success.get())
  }

  private fun assertLogPhase(
    instrumentation: Instrumentation,
    core: MpvPlayerCore,
    logs: LinkedBlockingQueue<Pair<String, String>>,
    phase: String,
    expectInfo: Boolean
  ) {
    val token = "mpv-log-$phase-${UUID.randomUUID()}"
    val infoMarker = "$token-info"
    val errorMarker = "$token-missing"
    val missingFile = File(instrumentation.targetContext.cacheDir, errorMarker)
    command(instrumentation, core, "print-text", infoMarker)
    command(instrumentation, core, "loadfile", missingFile.absolutePath, "replace")

    // The failed open is an error-level barrier in the same ordered log stream.
    // Seeing it proves the preceding informational message was either delivered
    // or filtered; no sleep is needed to assert that a quiet log stayed quiet.
    val deadline = SystemClock.elapsedRealtime() + TimeUnit.SECONDS.toMillis(TIMEOUT_SECONDS)
    var sawInfo = false
    while (true) {
      val remaining = deadline - SystemClock.elapsedRealtime()
      assertTrue("Missing native error log in $phase", remaining > 0)
      val log = logs.poll(remaining, TimeUnit.MILLISECONDS)
      assertTrue("Missing native error log in $phase", log != null)
      if (log!!.second.contains(infoMarker)) {
        assertEquals("info", log.first)
        sawInfo = true
      }
      if (log.first == "error" && log.second.contains(errorMarker)) break
    }
    assertEquals("Informational log visibility in $phase", expectInfo, sawInfo)
  }

  private fun assertCompletes(latch: CountDownLatch, operation: String) {
    assertTrue("Timed out during $operation", latch.await(TIMEOUT_SECONDS, TimeUnit.SECONDS))
  }

  private companion object {
    const val TIMEOUT_SECONDS = 15L
  }
}

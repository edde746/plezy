package com.edde746.plezy.mpv

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.edde746.plezy.shared.PlayerDelegate
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Exercises MPV's JNI reachability against the production-shrunk app with
 * `-Pplezy.testBuildType=minified`. Native initialization resolves all nine static
 * callback descriptors, so a stale or missing keep fails before initialization completes.
 *
 * Only calls the core APIs used by production. Referencing MpvPlayer's callbacks
 * directly here would let the harness mask missing retention in the app APK.
 */
@RunWith(AndroidJUnit4::class)
class MpvPlayerReachabilityTest {
  @Test
  fun productionCoreInitializesDeliversNativeLogAndDisposes() {
    val instrumentation = InstrumentationRegistry.getInstrumentation()
    val core = AtomicReference<MpvPlayerCore>()
    val initialized = CountDownLatch(1)
    val initializationSucceeded = AtomicBoolean()
    val commandCompleted = CountDownLatch(1)
    val commandSucceeded = AtomicBoolean()
    val nativeLogReceived = CountDownLatch(1)

    instrumentation.runOnMainSync {
      // Pass every constructor argument: production uses this constructor, not
      // the default-argument bridge that R8 may legitimately remove.
      core.set(MpvPlayerCore(instrumentation.targetContext, true, true, 1f, "v"))
      core.get().delegate = object : PlayerDelegate {
        override fun onPropertyChange(name: String, value: Any?) = Unit

        override fun onEvent(name: String, data: Map<String, Any>?) {
          if (name == "log-message" && data?.get("level") == "info" && data["text"] == LOG_MARKER) {
            nativeLogReceived.countDown()
          }
        }
      }
    }
    try {
      instrumentation.runOnMainSync {
        core.get().initialize {
          initializationSucceeded.set(it)
          initialized.countDown()
        }
      }
      assertCompletes(initialized, "initialization")
      assertTrue("Native MPV initialization failed", initializationSucceeded.get())

      // initialize completes after the production flow collectors subscribe.
      // This marker must cross the real native event thread and reach the delegate.
      instrumentation.runOnMainSync {
        core.get().command(arrayOf("print-text", LOG_MARKER)) {
          commandSucceeded.set(it)
          commandCompleted.countDown()
        }
      }
      assertCompletes(commandCompleted, "print-text")
      assertTrue("Native MPV print-text failed", commandSucceeded.get())
      assertCompletes(nativeLogReceived, "native log callback")
    } finally {
      val disposed = CountDownLatch(1)
      instrumentation.runOnMainSync { core.get().dispose(disposed::countDown) }
      assertCompletes(disposed, "native teardown")
    }
  }

  private fun assertCompletes(latch: CountDownLatch, operation: String) {
    assertTrue("Timed out during $operation", latch.await(TIMEOUT_SECONDS, TimeUnit.SECONDS))
  }

  private companion object {
    const val TIMEOUT_SECONDS = 15L
    const val LOG_MARKER = "plezy-mpv-r8-native-log"
  }
}

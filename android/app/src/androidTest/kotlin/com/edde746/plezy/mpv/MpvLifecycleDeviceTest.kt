package com.edde746.plezy.mpv

import android.app.Instrumentation
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.ViewGroup
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.edde746.plezy.shared.PlayerDelegate
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class MpvLifecycleDeviceTest {
  @Test
  fun repeatedMediaCodecPlaybackCompletesTerminalTeardown() {
    val instrumentation = InstrumentationRegistry.getInstrumentation()
    val fixtureBytes = instrumentation.context.assets.open("ffmpeg/mediacodec_teardown.mp4").use { it.readBytes() }
    val fixture = copyFixture(fixtureBytes, instrumentation.targetContext.cacheDir)

    val activity = instrumentation.startActivitySync(
      Intent(instrumentation.targetContext, MpvLifecycleTestActivity::class.java)
        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    ) as MpvLifecycleTestActivity
    instrumentation.waitForIdleSync()
    try {
      repeat(CYCLE_COUNT) { cycle ->
        runPlaybackCycle(instrumentation, activity, fixture, cycle)
      }
    } finally {
      instrumentation.runOnMainSync(activity::finish)
      instrumentation.waitForIdleSync()
      fixture.delete()
    }
  }

  private fun runPlaybackCycle(
    instrumentation: Instrumentation,
    activity: MpvLifecycleTestActivity,
    fixture: File,
    cycle: Int
  ) {
    val initialized = CountDownLatch(1)
    val initializationResult = AtomicReference<Boolean>()
    val events = RecordingDelegate()
    val core = AtomicReference<MpvPlayerCore>()

    instrumentation.runOnMainSync {
      core.set(
        MpvPlayerCore(activity, hardwareDecoding = true).also { playerCore ->
          playerCore.delegate = events
          playerCore.initialize { success ->
            initializationResult.set(success)
            initialized.countDown()
          }
        }
      )
    }

    assertCompletes(initialized, "MPV initialization", cycle)
    assertTrue("MPV initialization failed in cycle $cycle", initializationResult.get())
    setProperty(instrumentation, core.get(), "hwdec", "mediacodec", cycle)
    setProperty(instrumentation, core.get(), "aid", "no", cycle)

    val commandCompleted = CountDownLatch(1)
    val commandResult = AtomicReference<Boolean>()
    instrumentation.runOnMainSync {
      core.get().command(arrayOf("loadfile", fixture.absolutePath, "replace")) { success ->
        commandResult.set(success)
        commandCompleted.countDown()
      }
    }
    assertCompletes(commandCompleted, "loadfile command", cycle)
    assertTrue("loadfile command failed in cycle $cycle", commandResult.get())
    assertCompletes(events.fileLoaded, "file-loaded event", cycle)
    assertCompletes(events.playbackRestart, "playback-restart event", cycle)

    assertEquals("mediacodec", core.get().getProperty("current-vo"))
    assertTrue(
      "Expected MediaCodec hardware decoding in cycle $cycle",
      core.get().getProperty("hwdec-current")?.startsWith("mediacodec") == true
    )

    val disposed = CountDownLatch(1)
    val nextMainTurn = CountDownLatch(1)
    val disposeElapsedMs = AtomicReference<Long>()
    val synchronousDisposeElapsedMs = AtomicReference<Long>()
    val disposeStartedAt = SystemClock.elapsedRealtime()
    instrumentation.runOnMainSync {
      val synchronousDisposeStartedAt = SystemClock.elapsedRealtime()
      core.get().dispose {
        disposeElapsedMs.set(SystemClock.elapsedRealtime() - disposeStartedAt)
        disposed.countDown()
      }
      Handler(Looper.getMainLooper()).post(nextMainTurn::countDown)
      synchronousDisposeElapsedMs.set(SystemClock.elapsedRealtime() - synchronousDisposeStartedAt)
    }
    assertTrue(
      "dispose() blocked the main thread for ${synchronousDisposeElapsedMs.get()}ms in cycle $cycle",
      synchronousDisposeElapsedMs.get() <= MAX_SYNCHRONOUS_DISPOSE_MS
    )
    assertCompletes(nextMainTurn, "main-looper turn after dispose", cycle, MAIN_LOOP_TIMEOUT_SECONDS)
    assertCompletes(disposed, "terminal teardown", cycle, DISPOSE_TIMEOUT_SECONDS)
    assertTrue(
      "Terminal teardown took ${disposeElapsedMs.get()}ms in cycle $cycle",
      disposeElapsedMs.get() <= MAX_DISPOSE_LATENCY_MS
    )
    instrumentation.runOnMainSync {
      val content = activity.findViewById<ViewGroup>(android.R.id.content)
      assertEquals("Player surface container leaked in cycle $cycle", 1, content.childCount)
    }
  }

  private fun setProperty(
    instrumentation: Instrumentation,
    core: MpvPlayerCore,
    name: String,
    value: String,
    cycle: Int
  ) {
    val completed = CountDownLatch(1)
    val result = AtomicReference<Result<Unit>>()
    instrumentation.runOnMainSync {
      core.setProperty(name, value) { outcome ->
        result.set(outcome)
        completed.countDown()
      }
    }
    assertCompletes(completed, "$name property write", cycle)
    assertTrue("$name property write failed in cycle $cycle", result.get().isSuccess)
  }

  private fun assertCompletes(
    latch: CountDownLatch,
    operation: String,
    cycle: Int,
    timeoutSeconds: Long = OPERATION_TIMEOUT_SECONDS
  ) {
    assertTrue(
      "$operation timed out in cycle $cycle after ${timeoutSeconds}s",
      latch.await(timeoutSeconds, TimeUnit.SECONDS)
    )
  }

  private fun copyFixture(bytes: ByteArray, cacheDir: File): File = File.createTempFile("mpv-lifecycle-", ".mp4", cacheDir).apply { writeBytes(bytes) }

  private class RecordingDelegate : PlayerDelegate {
    val fileLoaded = CountDownLatch(1)
    val playbackRestart = CountDownLatch(1)

    override fun onPropertyChange(name: String, value: Any?) = Unit

    override fun onEvent(name: String, data: Map<String, Any>?) {
      when (name) {
        "file-loaded" -> fileLoaded.countDown()
        "playback-restart" -> playbackRestart.countDown()
      }
    }
  }

  private companion object {
    const val CYCLE_COUNT = 8
    const val OPERATION_TIMEOUT_SECONDS = 10L
    const val DISPOSE_TIMEOUT_SECONDS = 15L
    const val MAIN_LOOP_TIMEOUT_SECONDS = 1L
    const val MAX_SYNCHRONOUS_DISPOSE_MS = 500L
    const val MAX_DISPOSE_LATENCY_MS = 2_000L
  }
}

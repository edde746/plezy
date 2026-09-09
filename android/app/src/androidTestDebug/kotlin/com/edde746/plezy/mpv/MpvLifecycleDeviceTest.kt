package com.edde746.plezy.mpv

import android.app.Instrumentation
import android.content.Intent
import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import android.view.ViewGroup
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.edde746.plezy.shared.PlayerDelegate
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class MpvLifecycleDeviceTest {
  @Test
  fun repeatedMediaCodecPlaybackCompletesTerminalTeardown() = runPlaybackTest(recreateSurfaces = false)

  @Test
  fun pausedMediaCodecPlaybackSurvivesRepeatedSurfaceRecreation() = runPlaybackTest(recreateSurfaces = true)

  @Test
  fun pausedGpuPlaybackSurvivesRepeatedSurfaceRecreation() = runPlaybackTest(recreateSurfaces = true, hardwareDecoding = false)

  @Test
  fun placeholderConsumesFramesWithoutBlockingProducer() {
    val placeholder = runBlocking { MpvPlaceholderSurface.create() }
    val completed = CountDownLatch(1)
    val failure = AtomicReference<Throwable?>()
    val producer = Thread {
      try {
        // More than a BufferQueue can retain without an active consumer.
        repeat(16) {
          val canvas = placeholder.surface.lockCanvas(null)
          canvas.drawColor(Color.BLACK)
          placeholder.surface.unlockCanvasAndPost(canvas)
        }
      } catch (error: Throwable) {
        failure.set(error)
      } finally {
        completed.countDown()
      }
    }.apply { isDaemon = true }
    try {
      producer.start()
      assertCompletes(completed, "placeholder buffer consumption", 0)
      failure.get()?.let { throw AssertionError("Placeholder producer failed", it) }
    } finally {
      placeholder.close()
      producer.join(2_000)
      assertTrue("Placeholder producer survived cleanup", !producer.isAlive)
    }
  }

  private fun runPlaybackTest(recreateSurfaces: Boolean, hardwareDecoding: Boolean = true) {
    val instrumentation = InstrumentationRegistry.getInstrumentation()
    val fixtureBytes = instrumentation.context.assets.open("ffmpeg/mediacodec_teardown.mp4").use { it.readBytes() }
    val fixture = copyFixture(fixtureBytes, instrumentation.targetContext.cacheDir)

    try {
      val activity = instrumentation.startActivitySync(
        Intent(instrumentation.targetContext, MpvLifecycleTestActivity::class.java)
          .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
      ) as MpvLifecycleTestActivity
      try {
        instrumentation.waitForIdleSync()
        repeat(CYCLE_COUNT) { cycle ->
          runPlaybackCycle(instrumentation, activity, fixture, cycle, recreateSurfaces, hardwareDecoding)
        }
      } finally {
        instrumentation.runOnMainSync(activity::finish)
        instrumentation.waitForIdleSync()
      }
    } finally {
      fixture.delete()
    }
  }

  private fun runPlaybackCycle(
    instrumentation: Instrumentation,
    activity: MpvLifecycleTestActivity,
    fixture: File,
    cycle: Int,
    recreateSurfaces: Boolean,
    hardwareDecoding: Boolean
  ) {
    val initialized = CountDownLatch(1)
    val initializationResult = AtomicReference<Boolean>()
    val events = RecordingDelegate()
    val core = AtomicReference<MpvPlayerCore>()

    instrumentation.runOnMainSync {
      core.set(
        MpvPlayerCore(activity, hardwareDecoding = hardwareDecoding).also { playerCore ->
          playerCore.delegate = events
          playerCore.initialize { success ->
            initializationResult.set(success)
            initialized.countDown()
          }
        }
      )
    }

    try {
      assertCompletes(initialized, "MPV initialization", cycle)
      assertTrue("MPV initialization failed in cycle $cycle", initializationResult.get())
      setProperty(instrumentation, core.get(), "hwdec", if (hardwareDecoding) "mediacodec" else "no", cycle)
      setProperty(instrumentation, core.get(), "aid", "no", cycle)
      if (recreateSurfaces) setProperty(instrumentation, core.get(), "loop-file", "inf", cycle)

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

      assertVideoOutput(core.get(), cycle, hardwareDecoding)
      if (recreateSurfaces) exerciseSurfaceRecreation(instrumentation, activity, core.get(), cycle, hardwareDecoding)
    } finally {
      disposeCore(instrumentation, activity, core.get(), cycle)
    }
  }

  private fun disposeCore(
    instrumentation: Instrumentation,
    activity: MpvLifecycleTestActivity,
    core: MpvPlayerCore,
    cycle: Int
  ) {
    val disposed = CountDownLatch(1)
    val nextMainTurn = CountDownLatch(1)
    val disposeElapsedMs = AtomicReference<Long>()
    val synchronousDisposeElapsedMs = AtomicReference<Long>()
    val disposeStartedAt = SystemClock.elapsedRealtime()
    instrumentation.runOnMainSync {
      val synchronousDisposeStartedAt = SystemClock.elapsedRealtime()
      core.dispose {
        disposeElapsedMs.set(SystemClock.elapsedRealtime() - disposeStartedAt)
        disposed.countDown()
      }
      Handler(Looper.getMainLooper()).post(nextMainTurn::countDown)
      synchronousDisposeElapsedMs.set(SystemClock.elapsedRealtime() - synchronousDisposeStartedAt)
    }
    try {
      assertTrue(
        "dispose() blocked the main thread for ${synchronousDisposeElapsedMs.get()}ms in cycle $cycle",
        synchronousDisposeElapsedMs.get() <= MAX_SYNCHRONOUS_DISPOSE_MS
      )
      assertCompletes(nextMainTurn, "main-looper turn after dispose", cycle, MAIN_LOOP_TIMEOUT_SECONDS)
    } finally {
      assertCompletes(disposed, "terminal teardown", cycle, DISPOSE_TIMEOUT_SECONDS)
    }
    assertTrue(
      "Terminal teardown took ${disposeElapsedMs.get()}ms in cycle $cycle",
      disposeElapsedMs.get() <= MAX_DISPOSE_LATENCY_MS
    )
    instrumentation.runOnMainSync {
      val content = activity.findViewById<ViewGroup>(android.R.id.content)
      assertEquals("Player surface container leaked in cycle $cycle", 1, content.childCount)
    }
  }

  private fun exerciseSurfaceRecreation(
    instrumentation: Instrumentation,
    activity: MpvLifecycleTestActivity,
    core: MpvPlayerCore,
    cycle: Int,
    hardwareDecoding: Boolean
  ) {
    val surfaces = mutableListOf<SurfaceView>()
    instrumentation.runOnMainSync {
      val content = activity.findViewById<ViewGroup>(android.R.id.content)
      val container = content.getChildAt(0) as ViewGroup
      // The host's SurfaceViews are the video plane and, with hardware
      // decoding, the OSD plane.
      for (index in 0 until container.childCount) {
        (container.getChildAt(index) as? SurfaceView)?.let(surfaces::add)
      }
    }
    assertEquals("Expected video and optional OSD surfaces", if (hardwareDecoding) 2 else 1, surfaces.size)

    // Separate visibility changes and callback latches guarantee both real
    // destruction/creation orders, including video returning before the OSD.
    val orders = if (hardwareDecoding) listOf(surfaces, surfaces.reversed()) else listOf(surfaces)
    for (order in orders) {
      setProperty(instrumentation, core, "pause", "yes", cycle)
      awaitProperty(core, "pause", "public pause", cycle) { it == "yes" }
      for (surface in order) {
        changeSurfaceVisibility(instrumentation, surface, visible = false, cycle = cycle)
        assertEquals("Surface loss cleared public pause in cycle $cycle", "yes", core.getProperty("pause"))
      }
      for (surface in order) {
        changeSurfaceVisibility(instrumentation, surface, visible = true, cycle = cycle)
        assertEquals("Surface restoration cleared public pause in cycle $cycle", "yes", core.getProperty("pause"))
      }

      val pausedPosition = awaitProperty(core, "time-pos", "paused playback position", cycle) {
        it?.toDoubleOrNull() != null
      }.toDouble()
      setProperty(instrumentation, core, "pause", "no", cycle)
      awaitProperty(core, "pause", "public resume", cycle) { it == "no" }
      var progressStart = pausedPosition
      awaitProperty(core, "time-pos", "playback progress after surface restoration", cycle) { value ->
        val position = value?.toDoubleOrNull()
        if (position == null) {
          false
        } else {
          // The fixture is two seconds long and loops. Start measuring again
          // across a loop boundary rather than mistaking a wrap for a stall.
          if (position < progressStart) progressStart = position
          position >= progressStart + 0.1
        }
      }
      assertVideoOutput(core, cycle, hardwareDecoding)
    }
  }

  private fun changeSurfaceVisibility(
    instrumentation: Instrumentation,
    surface: SurfaceView,
    visible: Boolean,
    cycle: Int
  ) {
    val changed = CountDownLatch(1)
    val callback = object : SurfaceHolder.Callback {
      override fun surfaceCreated(holder: SurfaceHolder) {
        if (visible) changed.countDown()
      }

      override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) = Unit

      override fun surfaceDestroyed(holder: SurfaceHolder) {
        if (!visible) changed.countDown()
      }
    }
    try {
      instrumentation.runOnMainSync {
        surface.holder.addCallback(callback)
        surface.visibility = if (visible) View.VISIBLE else View.INVISIBLE
      }
      assertCompletes(changed, if (visible) "real surface creation" else "real surface destruction", cycle)
      instrumentation.runOnMainSync {
        assertEquals("Unexpected surface validity in cycle $cycle", visible, surface.holder.surface.isValid)
      }
    } finally {
      instrumentation.runOnMainSync { surface.holder.removeCallback(callback) }
    }
  }

  private fun awaitProperty(
    core: MpvPlayerCore,
    name: String,
    operation: String,
    cycle: Int,
    matches: (String?) -> Boolean
  ): String {
    val deadline = SystemClock.elapsedRealtime() + TimeUnit.SECONDS.toMillis(OPERATION_TIMEOUT_SECONDS)
    var value: String?
    do {
      value = core.getProperty(name)
      if (matches(value)) return requireNotNull(value)
      SystemClock.sleep(20)
    } while (SystemClock.elapsedRealtime() < deadline)
    throw AssertionError("$operation timed out in cycle $cycle; $name=$value")
  }

  private fun assertVideoOutput(core: MpvPlayerCore, cycle: Int, hardwareDecoding: Boolean) {
    if (hardwareDecoding) {
      assertEquals("mediacodec", core.getProperty("current-vo"))
      assertTrue(
        "Expected MediaCodec hardware decoding in cycle $cycle",
        core.getProperty("hwdec-current")?.startsWith("mediacodec") == true
      )
    } else {
      assertEquals("gpu", core.getProperty("current-vo"))
      assertEquals("no", core.getProperty("hwdec-current"))
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

package com.edde746.plezy.mpv

import android.content.ComponentCallbacks2
import android.content.Intent
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.edde746.plezy.shared.PlayerDelegate
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * The performance overlay's read path against a real core.
 *
 * The JVM suite pins the ordering property - a sweep may not sit in front of a
 * real property read - with a controlled reader. What only a device can answer
 * is whether the sweep, now one suspend pass rather than a property at a time
 * through the blocking entry, still reads what the overlay renders out of an
 * actual mpv core, and whether a concurrent read is answered while it runs.
 */
@RunWith(AndroidJUnit4::class)
class MpvStatsSweepDeviceTest {

  @Test
  fun aSweepReadsRealValuesWhileAConcurrentPropertyReadIsAnswered() {
    withPlayingCore { core ->
      // The sweep is one suspend pass now; the synchronous entry is a single
      // blocking read. Both have to see the same core state, or the sweep is
      // reporting something the rest of the app would disagree with.
      val shared = listOf("current-vo", "hwdec-current", "video-codec")
      val direct = shared.associateWith { core.getProperty(it) }
      val sweepDone = CountDownLatch(1)
      val sweep = AtomicReference<Map<String, Any?>>()
      val readDone = CountDownLatch(1)
      val read = AtomicReference<String?>()

      // Both issued before either can answer, so the read is genuinely
      // concurrent with the sweep rather than sequenced after it.
      onMain {
        core.getStatsAsync {
          sweep.set(it)
          sweepDone.countDown()
        }
        core.getPropertyAsync("volume") {
          read.set(it)
          readDone.countDown()
        }
      }

      assertTrue("the concurrent property read was never answered", readDone.await(5, TimeUnit.SECONDS))
      assertNotNull("the concurrent property read answered null", read.get())
      assertTrue("the sweep never answered", sweepDone.await(10, TimeUnit.SECONDS))

      val stats = sweep.get()
      assertEquals("mpv", stats["playerType"])
      // A sweep that silently read nothing would still carry playerType, so
      // assert on values only a decoding core can supply.
      for (key in listOf("video-codec", "video-params/w", "video-params/h", "current-vo", "demuxer-max-bytes")) {
        assertNotNull("$key came back null; sweep=$stats", stats[key])
      }
      // The video-only keys are gated on the sweep's own first read, so their
      // presence proves that read landed too.
      assertNotNull("video-params/pixelformat missing, so hasVideo read false; sweep=$stats", stats["video-params/pixelformat"])
      assertEquals("the sweep and the synchronous read disagree", direct, shared.associateWith { stats[it] })
    }
  }

  @Test
  fun memoryPressureNarrowsTheDemuxerBudgetOneWay() {
    withPlayingCore { core ->
      // getProperty refuses to run on the main thread, so these synchronous
      // reads stay on the instrumentation thread.
      fun budget() = core.getProperty("demuxer-max-bytes")?.toLongOrNull()

      val steady = budget()
      assertNotNull("demuxer-max-bytes unreadable on a playing core", steady)

      onMain { core.onTrimMemory(ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL) }
      val critical = awaitBudgetChange(steady) { budget() }
      assertTrue("critical pressure did not narrow $steady", critical!! < steady!!)

      // A milder level afterwards asks for more read-ahead than critical left
      // applied; re-growing while the device is still thrashing is how the app
      // got killed, so the budget must stay where it is.
      onMain { core.onTrimMemory(ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW) }
      Thread.sleep(500)
      assertEquals("a milder trim level re-grew the budget", critical, budget())
    }
  }

  private fun awaitBudgetChange(from: Long?, read: () -> Long?): Long? {
    repeat(50) {
      val value = read()
      if (value != from) return value
      Thread.sleep(100)
    }
    return read()
  }

  private fun withPlayingCore(body: (MpvPlayerCore) -> Unit) {
    val instrumentation = InstrumentationRegistry.getInstrumentation()
    val fixtureBytes = instrumentation.context.assets.open("ffmpeg/mediacodec_teardown.mp4").use { it.readBytes() }
    val fixture = File.createTempFile("mpv-stats-", ".mp4", instrumentation.targetContext.cacheDir)
      .apply { writeBytes(fixtureBytes) }
    val activity = instrumentation.startActivitySync(
      Intent(instrumentation.targetContext, MpvLifecycleTestActivity::class.java)
        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    ) as MpvLifecycleTestActivity
    instrumentation.waitForIdleSync()

    val events = Loaded()
    val core = AtomicReference<MpvPlayerCore>()
    val initialized = CountDownLatch(1)
    val initializationResult = AtomicReference<Boolean>()
    instrumentation.runOnMainSync {
      core.set(
        MpvPlayerCore(activity).also {
          it.delegate = events
          it.initialize { success ->
            initializationResult.set(success)
            initialized.countDown()
          }
        }
      )
    }
    try {
      assertTrue("MPV initialization timed out", initialized.await(10, TimeUnit.SECONDS))
      assertTrue("MPV initialization failed", initializationResult.get())
      // The fixture is two seconds long, so playing it out would leave mpv
      // idle by the time the sweep runs and every runtime property would
      // legitimately read null. Loop it and hold it paused: the file stays
      // loaded and its decode state stays readable for as long as the test
      // needs, without depending on the fixture's length.
      // Same pre-load setup the lifecycle suite uses, which is what gets a
      // video output configured in this bare host: the decoder is chosen
      // explicitly and audio is left out of it.
      write(core.get(), "hwdec", "mediacodec")
      write(core.get(), "aid", "no")
      write(core.get(), "loop-file", "inf")
      val loaded = CountDownLatch(1)
      instrumentation.runOnMainSync {
        core.get().command(arrayOf("loadfile", fixture.absolutePath, "replace")) { loaded.countDown() }
      }
      assertTrue("loadfile timed out", loaded.await(10, TimeUnit.SECONDS))
      assertTrue("file-loaded never arrived", events.fileLoaded.await(10, TimeUnit.SECONDS))
      assertTrue("playback-restart never arrived", events.playbackRestart.await(10, TimeUnit.SECONDS))
      write(core.get(), "pause", "yes")

      body(core.get())
    } finally {
      val disposed = CountDownLatch(1)
      instrumentation.runOnMainSync { core.get().dispose { disposed.countDown() } }
      disposed.await(15, TimeUnit.SECONDS)
      instrumentation.runOnMainSync(activity::finish)
      instrumentation.waitForIdleSync()
      fixture.delete()
    }
  }

  private fun write(core: MpvPlayerCore, name: String, value: String) {
    val done = CountDownLatch(1)
    onMain { core.setProperty(name, value) { done.countDown() } }
    assertTrue("$name write timed out", done.await(10, TimeUnit.SECONDS))
  }

  private fun onMain(block: () -> Unit) = InstrumentationRegistry.getInstrumentation().runOnMainSync(block)

  private class Loaded : PlayerDelegate {
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
}

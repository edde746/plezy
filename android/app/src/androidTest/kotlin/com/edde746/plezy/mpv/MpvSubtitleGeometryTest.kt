package com.edde746.plezy.mpv

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Rect
import android.view.Choreographer
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.edde746.plezy.shared.PlayerDelegate
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Pixel coverage for the real MediaCodec video + OSD surfaces, not channel forwarding.
 * Fixture: 640x480 blue H.264, 24 fps, 30 seconds, with a red 80x80 ASS drawing
 * at \pos(0,0), PlayRes 640x480, no outline/shadow. Encoded by ffmpeg/libx264
 * baseline, yuv420p, ultrafast, CRF 30; the ASS stream is muxed, not burned in.
 */
@RunWith(AndroidJUnit4::class)
class MpvSubtitleGeometryTest {
  @Test
  fun positionedSignUsesPictureCoordinates() = checkPositionedSign(1f)

  @Test
  fun reducedOsdBufferPreservesPictureCoordinates() = checkPositionedSign(1f / 3f)

  @Test
  fun pausedRendererChangesPreservePositionAndSubtitles() = checkPositionedSign(1f, changeRenderers = true)

  private fun checkPositionedSign(renderScale: Float, changeRenderers: Boolean = false) {
    val instrumentation = InstrumentationRegistry.getInstrumentation()
    val context = instrumentation.targetContext
    val intent = Intent().setClassName(context.packageName, "${context.packageName}.mpv.MpvLifecycleTestActivity")
      .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    // The empty host is debug-only; the separate reachability suite owns minified builds.
    assumeTrue("Requires debug activity", context.packageManager.resolveActivity(intent, 0) != null)
    val media = File.createTempFile("subtitle-geometry-", ".mkv", context.cacheDir)
    val fonts = File(context.cacheDir, "subtitle-geometry-fonts-${System.nanoTime()}").apply { check(mkdir()) }
    val core = AtomicReference<MpvPlayerCore>()
    val started = CountDownLatch(1)
    var scenario: ActivityScenario<Activity>? = null
    try {
      instrumentation.context.assets.open("ffmpeg/subtitle_geometry.mkv").use { input ->
        media.outputStream().use(input::copyTo)
      }
      context.assets.open("flutter_assets/assets/go-noto-current-regular.ttf").use { input ->
        File(fonts, "go-noto-current-regular.ttf").outputStream().use(input::copyTo)
      }
      val initialized = CountDownLatch(1)
      scenario = ActivityScenario.launch<Activity>(intent)
      scenario.onActivity { activity ->
        core.set(MpvPlayerCore(activity, false, true, renderScale, "warn"))
        core.get().delegate = object : PlayerDelegate {
          override fun onPropertyChange(name: String, value: Any?) = Unit
          override fun onEvent(name: String, data: Map<String, Any>?) {
            if (name == "playback-restart") started.countDown()
          }
        }
        core.get().initialize { success ->
          assertTrue("MPV initialization", success)
          initialized.countDown()
        }
      }
      await(initialized, "initialize")
      // Production's Dart startup sets this independently of native VO choice.
      setProperty(core.get(), "hwdec", "mediacodec")
      // Native-only hosts must perform the font setup normally owned by Dart.
      setProperty(core.get(), "sub-fonts-dir", fonts.absolutePath)
      setProperty(core.get(), "sub-font", "Go Noto Current-Regular")
      setProperty(core.get(), "sid", "1")
      setProperty(core.get(), "sub-ass-override", "no")
      setProperty(core.get(), "sub-ass-video-aspect-override", "1")
      setProperty(core.get(), "sub-use-margins", "no")
      val opened = CountDownLatch(1)
      instrumentation.runOnMainSync {
        core.get().command(arrayOf("loadfile", media.absolutePath)) { success ->
          assertTrue("Opening geometry fixture", success)
          opened.countDown()
        }
      }
      await(opened, "loadfile")
      // Match PlayerNative.open: loadfile does not establish public play intent.
      setProperty(core.get(), "pause", "no")
      await(started, "playback-restart")
      assertEquals("Hardware-plane regression must exercise the hardware VO", "mediacodec", core.get().getProperty("current-vo"))
      captureSubtitles().recycle()
      setProperty(core.get(), "pause", "yes")
      val pausedAt = core.get().getProperty("time-pos")!!.toDouble()
      val shader = File(fonts, "passthrough.glsl")
      if (changeRenderers) {
        // A real user shader selects GPU output without changing the picture.
        shader.writeText("//!HOOK MAIN\n//!BIND HOOKED\nvec4 hook() { return HOOKED_tex(HOOKED_pos); }\n")
      }

      for (useMargins in listOf("no", "yes")) {
        setProperty(core.get(), "sub-use-margins", useMargins)
        for (vo in if (changeRenderers) listOf("gpu", "mediacodec") else listOf("mediacodec")) {
          if (changeRenderers) {
            setProperty(core.get(), "glsl-shaders", if (vo == "gpu") shader.absolutePath else "")
            awaitRenderer(core.get(), vo)
          }
          val image = captureSubtitles()
          try {
            assertEquals("Renderer", vo, core.get().getProperty("current-vo"))
            assertEquals("Paused state", "yes", core.get().getProperty("pause"))
            assertEquals("Decoder", "mediacodec", core.get().getProperty("hwdec-current"))
            assertEquals("Paused position", pausedAt, core.get().getProperty("time-pos")!!.toDouble(), 0.1)
            if (InstrumentationRegistry.getArguments().getString("geometryScreenshots") == "true") {
              val capture = File(context.cacheDir, "subtitle-geometry-$renderScale-$useMargins.png")
              capture.outputStream().use { image.compress(Bitmap.CompressFormat.PNG, 100, it) }
            }
            val picture = colorBounds(image, red = false)
            val sign = colorBounds(image, red = true)
            val tolerance = 8
            assertTrue("Sign left $sign must follow picture $picture", kotlin.math.abs(sign.left - picture.left) <= tolerance)
            assertTrue("Sign top $sign must follow picture $picture", kotlin.math.abs(sign.top - picture.top) <= tolerance)
            assertTrue("Sign width $sign must retain authored scale within $picture", kotlin.math.abs(sign.width() - picture.width() / 8) <= tolerance)
            assertTrue("Sign height $sign must retain authored scale within $picture", kotlin.math.abs(sign.height() - picture.height() / 6) <= tolerance)
          } finally {
            image.recycle()
          }
        }
      }
    } finally {
      try {
        core.get()?.let { player ->
          val disposed = CountDownLatch(1)
          instrumentation.runOnMainSync { player.dispose(disposed::countDown) }
          await(disposed, "dispose")
        }
      } finally {
        try {
          scenario?.close()
        } finally {
          media.delete()
          fonts.deleteRecursively()
        }
      }
    }
  }

  private fun awaitRenderer(core: MpvPlayerCore, expected: String) {
    val instrumentation = InstrumentationRegistry.getInstrumentation()
    var matchingFrames = 0
    repeat(120) {
      val frame = CountDownLatch(1)
      instrumentation.runOnMainSync { Choreographer.getInstance().postFrameCallback { frame.countDown() } }
      await(frame, "renderer frame")
      if (core.getProperty("current-vo") == expected) matchingFrames++ else matchingFrames = 0
      if (matchingFrames == 8) return
    }
    error("Renderer did not settle on $expected: ${core.getProperty("current-vo")}")
  }

  private fun setProperty(core: MpvPlayerCore, name: String, value: String) {
    val finished = CountDownLatch(1)
    val result = AtomicReference<Result<Unit>>()
    InstrumentationRegistry.getInstrumentation().runOnMainSync {
      core.setProperty(name, value) {
        result.set(it)
        finished.countDown()
      }
    }
    await(finished, name)
    result.get().getOrThrow()
  }

  private fun captureSubtitles(): Bitmap {
    val instrumentation = InstrumentationRegistry.getInstrumentation()
    // playback-restart precedes asynchronous OSD presentation. Wait on display
    // frames until both planes are visible, never on the expected coordinates.
    repeat(120) {
      val frame = CountDownLatch(1)
      instrumentation.runOnMainSync { Choreographer.getInstance().postFrameCallback { frame.countDown() } }
      await(frame, "display frame")
      val image = instrumentation.uiAutomation.takeScreenshot()
      if (image != null) {
        if (!colorBounds(image, true).isEmpty && !colorBounds(image, false).isEmpty) return image
        image.recycle()
      }
    }
    error("Video and subtitle planes did not become visible")
  }

  private fun colorBounds(image: Bitmap, red: Boolean): Rect {
    val bounds = Rect(image.width, image.height, 0, 0)
    val row = IntArray(image.width)
    for (y in 0 until image.height) {
      image.getPixels(row, 0, image.width, 0, y, image.width, 1)
      for (x in row.indices) {
        val color = row[x]
        val r = (color shr 16) and 255
        val g = (color shr 8) and 255
        val b = color and 255
        val matches = if (red) r > 150 && g < 70 && b < 70 else b > 150 && r < 70 && g < 70
        if (matches) {
          bounds.left = minOf(bounds.left, x)
          bounds.top = minOf(bounds.top, y)
          bounds.right = maxOf(bounds.right, x + 1)
          bounds.bottom = maxOf(bounds.bottom, y + 1)
        }
      }
    }
    return bounds
  }

  private fun await(latch: CountDownLatch, operation: String) {
    assertTrue("Timed out: $operation", latch.await(15, TimeUnit.SECONDS))
  }
}

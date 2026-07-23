package com.edde746.plezy.exoplayer

import android.app.Activity
import android.os.Looper
import com.edde746.plezy.mpv.MpvPlayerCore
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.CancellationException
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf

@RunWith(RobolectricTestRunner::class)
class ExoPlayerPluginTest {

  @Test
  fun fallbackGetStatsCompletesAfterActivityDetach() {
    val plugin = ExoPlayerPlugin()
    plugin.javaClass.getDeclaredField("usingMpvFallback").apply {
      isAccessible = true
      setBoolean(plugin, true)
    }
    val result = RecordingResult()

    plugin.onMethodCall(MethodCall("getStats", null), result)

    var completed = false
    repeat(100) {
      shadowOf(Looper.getMainLooper()).idle()
      if (result.completed.await(10, TimeUnit.MILLISECONDS)) {
        completed = true
        return@repeat
      }
    }

    assertTrue("fallback getStats never completed", completed)
    assertEquals(mapOf("playerType" to "mpv"), result.successValue)
  }

  @Test
  fun fallbackPropertyHandlersWaitForAcceptedWritesAndReplyOnce() {
    for (case in fallbackPropertyCases()) {
      val writes = mutableListOf<Pair<String, String>>()
      val plugin = fallbackPlugin { name, value -> writes += name to value }
      val result = RecordingResult()

      plugin.onMethodCall(MethodCall(case.method, case.arguments), result)
      awaitCompletion(result)

      assertEquals(listOf(case.expectedWrite), writes)
      assertEquals(case.successValue, result.successValue)
      assertEquals(1, result.completionCount)
      assertEquals(null, result.errorCode)
    }
  }

  @Test
  fun fallbackPropertyHandlersMapRejectedWritesToBoundedErrorsOnce() {
    for (case in fallbackPropertyCases()) {
      val writes = AtomicInteger()
      val plugin = fallbackPlugin { _, _ ->
        writes.incrementAndGet()
        error("secret-fallback-value")
      }
      val result = RecordingResult()

      plugin.onMethodCall(MethodCall(case.method, case.arguments), result)
      awaitCompletion(result)

      assertEquals(1, writes.get())
      assertEquals(1, result.completionCount)
      assertEquals("SET_PROPERTY_FAILED", result.errorCode)
      assertEquals("MPV property write was rejected or cancelled", result.errorMessage)
      assertTrue(result.errorMessage?.contains("secret-fallback-value") == false)
      assertEquals(null, result.successValue)
      assertEquals(null, result.errorDetails)
    }
  }

  @Test
  fun fallbackCancellationReturnsSetPropertyFailedOnce() {
    val plugin = fallbackPlugin { _, _ ->
      throw CancellationException("secret-cancellation")
    }
    val result = RecordingResult()

    plugin.onMethodCall(
      MethodCall("setMpvProperty", mapOf("name" to "custom", "value" to "secret")),
      result
    )
    awaitCompletion(result)

    assertEquals(1, result.completionCount)
    assertEquals("SET_PROPERTY_FAILED", result.errorCode)
    assertTrue(result.errorMessage?.contains("secret") == false)
    assertEquals(null, result.successValue)
  }

  @Test
  fun fallbackWithoutCoreReturnsNotInitializedOnce() {
    val plugin = ExoPlayerPlugin()
    setField(plugin, "usingMpvFallback", true)
    setField(plugin, "activity", Robolectric.buildActivity(Activity::class.java).setup().get())
    val result = RecordingResult()

    plugin.onMethodCall(MethodCall("pause", null), result)

    assertEquals(1, result.completionCount)
    assertEquals("NOT_INITIALIZED", result.errorCode)
    assertEquals(null, result.successValue)
  }

  @Test
  fun fallbackWithoutActivityReturnsNotInitializedOnce() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val core = MpvPlayerCore(activity, true) { _, _ -> Unit }
    val plugin = ExoPlayerPlugin()
    setField(plugin, "usingMpvFallback", true)
    setField(plugin, "mpvCore", core)
    val result = RecordingResult()

    plugin.onMethodCall(MethodCall("play", null), result)

    assertEquals(1, result.completionCount)
    assertEquals("NOT_INITIALIZED", result.errorCode)
    assertEquals(null, result.successValue)
  }

  @Test
  fun genericPropertyBeforeFallbackIsAcceptedIntoLastWriteWinsPendingMap() {
    val plugin = ExoPlayerPlugin()
    val first = RecordingResult()
    val second = RecordingResult()

    plugin.onMethodCall(
      MethodCall("setMpvProperty", mapOf("name" to "custom", "value" to "first")),
      first
    )
    plugin.onMethodCall(
      MethodCall("setMpvProperty", mapOf("name" to "custom", "value" to "second")),
      second
    )

    @Suppress("UNCHECKED_CAST")
    val pending = getField(plugin, "pendingMpvProperties") as Map<String, String>
    assertEquals(mapOf("custom" to "second"), pending)
    assertEquals(1, first.completionCount)
    assertEquals(1, second.completionCount)
    assertEquals(null, first.errorCode)
    assertEquals(null, second.errorCode)
  }

  @Test
  fun eventCallbacksKeepTheSharedPlayerEnvelope() {
    val plugin = ExoPlayerPlugin()
    val sink = RecordingEventSink()
    plugin.onListen(null, sink)

    plugin.onEvent("ready", mapOf("position" to 42))

    assertEquals(
      mapOf(
        "type" to "event",
        "name" to "ready",
        "data" to mapOf("position" to 42)
      ),
      sink.successValue
    )
  }

  private data class FallbackPropertyCase(
    val method: String,
    val arguments: Any?,
    val expectedWrite: Pair<String, String>,
    val successValue: Any? = null
  )

  private fun fallbackPropertyCases() = listOf(
    FallbackPropertyCase("play", null, "pause" to "no"),
    FallbackPropertyCase("pause", null, "pause" to "yes"),
    FallbackPropertyCase("setVolume", mapOf("volume" to 25), "volume" to "25.0"),
    FallbackPropertyCase("setRate", mapOf("rate" to 1.5), "speed" to "1.5"),
    FallbackPropertyCase("selectAudioTrack", mapOf("trackId" to "2"), "aid" to "2"),
    FallbackPropertyCase("selectSubtitleTrack", emptyMap<String, Any?>(), "sid" to "no"),
    FallbackPropertyCase(
      "setAudioPassthrough",
      mapOf("enabled" to true),
      "audio-spdif" to "ac3,eac3,dts,dts-hd,truehd",
      true
    ),
    FallbackPropertyCase(
      "setMpvProperty",
      mapOf("name" to "custom", "value" to "value"),
      "custom" to "value"
    )
  )

  private fun fallbackPlugin(
    writer: suspend (String, String) -> Unit
  ): ExoPlayerPlugin {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val core = MpvPlayerCore(activity, true, writer)
    return ExoPlayerPlugin().also { plugin ->
      setField(plugin, "activity", activity)
      setField(plugin, "mpvCore", core)
      setField(plugin, "usingMpvFallback", true)
    }
  }

  private fun setField(plugin: ExoPlayerPlugin, name: String, value: Any?) {
    plugin.javaClass.getDeclaredField(name).apply {
      isAccessible = true
      set(plugin, value)
    }
  }

  private fun getField(plugin: ExoPlayerPlugin, name: String): Any? = plugin.javaClass.getDeclaredField(name).run {
    isAccessible = true
    get(plugin)
  }

  private fun awaitCompletion(result: RecordingResult) {
    var completed = false
    repeat(100) {
      shadowOf(Looper.getMainLooper()).idle()
      if (result.completed.await(10, TimeUnit.MILLISECONDS)) {
        completed = true
        return@repeat
      }
    }
    shadowOf(Looper.getMainLooper()).idle()
    assertTrue("fallback property result never completed", completed)
    assertEquals(1, result.completionCount)
  }

  private class RecordingResult : MethodChannel.Result {
    val completed = CountDownLatch(1)
    var successValue: Any? = null
    var errorCode: String? = null
    var errorMessage: String? = null
    var errorDetails: Any? = null
    var completionCount: Int = 0

    override fun success(result: Any?) {
      completionCount++
      successValue = result
      completed.countDown()
    }

    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
      completionCount++
      this.errorCode = errorCode
      this.errorMessage = errorMessage
      this.errorDetails = errorDetails
      completed.countDown()
    }

    override fun notImplemented() {
      completionCount++
      completed.countDown()
    }
  }

  private class RecordingEventSink : EventChannel.EventSink {
    var successValue: Any? = null

    override fun success(event: Any?) {
      successValue = event
    }

    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) = Unit

    override fun endOfStream() = Unit
  }
}

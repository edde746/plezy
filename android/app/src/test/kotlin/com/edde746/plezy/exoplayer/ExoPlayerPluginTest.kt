package com.edde746.plezy.exoplayer

import android.os.Looper
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
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

  private class RecordingResult : MethodChannel.Result {
    val completed = CountDownLatch(1)
    var successValue: Any? = null

    override fun success(result: Any?) {
      successValue = result
      completed.countDown()
    }

    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
      completed.countDown()
    }

    override fun notImplemented() {
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

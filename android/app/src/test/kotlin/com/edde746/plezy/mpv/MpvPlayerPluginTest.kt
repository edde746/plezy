package com.edde746.plezy.mpv

import dev.jdtech.mpv.EndFileReason
import dev.jdtech.mpv.LogLevel
import dev.jdtech.mpv.LogMessage
import dev.jdtech.mpv.MpvEvent
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class MpvPlayerPluginTest {

  @Test
  fun commandWithoutCoreReportsNotInitialized() {
    val result = RecordingResult()

    MpvPlayerPlugin().onMethodCall(
      MethodCall("command", mapOf("args" to listOf("seek", "1", "absolute"))),
      result
    )

    assertEquals("NOT_INITIALIZED", result.errorCode)
    assertNull(result.successValue)
  }

  @Test
  fun disposeCompletesEveryPendingInitialization() {
    val plugin = MpvPlayerPlugin()
    val first = RecordingResult()
    val second = RecordingResult()

    @Suppress("UNCHECKED_CAST")
    val pending = plugin.javaClass.getDeclaredField("pendingInitResults").apply {
      isAccessible = true
    }.get(plugin) as MutableList<MethodChannel.Result>
    pending += first
    pending += second
    plugin.javaClass.getDeclaredField("isInitializing").apply {
      isAccessible = true
      setBoolean(plugin, true)
    }
    val dispose = RecordingResult()

    plugin.onMethodCall(MethodCall("dispose", null), dispose)

    assertEquals(false, first.successValue)
    assertEquals(false, second.successValue)
    assertNull(dispose.successValue)
    assertTrue(first.completed)
    assertTrue(second.completed)
    assertTrue(dispose.completed)
    assertEquals(0, pending.size)
  }

  @Test
  fun setLogLevelReportsUnsupported() {
    val result = RecordingResult()

    MpvPlayerPlugin().onMethodCall(
      MethodCall("setLogLevel", mapOf("level" to "warn")),
      result
    )

    assertEquals("UNSUPPORTED", result.errorCode)
    assertNull(result.successValue)
  }

  @Test
  fun endFileDiagnosticsPreserveReasonIdAndExposeDependencyErrorLog() {
    val diagnostics = MpvEndFileDiagnostics()
    diagnostics.onStartFile()
    diagnostics.onLogMessage(LogMessage("ffmpeg", LogLevel.Error, "Invalid data found when processing input"))

    assertEquals(
      mapOf(
        "reason" to 4,
        "message" to "Invalid data found when processing input"
      ),
      diagnostics.onEndFile(MpvEvent.EndFile(EndFileReason.Error))
    )
  }

  @Test
  fun endFileDiagnosticsDoNotAttachStaleOrInventedDetails() {
    val diagnostics = MpvEndFileDiagnostics()
    diagnostics.onLogMessage(LogMessage("ffmpeg", LogLevel.Error, "old failure"))
    diagnostics.onStartFile()

    assertEquals(mapOf("reason" to 0), diagnostics.onEndFile(MpvEvent.EndFile(EndFileReason.Eof)))
    assertEquals(mapOf("reason" to 4), diagnostics.onEndFile(MpvEvent.EndFile(EndFileReason.Error)))
    assertNull(diagnostics.onEndFile(MpvEvent.EndFile(null)))
  }

  @Test
  fun endFileEventChannelPayloadKeepsExistingEnvelopeAndAddsMessage() {
    val sink = RecordingEventSink()
    val plugin = MpvPlayerPlugin()
    plugin.onListen(null, sink)

    plugin.onEvent(
      "end-file",
      mapOf(
        "reason" to 4,
        "message" to "Failed to open stream"
      )
    )

    assertEquals(
      mapOf(
        "type" to "event",
        "name" to "end-file",
        "data" to mapOf(
          "reason" to 4,
          "message" to "Failed to open stream"
        )
      ),
      sink.successValue
    )
  }

  private class RecordingResult : MethodChannel.Result {
    var successValue: Any? = null
    var errorCode: String? = null
    var completed: Boolean = false

    override fun success(result: Any?) {
      completed = true
      successValue = result
    }

    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
      completed = true
      this.errorCode = errorCode
    }

    override fun notImplemented() = Unit
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

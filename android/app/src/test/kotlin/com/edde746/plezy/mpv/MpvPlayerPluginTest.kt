package com.edde746.plezy.mpv

import android.app.Activity
import android.os.Looper
import dev.jdtech.mpv.EndFileReason
import dev.jdtech.mpv.LogLevel
import dev.jdtech.mpv.LogMessage
import dev.jdtech.mpv.MpvEvent
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.CancellationException
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import kotlinx.coroutines.suspendCancellableCoroutine
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf

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
  fun setPropertyWithoutCoreReportsNotInitializedForVideoAndAudio() {
    for (plugin in listOf(MpvPlayerPlugin(), MpvAudioPlayerPlugin())) {
      val result = RecordingResult()

      plugin.onMethodCall(propertyCall(), result)

      assertEquals("NOT_INITIALIZED", result.errorCode)
      assertEquals(1, result.completionCount)
      assertNull(result.successValue)
    }
  }

  @Test
  fun acceptedSetPropertyCompletesOnceForVideoAndAudio() {
    for (plugin in listOf(MpvPlayerPlugin(), MpvAudioPlayerPlugin())) {
      val writes = AtomicInteger()
      installCore(plugin, testCore { _, _ -> writes.incrementAndGet() })
      val result = RecordingResult()

      plugin.onMethodCall(propertyCall(), result)
      awaitCompletion(result)

      assertEquals(1, writes.get())
      assertEquals(1, result.completionCount)
      assertNull(result.errorCode)
      assertNull(result.successValue)
    }
  }

  @Test
  fun rejectedSetPropertyFailsOnceForVideoAndAudioWithoutLeakingPayload() {
    for (plugin in listOf(MpvPlayerPlugin(), MpvAudioPlayerPlugin())) {
      installCore(plugin, testCore { _, _ -> error("secret-property-value") })
      val result = RecordingResult()

      plugin.onMethodCall(propertyCall(), result)
      awaitCompletion(result)

      assertEquals(1, result.completionCount)
      assertEquals("SET_PROPERTY_FAILED", result.errorCode)
      assertEquals("MPV property write was rejected or cancelled", result.errorMessage)
      assertTrue(result.errorMessage?.contains("secret-property-value") == false)
      assertNull(result.successValue)
      assertNull(result.errorDetails)
    }
  }

  @Test
  fun cancelledSetPropertyFailsOnceForVideoAndAudio() {
    for (plugin in listOf(MpvPlayerPlugin(), MpvAudioPlayerPlugin())) {
      installCore(plugin, testCore { _, _ -> throw CancellationException("secret-cancellation") })
      val result = RecordingResult()

      plugin.onMethodCall(propertyCall(), result)
      awaitCompletion(result)

      assertEquals(1, result.completionCount)
      assertEquals("SET_PROPERTY_FAILED", result.errorCode)
      assertTrue(result.errorMessage?.contains("secret-cancellation") == false)
      assertNull(result.successValue)
    }
  }

  @Test
  fun coreReportsMissingPlayerDuringWriteAsFailure() {
    val core = testCore(null)
    var outcome: Result<Unit>? = null

    core.setProperty("volume", "50") { outcome = it }
    awaitCondition { outcome != null }

    assertTrue(outcome?.isFailure == true)
  }

  @Test
  fun disposeCancelsQueuedPropertyWritesAndCompletesEachCallbackOnce() {
    val firstStarted = CountDownLatch(1)
    val core = testCore { name, _ ->
      if (name == "first") {
        suspendCancellableCoroutine<Unit> {
          firstStarted.countDown()
        }
      }
    }
    val outcomes = mutableListOf<Result<Unit>>()

    core.setProperty("first", "value") { outcomes += it }
    assertTrue(firstStarted.await(1, TimeUnit.SECONDS))
    core.setProperty("second", "value") { outcomes += it }
    core.dispose()
    awaitCondition { outcomes.size == 2 }

    assertEquals(2, outcomes.size)
    assertTrue(outcomes.all { it.isFailure })
  }

  @Test
  fun failedPauseLeavesAllPauseBookkeepingUnchanged() {
    val core = testVideoCore { _, _ -> error("rejected") }
    setBoolean(core, "cachedPaused", false)
    setBoolean(core, "pausedForSurfaceLoss", true)
    setBoolean(core, "resumeBlockedByPublicPause", false)
    setBoolean(core, "deferredResumeRequested", true)
    var outcome: Result<Unit>? = null

    core.setProperty("pause", "yes") { outcome = it }
    awaitCondition { outcome != null }

    assertTrue(outcome?.isFailure == true)
    assertEquals(false, getBoolean(core, "cachedPaused"))
    assertEquals(true, getBoolean(core, "pausedForSurfaceLoss"))
    assertEquals(false, getBoolean(core, "resumeBlockedByPublicPause"))
    assertEquals(true, getBoolean(core, "deferredResumeRequested"))
  }

  @Test
  fun resumeWithoutReadyVideoOutputIsAcceptedAndDeferredWithoutWriting() {
    val writes = AtomicInteger()
    val core = testVideoCore { _, _ -> writes.incrementAndGet() }
    setBoolean(core, "resumeBlockedByPublicPause", true)
    var outcome: Result<Unit>? = null

    core.setProperty("pause", "no") { outcome = it }
    awaitCondition { outcome != null }

    assertTrue(outcome?.isSuccess == true)
    assertEquals(0, writes.get())
    assertEquals(false, getBoolean(core, "resumeBlockedByPublicPause"))
    assertEquals(true, getBoolean(core, "deferredResumeRequested"))
    assertEquals(true, getBoolean(core, "cachedPaused"))
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
    assertEquals(1, first.completionCount)
    assertEquals(1, second.completionCount)
    assertEquals(1, dispose.completionCount)
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

  private fun propertyCall() = MethodCall(
    "setProperty",
    mapOf("name" to "volume", "value" to "50")
  )

  private fun testCore(
    writer: (suspend (String, String) -> Unit)?
  ): MpvPlayerCore = MpvPlayerCore(
    Robolectric.buildActivity(Activity::class.java).setup().get(),
    true,
    writer
  )

  private fun testVideoCore(
    writer: suspend (String, String) -> Unit
  ): MpvPlayerCore = MpvPlayerCore(
    Robolectric.buildActivity(Activity::class.java).setup().get(),
    false,
    writer
  )

  private fun installCore(plugin: MpvPlayerPlugin, core: MpvPlayerCore) {
    MpvPlayerPlugin::class.java.getDeclaredField("playerCore").apply {
      isAccessible = true
      set(plugin, core)
    }
  }

  private fun setBoolean(core: MpvPlayerCore, name: String, value: Boolean) {
    MpvPlayerCore::class.java.getDeclaredField(name).apply {
      isAccessible = true
      setBoolean(core, value)
    }
  }

  private fun getBoolean(core: MpvPlayerCore, name: String): Boolean = MpvPlayerCore::class.java.getDeclaredField(name).run {
    isAccessible = true
    getBoolean(core)
  }

  private fun awaitCompletion(result: RecordingResult) {
    awaitCondition { result.completed.await(10, TimeUnit.MILLISECONDS) }
    shadowOf(Looper.getMainLooper()).idle()
    assertEquals(1, result.completionCount)
  }

  private fun awaitCondition(condition: () -> Boolean) {
    var completed = false
    repeat(100) {
      shadowOf(Looper.getMainLooper()).idle()
      if (condition()) {
        completed = true
        return@repeat
      }
      Thread.sleep(10)
    }
    assertTrue("asynchronous operation never completed", completed)
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

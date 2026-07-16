package com.edde746.plezy

import android.app.Activity
import android.content.Intent
import io.flutter.plugin.common.MethodChannel
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class ExternalPlayerChannelTest {

  @Test
  fun mxPlayerResultPreservesPositionDurationAndCompletion() {
    val activity = Robolectric.buildActivity(Activity::class.java).get()
    val channel = ExternalPlayerChannel(activity)
    val data = Intent("com.mxtech.intent.result.VIEW")
      .putExtra("position", 123)
      .putExtra("duration", "456")
      .putExtra("end_by", "playback_completion")

    val result = channel.buildResult(Activity.RESULT_OK, data)

    assertEquals(123L, result["positionMs"])
    assertEquals(456L, result["durationMs"])
    assertEquals(true, result["playbackCompleted"])
    assertEquals(false, result["playbackError"])
  }

  @Test
  fun activityDestroyCompletesPendingChannelCall() {
    val activity = Robolectric.buildActivity(Activity::class.java).get()
    val channel = ExternalPlayerChannel(activity)
    val result = RecordingResult()
    channel.javaClass.getDeclaredField("pendingResult").apply {
      isAccessible = true
      set(channel, result)
    }

    channel.dispose()

    assertTrue(result.completed)
    assertEquals("ACTIVITY_DESTROYED", result.errorCode)
  }

  private class RecordingResult : MethodChannel.Result {
    var completed = false
    var errorCode: String? = null

    override fun success(result: Any?) {
      completed = true
    }

    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
      completed = true
      this.errorCode = errorCode
    }

    override fun notImplemented() {
      completed = true
    }
  }
}

package com.edde746.plezy

import android.app.Activity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [25])
class AppUpdateChannelTest {
  @Test
  fun preparationOnlyDeletesUpdaterFiles() {
    val activity = Robolectric.buildActivity(Activity::class.java).get()
    val directory = File(activity.cacheDir, "app-updates").apply { mkdirs() }
    listOf("update.apk", "update.tar.gz", "update.tar.gz.part").forEach { File(directory, it).writeText("old") }
    val unrelated = File(activity.cacheDir, "other-data").apply { writeText("keep") }
    val result = RecordingResult()

    AppUpdateChannel(activity).onMethodCall(MethodCall("prepareUpdateDirectory", null), result)

    assertEquals(directory.absolutePath, result.value)
    assertTrue(directory.listFiles().isNullOrEmpty())
    assertTrue(unrelated.exists())
  }

  @Test
  fun refusesFilesOutsideUpdateCache() {
    val activity = Robolectric.buildActivity(Activity::class.java).get()
    val unrelated = File(activity.cacheDir, "untrusted.apk").apply { writeText("not an APK") }
    val result = RecordingResult()

    AppUpdateChannel(activity).onMethodCall(MethodCall("installUpdate", mapOf("path" to unrelated.path)), result)

    assertEquals("UPDATE_FAILED", result.errorCode)
    assertTrue(unrelated.exists())
  }

  private class RecordingResult : MethodChannel.Result {
    var value: Any? = null
    var errorCode: String? = null
    override fun success(result: Any?) { value = result }
    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) { this.errorCode = errorCode }
    override fun notImplemented() { errorCode = "NOT_IMPLEMENTED" }
  }
}

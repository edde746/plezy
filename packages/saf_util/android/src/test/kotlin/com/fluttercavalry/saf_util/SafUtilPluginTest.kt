package com.fluttercavalry.saf_util

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import org.mockito.ArgumentCaptor
import org.mockito.Mockito.mock
import org.mockito.Mockito.verify
import org.mockito.Mockito.verifyNoInteractions
import org.mockito.Mockito.verifyNoMoreInteractions
import org.mockito.Mockito.`when`

internal class SafUtilPluginTest {
  @Test
  fun onMethodCall_unknownMethod_returnsNotImplemented() {
    val plugin = SafUtilPlugin()
    val result = mock(MethodChannel.Result::class.java)

    plugin.onMethodCall(MethodCall("unknown", null), result)

    verify(result).notImplemented()
    verifyNoMoreInteractions(result)
  }

  @Test
  fun pickDirectory_withoutActivity_returnsNoActivityError() {
    val plugin = SafUtilPlugin()
    val result = mock(MethodChannel.Result::class.java)

    plugin.onMethodCall(MethodCall("pickDirectory", null), result)

    verify(result).error("NO_ACTIVITY", "Activity is null", null)
    verifyNoMoreInteractions(result)
  }

  @Suppress("DEPRECATION")
  @Test
  fun unrelatedActivityResultDoesNotConsumeOrAnswerPendingPicker() {
    val plugin = SafUtilPlugin()
    val activity = RecordingActivity()
    val binding = mock(ActivityPluginBinding::class.java)
    `when`(binding.activity).thenReturn(activity)
    plugin.onAttachedToActivity(binding)

    val listenerCaptor = ArgumentCaptor.forClass(PluginRegistry.ActivityResultListener::class.java)
    verify(binding).addActivityResultListener(listenerCaptor.capture())
    val result = mock(MethodChannel.Result::class.java)
    plugin.onMethodCall(MethodCall("pickDirectory", null), result)

    assertFalse(listenerCaptor.value.onActivityResult(9999, Activity.RESULT_CANCELED, null))
    verifyNoInteractions(result)
    assertTrue(listenerCaptor.value.onActivityResult(1001, Activity.RESULT_CANCELED, null))
    verify(result).success(null)

    assertTrue(listenerCaptor.value.onActivityResult(1001, Activity.RESULT_CANCELED, null))
    verifyNoMoreInteractions(result)
  }

  @Suppress("DEPRECATION")
  @Test
  fun pickDirectory_afterConfigChange_reattachesListenerAndClearsPendingResult() {
    val plugin = SafUtilPlugin()
    val firstActivity = RecordingActivity()
    val firstBinding = mock(ActivityPluginBinding::class.java)
    `when`(firstBinding.activity).thenReturn(firstActivity)

    plugin.onAttachedToActivity(firstBinding)

    val firstListenerCaptor = ArgumentCaptor.forClass(PluginRegistry.ActivityResultListener::class.java)
    verify(firstBinding).addActivityResultListener(firstListenerCaptor.capture())

    val firstResult = mock(MethodChannel.Result::class.java)
    plugin.onMethodCall(MethodCall("pickDirectory", null), firstResult)
    assertEquals(listOf(1001), firstActivity.startedRequestCodes)

    val secondResult = mock(MethodChannel.Result::class.java)
    plugin.onMethodCall(MethodCall("pickDirectory", null), secondResult)
    verify(secondResult).error("ALREADY_PICKING", "Another picker process is already in progress", null)

    plugin.onDetachedFromActivityForConfigChanges()
    verify(firstBinding).removeActivityResultListener(firstListenerCaptor.value)

    val secondActivity = RecordingActivity()
    val secondBinding = mock(ActivityPluginBinding::class.java)
    `when`(secondBinding.activity).thenReturn(secondActivity)

    plugin.onReattachedToActivityForConfigChanges(secondBinding)

    val secondListenerCaptor = ArgumentCaptor.forClass(PluginRegistry.ActivityResultListener::class.java)
    verify(secondBinding).addActivityResultListener(secondListenerCaptor.capture())

    secondListenerCaptor.value.onActivityResult(1001, Activity.RESULT_CANCELED, null)
    verify(firstResult).success(null)

    val thirdResult = mock(MethodChannel.Result::class.java)
    plugin.onMethodCall(MethodCall("pickDirectory", null), thirdResult)
    assertEquals(listOf(1001), secondActivity.startedRequestCodes)
  }

  private class RecordingActivity : Activity() {
    val startedRequestCodes = mutableListOf<Int>()

    @Deprecated("Deprecated in Android")
    override fun startActivityForResult(intent: Intent?, requestCode: Int) {
      startedRequestCodes.add(requestCode)
    }
  }
}

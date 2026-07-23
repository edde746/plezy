package com.fluttercavalry.saf_util

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.ParcelFileDescriptor
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.IOException
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import org.mockito.ArgumentCaptor
import org.mockito.Mockito.doThrow
import org.mockito.Mockito.mock
import org.mockito.Mockito.times
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

  @Test
  fun extractVideoFrame_releasesRetrieverAfterSuccess() {
    val context = mock(Context::class.java)
    val uri = mock(Uri::class.java)
    val frame = mock(Bitmap::class.java)
    val retriever = mock(MediaMetadataRetriever::class.java)
    `when`(retriever.frameAtTime).thenReturn(frame)

    val extracted = extractVideoFrame(context, uri, 320, 180, retriever)

    assertEquals(frame, extracted)
    verify(retriever).setDataSource(context, uri)
    verify(retriever).release()
  }

  @Test
  fun extractVideoFrame_releasesRetrieverWhenDataSourceThrows() {
    val context = mock(Context::class.java)
    val uri = mock(Uri::class.java)
    val retriever = mock(MediaMetadataRetriever::class.java)
    val failure = IllegalStateException("invalid source")
    doThrow(failure).`when`(retriever).setDataSource(context, uri)

    val thrown =
      assertFailsWith<IllegalStateException> {
        extractVideoFrame(context, uri, 320, 180, retriever)
      }

    assertEquals(failure, thrown)
    verify(retriever).release()
  }

  @Test
  fun extractVideoFrame_releasesRetrieverWhenFrameExtractionThrows() {
    val context = mock(Context::class.java)
    val uri = mock(Uri::class.java)
    val retriever = mock(MediaMetadataRetriever::class.java)
    val failure = IllegalStateException("extract failed")
    `when`(retriever.frameAtTime).thenThrow(failure)

    val thrown =
      assertFailsWith<IllegalStateException> {
        extractVideoFrame(context, uri, 320, 180, retriever)
      }

    assertEquals(failure, thrown)
    verify(retriever).release()
  }

  @Test
  fun extractVideoFrame_releasesRetrieverWhenFrameIsNull() {
    val context = mock(Context::class.java)
    val uri = mock(Uri::class.java)
    val retriever = mock(MediaMetadataRetriever::class.java)
    `when`(retriever.frameAtTime).thenReturn(null)

    assertNull(extractVideoFrame(context, uri, 320, 180, retriever))

    verify(retriever).release()
  }

  @Test
  fun closeFileDescriptor_isIdempotent() {
    val registry = FileDescriptorRegistry()
    val descriptor = descriptor(42)
    registry.attach()
    assertEquals(42, registry.register(descriptor))

    registry.close(42)
    registry.close(42)
    registry.close(99)

    verify(descriptor, times(1)).close()
    assertEquals(0, registry.trackedCount)
  }

  @Test
  fun engineDetach_closesAndClearsEveryDescriptorBestEffort() {
    val registry = FileDescriptorRegistry()
    val failingDescriptor = descriptor(42)
    val laterDescriptor = descriptor(43)
    doThrow(IOException("close failed")).`when`(failingDescriptor).close()
    registry.attach()
    registry.register(failingDescriptor)
    registry.register(laterDescriptor)

    registry.detach()
    registry.close(42)
    registry.close(43)

    verify(failingDescriptor, times(1)).close()
    verify(laterDescriptor, times(1)).close()
    assertEquals(0, registry.trackedCount)
  }

  @Test
  fun descriptorCompletingAfterDetach_isRejectedAndClosed() {
    val registry = FileDescriptorRegistry()
    val descriptor = descriptor(42)
    registry.attach()

    registry.detach()
    val registeredFd = registry.register(descriptor)

    assertNull(registeredFd)
    verify(descriptor, times(1)).close()
    assertEquals(0, registry.trackedCount)
  }

  @Test
  fun engineReattach_startsWithEmptyDescriptorOwnership() {
    val registry = FileDescriptorRegistry()
    val firstDescriptor = descriptor(42)
    val secondDescriptor = descriptor(43)
    registry.attach()
    registry.register(firstDescriptor)
    registry.detach()

    registry.attach()
    assertEquals(43, registry.register(secondDescriptor))
    registry.close(43)

    verify(firstDescriptor, times(1)).close()
    verify(secondDescriptor, times(1)).close()
    assertEquals(0, registry.trackedCount)
  }

  private fun descriptor(fd: Int): ParcelFileDescriptor = mock(ParcelFileDescriptor::class.java).also { descriptor ->
    `when`(descriptor.fd).thenReturn(fd)
  }

  private class RecordingActivity : Activity() {
    val startedRequestCodes = mutableListOf<Int>()

    @Deprecated("Deprecated in Android")
    override fun startActivityForResult(intent: Intent?, requestCode: Int) {
      startedRequestCodes.add(requestCode)
    }
  }
}

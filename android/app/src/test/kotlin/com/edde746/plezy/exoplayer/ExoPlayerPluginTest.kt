package com.edde746.plezy.exoplayer

import android.app.Activity
import android.media.AudioManager
import android.os.Handler
import android.os.Looper
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.widget.FrameLayout
import com.edde746.plezy.mpv.MpvPlayerCore
import com.edde746.plezy.shared.AudioFocusManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.CancellationException
import java.util.concurrent.ConcurrentLinkedQueue
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
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
      assertEquals("MPV property write was rejected", result.errorMessage)
      assertTrue(result.errorMessage?.contains("secret-fallback-value") == false)
      assertEquals(null, result.successValue)
      assertEquals(null, result.errorDetails)
    }
  }

  @Test
  fun fallbackCancellationReturnsNotInitializedOnce() {
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
    assertEquals("NOT_INITIALIZED", result.errorCode)
    assertTrue(result.errorMessage?.contains("secret") == false)
    assertEquals(null, result.successValue)
  }

  @Test
  fun fallbackPropertyCancelledByTeardownReturnsNotInitializedOnce() {
    val writerEntered = CountDownLatch(1)
    val releaseWriter = CountDownLatch(1)
    val plugin = fallbackPlugin { _, _ ->
      writerEntered.countDown()
      releaseWriter.await(2, TimeUnit.SECONDS)
    }
    val property = RecordingResult()

    plugin.onMethodCall(MethodCall("setRate", mapOf("rate" to 1.5)), property)
    assertTrue("fallback property writer never started", writerEntered.await(2, TimeUnit.SECONDS))

    val dispose = RecordingResult()
    plugin.onMethodCall(MethodCall("dispose", null), dispose)
    awaitCompletion(dispose)
    releaseWriter.countDown()

    awaitCompletion(property)
    assertEquals(1, property.completionCount)
    assertEquals("NOT_INITIALIZED", property.errorCode)
    assertEquals(null, property.successValue)
  }

  @Test
  fun staleSuccessfulFallbackPropertyReturnsNotInitializedOnce() {
    val writerEntered = CountDownLatch(1)
    val releaseWriter = CountDownLatch(1)
    val plugin = fallbackPlugin { _, _ ->
      writerEntered.countDown()
      releaseWriter.await(2, TimeUnit.SECONDS)
    }
    val core = getField(plugin, "mpvCore") as MpvPlayerCore
    val result = RecordingResult()

    plugin.onMethodCall(MethodCall("setRate", mapOf("rate" to 1.5)), result)
    assertTrue("fallback property writer never started", writerEntered.await(2, TimeUnit.SECONDS))

    setField(plugin, "usingMpvFallback", false)
    releaseWriter.countDown()

    awaitCompletion(result)
    assertEquals(1, result.completionCount)
    assertEquals("NOT_INITIALIZED", result.errorCode)
    assertEquals(null, result.successValue)
    core.dispose()
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
  fun openDuringFallbackDispatchesOnlyTheNewestMediaGeneration() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val exoCore = ExoPlayerCore(activity)
    val mpvCore = MpvPlayerCore(activity, true) { _, _ -> Unit }
    val plugin = ExoPlayerPlugin()
    val sink = RecordingEventSink()
    plugin.onListen(null, sink)
    var initializeCallback: ((Boolean) -> Unit)? = null
    setField(plugin, "activity", activity)
    setField(plugin, "playerCore", exoCore)
    plugin.createMpvCore = { mpvCore }
    plugin.initializeMpvCore = { _, callback -> initializeCallback = callback }

    assertTrue(
      plugin.onFormatUnsupported(
        mediaGeneration = 0,
        uri = "https://example.test/failed.mkv",
        headers = null,
        positionMs = 1234L,
        playWhenReady = true,
        errorMessage = "unsupported"
      )
    )
    shadowOf(Looper.getMainLooper()).idle()
    assertTrue(initializeCallback != null)

    val superseded = RecordingResult()
    val active = RecordingResult()
    plugin.onMethodCall(
      MethodCall("open", mapOf("uri" to "https://example.test/episode-2.mkv", "autoPlay" to true)),
      superseded
    )
    plugin.onMethodCall(
      MethodCall("open", mapOf("uri" to "https://example.test/episode-3.mkv", "autoPlay" to true)),
      active
    )

    assertEquals(1, superseded.completionCount)
    assertEquals("OPEN_SUPERSEDED", superseded.errorCode)
    assertEquals(0, active.completionCount)

    initializeCallback!!(true)
    mpvCore.delegate?.onEvent("file-loaded", null)
    awaitCompletion(active)

    assertEquals(null, active.errorCode)
    assertEquals(true, getField(plugin, "usingMpvFallback"))
    assertEquals(false, getField(plugin, "fallbackInProgress"))
    assertNull(getField(plugin, "pendingOpen"))
    assertEquals(listOf("backend-switched", "file-loaded"), sink.eventNames)

    val disposeResult = RecordingResult()
    plugin.onMethodCall(MethodCall("dispose", null), disposeResult)
    awaitCompletion(disposeResult)
  }

  @Test
  fun repeatedInitializeDuringFallbackKeepsTheQueuedOpenOwnedByThatSession() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val exoCore = ExoPlayerCore(activity)
    val mpvCore = MpvPlayerCore(activity, true) { _, _ -> Unit }
    val plugin = ExoPlayerPlugin()
    var initializeCallback: ((Boolean) -> Unit)? = null
    setField(plugin, "activity", activity)
    setField(plugin, "playerCore", exoCore)
    plugin.createMpvCore = { mpvCore }
    plugin.initializeMpvCore = { _, callback -> initializeCallback = callback }

    assertTrue(
      plugin.onFormatUnsupported(
        mediaGeneration = 0,
        uri = "https://example.test/failed.mkv",
        headers = null,
        positionMs = 0L,
        playWhenReady = true,
        errorMessage = "unsupported"
      )
    )
    shadowOf(Looper.getMainLooper()).idle()

    val open = RecordingResult()
    plugin.onMethodCall(
      MethodCall("open", mapOf("uri" to "https://example.test/episode-2.mkv", "autoPlay" to true)),
      open
    )
    val repeatedInitialize = RecordingResult()
    plugin.onMethodCall(MethodCall("initialize", emptyMap<String, Any?>()), repeatedInitialize)
    awaitCompletion(repeatedInitialize)

    assertEquals(true, repeatedInitialize.successValue)
    assertEquals(0, open.completionCount)
    assertTrue(getField(plugin, "pendingOpen") != null)
    assertEquals(true, getField(plugin, "fallbackInProgress"))

    initializeCallback!!(false)
    awaitCompletion(open)
    assertEquals("FALLBACK_FAILED", open.errorCode)
  }

  @Test
  fun fallbackInitializationFailureTerminatesTheActiveQueuedOpenOnce() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val exoCore = ExoPlayerCore(activity)
    val mpvCore = MpvPlayerCore(activity, true) { _, _ -> Unit }
    val plugin = ExoPlayerPlugin()
    val sink = RecordingEventSink()
    plugin.onListen(null, sink)
    var initializeCallback: ((Boolean) -> Unit)? = null
    setField(plugin, "activity", activity)
    setField(plugin, "playerCore", exoCore)
    plugin.createMpvCore = { mpvCore }
    plugin.initializeMpvCore = { _, callback -> initializeCallback = callback }

    assertTrue(
      plugin.onFormatUnsupported(
        mediaGeneration = 0,
        uri = "https://example.test/failed.mkv",
        headers = null,
        positionMs = 0L,
        playWhenReady = true,
        errorMessage = "unsupported"
      )
    )
    shadowOf(Looper.getMainLooper()).idle()

    val active = RecordingResult()
    plugin.onMethodCall(
      MethodCall("open", mapOf("uri" to "https://example.test/episode-2.mkv", "autoPlay" to true)),
      active
    )

    initializeCallback!!(false)
    awaitCompletion(active)
    initializeCallback!!(false)
    shadowOf(Looper.getMainLooper()).idle()

    assertEquals(1, active.completionCount)
    assertEquals("FALLBACK_FAILED", active.errorCode)
    assertEquals(1, getField(plugin, "terminalEventGeneration"))
    assertEquals(false, getField(plugin, "fallbackInProgress"))
    assertNull(getField(plugin, "pendingOpen"))
    assertEquals(listOf("end-file"), sink.eventNames)
  }

  @Test
  fun fallbackInitializationTimeoutTerminatesTheActiveQueuedOpen() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val exoCore = ExoPlayerCore(activity)
    val mpvCore = MpvPlayerCore(activity, true) { _, _ -> Unit }
    val plugin = ExoPlayerPlugin()
    setField(plugin, "activity", activity)
    setField(plugin, "playerCore", exoCore)
    plugin.createMpvCore = { mpvCore }
    plugin.initializeMpvCore = { _, _ -> Unit }

    assertTrue(
      plugin.onFormatUnsupported(
        mediaGeneration = 0,
        uri = "https://example.test/failed.mkv",
        headers = null,
        positionMs = 0L,
        playWhenReady = true,
        errorMessage = "unsupported"
      )
    )
    shadowOf(Looper.getMainLooper()).idle()

    val active = RecordingResult()
    plugin.onMethodCall(
      MethodCall("open", mapOf("uri" to "https://example.test/episode-2.mkv", "autoPlay" to true)),
      active
    )

    shadowOf(Looper.getMainLooper()).idleFor(10, TimeUnit.SECONDS)
    awaitCompletion(active)

    assertEquals(1, active.completionCount)
    assertEquals("FALLBACK_FAILED", active.errorCode)
    assertEquals(1, getField(plugin, "terminalEventGeneration"))
    assertEquals(false, getField(plugin, "fallbackInProgress"))
    assertNull(getField(plugin, "pendingOpen"))
  }

  @Test
  fun fallbackMediaResolutionTimeoutTerminatesTheOpenAndPlayback() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val mpvCore = MpvPlayerCore(activity, true) { _, _ -> Unit }
    val plugin = ExoPlayerPlugin()
    val sink = RecordingEventSink()
    plugin.onListen(null, sink)
    setField(plugin, "activity", activity)
    setField(plugin, "mpvCore", mpvCore)
    setField(plugin, "usingMpvFallback", true)
    plugin.resolveMpvUri = { _, _, _ -> Unit }

    val open = RecordingResult()
    plugin.onMethodCall(
      MethodCall("open", mapOf("uri" to "content://example.test/blocked", "autoPlay" to true)),
      open
    )

    shadowOf(Looper.getMainLooper()).idleFor(10, TimeUnit.SECONDS)
    awaitCompletion(open)

    assertEquals("OPEN_TIMEOUT", open.errorCode)
    assertEquals(false, getField(plugin, "usingMpvFallback"))
    assertNull(getField(plugin, "inFlightOpen"))
    assertEquals(listOf("end-file"), sink.eventNames)
  }

  @Test
  fun supersededActiveOpenRecreatesMpvAndDispatchesOnlyTheLatestQueuedRequest() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val originalCore = MpvPlayerCore(activity, true) { _, _ -> Unit }
    val replacementCore = MpvPlayerCore(activity, true) { _, _ -> Unit }
    val plugin = reusedFallbackPlugin(activity, originalCore)
    var replacementInitialize: ((Boolean) -> Unit)? = null
    var replacementCount = 0
    plugin.createMpvCore = {
      replacementCount++
      replacementCore
    }
    plugin.initializeMpvCore = { _, callback -> replacementInitialize = callback }
    plugin.resolveMpvUri = { _, _, _ -> Unit }

    val first = RecordingResult()
    val supersededPending = RecordingResult()
    val latest = RecordingResult()
    plugin.onMethodCall(
      MethodCall("open", mapOf("uri" to "content://example.test/first", "autoPlay" to true)),
      first
    )
    plugin.onMethodCall(
      MethodCall("open", mapOf("uri" to "content://example.test/second", "autoPlay" to true)),
      supersededPending
    )
    assertEquals("OPEN_SUPERSEDED", first.errorCode)

    shadowOf(Looper.getMainLooper()).idleFor(10, TimeUnit.SECONDS)
    assertEquals(1, replacementCount)
    assertTrue(replacementInitialize != null)
    assertEquals(0, supersededPending.completionCount)

    plugin.onMethodCall(
      MethodCall("open", mapOf("uri" to "content://example.test/latest", "autoPlay" to true)),
      latest
    )
    assertEquals("OPEN_SUPERSEDED", supersededPending.errorCode)

    replacementInitialize!!(true)
    shadowOf(Looper.getMainLooper()).idle()

    assertEquals(0, latest.completionCount)
    assertNull(getField(plugin, "pendingOpen"))
    assertTrue(getField(plugin, "inFlightOpen") != null)
    assertEquals(replacementCore, getField(plugin, "mpvCore"))

    val dispose = RecordingResult()
    plugin.onMethodCall(MethodCall("dispose", null), dispose)
    awaitCompletion(dispose)
    assertEquals("NOT_INITIALIZED", latest.errorCode)
  }

  @Test
  fun fallbackLoadFailureReturnsAnErrorAndTerminatesTheActiveMedia() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val exoCore = ExoPlayerCore(activity)
    val mpvCore = MpvPlayerCore(activity, true) { _, _ -> Unit }
    val plugin = ExoPlayerPlugin()
    val sink = RecordingEventSink()
    plugin.onListen(null, sink)
    var initializeCallback: ((Boolean) -> Unit)? = null
    setField(plugin, "activity", activity)
    setField(plugin, "playerCore", exoCore)
    plugin.createMpvCore = { mpvCore }
    plugin.initializeMpvCore = { _, callback -> initializeCallback = callback }

    assertTrue(
      plugin.onFormatUnsupported(
        mediaGeneration = 0,
        uri = "https://example.test/failed.mkv",
        headers = null,
        positionMs = 0L,
        playWhenReady = true,
        errorMessage = "unsupported"
      )
    )
    shadowOf(Looper.getMainLooper()).idle()

    val active = RecordingResult()
    plugin.onMethodCall(
      MethodCall("open", mapOf("uri" to "https://example.test/episode-2.mkv", "autoPlay" to true)),
      active
    )

    mpvCore.dispose()
    initializeCallback!!(true)
    awaitCompletion(active)

    assertEquals(1, active.completionCount)
    assertEquals("OPEN_FAILED", active.errorCode)
    assertEquals(1, getField(plugin, "terminalEventGeneration"))
    assertEquals(false, getField(plugin, "usingMpvFallback"))
    assertNull(getField(plugin, "inFlightOpen"))
    assertEquals(listOf("end-file"), sink.eventNames)
  }

  @Test
  fun fallbackPlayAfterFocusLossUsesExplicitResumeContract() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val writes = ConcurrentLinkedQueue<Pair<String, String>>()
    val core = MpvPlayerCore(activity, true) { name, value -> writes += name to value }
    val focusManager = testAudioFocusManager(activity, core)
    core.setPrivateField("audioFocusManager", focusManager)
    core.setPrivateField("desiredPaused", false)
    core.setPrivateField("cachedPaused", false)
    val plugin = reusedFallbackPlugin(activity, core)

    dispatchAudioFocusChange(focusManager, AudioManager.AUDIOFOCUS_LOSS)
    assertTrue(awaitQueueEntry(writes, "pause" to "yes"))
    assertEquals(true, core.getPrivateField("pausedForAudioFocusLoss"))
    setNextAudioFocusRequestResponse(focusManager, AudioManager.AUDIOFOCUS_REQUEST_GRANTED)

    val result = RecordingResult()
    plugin.onMethodCall(MethodCall("play", null), result)
    awaitCompletion(result)

    assertEquals(1, result.completionCount)
    assertNull(result.errorCode)
    assertEquals(listOf("pause" to "yes", "pause" to "no"), writes.toList())
    assertEquals(1, writes.count { it == "pause" to "no" })
    assertEquals(false, core.getPrivateField("pausedForAudioFocusLoss"))
    assertEquals(false, core.getPrivateField("deferredResumeRequested"))
    core.dispose()
  }

  @Test
  fun initialHeldFallbackSynchronouslyBlocksFocusAndSurfaceResumeWithoutPausePropertyWrite() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val writes = ConcurrentLinkedQueue<Pair<String, String>>()
    val core = MpvPlayerCore(activity, true) { name, value -> writes += name to value }
    core.setPrivateField("desiredPaused", false)
    core.setPrivateField("cachedPaused", false)
    core.setPrivateField("resumeBlockedByPublicPause", false)
    core.setPrivateField("pausedForSurfaceLoss", true)
    core.setPrivateField("pausedForAudioFocusLoss", true)
    core.setPrivateField("deferredResumeRequested", true)
    val plugin = initialFallbackPlugin(activity, core)

    invokeSetupMpvFallback(plugin, core, playWhenReady = false)
    invokeAutoResume(core, "audio focus gain")
    invokeAutoResume(core, "surface attached")

    assertEquals(true, core.getPrivateField("desiredPaused"))
    assertEquals(true, core.getPrivateField("cachedPaused"))
    assertEquals(true, core.getPrivateField("resumeBlockedByPublicPause"))
    assertEquals(false, core.getPrivateField("pausedForSurfaceLoss"))
    assertEquals(false, core.getPrivateField("pausedForAudioFocusLoss"))
    assertEquals(false, core.getPrivateField("deferredResumeRequested"))
    assertTrue(awaitQueueEntry(writes, "ao" to "audiotrack"))
    assertFalse(awaitPauseWriteCount(writes, 1))
    core.dispose()
  }

  @Test
  fun initialAutoplayFallbackClearsPublicPauseBlockWithoutPausePropertyWrite() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val writes = ConcurrentLinkedQueue<Pair<String, String>>()
    val core = MpvPlayerCore(activity, true) { name, value -> writes += name to value }
    core.setPrivateField("desiredPaused", true)
    core.setPrivateField("cachedPaused", true)
    core.setPrivateField("resumeBlockedByPublicPause", true)
    val plugin = initialFallbackPlugin(activity, core)

    invokeSetupMpvFallback(plugin, core, playWhenReady = true)

    assertEquals(false, core.getPrivateField("desiredPaused"))
    assertEquals(false, core.getPrivateField("cachedPaused"))
    assertEquals(false, core.getPrivateField("resumeBlockedByPublicPause"))
    assertTrue(awaitQueueEntry(writes, "ao" to "audiotrack"))
    assertFalse(awaitPauseWriteCount(writes, 1))
    core.dispose()
  }

  @Test
  fun reusedHeldFallbackSynchronouslyBlocksAutoResumeWithoutPausePropertyWrite() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val writes = ConcurrentLinkedQueue<Pair<String, String>>()
    val core = MpvPlayerCore(activity, true) { name, value -> writes += name to value }
    core.setPrivateField("desiredPaused", false)
    core.setPrivateField("cachedPaused", false)
    core.setPrivateField("resumeBlockedByPublicPause", false)
    core.setPrivateField("pausedForSurfaceLoss", true)
    core.setPrivateField("deferredResumeRequested", true)
    val plugin = reusedFallbackPlugin(activity, core)
    val result = RecordingResult()

    plugin.onMethodCall(
      MethodCall(
        "open",
        mapOf("uri" to "https://example.test/video.mkv", "autoPlay" to false)
      ),
      result
    )
    invokeAutoResume(core, "surface attached")
    awaitCompletion(result)

    assertEquals(1, result.completionCount)
    assertNull(result.errorCode)
    assertEquals(true, core.getPrivateField("desiredPaused"))
    assertEquals(true, core.getPrivateField("cachedPaused"))
    assertEquals(true, core.getPrivateField("resumeBlockedByPublicPause"))
    assertEquals(false, core.getPrivateField("pausedForSurfaceLoss"))
    assertEquals(false, core.getPrivateField("deferredResumeRequested"))
    assertFalse(awaitPauseWriteCount(writes, 1))
    core.dispose()
  }

  @Test
  fun reusedAutoplayFallbackClearsIntentBeforeLoadWithoutLatePausePropertyWrite() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val writes = ConcurrentLinkedQueue<Pair<String, String>>()
    val core = MpvPlayerCore(activity, true) { name, value -> writes += name to value }
    core.setPrivateField("desiredPaused", true)
    core.setPrivateField("cachedPaused", true)
    core.setPrivateField("resumeBlockedByPublicPause", true)
    val plugin = reusedFallbackPlugin(activity, core)
    val result = RecordingResult()

    plugin.onMethodCall(
      MethodCall(
        "open",
        mapOf("uri" to "https://example.test/video.mkv", "autoPlay" to true)
      ),
      result
    )
    awaitCompletion(result)

    assertEquals(1, result.completionCount)
    assertNull(result.errorCode)
    assertEquals(false, core.getPrivateField("desiredPaused"))
    assertEquals(false, core.getPrivateField("cachedPaused"))
    assertEquals(false, core.getPrivateField("resumeBlockedByPublicPause"))
    assertFalse(awaitPauseWriteCount(writes, 1))
    assertEquals(emptyList<Pair<String, String>>(), writes.filter { it.first == "pause" })
    core.dispose()
  }

  @Test
  fun mpvFallbackLoadsSharedSubtitleContainerOnce() {
    val plugin = ExoPlayerPlugin()
    val options = mutableListOf<String>()
    val appendOptions = plugin.javaClass.getDeclaredMethod(
      "appendExternalSubtitleOptions",
      MutableList::class.java,
      List::class.java
    ).apply {
      isAccessible = true
    }

    appendOptions.invoke(
      plugin,
      options,
      listOf(
        mapOf("uri" to "shared.mkv", "isContainer" to true),
        mapOf("uri" to "shared.mkv", "isContainer" to true),
        mapOf("uri" to "")
      )
    )

    assertEquals(listOf("sub-files=%10%shared.mkv"), options)
  }

  @Test
  fun configDetachAndEngineDetachReleaseExoActivityOwnershipExactlyOnce() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    activity.setContentView(FrameLayout(activity))
    val content = activity.findViewById<ViewGroup>(android.R.id.content)
    val container = FrameLayout(activity)
    content.addView(container)
    var layoutCallbacks = 0
    val listener = ViewTreeObserver.OnGlobalLayoutListener { layoutCallbacks++ }
    content.viewTreeObserver.addOnGlobalLayoutListener(listener)
    val core = ExoPlayerCore(activity)
    core.setPrivateField("surfaceContainer", container)
    core.setPrivateField("overlayLayoutListener", listener)
    val plugin = ExoPlayerPlugin()
    setField(plugin, "activity", activity)
    setField(plugin, "playerCore", core)
    setField(plugin, "usingMpvFallback", true)
    setField(plugin, "fallbackInProgress", true)
    setField(plugin, "currentExternalSubtitles", listOf(mapOf("uri" to "content://subtitle")))
    @Suppress("UNCHECKED_CAST")
    (getField(plugin, "pendingMpvProperties") as MutableMap<String, String>)["pause"] = "yes"

    plugin.onDetachedFromActivityForConfigChanges()
    content.viewTreeObserver.dispatchOnGlobalLayout()
    shadowOf(Looper.getMainLooper()).idle()
    plugin.onDetachedFromEngine(pluginBinding(activity))

    assertEquals(0, layoutCallbacks)
    assertNull(container.parent)
    assertNull(getField(plugin, "playerCore"))
    assertNull(getField(plugin, "mpvCore"))
    assertFalse(getField(plugin, "usingMpvFallback") as Boolean)
    assertFalse(getField(plugin, "fallbackInProgress") as Boolean)
    assertNull(getField(plugin, "currentExternalSubtitles"))
    assertTrue((getField(plugin, "pendingMpvProperties") as Map<*, *>).isEmpty())
    assertNull(getField(plugin, "activity"))
  }

  @Test
  fun engineDetachReleasesPublishedMpvFallbackActivityOwnership() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    activity.setContentView(FrameLayout(activity))
    val content = activity.findViewById<ViewGroup>(android.R.id.content)
    val container = FrameLayout(activity)
    content.addView(container)
    var layoutCallbacks = 0
    val listener = ViewTreeObserver.OnGlobalLayoutListener { layoutCallbacks++ }
    content.viewTreeObserver.addOnGlobalLayoutListener(listener)
    val core = MpvPlayerCore(activity)
    core.setPrivateField("surfaceContainer", container)
    core.setPrivateField("overlayLayoutListener", listener)
    val plugin = ExoPlayerPlugin()
    setField(plugin, "activity", activity)
    setField(plugin, "mpvCore", core)
    setField(plugin, "usingMpvFallback", true)

    plugin.onDetachedFromEngine(pluginBinding(activity))
    shadowOf(Looper.getMainLooper()).idle()
    content.viewTreeObserver.dispatchOnGlobalLayout()

    assertEquals(0, layoutCallbacks)
    assertNull(container.parent)
    assertNull(getField(plugin, "mpvCore"))
    assertFalse(getField(plugin, "usingMpvFallback") as Boolean)
    assertTrue(core.getPrivateField("disposing") as Boolean)
  }

  @Test
  fun configDetachRejectsQueuedInitializationFromOldActivityGeneration() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    activity.setContentView(FrameLayout(activity))
    val plugin = ExoPlayerPlugin()
    setField(plugin, "activity", activity)
    val result = RecordingResult()

    Thread {
      plugin.onMethodCall(MethodCall("initialize", emptyMap<String, Any?>()), result)
    }.apply {
      start()
      join()
    }
    plugin.onDetachedFromActivityForConfigChanges()
    shadowOf(Looper.getMainLooper()).idle()

    assertEquals(false, result.successValue)
    assertEquals(1, result.completionCount)
    assertNull(getField(plugin, "playerCore"))
    assertNull(getField(plugin, "activity"))
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

  private fun initialFallbackPlugin(
    activity: Activity,
    core: MpvPlayerCore
  ): ExoPlayerPlugin = ExoPlayerPlugin().also { plugin ->
    setField(plugin, "activity", activity)
    setField(plugin, "mpvCore", core)
    setField(plugin, "usingMpvFallback", true)
  }

  private fun reusedFallbackPlugin(
    activity: Activity,
    core: MpvPlayerCore
  ): ExoPlayerPlugin = ExoPlayerPlugin().also { plugin ->
    setField(plugin, "activity", activity)
    setField(plugin, "mpvCore", core)
    setField(plugin, "usingMpvFallback", true)
  }

  private fun invokeSetupMpvFallback(
    plugin: ExoPlayerPlugin,
    core: MpvPlayerCore,
    playWhenReady: Boolean
  ) {
    core.setPauseIntentForLoad(paused = !playWhenReady)
    ExoPlayerPlugin::class.java.getDeclaredMethod(
      "prepareMpvFallback",
      MpvPlayerCore::class.java
    ).apply {
      isAccessible = true
      invoke(plugin, core)
    }
  }

  private fun testAudioFocusManager(
    activity: Activity,
    core: MpvPlayerCore
  ): AudioFocusManager = AudioFocusManager(
    context = activity,
    handler = Handler(Looper.getMainLooper()),
    onPause = {
      MpvPlayerCore::class.java.getDeclaredMethod("pauseForAudioFocusLoss").apply {
        isAccessible = true
        invoke(core)
      }
    },
    onResume = {
      MpvPlayerCore::class.java.getDeclaredMethod(
        "resumeAfterAudioFocusGain",
        String::class.java
      ).apply {
        isAccessible = true
        invoke(core, "audio focus gain")
      }
    },
    isPaused = { core.getPrivateField("desiredPaused") as Boolean }
  )

  private fun dispatchAudioFocusChange(manager: AudioFocusManager, focusChange: Int) {
    val listener = AudioFocusManager::class.java.getDeclaredField("audioFocusChangeListener").run {
      isAccessible = true
      get(manager) as AudioManager.OnAudioFocusChangeListener
    }
    listener.onAudioFocusChange(focusChange)
  }

  private fun setNextAudioFocusRequestResponse(manager: AudioFocusManager, response: Int) {
    val audioManager = AudioFocusManager::class.java.getDeclaredField("audioManager").run {
      isAccessible = true
      get(manager) as AudioManager
    }
    shadowOf(audioManager).setNextFocusRequestResponse(response)
  }

  private fun invokeAutoResume(core: MpvPlayerCore, reason: String) {
    MpvPlayerCore::class.java.getDeclaredMethod("requestAutoResume", String::class.java).apply {
      isAccessible = true
      invoke(core, reason)
    }
  }

  private fun awaitQueueEntry(
    queue: ConcurrentLinkedQueue<Pair<String, String>>,
    expected: Pair<String, String>
  ): Boolean {
    repeat(100) {
      shadowOf(Looper.getMainLooper()).idle()
      if (queue.contains(expected)) return true
      Thread.sleep(10)
    }
    return false
  }

  private fun awaitPauseWriteCount(
    queue: ConcurrentLinkedQueue<Pair<String, String>>,
    expectedCount: Int
  ): Boolean {
    repeat(100) {
      shadowOf(Looper.getMainLooper()).idle()
      if (queue.count { it.first == "pause" } >= expectedCount) return true
      Thread.sleep(10)
    }
    return false
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

  private fun Any.setPrivateField(name: String, value: Any?) {
    javaClass.getDeclaredField(name).apply {
      isAccessible = true
      set(this@setPrivateField, value)
    }
  }

  private fun Any.getPrivateField(name: String): Any? = javaClass.getDeclaredField(name).run {
    isAccessible = true
    get(this@getPrivateField)
  }

  private fun pluginBinding(activity: Activity): FlutterPlugin.FlutterPluginBinding {
    val constructor = FlutterPlugin.FlutterPluginBinding::class.java.constructors.single()
    return constructor.newInstance(activity, null, null, null, null, null, null) as FlutterPlugin.FlutterPluginBinding
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
    val successValues = mutableListOf<Any?>()
    val eventNames: List<String>
      get() = successValues.mapNotNull { event ->
        val envelope = event as? Map<*, *> ?: return@mapNotNull null
        if (envelope["type"] == "event") envelope["name"] as? String else null
      }

    override fun success(event: Any?) {
      successValue = event
      successValues += event
    }

    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) = Unit

    override fun endOfStream() = Unit
  }
}

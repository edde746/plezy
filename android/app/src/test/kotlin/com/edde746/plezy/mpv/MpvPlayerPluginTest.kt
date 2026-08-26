package com.edde746.plezy.mpv

import android.app.Activity
import android.media.AudioManager
import android.os.Handler
import android.os.Looper
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.widget.FrameLayout
import com.edde746.plezy.shared.AudioFocusManager
import dev.jdtech.mpv.EndFileReason
import dev.jdtech.mpv.LogLevel
import dev.jdtech.mpv.LogMessage
import dev.jdtech.mpv.MpvEvent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.CancellationException
import java.util.concurrent.ConcurrentLinkedQueue
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import kotlinx.coroutines.suspendCancellableCoroutine
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
  fun audioSpdifCodecsWithoutContextAnswersEmptySoMpvDecodes() {
    // mpv force-passthroughs every codec named in audio-spdif with no decode fallback, so
    // with no context to inspect the audio route the only safe answer is "" (#1703, #1991).
    val result = RecordingResult()

    MpvPlayerPlugin().onMethodCall(MethodCall("getAudioSpdifCodecs", null), result)

    assertEquals("", result.successValue)
    assertNull(result.errorCode)
    assertEquals(1, result.completionCount)
  }

  @Test
  fun hardwareDecodeSessionsUseTheMediaCodecVoWithGpuFallback() {
    // Rationale on MpvPlayerCore.initialVideoOutput.
    assertEquals("mediacodec,gpu", MpvPlayerCore.initialVideoOutput(hardwareDecoding = true))
    assertEquals("gpu,gpu-next", MpvPlayerCore.initialVideoOutput(hardwareDecoding = false))
  }

  @Test
  fun hdrSurfaceIsWantedOnlyForPqAndHlgTransfers() {
    // Rationale on MpvPlayerCore.wantsHdrSurface: both render into a PQ
    // target; anything else stays on the sRGB surface, which renders every
    // content correctly.
    assertTrue(MpvPlayerCore.wantsHdrSurface("smpte2084"))
    assertTrue(MpvPlayerCore.wantsHdrSurface("arib-std-b67"))
    assertFalse(MpvPlayerCore.wantsHdrSurface("bt709"))
    assertFalse(MpvPlayerCore.wantsHdrSurface("bt1886"))
    assertFalse(MpvPlayerCore.wantsHdrSurface("unknown"))
    assertFalse(MpvPlayerCore.wantsHdrSurface(""))
    assertFalse(MpvPlayerCore.wantsHdrSurface(null))
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
  fun rejectedSetPropertyReportsBoundedErrorForVideoAndAudio() {
    for (plugin in listOf(MpvPlayerPlugin(), MpvAudioPlayerPlugin())) {
      installCore(plugin, testCore { _, _ -> error("secret-property-value") })
      val result = RecordingResult()

      plugin.onMethodCall(propertyCall(), result)
      awaitCompletion(result)

      assertEquals(1, result.completionCount)
      assertEquals("SET_PROPERTY_FAILED", result.errorCode)
      assertEquals("MPV property write was rejected", result.errorMessage)
      assertTrue(result.errorMessage?.contains("secret-property-value") == false)
      assertNull(result.errorDetails)
      assertNull(result.successValue)
    }
  }

  @Test
  fun cancelledSetPropertyReportsNotInitializedOnceForVideoAndAudio() {
    for (plugin in listOf(MpvPlayerPlugin(), MpvAudioPlayerPlugin())) {
      installCore(plugin, testCore { _, _ -> throw CancellationException("secret-cancellation") })
      val result = RecordingResult()

      plugin.onMethodCall(propertyCall(), result)
      awaitCompletion(result)

      assertEquals(1, result.completionCount)
      assertEquals("NOT_INITIALIZED", result.errorCode)
      assertTrue(result.errorMessage?.contains("secret-cancellation") == false)
      assertEquals("Player not initialized", result.errorMessage)
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
    assertTrue(outcome?.exceptionOrNull() is CancellationException)
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
    assertTrue(outcomes.all { it.exceptionOrNull() is CancellationException })
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
  fun failedResumeRestoresThePreviousPublicPauseIntent() {
    val core = testCore { _, _ -> error("rejected") }
    setBoolean(core, "cachedPaused", true)
    setBoolean(core, "resumeBlockedByPublicPause", true)
    var outcome: Result<Unit>? = null

    core.setProperty("pause", "no") { outcome = it }
    awaitCondition { outcome != null }

    assertTrue(outcome?.isFailure == true)
    assertEquals(true, getBoolean(core, "cachedPaused"))
    assertEquals(true, getBoolean(core, "resumeBlockedByPublicPause"))
  }

  @Test
  fun failedOlderPauseWriteDoesNotRollbackANewerResumeIntent() {
    val firstStarted = CountDownLatch(1)
    val releaseFirst = CountDownLatch(1)
    val writes = AtomicInteger()
    val core = testCore { _, _ ->
      if (writes.incrementAndGet() == 1) {
        firstStarted.countDown()
        releaseFirst.await(1, TimeUnit.SECONDS)
        error("rejected")
      }
    }
    var firstOutcome: Result<Unit>? = null
    var secondOutcome: Result<Unit>? = null

    core.setProperty("pause", "yes") { firstOutcome = it }
    assertTrue(firstStarted.await(1, TimeUnit.SECONDS))
    core.setProperty("pause", "no") { secondOutcome = it }
    releaseFirst.countDown()
    awaitCondition { firstOutcome != null && secondOutcome != null }

    assertTrue(firstOutcome?.isFailure == true)
    assertTrue(secondOutcome?.isSuccess == true)
    assertEquals(2, writes.get())
    assertEquals(false, getBoolean(core, "cachedPaused"))
    assertEquals(false, getBoolean(core, "resumeBlockedByPublicPause"))
  }

  @Test
  fun pauseIntentBlocksAudioFocusAutoResumeBeforeNativeWriteCompletes() {
    val writeStarted = CountDownLatch(1)
    val releaseWrite = CountDownLatch(1)
    val writes = AtomicInteger()
    val unexpectedResumeWrite = CountDownLatch(1)
    val core = testCore { name, value ->
      if (writes.incrementAndGet() > 1) unexpectedResumeWrite.countDown()
      if (name == "pause" && value == "yes") {
        writeStarted.countDown()
        releaseWrite.await(1, TimeUnit.SECONDS)
      }
    }
    setBoolean(core, "resumeBlockedByPublicPause", false)
    var outcome: Result<Unit>? = null

    core.setProperty("pause", "yes") { outcome = it }
    assertTrue(writeStarted.await(1, TimeUnit.SECONDS))
    invokeAutoResume(core, "audio focus gain")

    assertEquals(true, getBoolean(core, "resumeBlockedByPublicPause"))
    assertNull(outcome)
    assertEquals(1, writes.get())

    releaseWrite.countDown()
    awaitCondition { outcome != null }
    assertFalse(unexpectedResumeWrite.await(100, TimeUnit.MILLISECONDS))
    assertTrue(outcome?.isSuccess == true)
    assertEquals(1, writes.get())
    assertEquals(true, getBoolean(core, "resumeBlockedByPublicPause"))
  }

  @Test
  fun heldLoadPauseIntentSynchronouslyBlocksFocusAndSurfaceAutoResumeWithoutNativeWrite() {
    val writes = ConcurrentLinkedQueue<Pair<String, String>>()
    val core = testVideoCore { name, value -> writes += name to value }
    setBoolean(core, "desiredPaused", false)
    setBoolean(core, "cachedPaused", false)
    setBoolean(core, "resumeBlockedByPublicPause", false)
    setBoolean(core, "pausedForSurfaceLoss", true)
    setBoolean(core, "pausedForAudioFocusLoss", true)
    setBoolean(core, "deferredResumeRequested", true)

    core.setPauseIntentForLoad(paused = true)
    invokeAutoResume(core, "audio focus gain")
    invokeAutoResume(core, "surface attached")

    assertEquals(true, getBoolean(core, "desiredPaused"))
    assertEquals(true, getBoolean(core, "cachedPaused"))
    assertEquals(true, getBoolean(core, "resumeBlockedByPublicPause"))
    assertEquals(false, getBoolean(core, "pausedForSurfaceLoss"))
    assertEquals(false, getBoolean(core, "pausedForAudioFocusLoss"))
    assertEquals(false, getBoolean(core, "deferredResumeRequested"))
    assertFalse(awaitQueueEntry(writes, "pause" to "no"))
    assertTrue(writes.isEmpty())
  }

  @Test
  fun autoplayLoadIntentClearsPublicPauseBlockWithoutPrematureNativeResumeWrite() {
    val writes = ConcurrentLinkedQueue<Pair<String, String>>()
    val core = testCore { name, value -> writes += name to value }
    setBoolean(core, "desiredPaused", true)
    setBoolean(core, "cachedPaused", true)
    setBoolean(core, "resumeBlockedByPublicPause", true)

    core.setPauseIntentForLoad(paused = false)

    assertEquals(false, getBoolean(core, "desiredPaused"))
    assertEquals(false, getBoolean(core, "cachedPaused"))
    assertEquals(false, getBoolean(core, "resumeBlockedByPublicPause"))
    assertFalse(awaitQueueEntry(writes, "pause" to "no"))

    invokeAudioFocusPause(core)
    assertTrue(awaitQueueEntry(writes, "pause" to "yes"))
    assertEquals(listOf("pause" to "yes"), writes.toList())
  }

  @Test
  fun activeFocusLossExplicitResumeReacquiresFocusAndWritesOnce() {
    val writes = ConcurrentLinkedQueue<Pair<String, String>>()
    val focusResumeCallbacks = AtomicInteger()
    val completionCount = AtomicInteger()
    val core = testCore { name, value -> writes += name to value }
    val focusManager = testAudioFocusManager(core, focusResumeCallbacks)
    setCoreField(core, "audioFocusManager", focusManager)
    setBoolean(core, "desiredPaused", false)
    setBoolean(core, "cachedPaused", false)

    dispatchAudioFocusChange(focusManager, AudioManager.AUDIOFOCUS_LOSS)
    awaitCondition { writes.count { it == "pause" to "yes" } == 1 }
    assertEquals(true, getBoolean(core, "pausedForAudioFocusLoss"))
    setNextAudioFocusRequestResponse(focusManager, AudioManager.AUDIOFOCUS_REQUEST_GRANTED)

    var outcome: Result<Unit>? = null
    core.setProperty("pause", "no") {
      completionCount.incrementAndGet()
      outcome = it
    }
    awaitCondition { outcome != null }

    assertTrue(outcome?.isSuccess == true)
    assertEquals(1, completionCount.get())
    assertEquals(listOf("pause" to "yes", "pause" to "no"), writes.toList())
    assertEquals(1, writes.count { it == "pause" to "no" })
    assertEquals(false, getBoolean(core, "pausedForAudioFocusLoss"))
    assertEquals(false, getBoolean(core, "deferredResumeRequested"))
    assertEquals(false, getBoolean(core, "cachedPaused"))
  }

  @Test
  fun deniedExplicitResumeFocusRequestCompletesWithoutWriting() {
    val writes = ConcurrentLinkedQueue<Pair<String, String>>()
    val focusResumeCallbacks = AtomicInteger()
    val core = testCore { name, value -> writes += name to value }
    val focusManager = testAudioFocusManager(core, focusResumeCallbacks)
    val plugin = MpvAudioPlayerPlugin()
    setCoreField(core, "audioFocusManager", focusManager)
    installCore(plugin, core)
    setBoolean(core, "desiredPaused", false)
    setBoolean(core, "cachedPaused", false)

    dispatchAudioFocusChange(focusManager, AudioManager.AUDIOFOCUS_LOSS_TRANSIENT)
    awaitCondition { writes.contains("pause" to "yes") }
    assertEquals(true, getBoolean(core, "pausedForAudioFocusLoss"))

    val coreCompletionCount = AtomicInteger()
    var coreOutcome: Result<Unit>? = null
    setNextAudioFocusRequestResponse(focusManager, AudioManager.AUDIOFOCUS_REQUEST_FAILED)
    core.setProperty("pause", "no") {
      coreCompletionCount.incrementAndGet()
      coreOutcome = it
    }
    awaitCondition { coreOutcome != null }

    assertTrue(coreOutcome?.isSuccess == true)
    assertEquals(1, coreCompletionCount.get())
    assertEquals(0, writes.count { it == "pause" to "no" })
    assertEquals(true, getBoolean(core, "pausedForAudioFocusLoss"))
    assertEquals(true, getBoolean(core, "cachedPaused"))
    assertEquals(false, getBoolean(core, "desiredPaused"))
    assertEquals(false, getBoolean(core, "resumeBlockedByPublicPause"))

    setNextAudioFocusRequestResponse(focusManager, AudioManager.AUDIOFOCUS_REQUEST_FAILED)
    val denied = RecordingResult()
    plugin.onMethodCall(
      MethodCall("setProperty", mapOf("name" to "pause", "value" to "no")),
      denied
    )
    awaitCompletion(denied)

    assertEquals(1, denied.completionCount)
    assertNull(denied.errorCode)
    assertEquals(0, writes.count { it == "pause" to "no" })
    assertEquals(true, getBoolean(core, "pausedForAudioFocusLoss"))

    setNextAudioFocusRequestResponse(focusManager, AudioManager.AUDIOFOCUS_REQUEST_GRANTED)
    val retry = RecordingResult()
    plugin.onMethodCall(
      MethodCall("setProperty", mapOf("name" to "pause", "value" to "no")),
      retry
    )
    awaitCompletion(retry)

    assertEquals(1, retry.completionCount)
    assertNull(retry.errorCode)
    assertEquals(1, writes.count { it == "pause" to "no" })
    assertEquals(false, getBoolean(core, "pausedForAudioFocusLoss"))
    assertEquals(false, getBoolean(core, "cachedPaused"))
  }

  @Test
  fun delayedFocusGainAfterExplicitResumeDoesNotWriteAgain() {
    val writes = ConcurrentLinkedQueue<Pair<String, String>>()
    val explicitResumeStarted = CountDownLatch(1)
    val releaseExplicitResume = CountDownLatch(1)
    val duplicateResume = CountDownLatch(1)
    val resumeWrites = AtomicInteger()
    val focusResumeCallbacks = AtomicInteger()
    val core = testCore { name, value ->
      writes += name to value
      if (name == "pause" && value == "no") {
        if (resumeWrites.incrementAndGet() == 1) {
          explicitResumeStarted.countDown()
          releaseExplicitResume.await(1, TimeUnit.SECONDS)
        } else {
          duplicateResume.countDown()
        }
      }
    }
    val focusManager = testAudioFocusManager(core, focusResumeCallbacks)
    setCoreField(core, "audioFocusManager", focusManager)
    setBoolean(core, "desiredPaused", false)
    setBoolean(core, "cachedPaused", false)

    dispatchAudioFocusChange(focusManager, AudioManager.AUDIOFOCUS_LOSS)
    awaitCondition { writes.contains("pause" to "yes") }
    setNextAudioFocusRequestResponse(focusManager, AudioManager.AUDIOFOCUS_REQUEST_GRANTED)
    var outcome: Result<Unit>? = null
    core.setProperty("pause", "no") { outcome = it }
    assertTrue(explicitResumeStarted.await(1, TimeUnit.SECONDS))
    assertEquals(false, getBoolean(core, "pausedForAudioFocusLoss"))

    dispatchAudioFocusChange(focusManager, AudioManager.AUDIOFOCUS_GAIN)
    assertEquals(1, focusResumeCallbacks.get())
    releaseExplicitResume.countDown()
    awaitCondition { outcome != null }

    shadowOf(Looper.getMainLooper()).idle()
    assertFalse(duplicateResume.await(100, TimeUnit.MILLISECONDS))
    assertTrue(outcome?.isSuccess == true)
    assertEquals(1, resumeWrites.get())
    assertEquals(listOf("pause" to "yes", "pause" to "no"), writes.toList())
  }

  @Test
  fun freshFocusLossAfterExplicitClaimPreventsThePendingResumeWrite() {
    val writes = ConcurrentLinkedQueue<Pair<String, String>>()
    val blockerStarted = CountDownLatch(1)
    val releaseBlocker = CountDownLatch(1)
    val focusResumeCallbacks = AtomicInteger()
    val core = testCore { name, value ->
      writes += name to value
      if (name == "block") {
        blockerStarted.countDown()
        releaseBlocker.await(1, TimeUnit.SECONDS)
      }
    }
    val focusManager = testAudioFocusManager(core, focusResumeCallbacks)
    setCoreField(core, "audioFocusManager", focusManager)
    setBoolean(core, "desiredPaused", false)
    setBoolean(core, "cachedPaused", false)

    dispatchAudioFocusChange(focusManager, AudioManager.AUDIOFOCUS_LOSS)
    awaitCondition { writes.count { it == "pause" to "yes" } == 1 }
    var blockerOutcome: Result<Unit>? = null
    core.setProperty("block", "value") { blockerOutcome = it }
    assertTrue(blockerStarted.await(1, TimeUnit.SECONDS))

    setNextAudioFocusRequestResponse(focusManager, AudioManager.AUDIOFOCUS_REQUEST_GRANTED)
    val resumeCompletionCount = AtomicInteger()
    var resumeOutcome: Result<Unit>? = null
    core.setProperty("pause", "no") {
      resumeCompletionCount.incrementAndGet()
      resumeOutcome = it
    }
    assertEquals(false, getBoolean(core, "pausedForAudioFocusLoss"))

    dispatchAudioFocusChange(focusManager, AudioManager.AUDIOFOCUS_LOSS_TRANSIENT)
    assertEquals(true, getBoolean(core, "pausedForAudioFocusLoss"))
    releaseBlocker.countDown()
    awaitCondition {
      blockerOutcome != null &&
        resumeOutcome != null &&
        writes.count { it == "pause" to "yes" } == 2
    }

    assertTrue(blockerOutcome?.isSuccess == true)
    assertTrue(resumeOutcome?.isSuccess == true)
    assertEquals(1, resumeCompletionCount.get())
    assertEquals(0, writes.count { it == "pause" to "no" })
    assertEquals(true, getBoolean(core, "pausedForAudioFocusLoss"))
    assertEquals(true, getBoolean(core, "cachedPaused"))
  }

  @Test
  fun explicitVideoResumeAfterFocusLossRemainsDeferredOnlyForSurface() {
    val writes = ConcurrentLinkedQueue<Pair<String, String>>()
    val focusResumeCallbacks = AtomicInteger()
    val completionCount = AtomicInteger()
    val core = testVideoCore { name, value -> writes += name to value }
    val focusManager = testAudioFocusManager(core, focusResumeCallbacks)
    setCoreField(core, "audioFocusManager", focusManager)
    setBoolean(core, "desiredPaused", false)
    setBoolean(core, "cachedPaused", false)

    dispatchAudioFocusChange(focusManager, AudioManager.AUDIOFOCUS_LOSS)
    awaitCondition { writes.contains("pause" to "yes") }
    setNextAudioFocusRequestResponse(focusManager, AudioManager.AUDIOFOCUS_REQUEST_GRANTED)
    var outcome: Result<Unit>? = null
    core.setProperty("pause", "no") {
      completionCount.incrementAndGet()
      outcome = it
    }
    awaitCondition { outcome != null }

    assertTrue(outcome?.isSuccess == true)
    assertEquals(1, completionCount.get())
    assertEquals(listOf("pause" to "yes"), writes.toList())
    assertEquals(false, getBoolean(core, "pausedForAudioFocusLoss"))
    assertEquals(true, getBoolean(core, "deferredResumeRequested"))
    assertEquals(true, getBoolean(core, "cachedPaused"))
  }

  @Test
  fun pausedFocusLossAndGainWithoutResumeCallbackAllowsOneExplicitResume() {
    val writes = ConcurrentLinkedQueue<Pair<String, String>>()
    val focusResumeCallbacks = AtomicInteger()
    val core = testCore { name, value -> writes += name to value }
    val focusManager = testAudioFocusManager(core, focusResumeCallbacks)
    var pauseOutcome: Result<Unit>? = null
    var resumeOutcome: Result<Unit>? = null

    core.setProperty("pause", "yes") { pauseOutcome = it }
    awaitCondition { pauseOutcome != null }

    dispatchAudioFocusChange(focusManager, AudioManager.AUDIOFOCUS_LOSS_TRANSIENT)
    assertEquals(false, getBoolean(core, "pausedForAudioFocusLoss"))
    dispatchAudioFocusChange(focusManager, AudioManager.AUDIOFOCUS_GAIN)
    assertEquals(0, focusResumeCallbacks.get())

    core.setProperty("pause", "no") { resumeOutcome = it }
    awaitCondition { resumeOutcome != null }

    assertTrue(pauseOutcome?.isSuccess == true)
    assertTrue(resumeOutcome?.isSuccess == true)
    assertEquals(listOf("pause" to "yes", "pause" to "no"), writes.toList())
    assertEquals(1, writes.count { it == "pause" to "no" })
    assertEquals(false, getBoolean(core, "pausedForAudioFocusLoss"))
  }

  @Test
  fun synchronousFocusReacquisitionClearsLossMarkerAndResumesOnce() {
    val writes = ConcurrentLinkedQueue<Pair<String, String>>()
    val focusResumeCallbacks = AtomicInteger()
    val core = testCore { name, value -> writes += name to value }
    val focusManager = testAudioFocusManager(core, focusResumeCallbacks)
    setCoreField(core, "audioFocusManager", focusManager)
    setBoolean(core, "desiredPaused", false)
    setBoolean(core, "cachedPaused", false)

    dispatchAudioFocusChange(focusManager, AudioManager.AUDIOFOCUS_LOSS)
    awaitCondition { writes.contains("pause" to "yes") }
    assertEquals(true, getBoolean(core, "pausedForAudioFocusLoss"))

    assertTrue(core.requestAudioFocus())
    awaitCondition { writes.count { it == "pause" to "no" } == 1 }

    assertEquals(0, focusResumeCallbacks.get())
    assertEquals(listOf("pause" to "yes", "pause" to "no"), writes.toList())
    assertEquals(false, getBoolean(core, "pausedForAudioFocusLoss"))
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
  fun configDetachThenEngineDetachTearsDownVideoCoreAndPendingInitOnce() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    activity.setContentView(FrameLayout(activity))
    val content = activity.findViewById<ViewGroup>(android.R.id.content)
    val container = FrameLayout(activity)
    content.addView(container)
    var layoutCallbacks = 0
    val listener = ViewTreeObserver.OnGlobalLayoutListener { layoutCallbacks++ }
    content.viewTreeObserver.addOnGlobalLayoutListener(listener)
    val core = MpvPlayerCore(activity)
    setCoreField(core, "surfaceContainer", container)
    setCoreField(core, "overlayLayoutListener", listener)
    val plugin = MpvPlayerPlugin()
    installCore(plugin, core)
    setPluginField(plugin, "activity", activity)
    val pendingResult = RecordingResult()
    pendingInitResults(plugin) += pendingResult
    setPluginField(plugin, "isInitializing", true)
    setPluginField(plugin, "activeInitAttempt", 7)
    setPluginField(plugin, "initAttemptCounter", 7)

    plugin.onDetachedFromActivityForConfigChanges()
    shadowOf(Looper.getMainLooper()).idle()
    plugin.onDetachedFromEngine(pluginBinding(activity))
    content.viewTreeObserver.dispatchOnGlobalLayout()

    assertEquals(false, pendingResult.successValue)
    assertEquals(1, pendingResult.completionCount)
    assertEquals(0, layoutCallbacks)
    assertNull(container.parent)
    assertNull(getPluginField(plugin, "playerCore"))
    assertNull(getPluginField(plugin, "activity"))
    assertTrue(getCoreField(core, "disposing") as Boolean)
    assertFalse(getPluginField(plugin, "isInitializing") as Boolean)
  }

  @Test
  fun staleInitCompletionCannotConsumeReplacementAttemptResults() {
    val plugin = MpvPlayerPlugin()
    val stale = RecordingResult()
    pendingInitResults(plugin) += stale
    setPluginField(plugin, "isInitializing", true)
    setPluginField(plugin, "activeInitAttempt", 1)
    setPluginField(plugin, "initAttemptCounter", 1)

    plugin.onDetachedFromActivityForConfigChanges()
    assertEquals(false, stale.successValue)
    assertEquals(1, stale.completionCount)

    val replacement = RecordingResult()
    pendingInitResults(plugin) += replacement
    setPluginField(plugin, "isInitializing", true)
    setPluginField(plugin, "activeInitAttempt", 3)
    setPluginField(plugin, "initAttemptCounter", 3)

    plugin.completePendingInits(1, success = true)
    assertEquals(0, replacement.completionCount)

    plugin.completePendingInits(3, success = true)
    assertEquals(true, replacement.successValue)
    assertEquals(1, replacement.completionCount)
  }

  @Test
  fun engineDetachAlsoTerminatesApplicationContextAudioCore() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val plugin = MpvAudioPlayerPlugin()
    val core = testCore { _, _ -> Unit }
    installCore(plugin, core)

    plugin.onDetachedFromEngine(pluginBinding(activity))

    assertNull(getPluginField(plugin, "playerCore"))
    assertTrue(getCoreField(core, "disposing") as Boolean)
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

  @Suppress("UNCHECKED_CAST")
  private fun pendingInitResults(plugin: MpvPlayerPlugin): MutableList<MethodChannel.Result> = getPluginField(plugin, "pendingInitResults") as MutableList<MethodChannel.Result>

  private fun setPluginField(plugin: MpvPlayerPlugin, name: String, value: Any?) {
    MpvPlayerPlugin::class.java.getDeclaredField(name).apply {
      isAccessible = true
      set(plugin, value)
    }
  }

  private fun getPluginField(plugin: MpvPlayerPlugin, name: String): Any? = MpvPlayerPlugin::class.java.getDeclaredField(name).run {
    isAccessible = true
    get(plugin)
  }

  private fun setCoreField(core: MpvPlayerCore, name: String, value: Any?) {
    MpvPlayerCore::class.java.getDeclaredField(name).apply {
      isAccessible = true
      set(core, value)
    }
  }

  private fun getCoreField(core: MpvPlayerCore, name: String): Any? = MpvPlayerCore::class.java.getDeclaredField(name).run {
    isAccessible = true
    get(core)
  }

  private fun pluginBinding(activity: Activity): FlutterPlugin.FlutterPluginBinding {
    val constructor = FlutterPlugin.FlutterPluginBinding::class.java.constructors.single()
    return constructor.newInstance(activity, null, null, null, null, null, null) as FlutterPlugin.FlutterPluginBinding
  }

  private fun testAudioFocusManager(
    core: MpvPlayerCore,
    resumeCallbacks: AtomicInteger
  ): AudioFocusManager = AudioFocusManager(
    context = Robolectric.buildActivity(Activity::class.java).setup().get(),
    handler = Handler(Looper.getMainLooper()),
    onPause = { invokeAudioFocusPause(core) },
    onResume = {
      resumeCallbacks.incrementAndGet()
      invokeAudioFocusResume(core, "audio focus gain")
    },
    isPaused = { getBoolean(core, "desiredPaused") }
  )

  private fun invokeAudioFocusPause(core: MpvPlayerCore) {
    MpvPlayerCore::class.java.getDeclaredMethod("pauseForAudioFocusLoss").apply {
      isAccessible = true
      invoke(core)
    }
  }

  private fun invokeAudioFocusResume(core: MpvPlayerCore, reason: String) {
    MpvPlayerCore::class.java.getDeclaredMethod(
      "resumeAfterAudioFocusGain",
      String::class.java
    ).apply {
      isAccessible = true
      invoke(core, reason)
    }
  }

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

  private fun invokeSetGpuVoRequirement(core: MpvPlayerCore, reason: String, active: Boolean) {
    MpvPlayerCore::class.java
      .getDeclaredMethod("setGpuVoRequirement", String::class.java, Boolean::class.javaPrimitiveType)
      .apply {
        isAccessible = true
        invoke(core, reason, active)
      }
  }

  @Test
  fun voTargetFollowsTheActiveReasonSet() {
    // Reason precedence through the real property-write path: DV reshaping
    // outranks HDR-on-SDR, dropping the winner falls back to the reason still
    // active, and dropping the last one returns the session to the plane.
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val writes = ConcurrentLinkedQueue<Pair<String, String>>()
    val core = MpvPlayerCore(activity, audioOnly = false, propertyWriter = { name, value ->
      writes.add(name to value)
    })
    setBoolean(core, "isInitialized", true)

    fun lastVo(): String? = writes.toList().lastOrNull { it.first == "vo" }?.second

    // HDR-on-SDR raises first, then the DV router wins the arbitration.
    invokeSetGpuVoRequirement(core, GpuVoPolicy.REASON_HDR_SDR, true)
    invokeSetGpuVoRequirement(core, GpuVoPolicy.REASON_DV_RESHAPE, true)
    awaitCondition { lastVo() == "gpu-next" }
    assertEquals("gpu-next", lastVo())

    // Dropping the winning reason must fall back to the one still active,
    // not to the plane.
    invokeSetGpuVoRequirement(core, GpuVoPolicy.REASON_DV_RESHAPE, false)
    awaitCondition { lastVo() == "gpu" }
    assertEquals("gpu", lastVo())

    // Last reason dropping returns the session to the video plane.
    invokeSetGpuVoRequirement(core, GpuVoPolicy.REASON_HDR_SDR, false)
    awaitCondition { lastVo() == "mediacodec" }
    assertEquals("mediacodec", lastVo())
  }

  @Test
  fun dvConversionModeMapsOntoForkDecoderOptions() {
    // The app-level `dv-conversion-mode` property must translate to the fork
    // FFmpeg hevc_mediacodec options, mirroring the ExoPlayer DoviBridge
    // modes. Robolectric reports no Dolby Vision display, so `auto` takes the
    // no-DV branch deterministically.
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val writes = ConcurrentLinkedQueue<Pair<String, String>>()
    val core = MpvPlayerCore(activity, audioOnly = false, propertyWriter = { name, value ->
      writes.add(name to value)
    })

    fun apply(mode: String): Result<Unit> {
      writes.clear()
      var outcome: Result<Unit>? = null
      core.setProperty("dv-conversion-mode", mode) { outcome = it }
      awaitCondition { outcome != null }
      return outcome!!
    }

    assertTrue(apply("auto").isSuccess)
    assertEquals(listOf("vd-lavc-o" to "dolby_vision=0,dv_p7_mode=strip"), writes.toList())

    assertTrue(apply("disabled").isSuccess)
    assertEquals(listOf("vd-lavc-o" to "dolby_vision=1,dv_p7_mode=native"), writes.toList())

    assertTrue(apply("dv81").isSuccess)
    assertEquals(listOf("vd-lavc-o" to "dolby_vision=1,dv_p7_mode=convert"), writes.toList())

    assertTrue(apply("hevc_strip").isSuccess)
    assertEquals(listOf("vd-lavc-o" to "dolby_vision=1,dv_p7_mode=strip"), writes.toList())

    val invalid = apply("bogus")
    assertTrue(invalid.isFailure)
    assertTrue(writes.isEmpty())
  }

  @Test
  fun decoderOptionsMergeKeepsUserEntriesFirst() {
    // The property interface cannot append to a list option, so the write
    // replaces it wholesale: a user's own mpv.conf `vd-lavc-o` entries must
    // survive, with the app's keys last (FFmpeg keeps the last duplicate).
    assertEquals(
      "threads=4,dolby_vision=1",
      MpvPlayerCore.mergeDecoderOptions("threads=4", "dolby_vision=1")
    )
    assertEquals("dolby_vision=1", MpvPlayerCore.mergeDecoderOptions(null, "dolby_vision=1"))
    assertEquals("dolby_vision=1", MpvPlayerCore.mergeDecoderOptions("  ", "dolby_vision=1"))
  }

  private fun awaitQueueEntry(
    queue: ConcurrentLinkedQueue<Pair<String, String>>,
    expected: Pair<String, String>
  ): Boolean {
    repeat(10) {
      shadowOf(Looper.getMainLooper()).idle()
      if (queue.contains(expected)) return true
      Thread.sleep(10)
    }
    return false
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

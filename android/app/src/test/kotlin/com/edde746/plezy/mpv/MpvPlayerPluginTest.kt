package com.edde746.plezy.mpv

import android.app.Activity
import android.content.ComponentCallbacks2
import android.media.AudioManager
import android.os.Handler
import android.os.Looper
import android.view.Display
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.widget.FrameLayout
import com.edde746.plezy.libmpv.EndFileReason
import com.edde746.plezy.libmpv.LogLevel
import com.edde746.plezy.libmpv.LogMessage
import com.edde746.plezy.libmpv.MpvEvent
import com.edde746.plezy.libmpv.MpvPlayer
import com.edde746.plezy.shared.AudioFocusManager
import com.edde746.plezy.shared.PlayerDelegate
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
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowDisplayManager

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
  fun commandWithoutNativePlayerReportsFailureInsteadOfSilentSuccess() {
    // A load that never reached mpv produces no source; answering success
    // would leave Dart waiting on a start-file that never comes.
    val plugin = MpvPlayerPlugin()
    installCore(plugin, testCore(null))
    val result = RecordingResult()

    plugin.onMethodCall(MethodCall("command", mapOf("args" to listOf("loadfile", "x", "replace"))), result)
    awaitCompletion(result)

    assertEquals("COMMAND_FAILED", result.errorCode)
    assertEquals(1, result.completionCount)
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
  fun staleDisposeIsAcknowledgedWithoutTearingDownTheCore() {
    // A dispose whose instanceId is not the core creator's lost the ownership
    // race to a successor; tearing the core down anyway would kill that
    // successor's session. It must be acknowledged as a no-op instead.
    val plugin = MpvPlayerPlugin()
    installCore(plugin, testCore { _, _ -> })
    setPluginField(plugin, "coreInstanceId", 2L)
    val result = RecordingResult()

    plugin.onMethodCall(MethodCall("dispose", mapOf("instanceId" to 1)), result)
    awaitCompletion(result)

    assertNull(result.errorCode)
    assertNotNull(getPluginField(plugin, "playerCore"))
    assertEquals(2L, getPluginField(plugin, "coreInstanceId"))
  }

  @Test
  fun matchingDisposeTearsDownTheCoreAndClearsTheToken() {
    val plugin = MpvPlayerPlugin()
    installCore(plugin, testCore { _, _ -> })
    setPluginField(plugin, "coreInstanceId", 7L)
    val result = RecordingResult()

    plugin.onMethodCall(MethodCall("dispose", mapOf("instanceId" to 7)), result)
    awaitCompletion(result)

    assertNull(result.errorCode)
    assertNull(getPluginField(plugin, "playerCore"))
    assertNull(getPluginField(plugin, "coreInstanceId"))
  }

  @Test
  fun tokenlessDisposeKeepsLegacySemanticsAndTearsDownTheCore() {
    val plugin = MpvPlayerPlugin()
    installCore(plugin, testCore { _, _ -> })
    setPluginField(plugin, "coreInstanceId", 7L)
    val result = RecordingResult()

    plugin.onMethodCall(MethodCall("dispose", null), result)
    awaitCompletion(result)

    assertNull(result.errorCode)
    assertNull(getPluginField(plugin, "playerCore"))
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
  fun concurrentInitializeCallersShareOneAttemptAndOneOutcome() {
    // Two `initialize` calls must build one core and answer both callers
    // with its outcome; the second tearing down the in-flight core was #930.
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val plugin = MpvPlayerPlugin()
    setPluginField(plugin, "activity", activity)
    val core = MpvPlayerCore(activity)
    var created = 0
    var initialized: ((Boolean) -> Unit)? = null
    plugin.createCore = { _, _, _, _, _ ->
      created++
      core
    }
    plugin.initializeCore = { _, onInitialized -> initialized = onInitialized }
    val first = RecordingResult()
    val second = RecordingResult()

    plugin.onMethodCall(MethodCall("initialize", mapOf("instanceId" to 1)), first)
    plugin.onMethodCall(MethodCall("initialize", mapOf("instanceId" to 1)), second)
    shadowOf(Looper.getMainLooper()).idle()

    assertEquals(1, created)
    assertEquals(0, first.completionCount)
    assertEquals(0, second.completionCount)

    initialized!!(true)
    shadowOf(Looper.getMainLooper()).idle()

    assertEquals(true, first.successValue)
    assertEquals(true, second.successValue)
    assertEquals(1, first.completionCount)
    assertEquals(1, second.completionCount)
    assertEquals(core, getPluginField(plugin, "playerCore"))

    // The settled attempt cancelled its watchdog; it must not re-answer.
    shadowOf(Looper.getMainLooper()).idleFor(30, TimeUnit.SECONDS)
    assertEquals(1, first.completionCount)
    assertEquals(1, second.completionCount)
    core.dispose()
  }

  @Test
  fun initializationThatNeverAnswersIsBoundedByTheWatchdog() {
    // A core that never calls back must not leave the Dart future waiting
    // forever, and its late answer must still retire the orphaned core.
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val plugin = MpvPlayerPlugin()
    setPluginField(plugin, "activity", activity)
    val core = MpvPlayerCore(activity)
    var initialized: ((Boolean) -> Unit)? = null
    plugin.createCore = { _, _, _, _, _ -> core }
    plugin.initializeCore = { _, onInitialized -> initialized = onInitialized }
    val result = RecordingResult()

    plugin.onMethodCall(MethodCall("initialize", mapOf("instanceId" to 1)), result)
    shadowOf(Looper.getMainLooper()).idle()
    assertEquals(0, result.completionCount)

    shadowOf(Looper.getMainLooper()).idleFor(30, TimeUnit.SECONDS)

    assertEquals(false, result.successValue)
    assertEquals(1, result.completionCount)
    assertFalse(getPluginField(plugin, "isInitializing") as Boolean)

    initialized!!(true)
    shadowOf(Looper.getMainLooper()).idle()

    assertEquals(1, result.completionCount)
    assertNull(getPluginField(plugin, "playerCore"))
    assertTrue(getCoreField(core, "disposing") as Boolean)
  }

  @Test
  fun successfulInitializationArrivingAfterDisposeIsDisposedExactlyOnce() {
    // The core answers after its session was torn down: the plugin owns the
    // orphan, must not publish it, and must not build a replacement.
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val plugin = MpvPlayerPlugin()
    setPluginField(plugin, "activity", activity)
    val core = MpvPlayerCore(activity)
    var created = 0
    var initialized: ((Boolean) -> Unit)? = null
    plugin.createCore = { _, _, _, _, _ ->
      created++
      core
    }
    plugin.initializeCore = { _, onInitialized -> initialized = onInitialized }
    val init = RecordingResult()

    plugin.onMethodCall(MethodCall("initialize", mapOf("instanceId" to 1)), init)
    shadowOf(Looper.getMainLooper()).idle()
    assertEquals(1, created)

    val dispose = RecordingResult()
    plugin.onMethodCall(MethodCall("dispose", mapOf("instanceId" to 1)), dispose)
    awaitCompletion(dispose)
    assertEquals(false, init.successValue)

    initialized!!(true)
    shadowOf(Looper.getMainLooper()).idle()

    assertEquals(1, created)
    assertEquals(1, init.completionCount)
    assertNull(getPluginField(plugin, "playerCore"))
    assertTrue(getCoreField(core, "disposing") as Boolean)
  }

  @Test
  fun aCondemnedSessionDoesNotStopTheNextOneFromInitializing() {
    // A write that never returned condemns the session it was issued for and
    // nothing else. Its teardown runs on its own thread - on a wedged decoder,
    // forever - while the successor gets its own mpv session, so Retry works
    // instead of the viewer being told to restart the app (#2290).
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val condemned = MpvPlayerCore(activity)
    condemnNativeOperations(condemned)

    val plugin = MpvPlayerPlugin()
    setPluginField(plugin, "activity", activity)
    val successor = MpvPlayerCore(activity)
    var initialized: ((Boolean) -> Unit)? = null
    plugin.createCore = { _, _, _, _, _ -> successor }
    plugin.initializeCore = { _, onInitialized -> initialized = onInitialized }
    val result = RecordingResult()

    plugin.onMethodCall(MethodCall("initialize", mapOf("instanceId" to 1)), result)
    shadowOf(Looper.getMainLooper()).idle()
    initialized!!(true)
    shadowOf(Looper.getMainLooper()).idle()

    assertNull(result.errorCode)
    assertEquals(true, result.successValue)
    assertEquals(successor, getPluginField(plugin, "playerCore"))
    successor.dispose()
    condemned.dispose()
  }

  @Test
  fun aCondemnedSessionRefusesFurtherInitializationOfItsOwnCore() {
    // The verdict is still terminal for the core that earned it: its mpv
    // state is unknown, so it must not be reinitialized in place.
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val condemned = MpvPlayerCore(activity)
    condemnNativeOperations(condemned)

    var accepted: Boolean? = null
    condemned.initialize { accepted = it }

    assertEquals(false, accepted)
    condemned.dispose()
  }

  private fun condemnNativeOperations(core: MpvPlayerCore) {
    MpvPlayerCore::class.java.getDeclaredMethod("failNativeOperations", Exception::class.java).apply {
      isAccessible = true
      invoke(core, MpvOperationTimeout("property write"))
    }
  }

  // Instrumenting libmpv lets Robolectric no-op System.loadLibrary, which
  // MpvPlayer's companion runs on class initialization; see fakeNativePlayer.
  @Config(instrumentedPackages = ["com.edde746.plezy.libmpv"])
  @Test
  fun repeatedDisposalSharesTheFirstRetirementInsteadOfReportingItDone() {
    // A second dispose must join the retirement already running: answering
    // it while the native close is still in flight tells the caller a
    // teardown finished that has not.
    val core = testVideoCore { _, _ -> }
    setCoreField(core, "player", fakeNativePlayer())
    val settled = mutableListOf<String>()

    core.dispose { settled += "first" }
    core.dispose { settled += "second" }

    // Native teardown runs on a worker and settles its callers through the
    // main looper, which Robolectric leaves paused until the test idles it.
    assertEquals(emptyList<String>(), settled)

    awaitCondition { settled.size == 2 }
    assertEquals(listOf("first", "second"), settled)
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
  fun setLogLevelWithoutCoreReportsNotInitializedForVideoAndAudio() {
    for (plugin in listOf(MpvPlayerPlugin(), MpvAudioPlayerPlugin())) {
      val result = RecordingResult()

      plugin.onMethodCall(MethodCall("setLogLevel", mapOf("level" to "warn")), result)

      assertEquals("NOT_INITIALIZED", result.errorCode)
      assertEquals(1, result.completionCount)
      assertNull(result.successValue)
    }
  }

  @Test
  fun setLogLevelRejectsMissingOrNonStringLevel() {
    for (level in listOf(null, 42)) {
      val result = RecordingResult()

      MpvPlayerPlugin().onMethodCall(MethodCall("setLogLevel", mapOf("level" to level)), result)

      assertEquals("INVALID_ARGS", result.errorCode)
      assertEquals(1, result.completionCount)
    }
  }

  @Test
  fun disposeCompletesQueuedLogLevelChangeOnceWithoutAnActiveNativePlayer() {
    val blockerStarted = CountDownLatch(1)
    val releaseBlocker = CountDownLatch(1)
    val core = testCore { _, _ ->
      blockerStarted.countDown()
      check(releaseBlocker.await(2, TimeUnit.SECONDS))
    }
    val plugin = MpvPlayerPlugin()
    installCore(plugin, core)
    val result = RecordingResult()
    try {
      core.setProperty("block", "value")
      assertTrue(blockerStarted.await(1, TimeUnit.SECONDS))
      plugin.onMethodCall(MethodCall("setLogLevel", mapOf("level" to "v")), result)
      core.dispose()
    } finally {
      releaseBlocker.countDown()
    }
    awaitCompletion(result)

    assertEquals("NOT_INITIALIZED", result.errorCode)
    assertEquals(1, result.completionCount)
    assertNull(result.successValue)
  }

  @Test
  fun endFileDiagnosticsPreserveReasonIdAndExposeDependencyErrorLog() {
    val diagnostics = MpvEndFileDiagnostics()
    diagnostics.onStartFile()
    diagnostics.onLogMessage(LogMessage("ffmpeg", LogLevel.Error, "Invalid data found when processing input"))

    assertEquals(
      mapOf(
        "sourceId" to 73L,
        "reason" to 4,
        "message" to "Invalid data found when processing input"
      ),
      diagnostics.onEndFile(MpvEvent.EndFile(EndFileReason.Error, 73L))
    )
  }

  @Test
  fun endFileDiagnosticsDoNotAttachStaleOrInventedDetails() {
    val diagnostics = MpvEndFileDiagnostics()
    diagnostics.onLogMessage(LogMessage("ffmpeg", LogLevel.Error, "old failure"))
    diagnostics.onStartFile()

    assertEquals(mapOf("reason" to 0), diagnostics.onEndFile(MpvEvent.EndFile(EndFileReason.Eof, null)))
    assertEquals(mapOf("reason" to 4), diagnostics.onEndFile(MpvEvent.EndFile(EndFileReason.Error, null)))
    assertEquals(mapOf("sourceId" to 81L), diagnostics.onEndFile(MpvEvent.EndFile(null, 81L)))
    assertNull(diagnostics.onEndFile(MpvEvent.EndFile(null, null)))
  }

  @Test
  fun endFileEventChannelPayloadKeepsExistingEnvelopeAndAddsMessage() {
    val sink = RecordingEventSink()
    val plugin = MpvPlayerPlugin()
    plugin.onListen(null, sink)

    plugin.onEvent(
      "end-file",
      mapOf(
        "sourceId" to 92L,
        "reason" to 4,
        "message" to "Failed to open stream"
      )
    )

    assertEquals(
      mapOf(
        "type" to "event",
        "name" to "end-file",
        "data" to mapOf(
          "sourceId" to 92L,
          "reason" to 4,
          "message" to "Failed to open stream"
        )
      ),
      sink.successValue
    )
  }

  @Test
  fun sourceQualifiedLifecycleAndPropertiesKeepTheirDequeueIdentity() {
    val sink = RecordingEventSink()
    val plugin = MpvPlayerPlugin()
    plugin.onListen(null, sink)
    // This test owns event routing, not native observation admission.
    setPluginField(plugin, "nameToId", mutableMapOf("time-pos" to 7))

    plugin.onPropertyChange("time-pos", 0.0)
    plugin.onEvent("start-file", mapOf("sourceId" to 202L))
    plugin.onEvent("file-loaded", mapOf("sourceId" to 202L))
    plugin.onPropertyChange("time-pos", 12.5, 101L)
    plugin.onEvent(
      "playback-restart",
      mapOf("sourceId" to 202L, "positionSeconds" to 18.75)
    )

    assertEquals(
      listOf(
        listOf(7, 0.0, null),
        mapOf(
          "type" to "event",
          "name" to "start-file",
          "data" to mapOf("sourceId" to 202L)
        ),
        mapOf(
          "type" to "event",
          "name" to "file-loaded",
          "data" to mapOf("sourceId" to 202L)
        ),
        listOf(7, 12.5, 101L),
        mapOf(
          "type" to "event",
          "name" to "playback-restart",
          "data" to mapOf("sourceId" to 202L, "positionSeconds" to 18.75)
        )
      ),
      sink.successValues
    )
  }

  @Test
  fun hardwareOsdUsesLaidOutContainCoverFillAndZoomBounds() {
    val writes = ConcurrentLinkedQueue<Pair<String, String>>()
    val core = testVideoCore { name, value -> writes.add(name to value) }
    val container = installVideoRectViews(core)
    setCoreField(core, "videoDisplayWidth", 1000)
    setCoreField(core, "videoDisplayHeight", 500)

    applyAndLayoutVideoRect(core, container)
    awaitCondition { writes.contains("vo-mediacodec-video-rect" to "1001,701,0,100,1001,600") }

    // CENTER truncates odd negative differences towards zero, not floor.
    setCoreField(core, "videoPanscan", 1f)
    applyAndLayoutVideoRect(core, container)
    awaitCondition { writes.contains("vo-mediacodec-video-rect" to "1001,701,-200,0,1202,701") }

    // A stretched display aspect fills the viewport without OSD resizing.
    setCoreField(core, "videoPanscan", 0f)
    setCoreField(core, "videoDisplayWidth", 1001)
    setCoreField(core, "videoDisplayHeight", 701)
    applyAndLayoutVideoRect(core, container)
    awaitCondition { writes.contains("vo-mediacodec-video-rect" to "1001,701,0,0,1001,701") }

    setCoreField(core, "videoZoomLog2", 1f)
    applyAndLayoutVideoRect(core, container)
    awaitCondition { writes.contains("vo-mediacodec-video-rect" to "1001,701,-500,-350,1502,1052") }
    val osd = getCoreField(core, "osdSurfaceView") as SurfaceView
    assertEquals(1001, osd.width)
    assertEquals(701, osd.height)
    setCoreField(core, "videoZoomLog2", 0f)
    setCoreField(core, "videoDisplayWidth", 500)
    setCoreField(core, "videoDisplayHeight", 1000)
    applyAndLayoutVideoRect(core, container)
    awaitCondition { writes.contains("vo-mediacodec-video-rect" to "1001,701,325,0,675,701") }
    core.dispose()
  }

  @Test
  fun pausedGeometryCoalescesLayoutAndReplaysForNewOutput() {
    val writes = ConcurrentLinkedQueue<Pair<String, String>>()
    val core = testVideoCore { name, value -> writes.add(name to value) }
    val container = installVideoRectViews(core)
    setBoolean(core, "cachedPaused", true)
    setCoreField(core, "videoDisplayWidth", 1000)
    setCoreField(core, "videoDisplayHeight", 500)
    applyAndLayoutVideoRect(core, container)
    drainGeometryWrites(core)
    repeat(3) { invokeVideoRectLayout(core) }
    drainGeometryWrites(core)
    fun rectangles() = writes.filter { it.first == "vo-mediacodec-video-rect" }
    assertEquals(listOf("vo-mediacodec-video-rect" to "1001,701,0,100,1001,600"), rectangles())

    setCoreField(core, "videoOutputEpoch", 1L)
    invokeVideoRectLayout(core)
    drainGeometryWrites(core)
    assertEquals(2, rectangles().size)
    // Fractional buffer pixels must not replace the full OSD view viewport.
    val callback = getCoreField(core, "osdSurfaceCallback") as SurfaceHolder.Callback
    val osd = getCoreField(core, "osdSurfaceView") as SurfaceView
    callback.surfaceChanged(osd.holder, 0, 334, 234)
    drainGeometryWrites(core)
    assertEquals(3, rectangles().size)
    assertEquals("1001,701,0,100,1001,600", rectangles().last().second)
    // Resize while paused: layout, not decoder progress, publishes the change.
    layoutVideoRectViews(container, 701, 1001)
    invokeVideoRectLayout(core)
    layoutVideoRectViews(container, 701, 1001)
    invokeVideoRectLayout(core)
    drainGeometryWrites(core)
    assertEquals("701,1001,0,325,701,675", rectangles().last().second)
    assertTrue(writes.none { it.first == "pause" })
    core.dispose()
  }

  @Test
  fun pendingGeometryDropsSupersededLayoutsAndRetiredSurfaceEpochs() {
    val writes = ConcurrentLinkedQueue<Pair<String, String>>()
    val blockerStarted = CountDownLatch(1)
    val releaseBlocker = CountDownLatch(1)
    val core = testVideoCore { name, value ->
      if (name == "block") {
        blockerStarted.countDown()
        check(releaseBlocker.await(2, TimeUnit.SECONDS))
      }
      writes.add(name to value)
    }
    val container = installVideoRectViews(core)
    core.setProperty("block", "yes")
    assertTrue(blockerStarted.await(1, TimeUnit.SECONDS))
    try {
      setCoreField(core, "videoDisplayWidth", 1000)
      setCoreField(core, "videoDisplayHeight", 500)
      applyAndLayoutVideoRect(core, container)
      setCoreField(core, "videoPanscan", 1f)
      applyAndLayoutVideoRect(core, container)
      // Both queued snapshots belong to a surface which has now retired.
      setCoreField(core, "videoOutputEpoch", 1L)
    } finally {
      releaseBlocker.countDown()
    }
    drainGeometryWrites(core)
    assertTrue(writes.none { it.first == "vo-mediacodec-video-rect" })
    invokeVideoRectLayout(core)
    drainGeometryWrites(core)
    assertEquals(
      listOf("vo-mediacodec-video-rect" to "1001,701,-200,0,1202,701"),
      writes.filter { it.first == "vo-mediacodec-video-rect" }
    )
    core.dispose()
  }

  @Config(instrumentedPackages = ["com.edde746.plezy.libmpv"])
  @Test
  fun osdRetirementDuringAGpuRefreshDoesNotStrandVideoReadiness() {
    // A session that has moved to a GPU vo retires its OSD plane while a
    // video refresh is still queued. Bumping the epoch cancels that queued
    // refresh, and a bump with no replacement work leaves
    // videoOutputRestoring true forever: hasReadyVideoOutput() never turns
    // true again and the deferred resume never reaches mpv. Nothing else
    // can clear it either — the transition hides the OSD view, so no
    // osdSurfaceCreated will follow to schedule a refresh.
    val core = testVideoCore { _, _ -> }
    installVideoRectViews(core)
    setCoreField(core, "player", fakeNativePlayer())
    setCoreField(core, "activeGpuVoTarget", "gpu")
    setCoreField(core, "appliedGpuVoTarget", "gpu")
    setCoreField(core, "attachedOsdSurface", null)
    setCoreField(core, "videoOutputEpoch", 4L)
    setCoreField(core, "lastKnownSurfaceWidth", 0)
    setCoreField(core, "lastKnownSurfaceHeight", 0)
    // A refresh is in flight against epoch 4.
    setBoolean(core, "videoOutputRestoring", true)

    val osdCallback = getCoreField(core, "osdSurfaceCallback") as SurfaceHolder.Callback
    val osdView = getCoreField(core, "osdSurfaceView") as SurfaceView
    osdCallback.surfaceDestroyed(osdView.holder)

    // The retirement invalidated the queued refresh and issued a
    // replacement: with no candidate surface in this harness the
    // replacement re-parks the latch, but it re-reads the video view's
    // size on the way there and nothing else in the retirement path does.
    assertEquals(5L, getCoreField(core, "videoOutputEpoch"))
    assertEquals(1001, getCoreField(core, "lastKnownSurfaceWidth"))
    assertEquals(701, getCoreField(core, "lastKnownSurfaceHeight"))
    assertTrue(getBoolean(core, "videoOutputRestoring"))
    core.dispose()
  }

  /**
   * An adopted native session, without libmpv: Robolectric no-ops
   * `System.loadLibrary`, and pre-closing the wrapper makes [MpvPlayer.close]
   * return before its JNI call, so the core's lifecycle paths that require a
   * player can run on the JVM.
   */
  private fun fakeNativePlayer(): MpvPlayer {
    val player = MpvPlayer::class.java.getDeclaredConstructor(Long::class.javaPrimitiveType).run {
      isAccessible = true
      newInstance(1L)
    }
    MpvPlayer::class.java.getDeclaredField("closed").apply {
      isAccessible = true
      setBoolean(player, true)
    }
    return player
  }

  private fun installVideoRectViews(core: MpvPlayerCore): FrameLayout {
    val context = getCoreField(core, "context") as Activity
    val container = FrameLayout(context)
    val video = SurfaceView(context)
    val osd = SurfaceView(context)
    container.addView(video, FrameLayout.LayoutParams(-1, -1))
    container.addView(osd, FrameLayout.LayoutParams(-1, -1))
    setCoreField(core, "surfaceContainer", container)
    setCoreField(core, "surfaceView", video)
    setCoreField(core, "osdSurfaceView", osd)
    layoutVideoRectViews(container)
    return container
  }

  private fun layoutVideoRectViews(container: FrameLayout, width: Int = 1001, height: Int = 701) {
    container.measure(
      View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY),
      View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.EXACTLY)
    )
    container.layout(0, 0, width, height)
  }

  private fun applyAndLayoutVideoRect(core: MpvPlayerCore, container: FrameLayout) {
    invokeVideoRectLayout(core)
    layoutVideoRectViews(container)
    invokeVideoRectLayout(core)
  }

  private fun invokeVideoRectLayout(core: MpvPlayerCore, force: Boolean = false) {
    MpvPlayerCore::class.java.getDeclaredMethod("applyVideoRectLayout", Boolean::class.javaPrimitiveType).apply {
      isAccessible = true
      invoke(core, force)
    }
  }

  private fun drainGeometryWrites(core: MpvPlayerCore) {
    var completed = false
    core.setProperty("geometry-test-barrier", "yes") { completed = true }
    awaitCondition { completed }
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

  /** Stands in for the budget `initialize` applies from the same tier table. */
  private fun setAppliedDemuxerBudget(core: MpvPlayerCore, budget: DemuxerBudget) {
    MpvPlayerCore::class.java.getDeclaredField("appliedDemuxerBudget").apply {
      isAccessible = true
      set(core, budget)
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
  fun everyVideoRouteReasonChangeIsLogged() {
    // The reason set is what diagnoses a session that left the video plane
    // (#2302), so a change has to reach the uploadable log even when the
    // target does not move.
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val core = MpvPlayerCore(activity, audioOnly = false, propertyWriter = { _, _ -> })
    setBoolean(core, "isInitialized", true)
    val routes = ConcurrentLinkedQueue<String>()
    core.delegate = object : PlayerDelegate {
      override fun onPropertyChange(name: String, value: Any?) = Unit
      override fun onEvent(name: String, data: Map<String, Any>?) {
        if (name == "log-message" && data?.get("prefix") == "video-route") {
          routes.add(data["text"] as String)
        }
      }
    }

    invokeSetGpuVoRequirement(core, GpuVoPolicy.REASON_HDR_SDR, true)
    invokeSetGpuVoRequirement(core, GpuVoPolicy.REASON_SHADERS, true)

    val logged = routes.toList()
    assertEquals(2, logged.size)
    assertTrue(logged[0].contains("mediacodec -> gpu"))
    assertTrue(logged[1].contains(GpuVoPolicy.REASON_HDR_SDR))
    assertTrue(logged[1].contains(GpuVoPolicy.REASON_SHADERS))
  }

  @Test
  fun hwdecWritesParkWhileAPerFileHoldIsActive() {
    // While DV P5 reshaping or Hi10 routing holds hwdec at `no`, a session
    // write of a hardware value must not reach mpv (it would re-enable the
    // decoder that was just refused) but must be kept for the restore.
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val writes = ConcurrentLinkedQueue<Pair<String, String>>()
    val core = MpvPlayerCore(activity, audioOnly = false, propertyWriter = { name, value ->
      writes.add(name to value)
    })
    setBoolean(core, "isInitialized", true)
    setBoolean(core, "hwdecHeld", true)

    var outcome: Result<Unit>? = null
    core.setProperty("hwdec", "mediacodec,mediacodec-copy") { outcome = it }
    awaitCondition { outcome != null }
    assertTrue(outcome!!.isSuccess)
    assertTrue(writes.isEmpty())
    val parked = MpvPlayerCore::class.java.getDeclaredField("parkedHwdec").run {
      isAccessible = true
      @Suppress("UNCHECKED_CAST")
      (get(core) as java.util.concurrent.atomic.AtomicReference<String?>).get()
    }
    assertEquals("mediacodec,mediacodec-copy", parked)

    // Once the hold is gone, hwdec writes flow through again.
    setBoolean(core, "hwdecHeld", false)
    outcome = null
    core.setProperty("hwdec", "no") { outcome = it }
    awaitCondition { outcome != null }
    assertEquals(listOf("hwdec" to "no"), writes.toList())
  }

  @Test
  fun memoryPressureWritesTheDemuxerBoundsOnceAndNeverReGrowsThem() {
    // Nothing else in the app hands native buffers back, so the two bounds
    // actually reaching mpv is the whole reclaim. Robolectric reports a 16 MB
    // large heap class, i.e. the tight tier, which is the device class this
    // exists for.
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val writes = ConcurrentLinkedQueue<Pair<String, String>>()
    val core = MpvPlayerCore(activity, audioOnly = false, propertyWriter = { name, value ->
      writes.add(name to value)
    })
    setBoolean(core, "isInitialized", true)
    val steady = DemuxerBudget.forHeapClassMB(16)!!
    setAppliedDemuxerBudget(core, steady)

    core.onTrimMemory(ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW)
    awaitCondition { writes.size == 2 }
    assertEquals(
      listOf("demuxer-max-bytes" to steady.aheadBytes.toString(), "demuxer-max-back-bytes" to "0"),
      writes.toList()
    )

    // Neither of these may reach mpv: the first level asks for nothing back,
    // and the session already holds what the harsher one would ask for on
    // this tier. Fenced behind a later write on the same serialized queue
    // rather than a pump: if either had queued a pair, it would be ahead of
    // the fence and already recorded by the time its callback fires.
    core.onTrimMemory(ComponentCallbacks2.TRIM_MEMORY_UI_HIDDEN)
    core.onTrimMemory(ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL)
    var fenced: Result<Unit>? = null
    core.setProperty("volume", "50") { fenced = it }
    awaitCondition { fenced != null }
    assertEquals(
      listOf(
        "demuxer-max-bytes" to steady.aheadBytes.toString(),
        "demuxer-max-back-bytes" to "0",
        "volume" to "50"
      ),
      writes.toList()
    )
  }

  @Test
  fun aStatsSweepDoesNotDelayARealPropertyRead() {
    // mpv_get_property waits on the core thread, so on a core decoding 4K in
    // software one sweep's ~38 reads can take seconds. Queued behind the
    // overlay, a real read waited out the whole sweep - not just the read
    // deadline, because the worker cannot be interrupted out of a blocking
    // JNI call. Diagnostics must not delay the playback they measure.
    val core = testVideoCore { _, _ -> }
    setBoolean(core, "isInitialized", true)
    val sweepEntered = java.util.concurrent.atomic.AtomicBoolean()
    val releaseSweep = CountDownLatch(1)
    core.propertyReaderOverride = { name ->
      if (name == "volume") {
        "50"
      } else {
        sweepEntered.set(true)
        releaseSweep.await(5, TimeUnit.SECONDS)
        null
      }
    }

    var sweep: Map<String, Any?>? = null
    core.getStatsAsync { sweep = it }
    awaitCondition { sweepEntered.get() }
    assertTrue("sweep did not start", sweepEntered.get())
    var read: String? = null
    var answered = false
    core.getPropertyAsync("volume") {
      read = it
      answered = true
    }
    awaitCondition { answered }
    assertTrue("the read waited for the sweep", answered)
    assertEquals("50", read)
    assertNull("the sweep answered early", sweep)

    releaseSweep.countDown()
    awaitCondition { sweep != null }
    assertEquals("mpv", sweep?.get("playerType"))
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
  fun displayChangeRepublishesTheRefreshRateToMpvUntilDispose() {
    // The fork vo builds its vsync grid from display-fps-override. A mode
    // switch the app did not make (the TV's own content matching, an HDR
    // mode change) must still reach mpv, and a disposed core must not write
    // into a session it no longer owns.
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val writes = ConcurrentLinkedQueue<Pair<String, String>>()
    val core = MpvPlayerCore(activity, audioOnly = false, propertyWriter = { name, value ->
      writes.add(name to value)
    })
    MpvPlayerCore::class.java.getDeclaredMethod("registerDisplayListener").apply {
      isAccessible = true
      invoke(core)
    }

    ShadowDisplayManager.changeDisplay(Display.DEFAULT_DISPLAY, "w1920dp-h1080dp")
    awaitCondition { writes.isNotEmpty() }
    val refreshRate = activity.windowManager.defaultDisplay.mode.refreshRate.toString()
    assertEquals(listOf("display-fps-override" to refreshRate), writes.toList())

    core.dispose()
    writes.clear()
    ShadowDisplayManager.changeDisplay(Display.DEFAULT_DISPLAY, "w1280dp-h720dp")
    shadowOf(Looper.getMainLooper()).idle()
    Thread.sleep(50)
    shadowOf(Looper.getMainLooper()).idle()
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
    val successValues = mutableListOf<Any?>()

    override fun success(event: Any?) {
      successValue = event
      successValues += event
    }

    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) = Unit

    override fun endOfStream() = Unit
  }
}

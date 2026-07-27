package com.edde746.plezy.exoplayer

import android.app.Activity
import android.os.Looper
import android.widget.FrameLayout
import androidx.media3.common.C
import androidx.media3.common.Format
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlaybackException
import androidx.media3.exoplayer.analytics.AnalyticsListener
import androidx.media3.exoplayer.source.SinglePeriodTimeline
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
class ExoPlayerFallbackTerminalTest {

  @Test
  fun unhandledFallbackPausesPlaybackAndEmitsOneTerminalError() {
    val core = ExoPlayerCore(Robolectric.buildActivity(Activity::class.java).setup().get())
    val delegate = RecordingDelegate(handlesFallback = false)
    core.delegate = delegate

    try {
      assertFalse(requestFallback(core, mediaGeneration = 0))
      assertFalse(requestFallback(core, mediaGeneration = 0))

      assertEquals(2, delegate.fallbackRequests)
      assertEquals(listOf("paused-for-cache" to false, "pause" to true), delegate.properties)
      assertEquals(1, delegate.events.size)
      assertEquals("end-file", delegate.events.single().first)
      assertEquals("error", delegate.events.single().second?.get("reason"))
    } finally {
      core.dispose()
    }
  }

  @Test
  fun handledFallbackLeavesTerminalOutcomeToThePlugin() {
    val core = ExoPlayerCore(Robolectric.buildActivity(Activity::class.java).setup().get())
    val delegate = RecordingDelegate(handlesFallback = true)
    core.delegate = delegate

    try {
      assertTrue(requestFallback(core, mediaGeneration = 0))

      assertEquals(1, delegate.fallbackRequests)
      assertTrue(delegate.properties.isEmpty())
      assertTrue(delegate.events.isEmpty())
    } finally {
      core.dispose()
    }
  }

  @Test
  fun staleFallbackCallbackCannotAffectTheActiveMedia() {
    val core = ExoPlayerCore(Robolectric.buildActivity(Activity::class.java).setup().get())
    val delegate = RecordingDelegate(handlesFallback = false)
    core.delegate = delegate

    try {
      assertTrue(requestFallback(core, mediaGeneration = 1))

      assertEquals(0, delegate.fallbackRequests)
      assertTrue(delegate.properties.isEmpty())
      assertTrue(delegate.events.isEmpty())
    } finally {
      core.dispose()
    }
  }

  @Test
  fun newOpenRearmsFirstFrameAndTerminalStateForItsMediaGeneration() {
    val core = ExoPlayerCore(Robolectric.buildActivity(Activity::class.java).setup().get())
    setField(core, "isInitialized", true)
    setField(core, "firstFrameRendered", true)
    setField(core, "terminalErrorGeneration", 2)

    try {
      core.open(
        uri = "https://example.test/next.mkv",
        headers = null,
        startPositionMs = 0L,
        autoPlay = true,
        mediaGeneration = 3
      )

      assertEquals(false, getField(core, "firstFrameRendered"))
      assertEquals(3, getField(core, "currentMediaGeneration"))
      assertEquals(null, getField(core, "terminalErrorGeneration"))
      assertEquals("3", mediaItemId(core))
    } finally {
      core.dispose()
    }
  }

  @Test
  fun videoPlaybackRestartComesFromTheRenderedFrameCallback() {
    val core = ExoPlayerCore(Robolectric.buildActivity(Activity::class.java).setup().get())
    val delegate = RecordingDelegate(handlesFallback = false)
    core.delegate = delegate
    setField(core, "currentMediaGeneration", 7)
    val mediaItem = MediaItem.Builder()
      .setMediaId("7")
      .setUri("https://example.test/video.mkv")
      .build()
    val timeline = SinglePeriodTimeline(
      1_000_000L,
      true,
      false,
      false,
      null,
      mediaItem
    )
    val eventTime = AnalyticsListener.EventTime(
      0L,
      timeline,
      0,
      null,
      0L,
      timeline,
      0,
      null,
      0L,
      0L
    )
    val analytics = getField(core, "decoderHangListener") as AnalyticsListener

    try {
      assertTrue(delegate.events.isEmpty())
      analytics.onRenderedFirstFrame(eventTime, Any(), 0L)

      assertEquals(listOf("playback-restart"), delegate.events.map { it.first })
      assertEquals(true, getField(core, "firstFrameRendered"))
    } finally {
      core.dispose()
    }
  }

  @Test
  fun videoPlaybackRestartRepeatsAfterSeekWithoutDecoderReinit() {
    val core = ExoPlayerCore(Robolectric.buildActivity(Activity::class.java).setup().get())
    val delegate = RecordingDelegate(handlesFallback = false)
    core.delegate = delegate
    setField(core, "currentMediaGeneration", 7)
    val mediaItem = MediaItem.Builder()
      .setMediaId("7")
      .setUri("https://example.test/video.mkv")
      .build()
    val timeline = SinglePeriodTimeline(
      1_000_000L,
      true,
      false,
      false,
      null,
      mediaItem
    )
    val eventTime = AnalyticsListener.EventTime(
      0L,
      timeline,
      0,
      null,
      0L,
      timeline,
      0,
      null,
      0L,
      0L
    )
    val analytics = getField(core, "decoderHangListener") as AnalyticsListener

    try {
      analytics.onRenderedFirstFrame(eventTime, Any(), 0L)
      analytics.onRenderedFirstFrame(eventTime, Any(), 0L)

      assertEquals(
        listOf("playback-restart", "playback-restart"),
        delegate.events.map { it.first }
      )
      assertEquals(true, getField(core, "firstFrameRendered"))
    } finally {
      core.dispose()
    }
  }

  @Test
  fun audioOnlyReadyEmitsPlaybackRestartWithoutAFrameCallback() {
    val core = ExoPlayerCore(Robolectric.buildActivity(Activity::class.java).setup().get())
    val delegate = RecordingDelegate(handlesFallback = false)
    core.delegate = delegate

    try {
      invokePlaybackState(core, Player.STATE_READY)

      assertEquals(listOf("playback-restart"), delegate.events.map { it.first })
      assertEquals(true, getField(core, "firstFrameRendered"))
    } finally {
      core.dispose()
    }
  }

  @Test
  fun audioOnlyPlaybackRestartRepeatsOnReentryToReady() {
    val core = ExoPlayerCore(Robolectric.buildActivity(Activity::class.java).setup().get())
    val delegate = RecordingDelegate(handlesFallback = false)
    core.delegate = delegate

    try {
      invokePlaybackState(core, Player.STATE_READY)
      invokePlaybackState(core, Player.STATE_BUFFERING)
      invokePlaybackState(core, Player.STATE_READY)

      assertEquals(
        listOf("playback-restart", "playback-restart"),
        delegate.events.map { it.first }
      )
      assertEquals(true, getField(core, "firstFrameRendered"))
    } finally {
      core.dispose()
    }
  }

  @Test
  fun pausedTimeDoesNotConsumeTheFrameWatchdogTimeout() {
    val core = ExoPlayerCore(Robolectric.buildActivity(Activity::class.java).setup().get())
    setField(core, "frameWatchdogStartTime", 100L)

    try {
      assertEquals(0L, frameWatchdogElapsed(core, nowMs = 10_000L, isPlaying = false))
      assertEquals(250L, frameWatchdogElapsed(core, nowMs = 10_250L, isPlaying = true))
    } finally {
      core.dispose()
    }
  }

  @Test
  fun pauseAndResumeTransitionsResetTheFrameWatchdogBaselineWithoutAPoll() {
    val core = ExoPlayerCore(Robolectric.buildActivity(Activity::class.java).setup().get())

    try {
      setField(core, "frameWatchdogStartTime", 100L)
      invokeIsPlayingChanged(core, false)
      assertTrue((getField(core, "frameWatchdogStartTime") as Long) > 100L)

      setField(core, "frameWatchdogStartTime", 100L)
      invokeIsPlayingChanged(core, true)
      assertTrue((getField(core, "frameWatchdogStartTime") as Long) > 100L)
    } finally {
      core.dispose()
    }
  }

  @Test
  @Config(sdk = [28])
  fun warmVideoDecoderErrorRetriesOnceBeforeFallback() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    activity.setContentView(FrameLayout(activity))
    val core = ExoPlayerCore(activity)
    val delegate = RecordingDelegate(handlesFallback = true)
    core.delegate = delegate

    try {
      assertTrue(core.initialize())
      setField(core, "currentMediaGeneration", 7)
      setField(core, "currentMediaUri", "file:///missing-video.mkv")
      emitRenderedFirstFrame(core, mediaGeneration = 7)

      invokePlayerError(core, videoDecoderError(), mediaGeneration = 7)

      assertEquals(0, delegate.fallbackRequests)
      assertEquals(1, getField(core, "videoDecoderRecoveryConsecutiveAttempts"))
      assertEquals(1, getField(core, "videoDecoderRecoveryTotalAttempts"))

      invokePlayerError(core, videoDecoderError(), mediaGeneration = 7)

      assertEquals(1, delegate.fallbackRequests)
    } finally {
      core.dispose()
      shadowOf(Looper.getMainLooper()).idle()
    }
  }

  @Test
  @Config(sdk = [28])
  fun coldVideoDecoderErrorFallsBackImmediately() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    activity.setContentView(FrameLayout(activity))
    val core = ExoPlayerCore(activity)
    val delegate = RecordingDelegate(handlesFallback = true)
    core.delegate = delegate

    try {
      assertTrue(core.initialize())
      setField(core, "currentMediaGeneration", 7)
      setField(core, "currentMediaUri", "file:///missing-video.mkv")

      invokePlayerError(core, videoDecoderError(), mediaGeneration = 7)

      assertEquals(1, delegate.fallbackRequests)
      assertEquals(0, getField(core, "videoDecoderRecoveryConsecutiveAttempts"))
      assertEquals(0, getField(core, "videoDecoderRecoveryTotalAttempts"))
    } finally {
      core.dispose()
      shadowOf(Looper.getMainLooper()).idle()
    }
  }

  @Test
  @Config(sdk = [28])
  fun sustainedPlaybackRearmsDecoderRecovery() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    activity.setContentView(FrameLayout(activity))
    val core = ExoPlayerCore(activity)
    val delegate = RecordingDelegate(handlesFallback = true)
    core.delegate = delegate

    try {
      assertTrue(core.initialize())
      setField(core, "currentMediaGeneration", 7)
      setField(core, "currentMediaUri", "file:///missing-video.mkv")
      emitRenderedFirstFrame(core, mediaGeneration = 7)

      invokePlayerError(core, videoDecoderError(), mediaGeneration = 7)
      emitRenderedFirstFrame(core, mediaGeneration = 7)
      invokeVideoDecoderRecoveryHealth(
        core,
        currentPositionMs = VideoDecoderRecoveryPolicy.HEALTHY_PLAYBACK_PROGRESS_MS,
        isPlaying = true
      )

      assertEquals(0, getField(core, "videoDecoderRecoveryConsecutiveAttempts"))
      assertEquals(1, getField(core, "videoDecoderRecoveryTotalAttempts"))

      invokePlayerError(core, videoDecoderError(), mediaGeneration = 7)

      assertEquals(0, delegate.fallbackRequests)
      assertEquals(2, getField(core, "videoDecoderRecoveryTotalAttempts"))

      invokePlayerError(core, videoDecoderError(), mediaGeneration = 7)

      assertEquals(1, delegate.fallbackRequests)
    } finally {
      core.dispose()
      shadowOf(Looper.getMainLooper()).idle()
    }
  }

  private fun setField(target: Any, name: String, value: Any?) {
    target.javaClass.getDeclaredField(name).apply {
      isAccessible = true
      set(target, value)
    }
  }

  private fun getField(target: Any, name: String): Any? = target.javaClass.getDeclaredField(name).apply { isAccessible = true }.get(target)

  private fun requestFallback(core: ExoPlayerCore, mediaGeneration: Int): Boolean {
    val method = ExoPlayerCore::class.java.getDeclaredMethod(
      "requestFormatFallback",
      Int::class.javaPrimitiveType,
      String::class.java,
      Long::class.javaPrimitiveType,
      Boolean::class.javaPrimitiveType,
      String::class.java
    )
    method.isAccessible = true
    return method.invoke(
      core,
      mediaGeneration,
      "https://example.test/video.mkv",
      0L,
      true,
      "unsupported video"
    ) as Boolean
  }

  private fun invokePlaybackState(core: ExoPlayerCore, state: Int) {
    ExoPlayerCore::class.java.getDeclaredMethod(
      "handlePlaybackStateChanged",
      Int::class.javaPrimitiveType
    ).apply {
      isAccessible = true
      invoke(core, state)
    }
  }

  private fun invokeIsPlayingChanged(core: ExoPlayerCore, isPlaying: Boolean) {
    ExoPlayerCore::class.java.getDeclaredMethod(
      "handleIsPlayingChanged",
      Boolean::class.javaPrimitiveType
    ).apply {
      isAccessible = true
      invoke(core, isPlaying)
    }
  }

  private fun emitRenderedFirstFrame(core: ExoPlayerCore, mediaGeneration: Int) {
    val mediaItem = MediaItem.Builder()
      .setMediaId(mediaGeneration.toString())
      .setUri("file:///video.mkv")
      .build()
    val timeline = SinglePeriodTimeline(
      1_000_000L,
      true,
      false,
      false,
      null,
      mediaItem
    )
    val eventTime = AnalyticsListener.EventTime(
      0L,
      timeline,
      0,
      null,
      0L,
      timeline,
      0,
      null,
      0L,
      0L
    )
    val analytics = getField(core, "decoderHangListener") as AnalyticsListener
    analytics.onRenderedFirstFrame(eventTime, Any(), 0L)
  }

  private fun videoDecoderError(): ExoPlaybackException = ExoPlaybackException.createForRenderer(
    IllegalStateException("codec reclaimed"),
    "MediaCodecVideoRenderer",
    0,
    Format.Builder().setSampleMimeType(MimeTypes.VIDEO_H264).build(),
    C.FORMAT_HANDLED,
    false,
    PlaybackException.ERROR_CODE_DECODING_FAILED
  )

  private fun invokePlayerError(
    core: ExoPlayerCore,
    error: PlaybackException,
    mediaGeneration: Int
  ) {
    ExoPlayerCore::class.java.getDeclaredMethod(
      "handlePlayerError",
      PlaybackException::class.java,
      Int::class.javaPrimitiveType
    ).apply {
      isAccessible = true
      invoke(core, error, mediaGeneration)
    }
  }

  private fun invokeVideoDecoderRecoveryHealth(
    core: ExoPlayerCore,
    currentPositionMs: Long,
    isPlaying: Boolean
  ) {
    ExoPlayerCore::class.java.getDeclaredMethod(
      "updateVideoDecoderRecoveryHealth",
      Long::class.javaPrimitiveType,
      Boolean::class.javaPrimitiveType
    ).apply {
      isAccessible = true
      invoke(core, currentPositionMs, isPlaying)
    }
  }

  private fun frameWatchdogElapsed(core: ExoPlayerCore, nowMs: Long, isPlaying: Boolean): Long {
    val method = ExoPlayerCore::class.java.getDeclaredMethod(
      "frameWatchdogElapsedMs",
      Long::class.javaPrimitiveType,
      Boolean::class.javaPrimitiveType
    )
    method.isAccessible = true
    return method.invoke(core, nowMs, isPlaying) as Long
  }

  private fun mediaItemId(core: ExoPlayerCore): String {
    val method = ExoPlayerCore::class.java.getDeclaredMethod("buildMediaItem", String::class.java)
    method.isAccessible = true
    val item = method.invoke(core, "https://example.test/next.mkv") as androidx.media3.common.MediaItem
    return item.mediaId
  }

  private class RecordingDelegate(
    private val handlesFallback: Boolean
  ) : ExoPlayerDelegate {
    var fallbackRequests = 0
    val properties = mutableListOf<Pair<String, Any?>>()
    val events = mutableListOf<Pair<String, Map<String, Any>?>>()

    override fun onFormatUnsupported(
      mediaGeneration: Int,
      uri: String,
      headers: Map<String, String>?,
      positionMs: Long,
      playWhenReady: Boolean,
      errorMessage: String
    ): Boolean {
      fallbackRequests++
      return handlesFallback
    }

    override fun onPropertyChange(name: String, value: Any?) {
      properties += name to value
    }

    override fun onEvent(name: String, data: Map<String, Any>?) {
      events += name to data
    }
  }
}

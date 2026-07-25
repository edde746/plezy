package com.edde746.plezy.exoplayer

import android.app.Activity
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.analytics.AnalyticsListener
import androidx.media3.exoplayer.source.SinglePeriodTimeline
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner

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

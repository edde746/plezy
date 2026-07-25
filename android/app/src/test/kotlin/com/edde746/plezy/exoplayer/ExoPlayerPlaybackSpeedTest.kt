package com.edde746.plezy.exoplayer

import android.app.Activity
import android.os.Looper
import android.widget.FrameLayout
import androidx.media3.exoplayer.ExoPlayer
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class ExoPlayerPlaybackSpeedTest {

  @Test
  fun eightTimesPlaybackIsAppliedAndOutOfRangeRequestsReportTheClamp() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    activity.setContentView(FrameLayout(activity))
    val core = ExoPlayerCore(activity)
    val delegate = RecordingDelegate()
    core.delegate = delegate

    try {
      assertTrue(core.initialize())
      val player = core.getExoPlayer()

      core.setPlaybackSpeed(8f)
      assertEquals(8f, player.playbackParameters.speed, 0f)

      core.setPlaybackSpeed(9f)
      assertEquals(8f, player.playbackParameters.speed, 0f)
      assertEquals(listOf(8.0, 8.0), delegate.reportedSpeeds)
    } finally {
      core.dispose()
      shadowOf(Looper.getMainLooper()).idle()
    }
  }

  private fun ExoPlayerCore.getExoPlayer(): ExoPlayer = javaClass.getDeclaredField("exoPlayer").apply { isAccessible = true }.get(this) as ExoPlayer

  private class RecordingDelegate : ExoPlayerDelegate {
    val reportedSpeeds = mutableListOf<Double>()

    override fun onPropertyChange(name: String, value: Any?) {
      if (name == "speed") reportedSpeeds += value as Double
    }

    override fun onEvent(name: String, data: Map<String, Any>?) = Unit
  }
}

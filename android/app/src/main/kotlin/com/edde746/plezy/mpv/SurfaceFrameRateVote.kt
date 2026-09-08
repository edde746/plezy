package com.edde746.plezy.mpv

import android.os.Build
import android.util.Log
import android.view.Surface

/**
 * The seamless frame-rate vote Media3's `VideoFrameReleaseHelper` places on
 * the video Surface, for the mpv backend.
 *
 * `Surface.setFrameRate(fps, FIXED_SOURCE)` tells SurfaceFlinger what cadence
 * the surface will present at. With the platform default of seamless-only
 * switching it is invisible on a display that cannot change mode without a
 * blank, and on one that can (or whose HWC keeps its modes in a single
 * group) it is what moves a 60 Hz panel to 24/25 Hz under ExoPlayer without
 * any app-side mode switch. Deliberate, non-seamless switches stay with
 * [com.edde746.plezy.shared.FrameRateManager]. mpv-build `6aa1d87` removed the
 * vote from the fork vo; this puts it back where Media3 keeps it, in the
 * player that owns the Surface.
 *
 * Mirrors Media3 semantics: the vote is media frame rate times playback
 * speed while rendering is started, cleared (rate 0) when stopped, cleared on
 * the outgoing Surface and re-applied unconditionally on a new one. Callers
 * drive it from one thread.
 */
internal class SurfaceFrameRateVote(
  private val setFrameRate: (Surface, Float) -> Unit = ::setSurfaceFrameRate
) {
  private var surface: Surface? = null
  private var mediaFrameRate = 0f
  private var playbackSpeed = 1f
  private var started = false

  /** The rate the current [surface] was last given; 0 means cleared. */
  private var votedFrameRate = 0f

  /** [surface] null: no real video Surface (placeholder, destroyed, disposed). */
  fun onSurfaceChanged(surface: Surface?) {
    if (this.surface === surface) return
    clear()
    this.surface = surface
    // A new Surface may carry any earlier vote; always write ours.
    update(force = true)
  }

  /** `container-fps`, or 0 while the file's rate is unknown. */
  fun onMediaFrameRate(fps: Float) {
    val next = if (fps.isFinite() && fps > 0f) fps else 0f
    if (mediaFrameRate == next) return
    mediaFrameRate = next
    update(force = false)
  }

  fun onPlaybackSpeed(speed: Float) {
    val next = if (speed.isFinite() && speed > 0f) speed else 1f
    if (playbackSpeed == next) return
    playbackSpeed = next
    update(force = false)
  }

  fun onStarted() {
    if (started) return
    started = true
    update(force = false)
  }

  fun onStopped() {
    if (!started) return
    started = false
    clear()
  }

  private fun update(force: Boolean) {
    val target = surface ?: return
    val rate = if (started && mediaFrameRate > 0f) mediaFrameRate * playbackSpeed else 0f
    if (!force && rate == votedFrameRate) return
    votedFrameRate = rate
    setFrameRate(target, rate)
  }

  private fun clear() {
    val target = surface ?: return
    if (votedFrameRate == 0f) return
    votedFrameRate = 0f
    setFrameRate(target, 0f)
  }

  companion object {
    private const val TAG = "SurfaceFrameRateVote"

    /** Media3 `VideoFrameReleaseHelper.Api30.setSurfaceFrameRate`. */
    private fun setSurfaceFrameRate(surface: Surface, frameRate: Float) {
      if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R || !surface.isValid) return
      val compatibility = if (frameRate == 0f) Surface.FRAME_RATE_COMPATIBILITY_DEFAULT else Surface.FRAME_RATE_COMPATIBILITY_FIXED_SOURCE
      try {
        // Two-argument overload: CHANGE_FRAME_RATE_ONLY_IF_SEAMLESS.
        surface.setFrameRate(frameRate, compatibility)
        Log.d(TAG, "Surface.setFrameRate($frameRate, compatibility=$compatibility)")
      } catch (e: IllegalStateException) {
        // The Surface was abandoned between the validity check and the call.
        Log.w(TAG, "Surface.setFrameRate($frameRate) failed", e)
      }
    }
  }
}

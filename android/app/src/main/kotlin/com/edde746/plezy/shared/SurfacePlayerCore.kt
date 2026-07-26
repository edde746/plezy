package com.edde746.plezy.shared

/**
 * Surface and display concerns that the ExoPlayer and mpv cores implement
 * identically, so a plugin holding either one dispatches without branching
 * on which backend is active.
 *
 * Only backend-independent members belong here: playback control
 * (play/seek/track selection) stays off this interface because mpv drives it
 * through properties and commands where ExoPlayer uses direct method calls.
 */
interface SurfacePlayerCore {
  fun setVisible(visible: Boolean)
  fun updateFrame()
  fun onPipModeChanged(isInPipMode: Boolean)
  fun requestAudioFocus(): Boolean
  fun abandonAudioFocus()
  fun clearVideoFrameRate()
  fun setVideoFrameRate(
    fps: Float,
    videoDurationMs: Long,
    extraDelayMs: Long,
    videoWidth: Int,
    videoHeight: Int,
    onComplete: (switched: Boolean) -> Unit
  )
}

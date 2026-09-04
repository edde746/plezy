package com.edde746.plezy.mpv

import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow

/**
 * Pure geometry for the video plane's surface rectangle.
 *
 * The fork `vo=mediacodec` scales decoded buffers to the whole Surface and
 * implements none of mpv's src/dst rect math, so aspect, cover and zoom are
 * view geometry: the video surface is sized to the rectangle the image should
 * occupy and the container clips whatever falls outside it. That mirrors the
 * ExoPlayer path, which scales its own surface and keeps the subtitle overlay
 * on the full-size container.
 */
internal object VideoRectPolicy {
  /**
   * `video-zoom` is reachable from the user's mpv.conf, where an absurd value
   * is a compositor allocation rather than just arithmetic. Bounds it well
   * outside the range the player's own zoom control offers.
   */
  private const val MAX_ZOOM_LOG2 = 2f

  data class Size(val width: Int, val height: Int)

  /**
   * Size for the video surface, or null when a dimension is not known yet.
   *
   * [panscan] is mpv's 0..1 property: 0 fits the image inside the container
   * (letterbox), 1 fills it (crop), values between interpolate the scale.
   * [videoZoomLog2] is mpv's `video-zoom`, a log2 factor, applied on top.
   */
  fun sizeFor(
    containerWidth: Int,
    containerHeight: Int,
    videoWidth: Int,
    videoHeight: Int,
    panscan: Float = 0f,
    videoZoomLog2: Float = 0f
  ): Size? {
    if (containerWidth <= 0 || containerHeight <= 0 || videoWidth <= 0 || videoHeight <= 0) return null
    val fit = min(containerWidth.toFloat() / videoWidth, containerHeight.toFloat() / videoHeight)
    val cover = max(containerWidth.toFloat() / videoWidth, containerHeight.toFloat() / videoHeight)
    val pan = panscan.coerceIn(0f, 1f)
    val zoom = 2.0f.pow(videoZoomLog2.coerceIn(-MAX_ZOOM_LOG2, MAX_ZOOM_LOG2))
    val scale = (fit + (cover - fit) * pan) * zoom
    return Size(
      width = (videoWidth * scale).toInt().coerceAtLeast(1),
      height = (videoHeight * scale).toInt().coerceAtLeast(1)
    )
  }
}

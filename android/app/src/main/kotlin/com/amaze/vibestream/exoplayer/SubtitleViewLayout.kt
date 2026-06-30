package com.amaze.vibestream.exoplayer

import androidx.media3.ui.AspectRatioFrameLayout
import kotlin.math.roundToInt

internal data class SubtitleViewDimensions(val width: Int, val height: Int)

internal object SubtitleViewLayout {
  fun textDimensions(
    containerWidth: Int,
    containerHeight: Int,
    videoWidth: Int,
    videoHeight: Int,
    pixelRatio: Float,
    resizeMode: Int,
    zoomScale: Float
  ): SubtitleViewDimensions? {
    val videoAspect = videoAspect(videoWidth, videoHeight, pixelRatio) ?: return null
    if (containerWidth <= 0 || containerHeight <= 0) return null

    if (resizeMode != AspectRatioFrameLayout.RESIZE_MODE_FIT) {
      return SubtitleViewDimensions(containerWidth, containerHeight)
    }

    val base = fit(containerWidth, containerHeight, videoAspect)
    return when {
      zoomScale < 0.999f -> scale(base, zoomScale)
      zoomScale > 1.001f -> SubtitleViewDimensions(containerWidth, containerHeight)
      else -> base
    }
  }

  fun bitmapDimensions(
    containerWidth: Int,
    containerHeight: Int,
    videoWidth: Int,
    videoHeight: Int,
    pixelRatio: Float,
    resizeMode: Int,
    zoomScale: Float
  ): SubtitleViewDimensions? {
    val videoAspect = videoAspect(videoWidth, videoHeight, pixelRatio) ?: return null
    if (containerWidth <= 0 || containerHeight <= 0) return null

    // PGS/VOB cues are authored in video coordinates, but users expect them to
    // remain readable and fully visible when the video is cropped or zoomed.
    // Fit to the visible container instead of following the cropped video rect.
    return fit(containerWidth, containerHeight, videoAspect)
  }

  private fun videoAspect(videoWidth: Int, videoHeight: Int, pixelRatio: Float): Float? {
    if (videoWidth <= 0 || videoHeight <= 0 || pixelRatio <= 0f) return null
    val aspect = (videoWidth * pixelRatio) / videoHeight
    return if (aspect.isFinite() && aspect > 0f) aspect else null
  }

  // Largest [videoAspect] rectangle that fits inside the container, as (width, height)
  // in float pixels. Shared by the SubtitleView sizing (rounded to ints in [fit]) and
  // the libass FIT-mode margins in updateAssMargins() (kept as floats for the zoom
  // multiply) so both agree on the video dst rect.
  fun letterbox(containerWidth: Int, containerHeight: Int, videoAspect: Float): Pair<Float, Float> {
    val containerAspect = containerWidth.toFloat() / containerHeight
    return if (videoAspect > containerAspect) {
      containerWidth.toFloat() to containerWidth / videoAspect
    } else {
      containerHeight * videoAspect to containerHeight.toFloat()
    }
  }

  private fun fit(containerWidth: Int, containerHeight: Int, videoAspect: Float): SubtitleViewDimensions {
    val (width, height) = letterbox(containerWidth, containerHeight, videoAspect)
    return SubtitleViewDimensions(
      width.roundToInt().coerceAtLeast(1),
      height.roundToInt().coerceAtLeast(1)
    )
  }

  private fun scale(dimensions: SubtitleViewDimensions, scale: Float): SubtitleViewDimensions {
    val safeScale = scale.coerceAtLeast(0.001f)
    return SubtitleViewDimensions(
      (dimensions.width * safeScale).roundToInt().coerceAtLeast(1),
      (dimensions.height * safeScale).roundToInt().coerceAtLeast(1)
    )
  }
}

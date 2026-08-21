package com.edde746.plezy.exoplayer

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
    zoomScale: Float,
    anchorToScreen: Boolean = false
  ): SubtitleViewDimensions? {
    val videoAspect = videoAspect(videoWidth, videoHeight, pixelRatio) ?: return null
    if (containerWidth <= 0 || containerHeight <= 0) return null

    // Anchor-to-screen (#1730): size the text view to the full container so
    // media3's fractional text size and bottom-anchored cue placement compute
    // against the physical screen, letting subtitles render in the letterbox
    // bars instead of inside the video rect. Same geometry the non-FIT modes
    // below already use.
    if (anchorToScreen || resizeMode != AspectRatioFrameLayout.RESIZE_MODE_FIT) {
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
    planeAspect: Float?
  ): SubtitleViewDimensions? {
    if (containerWidth <= 0 || containerHeight <= 0) return null
    val videoAspect = videoAspect(videoWidth, videoHeight, pixelRatio) ?: return null
    val visibleVideoBounds = fit(containerWidth, containerHeight, videoAspect)
    val layoutAspect = planeAspect?.takeIf { it.isFinite() && it > 0f }
      ?: return visibleVideoBounds

    // Media3 expresses bitmap cue positions and dimensions relative to the
    // subtitle composition plane, which can differ from a cropped video's
    // dimensions. Fit that plane inside the visible video bounds so cues keep
    // their authored geometry without entering the letterbox bars.
    return fit(visibleVideoBounds.width, visibleVideoBounds.height, layoutAspect)
  }

  fun bitmapPlaneAspect(
    bitmapWidth: Int,
    bitmapHeight: Int,
    cueWidthFraction: Float,
    cueHeightFraction: Float
  ): Float? {
    if (bitmapWidth <= 0 || bitmapHeight <= 0) return null
    if (!cueWidthFraction.isFinite() || cueWidthFraction <= 0f) return null
    if (!cueHeightFraction.isFinite() || cueHeightFraction <= 0f) return null

    // cueWidth = bitmapWidth / planeWidth and cueHeight = bitmapHeight / planeHeight.
    val aspect = bitmapWidth.toDouble() * cueHeightFraction.toDouble() /
      (bitmapHeight.toDouble() * cueWidthFraction.toDouble())
    return aspect.toFloat().takeIf { it.isFinite() && it > 0f }
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

package com.edde746.plezy.mpv

import kotlin.math.roundToInt

/**
 * Pure geometry for the `vo=mediacodec` subtitle/OSD plane.
 *
 * mpv rasterizes subtitles at whatever size the OSD Surface reports, so the
 * "Render Resolution" setting is applied by giving the OSD SurfaceView a
 * fixed buffer size below its view size; SurfaceFlinger scales the plane back
 * up. Every stage of the OSD pass (libass rasterization, the software
 * composite, the Surface copy) is proportional to that pixel count, which is
 * what makes the setting a throughput knob on render-bound TV hardware. The
 * ExoPlayer path applies the same fraction to its libass overlay.
 */
internal object OsdPlanePolicy {
  data class Size(val width: Int, val height: Int)

  /**
   * Fixed buffer size for an OSD plane whose view measures [viewWidth] x
   * [viewHeight], or null when the plane should track the view (full
   * resolution, or a view that has not been laid out yet).
   *
   * Dimensions are rounded to even values: the 4:2:0-derived alignment
   * assumptions in the compositor stack are cheap to honor here and an odd
   * OSD width buys nothing.
   */
  fun fixedSizeFor(viewWidth: Int, viewHeight: Int, renderScale: Float): Size? {
    if (viewWidth <= 0 || viewHeight <= 0) return null
    if (!(renderScale > 0f) || renderScale >= 1f) return null
    return Size(
      width = scaledEven(viewWidth, renderScale),
      height = scaledEven(viewHeight, renderScale)
    )
  }

  private fun scaledEven(value: Int, scale: Float): Int {
    val scaled = (value * scale).roundToInt().coerceAtLeast(2)
    return scaled and 1.inv()
  }
}

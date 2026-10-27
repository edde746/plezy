package com.edde746.plezy.shared

import android.content.Context
import android.os.Build
import android.util.Log
import android.view.Display
import android.view.WindowManager

object DisplayHdrCapabilities {
  private const val TAG = "DisplayHdrCapabilities"

  fun displaySupportsDolbyVision(context: Context): Boolean {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
      Log.i(TAG, "Display Dolby Vision support: false (HDR capabilities require API 24, device API=${Build.VERSION.SDK_INT})")
      return false
    }

    val display = getCurrentDisplay(context)
    if (display == null) {
      Log.i(TAG, "Display Dolby Vision support: false (no active display)")
      return false
    }

    val hdrTypes = runCatching { getDisplayHdrTypes(display) }.getOrElse { error ->
      Log.w(TAG, "Display Dolby Vision support: false (failed to query HDR types)", error)
      return false
    }
    val supported = hdrTypes.contains(Display.HdrCapabilities.HDR_TYPE_DOLBY_VISION)
    Log.i(TAG, "Display Dolby Vision support: $supported; ${describeDisplayHdrCapabilities(display)}")
    return supported
  }

  /** Whether the active display advertises any HDR output type. */
  fun displaySupportsHdr(context: Context): Boolean {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return false
    val display = getCurrentDisplay(context) ?: return false
    val hdrTypes = runCatching { getDisplayHdrTypes(display) }.getOrElse { error ->
      Log.w(TAG, "Display HDR support: failed to query HDR types", error)
      return false
    }
    return hdrTypes.isNotEmpty()
  }

  private fun getCurrentDisplay(context: Context): Display? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
    context.display
  } else {
    @Suppress("DEPRECATION")
    (context.getSystemService(Context.WINDOW_SERVICE) as? WindowManager)?.defaultDisplay
  }

  private fun describeHdrTypes(hdrTypes: IntArray): String {
    if (hdrTypes.isEmpty()) return "none"
    return hdrTypes.joinToString(prefix = "[", postfix = "]") { type ->
      when (type) {
        Display.HdrCapabilities.HDR_TYPE_DOLBY_VISION -> "DOLBY_VISION"
        Display.HdrCapabilities.HDR_TYPE_HDR10 -> "HDR10"
        Display.HdrCapabilities.HDR_TYPE_HLG -> "HLG"
        Display.HdrCapabilities.HDR_TYPE_HDR10_PLUS -> "HDR10_PLUS"
        else -> "unknown(${hex(type)})"
      }
    }
  }

  private fun describeDisplayHdrCapabilities(display: Display): String {
    val hdrCapabilities = getDisplayHdrCapabilities(display)
    val parts = mutableListOf(
      "display=${display.displayId}:${display.name}",
      "activeMode=${describeDisplayMode(display.mode)}"
    )
    if (hdrCapabilities == null) {
      parts += "hdrCapabilities=unavailable"
    } else {
      @Suppress("DEPRECATION")
      parts += "hdrCapabilities=${describeHdrTypes(hdrCapabilities.supportedHdrTypes)}"
      parts += "desiredLuminance=max=${formatLuminance(hdrCapabilities.desiredMaxLuminance)}, " +
        "maxAvg=${formatLuminance(hdrCapabilities.desiredMaxAverageLuminance)}, " +
        "min=${formatLuminance(hdrCapabilities.desiredMinLuminance)}"
    }
    parts += "supportedModes=${display.supportedModes.joinToString(prefix = "[", postfix = "]") { describeDisplayMode(it) }}"
    return parts.joinToString(prefix = "{", postfix = "}")
  }

  private fun getDisplayHdrCapabilities(display: Display): Display.HdrCapabilities? = runCatching {
    display.hdrCapabilities
  }.onFailure { Log.w(TAG, "Failed to query display HDR capabilities", it) }.getOrNull()

  private fun getDisplayHdrTypes(display: Display): IntArray {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
      runCatching { display.mode.supportedHdrTypes }
        .onSuccess { return it }
        .onFailure { Log.w(TAG, "Failed to query mode HDR types; falling back to display HDR capabilities", it) }
    }

    @Suppress("DEPRECATION")
    return getDisplayHdrCapabilities(display)?.supportedHdrTypes ?: IntArray(0)
  }

  private fun describeDisplayMode(mode: Display.Mode): String {
    val hdr = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
      ", hdr=${describeHdrTypes(mode.supportedHdrTypes)}"
    } else {
      ""
    }
    return "#${mode.modeId} ${mode.physicalWidth}x${mode.physicalHeight}@${mode.refreshRate}Hz$hdr"
  }

  private fun formatLuminance(value: Float): String = if (value.isNaN() || value <= 0f) "unknown" else "${value}nits"

  private fun hex(value: Int): String = "0x${value.toString(16)}"
}

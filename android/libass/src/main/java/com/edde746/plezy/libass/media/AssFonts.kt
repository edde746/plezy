package com.edde746.plezy.libass.media

/**
 * Shared policy for embedded font attachments delivered to libass: which
 * attachment mime types are fonts, and the per-font/aggregate byte budgets
 * that keep a hostile container from ballooning the font store.
 */
object AssFonts {
  const val MAX_FONT_BYTES = 16L * 1024 * 1024
  const val MAX_TOTAL_FONT_BYTES = 32L * 1024 * 1024

  val fontMimeTypes = listOf(
    "font/ttf",
    "font/otf",
    "font/sfnt",
    "font/woff",
    "font/woff2",
    "application/font-sfnt",
    "application/font-woff",
    "application/x-truetype-font",
    "application/vnd.ms-opentype",
    "application/x-font-ttf"
  )

  /** Null to accept the font, or a human-readable rejection reason. */
  fun rejectionReason(size: Long, acceptedBytes: Long): String? = when {
    size > MAX_FONT_BYTES -> "per-font limit"
    size > MAX_TOTAL_FONT_BYTES - acceptedBytes -> "aggregate limit"
    else -> null
  }
}

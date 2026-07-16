package com.edde746.plezy.libass.media.parser

import androidx.annotation.OptIn
import androidx.media3.common.Format
import androidx.media3.common.util.UnstableApi

@OptIn(UnstableApi::class)
object AssHeaderParser {

  private const val ASS_EVENTS = "[Events]\n" +
    "Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text"

  /**
   * Fix some ass header with error end.
   * https://github.com/jellyfin/jellyfin-ffmpeg/issues/506
   */
  private fun fixAssHeaderIfNeed(buffer: ByteArray): ByteArray = if (buffer[buffer.size - 1] != 0.toByte()) {
    // validate ass header
    buffer
  } else {
    // remote the last null character and append the events tag
    (String(buffer, 0, buffer.size - 1) + "\n" + ASS_EVENTS).toByteArray()
  }

  /**
   * Parses the headers from the initialization data of the given [format]. The original
   * headers are preserved (duplication checks are handled by libass).
   */
  fun parse(format: Format): ByteArray = fixAssHeaderIfNeed(format.initializationData[1])
}

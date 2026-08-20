package com.edde746.plezy.libass.media.parser

import androidx.annotation.OptIn
import androidx.media3.common.Format
import androidx.media3.common.util.UnstableApi

@OptIn(UnstableApi::class)
object AssHeaderParser {

  private const val ASS_EVENTS = "[Events]\n" +
    "Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text"
  private val assEventsSuffix = ("\n" + ASS_EVENTS).toByteArray(Charsets.UTF_8)

  /**
   * Matroska CodecPrivate data may omit the events section and end with one or more NUL
   * terminators. Remove every terminator before checking or appending the section so an
   * embedded NUL cannot hide the event format from libass.
   *
   * https://github.com/jellyfin/jellyfin-ffmpeg/issues/506
   */
  private fun normalizeHeader(buffer: ByteArray): ByteArray {
    var contentLength = buffer.size
    while (contentLength > 0 && buffer[contentLength - 1] == 0.toByte()) {
      contentLength--
    }

    val header = String(buffer, 0, contentLength, Charsets.UTF_8)
    val hasEventsSection = header.lineSequence().any {
      it.trim().equals("[Events]", ignoreCase = true)
    }
    if (hasEventsSection) {
      return if (contentLength == buffer.size) buffer else buffer.copyOf(contentLength)
    }

    return buffer.copyOf(contentLength + assEventsSuffix.size).also {
      assEventsSuffix.copyInto(it, destinationOffset = contentLength)
    }
  }

  /**
   * Parses and normalizes the ASS header from the initialization data of the given [format].
   */
  fun parse(format: Format): ByteArray = normalizeHeader(format.initializationData[1])
}

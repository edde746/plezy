package com.edde746.plezy.exoplayer

import java.util.Locale

/**
 * Builds text subtitle samples in the exact shape media3's MatroskaExtractor
 * writes, so the same downstream consumers work behind the FFmpeg demuxer:
 * the bundled SsaParser/SubripParser/WebvttParser (via
 * SubtitleTranscodingExtractorOutput) and AssTrackOutput's dialogue feed.
 *
 * MatroskaExtractor prefixes each raw payload with a synthetic header whose
 * *second* timecode carries the sample duration (BlockDuration), while the
 * first stays zero; parsers reconstruct absolute times as sampleTimeUs +
 * parsedStart. FFmpeg hands us the same raw payloads (an ASS packet is the
 * MKV block: "ReadOrder,Layer,Style,...,Text"; SubRip/WebVTT packets are the
 * bare cue text), so only the prefix needs synthesizing.
 */
internal object FfmpegSubtitleSamples {

  val SSA_DIALOGUE_FORMAT: ByteArray =
    "Format: Start, End, ReadOrder, Layer, Style, Name, MarginL, MarginR, MarginV, Effect, Text"
      .toByteArray(Charsets.UTF_8)

  /** `Dialogue: 0:00:00:00,H:MM:SS:CC,` — centiseconds, ':' separator (media3's SSA shape). */
  fun ssaPrefix(durationUs: Long): ByteArray = "Dialogue: 0:00:00:00,${timecode(durationUs, "%01d:%02d:%02d:%02d", 10_000)},"
    .toByteArray(Charsets.UTF_8)

  /** `1\n00:00:00,000 --> HH:MM:SS,mmm\n` — a complete SRT cue header. */
  fun subripPrefix(durationUs: Long): ByteArray = "1\n00:00:00,000 --> ${timecode(durationUs, "%02d:%02d:%02d,%03d", 1_000)}\n"
    .toByteArray(Charsets.UTF_8)

  /** `WEBVTT\n\n00:00:00.000 --> HH:MM:SS.mmm\n` — a one-cue WebVTT document header. */
  fun vttPrefix(durationUs: Long): ByteArray = "WEBVTT\n\n00:00:00.000 --> ${timecode(durationUs, "%02d:%02d:%02d.%03d", 1_000)}\n"
    .toByteArray(Charsets.UTF_8)

  private fun timecode(timeUs: Long, format: String, lastValueDivisor: Long): String {
    val hours = timeUs / 3_600_000_000L
    var remainder = timeUs - hours * 3_600_000_000L
    val minutes = remainder / 60_000_000L
    remainder -= minutes * 60_000_000L
    val seconds = remainder / 1_000_000L
    remainder -= seconds * 1_000_000L
    val lastValue = remainder / lastValueDivisor
    return String.format(Locale.US, format, hours, minutes, seconds, lastValue)
  }
}

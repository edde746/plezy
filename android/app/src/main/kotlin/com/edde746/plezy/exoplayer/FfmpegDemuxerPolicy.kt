package com.edde746.plezy.exoplayer

/**
 * Decides whether the FFmpeg demuxer sits ahead of media3's own extractors.
 *
 * FFmpeg demuxes every progressive container by default. media3's bundled
 * extractors were weak exactly where this app kept accumulating container
 * patches — AVI (XviD packed-bitstream timestamps, missing VOL csd — issue
 * #2052), ASF/WMV (no extractor at all), MPEG-PS/VOB (no extractor), and
 * Matroska (zlib-compressed subtitles, LOAS/LATM audio as A_MS/ACM, cueless
 * seeking, font attachments) — and libavformat handles all of it natively.
 * media3's extractors stay behind FFmpeg in the list, so a container FFmpeg
 * fails to sniff still reaches media3's parsers. [Preference.MEDIA3_ONLY] is
 * the user-facing escape hatch in case a file misbehaves on the FFmpeg path.
 */
internal object FfmpegDemuxerPolicy {
  enum class Preference(val wireName: String) {
    FFMPEG("ffmpeg"),
    MEDIA3_ONLY("media3")
  }

  /** Unknown wire values (including the retired "auto") resolve to FFmpeg. */
  fun fromWire(value: String?): Preference = Preference.entries.firstOrNull { it.wireName == value } ?: Preference.FFMPEG

  /** Whether the FFmpeg extractor placed before media3's list demuxes at all. */
  fun enabled(preference: Preference): Boolean = preference == Preference.FFMPEG
}

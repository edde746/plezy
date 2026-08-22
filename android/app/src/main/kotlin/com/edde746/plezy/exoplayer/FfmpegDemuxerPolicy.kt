package com.edde746.plezy.exoplayer

/**
 * Decides where the FFmpeg demuxer sits relative to media3's own extractors.
 *
 * media3's bundled extractors are strong for MP4/TS and weak exactly where
 * this app kept accumulating container patches: AVI (XviD packed-bitstream
 * timestamps, missing VOL csd — issue #2052), ASF/WMV (no extractor at all),
 * MPEG-PS/VOB (no extractor), and Matroska (zlib-compressed subtitles,
 * LOAS/LATM audio as A_MS/ACM, cueless seeking, font attachments — all of
 * which libavformat handles natively). "Auto" therefore puts FFmpeg first for
 * those families and leaves everything else on media3, with an any-container
 * FFmpeg fallback behind media3's list so exotic containers still play
 * instead of failing outright.
 */
internal object FfmpegDemuxerPolicy {
  enum class Preference(val wireName: String) {
    AUTO("auto"),
    FFMPEG_FIRST("ffmpeg"),
    MEDIA3_ONLY("media3")
  }

  /**
   * Containers FFmpeg demuxes ahead of media3 under Auto. Probed short names
   * from libavformat: "avi" covers AVI/DIVX, "asf" covers WMV, "mpeg" covers
   * MPEG-PS and VOB, "matroska,webm" covers MKV and WebM.
   */
  val FFMPEG_FIRST_CONTAINERS = setOf("avi", "asf", "mpeg", "matroska,webm")

  fun fromWire(value: String?): Preference = Preference.entries.firstOrNull { it.wireName == value } ?: Preference.AUTO

  /**
   * Whether the FFmpeg extractor placed before media3's list accepts a probed
   * container name. Under [Preference.FFMPEG_FIRST] it accepts everything, so
   * the trailing catch-all becomes redundant but harmless.
   */
  fun primaryAccepts(preference: Preference, probedContainer: String): Boolean = when (preference) {
    Preference.MEDIA3_ONLY -> false
    Preference.FFMPEG_FIRST -> true
    Preference.AUTO -> probedContainer.lowercase() in FFMPEG_FIRST_CONTAINERS
  }

  /** Whether the any-container FFmpeg fallback behind media3's list exists. */
  fun catchAllEnabled(preference: Preference): Boolean = preference != Preference.MEDIA3_ONLY
}

package com.edde746.plezy.exoplayer

/**
 * RFC 6381 codecs strings for Dolby Vision tracks, mirroring media3's
 * `DolbyVisionConfig.parse` profile table so the FFmpeg demux path publishes
 * the same format media3's own MP4/Matroska extractors would: recognized
 * profiles get `video/dolby-vision` plus this string, unrecognized profiles
 * keep the base codec's format untouched.
 */
internal object DoviCodecs {

  /**
   * Codecs string for a DOVIDecoderConfigurationRecord's [profile]/[level],
   * or null when media3 does not recognize the profile (the track then plays
   * as its base codec).
   */
  fun rfc6381(profile: Int, level: Int): String? {
    val prefix = when (profile) {
      4, 5, 7, 8 -> "dvhe"
      9 -> "dvav"
      10 -> "dav1"
      else -> return null
    }
    return "%s.%02d.%02d".format(prefix, profile, level)
  }
}

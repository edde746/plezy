package com.edde746.plezy.exoplayer

/**
 * Identity of a side-loaded subtitle across media3's media-source merging.
 *
 * Each `MediaItem.SubtitleConfiguration` is tagged with [idFor], and the tag is
 * read back off the `Format` the track selector reports. The tag does not
 * survive verbatim: `DefaultMediaSourceFactory.createMediaSource` always wraps
 * the primary source plus one source per subtitle configuration in a
 * `MergingMediaSource`, and since media3 1.3.0 `MergingMediaPeriod.onPrepared`
 * rewrites every child format id to `"<periodIndex>:<originalId>"`. A second
 * merge — the one this player builds for container sidecars — prefixes it
 * again. So the same configuration can surface as `external_0`,
 * `1:external_0`, or `0:1:external_0`.
 *
 * Only the final `:`-separated segment carries the tag, which is why matching
 * on the whole id silently classifies every sidecar as an embedded track.
 */
internal object ExternalSubtitleIds {
  private const val PREFIX = "external_"

  /** Tag written onto the [index]th side-loaded subtitle configuration. */
  fun idFor(index: Int): String = "$PREFIX$index"

  /** Whether [formatId] identifies a side-loaded subtitle. */
  fun isExternal(formatId: String?): Boolean = tagOf(formatId) != null

  /**
   * Index passed to [idFor], or null when [formatId] is not a side-loaded
   * subtitle or carries a tag this build did not write.
   */
  fun indexOf(formatId: String?): Int? = tagOf(formatId)?.toIntOrNull()

  private fun tagOf(formatId: String?): String? {
    // substringAfterLast returns the whole string when no ':' is present, which
    // is the unmerged case.
    val segment = formatId?.substringAfterLast(':') ?: return null
    return if (segment.startsWith(PREFIX)) segment.removePrefix(PREFIX) else null
  }
}

package com.edde746.plezy.libass.media.parser

import androidx.media3.common.Format
import androidx.media3.common.util.Consumer
import androidx.media3.common.util.UnstableApi
import androidx.media3.extractor.text.CuesWithTiming
import androidx.media3.extractor.text.SubtitleParser
import com.edde746.plezy.libass.AssTrack

/**
 * Parser for full (non-embedded) ASS documents, e.g. external sidecar files.
 * Feeds the whole document into the libass track; rendering happens on the
 * overlay surface, so no Media3 cues are emitted.
 */
@UnstableApi
class AssFullSubtitleParser(private val track: AssTrack) : SubtitleParser {

  override fun parse(
    data: ByteArray,
    offset: Int,
    length: Int,
    outputOptions: SubtitleParser.OutputOptions,
    output: Consumer<CuesWithTiming>
  ) {
    track.readBuffer(data, offset, length)
  }

  override fun getCueReplacementBehavior(): Int = Format.CUE_REPLACEMENT_BEHAVIOR_REPLACE
}

package com.edde746.plezy.libass.media.parser

import androidx.media3.common.Format
import androidx.media3.common.util.Consumer
import androidx.media3.common.util.UnstableApi
import androidx.media3.extractor.text.CuesWithTiming
import androidx.media3.extractor.text.SubtitleParser

/**
 * No operation subtitle parser.
 */
@UnstableApi
class AssNoOpSubtitleParser : SubtitleParser {
  override fun parse(
    p0: ByteArray,
    p1: Int,
    p2: Int,
    p3: SubtitleParser.OutputOptions,
    p4: Consumer<CuesWithTiming>
  ) {
  }

  override fun getCueReplacementBehavior(): Int = Format.CUE_REPLACEMENT_BEHAVIOR_REPLACE
}

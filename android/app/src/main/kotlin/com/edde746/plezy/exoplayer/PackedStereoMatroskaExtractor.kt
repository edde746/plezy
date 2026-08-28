package com.edde746.plezy.exoplayer

import androidx.media3.common.util.UnstableApi
import androidx.media3.extractor.mkv.MatroskaExtractor
import androidx.media3.extractor.text.SubtitleParser

/** Observes raw Matroska StereoMode while delegating parsing to Media3. */
@UnstableApi
internal class PackedStereoMatroskaExtractor(
  subtitleParserFactory: SubtitleParser.Factory,
  flags: @MatroskaExtractor.Flags Int,
  private val onStereoMode: (Long) -> Unit
) : MatroskaExtractor(subtitleParserFactory, flags) {
  override fun integerElement(id: Int, value: Long) {
    super.integerElement(id, value)
    if (id == ID_STEREO_MODE) onStereoMode(value)
  }

  private companion object {
    const val ID_STEREO_MODE = 0x53B8
  }
}

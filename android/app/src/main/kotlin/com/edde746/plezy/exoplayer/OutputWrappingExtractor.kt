package com.edde746.plezy.exoplayer

import androidx.media3.common.util.UnstableApi
import androidx.media3.extractor.Extractor
import androidx.media3.extractor.ExtractorInput
import androidx.media3.extractor.ExtractorOutput
import androidx.media3.extractor.PositionHolder

/**
 * Delegates everything to [delegate] but hands it a wrapped [ExtractorOutput].
 * Used to compose the text pipeline (libass dialogue feed + subtitle cue
 * transcoding) around media3's raw-subtitle MatroskaExtractor without
 * subclassing or reflection.
 */
@UnstableApi
internal class OutputWrappingExtractor(
  private val delegate: Extractor,
  private val wrap: (ExtractorOutput) -> ExtractorOutput
) : Extractor {
  override fun sniff(input: ExtractorInput): Boolean = delegate.sniff(input)

  override fun init(output: ExtractorOutput) = delegate.init(wrap(output))

  override fun read(input: ExtractorInput, seekPosition: PositionHolder): Int = delegate.read(input, seekPosition)

  override fun seek(position: Long, timeUs: Long) = delegate.seek(position, timeUs)

  override fun release() = delegate.release()

  override fun getUnderlyingImplementation(): Extractor = delegate.underlyingImplementation
}

package com.edde746.plezy.libass.media.text

import androidx.media3.common.C
import androidx.media3.common.util.UnstableApi
import androidx.media3.extractor.ExtractorOutput
import androidx.media3.extractor.TrackOutput
import com.edde746.plezy.libass.media.AssHandler
import com.edde746.plezy.libass.media.extractor.AssMatroskaExtractor

/**
 * This class is only used by the overlay renderer. It's needed to get the start time of the subtitles.
 */
@UnstableApi
class AssSubtitleExtractorOutput(
  private val delegate: ExtractorOutput,
  private val assHandler: AssHandler,
  private val extractor: AssMatroskaExtractor
) : ExtractorOutput by delegate {
  override fun track(id: Int, type: Int): TrackOutput = if (type == C.TRACK_TYPE_TEXT) {
    // We can't know at this time if the subtitle track is ASS or other format, so we wrap
    // every subtitle track
    AssTrackOutput(delegate.track(id, type), assHandler, extractor)
  } else {
    delegate.track(id, type)
  }
}

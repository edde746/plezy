package com.edde746.plezy.libass.media.text

import androidx.media3.common.C
import androidx.media3.common.util.UnstableApi
import androidx.media3.extractor.ExtractorOutput
import androidx.media3.extractor.TrackOutput
import com.edde746.plezy.libass.media.AssHandler

/**
 * Wraps every text track with [AssTrackOutput] so embedded ASS dialogue
 * reaches libass. Install it on the raw-subtitle side of the output chain —
 * between the extractor and the SubtitleTranscodingExtractorOutput — so the
 * dialogue bytes are still unparsed when they pass through.
 */
@UnstableApi
class AssSubtitleExtractorOutput(
  private val delegate: ExtractorOutput,
  private val assHandler: AssHandler
) : ExtractorOutput by delegate {
  override fun track(id: Int, type: Int): TrackOutput = if (type == C.TRACK_TYPE_TEXT) {
    // We can't know at this time if the subtitle track is ASS or another
    // format, so we wrap every subtitle track; non-ASS tracks pass through.
    AssTrackOutput(delegate.track(id, type), assHandler::readTrackDialogue)
  } else {
    delegate.track(id, type)
  }
}

package com.edde746.plezy.libass.media.parser

import androidx.media3.common.Format
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.UnstableApi
import androidx.media3.extractor.text.DefaultSubtitleParserFactory
import androidx.media3.extractor.text.SubtitleParser
import com.edde746.plezy.libass.media.AssHandler

@UnstableApi
class AssSubtitleParserFactory(private val assHandler: AssHandler) : SubtitleParser.Factory {

  private val defaultSubtitleParserFactory = DefaultSubtitleParserFactory()

  override fun supportsFormat(format: Format): Boolean = defaultSubtitleParserFactory.supportsFormat(format)

  override fun getCueReplacementBehavior(format: Format): Int = defaultSubtitleParserFactory.getCueReplacementBehavior(format)

  override fun create(format: Format): SubtitleParser = if (format.sampleMimeType == MimeTypes.TEXT_SSA) {
    val embeddedSubtitles = MimeTypes.VIDEO_MATROSKA
      .contentEquals(format.containerMimeType)
    val track = assHandler.createTrack(format)
    if (embeddedSubtitles) {
      // Embedded dialogue lines reach libass via AssTrackOutput; nothing to parse here.
      AssNoOpSubtitleParser()
    } else {
      AssFullSubtitleParser(track)
    }
  } else {
    defaultSubtitleParserFactory.create(format)
  }
}

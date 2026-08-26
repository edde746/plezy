package com.edde746.plezy.libass.media.extractor

import android.util.Log
import androidx.annotation.OptIn
import androidx.media3.common.ParserException
import androidx.media3.common.util.ParsableByteArray
import androidx.media3.common.util.UnstableApi
import androidx.media3.extractor.ExtractorInput
import androidx.media3.extractor.ExtractorOutput
import androidx.media3.extractor.mkv.EbmlProcessor
import androidx.media3.extractor.mkv.MatroskaExtractor
import androidx.media3.extractor.text.SubtitleParser
import com.edde746.plezy.libass.media.AssHandler
import com.edde746.plezy.libass.media.text.AssSubtitleExtractorOutput

@OptIn(UnstableApi::class)
open class AssMatroskaExtractor(
  subtitleParserFactory: SubtitleParser.Factory,
  private val assHandler: AssHandler,
  flags: Int = 0
) : MatroskaExtractor(subtitleParserFactory, flags) {

  private var currentAttachmentName: String? = null
  private var currentAttachmentMime: String? = null
  internal var acceptedFontBytes = 0L
    private set

  internal val subtitleSample = subtitleSampleField.get(this) as ParsableByteArray

  override fun getElementType(id: Int): Int = when (id) {
    ID_ATTACHMENTS -> EbmlProcessor.ELEMENT_TYPE_MASTER
    ID_ATTACHED_FILE -> EbmlProcessor.ELEMENT_TYPE_MASTER
    ID_FILE_NAME -> EbmlProcessor.ELEMENT_TYPE_STRING
    ID_FILE_MIME_TYPE -> EbmlProcessor.ELEMENT_TYPE_STRING
    ID_FILE_DATA -> EbmlProcessor.ELEMENT_TYPE_BINARY
    else -> super.getElementType(id)
  }

  override fun isLevel1Element(id: Int): Boolean = super.isLevel1Element(id) || id == ID_ATTACHMENTS

  override fun startMasterElement(id: Int, contentPosition: Long, contentSize: Long) {
    when (id) {
      ID_EBML -> {
        val currentExtractor = extractorOutput.get(this) as ExtractorOutput
        if (currentExtractor !is AssSubtitleExtractorOutput) {
          extractorOutput.set(
            this,
            AssSubtitleExtractorOutput(currentExtractor, assHandler, this)
          )
        }
        super.startMasterElement(id, contentPosition, contentSize)
      }
      ID_ATTACHED_FILE -> clearAttachment()
      else -> super.startMasterElement(id, contentPosition, contentSize)
    }
  }

  override fun endMasterElement(id: Int) {
    when (id) {
      ID_VIDEO -> {
        // We need to get the video dimensions very early
        val track = getCurrentTrack(id)
        assHandler.setVideoSize(track.width, track.height)
        super.endMasterElement(id)
      }
      ID_ATTACHED_FILE -> clearAttachment()
      else -> super.endMasterElement(id)
    }
  }

  override fun stringElement(id: Int, value: String) {
    when (id) {
      ID_FILE_NAME -> currentAttachmentName = value
      ID_FILE_MIME_TYPE -> currentAttachmentMime = value
      else -> super.stringElement(id, value)
    }
  }

  override fun binaryElement(id: Int, contentSize: Int, input: ExtractorInput) {
    when (id) {
      ID_FILE_DATA -> {
        if (contentSize < 0) {
          throw ParserException.createForMalformedContainer(
            "Negative Matroska attachment size",
            null
          )
        }

        val attachmentName = requireNotNull(currentAttachmentName)
        val attachmentMime = requireNotNull(currentAttachmentMime)
        if (attachmentMime !in fontMimeTypes) {
          input.skipFully(contentSize)
          return
        }
        if (contentSize == 0) {
          input.skipFully(0)
          return
        }

        val size = contentSize.toLong()
        val rejectionReason = when {
          size > MAX_FONT_BYTES -> "per-font limit"
          size > MAX_TOTAL_FONT_BYTES - acceptedFontBytes -> "aggregate limit"
          else -> null
        }
        if (rejectionReason != null) {
          onFontRejected(contentSize, acceptedFontBytes, rejectionReason)
          input.skipFully(contentSize)
          return
        }

        val data = ByteArray(contentSize)
        input.readFully(data, 0, contentSize)
        acceptedFontBytes += size
        assHandler.addFont(attachmentName, data)
      }
      else -> super.binaryElement(id, contentSize, input)
    }
  }

  protected open fun onFontRejected(
    contentSize: Int,
    acceptedBytes: Long,
    reason: String
  ) {
    Log.w(
      TAG,
      "Skipping embedded font: $reason (bytes=$contentSize, accepted=$acceptedBytes)"
    )
  }

  private fun clearAttachment() {
    currentAttachmentName = null
    currentAttachmentMime = null
  }

  companion object {
    private const val TAG = "AssMatroskaExtractor"
    internal const val MAX_FONT_BYTES = 16L * 1024 * 1024
    internal const val MAX_TOTAL_FONT_BYTES = 32L * 1024 * 1024
    const val ID_EBML = 0x1A45DFA3
    const val ID_VIDEO = 0xE0
    const val ID_ATTACHMENTS = 0x1941A469
    const val ID_ATTACHED_FILE = 0x61A7
    const val ID_FILE_NAME = 0x466E
    const val ID_FILE_MIME_TYPE = 0x4660
    const val ID_FILE_DATA = 0x465C

    val fontMimeTypes = listOf(
      "font/ttf",
      "font/otf",
      "font/sfnt",
      "font/woff",
      "font/woff2",
      "application/font-sfnt",
      "application/font-woff",
      "application/x-truetype-font",
      "application/vnd.ms-opentype",
      "application/x-font-ttf"
    )

    val extractorOutput = MatroskaExtractor::class.java.getDeclaredField("extractorOutput").apply {
      isAccessible = true
    }
    val subtitleSampleField = MatroskaExtractor::class.java.getDeclaredField("subtitleSample").apply {
      isAccessible = true
    }
  }
}

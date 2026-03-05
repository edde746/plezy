package com.edde746.plezy.exoplayer

import android.util.Log
import androidx.media3.extractor.ExtractorInput
import androidx.media3.extractor.ExtractorOutput
import androidx.media3.extractor.mkv.MatroskaExtractor
import androidx.media3.extractor.text.SubtitleParser
import io.github.peerless2012.ass.media.AssHandler

/**
 * MatroskaExtractor subclass that adds:
 * 1. ASS subtitle support (font extraction from MKV attachments, video size reporting)
 * 2. Dolby Vision Profile 7 → 8.1 conversion (RPU capture from BlockAdditions)
 *
 * Replaces both AssMatroskaExtractor and adds DV handling on top.
 * Font extraction and video size reporting are replicated from AssMatroskaExtractor
 * since that class is final and cannot be extended.
 */
class DoviMatroskaExtractor(
    subtitleParserFactory: SubtitleParser.Factory,
    private val assHandler: AssHandler,
    private val dvMode: DvConversionMode = DvConversionMode.HEVC_STRIP,
) : MatroskaExtractor(subtitleParserFactory) {

    companion object {
        private const val TAG = "DoviMkvExtractor"

        // Matroska element IDs for attachments
        private const val ID_ATTACHMENTS = 0x1941A469
        private const val ID_ATTACHED_FILE = 0x61A7
        private const val ID_FILE_NAME = 0x466E
        private const val ID_FILE_MIME_TYPE = 0x4660
        private const val ID_FILE_DATA = 0x465C

        // Track video element
        private const val ID_VIDEO = 0xE0

        // EBML header - hook point for output wrapping
        private const val ID_EBML = 0x1A45DFA3

        // MKV element type constants (matching MatroskaExtractor internals)
        private const val TYPE_MASTER = 1
        private const val TYPE_STRING = 3
        private const val TYPE_BINARY = 4

        private val FONT_MIME_TYPES = setOf(
            "application/x-truetype-font",
            "application/x-font-truetype",
            "application/vnd.ms-opentype",
            "font/sfnt",
            "font/ttf",
            "font/otf",
            "font/collection",
        )

        private val extractorOutputField by lazy {
            try {
                MatroskaExtractor::class.java.getDeclaredField("extractorOutput").apply {
                    isAccessible = true
                }
            } catch (e: Exception) {
                Log.w(TAG, "Cannot access extractorOutput field: ${e.message}")
                null
            }
        }
    }

    // ASS font attachment state
    private var currentAttachmentName: String? = null
    private var currentAttachmentMime: String? = null

    // DV conversion state
    @Volatile var doviTrackOutput: DoviConvertingTrackOutput? = null
        internal set

    // ===== Matroska element overrides =====

    override fun getElementType(id: Int): Int = when (id) {
        ID_ATTACHMENTS, ID_ATTACHED_FILE -> TYPE_MASTER
        ID_FILE_NAME, ID_FILE_MIME_TYPE -> TYPE_STRING
        ID_FILE_DATA -> TYPE_BINARY
        else -> super.getElementType(id)
    }

    override fun isLevel1Element(id: Int): Boolean =
        super.isLevel1Element(id) || id == ID_ATTACHMENTS

    override fun startMasterElement(id: Int, contentPosition: Long, contentSize: Long) {
        when (id) {
            ID_EBML -> {
                wrapExtractorOutput()
                super.startMasterElement(id, contentPosition, contentSize)
            }
            ID_ATTACHED_FILE -> clearAttachment()
            else -> super.startMasterElement(id, contentPosition, contentSize)
        }
    }

    override fun endMasterElement(id: Int) {
        when (id) {
            ID_VIDEO -> {
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

    override fun binaryElement(id: Int, size: Int, input: ExtractorInput) {
        if (id == ID_FILE_DATA) {
            val mime = currentAttachmentMime
            val name = currentAttachmentName
            if (mime != null && name != null && mime in FONT_MIME_TYPES) {
                val data = ByteArray(size)
                input.readFully(data, 0, size)
                assHandler.addFont(name, data)
            } else {
                input.skipFully(size)
            }
            clearAttachment()
        } else {
            super.binaryElement(id, size, input)
        }
    }

    // ===== ExtractorOutput wrapping =====

    private fun wrapExtractorOutput() {
        val field = extractorOutputField ?: return
        val output = field.get(this) as? ExtractorOutput ?: return
        if (output is DoviExtractorOutputWrapper) return
        field.set(this, DoviExtractorOutputWrapper(output, dvMode) { doviTrackOutput = it })
    }

    private fun clearAttachment() {
        currentAttachmentName = null
        currentAttachmentMime = null
    }
}

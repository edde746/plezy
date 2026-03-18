package com.edde746.plezy.exoplayer

import android.util.Log
import androidx.media3.extractor.ExtractorInput
import androidx.media3.extractor.ExtractorOutput
import androidx.media3.extractor.SeekMap
import androidx.media3.extractor.TrackOutput
import androidx.media3.extractor.mkv.MatroskaExtractor
import io.github.peerless2012.ass.media.AssHandler
import io.github.peerless2012.ass.media.extractor.AssMatroskaExtractor
import androidx.media3.extractor.text.SubtitleParser

/**
 * Extends AssMatroskaExtractor to add support for MKV ContentCompAlgo 0 (zlib).
 *
 * Media3's MatroskaExtractor only supports ContentCompAlgo 3 (header stripping).
 * This subclass intercepts the compression algorithm during track header parsing:
 * - Tells the parent it's header stripping (algo 3) to avoid the ParserException
 * - Wraps TrackOutputs with ZlibInflatingTrackOutput to decompress per-sample data
 * - Skips ContentCompSettings for zlib tracks (not applicable)
 */
class ZlibMatroskaExtractor(
    subtitleParserFactory: SubtitleParser.Factory,
    assHandler: AssHandler,
) : AssMatroskaExtractor(subtitleParserFactory, assHandler) {

    companion object {
        private const val TAG = "ZlibMkvExtractor"

        // Matroska EBML element IDs
        private const val ID_SEGMENT = 0x18538067
        private const val ID_TRACK_ENTRY = 0xAE
        private const val ID_CONTENT_COMPRESSION_ALGORITHM = 0x4254
        private const val ID_CONTENT_COMPRESSION_SETTINGS = 0x4255

        private val extractorOutputField by lazy {
            MatroskaExtractor::class.java.getDeclaredField("extractorOutput").apply {
                isAccessible = true
            }
        }
    }

    private var zlibOutput: ZlibExtractorOutputWrapper? = null
    private var currentTrackUsesZlib = false

    override fun startMasterElement(id: Int, contentPosition: Long, contentSize: Long) {
        super.startMasterElement(id, contentPosition, contentSize)

        // After super installs AssSubtitleExtractorOutput, wrap it with our zlib layer
        if (id == ID_SEGMENT && zlibOutput == null) {
            val currentOutput = extractorOutputField.get(this) as ExtractorOutput
            val wrapper = ZlibExtractorOutputWrapper(currentOutput)
            zlibOutput = wrapper
            extractorOutputField.set(this, wrapper)
            Log.d(TAG, "Installed zlib ExtractorOutput wrapper")
        }
    }

    override fun integerElement(id: Int, value: Long) {
        if (id == ID_CONTENT_COMPRESSION_ALGORITHM && value == 0L) {
            currentTrackUsesZlib = true
            Log.i(TAG, "Track uses ContentCompAlgo 0 (zlib), will inflate samples")
            // Tell parent it's header stripping (algo 3) to avoid ParserException
            super.integerElement(id, 3)
            return
        }
        super.integerElement(id, value)
    }

    override fun binaryElement(id: Int, contentSize: Int, input: ExtractorInput) {
        if (id == ID_CONTENT_COMPRESSION_SETTINGS && currentTrackUsesZlib) {
            // Skip ContentCompSettings for zlib tracks — parent would store these as
            // sampleStrippedBytes and prepend them to every sample, corrupting output.
            input.skipFully(contentSize)
            return
        }
        super.binaryElement(id, contentSize, input)
    }

    override fun endMasterElement(id: Int) {
        val wasZlib = currentTrackUsesZlib
        super.endMasterElement(id)

        if (id == ID_TRACK_ENTRY && wasZlib) {
            zlibOutput?.activateLast()
            currentTrackUsesZlib = false
            Log.i(TAG, "Activated zlib inflation for track")
        }
    }

    /**
     * ExtractorOutput wrapper that wraps all TrackOutputs with ZlibInflatingTrackOutput.
     * Tracks are created inactive; activateLast() enables inflation for the most recently
     * created track (called when we know a track uses zlib compression).
     */
    private class ZlibExtractorOutputWrapper(
        private val delegate: ExtractorOutput,
    ) : ExtractorOutput {

        private var lastCreatedWrapper: ZlibInflatingTrackOutput? = null

        override fun track(id: Int, type: Int): TrackOutput {
            val original = delegate.track(id, type)
            val wrapper = ZlibInflatingTrackOutput(original)
            lastCreatedWrapper = wrapper
            return wrapper
        }

        fun activateLast() {
            lastCreatedWrapper?.active = true
        }

        override fun endTracks() = delegate.endTracks()
        override fun seekMap(seekMap: SeekMap) = delegate.seekMap(seekMap)
    }
}

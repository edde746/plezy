package com.edde746.plezy.exoplayer

import androidx.media3.common.C
import androidx.media3.extractor.Extractor
import androidx.media3.extractor.ExtractorInput
import androidx.media3.extractor.ExtractorOutput
import androidx.media3.extractor.PositionHolder
import androidx.media3.extractor.SeekMap
import androidx.media3.extractor.TrackOutput

/**
 * Extractor decorator for Mp4/FragmentedMp4 containers.
 * Wraps the video TrackOutput with DoviConvertingTrackOutput to perform
 * DV Profile 7 → 8.1 conversion via inline NAL processing.
 *
 * For MP4, RPU (UNSPEC62) and EL (UNSPEC63) NALs are interleaved in sample data,
 * so no BlockAdditions handling is needed.
 */
class DoviExtractorWrapper(
    private val delegate: Extractor,
    private val dvMode: DvConversionMode = DvConversionMode.HEVC_STRIP,
) : Extractor {

    @Volatile var doviTrackOutput: DoviConvertingTrackOutput? = null
        private set

    override fun sniff(input: ExtractorInput): Boolean = delegate.sniff(input)

    override fun init(output: ExtractorOutput) {
        delegate.init(object : ExtractorOutput {
            override fun track(id: Int, type: Int): TrackOutput {
                val original = output.track(id, type)
                if (type == C.TRACK_TYPE_VIDEO) {
                    val wrapper = DoviConvertingTrackOutput(original, dvMode)
                    doviTrackOutput = wrapper
                    return wrapper
                }
                return original
            }

            override fun endTracks() = output.endTracks()
            override fun seekMap(seekMap: SeekMap) = output.seekMap(seekMap)
        })
    }

    override fun read(input: ExtractorInput, seekPosition: PositionHolder): Int =
        delegate.read(input, seekPosition)

    override fun seek(position: Long, timeUs: Long) = delegate.seek(position, timeUs)

    override fun release() = delegate.release()
}

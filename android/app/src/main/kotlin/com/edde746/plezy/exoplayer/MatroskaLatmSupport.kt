package com.edde746.plezy.exoplayer

import androidx.media3.extractor.ExtractorOutput
import androidx.media3.extractor.SeekMap
import androidx.media3.extractor.TrackOutput
import androidx.media3.extractor.mkv.MatroskaExtractor

/** MKV CodecID for Microsoft ACM compatibility mode. */
private const val CODEC_ID_ACM = "A_MS/ACM"

/**
 * MatroskaExtractor.init is final and extractorOutput private; subclasses swap
 * in wrapping outputs via reflection once the Segment element starts (shared
 * with ZlibMatroskaExtractor).
 */
internal val matroskaExtractorOutputField by lazy {
  MatroskaExtractor::class.java.getDeclaredField("extractorOutput").apply {
    isAccessible = true
  }
}

/** WAVEFORMATEX format tag for LOAS/LATM-wrapped AAC (WAVE_FORMAT_MPEG_LOAS). */
private const val WAVE_FORMAT_MPEG_LOAS = 0x1602

/**
 * Returns whether a track is LOAS/LATM AAC muxed as A_MS/ACM — ffmpeg's
 * fallback mapping for aac_latm, which Matroska has no native codec ID for.
 * The WAVEFORMATEX wFormatTag is the first 2 bytes (LE) of CodecPrivate.
 */
fun isLoasAcmTrack(codecId: String?, codecPrivate: ByteArray?): Boolean = codecId == CODEC_ID_ACM &&
  codecPrivate != null &&
  codecPrivate.size >= 2 &&
  ((codecPrivate[0].toInt() and 0xFF) or ((codecPrivate[1].toInt() and 0xFF) shl 8)) == WAVE_FORMAT_MPEG_LOAS

/**
 * ExtractorOutput wrapper that wraps marked tracks with [LatmTrackOutput].
 * Call [markNextTrackLatm] before the parent extractor creates the track
 * (i.e. before super.endMasterElement(ID_TRACK_ENTRY)).
 */
class LatmExtractorOutputWrapper(
  private val delegate: ExtractorOutput
) : ExtractorOutput {

  private var nextTrackIsLatm = false
  private val latmOutputs = mutableListOf<LatmTrackOutput>()

  fun markNextTrackLatm() {
    nextTrackIsLatm = true
  }

  /** Resets LATM parser state after an extractor seek. */
  fun resetTracks() {
    latmOutputs.forEach { it.reset() }
  }

  override fun track(id: Int, type: Int): TrackOutput {
    val original = delegate.track(id, type)
    if (!nextTrackIsLatm) return original
    nextTrackIsLatm = false
    return LatmTrackOutput(original, id).also { latmOutputs.add(it) }
  }

  override fun endTracks() = delegate.endTracks()
  override fun seekMap(seekMap: SeekMap) = delegate.seekMap(seekMap)
}

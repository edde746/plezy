package com.edde746.plezy.exoplayer

import android.util.Log
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
 * Returns whether a track is LOAS/LATM AAC muxed as A_MS/ACM — ffmpeg's (and
 * therefore Plex's) fallback mapping for aac_latm, which Matroska has no native
 * codec ID for. The WAVEFORMATEX wFormatTag is the first 2 bytes (LE) of
 * CodecPrivate.
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

/**
 * MatroskaExtractor with LOAS/LATM AAC support, used for Plex Live TV MKV
 * streams (which bypass the ASS/DV extractor chain). VOD playback gets the
 * same LATM handling via ZlibMatroskaExtractor.
 */
class LatmMatroskaExtractor(flags: Int) : MatroskaExtractor(flags) {

  companion object {
    private const val TAG = "LatmMkvExtractor"
    private const val ID_SEGMENT = 0x18538067
    private const val ID_TRACK_ENTRY = 0xAE
  }

  private var latmWrapper: LatmExtractorOutputWrapper? = null

  override fun startMasterElement(id: Int, contentPosition: Long, contentSize: Long) {
    super.startMasterElement(id, contentPosition, contentSize)

    // init() is final, so install the wrapping output when the Segment starts —
    // before any TrackEntry can create a track through it.
    if (id == ID_SEGMENT && latmWrapper == null) {
      val currentOutput = matroskaExtractorOutputField.get(this) as ExtractorOutput
      val wrapper = LatmExtractorOutputWrapper(currentOutput)
      latmWrapper = wrapper
      matroskaExtractorOutputField.set(this, wrapper)
    }
  }

  override fun endMasterElement(id: Int) {
    if (id == ID_TRACK_ENTRY) {
      val track = getCurrentTrack(id)
      if (isLoasAcmTrack(track.codecId, track.codecPrivate)) {
        Log.i(TAG, "Track ${track.number} is LOAS/LATM AAC, unwrapping to raw AAC")
        latmWrapper?.markNextTrackLatm()
      }
    }
    super.endMasterElement(id)
  }

  override fun seek(position: Long, timeUs: Long) {
    latmWrapper?.resetTracks()
    super.seek(position, timeUs)
  }
}

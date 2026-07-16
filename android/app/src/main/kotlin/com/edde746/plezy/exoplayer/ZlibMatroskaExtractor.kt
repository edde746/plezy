package com.edde746.plezy.exoplayer

import android.util.Log
import androidx.media3.extractor.ExtractorInput
import androidx.media3.extractor.ExtractorOutput
import androidx.media3.extractor.SeekMap
import androidx.media3.extractor.TrackOutput
import androidx.media3.extractor.text.SubtitleParser
import com.edde746.plezy.libass.media.AssHandler
import com.edde746.plezy.libass.media.extractor.AssMatroskaExtractor

/**
 * Extends AssMatroskaExtractor to add support for MKV quirks media3 rejects:
 *
 * ContentCompAlgo 0 (zlib) — media3 only supports ContentCompAlgo 3 (header
 * stripping). This subclass intercepts the compression algorithm during track
 * header parsing:
 * - Tells the parent it's header stripping (algo 3) to avoid the ParserException
 * - Wraps TrackOutputs with ZlibInflatingTrackOutput to decompress per-sample data
 * - Skips ContentCompSettings for zlib tracks (not applicable)
 *
 * LOAS/LATM AAC as A_MS/ACM — media3 sets audio/x-unknown for non-PCM ACM
 * tracks (silent playback). Detected tracks are wrapped with LatmTrackOutput,
 * which unwraps LOAS frames to raw AAC (see LatmMatroskaExtractor for the
 * Live TV counterpart).
 */
class ZlibMatroskaExtractor(
  subtitleParserFactory: SubtitleParser.Factory,
  assHandler: AssHandler
) : AssMatroskaExtractor(subtitleParserFactory, assHandler) {

  companion object {
    private const val TAG = "ZlibMkvExtractor"

    // Matroska EBML element IDs
    private const val ID_SEGMENT = 0x18538067
    private const val ID_TRACK_ENTRY = 0xAE
    private const val ID_CONTENT_COMPRESSION_ALGORITHM = 0x4254
    private const val ID_CONTENT_COMPRESSION_SETTINGS = 0x4255
  }

  private var zlibOutput: ZlibExtractorOutputWrapper? = null
  private var latmOutput: LatmExtractorOutputWrapper? = null
  private var currentTrackUsesZlib = false

  override fun startMasterElement(id: Int, contentPosition: Long, contentSize: Long) {
    super.startMasterElement(id, contentPosition, contentSize)

    // After super installs AssSubtitleExtractorOutput, wrap it with our zlib +
    // LATM layers (zlib outermost so inflation runs before LATM parsing).
    if (id == ID_SEGMENT && zlibOutput == null) {
      val currentOutput = matroskaExtractorOutputField.get(this) as ExtractorOutput
      val latmWrapper = LatmExtractorOutputWrapper(currentOutput)
      latmOutput = latmWrapper
      val wrapper = ZlibExtractorOutputWrapper(latmWrapper)
      zlibOutput = wrapper
      matroskaExtractorOutputField.set(this, wrapper)
      Log.d(TAG, "Installed zlib+LATM ExtractorOutput wrapper")
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
    if (id == ID_TRACK_ENTRY) {
      // Must mark before super — the track output is created inside super's
      // endMasterElement, and the x-unknown format must never reach the queue.
      val track = getCurrentTrack(id)
      if (isLoasAcmTrack(track.codecId, track.codecPrivate)) {
        Log.i(TAG, "Track ${track.number} is LOAS/LATM AAC, unwrapping to raw AAC")
        latmOutput?.markNextTrackLatm()
      }
    }

    val wasZlib = currentTrackUsesZlib
    super.endMasterElement(id)

    if (id == ID_TRACK_ENTRY && wasZlib) {
      zlibOutput?.activateLast()
      currentTrackUsesZlib = false
      Log.i(TAG, "Activated zlib inflation for track")
    }
  }

  override fun seek(position: Long, timeUs: Long) {
    latmOutput?.resetTracks()
    super.seek(position, timeUs)
  }

  /**
   * ExtractorOutput wrapper that wraps all TrackOutputs with ZlibInflatingTrackOutput.
   * Tracks are created inactive; activateLast() enables inflation for the most recently
   * created track (called when we know a track uses zlib compression).
   */
  private class ZlibExtractorOutputWrapper(
    private val delegate: ExtractorOutput
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

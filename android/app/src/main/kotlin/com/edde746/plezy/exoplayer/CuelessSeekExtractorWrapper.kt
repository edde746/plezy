package com.edde746.plezy.exoplayer

import android.util.Log
import androidx.media3.common.C
import androidx.media3.extractor.Extractor
import androidx.media3.extractor.ExtractorInput
import androidx.media3.extractor.ExtractorOutput
import androidx.media3.extractor.PositionHolder
import androidx.media3.extractor.SeekMap
import androidx.media3.extractor.SeekPoint
import androidx.media3.extractor.TrackAwareSeekMap
import androidx.media3.extractor.TrackOutput
import java.util.concurrent.CopyOnWriteArrayList

/**
 * Extractor wrapper that repairs seeking for MKV files media3 reports as unseekable.
 *
 * Two repairs, in priority order:
 * - [SeekMap.Unseekable] with a known duration (no Cues element at all): replaced with a
 *   proportional byte-position estimate, resynced to the nearest Cluster boundary after seeking.
 * - A [TrackAwareSeekMap] whose [SeekMap.isSeekable] is false (media3 1.11.0 builds the Matroska
 *   seek map while parsing Cues, which for files whose Tracks element follows the Clusters is
 *   before any track is known — the primary seek track stays unset even though the Cues parsed):
 *   wrapped so seeks resolve through the per-track cue lookups using the track IDs observed on
 *   this output.
 */
@androidx.media3.common.util.UnstableApi
class CuelessSeekExtractorWrapper(
  private val delegate: Extractor
) : Extractor {

  companion object {
    private const val TAG = "CuelessSeek"

    // MKV Cluster element ID: 0x1F43B675 (4-byte EBML Class-D ID)
    private val CLUSTER_ID = byteArrayOf(0x1F, 0x43, 0xB6.toByte(), 0x75)
    private const val SCAN_BUFFER_SIZE = 8192

    // Max bytes to scan for a Cluster boundary before giving up
    private const val MAX_SCAN_BYTES = 1024 * 1024 // 1 MB
  }

  private var inputLength: Long = C.LENGTH_UNSET.toLong()
  private var needsClusterResync = false
  private var isApproximateSeeking = false
  private var pendingSeekTimeUs: Long = C.TIME_UNSET

  /** Track IDs and types observed on the output, consulted by [TrackCueSeekMap]. */
  private val registeredTracks = CopyOnWriteArrayList<Pair<Int, Int>>()

  override fun sniff(input: ExtractorInput): Boolean = delegate.sniff(input)

  override fun init(output: ExtractorOutput) {
    delegate.init(SeekInterceptingOutput(output))
  }

  override fun read(input: ExtractorInput, seekPosition: PositionHolder): Int {
    if (inputLength == C.LENGTH_UNSET.toLong()) {
      inputLength = input.length
    }
    if (needsClusterResync) {
      needsClusterResync = false
      return scanForCluster(input, seekPosition)
    }
    return delegate.read(input, seekPosition)
  }

  override fun seek(position: Long, timeUs: Long) {
    if (isApproximateSeeking && position > 0) {
      needsClusterResync = true
      pendingSeekTimeUs = timeUs
    }
    delegate.seek(position, timeUs)
  }

  override fun release() = delegate.release()

  /**
   * Scan forward from the current input position to find the next MKV Cluster
   * element ID (0x1F43B675). Returns [Extractor.RESULT_SEEK] with the Cluster's
   * byte position so ExoPlayer repositions the DataSource there.
   */
  private fun scanForCluster(input: ExtractorInput, seekPosition: PositionHolder): Int {
    val buffer = ByteArray(SCAN_BUFFER_SIZE)
    var totalScanned = 0L
    // Carry over last 3 bytes across buffer boundaries to detect split IDs
    var carry = ByteArray(0)

    while (totalScanned < MAX_SCAN_BYTES) {
      val toRead = minOf(SCAN_BUFFER_SIZE, (MAX_SCAN_BYTES - totalScanned).toInt())
      val bytesRead: Int
      try {
        bytesRead = input.read(buffer, 0, toRead)
      } catch (_: Exception) {
        break
      }
      if (bytesRead == C.RESULT_END_OF_INPUT) break

      // Combine carry + new data for scanning
      val scanData = if (carry.isNotEmpty()) carry + buffer.copyOf(bytesRead) else buffer.copyOf(bytesRead)

      for (i in 0..scanData.size - 4) {
        if (scanData[i] == CLUSTER_ID[0] &&
          scanData[i + 1] == CLUSTER_ID[1] &&
          scanData[i + 2] == CLUSTER_ID[2] &&
          scanData[i + 3] == CLUSTER_ID[3]
        ) {
          // Compute the absolute byte position of this Cluster
          val clusterPosition = input.position - bytesRead - carry.size + i
          Log.d(TAG, "Found Cluster at byte $clusterPosition (scanned ${totalScanned + i} bytes)")
          seekPosition.position = clusterPosition
          delegate.seek(clusterPosition, pendingSeekTimeUs)
          pendingSeekTimeUs = C.TIME_UNSET
          return Extractor.RESULT_SEEK
        }
      }

      // Keep last 3 bytes as carry for next iteration
      carry = if (scanData.size >= 3) scanData.copyOfRange(scanData.size - 3, scanData.size) else scanData.copyOf()
      totalScanned += bytesRead
    }

    // Failed to find a Cluster — fall back to position 0
    Log.w(TAG, "No Cluster found after scanning $totalScanned bytes, resetting to start")
    seekPosition.position = 0
    delegate.seek(0, 0)
    return Extractor.RESULT_SEEK
  }

  /**
   * ExtractorOutput wrapper that intercepts [seekMap] calls to replace
   * [SeekMap.Unseekable] with an approximate proportional SeekMap.
   */
  private inner class SeekInterceptingOutput(
    private val delegate: ExtractorOutput
  ) : ExtractorOutput {

    override fun track(id: Int, type: Int): TrackOutput {
      if (registeredTracks.none { it.first == id }) {
        registeredTracks.add(id to type)
      }
      return delegate.track(id, type)
    }

    override fun endTracks() = delegate.endTracks()

    override fun seekMap(seekMap: SeekMap) {
      if (seekMap is SeekMap.Unseekable) {
        val durationUs = seekMap.durationUs
        if (durationUs != C.TIME_UNSET && durationUs > 0) {
          Log.i(TAG, "Replacing Unseekable with approximate SeekMap (duration=${durationUs / 1_000_000}s)")
          isApproximateSeeking = true
          delegate.seekMap(ApproximateSeekMap(durationUs))
          return
        }
      } else if (!seekMap.isSeekable && seekMap is TrackAwareSeekMap) {
        Log.i(TAG, "Wrapping unseekable TrackAwareSeekMap with per-track cue seeking")
        isApproximateSeeking = false
        delegate.seekMap(TrackCueSeekMap(seekMap))
        return
      }
      // File has real Cues or unknown duration — pass through
      isApproximateSeeking = false
      delegate.seekMap(seekMap)
    }
  }

  /**
   * Approximate SeekMap that estimates byte positions proportionally.
   * Used when the MKV has no Cues but has a known duration.
   */
  private inner class ApproximateSeekMap(
    private val durationUs: Long
  ) : SeekMap {

    override fun isSeekable(): Boolean = true

    override fun getDurationUs(): Long = durationUs

    override fun getSeekPoints(timeUs: Long): SeekMap.SeekPoints {
      val length = inputLength
      if (length == C.LENGTH_UNSET.toLong() || durationUs <= 0) {
        return SeekMap.SeekPoints(SeekPoint(0, 0))
      }
      val clampedTimeUs = timeUs.coerceIn(0, durationUs)
      val position = (clampedTimeUs.toDouble() / durationUs * length).toLong().coerceIn(0, length)
      return SeekMap.SeekPoints(SeekPoint(clampedTimeUs, position))
    }
  }

  /**
   * Routes seeks through [TrackAwareSeekMap]'s per-track cue lookups when the delegate reports
   * unseekable overall. The per-track queries read the live cue data (populated once the Cues
   * element parsed), so they resolve correctly even when the map was constructed before the
   * Tracks element — the media3 1.11.0 tracks-after-clusters case.
   */
  private inner class TrackCueSeekMap(
    private val delegate: TrackAwareSeekMap
  ) : SeekMap {

    override fun isSeekable(): Boolean = delegate.isSeekable || seekableTrackId() != null

    override fun getDurationUs(): Long = delegate.durationUs

    override fun getSeekPoints(timeUs: Long): SeekMap.SeekPoints {
      if (delegate.isSeekable) return delegate.getSeekPoints(timeUs)
      val trackId = seekableTrackId() ?: return delegate.getSeekPoints(timeUs)
      return delegate.getSeekPoints(timeUs, trackId)
    }

    /** Mirrors media3's primary-track priority: video first, then audio, then anything with cues. */
    private fun seekableTrackId(): Int? {
      var audio: Int? = null
      var fallback: Int? = null
      for ((id, type) in registeredTracks) {
        if (!delegate.isSeekable(id)) continue
        when (type) {
          C.TRACK_TYPE_VIDEO -> return id
          C.TRACK_TYPE_AUDIO -> if (audio == null) audio = id
          else -> if (fallback == null) fallback = id
        }
      }
      return audio ?: fallback
    }
  }
}

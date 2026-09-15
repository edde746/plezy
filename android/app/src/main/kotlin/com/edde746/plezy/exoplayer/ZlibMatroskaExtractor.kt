package com.edde746.plezy.exoplayer

import android.util.Log
import androidx.media3.common.C
import androidx.media3.common.DataReader
import androidx.media3.extractor.DefaultExtractorInput
import androidx.media3.extractor.ExtractorInput
import androidx.media3.extractor.ExtractorOutput
import androidx.media3.extractor.SeekMap
import androidx.media3.extractor.TrackOutput
import androidx.media3.extractor.text.SubtitleParser
import com.edde746.plezy.libass.media.AssHandler
import com.edde746.plezy.libass.media.extractor.AssMatroskaExtractor
import java.io.EOFException
import java.util.zip.DataFormatException
import java.util.zip.Inflater

/**
 * Extends AssMatroskaExtractor to add support for MKV quirks media3 rejects:
 *
 * ContentCompAlgo 0 (zlib) — media3 only supports ContentCompAlgo 3 (header
 * stripping). This subclass intercepts the compression algorithm during track
 * header parsing:
 * - Tells the parent it's header stripping (algo 3) to avoid the ParserException
 * - Skips ContentCompSettings for zlib tracks (not applicable)
 * - For text subtitle tracks, inflates the block payload *before* the parent
 *   parses it (see below). For every other zlib track, wraps TrackOutputs with
 *   ZlibInflatingTrackOutput to decompress per-sample data.
 *
 * Text subtitle tracks (SRT/ASS/SSA/VTT) cannot be inflated at the TrackOutput
 * level: MatroskaExtractor rewrites their samples in-place before any TrackOutput
 * runs — it prepends a plaintext timecode prefix ("Dialogue: 0:00:00:00,…,") to
 * the still-compressed payload and truncates the sample at the first NUL byte,
 * which deflate streams routinely contain (#2023). AssTrackOutput additionally
 * feeds that same internal buffer straight to libass. So for zlib text tracks the
 * frame payload is inflated at the block level, before the parent's sample
 * assembly, and the TrackOutput wrapper is left inactive.
 *
 * LOAS/LATM AAC as A_MS/ACM — media3 sets audio/x-unknown for non-PCM ACM
 * tracks (silent playback). Detected tracks are wrapped with LatmTrackOutput,
 * which unwraps LOAS frames to raw AAC for direct-playing Matroska files.
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
    private const val ID_CONTENT_COMPRESSION = 0x5034
    private const val ID_SIMPLE_BLOCK = 0xA3
    private const val ID_BLOCK = 0xA1

    /**
     * Codec IDs whose samples MatroskaExtractor rewrites in-place (timecode prefix
     * plus NUL truncation) before any TrackOutput runs — the authority is the
     * prefix list in MatroskaExtractor.writeSampleData.
     */
    private val TEXT_SUBTITLE_CODEC_IDS = setOf("S_TEXT/UTF8", "S_TEXT/ASS", "S_TEXT/SSA", "S_TEXT/WEBVTT")

    /** Subtitle blocks are tiny; anything above this passes through untouched. */
    private const val MAX_TEXT_BLOCK_BYTES = 16 * 1024 * 1024
  }

  private var zlibOutput: ZlibExtractorOutputWrapper? = null
  private var latmOutput: LatmExtractorOutputWrapper? = null
  private var currentTrackUsesZlib = false

  /** Track numbers whose blocks are inflated before the parent parses them. */
  private val zlibTextTrackNumbers = mutableSetOf<Int>()
  private val blockInflater = Inflater()
  private var blockBuf = ByteArray(0)
  private val peekBuf = ByteArray(8)

  override fun startMasterElement(id: Int, contentPosition: Long, contentSize: Long) {
    super.startMasterElement(id, contentPosition, contentSize)

    // ContentCompAlgo DEFAULTS to 0 (zlib), so mkvmerge omits the element for
    // zlib tracks entirely — the mere presence of ContentCompression means zlib
    // until an explicit ContentCompAlgo says otherwise. media3 ignores an empty
    // ContentCompression and would silently emit compressed samples.
    if (id == ID_CONTENT_COMPRESSION) {
      currentTrackUsesZlib = true
      Log.i(TAG, "Track has ContentCompression, assuming ContentCompAlgo 0 (zlib) until told otherwise")
    }

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
    if (id == ID_CONTENT_COMPRESSION_ALGORITHM) {
      if (value == 0L) {
        currentTrackUsesZlib = true
        Log.i(TAG, "Track uses explicit ContentCompAlgo 0 (zlib), will inflate samples")
        // Tell parent it's header stripping (algo 3) to avoid ParserException
        super.integerElement(id, 3)
        return
      }
      // Explicit non-zlib algorithm: header stripping (3) is handled by the
      // parent; anything else makes the parent throw, matching stock behavior.
      currentTrackUsesZlib = false
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
    if ((id == ID_SIMPLE_BLOCK || id == ID_BLOCK) &&
      zlibTextTrackNumbers.isNotEmpty() &&
      contentSize in MIN_BLOCK_BYTES..MAX_TEXT_BLOCK_BYTES &&
      peekBlockTrackNumber(input) in zlibTextTrackNumbers
    ) {
      inflateTextBlock(id, contentSize, input)
      return
    }
    super.binaryElement(id, contentSize, input)
  }

  override fun endMasterElement(id: Int) {
    var zlibTextTrackNumber: Int? = null
    if (id == ID_TRACK_ENTRY) {
      // Must inspect before super — the track output is created inside super's
      // endMasterElement, and the current track is cleared afterwards.
      val track = getCurrentTrack(id)
      if (isLoasAcmTrack(track.codecId, track.codecPrivate)) {
        Log.i(TAG, "Track ${track.number} is LOAS/LATM AAC, unwrapping to raw AAC")
        latmOutput?.markNextTrackLatm()
      }
      if (currentTrackUsesZlib && track.codecId in TEXT_SUBTITLE_CODEC_IDS) {
        zlibTextTrackNumber = track.number
      }
    }

    val wasZlib = currentTrackUsesZlib
    super.endMasterElement(id)

    if (id == ID_TRACK_ENTRY && wasZlib) {
      currentTrackUsesZlib = false
      if (zlibTextTrackNumber != null) {
        // Text subtitle samples are rewritten inside the parent before any
        // TrackOutput runs, so the TrackOutput wrapper stays inactive and the
        // block payload is inflated in binaryElement instead.
        zlibTextTrackNumbers.add(zlibTextTrackNumber)
        Log.i(TAG, "Track $zlibTextTrackNumber is a zlib text subtitle track, inflating at block level")
      } else {
        zlibOutput?.activateLast()
        Log.i(TAG, "Activated zlib inflation for track")
      }
    }
  }

  override fun seek(position: Long, timeUs: Long) {
    latmOutput?.resetTracks()
    zlibOutput?.resetTracks()
    super.seek(position, timeUs)
  }

  /**
   * Peeks the EBML varint at the block start — the block's track number — without
   * consuming input. Returns null for malformed varints or truncated input; the
   * parent then produces the canonical failure for the untouched stream.
   */
  private fun peekBlockTrackNumber(input: ExtractorInput): Int? {
    try {
      input.peekFully(peekBuf, 0, 1)
      val first = peekBuf[0].toInt() and 0xFF
      if (first == 0) return null
      val length = Integer.numberOfLeadingZeros(first) - 23
      var value = (first and (0xFF ushr length)).toLong()
      if (length > 1) {
        input.peekFully(peekBuf, 1, length - 1)
        for (i in 1 until length) {
          value = (value shl 8) or (peekBuf[i].toLong() and 0xFF)
        }
      }
      return if (value <= Int.MAX_VALUE) value.toInt() else null
    } catch (_: EOFException) {
      return null
    } finally {
      input.resetPeekPosition()
    }
  }

  /**
   * Buffers one text-subtitle block, inflates its frame payload, and hands the
   * parent a block whose payload is plaintext. A block that cannot be rewritten
   * (laced, corrupt, or over-bound) passes through byte-identical.
   */
  private fun inflateTextBlock(id: Int, contentSize: Int, input: ExtractorInput) {
    val basePosition = input.position
    if (blockBuf.size < contentSize) blockBuf = ByteArray(maxOf(contentSize, blockBuf.size * 2))
    input.readFully(blockBuf, 0, contentSize)
    val rewritten = rewriteZlibTextBlock(blockBuf, contentSize, blockInflater)
    if (rewritten == null) {
      Log.w(TAG, "Passing zlib text block through uninflated (laced, corrupt, or over-bound)")
      super.binaryElement(id, contentSize, bufferedInput(blockBuf, contentSize, basePosition))
    } else {
      super.binaryElement(id, rewritten.size, bufferedInput(rewritten, rewritten.size, basePosition))
    }
  }

  private fun bufferedInput(data: ByteArray, limit: Int, position: Long): ExtractorInput = DefaultExtractorInput(ByteRangeDataReader(data, limit), position, position + limit)

  private class ByteRangeDataReader(private val data: ByteArray, private val limit: Int) : DataReader {
    private var position = 0

    override fun read(buffer: ByteArray, offset: Int, length: Int): Int {
      if (position == limit) return C.RESULT_END_OF_INPUT
      val count = minOf(length, limit - position)
      System.arraycopy(data, position, buffer, offset, count)
      position += count
      return count
    }
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
    private val trackOutputs = mutableListOf<ZlibInflatingTrackOutput>()

    override fun track(id: Int, type: Int): TrackOutput {
      val original = delegate.track(id, type)
      return ZlibInflatingTrackOutput(original).also {
        trackOutputs.add(it)
        lastCreatedWrapper = it
      }
    }

    fun activateLast() {
      lastCreatedWrapper?.active = true
    }

    fun resetTracks() {
      trackOutputs.forEach { it.resetBufferedData() }
    }

    override fun endTracks() = delegate.endTracks()
    override fun seekMap(seekMap: SeekMap) = delegate.seekMap(seekMap)
  }
}

/** Smallest well-formed unlaced block: 1-byte varint + 2-byte timecode + flags + 1 payload byte. */
internal const val MIN_BLOCK_BYTES = 5

/**
 * Rewrites one unlaced Matroska block whose frame payload is zlib-compressed:
 * returns the unchanged block header followed by the inflated payload, or null
 * when the block must pass through unchanged — lacing (never produced for text
 * subtitle tracks), a truncated or corrupt deflate stream, or an inflated size
 * beyond the bounds shared with [ZlibInflatingTrackOutput]'s hardening.
 */
internal fun rewriteZlibTextBlock(data: ByteArray, limit: Int, inflater: Inflater): ByteArray? {
  if (limit < MIN_BLOCK_BYTES) return null
  val first = data[0].toInt() and 0xFF
  if (first == 0) return null // track-number varint longer than 8 bytes
  val varintLength = Integer.numberOfLeadingZeros(first) - 23
  val headerLength = varintLength + 3 // varint + 2-byte timecode + flags
  if (limit <= headerLength) return null
  if (data[headerLength - 1].toInt() and 0x06 != 0) return null // laced

  val payloadLength = limit - headerLength
  val ratioBound = maxOf(1024L * 1024, payloadLength.toLong() * 1024)
  val maxInflatedBytes = 16 * 1024 * 1024
  inflater.reset()
  inflater.setInput(data, headerLength, payloadLength)
  var buf = ByteArray(maxOf(4096, payloadLength * 4))
  var written = 0
  try {
    while (true) {
      if (written == buf.size) {
        if (buf.size >= maxInflatedBytes) return null
        buf = buf.copyOf(minOf(maxInflatedBytes, buf.size * 2))
      }
      val count = inflater.inflate(buf, written, buf.size - written)
      written += count
      if (written > ratioBound) return null
      if (inflater.finished()) break
      if (count == 0) return null // truncated stream or preset-dictionary request
    }
  } catch (_: DataFormatException) {
    return null
  }
  return ByteArray(headerLength + written).also {
    System.arraycopy(data, 0, it, 0, headerLength)
    System.arraycopy(buf, 0, it, headerLength, written)
  }
}

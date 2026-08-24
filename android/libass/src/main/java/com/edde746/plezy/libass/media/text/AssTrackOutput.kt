package com.edde746.plezy.libass.media.text

import androidx.media3.common.C
import androidx.media3.common.DataReader
import androidx.media3.common.Format
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.ParsableByteArray
import androidx.media3.common.util.UnstableApi
import androidx.media3.common.util.Util
import androidx.media3.extractor.TrackOutput
import java.io.EOFException
import java.util.regex.Pattern

/**
 * Feeds embedded ASS dialogue to libass while forwarding every sample
 * unchanged. Only used by the overlay renderer, which needs the start time and
 * duration of each dialogue line.
 *
 * Samples must arrive in the media3 MatroskaExtractor subtitle shape
 * `Dialogue: 0:00:00:00,<duration timecode>,<ReadOrder,Layer,Style,...>` — the
 * second field carries the sample *duration* (MatroskaExtractor patches
 * BlockDuration into it; the FFmpeg extractor writes the packet duration).
 * The extractor beneath must therefore emit raw subtitle samples: media3's
 * MatroskaExtractor with FLAG_EMIT_RAW_SUBTITLE_DATA, or the FFmpeg demuxer
 * path. Cue transcoding happens downstream of this wrapper.
 */
@UnstableApi
class AssTrackOutput(
  private val delegate: TrackOutput,
  private val dialogueSink: DialogueSink
) : TrackOutput {

  /** Receives one dialogue line; mirrors AssHandler.readTrackDialogue. */
  fun interface DialogueSink {
    fun onDialogue(trackId: String?, startMs: Long, durationMs: Long, data: ByteArray, offset: Int, length: Int)
  }

  private var isAss = false
  private var trackId: String? = null

  // Sample bytes buffered between sampleData and sampleMetadata; only
  // populated for ASS tracks.
  private var buf = ByteArray(INITIAL_BUFFER_SIZE)
  private var bufLen = 0
  private var readBuf = ByteArray(INITIAL_BUFFER_SIZE)
  private val forwardParsable = ParsableByteArray()

  override fun format(format: Format) {
    if (format.sampleMimeType == MimeTypes.TEXT_SSA || format.codecs == MimeTypes.TEXT_SSA) {
      isAss = true
      trackId = format.id
    }
    delegate.format(format)
  }

  override fun sampleData(
    input: DataReader,
    length: Int,
    allowEndOfInput: Boolean,
    sampleDataPart: Int
  ): Int {
    if (!isAss) return delegate.sampleData(input, length, allowEndOfInput, sampleDataPart)
    if (readBuf.size < length) readBuf = ByteArray(length)
    val bytesRead = input.read(readBuf, 0, length)
    if (bytesRead == C.RESULT_END_OF_INPUT) {
      if (!allowEndOfInput) throw EOFException()
      return C.RESULT_END_OF_INPUT
    }
    append(readBuf, bytesRead)
    forwardParsable.reset(readBuf, bytesRead)
    delegate.sampleData(forwardParsable, bytesRead, sampleDataPart)
    return bytesRead
  }

  override fun sampleData(data: ParsableByteArray, length: Int, sampleDataPart: Int) {
    if (isAss) {
      ensureCapacity(bufLen + length)
      System.arraycopy(data.data, data.position, buf, bufLen, length)
      bufLen += length
    }
    delegate.sampleData(data, length, sampleDataPart)
  }

  override fun sampleMetadata(
    timeUs: Long,
    flags: Int,
    size: Int,
    offset: Int,
    cryptoData: TrackOutput.CryptoData?
  ) {
    if (isAss) {
      // offset counts bytes buffered after this sample; the slice math matches
      // media3's TrackOutput contract even though subtitle samples are
      // normally delivered one at a time with offset 0.
      val start = bufLen - offset - size
      if (timeUs != C.TIME_UNSET && start >= 0) {
        feedDialogue(timeUs, start, size)
      }
      if (offset == 0) bufLen = 0
    }
    delegate.sampleMetadata(timeUs, flags, size, offset, cryptoData)
  }

  private fun feedDialogue(timeUs: Long, start: Int, size: Int) {
    val end = start + size
    val durationIndex = findTokenIndex(start, end, 1)
    val lineIndex = findTokenIndex(start, end, 2)
    if (durationIndex <= start || lineIndex <= durationIndex) return
    val rawDuration = buf.decodeToString(durationIndex, lineIndex - 1)
    val durationUs = parseTimecodeUs(rawDuration)
    if (durationUs == C.TIME_UNSET) return
    dialogueSink.onDialogue(
      trackId,
      timeUs / 1000,
      durationUs / 1000,
      buf,
      lineIndex,
      end - lineIndex
    )
  }

  private fun parseTimecodeUs(timeString: String): Long {
    val matcher = SSA_TIMECODE_PATTERN.matcher(timeString.trim { it <= ' ' })
    if (!matcher.matches()) {
      return C.TIME_UNSET
    }
    var timestampUs =
      Util.castNonNull(matcher.group(1)).toLong() * 60 * 60 * C.MICROS_PER_SECOND
    timestampUs += Util.castNonNull(matcher.group(2)).toLong() * 60 * C.MICROS_PER_SECOND
    timestampUs += Util.castNonNull(matcher.group(3)).toLong() * C.MICROS_PER_SECOND
    timestampUs += Util.castNonNull(matcher.group(4)).toLong() * 10000
    return timestampUs
  }

  /** Index just past the [tokenNumber]th comma inside [from, to), or [from]. */
  private fun findTokenIndex(from: Int, to: Int, tokenNumber: Int): Int {
    var tokensFound = 0
    for (index in from until to) {
      if (buf[index] == COMMA && ++tokensFound == tokenNumber) {
        return index + 1
      }
    }
    return from
  }

  private fun append(src: ByteArray, length: Int) {
    ensureCapacity(bufLen + length)
    System.arraycopy(src, 0, buf, bufLen, length)
    bufLen += length
  }

  private fun ensureCapacity(needed: Int) {
    if (buf.size < needed) buf = buf.copyOf(maxOf(needed, buf.size * 2))
  }

  private companion object {
    val SSA_TIMECODE_PATTERN: Pattern =
      Pattern.compile("""(?:(\d+):)?(\d+):(\d+)[:.](\d+)""")

    const val COMMA = ','.code.toByte()
    const val INITIAL_BUFFER_SIZE = 1024
  }
}

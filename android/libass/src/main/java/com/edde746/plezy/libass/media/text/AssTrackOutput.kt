package com.edde746.plezy.libass.media.text

import androidx.media3.common.C
import androidx.media3.common.Format
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.UnstableApi
import androidx.media3.common.util.Util
import androidx.media3.extractor.TrackOutput
import com.edde746.plezy.libass.media.AssHandler
import com.edde746.plezy.libass.media.extractor.AssMatroskaExtractor
import java.util.regex.Pattern

/**
 * This class is only used by the overlay renderer. It's needed to get the start time of the subtitles.
 */
@UnstableApi
class AssTrackOutput(
  private val delegate: TrackOutput,
  private val assHandler: AssHandler,
  private val extractor: AssMatroskaExtractor
) : TrackOutput by delegate {

  private var isAss = false

  private var trackId: String? = null

  override fun format(format: Format) {
    if (format.sampleMimeType == MimeTypes.TEXT_SSA || format.codecs == MimeTypes.TEXT_SSA) {
      isAss = true
      trackId = format.id
    }
    delegate.format(format)
  }

  override fun sampleMetadata(
    timeUs: Long,
    flags: Int,
    size: Int,
    offset: Int,
    cryptoData: TrackOutput.CryptoData?
  ) {
    if (isAss && timeUs.isValidTs) {
      val sample = extractor.subtitleSample
      val endIndex = findTokenIndex(sample.data, 1)
      val lineIndex = findTokenIndex(sample.data, 2)

      val rawDuration = sample.data.decodeToString(endIndex, lineIndex - 1)
      val durationUs = parseTimecodeUs(rawDuration)

      assHandler.readTrackDialogue(
        trackId = trackId,
        start = timeUs / 1000,
        duration = durationUs / 1000,
        data = sample.data,
        offset = lineIndex,
        length = sample.limit() - lineIndex
      )
    }
    delegate.sampleMetadata(timeUs, flags, size, offset, cryptoData)
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

  private fun findTokenIndex(array: ByteArray, tokenNumber: Int): Int {
    if (tokenNumber == 0) return 0
    var tokensFound = 0
    array.forEachIndexed { index, byte ->
      if (byte == COMMA && ++tokensFound == tokenNumber) {
        return index + 1
      }
    }
    return 0
  }

  private val Long.isValidTs
    get() = this != C.TIME_UNSET

  private companion object {
    val SSA_TIMECODE_PATTERN: Pattern =
      Pattern.compile("""(?:(\d+):)?(\d+):(\d+)[:.](\d+)""")

    const val COMMA = ','.code.toByte()
  }
}

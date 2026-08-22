package com.edde746.plezy.exoplayer

import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi

/**
 * JNI surface for the libavformat demuxer shim (`cpp/media3_ffmpeg_demuxer`).
 *
 * One demuxer exists per process, owned by whichever [FfmpegExtractor] is
 * currently open — Plezy plays at most one progressive source at a time, and
 * every other playback mode (HLS/DASH, music) stays on media3's own sources.
 *
 * The long[] layouts mirror the constants documented in
 * `ffmpeg_demuxer_jni.cc`; keep both sides in sync.
 */
@OptIn(UnstableApi::class)
internal object FfmpegDemuxerJni {
  /** Re-entry point for the AVIO callbacks while a native call is in flight. */
  interface Input {
    /** Current byte position of the underlying [androidx.media3.extractor.ExtractorInput]. */
    fun position(): Long

    /**
     * Reads up to [length] bytes into [buf]. Returns the number of bytes read,
     * `0` at end of input, or `-1` after storing the failure in [lastError].
     */
    fun read(buf: ByteArray, length: Int): Int

    /** Total input length in bytes, or `-1` when unknown. */
    fun length(): Long

    var lastError: String?
  }

  // readPacket out[] indices. Deferral targets travel through
  // [nativeConsumePendingSeek], not this array.
  const val OUT_CODE = 0
  const val OUT_STREAM_INDEX = 1
  const val OUT_PTS_US = 2
  const val OUT_FLAGS = 3
  const val OUT_SIZE = 4
  const val OUT_POSITION = 5
  const val OUT_DURATION_US = 6
  const val OUT_LENGTH = 7

  // Result codes written to out[OUT_CODE]; negative values are raw AVERRORs.
  const val CODE_PACKET = 0
  const val CODE_EOF = 1
  const val CODE_NEED_SEEK = 2
  const val CODE_GROW = 3
  const val ERR_JAVA = -102

  // streamInfo long[] layout.
  const val INFO_TRACK_TYPE = 0
  const val INFO_WIDTH = 1
  const val INFO_HEIGHT = 2
  const val INFO_PAR_NUM = 3
  const val INFO_PAR_DEN = 4
  const val INFO_FPS_NUM = 5
  const val INFO_FPS_DEN = 6
  const val INFO_SAMPLE_RATE = 7
  const val INFO_CHANNELS = 8
  const val INFO_PCM_ENCODING = 9
  const val INFO_ROTATION = 10
  const val INFO_SELECTION_FLAGS = 11
  const val INFO_ROLE_FLAGS = 12
  const val INFO_BITRATE = 13
  const val INFO_DOVI_PROFILE = 14
  const val INFO_DOVI_LEVEL = 15
  const val INFO_LATM = 16
  const val INFO_LENGTH = 17

  val available: Boolean = try {
    System.loadLibrary("ffmpegJNI")
    true
  } catch (_: UnsatisfiedLinkError) {
    false
  }

  /** Probes container bytes; returns the ffmpeg short name ("avi", "asf", …) or null. */
  external fun nativeProbeFormat(header: ByteArray): String?

  /**
   * Opens (and resumes opening) the demuxer against [input]. Returns 0 on
   * success, [CODE_NEED_SEEK] when the loader must move the input first, or a
   * negative AVERROR. The stream count is read separately via
   * [nativeStreamCount]; it must not ride the same namespace as result codes.
   */
  external fun nativeOpen(input: Input): Int

  external fun nativeClose()

  external fun nativeStreamCount(): Int

  /** Total duration in microseconds, or -1 when unknown. */
  external fun nativeDurationUs(): Long

  /** Fills [numbers]/[strings] for [index]; false when the stream is unusable. */
  external fun nativeStreamInfo(index: Int, numbers: LongArray, strings: Array<String?>): Boolean

  /** Codec initialization data (extradata), or null. */
  external fun nativeStreamExtradata(index: Int): ByteArray?

  /** Number of attachment streams (embedded fonts and friends) with payloads. */
  external fun nativeAttachmentCount(): Int

  /**
   * Fills [strings] with [filename, mimetype] for attachment [ordinal] and
   * returns the payload size in bytes, or -1 when out of range. Lets Kotlin
   * enforce font budgets before copying any bytes across the boundary.
   */
  external fun nativeAttachmentInfo(ordinal: Int, strings: Array<String?>): Long

  /** Attachment payload bytes, or null. */
  external fun nativeAttachmentData(ordinal: Int): ByteArray?

  /**
   * Reads one packet into [buffer], filling [out]. See the shim header
   * comment for the result contract.
   */
  external fun nativeReadPacket(buffer: ByteArray, out: LongArray): Int

  /** Returns the recorded seek target, or [Long.MIN_VALUE] when none. */
  external fun nativeConsumePendingSeek(): Long

  /** Adopts [position] as the AVIO position; the input must already be there. */
  external fun nativeResumeAfterSeek(position: Long): Int

  /**
   * Records a presentation-time seek (media3 timeline microseconds). The next
   * [nativeReadPacket] executes it via avformat_seek_file, deferring through
   * the loader as needed; the demuxer picks the byte position itself.
   */
  external fun nativeSeekTo(timeUs: Long)

  /** Drops cached header blocks; called when the extractor binds a new source. */
  external fun nativeResetCache()
}

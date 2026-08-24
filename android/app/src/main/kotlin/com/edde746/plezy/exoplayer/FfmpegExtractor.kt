package com.edde746.plezy.exoplayer

import android.util.Log
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.Format
import androidx.media3.common.MimeTypes
import androidx.media3.common.ParserException
import androidx.media3.common.util.ParsableByteArray
import androidx.media3.common.util.UnstableApi
import androidx.media3.extractor.Extractor
import androidx.media3.extractor.ExtractorInput
import androidx.media3.extractor.ExtractorOutput
import androidx.media3.extractor.PositionHolder
import androidx.media3.extractor.SeekMap
import androidx.media3.extractor.SeekPoint
import androidx.media3.extractor.TrackOutput
import androidx.media3.extractor.text.SubtitleParser
import androidx.media3.extractor.text.SubtitleTranscodingExtractorOutput
import com.edde746.plezy.libass.media.AssFonts
import com.edde746.plezy.libass.media.AssHandler
import com.edde746.plezy.libass.media.text.AssSubtitleExtractorOutput
import java.io.IOException

/**
 * Demuxes progressive containers with libavformat and feeds the packets to
 * media3's renderers, so FFmpeg's container coverage replaces media3's on the
 * paths where it is weak (AVI/XviD timestamps and VOL csd — #2052 — ASF/WMV,
 * MPEG-PS) and where the app accumulated Matroska patches (zlib-compressed
 * subtitles, LOAS/LATM audio, cueless seeking) without giving up any of the
 * renderer-side work (passthrough carriers, DV sanitizing, libass rendering
 * with embedded fonts, subtitle latency calibration).
 *
 * Text tracks are emitted in the exact sample shape media3's
 * MatroskaExtractor writes (see [FfmpegSubtitleSamples]); the output chain
 * composed in [init] then feeds libass dialogue and transcodes cues the same
 * way the media3 Matroska path does.
 *
 * Seeking: libavformat resolves seeks itself, reading its own index through
 * [FfmpegRandomAccessSource]. media3's byte hints are ignored, nothing is ever
 * unwound, and the loader is merely nudged to follow along so that sample
 * delivery keeps streaming on its connection (see [alignLoader]).
 *
 * The instance sits before media3's extractors and sniffs everything FFmpeg
 * can probe while [FfmpegDemuxerPolicy] enables it; media3's list behind it
 * is the fallback for anything FFmpeg cannot open.
 */
@OptIn(UnstableApi::class)
internal class FfmpegExtractor private constructor(
  private val preferenceSupplier: () -> FfmpegDemuxerPolicy.Preference,
  private val dvMode: DvConversionMode,
  private val subtitleParserFactory: SubtitleParser.Factory,
  private val assHandler: AssHandler,
  private val io: FfmpegRandomAccessSource
) : Extractor {

  companion object {
    private const val TAG = "FfmpegExtractor"
    private const val SNIFF_BYTES = 64 * 1024
    private const val INITIAL_PACKET_BUFFER_BYTES = 2 * 1024 * 1024

    /** Null when the native library is unavailable. */
    fun create(
      preferenceSupplier: () -> FfmpegDemuxerPolicy.Preference,
      dvMode: DvConversionMode,
      subtitleParserFactory: SubtitleParser.Factory,
      assHandler: AssHandler,
      io: FfmpegRandomAccessSource
    ): FfmpegExtractor? = if (FfmpegDemuxerJni.available) {
      FfmpegExtractor(preferenceSupplier, dvMode, subtitleParserFactory, assHandler, io)
    } else {
      null
    }
  }

  private lateinit var output: ExtractorOutput
  private var currentInput: ExtractorInput? = null
  private val inputProxy = object : FfmpegDemuxerJni.Input {
    override fun position(): Long = currentInput?.position ?: 0L

    override fun read(buf: ByteArray, length: Int): Int {
      val input = currentInput ?: return 0
      lastError = null
      return try {
        val read = input.read(buf, 0, length)
        if (read == C.RESULT_END_OF_INPUT) 0 else read
      } catch (e: IOException) {
        lastError = e.message ?: "demuxer input failed"
        -1
      }
    }

    override fun readAt(position: Long, buf: ByteArray, length: Int): Int {
      lastError = null
      return try {
        io.readAt(position, buf, length)
      } catch (e: IOException) {
        lastError = e.message ?: "demuxer random access read failed"
        -1
      }
    }

    override fun length(): Long {
      val fromLoader = currentInput?.length ?: C.LENGTH_UNSET.toLong()
      if (fromLoader != C.LENGTH_UNSET.toLong()) return fromLoader
      // Length-less loader open (progressive live stream): fall back to
      // whatever a random-access open already resolved.
      val resolved = io.length()
      return if (resolved == C.LENGTH_UNSET.toLong()) -1L else resolved
    }

    override var lastError: String? = null
  }

  private var opened = false
  private var doviOutputWrapper: DoviExtractorOutputWrapper? = null
  private var durationUs = C.TIME_UNSET
  private var trackOutputs: Array<TrackOutput?> = emptyArray()
  private var packetBytes = ByteArray(INITIAL_PACKET_BUFFER_BYTES)
  private val packetParsable = ParsableByteArray()
  private val packetOut = LongArray(FfmpegDemuxerJni.OUT_LENGTH)
  private val prefixParsable = ParsableByteArray()

  // Per-stream text handling picked in prepareTracks; parallel to trackOutputs.
  private var subtitleKinds: Array<SubtitleKind> = emptyArray()
  private val latmOutputs = ArrayList<LatmTrackOutput>()

  // Per-audio-stream measured bitrate, parallel to trackOutputs. Written by
  // the loader thread, read by ExoPlayerCore.getStats on another thread.
  @Volatile private var bitrateMeters: Array<StreamBitrateMeter?> = emptyArray()

  // Set by seek(), applied by the next read(): media3 calls both on the loader
  // thread, but only read() is allowed to throw IOException and the demuxer's
  // seek reads its index.
  private var pendingSeekUs = C.TIME_UNSET
  private var deliveredAnyPacket = false

  private val sniffScratch = ByteArray(SNIFF_BYTES)

  override fun sniff(input: ExtractorInput): Boolean {
    // media3 materializes the extractor array once per player session, so the
    // policy must be read live at sniff time — a preference captured at
    // construction would freeze for the session.
    if (!FfmpegDemuxerPolicy.enabled(preferenceSupplier())) return false
    val probed = probe(input) ?: return false
    Log.i(TAG, "sniff accepted $probed")
    return true
  }

  private fun probe(input: ExtractorInput): String? {
    // create() only builds instances when the native library loaded.
    input.resetPeekPosition()
    return try {
      val filled =
        input.peekFully(
          sniffScratch,
          /* offset= */
          0,
          sniffScratch.size,
          /* allowEndOfInput= */
          true
        )
      if (!filled) return null
      FfmpegDemuxerJni.nativeProbeFormat(sniffScratch)?.lowercase()
    } catch (_: Throwable) {
      // A sniffer must never take playback down: media3 escalates anything
      // that is not an IOException into a fatal loader error.
      null
    } finally {
      input.resetPeekPosition()
    }
  }

  override fun init(output: ExtractorOutput) {
    // media3 reuses extractor instances across sources; drop the previous
    // item's demuxer and byte source so this open starts clean.
    releaseDemuxer()
    // Same composition as the MP4/MKV paths: DoviConvertingTrackOutput
    // inspects each video track's codecs string and passes non-DV through.
    val doviWrapped = if (dvMode != DvConversionMode.DISABLED) {
      // The wrapper forwards emitLog into each converting track output; the
      // playback-info hook stays wired to the MKV/MP4 wrappers, so nothing to
      // capture here.
      DoviExtractorOutputWrapper(
        output,
        dvMode,
        emitLog = { level, prefix, message ->
          Log.println(if (level == "error") Log.ERROR else Log.INFO, TAG, "$prefix $message")
        },
        onVideoTrackWrapped = { _ -> }
      ).also { doviOutputWrapper = it }
    } else {
      doviOutputWrapper = null
      output
    }
    // Text pipeline, extractor-outward: raw media3-shape samples first hit
    // AssTrackOutput (libass dialogue feed), then the transcoding wrapper
    // parses them into cue samples. media3 does NOT wrap third-party
    // extractors' outputs; without this wrapper no text track would ever
    // reach the renderer as cues.
    this.output = AssSubtitleExtractorOutput(
      SubtitleTranscodingExtractorOutput(doviWrapped, subtitleParserFactory),
      assHandler
    )
  }

  override fun read(input: ExtractorInput, seekPosition: PositionHolder): Int {
    currentInput = input
    try {
      if (!opened) openStreams()
      applyPendingSeek()
      alignLoader(input)?.let { position ->
        seekPosition.position = position
        return Extractor.RESULT_SEEK
      }
      // Aligned: the loader serves the samples, so nothing needs a second
      // handle open until the demuxer jumps again.
      if (io.isOpen) io.close()
      return readPacket()
    } catch (e: Throwable) {
      Log.w(TAG, "read threw at input=${input.position}", e)
      throw e
    } finally {
      currentInput = null
    }
  }

  /**
   * Byte position the loader should move to, or null when it already stands
   * where libavformat reads.
   *
   * Reads outside the loader's window are served by [io] regardless, so this
   * is an optimization, never a correctness requirement: it keeps sample
   * delivery on media3's own connection, which is what drives its byte
   * accounting, back-pressure (ProgressiveMediaPeriod watches the input
   * position) and load-error policy. Nothing here needs a retry budget.
   */
  private fun alignLoader(input: ExtractorInput): Long? {
    val demuxerPosition = FfmpegDemuxerJni.nativeLogicalPosition()
    if (demuxerPosition < 0 || demuxerPosition == input.position) return null
    val length = input.length
    // Opening a range at or past the end is a failed request, not an
    // alignment; let the read report end of input instead.
    if (length != C.LENGTH_UNSET.toLong() && demuxerPosition >= length) return null
    return demuxerPosition
  }

  /**
   * Records the target; [read] performs it. media3's byte position is its
   * SeekMap guess and is deliberately ignored — libavformat picks the byte
   * position from its own index.
   */
  override fun seek(position: Long, timeUs: Long) {
    Log.i(TAG, "extractor seek timeUs=$timeUs opened=$opened")
    doviOutputWrapper?.resetTracks()
    // Buffered LOAS bytes belong to the pre-seek stream; the StreamMuxConfig
    // survives so audio resumes without waiting for the next config.
    for (latm in latmOutputs) latm.reset()
    pendingSeekUs = timeUs
  }

  private fun applyPendingSeek() {
    val target = pendingSeekUs
    if (target == C.TIME_UNSET) return
    pendingSeekUs = C.TIME_UNSET
    // media3 issues seek(0) before the first read of every item; a demuxer
    // that has not delivered a packet yet is already at the start, and
    // seeking would throw away find_stream_info's buffered packets and
    // re-read the header region.
    if (target == 0L && !deliveredAnyPacket) return
    val code = FfmpegDemuxerJni.nativeSeek(target)
    if (code == FfmpegDemuxerJni.ERR_JAVA) {
      throw IOException(inputProxy.lastError ?: "demuxer input failed")
    }
    if (code != 0) {
      // No usable index in this container: libavformat keeps delivering from
      // where it stands and the renderers decode-discard toward the target,
      // which is what media3's own extractors do for a cueless file.
      Log.w(TAG, "demuxer refused seek to ${target}us: $code")
    }
  }

  override fun release() {
    releaseDemuxer()
  }

  private fun releaseDemuxer() {
    if (opened) {
      opened = false
      FfmpegDemuxerJni.nativeClose()
    }
    io.close()
    pendingSeekUs = C.TIME_UNSET
    deliveredAnyPacket = false
    // media3's extractors may demux a later item while this instance keeps
    // the previous one's stream layout; a stale measurement must not leak
    // into stats.
    bitrateMeters = emptyArray()
  }

  /**
   * Measured average bitrate (bps) of the audio stream whose index matches
   * [formatId] (this extractor sets `Format.id` to the stream index), or null
   * when this instance is not demuxing that stream. Fallback for containers
   * that declare no per-track bitrate (#2063).
   */
  fun measuredAudioBitrateBps(formatId: String?): Int? {
    val index = formatId?.toIntOrNull() ?: return null
    return bitrateMeters.getOrNull(index)?.bitrateBps()
  }

  private fun openStreams() {
    when (val code = FfmpegDemuxerJni.nativeOpen(inputProxy)) {
      0 -> {
        prepareTracks()
        opened = true
        Log.i(TAG, "ffmpeg demuxer ready: ${trackOutputs.count { it != null }} tracks")
      }
      FfmpegDemuxerJni.ERR_JAVA -> throw IOException(inputProxy.lastError ?: "demuxer input failed")
      else -> throw malformed("ffmpeg demuxer open failed: $code")
    }
  }

  private enum class SubtitleKind { NONE, SSA, SUBRIP, VTT }

  private fun prepareTracks() {
    val count = FfmpegDemuxerJni.nativeStreamCount()
    durationUs = FfmpegDemuxerJni.nativeDurationUs().takeIf { it >= 0 } ?: C.TIME_UNSET
    trackOutputs = arrayOfNulls(count)
    subtitleKinds = Array(count) { SubtitleKind.NONE }
    bitrateMeters = arrayOfNulls(count)
    latmOutputs.clear()
    // Fonts go in before any text track exists so AssHandler's store flushes
    // them into libass when the first ASS track is created.
    deliverFontAttachments()
    val numbers = LongArray(FfmpegDemuxerJni.INFO_LENGTH)
    val strings = arrayOfNulls<String>(3)
    var primaryVideo = -1
    var primaryAudio = -1

    for (index in 0 until count) {
      if (!FfmpegDemuxerJni.nativeStreamInfo(index, numbers, strings)) continue
      val mime = strings[0] ?: continue
      val trackType = when (numbers[FfmpegDemuxerJni.INFO_TRACK_TYPE]) {
        0L -> C.TRACK_TYPE_VIDEO
        1L -> C.TRACK_TYPE_AUDIO
        2L -> C.TRACK_TYPE_TEXT
        else -> continue
      }

      val builder = Format.Builder()
        .setId(index.toString())
        .setSampleMimeType(mime)
        .setLanguage(strings[1])
        .setLabel(strings[2])
        .setSelectionFlags(numbers[FfmpegDemuxerJni.INFO_SELECTION_FLAGS].toInt())
        .setRoleFlags(numbers[FfmpegDemuxerJni.INFO_ROLE_FLAGS].toInt())
        .setAverageBitrate(numbers[FfmpegDemuxerJni.INFO_BITRATE].toInt())

      val extradata = FfmpegDemuxerJni.nativeStreamExtradata(index)
      if (extradata != null) {
        // Audio csd is codec-specific in media3 (see FfmpegAudioCsd); raw
        // extradata is only correct for video (already Annex-B via the JNI
        // bitstream filter) and text tracks.
        builder.setInitializationData(
          if (trackType == C.TRACK_TYPE_AUDIO) {
            FfmpegAudioCsd.initializationData(mime, extradata)
          } else {
            listOf(extradata)
          }
        )
      }

      when (trackType) {
        C.TRACK_TYPE_VIDEO -> {
          // A Dolby Vision config record rides the stream as side data.
          // Mirror media3's MP4/Matroska extractors: recognized profiles
          // publish video/dolby-vision with the RFC 6381 codecs string, so
          // DoviConvertingTrackOutput's P7 conversion, the P8 passthrough
          // path, and the renderer's HEVC fallback engage exactly as they do
          // on the media3 demux path.
          val doviProfile = numbers[FfmpegDemuxerJni.INFO_DOVI_PROFILE].toInt()
          if (doviProfile >= 0) {
            val doviLevel = numbers[FfmpegDemuxerJni.INFO_DOVI_LEVEL].toInt().coerceAtLeast(0)
            val doviCodecs = DoviCodecs.rfc6381(doviProfile, doviLevel)
            if (doviCodecs != null) {
              builder.setCodecs(doviCodecs)
              builder.setSampleMimeType(MimeTypes.VIDEO_DOLBY_VISION)
            }
            Log.i(TAG, "video track $index: doviProfile=$doviProfile doviLevel=$doviLevel codecs=$doviCodecs baseMime=$mime")
          }
          val width = numbers[FfmpegDemuxerJni.INFO_WIDTH].toInt()
          val height = numbers[FfmpegDemuxerJni.INFO_HEIGHT].toInt()
          builder
            .setWidth(width)
            .setHeight(height)
            .setRotationDegrees(numbers[FfmpegDemuxerJni.INFO_ROTATION].toInt())
          val parNum = numbers[FfmpegDemuxerJni.INFO_PAR_NUM]
          val parDen = numbers[FfmpegDemuxerJni.INFO_PAR_DEN]
          if (parNum > 0 && parDen > 0 && parNum != parDen) {
            builder.setPixelWidthHeightRatio(parNum.toFloat() / parDen.toFloat())
          }
          val fpsNum = numbers[FfmpegDemuxerJni.INFO_FPS_NUM]
          val fpsDen = numbers[FfmpegDemuxerJni.INFO_FPS_DEN]
          if (fpsNum > 0 && fpsDen > 0) {
            builder.setFrameRate(fpsNum.toFloat() / fpsDen.toFloat())
          }
          if (primaryVideo < 0) {
            primaryVideo = index
            // libass needs the storage size before the first render; the
            // Matroska path published it from the Tracks element the same way.
            if (width > 0 && height > 0) assHandler.setVideoSize(width, height)
          }
        }
        C.TRACK_TYPE_AUDIO -> {
          builder
            .setSampleRate(numbers[FfmpegDemuxerJni.INFO_SAMPLE_RATE].toInt())
            .setChannelCount(numbers[FfmpegDemuxerJni.INFO_CHANNELS].toInt())
          val pcmEncoding = numbers[FfmpegDemuxerJni.INFO_PCM_ENCODING].toInt()
          if (pcmEncoding >= 0) builder.setPcmEncoding(pcmEncoding)
          if (primaryAudio < 0) primaryAudio = index
          bitrateMeters[index] = StreamBitrateMeter()
        }
        C.TRACK_TYPE_TEXT -> {
          val kind = when (mime) {
            MimeTypes.TEXT_SSA -> SubtitleKind.SSA
            MimeTypes.APPLICATION_SUBRIP -> SubtitleKind.SUBRIP
            MimeTypes.TEXT_VTT -> SubtitleKind.VTT
            else -> SubtitleKind.NONE
          }
          subtitleKinds[index] = kind
          if (kind == SubtitleKind.SSA) {
            // Embedded ASS reaches libass as per-sample dialogue, never as a
            // whole file: AssSubtitleParserFactory keys embedded handling off
            // the Matroska container mime, and AssHeaderParser reads the
            // header from initializationData[1] — the exact layout media3's
            // MatroskaExtractor publishes.
            builder.setContainerMimeType(MimeTypes.VIDEO_MATROSKA)
            if (extradata != null) {
              builder.setInitializationData(
                listOf(FfmpegSubtitleSamples.SSA_DIALOGUE_FORMAT, extradata)
              )
            }
          }
        }
      }

      val rawOutput = output.track(index, trackType)
      val trackOutput = if (trackType == C.TRACK_TYPE_AUDIO && numbers[FfmpegDemuxerJni.INFO_LATM] == 1L) {
        // LOAS/LATM-framed AAC: unwrap to raw access units; the wrapper
        // swallows this placeholder Format and emits the real one parsed from
        // the StreamMuxConfig.
        LatmTrackOutput(rawOutput, index).also { latmOutputs.add(it) }
      } else {
        rawOutput
      }
      trackOutput.format(builder.build())
      trackOutputs[index] = trackOutput
    }

    output.endTracks()
    output.seekMap(SeekMapImpl())
  }

  /** Hands embedded font attachments to libass, under the shared budgets. */
  private fun deliverFontAttachments() {
    val count = FfmpegDemuxerJni.nativeAttachmentCount()
    if (count <= 0) return
    var acceptedBytes = 0L
    val meta = arrayOfNulls<String>(2)
    for (ordinal in 0 until count) {
      val size = FfmpegDemuxerJni.nativeAttachmentInfo(ordinal, meta)
      if (size <= 0) continue
      val name = meta[0] ?: continue
      val mime = meta[1] ?: continue
      if (mime !in AssFonts.fontMimeTypes) continue
      val rejectionReason = AssFonts.rejectionReason(size, acceptedBytes)
      if (rejectionReason != null) {
        Log.w(TAG, "Skipping embedded font: $rejectionReason (bytes=$size, accepted=$acceptedBytes)")
        continue
      }
      val data = FfmpegDemuxerJni.nativeAttachmentData(ordinal) ?: continue
      acceptedBytes += size
      assHandler.addFont(name, data)
    }
  }

  private fun readPacket(): Int {
    while (true) {
      val code = FfmpegDemuxerJni.nativeReadPacket(packetBytes, packetOut)
      when (code) {
        FfmpegDemuxerJni.CODE_PACKET -> {
          val streamIndex = packetOut[FfmpegDemuxerJni.OUT_STREAM_INDEX].toInt()
          val size = packetOut[FfmpegDemuxerJni.OUT_SIZE].toInt()
          val trackOutput = trackOutputs.getOrNull(streamIndex) ?: continue
          val ptsUs = packetOut[FfmpegDemuxerJni.OUT_PTS_US]
          val isKeyframe = packetOut[FfmpegDemuxerJni.OUT_FLAGS] and 1L != 0L
          val subtitleKind = subtitleKinds.getOrNull(streamIndex) ?: SubtitleKind.NONE
          if (subtitleKind != SubtitleKind.NONE) {
            // Text samples carry their duration inside the sample text, in
            // media3's MatroskaExtractor shape; a sample without a duration
            // cannot be displayed (same skip media3 performs).
            val sampleDurationUs = packetOut[FfmpegDemuxerJni.OUT_DURATION_US]
            if (sampleDurationUs <= 0) {
              Log.w(TAG, "Skipping subtitle sample with no duration (stream=$streamIndex)")
              continue
            }
            val prefix = when (subtitleKind) {
              SubtitleKind.SSA -> FfmpegSubtitleSamples.ssaPrefix(sampleDurationUs)
              SubtitleKind.SUBRIP -> FfmpegSubtitleSamples.subripPrefix(sampleDurationUs)
              else -> FfmpegSubtitleSamples.vttPrefix(sampleDurationUs)
            }
            prefixParsable.reset(prefix, prefix.size)
            trackOutput.sampleData(prefixParsable, prefix.size)
            packetParsable.reset(packetBytes, size)
            trackOutput.sampleData(packetParsable, size)
            trackOutput.sampleMetadata(
              ptsUs,
              C.BUFFER_FLAG_KEY_FRAME,
              prefix.size + size,
              /* offset= */
              0,
              /* cryptoData= */
              null
            )
            return Extractor.RESULT_CONTINUE
          }
          packetParsable.reset(packetBytes, size)
          trackOutput.sampleData(packetParsable, size)
          // Native drops packets without any timestamp, so ptsUs is always real.
          trackOutput.sampleMetadata(
            ptsUs,
            if (isKeyframe) C.BUFFER_FLAG_KEY_FRAME else 0,
            size,
            /* offset= */
            0,
            /* cryptoData= */
            null
          )
          deliveredAnyPacket = true
          bitrateMeters.getOrNull(streamIndex)?.onPacket(ptsUs, size)
          return Extractor.RESULT_CONTINUE
        }
        FfmpegDemuxerJni.CODE_EOF -> return Extractor.RESULT_END_OF_INPUT
        FfmpegDemuxerJni.CODE_GROW -> {
          val required = packetOut[FfmpegDemuxerJni.OUT_SIZE].toInt()
          packetBytes = ByteArray(required + 64 * 1024)
        }
        FfmpegDemuxerJni.ERR_JAVA ->
          throw IOException(inputProxy.lastError ?: "demuxer input failed")
        else -> throw malformed("ffmpeg demuxer read failed: $code")
      }
    }
  }

  private fun malformed(message: String): ParserException = ParserException.createForMalformedContainer(message, null)

  private inner class SeekMapImpl : SeekMap {
    override fun isSeekable(): Boolean = this@FfmpegExtractor.durationUs != C.TIME_UNSET

    /**
     * The demuxer owns seek resolution: it reads its own index and lands on
     * the right keyframe by itself, so there is no second index here to keep
     * consistent. The byte position exists only to satisfy the interface —
     * [alignLoader] moves the loader to wherever libavformat actually ended
     * up, on the read that follows the seek.
     */
    override fun getSeekPoints(timeUs: Long): SeekMap.SeekPoints = SeekMap.SeekPoints(SeekPoint(timeUs, 0))

    // Qualified on purpose: bare `durationUs` binds to the inherited Java
    // getter as a synthetic property (this.getDurationUs()) and recurses.
    override fun getDurationUs(): Long = this@FfmpegExtractor.durationUs
  }
}

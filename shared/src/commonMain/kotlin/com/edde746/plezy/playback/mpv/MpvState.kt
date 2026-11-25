package com.edde746.plezy.playback.mpv

import com.edde746.plezy.log.Log
import com.edde746.plezy.log.Redactor
import com.edde746.plezy.playback.AudioDevice
import com.edde746.plezy.playback.AudioInfo
import com.edde746.plezy.playback.AudioRendering
import com.edde746.plezy.playback.Chapter
import com.edde746.plezy.playback.DynamicRange
import com.edde746.plezy.playback.EngineErrorKind
import com.edde746.plezy.playback.PlaybackStats
import com.edde746.plezy.playback.SubtitleFrame
import com.edde746.plezy.playback.Track
import com.edde746.plezy.playback.TrackKind
import com.edde746.plezy.playback.VideoInfo
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.longOrNull
import kotlin.math.abs

/**
 * What every engine reads from mpv, turned into the shared playback model ([com.edde746.plezy.playback.EngineState]),
 * one rule for Android, desktop and Apple; [MpvLifecycle] applies it to the properties every engine observes. Engines
 * observe mpv's node properties (`track-list`, `video-params`, `video-target-params`, `audio-params`, `chapter-list`,
 * `audio-device-list`, `osd-dimensions`, `demuxer-cache-state`) as strings, which mpv prints as JSON: an absent
 * property (null) reads as none, and text that isn't JSON, which mpv never prints, is logged as the error it is and read
 * as none. Numbers follow mpv's formats: an integer is an integer in the JSON, a double has a fraction.
 */
object MpvState {
    /**
     * A video track as the per-file decode routing and the display's setup see it (nothing need be selected yet): with
     * the container's frame rate and size (`demux-fps`, `demux-w`, `demux-h`), each null when it gives none.
     */
    data class VideoTrack(
        val id: Long,
        val selected: Boolean,
        val codec: String?,
        val codecProfile: String?,
        val doviProfile: Int?,
        val doviLevel: Int?,
        val fps: Double? = null,
        val width: Int? = null,
        val height: Int? = null,
    )

    /** The display's mode at a stats reading: its size in pixels and its refresh rate in Hz, each null when unknown. */
    data class DisplayMode(val width: Int?, val height: Int?, val refreshRate: Double?)

    /** The video packets the demuxer holds: [seconds] of them ahead of the decoder, the pts of the one it took last. */
    data class VideoCache(val seconds: Double, val readerPts: Double?)

    /** mpv's `osd-dimensions`: the output's size and the bands around the picture, in pixels. */
    data class OsdDimensions(
        val width: Double,
        val height: Double,
        val left: Double,
        val right: Double,
        val top: Double,
        val bottom: Double,
    )

    /**
     * Whether the engine shows a file as buffering ([com.edde746.plezy.playback.EngineState.buffering], whose KDoc
     * is the contract): [open] a load went out and its file hasn't ended, [failed] it ended in an error, [eof] mpv
     * reached its end, [firstFrameShown] its first `playback-restart` came, [held] the platform holds playback (a display
     * mode switch, Apple's start gate), [pausedForCache] mpv's `paused-for-cache`, [seeking] mpv's `seeking` for a seek
     * that moves playback (not one in place, [MpvLifecycle.seekInPlace]).
     */
    internal fun buffering(
        open: Boolean,
        failed: Boolean,
        eof: Boolean,
        firstFrameShown: Boolean,
        held: Boolean,
        pausedForCache: Boolean,
        seeking: Boolean,
    ): Boolean = open && !failed && !eof && (held || !firstFrameShown || pausedForCache || seeking)

    /**
     * `track-list` entries as [Track]s. Entries of unknown type or without an id are skipped; the channel count
     * (`demux-channel-count`) is kept for audio only and when positive; a blank title, language, codec or profile is none.
     * A track mpv selected as `secondary-sid` (`main-selection` 1) is [Track.secondary], not [Track.selected].
     */
    internal fun tracks(trackList: String?): List<Track> = array(trackList)?.let(::tracks).orEmpty()

    internal fun tracks(trackList: JsonArray): List<Track> = trackList.objects().mapNotNull { track ->
        val kind = when (track.string("type")) {
            "video" -> TrackKind.VIDEO
            "audio" -> TrackKind.AUDIO
            "sub" -> TrackKind.SUBTITLE
            else -> return@mapNotNull null
        }
        Track(
            id = track.long("id") ?: return@mapNotNull null,
            kind = kind,
            title = track.string("title"),
            language = track.string("lang"),
            codec = track.string("codec"),
            selected = track.flag("selected") && track.long("main-selection") != 1L,
            secondary = track.flag("selected") && track.long("main-selection") == 1L,
            external = track.flag("external"),
            externalFilename = track.string("external-filename"),
            isDefault = track.flag("default"),
            forced = track.flag("forced"),
            hearingImpaired = track.flag("hearing-impaired"),
            visualImpaired = track.flag("visual-impaired"),
            channels = if (kind == TrackKind.AUDIO) track.long("demux-channel-count")?.toInt()?.takeIf { it > 0 } else null,
            codecProfile = track.string("codec-profile"),
        )
    }

    /** The video entries of `track-list`, selected or not, with their Dolby Vision configuration record. */
    fun videoTracks(trackList: String?): List<VideoTrack> = array(trackList)?.let(::videoTracks).orEmpty()

    internal fun videoTracks(trackList: JsonArray): List<VideoTrack> = trackList.objects()
        .filter { it.string("type") == "video" }
        .mapNotNull { track ->
            VideoTrack(
                id = track.long("id") ?: return@mapNotNull null,
                selected = track.flag("selected"),
                codec = track.string("codec"),
                codecProfile = track.string("codec-profile"),
                doviProfile = track.long("dolby-vision-profile")?.toInt(),
                doviLevel = track.long("dolby-vision-level")?.toInt(),
                fps = track.double("demux-fps")?.takeIf { it > 0 },
                width = track.long("demux-w")?.toInt()?.takeIf { it > 0 },
                height = track.long("demux-h")?.toInt()?.takeIf { it > 0 },
            )
        }

    /**
     * The shown video from `video-params` (its size and `rotate`) and the selected video track (codec,
     * `dolby-vision-profile`), at the rate the player presents it: [containerFps] (`container-fps`, else the track's
     * `demux-fps`) times [rateFactor] ([presentedRateFactor]); without either (a Matroska track with no
     * DefaultDuration), the [standardRate] mpv's measured output rate ([estimatedFps], `estimated-vf-fps`) identifies,
     * already the presented one. Null until the video output is configured
     * (`video-params` has a size and a pixel format): before the first frame mpv reports the container's size alone,
     * without the transfer, which would read an HDR file as SDR (and a display switched for that would switch again).
     *
     * Dynamic range: Dolby Vision when the track carries a Dolby Vision configuration record or the frames are in
     * Dolby Vision's colour system (`colormatrix=dolbyvision`, profile 5 decoded with its RPU); otherwise the
     * transfer (`gamma`) decides: `pq` is HDR10, `hlg` is HLG, anything else SDR.
     */
    internal fun videoInfo(videoParams: String?, trackList: String?): VideoInfo? =
        obj(videoParams)?.let { videoInfo(it, array(trackList)) }

    internal fun videoInfo(
        videoParams: JsonObject,
        trackList: JsonArray?,
        containerFps: Double? = null,
        rateFactor: Double = 1.0,
        estimatedFps: Double? = null,
    ): VideoInfo? {
        val params = videoParams.takeIf { it.string("pixelformat") != null } ?: return null
        val width = params.long("w")?.toInt()?.takeIf { it > 0 } ?: return null
        val height = params.long("h")?.toInt()?.takeIf { it > 0 } ?: return null
        val track = selected(trackList, "video")
        val doviProfile = track?.long("dolby-vision-profile")?.toInt()
        val range = when {
            doviProfile != null || params.string("colormatrix") == "dolbyvision" -> DynamicRange.DOLBY_VISION
            else -> rangeOfTransfer(params.string("gamma"))
        }
        return VideoInfo(
            width = width,
            height = height,
            codec = track?.string("codec"),
            fps = (containerFps ?: track?.double("demux-fps"))?.takeIf { it > 0 }?.let { it * rateFactor } ?: standardRate(estimatedFps),
            dynamicRange = range,
            doviProfile = doviProfile.takeIf { range == DynamicRange.DOLBY_VISION },
            rotation = params.long("rotate")?.toInt() ?: 0,
            sigPeak = params.double("sig-peak")?.takeIf { it > 0 },
            gamma = params.string("gamma"),
            primaries = params.string("primaries"),
            colorMatrix = params.string("colormatrix"),
        )
    }

    /** The transfer (`gamma`) of `video-params`: `pq`, `hlg`, `bt.1886`…; null before the output is configured. */
    internal fun transfer(videoParams: String?): String? = obj(videoParams)?.let(::transfer)

    internal fun transfer(videoParams: JsonObject): String? = videoParams.string("gamma")

    /**
     * What the player presents of a [containerFps] video, as a multiple of it: one frame per field doubles it
     * ([presentsFields]), inverse telecine ([ivtcActive], mpv's `ivtc-active`: the film frames rebuilt, one in five
     * dropped) makes it four fifths, so 29.97i film is presented at 23.976. A display mode picked for the container's
     * rate would drop every other frame of a field-rate picture, or bring the 3:2 judder back to a film one.
     */
    fun presentedRateFactor(containerFps: Double?, estimatedFps: Double?, deinterlaceActive: Boolean, ivtcActive: Boolean): Double = when {
        ivtcActive -> IVTC_RATE_FACTOR
        presentsFields(containerFps, estimatedFps, deinterlaceActive) -> 2.0
        else -> 1.0
    }

    /**
     * A [containerFps] video is presented one frame per field: mpv's own deinterlacer runs ([deinterlaceActive], mpv's
     * `deinterlace-active`: every deinterlacer `deinterlace=auto` picks emits fields), or the output cadence mpv
     * measures ([estimatedFps], `estimated-vf-fps`) is the container's doubled, which is all that tells a decoder that
     * deinterlaces by itself (MediaCodec on Tegra, MediaTek, Amlogic). The band absorbs Matroska's millisecond
     * timestamps (a 16.68 ms field reads as 16 or 17 ms) and one duplicated timestamp in ten frames (10/9 × 2 = 2.22),
     * and rejects a duplicate of every frame (3×), a dropped one (0.5×) and telecine (1.25×).
     */
    fun presentsFields(containerFps: Double?, estimatedFps: Double?, deinterlaceActive: Boolean): Boolean {
        if (deinterlaceActive) return true
        if (containerFps == null || containerFps <= 0 || estimatedFps == null || estimatedFps <= 0) return false
        val ratio = estimatedFps / containerFps
        return ratio > 1.7 && ratio < 2.3
    }

    /** 3:2 pulldown carries four film frames in five video frames. */
    const val IVTC_RATE_FACTOR = 0.8

    /** The rates [standardRate] may identify. */
    private val STANDARD_RATES = doubleArrayOf(
        24000.0 / 1001, 24.0, 25.0, 30000.0 / 1001, 30.0, 48000.0 / 1001, 48.0, 50.0, 60000.0 / 1001, 60.0, 100.0,
        120000.0 / 1001, 120.0,
    )

    /**
     * The standard rate (23.976 to 120) nearest a measured [fps], or null when none lies within what millisecond
     * timestamps blur: ten frames' span, to a millisecond. Ten 24 fps frames may read as 23.976's 417 ms (one repeated
     * frame every ~42 s rather than 3:2 judder); variable-rate content or a misdetected 24.417 matches nothing, so
     * nothing switches for it.
     */
    fun standardRate(fps: Double?): Double? {
        if (fps == null || fps <= 0) return null
        val span = STANDARD_SPAN_FRAMES / fps
        val nearest = STANDARD_RATES.minBy { abs(STANDARD_SPAN_FRAMES / it - span) }
        return nearest.takeIf { abs(STANDARD_SPAN_FRAMES / it - span) <= STANDARD_SPAN_TOLERANCE_SECONDS }
    }

    private const val STANDARD_SPAN_FRAMES = 10
    private const val STANDARD_SPAN_TOLERANCE_SECONDS = 0.001

    /**
     * The played audio from `audio-params` (`channel-count`, `samplerate`: the decoder's output) and the codec of the
     * selected audio track. Null until audio is decoding.
     */
    internal fun audioInfo(audioParams: String?, trackList: String?): AudioInfo? =
        obj(audioParams)?.let { audioInfo(it, array(trackList)) }

    internal fun audioInfo(audioParams: JsonObject, trackList: JsonArray?): AudioInfo? {
        val params = audioParams.takeIf { it.isNotEmpty() } ?: return null
        return AudioInfo(
            codec = selected(trackList, "audio")?.string("codec"),
            channels = params.long("channel-count")?.toInt()?.takeIf { it > 0 },
            sampleRate = params.long("samplerate")?.toInt()?.takeIf { it > 0 },
        )
    }

    /**
     * Whether passthrough is in effect, from the format the audio output was opened with (`audio-out-params/format`):
     * mpv names the bitstreams it wraps for a receiver (IEC 61937) `spdif-ac3`, `spdif-eac3`, `spdif-dts`, `spdif-dtshd`,
     * `spdif-truehd`… A PCM format, or no output (null), decodes. mpv falls back to decoding when the output refuses a
     * bitstream, so this, not `audio-spdif`, says what reaches the receiver.
     */
    fun audioPassthrough(outputFormat: String?): Boolean = outputFormat?.startsWith(SPDIF) == true

    /** The bitstream the receiver gets undecoded: `audio-out-params/format` less its `spdif-`; null while decoding. */
    fun passthroughFormat(outputFormat: String?): String? = outputFormat?.takeIf(::audioPassthrough)?.removePrefix(SPDIF)

    /** `chapter-list` entries (`title`, `time`) as [Chapter]s; entries without a time are skipped, an empty title is none. */
    internal fun chapters(chapterList: String?): List<Chapter> = array(chapterList)?.let(::chapters).orEmpty()

    internal fun chapters(chapterList: JsonArray): List<Chapter> = chapterList.objects().mapNotNull { chapter ->
        val time = chapter.double("time") ?: return@mapNotNull null
        Chapter(title = chapter.string("title"), startSeconds = time)
    }

    /**
     * `audio-device-list` entries (`name`, `description`) as [AudioDevice]s, in mpv's order (`auto`, the system's
     * choice, first); entries without a name are skipped.
     */
    internal fun audioDevices(deviceList: String?): List<AudioDevice> = array(deviceList)?.let(::audioDevices).orEmpty()

    internal fun audioDevices(deviceList: JsonArray): List<AudioDevice> = deviceList.objects().mapNotNull { device ->
        val name = device.string("name") ?: return@mapNotNull null
        AudioDevice(name, device.string("description") ?: name)
    }

    /**
     * Where the entry of `demuxer-cache-state`'s `seekable-ranges` that holds [position] starts
     * (`EngineState.cacheStartSeconds`); null when none holds it, or with no cache state (no file).
     */
    internal fun cacheStart(cacheState: String?, position: Double): Double? = obj(cacheState)?.let { cacheStart(it, position) }

    internal fun cacheStart(cacheState: JsonObject, position: Double): Double? =
        (cacheState["seekable-ranges"] as? JsonArray).objects().firstNotNullOfOrNull { range ->
            val start = range.double("start") ?: return@firstNotNullOfOrNull null
            val end = range.double("end") ?: return@firstNotNullOfOrNull null
            start.takeIf { position in start..end }
        }

    /**
     * Where what mpv read ahead ends (`EngineState.cacheEndSeconds`): `demuxer-cache-state`'s `cache-end`, the last
     * timestamp read, as `time-pos` counts; [duration] once the read reached the file's end (`eof`) and the file has
     * one. Null with nothing read.
     */
    internal fun cacheEnd(cacheState: JsonObject, duration: Double): Double? =
        if (cacheState.flag("eof") && duration > 0) duration else cacheState.double("cache-end")

    /**
     * The video stream's entry of `demuxer-cache-state`'s `ts-per-stream` ([VideoCache]: `cache-duration`,
     * `reader-pts`); null without one, which mpv leaves out for a file without video, for cover art (not read ahead)
     * and for a video stream whose packets have all been taken at its end.
     */
    fun videoCache(cacheState: String?): VideoCache? {
        val video = (obj(cacheState)?.get("ts-per-stream") as? JsonArray).objects().firstOrNull { it.string("type") == "video" } ?: return null
        return VideoCache(seconds = video.double("cache-duration") ?: return null, readerPts = video.double("reader-pts"))
    }

    /**
     * What the display gets from a video output that renders (`EngineState.outputDynamicRange`): its render target's
     * transfer (`video-target-params/gamma`), `pq` HDR10, `hlg` HLG, anything else SDR. Null before mpv has a target,
     * and while it says `auto`.
     */
    fun outputRange(targetParams: String?): DynamicRange? = when (val gamma = obj(targetParams)?.string("gamma")) {
        null, "auto" -> null
        else -> rangeOfTransfer(gamma)
    }

    /**
     * What the display gets on Android, where the picture goes either to the video plane ([videoPlane],
     * `vo=mediacodec`) or to a GL vo. The plane composes the decoder's buffers in their own colour space: the frames'
     * HDR format when the display takes it ([displayHdr], its `HdrCapabilities` types), otherwise SDR, which Android
     * tone-maps HDR to. That is Dolby Vision from a Dolby Vision decoder ([dolbyVisionDecoder]); otherwise the
     * [transfer] the decoder reports (`video-params/gamma`, [MpvLifecycle.transfer]), so Dolby Vision profile 8 decoded
     * as HEVC is its base layer's HDR10 (8.1) or HLG (8.4). A GL vo's picture is its render target ([outputRange]).
     * Under [sdrHeadroom] (the compositor keeps the picture within SDR, `SurfaceHints.sdr` on API 35+) every HDR picture
     * reaches the display tone-mapped: SDR. Null while the output is not configured.
     */
    fun androidOutputRange(
        transfer: String?,
        targetParams: String?,
        videoPlane: Boolean,
        displayHdr: Set<DynamicRange>,
        dolbyVisionDecoder: Boolean,
        sdrHeadroom: Boolean,
    ): DynamicRange? {
        val range = if (videoPlane) {
            val frames = rangeOfTransfer(transfer ?: return null)
            when {
                dolbyVisionDecoder && DynamicRange.DOLBY_VISION in displayHdr -> DynamicRange.DOLBY_VISION
                frames in displayHdr -> frames
                else -> DynamicRange.SDR
            }
        } else {
            outputRange(targetParams) ?: return null
        }
        return if (sdrHeadroom) DynamicRange.SDR else range
    }

    /**
     * The picture text subtitles are placed by (`sub-use-margins=no`) from `osd-dimensions`: the output's height `h`
     * less the bands `mt` above and `mb` below the picture; [SubtitleFrame.SCREEN] before mpv has an output.
     */
    fun subtitleFrame(osdDimensions: String?): SubtitleFrame {
        val dimensions = obj(osdDimensions) ?: return SubtitleFrame.SCREEN
        return SubtitleFrame.picture(
            height = dimensions.double("h") ?: 0.0,
            top = dimensions.double("mt") ?: 0.0,
            bottom = dimensions.double("mb") ?: 0.0,
        )
    }

    /** The video output's shape from `osd-dimensions` (`w`, `h`, in pixels), width over height; null before an output. */
    fun surfaceAspect(osdDimensions: String?): Double? {
        val dimensions = obj(osdDimensions) ?: return null
        val width = dimensions.long("w")?.takeIf { it > 0 } ?: return null
        val height = dimensions.long("h")?.takeIf { it > 0 } ?: return null
        return width.toDouble() / height
    }

    /**
     * The picture's shape as it shows from `video-params` (`dw`, `dh`: its display size, the pixel aspect counted),
     * width over height; null before the output is configured. Ambient lighting's `sub-video-rect-aspect`.
     */
    fun displayAspect(videoParams: String?): Double? {
        val params = obj(videoParams) ?: return null
        val width = params.long("dw")?.takeIf { it > 0 } ?: return null
        val height = params.long("dh")?.takeIf { it > 0 } ?: return null
        return width.toDouble() / height
    }

    /** `osd-dimensions` (`w`, `h`, and the bands `ml`, `mr`, `mt`, `mb`, 0 when absent); null before an output. */
    fun osdDimensions(osdDimensions: String?): OsdDimensions? {
        val dimensions = obj(osdDimensions) ?: return null
        return OsdDimensions(
            width = dimensions.double("w")?.takeIf { it > 0 } ?: return null,
            height = dimensions.double("h")?.takeIf { it > 0 } ?: return null,
            left = dimensions.double("ml") ?: 0.0,
            right = dimensions.double("mr") ?: 0.0,
            top = dimensions.double("mt") ?: 0.0,
            bottom = dimensions.double("mb") ?: 0.0,
        )
    }

    /** The properties [stats] reads as text: node properties among them come as their JSON. */
    val STATS_TEXT_PROPERTIES: List<String> = listOf(
        "filename", "file-format", "video-params", "audio-params/hr-channels", "current-ao", "audio-out-params/format",
        "demuxer-cache-state",
    )

    /** The properties [stats] reads as numbers (mpv converts its integers to doubles). */
    val STATS_NUMBER_PROPERTIES: List<String> = listOf(
        "file-size", "video-bitrate", "audio-bitrate", "frame-drop-count", "decoder-frame-drop-count",
        "vo-delayed-frame-count", "cache-speed", "cache-buffering-state", "estimated-vf-fps", "total-avsync-change",
        "demuxer-max-bytes", "demuxer-max-back-bytes", "current-tracks/audio/demux-samplerate",
        "current-tracks/audio/demux-channel-count",
    )

    /**
     * One playback info reading ([PlaybackStats] names each field's mpv property): [text] reads one of
     * [STATS_TEXT_PROPERTIES], [number] one of [STATS_NUMBER_PROPERTIES]; either is null for a property mpv has no value
     * for. [display] is the display's mode, from the platform or from mpv (`display-width`, `display-height`,
     * `display-fps`), and [audioRendering] the system's rendering of the audio where the platform reports it. A count or
     * rate below zero is none.
     */
    fun stats(
        text: (String) -> String?,
        number: (String) -> Double?,
        display: DisplayMode?,
        audioRendering: AudioRendering? = null,
    ): PlaybackStats {
        fun count(name: String): Long? = number(name)?.takeIf { it.isFinite() && it >= 0 }?.toLong()
        fun rate(name: String): Double? = number(name)?.takeIf { it.isFinite() && it >= 0 }
        val video = obj(text("video-params"))
        return PlaybackStats(
            fileName = text("filename")?.takeIf { it.isNotBlank() },
            fileFormat = text("file-format")?.takeIf { it.isNotBlank() },
            fileSizeBytes = count("file-size"),
            pixelFormat = video?.string("pixelformat"),
            hwPixelFormat = video?.string("hw-pixelformat"),
            primaries = video?.string("primaries"),
            transfer = video?.string("gamma"),
            colorMatrix = video?.string("colormatrix"),
            maxCll = video?.double("max-cll"),
            maxFall = video?.double("max-fall"),
            masteringMinLuminance = video?.double("min-luma"),
            masteringMaxLuminance = video?.double("max-luma"),
            videoBitrate = rate("video-bitrate"),
            audioBitrate = rate("audio-bitrate"),
            droppedFrames = count("frame-drop-count"),
            decoderDroppedFrames = count("decoder-frame-drop-count"),
            delayedFrames = count("vo-delayed-frame-count"),
            displayWidth = display?.width,
            displayHeight = display?.height,
            displayRefreshRate = display?.refreshRate,
            channelLayout = text("audio-params/hr-channels")?.takeIf { it.isNotBlank() },
            audioOutput = text("current-ao")?.takeIf { it.isNotBlank() },
            passthroughFormat = passthroughFormat(text("audio-out-params/format")),
            audioRendering = audioRendering,
            cacheBytes = obj(text("demuxer-cache-state"))?.long("fw-bytes")?.takeIf { it >= 0 },
            downloadBytesPerSecond = count("cache-speed"),
            bufferingPercent = count("cache-buffering-state")?.toInt(),
            estimatedFps = rate("estimated-vf-fps"),
            aspectName = video?.string("aspect-name"),
            avSyncChange = number("total-avsync-change")?.takeIf { it.isFinite() },
            sourceSampleRate = count("current-tracks/audio/demux-samplerate")?.toInt()?.takeIf { it > 0 },
            sourceChannelCount = count("current-tracks/audio/demux-channel-count")?.toInt()?.takeIf { it > 0 },
            demuxerMaxBytes = count("demuxer-max-bytes"),
            demuxerMaxBackBytes = count("demuxer-max-back-bytes"),
        )
    }

    /**
     * The status of an FFmpeg HTTP failure in an mpv log line (`http: HTTP error 404 Not Found`), if it is one: FFmpeg
     * logs it before mpv reports the open failure.
     */
    fun httpStatus(logLine: String): Int? = HTTP_ERROR.find(logLine)?.groupValues?.get(1)?.toInt()

    /**
     * mpv's error code (`mpv_error` in client.h: an end-file's `error`, a command's status) as what the player says.
     */
    fun errorKind(code: Int): EngineErrorKind = when (code) {
        MPV_ERROR_LOADING_FAILED -> EngineErrorKind.OPEN
        MPV_ERROR_UNKNOWN_FORMAT, MPV_ERROR_UNSUPPORTED -> EngineErrorKind.FORMAT
        MPV_ERROR_AO_INIT_FAILED -> EngineErrorKind.AUDIO_OUTPUT
        MPV_ERROR_VO_INIT_FAILED, MPV_ERROR_NOTHING_TO_PLAY -> EngineErrorKind.DECODE
        else -> EngineErrorKind.OTHER
    }

    private const val SPDIF = "spdif-"

    private val HTTP_ERROR = Regex("""HTTP error (\d{3})""")

    // client.h's mpv_error values.
    private const val MPV_ERROR_LOADING_FAILED = -13
    private const val MPV_ERROR_AO_INIT_FAILED = -14
    private const val MPV_ERROR_VO_INIT_FAILED = -15
    private const val MPV_ERROR_NOTHING_TO_PLAY = -16
    private const val MPV_ERROR_UNKNOWN_FORMAT = -17
    private const val MPV_ERROR_UNSUPPORTED = -18

    private fun rangeOfTransfer(gamma: String?): DynamicRange = when (gamma) {
        "pq" -> DynamicRange.HDR10
        "hlg" -> DynamicRange.HLG
        else -> DynamicRange.SDR
    }

    /** [json] as mpv printed it; null for none, and for text that isn't JSON, which is logged: mpv prints only JSON. */
    internal fun parse(json: String?): JsonElement? {
        if (json == null) return null
        return try {
            Json.parseToJsonElement(json)
        } catch (e: SerializationException) {
            Log.e(TAG, e) { "mpv's node text isn't JSON: ${Redactor.redact(json.take(200))}" }
            null
        }
    }

    private const val TAG = "MpvState"

    private fun array(json: String?): JsonArray? = parse(json) as? JsonArray

    private fun obj(json: String?): JsonObject? = parse(json) as? JsonObject

    private fun selected(trackList: JsonArray?, type: String): JsonObject? =
        trackList.objects().firstOrNull { it.string("type") == type && it.flag("selected") }

    private fun JsonArray?.objects(): List<JsonObject> = this.orEmpty().filterIsInstance<JsonObject>()

    private fun JsonObject.primitive(name: String): JsonPrimitive? = this[name] as? JsonPrimitive

    /** A string value, none when blank. */
    private fun JsonObject.string(name: String): String? = primitive(name)?.takeIf { it.isString }?.content?.takeIf { it.isNotBlank() }

    private fun JsonObject.long(name: String): Long? = primitive(name)?.takeUnless { it.isString }?.longOrNull

    private fun JsonObject.double(name: String): Double? =
        primitive(name)?.takeUnless { it.isString }?.doubleOrNull?.takeIf { it.isFinite() }

    private fun JsonObject.flag(name: String): Boolean = primitive(name)?.takeUnless { it.isString }?.booleanOrNull == true
}

package com.edde746.plezy.playback.mpv

import com.edde746.plezy.log.Log
import com.edde746.plezy.log.Redactor
import com.edde746.plezy.playback.AudioRendering
import com.edde746.plezy.playback.DynamicRange
import com.edde746.plezy.playback.EngineError
import com.edde746.plezy.playback.EngineErrorKind
import com.edde746.plezy.playback.EngineState
import com.edde746.plezy.playback.PlaybackStats
import kotlin.concurrent.atomics.AtomicLong
import kotlin.concurrent.atomics.ExperimentalAtomicApi
import kotlin.math.abs
import kotlin.math.floor
import kotlin.math.log10
import kotlin.math.pow
import kotlin.math.round
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

/**
 * One engine's mpv as [EngineState], one rule for Android, desktop and Apple: each file's lifecycle (a load, then mpv's
 * `start-file`, `file-loaded`, `playback-restart` and `end-file`), what a new file starts over, and the properties every
 * engine observes ([DOUBLES], [FLAGS], [TEXTS]; [AUDIO_DEVICE_TEXTS] where the player picks the output) with the field
 * each one sets ([MpvState]'s rules). The engine keeps mpv's handle and its events, its surfaces and its audio route:
 * it hands each event, observed value and log line here, from one thread at a time (its mpv thread, or under its state
 * lock), with what only the platform knows ([hold], [outputRange], [stats], [fail]), and publishes [state] when
 * [publishable] says so.
 *
 * A new file (a load, and mpv's `start-file`) starts over what is the file's own: its position and length, what is
 * read ahead, its tracks and chapters, its end, its error, its first frame and the playback info's reading. What mpv's
 * outputs and decoder report (the video, the audio, the hardware decoder, whether the file seeks, passthrough, the
 * output's dynamic range) and the player's settings stay until mpv reports others: mpv sends an observed property only
 * when it differs from what it sent last, as of when the engine reads its events, so a spell without a value between
 * two files can go unseen, and a value the next file repeats doesn't come again.
 */
@OptIn(ExperimentalAtomicApi::class)
class MpvLifecycle {
    /** The engine's state as mpv's events and properties and the platform made it. */
    var state: EngineState = EngineState()
        private set

    /** mpv loaded the current file (`file-loaded`): commands on the file's tracks, `sub-add` among them, take. */
    var isFileLoaded: Boolean = false
        private set

    /** The transfer of `video-params` (`pq`, `hlg`, `bt.1886`…) as last reported; null before the output is configured. */
    var transfer: String? = null
        private set

    /** The current file's video tracks with their Dolby Vision configuration record, per file like its tracks. */
    var videoTracks: List<MpvState.VideoTrack> = emptyList()
        private set

    /** The platform holds playback ([hold]). */
    val held: Boolean get() = heldPaused != null

    private val loadIds = AtomicLong(0L)

    /** A load went out and its file hasn't ended. */
    private var open = false

    /** A load went out and mpv hasn't started its file: mpv's events until then are the replaced file's. */
    private var startFilePending = false

    /** The current file's first `playback-restart` came: [EngineState.loaded]. */
    private var frameShown = false
    private var pausedForCache = false
    private var seeking = false

    /** The seek under way only drops what the output holds ([seekInPlace]): no wait. */
    private var seekingInPlace = false

    /** mpv's `pause`, and while the platform holds playback ([hold]) the viewer's own pause. */
    private var mpvPaused = false
    private var heldPaused: Boolean? = null

    /**
     * What the current file's log said of a failure: FFmpeg's last HTTP status for the stream ([EngineState.httpErrorStatus]),
     * the one before it (back in place once an external file's open turns out to have logged the last), and mpv's last
     * error line, redacted.
     */
    private var httpStatus: Int? = null
    private var earlierHttpStatus: Int? = null
    private var errorLine: String? = null

    /** The node properties [EngineState.tracks], [EngineState.video] and [EngineState.audio] come from, read once per change. */
    private var trackList: JsonArray? = null
    private var videoParams: JsonObject? = null
    private var audioParams: JsonObject? = null

    /** The current file's last `demuxer-cache-state`, which [EngineState.cacheEndSeconds] reads with the duration. */
    private var cacheState: JsonObject? = null

    /**
     * What the presented rate of [EngineState.video] comes from ([MpvState.presentedRateFactor]): `container-fps`,
     * `estimated-vf-fps`, `deinterlace-active` and `ivtc-active` as last reported, and the factor they make, which
     * changes the video only when it changes (the estimate moves at every frame).
     */
    private var containerFps: Double? = null
    private var estimatedFps: Double? = null
    private var deinterlaceActive = false
    private var ivtcActive = false
    private var rateFactor = 1.0

    /** The state the engine's listener got last ([publishable]). */
    private var published: EngineState? = null

    /** The file the last load replaces, as it was then ([load]): what [keepOutgoing] makes current again. */
    private var outgoing: Outgoing? = null

    /** A new load's id, from any thread: [com.edde746.plezy.playback.PlayerEngine.load] returns it, [load] starts it. */
    fun nextLoadId(): Long = loadIds.addAndFetch(1L)

    /**
     * The load [id] ([nextLoadId]) went out: a new file, and every state from now on is that load's. Until mpv starts
     * its file ([startFile]) the track lists mpv reports are the replaced file's, and the load's tracks stay empty.
     */
    fun load(id: Long) {
        outgoing = Outgoing(state, open, startFilePending, frameShown, isFileLoaded, httpStatus, earlierHttpStatus, errorLine, videoTracks, cacheState)
        open = true
        startFilePending = true
        newFile(state.copy(loadId = id))
    }

    /**
     * mpv refused the last load ([load]) before it replaced the file: a value of the file or its `loadfile`, which the
     * engine reported as the load's error ([fail]) first. mpv plays on the file it had, so that file is current again
     * as the load found it: its load id, position and length, read-ahead, tracks and chapters, its first frame and
     * end, and its track lists count again. The player's settings and what the outputs report stay as mpv last said.
     */
    fun keepOutgoing() {
        val before = checkNotNull(outgoing) { "no load to take back" }
        outgoing = null
        open = before.open
        startFilePending = before.startFilePending
        frameShown = before.frameShown
        isFileLoaded = before.isFileLoaded
        httpStatus = before.httpStatus
        earlierHttpStatus = before.earlierHttpStatus
        errorLine = before.errorLine
        videoTracks = before.videoTracks
        cacheState = before.cacheState
        val file = before.state
        set(
            state.copy(
                loadId = file.loadId,
                positionSeconds = file.positionSeconds,
                durationSeconds = file.durationSeconds,
                cacheEndSeconds = file.cacheEndSeconds,
                cacheStartSeconds = file.cacheStartSeconds,
                tracks = file.tracks,
                chapters = file.chapters,
                eof = file.eof,
                error = file.error,
                playbackRestarts = file.playbackRestarts,
                stats = file.stats,
                httpErrorStatus = file.httpErrorStatus,
                transportFault = file.transportFault,
                fileSizeBytes = file.fileSizeBytes,
                fileFormat = file.fileFormat,
            ),
        )
    }

    /** mpv's `start-file`: the load's file starts, or a file its playlist names after a redirect. */
    fun startFile() {
        open = true
        startFilePending = false
        newFile(state)
    }

    /** mpv's `file-loaded`. */
    fun fileLoaded() {
        isFileLoaded = true
    }

    /**
     * mpv's `playback-restart`: a frame is up after the file's start or a seek; true for the file's first. One while a
     * load waits for its file to start is the replaced file's (a seek's), which says nothing of the new one.
     */
    fun playbackRestart(): Boolean {
        if (startFilePending) return false
        frameShown = true
        // A seek in place mpv ran too fast to report `seeking` for ends here.
        if (!seeking) seekingInPlace = false
        set(state.copy(playbackRestarts = state.playbackRestarts + 1))
        return state.playbackRestarts == 1
    }

    /**
     * mpv's `end-file` with its `reason` and `error` as client.h has them (`mpv_end_file_reason`, `mpv_error`), and
     * [message], mpv's text for [error]. An end while a load waits for its file to start is the replaced file's, and a
     * redirect goes on to the files it names (a playlist's entries), which mpv starts next: neither ends the load's
     * file. An error ends it as [EngineError]: the line the log named the failure with (else [message]), the HTTP
     * status FFmpeg logged and mpv's [error] as the kind ([MpvState.errorKind]); the file's end keeps it loaded. A stop
     * before `file-loaded` (a newer load, a stop, a release) is the app's own doing, not an error, but an open that
     * failed and was then abandoned ends just so: it logs a warning with the last error line.
     */
    fun endFile(reason: Int, error: Int, message: String) {
        if (startFilePending || reason == END_FILE_REASON_REDIRECT) return
        val abandoned = open && !isFileLoaded
        open = false
        isFileLoaded = false
        when (reason) {
            END_FILE_REASON_ERROR -> {
                frameShown = false
                val failure = EngineError(errorLine ?: message, httpStatus, MpvState.errorKind(error))
                Log.w(TAG) { "playback failed: $failure" }
                set(state.copy(error = failure))
            }
            END_FILE_REASON_EOF -> set(state.copy(eof = true))
            else -> {
                if (reason == END_FILE_REASON_STOP && abandoned) {
                    Log.w(TAG) { "the load stopped before file-loaded" + errorLine?.let { "; last error: $it" }.orEmpty() }
                }
                set(state)
            }
        }
    }

    /**
     * One of mpv's log lines, as mpv wrote it (URLs and all); [error] for an error or fatal one, [warning] for one at
     * warning level or worse (the engines ask mpv for those), [prefix] mpv's module prefix ("ffmpeg", "af", "cplayer";
     * empty from an engine that doesn't pass it). FFmpeg's HTTP status in it ("HTTP error 404 Not Found") and the last
     * error line, redacted ([Redactor]), name the current file's failure: mpv logs them before the end-file they explain,
     * and hands its client queued events first, so a status that comes after the file's error goes to that error. The
     * status is the stream's
     * ([EngineState.httpErrorStatus]) unless mpv then fails to open an external file (a subtitle's `sub-add`: "Can not
     * open external file <url>."), whose open logged it. A transport fault ([OpenFailureLog.isTransportFault]) latches
     * [EngineState.transportFault] for the file. Before the file's first frame, a line mpv gives a stream up on
     * ([OpenFailureLog.cause]) fails the file: mpv plays on with the other stream and never ends it.
     */
    fun logLine(text: String, error: Boolean, prefix: String = "", warning: Boolean = true) {
        MpvState.httpStatus(text)?.let { status ->
            earlierHttpStatus = httpStatus
            httpStatus = status
            val failure = state.error
            set(state.copy(httpErrorStatus = status, error = if (failure != null && failure.httpStatus == null) failure.copy(httpStatus = status) else failure))
        }
        if (text.startsWith(EXTERNAL_FILE_FAILED)) {
            httpStatus = earlierHttpStatus
            earlierHttpStatus = null
            set(state.copy(httpErrorStatus = httpStatus))
        }
        if (error && text.isNotBlank()) errorLine = Redactor.redact(text)
        if (!state.transportFault && OpenFailureLog.isTransportFault(warning, prefix, text)) set(state.copy(transportFault = true))
        if (open && !startFilePending && !frameShown && state.error == null) {
            when (OpenFailureLog.cause(error, prefix, text)) {
                OpenFailureCause.AUDIO_OUTPUT -> openFailed(text, EngineErrorKind.AUDIO_OUTPUT)
                OpenFailureCause.STREAM_INIT -> openFailed(text, EngineErrorKind.DECODE)
                null -> {}
            }
        }
    }

    private fun openFailed(line: String, kind: EngineErrorKind) {
        val failure = EngineError(Redactor.redact(line.trim()), httpStatus, kind)
        Log.w(TAG) { "the open failed on mpv's log: $failure" }
        set(state.copy(error = failure))
    }

    /** mpv reports [name], one of [DOUBLES], as [value]; a value that isn't finite is none ([unavailable]). */
    fun double(name: String, value: Double) = change(name, Format.DOUBLE, value.takeIf { it.isFinite() })

    /** mpv reports [name], one of [FLAGS], as [value]. */
    fun flag(name: String, value: Boolean) = change(name, Format.FLAG, value)

    /** mpv reports [name], one of [TEXTS] or [AUDIO_DEVICE_TEXTS], as [value]: a node property as its JSON. */
    fun text(name: String, value: String) = change(name, Format.TEXT, value)

    /** mpv reports [name] unavailable (`MPV_FORMAT_NONE`): no file, or none of it yet. */
    fun unavailable(name: String) = change(name, requireNotNull(FORMATS[name]) { "mpv's $name isn't a property the lifecycle maps" }, null)

    /**
     * The platform holds playback (mpv paused while the display switches mode, Apple's start gate): the state reports
     * buffering ([MpvState.buffering]) and [viewerPaused], the pause the viewer asked for, as [EngineState.paused];
     * called again as the viewer pauses or plays meanwhile.
     */
    fun hold(viewerPaused: Boolean) {
        heldPaused = viewerPaused
        set(state)
    }

    /**
     * The engine seeks to where it plays to drop what its output holds (a speed change on an audio output that keeps
     * seconds of audio at the old speed): the picture stays where it is, so mpv's `seeking` for it reports no
     * buffering ([MpvState.buffering]), until the seek ends. A wait for the cache meanwhile still does.
     */
    fun seekInPlace() {
        seekingInPlace = true
        set(state)
    }

    /** The hold ended with mpv's `pause` set to [paused]: reported at once, and mpv's own report confirms it. */
    fun endHold(paused: Boolean) {
        heldPaused = null
        mpvPaused = paused
        set(state)
    }

    /** What the display gets ([EngineState.outputDynamicRange]), as the platform's video output says. */
    fun outputRange(range: DynamicRange?) = set(state.copy(outputDynamicRange = range))

    /** How the system renders the audio ([EngineState.audioRendering]), as the platform says. */
    fun audioRendering(rendering: AudioRendering?) {
        if (rendering != state.audioRendering) set(state.copy(audioRendering = rendering))
    }

    /**
     * A playback info reading ([com.edde746.plezy.playback.PlayerEngine.setStatsWanted]); null as the info closes.
     * One while a load waits for its file to start is of the replaced file, and goes.
     */
    fun stats(reading: PlaybackStats?) {
        if (reading != null && startFilePending) return
        set(state.copy(stats = reading))
    }

    /** The file fails for a reason of the engine's own: mpv didn't start, refused the loadfile, a vo or decoder failed. */
    fun fail(error: EngineError) = set(state.copy(error = error))

    /**
     * [state] when it is due to go to the engine's listener, then the one published; null when it isn't. mpv reports
     * `time-pos` at every frame (24 a second for a film, twice that at 2x), and the controls, the media session and the
     * watch-together room need a few a second: a change of the position alone goes once it is [POSITION_STEP] seconds of
     * video from the one published, anything else at once.
     */
    fun publishable(): EngineState? {
        val last = published
        val next = state
        if (next == last) return null
        if (last != null && abs(next.positionSeconds - last.positionSeconds) < POSITION_STEP &&
            next.copy(positionSeconds = last.positionSeconds) == last
        ) {
            return null
        }
        published = next
        return next
    }

    /** The engine's listener changed: [publishable] gives it the state as it is. */
    fun republish() {
        published = null
    }

    private fun change(name: String, format: Format, value: Any?) {
        require(FORMATS[name] == format) { "mpv's $name isn't observed as $format" }
        val s = state
        set(
            when (name) {
                "time-pos" -> s.copy(positionSeconds = value as Double? ?: 0.0)
                "duration" -> (value as Double? ?: 0.0).let { duration ->
                    s.copy(durationSeconds = duration, cacheEndSeconds = cacheState?.let { MpvState.cacheEnd(it, duration) })
                }
                // The player's settings: mpv always has a value, and none would keep the last.
                "speed" -> (value as Double?)?.let { s.copy(speed = it) } ?: s
                "sub-delay" -> (value as Double?)?.let { s.copy(subtitleDelaySeconds = floatDecimal(it)) } ?: s
                "audio-delay" -> (value as Double?)?.let { s.copy(audioDelaySeconds = floatDecimal(it)) } ?: s
                "volume" -> (value as Double?)?.let { s.copy(volume = floatDecimal(it)) } ?: s
                "mute" -> (value as Boolean?)?.let { s.copy(muted = it) } ?: s
                "pause" -> s.also { mpvPaused = value as Boolean? ?: false }
                "paused-for-cache" -> s.also { pausedForCache = value as Boolean? ?: false }
                "seeking" -> s.also {
                    seeking = value as Boolean? ?: false
                    if (!seeking) seekingInPlace = false
                }
                "eof-reached" -> s.copy(eof = value as Boolean? ?: false)
                "seekable" -> s.copy(seekable = value as Boolean? ?: false)
                "container-fps" -> s.also { containerFps = (value as Double?)?.takeIf { it > 0 } }.withMedia()
                "estimated-vf-fps" -> s.also { estimatedFps = value as Double? }.withRateFactor()
                "deinterlace-active" -> s.also { deinterlaceActive = value as Boolean? ?: false }.withRateFactor()
                "ivtc-active" -> s.also { ivtcActive = value as Boolean? ?: false }.withRateFactor()
                "hwdec-current" -> s.copy(hwdec = value as String?)
                "file-format" -> s.copy(fileFormat = value as String?)
                "file-size" -> s.copy(fileSizeBytes = (value as Double?)?.toLong()?.takeIf { it > 0 })
                "audio-out-params/format" -> s.copy(audioPassthrough = MpvState.audioPassthrough(value as String?))
                "audio-device" -> s.copy(audioDevice = value as String? ?: "auto")
                // Until the load's file starts, mpv's track list is still the replaced file's.
                "track-list" -> if (startFilePending) s else node<JsonArray>(name, value) { list ->
                    trackList = list
                    videoTracks = list?.let { MpvState.videoTracks(it) }.orEmpty()
                    s.copy(tracks = list?.let { MpvState.tracks(it) }.orEmpty()).withMedia()
                }
                "video-params" -> node<JsonObject>(name, value) { params ->
                    videoParams = params
                    transfer = params?.let { MpvState.transfer(it) }
                    s.withMedia()
                }
                "audio-params" -> node<JsonObject>(name, value) { params ->
                    audioParams = params
                    s.withMedia()
                }
                "chapter-list" -> node<JsonArray>(name, value) { list -> s.copy(chapters = list?.let { MpvState.chapters(it) }.orEmpty()) }
                "demuxer-cache-state" -> node<JsonObject>(name, value) { cache ->
                    cacheState = cache
                    s.copy(
                        cacheStartSeconds = cache?.let { MpvState.cacheStart(it, s.positionSeconds) },
                        cacheEndSeconds = cache?.let { MpvState.cacheEnd(it, s.durationSeconds) },
                    )
                }
                "audio-device-list" -> node<JsonArray>(name, value) { list ->
                    s.copy(audioDevices = list?.let { MpvState.audioDevices(it) }.orEmpty())
                }
                else -> error("mpv's $name has no mapping")
            },
        )
    }

    /**
     * [read] of node property [name]'s JSON [text] (null while unavailable). Text that isn't the node mpv prints, which
     * would be a bug of ours (a property observed in another format), is logged and changes nothing.
     */
    private inline fun <reified T : JsonElement> node(name: String, text: Any?, read: (T?) -> EngineState): EngineState {
        if (text == null) return read(null)
        val node = MpvState.parse(text as String) as? T
        if (node == null) {
            Log.e(TAG) { "mpv's $name isn't the node mpv prints; the last one stays" }
            return state
        }
        return read(node)
    }

    private fun EngineState.withMedia(): EngineState {
        rateFactor = MpvState.presentedRateFactor(containerFps ?: selectedTrackFps(), estimatedFps, deinterlaceActive, ivtcActive)
        return copy(
            video = videoParams?.let { MpvState.videoInfo(it, trackList, containerFps, rateFactor, estimatedFps) },
            audio = audioParams?.let { MpvState.audioInfo(it, trackList) },
        )
    }

    /**
     * The video again when the presented rate's factor changed, or the rate rests on mpv's measured one alone (no
     * container or track rate: [MpvState.standardRate]) and that names another; the same state otherwise.
     */
    private fun EngineState.withRateFactor(): EngineState {
        val sourceFps = containerFps ?: selectedTrackFps()
        val factor = MpvState.presentedRateFactor(sourceFps, estimatedFps, deinterlaceActive, ivtcActive)
        val measuredOnly = sourceFps == null && video != null && video.fps != MpvState.standardRate(estimatedFps)
        return if (factor == rateFactor && !measuredOnly) this else withMedia()
    }

    private fun selectedTrackFps(): Double? = videoTracks.firstOrNull { it.selected }?.fps

    private fun newFile(from: EngineState) {
        frameShown = false
        isFileLoaded = false
        httpStatus = null
        earlierHttpStatus = null
        errorLine = null
        videoTracks = emptyList()
        cacheState = null
        seekingInPlace = false
        set(
            from.copy(
                positionSeconds = 0.0,
                durationSeconds = 0.0,
                cacheEndSeconds = null,
                cacheStartSeconds = null,
                tracks = emptyList(),
                chapters = emptyList(),
                eof = false,
                error = null,
                playbackRestarts = 0,
                stats = null,
                httpErrorStatus = null,
                transportFault = false,
                fileSizeBytes = null,
                fileFormat = null,
            ),
        )
    }

    /** [next] with what the lifecycle and the platform's hold decide: the pause reported, [EngineState.loaded], [EngineState.buffering]. */
    private fun set(next: EngineState) {
        state = next.copy(
            paused = heldPaused ?: mpvPaused,
            loaded = frameShown,
            buffering = MpvState.buffering(
                open = open,
                failed = next.error != null,
                eof = next.eof,
                firstFrameShown = frameShown,
                held = heldPaused != null,
                pausedForCache = pausedForCache,
                seeking = seeking && !seekingInPlace,
            ),
        )
    }

    private enum class Format { DOUBLE, FLAG, TEXT }

    /** A file as a load found it, with what the lifecycle knew of it ([keepOutgoing]). */
    private class Outgoing(
        val state: EngineState,
        val open: Boolean,
        val startFilePending: Boolean,
        val frameShown: Boolean,
        val isFileLoaded: Boolean,
        val httpStatus: Int?,
        val earlierHttpStatus: Int?,
        val errorLine: String?,
        val videoTracks: List<MpvState.VideoTrack>,
        val cacheState: JsonObject?,
    )

    companion object {
        /**
         * The properties every engine observes as doubles (`MPV_FORMAT_DOUBLE`), each read by [double]; the frame rates
         * make the presented one ([MpvState.presentedRateFactor]).
         */
        val DOUBLES: List<String> = listOf(
            "time-pos", "duration", "speed", "sub-delay", "audio-delay", "volume", "file-size", "container-fps", "estimated-vf-fps",
        )

        /**
         * The properties every engine observes as flags (`MPV_FORMAT_FLAG`), each read by [flag]; `ivtc-active` is
         * mpv-build's (inverse telecine), unavailable in an mpv without it.
         */
        val FLAGS: List<String> = listOf(
            "pause", "paused-for-cache", "seeking", "eof-reached", "mute", "seekable", "deinterlace-active", "ivtc-active",
        )

        /**
         * The properties every engine observes as text (`MPV_FORMAT_STRING`), each read by [text]: the node properties
         * among them as mpv's JSON of the node ([MpvState]).
         */
        val TEXTS: List<String> = listOf(
            "track-list", "video-params", "audio-params", "chapter-list", "demuxer-cache-state", "hwdec-current",
            // The format the audio output was opened with: a bitstream one while passthrough is in effect.
            "audio-out-params/format",
            // The stream's shape, which tells an early end of a sized file from a stream cut short.
            "file-format",
        )

        /**
         * The outputs mpv can play to and the one it plays to ([EngineState.audioDevices], [EngineState.audioDevice]), as
         * text: observed by the engines whose player picks the output (the desktop, macOS).
         */
        val AUDIO_DEVICE_TEXTS: List<String> = listOf("audio-device-list", "audio-device")

        /** How far the position moves, in seconds of video, before a change of it alone goes out ([publishable]). */
        const val POSITION_STEP = 0.25

        private const val TAG = "MpvLifecycle"

        // client.h's mpv_end_file_reason values.
        private const val END_FILE_REASON_EOF = 0
        private const val END_FILE_REASON_STOP = 2
        private const val END_FILE_REASON_ERROR = 4
        private const val END_FILE_REASON_REDIRECT = 5

        /** How mpv's log line starts when an external file (a subtitle's `sub-add`) failed to open. */
        private const val EXTERNAL_FILE_FAILED = "Can not open external file"

        private val FORMATS: Map<String, Format> = DOUBLES.associateWith { Format.DOUBLE } + FLAGS.associateWith { Format.FLAG } +
            (TEXTS + AUDIO_DEVICE_TEXTS).associateWith { Format.TEXT }

        /**
         * The decimal mpv's float option stands for: it keeps `sub-delay`, `audio-delay` and `volume` as floats, so -0.1
         * comes back as -0.10000000149011612. The fewest significant digits that are the same float, so a value that was
         * set comes back equal.
         */
        private fun floatDecimal(value: Double): Double {
            val float = value.toFloat()
            if (float == 0f) return 0.0
            val magnitude = floor(log10(abs(value))).toInt()
            for (digits in 1..9) {
                val exponent = digits - 1 - magnitude
                val rounded = if (exponent >= 0) round(value * 10.0.pow(exponent)) / 10.0.pow(exponent) else round(value / 10.0.pow(-exponent)) * 10.0.pow(-exponent)
                if (rounded.toFloat() == float) return rounded
            }
            return value
        }
    }
}

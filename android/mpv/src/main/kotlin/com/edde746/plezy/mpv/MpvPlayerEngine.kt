package com.edde746.plezy.mpv

import android.app.ActivityManager
import android.content.Context
import android.hardware.display.DisplayManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.view.Display
import android.view.Surface
import com.edde746.mpv.EndFileReason
import com.edde746.mpv.GlCapabilities
import com.edde746.mpv.GpuVoPolicy
import com.edde746.mpv.MediaCodecQuery
import com.edde746.mpv.MpvError
import com.edde746.mpv.MpvEvent
import com.edde746.mpv.MpvException
import com.edde746.mpv.MpvPlaceholderSurface
import com.edde746.mpv.MpvPlayer
import com.edde746.mpv.PropertyChange
import com.edde746.mpv.PropertyFormat
import com.edde746.mpv.VideoRectPolicy
import com.edde746.plezy.data.settings.DeviceSettings
import com.edde746.plezy.data.settings.DolbyVisionConversion
import com.edde746.plezy.log.Log.Level as AppLogLevel
import com.edde746.plezy.log.Redactor
import com.edde746.plezy.playback.ANDROID_LOUDNESS_NORMALIZATION_FILTER
import com.edde746.plezy.playback.AudioChannels
import com.edde746.plezy.playback.AudioState
import com.edde746.plezy.playback.AudioStateReconciler
import com.edde746.plezy.playback.COMMON_MPV_OPTIONS
import com.edde746.plezy.playback.DolbyVisionRoute
import com.edde746.plezy.playback.DolbyVisionStats
import com.edde746.plezy.playback.Downmix
import com.edde746.plezy.playback.DynamicRange
import com.edde746.plezy.playback.EngineError
import com.edde746.plezy.playback.EngineErrorKind
import com.edde746.plezy.playback.EngineFeatures
import com.edde746.plezy.playback.EngineState
import com.edde746.plezy.playback.LoadRequest
import com.edde746.plezy.playback.PlaybackOptions
import com.edde746.plezy.playback.PlayerEngine
import com.edde746.plezy.playback.PlayerEngineListener
import com.edde746.plezy.playback.STATS_INTERVAL_MS
import com.edde746.plezy.playback.SubtitleFrame
import com.edde746.plezy.playback.SubtitleStyle
import com.edde746.plezy.playback.TrackKind
import com.edde746.plezy.playback.VideoInfo
import com.edde746.plezy.playback.VideoLayout
import com.edde746.plezy.playback.mpv.DecoderOperatingRate
import com.edde746.plezy.playback.mpv.MpvAmbientLighting
import com.edde746.plezy.playback.mpv.MpvLifecycle
import com.edde746.plezy.playback.mpv.MpvLoad
import com.edde746.plezy.playback.mpv.MpvLog
import com.edde746.plezy.playback.mpv.MpvStartup
import com.edde746.plezy.playback.mpv.MpvState
import com.edde746.plezy.playback.mpv.MpvUserConfig
import com.edde746.plezy.playback.output.DecoderHold
import kotlinx.coroutines.CompletableDeferred
import java.io.File
import java.io.IOException
import java.util.Locale
import java.util.concurrent.CopyOnWriteArraySet
import java.util.concurrent.CountDownLatch
import java.util.concurrent.ExecutionException
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.FutureTask
import java.util.concurrent.RejectedExecutionException
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong

/**
 * [PlayerEngine] on libmpv for Android and Android TV.
 *
 * Output: `vo=mediacodec` puts MediaCodec buffers straight on the video plane (10-bit and the decoder's dataspace
 * intact, no GLES pass) and renders subtitles/OSD on a sibling OSD Surface. A per-file decode fallback moves the
 * session to `vo=gpu` ([GpuVoPolicy]), and so does software decoding by choice. [MpvVideoView] hosts both Surfaces; a
 * host without an OSD plane can drive [attachSurface]/[detachSurface] directly.
 *
 * Each file's `hwdec`, demuxer cache and stream options come with its [LoadRequest] ([PlaybackOptions], [MpvLoad]).
 * With the Read-ahead cache setting on Automatic, the demuxer cache is the device's heap class's ([DemuxerBudget]),
 * narrowed under memory pressure ([trimMemory]) and walked back once the memory is there again. A `content://` file (a
 * download in a folder the user picked) opens as a file descriptor (`fdclose://`). The session starts with the
 * settings' logging, volume and subtitle style ([MpvStartup], [SubtitleStyle]).
 *
 * The picture's [VideoLayout] is view geometry on the plane ([MpvVideoView], [VideoRectPolicy]) and mpv's properties
 * on a GL vo; both follow the host's shape. Audio stays with the platform's route: no devices to pick, passthrough
 * only while the audio is neither normalized, mixed down to stereo nor played at another speed than 1.
 *
 * Threading: every mpv call runs on this engine's serial executor, never on the Android main thread. The public
 * [PlayerEngine] calls may come from any thread. The surface calls are made from the main thread (SurfaceHolder
 * callbacks); [detachSurface] and [detachOsdSurface] block it until mpv has let go of the Surface, at most
 * [SURFACE_HANDOFF_TIMEOUT_MS]. After [release] that is the teardown's first step, which moves mpv to the placeholder
 * before terminating it: the termination itself can take seconds and holds no host Surface.
 * mpv's callbacks come in mpv's order on the library's delivery thread for the session (`mpv-listener-<session>`),
 * which only publishes state and queues work on the executor. [PlayerEngineListener.onState] fires on that thread or
 * the executor.
 *
 * @param extraOptions more mpv options applied last, before `mpv_initialize` (test runs pass `ao=null`); they also win
 *   over a [LoadRequest]'s options of the same name.
 * @param events told `load` as [load] is entered, `loadfile` once a file's loadfile command is issued, `playing` at a
 *   load's first playback restart (its first frame) and `terminate` as a released engine starts terminating mpv, its
 *   host's Surfaces already let go: a debug launch's perf marks and the device tests. Called on the caller's thread,
 *   the engine's executor and the library's delivery thread.
 * @param settings this device's settings as the playback starts: Dolby Vision, HDR, logging, volume, the read-ahead
 *   cache and the subtitles' look and render resolution.
 * @param tv the device is a TV box: the subtitle plane's timing depends on it ([OsdPlanePolicy.socOptions]).
 */
class MpvPlayerEngine(
    context: Context,
    private val extraOptions: Map<String, String> = emptyMap(),
    private val events: ((String) -> Unit)? = null,
    private val settings: DeviceSettings = DeviceSettings.DEFAULT,
    private val tv: Boolean = false,
) : PlayerEngine {
    companion object {
        private const val TAG = "MpvPlayerEngine"

        /**
         * How long a surface destruction may hold the Android main thread for mpv to let go of the surface. A budget
         * for the main looper, never a verdict on the core: an unacknowledged handoff stays queued.
         */
        const val SURFACE_HANDOFF_TIMEOUT_MS = 2_000L

        /** Plane first; gpu stays in the chain for preinit failure. */
        private const val VIDEO_OUTPUT = "mediacodec,gpu"

        /** The GL vo's reason while ambient lighting is on: the plane runs no user shaders. */
        private const val REASON_AMBIENT_LIGHTING = "ambient-lighting"

        /** mpv's accepted `speed` range. */
        private const val MIN_SPEED = 0.01
        private const val MAX_SPEED = 100.0

        /** How often a loaded file is looked at for a stalled decoder ([checkDecodeStall]). */
        private const val STALL_SAMPLE_MS = 1_000L

        /** The vote's API level: `Surface.setFrameRate` came with Android 11 ([SurfaceFrameRateVote]). */
        private const val FRAME_RATE_VOTE_MIN_SDK = Build.VERSION_CODES.R

        /**
         * Paces every engine's stats readings ([setStatsWanted]) and decode stall checks ([watchDecodeStall]). A tick
         * only queues the work on its engine's executor, so one daemon thread serves them all.
         */
        private val statsClock: ScheduledExecutorService by lazy {
            Executors.newSingleThreadScheduledExecutor { Thread(it, "mpv-stats-clock").apply { isDaemon = true } }
        }

        /**
         * mpv's decoder thread and frame queue for hardware sessions: a MediaCodec decoder is a pipeline with a
         * declared output delay (12 frames on Tensor AV1), which mpv's on-demand decode otherwise shows late.
         */
        private val DECODER_QUEUE_OPTIONS = listOf(
            "vd-queue-enable" to "yes",
            "vd-queue-max-samples" to "12",
            "vd-queue-max-secs" to "0.5",
            "vd-queue-max-bytes" to "48MiB",
        )

        /**
         * The codecs mpv may decode in hardware: every MediaCodec video decoder FFmpeg wraps but mpeg4, whose Xvid and
         * DivX keep software decoding. mpv's default list leaves MPEG-2 out, which sent broadcast HD and DVD remuxes to
         * software decoding on the GL vo; a device without an MPEG-2 decoder still falls back to software.
         */
        private const val HWDEC_CODECS = "h264,hevc,mpeg2video,vp8,vp9,av1"

        /**
         * What this engine observes besides [MpvLifecycle]'s properties, for the plane's routing, its geometry and the
         * log.
         */
        private val OBSERVED = listOf(
            "current-vo" to PropertyFormat.String,
            "dwidth" to PropertyFormat.Int64,
            "dheight" to PropertyFormat.Int64,
            // A GL vo's render target: what the display gets from it (EngineState.outputDynamicRange).
            "video-target-params" to PropertyFormat.String,
            "osd-dimensions" to PropertyFormat.String,
            // mpv-build's: vo_mediacodec cannot show the decoded frames and the video chain waits for a vo switch.
            "vo-format-rejected" to PropertyFormat.Flag,
        )

        /**
         * The subtitle fonts in the APK's assets: Go Noto Current (every living script but Hangul, CJK ideographs
         * included; satbyy/go-noto-universal v7.0, SIL OFL 1.1) and the Hangul companion of it, which carries
         * the same family name ([SUBTITLE_FONT_FAMILY]).
         */
        private const val SUBTITLE_FONT_ASSETS = "subtitle-fonts"
        private const val SUBTITLE_FONT_FAMILY = "Go Noto Current-Regular"

        private val ids = AtomicInteger()

        /**
         * The bundled FFmpeg's MediaCodec decoder options: the Java MediaCodec wrapper (`ndk_codec=0`, the only one
         * that reads crop rectangles below API 28), asynchronous where the platform is trusted to be (API 31+,
         * Media3's threshold), realtime priority, and per file the Dolby Vision decoder routing ([dv]; FFmpeg's own
         * defaults until the first file decides).
         */
        private fun decoderOptions(sdkInt: Int, dv: GpuVoPolicy.DvDecoderOptions? = null): String = buildList {
            add("ndk_codec=0")
            if (sdkInt >= Build.VERSION_CODES.S) add("async=1")
            add("priority=0")
            if (dv != null) {
                add("dolby_vision=${if (dv.dolbyVision) 1 else 0}")
                add("dv_p7_mode=${dv.p7Mode}")
            }
        }.joinToString(",")

        /** The engines not released yet, which the app's memory pressure reaches ([trimMemory]). */
        private val live = CopyOnWriteArraySet<MpvPlayerEngine>()

        /**
         * Android's memory pressure (`ComponentCallbacks2.onTrimMemory`'s level; `onLowMemory` as
         * `TRIM_MEMORY_RUNNING_LOW`), from the application: every live engine narrows its demuxer cache
         * ([DemuxerBudget.forTrimLevel]). Any thread.
         */
        fun trimMemory(level: Int) {
            for (engine in live) engine.onTrimMemory(level)
        }

        private const val MIB = 1024L * 1024
        private const val CONTENT_SCHEME = "content://"

        /**
         * The longest a file's decoder waits at `on_preloaded` for the display ([holdDecoder]): the output's own wait
         * (a switch's settle, the longest display switch delay and a display that never lands: 16 s) and some to spare.
         */
        private const val DECODER_HOLD_TIMEOUT_MS = 20_000L

        private fun yesNo(value: Boolean) = if (value) "yes" else "no"
    }

    private val appContext = context.applicationContext
    private val executor: ExecutorService = Executors.newSingleThreadExecutor { Thread(it, "mpv-engine-${ids.incrementAndGet()}") }
    private val released = AtomicBoolean()

    /** The output's hold on the next file's video decoder ([holdDecoder]). */
    private val decoderHolds = DecoderHoldGate()
    private val decoderHoldTokens = AtomicLong()

    /**
     * What the decoder makes of Dolby Vision Profile 7 ([GpuVoPolicy.DV_CONVERSION_MODES]), whether Dolby Vision goes
     * to a display that takes it (false plays its HDR10 or HLG base layer, [GpuVoPolicy.dvRouting]) and who converts HDR
     * for a display that doesn't take its format ([GpuVoPolicy.HDR_SDR_CONVERSION_MODES], [GpuVoPolicy.needsToneMapping]).
     */
    @Volatile private var dvConversionMode = settings.dvConversionMode.wire
    private val dolbyVisionOutput = !settings.disableDolbyVision
    private val hdrSdrConversion = settings.hdrSdrConversion.wire

    /** The user's mpv.conf ([MpvUserConfig]): set after the engine's own options; a line wins over its later writes. */
    private val userConfig = MpvUserConfig.of(settings.mpvConfigText, linuxPlane = false)

    /** mpv's `volume-max`: the most [setVolume] asks for; a mpv.conf line's where it sets one. */
    private val volumeMax = userConfig["volume-max"]?.toDoubleOrNull() ?: MpvStartup.volumeMax(settings)

    /** An app write after mpv started: skipped where a line of the user's mpv.conf sets [name] ([MpvUserConfig.appWrites]). */
    private fun MpvPlayer.setAppProperty(name: String, value: String) {
        if (userConfig.appWrites(name)) setProperty(name, value)
    }

    /** The OSD plane's share of its view's size, the Subtitle render resolution setting ([MpvVideoView]). */
    internal val osdRenderScale: Double = settings.subtitleRenderResolution.androidRenderScale

    /** The device's heap class in MB (`ActivityManager.getLargeMemoryClass`), 0 where unknown. */
    private val heapClassMB = appContext.getSystemService(ActivityManager::class.java)?.largeMemoryClass ?: 0

    /**
     * The demuxer cache the session comes back to ([DemuxerBudget.forHeapClassMB], with the Read-ahead cache setting
     * on Automatic; null keeps each file's own) and the one it holds now, narrowed under memory pressure; executor.
     */
    private val steadyBudget = if (settings.cacheSizeMegabytes == null) DemuxerBudget.forHeapClassMB(heapClassMB) else null
    private var appliedBudget = steadyBudget
    private var lastNarrowAtMs = 0L

    /** The walk back to [steadyBudget] while the budget is narrowed ([scheduleBudgetRestore]); executor. */
    private var budgetRestore: ScheduledFuture<*>? = null

    private val contentFds = AndroidContentFds(appContext)

    /** The first file decided the GL vo's surface colorspace for the session ([decideHdrSurface]); executor. */
    private var hdrSurfaceDecided = false

    private val diagnostics = PlaybackDiagnostics(appContext, PlaybackDiagnostics.PLAYER_MPV)

    /**
     * Open once a released engine's mpv holds none of its host's Surfaces: the teardown moved it to the placeholder, or
     * mpv is gone.
     */
    private val hostSurfacesReleased = CountDownLatch(1)

    // Published by the main thread, read on the executor.
    @Volatile private var videoSurface: Surface? = null
    @Volatile private var videoGeneration = 0L
    @Volatile private var osdSurface: Surface? = null
    @Volatile private var osdGeneration = 0L
    @Volatile private var surfaceSize: String? = null
    @Volatile private var surfaceAspect: Double? = null
    @Volatile private var viewportAspect: Double? = null
    @Volatile private var videoRect: String? = null
    @Volatile private var host: MpvVideoView? = null

    /** The latest layout, from any thread; the host lays the plane out by it. */
    @Volatile private var videoLayout = VideoLayout.DEFAULT

    // Published by the delivery thread / executor for a (re)binding host.
    @Volatile private var videoWidth = 0
    @Volatile private var videoHeight = 0
    @Volatile private var gpuVoActive = false
    @Volatile private var surfaceHints = SurfaceHints.NONE

    /** The seamless frame-rate vote on the real video Surface; guarded by stateLock, like the state it follows. */
    private val frameRateVote = SurfaceFrameRateVote(::setSurfaceFrameRate)

    /** The current file is live ([LoadRequest.live]): a decoder refresh may find its position gone from the cache. */
    private var liveFile = false

    // Confined to the executor.
    private var player: MpvPlayer? = null

    /** Ambient lighting on [player] (executor). */
    private val ambientLighting = MpvAmbientLighting(
        set = { name, value -> mpvCall(name) { it.setProperty(name, value) } },
        command = { args -> mpvCall(args.joinToString(" ")) { it.command(*args.toTypedArray()) } },
    )

    /** [call] on [player], false when there's none or mpv refuses it (logged). */
    private inline fun mpvCall(what: String, call: (MpvPlayer) -> Unit): Boolean {
        val p = player ?: return false
        return try {
            call(p)
            true
        } catch (e: MpvException) {
            Log.w(TAG, "mpv $what failed", e)
            false
        }
    }

    /** Why mpv didn't start ([initialize]): with no mpv to play, each [load] fails with it. */
    private var initFailure: EngineError? = null
    private var placeholder: MpvPlaceholderSurface? = null

    /** mpv's `display-fps-override`: the default display's refresh rate as last set ([followDisplayRate]). */
    private var appliedDisplayFps: Float? = null
    private var attachedVideo: Surface? = null
    private var attachedVideoGeneration = -1L
    private var attachedOsd: Surface? = null
    private var attachedOsdGeneration = -1L
    private var appliedSurfaceSize: String? = null
    private var appliedVideoRect: String? = null
    private var pausedForSurfaceLoss = false
    private var videoOutputFailed = false
    private val gpuVoReasons = LinkedHashSet<String>()
    private var appliedGpuVo: String? = null

    /** The layout's mpv properties as last written, and whether that layout runs past the surface. */
    private val appliedLayout = HashMap<String, String>()
    private var layoutOverflows = false

    /** The route's passthrough formats as last reported ([setAudioPassthrough]), for `audio-spdif`. */
    private var passthroughCodecs = emptyList<String>()

    /**
     * The audio options and the speed, applied in an order that never hands a bitstream to the filter, a fold or
     * another speed (executor). Android never claims the device: the audiotrack output ignores `audio-exclusive`, and
     * each write of it reopens the audio output.
     */
    private val audio = AudioStateReconciler(
        normalizationFilter = ANDROID_LOUDNESS_NORMALIZATION_FILTER,
        exclusiveHint = false,
        codecs = { passthroughCodecs.joinToString(",") },
        warn = { message, e -> Log.w(TAG, "mpv $message", e) },
    ) { name, value ->
        checkNotNull(player).setProperty(name, value)
        if (name != "speed") Log.i(TAG, "$name=${value.ifEmpty { "(none)" }}")
    }

    /**
     * The current file's video rate (`demux-fps`) and its hardware decoder's advertised maximum at its size, set in
     * `on_preloaded`: with the speed, the operating rate the decoder is told ([DecoderOperatingRate]).
     */
    private var decoderContentFps: Double? = null
    private var decoderMaxFps: Int? = null

    /**
     * The latest subtitle style (the settings' until the player sets one), the controls' lift and the picture's frame
     * in the subtitle plane (`osd-dimensions`), which `sub-pos` combines ([applySubtitlePosition]).
     */
    private var subtitleStyle = SubtitleStyle.of(settings.subtitles)
    private var controlsLift = 0.0
    private var subtitleFrame = SubtitleFrame.SCREEN

    /** mpv option -> the default it had before the cheap render tier replaced it; empty while the tier is off. */
    private val cheapRenderRestore = LinkedHashMap<String, String>()
    private var cheapRenderTierActive = false

    /** Per-file reasons holding `hwdec` at `no`; the session's own value is parked meanwhile. */
    private val hwdecHoldReasons = LinkedHashSet<String>()
    private var parkedHwdec: String? = null

    /** The `hwdec` the file loaded last asked for (the session's own value). */
    private var requestedHwdec: String? = null

    /** `dolby-vision-profile` of the current file's video track, set in `on_preloaded`; read on the delivery thread. */
    @Volatile private var pendingDoviProfile: Int? = null

    // Guarded by stateLock. onState runs under it, so listeners see states in order.
    private val stateLock = Any()
    private var listener: PlayerEngineListener? = null

    /**
     * Each file's lifecycle and the state mpv's properties make ([MpvLifecycle]). Its hold ([MpvLifecycle.hold]) is the
     * output's while the display switches mode ([holdForDisplay]): mpv is paused and the state reports buffering, its
     * `paused` the pause the viewer asked for, which the release leaves.
     */
    private val lifecycle = MpvLifecycle()

    /**
     * Where the picture goes ([MpvState.androidOutputRange]): the video plane or a GL vo, the display's HDR formats,
     * a Dolby Vision decoder, the compositor's SDR headroom.
     */
    private data class PictureOutput(
        val videoPlane: Boolean,
        val displayHdr: Set<DynamicRange>,
        val dolbyVisionDecoder: Boolean,
        val sdrHeadroom: Boolean,
    )

    /**
     * The last `video-target-params` and where the picture goes ([refreshPictureOutput]; null until the first refresh):
     * with the frames' transfer ([MpvLifecycle.transfer]), what [EngineState.outputDynamicRange] is made of.
     */
    private var targetParams: String? = null
    private var pictureOutput: PictureOutput? = null

    /** `video-params` reported an HDR transfer since the current file started ([GpuVoPolicy.hardwareDroppedHdr]). */
    private var hdrTransferSeen = false

    /** A load waiting for the bound host's first video Surface; executor-confined. */
    private var pendingLoad: LoadRequest? = null

    /**
     * The current file decodes on a Dolby Vision decoder ([applyDvRouting]), which hands the video plane a Dolby
     * Vision picture; executor-confined.
     */
    private var dolbyVisionDecoder = false

    /** The [statsClock] tick while the playback info shows ([setStatsWanted]); written on the executor. */
    @Volatile private var statsTick: ScheduledFuture<*>? = null

    /** A stats reading waits on the executor: a busy executor gets one, not a backlog. */
    private val statsReadQueued = AtomicBoolean()

    /** The [statsClock] tick while a file is loaded ([watchDecodeStall]); written on the executor. */
    @Volatile private var stallTick: ScheduledFuture<*>? = null

    /** A stall check waits on the executor: a busy executor gets one, not a backlog. */
    private val stallCheckQueued = AtomicBoolean()

    /** The last look [checkDecodeStall] took, and since when (`System.nanoTime`) it has been the same; executor-only. */
    private var stallSample: GpuVoPolicy.DecodeSample? = null
    private var stallSampleSince = 0L

    // PlayerEngine

    /**
     * With a host bound ([MpvVideoView]) and no video Surface from it yet, the file opens once that Surface is
     * attached: opening on the placeholder would make the fork vo repoint a decoder mid-initialization.
     */
    override fun load(request: LoadRequest): Long {
        events?.invoke("load")
        val id = lifecycle.nextLoadId()
        submit("load") {
            diagnostics.opened()
            publish {
                load(id)
                initFailure?.let { fail(it) }
            }
            if (host != null && !onRealSurface()) {
                pendingLoad = request
                return@submit
            }
            pendingLoad = null
            loadFile(request)
        }
        return id
    }

    /**
     * The file's values as mpv's properties ([MpvLoad]; the stream ring within the heap class's cap,
     * [DemuxerBudget.streamRingCapBytes]), then a plain loadfile: the files mpv opens from this one's playlist keep
     * them. A `content://` document opens as a descriptor mpv takes over (`fdclose://`): mpv can't open the URI. A
     * value ([MpvLoad.refusalFailsLoad]), header list or loadfile mpv refuses, or a document that doesn't open, refuses
     * the load: it fails with the reason, then the file mpv plays on is current again ([MpvLifecycle.keepOutgoing]). A
     * refused playback default is only logged.
     */
    private fun loadFile(request: LoadRequest) {
        val p = player ?: return
        val fd = if (request.url.startsWith(CONTENT_SCHEME)) {
            try {
                contentFds.open(request.url)
            } catch (e: Exception) {
                Log.w(TAG, "Opening ${Redactor.redact(request.url)} failed", e)
                publish { fail(EngineError("The file can't be opened: ${e.message}", kind = EngineErrorKind.OPEN)) }
                publish { keepOutgoing() }
                return
            }
        } else {
            null
        }
        try {
            applyFileOptions(p, request.options, request.live)
            decideHdrSurface(p, request)
            p.setProperty("http-header-fields", MpvLoad.headerFields(request.headers))
            val fileProperties = MpvLoad.fileProperties(request, DemuxerBudget.streamRingCapBytes(heapClassMB), MpvLoad.ANDROID_UNCACHED_ROOTS, cacheForced = userConfig["cache"] == "yes")
            for ((name, value) in fileProperties) {
                if (MpvLoad.refusalFailsLoad(name)) p.setAppProperty(name, value) else mpvCall(name) { it.setAppProperty(name, value) }
            }
            p.command("loadfile", if (fd != null) "fdclose://$fd" else request.url, "replace")
        } catch (e: Exception) {
            // mpv never took the descriptor.
            fd?.let(contentFds::close)
            // mpv-build's MpvException carries no error code to tell the kind by.
            publish { fail(EngineError(e.message ?: "loadfile failed")) }
            publish { keepOutgoing() }
            return
        }
        liveFile = request.live
        events?.invoke("loadfile")
    }

    /**
     * The file's decoding and cache options ([MpvLoad.decodingOptions]), written before its loadfile and each only when
     * it changes: a `hwdec` write re-creates the playing file's decoder. The demuxer cache is the session's budget
     * where it has one ([appliedBudget]). An [extraOptions] entry of the same name wins. While a per-file hold keeps
     * `hwdec` at `no`, the file's value is parked for the hold to give back.
     */
    private fun applyFileOptions(p: MpvPlayer, options: PlaybackOptions, live: Boolean) {
        val hwdec = extraOptions["hwdec"] ?: userConfig["hwdec"] ?: options.hwdec
        requestedHwdec = hwdec
        val budget = appliedBudget
        val decoding = MpvLoad.decodingOptions(options, live) + if (budget != null) budgetOptions(budget) else emptyMap()
        for ((name, value) in decoding) {
            when {
                name in extraOptions -> Unit
                name == "hwdec" && parkedHwdec != null -> parkedHwdec = value
                p.getString(name) != value -> p.setAppProperty(name, value)
            }
        }
        Log.i(TAG, "File options: hwdec=$hwdec demuxer-max-bytes=${decoding["demuxer-max-bytes"]} demuxer-max-back-bytes=${decoding["demuxer-max-back-bytes"]} deinterlace=${decoding["deinterlace"]}")
    }

    private fun budgetOptions(budget: DemuxerBudget) = mapOf(
        "demuxer-max-bytes" to budget.aheadBytes.toString(),
        "demuxer-max-back-bytes" to budget.backBytes.toString(),
    )

    /**
     * Narrows the demuxer cache for memory pressure at [level] ([DemuxerBudget.forTrimLevel]; read-ahead in seconds of
     * the playing stream, [DemuxerBudget.streamByteRate]) and starts the walk back ([scheduleBudgetRestore]). mpv frees
     * what the smaller bounds leave over at once. Only narrows; a session with the setting's own cache keeps it.
     */
    private fun onTrimMemory(level: Int) {
        submit("memory trim") {
            val p = player ?: return@submit
            val current = appliedBudget ?: return@submit
            val rate = DemuxerBudget.streamByteRate(
                cachedBytes = p.getString("demuxer-cache-state/fw-bytes")?.toLongOrNull() ?: 0L,
                cachedSeconds = p.getDouble("demuxer-cache-duration") ?: 0.0,
                fileBytes = p.getString("file-size")?.toLongOrNull() ?: 0L,
                fileSeconds = p.getDouble("duration") ?: 0.0,
            )
            val wanted = DemuxerBudget.forTrimLevel(heapClassMB, level, rate) ?: return@submit
            val next = current.narrowedTo(wanted)
            if (next == current) return@submit
            writeBudget(p, next, "trim level $level (stream ${rate / 1000} kB/s)")
            lastNarrowAtMs = SystemClock.elapsedRealtime()
            scheduleBudgetRestore()
        }
    }

    /**
     * Walks the budget back toward [steadyBudget] a rung per [DemuxerBudget.RESTORE_POLL_MS], each step only once
     * [DemuxerBudget.RESTORE_QUIET_MS] passed since the last narrowing and the memory allows it ([DemuxerBudget.canWiden]);
     * ends at the steady budget.
     */
    private fun scheduleBudgetRestore() {
        if (budgetRestore != null) return
        budgetRestore = statsClock.scheduleWithFixedDelay({
            submit("demuxer budget restore") { restoreBudgetStep() }
        }, DemuxerBudget.RESTORE_POLL_MS, DemuxerBudget.RESTORE_POLL_MS, TimeUnit.MILLISECONDS)
    }

    private fun restoreBudgetStep() {
        val p = player ?: return
        val current = appliedBudget ?: return
        val steady = steadyBudget ?: return
        val next = current.widenedToward(steady)
        if (next == null) {
            budgetRestore?.cancel(false)
            budgetRestore = null
            return
        }
        if (SystemClock.elapsedRealtime() - lastNarrowAtMs < DemuxerBudget.RESTORE_QUIET_MS) return
        val memory = ActivityManager.MemoryInfo()
        appContext.getSystemService(ActivityManager::class.java)?.getMemoryInfo(memory) ?: return
        if (!current.canWiden(next, memory.availMem, memory.threshold, memory.lowMemory)) return
        writeBudget(p, next, "memory recovered (${memory.availMem / MIB} MB free, threshold ${memory.threshold / MIB} MB)")
    }

    private fun writeBudget(p: MpvPlayer, budget: DemuxerBudget, why: String) {
        appliedBudget = budget
        for ((name, value) in budgetOptions(budget)) {
            if (name !in extraOptions) p.setProperty(name, value)
        }
        Log.i(TAG, "Demuxer budget ${budget.aheadBytes / MIB} MB ahead, ${budget.backBytes / MIB} MB back: $why")
    }

    private fun onRealSurface(): Boolean = attachedVideo != null && attachedVideo !== placeholder?.surface

    override fun setPaused(paused: Boolean) {
        submit("pause") {
            // An explicit choice wins over the automatic resume after a surface loss.
            pausedForSurfaceLoss = false
            // Held for a display switch: the choice is the release's to apply.
            if (synchronized(stateLock) { lifecycle.held }) {
                publish { hold(paused) }
            } else {
                player?.setProperty("pause", paused)
            }
        }
    }

    /**
     * Holds the video decoder of the next file [load] opens at `on_preloaded`, once the demuxer has read the file and
     * before any decoder exists, so the display can switch for it first ([DecoderHold]). Any thread; arm it right
     * before the load. The hold answers the file's video as its container declares it (`demux-fps`, its size), or null
     * when nothing was held; the decoder opens on [DecoderHold.release], at the latest [DECODER_HOLD_TIMEOUT_MS] later.
     */
    fun holdDecoder(): DecoderHold {
        val token = decoderHoldTokens.incrementAndGet()
        val declared = CompletableDeferred<VideoInfo?>()
        decoderHolds.arm(token) { declared.complete(it) }
        return object : DecoderHold {
            override suspend fun video(): VideoInfo? = declared.await()

            override fun release() = decoderHolds.release(token)
        }
    }

    /**
     * Keeps the hook [id] of [p]'s file (its `on_preloaded`) waiting until [hold] is released or
     * [DECODER_HOLD_TIMEOUT_MS] passed, then lets mpv go on, on the executor (before a teardown queued after it).
     */
    private fun continueAfterRelease(p: MpvPlayer, id: Long, hold: DecoderHoldGate.Hold, track: MpvState.VideoTrack) {
        val started = System.nanoTime()
        val done = AtomicBoolean()
        lateinit var timeout: ScheduledFuture<*>
        fun goOn(released: Boolean) {
            if (!done.compareAndSet(false, true)) return
            timeout.cancel(false)
            decoderHolds.finish(hold)
            val heldMs = (System.nanoTime() - started) / 1_000_000
            Log.i(TAG, if (released) "Video decoder held $heldMs ms for the display (${track.fps} fps, ${track.width}x${track.height})" else "Display not ready after $heldMs ms; opening the video decoder")
            // Once the engine is released its teardown destroys mpv, the waiting hook with it.
            submit("decoder hold end") { p.continueHook(id) }
        }
        timeout = statsClock.schedule({ goOn(released = false) }, DECODER_HOLD_TIMEOUT_MS, TimeUnit.MILLISECONDS)
        hold.released.invokeOnCompletion { goOn(released = true) }
    }

    /**
     * Holds playback while the display switches mode ([held]), so the picture doesn't go blank under the sound: the
     * output host's call, from any thread. mpv pauses and the state reports buffering, with [EngineState.paused] the
     * viewer's own; a pause or play asked for meanwhile ([setPaused]) is what the release leaves. Released, playback
     * goes on unless the viewer paused (once the video Surface is back, if it went meanwhile).
     */
    fun holdForDisplay(held: Boolean) {
        submit("display hold") {
            val p = player ?: return@submit
            if (held == synchronized(stateLock) { lifecycle.held }) return@submit
            if (held) {
                // A pause for a lost Surface is the engine's, not the viewer's: the release resumes it.
                val paused = p.getFlag("pause") == true && !pausedForSurfaceLoss
                pausedForSurfaceLoss = false
                publish { hold(paused) }
                p.setProperty("pause", true)
                Log.i(TAG, "Display hold: paused at ${p.getString("time-pos")} s while the display switches${if (paused) " (the viewer's pause kept)" else ""}")
            } else {
                // While held, the state's pause is the viewer's.
                val paused = synchronized(stateLock) { lifecycle.state.paused }
                publish { endHold(paused) }
                when {
                    paused -> Unit
                    onRealSurface() -> p.setProperty("pause", false)
                    else -> pausedForSurfaceLoss = true
                }
                Log.i(TAG, "Display hold released at ${p.getString("time-pos")} s: ${if (paused) "stays paused" else "plays"}")
            }
        }
    }

    /**
     * Starts the hardware decoder over against the display's new mode, before a hold for the switch is released
     * ([holdForDisplay]): a seek to where playback is, which resets the decoder as `drop-buffers` does but keeps what
     * is read ahead (on a live stream, where the cache still holds the position). A live position gone from the cache
     * drops the buffers instead, so playback goes on from what the stream sends next.
     */
    fun refreshDecoder() {
        submit("decoder refresh") {
            val p = player ?: return@submit
            val state = synchronized(stateLock) { lifecycle.state }
            if (!state.loaded) return@submit
            val position = state.positionSeconds
            val start = state.cacheStartSeconds
            val end = state.cacheEndSeconds
            if (!liveFile || (start != null && end != null && position in start..end)) {
                p.command("seek", String.format(Locale.ROOT, "%.3f", position), "absolute+exact")
                Log.i(TAG, "Decoder refreshed after the display switch: seek to $position s")
            } else {
                p.command("drop-buffers")
                Log.i(TAG, "Decoder refreshed after the display switch: $position s no longer cached, buffers dropped")
            }
        }
    }

    override fun seek(seconds: Double, exact: Boolean) {
        submit("seek") {
            player?.command("seek", String.format(Locale.ROOT, "%.3f", seconds), if (exact) "absolute+exact" else "absolute+keyframes")
        }
    }

    /** Passthrough leaves before any speed but 1 and comes back after 1 ([audio]). */
    override fun setSpeed(speed: Double) {
        if (!speed.isFinite()) return
        submit("speed") {
            val p = player ?: return@submit
            audio.reconcile(audio.requestRate(speed.coerceIn(MIN_SPEED, MAX_SPEED)))
            applyOperatingRate(p)
        }
    }

    override fun setSubtitleDelay(seconds: Double) {
        if (!seconds.isFinite()) return
        submit("subtitle delay") {
            player?.setProperty("sub-delay", seconds)
            player?.setProperty("secondary-sub-delay", seconds)
        }
    }

    override fun setAudioDelay(seconds: Double) {
        if (!seconds.isFinite()) return
        submit("audio delay") { player?.setProperty("audio-delay", seconds) }
    }

    override fun setSubtitleLift(fraction: Double) {
        if (!fraction.isFinite()) return
        submit("subtitle lift") {
            controlsLift = fraction
            applySubtitlePosition()
        }
    }

    /** The style's properties, its margins ([applyVideoLayout]) and position; a property mpv refuses is logged and skipped. */
    override fun setSubtitleStyle(style: SubtitleStyle) {
        submit("subtitle style") {
            subtitleStyle = style
            val p = player ?: return@submit
            for ((name, value) in style.properties()) {
                try {
                    p.setAppProperty(name, value)
                } catch (e: MpvException) {
                    Log.w(TAG, "mpv $name=$value failed", e)
                }
            }
            applyVideoLayout()
            applySubtitlePosition()
        }
    }

    /** Text subtitles may use the margins: the style asks for it, or the picture runs past the surface. */
    private fun subtitleMargins() = subtitleStyle.useMargins || layoutOverflows

    /** `sub-pos` for the latest style and controls, in the screen with margins and in the picture without (executor). */
    private fun applySubtitlePosition() {
        val frame = if (subtitleMargins()) SubtitleFrame.SCREEN else subtitleFrame
        player?.setAppProperty("sub-pos", subtitleStyle.position(controlsLift, frame).toString())
    }

    override fun setVideoLayout(layout: VideoLayout) {
        videoLayout = layout
        host?.onVideoLayout(layout)
        submit("video layout") { applyVideoLayout() }
    }

    /**
     * The layout's mpv properties for the host's shape ([VideoLayout.properties]), each written when it changes. On the
     * plane the host sizes the picture and these place the subtitles and OSD to match (the aspect override gives a
     * stretch its display size, `dwidth`×`dheight`); a GL vo lays the picture out by them. Text subtitles go by the
     * picture, or by the surface (`sub-use-margins`) where the style asks for it or the picture runs past the surface,
     * so they stay on screen.
     */
    private fun applyVideoLayout() {
        val p = player ?: return
        val layout = videoLayout
        val properties = layout.properties(viewportAspect ?: surfaceAspect) +
            ("sub-use-margins" to yesNo(subtitleStyle.useMargins || layout.overflows))
        for ((name, value) in properties) {
            if (appliedLayout[name] == value) continue
            try {
                p.setAppProperty(name, value)
                appliedLayout[name] = value
            } catch (e: MpvException) {
                Log.w(TAG, "mpv $name=$value failed", e)
            }
        }
        if (layout.overflows != layoutOverflows) {
            layoutOverflows = layout.overflows
            applySubtitlePosition()
        }
        Log.i(TAG, "Video layout: ${layout.fit} zoom=${layout.zoom} $properties")
    }

    /**
     * mpv's `glsl-shaders`, a session option that stays for the files after this one. The video plane renders no user
     * shaders, so a non-empty list holds the session on the GL vo ([GpuVoPolicy.REASON_SHADERS]), which no file change
     * clears; an empty one lets it back onto the plane.
     */
    override fun setShaders(paths: List<String>) {
        submit("shaders") {
            val p = player ?: return@submit
            p.command("change-list", "glsl-shaders", "clr", "")
            for (path in paths) p.command("change-list", "glsl-shaders", "append", path)
            ambientLighting.afterShadersRebuilt()
            Log.i(TAG, "glsl-shaders: ${paths.size} file(s)")
            setGpuVoRequirement(GpuVoPolicy.REASON_SHADERS, paths.isNotEmpty())
        }
    }

    /**
     * Ambient lighting ([MpvAmbientLighting]): its shader runs on the GL vo, so while it is on the session holds that
     * ([REASON_AMBIENT_LIGHTING]), which lays the picture out across the whole view.
     */
    override fun setAmbientLighting(shaderPath: String?) {
        submit("ambient lighting") {
            setGpuVoRequirement(REASON_AMBIENT_LIGHTING, shaderPath != null)
            ambientLighting.set(shaderPath)
            Log.i(TAG, "Ambient lighting: ${if (shaderPath != null) "on" else "off"}")
        }
    }

    /** [ANDROID_LOUDNESS_NORMALIZATION_FILTER] in mpv's `af` (empty for off), with passthrough out of its way. */
    override fun setAudioNormalization(enabled: Boolean) {
        submit("audio normalization") {
            if (player != null) audio.reconcile(audio.requestNormalization(enabled))
            recordAudioChoice()
        }
    }

    override fun setAudioChannels(channels: AudioChannels, downmix: Downmix) {
        submit("audio channels") {
            if (player != null) audio.reconcile(audio.requestChannels(channels, downmix))
            recordAudioChoice()
        }
    }

    private fun recordAudioChoice() {
        val accepted = audio.accepted
        diagnostics.audio(normalization = accepted.normalization, downmix = accepted.channels == AudioChannels.STEREO)
    }

    /** Android routes the audio itself: no devices are reported, so none is picked. */
    override fun setAudioDevice(name: String) = Unit

    /**
     * Reads the stats at once and then every [STATS_INTERVAL_MS] while [wanted] ([MpvState.stats]): a [statsClock]
     * tick queues each reading on the executor. The display's mode comes from the platform.
     */
    override fun setStatsWanted(wanted: Boolean) {
        submit("stats") {
            if (wanted == (statsTick != null)) return@submit
            if (wanted) {
                // None after the teardown (a call racing release) or without a player.
                if (player == null) return@submit
                readStats()
                statsTick = statsClock.scheduleWithFixedDelay({ queueStatsReading() }, STATS_INTERVAL_MS, STATS_INTERVAL_MS, TimeUnit.MILLISECONDS)
            } else {
                statsTick?.cancel(false)
                statsTick = null
                publish { stats(null) }
            }
        }
    }

    /** A [statsClock] tick: queues a reading unless one still waits; a released engine's tick stops itself. */
    private fun queueStatsReading() {
        if (!statsReadQueued.compareAndSet(false, true)) return
        val queued = submit("stats reading") {
            statsReadQueued.set(false)
            if (statsTick != null) readStats()
        }
        if (!queued) statsTick?.cancel(false)
    }

    /**
     * Reads and publishes the stats (executor); a reading while a load waits for its file to start is the replaced
     * file's, which the lifecycle drops.
     */
    private fun readStats() {
        val p = player ?: return
        val reading = MpvState.stats(p::getString, p::getDouble, displayMode()).copy(dolbyVision = dolbyVisionStats(p))
        publish { stats(reading) }
    }

    /**
     * What decodes the file's Dolby Vision ([GpuVoPolicy.dvRoute]): the DV decoder, the bare base layer or gpu-next
     * reshaping. The track's profile is the bitstream's DOVI record: a file without one reports nothing.
     */
    private fun dolbyVisionStats(p: MpvPlayer): DolbyVisionStats? {
        val profile = pendingDoviProfile ?: return null
        val route = GpuVoPolicy.dvRoute(
            profile,
            p.getString("vd-lavc-o"),
            MediaCodecQuery.dvDecoderCandidates,
            p.getString("hwdec-current"),
            p.getString("current-vo"),
        )
        return DolbyVisionStats(sourceProfile = profile, route = DolbyVisionRoute.of(route?.id))
    }

    /** The default display's current mode, its size as well as its rate (mpv's `display-fps` is our override). */
    private fun displayMode(): MpvState.DisplayMode? {
        val mode = defaultDisplay()?.mode ?: return null
        // The decimal the float stands for (59.94, not 59.939998626708984).
        return MpvState.DisplayMode(mode.physicalWidth, mode.physicalHeight, mode.refreshRate.toString().toDouble())
    }

    /** The HDR formats the default display takes ([DisplayHdr.hdrTypes]). */
    private fun displayHdr(): Set<DynamicRange> = buildSet {
        for (type in DisplayHdr.hdrTypes(appContext)) {
            when (type) {
                Display.HdrCapabilities.HDR_TYPE_DOLBY_VISION -> add(DynamicRange.DOLBY_VISION)
                Display.HdrCapabilities.HDR_TYPE_HDR10 -> add(DynamicRange.HDR10)
                Display.HdrCapabilities.HDR_TYPE_HLG -> add(DynamicRange.HLG)
            }
        }
    }

    /** Within 0 and the session's `volume-max` ([MpvStartup.volumeMax], the Max volume setting). */
    override fun setVolume(volume: Double) {
        if (!volume.isFinite()) return
        submit("volume") { player?.setProperty("volume", volume.coerceIn(0.0, volumeMax)) }
    }

    override fun setMuted(muted: Boolean) {
        submit("mute") { player?.setProperty("mute", muted) }
    }

    override fun selectTrack(kind: TrackKind, id: Long?) {
        val property = when (kind) {
            TrackKind.VIDEO -> "vid"
            TrackKind.AUDIO -> "aid"
            TrackKind.SUBTITLE -> "sid"
        }
        submit("track selection") { player?.setProperty(property, id?.toString() ?: "no") }
    }

    override fun selectSecondSubtitle(id: Long?) {
        submit("second subtitle") { player?.setProperty("secondary-sid", id?.toString() ?: "no") }
    }

    override fun screenshot(onResult: (saved: Boolean) -> Unit) {
        val queued = submit("screenshot") {
            val saved = try {
                player?.command("screenshot", "subtitles") != null
            } catch (e: Exception) {
                Log.w(TAG, "mpv screenshot failed", e)
                false
            }
            onResult(saved)
        }
        if (!queued) onResult(false)
    }

    override fun stop() {
        submit("stop") { player?.command("stop") }
    }

    override fun subtitleSeek(forward: Boolean) {
        submit("sub-seek") { player?.command("sub-seek", if (forward) "1" else "-1") }
    }

    /**
     * Android routes the audio itself, and its video Surface drops HDR only from API 35: no output list and no player
     * HDR switch. Dolby Vision conversion follows the plan from the next file's routing ([setDolbyVisionConversion]).
     */
    override val features = EngineFeatures(dolbyVisionConversion = true)

    override fun setDolbyVisionConversion(mode: DolbyVisionConversion) {
        dvConversionMode = mode.wire
    }

    override fun addSubtitle(url: String, title: String?, lang: String?) {
        submit("subtitle") {
            val args = buildList {
                add("sub-add")
                add(url)
                add("auto")
                if (title != null || lang != null) add(title.orEmpty())
                if (lang != null) add(lang)
            }
            player?.command(*args.toTypedArray())
        }
    }

    override fun setListener(listener: PlayerEngineListener?) {
        synchronized(stateLock) {
            this.listener = listener
            lifecycle.republish()
            lifecycle.publishable()?.let { listener?.onState(it) }
        }
    }

    /** The engine's latest state: the listener's with the position mpv reported last. */
    val currentState: EngineState get() = synchronized(stateLock) { lifecycle.state }

    /**
     * HDR output as the output plan has it: the video Surface's HDR headroom ([SurfaceHints], capped at SDR without
     * it). The bound [MpvVideoView] applies it now and to every Surface it creates later; a view bound later gets it on
     * binding. Below API 35 [SurfaceHints.sdr] also moves HDR video to the GL vo, where mpv tone-maps it
     * ([applyToneMapRoute]). The frame-rate vote is the engine's own ([SurfaceFrameRateVote]). Always taken.
     */
    override fun setHdrOutput(enabled: Boolean, onResult: (applied: Boolean) -> Unit) {
        val hints = SurfaceHints(sdr = !enabled)
        surfaceHints = hints
        submit("picture output") { refreshPictureOutput() }
        host?.onSurfaceHints(hints)
        submit("tone-map route") { applyToneMapRoute() }
        onResult(true)
    }

    /**
     * The compressed formats (`ac3`, `eac3`, `dts`, `dts-hd`, `truehd`) the audio route takes undecoded; empty decodes
     * everything. mpv's `audio-spdif` lists them while the audio is neither normalized, mixed down to stereo nor played
     * at another speed than 1, which need decoded PCM ([AudioState.passesThrough]): while normalized, a route that
     * changes its formats mid-playback leaves `audio-spdif` empty, so no bitstream reaches the `af` filter. A change
     * while playing reopens the audio output. Whether the playing audio goes out undecoded is
     * [EngineState.audioPassthrough], from the output's format: mpv decodes a codec the list doesn't name, and falls
     * back to decoding when AudioTrack refuses the bitstream.
     */
    fun setAudioPassthrough(codecs: List<String>) {
        submit("audio passthrough") {
            passthroughCodecs = codecs
            if (player != null) audio.reconcile(audio.requestPassthrough(codecs.isNotEmpty()))
        }
    }

    /**
     * Diagnostics for test reports: reads [names] as strings on the engine's thread, null for a property mpv has no
     * value for. Empty when the engine is released or busy for longer than [timeoutMs] (a surface handoff). Blocks
     * the caller, so never call it on the main thread.
     */
    fun properties(names: List<String>, timeoutMs: Long = 1_000): Map<String, String?> {
        val read = FutureTask { names.associateWith { player?.getString(it) } }
        try {
            executor.execute(read)
        } catch (e: RejectedExecutionException) {
            return emptyMap()
        }
        return try {
            read.get(timeoutMs, TimeUnit.MILLISECONDS)
        } catch (e: TimeoutException) {
            emptyMap()
        } catch (e: ExecutionException) {
            emptyMap()
        } catch (e: InterruptedException) {
            Thread.currentThread().interrupt()
            emptyMap()
        }
    }

    override fun release() {
        if (!released.compareAndSet(false, true)) return
        // An armed hold is answered; a held decoder goes, its hook continued ahead of the teardown.
        decoderHolds.close()
        statsTick?.cancel(false)
        stallTick?.cancel(false)
        diagnostics.released()
        appContext.getSystemService(DisplayManager::class.java)?.unregisterDisplayListener(displayListener)
        synchronized(stateLock) { listener = null }
        host = null
        // Per-session isolation: the teardown blocks only this engine's own thread, and on a wedged decoder may
        // never return; a Surface destruction waits only for its first step, the move to the placeholder.
        try {
            executor.execute(::teardown)
        } catch (e: RejectedExecutionException) {
            hostSurfacesReleased.countDown()
        }
        executor.shutdown()
    }

    // Surfaces (main thread)

    /** `SurfaceHolder.Callback.surfaceCreated` of the video SurfaceView. */
    fun attachSurface(surface: Surface) {
        videoGeneration += 1
        videoSurface = surface
        submit("surface attach") { syncSurfaces() }
    }

    /**
     * `SurfaceHolder.Callback.surfaceDestroyed` of the video SurfaceView: moves mpv to the placeholder surface and
     * returns once it has let go of this one, or after [SURFACE_HANDOFF_TIMEOUT_MS]. Playback pauses until a real
     * surface returns, then resumes if this pause was the engine's.
     */
    fun detachSurface() {
        videoSurface = null
        handOff("surface detach")
    }

    /** `surfaceCreated` of the `vo=mediacodec` subtitle/OSD plane: a transparent SurfaceView above the video. */
    fun attachOsdSurface(surface: Surface) {
        osdGeneration += 1
        osdSurface = surface
        submit("OSD attach") {
            syncSurfaces()
            // A return to the plane waits for its OSD Surface.
            if (appliedGpuVo != GpuVoPolicy.targetFor(gpuVoReasons)) applyGpuVoTarget()
        }
    }

    /** `surfaceDestroyed` of the OSD plane; same contract as [detachSurface]. */
    fun detachOsdSurface() {
        osdSurface = null
        handOff("OSD detach")
    }

    /** `surfaceChanged` of the video SurfaceView; GL video outputs size their drawable from it. */
    fun setSurfaceSize(width: Int, height: Int) {
        if (width <= 0 || height <= 0) return
        surfaceSize = "${width}x$height"
        surfaceAspect = width.toDouble() / height
        submit("surface size") {
            applySurfaceSize()
            // A host without a viewport of its own (no MpvVideoView): a stretch takes the surface's shape.
            if (viewportAspect == null) applyVideoLayout()
        }
    }

    /** The host's size (main thread; [MpvVideoView]'s, which the plane's surface is laid out in): a stretch's shape. */
    internal fun setViewportSize(width: Int, height: Int) {
        if (width <= 0 || height <= 0) return
        val aspect = width.toDouble() / height
        if (aspect == viewportAspect) return
        viewportAspect = aspect
        submit("viewport size") { applyVideoLayout() }
    }

    internal fun setVideoRect(rect: VideoRectPolicy.Rect) {
        val value = rect.propertyValue()
        if (value == videoRect) return
        videoRect = value
        submit("video rectangle") { applyVideoRect() }
    }

    /** Binds the view that hosts this engine's Surfaces (main thread). Unbinding opens a load still waiting for it. */
    internal fun bindHost(host: MpvVideoView?) {
        this.host = host.takeUnless { released.get() }
        host?.onVideoSize(videoWidth, videoHeight)
        host?.onGpuVo(gpuVoActive)
        host?.onSurfaceHints(surfaceHints)
        host?.onVideoLayout(videoLayout)
        if (host == null) submit("pending load") { runPendingLoad() }
    }

    private fun runPendingLoad() {
        val request = pendingLoad ?: return
        pendingLoad = null
        loadFile(request)
    }

    private fun handOff(reason: String) {
        if (released.get()) {
            awaitHostSurfacesReleased()
            return
        }
        val retired = CountDownLatch(1)
        val queued = submit(reason) {
            try {
                syncSurfaces(onRetired = retired::countDown)
            } finally {
                retired.countDown()
            }
        }
        if (!queued) {
            awaitHostSurfacesReleased()
            return
        }
        try {
            if (!retired.await(SURFACE_HANDOFF_TIMEOUT_MS, TimeUnit.MILLISECONDS)) {
                Log.w(TAG, "Surface handoff ($reason) unacknowledged after ${SURFACE_HANDOFF_TIMEOUT_MS}ms; it stays queued")
            }
        } catch (e: InterruptedException) {
            Thread.currentThread().interrupt()
        }
    }

    /** A Surface destroyed after [release]: the teardown's first step moves mpv off it ([teardown]). */
    private fun awaitHostSurfacesReleased() {
        try {
            if (!hostSurfacesReleased.await(SURFACE_HANDOFF_TIMEOUT_MS, TimeUnit.MILLISECONDS)) {
                Log.e(TAG, "Teardown did not move mpv off the destroyed surface within ${SURFACE_HANDOFF_TIMEOUT_MS}ms")
            }
        } catch (e: InterruptedException) {
            Thread.currentThread().interrupt()
        }
    }

    // Executor

    /** Queues [block] on the executor; false once the engine is released. */
    private fun submit(name: String, block: () -> Unit): Boolean = try {
        executor.execute {
            try {
                block()
            } catch (e: Exception) {
                Log.w(TAG, "mpv $name failed", e)
            }
        }
        true
    } catch (e: RejectedExecutionException) {
        false
    }

    private fun initialize() {
        try {
            val surface = MpvPlaceholderSurface.create()
            placeholder = surface
            val displayFps = displayRefreshRate()
            val subtitleFonts = subtitleFonts()
            // The GL vo's compiled shader programs, kept across playbacks: with them, Anime4K's first frame came about
            // 1.3 s sooner on a Fire TV Stick 4K.
            val shaderCache = File(appContext.cacheDir, "mpv-shaders").apply { mkdirs() }
            val p = MpvPlayer.create(appContext, callbacks) {
                // The options every engine sets first; Android's own and a test run's after them win.
                for ((name, value) in COMMON_MPV_OPTIONS) setOption(name, value)
                setOption("vo", VIDEO_OUTPUT)
                setOption("gpu-context", "android")
                setOption("opengl-es", "yes")
                setOption(MpvUserConfig.DECODER_OPTIONS, userConfig.decoderOptions(decoderOptions(Build.VERSION.SDK_INT)))
                setOption("hwdec-codecs", HWDEC_CODECS)
                val soc = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) Build.SOC_MANUFACTURER else null
                for ((name, value) in OsdPlanePolicy.socOptions(soc, Build.MANUFACTURER, tv)) setOption(name, value)
                for ((name, value) in DECODER_QUEUE_OPTIONS) setOption(name, value)
                // AV1 film grain stays in the decoder: gpu-next's GLES raster grain renders luma upside-down.
                setOption("vd-lavc-film-grain", "cpu")
                setOption("gpu-shader-cache-dir", shaderCache.path)
                if (displayFps != null) setOption("display-fps-override", displayFps.toString())
                setOption("ao", "audiotrack,opensles")
                if (subtitleFonts != null) {
                    setOption("sub-fonts-dir", subtitleFonts.absolutePath)
                    setOption("sub-font", SUBTITLE_FONT_FAMILY)
                }
                // On an upright phone the surface is the whole screen and the video a band across it: text subtitles
                // sized by the screen came out about three times the video's size, below the band. Sized and placed by
                // the video (as the Apple engine on iOS), they keep the video's proportions on every screen shape, and
                // `sub-pos` moves them by shares of the picture: the controls' lift is the part of them over it
                // (subtitleFrame, from osd-dimensions). The Subtitle margins setting (and a picture running past the
                // surface, applyVideoLayout) places them by the screen instead.
                setOption("sub-scale-with-window", "no")
                setOption("sub-use-margins", yesNo(subtitleStyle.useMargins))
                for ((name, value) in MpvStartup.properties(settings, desktop = false)) setOption(name, value)
                setLogLevel(MpvStartup.logLevel(settings.debugLogging))
                for ((name, value) in extraOptions) setOption(name, value)
            }
            player = p
            live.add(this)
            MpvNativeLibraries.loaded()
            appliedDisplayFps = displayFps
            // The user's mpv.conf after the engine's own options; every later app write yields to it (setAppProperty).
            for ((name, value) in userConfig.options) {
                // A decoder options line went in with the engine's own above, after them (MpvUserConfig.decoderOptions).
                if (name == MpvUserConfig.DECODER_OPTIONS) continue
                try {
                    p.setProperty(name, value)
                } catch (e: Exception) {
                    Log.w(TAG, "mpv.conf line $name=$value not applied: ${e.message}")
                }
            }
            p.setAppProperty("volume-max", volumeMax.toString())
            p.setProperty("volume", MpvStartup.volume(settings).coerceAtMost(volumeMax))
            Log.i(
                TAG,
                "mpv started: heap class ${heapClassMB} MB, demuxer budget ${steadyBudget?.let { "${it.aheadBytes / MIB}/${it.backBytes / MIB} MB" } ?: "the files' own"}, " +
                    "log level ${MpvStartup.logLevel(settings.debugLogging)}, volume-max $volumeMax",
            )
            for (name in MpvLifecycle.DOUBLES) p.observeProperty(name, PropertyFormat.Double)
            for (name in MpvLifecycle.FLAGS) p.observeProperty(name, PropertyFormat.Flag)
            for (name in MpvLifecycle.TEXTS) p.observeProperty(name, PropertyFormat.String)
            for ((name, format) in OBSERVED) p.observeProperty(name, format)
            // mpv always holds a valid Surface: the placeholder until the host's first surfaceCreated.
            syncSurfaces()
        } catch (e: Throwable) {
            // A native library that doesn't load (an ABI the AAR lacks) is a LinkageError: the same failure here.
            if (e !is Exception && e !is LinkageError) throw e
            Log.e(TAG, "mpv initialization failed", e)
            val error = EngineError("mpv initialization failed: ${e.message}")
            initFailure = error
            publish { fail(error) }
        }
    }

    /**
     * Moves mpv to the placeholder, as a surface loss does, then terminates it. A Surface destroyed after [release]
     * waits for the move alone: termination first joins the decoder thread, which a hardware decoder draining at the
     * end of a paused file holds a second per output dequeue, and then frees the codec, the audio track and the video
     * output.
     */
    private fun teardown() {
        val p = player
        player = null
        live.remove(this)
        budgetRestore?.cancel(false)
        budgetRestore = null
        if (p != null && letGoOfHostSurfaces(p)) hostSurfacesReleased.countDown()
        events?.invoke("terminate")
        try {
            // Blocks through decoder and video-output teardown. The MediaCodec vo can hold a Surface until final
            // decoder teardown, so the placeholder is only closed once this returns.
            p?.close()
            placeholder?.close()
            placeholder = null
        } catch (e: Exception) {
            // A failed close is not permission to free a Surface a producer may still use.
            Log.w(TAG, "mpv close failed", e)
        } finally {
            hostSurfacesReleased.countDown()
        }
    }

    /** False when mpv may still hold a host Surface: the move failed, and only the termination lets go of it. */
    private fun letGoOfHostSurfaces(p: MpvPlayer): Boolean {
        val placeholderSurface = placeholder?.surface ?: return false
        if ((attachedVideo == null || attachedVideo === placeholderSurface) && attachedOsd == null) return true
        return try {
            p.attachSurfaces(placeholderSurface, null, 0L, osdGeneration)
            attachedVideo = placeholderSurface
            synchronized(stateLock) { frameRateVote.onSurfaceChanged(null) }
            attachedOsd = null
            true
        } catch (e: Exception) {
            Log.w(TAG, "Teardown could not move mpv to the placeholder; the host's surfaces wait for its termination", e)
            false
        }
    }

    private fun displayRefreshRate(): Float? = defaultDisplay()?.mode?.refreshRate?.takeIf { it > 0f }

    /** A vote of [rate] (0 for none) on [surface] ([SurfaceFrameRateVote]): a fixed source, switching only seamlessly. */
    private fun setSurfaceFrameRate(surface: Surface, rate: Float) {
        if (Build.VERSION.SDK_INT < FRAME_RATE_VOTE_MIN_SDK || !surface.isValid) return
        val compatibility = if (rate == 0f) Surface.FRAME_RATE_COMPATIBILITY_DEFAULT else Surface.FRAME_RATE_COMPATIBILITY_FIXED_SOURCE
        try {
            surface.setFrameRate(rate, compatibility)
            Log.i(TAG, "Frame rate vote: ${if (rate > 0f) "$rate fps" else "none"}")
        } catch (e: IllegalStateException) {
            // The Surface was abandoned between the validity check and the call.
            Log.w(TAG, "Frame rate vote $rate failed", e)
        }
    }

    /** The Dolby Vision conversion as the settings and the display decide it ([GpuVoPolicy.dvRouting]). */
    private fun dvRouting(): GpuVoPolicy.DvRouting =
        GpuVoPolicy.dvRouting(dvConversionMode, DisplayHdr.supportsDolbyVision(appContext), dolbyVisionOutput)

    /**
     * The default display's mode changes under a playback once the video's rate is known: the system follows the
     * video Surface's frame-rate vote (`Surface.setFrameRate`, API 30+), or the window's preferred mode forces it on a
     * TV, after mpv started at the old rate (the output host holds playback through the switch, [holdForDisplay]).
     * Main thread.
     */
    private val displayListener = object : DisplayManager.DisplayListener {
        override fun onDisplayAdded(displayId: Int) = Unit

        override fun onDisplayRemoved(displayId: Int) = Unit

        override fun onDisplayChanged(displayId: Int) {
            if (displayId != Display.DEFAULT_DISPLAY) return
            val rate = displayRefreshRate() ?: return
            submit("display rate") { followDisplayRate(rate) }
        }
    }

    /** `display-fps-override` at the display's [rate], which mpv times frames and their drops by (executor). */
    private fun followDisplayRate(rate: Float) {
        val p = player ?: return
        if (rate == appliedDisplayFps) return
        p.setProperty("display-fps-override", rate.toString())
        appliedDisplayFps = rate
        Log.i(TAG, "display-fps-override=$rate")
    }

    private fun defaultDisplay(): Display? = appContext.getSystemService(DisplayManager::class.java)?.getDisplay(Display.DEFAULT_DISPLAY)

    /**
     * libass on Android has no system font provider (mpv-build compiles it without fontconfig): it draws only the
     * fonts in `sub-fonts-dir` and those a file embeds, and looks a glyph a style's font lacks up in `sub-font`'s
     * family alone. So every script comes from one family: the bundled Go Noto Current and its Hangul companion,
     * copied out of the APK into a directory of their own (again only when a size differs). libass
     * loads every file in that directory into memory (16.7 MB). Null (no subtitle text) when the copy fails.
     */
    private fun subtitleFonts(): File? = try {
        val assets = appContext.assets
        val fonts = assets.list(SUBTITLE_FONT_ASSETS).orEmpty().filter { it.endsWith(".ttf") }
        val dir = File(appContext.cacheDir, "mpv-fonts").apply { mkdirs() }
        dir.listFiles()?.filter { it.name !in fonts }?.forEach { it.delete() }
        for (name in fonts) {
            val target = File(dir, name)
            assets.open("$SUBTITLE_FONT_ASSETS/$name").use { input ->
                // An asset stream's available() is its whole uncompressed length.
                if (target.length() != input.available().toLong()) {
                    val partial = File(dir, "$name.partial")
                    partial.outputStream().use { input.copyTo(it) }
                    if (!partial.renameTo(target)) throw IOException("can't move $partial to $target")
                }
            }
        }
        dir
    } catch (e: IOException) {
        Log.w(TAG, "Subtitle font setup failed", e)
        null
    }

    /**
     * Binds mpv to the current Surfaces: the host's video Surface when there is one, else the placeholder; the OSD
     * plane only with a real video Surface on the plane. [onRetired] fires as soon as the Surfaces mpv held before
     * are released — the barrier a `surfaceDestroyed` caller waits for — before any pause or resume write.
     */
    private fun syncSurfaces(onRetired: () -> Unit = {}) {
        val p = player ?: return
        val placeholderSurface = placeholder?.surface ?: return
        if (videoOutputFailed) return
        val real = videoSurface?.takeIf { it.isValid }
        val video = real ?: placeholderSurface
        val videoGen = if (real != null) videoGeneration else 0L
        val osd = if (real != null && appliedGpuVo == null) osdSurface?.takeIf { it.isValid } else null
        val osdGen = osdGeneration
        val wasReal = attachedVideo != null && attachedVideo !== placeholderSurface
        val videoChanged = video !== attachedVideo || videoGen != attachedVideoGeneration
        val changed = videoChanged || osd !== attachedOsd || (osd != null && osdGen != attachedOsdGeneration)
        if (changed) {
            try {
                parkingVideoForRebuild(p) { p.attachSurfaces(video, osd, videoGen, osdGen) }
            } catch (e: Exception) {
                failVideoOutput(e)
                return
            }
            attachedVideo = video
            attachedVideoGeneration = videoGen
            attachedOsd = osd
            attachedOsdGeneration = osdGen
            appliedSurfaceSize = null
            appliedVideoRect = null
            Log.i(TAG, "Surfaces attached: video=${if (real != null) "real#$videoGen" else "placeholder"} osd=${if (osd != null) "#$osdGen" else "none"}")
        }
        onRetired()
        synchronized(stateLock) { frameRateVote.onSurfaceChanged(real) }
        if (real == null) {
            if (wasReal && p.getFlag("pause") == false) {
                p.setProperty("pause", true)
                pausedForSurfaceLoss = true
            }
            return
        }
        applySurfaceSize()
        applyVideoRect()
        // A Surface that arrives while paused (back from Home or a stopped picture-in-picture) gets the shown frame from
        // the library, which decodes it again into the new Surface.
        if (pausedForSurfaceLoss) {
            pausedForSurfaceLoss = false
            // Held for a display switch meanwhile: the hold's release plays on.
            if (!synchronized(stateLock) { lifecycle.held }) p.setProperty("pause", false)
        }
        runPendingLoad()
    }

    private fun failVideoOutput(error: Exception) {
        Log.e(TAG, "mpv video output failed", error)
        videoOutputFailed = true
        publish { fail(EngineError("Video output failed: ${error.message}", kind = EngineErrorKind.DECODE)) }
    }

    private fun applySurfaceSize() {
        val p = player ?: return
        if (attachedVideo == null || attachedVideo === placeholder?.surface) return
        val size = surfaceSize ?: return
        if (size == appliedSurfaceSize) return
        p.setProperty("android-surface-size", size)
        appliedSurfaceSize = size
    }

    /** The picture's bounds in the OSD plane, so the plane's subtitles and margins line up with the video. */
    private fun applyVideoRect() {
        val p = player ?: return
        if (appliedGpuVo != null || attachedOsd == null) return
        val rect = videoRect ?: return
        if (rect == appliedVideoRect) return
        p.setProperty("vo-mediacodec-video-rect", rect)
        appliedVideoRect = rect
    }

    private fun setGpuVoRequirement(reason: String, active: Boolean) {
        val changed = if (active) gpuVoReasons.add(reason) else gpuVoReasons.remove(reason)
        if (!changed) return
        Log.i(TAG, "Video route: ${appliedGpuVo ?: "mediacodec"} -> ${GpuVoPolicy.targetFor(gpuVoReasons) ?: "mediacodec"} (reasons=$gpuVoReasons)")
        applyGpuVoTarget()
    }

    /**
     * Moves the session between the video plane and a GL vo. The `vo` switch rebuilds the video chain on the Surface
     * mpv already holds; the plane gets its OSD Surface back in the same write, and a host waiting to show the OSD
     * plane again retries from [attachOsdSurface].
     */
    private fun applyGpuVoTarget() {
        val target = GpuVoPolicy.targetFor(gpuVoReasons)
        if (target == appliedGpuVo || videoOutputFailed) return
        val p = player ?: return
        val placeholderSurface = placeholder?.surface ?: return
        val video = attachedVideo ?: placeholderSurface
        val onReal = video !== placeholderSurface
        val osd = if (target == null && onReal) osdSurface?.takeIf { it.isValid } else null
        val currentHost = host
        if (target == null && onReal && osd == null && currentHost != null) {
            // Show the OSD plane first; its surfaceCreated comes back here.
            currentHost.onGpuVo(false)
            return
        }
        try {
            parkingVideoForRebuild(p) { p.attachSurfaces(video, osd, attachedVideoGeneration, osdGeneration, target ?: "mediacodec") }
        } catch (e: Exception) {
            failVideoOutput(e)
            return
        }
        attachedOsd = osd
        attachedOsdGeneration = osdGeneration
        appliedGpuVo = target
        refreshPictureOutput()
        appliedSurfaceSize = null
        appliedVideoRect = null
        gpuVoActive = target != null
        applyRenderTier(p, glVoActive = target != null)
        if (target != null && p.getString("vid").let { it == null || it == "no" }) {
            // A failed chain deselects video before this switch; re-select it by id.
            val videoTrack = synchronized(stateLock) { lifecycle.state.tracks.firstOrNull { it.kind == TrackKind.VIDEO } }
            if (videoTrack != null) p.setProperty("vid", videoTrack.id.toString())
        }
        applySurfaceSize()
        applyVideoRect()
        host?.onGpuVo(target != null)
    }

    /**
     * Runs [rebuild], a Surface hand-off or `vo` switch (each makes mpv rebuild the video chain and re-create the
     * decoder inside it), with the video track deselected when [GpuVoPolicy.needsParkedRebuild] says so: Tensor's
     * BigOcean AV1 service dies when the next decoder starts while the last one is still shutting down, and mpv then
     * falls back to copying or software decoding, which the plane can't show. Deselecting closes the
     * decoder before the rebuild; selecting the track again afterwards creates the next one on the finished output.
     */
    private fun parkingVideoForRebuild(p: MpvPlayer, rebuild: () -> Unit) {
        val park = GpuVoPolicy.needsParkedRebuild(p.getString("current-tracks/video/codec"), p.getString("hwdec"), MediaCodecQuery.bigOceanAv1)
        val vid = if (park) p.getString("vid")?.toLongOrNull() else null
        if (vid == null) return rebuild()
        Log.i(TAG, "Video track $vid parked across the output rebuild (BigOcean AV1)")
        p.setProperty("vid", "no")
        try {
            rebuild()
        } finally {
            p.setProperty("vid", vid.toString())
        }
    }

    /**
     * Moves the render options between mpv's defaults and the cheap tier as the session enters or leaves a GL vo
     * ([GpuVoPolicy.needsCheapRenderTier]). Only options still at their mpv default are replaced, so a deliberate
     * setting wins, and only those are restored.
     */
    private fun applyRenderTier(p: MpvPlayer, glVoActive: Boolean) {
        val wanted = GpuVoPolicy.needsCheapRenderTier(glVoActive, GlCapabilities.textureNorm16)
        if (wanted == cheapRenderTierActive) return
        cheapRenderTierActive = wanted
        if (wanted) {
            for ((option, cheap) in GpuVoPolicy.CHEAP_RENDER_OPTIONS) {
                val current = p.getString(option)
                if (!GpuVoPolicy.isDefaultRenderOption(option, current)) continue
                cheapRenderRestore[option] = current!!
                p.setProperty(option, cheap)
            }
            Log.i(TAG, "Cheap render tier (no GL_EXT_texture_norm16): ${cheapRenderRestore.keys.joinToString(",")}")
        } else {
            for ((option, value) in cheapRenderRestore) p.setProperty(option, value)
            cheapRenderRestore.clear()
        }
    }

    /**
     * Per-file decode routing inside `on_preloaded`: the demuxer has opened the file, no decoder exists yet, and mpv
     * waits for the answer. Streams hardware cannot serve decode in software from the start, on the GL vo; Dolby
     * Vision P5 without a decoder that converts it decodes in software on gpu-next, which reshapes it. A file whose
     * `hwdec` is `no` (the Hardware decoding setting off) goes to the GL vo too, since the plane takes MediaCodec
     * buffers only. Returns the file's video track; null without one.
     */
    private fun applyDecodeRouting(p: MpvPlayer): MpvState.VideoTrack? {
        val tracks = MpvState.videoTracks(p.getString("track-list"))
        val vid = p.getString("vid")
        val pendingVid = if (vid == null || vid == "auto") p.getString("pending-vid") else null
        val id = GpuVoPolicy.pendingVideoTrackId(vid, pendingVid, tracks.map { it.id })
        val track = tracks.firstOrNull { it.id == id }
        val softwareChosen = requestedHwdec == PlaybackOptions.SOFTWARE
        applyDvRouting(p, track?.doviProfile, softwareChosen)
        val needs = GpuVoPolicy.needsSoftwareDecode(
            codec = track?.codec,
            codecProfile = track?.codecProfile,
            hardwareHigh10 = MediaCodecQuery.hardwareAvcHigh10,
            hardwareHevcMain10 = MediaCodecQuery.hardwareHevcMain10,
            hardwareAv1 = MediaCodecQuery.hardwareAv1,
        )
        val route = when {
            softwareChosen -> "software decode on the GL vo (hwdec=no)"
            needs -> "software decode on the GL vo"
            else -> "hwdec"
        }
        Log.i(TAG, "Decode routing: track=$id codec=${track?.codec} profile=${track?.codecProfile} -> $route")
        holdHwdec(p, GpuVoPolicy.REASON_CODEC_SW_DECODE, needs)
        setGpuVoRequirement(GpuVoPolicy.REASON_CODEC_SW_DECODE, needs)
        setGpuVoRequirement(GpuVoPolicy.REASON_HWDEC_OFF, softwareChosen)
        decoderContentFps = track?.fps
        val mime = MediaCodecQuery.mimeTypeForCodec(track?.codec)
        val width = track?.width
        val height = track?.height
        decoderMaxFps = if (mime != null && width != null && height != null) MediaCodecQuery.maxDecoderFrameRate(mime, width, height) else null
        applyOperatingRate(p)
        applyFramedrop(p)
        return track
    }

    /**
     * Tells the file's MediaCodec decoder the rate to be ready for ([DecoderOperatingRate]): before it opens, and again
     * on the running decoder when the speed changes. A software decoder ignores it. A test run's or a mpv.conf line's
     * own value wins.
     */
    private fun applyOperatingRate(p: MpvPlayer) {
        if ("hwdec-mediacodec-operating-rate" in extraOptions) return
        val rate = DecoderOperatingRate.of(decoderContentFps, audio.accepted.rate, decoderMaxFps)
        p.setAppProperty("hwdec-mediacodec-operating-rate", rate.toString())
        Log.i(TAG, "Decoder operating rate $rate (fps=$decoderContentFps speed=${audio.accepted.rate} max=${decoderMaxFps ?: "unknown"})")
    }

    /**
     * `framedrop` for the file's decode path. On the plane the vo shows a late frame at the next vsync, so its `vo` part
     * does nothing there; `decoder` lets the MediaCodec decoder shed a frame no later frame references when mpv measures
     * itself behind, the only way a hardware decoder makes up time. Software decoding on the GL vo
     * keeps mpv's `vo`: its renderer can be what's slow, and dropping in a software decoder mistimes frames. A test
     * run's or a mpv.conf line's own value wins.
     */
    private fun applyFramedrop(p: MpvPlayer) {
        if ("framedrop" in extraOptions) return
        p.setAppProperty("framedrop", if (hwdecHoldReasons.isEmpty() && requestedHwdec != PlaybackOptions.SOFTWARE) "decoder+vo" else "vo")
    }

    /**
     * Writes the file's Dolby Vision decoder options before its decoder opens, and moves P5 that no decoder converts
     * (or that decodes in software, [softwareChosen]) to software decode on gpu-next. Both answers come from what the
     * bundled FFmpeg will actually open ([GpuVoPolicy.nativeDvDecoder]) and whether the display takes a DV signal.
     */
    private fun applyDvRouting(p: MpvPlayer, doviProfile: Int?, softwareChosen: Boolean) {
        pendingDoviProfile = doviProfile
        val candidates = MediaCodecQuery.dvDecoderCandidates
        val p5Decoder = GpuVoPolicy.nativeDvDecoder(candidates, 5)
        val routing = dvRouting()
        val displayDv = routing.displaySupportsDv
        val options = GpuVoPolicy.dvDecoderOptions(routing.conversionMode, displayDv, doviProfile, nativeP5Decoder = p5Decoder != null)
        p.setProperty(MpvUserConfig.DECODER_OPTIONS, userConfig.decoderOptions(decoderOptions(Build.VERSION.SDK_INT, options)))
        val reshape = GpuVoPolicy.needsDvReshaping(
            doviProfile,
            routing.conversionMode,
            nativeP5Decoder = p5Decoder != null,
            softwareDecode = softwareChosen,
        )
        val decoder = GpuVoPolicy.nativeDvDecoder(candidates, doviProfile)
        dolbyVisionDecoder = options.dolbyVision && decoder != null
        refreshPictureOutput()
        if (doviProfile != null) {
            Log.i(
                TAG,
                "DV routing: profile=$doviProfile decoder=${decoder ?: "none"} displayDv=$displayDv " +
                    "dolby_vision=${if (options.dolbyVision) 1 else 0} dv_p7_mode=${options.p7Mode} " +
                    "path=${if (reshape) "software decode + gpu-next reshaping" else "video plane"} " +
                    "(DV decoders: ${candidates.joinToString { "${it.name} ${it.mime}" }.ifEmpty { "none" }})",
            )
        }
        holdHwdec(p, GpuVoPolicy.REASON_DV_RESHAPE, reshape)
        setGpuVoRequirement(GpuVoPolicy.REASON_DV_RESHAPE, reshape)
    }

    /** The hardware decoder dropped this file's HDR colour aspects: software decode on the GL vo for the rest of it. */
    private fun onHardwareDroppedHdr() {
        val p = player ?: return
        Log.w(TAG, "Hardware decoder dropped the HDR colour aspects (video-params went SDR); software decode on the GL vo for this file")
        holdHwdec(p, GpuVoPolicy.REASON_HDR_ASPECTS, true)
        setGpuVoRequirement(GpuVoPolicy.REASON_HDR_ASPECTS, true)
    }

    /**
     * HDR frames leave the plane for the GL vo, where mpv tone-maps them to SDR, when the display doesn't take their
     * format or the Hdr setting is off below API 35, and come back when neither holds ([GpuVoPolicy.needsToneMapping]).
     * Decided on the output's transfer (`video-params`), so a file whose first frame hasn't come keeps the route the
     * last one had.
     */
    private fun applyToneMapRoute() {
        val gamma = synchronized(stateLock) { lifecycle.transfer } ?: return
        val needed = GpuVoPolicy.needsToneMapping(
            gamma,
            DisplayHdr.hdrTypes(appContext),
            dolbyVisionDecoder,
            hdrOutput = !surfaceHints.sdr,
            hdrSdrConversion,
            Build.VERSION.SDK_INT,
        )
        setGpuVoRequirement(GpuVoPolicy.REASON_TONE_MAP, needed)
    }

    /**
     * The GL vo's surface for the session, decided by its first file (an EGL surface's colorspace is fixed when the GL
     * vo creates it, up front for software decoding or at a fallback off the plane): a BT.2020 PQ surface with a
     * 10-bit or half-float config ([EglHdrCaps]) and a PQ target ([MpvLoad.hdrSurfaceOptions]), so PQ and HLG video
     * stays HDR on the GL vo, where the server says a direct-played file is PQ or HLG
     * ([com.edde746.plezy.playback.ServerStream.colorTransfer]; a transcode's transfer is unknown, as the server may
     * tone-map it), the Hdr setting and HDR output are on and the display takes HDR. Otherwise the surface stays sRGB
     * and mpv tone-maps HDR on it. The plane carries HDR in the decoder's dataspace and ignores all this. A PQ target
     * renders a later SDR file right, so the decision stays.
     */
    private fun decideHdrSurface(p: MpvPlayer, request: LoadRequest) {
        if (hdrSurfaceDecided) return
        hdrSurfaceDecided = true
        val transfer = request.server?.takeIf { !it.transcode }?.colorTransfer?.trim()?.lowercase()
        val hdrDisplay = displayHdr().let { DynamicRange.HDR10 in it || DynamicRange.HLG in it }
        val options = MpvLoad.hdrSurfaceOptions(transfer, displayTakesHdr = hdrDisplay, hdrOutput = settings.hdr && !surfaceHints.sdr)
        if (options.isEmpty()) return
        val format = EglHdrCaps.pqOutputFormat
        if (format == null) {
            Log.i(TAG, "HDR GL surface unavailable: transfer=$transfer, no 10-bit or half-float EGL config")
            return
        }
        try {
            p.setAppProperty("egl-output-format", format)
            for ((name, value) in options) p.setAppProperty(name, value)
            Log.i(TAG, "HDR GL surface: BT.2020 PQ, $format, for transfer=$transfer")
        } catch (e: MpvException) {
            // The GL vo keeps its sRGB surface and tone-maps, as without the surface.
            Log.w(TAG, "HDR GL surface not applied", e)
        }
    }

    /** Looks at the file that just loaded every [STALL_SAMPLE_MS] until it ends ([checkDecodeStall]). */
    private fun watchDecodeStall() {
        stallSample = null
        if (stallTick != null || player == null) return
        stallTick = statsClock.scheduleWithFixedDelay({ queueStallCheck() }, STALL_SAMPLE_MS, STALL_SAMPLE_MS, TimeUnit.MILLISECONDS)
    }

    private fun stopDecodeStallWatch() {
        stallTick?.cancel(false)
        stallTick = null
        stallSample = null
    }

    /** A [statsClock] tick: queues a stall check unless one still waits; a released engine's tick stops itself. */
    private fun queueStallCheck() {
        if (!stallCheckQueued.compareAndSet(false, true)) return
        val queued = submit("decode stall check") {
            stallCheckQueued.set(false)
            if (stallTick != null) checkDecodeStall()
        }
        if (!queued) stallTick?.cancel(false)
    }

    /**
     * One look at the current file ([GpuVoPolicy.DecodeSample]), acted on per [GpuVoPolicy.decodeStall]: a stuck
     * decoder that may be hardware moves the file to software decode on the GL vo, reloaded at the current position; a
     * software one fails the file. A decoder that never answers, at the open, after a seek or mid-file, ends in
     * playback or the player's error, never in a frozen picture or an endless open.
     */
    private fun checkDecodeStall() {
        val p = player ?: return
        val cache = MpvState.videoCache(p.getString("demuxer-cache-state"))
        // Unavailable until playback is initialized, when the first frame is due as well.
        val restartPending = p.getFlag("seeking") ?: true
        val pausedForCache = p.getFlag("paused-for-cache") == true
        val sample = synchronized(stateLock) {
            val state = lifecycle.state
            if (state.error != null) return
            GpuVoPolicy.DecodeSample(
                position = state.positionSeconds,
                restarts = state.playbackRestarts,
                videoReaderPts = cache?.readerPts,
                restartPending = restartPending,
                paused = state.paused || lifecycle.held,
                pausedForCache = pausedForCache,
                eof = state.eof,
            )
        }
        val now = System.nanoTime()
        if (sample != stallSample) {
            stallSample = sample
            stallSampleSince = now
        }
        val unchanged = (now - stallSampleSince) / 1e9
        val hwdec = p.getString("hwdec")
        val decision = GpuVoPolicy.decodeStall(sample, unchanged, cache?.seconds, hardwareAllowed = hwdec != "no")
        if (decision == GpuVoPolicy.DecodeStall.NONE) return
        val stall = String.format(
            Locale.ROOT,
            "no frame and no video packet taken for %.1f s at %.3f s (%s, %.1f s of video ahead, hwdec=%s)",
            unchanged, sample.position, if (sample.restartPending) "waiting for the first frame" else "playing", cache?.seconds, hwdec,
        )
        if (decision == GpuVoPolicy.DecodeStall.SOFTWARE) {
            Log.w(TAG, "Decode stalled: $stall; software decode on the GL vo for this file, reloaded at the current position")
            holdHwdec(p, GpuVoPolicy.REASON_HW_DECODE_FAILURE, true)
            // The reload: an exact seek to the current position, which repeats a seek still waiting for its frame.
            p.command("seek", "0", "relative+exact")
            setGpuVoRequirement(GpuVoPolicy.REASON_SW_DECODE, true)
            stallSample = null
        } else {
            stopDecodeStallWatch()
            val error = EngineError("Video decoding stalled: no frame for ${unchanged.toInt()} s", kind = EngineErrorKind.DECODE)
            Log.w(TAG, "Decode stalled: $stall; playback failed: $error")
            publish { fail(error) }
        }
    }

    /** Adds or drops a per-file reason to hold `hwdec` at `no`; parks the session's value on the first. */
    private fun holdHwdec(p: MpvPlayer, reason: String, hold: Boolean) {
        val changed = if (hold) hwdecHoldReasons.add(reason) else hwdecHoldReasons.remove(reason)
        if (!changed) return
        applyFramedrop(p)
        if (hold && parkedHwdec == null) {
            parkedHwdec = p.getString("hwdec") ?: requestedHwdec ?: PlaybackOptions.SOFTWARE
            p.setProperty("hwdec", "no")
        } else if (!hold && hwdecHoldReasons.isEmpty()) {
            parkedHwdec?.let { p.setProperty("hwdec", it) }
            parkedHwdec = null
        }
    }

    // State

    /**
     * Applies [change] to the lifecycle (which may also update the engine's own inputs to it) and tells the listener
     * what is due ([MpvLifecycle.publishable]), under stateLock.
     */
    private inline fun publish(change: MpvLifecycle.() -> Unit) {
        synchronized(stateLock) {
            lifecycle.change()
            val state = lifecycle.state
            frameRateVote.onFrameRate(state.video?.fps?.toFloat() ?: 0f)
            frameRateVote.onPlaybackSpeed(state.speed.toFloat())
            frameRateVote.onRunning(state.loaded && !state.paused && !state.buffering)
            lifecycle.publishable()?.let { listener?.onState(it) }
            diagnostics.update(state)
        }
    }

    /**
     * Where the picture goes, read again when the vo, the file's decoder or the surface hints change (executor), and
     * what the display gets from it ([EngineState.outputDynamicRange]). The display's HDR formats are read here too:
     * at every file (its decoder routing) and every vo switch.
     */
    private fun refreshPictureOutput() {
        val output = PictureOutput(
            videoPlane = appliedGpuVo == null,
            displayHdr = displayHdr(),
            dolbyVisionDecoder = dolbyVisionDecoder,
            sdrHeadroom = surfaceHints.sdr && Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM,
        )
        publish {
            pictureOutput = output
            outputRange(androidOutputRange())
        }
    }

    /** [EngineState.outputDynamicRange] from the frames' transfer, [targetParams] and [pictureOutput]. Under stateLock. */
    private fun androidOutputRange() = pictureOutput?.let {
        MpvState.androidOutputRange(lifecycle.transfer, targetParams, it.videoPlane, it.displayHdr, it.dolbyVisionDecoder, it.sdrHeadroom)
    }

    private val callbacks = object : MpvPlayer.Listener {
        override fun onPropertyChange(change: PropertyChange) {
            when (change.name) {
                "video-target-params" -> publish {
                    targetParams = change.string()
                    outputRange(androidOutputRange())
                }
                "current-vo" -> Log.i(TAG, "current-vo=${change.string()}")
                "vo-format-rejected" -> if (change.flag() == true) {
                    submit("rejected format route") { setGpuVoRequirement(GpuVoPolicy.REASON_FORMAT_REJECTED, true) }
                }
                "dwidth", "dheight" -> {
                    val value = (change as? PropertyChange.Int64)?.value?.toInt() ?: 0
                    if (change.name == "dwidth") videoWidth = value else videoHeight = value
                    if (videoWidth > 0 && videoHeight > 0) host?.onVideoSize(videoWidth, videoHeight)
                }
                "osd-dimensions" -> {
                    // The picture moves within the subtitle plane (a rotation, a new file): lifted subtitles follow.
                    val frame = MpvState.subtitleFrame(change.string())
                    submit("subtitle frame") {
                        if (frame != subtitleFrame) {
                            subtitleFrame = frame
                            applySubtitlePosition()
                        }
                    }
                }
                else -> onLifecycleProperty(change)
            }
        }

        /** One of [MpvLifecycle]'s properties, and the routes `video-params` and `hwdec-current` decide. */
        private fun onLifecycleProperty(change: PropertyChange) {
            var droppedHdr = false
            publish {
                val hwdec = state.hwdec
                when (change) {
                    is PropertyChange.Double -> double(change.name, change.value)
                    is PropertyChange.Flag -> flag(change.name, change.value)
                    is PropertyChange.Str -> text(change.name, change.value)
                    is PropertyChange.None -> unavailable(change.name)
                    else -> error("mpv's ${change.name} came in a format the lifecycle doesn't observe it in: $change")
                }
                if (change.name == "video-params") {
                    val gamma = transfer
                    if (GpuVoPolicy.isHdrTransfer(gamma)) {
                        hdrTransferSeen = true
                    } else {
                        droppedHdr = GpuVoPolicy.hardwareDroppedHdr(hdrTransferSeen, gamma, hwdec)
                    }
                    outputRange(androidOutputRange())
                }
            }
            when (change.name) {
                "video-params" -> {
                    if (droppedHdr) submit("HDR aspects route") { onHardwareDroppedHdr() }
                    val aspect = MpvState.displayAspect(change.string())
                    submit("ambient lighting aspect") { ambientLighting.onVideoParams(aspect) }
                    submit("tone-map route") { applyToneMapRoute() }
                }
                "hwdec-current" -> {
                    val value = change.string()
                    Log.i(TAG, "hwdec-current=$value")
                    if (GpuVoPolicy.needsSoftwareRender(value)) {
                        val dvReshape = GpuVoPolicy.softwareDecodeNeedsDvReshaping(pendingDoviProfile, dvRouting().conversionMode, value)
                        submit("software render route") {
                            // mpv settled on software: its hardware decoders failed or none takes the codec. Held
                            // before the vo switch, so the GL vo's rebuilt chain doesn't probe MediaCodec again.
                            if (value == "no") player?.let { holdHwdec(it, GpuVoPolicy.REASON_HW_DECODE_FAILURE, true) }
                            setGpuVoRequirement(GpuVoPolicy.REASON_SW_DECODE, true)
                            if (dvReshape) setGpuVoRequirement(GpuVoPolicy.REASON_DV_RESHAPE, true)
                        }
                    }
                }
            }
        }

        override fun onEvent(event: MpvEvent) {
            when (event) {
                is MpvEvent.StartFile -> {
                    decoderHolds.onFileStarted()
                    publish {
                        startFile()
                        hdrTransferSeen = false
                    }
                    // All of these are per file; give the plane and hardware decoding back to the next one.
                    submit("per-file video route reset") {
                        player?.let {
                            holdHwdec(it, GpuVoPolicy.REASON_HW_DECODE_FAILURE, false)
                            holdHwdec(it, GpuVoPolicy.REASON_HDR_ASPECTS, false)
                        }
                        setGpuVoRequirement(GpuVoPolicy.REASON_FORMAT_REJECTED, false)
                        setGpuVoRequirement(GpuVoPolicy.REASON_SW_DECODE, false)
                        setGpuVoRequirement(GpuVoPolicy.REASON_HDR_ASPECTS, false)
                    }
                }
                is MpvEvent.FileLoaded -> {
                    publish { fileLoaded() }
                    submit("decode stall watch") { watchDecodeStall() }
                }
                is MpvEvent.PlaybackRestart -> {
                    var first = false
                    publish { first = playbackRestart() }
                    if (first) events?.invoke("playing")
                }
                is MpvEvent.EndFile -> {
                    decoderHolds.onFileEnded()
                    submit("decode stall watch end") { stopDecodeStallWatch() }
                    // mpv-android names every reason client.h has; one it doesn't name is an mpv newer than it.
                    val reason = event.reason
                    if (reason == null) {
                        Log.w(TAG, "end-file with a reason mpv-android doesn't name: $event")
                    } else {
                        publish { endFile(reason.id, event.error?.code ?: 0, event.errorMessage ?: "playback error") }
                    }
                }
                is MpvEvent.LogMessage -> onLogMessage(event)
            }
        }

        /**
         * mpv's own lines into the app's log ([MpvLog], redacted there: mpv names the URL it failed to open, and stream
         * URLs carry API keys). The lifecycle takes the line as it is, for the HTTP status and the error it names
         * (mpv-build's library hands them over before the end-file they explain).
         */
        private fun onLogMessage(message: MpvEvent.LogMessage) {
            val level = MpvLog.level(message.level.name)
            MpvLog.write(level, message.prefix, message.text)
            publish { logLine(message.text, error = level == AppLogLevel.ERROR, prefix = message.prefix, warning = level >= AppLogLevel.WARN) }
        }

        /**
         * mpv waits on [name] until [MpvPlayer.continueHook]. At `on_preloaded` the file's decode is routed, and a
         * decoder hold armed for it ([holdDecoder]) keeps the hook waiting while the display switches (the hold is taken
         * first, so an arm never outlives its file whatever the routing does).
         */
        override fun onHook(player: MpvPlayer, name: String, id: Long) {
            val queued = submit("hook $name") {
                val hold = if (name == "on_preloaded") decoderHolds.take() else null
                var held = false
                try {
                    val track = if (name == "on_preloaded") applyDecodeRouting(player) else null
                    if (hold != null && track != null) {
                        hold.answer(VideoInfo(track.width ?: 0, track.height ?: 0, track.codec, track.fps, DynamicRange.SDR))
                        continueAfterRelease(player, id, hold, track)
                        held = true
                    }
                } finally {
                    if (!held) {
                        hold?.let {
                            it.answer(null)
                            decoderHolds.finish(it)
                        }
                        player.continueHook(id)
                    }
                }
            }
            if (!queued) player.continueHook(id)
        }
    }

    // Last in the class body: the executor thread starts using this object once it is queued.
    init {
        submit("initialization") { initialize() }
        appContext.getSystemService(DisplayManager::class.java)?.registerDisplayListener(displayListener, Handler(Looper.getMainLooper()))
    }

    private fun PropertyChange.flag(): Boolean? = (this as? PropertyChange.Flag)?.value

    private fun PropertyChange.string(): String? = (this as? PropertyChange.Str)?.value
}

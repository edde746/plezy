package com.edde746.plezy.mpv

import com.edde746.plezy.data.settings.DolbyVisionConversion
import com.edde746.plezy.log.Log
import com.edde746.plezy.data.settings.DeviceSettings
import com.edde746.plezy.mpv.core.MpvCore
import com.edde746.plezy.mpv.ffi.MpvFfi
import com.edde746.plezy.mpv.ffi.mpv_event
import com.edde746.plezy.mpv.ffi.mpv_event_end_file
import com.edde746.plezy.mpv.ffi.mpv_event_log_message
import com.edde746.plezy.mpv.ffi.mpv_event_property
import com.edde746.plezy.mpv.os.utf8
import com.edde746.plezy.mpv.video.VideoHost
import com.edde746.plezy.mpv.video.WaylandVideoHost
import com.edde746.plezy.playback.AudioChannels
import com.edde746.plezy.playback.AudioState
import com.edde746.plezy.playback.AudioStateReconciler
import com.edde746.plezy.playback.DESKTOP_SCREENSHOT_DIRECTORY
import com.edde746.plezy.playback.Downmix
import com.edde746.plezy.playback.EngineError
import com.edde746.plezy.playback.EngineErrorKind
import com.edde746.plezy.playback.EngineFeatures
import com.edde746.plezy.playback.EngineState
import com.edde746.plezy.playback.HardwareDecoder
import com.edde746.plezy.playback.LOUDNESS_NORMALIZATION_FILTER
import com.edde746.plezy.playback.LoadRequest
import com.edde746.plezy.playback.PlayerEngine
import com.edde746.plezy.playback.PlayerEngineListener
import com.edde746.plezy.playback.STATS_INTERVAL_MS
import com.edde746.plezy.playback.SubtitleFrame
import com.edde746.plezy.playback.SubtitleStyle
import com.edde746.plezy.playback.TrackKind
import com.edde746.plezy.playback.VideoLayout
import com.edde746.plezy.playback.mpv.MpvAmbientLighting
import com.edde746.plezy.playback.mpv.MpvLifecycle
import com.edde746.plezy.playback.mpv.MpvLoad
import com.edde746.plezy.playback.mpv.MpvLog
import com.edde746.plezy.playback.mpv.MpvState
import com.edde746.plezy.playback.mpv.MpvStartup
import com.edde746.plezy.playback.mpv.MpvUserConfig
import java.awt.Window
import java.lang.foreign.MemorySegment
import java.lang.foreign.ValueLayout
import java.nio.file.Files
import java.nio.file.Path
import java.util.Locale
import java.util.concurrent.CompletableFuture
import java.util.concurrent.CountDownLatch
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit
import kotlin.time.Duration

/**
 * @param logFile mpv's debug log, redacted, for diagnostics and the remote harness ([MpvLogFile]); each engine starts
 *   it anew.
 * @param shaderCache where mpv keeps the GPU shaders it compiled (`gpu-shader-cache-dir`), created when missing; null
 *   for none (every playback compiles them again).
 * @param extraOptions more mpv options applied last, before mpv_initialize (e.g. `mute=yes` for unattended runs); they
 *   also win over a [LoadRequest]'s options of the same name.
 * @param settings this device's settings as the playback opens: debug logging, the stored audio output, the volume and
 *   its top ([MpvStartup]).
 * @param audioRecovery whether a lost audio output is reloaded and, after its budget, fails the file ([AudioRecovery]);
 *   off for a session that plays with no audio output at all (`ao=null`).
 */
data class MpvEngineOptions(
    val logFile: Path? = null,
    val shaderCache: Path? = null,
    val extraOptions: Map<String, String> = emptyMap(),
    val settings: DeviceSettings = DeviceSettings.DEFAULT,
    val audioRecovery: Boolean = true,
)

/**
 * [PlayerEngine] on libmpv for Windows and Linux.
 *
 * One `mpv` thread owns the handle: every call is queued to it and it alternates between running queued commands and
 * `mpv_wait_event` (woken by `mpv_wakeup`). Listener callbacks run on that thread. The core is created once the
 * platform video host is ready, which needs the window: put [MpvVideoSurface] in the UI. Calls made before that (the
 * first [load], [setPaused], track selection, speed/delay/volume/mute, the cache wait, the subtitle style) are kept and
 * applied then. Each file's lifecycle and the state mpv's properties make are the shared [MpvLifecycle]'s, which the
 * thread feeds mpv's events; while the playback info shows ([setStatsWanted]) the thread also reads the info's stats once
 * a second. The engine's own settings (the cache wait, the subtitle style, the picture's layout, the audio options and
 * output) carry across files; [load] also brings the file's `hwdec` and demuxer cache ([LoadRequest.options]). The
 * layout's properties follow the output's shape (`osd-dimensions`), so a stretch keeps
 * filling a resized window. [release] stops the thread and the file, lets the video host go, and runs
 * `mpv_terminate_destroy` on a throwaway thread holding nothing but the handle, since it can block on network teardown
 * (stop the event loop, drop the video host, terminate); that thread first waits for the host to let go
 * of the core ([VideoHost.awaitUnbound]), and leaves the core alive when it never may be destroyed.
 */
class MpvPlayerEngine internal constructor(
    private val options: MpvEngineOptions,
    internal val host: VideoHost,
) : PlayerEngine {
    constructor(options: MpvEngineOptions = MpvEngineOptions()) : this(options, VideoHost.forCurrentOs())

    /** The hardware decoder of this OS's video output, which a file's `hwdec` names while hardware decoding is on. */
    val hardwareDecoder: HardwareDecoder get() = host.hardwareDecoder

    private val commands = LinkedBlockingQueue<Command>()
    private val coreLock = Any()
    private val terminated = CountDownLatch(1)
    private val log = System.getLogger(MpvPlayerEngine::class.java.name)

    @Volatile private var listener: PlayerEngineListener? = null
    @Volatile private var released = false

    /** The latest state ([MpvLifecycle.state]), readable from any thread. */
    @Volatile var currentState: EngineState = EngineState()
        private set

    // mpv-thread state. [core] is also read under [coreLock] to wake the thread.
    private var core: MpvCore? = null
    private var stopped = false
    private var videoReady = false
    /** Why mpv or its video output can't work (no core, no canvas, a host that failed): each [load] fails with it. */
    private var videoFailure: EngineError? = null
    private var pendingLoad: LoadRequest? = null
    /** The viewer's pause: mpv's, but while the lifecycle holds for a display switch ([holdForDisplay]). */
    private var desiredPause = false
    private val pendingTracks = linkedMapOf<TrackKind, Long?>()
    private val pendingSubtitles = mutableListOf<List<String>>()
    /**
     * Player settings (speed, delays, the cache wait, the subtitle style and lift, volume, mute) set before the core
     * exists, applied as soon as it does.
     */
    private val startupSettings = linkedMapOf("volume" to num(MpvStartup.volume(options.settings)))

    /** The user's mpv.conf ([MpvUserConfig]): set after the engine's own options; a line wins over its later writes. */
    private val userConfig = MpvUserConfig.of(options.settings.mpvConfigText, linuxPlane = host is WaylandVideoHost)

    /** The top of the volume ([MpvStartup.volumeMax], or a mpv.conf line's): mpv's `volume-max`, which [setVolume] stays within. */
    private val volumeMax = userConfig["volume-max"]?.toDoubleOrNull() ?: MpvStartup.volumeMax(options.settings)

    /**
     * The latest subtitle style and the controls' lift, which `sub-pos` combines in the frame mpv places text subtitles
     * in: the window while the style lets them use its margins (or the picture runs past it), else the picture, from
     * `osd-dimensions` ([osdDimensions]).
     */
    private var subtitleStyle = SubtitleStyle.DEFAULT
    private var controlsLift = 0.0
    private var osdDimensions: String? = null

    /** The picture's layout, the output's shape (`osd-dimensions`) and the layout's properties as last written. */
    private var videoLayout = VideoLayout.DEFAULT
    private var surfaceAspect: Double? = null
    private val appliedLayout = HashMap<String, String>()

    /** The audio output, applied as soon as the core exists; null for mpv's own choice. */
    private var audioDevice: String? = null

    /**
     * The audio options, the Passthrough setting and the speed, applied in an order that never hands a bitstream to
     * the filter, a fold or another speed (mpv thread); recorded before the core exists and applied as it starts.
     * Passthrough offers every format mpv wraps for a receiver ([PASSTHROUGH_CODECS]) and claims the device
     * (`audio-exclusive`: WASAPI's exclusive mode, a PipeWire stream no other shares); a refused claim only warns.
     */
    private val audio = AudioStateReconciler(
        normalizationFilter = LOUDNESS_NORMALIZATION_FILTER,
        exclusiveHint = true,
        codecs = { PASSTHROUGH_CODECS.joinToString(",") },
        warn = { message, e -> log.log(System.Logger.Level.WARNING, "mpv $message", e) },
    ) { name, value ->
        val rc = checkNotNull(core).setString(name, value)
        if (rc < 0) throw IllegalStateException("mpv $name=$value: ${MpvCore.errorString(rc)}")
        if (name != "speed") log.log(System.Logger.Level.INFO, "{0}={1}", name, value.ifEmpty { "(none)" })
    }

    private var defaultColorspaceHint: String? = null
    /** The user's shader files, in order, as `glsl-shaders` ([setShaders]); kept for later files. */
    private var shaders = emptyList<String>()
    /** Ambient lighting on the core, once there is one ([setAmbientLighting]; mpv thread). */
    private val ambientLighting = MpvAmbientLighting(
        set = { name, value -> core?.setString(name, value)?.also { logIfFailed(name, it) }?.let { it >= 0 } ?: false },
        command = { args -> core?.command(*args.toTypedArray())?.also { logIfFailed(args.joinToString(" "), it) }?.let { it >= 0 } ?: false },
    )
    /** Each file's lifecycle and the state mpv's properties make; its hold is the display switch's ([holdForDisplay]). */
    private val lifecycle = MpvLifecycle()
    /** While true, a change keeps the state for the next publish ([takePendingBehindEndFile]). */
    private var holdingEmits = false
    /** The playback info shows ([setStatsWanted]): its stats are read when [nextStatsNanos] comes. */
    private var statsWanted = false
    private var nextStatsNanos = 0L
    /** When the audio output is reloaded: a device lost to `null`, a wake from sleep (mpv thread). */
    private val audioRecovery = if (options.audioRecovery) AudioRecovery() else null

    private val thread = Thread(::run, "mpv").apply { isDaemon = true; start() }

    /** Called by [MpvVideoSurface] on the UI thread until it returns true (the window's canvas exists). */
    internal fun attach(window: Window): Boolean = host.attach(window) { post(block = ::onHostReady) }

    /** Starts mpv for a [host] that needs no window (the libmpv tests' `vo=null`); [attach] does it for the UI. */
    internal fun startWithoutWindow() {
        post(block = ::onHostReady)
    }

    /**
     * [MpvVideoSurface] found no canvas for the video in its window within [waited] (Skiko's components changed): the
     * playback fails with that error instead of waiting forever.
     */
    internal fun attachTimedOut(waited: Duration) {
        post { if (core == null) failVideo("video host: the window's canvas wasn't found within $waited") }
    }

    override fun load(request: LoadRequest): Long {
        val id = lifecycle.nextLoadId()
        post {
            pendingSubtitles.clear()
            update {
                load(id)
                videoFailure?.let { fail(it) }
            }
            when {
                videoFailure != null -> {}
                videoReady -> startLoad(request)
                else -> pendingLoad = request
            }
        }
        return id
    }

    override fun setPaused(paused: Boolean) {
        post {
            desiredPause = paused
            val c = core
            when {
                // Held for a display switch: the release applies the choice.
                lifecycle.held -> update { hold(paused) }
                c != null -> logIfFailed("pause", c.setFlag("pause", paused))
                // Shown at once: the core starts with it, and reports it then.
                else -> update { flag("pause", paused) }
            }
        }
    }

    /**
     * Holds playback while the display switches mode ([held]), so the picture doesn't go blank under the sound: the
     * display matching's call, from any thread. mpv pauses and the state reports buffering, with [EngineState.paused]
     * the viewer's own; a pause or play asked for meanwhile ([setPaused]) is what the release leaves.
     */
    fun holdForDisplay(held: Boolean) {
        post {
            if (held == lifecycle.held) return@post
            core?.setFlag("pause", held || desiredPause)?.let { logIfFailed("pause", it) }
            update { if (held) hold(desiredPause) else endHold(desiredPause) }
        }
    }

    override fun seek(seconds: Double, exact: Boolean) {
        post {
            val c = core
            val pending = pendingLoad
            when {
                pending != null -> pendingLoad = pending.copy(startSeconds = seconds)
                c != null -> logIfFailed("seek", c.command("seek", num(seconds), if (exact) "absolute+exact" else "absolute+keyframes"))
            }
        }
    }

    /** Passthrough leaves before any speed but 1 and comes back after 1 ([audio]). */
    override fun setSpeed(speed: Double) {
        post {
            val request = audio.requestRate(speed)
            if (core != null) {
                reconcileAudio(request)
            } else {
                startupSettings["speed"] = num(speed)
                update { double("speed", speed) }
            }
        }
    }

    override fun setSubtitleDelay(seconds: Double) {
        setting("sub-delay", seconds)
        post { setAppProperty("secondary-sub-delay", num(seconds)) }
    }

    override fun setAudioDelay(seconds: Double) = setting("audio-delay", seconds)

    override fun setSubtitleLift(fraction: Double) {
        if (!fraction.isFinite()) return
        post {
            controlsLift = fraction
            applySubtitlePlacement()
        }
    }

    override fun setSubtitleStyle(style: SubtitleStyle) {
        post {
            subtitleStyle = style
            for ((name, value) in style.properties()) setAppProperty(name, value)
            applySubtitlePlacement()
        }
    }

    /**
     * `sub-use-margins` and `sub-pos` for the latest style, layout and controls (mpv thread): text subtitles use the
     * window's margins while the style lets them or the picture runs past the window, and are placed by the picture
     * otherwise.
     */
    private fun applySubtitlePlacement() {
        val margins = subtitleStyle.useMargins || videoLayout.overflows
        setAppProperty("sub-use-margins", yesNo(margins))
        val frame = if (margins) SubtitleFrame.SCREEN else MpvState.subtitleFrame(osdDimensions)
        setAppProperty("sub-pos", num(subtitleStyle.position(controlsLift, frame)))
    }

    /**
     * An app write (mpv thread): set now, or kept for the core while there is none; skipped where a line of the user's
     * mpv.conf sets [name] ([MpvUserConfig.appWrites]). False when mpv refused it.
     */
    private fun setAppProperty(name: String, value: String): Boolean {
        if (!userConfig.appWrites(name)) return true
        val c = core
        if (c == null) {
            startupSettings[name] = value
            return true
        }
        val rc = c.setString(name, value)
        logIfFailed(name, rc)
        return rc >= 0
    }

    override fun setVideoLayout(layout: VideoLayout) {
        post {
            videoLayout = layout
            core?.let(::applyVideoLayout)
            applySubtitlePlacement()
        }
    }

    /** The layout's properties for the output's shape, each written when it changes (mpv thread). */
    private fun applyVideoLayout(c: MpvCore) {
        for ((name, value) in videoLayout.properties(surfaceAspect)) {
            if (appliedLayout[name] == value) continue
            if (setAppProperty(name, value)) appliedLayout[name] = value
        }
    }

    override fun setAudioNormalization(enabled: Boolean) {
        post { reconcileAudio(audio.requestNormalization(enabled)) }
    }

    override fun setShaders(paths: List<String>) {
        post {
            shaders = paths
            core?.let(::applyShaders)
        }
    }

    /**
     * `glsl-shaders` as [shaders]: cleared, then each path appended, so no path needs the list's separator (`;` on
     * Windows, `:` elsewhere) escaped, and ambient lighting's shader last (mpv thread).
     */
    private fun applyShaders(c: MpvCore) {
        logIfFailed("glsl-shaders", c.command("change-list", "glsl-shaders", "clr", ""))
        for (path in shaders) logIfFailed("glsl-shaders", c.command("change-list", "glsl-shaders", "append", path))
        ambientLighting.afterShadersRebuilt()
    }

    override fun setAmbientLighting(shaderPath: String?) {
        post { ambientLighting.set(shaderPath) }
    }

    override fun setAudioChannels(channels: AudioChannels, downmix: Downmix) {
        post { reconcileAudio(audio.requestChannels(channels, downmix)) }
    }

    override fun setAudioDevice(name: String) {
        post {
            audioDevice = name
            core?.let { logIfFailed("audio-device", it.setString("audio-device", name)) }
        }
    }

    /**
     * The Passthrough setting (OutputPlan.audioPassthrough). Nothing tells the desktop which formats its output takes
     * undecoded, so mpv offers every one it can wrap for a receiver ([PASSTHROUGH_CODECS]) and decodes the audio when
     * the output doesn't open with the bitstream. In effect only while the audio is neither normalized, mixed down to
     * stereo nor played at another speed than 1 ([AudioState.passesThrough]). Whether the playing audio goes out
     * undecoded is [EngineState.audioPassthrough].
     */
    fun setAudioPassthrough(enabled: Boolean) {
        post { reconcileAudio(audio.requestPassthrough(enabled)) }
    }

    /** Applies an audio [request] once the core exists (mpv thread); a write mpv refuses is rolled back and logged. */
    private fun reconcileAudio(request: AudioStateReconciler.Request) {
        if (core == null) return
        try {
            audio.reconcile(request)
        } catch (e: Exception) {
            log.log(System.Logger.Level.WARNING, "mpv audio options refused", e)
        }
    }

    override fun setStatsWanted(wanted: Boolean) {
        post {
            statsWanted = wanted
            if (wanted) {
                readStats()
            } else {
                update { stats(null) }
            }
        }
    }

    override fun setVolume(volume: Double) = setting("volume", volume.coerceIn(0.0, volumeMax))

    override fun setMuted(muted: Boolean) {
        post {
            val c = core
            if (c != null) {
                logIfFailed("mute", c.setFlag("mute", muted))
            } else {
                startupSettings["mute"] = yesNo(muted)
                update { flag("mute", muted) }
            }
        }
    }

    /**
     * The display's refresh rate after the app switched the display's mode (display matching), or null for mpv's own
     * reading (`display-fps-override`). mpv reads the rate again only when its window's monitor changes or its window
     * gets WM_DISPLAYCHANGE, which Windows sends to top-level windows only; mpv's window here is a child window.
     */
    fun setDisplayFps(fps: Double?) {
        post {
            val value = String.format(Locale.ROOT, "%.6f", fps ?: 0.0)
            val c = core
            if (c != null) logIfFailed("display-fps-override", c.setString("display-fps-override", value)) else startupSettings["display-fps-override"] = value
        }
    }

    /**
     * Whether mpv may present HDR, as the output plan has it (OutputPlan.hdrOutput, the player's HDR switch one of its
     * inputs). Off, it keeps an SDR swapchain (`target-colorspace-hint=no`) and tone-maps HDR video to SDR, even where
     * the display's HDR is on; on, mpv's default (HDR passthrough where the display is in HDR mode). On Wayland the
     * video plane decides with the compositor, per source ([VideoHost]). HDR asked of an output that can't carry it
     * ([VideoHost.carriesHdr]) is refused; otherwise mpv's write answers (before mpv starts, it is kept for its start).
     */
    override fun setHdrOutput(enabled: Boolean, onResult: (applied: Boolean) -> Unit) {
        if (enabled && !host.carriesHdr) return onResult(false)
        if (host.setHdrOutput(enabled)) return onResult(true)
        post({ onResult(false) }) {
            val hint = if (enabled) defaultColorspaceHint ?: "auto" else "no"
            if (core == null && enabled) {
                startupSettings.remove("target-colorspace-hint")
                onResult(true)
            } else {
                // Through the app-write helper: a line of the user's mpv.conf keeps its value.
                onResult(setAppProperty("target-colorspace-hint", hint))
            }
        }
    }

    /** Who tone-maps HDR shown as HDR on Wayland: mpv, to the display's peak ([player]), or the compositor (default). */
    fun setHdrToneMapping(player: Boolean) = host.setToneMapping(player)

    /** The video output's state (the Wayland plane's frames, buffer depth, HDR decision), for diagnostics. */
    fun videoOutputStats(): Map<String, Any?> = host.stats()

    /**
     * Where SDR video's white sits in an HDR (PQ) output, in whole cd/m² (`hdr-reference-white`), or null for mpv's
     * 203. The desktop's own SDR white (Windows' SDR content brightness) shows SDR video as bright as the controls over
     * it and every other window; mpv 0.41 doesn't read it itself (a later mpv's `auto` does).
     */
    fun setSdrWhite(nits: Double?) {
        post {
            val value = nits?.let { Math.round(it).toString() } ?: "auto"
            val c = core
            if (c != null) logIfFailed("hdr-reference-white", c.setString("hdr-reference-white", value)) else startupSettings["hdr-reference-white"] = value
        }
    }

    /**
     * Sets a numeric player property, one of [MpvLifecycle.DOUBLES]. Once the core exists the observed property reports
     * the applied value; before that the value is kept for the new core and shown in the state right away.
     */
    private fun setting(property: String, value: Double) {
        post {
            val c = core
            if (c != null) {
                logIfFailed(property, c.setDouble(property, value))
            } else {
                startupSettings[property] = num(value)
                update { double(property, value) }
            }
        }
    }

    override fun selectTrack(kind: TrackKind, id: Long?) {
        post {
            val c = core
            if (c == null) pendingTracks[kind] = id else applyTrack(c, kind, id)
        }
    }

    override fun selectSecondSubtitle(id: Long?) {
        post { setAppProperty("secondary-sid", id?.toString() ?: "no") }
    }

    override fun screenshot(onResult: (saved: Boolean) -> Unit) {
        post({ onResult(false) }) {
            val c = core
            val rc = if (c == null || !lifecycle.isFileLoaded) -1 else c.command("screenshot", "subtitles")
            logIfFailed("screenshot", rc)
            onResult(rc >= 0)
        }
    }

    override fun stop() {
        post { core?.let { logIfFailed("stop", it.command("stop")) } }
    }

    override fun subtitleSeek(forward: Boolean) {
        post {
            val c = core
            if (c != null && lifecycle.isFileLoaded) logIfFailed("sub-seek", c.command("sub-seek", if (forward) "1" else "-1"))
        }
    }

    /** The outputs are listed (`audio-device-list`); the HDR switch where the output can carry HDR ([VideoHost.carriesHdr]). */
    override val features: EngineFeatures get() = EngineFeatures(hdrControl = host.carriesHdr, audioDevices = true)


    /** mpv on the desktop has no Dolby Vision conversion of its own. */
    override fun setDolbyVisionConversion(mode: DolbyVisionConversion) = Unit

    override fun addSubtitle(url: String, title: String?, lang: String?) {
        post {
            // "auto" adds without changing the selection; selectTrack picks it.
            val args = listOf("sub-add", url, "auto", title.orEmpty(), lang.orEmpty())
            val c = core
            if (c == null || !lifecycle.isFileLoaded) pendingSubtitles += args else logIfFailed("sub-add", c.command(*args.toTypedArray()))
        }
    }

    override fun setListener(listener: PlayerEngineListener?) {
        this.listener = listener
        if (listener != null) {
            post {
                lifecycle.republish()
                emit()
            }
        }
    }

    override fun release() {
        listener = null
        post(block = ::shutdown)
    }

    /** Waits until [release] has finished (mpv_terminate_destroy returned, or the core was left alive); false on timeout. */
    fun awaitReleased(timeout: Duration): Boolean = terminated.await(timeout.inWholeMilliseconds, TimeUnit.MILLISECONDS)

    /** The system woke from sleep: the audio output is reloaded, twice ([AudioRecovery]). Any thread. */
    fun onSystemResume() {
        post { audioRecovery?.requestResume() }
    }

    /**
     * Reads mpv properties as strings (null when unavailable), for diagnostics and test reports. Blocks until the
     * mpv thread answers; never call it from a listener callback.
     */
    fun properties(names: List<String>, timeoutMs: Long = 2000): Map<String, String?> {
        val result = CompletableFuture<Map<String, String?>>()
        val none = names.associateWith { null }
        post({ result.complete(none) }) { result.complete(core?.let { c -> names.associateWith { c.getString(it) } } ?: none) }
        return runCatching { result.get(timeoutMs, TimeUnit.MILLISECONDS) }.getOrDefault(none)
    }

    // ---- mpv thread ----------------------------------------------------------------------------------------------

    /** A queued [block], and what answers its caller instead when the thread ends before running it. */
    private class Command(val rejected: () -> Unit, val block: () -> Unit)

    private fun post(rejected: () -> Unit = {}, block: () -> Unit) {
        if (released) return rejected()
        val command = Command(rejected, block)
        commands.add(command)
        // The thread may have ended between the check and the add: then it is this call's to reject, unless the
        // thread's last drain took it.
        if (released && commands.remove(command)) return rejected()
        synchronized(coreLock) { core?.wakeup() }
    }

    private fun run() {
        while (!stopped) {
            val c = core
            if (c == null) {
                guarded("command", commands.take().block)
                continue
            }
            while (!stopped) guarded("command", (commands.poll() ?: break).block)
            if (stopped || core == null) continue
            guarded("event") {
                handleEvent(c.waitEvent(waitTimeoutSeconds()))
                if (statsWanted && System.nanoTime() >= nextStatsNanos) readStats()
                runAudioRecovery(c)
            }
        }
        // What was queued behind the release never runs.
        while (true) guarded("command", (commands.poll() ?: break).rejected)
    }

    /**
     * The playback info's stats, read now and next in [STATS_INTERVAL_NANOS] (mpv thread). They are polled rather than
     * observed: mpv re-reads the bitrates and the late-frame count on every tick for an observer.
     */
    private fun readStats() {
        val c = core ?: return
        nextStatsNanos = System.nanoTime() + STATS_INTERVAL_NANOS
        val display = MpvState.DisplayMode(
            width = c.getDouble("display-width")?.toInt(),
            height = c.getDouble("display-height")?.toInt(),
            refreshRate = c.getDouble("display-fps"),
        )
        val reading = MpvState.stats(text = c::getString, number = c::getDouble, display = display)
        update { stats(reading) }
    }

    /** One turn of the mpv thread: what fails in it (a listener, a reply it can't read) is logged, and the thread goes on. */
    private inline fun guarded(what: String, block: () -> Unit) {
        try {
            block()
        } catch (t: Throwable) {
            log.log(System.Logger.Level.ERROR, "mpv $what failed", t)
        }
    }

    private fun onHostReady() {
        if (stopped || core != null) return
        val c = try {
            MpvCore.create(baseOptions() + host.options() + options.extraOptions + ("pause" to yesNo(desiredPause || lifecycle.held)), ::setUp)
        } catch (t: Throwable) {
            failVideo(t.message ?: t.toString())
            return
        }
        synchronized(coreLock) { core = c }
        for ((kind, id) in pendingTracks) applyTrack(c, kind, id)
        pendingTracks.clear()
        applyVideoLayout(c)
        if (shaders.isNotEmpty()) applyShaders(c)
        reconcileAudio(audio.requestAll())
        audioDevice?.let { logIfFailed("audio-device", c.setString("audio-device", it)) }
        // The user's mpv.conf follows here; the app's volume top after it.
        logIfFailed("volume-max", c.setDouble("volume-max", volumeMax))
        host.bind(c) { error -> post { onVideoReady(error) } }
    }

    /**
     * Readies a new core (mpv thread): its log file, the settings made before it, and the properties ([OBSERVED]) and
     * warnings this engine follows. An observation or a log level mpv refuses throws, which fails the core.
     */
    private fun setUp(c: MpvCore) {
        options.logFile?.let { MpvLogFile.start(c, it) }
        defaultColorspaceHint = c.getString("target-colorspace-hint")
        // The device's settings first; the stored output where mpv lists it, unless the player already chose one.
        for ((name, value) in MpvStartup.properties(options.settings, desktop = true)) logIfFailed(name, c.setString(name, value))
        if (audioDevice == null) MpvStartup.preferredAudioDevice(options.settings, c.getString("audio-device-list"))?.let { audioDevice = it }
        // The user's mpv.conf after the engine's own options; every later app write yields to it (setAppProperty).
        for ((name, value) in userConfig.options) logIfFailed("mpv.conf line $name=$value", c.setString(name, value))
        // The volume's top before the volume, which mpv keeps within it.
        if (userConfig.appWrites("volume-max")) logIfFailed("volume-max", c.setDouble("volume-max", volumeMax))
        // As properties, so a value mpv rejects is logged like a live call instead of failing the core. Test and
        // diagnostic extraOptions win over them (a test's mute=yes stays muted).
        val pending = startupSettings.filterKeys { it !in options.extraOptions && userConfig.appWrites(it) }
        startupSettings.clear()
        for ((name, value) in pending) logIfFailed(name, c.setString(name, value))
        for ((i, p) in OBSERVED.withIndex()) c.observe(i.toLong(), p.first, p.second)
        c.requestLogMessages(MpvStartup.logLevel(options.settings.debugLogging))
    }

    /** The host's answer to [VideoHost.bind]: null once a file may load, else why video can't work, even after that. */
    private fun onVideoReady(error: String?) {
        if (stopped) return
        if (error != null) {
            failVideo("video output: $error", EngineErrorKind.DECODE)
            return
        }
        videoReady = true
        pendingLoad?.let(::startLoad)
        pendingLoad = null
    }

    /**
     * The file's values as properties ([MpvLoad]), then a plain loadfile: the files mpv opens from this one's playlist
     * keep them. A value ([MpvLoad.refusalFailsLoad]) or loadfile mpv refuses refuses the load ([refuse]): nothing
     * replaces the file playing. A refused playback default is only logged.
     */
    private fun startLoad(request: LoadRequest) {
        val c = core ?: return
        // The device's decoding and cache options are written only when they change: a `hwdec` write re-creates the
        // playing file's decoder. A test's own --mpv-opt or a line of the user's mpv.conf of the same name wins.
        val decoding = MpvLoad.decodingOptions(request.options, request.live).filter { (name, value) -> name !in options.extraOptions && c.getString(name) != value }
        val values = userConfig.yielding(decoding + MpvLoad.fileProperties(request)) + ("http-header-fields" to MpvLoad.headerFields(request.headers))
        for ((name, value) in values) {
            val rc = c.setString(name, value)
            if (rc < 0 && MpvLoad.refusalFailsLoad(name)) return refuse(name, rc)
            logIfFailed(name, rc)
        }
        val rc = c.command("loadfile", request.url, "replace")
        if (rc < 0) refuse("loadfile", rc)
    }

    /**
     * mpv refused [what] of the load with [rc]: the load fails with mpv's reason, then the file mpv plays on is current
     * again ([MpvLifecycle.keepOutgoing]).
     */
    private fun refuse(what: String, rc: Int) {
        update { fail(EngineError("$what: ${MpvCore.errorString(rc)}", kind = MpvState.errorKind(rc))) }
        update { keepOutgoing() }
    }

    private fun applyTrack(c: MpvCore, kind: TrackKind, id: Long?) {
        val property = when (kind) {
            TrackKind.VIDEO -> "vid"
            TrackKind.AUDIO -> "aid"
            TrackKind.SUBTITLE -> "sid"
        }
        logIfFailed(property, c.setString(property, id?.toString() ?: "no"))
    }

    private fun handleEvent(ev: MemorySegment) {
        when (mpv_event.event_id(ev)) {
            MpvFfi.MPV_EVENT_PROPERTY_CHANGE() -> onProperty(mpv_event.reply_userdata(ev), mpv_event.data(ev))
            MpvFfi.MPV_EVENT_START_FILE() -> update { startFile() }
            MpvFfi.MPV_EVENT_FILE_LOADED() -> {
                update { fileLoaded() }
                audioRecovery?.setFileLoaded(true, nowMillis())
                val c = core
                if (c != null) for (args in pendingSubtitles) logIfFailed("sub-add", c.command(*args.toTypedArray()))
                pendingSubtitles.clear()
            }
            MpvFfi.MPV_EVENT_PLAYBACK_RESTART() -> {
                host.playbackRestarted()
                update { playbackRestart() }
            }
            MpvFfi.MPV_EVENT_END_FILE() -> {
                val end = mpv_event.data(ev)
                val reason = mpv_event_end_file.reason(end)
                val code = mpv_event_end_file.error(end)
                // The log lines that explain a failure wait behind its end-file: taken first, so the error goes out with them.
                val next = if (reason == MpvFfi.MPV_END_FILE_REASON_ERROR()) core?.let(::takePendingBehindEndFile) else null
                update { endFile(reason, code, MpvCore.errorString(code)) }
                audioRecovery?.setFileLoaded(false, nowMillis())
                next?.let(::handleEvent)
            }
            // mpv names the URL it failed to open ("Failed to open <url>."), and stream URLs carry API keys: the
            // line goes to the app's log redacted ([MpvLog]), to the lifecycle as it is (the HTTP status, the error it names).
            MpvFfi.MPV_EVENT_LOG_MESSAGE() -> {
                val m = mpv_event.data(ev)
                val text = mpv_event_log_message.text(m).utf8().orEmpty().trimEnd()
                val prefix = mpv_event_log_message.prefix(m).utf8().orEmpty()
                val level = MpvLog.level(mpv_event_log_message.level(m).utf8().orEmpty())
                update { logLine(text, error = level == Log.Level.ERROR, prefix = prefix, warning = level >= Log.Level.WARN) }
                MpvLog.write(level, prefix, text)
            }
            MpvFfi.MPV_EVENT_SHUTDOWN() -> shutdown()
        }
    }

    /**
     * Takes what mpv has pending behind an error end-file, without blocking, up to the first event that starts or ends
     * a file, which comes back unhandled (null once nothing is pending); the state it changes goes out with the error,
     * not before it. mpv buffers a client's log lines apart from its events and hands out queued events and property
     * changes first (`mpv_wait_event`), so the lines explaining a failed open (FFmpeg's "HTTP error 404 Not Found"),
     * logged before the end-file was posted, still wait behind it when this thread was busy as the open failed (a
     * listener callback, a stats read). mpv-build's Android library takes them the same way.
     */
    private fun takePendingBehindEndFile(c: MpvCore): MemorySegment? {
        holdingEmits = true
        try {
            while (true) {
                val ev = c.waitEvent(0.0)
                when (mpv_event.event_id(ev)) {
                    MpvFfi.MPV_EVENT_NONE() -> return null
                    MpvFfi.MPV_EVENT_START_FILE(), MpvFfi.MPV_EVENT_FILE_LOADED(), MpvFfi.MPV_EVENT_PLAYBACK_RESTART(),
                    MpvFfi.MPV_EVENT_END_FILE(), MpvFfi.MPV_EVENT_SHUTDOWN() -> return ev
                    else -> handleEvent(ev)
                }
            }
        } finally {
            holdingEmits = false
        }
    }

    private fun onProperty(id: Long, p: MemorySegment) {
        val (name, _) = OBSERVED.getOrNull(id.toInt()) ?: return
        val data = mpv_event_property.data(p)
        val format = mpv_event_property.format(p)
        val string = if (format == MpvFfi.MPV_FORMAT_STRING() && data.address() != 0L) data.get(ValueLayout.ADDRESS, 0).utf8() else null
        when (name) {
            "current-ao" -> audioRecovery?.setOutput(string, nowMillis())
            "audio-device-list" -> {
                audioRecovery?.onDeviceListChanged(nowMillis())
                update { if (string != null) text(name, string) else unavailable(name) }
            }
            "osd-dimensions" -> {
                osdDimensions = string
                val aspect = MpvState.surfaceAspect(string)
                if (aspect != surfaceAspect) {
                    surfaceAspect = aspect
                    core?.let(::applyVideoLayout)
                }
                if (!subtitleStyle.useMargins && !videoLayout.overflows) applySubtitlePlacement()
            }
            "video-target-params" -> update { outputRange(MpvState.outputRange(string)) }
            "video-params" -> {
                host.videoParams(string)
                ambientLighting.onVideoParams(MpvState.displayAspect(string))
                update { if (string != null) text(name, string) else unavailable(name) }
            }
            else -> update {
                when {
                    format == MpvFfi.MPV_FORMAT_DOUBLE() && data.address() != 0L -> double(name, data.get(ValueLayout.JAVA_DOUBLE, 0))
                    format == MpvFfi.MPV_FORMAT_FLAG() && data.address() != 0L -> flag(name, data.get(ValueLayout.JAVA_INT, 0) != 0)
                    string != null -> text(name, string)
                    else -> unavailable(name)
                }
            }
        }
    }

    /** Applies [change] to the lifecycle (mpv thread) and publishes what is due ([emit]). */
    private inline fun update(change: MpvLifecycle.() -> Unit) {
        lifecycle.change()
        currentState = lifecycle.state
        emit()
    }

    /** Hands the listener what is due ([MpvLifecycle.publishable]), unless held behind an end-file ([holdingEmits]). */
    private fun emit() {
        if (holdingEmits) return
        lifecycle.publishable()?.let { listener?.onState(it) }
    }

    /** How long mpv_wait_event may block: until the next stats reading or audio reload is due, else until woken. */
    private fun waitTimeoutSeconds(): Double {
        val stats = if (statsWanted) (nextStatsNanos - System.nanoTime()).coerceAtLeast(0) / 1e9 else null
        val audio = audioRecovery?.nextDueAt()?.let { (it - nowMillis()).coerceAtLeast(0) / 1e3 }
        return listOfNotNull(stats, audio).minOrNull() ?: -1.0
    }

    /**
     * Reloads the audio output when [audioRecovery] says so (mpv thread); its give-up stops the file and fails it as
     * the audio output's ([EngineErrorKind.AUDIO_OUTPUT]).
     */
    private fun runAudioRecovery(c: MpvCore) {
        when (val action = audioRecovery?.next(nowMillis()) ?: return) {
            is AudioRecovery.Action.Reload -> {
                log.log(System.Logger.Level.WARNING, "audio-recovery: ao-reload ({0}, attempt {1})", action.reason, action.attempt)
                logIfFailed("ao-reload", c.command("ao-reload"))
            }
            AudioRecovery.Action.GiveUp -> {
                log.log(System.Logger.Level.WARNING, "audio-recovery: the audio output stayed null; stopping the file")
                logIfFailed("stop", c.command("stop"))
                val message = "audio output failed: no audio device took the audio after ${AudioRecovery.NULL_BUDGET} reloads"
                update { fail(EngineError(message, kind = EngineErrorKind.AUDIO_OUTPUT)) }
            }
        }
    }

    private fun nowMillis() = System.nanoTime() / 1_000_000

    /** Fails the playback for good: with no mpv or no video output, this load and every later one ([videoFailure]). */
    private fun failVideo(message: String, kind: EngineErrorKind = EngineErrorKind.OTHER) {
        val error = EngineError(message, kind = kind)
        videoFailure = error
        pendingLoad = null
        update { fail(error) }
    }

    private fun logIfFailed(what: String, rc: Int) {
        if (rc < 0) log.log(System.Logger.Level.WARNING, "mpv {0}: {1}", what, MpvCore.errorString(rc))
    }

    private fun shutdown() {
        if (stopped) return
        stopped = true
        released = true
        listener = null
        val c = core
        synchronized(coreLock) { core = null }
        if (c == null) {
            host.close()
            terminated.countDown()
            return
        }
        // Nothing plays on while the host lets go, however long that takes (a Linux window that doesn't draw).
        logIfFailed("stop", c.command("stop"))
        host.unbind(c)
        host.close()
        Thread({
            try {
                // Never under a render context still on the core: libmpv needs it freed first.
                if (host.awaitUnbound()) c.terminateDestroy()
            } finally {
                terminated.countDown()
            }
        }, "mpv-terminate").apply { isDaemon = true; start() }
    }

    /** The desktop's own startup options; [MpvCore.create] sets every engine's (`COMMON_MPV_OPTIONS`) before them. */
    private fun baseOptions(): Map<String, String> = linkedMapOf(
        // With no audio device that opens, mpv plays on as with ao=null.
        "audio-fallback-to-null" to "yes",
        "screenshot-directory" to DESKTOP_SCREENSHOT_DIRECTORY,
    ).apply {
        options.shaderCache?.let { put("gpu-shader-cache-dir", Files.createDirectories(it).toString()) }
        // The app's subtitle fonts, every script but none of the system's needed.
        putAll(SubtitleFonts.options())
    }

    private companion object {
        /** How often the stats are read while they are wanted. */
        const val STATS_INTERVAL_NANOS = STATS_INTERVAL_MS * 1_000_000

        /**
         * Observed properties, [MpvLifecycle]'s and the desktop's own; the index is the reply_userdata. Node properties
         * come as their JSON text (MPV_FORMAT_STRING), which [MpvState] reads.
         */
        val OBSERVED: List<Pair<String, Int>> = MpvLifecycle.DOUBLES.map { it to MpvFfi.MPV_FORMAT_DOUBLE() } +
            MpvLifecycle.FLAGS.map { it to MpvFfi.MPV_FORMAT_FLAG() } +
            (MpvLifecycle.TEXTS + MpvLifecycle.AUDIO_DEVICE_TEXTS).map { it to MpvFfi.MPV_FORMAT_STRING() } +
            listOf(
                // The output's shape, which a stretched picture takes.
                "osd-dimensions" to MpvFfi.MPV_FORMAT_STRING(),
                // The colour space mpv renders to for the display: what the display gets (HDR or SDR).
                "video-target-params" to MpvFfi.MPV_FORMAT_STRING(),
                // The audio output in use: `null` once mpv fell back from a device that failed (AudioRecovery).
                "current-ao" to MpvFfi.MPV_FORMAT_STRING(),
            )

        fun num(v: Double) = String.format(Locale.ROOT, "%.3f", v)
        fun yesNo(v: Boolean) = if (v) "yes" else "no"

        /** Every format mpv wraps for a receiver, by its `audio-spdif` names: what passthrough offers here. */
        val PASSTHROUGH_CODECS = listOf("ac3", "eac3", "dts", "dts-hd", "truehd")
    }
}

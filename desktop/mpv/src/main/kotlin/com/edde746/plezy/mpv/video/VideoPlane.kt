package com.edde746.plezy.mpv.video

import com.edde746.plezy.mpv.core.MpvCore
import com.edde746.plezy.mpv.ffi.MpvFfi
import com.edde746.plezy.mpv.ffi.mpv_opengl_fbo
import com.edde746.plezy.mpv.ffi.mpv_opengl_init_params
import com.edde746.plezy.mpv.ffi.mpv_render_param
import com.edde746.plezy.mpv.ffi.mpv_render_update_fn
import com.edde746.plezy.mpv.os.Egl
import com.edde746.plezy.mpv.os.Gles
import com.edde746.plezy.mpv.os.Posix
import com.edde746.plezy.mpv.os.Protocols
import com.edde746.plezy.mpv.os.QueueWait
import com.edde746.plezy.mpv.os.Wl
import com.edde746.plezy.mpv.video.hdr.CompositorColorSupport
import com.edde746.plezy.mpv.video.hdr.CompositorLuminanceSupport
import com.edde746.plezy.mpv.video.hdr.HdrDecision
import com.edde746.plezy.mpv.video.hdr.HdrInputs
import com.edde746.plezy.mpv.video.hdr.HdrMetadata
import com.edde746.plezy.mpv.video.hdr.HdrToneMapping
import com.edde746.plezy.mpv.video.hdr.OutputColour
import com.edde746.plezy.mpv.video.hdr.SourceTransfer
import com.edde746.plezy.mpv.video.hdr.bufferExtent
import com.edde746.plezy.mpv.video.hdr.bufferScale
import com.edde746.plezy.mpv.video.hdr.decideHdr
import com.edde746.plezy.mpv.video.hdr.describeTonemappedTo
import com.edde746.plezy.mpv.video.hdr.outputHasHdrHeadroom
import com.edde746.plezy.mpv.video.hdr.planHdrLuminance
import com.edde746.plezy.mpv.video.hdr.sourceIsDescribable
import java.lang.foreign.Arena
import java.lang.foreign.MemorySegment
import java.lang.foreign.ValueLayout
import java.util.Locale
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock

/**
 * mpv's video on a Wayland subsurface stacked below a window's own surface: the window draws the UI with alpha, and
 * the video shows wherever the UI is transparent. The plane has an empty input region (every pointer event goes to the
 * window), an opaque region over all of it, its own EGL window surface and OpenGL ES 3 context, and a viewport, so its
 * buffer is the video's size in the output's pixels at any desktop scale: at the output's own scale where the compositor
 * says it (fractional-scale-v1; 1.15 at 115 %, where the window draws at 2), as [bufferScale] picks.
 *
 * Threads: [create] and the geometry calls ([setRect], [setVisible], [parentFrame]) run on the UI thread; everything
 * else (the plane's private event queue, EGL, mpv's render API, the colour management) on the plane's own [PlaneLoop].
 * Every request that changes the plane surface's committed state holds [surfaceLock], so a UI-side geometry change never
 * lands between a frame request and the commit of the frame it paces.
 *
 * Presentation is paced by the surface's own frame callbacks with a swap interval of 0: a frame is presented only when
 * mpv has a new one (or the plane owes a redraw: a new size, shown again, a colour change), and the very first present
 * waits for mpv's first frame. An occluded surface gets no frame callbacks, so a frame not acknowledged within 500 ms
 * is given up on; after five misses in a row the plane re-presents at most once a second until the compositor answers.
 *
 * A size change switches the plane to synchronized mode and stages the new viewport destination, so the window's next
 * commit applies the new window size and the new video size together; the plane goes back to desynchronized once a
 * frame at the new size has been carried by a window commit. Each frame presented in synchronized mode asks the window
 * for a commit ([commitParent]): the window commits only when it paints, and with Compose drawing on its own layer it
 * may not paint for a long time.
 *
 * HDR: the plane is described to the compositor (color-management-v1, parametric PQ or HLG over BT.2020) only when the
 * app allows it, this client can describe it (the compositor advertises the parametric creator, the perceptual intent,
 * BT.2020 and an HDR curve, and the plane got a 10-bit or fp16 config), the output has headroom above SDR white, and the
 * source itself is PQ or HLG in BT.2020 ([decideHdr]). A change is one transaction ([applyHdr]): the description is
 * created and validated first, then mpv's output colour is switched ([OutputColour]), and only then is the description
 * attached, committed together with mpv's first frame in the new colour space. A failure anywhere leaves both halves as
 * they were, or both in SDR.
 */
internal class VideoPlane private constructor(
    private val display: MemorySegment,
    private val parent: MemorySegment,
    /** Asks the window for a commit soon (any thread), which carries the plane's synchronized state. */
    private val commitParent: () -> Unit,
) {
    private val queue = Wl.createQueue(display)
    private val displayWrapper = Wl.wrapper(display, queue)
    private val registry = Wl.globals(displayWrapper, ::global)
    private val wakeFd = Posix.eventFd()
    private val events = QueueWait(Wl.eventQueue(display, queue), wakeFd, "video plane")
    private val log = System.getLogger(VideoPlane::class.java.name)

    // Globals.
    private var compositor = MemorySegment.NULL
    private var subcompositor = MemorySegment.NULL
    private var viewporter = MemorySegment.NULL
    private var fractionalScaleManager = MemorySegment.NULL
    private var colorManager = MemorySegment.NULL
    private val outputs = HashMap<Long, Output>()

    private class Output(val proxy: MemorySegment) {
        var refreshMilliHz = 0
    }

    // What the compositor's colour manager advertised.
    private var parametric = false
    private var perceptual = false
    private var mastering = false
    private var extendedTargetVolume = false
    private var pq = false
    private var hlg = false
    private var bt2020 = false

    // The plane's objects.
    private var surface = MemorySegment.NULL
    private var subsurface = MemorySegment.NULL
    private var viewport = MemorySegment.NULL
    private var fractionalScale = MemorySegment.NULL
    private var colorSurface = MemorySegment.NULL
    private var feedback = MemorySegment.NULL
    private var eglWindow = MemorySegment.NULL

    // EGL.
    private var eglDisplay = MemorySegment.NULL
    private var eglConfig = MemorySegment.NULL
    private var eglContext = MemorySegment.NULL
    private var eglSurface = MemorySegment.NULL
    /** Bits per colour channel of the plane's buffer: 10 (unorm), 16 (float) or 8. */
    var depthBits = 8
        private set

    private val loop = PlaneLoop("video-plane", ::turn, ::waitForEvents) { Posix.signal(wakeFd) }
    private val surfaceLock = ReentrantLock()
    @Volatile private var destroyed = false

    // Geometry (under surfaceLock): logical units in the window's surface, the buffer in physical pixels at the window's
    // scale or the output's own (bufferScale).
    private var x = Int.MIN_VALUE
    private var y = Int.MIN_VALUE
    private var width = 0
    private var height = 0
    private var bufferWidth = 0
    private var bufferHeight = 0
    private var hasRect = false
    private var surfaceScale = 1.0
    /** The compositor's preferred scale for the plane (the output it is on), fractional; null until it says one. */
    @Volatile private var outputScale: Double? = null
    private var visible = true
    private var syncMode = false
    private var resizeSerial = 0L
    private var resizedFrameSerial = -1L
    private var parentFramesSinceResizedFrame = 0

    // Plane thread.
    private var core: MpvCore? = null
    private var render = MemorySegment.NULL
    private var renderArena: Arena? = null
    private val mpvUpdate = AtomicBoolean(false)
    private val forceRender = AtomicBoolean(false)
    private var frameReady = false
    private var frameCallback = MemorySegment.NULL
    private var frameSentNanos = 0L
    private var frameAckMisses = 0
    private var presentedWidth = 0
    private var presentedHeight = 0
    private var outputRefresh = 0

    /** mpv's first frame is on screen; until then the UI shows black where the video goes. */
    @Volatile var firstFramePresented = false
        private set

    @Volatile var frames = 0L
        private set

    // The compositor's preferred description for the plane (the output it is on).
    private class Preferred(
        var valid: Boolean = false,
        var tf: Long = 0,
        var primaries: Long = 0,
        var reference: Long = 0,
        var targetMinScaled: Long = 0,
        var targetMax: Long = 0,
    )

    @Volatile private var preferred = Preferred()
    private var pendingPreferred = Preferred()
    private var preferredDescription = MemorySegment.NULL
    private var preferredInfo = MemorySegment.NULL

    // HDR: what the app allows and asks for (any thread), what the source is (mpv thread), what is in force (plane thread).
    @Volatile private var hdrAllowed = false
    @Volatile private var toneMapping = HdrToneMapping.COMPOSITOR
    @Volatile private var source = HdrMetadata()
    private val hdrReapply = AtomicBoolean(false)
    @Volatile var hdrActive = false
        private set
    private var activeDescription = HdrMetadata()
    private var appliedTargetPeak = 0L
    @Volatile private var lastHdrDecision: HdrDecision? = null
    private var stagedDescription = MemorySegment.NULL
    private var stagedState = Staged.NONE
    private var stagedError: String? = null
    private var outputColour: OutputColour? = null

    private enum class Staged { NONE, PENDING, READY, FAILED }

    /**
     * This client can describe an HDR plane at all: the compositor advertises what an HDR description needs, and the
     * plane got a deep (10-bit or fp16) config. Whether the output is in HDR is [outputIsHdr].
     */
    var supportsHdr = false
        private set

    /** The output the plane is on shows highlights above SDR white ([outputHasHdrHeadroom]). */
    val outputIsHdr: Boolean get() = preferred.let { it.valid && outputHasHdrHeadroom(it.targetMax, it.reference) }

    private fun create() {
        // The globals, then what the colour manager and the outputs announce on binding.
        check(Wl.roundtrip(display, queue) >= 0 && Wl.roundtrip(display, queue) >= 0) { "the Wayland connection failed" }
        if (compositor.address() == 0L || subcompositor.address() == 0L || viewporter.address() == 0L) {
            error("the compositor lacks wl_subcompositor or wp_viewporter, which the video plane needs")
        }
        initEgl()
        surface = Wl.request(compositor, 0, null, newInterface = Wl.coreInterface("wl_surface"))
        Wl.listen(surface) { opcode, args ->
            if (opcode == 0) outputs[args.obj(0).address()]?.let(::enteredOutput)
        }
        // Input belongs to the window: an empty input region passes every pointer event through.
        val empty = Wl.request(compositor, 1, null, newInterface = Wl.coreInterface("wl_region"))
        Wl.request(surface, 5, empty)
        Wl.destroy(empty)
        // Video is opaque: with an alpha-carrying (fp16) config the compositor must not blend it.
        val opaque = Wl.request(compositor, 1, null, newInterface = Wl.coreInterface("wl_region"))
        Wl.request(opaque, 1, 0, 0, Int.MAX_VALUE, Int.MAX_VALUE)
        Wl.request(surface, 4, opaque)
        Wl.destroy(opaque)
        subsurface = Wl.request(subcompositor, 1, null, surface, parent, newInterface = Wl.coreInterface("wl_subsurface"))
        Wl.request(subsurface, 3, parent) // place_below
        Wl.request(subsurface, 5) // set_desync
        viewport = Wl.request(viewporter, 1, null, surface, newInterface = Protocols["wp_viewport"])
        if (fractionalScaleManager.address() != 0L) {
            fractionalScale = Wl.request(fractionalScaleManager, 1, null, surface, newInterface = Protocols["wp_fractional_scale_v1"])
            // preferred_scale, in 120ths.
            Wl.listen(fractionalScale) { _, args -> outputScaleChanged(args.uint(0) / 120.0) }
        }
        eglWindow = Egl.window(surface, 1, 1)
        eglSurface = Egl.windowSurface(eglDisplay, eglConfig, eglWindow)
        supportsHdr = colorManager.address() != 0L && parametric && perceptual && bt2020 && (pq || hlg) && depthBits >= 10
        if (colorManager.address() != 0L) {
            colorSurface = Wl.request(colorManager, 2, null, surface, newInterface = Protocols["wp_color_management_surface_v1"])
            feedback = Wl.request(colorManager, 3, null, surface, newInterface = Protocols["wp_color_management_surface_feedback_v1"])
            Wl.listen(feedback) { _, _ -> beginPreferredQuery() }
            // Bootstrapped before the plane starts, so the first HDR decision has the output's answer.
            beginPreferredQuery()
            repeat(4) { if (!preferred.valid && Wl.roundtrip(display, queue) >= 0) Unit }
        }
        Wl.flush(display)
        log.log(
            System.Logger.Level.INFO,
            "video plane: {0}-bit, colour management v{1} (parametric={2} perceptual={3} pq={4} hlg={5} bt2020={6} mastering={7}), HDR {8}, output HDR {9}",
            depthBits, if (colorManager.address() != 0L) Wl.version(colorManager) else 0, parametric, perceptual, pq, hlg, bt2020, mastering,
            if (supportsHdr) "available" else "unavailable", outputIsHdr,
        )
        loop.start()
    }

    private fun global(global: Wl.Global) {
        val version = global.version
        val bind = global::bind
        when (global.iface) {
            "wl_compositor" -> compositor = bind(Wl.coreInterface("wl_compositor"), minOf(version, 4))
            "wl_subcompositor" -> subcompositor = bind(Wl.coreInterface("wl_subcompositor"), 1)
            "wp_viewporter" -> viewporter = bind(Protocols["wp_viewporter"], 1)
            "wp_fractional_scale_manager_v1" -> fractionalScaleManager = bind(Protocols["wp_fractional_scale_manager_v1"], 1)
            "wp_color_manager_v1" -> if (colorManager.address() == 0L) {
                colorManager = bind(Protocols["wp_color_manager_v1"], minOf(version, COLOR_MANAGER_MAX_VERSION))
                Wl.listen(colorManager) { opcode, args ->
                    val value = args.uint(0)
                    when (opcode) {
                        0 -> if (value == INTENT_PERCEPTUAL) perceptual = true
                        1 -> when (value) {
                            FEATURE_PARAMETRIC -> parametric = true
                            FEATURE_MASTERING -> mastering = true
                            FEATURE_EXTENDED_TARGET_VOLUME -> extendedTargetVolume = true
                        }
                        2 -> when (value) {
                            TF_PQ -> pq = true
                            TF_HLG -> hlg = true
                        }
                        3 -> if (value == PRIMARIES_BT2020) bt2020 = true
                    }
                }
            }
            "wl_output" -> {
                val output = Output(bind(Wl.coreInterface("wl_output"), minOf(version, Wl.interfaceVersion(Wl.coreInterface("wl_output")), 3)))
                outputs[output.proxy.address()] = output
                Wl.listen(output.proxy) { opcode, args ->
                    // mode: flags, width, height, refresh in mHz; the current mode has flag 1.
                    if (opcode == 1 && args.uint(0) and 1L != 0L) output.refreshMilliHz = args.int(3)
                }
            }
        }
    }

    private fun initEgl() {
        eglDisplay = Egl.display(display)
        val float = "EGL_EXT_pixel_format_float" in Egl.extensions(eglDisplay)
        // Deepest first: 10-bit unorm, then fp16 (NVIDIA offers no 10-bit window config on Wayland), then 8-bit, which
        // carries no HDR.
        for ((bits, floating) in listOf(10 to false, 16 to true, 8 to false)) {
            if (floating && !float) continue
            val attrs = intArrayOf(
                Egl.SURFACE_TYPE, Egl.WINDOW_BIT, Egl.RENDERABLE_TYPE, Egl.OPENGL_ES3_BIT,
                Egl.RED_SIZE, bits, Egl.GREEN_SIZE, bits, Egl.BLUE_SIZE, bits,
            ) + if (floating) intArrayOf(Egl.COLOR_COMPONENT_TYPE_EXT, Egl.COLOR_COMPONENT_TYPE_FLOAT_EXT) else intArrayOf(Egl.ALPHA_SIZE, 0)
            // Configs come deepest first for "at least" sizes: take the tier asked for exactly.
            val config = Egl.configs(eglDisplay, attrs).firstOrNull { Egl.attribute(eglDisplay, it, Egl.RED_SIZE) == bits } ?: continue
            eglContext = Egl.context(eglDisplay, config) ?: continue
            eglConfig = config
            depthBits = bits
            return
        }
        error("no EGL config with an OpenGL ES 3 context for the video plane")
    }

    // ---- the UI thread -------------------------------------------------------------------------------------------------

    /**
     * Places the plane at [x], [y] in the window's surface, [width] × [height] logical units, in a window of
     * [surfaceScale] pixels per unit; its buffer is at [bufferScale]. Call before the window's next commit (during its
     * layout or paint): the position is window state, and a size change lands with the window's commit.
     */
    fun setRect(x: Int, y: Int, width: Int, height: Int, surfaceScale: Double): Unit = surfaceLock.withLock {
        if (destroyed) return
        if (x != this.x || y != this.y) {
            Wl.request(subsurface, 1, x, y)
            this.x = x
            this.y = y
        }
        this.surfaceScale = surfaceScale
        resize(width, height)
        hasRect = true
        Wl.flush(display)
        loop.post {}
    }

    /** The output's scale for the plane changed (the window moved to another output, or its scale changed). */
    private fun outputScaleChanged(scale: Double): Unit = surfaceLock.withLock {
        if (destroyed || scale == outputScale) return
        outputScale = scale
        log.log(System.Logger.Level.INFO, "video plane: output scale {0}", scale)
        if (!hasRect) return
        resize(width, height)
        Wl.flush(display)
        loop.post {}
    }

    /** The plane at [width] × [height] logical units with its buffer at [bufferScale], under [surfaceLock]. */
    private fun resize(width: Int, height: Int) {
        val scale = bufferScale(surfaceScale, outputScale)
        val bufferWidth = bufferExtent(width, scale)
        val bufferHeight = bufferExtent(height, scale)
        if (width == this.width && height == this.height && bufferWidth == this.bufferWidth && bufferHeight == this.bufferHeight) return
        if (!syncMode) {
            Wl.request(subsurface, 4) // set_sync
            syncMode = true
        }
        Wl.request(viewport, 2, width, height)
        Wl.request(surface, 6) // commit: cached until the window's commit
        this.width = width
        this.height = height
        this.bufferWidth = bufferWidth
        this.bufferHeight = bufferHeight
        resizeSerial++
        forceRender.set(true)
    }

    /** Shows or hides the plane (hidden: no buffer, so nothing of a last frame stays on screen). */
    fun setVisible(visible: Boolean): Unit = surfaceLock.withLock {
        if (destroyed || visible == this.visible) return
        this.visible = visible
        if (!visible) {
            Wl.request(surface, 1, null, 0, 0) // attach(null)
            Wl.request(surface, 6)
            Wl.flush(display)
            firstFramePresented = false
        }
        forceRender.set(true)
        loop.post {}
    }

    /**
     * The window is about to commit (its paint). Once a frame at a new size has been carried by a window commit, the
     * plane goes back to presenting on its own.
     */
    fun parentFrame() = surfaceLock.withLock {
        if (destroyed || !syncMode || resizedFrameSerial != resizeSerial) return
        if (++parentFramesSinceResizedFrame < 2) return
        Wl.request(subsurface, 5) // set_desync
        Wl.flush(display)
        syncMode = false
    }

    // ---- any thread ------------------------------------------------------------------------------------------------------

    /** Whether the app allows HDR on the plane (the HDR setting and the playback's output plan). */
    fun setHdrAllowed(allowed: Boolean) {
        hdrAllowed = allowed
        requestHdr()
    }

    /** Who tone-maps an HDR source shown as HDR: the compositor (passthrough) or mpv, to the output's peak. */
    fun setToneMapping(mode: HdrToneMapping) {
        toneMapping = mode
        requestHdr()
    }

    /** The source's colour space and HDR10 metadata changed (mpv's `video-params`). */
    fun setSource(metadata: HdrMetadata) {
        if (metadata == source) return
        source = metadata
        log.log(
            System.Logger.Level.INFO, "video plane: source {0}/{1} MaxCLL={2} MaxFALL={3} mastering={4}-{5} nits",
            metadata.transfer, metadata.primaries, metadata.maxCll, metadata.maxFall, metadata.minLuminance, metadata.maxLuminance,
        )
        requestHdr()
    }

    /** A new file or a seek: a fresh chance to name the output, whatever the last one ended in. */
    fun playbackRestarted() = requestHdr()

    private fun requestHdr() {
        if (hdrReapply.compareAndSet(false, true)) loop.post { if (hdrReapply.getAndSet(false)) applyHdr() }
    }

    /**
     * Creates mpv's render context for [core] on the plane's thread (render API on its EGL context, with the Wayland
     * connection for hardware-decoding interop). Returns null once it is ready, or why it failed.
     */
    fun attach(core: MpvCore): String? {
        val done = CountDownLatch(1)
        var failure: String? = "the video plane stopped"
        if (!loop.post {
                failure = try {
                    attachOnLoop(core)
                    null
                } catch (t: Throwable) {
                    log.log(System.Logger.Level.ERROR, "video plane: mpv's render context failed", t)
                    t.message ?: t.toString()
                }
                done.countDown()
            }
        ) return failure
        if (!done.await(ATTACH_TIMEOUT_SECONDS, TimeUnit.SECONDS)) return "the video plane did not answer within $ATTACH_TIMEOUT_SECONDS s"
        return failure
    }

    /**
     * Frees mpv's render context on the plane's thread and takes the video off screen; [unbound] counts down once done
     * (it must be, before mpv_terminate_destroy).
     */
    fun detach(unbound: CountDownLatch) {
        if (!loop.post { detachOnLoop(); unbound.countDown() }) unbound.countDown()
    }

    /**
     * Destroys the plane: every Wayland and EGL object, then the thread. False when the thread didn't finish within 5 s
     * (stuck in a driver call): then nothing it might still touch is freed, mpv's core included.
     */
    fun destroy(): Boolean {
        surfaceLock.withLock { destroyed = true }
        loop.post(::destroyOnLoop)
        return loop.shutdownAndJoin(SHUTDOWN_TIMEOUT_MS)
    }

    /** The plane's state for diagnostics and test reports. */
    fun stats(): Map<String, Any?> {
        val p = preferred
        return linkedMapOf(
            "frames" to frames, "firstFrame" to firstFramePresented, "depthBits" to depthBits, "buffer" to listOf(presentedWidth, presentedHeight),
            "supportsHdr" to supportsHdr, "outputHdr" to outputIsHdr, "hdrAllowed" to hdrAllowed, "toneMapping" to toneMapping.name,
            "described" to hdrActive, "decision" to lastHdrDecision?.let { mapOf("describe" to it.describe, "toneMapInPlayer" to it.toneMapInPlayer, "targetPeak" to it.targetPeakNits) },
            "preferred" to mapOf("valid" to p.valid, "tf" to p.tf, "primaries" to p.primaries, "reference" to p.reference, "targetMax" to p.targetMax, "targetMin" to p.targetMinScaled / 10000.0),
            "source" to source.let { mapOf("transfer" to it.transfer.name, "primaries" to it.primaries.name, "maxCll" to it.maxCll, "maxFall" to it.maxFall, "maxLuminance" to it.maxLuminance) },
            "outputRefreshMilliHz" to outputRefresh, "outputScale" to outputScale,
        )
    }

    // ---- the plane's thread ----------------------------------------------------------------------------------------------

    private fun attachOnLoop(core: MpvCore) {
        check(Egl.makeCurrent(eglDisplay, eglSurface, eglContext)) { "eglMakeCurrent failed: 0x%x".format(Egl.error()) }
        // Never block this thread on the compositor: the frame callbacks pace it.
        Egl.swapInterval(eglDisplay, 0)
        val a = Arena.ofShared().also { renderArena = it }
        val getProcAddress = mpv_opengl_init_params.get_proc_address.allocate({ _, name -> Egl.procAddress(name) }, a)
        val init = mpv_opengl_init_params.allocate(a)
        mpv_opengl_init_params.get_proc_address(init, getProcAddress)
        mpv_opengl_init_params.get_proc_address_ctx(init, MemorySegment.NULL)
        val params = mpv_render_param.allocateArray(4, a)
        param(params, 0, MpvFfi.MPV_RENDER_PARAM_API_TYPE(), MpvFfi.MPV_RENDER_API_TYPE_OPENGL())
        param(params, 1, MpvFfi.MPV_RENDER_PARAM_OPENGL_INIT_PARAMS(), init)
        param(params, 2, MpvFfi.MPV_RENDER_PARAM_WL_DISPLAY(), display)
        param(params, 3, MpvFfi.MPV_RENDER_PARAM_INVALID(), MemorySegment.NULL)
        val out = a.allocate(ValueLayout.ADDRESS)
        val rc = MpvFfi.mpv_render_context_create(out, core.handle, params)
        check(rc >= 0) { "mpv_render_context_create: ${MpvCore.errorString(rc)}" }
        render = out.get(ValueLayout.ADDRESS, 0)
        // Called on mpv's threads; must not throw (an exception in an upcall aborts the JVM).
        val onUpdate = mpv_render_update_fn.allocate({ _ -> mpvUpdate.set(true); Posix.signal(wakeFd) }, a)
        MpvFfi.mpv_render_context_set_update_callback(render, onUpdate, MemorySegment.NULL)
        this.core = core
        outputColour = OutputColour(write = { name, value -> core.setString(name, value) }, canCommand = { this.core != null })
        outputs.values.firstOrNull { it.refreshMilliHz > 0 }?.takeIf { outputRefresh == 0 }?.let(::applyRefresh)
        log.log(System.Logger.Level.INFO, "video plane: mpv renders on {0}, {1}-bit plane", Gles.describe(), depthBits)
        // A software renderer (Mesa's llvmpipe, a VM without GPU) draws mpv's default upscaler (the separated filter
        // with its weights texture) black: every source smaller than the plane would show nothing. Bilinear draws.
        if (SOFTWARE_RENDERERS.any { it in Gles.renderer() }) {
            log.log(System.Logger.Level.WARNING, "video plane: software renderer, so mpv upscales bilinear")
            core.setString("scale", "bilinear")
        }
        applyHdr()
    }

    private fun detachOnLoop() {
        if (render.address() != 0L) {
            MpvFfi.mpv_render_context_set_update_callback(render, MemorySegment.NULL, MemorySegment.NULL)
            MpvFfi.mpv_render_context_free(render)
            render = MemorySegment.NULL
        }
        renderArena?.close()
        renderArena = null
        core = null
        outputColour = null
        surfaceLock.withLock {
            if (surface.address() != 0L) {
                Wl.request(surface, 1, null, 0, 0)
                Wl.request(surface, 6)
            }
        }
        firstFramePresented = false
        Wl.flush(display)
    }

    private fun destroyOnLoop() {
        detachOnLoop()
        Egl.releaseCurrent(eglDisplay)
        if (eglSurface.address() != 0L) Egl.destroySurface(eglDisplay, eglSurface)
        if (eglContext.address() != 0L) Egl.destroyContext(eglDisplay, eglContext)
        if (eglWindow.address() != 0L) Egl.destroyWindow(eglWindow)
        if (frameCallback.address() != 0L) Wl.forget(frameCallback)
        if (stagedDescription.address() != 0L) Wl.destroy(stagedDescription)
        if (preferredInfo.address() != 0L) Wl.forget(preferredInfo)
        if (preferredDescription.address() != 0L) Wl.destroy(preferredDescription)
        for (proxy in listOf(feedback, colorSurface, fractionalScale, viewport, subsurface, surface)) if (proxy.address() != 0L) Wl.destroy(proxy)
        if (colorManager.address() != 0L) Wl.destroy(colorManager)
        if (viewporter.address() != 0L) Wl.destroy(viewporter)
        if (fractionalScaleManager.address() != 0L) Wl.destroy(fractionalScaleManager)
        if (subcompositor.address() != 0L) Wl.destroy(subcompositor)
        outputs.values.forEach { if (Wl.version(it.proxy) >= 3) Wl.destroy(it.proxy, 0) else Wl.forget(it.proxy) }
        if (compositor.address() != 0L) Wl.forget(compositor)
        Wl.forget(registry)
        Wl.destroyWrapper(displayWrapper)
        Wl.flush(display)
        Wl.destroyQueue(queue)
        Posix.close(wakeFd)
    }

    /** One turn between jobs: watchdogs, then a present if one is due. Returns how long the next wait may last. */
    private fun turn(): Int {
        if (destroyed || events.lost) return -1
        if (frameCallback.address() != 0L) {
            val waited = (System.nanoTime() - frameSentNanos) / 1_000_000
            val limit = if (frameAckMisses > MAX_FRAME_ACK_MISSES) STALLED_REPRESENT_MS else FRAME_ACK_TIMEOUT_MS
            if (waited < limit) return (limit - waited).toInt().coerceAtLeast(1)
            // Never acknowledged (occluded, minimized): stop waiting, so presenting resumes on its own.
            Wl.forget(frameCallback)
            frameCallback = MemorySegment.NULL
            frameAckMisses++
            if (frameAckMisses == MAX_FRAME_ACK_MISSES + 1) {
                log.log(System.Logger.Level.WARNING, "video plane: the compositor isn't acknowledging frames; presenting at most once a second")
            }
        }
        if (render.address() == 0L) return -1
        if (mpvUpdate.getAndSet(false)) {
            if (MpvFfi.mpv_render_context_update(render) and MpvFfi.MPV_RENDER_UPDATE_FRAME().toLong() != 0L) frameReady = true
        }
        val (shown, size) = surfaceLock.withLock { (hasRect && visible) to (bufferWidth to bufferHeight) }
        if (!shown) return -1
        // Never an empty buffer as the first present: a compositor may ignore the frame callback of that commit forever.
        if (!firstFramePresented && !frameReady) return -1
        if (!frameReady && !forceRender.get()) return -1
        present(size.first, size.second)
        return -1
    }

    private fun present(w: Int, h: Int) {
        forceRender.set(false)
        frameReady = false
        if (w != presentedWidth || h != presentedHeight) Egl.resizeWindow(eglWindow, w, h)
        Arena.ofConfined().use { a ->
            val fbo = mpv_opengl_fbo.allocate(a)
            mpv_opengl_fbo.fbo(fbo, 0)
            mpv_opengl_fbo.w(fbo, w)
            mpv_opengl_fbo.h(fbo, h)
            mpv_opengl_fbo.internal_format(fbo, if (depthBits >= 16) Gles.RGBA16F else if (depthBits >= 10) Gles.RGB10_A2 else Gles.RGBA8)
            val params = mpv_render_param.allocateArray(4, a)
            param(params, 0, MpvFfi.MPV_RENDER_PARAM_OPENGL_FBO(), fbo)
            param(params, 1, MpvFfi.MPV_RENDER_PARAM_FLIP_Y(), a.allocateFrom(ValueLayout.JAVA_INT, 1))
            // Without it mpv dithers to 8 bits whatever the buffer holds.
            param(params, 2, MpvFfi.MPV_RENDER_PARAM_DEPTH(), a.allocateFrom(ValueLayout.JAVA_INT, depthBits))
            param(params, 3, MpvFfi.MPV_RENDER_PARAM_INVALID(), MemorySegment.NULL)
            MpvFfi.mpv_render_context_render(render, params)
        }
        val (swapped, synced) = surfaceLock.withLock {
            if (destroyed) return
            frameCallback = Wl.request(surface, 3, null, newInterface = Wl.coreInterface("wl_callback"), newVersion = 1)
            val callback = frameCallback
            Wl.listen(callback) { _, _ ->
                if (frameCallback == callback) {
                    Wl.forget(callback)
                    frameCallback = MemorySegment.NULL
                    frameAckMisses = 0
                }
            }
            frameSentNanos = System.nanoTime()
            val ok = Egl.swap(eglDisplay, eglSurface)
            if (ok && syncMode && resizedFrameSerial != resizeSerial && w == bufferWidth && h == bufferHeight) {
                resizedFrameSerial = resizeSerial
                parentFramesSinceResizedFrame = 0
            }
            ok to syncMode
        }
        MpvFfi.mpv_render_context_report_swap(render)
        if (!swapped) {
            log.log(System.Logger.Level.WARNING, "video plane: eglSwapBuffers failed: 0x{0}", Integer.toHexString(Egl.error()))
            forceRender.set(true)
            return
        }
        presentedWidth = w
        presentedHeight = h
        frames++
        firstFramePresented = true
        Wl.flush(display)
        if (synced) commitParent()
    }

    /** Waits for the plane's events or a wake-up, at most [timeoutMs] (-1: until one), and dispatches its queue. */
    private fun waitForEvents(timeoutMs: Int) {
        if (destroyed) return
        events.await(timeoutMs)
    }

    private fun enteredOutput(output: Output) {
        if (output.refreshMilliHz > 0) applyRefresh(output)
    }

    /**
     * vo=libmpv has no display of its own to time against, so mpv is told the refresh rate of the output the plane is
     * on (`display-fps-override`), whenever it changes.
     */
    private fun applyRefresh(output: Output) {
        val c = core ?: return
        if (output.refreshMilliHz == outputRefresh) return
        outputRefresh = output.refreshMilliHz
        val rc = c.setString("display-fps-override", String.format(Locale.ROOT, "%.3f", outputRefresh / 1000.0))
        if (rc < 0) log.log(System.Logger.Level.WARNING, "video plane: display-fps-override: {0}", MpvCore.errorString(rc))
    }

    // ---- the compositor's preferred description ------------------------------------------------------------------------

    private fun beginPreferredQuery() {
        if (preferredInfo.address() != 0L) Wl.forget(preferredInfo)
        if (preferredDescription.address() != 0L) Wl.destroy(preferredDescription)
        preferredInfo = MemorySegment.NULL
        // The parametric form: only parameters can be read, an ICC preferred description would say nothing.
        val description = Wl.request(feedback, 2, null, newInterface = Protocols["wp_image_description_v1"])
        preferredDescription = description
        Wl.listen(description) { opcode, args ->
            if (description != preferredDescription) return@listen
            when (opcode) {
                0 -> {
                    // failed: no output, or a version the compositor won't describe; the output then reads as SDR.
                    log.log(System.Logger.Level.INFO, "video plane: no preferred description ({0}: {1})", args.uint(0), args.string(1))
                    Wl.destroy(description)
                    preferredDescription = MemorySegment.NULL
                    preferred = Preferred()
                    preferredChanged()
                }
                1, 2 -> readPreferred(description)
            }
        }
    }

    private fun readPreferred(description: MemorySegment) {
        pendingPreferred = Preferred()
        val info = Wl.request(description, 1, null, newInterface = Protocols["wp_image_description_info_v1"])
        preferredInfo = info
        Wl.listen(info) { opcode, args ->
            if (info != preferredInfo) return@listen
            val p = pendingPreferred
            when (opcode) {
                0 -> {
                    p.valid = true
                    val before = preferred
                    preferred = p
                    Wl.forget(info)
                    preferredInfo = MemorySegment.NULL
                    if (preferredDescription.address() != 0L) Wl.destroy(preferredDescription)
                    preferredDescription = MemorySegment.NULL
                    // KWin re-announces its preference dozens of times a second for seconds after an HDR description
                    // lands, moving only the black level: logged when anything the HDR decision reads changes.
                    if (!before.valid || before.tf != p.tf || before.primaries != p.primaries || before.reference != p.reference || before.targetMax != p.targetMax) {
                        log.log(
                            System.Logger.Level.INFO, "video plane: preferred tf={0} primaries={1} reference={2} target={3}-{4} nits",
                            p.tf, p.primaries, p.reference, p.targetMinScaled / 10000.0, p.targetMax,
                        )
                    }
                    preferredChanged()
                }
                1 -> Posix.close(args.int(0)) // an ICC file: never read
                3 -> p.primaries = args.uint(0)
                5 -> p.tf = args.uint(0)
                6 -> p.reference = args.uint(2)
                // The output's peak: the transfer's own luminances are the curve's, 0.005-10000 for PQ.
                8 -> {
                    p.targetMinScaled = args.uint(0)
                    p.targetMax = args.uint(1)
                }
            }
        }
    }

    /** The output (or its HDR state) changed under the plane: re-decide only when the answer moved. */
    private fun preferredChanged() {
        if (core == null) return
        val decision = decide(source)
        if (decision.describe != hdrActive || decision.targetPeakNits != appliedTargetPeak) requestHdr()
    }

    // ---- HDR ------------------------------------------------------------------------------------------------------------

    private fun decide(source: HdrMetadata): HdrDecision {
        val p = preferred
        return decideHdr(
            HdrInputs(
                allowed = hdrAllowed,
                clientCanDescribe = supportsHdr,
                outputIsHdr = outputIsHdr,
                sourceDescribable = sourceIsDescribable(source, CompositorColorSupport(bt2020 = bt2020, pq = pq, hlg = hlg)),
                requested = toneMapping,
                displayPeakNits = p.targetMax,
                sdrReferenceNits = if (p.valid) p.reference else 0,
            ),
            source,
        )
    }

    /**
     * The HDR transaction, on the plane's thread: decide, stage and validate a description, switch mpv, then attach the
     * description and present mpv's first frame in the new colour space in one commit.
     */
    private fun applyHdr() {
        val colour = outputColour ?: return
        val source = source
        val decision = decide(source)
        lastHdrDecision = decision
        val described = if (decision.toneMapInPlayer) describeTonemappedTo(source, decision.targetPeakNits) else source
        val transfer = if (decision.describe) described.transfer else SourceTransfer.SDR
        val description = if (decision.describe && !(hdrActive && activeDescription == described)) {
            stageDescription(described) ?: run {
                log.log(System.Logger.Level.WARNING, "video plane: HDR description refused ({0}); HDR stays as it was", stagedError)
                forceRender.set(true)
                return
            }
        } else null
        when (val result = colour.apply(transfer, decision.targetPeakNits)) {
            OutputColour.Result.APPLIED -> {
                surfaceLock.withLock {
                    if (description != null) {
                        Wl.request(colorSurface, 1, description, INTENT_PERCEPTUAL)
                    } else if (!decision.describe && hdrActive) {
                        Wl.request(colorSurface, 2)
                    }
                }
                if (decision.describe != hdrActive || description != null) {
                    log.log(
                        System.Logger.Level.INFO, "video plane: HDR {0}{1}", if (decision.describe) "on" else "off",
                        if (decision.describe) ", tone mapping by " + (if (decision.toneMapInPlayer) "the player" else "the compositor") else "",
                    )
                }
                hdrActive = decision.describe
                if (decision.describe) activeDescription = described
                appliedTargetPeak = decision.targetPeakNits
            }
            OutputColour.Result.RESTORED ->
                log.log(System.Logger.Level.WARNING, "video plane: mpv refused the {0} output colour space and was put back", if (decision.describe) "HDR" else "SDR")
            OutputColour.Result.FORCED_SDR, OutputColour.Result.UNKNOWN -> {
                // Whatever mpv emits now, no HDR claim may stand over it: the plane shows it undescribed.
                if (hdrActive) surfaceLock.withLock { Wl.request(colorSurface, 2) }
                hdrActive = false
                appliedTargetPeak = 0
                log.log(System.Logger.Level.WARNING, "video plane: mpv's output colour space is {0}; HDR withdrawn", result)
            }
        }
        if (description != null) Wl.destroy(description)
        stagedDescription = MemorySegment.NULL
        // The new colour space and its description reach the screen together, with the next frame.
        forceRender.set(true)
        if (render.address() != 0L && surfaceLock.withLock { hasRect && visible } && firstFramePresented) {
            val (w, h) = surfaceLock.withLock { bufferWidth to bufferHeight }
            present(w, h)
        }
    }

    /**
     * A parametric PQ or HLG / BT.2020 description of [metadata], with only the luminances the compositor will accept
     * ([planHdrLuminance]), once the compositor has validated it; null when it refused it or didn't answer within 5 s.
     */
    private fun stageDescription(metadata: HdrMetadata): MemorySegment? {
        val creator = Wl.request(colorManager, 5, null, newInterface = Protocols["wp_image_description_creator_params_v1"])
        Wl.request(creator, 1, if (metadata.transfer == SourceTransfer.HLG) TF_HLG else TF_PQ)
        Wl.request(creator, 3, PRIMARIES_BT2020)
        val plan = planHdrLuminance(metadata, CompositorLuminanceSupport(mastering, extendedTargetVolume, Wl.version(colorManager)))
        if (plan.sendMastering) Wl.request(creator, 7, plan.masteringMinScaled, plan.masteringMax)
        if (plan.sendMaxCll) Wl.request(creator, 8, plan.maxCll)
        if (plan.sendMaxFall) Wl.request(creator, 9, plan.maxFall)
        val description = Wl.request(creator, 0, null, newInterface = Protocols["wp_image_description_v1"], destroy = true)
        stagedDescription = description
        stagedState = Staged.PENDING
        stagedError = null
        Wl.listen(description) { opcode, args ->
            if (description != stagedDescription) return@listen
            when (opcode) {
                0 -> {
                    stagedState = Staged.FAILED
                    stagedError = "${args.uint(0)}: ${args.string(1)}"
                }
                1, 2 -> stagedState = Staged.READY
            }
        }
        val until = System.nanoTime() + TimeUnit.SECONDS.toNanos(TRANSITION_TIMEOUT_SECONDS)
        while (stagedState == Staged.PENDING && System.nanoTime() < until && !destroyed && !events.lost) waitForEvents(50)
        if (stagedState == Staged.READY) return description
        if (stagedState == Staged.PENDING) stagedError = "no answer within $TRANSITION_TIMEOUT_SECONDS s"
        Wl.destroy(description)
        stagedDescription = MemorySegment.NULL
        return null
    }

    private fun param(params: MemorySegment, i: Long, type: Int, data: MemorySegment) {
        val p = mpv_render_param.asSlice(params, i)
        mpv_render_param.type(p, type)
        mpv_render_param.data(p, data)
    }

    companion object {
        /** The highest wp_color_manager_v1 version this client describes. */
        private const val COLOR_MANAGER_MAX_VERSION = 3
        private const val INTENT_PERCEPTUAL = 0L
        private const val FEATURE_PARAMETRIC = 1L
        private const val FEATURE_MASTERING = 5L
        private const val FEATURE_EXTENDED_TARGET_VOLUME = 6L
        private const val TF_PQ = 11L
        private const val TF_HLG = 13L
        private const val PRIMARIES_BT2020 = 6L
        /** `GL_RENDERER` names of Mesa's software renderers. */
        private val SOFTWARE_RENDERERS = listOf("llvmpipe", "softpipe", "swrast")
        private const val FRAME_ACK_TIMEOUT_MS = 500L
        private const val MAX_FRAME_ACK_MISSES = 5
        private const val STALLED_REPRESENT_MS = 1000L
        private const val TRANSITION_TIMEOUT_SECONDS = 5L
        private const val ATTACH_TIMEOUT_SECONDS = 10L
        private const val SHUTDOWN_TIMEOUT_MS = 5000L

        /**
         * A plane under [parent] (the window's `wl_surface`) on the window's Wayland connection [display]. Call on the
         * UI thread. Throws with the reason when the compositor or the GPU can't give one.
         */
        fun create(display: MemorySegment, parent: MemorySegment, commitParent: () -> Unit): VideoPlane = VideoPlane(display, parent, commitParent).apply {
            try {
                create()
            } catch (t: Throwable) {
                runCatching { loop.start(); destroy() }
                throw t
            }
        }
    }
}

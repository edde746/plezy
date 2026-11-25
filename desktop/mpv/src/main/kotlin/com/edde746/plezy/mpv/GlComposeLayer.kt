package com.edde746.plezy.mpv

import com.edde746.plezy.mpv.os.Egl
import com.edde746.plezy.mpv.os.Gles
import com.edde746.plezy.mpv.os.Posix
import com.edde746.plezy.mpv.os.Protocols
import com.edde746.plezy.mpv.os.QueueWait
import com.edde746.plezy.mpv.os.Wl
import com.edde746.plezy.mpv.video.PlaneLoop
import java.lang.foreign.MemorySegment
import javax.swing.JComponent
import javax.swing.SwingUtilities
import kotlin.math.ceil
import kotlin.math.floor
import org.jetbrains.skia.BackendRenderTarget
import org.jetbrains.skia.ColorSpace
import org.jetbrains.skia.DirectContext
import org.jetbrains.skia.GLAssembledInterface
import org.jetbrains.skia.Surface
import org.jetbrains.skia.SurfaceColorFormat
import org.jetbrains.skia.SurfaceOrigin
import org.jetbrains.skia.SurfaceProps
import org.jetbrains.skia.makeGLWithInterface
import org.jetbrains.skiko.SkikoRenderDelegate
import org.jetbrains.skiko.swing.SkiaSwingLayer

/**
 * Compose's frames on the GPU in a Wayland session: Skia's OpenGL ES backend draws the [WaylandWindow]'s Compose scene
 * into an EGL window surface of its own, on a subsurface stacked above the window's surface. Only the drawing moves:
 * the window's [androidx.compose.ui.awt.ComposePanel] stays in Swing's hierarchy and takes input, focus, IME and
 * accessibility as before (the subsurface's input region is empty, so every pointer event goes to the window), and the
 * window's surface keeps what Swing paints there (the background, cleared where the video plane shows).
 *
 * Compose asks for a frame by repainting its Skia layer; the window's repaint manager hands those requests to
 * [requestFrame] instead of to Swing. A frame renders on the UI thread (the scene's), paced by the subsurface's frame
 * callbacks: one frame in flight, and a watchdog for a window the compositor doesn't draw (minimized, occluded), which
 * then gets a frame every half second, after five misses every second.
 *
 * The subsurface is desynchronized, so a frame shows when it is committed, without the window. A frame that changes the
 * window as well (a new size, the video plane moving) is synchronized with it: the subsurface switches to synchronized
 * mode, every frame renders during the window's paint ([paint]) and lands with the window's commit, until a frame
 * rendered in that mode has been shown (its frame callback, which a synchronized subsurface gets only once the window's
 * commit applied it).
 *
 * The UI-thread state is touched only there; the frame callback and pacing state are guarded by [lock], shared with the
 * thread dispatching the subsurface's event queue.
 */
internal class GlComposeLayer private constructor(
    private val window: WaylandWindow,
    private val layer: JComponent,
    /** The Compose scene's drawing: what Skiko's Swing layer calls with a canvas of its own. */
    private val scene: SkikoRenderDelegate,
    private val display: MemorySegment,
    private val parent: MemorySegment,
    /** Hears how long each frame took to render, in nanoseconds (on the UI thread). */
    private val onFrame: (Long) -> Unit,
) {
    private val queue = Wl.createQueue(display)
    private val displayWrapper = Wl.wrapper(display, queue)
    private val registry = Wl.globals(displayWrapper, ::global)
    private val wakeFd = Posix.eventFd()
    private val events = QueueWait(Wl.eventQueue(display, queue), wakeFd, "compose layer")
    private val loop = PlaneLoop("compose-gl", ::turn, ::waitForEvents) { Posix.signal(wakeFd) }

    private var compositor = MemorySegment.NULL
    private var subcompositor = MemorySegment.NULL
    private var viewporter = MemorySegment.NULL
    private var surface = MemorySegment.NULL
    private var subsurface = MemorySegment.NULL
    private var viewport = MemorySegment.NULL
    private var eglWindow = MemorySegment.NULL
    private var eglDisplay = MemorySegment.NULL
    private var eglContext = MemorySegment.NULL
    private var eglSurface = MemorySegment.NULL
    private var stencilBits = 0
    private var skia: DirectContext? = null
    private var target: BackendRenderTarget? = null
    private var canvasSurface: Surface? = null

    /** `GL_VERSION (GL_RENDERER)` of the context Compose draws with. */
    var renderer = ""
        private set

    // ---- UI thread ---------------------------------------------------------------------------------------------------

    /** Where the layer is in the window's surface and how large (logical units), and its buffer's size in pixels. */
    private data class Geometry(val x: Int, val y: Int, val width: Int, val height: Int, val bufferWidth: Int, val bufferHeight: Int)

    private var applied = Geometry(Int.MIN_VALUE, Int.MIN_VALUE, 0, 0, 0, 0)
    private var presentedWidth = 0
    private var presentedHeight = 0
    private var syncMode = false
    /** The latest frame rendered in synchronized mode since the last [syncWithWindow]: its frame callback's address. */
    private var syncFrame = 0L

    // ---- guarded by lock -----------------------------------------------------------------------------------------------

    private val lock = Any()
    private var destroyed = false
    /** Compose asked for a frame that hasn't rendered yet. */
    private var wanted = false
    /** A [frame] is queued on the UI thread. */
    private var scheduled = false
    private var frameCallback = MemorySegment.NULL
    private var frameSentNanos = 0L
    private var frameAckMisses = 0
    /** The address of the latest frame callback the compositor answered. */
    private var ackedFrame = 0L

    private fun create() {
        check(Wl.roundtrip(display, queue) >= 0) { "the Wayland connection failed" }
        check(compositor.address() != 0L && subcompositor.address() != 0L && viewporter.address() != 0L) {
            "the compositor lacks wl_subcompositor or wp_viewporter"
        }
        eglDisplay = Egl.display(display)
        val attributes = intArrayOf(
            Egl.SURFACE_TYPE, Egl.WINDOW_BIT, Egl.RENDERABLE_TYPE, Egl.OPENGL_ES3_BIT,
            Egl.RED_SIZE, 8, Egl.GREEN_SIZE, 8, Egl.BLUE_SIZE, 8, Egl.ALPHA_SIZE, 8, Egl.STENCIL_SIZE, 8,
        )
        // Configs come deepest first for "at least" sizes: take 8 bits a channel, with alpha.
        val config = Egl.configs(eglDisplay, attributes).firstOrNull {
            Egl.attribute(eglDisplay, it, Egl.RED_SIZE) == 8 && Egl.attribute(eglDisplay, it, Egl.ALPHA_SIZE) == 8
        } ?: error("no 8-bit RGBA EGL window config with a stencil buffer")
        stencilBits = Egl.attribute(eglDisplay, config, Egl.STENCIL_SIZE)
        eglContext = Egl.context(eglDisplay, config) ?: error("no OpenGL ES 3 context")
        surface = Wl.request(compositor, 0, null, newInterface = Wl.coreInterface("wl_surface"))
        // Input belongs to the window: an empty input region passes every pointer event through.
        val empty = Wl.request(compositor, 1, null, newInterface = Wl.coreInterface("wl_region"))
        Wl.request(surface, 5, empty)
        Wl.destroy(empty)
        // A new subsurface is the topmost of its parent's: above the window's surface (the video plane is below it).
        subsurface = Wl.request(subcompositor, 1, null, surface, parent, newInterface = Wl.coreInterface("wl_subsurface"))
        Wl.request(subsurface, 5) // set_desync
        viewport = Wl.request(viewporter, 1, null, surface, newInterface = Protocols["wp_viewport"])
        eglWindow = Egl.window(surface, 1, 1)
        eglSurface = Egl.windowSurface(eglDisplay, config, eglWindow)
        makeCurrent()
        // Never block the UI thread on the compositor: the frame callbacks pace the frames.
        Egl.swapInterval(eglDisplay, 0)
        renderer = Gles.describe()
        val name = Gles.renderer().lowercase()
        check(SOFTWARE_RENDERERS.none { it in name }) { "OpenGL renders in software ($renderer)" }
        val gl = GLAssembledInterface.createFromNativePointers(0L, Egl.skiaGetProc.address())
        skia = try {
            DirectContext.makeGLWithInterface(gl)
        } finally {
            gl.close()
        }
        Wl.flush(display)
        loop.start()
    }

    private fun global(global: Wl.Global) {
        when (global.iface) {
            "wl_compositor" -> compositor = global.bind(Wl.coreInterface("wl_compositor"), minOf(global.version, 4))
            "wl_subcompositor" -> subcompositor = global.bind(Wl.coreInterface("wl_subcompositor"), 1)
            "wp_viewporter" -> viewporter = global.bind(Protocols["wp_viewporter"], 1)
        }
    }

    private fun makeCurrent() {
        check(Egl.makeCurrent(eglDisplay, eglSurface, eglContext)) { "eglMakeCurrent failed: 0x%x".format(Egl.error()) }
    }

    /** Compose wants a frame (its layer was repainted). Any thread. */
    fun requestFrame() {
        synchronized(lock) {
            wanted = true
            if (destroyed || scheduled || frameCallback.address() != 0L) return
            scheduled = true
        }
        SwingUtilities.invokeLater(::frame)
    }

    /** The frame Compose wants, once the last one has been shown. */
    private fun frame() {
        val acked = synchronized(lock) {
            scheduled = false
            if (destroyed || !wanted || frameCallback.address() != 0L) return
            ackedFrame
        }
        // The window's commit has carried a frame rendered in synchronized mode: back to presenting on its own.
        if (syncMode && syncFrame != 0L && acked == syncFrame) {
            Wl.request(subsurface, 5) // set_desync
            syncMode = false
        }
        // Synchronized, or about to be: the window's paint renders the frame, and its commit carries it.
        if (syncMode || geometry() != applied) window.requestCommit() else render()
    }

    /**
     * The window's paint, which its commit follows: renders the frame Compose wants, and one at a new size or place
     * (synchronized with the window, so the window's commit carries both).
     */
    fun paint() {
        val g = geometry()
        val moved = g != applied
        if (moved) {
            if (g.x != applied.x || g.y != applied.y) Wl.request(subsurface, 1, g.x, g.y) // set_position: the window's state
            if (g.width != applied.width || g.height != applied.height || g.bufferWidth != applied.bufferWidth || g.bufferHeight != applied.bufferHeight) {
                syncWithWindow()
                Wl.request(viewport, 2, g.width, g.height) // set_destination
            }
            applied = g
        }
        if (moved || synchronized(lock) { wanted }) render()
    }

    /**
     * The window changes along with Compose's frame (the video plane's place, during Compose's layout): this frame and
     * the next ones land with the window's commits until one has been shown.
     */
    fun syncWithWindow() {
        if (!syncMode) {
            Wl.request(subsurface, 4) // set_sync
            syncMode = true
        }
        syncFrame = 0L
    }

    /** The layer in the window's surface units, its buffer in physical pixels as Skiko sizes the scene's canvas. */
    private fun geometry(): Geometry {
        val at = SwingUtilities.convertPoint(layer, 0, 0, window)
        val scale = window.graphicsConfiguration.defaultTransform.scaleX
        val toSurface = scale / window.surfaceScale()
        val width = maxOf(1, layer.width)
        val height = maxOf(1, layer.height)
        return Geometry(
            floor(at.x * toSurface).toInt(), floor(at.y * toSurface).toInt(),
            ceil(width * toSurface).toInt(), ceil(height * toSurface).toInt(),
            maxOf(1, (width * scale).toInt()), maxOf(1, (height * scale).toInt()),
        )
    }

    private fun render() {
        val start = System.nanoTime()
        synchronized(lock) { wanted = false }
        val context = checkNotNull(skia)
        makeCurrent()
        val width = applied.bufferWidth
        val height = applied.bufferHeight
        if (width != presentedWidth || height != presentedHeight || canvasSurface == null) {
            Egl.resizeWindow(eglWindow, width, height)
            canvasSurface?.close()
            target?.close()
            val rt = BackendRenderTarget.makeGL(width, height, 0, stencilBits, 0, Gles.RGBA8).also { target = it }
            canvasSurface = Surface.makeFromBackendRenderTarget(context, rt, SurfaceOrigin.BOTTOM_LEFT, SurfaceColorFormat.RGBA_8888, ColorSpace.sRGB, SurfaceProps())
                ?: error("Skia made no surface for the ${width}x$height window surface")
            presentedWidth = width
            presentedHeight = height
        }
        val canvas = checkNotNull(canvasSurface)
        canvas.canvas.clear(0)
        scene.onRender(canvas.canvas, width, height, System.nanoTime())
        context.flushAndSubmit(canvas)
        // A callback is forgotten only under the lock, by whoever finds it current: the event thread may be in its
        // handler right now.
        val callback = synchronized(lock) {
            if (frameCallback.address() != 0L) Wl.forget(frameCallback)
            val cb = Wl.request(surface, 3, null, newInterface = Wl.coreInterface("wl_callback"), newVersion = 1)
            Wl.listen(cb) { _, _ -> frameDone(cb) }
            frameCallback = cb
            frameSentNanos = System.nanoTime()
            cb
        }
        check(Egl.swap(eglDisplay, eglSurface)) { "eglSwapBuffers failed: 0x%x".format(Egl.error()) }
        if (syncMode) syncFrame = callback.address()
        Wl.flush(display)
        // The watchdog's next deadline.
        loop.post {}
        onFrame(System.nanoTime() - start)
    }

    // ---- the event thread ----------------------------------------------------------------------------------------------

    private fun frameDone(callback: MemorySegment) {
        synchronized(lock) {
            if (callback != frameCallback) return
            Wl.forget(callback)
            frameCallback = MemorySegment.NULL
            frameAckMisses = 0
            ackedFrame = callback.address()
            if (destroyed || !wanted || scheduled) return
            scheduled = true
        }
        SwingUtilities.invokeLater(::frame)
    }

    /** The watchdog: a frame the compositor hasn't answered in time stops pacing the next. */
    private fun turn(): Int {
        synchronized(lock) {
            if (destroyed || events.lost || frameCallback.address() == 0L) return -1
            val waited = (System.nanoTime() - frameSentNanos) / 1_000_000
            val limit = if (frameAckMisses > MAX_FRAME_ACK_MISSES) STALLED_FRAME_MS else FRAME_ACK_TIMEOUT_MS
            if (waited < limit) return (limit - waited).toInt().coerceAtLeast(1)
            Wl.forget(frameCallback)
            frameCallback = MemorySegment.NULL
            frameAckMisses++
            if (!wanted || scheduled) return -1
            scheduled = true
        }
        SwingUtilities.invokeLater(::frame)
        return -1
    }

    private fun waitForEvents(timeoutMs: Int) {
        if (synchronized(lock) { destroyed }) return
        events.await(timeoutMs)
    }

    /**
     * Frees everything, the subsurface before the window's surface goes. On the UI thread; once. When the loop doesn't
     * end in time, what it can still touch (the queue, its registry and frame callback, the wake-up fd) is left alive.
     */
    fun destroy() {
        synchronized(lock) {
            if (destroyed) return
            destroyed = true
        }
        val joined = loop.shutdownAndJoin(SHUTDOWN_TIMEOUT_MS)
        if (eglContext.address() != 0L && eglSurface.address() != 0L && Egl.makeCurrent(eglDisplay, eglSurface, eglContext)) {
            canvasSurface?.close()
            target?.close()
            skia?.close()
        }
        if (eglDisplay.address() != 0L) Egl.releaseCurrent(eglDisplay)
        if (eglSurface.address() != 0L) Egl.destroySurface(eglDisplay, eglSurface)
        if (eglContext.address() != 0L) Egl.destroyContext(eglDisplay, eglContext)
        if (eglWindow.address() != 0L) Egl.destroyWindow(eglWindow)
        for (proxy in listOf(viewport, subsurface, surface)) if (proxy.address() != 0L) Wl.destroy(proxy)
        if (viewporter.address() != 0L) Wl.destroy(viewporter)
        if (subcompositor.address() != 0L) Wl.destroy(subcompositor)
        if (compositor.address() != 0L) Wl.forget(compositor)
        Wl.flush(display)
        if (!joined) {
            System.getLogger(GlComposeLayer::class.java.name).log(System.Logger.Level.WARNING, "compose layer: its thread did not end; its queue is left")
            return
        }
        synchronized(lock) { if (frameCallback.address() != 0L) Wl.forget(frameCallback) }
        Wl.forget(registry)
        Wl.destroyWrapper(displayWrapper)
        Wl.flush(display)
        Wl.destroyQueue(queue)
        Posix.close(wakeFd)
    }

    companion object {
        /** Mesa's software rasterizers: Skia's CPU backend outdraws them, so Compose stays in Swing's software path. */
        private val SOFTWARE_RENDERERS = listOf("llvmpipe", "softpipe", "swrast")
        private const val FRAME_ACK_TIMEOUT_MS = 500L
        private const val MAX_FRAME_ACK_MISSES = 5
        private const val STALLED_FRAME_MS = 1000L
        private const val SHUTDOWN_TIMEOUT_MS = 1000L

        /**
         * Compose's drawing for [layer] (the Skiko layer of [window]'s Compose panel) on a subsurface of [parent] (the
         * window's `wl_surface`) on the window's Wayland connection [display]. On the UI thread. Throws with the reason
         * when the compositor or the GPU can't give one.
         */
        fun create(window: WaylandWindow, layer: SkiaSwingLayer, display: MemorySegment, parent: MemorySegment, onFrame: (Long) -> Unit): GlComposeLayer {
            val scene = SkiaSwingLayer::class.java.getDeclaredField("renderDelegateWithClipping")
                .apply { isAccessible = true }.get(layer) as SkikoRenderDelegate
            return GlComposeLayer(window, layer, scene, display, parent, onFrame).apply {
                try {
                    create()
                } catch (t: Throwable) {
                    runCatching { destroy() }
                    throw t
                }
            }
        }
    }
}

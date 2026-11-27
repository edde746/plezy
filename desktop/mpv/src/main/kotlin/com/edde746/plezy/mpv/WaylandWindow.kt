package com.edde746.plezy.mpv

import androidx.compose.runtime.Composable
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.awt.ComposePanel
import androidx.compose.ui.awt.RenderSettings
import com.edde746.plezy.mpv.os.Protocols
import com.edde746.plezy.mpv.os.Wl
import java.awt.AlphaComposite
import java.awt.BorderLayout
import java.awt.Component
import java.awt.Container
import java.awt.Graphics
import java.awt.Graphics2D
import java.awt.Rectangle
import java.awt.Toolkit
import java.awt.Window
import java.awt.geom.AffineTransform
import java.lang.foreign.MemorySegment
import java.util.WeakHashMap
import java.util.concurrent.CopyOnWriteArrayList
import javax.swing.JComponent
import javax.swing.JFrame
import javax.swing.JPanel
import javax.swing.RepaintManager
import javax.swing.SwingUtilities
import kotlin.math.ceil
import kotlin.math.floor
import org.jetbrains.skiko.swing.SkiaSwingLayer

/**
 * The app's window in a Wayland session: a native Wayland toplevel (JetBrains Runtime's WLToolkit) holding Compose in a
 * [ComposePanel], since Skiko's own window surface needs X11. The window's buffer carries alpha, and its root paints the
 * background everywhere but the [videoHole], which it clears: the video plane under the window
 * ([com.edde746.plezy.mpv.video.VideoPlane]) shows there, under Compose's transparent pixels. Swing's double buffer is
 * off for the window, since its back buffer is opaque and would cover the hole.
 *
 * Compose draws on the GPU where it can ([GlComposeLayer]: Skia's OpenGL ES backend on a subsurface above the
 * window's surface, its frames paced by the compositor), and Swing's repaint manager hands Compose's repaints there, so
 * Swing paints only the background and the hole. Where it can't (no EGL, a compositor without viewporter, Mesa's
 * software rasterizer, or `-Dplezy.compose.renderer=software`), Compose draws in software through Swing's graphics
 * ([RenderSettings.SwingGraphics]); Swing then paints as soon as anything is dirty, so while something animates
 * Compose redraws as fast as the CPU allows, which the compositor shows at most once per refresh.
 */
@OptIn(ExperimentalComposeUiApi::class)
class WaylandWindow : JFrame() {
    val compose = ComposePanel(renderSettings = RenderSettings.SwingGraphics())
    private val paints = CopyOnWriteArrayList<() -> Unit>()
    private val frameStats = LongArray(3) // count, total ns, longest ns; guarded by itself
    private val log = System.getLogger(WaylandWindow::class.java.name)

    /** Compose's GPU drawing while it runs (UI thread). */
    private var gpu: GlComposeLayer? = null
    private var gpuTried = false
    /** The repaint manager [gpu] replaced, put back when it stops. */
    private var swingRepaints: RepaintManager? = null

    /** Where the video plane is, in the window's coordinates; null while it shows none. */
    @Volatile internal var videoHole: Rectangle? = null
        set(value) {
            if (field == value) return
            field = value
            // During Compose's frame (its layout places the plane): that frame lands with the window's commit.
            if (SwingUtilities.isEventDispatchThread()) gpu?.syncWithWindow()
            repaint()
        }

    private val root = object : JPanel(BorderLayout()) {
        override fun paintComponent(g: Graphics) {
            paints.forEach { it() }
            val g2 = g.create() as Graphics2D
            try {
                g2.color = this@WaylandWindow.background
                g2.fillRect(0, 0, width, height)
                videoHole?.let { hole ->
                    val at = SwingUtilities.convertPoint(this@WaylandWindow, hole.x, hole.y, this)
                    // In device pixels: Java2D has no loop clearing a scaled (parallelogram) fill on this surface.
                    val t = g2.transform
                    val x0 = floor(t.translateX + at.x * t.scaleX).toInt()
                    val y0 = floor(t.translateY + at.y * t.scaleY).toInt()
                    val x1 = ceil(t.translateX + (at.x + hole.width) * t.scaleX).toInt()
                    val y1 = ceil(t.translateY + (at.y + hole.height) * t.scaleY).toInt()
                    g2.transform = AffineTransform()
                    g2.composite = AlphaComposite.Clear
                    g2.fillRect(x0, y0, x1 - x0, y1 - y0)
                }
            } finally {
                g2.dispose()
            }
        }

        // Compose draws in here: on its GPU layer, or through Swing's graphics into the window's buffer.
        override fun paintChildren(g: Graphics) {
            val layer = gpu ?: startGpu()
            if (layer != null) {
                try {
                    layer.paint()
                } catch (t: Throwable) {
                    stopGpu(t)
                }
                return
            }
            val start = System.nanoTime()
            super.paintChildren(g)
            recordFrame(System.nanoTime() - start)
        }
    }

    init {
        RepaintManager.currentManager(this).isDoubleBufferingEnabled = false
        rootPane.isOpaque = false
        root.isOpaque = false
        compose.isOpaque = false
        root.add(compose, BorderLayout.CENTER)
        contentPane = root
    }

    fun setContent(content: @Composable () -> Unit) = compose.setContent(content)

    /** Runs [hook] on the UI thread at each paint of the window, which is followed by the window's commit. */
    internal fun onPaint(hook: () -> Unit) {
        paints += hook
    }

    internal fun removeOnPaint(hook: () -> Unit) {
        paints -= hook
    }

    /**
     * A paint of the window soon (one pixel of its background), which its commit follows: what a subsurface in
     * synchronized mode waits for (the video plane's frames, and Compose's [GlComposeLayer] renders its frame in it).
     * Any thread.
     */
    internal fun requestCommit() = root.repaint(0, 0, 1, 1)

    /**
     * Physical pixels per unit of the window's `wl_surface` (its subsurfaces' positions and viewport destinations):
     * the toolkit's display scale. AWT's units are physical pixels over `defaultTransform`'s scale, which differs from
     * it under `sun.java2d.uiScale`.
     */
    internal fun surfaceScale(): Double = (displayScale.invoke(graphicsConfiguration) as Int).toDouble()

    private val displayScale by lazy { Class.forName("sun.awt.wl.WLGraphicsConfig").getMethod("getDisplayScale") }

    /**
     * Starts Compose's GPU drawing once the window has its `wl_surface` and Compose its Skia layer; null (and Compose in
     * software for good) when it can't, saying why.
     */
    private fun startGpu(): GlComposeLayer? {
        if (gpuTried) return null
        val parent = WaylandSession.surface(this) ?: return null
        val layer = compose.skiaLayer() ?: return null
        gpuTried = true
        if (System.getProperty("plezy.compose.renderer") == "software") {
            log.log(System.Logger.Level.INFO, "Compose draws in software (plezy.compose.renderer=software)")
            return null
        }
        val started = try {
            GlComposeLayer.create(this, layer, WaylandSession.display(), parent, ::recordFrame)
        } catch (t: Throwable) {
            log.log(System.Logger.Level.INFO, "Compose draws in software: {0}", t.message ?: t.toString())
            return null
        }
        gpu = started
        swingRepaints = RepaintManager.currentManager(this)
        RepaintManager.setCurrentManager(GpuRepaints(started))
        log.log(System.Logger.Level.INFO, "Compose draws on the GPU: {0}", started.renderer)
        // Whatever Compose drew in software before goes: the window's surface keeps only the background and the hole.
        repaint()
        return started
    }

    /** Compose goes back to Swing's software drawing: GPU drawing failed ([failure]) or the window goes away. */
    private fun stopGpu(failure: Throwable?) {
        val layer = gpu ?: return
        gpu = null
        swingRepaints?.let(RepaintManager::setCurrentManager)
        swingRepaints = null
        if (failure != null) log.log(System.Logger.Level.ERROR, "Compose's GPU drawing failed; it draws in software from now on", failure)
        layer.destroy()
        repaint()
    }

    override fun removeNotify() {
        stopGpu(null)
        gpuTried = false
        super.removeNotify()
    }

    private fun recordFrame(nanos: Long) = synchronized(frameStats) {
        frameStats[0]++
        frameStats[1] += nanos
        frameStats[2] = maxOf(frameStats[2], nanos)
    }

    /**
     * Compose's frames since the last call: how many, their mean and longest time to render in milliseconds, and
     * where they rendered (`gpu`, with the OpenGL renderer, or `software`). For diagnostics.
     */
    fun takePaintStats(): Map<String, Any> = synchronized(frameStats) {
        val (count, total, longest) = frameStats.toList()
        frameStats.fill(0)
        linkedMapOf(
            "paints" to count, "meanMs" to if (count == 0L) 0.0 else total / count / 1e6, "maxMs" to longest / 1e6,
            "renderer" to (gpu?.let { "gpu: ${it.renderer}" } ?: "software"),
        )
    }

    /** Swing's repaint manager while Compose draws on the GPU: repaints of Compose's components are [gpu]'s frames. */
    private inner class GpuRepaints(private val layer: GlComposeLayer) : RepaintManager() {
        init {
            isDoubleBufferingEnabled = false
        }

        override fun addDirtyRegion(c: JComponent, x: Int, y: Int, w: Int, h: Int) {
            if (SwingUtilities.isDescendingFrom(c, compose)) layer.requestFrame() else super.addDirtyRegion(c, x, y, w, h)
        }
    }
}

/** The Skia layer Compose draws through, once the panel has built it. */
private fun Container.skiaLayer(): SkiaSwingLayer? =
    components.firstNotNullOfOrNull { it as? SkiaSwingLayer ?: (it as? Container)?.skiaLayer() }

/**
 * The Wayland session the app runs in natively, through JetBrains Runtime's WLToolkit; X11 sessions (and Windows) run
 * on AWT's other toolkits. [useNativeToolkit] picks the toolkit before AWT starts; [active] says which it got.
 */
object WaylandSession {
    private const val TOOLKIT = "sun.awt.wl.WLToolkit"

    /**
     * On Linux with a Wayland session (`WAYLAND_DISPLAY`), makes AWT a native Wayland client. Call before anything
     * touches AWT. The runtime presets `awt.toolkit.name` to `XToolkit` itself, so the choice overrides it.
     *
     * AWT then draws at each output's `wl_output.scale`, which compositors round up at a fractional scale (2 at
     * 125 %), and the compositor scales the window down to the output's own scale, as it does GTK's windows. Never
     * `sun.java2d.uiScale` here: the runtime draws at that scale but still presents its buffers at the output's whole
     * scale, which shrinks the window by their ratio (to 62.5 % at 125 %).
     */
    fun useNativeToolkit() {
        if (!System.getProperty("os.name").startsWith("Linux") || System.getenv("WAYLAND_DISPLAY").isNullOrEmpty()) return
        System.setProperty("awt.toolkit.name", "WLToolkit")
    }

    /** AWT runs on WLToolkit: the windows are native Wayland toplevels. */
    val active: Boolean by lazy { System.getProperty("os.name").startsWith("Linux") && Toolkit.getDefaultToolkit().javaClass.name == TOOLKIT }

    /** AWT's Wayland connection (`wl_display`). */
    internal fun display(): MemorySegment {
        val cls = Class.forName("sun.awt.wl.WLDisplay")
        return MemorySegment.ofAddress(cls.getMethod("getDisplayPtr").invoke(cls.getMethod("getInstance").invoke(null)) as Long)
    }

    /**
     * The compositor can show an HDR video plane: its colour manager (color-management-v1) takes parametric
     * descriptions, the perceptual intent, BT.2020 primaries and the PQ curve. Whether the output is in HDR mode is
     * a playback's own question (the plane asks the compositor for its output's description).
     */
    val compositorDescribesHdr: Boolean by lazy {
        if (!active) return@lazy false
        val display = display()
        val queue = Wl.createQueue(display)
        val wrapper = Wl.wrapper(display, queue)
        try {
            var manager = MemorySegment.NULL
            val seen = mutableSetOf<String>()
            val registry = Wl.globals(wrapper) { global ->
                if (global.iface == "wp_color_manager_v1" && manager.address() == 0L) {
                    manager = global.bind(Protocols["wp_color_manager_v1"], 1)
                    // supported_intent 0 perceptual, supported_feature 1 parametric, tf_named 11 PQ, primaries_named 6 BT.2020.
                    Wl.listen(manager) { event, values -> seen += "$event:${values.uint(0)}" }
                }
            }
            Wl.roundtrip(display, queue)
            Wl.roundtrip(display, queue)
            Wl.forget(registry)
            if (manager.address() != 0L) Wl.destroy(manager, 0)
            seen.containsAll(listOf("0:0", "1:1", "2:11", "3:6"))
        } finally {
            Wl.destroyWrapper(wrapper)
            Wl.destroyQueue(queue)
        }
    }

    /** [window]'s `wl_surface`, or null while it has none (not shown yet). */
    internal fun surface(window: Window): MemorySegment? {
        val accessor = Class.forName("sun.awt.AWTAccessor").getMethod("getComponentAccessor").invoke(null)
        val peer = Class.forName("sun.awt.AWTAccessor\$ComponentAccessor").getMethod("getPeer", Component::class.java).invoke(accessor, window) ?: return null
        val surface = peer.javaClass.getMethod("getSurface").invoke(peer) ?: return null
        val ptr = surface.javaClass.getMethod("getWlSurfacePtr").invoke(surface) as Long
        return if (ptr == 0L) null else MemorySegment.ofAddress(ptr)
    }

    /** Each window's decoration palette object ([useDecorationPalette]), kept for the window's lifetime. */
    private val palettes: MutableMap<Window, MemorySegment> = WeakHashMap()

    /**
     * Asks KWin to draw [window]'s server-side title bar and frame in the colour scheme [scheme] (KDE's decoration
     * palette, a scheme file's path), as the X11 path's hint does; again with another scheme as the app's theme
     * changes. False where the compositor has no such protocol (it draws its own default). On the AWT event thread.
     */
    internal fun useDecorationPalette(window: Window, scheme: String): Boolean {
        palettes[window]?.let { palette ->
            Wl.request(palette, 0, scheme)
            Wl.flush(display())
            return true
        }
        val surface = surface(window) ?: return false
        val display = display()
        val queue = Wl.createQueue(display)
        val wrapper = Wl.wrapper(display, queue)
        // The palette, when there is one, lives on this queue for the window's lifetime.
        var palette = MemorySegment.NULL
        try {
            var manager = MemorySegment.NULL
            val registry = Wl.globals(wrapper) { global ->
                if (global.iface == "org_kde_kwin_server_decoration_palette_manager") {
                    manager = global.bind(Protocols["org_kde_kwin_server_decoration_palette_manager"], 1)
                }
            }
            Wl.roundtrip(display, queue)
            Wl.forget(registry)
            if (manager.address() == 0L) return false
            // The palette object stays for the window's lifetime: releasing it puts the default palette back.
            palette = Wl.request(manager, 0, null, surface, newInterface = Protocols["org_kde_kwin_server_decoration_palette"])
            Wl.request(palette, 0, scheme)
            Wl.forget(manager)
            Wl.flush(display)
            palettes[window] = palette
            return true
        } finally {
            Wl.destroyWrapper(wrapper)
            if (palette.address() == 0L) Wl.destroyQueue(queue)
        }
    }
}

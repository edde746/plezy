package com.edde746.plezy.mpv.video

import androidx.compose.foundation.layout.Box
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.edde746.plezy.mpv.core.MpvCore
import com.edde746.plezy.mpv.os.Dxgi
import com.edde746.plezy.mpv.os.Win32
import com.edde746.plezy.playback.HardwareDecoder
import java.awt.Component
import java.awt.Window
import java.awt.event.ComponentAdapter
import java.awt.event.ComponentEvent
import java.util.concurrent.CompletableFuture
import java.util.concurrent.TimeUnit

/**
 * Windows: mpv (`vo=gpu-next`, d3d11) renders into a disabled child of the Skiko canvas HWND, and Compose draws
 * above it through Skiko's DirectComposition swapchain (`compose.interop.blending=true`, set by the app before Compose
 * starts), so transparent Compose pixels show the video. The child's own window class paints it black until mpv's first
 * frame (a system control such as `STATIC` paints the system's light grey). `WS_DISABLED` sends all mouse input over the
 * video to the canvas (Compose); mpv never sees input.
 *
 * The child lives on its own thread with its own message pump: AWT never pumps windows it did not create, and
 * DestroyWindow must run on the creating thread. It is sized from the canvas client rect rather than Compose bounds,
 * which come out 1 px short at 150 % scaling.
 *
 * While a host's child window exists the process is exempt from Windows power throttling (EcoQoS and ignored timer
 * resolution). Without that, a window behind others with nothing audible (muted, or no audio device) played 4K60 HDR10
 * at 0.2× real time with ~4 dropped frames/s on a Ryzen 5 7600X with an RTX 4090; exempt, it plays at 1.0× with no
 * drops after the start.
 * The exemption is one switch for the whole process, so the hosts count themselves: the last one gone hands it back,
 * and a previous playback's slow teardown can't clear it under the next one.
 */
internal class Win32VideoHost : VideoHost {
    @Volatile private var hwnd = 0L
    @Volatile private var canvasHwnd = 0L
    @Volatile private var pumpThreadId = 0
    private var pump: Thread? = null
    /** Completes on the pump thread once its child exists (0 if creation failed); its message queue exists by then. */
    private var created: CompletableFuture<Long>? = null
    private var canvas: Component? = null
    /** Guarded by [Companion]: this host counts in [exemptHosts]; [destroyed] once its child is gone or going. */
    private var exempting = false
    private var destroyed = false
    private val fitOnResize = object : ComponentAdapter() {
        override fun componentResized(e: ComponentEvent) = fit()
    }
    private val log = System.getLogger(Win32VideoHost::class.java.name)

    override fun attach(window: Window, onReady: () -> Unit): Boolean {
        if (canvas != null) return true
        // Skiko's HardwareLayer is the heavyweight canvas (the HWND DirectComposition presents to); it is
        // Kotlin-internal, so its public getContentHandle() is called reflectively.
        val layer = findComponent(window, "org.jetbrains.skiko.HardwareLayer") ?: return false
        val parent = layer.javaClass.getMethod("getContentHandle").invoke(layer) as Long
        if (parent == 0L) return false
        canvas = layer
        canvasHwnd = parent
        val created = CompletableFuture<Long>().also { this.created = it }
        pump = Thread({
            val child = Win32.createChild(
                parent, hostClass,
                Win32.WS_CHILD or Win32.WS_VISIBLE or Win32.WS_CLIPSIBLINGS or Win32.WS_DISABLED,
                Win32.WS_EX_NOPARENTNOTIFY,
            )
            pumpThreadId = Win32.currentThreadId()
            created.complete(child)
            if (child == 0L) return@Thread
            Win32.pump { msg ->
                if (msg != DESTROY) return@pump false
                Win32.hide(child)
                Win32.destroy(child)
                true
            }
        }, "mpv-video-host").apply { isDaemon = true; start() }
        created.thenAccept { child ->
            hwnd = child
            fit()
            holdExemption()
            onReady()
        }
        layer.addComponentListener(fitOnResize)
        return true
    }

    override val hardwareDecoder = HardwareDecoder.WINDOWS

    override fun options(): Map<String, String> {
        val child = hwnd
        check(child != 0L) { "could not create the video host window (CreateWindowExW)" }
        val qualcomm = Dxgi.hasQualcommGpu
        log.log(System.Logger.Level.INFO, if (qualcomm) "hdr-config: Qualcomm GPU: hdr-compute-peak=no, vf=format:hdr10plus=no" else "hdr-config: hdr-compute-peak=auto")
        return options(child, qualcomm)
    }

    /** The options for mpv rendering into the window [child], on a system with a Qualcomm GPU when [qualcomm]. */
    internal fun options(child: Long, qualcomm: Boolean = false): Map<String, String> = linkedMapOf(
        "wid" to child.toString(),
        "vo" to "gpu-next",
        "gpu-api" to "d3d11",
        // The System Media Transport Controls own the media keys, not mpv.
        "input-media-keys" to "no",
        // HDR passthrough when Windows HDR is on; tone-mapped otherwise.
        "target-colorspace-hint" to "auto",
        // Black stays absolute black. Under `auto` mpv's d3d11 output takes the
        // black level Windows reports for the display (DXGI MinLuminance) as the target's, and libplacebo since
        // b915882d honours it for PQ output instead of sending zero nits: on a TV whose reported floor sits above
        // what it shows, every video's blacks and shadows come out lifted against black letterbox bars. An HDR10
        // display maps PQ itself. A user's `--mpv-opt target-contrast=…` still wins.
        "target-contrast" to "inf",
        "tone-mapping" to "auto",
        // libplacebo regenerates its tone-mapping LUT whenever the frame's HDR metadata moves, which peak detection and
        // HDR10+ per-scene metadata do every frame. Qualcomm's D3D11 driver has no host-visible upload path, so each
        // regeneration costs tens of milliseconds (4K HDR to SDR drops to single-digit fps and flickers): there both
        // sources are silenced and tone mapping uses the static HDR10 mastering metadata.
        "hdr-compute-peak" to if (qualcomm) "no" else "auto",
    ).apply {
        if (qualcomm) put("vf", "format:hdr10plus=no")
    }

    override fun bind(core: MpvCore, onVideoReady: (error: String?) -> Unit) = onVideoReady(null)

    /** Dispose order: the event loop has stopped; destroy the host window, then mpv terminates. */
    override fun unbind(core: MpvCore) = destroyChild()

    /** mpv renders into the child window on its own thread: nothing of the core is left here once [unbind] returns. */
    override fun awaitUnbound() = true

    override fun close() = destroyChild()

    private fun destroyChild() {
        canvas?.removeComponentListener(fitOnResize)
        synchronized(Companion) { destroyed = true }
        val thread = pump ?: return
        // A close right after attach can come before the pump thread has its child, or before [hwnd] is set from it:
        // wait for the creation itself, then post DESTROY whenever a child exists, so the pump always gets to end.
        val child = runCatching { created?.get(3, TimeUnit.SECONDS) }.getOrNull()
        if (child == null) log.log(System.Logger.Level.ERROR, "video host window creation didn't finish within 3 s: the child may outlive its player")
        else if (child != 0L && !Win32.postThreadMessage(pumpThreadId, DESTROY)) log.log(System.Logger.Level.ERROR, "could not post DESTROY to the video host thread")
        thread.join(3000)
        if (thread.isAlive) log.log(System.Logger.Level.ERROR, "video host thread didn't end within 3 s: its child window is left over the canvas")
        created = null
        hwnd = 0L
        pump = null
        releaseExemption()
    }

    /** Counts this host among those keeping the process exempt from power throttling; the first one asks Windows. */
    private fun holdExemption() {
        synchronized(Companion) {
            if (exempting || destroyed) return
            exempting = true
            if (exemptHosts++ == 0 && !Win32.exemptFromPowerThrottling(true)) log.log(System.Logger.Level.WARNING, "power throttling exemption failed")
        }
    }

    /** This host no longer counts; the last one hands the decision back to Windows. */
    private fun releaseExemption() {
        synchronized(Companion) {
            if (!exempting) return
            exempting = false
            if (--exemptHosts == 0) Win32.exemptFromPowerThrottling(false)
        }
    }

    private fun fit() {
        val child = hwnd
        if (child == 0L) return
        val client = Win32.clientRect(canvasHwnd)
        Win32.setPos(
            child, 0, 0, client.width.coerceAtLeast(1), client.height.coerceAtLeast(1),
            Win32.SWP_NOZORDER or Win32.SWP_NOACTIVATE or Win32.SWP_ASYNCWINDOWPOS,
        )
    }

    @Composable
    override fun Content(modifier: Modifier) = Box(modifier)

    private companion object {
        const val DESTROY = Win32.WM_APP + 1

        /** The hosts whose child window exists ([holdExemption]); guarded by this object. */
        var exemptHosts = 0

        /** The child's window class, registered once per process. */
        val hostClass by lazy { "PlezyVideoHost".also(Win32::registerBlackClass) }
    }
}

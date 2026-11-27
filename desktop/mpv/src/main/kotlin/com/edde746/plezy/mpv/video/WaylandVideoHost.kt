package com.edde746.plezy.mpv.video

import androidx.compose.foundation.layout.Box
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.LayoutCoordinates
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.layout.positionInRoot
import com.edde746.plezy.mpv.WaylandSession
import com.edde746.plezy.mpv.WaylandWindow
import com.edde746.plezy.mpv.core.MpvCore
import com.edde746.plezy.mpv.video.hdr.HdrToneMapping
import com.edde746.plezy.mpv.video.hdr.parseSourceHdrMetadata
import com.edde746.plezy.mpv.video.hdr.planeRect
import com.edde746.plezy.mpv.video.hdr.toHdrMetadata
import com.edde746.plezy.playback.HardwareDecoder
import java.awt.Rectangle
import java.awt.Window
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import javax.swing.SwingUtilities
import kotlin.math.floor
import kotlinx.coroutines.delay

/**
 * Linux in a Wayland session: `vo=libmpv` rendering into a [VideoPlane] under the [WaylandWindow], the only way video
 * shows on Linux. The video composable is transparent (black until mpv's first frame) and places the plane over its
 * own bounds, and the window clears its background there. The plane's colour management follows the app's HDR
 * permission ([setHdrOutput]), the tone-mapping choice ([setToneMapping]) and the source's `video-params`.
 */
internal class WaylandVideoHost : VideoHost {
    @Volatile private var window: WaylandWindow? = null
    @Volatile private var plane: VideoPlane? = null
    @Volatile private var planeError: String? = null
    @Volatile private var bound = false
    private val unbound = CountDownLatch(1)
    @Volatile private var hdrAllowed = false
    @Volatile private var toneMapping = HdrToneMapping.COMPOSITOR
    private val parentPainted: () -> Unit = { plane?.parentFrame() }

    override fun attach(window: Window, onReady: () -> Unit): Boolean {
        if (this.window != null) return true
        val frame = window as? WaylandWindow ?: error("the Wayland video plane needs the app's WaylandWindow, not ${window.javaClass.name}")
        val parent = WaylandSession.surface(frame) ?: return false
        this.window = frame
        try {
            plane = VideoPlane.create(WaylandSession.display(), parent, frame::requestCommit).also {
                it.setHdrAllowed(hdrAllowed)
                it.setToneMapping(toneMapping)
            }
            frame.onPaint(parentPainted)
        } catch (t: Throwable) {
            System.getLogger(javaClass.name).log(System.Logger.Level.ERROR, "the video plane could not start", t)
            planeError = t.message ?: t.toString()
        }
        onReady()
        return true
    }

    override fun options(): Map<String, String> = linkedMapOf(
        "vo" to "libmpv",
        // Peak detection costs nothing while the compositor tone-maps and adapts mpv's own tone mapping once it does.
        "hdr-compute-peak" to "auto",
    )

    override val hardwareDecoder = HardwareDecoder.LINUX

    override fun bind(core: MpvCore, onVideoReady: (error: String?) -> Unit) {
        val p = plane
        if (p == null) {
            onVideoReady(planeError ?: "no video plane")
            return
        }
        bound = true
        onVideoReady(p.attach(core))
    }

    override fun unbind(core: MpvCore) {
        val p = plane
        if (p != null && bound) p.detach(unbound) else unbound.countDown()
    }

    override fun awaitUnbound(): Boolean {
        val freed = unbound.await(UNBIND_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        val destroyed = destroyPlane()
        if (!freed || !destroyed) {
            System.getLogger(javaClass.name).log(System.Logger.Level.ERROR, "the video plane did not let go of mpv: the plane and the mpv core are left alive")
        }
        return freed && destroyed
    }

    /** With a bound core the plane goes in [awaitUnbound], after the render context; without one, here. */
    override fun close() {
        if (!bound) destroyPlane()
    }

    private fun destroyPlane(): Boolean {
        val p = plane ?: return true
        plane = null
        window?.let { w ->
            w.removeOnPaint(parentPainted)
            SwingUtilities.invokeLater { w.videoHole = null }
        }
        return p.destroy()
    }

    override fun videoParams(json: String?) {
        plane?.setSource(parseSourceHdrMetadata(json).toHdrMetadata())
    }

    override fun playbackRestarted() {
        plane?.playbackRestarted()
    }

    override fun setHdrOutput(enabled: Boolean): Boolean {
        hdrAllowed = enabled
        plane?.setHdrAllowed(enabled)
        return true
    }

    /** The plane's own answer once it exists (a 10-bit surface the compositor can describe), else the compositor's. */
    override val carriesHdr: Boolean get() = plane?.supportsHdr ?: WaylandSession.compositorDescribesHdr

    override fun setToneMapping(player: Boolean) {
        toneMapping = if (player) HdrToneMapping.PLAYER else HdrToneMapping.COMPOSITOR
        plane?.setToneMapping(toneMapping)
    }

    override fun stats(): Map<String, Any?> = plane?.stats() ?: mapOf("error" to planeError)

    @Composable
    override fun Content(modifier: Modifier) {
        var firstFrame by remember { mutableStateOf(false) }
        LaunchedEffect(Unit) {
            while (plane?.firstFramePresented != true) delay(FIRST_FRAME_POLL_MS)
            firstFrame = true
        }
        DisposableEffect(Unit) {
            onDispose {
                plane?.setVisible(false)
                window?.videoHole = null
            }
        }
        Box(
            modifier
                .onGloballyPositioned(::place)
                .drawBehind { if (!firstFrame) drawRect(Color.Black) },
        )
    }

    /**
     * The plane over the video's bounds, in the window's surface units (on the UI thread, before the window's commit),
     * and the window's hole there, in AWT's units. The plane sizes its buffer itself ([VideoPlane.setRect]).
     */
    private fun place(coordinates: LayoutCoordinates) {
        val w = window ?: return
        val p = plane ?: return
        val scale = w.graphicsConfiguration.defaultTransform.scaleX
        val panel = SwingUtilities.convertPoint(w.compose, 0, 0, w)
        val at = coordinates.positionInRoot()
        val size = coordinates.size
        if (size.width <= 0 || size.height <= 0) return
        val x = floor(panel.x * scale + at.x).toInt()
        val y = floor(panel.y * scale + at.y).toInt()
        val surfaceScale = w.surfaceScale()
        val r = planeRect(x = x, y = y, width = size.width, height = size.height, scale = surfaceScale)
        p.setRect(r.x, r.y, r.width, r.height, surfaceScale)
        p.setVisible(true)
        val hole = planeRect(x = x, y = y, width = size.width, height = size.height, scale = scale)
        w.videoHole = Rectangle(hole.x, hole.y, hole.width, hole.height)
    }

    private companion object {
        const val UNBIND_TIMEOUT_SECONDS = 10L
        const val FIRST_FRAME_POLL_MS = 50L
    }
}

/** Linux outside a Wayland session: the app runs, but video fails, saying why, as in an X11 session. */
internal class UnsupportedVideoHost(private val reason: String) : VideoHost {
    override fun attach(window: Window, onReady: () -> Unit): Boolean {
        onReady()
        return true
    }

    override fun options(): Map<String, String> = linkedMapOf("vo" to "null")

    override val hardwareDecoder = HardwareDecoder.LINUX

    override fun bind(core: MpvCore, onVideoReady: (error: String?) -> Unit) = onVideoReady(reason)

    override val carriesHdr = false

    override fun unbind(core: MpvCore) = Unit

    override fun awaitUnbound() = true

    override fun close() = Unit

    @Composable
    override fun Content(modifier: Modifier) = Box(modifier.drawBehind { drawRect(Color.Black) })

    companion object {
        /** The message an X11 session's playback fails with. */
        const val X11_SESSION = "Video needs a Wayland session. This looks like an X11 session; log in under Wayland, or run X11 applications through XWayland instead."
    }
}

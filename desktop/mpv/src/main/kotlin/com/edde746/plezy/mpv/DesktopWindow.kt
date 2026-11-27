package com.edde746.plezy.mpv

import androidx.compose.ui.awt.ComposeWindow
import androidx.compose.ui.window.WindowPlacement
import com.edde746.plezy.mpv.os.WinRect
import com.edde746.plezy.mpv.os.Win32
import com.edde746.plezy.mpv.os.X11
import java.awt.AWTEvent
import java.awt.Component
import java.awt.Dialog
import java.awt.Frame
import java.awt.GraphicsEnvironment
import java.awt.Rectangle
import java.awt.Toolkit
import java.awt.Window
import java.awt.event.HierarchyEvent
import java.util.WeakHashMap
import javax.swing.JFrame
import javax.swing.SwingUtilities
import kotlin.math.roundToInt

/**
 * Per-OS window behaviour for the player window. Call from the AWT event thread.
 *
 * Fullscreen on Windows is borderless, done in Win32: strip the caption and frame styles, then cover the monitor with
 * `SetWindowPos(SWP_FRAMECHANGED)`. Never Compose's `WindowPlacement.Fullscreen` there: in AWT exclusive fullscreen
 * Skiko clears its layer opaque (the video goes black) and leaving it restored the window at the wrong size at 150 %.
 * On Linux the compositor's fullscreen is used: AWT's full-screen window under Wayland ([WaylandWindow]), Compose's
 * fullscreen placement under X11; with JetBrains Runtime both track the window manager. A window maximized before it
 * went fullscreen is maximized again as it leaves (leaving restores the floating size otherwise).
 */
class DesktopWindow(private val window: JFrame) {
    private var savedStyle = 0L
    /** Linux: the window was maximized as it went fullscreen. */
    private var maximizedBefore = false
    private var savedRect: WinRect? = null

    var isFullscreen: Boolean = false
        private set

    fun setFullscreen(fullscreen: Boolean) {
        if (fullscreen == isFullscreen) return
        if (!isWindows) {
            if (fullscreen) maximizedBefore = window.extendedState and Frame.MAXIMIZED_BOTH == Frame.MAXIMIZED_BOTH
            if (window is ComposeWindow) {
                window.placement = when {
                    fullscreen -> WindowPlacement.Fullscreen
                    maximizedBefore -> WindowPlacement.Maximized
                    else -> WindowPlacement.Floating
                }
            } else {
                window.graphicsConfiguration.device.fullScreenWindow = if (fullscreen) window else null
                if (!fullscreen && maximizedBefore) window.extendedState = window.extendedState or Frame.MAXIMIZED_BOTH
            }
        } else {
            val frame = Peers.hwnd(window)
            if (fullscreen) {
                savedStyle = Win32.style(frame)
                savedRect = Win32.windowRect(frame)
                val frameStyles = Win32.WS_CAPTION or Win32.WS_THICKFRAME or Win32.WS_SYSMENU or Win32.WS_MINIMIZEBOX or Win32.WS_MAXIMIZEBOX
                Win32.setStyle(frame, savedStyle and frameStyles.toLong().inv())
                val m = Win32.monitorRect(frame)
                Win32.setPos(frame, m.left, m.top, m.width, m.height, Win32.SWP_FRAMECHANGED)
            } else {
                Win32.setStyle(frame, savedStyle)
                val r = checkNotNull(savedRect)
                Win32.setPos(frame, r.left, r.top, r.width, r.height, Win32.SWP_FRAMECHANGED)
            }
        }
        isFullscreen = fullscreen
    }

    /**
     * The window's outer rect `[x, y, width, height]` in physical pixels. On Linux, fullscreen windows have no
     * decorations (KWin drops them) while AWT keeps the windowed insets, so the frame is the content area then.
     */
    fun frameRect(): List<Int> = when {
        isWindows -> Win32.windowRect(Peers.hwnd(window)).toList()
        isFullscreen -> contentRect() ?: physical(window.bounds)
        else -> physical(window.bounds)
    }

    /**
     * The content area (what Compose draws, inside the frame's decorations) `[x, y, width, height]` in screen pixels on
     * Linux (the report's probes are relative to it); null on Windows, whose AWT coordinates are scaled (the Windows
     * harness asks Win32 instead). Under Wayland a client never learns its window's position, and the compositor draws
     * the title bar outside the window: the origin is 0, 0 there, and the Linux harness asks KWin where the window is.
     */
    fun contentRect(): List<Int>? {
        if (isWindows || !window.isShowing) return null
        val pane = window.contentPane
        val origin = pane.locationOnScreen
        return physical(Rectangle(origin.x, origin.y, pane.width, pane.height))
    }

    /** The monitor under the window, `[x, y, width, height]` in physical pixels. */
    fun monitorRect(): List<Int> =
        if (isWindows) Win32.monitorRect(Peers.hwnd(window)).toList()
        else physical(window.graphicsConfiguration.bounds)

    /** AWT's units on Linux in physical pixels: times AWT's own scale (see [composeScale]). */
    private fun physical(r: Rectangle): List<Int> {
        val s = window.graphicsConfiguration.defaultTransform.scaleX
        return listOf((r.x * s).roundToInt(), (r.y * s).roundToInt(), (r.width * s).roundToInt(), (r.height * s).roundToInt())
    }

    /** Whether the window's system chrome is dark ([useChrome]), read back from the OS. */
    fun hasDarkChrome(): Boolean = hasDarkChrome(window)

    companion object {
        /** The factor Compose applies on top of AWT's own scale ([composeScale]). */
        val uiScale: Float by lazy {
            val x11 = System.getProperty("os.name").startsWith("Linux") && !WaylandSession.active
            val awt = GraphicsEnvironment.getLocalGraphicsEnvironment().defaultScreenDevice.defaultConfiguration.defaultTransform.scaleX
            composeScale(x11, if (x11) X11.xftScale() else null, awt)
        }

        /**
         * The factor Compose applies on top of AWT's scale [awtScale], so the app draws at the desktop's scale once.
         * Under X11 ([x11]) that scale is `Xft.dpi` / 96 ([xftScale]; KDE and GNOME set it to the whole scale, text
         * scaling included), of which AWT may already apply a part: JetBrains Runtime scales by a whole `Xft.dpi` / 96
         * or GNOME's scaling factor, times `GDK_SCALE` × `GDK_DPI_SCALE` (2 at 200 %, 1 at 150 %). Compose applies the
         * rest. Without `Xft.dpi`, AWT's scale alone. Under Wayland AWT draws at each output's scale and on Windows at
         * each monitor's: 1 there.
         */
        internal fun composeScale(x11: Boolean, xftScale: Double?, awtScale: Double): Float =
            if (x11 && xftScale != null) (xftScale / awtScale).toFloat() else 1f

        /**
         * Under X11, the class (`WM_CLASS`, its name and class both) of every window the app makes from now on is the
         * app's id the JVM was started with (`awt.app.id`: the desktop entry's id, which JetBrains Runtime gives a
         * Wayland window as its app id itself), not the main class's name AWT takes, so the desktop shows the windows as
         * the entry's app, as the earlier releases' GTK windows were. Nothing without that id, under Wayland or
         * elsewhere. Call on the AWT event thread before the first window is made; takes `--add-opens` of
         * `java.desktop/sun.awt.X11` (desktop/app/build.gradle.kts).
         */
        fun useAppId() {
            val id = System.getProperty("awt.app.id") ?: return
            if (!System.getProperty("os.name").startsWith("Linux") || WaylandSession.active) return
            // AWT names the class as its toolkit starts: after that.
            Toolkit.getDefaultToolkit()
            Class.forName("sun.awt.X11.XToolkit").getDeclaredField("awtAppClassName").apply { isAccessible = true }.set(null, id)
        }

        /** Kernel/GDI/USER handle counts on Windows (the libmpv handle leak check); empty elsewhere. */
        fun processHandleCounts(): Map<String, Int> =
            if (System.getProperty("os.name").startsWith("Windows")) Win32.handleCounts() else emptyMap()

        /**
         * Draws the system's chrome (title bar and frame) of every decorated window the process has and opens from now
         * on [dark] or light, as the app's theme is ([dark]: its palette is dark), whatever the OS's light or dark mode:
         * the main window, the file choosers' dialogs, any later one. A window opened later gets it as its native window
         * is made, before it first shows: on Windows DWM's dark or light frame; on Linux under X11 the hints window
         * managers draw their decorations from: KWin's colour scheme for the window (`_KDE_NET_WM_COLOR_SCHEME`, Breeze
         * Dark's or Breeze Light's) and GTK's variant (`_GTK_THEME_VARIANT`, Mutter's); under Wayland, as it shows,
         * KWin's decoration palette (Breeze Dark or Breeze Light), where the compositor has it. Call on the AWT event
         * thread, first before the first window. Reaching the native windows takes `--add-exports` of
         * `java.desktop/sun.awt` and of `sun.awt.windows` or `sun.awt.wl`, or `--add-opens` of `sun.awt.X11`
         * (desktop/app/build.gradle.kts).
         */
        fun useChrome(dark: Boolean) {
            if (chromeDark == dark) return
            val first = chromeDark == null
            chromeDark = dark
            if (first) {
                Toolkit.getDefaultToolkit().addAWTEventListener({ event ->
                    val e = event as HierarchyEvent
                    val window = e.changed as? Window
                    if (window != null && e.component === window && window.isDecorated) {
                        val madeNative = e.changeFlags and HierarchyEvent.DISPLAYABILITY_CHANGED.toLong() != 0L && window.isDisplayable
                        val shown = e.changeFlags and HierarchyEvent.SHOWING_CHANGED.toLong() != 0L && window.isShowing
                        when {
                            // The window's wl_surface comes with its first show.
                            WaylandSession.active -> if (shown && window !in waylandChrome) SwingUtilities.invokeLater { applyChrome(window) }
                            madeNative -> applyChrome(window)
                        }
                    }
                }, AWTEvent.HIERARCHY_EVENT_MASK)
            }
            for (window in Window.getWindows()) {
                if (window.isDecorated && (if (WaylandSession.active) window.isShowing else window.isDisplayable)) applyChrome(window)
            }
        }

        private fun applyChrome(window: Window) {
            val dark = chromeDark ?: return
            when {
                isWindows -> Win32.useFrame(Peers.hwnd(window), dark)
                WaylandSession.active -> if (WaylandSession.useDecorationPalette(window, if (dark) BREEZE_DARK else BREEZE_LIGHT)) {
                    waylandChrome[window] = dark
                }
                else -> Peers.withX11(window) { display, xWindow ->
                    X11.setText(display, xWindow, KDE_COLOR_SCHEME, "STRING", if (dark) BREEZE_DARK else BREEZE_LIGHT)
                    X11.setText(display, xWindow, GTK_THEME_VARIANT, "UTF8_STRING", if (dark) "dark" else "light")
                }
            }
        }

        /**
         * Whether [window]'s system chrome is dark ([useChrome]): read back from the OS (DWM's frame, or both X hints);
         * under Wayland, whether KWin took the dark palette (the protocol has nothing to read back).
         */
        fun hasDarkChrome(window: Window): Boolean =
            when {
                isWindows -> Win32.hasDarkFrame(Peers.hwnd(window))
                WaylandSession.active -> waylandChrome[window] == true
                else -> Peers.withX11(window) { display, xWindow ->
                    X11.text(display, xWindow, KDE_COLOR_SCHEME) == BREEZE_DARK && X11.text(display, xWindow, GTK_THEME_VARIANT) == "dark"
                }
            }

        /** [window]'s X window under X11: the parent a desktop portal's dialog is shown over. */
        fun xWindow(window: Window): Long = Peers.withX11(window) { _, xWindow -> xWindow }

        /** The chrome's brightness ([useChrome]); null before the first call. */
        private var chromeDark: Boolean? = null

        /** The Wayland windows whose decoration palette KWin took: dark or not. */
        private val waylandChrome: MutableMap<Window, Boolean> = WeakHashMap()

        private const val KDE_COLOR_SCHEME = "_KDE_NET_WM_COLOR_SCHEME"
        private const val GTK_THEME_VARIANT = "_GTK_THEME_VARIANT"
        /** KWin reads the file itself: a path on the host (a Flatpak's own /usr is not), where KDE installs Breeze's schemes. */
        private const val BREEZE_DARK = "/usr/share/color-schemes/BreezeDark.colors"
        private const val BREEZE_LIGHT = "/usr/share/color-schemes/BreezeLight.colors"
        private val isWindows = System.getProperty("os.name").startsWith("Windows")

        private val Window.isDecorated get() = (this as? Frame)?.isUndecorated == false || (this as? Dialog)?.isUndecorated == false
    }
}

/**
 * The native windows behind AWT's peers, through the JDK's internal API (exported to the app by the JVM flags
 * [DesktopWindow.useChrome] names): a window's HWND on Windows; on Linux its X window and AWT's own X connection,
 * used under AWT's lock so that requests about a window follow AWT's own creation of it.
 */
private object Peers {
    private val accessor = Class.forName("sun.awt.AWTAccessor").getMethod("getComponentAccessor").invoke(null)
    private val getPeer = Class.forName("sun.awt.AWTAccessor\$ComponentAccessor").getMethod("getPeer", Component::class.java)

    private fun peer(window: Window): Any = checkNotNull(getPeer.invoke(accessor, window)) { "window ${window.name} has no native window" }

    private val getHWnd by lazy { Class.forName("sun.awt.windows.WComponentPeer").getMethod("getHWnd") }

    fun hwnd(window: Window): Long = getHWnd.invoke(peer(window)) as Long

    private val getXWindow by lazy { Class.forName("sun.awt.X11.XBaseWindow").getMethod("getWindow") }
    private val getDisplay by lazy { Class.forName("sun.awt.X11.XToolkit").getMethod("getDisplay") }
    private val awtLock by lazy { Class.forName("sun.awt.SunToolkit").getMethod("awtLock") }
    private val awtUnlock by lazy { Class.forName("sun.awt.SunToolkit").getMethod("awtUnlock") }

    fun <T> withX11(window: Window, use: (display: Long, xWindow: Long) -> T): T {
        val xWindow = getXWindow.invoke(peer(window)) as Long
        awtLock.invoke(null)
        try {
            return use(getDisplay.invoke(null) as Long, xWindow)
        } finally {
            awtUnlock.invoke(null)
        }
    }
}

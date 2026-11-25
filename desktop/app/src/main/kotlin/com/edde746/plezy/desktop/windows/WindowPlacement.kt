package com.edde746.plezy.desktop.windows

import com.edde746.plezy.desktop.bind
import com.edde746.plezy.desktop.int
import java.awt.event.ComponentAdapter
import java.awt.event.ComponentEvent
import java.lang.foreign.Arena
import java.lang.foreign.FunctionDescriptor
import java.lang.foreign.Linker
import java.lang.foreign.MemorySegment
import java.lang.foreign.SymbolLookup
import java.lang.foreign.ValueLayout.ADDRESS
import java.lang.foreign.ValueLayout.JAVA_BYTE
import java.lang.foreign.ValueLayout.JAVA_INT
import java.lang.invoke.MethodHandle
import java.nio.ByteBuffer
import java.nio.ByteOrder
import javax.swing.JFrame
import javax.swing.SwingUtilities
import javax.swing.Timer

/** A Win32 `RECT`. */
internal data class PlacementRect(val left: Int, val top: Int, val right: Int, val bottom: Int) {
    val width: Int get() = right - left
    val height: Int get() = bottom - top

    fun offset(dx: Int, dy: Int) = PlacementRect(left + dx, top + dy, right + dx, bottom + dy)
}

/** A monitor's whole area and its work area (without the taskbar), in screen coordinates. */
internal data class PlacementMonitor(val bounds: PlacementRect, val work: PlacementRect)

/**
 * Win32's `WINDOWPLACEMENT`: the show state ([showCmd]), the minimized and maximized positions and the restored rect
 * ([normal], in the workspace coordinates of its monitor: screen coordinates less the work area's offset), stored as
 * its 44 bytes ([encode]), as the earlier releases stored it.
 */
internal data class WindowPlacement(
    val flags: Int,
    val showCmd: Int,
    val minX: Int,
    val minY: Int,
    val maxX: Int,
    val maxY: Int,
    val normal: PlacementRect,
) {
    /** The window shows maximized: maximized, or minimized from maximized (it restores to maximized). */
    val maximized: Boolean get() = showCmd == SW_SHOWMAXIMIZED || flags and WPF_RESTORETOMAXIMIZED != 0

    fun encode(): ByteArray = ByteBuffer.allocate(SIZE).order(ByteOrder.LITTLE_ENDIAN).apply {
        putInt(SIZE)
        putInt(flags)
        putInt(showCmd)
        putInt(minX)
        putInt(minY)
        putInt(maxX)
        putInt(maxY)
        putInt(normal.left)
        putInt(normal.top)
        putInt(normal.right)
        putInt(normal.bottom)
    }.array()

    companion object {
        /** `sizeof(WINDOWPLACEMENT)`. */
        const val SIZE = 44
        const val SW_HIDE = 0
        const val SW_SHOWMAXIMIZED = 3
        const val WPF_RESTORETOMAXIMIZED = 2

        /** The placement in [bytes]; null unless they are a whole one. */
        fun decode(bytes: ByteArray): WindowPlacement? {
            if (bytes.size != SIZE) return null
            val b = ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN)
            b.getInt()
            return WindowPlacement(
                flags = b.getInt(),
                showCmd = b.getInt(),
                minX = b.getInt(),
                minY = b.getInt(),
                maxX = b.getInt(),
                maxY = b.getInt(),
                normal = PlacementRect(b.getInt(), b.getInt(), b.getInt(), b.getInt()),
            )
        }

        /**
         * [placement] of a window Aero Snap arranged (`IsWindowArranged`): Windows keeps the rect from before the snap
         * as the restored one, so the window's rect on screen ([windowRect]) takes its place, moved into the workspace
         * coordinates of its [monitor]. There is no way to snap a window again: the next start shows a window of its
         * own on that rect.
         */
        fun arranged(placement: WindowPlacement, windowRect: PlacementRect, monitor: PlacementMonitor): WindowPlacement =
            placement.copy(normal = windowRect.offset(monitor.bounds.left - monitor.work.left, monitor.bounds.top - monitor.work.top))

        /**
         * [saved] as the window restores it: as it was where its rect is on a monitor still there; where it isn't (a
         * laptop undocked, a TV off), its size at the window's default position ([current], the new window's own
         * placement), so it never restores off screen. [nearestMonitor] is the monitor nearest a workspace rect
         * (`MonitorFromRect`'s nearest), [onScreen] whether a screen rect touches any monitor.
         */
        fun restored(
            saved: WindowPlacement,
            current: WindowPlacement,
            nearestMonitor: (PlacementRect) -> PlacementMonitor?,
            onScreen: (PlacementRect) -> Boolean,
        ): WindowPlacement {
            val monitor = nearestMonitor(saved.normal)
            val shown = monitor != null && onScreen(saved.normal.offset(monitor.work.left - monitor.bounds.left, monitor.work.top - monitor.bounds.top))
            if (shown) return saved
            val at = current.normal
            return saved.copy(normal = PlacementRect(at.left, at.top, at.left + saved.normal.width, at.top + saved.normal.height))
        }
    }
}

/**
 * The app window's place on Windows, kept across starts in `HKCU\Software\Plezy` as `WindowPlacement` (a `REG_BINARY`
 * [WindowPlacement]), the value the earlier releases kept. [restore] puts the window there before it shows; from
 * [track] on, a move, a resize or a maximize saves it 500 ms after the last one, never while the window is
 * fullscreen, changing fullscreen ([fullscreenChanging]) or hidden; closing saves it at once ([saveOnClose]), the
 * place from before fullscreen if the window is fullscreen then. A window Aero Snap arranged saves its rect on screen
 * ([WindowPlacement.arranged]). Event thread only.
 */
internal class WindowsWindowPlacement(private val window: JFrame, private val hwnd: () -> Long, private val fullscreen: () -> Boolean) {
    private val saveTimer = Timer(SAVE_DELAY_MS) { save() }.apply { isRepeats = false }
    private var togglingFullscreen = false
    private var beforeFullscreen: WindowPlacement? = null

    /** Saves the place after each move, resize or maximize, once they rest. */
    fun track() {
        window.addComponentListener(object : ComponentAdapter() {
            override fun componentMoved(e: ComponentEvent) = changed()

            override fun componentResized(e: ComponentEvent) = changed()
        })
        window.addWindowStateListener { changed() }
    }

    /** The window is about to enter or leave fullscreen: its place before fullscreen is kept for [saveOnClose]. */
    fun fullscreenChanging(entering: Boolean) {
        saveTimer.stop()
        togglingFullscreen = true
        beforeFullscreen = if (entering) query() else null
    }

    /** The fullscreen change is done; its own moves, queued meanwhile, save nothing. */
    fun fullscreenChanged() {
        SwingUtilities.invokeLater { togglingFullscreen = false }
    }

    fun saveOnClose() {
        saveTimer.stop()
        val before = beforeFullscreen
        if (fullscreen() && before != null) write(before) else save()
    }

    private fun changed() {
        if (fullscreen() || togglingFullscreen || !Win32Placement.isVisible(hwnd())) return
        saveTimer.restart()
    }

    private fun save() {
        if (!Win32Placement.isVisible(hwnd())) return
        query()?.let(::write)
    }

    private fun write(placement: WindowPlacement) {
        if (!WindowsRegistry.setBinary(WindowsRegistry.Root.CURRENT_USER, KEY, VALUE, placement.encode())) {
            System.err.println("plezy: the window's place couldn't be saved")
        }
    }

    /** The window's placement, its rect on screen in place of the restored one while Aero Snap arranges it. */
    private fun query(): WindowPlacement? {
        val handle = hwnd()
        val placement = Win32Placement.get(handle) ?: return null
        if (!Win32Placement.isArranged(handle)) return placement
        val rect = Win32Placement.windowRect(handle) ?: return placement
        val monitor = Win32Placement.monitorOf(handle) ?: return placement
        return WindowPlacement.arranged(placement, rect, monitor)
    }

    companion object {
        const val KEY = "Software\\Plezy"
        const val VALUE = "WindowPlacement"
        private const val SAVE_DELAY_MS = 500

        /**
         * Puts the window [hwnd], not shown yet, where the last start left it (on a monitor that is gone: that size at
         * its default position). True when it was maximized: the caller maximizes it as it shows. Nothing when nothing
         * was saved.
         */
        fun restore(hwnd: Long): Boolean {
            // An unreadable registry must not stop the start: the window then opens where it would without a saved place.
            val bytes = try {
                WindowsRegistry.binary(WindowsRegistry.Root.CURRENT_USER, KEY, VALUE)
            } catch (e: IllegalStateException) {
                System.err.println("plezy: the window's saved place couldn't be read: ${e.message}")
                null
            }
            val saved = bytes?.let(WindowPlacement::decode) ?: return false
            val current = Win32Placement.get(hwnd) ?: return false
            val placement = WindowPlacement.restored(saved, current, Win32Placement::nearestMonitor, Win32Placement::onScreen)
            // Applied hidden: the window shows once, where it belongs.
            Win32Placement.set(hwnd, placement.copy(showCmd = WindowPlacement.SW_HIDE))
            return placement.maximized
        }
    }
}

/** user32's placement and monitor calls, bound on first use. */
private object Win32Placement {
    private val user32 = SymbolLookup.libraryLookup("user32", Arena.global())
    private val getWindowPlacement = user32.bind("GetWindowPlacement", FunctionDescriptor.of(JAVA_INT, ADDRESS, ADDRESS))
    private val setWindowPlacement = user32.bind("SetWindowPlacement", FunctionDescriptor.of(JAVA_INT, ADDRESS, ADDRESS))
    private val isWindowVisible = user32.bind("IsWindowVisible", FunctionDescriptor.of(JAVA_INT, ADDRESS))
    private val isIconic = user32.bind("IsIconic", FunctionDescriptor.of(JAVA_INT, ADDRESS))
    private val isZoomed = user32.bind("IsZoomed", FunctionDescriptor.of(JAVA_INT, ADDRESS))
    private val getWindowRect = user32.bind("GetWindowRect", FunctionDescriptor.of(JAVA_INT, ADDRESS, ADDRESS))
    private val monitorFromWindow = user32.bind("MonitorFromWindow", FunctionDescriptor.of(ADDRESS, ADDRESS, JAVA_INT))
    private val monitorFromRect = user32.bind("MonitorFromRect", FunctionDescriptor.of(ADDRESS, ADDRESS, JAVA_INT))
    private val getMonitorInfoW = user32.bind("GetMonitorInfoW", FunctionDescriptor.of(JAVA_INT, ADDRESS, ADDRESS))

    /** Windows 10 1903 and later; exported without a header. */
    private val isWindowArranged: MethodHandle? = user32.find("IsWindowArranged").map {
        Linker.nativeLinker().downcallHandle(it, FunctionDescriptor.of(JAVA_INT, ADDRESS))
    }.orElse(null)

    private const val MONITOR_DEFAULTTONULL = 0
    private const val MONITOR_DEFAULTTONEAREST = 2
    private const val MONITORINFO_SIZE = 40

    private fun window(hwnd: Long) = MemorySegment.ofAddress(hwnd)

    fun get(hwnd: Long): WindowPlacement? = Arena.ofConfined().use { a ->
        val buffer = a.allocate(WindowPlacement.SIZE.toLong(), 4).also { it.set(JAVA_INT, 0, WindowPlacement.SIZE) }
        if (getWindowPlacement.int(window(hwnd), buffer) == 0) null else WindowPlacement.decode(buffer.toArray(JAVA_BYTE))
    }

    fun set(hwnd: Long, placement: WindowPlacement): Boolean = Arena.ofConfined().use { a ->
        val bytes = placement.encode()
        val buffer = a.allocate(bytes.size.toLong(), 4).also { MemorySegment.copy(bytes, 0, it, JAVA_BYTE, 0, bytes.size) }
        setWindowPlacement.int(window(hwnd), buffer) != 0
    }

    fun isVisible(hwnd: Long): Boolean = isWindowVisible.int(window(hwnd)) != 0

    /** Aero Snap arranged the window, neither minimized nor maximized. */
    fun isArranged(hwnd: Long): Boolean {
        val arranged = isWindowArranged ?: return false
        if (isIconic.int(window(hwnd)) != 0 || isZoomed.int(window(hwnd)) != 0) return false
        return arranged.int(window(hwnd)) != 0
    }

    fun windowRect(hwnd: Long): PlacementRect? = Arena.ofConfined().use { a ->
        val rect = a.allocate(16, 4)
        if (getWindowRect.int(window(hwnd), rect) == 0) null else rect.rect(0)
    }

    fun monitorOf(hwnd: Long): PlacementMonitor? = info(monitorFromWindow.invokeWithArguments(window(hwnd), MONITOR_DEFAULTTONEAREST) as MemorySegment)

    fun nearestMonitor(rect: PlacementRect): PlacementMonitor? = Arena.ofConfined().use { a ->
        info(monitorFromRect.invokeWithArguments(a.rect(rect), MONITOR_DEFAULTTONEAREST) as MemorySegment)
    }

    fun onScreen(rect: PlacementRect): Boolean = Arena.ofConfined().use { a ->
        (monitorFromRect.invokeWithArguments(a.rect(rect), MONITOR_DEFAULTTONULL) as MemorySegment).address() != 0L
    }

    private fun info(monitor: MemorySegment): PlacementMonitor? {
        if (monitor.address() == 0L) return null
        return Arena.ofConfined().use { a ->
            val info = a.allocate(MONITORINFO_SIZE.toLong(), 4).also { it.set(JAVA_INT, 0, MONITORINFO_SIZE) }
            if (getMonitorInfoW.int(monitor, info) == 0) null else PlacementMonitor(info.rect(4), info.rect(20))
        }
    }

    private fun Arena.rect(rect: PlacementRect): MemorySegment = allocate(16, 4).also {
        it.set(JAVA_INT, 0, rect.left)
        it.set(JAVA_INT, 4, rect.top)
        it.set(JAVA_INT, 8, rect.right)
        it.set(JAVA_INT, 12, rect.bottom)
    }

    private fun MemorySegment.rect(offset: Long) =
        PlacementRect(get(JAVA_INT, offset), get(JAVA_INT, offset + 4), get(JAVA_INT, offset + 8), get(JAVA_INT, offset + 12))
}

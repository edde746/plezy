package com.edde746.plezy.mpv.os

import java.lang.foreign.Arena
import java.lang.foreign.MemorySegment
import java.lang.foreign.SymbolLookup
import java.lang.foreign.ValueLayout
import java.nio.charset.StandardCharsets

/** A window rectangle in physical pixels. */
internal data class WinRect(val left: Int, val top: Int, val right: Int, val bottom: Int) {
    val width get() = right - left
    val height get() = bottom - top
    fun toList() = listOf(left, top, width, height)
}

/** The user32/kernel32 calls the Windows video host and borderless fullscreen need. HWNDs travel as Longs. */
internal object Win32 {
    const val WS_CHILD = 0x40000000
    const val WS_VISIBLE = 0x10000000
    const val WS_DISABLED = 0x08000000
    const val WS_CLIPSIBLINGS = 0x04000000
    const val WS_CAPTION = 0x00C00000
    const val WS_THICKFRAME = 0x00040000
    const val WS_SYSMENU = 0x00080000
    const val WS_MINIMIZEBOX = 0x00020000
    const val WS_MAXIMIZEBOX = 0x00010000
    const val WS_EX_NOPARENTNOTIFY = 0x4
    const val GWL_STYLE = -16
    const val SWP_NOZORDER = 0x4
    const val SWP_NOACTIVATE = 0x10
    const val SWP_FRAMECHANGED = 0x20
    const val SWP_ASYNCWINDOWPOS = 0x4000
    const val SW_HIDE = 0
    const val WM_APP = 0x8000
    private const val MONITOR_DEFAULTTONEAREST = 2
    private const val PROCESS_POWER_THROTTLING = 4 // PROCESS_INFORMATION_CLASS.ProcessPowerThrottling
    private const val THROTTLE_EXECUTION_SPEED = 0x1
    private const val THROTTLE_IGNORE_TIMER_RESOLUTION = 0x4
    private const val CS_VREDRAW = 0x1
    private const val CS_HREDRAW = 0x2
    private const val BLACK_BRUSH = 4
    private const val IDC_ARROW = 32512L
    private const val WM_NCACTIVATE = 0x86
    /** DWMWA_USE_IMMERSIVE_DARK_MODE: 20 since Windows 10 20H1, 19 on the builds before it (1809 to 1909). */
    private val DARK_MODE_ATTRIBUTES = intArrayOf(20, 19)

    private val user32 = SymbolLookup.libraryLookup("user32", Arena.global())
    private val kernel32 = SymbolLookup.libraryLookup("kernel32", Arena.global())
    private val gdi32 = SymbolLookup.libraryLookup("gdi32", Arena.global())
    private val dwmapi = SymbolLookup.libraryLookup("dwmapi", Arena.global())

    private val registerClassExW = user32.fn("RegisterClassExW", ValueLayout.JAVA_SHORT, PTR)
    private val defWindowProcW = user32.find("DefWindowProcW").orElseThrow { UnsatisfiedLinkError("DefWindowProcW") }
    private val loadCursorW = user32.fn("LoadCursorW", PTR, PTR, PTR)
    private val getStockObject = gdi32.fn("GetStockObject", PTR, I32)
    private val createWindowExW = user32.fn("CreateWindowExW", PTR, I32, PTR, PTR, I32, I32, I32, I32, I32, PTR, PTR, PTR, PTR)
    private val destroyWindow = user32.fn("DestroyWindow", I32, PTR)
    private val showWindow = user32.fn("ShowWindow", I32, PTR, I32)
    private val setWindowPos = user32.fn("SetWindowPos", I32, PTR, PTR, I32, I32, I32, I32, I32)
    private val getMessageW = user32.fn("GetMessageW", I32, PTR, PTR, I32, I32)
    private val translateMessage = user32.fn("TranslateMessage", I32, PTR)
    private val dispatchMessageW = user32.fn("DispatchMessageW", I64, PTR)
    private val postThreadMessageW = user32.fn("PostThreadMessageW", I32, I32, I32, I64, I64)
    private val getWindowRect = user32.fn("GetWindowRect", I32, PTR, PTR)
    private val getClientRect = user32.fn("GetClientRect", I32, PTR, PTR)
    private val getWindowLongPtrW = user32.fn("GetWindowLongPtrW", I64, PTR, I32)
    private val setWindowLongPtrW = user32.fn("SetWindowLongPtrW", I64, PTR, I32, I64)
    private val monitorFromWindow = user32.fn("MonitorFromWindow", PTR, PTR, I32)
    private val getMonitorInfoW = user32.fn("GetMonitorInfoW", I32, PTR, PTR)
    private val getGuiResources = user32.fn("GetGuiResources", I32, PTR, I32)
    private val isWindowVisible = user32.fn("IsWindowVisible", I32, PTR)
    private val getForegroundWindow = user32.fn("GetForegroundWindow", PTR)
    private val callDefWindowProc = user32.fn("DefWindowProcW", I64, PTR, I32, I64, I64)
    private val getCurrentThreadId = kernel32.fn("GetCurrentThreadId", I32)
    private val getModuleHandleW = kernel32.fn("GetModuleHandleW", PTR, PTR)
    private val getCurrentProcess = kernel32.fn("GetCurrentProcess", PTR)
    private val getProcessHandleCount = kernel32.fn("GetProcessHandleCount", I32, PTR, PTR)
    private val setProcessInformation = kernel32.fn("SetProcessInformation", I32, PTR, I32, PTR, I32)
    private val dwmSetWindowAttribute = dwmapi.fn("DwmSetWindowAttribute", I32, PTR, I32, PTR, I32)
    private val dwmGetWindowAttribute = dwmapi.fn("DwmGetWindowAttribute", I32, PTR, I32, PTR, I32)

    fun currentThreadId(): Int = getCurrentThreadId.call() as Int

    /**
     * Registers the window class [name] for this process: plain windows (the default window procedure, the arrow
     * cursor) whose background is black, painted again whole when they change size. Fails loudly if Windows refuses.
     */
    fun registerBlackClass(name: String) = Arena.ofConfined().use { a ->
        val wc = a.allocate(80, 8) // WNDCLASSEXW
        wc.set(ValueLayout.JAVA_INT, 0, 80) // cbSize
        wc.set(ValueLayout.JAVA_INT, 4, CS_HREDRAW or CS_VREDRAW) // style
        wc.set(ValueLayout.ADDRESS, 8, defWindowProcW) // lpfnWndProc
        wc.set(ValueLayout.ADDRESS, 24, getModuleHandleW.call(MemorySegment.NULL) as MemorySegment) // hInstance
        wc.set(ValueLayout.ADDRESS, 40, loadCursorW.call(MemorySegment.NULL, ptr(IDC_ARROW)) as MemorySegment) // hCursor
        wc.set(ValueLayout.ADDRESS, 48, getStockObject.call(BLACK_BRUSH) as MemorySegment) // hbrBackground
        wc.set(ValueLayout.ADDRESS, 64, a.allocateFrom(name, StandardCharsets.UTF_16LE)) // lpszClassName
        check((registerClassExW.call(wc) as Short) != 0.toShort()) { "could not register the window class $name (RegisterClassExW)" }
    }

    /** Creates a child window of [parent] with an empty caption; 0 on failure. */
    fun createChild(parent: Long, className: String, style: Int, exStyle: Int): Long = Arena.ofConfined().use { a ->
        val module = getModuleHandleW.call(MemorySegment.NULL) as MemorySegment
        val hwnd = createWindowExW.call(
            exStyle, a.allocateFrom(className, StandardCharsets.UTF_16LE), a.allocateFrom("", StandardCharsets.UTF_16LE),
            style, 0, 0, 16, 16, ptr(parent), MemorySegment.NULL, module, MemorySegment.NULL,
        ) as MemorySegment
        hwnd.address()
    }

    fun hide(hwnd: Long) { showWindow.call(ptr(hwnd), SW_HIDE) }
    fun destroy(hwnd: Long): Boolean = (destroyWindow.call(ptr(hwnd)) as Int) != 0

    fun setPos(hwnd: Long, x: Int, y: Int, w: Int, h: Int, flags: Int): Boolean =
        (setWindowPos.call(ptr(hwnd), MemorySegment.NULL, x, y, w, h, flags) as Int) != 0

    fun windowRect(hwnd: Long): WinRect = Arena.ofConfined().use { a ->
        val r = a.allocate(16)
        getWindowRect.call(ptr(hwnd), r)
        r.toRect()
    }

    /** Client area size, origin (0, 0). */
    fun clientRect(hwnd: Long): WinRect = Arena.ofConfined().use { a ->
        val r = a.allocate(16)
        getClientRect.call(ptr(hwnd), r)
        r.toRect()
    }

    fun style(hwnd: Long): Long = getWindowLongPtrW.call(ptr(hwnd), GWL_STYLE) as Long
    fun setStyle(hwnd: Long, style: Long): Long = setWindowLongPtrW.call(ptr(hwnd), GWL_STYLE, style) as Long

    /** Physical rect of the monitor nearest to [hwnd]. */
    fun monitorRect(hwnd: Long): WinRect = Arena.ofConfined().use { a ->
        val monitor = monitorFromWindow.call(ptr(hwnd), MONITOR_DEFAULTTONEAREST) as MemorySegment
        val info = a.allocate(40) // MONITORINFO: cbSize, rcMonitor, rcWork, dwFlags
        info.set(ValueLayout.JAVA_INT, 0, 40)
        getMonitorInfoW.call(monitor, info)
        info.asSlice(4, 16).toRect()
    }

    /**
     * Runs a GetMessage loop on the calling thread. Thread messages (no target window) go to [onThreadMessage], which
     * returns true to end the loop; everything else is dispatched.
     */
    fun pump(onThreadMessage: (msg: Int) -> Boolean) = Arena.ofConfined().use { a ->
        val msg = a.allocate(48) // MSG
        while (true) {
            if ((getMessageW.call(msg, MemorySegment.NULL, 0, 0) as Int) <= 0) break
            if (msg.get(ValueLayout.JAVA_LONG, 0) == 0L && onThreadMessage(msg.get(ValueLayout.JAVA_INT, 8))) break
            translateMessage.call(msg)
            dispatchMessageW.call(msg)
        }
    }

    fun postThreadMessage(threadId: Int, msg: Int): Boolean = (postThreadMessageW.call(threadId, msg, 0L, 0L) as Int) != 0

    /**
     * Keeps Windows from throttling this process while [exempt] (PROCESS_POWER_THROTTLING_STATE): no EcoQoS execution
     * speed, and timer resolution requests honoured even when no window of the process is visible and nothing is
     * audible (Windows 11 otherwise ignores mpv's 1 ms timer then). Windows 10 doesn't know the timer-resolution flag and
     * refuses a call that names it, so there the process is exempt from the execution-speed throttling alone. [exempt]
     * false hands the decision back to Windows. False when Windows refused the execution-speed exemption.
     */
    fun exemptFromPowerThrottling(exempt: Boolean): Boolean {
        if (!exempt) return setPowerThrottling(0)
        return setPowerThrottling(THROTTLE_EXECUTION_SPEED or THROTTLE_IGNORE_TIMER_RESOLUTION) || setPowerThrottling(THROTTLE_EXECUTION_SPEED)
    }

    /** One SetProcessInformation call: Windows decides nothing in [controlled] (each bit off), the rest itself. */
    private fun setPowerThrottling(controlled: Int): Boolean = Arena.ofConfined().use { a ->
        val state = a.allocate(12) // Version, ControlMask, StateMask
        state.set(ValueLayout.JAVA_INT, 0, 1)
        state.set(ValueLayout.JAVA_INT, 4, controlled)
        state.set(ValueLayout.JAVA_INT, 8, 0)
        (setProcessInformation.call(getCurrentProcess.call() as MemorySegment, PROCESS_POWER_THROTTLING, state, 12) as Int) != 0
    }

    /** Kernel, GDI and USER handle counts of this process (the libmpv handle leak check). */
    fun handleCounts(): Map<String, Int> = Arena.ofConfined().use { a ->
        val process = getCurrentProcess.call() as MemorySegment
        val count = a.allocate(ValueLayout.JAVA_INT)
        getProcessHandleCount.call(process, count)
        mapOf(
            "kernel" to count.get(ValueLayout.JAVA_INT, 0),
            "gdi" to getGuiResources.call(process, 0) as Int,
            "user" to getGuiResources.call(process, 1) as Int,
        )
    }

    /**
     * Draws the title bar and frame of the top-level window [hwnd] [dark] or light whatever Windows' light or dark mode
     * (DWMWA_USE_IMMERSIVE_DARK_MODE). Fails loudly if DWM refuses it. Windows 10 repaints the caption in the new
     * theme only at the next activation change: a shown window's is repainted at once, straight through
     * DefWindowProc, so the window sees no activation change.
     */
    fun useFrame(hwnd: Long, dark: Boolean) = Arena.ofConfined().use { a ->
        val value = a.allocateFrom(ValueLayout.JAVA_INT, if (dark) 1 else 0)
        check(DARK_MODE_ATTRIBUTES.any { (dwmSetWindowAttribute.call(ptr(hwnd), it, value, 4) as Int) == 0 }) {
            "Windows refused a ${if (dark) "dark" else "light"} frame for window $hwnd (DwmSetWindowAttribute)"
        }
        if ((isWindowVisible.call(ptr(hwnd)) as Int) != 0) {
            val active = (getForegroundWindow.call() as MemorySegment).address() == hwnd
            callDefWindowProc.call(ptr(hwnd), WM_NCACTIVATE, if (active) 0L else 1L, 0L)
            callDefWindowProc.call(ptr(hwnd), WM_NCACTIVATE, if (active) 1L else 0L, 0L)
        }
    }

    /** Whether DWM draws [hwnd]'s title bar and frame dark ([useFrame]), as DWM reports it. Fails loudly if it can't. */
    fun hasDarkFrame(hwnd: Long): Boolean = Arena.ofConfined().use { a ->
        val value = a.allocate(ValueLayout.JAVA_INT)
        check(DARK_MODE_ATTRIBUTES.any { (dwmGetWindowAttribute.call(ptr(hwnd), it, value, 4) as Int) == 0 }) {
            "Windows can't say whether window $hwnd's frame is dark (DwmGetWindowAttribute)"
        }
        value.get(ValueLayout.JAVA_INT, 0) != 0
    }

    private fun MemorySegment.toRect() = WinRect(
        get(ValueLayout.JAVA_INT, 0), get(ValueLayout.JAVA_INT, 4), get(ValueLayout.JAVA_INT, 8), get(ValueLayout.JAVA_INT, 12),
    )
}

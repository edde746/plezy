package com.edde746.plezy.mpv.os

import java.lang.foreign.Arena
import java.lang.foreign.FunctionDescriptor
import java.lang.foreign.MemorySegment
import java.lang.foreign.SymbolLookup
import java.lang.foreign.ValueLayout
import java.lang.invoke.MethodHandle

/**
 * libc: the C numeric locale mpv_create insists on (the JVM applies the user's), and the eventfd and poll the Wayland
 * video plane's thread waits on.
 */
internal object Posix {
    // glibc's values; the desktop build only targets glibc Linux (macOS uses the native Swift player).
    private const val LC_NUMERIC_GLIBC = 1
    private const val EFD_CLOEXEC = 0x80000
    private const val EFD_NONBLOCK = 0x800
    const val POLLIN = 0x1
    const val POLLERR = 0x8
    const val POLLHUP = 0x10
    private val libc = linker.defaultLookup()
    private val setlocale by lazy { libc.fn("setlocale", PTR, I32, PTR) }
    private val eventfd by lazy { libc.fn("eventfd", I32, I32, I32) }
    private val poll by lazy { libc.fn("poll", I32, PTR, I64, I32) }
    private val read by lazy { libc.fn("read", I64, I32, PTR, I64) }
    private val write by lazy { libc.fn("write", I64, I32, PTR, I64) }
    private val close by lazy { libc.fn("close", I32, I32) }

    fun useCNumericLocale() = Arena.ofConfined().use { a ->
        setlocale.call(LC_NUMERIC_GLIBC, a.allocateFrom("C"))
        Unit
    }

    /** A non-blocking eventfd: [signal] makes it readable until [drain]. */
    fun eventFd(): Int = (eventfd.call(0, EFD_CLOEXEC or EFD_NONBLOCK) as Int).also { check(it >= 0) { "eventfd failed" } }

    fun signal(fd: Int) = Arena.ofConfined().use { a ->
        write.call(fd, a.allocateFrom(ValueLayout.JAVA_LONG, 1L), 8L)
        Unit
    }

    fun drain(fd: Int) = Arena.ofConfined().use { a ->
        read.call(fd, a.allocate(ValueLayout.JAVA_LONG), 8L)
        Unit
    }

    fun close(fd: Int) {
        close.call(fd)
    }

    /**
     * Waits up to [timeoutMs] (-1: forever) for [fds] to be readable; returns each one's `revents` (POLLIN, POLLERR,
     * POLLHUP). EINTR and a timeout read as no events.
     */
    fun poll(fds: IntArray, timeoutMs: Int): IntArray = Arena.ofConfined().use { a ->
        val set = a.allocate(8L * fds.size, 4)
        fds.forEachIndexed { i, fd ->
            set.set(ValueLayout.JAVA_INT, 8L * i, fd)
            set.set(ValueLayout.JAVA_SHORT, 8L * i + 4, POLLIN.toShort())
            set.set(ValueLayout.JAVA_SHORT, 8L * i + 6, 0)
        }
        val n = poll.call(set, fds.size.toLong(), timeoutMs) as Int
        IntArray(fds.size) { i -> if (n > 0) set.get(ValueLayout.JAVA_SHORT, 8L * i + 6).toInt() and 0xFFFF else 0 }
    }
}

/** The libX11 calls Linux needs: the desktop scale for Compose, the windows' hints. */
internal object X11 {
    private const val PROP_MODE_REPLACE = 0
    private const val ANY_PROPERTY_TYPE = 0L
    private val lib = SymbolLookup.libraryLookup("libX11.so.6", Arena.global())
    private val xOpenDisplay = lib.fn("XOpenDisplay", PTR, PTR)
    private val xCloseDisplay = lib.fn("XCloseDisplay", I32, PTR)
    private val xResourceManagerString = lib.fn("XResourceManagerString", PTR, PTR)
    private val xInternAtom = lib.fn("XInternAtom", I64, PTR, PTR, I32)
    private val xChangeProperty = lib.fn("XChangeProperty", I32, PTR, I64, I64, I64, I32, I32, PTR, I32)
    private val xGetWindowProperty = lib.fn("XGetWindowProperty", I32, PTR, I64, I64, I64, I64, I32, I64, PTR, PTR, PTR, PTR, PTR)
    private val xFree = lib.fn("XFree", I32, PTR)

    /**
     * `Xft.dpi` / 96 from the RESOURCE_MANAGER string (KDE sets 163 at 1.7×), or null when unset or no display is
     * reachable: the desktop's scale, of which Compose applies what AWT doesn't (DesktopWindow.composeScale). Opens
     * its own short-lived connection; no XInitThreads, which would have to precede AWT's own Xlib use (libX11 ≥ 1.8
     * locks by default).
     */
    fun xftScale(): Double? {
        val dpy = xOpenDisplay.call(MemorySegment.NULL) as MemorySegment
        if (dpy.address() == 0L) return null
        try {
            val resources = (xResourceManagerString.call(dpy) as MemorySegment).utf8() ?: return null
            val dpi = Regex("""(?m)^Xft\.dpi:\s*([0-9.]+)""").find(resources)?.groupValues?.get(1)?.toDoubleOrNull() ?: return null
            return dpi / 96.0
        } finally {
            xCloseDisplay.call(dpy)
        }
    }

    /** Sets [window]'s property [name] to the text [value] (8-bit, of the type [type]) over the connection [display]. */
    fun setText(display: Long, window: Long, name: String, type: String, value: String) = Arena.ofConfined().use { a ->
        val bytes = value.toByteArray()
        xChangeProperty.call(
            ptr(display), window, atom(a, display, name), atom(a, display, type), 8, PROP_MODE_REPLACE,
            a.allocateFrom(ValueLayout.JAVA_BYTE, *bytes), bytes.size,
        )
    }

    /** [window]'s property [name] as text, read over the connection [display]; null when it has none. */
    fun text(display: Long, window: Long, name: String): String? = Arena.ofConfined().use { a ->
        val type = a.allocate(ValueLayout.JAVA_LONG)
        val format = a.allocate(ValueLayout.JAVA_INT)
        val count = a.allocate(ValueLayout.JAVA_LONG)
        val after = a.allocate(ValueLayout.JAVA_LONG)
        val data = a.allocate(ValueLayout.ADDRESS)
        val status = xGetWindowProperty.call(
            ptr(display), window, atom(a, display, name), 0L, 1024L, 0, ANY_PROPERTY_TYPE, type, format, count, after, data,
        ) as Int
        check(status == 0) { "could not read the property $name of window $window (XGetWindowProperty: $status)" }
        val bytes = data.get(ValueLayout.ADDRESS, 0)
        if (bytes.address() == 0L) return null
        try {
            if (type.get(ValueLayout.JAVA_LONG, 0) == 0L) null
            else String(bytes.reinterpret(count.get(ValueLayout.JAVA_LONG, 0)).toArray(ValueLayout.JAVA_BYTE))
        } finally {
            xFree.call(bytes)
        }
    }

    private fun atom(a: Arena, display: Long, name: String): Long = xInternAtom.call(ptr(display), a.allocateFrom(name), 0) as Long
}

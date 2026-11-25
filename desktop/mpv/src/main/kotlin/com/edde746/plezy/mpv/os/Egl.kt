package com.edde746.plezy.mpv.os

import java.lang.foreign.Arena
import java.lang.foreign.FunctionDescriptor
import java.lang.foreign.MemorySegment
import java.lang.foreign.SymbolLookup
import java.lang.foreign.ValueLayout
import java.lang.invoke.MethodHandle
import java.lang.invoke.MethodHandles
import java.lang.invoke.MethodType

/**
 * The EGL, wayland-egl and GLES calls the Wayland video plane and Compose's GPU layer make. Every GL call runs on the
 * thread whose context is current.
 */
internal object Egl {
    const val PLATFORM_WAYLAND = 0x31D8
    const val NONE = 0x3038
    const val RED_SIZE = 0x3024
    const val GREEN_SIZE = 0x3023
    const val BLUE_SIZE = 0x3022
    const val ALPHA_SIZE = 0x3021
    const val STENCIL_SIZE = 0x3026
    const val SURFACE_TYPE = 0x3033
    const val WINDOW_BIT = 0x0004
    const val RENDERABLE_TYPE = 0x3040
    const val OPENGL_ES3_BIT = 0x0040
    const val OPENGL_ES_API = 0x30A0
    const val EXTENSIONS = 0x3055
    const val CONTEXT_MAJOR_VERSION = 0x3098
    const val CONTEXT_MINOR_VERSION = 0x30FB
    const val COLOR_COMPONENT_TYPE_EXT = 0x3339
    const val COLOR_COMPONENT_TYPE_FLOAT_EXT = 0x333B

    private val lib = SymbolLookup.libraryLookup("libEGL.so.1", Arena.global())
    private val waylandEgl = SymbolLookup.libraryLookup("libwayland-egl.so.1", Arena.global())

    private val getProcAddress = lib.fn("eglGetProcAddress", PTR, PTR)
    private val getPlatformDisplayExt by lazy { proc("eglGetPlatformDisplayEXT", PTR, I32, PTR, PTR) }
    private val initialize = lib.fn("eglInitialize", I32, PTR, PTR, PTR)
    private val bindApi = lib.fn("eglBindAPI", I32, I32)
    private val queryString = lib.fn("eglQueryString", PTR, PTR, I32)
    private val chooseConfig = lib.fn("eglChooseConfig", I32, PTR, PTR, PTR, I32, PTR)
    private val getConfigAttrib = lib.fn("eglGetConfigAttrib", I32, PTR, PTR, I32, PTR)
    private val createContext = lib.fn("eglCreateContext", PTR, PTR, PTR, PTR, PTR)
    private val destroyContext = lib.fn("eglDestroyContext", I32, PTR, PTR)
    private val createWindowSurface = lib.fn("eglCreateWindowSurface", PTR, PTR, PTR, PTR, PTR)
    private val destroySurface = lib.fn("eglDestroySurface", I32, PTR, PTR)
    private val makeCurrent = lib.fn("eglMakeCurrent", I32, PTR, PTR, PTR, PTR)
    private val swapBuffers = lib.fn("eglSwapBuffers", I32, PTR, PTR)
    private val swapInterval = lib.fn("eglSwapInterval", I32, PTR, I32)
    private val getError = lib.fn("eglGetError", I32)

    private val windowCreate = waylandEgl.fn("wl_egl_window_create", PTR, PTR, I32, I32)
    private val windowResize = waylandEgl.fn("wl_egl_window_resize", null, PTR, I32, I32, I32, I32)
    private val windowDestroy = waylandEgl.fn("wl_egl_window_destroy", null, PTR)

    private fun proc(name: String, ret: ValueLayout?, vararg args: ValueLayout): MethodHandle? {
        val address = Arena.ofConfined().use { a -> getProcAddress.call(a.allocateFrom(name)) as MemorySegment }
        if (address.address() == 0L) return null
        val desc = if (ret == null) FunctionDescriptor.ofVoid(*args) else FunctionDescriptor.of(ret, *args)
        return linker.downcallHandle(address, desc)
    }

    /** `eglGetProcAddress`, for mpv's GL loader (any thread). */
    fun procAddress(name: MemorySegment): MemorySegment = getProcAddress.call(name) as MemorySegment

    /** [procAddress] as Skia's `GrGLGetProc` (`void* (*)(void* ctx, const char* name)`), for its OpenGL interface. */
    val skiaGetProc: MemorySegment by lazy {
        linker.upcallStub(
            MethodHandles.lookup().findStatic(
                Egl::class.java, "skiaProc",
                MethodType.methodType(MemorySegment::class.java, MemorySegment::class.java, MemorySegment::class.java),
            ),
            FunctionDescriptor.of(PTR, PTR, PTR),
            Arena.global(),
        )
    }

    @JvmStatic
    @Suppress("unused") // the upcall's target; must not throw (an exception in an upcall aborts the JVM)
    private fun skiaProc(ctx: MemorySegment, name: MemorySegment): MemorySegment = procAddress(name)

    fun error(): Int = getError.call() as Int

    /** The EGL display of the Wayland connection [display]; shared with any other EGL user of it, so never terminated. */
    fun display(display: MemorySegment): MemorySegment {
        val ext = checkNotNull(getPlatformDisplayExt) { "EGL has no eglGetPlatformDisplayEXT" }
        val dpy = ext.call(PLATFORM_WAYLAND, display, MemorySegment.NULL) as MemorySegment
        check(dpy.address() != 0L) { "no EGL display for the Wayland connection" }
        check(initialize.call(dpy, MemorySegment.NULL, MemorySegment.NULL) as Int != 0) { "eglInitialize failed: 0x%x".format(error()) }
        check(bindApi.call(OPENGL_ES_API) as Int != 0) { "eglBindAPI(OpenGL ES) failed" }
        return dpy
    }

    fun extensions(dpy: MemorySegment): String = (queryString.call(dpy, EXTENSIONS) as MemorySegment).utf8().orEmpty()

    /** Every config matching [attributes] (an EGL_NONE-terminated list is made of them), best first. */
    fun configs(dpy: MemorySegment, attributes: IntArray): List<MemorySegment> = Arena.ofConfined().use { a ->
        val attrs = a.allocateFrom(ValueLayout.JAVA_INT, *(attributes + NONE))
        val out = a.allocate(PTR, MAX_CONFIGS)
        val n = a.allocate(ValueLayout.JAVA_INT)
        if (chooseConfig.call(dpy, attrs, out, MAX_CONFIGS.toInt(), n) as Int == 0) return emptyList()
        (0 until n.get(ValueLayout.JAVA_INT, 0)).map { out.getAtIndex(PTR, it.toLong()) }
    }

    fun attribute(dpy: MemorySegment, config: MemorySegment, attribute: Int): Int = Arena.ofConfined().use { a ->
        val out = a.allocate(ValueLayout.JAVA_INT)
        getConfigAttrib.call(dpy, config, attribute, out)
        out.get(ValueLayout.JAVA_INT, 0)
    }

    /** An OpenGL ES 3.x context for [config], the highest minor version the driver gives; null when none. */
    fun context(dpy: MemorySegment, config: MemorySegment): MemorySegment? = Arena.ofConfined().use { a ->
        for (minor in intArrayOf(2, 1, 0)) {
            val attrs = a.allocateFrom(ValueLayout.JAVA_INT, CONTEXT_MAJOR_VERSION, 3, CONTEXT_MINOR_VERSION, minor, NONE)
            val ctx = createContext.call(dpy, config, MemorySegment.NULL, attrs) as MemorySegment
            if (ctx.address() != 0L) return ctx
        }
        null
    }

    fun destroyContext(dpy: MemorySegment, ctx: MemorySegment) {
        destroyContext.call(dpy, ctx)
    }

    fun windowSurface(dpy: MemorySegment, config: MemorySegment, window: MemorySegment): MemorySegment {
        val s = createWindowSurface.call(dpy, config, window, MemorySegment.NULL) as MemorySegment
        check(s.address() != 0L) { "eglCreateWindowSurface failed: 0x%x".format(error()) }
        return s
    }

    fun destroySurface(dpy: MemorySegment, surface: MemorySegment) {
        destroySurface.call(dpy, surface)
    }

    fun makeCurrent(dpy: MemorySegment, surface: MemorySegment, ctx: MemorySegment): Boolean =
        makeCurrent.call(dpy, surface, surface, ctx) as Int != 0

    fun releaseCurrent(dpy: MemorySegment) {
        makeCurrent.call(dpy, MemorySegment.NULL, MemorySegment.NULL, MemorySegment.NULL)
    }

    /** Presents the back buffer: the plane surface's commit. */
    fun swap(dpy: MemorySegment, surface: MemorySegment): Boolean = swapBuffers.call(dpy, surface) as Int != 0

    fun swapInterval(dpy: MemorySegment, interval: Int) {
        swapInterval.call(dpy, interval)
    }

    fun window(surface: MemorySegment, width: Int, height: Int): MemorySegment {
        val w = windowCreate.call(surface, width, height) as MemorySegment
        check(w.address() != 0L) { "wl_egl_window_create failed" }
        return w
    }

    fun resizeWindow(window: MemorySegment, width: Int, height: Int) {
        windowResize.call(window, width, height, 0, 0)
    }

    fun destroyWindow(window: MemorySegment) {
        windowDestroy.call(window)
    }

    private const val MAX_CONFIGS = 64L
}

/** The GLES calls made here directly (mpv and Skia load their own through [Egl.procAddress]). */
internal object Gles {
    const val RGBA8 = 0x8058
    const val RGB10_A2 = 0x8059
    const val RGBA16F = 0x881A
    private const val VERSION = 0x1F02
    private const val RENDERER = 0x1F01

    private fun fn(name: String, ret: ValueLayout?, vararg args: ValueLayout): MethodHandle {
        val address = Arena.ofConfined().use { a -> Egl.procAddress(a.allocateFrom(name)) }
        check(address.address() != 0L) { "GL function $name not found" }
        return linker.downcallHandle(address, if (ret == null) FunctionDescriptor.ofVoid(*args) else FunctionDescriptor.of(ret, *args))
    }

    private val getString by lazy { fn("glGetString", PTR, I32) }

    /** `GL_RENDERER` of the current context. */
    fun renderer(): String = (getString.call(RENDERER) as MemorySegment).utf8().orEmpty()

    /** `GL_VERSION (GL_RENDERER)` of the current context. */
    fun describe(): String = "${(getString.call(VERSION) as MemorySegment).utf8()} (${renderer()})"
}

package com.edde746.plezy.mpv.core

import com.edde746.plezy.mpv.MpvNatives
import com.edde746.plezy.mpv.ffi.MpvFfi
import com.edde746.plezy.mpv.os.Posix
import com.edde746.plezy.mpv.os.utf8
import com.edde746.plezy.playback.COMMON_MPV_OPTIONS
import java.lang.foreign.Arena
import java.lang.foreign.MemorySegment
import java.lang.foreign.ValueLayout

/**
 * One libmpv handle over the jextract bindings. Not thread-safe by itself: the engine calls it from its own thread
 * only, except [wakeup], which libmpv allows from any thread.
 */
internal class MpvCore private constructor(val handle: MemorySegment) {

    fun setOption(name: String, value: String): Int = Arena.ofConfined().use { a ->
        MpvFfi.mpv_set_option_string(handle, a.allocateFrom(name), a.allocateFrom(value))
    }

    fun setString(name: String, value: String): Int = Arena.ofConfined().use { a ->
        MpvFfi.mpv_set_property_string(handle, a.allocateFrom(name), a.allocateFrom(value))
    }

    fun setFlag(name: String, value: Boolean): Int = Arena.ofConfined().use { a ->
        val data = a.allocateFrom(ValueLayout.JAVA_INT, if (value) 1 else 0)
        MpvFfi.mpv_set_property(handle, a.allocateFrom(name), MpvFfi.MPV_FORMAT_FLAG(), data)
    }

    fun setDouble(name: String, value: Double): Int = Arena.ofConfined().use { a ->
        val data = a.allocateFrom(ValueLayout.JAVA_DOUBLE, value)
        MpvFfi.mpv_set_property(handle, a.allocateFrom(name), MpvFfi.MPV_FORMAT_DOUBLE(), data)
    }

    fun command(vararg args: String): Int = Arena.ofConfined().use { a ->
        val argv = a.allocate(ValueLayout.ADDRESS, args.size + 1L)
        args.forEachIndexed { i, s -> argv.setAtIndex(ValueLayout.ADDRESS, i.toLong(), a.allocateFrom(s)) }
        argv.setAtIndex(ValueLayout.ADDRESS, args.size.toLong(), MemorySegment.NULL)
        MpvFfi.mpv_command(handle, argv)
    }

    fun getString(name: String): String? = Arena.ofConfined().use { a ->
        val p = MpvFfi.mpv_get_property_string(handle, a.allocateFrom(name))
        val s = p.utf8()
        if (p.address() != 0L) MpvFfi.mpv_free(p)
        s
    }

    /** A number property as a double (mpv converts an integer one); null when mpv has no value for it now. */
    fun getDouble(name: String): Double? = Arena.ofConfined().use { a ->
        val data = a.allocate(ValueLayout.JAVA_DOUBLE)
        if (MpvFfi.mpv_get_property(handle, a.allocateFrom(name), MpvFfi.MPV_FORMAT_DOUBLE(), data) < 0) null else data.get(ValueLayout.JAVA_DOUBLE, 0)
    }

    /** Sends [name]'s changes in [format] as events with [id]; throws [IllegalStateException] when mpv refuses. */
    fun observe(id: Long, name: String, format: Int) {
        val rc = Arena.ofConfined().use { a -> MpvFfi.mpv_observe_property(handle, id, a.allocateFrom(name), format) }
        check(rc >= 0) { "mpv_observe_property $name: ${errorString(rc)}" }
    }

    /** Sends mpv's log lines from [minLevel] up as events; throws [IllegalStateException] when mpv refuses. */
    fun requestLogMessages(minLevel: String) {
        val rc = Arena.ofConfined().use { a -> MpvFfi.mpv_request_log_messages(handle, a.allocateFrom(minLevel)) }
        check(rc >= 0) { "mpv_request_log_messages $minLevel: ${errorString(rc)}" }
    }

    /** The returned `mpv_event*` stays valid until the next call. */
    fun waitEvent(timeoutSeconds: Double): MemorySegment = MpvFfi.mpv_wait_event(handle, timeoutSeconds)

    fun wakeup() = MpvFfi.mpv_wakeup(handle)

    /** Blocks until mpv has shut down (it may wait on network teardown); callers run it on a throwaway thread. */
    fun terminateDestroy() = MpvFfi.mpv_terminate_destroy(handle)

    /**
     * A weak client of this initialized core (mpv_create_weak_client), with its own events and log level, for another
     * thread; it never keeps the core alive. It must [destroy] itself once it gets MPV_EVENT_SHUTDOWN, since
     * [terminateDestroy] waits for every client.
     */
    fun createWeakClient(name: String): MpvCore = Arena.ofConfined().use { a ->
        val client = MpvFfi.mpv_create_weak_client(handle, a.allocateFrom(name))
        check(client.address() != 0L) { "mpv_create_weak_client failed" }
        MpvCore(client)
    }

    /** Closes this client ([createWeakClient]'s) without terminating the core. */
    fun destroy() = MpvFfi.mpv_destroy(handle)

    companion object {
        /**
         * Creates, configures and initializes a core: the options every engine sets ([COMMON_MPV_OPTIONS]), then
         * [options], which win over them; then [setUp] on the initialized core. Throws with mpv's reason when a step
         * fails ([IllegalStateException], or what [setUp] throws), and destroys the core.
         */
        fun create(options: Map<String, String>, setUp: (MpvCore) -> Unit = {}): MpvCore {
            MpvNatives.library // fail with the setup hint rather than an ExceptionInInitializerError from MpvFfi
            if (!System.getProperty("os.name").startsWith("Windows")) Posix.useCNumericLocale()
            val handle = MpvFfi.mpv_create()
            check(handle.address() != 0L) { "mpv_create failed" }
            val core = MpvCore(handle)
            try {
                for ((k, v) in COMMON_MPV_OPTIONS + options) {
                    val rc = core.setOption(k, v)
                    check(rc >= 0) { "mpv option $k=$v: ${errorString(rc)}" }
                }
                val rc = MpvFfi.mpv_initialize(handle)
                check(rc >= 0) { "mpv_initialize: ${errorString(rc)}" }
                setUp(core)
            } catch (t: Throwable) {
                MpvFfi.mpv_terminate_destroy(handle)
                throw t
            }
            return core
        }

        fun errorString(rc: Int): String = MpvFfi.mpv_error_string(rc).utf8() ?: "error $rc"
    }
}

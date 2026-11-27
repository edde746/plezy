package com.edde746.plezy.mpv.os

import java.lang.foreign.Arena
import java.lang.foreign.FunctionDescriptor
import java.lang.foreign.MemorySegment
import java.lang.foreign.SymbolLookup
import java.lang.foreign.ValueLayout
import java.lang.invoke.MethodHandles
import java.lang.invoke.MethodType
import java.util.concurrent.ConcurrentHashMap

/**
 * libwayland-client through FFM: the requests the video plane, Compose's GPU layer and the window's decoration make,
 * and the events they read.
 *
 * Requests go through `wl_proxy_marshal_array_flags` (one downcall for every request, arguments as a `wl_argument`
 * array) and events through one `wl_proxy_add_dispatcher` upcall that routes by proxy to a Kotlin handler, so no
 * protocol needs generated C. The core interfaces come from the library itself; the extension protocols' interface
 * tables ([Protocols]) are built here from their XML, and must stay complete and exact: libwayland reads each event's
 * arguments by its signature, and an event the table lacks is a fatal error for the whole connection.
 *
 * A protocol error on any object ends the whole connection, the window's included: every request whose arguments a
 * compositor validates is gated by its caller on what the compositor advertised.
 */
internal object Wl {
    private val lib = SymbolLookup.libraryLookup("libwayland-client.so.0", Arena.global())
    private val arena = Arena.global()

    private val marshalArrayFlags = lib.fn("wl_proxy_marshal_array_flags", PTR, PTR, I32, PTR, I32, I32, PTR)
    private val addDispatcher = lib.fn("wl_proxy_add_dispatcher", I32, PTR, PTR, PTR, PTR)
    private val proxyDestroy = lib.fn("wl_proxy_destroy", null, PTR)
    private val proxyGetVersion = lib.fn("wl_proxy_get_version", I32, PTR)
    private val createWrapper = lib.fn("wl_proxy_create_wrapper", PTR, PTR)
    private val wrapperDestroy = lib.fn("wl_proxy_wrapper_destroy", null, PTR)
    private val setQueue = lib.fn("wl_proxy_set_queue", null, PTR, PTR)
    private val createQueue = lib.fn("wl_display_create_queue", PTR, PTR)
    private val destroyQueue = lib.fn("wl_event_queue_destroy", null, PTR)
    private val roundtripQueue = lib.fn("wl_display_roundtrip_queue", I32, PTR, PTR)
    private val prepareReadQueue = lib.fn("wl_display_prepare_read_queue", I32, PTR, PTR)
    private val readEvents = lib.fn("wl_display_read_events", I32, PTR)
    private val cancelRead = lib.fn("wl_display_cancel_read", null, PTR)
    private val dispatchQueuePending = lib.fn("wl_display_dispatch_queue_pending", I32, PTR, PTR)
    private val flush = lib.fn("wl_display_flush", I32, PTR)
    private val getFd = lib.fn("wl_display_get_fd", I32, PTR)
    private val getError = lib.fn("wl_display_get_error", I32, PTR)

    /** `WL_MARSHAL_FLAG_DESTROY`: the request is the proxy's destructor. */
    private const val DESTROY = 1

    /** The interface the library defines (`wl_surface_interface`, …). */
    fun coreInterface(name: String): MemorySegment = lib.find("${name}_interface").orElseThrow { UnsatisfiedLinkError("${name}_interface") }

    /** The highest version of [iface] this client's tables describe (its `version` field). */
    fun interfaceVersion(iface: MemorySegment): Int = iface.reinterpret(16).get(ValueLayout.JAVA_INT, 8)

    fun interfaceName(iface: MemorySegment): String = iface.reinterpret(8).get(PTR, 0).utf8().orEmpty()

    // ---- queues ------------------------------------------------------------------------------------------------------

    fun createQueue(display: MemorySegment): MemorySegment = createQueue.call(display) as MemorySegment

    fun destroyQueue(queue: MemorySegment) {
        destroyQueue.call(queue)
    }

    /** A wrapper of [proxy] whose new objects land on [queue]; free it with [destroyWrapper]. */
    fun wrapper(proxy: MemorySegment, queue: MemorySegment): MemorySegment {
        val w = createWrapper.call(proxy) as MemorySegment
        check(w.address() != 0L) { "wl_proxy_create_wrapper failed" }
        setQueue.call(w, queue)
        return w
    }

    fun destroyWrapper(wrapper: MemorySegment) {
        wrapperDestroy.call(wrapper)
    }

    /** Dispatches [queue] until the compositor has answered everything sent so far; negative on a dead connection. */
    fun roundtrip(display: MemorySegment, queue: MemorySegment): Int = roundtripQueue.call(display, queue) as Int

    fun flush(display: MemorySegment): Int = flush.call(display) as Int

    /** [queue] of [display], for a [QueueWait]. */
    fun eventQueue(display: MemorySegment, queue: MemorySegment): EventQueue = object : EventQueue {
        override val fd = getFd.call(display) as Int

        override fun prepareRead() = prepareReadQueue.call(display, queue) as Int

        override fun readEvents() = readEvents.call(display) as Int

        override fun cancelRead() {
            cancelRead.call(display)
        }

        override fun dispatchPending() = dispatchQueuePending.call(display, queue) as Int

        override fun flush() = flush(display)

        override fun error() = getError.call(display) as Int
    }

    /** One global the registry announced: [bind] makes this client's object of it. */
    class Global(private val registry: MemorySegment, val name: Int, val iface: String, val version: Int) {
        fun bind(interfaceSegment: MemorySegment, version: Int): MemorySegment =
            request(registry, 0, name, interfaceName(interfaceSegment), version, null, newInterface = interfaceSegment, newVersion = version)
    }

    /**
     * A `wl_registry` made through [wrapper] (so its events land on the wrapper's queue) that hands each announced
     * global to [onGlobal] as the queue is dispatched; free it with [forget].
     */
    fun globals(wrapper: MemorySegment, onGlobal: (Global) -> Unit): MemorySegment {
        val registry = request(wrapper, 1, null, newInterface = coreInterface("wl_registry"), newVersion = 1)
        listen(registry) { opcode, args -> if (opcode == 0) onGlobal(Global(registry, args.uint(0).toInt(), args.string(1).orEmpty(), args.uint(2).toInt())) }
        return registry
    }

    // ---- requests ----------------------------------------------------------------------------------------------------

    fun version(proxy: MemorySegment): Int = proxyGetVersion.call(proxy) as Int

    /**
     * Sends request [opcode] of [proxy] with [args] (Int or Long for `i`/`u`, String for `s`, MemorySegment for `o`, null
     * for a null object and for the `new_id` placeholder). With [newInterface] the request creates an object of it, at
     * [newVersion] (the proxy's own version when 0), which is returned; [destroy] makes it the proxy's destructor.
     */
    fun request(proxy: MemorySegment, opcode: Int, vararg args: Any?, newInterface: MemorySegment? = null, newVersion: Int = 0, destroy: Boolean = false): MemorySegment =
        Arena.ofConfined().use { a ->
            val array = a.allocate(8L * maxOf(1, args.size))
            args.forEachIndexed { i, v ->
                val at = 8L * i
                when (v) {
                    null -> array.set(PTR, at, MemorySegment.NULL)
                    is Int -> array.set(ValueLayout.JAVA_INT, at, v)
                    is Long -> array.set(ValueLayout.JAVA_INT, at, v.toInt())
                    is String -> array.set(PTR, at, a.allocateFrom(v))
                    is MemorySegment -> array.set(PTR, at, v)
                    else -> error("no wl_argument for ${v::class}")
                }
            }
            val version = if (newInterface != null && newVersion > 0) newVersion else version(proxy)
            marshalArrayFlags.call(proxy, opcode, newInterface ?: MemorySegment.NULL, version, if (destroy) DESTROY else 0, array) as MemorySegment
        }

    /** A destructor request (`destroy`, `release`), after which [proxy] is gone. */
    fun destroy(proxy: MemorySegment, opcode: Int = 0) {
        // Before the proxy is freed: once it is, another thread's new proxy may take its address.
        handlers.remove(proxy.address())
        request(proxy, opcode, destroy = true)
    }

    /** Frees [proxy] without a request: for an interface with no destructor request (`wl_callback`, an info object). */
    fun forget(proxy: MemorySegment) {
        handlers.remove(proxy.address())
        proxyDestroy.call(proxy)
    }

    // ---- events ------------------------------------------------------------------------------------------------------

    /** One event's arguments (`union wl_argument[]`), read by position as its signature says. */
    @JvmInline
    value class Args(private val segment: MemorySegment) {
        fun int(i: Int): Int = segment.get(ValueLayout.JAVA_INT, 8L * i)

        fun uint(i: Int): Long = segment.get(ValueLayout.JAVA_INT, 8L * i).toLong() and 0xFFFFFFFFL

        fun string(i: Int): String? = segment.get(PTR, 8L * i).utf8()

        fun obj(i: Int): MemorySegment = segment.get(PTR, 8L * i)
    }

    fun interface Handler {
        fun event(opcode: Int, args: Args)
    }

    private val handlers = ConcurrentHashMap<Long, Handler>()

    /**
     * Routes [proxy]'s events to [handler], on the thread that dispatches its queue. A handler that throws is logged:
     * an exception must never cross into libwayland.
     */
    fun listen(proxy: MemorySegment, handler: Handler) {
        handlers[proxy.address()] = handler
        val rc = addDispatcher.call(proxy, dispatcherStub, MemorySegment.NULL, MemorySegment.NULL) as Int
        check(rc == 0) { "wl_proxy_add_dispatcher failed" }
    }

    @JvmStatic
    @Suppress("unused") // the upcall's target
    private fun dispatch(impl: MemorySegment, proxy: MemorySegment, opcode: Int, message: MemorySegment, args: MemorySegment): Int {
        val handler = handlers[proxy.address()] ?: return 0
        try {
            handler.event(opcode, Args(args.reinterpret(8L * MAX_ARGS)))
        } catch (t: Throwable) {
            System.getLogger(Wl::class.java.name).log(System.Logger.Level.ERROR, "wayland event $opcode failed", t)
        }
        return 0
    }

    /** The most arguments an event here carries (image_description_info's primaries: 8). */
    private const val MAX_ARGS = 8L

    private val dispatcherStub: MemorySegment = linker.upcallStub(
        MethodHandles.lookup().findStatic(
            Wl::class.java, "dispatch",
            MethodType.methodType(Int::class.java, MemorySegment::class.java, MemorySegment::class.java, Int::class.java, MemorySegment::class.java, MemorySegment::class.java),
        ),
        FunctionDescriptor.of(I32, PTR, PTR, I32, PTR, PTR),
        arena,
    )
}

/** The calls a [QueueWait] makes on one event queue of a connection ([Wl.eventQueue]). */
internal interface EventQueue {
    val fd: Int

    /** `wl_display_prepare_read_queue`: 0 once this thread may read; otherwise the queue has events to dispatch first. */
    fun prepareRead(): Int

    fun readEvents(): Int

    fun cancelRead()

    fun dispatchPending(): Int

    fun flush(): Int

    /** The connection's fatal error (errno, EPROTO for a protocol error), 0 while it is alive. */
    fun error(): Int
}

/**
 * A plane thread's wait on its [queue] and its wake-up fd [wakeFd]. A dead connection (a fatal error, or the socket
 * hung up) is logged once and [lost]; from then on the wait sleeps on [wakeFd] alone, as libwayland neither reads nor
 * dispatches on a dead connection and a loop that went on asking it would spin.
 */
internal class QueueWait(private val queue: EventQueue, private val wakeFd: Int, private val name: String) {
    @Volatile var lost = false
        private set

    /** Waits for the queue's events or a wake-up, at most [timeoutMs] (-1: until one), and dispatches the queue. */
    fun await(timeoutMs: Int) {
        if (lost) {
            if (Posix.poll(intArrayOf(wakeFd), timeoutMs)[0] and Posix.POLLIN != 0) Posix.drain(wakeFd)
        } else if (!pump(timeoutMs)) {
            lost = true
            System.getLogger(QueueWait::class.java.name).log(System.Logger.Level.ERROR, "{0}: the Wayland connection failed (error {1})", name, queue.error())
        }
    }

    /** False once the connection is dead. */
    private fun pump(timeoutMs: Int): Boolean {
        while (queue.prepareRead() != 0) if (queue.dispatchPending() < 0) return false
        // A full socket (EAGAIN) is not fatal: the rest goes out on a later flush.
        if (queue.flush() < 0 && queue.error() != 0) {
            queue.cancelRead()
            return false
        }
        val ready = Posix.poll(intArrayOf(queue.fd, wakeFd), timeoutMs)
        if (ready[0] and Posix.POLLIN != 0) {
            if (queue.readEvents() < 0) return false
        } else {
            queue.cancelRead()
            if (ready[0] and (Posix.POLLHUP or Posix.POLLERR) != 0) return false
        }
        if (ready[1] and Posix.POLLIN != 0) Posix.drain(wakeFd)
        return queue.dispatchPending() >= 0
    }
}

/**
 * The extension protocols' interface tables (`struct wl_interface` / `struct wl_message`), in memory for the process:
 * viewporter, color-management-v1 (version 3) and KDE's server-decoration palette.
 */
internal object Protocols {
    /** One request or event: its name, its wire signature (since-version prefix, `?` for nullable) and the interface of each `o`/`n` argument. */
    private class Msg(val name: String, val signature: String, val types: List<String?> = emptyList())

    private class Def(val name: String, val version: Int, val requests: List<Msg>, val events: List<Msg> = emptyList())

    private val defs = listOf(
        Def("wp_viewporter", 1, listOf(Msg("destroy", ""), Msg("get_viewport", "no", listOf("wp_viewport", "wl_surface")))),
        Def("wp_viewport", 1, listOf(Msg("destroy", ""), Msg("set_source", "ffff"), Msg("set_destination", "ii"))),
        Def(
            "wp_color_manager_v1", 3,
            listOf(
                Msg("destroy", ""),
                Msg("get_output", "no", listOf("wp_color_management_output_v1", "wl_output")),
                Msg("get_surface", "no", listOf("wp_color_management_surface_v1", "wl_surface")),
                Msg("get_surface_feedback", "no", listOf("wp_color_management_surface_feedback_v1", "wl_surface")),
                Msg("create_icc_creator", "n", listOf("wp_image_description_creator_icc_v1")),
                Msg("create_parametric_creator", "n", listOf("wp_image_description_creator_params_v1")),
                Msg("create_windows_scrgb", "n", listOf("wp_image_description_v1")),
                Msg("get_image_description", "2no", listOf("wp_image_description_v1", "wp_image_description_reference_v1")),
                Msg("create_windows_bt2100", "3n", listOf("wp_image_description_v1")),
            ),
            listOf(Msg("supported_intent", "u"), Msg("supported_feature", "u"), Msg("supported_tf_named", "u"), Msg("supported_primaries_named", "u"), Msg("done", "")),
        ),
        Def(
            "wp_color_management_output_v1", 3,
            listOf(Msg("destroy", ""), Msg("get_image_description", "n", listOf("wp_image_description_v1"))),
            listOf(Msg("image_description_changed", "")),
        ),
        Def(
            "wp_color_management_surface_v1", 3,
            listOf(Msg("destroy", ""), Msg("set_image_description", "ou", listOf("wp_image_description_v1", null)), Msg("unset_image_description", "")),
        ),
        Def(
            "wp_color_management_surface_feedback_v1", 3,
            listOf(
                Msg("destroy", ""),
                Msg("get_preferred", "n", listOf("wp_image_description_v1")),
                Msg("get_preferred_parametric", "n", listOf("wp_image_description_v1")),
            ),
            listOf(Msg("preferred_changed", "u"), Msg("preferred_changed2", "2uu")),
        ),
        Def(
            "wp_image_description_creator_icc_v1", 3,
            listOf(Msg("create", "n", listOf("wp_image_description_v1")), Msg("set_icc_file", "huu")),
        ),
        Def(
            "wp_image_description_creator_params_v1", 3,
            listOf(
                Msg("create", "n", listOf("wp_image_description_v1")),
                Msg("set_tf_named", "u"),
                Msg("set_tf_power", "u"),
                Msg("set_primaries_named", "u"),
                Msg("set_primaries", "iiiiiiii"),
                Msg("set_luminances", "uuu"),
                Msg("set_mastering_display_primaries", "iiiiiiii"),
                Msg("set_mastering_luminance", "uu"),
                Msg("set_max_cll", "u"),
                Msg("set_max_fall", "u"),
            ),
        ),
        Def(
            "wp_image_description_v1", 3,
            listOf(Msg("destroy", ""), Msg("get_information", "n", listOf("wp_image_description_info_v1"))),
            listOf(Msg("failed", "us"), Msg("ready", "u"), Msg("ready2", "2uu")),
        ),
        Def(
            "wp_image_description_info_v1", 3,
            emptyList(),
            listOf(
                Msg("done", ""), Msg("icc_file", "hu"), Msg("primaries", "iiiiiiii"), Msg("primaries_named", "u"),
                Msg("tf_power", "u"), Msg("tf_named", "u"), Msg("luminances", "uuu"), Msg("target_primaries", "iiiiiiii"),
                Msg("target_luminance", "uu"), Msg("target_max_cll", "u"), Msg("target_max_fall", "u"),
            ),
        ),
        Def("wp_image_description_reference_v1", 1, listOf(Msg("destroy", ""))),
        Def(
            "org_kde_kwin_server_decoration_palette_manager", 1,
            listOf(Msg("create", "no", listOf("org_kde_kwin_server_decoration_palette", "wl_surface"))),
        ),
        Def("org_kde_kwin_server_decoration_palette", 1, listOf(Msg("set_palette", "s"), Msg("release", ""))),
        Def(
            "org_kde_kwin_server_decoration_manager", 1,
            listOf(Msg("create", "no", listOf("org_kde_kwin_server_decoration", "wl_surface"))),
            listOf(Msg("default_mode", "u")),
        ),
        Def("org_kde_kwin_server_decoration", 1, listOf(Msg("release", ""), Msg("request_mode", "u")), listOf(Msg("mode", "u"))),
    )

    private val interfaces: Map<String, MemorySegment>

    init {
        val a = Arena.global()
        val own = defs.associate { it.name to a.allocate(INTERFACE_SIZE, 8) }
        fun resolve(name: String): MemorySegment = own[name] ?: Wl.coreInterface(name)
        fun messages(list: List<Msg>): MemorySegment {
            if (list.isEmpty()) return MemorySegment.NULL
            val array = a.allocate(MESSAGE_SIZE * list.size, 8)
            list.forEachIndexed { i, m ->
                val args = m.signature.count { it.isLetter() }
                val types = a.allocate(8L * maxOf(1, args), 8)
                for (j in 0 until args) types.set(PTR, 8L * j, m.types.getOrNull(j)?.let(::resolve) ?: MemorySegment.NULL)
                val at = MESSAGE_SIZE * i
                array.set(PTR, at, a.allocateFrom(m.name))
                array.set(PTR, at + 8, a.allocateFrom(m.signature))
                array.set(PTR, at + 16, types)
            }
            return array
        }
        for (def in defs) {
            val s = own.getValue(def.name)
            s.set(PTR, 0, a.allocateFrom(def.name))
            s.set(ValueLayout.JAVA_INT, 8, def.version)
            s.set(ValueLayout.JAVA_INT, 12, def.requests.size)
            s.set(PTR, 16, messages(def.requests))
            s.set(ValueLayout.JAVA_INT, 24, def.events.size)
            s.set(PTR, 32, messages(def.events))
        }
        interfaces = own
    }

    operator fun get(name: String): MemorySegment = interfaces[name] ?: error("no interface table for $name")

    private const val INTERFACE_SIZE = 40L
    private const val MESSAGE_SIZE = 24L
}

package com.edde746.plezy.desktop.windows

import com.edde746.plezy.desktop.bind
import com.edde746.plezy.desktop.int
import com.edde746.plezy.log.Log
import java.lang.foreign.Arena
import java.lang.foreign.FunctionDescriptor
import java.lang.foreign.Linker
import java.lang.foreign.MemoryLayout
import java.lang.foreign.MemorySegment
import java.lang.foreign.SymbolLookup
import java.lang.foreign.ValueLayout.ADDRESS
import java.lang.foreign.ValueLayout.JAVA_BYTE
import java.lang.foreign.ValueLayout.JAVA_DOUBLE
import java.lang.foreign.ValueLayout.JAVA_INT
import java.lang.foreign.ValueLayout.JAVA_LONG
import java.lang.invoke.MethodHandle
import java.lang.invoke.MethodHandles
import java.lang.invoke.MethodType
import java.nio.ByteBuffer
import java.nio.charset.StandardCharsets.UTF_16LE
import java.security.MessageDigest
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger

/** A COM or Windows Runtime call that failed with [hresult]. */
internal class ComException(what: String, val hresult: Int) : Exception("$what failed: HRESULT 0x%08X".format(hresult))

/**
 * COM and the Windows Runtime through the JDK's FFM API (like mpv-jvm's libmpv and Win32 calls; no JNI, no C):
 * interface pointers are [MemorySegment]s and methods are called by vtable slot (IUnknown 0–2, IInspectable 3–5, then
 * the interface's own methods in metadata order). Runtime classes come from their activation factories, strings go in
 * as HSTRINGs, and delegates the runtime calls back (event handlers) are [Delegate]s.
 *
 * A thread calls [initializeThread] before its first call (the multithreaded apartment).
 */
internal object WinRt {
    private const val E_NOINTERFACE = 0x80004002.toInt()
    private const val RO_INIT_MULTITHREADED = 1

    private val IID_IUNKNOWN = guid("00000000-0000-0000-c000-000000000046")
    private val IID_IAGILE_OBJECT = guid("94ea2b94-e9cc-49e0-c0ff-ee64ca8f5b90")

    /** The namespace of parameterized interface IDs (the Windows Runtime type system's GUID generation). */
    private val PINTERFACE_NAMESPACE = UUID.fromString("11f47ad5-7b73-42c0-abae-878b1e16adee")

    private val linker = Linker.nativeLinker()
    private val methods = ConcurrentHashMap<FunctionDescriptor, MethodHandle>()

    /** Joins the calling thread to the multithreaded apartment; false when it can't (it is already single-threaded). */
    fun initializeThread(): Boolean = Api.roInitialize.int(RO_INIT_MULTITHREADED) >= 0

    fun uninitializeThread() {
        Api.roUninitialize.invokeWithArguments()
    }

    /**
     * Calls method [slot] of the interface [self] with [args] (MemorySegment, Int, Long, Double; a Boolean goes in as a
     * Windows Runtime boolean, one byte) and returns its HRESULT. A struct of one 64-bit field (TimeSpan) is a Long.
     */
    fun call(self: MemorySegment, slot: Int, vararg args: Any): Int {
        val layouts = arrayOf<MemoryLayout>(ADDRESS) + args.map(::layoutOf)
        val handle = methods.computeIfAbsent(FunctionDescriptor.of(JAVA_INT, *layouts)) { linker.downcallHandle(it) }
        val vtable = self.reinterpret(ADDRESS.byteSize()).get(ADDRESS, 0).reinterpret((slot + 1) * ADDRESS.byteSize())
        val values = ArrayList<Any>(args.size + 2)
        values += vtable.getAtIndex(ADDRESS, slot.toLong())
        values += self
        args.mapTo(values) { if (it is Boolean) (if (it) 1 else 0).toByte() else it }
        return handle.invokeWithArguments(values) as Int
    }

    /** [call], throwing a [ComException] naming [what] on a failed HRESULT. */
    fun invoke(what: String, self: MemorySegment, slot: Int, vararg args: Any) = check(what, call(self, slot, *args))

    /** Calls a method whose last parameter receives an interface pointer, and returns it (the caller [release]s it). */
    fun invokeForObject(what: String, self: MemorySegment, slot: Int, vararg args: Any): MemorySegment = Arena.ofConfined().use { a ->
        val out = a.allocate(ADDRESS)
        invoke(what, self, slot, *args, out)
        out.get(ADDRESS, 0)
    }

    /** Calls a method whose last parameter receives a 32-bit value (an enum), and returns it. */
    fun invokeForInt(what: String, self: MemorySegment, slot: Int, vararg args: Any): Int = Arena.ofConfined().use { a ->
        val out = a.allocate(JAVA_INT)
        invoke(what, self, slot, *args, out)
        out.get(JAVA_INT, 0)
    }

    /** Calls a method whose last parameter receives a 64-bit value (a TimeSpan, an event registration token). */
    fun invokeForLong(what: String, self: MemorySegment, slot: Int, vararg args: Any): Long = Arena.ofConfined().use { a ->
        val out = a.allocate(JAVA_LONG)
        invoke(what, self, slot, *args, out)
        out.get(JAVA_LONG, 0)
    }

    fun queryInterface(self: MemorySegment, iid: MemorySegment): MemorySegment = invokeForObject("QueryInterface", self, 0, iid)

    /** Releases an interface pointer; NULL is ignored. */
    fun release(self: MemorySegment?) {
        if (self != null && self.address() != 0L) call(self, 2)
    }

    fun check(what: String, hresult: Int) {
        if (hresult < 0) throw ComException(what, hresult)
    }

    /** The activation factory of the runtime class [className], as the interface [iid]. */
    fun activationFactory(className: String, iid: MemorySegment): MemorySegment = withHString(className) { name ->
        Arena.ofConfined().use { a ->
            val out = a.allocate(ADDRESS)
            check("RoGetActivationFactory($className)", Api.roGetActivationFactory.int(name, iid, out))
            out.get(ADDRESS, 0)
        }
    }

    /** A new instance of the runtime class [className] through its default constructor, as IInspectable. */
    fun activateInstance(className: String): MemorySegment = withHString(className) { name ->
        Arena.ofConfined().use { a ->
            val out = a.allocate(ADDRESS)
            check("RoActivateInstance($className)", Api.roActivateInstance.int(name, out))
            out.get(ADDRESS, 0)
        }
    }

    /** Runs [block] with [text] as an HSTRING, deleted afterwards. */
    fun <T> withHString(text: String, block: (MemorySegment) -> T): T = Arena.ofConfined().use { a ->
        val out = a.allocate(ADDRESS)
        check("WindowsCreateString", Api.windowsCreateString.int(a.allocateFrom(text, UTF_16LE), text.length, out))
        val string = out.get(ADDRESS, 0)
        try {
            block(string)
        } finally {
            Api.windowsDeleteString.invokeWithArguments(string)
        }
    }

    /** A GUID in its in-memory layout (Data1–3 little-endian, Data4 as written), for the process's lifetime. */
    fun guid(text: String): MemorySegment = guid(UUID.fromString(text))

    fun guid(uuid: UUID): MemorySegment {
        val msb = uuid.mostSignificantBits
        val lsb = uuid.leastSignificantBits
        val bytes = ByteBuffer.allocate(16).order(java.nio.ByteOrder.LITTLE_ENDIAN)
            .putInt((msb ushr 32).toInt()).putShort((msb ushr 16).toShort()).putShort(msb.toShort())
            .order(java.nio.ByteOrder.BIG_ENDIAN).putLong(lsb)
            .array()
        return Arena.global().allocate(16).copyFrom(MemorySegment.ofArray(bytes))
    }

    /**
     * The interface ID of a parameterized interface instance from its type signature, e.g.
     * `pinterface({9de1c534-…};rc(Windows.Media.SystemMediaTransportControls;{99fa3ff4-…});rc(…))` for a
     * TypedEventHandler: SHA-1 over the namespace GUID and the UTF-8 signature, as a version 5 UUID.
     */
    fun parameterizedIid(signature: String): UUID {
        val namespace = ByteBuffer.allocate(16).putLong(PINTERFACE_NAMESPACE.mostSignificantBits).putLong(PINTERFACE_NAMESPACE.leastSignificantBits).array()
        val hash = MessageDigest.getInstance("SHA-1").run {
            update(namespace)
            digest(signature.toByteArray(Charsets.UTF_8))
        }
        hash[6] = ((hash[6].toInt() and 0x0f) or 0x50).toByte()
        hash[8] = ((hash[8].toInt() and 0x3f) or 0x80).toByte()
        val buffer = ByteBuffer.wrap(hash, 0, 16)
        return UUID(buffer.getLong(), buffer.getLong())
    }

    private fun layoutOf(arg: Any): MemoryLayout = when (arg) {
        is MemorySegment -> ADDRESS
        is Int -> JAVA_INT
        is Long -> JAVA_LONG
        is Double -> JAVA_DOUBLE
        is Boolean -> JAVA_BYTE
        else -> throw IllegalArgumentException("no native layout for ${arg::class}")
    }

    /**
     * A delegate for the runtime to call: a COM object implementing the delegate interface [iid] (e.g. an instance of
     * TypedEventHandler), whose Invoke(sender, args) runs [onInvoke] on the runtime's thread. It is agile, so the
     * runtime calls it from any thread without marshaling. Reference-counted: [release] drops the creator's reference
     * once it stopped listening. The object's 16 bytes stay allocated for the process, since the runtime may release its
     * references later.
     */
    class Delegate(internal val iid: MemorySegment, internal val onInvoke: (sender: MemorySegment, args: MemorySegment) -> Unit) {
        internal val references = AtomicInteger(1)

        /** The COM object, to hand to an `add_…` method. */
        val pointer: MemorySegment = Arena.global().allocate(16).also {
            it.set(ADDRESS, 0, Upcalls.vtable)
            delegates[it.address()] = this
        }

        fun release() {
            Upcalls.release(pointer)
        }
    }

    private val delegates = ConcurrentHashMap<Long, Delegate>()

    /** The delegates' IUnknown + Invoke vtable as upcall stubs. They never throw: an exception here would end the JVM. */
    internal object Upcalls {
        val vtable: MemorySegment by lazy {
            val lookup = MethodHandles.lookup()
            val int = Int::class.javaPrimitiveType
            val segment = MemorySegment::class.java
            fun stub(name: String, vararg params: Class<*>): MemorySegment = linker.upcallStub(
                lookup.findStatic(Upcalls::class.java, name, MethodType.methodType(int, params)),
                FunctionDescriptor.of(JAVA_INT, *Array(params.size) { ADDRESS }),
                Arena.global(),
            )
            Arena.global().allocate(ADDRESS.byteSize() * 4).also {
                it.setAtIndex(ADDRESS, 0, stub("queryInterface", segment, segment, segment))
                it.setAtIndex(ADDRESS, 1, stub("addRef", segment))
                it.setAtIndex(ADDRESS, 2, stub("release", segment))
                it.setAtIndex(ADDRESS, 3, stub("invoke", segment, segment, segment))
            }
        }

        @JvmStatic
        fun queryInterface(self: MemorySegment, riid: MemorySegment, out: MemorySegment): Int {
            val result = out.reinterpret(ADDRESS.byteSize())
            val delegate = delegates[self.address()]
            val iid = riid.reinterpret(16)
            if (delegate == null || listOf(IID_IUNKNOWN, IID_IAGILE_OBJECT, delegate.iid).none { iid.mismatch(it) == -1L }) {
                result.set(ADDRESS, 0, MemorySegment.NULL)
                return E_NOINTERFACE
            }
            delegate.references.incrementAndGet()
            result.set(ADDRESS, 0, self)
            return 0
        }

        @JvmStatic
        fun addRef(self: MemorySegment): Int = delegates[self.address()]?.references?.incrementAndGet() ?: 1

        @JvmStatic
        fun release(self: MemorySegment): Int {
            val delegate = delegates[self.address()] ?: return 0
            val left = delegate.references.decrementAndGet()
            if (left == 0) delegates.remove(self.address())
            return left
        }

        @JvmStatic
        fun invoke(self: MemorySegment, sender: MemorySegment, args: MemorySegment): Int {
            try {
                delegates[self.address()]?.onInvoke?.invoke(sender, args)
            } catch (t: Throwable) {
                Log.e("winrt", t) { "event handler failed" }
            }
            return 0
        }
    }

    /** combase's runtime functions, bound on first use. */
    private object Api {
        private val combase = SymbolLookup.libraryLookup("combase", Arena.global())

        val roInitialize: MethodHandle = combase.bind("RoInitialize", FunctionDescriptor.of(JAVA_INT, JAVA_INT))
        val roUninitialize: MethodHandle = combase.bind("RoUninitialize", FunctionDescriptor.ofVoid())
        val roGetActivationFactory: MethodHandle = combase.bind("RoGetActivationFactory", FunctionDescriptor.of(JAVA_INT, ADDRESS, ADDRESS, ADDRESS))
        val roActivateInstance: MethodHandle = combase.bind("RoActivateInstance", FunctionDescriptor.of(JAVA_INT, ADDRESS, ADDRESS))
        val windowsCreateString: MethodHandle = combase.bind("WindowsCreateString", FunctionDescriptor.of(JAVA_INT, ADDRESS, JAVA_INT, ADDRESS))
        val windowsDeleteString: MethodHandle = combase.bind("WindowsDeleteString", FunctionDescriptor.of(JAVA_INT, ADDRESS))
    }
}

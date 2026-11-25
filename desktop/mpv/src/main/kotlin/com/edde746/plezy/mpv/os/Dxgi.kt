package com.edde746.plezy.mpv.os

import java.lang.foreign.Arena
import java.lang.foreign.FunctionDescriptor
import java.lang.foreign.MemorySegment
import java.lang.foreign.SymbolLookup
import java.lang.foreign.ValueLayout

/** DXGI's adapter list, through its COM vtables. */
internal object Dxgi {
    /** Qualcomm's DXGI vendor ids: the FourCC 'QCOM' its Windows driver reports (Adreno X1-85), and its PCI-SIG id. */
    private val QUALCOMM_VENDOR_IDS = setOf(0x4D4F4351, 0x5143)

    /**
     * Whether any GPU here is a Qualcomm Adreno. The whole list is read rather than predicting mpv's adapter (the DXGI
     * default): no machine pairs an Adreno with another GPU, and an x64 build emulated on Windows on Arm is covered
     * where an architecture check would miss it. False when DXGI can't be read.
     */
    val hasQualcommGpu: Boolean by lazy { runCatching { vendorIds().any { it in QUALCOMM_VENDOR_IDS } }.getOrDefault(false) }

    private fun vendorIds(): List<Int> = Arena.ofConfined().use { a ->
        val dxgi = SymbolLookup.libraryLookup("dxgi", a)
        val create = dxgi.fn("CreateDXGIFactory1", I32, PTR, PTR)
        val iid = a.allocate(16).also { guid(it, IID_IDXGI_FACTORY1) }
        val out = a.allocate(PTR)
        if (create.call(iid, out) as Int != 0) return emptyList()
        val factory = out.get(PTR, 0).reinterpret(Long.MAX_VALUE)
        val ids = mutableListOf<Int>()
        try {
            var i = 0
            while (true) {
                if (method(factory, ENUM_ADAPTERS1, I32, PTR, I32, PTR).call(factory, i++, out) as Int != 0) break
                val adapter = out.get(PTR, 0).reinterpret(Long.MAX_VALUE)
                val desc = a.allocate(DESC1_BYTES)
                if (method(adapter, GET_DESC1, I32, PTR, PTR).call(adapter, desc) as Int == 0) ids += desc.get(ValueLayout.JAVA_INT, VENDOR_ID_OFFSET)
                release(adapter)
            }
        } finally {
            release(factory)
        }
        ids
    }

    private fun release(obj: MemorySegment) {
        method(obj, RELEASE, I32, PTR).call(obj)
    }

    /** The vtable entry [index] of the COM object [obj]. */
    private fun method(obj: MemorySegment, index: Int, ret: ValueLayout, vararg args: ValueLayout) = linker.downcallHandle(
        obj.get(PTR, 0).reinterpret(Long.MAX_VALUE).getAtIndex(PTR, index.toLong()),
        FunctionDescriptor.of(ret, *args),
    )

    private fun guid(segment: MemorySegment, text: String) {
        val hex = text.replace("-", "")
        segment.set(ValueLayout.JAVA_INT, 0, hex.substring(0, 8).toLong(16).toInt())
        segment.set(ValueLayout.JAVA_SHORT, 4, hex.substring(8, 12).toInt(16).toShort())
        segment.set(ValueLayout.JAVA_SHORT, 6, hex.substring(12, 16).toInt(16).toShort())
        for (b in 0 until 8) segment.set(ValueLayout.JAVA_BYTE, 8L + b, hex.substring(16 + b * 2, 18 + b * 2).toInt(16).toByte())
    }

    private const val IID_IDXGI_FACTORY1 = "770aae78-f26f-4dba-a829-253c83d1b387"

    /** IUnknown's Release, IDXGIFactory1's EnumAdapters1, IDXGIAdapter1's GetDesc1. */
    private const val RELEASE = 2
    private const val ENUM_ADAPTERS1 = 12
    private const val GET_DESC1 = 10

    /** DXGI_ADAPTER_DESC1: Description (WCHAR[128]) and then VendorId. */
    private const val DESC1_BYTES = 312L
    private const val VENDOR_ID_OFFSET = 256L
}

package com.edde746.plezy.downloads

import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

/**
 * How much time an MPEG transport stream covers: the latest presentation time stamp in its last [WINDOW] bytes minus
 * the earliest in its first, over all its elementary streams. A transcode the server ended early stops short of its
 * item's runtime, which a file of that format otherwise can't tell (it has no index or duration to finish).
 */
internal object TransportStreamSpan {
    /** How much of each end is read. */
    const val WINDOW = 2 * 1024 * 1024

    private const val PACKET = 188
    private const val SYNC = 0x47
    private const val CLOCK_HZ = 90_000L
    private const val WRAP = 1L shl 33

    /** The runtime a whole file may fall short by: the last frame's length and the encoder's rounding. */
    private val SLACK = 2.seconds

    /** Streams whose PES header has no time stamp fields: program stream map, padding, private 2, ECM, EMM, directory. */
    private val UNTIMED_STREAMS = setOf(0xBC, 0xBE, 0xBF, 0xF0, 0xF1, 0xFF)

    /**
     * The span of a stream of [size] bytes read through [read] (bytes from an offset, fewer at the end, null when it
     * can't be read); null when either end holds no time stamp.
     */
    suspend fun measure(size: Long, read: suspend (offset: Long, length: Int) -> ByteArray?): Duration? {
        if (size <= 0) return null
        val head = read(0, minOf(size, WINDOW.toLong()).toInt()) ?: return null
        val tailStart = maxOf(0L, size - WINDOW)
        val tail = if (tailStart == 0L) head else read(tailStart, (size - tailStart).toInt()) ?: return null
        val first = timestamps(head).minOrNull() ?: return null
        var last = timestamps(tail).maxOrNull() ?: return null
        // The 33-bit clock wraps every 26.5 hours.
        if (last < first) last += WRAP
        return ((last - first) * 1000 / CLOCK_HZ).milliseconds
    }

    /** Whether [span] covers [runtimeMs], short by at most [SLACK] and 1%. */
    fun covers(span: Duration, runtimeMs: Long): Boolean = span + SLACK + (runtimeMs / 100).milliseconds >= runtimeMs.milliseconds

    /** The presentation time stamps (90 kHz) of the PES packets that start in [bytes], from the first packet boundary. */
    fun timestamps(bytes: ByteArray): List<Long> {
        val start = (0 until PACKET).firstOrNull { offset ->
            (0 until 3).all { n -> offset + n * PACKET < bytes.size && bytes.u(offset + n * PACKET) == SYNC }
        } ?: return emptyList()
        val found = mutableListOf<Long>()
        var packet = start
        while (packet + PACKET <= bytes.size) {
            if (bytes.u(packet) == SYNC) pts(bytes, packet)?.let(found::add)
            packet += PACKET
        }
        return found
    }

    /** The time stamp of the PES header starting in the packet at [packet], if it carries one. */
    private fun pts(bytes: ByteArray, packet: Int): Long? {
        val unitStart = bytes.u(packet + 1) and 0x40 != 0
        val adaptation = (bytes.u(packet + 3) shr 4) and 0x3
        if (!unitStart || adaptation and 0x1 == 0) return null
        val payload = packet + 4 + if (adaptation and 0x2 != 0) 1 + bytes.u(packet + 4) else 0
        val end = packet + PACKET
        if (payload + 14 > end) return null
        if (bytes.u(payload) != 0 || bytes.u(payload + 1) != 0 || bytes.u(payload + 2) != 1) return null
        if (bytes.u(payload + 3) in UNTIMED_STREAMS) return null
        if ((bytes.u(payload + 7) shr 6) and 0x2 == 0) return null
        val p = payload + 9
        return ((bytes.u(p).toLong() shr 1) and 0x7 shl 30) or
            (bytes.u(p + 1).toLong() shl 22) or
            ((bytes.u(p + 2).toLong() shr 1) shl 15) or
            (bytes.u(p + 3).toLong() shl 7) or
            (bytes.u(p + 4).toLong() shr 1)
    }

    private fun ByteArray.u(index: Int): Int = this[index].toInt() and 0xFF
}

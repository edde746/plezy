package com.edde746.plezy.trackers.ids

import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.UByteVar
import kotlinx.cinterop.addressOf
import kotlinx.cinterop.alloc
import kotlinx.cinterop.convert
import kotlinx.cinterop.memScoped
import kotlinx.cinterop.ptr
import kotlinx.cinterop.reinterpret
import kotlinx.cinterop.sizeOf
import kotlinx.cinterop.toKString
import kotlinx.cinterop.usePinned
import platform.zlib.Z_FINISH
import platform.zlib.Z_OK
import platform.zlib.Z_STREAM_END
import platform.zlib.inflate
import platform.zlib.inflateEnd
import platform.zlib.inflateInit2_
import platform.zlib.z_stream
import platform.zlib.zlibVersion

/**
 * Through the system zlib, in one call: zlib checks the member's CRC and size as it ends the stream, and a stream that
 * unpacks to more than [into] takes stops without its end (Z_BUF_ERROR).
 */
@OptIn(ExperimentalForeignApi::class)
internal actual fun inflateGzip(packed: ByteArray, into: ByteArray): Unit = memScoped {
    val stream = alloc<z_stream>()
    // 15 + 16: a gzip stream with the largest window.
    val init = inflateInit2_(stream.ptr, 15 + 16, zlibVersion()?.toKString(), sizeOf<z_stream>().convert())
    check(init == Z_OK) { "zlib doesn't start ($init)" }
    try {
        val status = packed.usePinned { input ->
            into.usePinned { output ->
                stream.next_in = input.addressOf(0).reinterpret<UByteVar>()
                stream.avail_in = packed.size.convert()
                // An empty [into] has no first byte to point at: no output, with avail_out 0.
                stream.next_out = if (into.isEmpty()) null else output.addressOf(0).reinterpret<UByteVar>()
                stream.avail_out = into.size.convert()
                inflate(stream.ptr, Z_FINISH)
            }
        }
        check(status == Z_STREAM_END) { "the gzip file is damaged, cut short or longer than its trailer says ($status)" }
        check(stream.total_out.toLong() == into.size.toLong()) { "the gzip file holds ${stream.total_out} bytes, its trailer says ${into.size}" }
        check(stream.avail_in == 0u) { "the gzip file has ${stream.avail_in} bytes after its end" }
    } finally {
        inflateEnd(stream.ptr)
    }
}

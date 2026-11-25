package com.edde746.plezy.trackers.ids

import java.util.zip.GZIPInputStream

/** Through GZIPInputStream, which checks the member's CRC and size at its end. */
internal actual fun inflateGzip(packed: ByteArray, into: ByteArray) {
    GZIPInputStream(packed.inputStream(), BUFFER_BYTES).use { input ->
        var filled = 0
        while (filled < into.size) {
            val read = input.read(into, filled, into.size - filled)
            check(read > 0) { "the gzip file is cut short: $filled of ${into.size} bytes" }
            filled += read
        }
        // Reaching the end reads the trailer, which checks the CRC; more data is another member, or a wrong trailer.
        check(input.read() == -1) { "the gzip file holds more than its trailer says" }
    }
}

private const val BUFFER_BYTES = 64 * 1024

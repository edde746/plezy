package com.edde746.plezy.trackers.ids

/**
 * The single gzip member [packed] unpacked, into an array of the size its trailer gives. Throws when [packed] isn't
 * gzip, is damaged or cut short, holds more than one member, or unpacks to more than [MAX_UNPACKED_BYTES].
 */
internal fun gunzip(packed: ByteArray): ByteArray {
    require(packed.size >= GZIP_MIN_BYTES) { "not gzip: ${packed.size} bytes" }
    val n = packed.size
    // ISIZE, the trailer's last four bytes: the unpacked size modulo 2^32.
    val size = (packed[n - 4].toLong() and 0xFF) or ((packed[n - 3].toLong() and 0xFF) shl 8) or
        ((packed[n - 2].toLong() and 0xFF) shl 16) or ((packed[n - 1].toLong() and 0xFF) shl 24)
    require(size <= MAX_UNPACKED_BYTES) { "gzip trailer gives $size bytes, more than $MAX_UNPACKED_BYTES" }
    return ByteArray(size.toInt()).also { inflateGzip(packed, it) }
}

/**
 * Inflates the gzip member [packed] into [into], which it must fill exactly and end there. Throws when [packed] isn't
 * gzip, is damaged, or holds more or fewer bytes than [into] takes.
 */
internal expect fun inflateGzip(packed: ByteArray, into: ByteArray)

/** A gzip member's header (10 bytes) and trailer (8). */
private const val GZIP_MIN_BYTES = 18

/** Far above the anime mappings' unpacked size: a bound on what a damaged trailer can make this allocate. */
private const val MAX_UNPACKED_BYTES = 64L * 1024 * 1024

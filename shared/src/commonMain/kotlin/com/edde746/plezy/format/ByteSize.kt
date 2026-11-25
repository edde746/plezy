package com.edde746.plezy.format

import com.edde746.plezy.strings.T
import kotlin.math.roundToLong

/**
 * A byte count for display, 1024-based with the B/KB/MB/GB/TB labels.
 * One decimal below 100 of a unit ("12.3 GB", "4 GB", "1.5 KB"), none from 100 ("850 MB"). Negative counts render as
 * zero. [keepZero] keeps a zero decimal below 100 ("4.0 GB"), for a count that changes as it shows (a cache, a speed):
 * its text then keeps its length as it moves.
 */
fun formatByteSize(bytes: Long, keepZero: Boolean = false): String {
    if (bytes < 1024) return T.format.size.bytes(bytes.coerceAtLeast(0).toString())
    var unit = 0
    var value = bytes.toDouble()
    while (value >= 1024 && unit < UNITS - 1) {
        value /= 1024
        unit++
    }
    var tenths = roundToTenths(value)
    // 1023.96 MB rounds to 1024: that is 1 GB.
    if (tenths >= 10240 && unit < UNITS - 1) {
        unit++
        tenths = roundToTenths(value / 1024)
    }
    val number = if (tenths % 10 == 0L && (!keepZero || tenths >= 1000)) {
        (tenths / 10).toString()
    } else {
        "${tenths / 10}${T.format.size.decimalSeparator}${tenths % 10}"
    }
    return when (unit) {
        1 -> T.format.size.kilobytes(number)
        2 -> T.format.size.megabytes(number)
        3 -> T.format.size.gigabytes(number)
        else -> T.format.size.terabytes(number)
    }
}

private const val UNITS = 5 // B, KB, MB, GB, TB

/** Tenths of [value]: one decimal below 100, whole numbers (in tenths) from 100. */
private fun roundToTenths(value: Double): Long =
    if (value < 99.95) (value * 10).roundToLong() else value.roundToLong() * 10

package com.edde746.plezy.format

/** `m:ss`, or `h:mm:ss` from one hour. Negative and non-finite values render as `0:00`. */
fun formatTimecode(seconds: Double): String {
    val total = if (seconds.isFinite() && seconds > 0) seconds.toLong() else 0L
    val h = total / 3600
    val m = (total % 3600) / 60
    val s = total % 60
    fun two(n: Long) = n.toString().padStart(2, '0')
    return if (h > 0) "$h:${two(m)}:${two(s)}" else "$m:${two(s)}"
}

package com.edde746.plezy.crash

import com.edde746.plezy.log.Log
import kotlinx.coroutines.delay
import kotlin.math.roundToLong
import kotlin.time.ComparableTimeMark
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

/**
 * When [RssWatchdog] evicts the image caches: the process's resident memory above [threshold] bytes, checked every
 * [period]; when the app goes to the background, above [backgroundThreshold].
 */
data class RssPolicy(val threshold: Long, val period: Duration, val backgroundThreshold: Long) {
    companion object {
        /** Windows, Linux and the Mac: 1.5 GiB, every 30 s; 1 GiB in the background. */
        val DESKTOP = RssPolicy(1536 * MIB, 30.seconds, 1024 * MIB)

        /**
         * Android: 45 % of the device's RAM ([totalRamBytes]) within 512 MiB..1.5 GiB, or 1 GiB when it is unknown;
         * every 15 s on low-end hardware ([lowEndAndroid]: decodes there swell the process within seconds), 30 s
         * otherwise. In the background, the low-memory killer's first candidate: 35 % of the RAM, or 768 MiB.
         */
        fun android(totalRamBytes: Long?, lowEnd: Boolean): RssPolicy = RssPolicy(
            threshold = totalRamBytes?.let { (it * 0.45).roundToLong().coerceIn(512 * MIB, 1536 * MIB) } ?: (1024 * MIB),
            period = if (lowEnd) 15.seconds else 30.seconds,
            backgroundThreshold = totalRamBytes?.let { (it * 0.35).roundToLong() } ?: (768 * MIB),
        )

        /**
         * Low-end Android hardware: a 32-bit process, a device that calls itself low-RAM, or at most 2252 MiB of RAM (a
         * nominal 2 GB device reports a little over 2 GiB after the carve-outs).
         */
        fun lowEndAndroid(is64Bit: Boolean, lowRamDevice: Boolean, totalRamBytes: Long?): Boolean =
            !is64Bit || lowRamDevice || (totalRamBytes != null && totalRamBytes <= 2252 * MIB)
    }
}

private const val MIB = 1L shl 20

/**
 * Evicts the image caches ([evict]) before the process's resident memory ([rss], in bytes; null when unreadable) gets
 * it killed: Android's low-memory killer can strike without a trim callback first, and a desktop's decoded images grow
 * without bound. Desktop and Android run it ([run]); iOS and tvOS hear the system's memory warnings instead.
 *
 * - [check], every [RssPolicy.period]: above [RssPolicy.threshold] it evicts, unless the caches hold under 8 MiB
 *   ([imageCacheBytes]; clearing a small cache buys nothing, and fetching it again is its own spike), or the last
 *   eviction was under 60 s ago and the memory hasn't risen past what it was then.
 * - [onBackground]: above [RssPolicy.backgroundThreshold] it evicts.
 * - [onMemoryPressure], the system's warning: it always evicts.
 *
 * Main thread only.
 */
class RssWatchdog(
    private val policy: RssPolicy,
    private val rss: () -> Long?,
    private val imageCacheBytes: () -> Long,
    private val evict: () -> Unit,
    private val timeSource: TimeSource.WithComparableMarks = TimeSource.Monotonic,
) {
    private var lastEviction: ComparableTimeMark? = null
    private var lastEvictionRss = 0L

    /** Checks every [RssPolicy.period] until cancelled. */
    suspend fun run(): Nothing {
        Log.i(TAG) {
            "RSS watchdog armed: threshold ${policy.threshold shr 20} MB every ${policy.period.inWholeSeconds} s, " +
                "background ${policy.backgroundThreshold shr 20} MB"
        }
        while (true) {
            delay(policy.period)
            check()
        }
    }

    /** One periodic check; true when it evicted. */
    fun check(): Boolean {
        val resident = rss() ?: return false
        if (resident <= policy.threshold) return false
        val cache = imageCacheBytes()
        if (cache < MIN_CACHE_BYTES) return false
        val now = timeSource.markNow()
        val last = lastEviction
        if (last != null && now - last < COOLDOWN && resident <= lastEvictionRss) return false
        lastEviction = now
        lastEvictionRss = resident
        Log.w(TAG) { "RSS high (${resident shr 20} MB > ${policy.threshold shr 20} MB), evicting image caches (cache ${cache shr 20} MB)" }
        evict()
        return true
    }

    /** The app went to the background; true when it evicted. */
    fun onBackground(): Boolean {
        val resident = rss() ?: return false
        if (resident <= policy.backgroundThreshold) return false
        Log.w(TAG) { "RSS high in the background (${resident shr 20} MB > ${policy.backgroundThreshold shr 20} MB), evicting image caches" }
        evict()
        return true
    }

    /** The system asked the process to release memory. */
    fun onMemoryPressure() {
        Log.w(TAG) { "System memory pressure, evicting image caches" }
        evict()
    }

    companion object {
        /** A cache smaller than this isn't evicted by [check]. */
        const val MIN_CACHE_BYTES = 8 * MIB

        /** After an eviction, [check] evicts again within this only if the memory rose past it. */
        val COOLDOWN = 60.seconds

        private const val TAG = "memory"
    }
}

package com.edde746.plezy.mpv

import android.content.ComponentCallbacks2

/**
 * The demuxer cache an Android mpv session holds, from the device's heap class
 * (`ActivityManager.getLargeMemoryClass`): mpv knows nothing of the device's memory, and its fixed 150 MiB ahead plus
 * 50 MiB back crowds a 1 GB TV box until the low-memory killer ends the app.
 *
 * Android's memory pressure narrows it ([forTrimLevel], [narrowedTo]); Android never says when the pressure ends, so
 * the engine samples the low-memory killer's threshold and walks the budget back one rung at a time ([widenedToward],
 * gated by [canWiden]).
 */
data class DemuxerBudget(val aheadBytes: Long, val backBytes: Long) {
    /** Ahead and back: with `demuxer-donate-buffer` on (mpv's default), the resident ceiling. */
    val totalBytes: Long get() = aheadBytes + backBytes

    /**
     * This budget narrowed to [wanted], never widened: trim levels aren't ordered by severity, and a milder one after
     * a harsher one would ask for the growth that got the app killed. Widening is the restore's alone.
     */
    fun narrowedTo(wanted: DemuxerBudget): DemuxerBudget =
        DemuxerBudget(aheadBytes = minOf(aheadBytes, wanted.aheadBytes), backBytes = minOf(backBytes, wanted.backBytes))

    /**
     * The next step back toward [steady], or null once there: read-ahead first, one tier rung at a time (a stream-rate
     * value of 60 MiB steps to 64, not 100), then the back cache at once, which went first and comes back last. Never
     * past [steady] on either axis.
     */
    fun widenedToward(steady: DemuxerBudget): DemuxerBudget? = when {
        aheadBytes < steady.aheadBytes -> {
            val rung = TIERS.firstOrNull { it.aheadBytes > aheadBytes }?.aheadBytes ?: steady.aheadBytes
            copy(aheadBytes = minOf(rung, steady.aheadBytes))
        }
        backBytes < steady.backBytes -> copy(backBytes = steady.backBytes)
        else -> null
    }

    /**
     * Whether widening to [next] is safe by `ActivityManager.MemoryInfo`: never while Android reports [lowMemory], and
     * only while the memory free above the low-memory killer's [thresholdBytes] covers the step four times over, so a
     * device near the threshold doesn't grow back into the kill it was trimmed to avoid. A threshold of 0 or less (a
     * vendor reporting none) counts as [UNKNOWN_THRESHOLD_BYTES].
     */
    fun canWiden(next: DemuxerBudget, availMemBytes: Long, thresholdBytes: Long, lowMemory: Boolean): Boolean {
        if (lowMemory) return false
        val threshold = if (thresholdBytes > 0) thresholdBytes else UNKNOWN_THRESHOLD_BYTES
        return availMemBytes - threshold >= RESTORE_HEADROOM_FACTOR * (next.totalBytes - totalBytes)
    }

    companion object {
        private const val MIB = 1024L * 1024L
        private const val TIGHT_TIER_MAX_MB = 256
        private const val MID_TIER_MAX_MB = 512

        /** The tiers in ascending order; [widenedToward] climbs them. */
        private val TIERS = listOf(
            DemuxerBudget(aheadBytes = 32 * MIB, backBytes = 16 * MIB),
            DemuxerBudget(aheadBytes = 64 * MIB, backBytes = 32 * MIB),
            DemuxerBudget(aheadBytes = 100 * MIB, backBytes = 48 * MIB),
        )

        /** How often the engine samples the memory while a budget is narrowed. */
        const val RESTORE_POLL_MS = 30_000L

        /** No widening within this long of the latest narrowing, which a trim during the way back restarts. */
        const val RESTORE_QUIET_MS = 60_000L

        private const val RESTORE_HEADROOM_FACTOR = 4L
        private const val UNKNOWN_THRESHOLD_BYTES = 256L * MIB

        /** The read-ahead a critical device is held to, and the floor of every tier. */
        private const val CRITICAL_AHEAD_BYTES = 32L * MIB

        /**
         * Seconds of the stream the read-ahead still covers at a critical level: the same 32 MiB is 13 s of a 20 Mbps
         * episode and 3.4 s of an 80 Mbps remux, too little to ride out a server's read stall.
         */
        private const val CRITICAL_AHEAD_SECONDS = 6

        /** The shortest cached span a rate is measured from ([streamByteRate]): less is a cache filling or starving. */
        private const val MIN_MEASURABLE_CACHE_SECONDS = 1.0

        /** The budget for a heap class in MB; null for an unknown class (0 or less), which keeps mpv's defaults. */
        fun forHeapClassMB(largeMemoryClassMB: Int): DemuxerBudget? = when {
            largeMemoryClassMB <= 0 -> null
            largeMemoryClassMB <= TIGHT_TIER_MAX_MB -> TIERS[0]
            largeMemoryClassMB <= MID_TIER_MAX_MB -> TIERS[1]
            else -> TIERS[2]
        }

        /**
         * mpv's `stream-buffer-size` ceiling for a heap class ([com.edde746.plezy.playback.mpv.MpvLoad.fileProperties]):
         * the stream ring is allocated whole, beside the demuxer cache.
         */
        fun streamRingCapBytes(largeMemoryClassMB: Int): Long = when {
            largeMemoryClassMB <= 0 -> 64 * MIB
            largeMemoryClassMB <= TIGHT_TIER_MAX_MB -> 32 * MIB
            largeMemoryClassMB <= MID_TIER_MAX_MB -> 64 * MIB
            else -> 128 * MIB
        }

        /**
         * The budget to hold under memory pressure at [level] (a `ComponentCallbacks2.TRIM_MEMORY_*` value), or null
         * when the level asks for nothing. The back cache goes first: the reader never reads from it, so dropping it
         * costs a download on a backward seek, never a rebuffer. Read-ahead is bounded only at a critical level, and
         * then only to [criticalAheadBytes] of [streamByteRate]. `UI_HIDDEN` and `RUNNING_MODERATE` say nothing about
         * the device's memory. The levels aren't ordered by severity, so they are matched by name.
         */
        fun forTrimLevel(largeMemoryClassMB: Int, level: Int, streamByteRate: Long = 0L): DemuxerBudget? {
            val steady = forHeapClassMB(largeMemoryClassMB) ?: return null
            @Suppress("DEPRECATION")
            return when (level) {
                ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL,
                ComponentCallbacks2.TRIM_MEMORY_COMPLETE,
                -> DemuxerBudget(aheadBytes = criticalAheadBytes(steady.aheadBytes, streamByteRate), backBytes = 0)
                ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW,
                ComponentCallbacks2.TRIM_MEMORY_BACKGROUND,
                ComponentCallbacks2.TRIM_MEMORY_MODERATE,
                -> steady.copy(backBytes = 0)
                else -> null
            }
        }

        /** [CRITICAL_AHEAD_BYTES] or [CRITICAL_AHEAD_SECONDS] of [streamByteRate], the larger, at most [steadyAheadBytes]. */
        fun criticalAheadBytes(steadyAheadBytes: Long, streamByteRate: Long): Long =
            minOf(maxOf(CRITICAL_AHEAD_BYTES, streamByteRate * CRITICAL_AHEAD_SECONDS), steadyAheadBytes)

        /**
         * The playing stream's bytes per second, 0 when nothing measures it: the larger of the cached span's rate
         * ([cachedBytes] over [cachedSeconds], mpv's `fw-bytes` and `demuxer-cache-duration`), which sees the region
         * playing, and the file's average ([fileBytes] over [fileSeconds], `file-size` and `duration`), which a remux's
         * peaks run well above.
         */
        fun streamByteRate(cachedBytes: Long, cachedSeconds: Double, fileBytes: Long, fileSeconds: Double): Long {
            val cached = if (cachedBytes > 0 && cachedSeconds >= MIN_MEASURABLE_CACHE_SECONDS) (cachedBytes / cachedSeconds).toLong() else 0L
            val average = if (fileBytes > 0 && fileSeconds > 0.0) (fileBytes / fileSeconds).toLong() else 0L
            return maxOf(cached, average)
        }
    }
}

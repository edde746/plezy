package com.edde746.plezy.net

import kotlin.random.Random

/**
 * Waits before a retry, randomized so that the clients that failed together (a server restart, one rate limit window)
 * don't all come back at the same moment: equal jitter, as in AWS's "Exponential Backoff and Jitter" (2015).
 */
internal object Backoff {
    /**
     * The wait before retry [attempt] (1 for the first after a failure): uniformly random from half the bound to the
     * bound, min([maxMillis], [minMillis] · 2^(attempt − 1)). The wait never drops below half of the bound, so a retry
     * that fails at once still slows down as the bound grows.
     */
    fun equalJitter(attempt: Int, minMillis: Long, maxMillis: Long, random: Random = Random): Long {
        val bound = (minMillis shl (attempt - 1).coerceIn(0, MAX_EXPONENT)).coerceAtMost(maxMillis)
        return bound / 2 + random.nextLong(bound - bound / 2 + 1)
    }

    /** 2^20 times the first wait is past any cap the callers use, and far from overflowing. */
    private const val MAX_EXPONENT = 20
}

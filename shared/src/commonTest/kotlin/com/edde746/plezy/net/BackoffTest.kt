package com.edde746.plezy.net

import kotlin.random.Random
import kotlin.test.Test
import kotlin.test.assertTrue

/** Retry waits stay within their bounds and spread across them. */
class BackoffTest {
    private val random = Random(42)

    private fun samples(wait: () -> Long) = List(500) { wait() }

    @Test
    fun equalJitterStaysBetweenHalfABoundThatDoublesUpToTheCapAndTheBound() {
        for (attempt in 1..30) {
            val bound = minOf(300_000L, 10_000L shl minOf(attempt - 1, 20))
            val waits = samples { Backoff.equalJitter(attempt, 10_000, 300_000, random) }
            assertTrue(waits.all { it in bound / 2..bound }, "attempt $attempt: ${waits.min()}..${waits.max()} outside ${bound / 2}..$bound")
            assertTrue(waits.max() > bound * 19 / 20 && waits.min() < bound * 11 / 20, "attempt $attempt spreads over its range")
        }
    }
}

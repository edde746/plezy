package com.edde746.plezy.jellyfin

import kotlin.time.Instant

/** Wire time units: durations and offsets in 100 ns ticks, timestamps as ISO-8601 strings. */
object JellyfinTime {
    const val TICKS_PER_MS: Long = 10_000

    fun ticksToMs(ticks: Long?): Long? = ticks?.div(TICKS_PER_MS)

    fun msToTicks(ms: Long): Long = ms * TICKS_PER_MS

    /** ISO-8601 → epoch seconds; null when empty or unparseable. */
    fun isoToEpochSeconds(iso: String?): Long? {
        if (iso.isNullOrEmpty()) return null
        val parsed = runCatching { Instant.parse(iso) }.getOrNull()
            ?: runCatching { Instant.parse(iso + "Z") }.getOrNull()
            ?: runCatching { Instant.parse(iso + "T00:00:00Z") }.getOrNull()
        return parsed?.epochSeconds
    }

    /** `2001-02-03T04:05:06Z` → `2001-02-03`. */
    fun isoToYmd(iso: String?): String? {
        if (iso.isNullOrEmpty()) return null
        val i = iso.indexOf('T')
        return if (i > 0) iso.substring(0, i) else iso
    }
}

package com.edde746.plezy.presentation.player

import kotlin.math.abs

/**
 * A value the store asked the engine for, shown until the engine reports back. Quick repeated presses (volume, delay,
 * speed, track cycling) then build on the last request rather than on a report that hasn't caught up.
 *
 * The request is dropped once the engine reports it, or reports any other change of the value: the engine has then
 * applied something, and its report is the truth again.
 */
internal class Pending<V : Any>(private val same: (V, V) -> Boolean = { a, b -> a == b }) {
    private var requested: V? = null

    fun request(value: V) {
        requested = value
    }

    /** The requested value while one is on its way, else [reported]. */
    fun resolve(reported: V): V = requested ?: reported

    fun onReport(previous: V, current: V) {
        val value = requested ?: return
        if (same(value, current) || !same(previous, current)) requested = null
    }

    fun clear() {
        requested = null
    }

    companion object {
        fun ofDouble() = Pending<Double> { a, b -> abs(a - b) < 1e-6 }
    }
}

/** A track choice; [id] null is "off". Wrapped so that "off" can be pending too. */
internal data class TrackChoice(val id: Long?)

/** Remembers the last result of [compute] and reuses it while the key is unchanged. */
internal class Memo<K, V>(private val compute: (K) -> V) {
    private var hasValue = false
    private var key: K? = null
    private var value: V? = null

    operator fun invoke(key: K): V {
        if (!hasValue || this.key != key) {
            value = compute(key)
            this.key = key
            hasValue = true
        }
        @Suppress("UNCHECKED_CAST")
        return value as V
    }
}

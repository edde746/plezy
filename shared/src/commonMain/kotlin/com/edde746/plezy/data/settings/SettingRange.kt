package com.edde746.plezy.data.settings

/**
 * The inclusive range a whole-number setting is kept in: a value outside it is clamped when it is stored and when it
 * is read back. Settings screens offer values inside it.
 */
data class SettingRange(val min: Int, val max: Int) {
    init {
        require(min <= max) { "Empty range $min..$max" }
    }

    fun clamp(value: Int): Int = value.coerceIn(min, max)

    operator fun contains(value: Int): Boolean = value in min..max
}

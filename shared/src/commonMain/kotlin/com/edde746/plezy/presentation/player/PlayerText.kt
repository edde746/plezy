package com.edde746.plezy.presentation.player

import com.edde746.plezy.format.formatTimecode
import com.edde746.plezy.strings.T
import kotlin.math.abs

/** The player's number and time formatting, in the language `T` is set to. */
internal object PlayerText {
    /** [value] with [minFractionDigits] to [maxFractionDigits] decimals, in the current language's notation. */
    fun decimal(value: Double, minFractionDigits: Int = 0, maxFractionDigits: Int = 2): String =
        localizedDecimal(value, minFractionDigits, maxFractionDigits, T.locale)

    /** "Normal" at 1×, otherwise "1.5×". */
    fun speed(speed: Double): String =
        if (abs(speed - 1.0) < SPEED_EPSILON) T.player.speed.normal else T.player.speed.value(decimal(speed))

    /** "+0.3 s", "−1.25 s", "0.0 s". */
    fun delay(seconds: Double): String =
        signed(seconds, threshold = 0.0005, T.player.format.seconds(decimal(abs(seconds), 1, 2)))

    /** "+1:20", "−0:30", "0:00": a scrub preview's distance from where it started. Timecodes count whole seconds. */
    fun offset(seconds: Double): String = signed(seconds, threshold = 1.0, formatTimecode(abs(seconds)))

    /** "−49:29": the time left. */
    fun remaining(seconds: Double): String = T.player.remaining(formatTimecode(seconds))

    /** "80%". */
    fun volume(percent: Int): String = T.player.volume.level(decimal(percent.toDouble(), 0, 0))

    private fun signed(value: Double, threshold: Double, magnitude: String): String = when {
        value >= threshold -> T.player.format.positive(magnitude)
        value <= -threshold -> T.player.format.negative(magnitude)
        else -> magnitude
    }

    const val SPEED_EPSILON = 1e-6

    /** The least change of speed the speed toast tells: smaller ones are a rounding, not a new speed. */
    const val SPEED_TOAST_EPSILON = 0.005
}

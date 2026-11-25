package com.edde746.plezy.image

import com.edde746.plezy.log.Log
import com.edde746.plezy.settings.VisualEffects
import kotlin.concurrent.Volatile
import kotlin.math.abs
import kotlin.math.floor
import kotlin.math.pow
import kotlin.math.roundToInt

/**
 * The effects tier for the startup log, with the hardware signals that decided it where the device reports them (an
 * Android device's: [ArtworkDevice.totalMemoryBytes] known), even when [visualEffects] forces the tier, so a log
 * answers whether the reduced tier engaged and why: `reduced (auto: 32-bit, lowRam:true, 1.9GiB)`,
 * `full (forced; hw: 64-bit, lowRam:false, 2.8GiB)`, `full`.
 */
fun describeEffects(visualEffects: VisualEffects, device: ArtworkDevice, display: ArtworkDisplay): String {
    val tier = if (display.reduced) "reduced" else "full"
    val signals = device.totalMemoryBytes?.let { memory ->
        listOf(
            if (device.is64Bit) "64-bit" else "32-bit",
            "lowRam:${device.lowRamDevice}",
            fixed(memory / GIB, 1) + "GiB",
        ).joinToString(", ")
    }
    return when {
        visualEffects != VisualEffects.AUTO -> if (signals == null) "$tier (forced)" else "$tier (forced; hw: $signals)"
        signals == null -> tier
        else -> "$tier (auto: $signals)"
    }
}

/**
 * The display for the startup log: the app's surface, [physicalWidth]×[physicalHeight] pixels at [pixelRatio] pixels
 * per logical pixel as the platform reports it, the [device]'s display where its size differs, and the artwork budget,
 * which tells a TV that composites at 1080p from a true 4K surface:
 * `3840x2160 physical, 960x540 logical @ 4.00x (budget 2.0x)`.
 */
fun describeDisplay(physicalWidth: Int, physicalHeight: Int, pixelRatio: Double, device: ArtworkDevice, display: ArtworkDisplay): String {
    val logicalWidth = if (pixelRatio > 0) (physicalWidth / pixelRatio).roundToInt() else 0
    val logicalHeight = if (pixelRatio > 0) (physicalHeight / pixelRatio).roundToInt() else 0
    return buildString {
        append("${physicalWidth}x$physicalHeight physical, ${logicalWidth}x$logicalHeight logical @ ${fixed(pixelRatio, 2)}x")
        val displayWidth = device.displayWidth
        val displayHeight = device.displayHeight
        if (displayWidth != null && displayHeight != null &&
            (abs(displayWidth - physicalWidth) > 1 || abs(displayHeight - physicalHeight) > 1)
        ) {
            append(", display ${displayWidth}x$displayHeight")
        }
        append(" (budget ${fixed(display.budget, 1)}x)")
    }
}

/**
 * The effects tier and the display as the app last logged them ([describeEffects], [describeDisplay]): into the app's
 * log at startup and whenever either changes ([log]), and as the logs' header shows them ("Effects: …", "Display: …").
 */
object ArtworkDiagnosticsLog {
    @Volatile
    var effects: String? = null
        private set

    @Volatile
    var display: String? = null
        private set

    /** The header's lines: none before the first [log]. */
    val headerLines: List<String>
        get() = listOfNotNull(effects?.let { "Effects: $it" }, display?.let { "Display: $it" })

    fun log(effects: String, display: String) {
        this.effects = effects
        this.display = display
        Log.i("app") { "Effects: $effects" }
        Log.i("app") { "Display: $display" }
    }
}

private const val GIB = 1024.0 * 1024 * 1024

/** [value] with [digits] decimals and a point, whatever the language, rounded half away from zero: a log's figures. */
private fun fixed(value: Double, digits: Int): String {
    val scale = 10.0.pow(digits)
    val scaled = floor(abs(value) * scale + 0.5).toLong()
    val unit = scale.toLong()
    val sign = if (value < 0 && scaled != 0L) "-" else ""
    if (digits == 0) return "$sign${scaled / unit}"
    return "$sign${scaled / unit}.${(scaled % unit).toString().padStart(digits, '0')}"
}

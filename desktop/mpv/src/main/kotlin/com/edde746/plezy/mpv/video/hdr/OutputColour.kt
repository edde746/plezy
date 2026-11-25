package com.edde746.plezy.mpv.video.hdr

/**
 * mpv's output colour space, applied as one transaction over the four properties that together say what mpv emits:
 * target-trc, target-prim, tone-mapping and target-peak.
 *
 * A half-applied set (BT.2020 primaries on a gamma curve) is neither SDR nor HDR, and the caller describes the surface
 * to the compositor from the result, so a refused write unwinds the ones that landed, newest first; an unwind that is
 * itself refused forces SDR (all four to "auto", always valid and always describable); and a refused "auto" means mpv
 * no longer takes orders, so the state becomes unknown until a clean apply.
 *
 * [write] sets one mpv property and returns mpv's status, negative when refused. [canCommand] is false once the core
 * is gone.
 */
internal class OutputColour(
    private val write: (name: String, value: String) -> Int,
    private val canCommand: () -> Boolean,
) {
    /** What mpv emits after a request, which decides whether the caller's committed surface description still holds. */
    enum class Result {
        /** The requested values are in force. */
        APPLIED,

        /** A write was refused and mpv is back where it was, so the previous description still holds. */
        RESTORED,

        /** mpv could not be put back and is SDR now; any HDR description is a lie about these pixels. */
        FORCED_SDR,

        /** What mpv emits cannot be named; the plane must not be shown undescribed or described. */
        UNKNOWN,
    }

    private val values = MutableList(PROPERTIES.size) { "auto" }

    /**
     * The cache trusts [values] as what mpv holds. False after a forced-SDR reset was refused partway: [values] then
     * records what was asked for, still the best rollback targets, but no ground for skipping a write.
     */
    private var known = true

    /** What mpv holds as far as this transaction knows: target-trc, target-prim, tone-mapping, target-peak. */
    val applied: List<String> get() = values.toList()

    /**
     * Puts mpv's output on [transfer] with mpv mapping to [targetPeakNits] (0, or anything outside mpv's 10..10000,
     * leaves the peak on auto).
     *
     * An HDR transfer names its curve over BT.2020. An SDR one with a named peak names sRGB, what an undescribed
     * surface is, and mobius, the operator measured best for that fallback; elsewhere the operator stays mpv's own
     * choice. Written in dependency order with the peak last, because the peak decides whether a tone-map pass runs.
     * A request for the values already in force writes nothing: playback restarts on every seek ask for it again.
     */
    fun apply(transfer: SourceTransfer, targetPeakNits: Long): Result {
        if (!canCommand()) return if (known) Result.RESTORED else Result.UNKNOWN
        val hdr = transfer != SourceTransfer.SDR
        val peakNamed = targetPeakNits in 10..PQ_MAX_LUMINANCE_NITS
        val curve = when (transfer) {
            SourceTransfer.HLG -> "hlg"
            SourceTransfer.PQ -> "pq"
            SourceTransfer.SDR -> if (peakNamed) "srgb" else "auto"
        }
        val requested = listOf(
            curve,
            if (hdr) "bt.2020" else "auto",
            if (peakNamed && !hdr) "mobius" else "auto",
            if (peakNamed) targetPeakNits.toString() else "auto",
        )
        if (known && requested == values) return Result.APPLIED
        for (index in PROPERTIES.indices) {
            if (write(PROPERTIES[index], requested[index]) < 0) return unwind(index)
        }
        requested.forEachIndexed { index, value -> values[index] = value }
        known = true
        return Result.APPLIED
    }

    /** Restores the [landed] writes newest first. Restored only means something while where it was is known. */
    private fun unwind(landed: Int): Result {
        for (index in landed - 1 downTo 0) {
            if (write(PROPERTIES[index], values[index]) < 0) return forceSdr()
        }
        return if (known) Result.RESTORED else Result.UNKNOWN
    }

    /** Each reset is recorded as it lands, so a later refusal leaves the cache naming what actually moved. */
    private fun forceSdr(): Result {
        for (index in PROPERTIES.indices) {
            if (write(PROPERTIES[index], "auto") < 0) {
                known = false
                return Result.UNKNOWN
            }
            values[index] = "auto"
        }
        known = true
        return Result.FORCED_SDR
    }

    private companion object {
        val PROPERTIES = listOf("target-trc", "target-prim", "tone-mapping", "target-peak")
    }
}

package com.edde746.plezy.playback.output

import com.edde746.plezy.data.settings.DolbyVisionConversion
import com.edde746.plezy.playback.DynamicRange
import com.edde746.plezy.playback.VideoInfo
import kotlin.math.abs

/**
 * What an Apple TV asks its TV for while a video plays (`AVDisplayManager.preferredDisplayCriteria`, written by the
 * tvOS surface): a dynamic range and a refresh rate for the stream as mpv decodes it. tvOS picks the TV's mode from
 * them, and only with Match Content on.
 *
 * @param range the dynamic range asked for.
 * @param baseRange the range of the video without its Dolby Vision layer: asked for instead when the system can't
 *   describe the Dolby Vision configuration ([range] Dolby Vision and its format description fails).
 * @param refreshRate the nominal rate ([nominalRefreshRate]) of the video's presented frame rate; 0 when unknown.
 * @param doviProfile the Dolby Vision profile the decoder outputs, 0 for none; [doviLevel] its level.
 * @param doviCompatibility the Dolby Vision base layer's signal compatibility id where known (1 = HDR10).
 */
data class AppleDisplayCriteria(
    val range: DynamicRange,
    val baseRange: DynamicRange,
    val refreshRate: Double,
    val width: Int,
    val height: Int,
    val doviProfile: Int,
    val doviLevel: Int,
    val doviCompatibility: Int?,
) {
    companion object {
        /** The rates a TV offers modes for, in Hz. */
        val NOMINAL_REFRESH_RATES = listOf(23.976, 24.0, 25.0, 29.97, 30.0, 48.0, 50.0, 59.94, 60.0, 100.0, 119.88, 120.0)

        /** The largest picture side and area the criteria describe; anything larger is no video's. */
        const val MAX_DIMENSION = 16_384
        const val MAX_PIXELS = 64L * 1024 * 1024

        /**
         * The rate asked of the TV for a video presented at [fps]: the nearest nominal rate when within 1 % of it
         * (FFmpeg's band for rounding a guessed rate to a standard one), else [fps] itself; 0 for none. A container's
         * rate is declared or averaged, never measured (a 29.97i capture reads 29.95784, a Matroska file with a 42 ms
         * default duration 23.8095), and the TV has modes for the nominal rates only; tvOS leaves the pick to the
         * system, so the request itself has to be nominal.
         */
        fun nominalRefreshRate(fps: Double): Double {
            if (!(fps > 0)) return 0.0
            val nearest = NOMINAL_REFRESH_RATES.minBy { abs(it - fps) }
            return if (abs(nearest - fps) / nearest < 0.01) nearest else fps
        }

        /**
         * The dynamic range of a stream without Dolby Vision, from mpv's `video-params` ([sigPeak], [gamma],
         * [primaries], [matrix]; tags compared lower-case, letters and digits only) and a Dolby Vision base layer's
         * [doviCompatibility]: an HLG transfer is HLG; a PQ transfer, a peak above SDR white or BT.2020 primaries or
         * matrix is HDR10; else compatibility 1 and 6 are HDR10, 4 HLG; anything else SDR.
         */
        fun baseRange(sigPeak: Double, gamma: String?, primaries: String?, matrix: String?, doviCompatibility: Int?): DynamicRange {
            val transfer = tag(gamma)
            if ("hlg" in transfer || "arib" in transfer) return DynamicRange.HLG
            if ("pq" in transfer || "smpte2084" in transfer || "st2084" in transfer || sigPeak > 1.0 ||
                "bt2020" in tag(primaries) || "bt2020" in tag(matrix)
            ) {
                return DynamicRange.HDR10
            }
            return when (doviCompatibility) {
                1, 6 -> DynamicRange.HDR10
                4 -> DynamicRange.HLG
                else -> DynamicRange.SDR
            }
        }

        /**
         * The criteria for [video] (its Dolby Vision [doviLevel] from the track), or null to ask for nothing (the TV's
         * own mode): its size isn't a picture's, or it carries neither a rate nor any colour information.
         *
         * - [hdr] off (the Hdr setting, or a TV without HDR) asks for SDR whatever the video, Dolby Vision included.
         * - Dolby Vision asks for Dolby Vision. Profile 7 is asked for as what the decoder makes of it: profile 8.1
         *   under [dvConversion] auto or dv81, else its HDR10 base layer (PQ, BT.2020 where the stream says nothing).
         * - [dolbyVisionOutput] off ("Disable Dolby Vision") asks for the base layer's range instead; profile 5 has no
         *   viewable base layer but is PQ BT.2020 once reshaped, so it asks for HDR10.
         * - Any other range is asked for only where the TV has it ([availableRanges], `AVPlayer.availableHDRModes`),
         *   else SDR.
         */
        fun of(
            video: VideoInfo,
            doviLevel: Int?,
            hdr: Boolean,
            dvConversion: DolbyVisionConversion,
            dolbyVisionOutput: Boolean,
            availableRanges: Set<DynamicRange>,
        ): AppleDisplayCriteria? {
            var profile = video.doviProfile ?: 0
            var level = if (profile > 0) doviLevel ?: 0 else 0
            var compatibility: Int? = null
            var gamma = video.gamma
            var primaries = video.primaries
            var matrix = video.colorMatrix
            if (profile == 7) {
                if (dvConversion == DolbyVisionConversion.AUTO || dvConversion == DolbyVisionConversion.DV81) {
                    profile = 8
                } else {
                    profile = 0
                    level = 0
                }
                compatibility = 1
                gamma = gamma ?: "smpte2084"
                primaries = primaries ?: "bt2020"
                matrix = matrix ?: "bt2020nc"
            }
            if (profile > 0 && !dolbyVisionOutput) {
                if (profile == 5) {
                    gamma = "smpte2084"
                    primaries = "bt2020"
                }
                profile = 0
                level = 0
            }
            val width = video.width
            val height = video.height
            if (width <= 0 || height <= 0 || width > MAX_DIMENSION || height > MAX_DIMENSION ||
                width.toLong() * height > MAX_PIXELS
            ) {
                return null
            }
            val refreshRate = nominalRefreshRate(video.fps ?: 0.0)
            val sigPeak = video.sigPeak ?: 0.0
            if (refreshRate <= 0 && profile == 0 && sigPeak <= 0 && gamma == null && primaries == null && matrix == null) return null
            val base = baseRange(sigPeak, gamma, primaries, matrix, compatibility)
            val range = when {
                !hdr -> DynamicRange.SDR
                profile > 0 -> DynamicRange.DOLBY_VISION
                base in availableRanges -> base
                else -> DynamicRange.SDR
            }
            return AppleDisplayCriteria(range, base, refreshRate, width, height, profile, level, compatibility)
        }

        /**
         * The environment mpv-build's FFmpeg reads as it opens a Dolby Vision decoder on Apple platforms: what it makes
         * of profile 7 (`PLEZY_DV_CONVERSION_MODE`, the setting's [DolbyVisionConversion.wire]) and whether it logs
         * the conversion (`PLEZY_DV_CONVERSION_LOG`, 1 with debug logging on, else 0).
         */
        fun conversionEnvironment(conversion: DolbyVisionConversion, log: Boolean): Map<String, String> = mapOf(
            "PLEZY_DV_CONVERSION_MODE" to conversion.wire,
            "PLEZY_DV_CONVERSION_LOG" to if (log) "1" else "0",
        )

        private fun tag(value: String?): String = value?.lowercase()?.filter { it.isLetterOrDigit() }.orEmpty()
    }
}

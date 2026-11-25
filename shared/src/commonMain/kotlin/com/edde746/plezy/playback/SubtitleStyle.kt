package com.edde746.plezy.playback

import com.edde746.plezy.data.settings.SubtitleAppearance
import com.edde746.plezy.settings.AppSettings

/**
 * How the player draws subtitles, as mpv's `sub-*` values, decided here for every platform from this device's
 * subtitle styling settings ([of]). The playback session hands it to the engine as it starts and again whenever a
 * setting changes ([PlayerEngine.setSubtitleStyle]), so a change shows at once, on the file playing too.
 *
 * Sizes are mpv's scaled pixels (a 720-line picture's pixels, scaled with the picture).
 *
 * @param fontSize `sub-font-size`; it applies to plain-text subtitles (styled ones keep theirs unless [assOverride]
 *   forces it).
 * @param color `sub-color`, `#RRGGBB` or `#AARRGGBB`.
 * @param outlineSize `sub-outline-size`; 0 draws none.
 * @param outlineColor `sub-outline-color`.
 * @param backColor `sub-back-color`, `#AARRGGBB`: the box's colour at the background opacity.
 * @param box a box goes behind the text (`sub-border-style=background-box`): the background opacity isn't 0.
 * @param bold / [italic] `sub-bold`, `sub-italic`.
 * @param assOverride `sub-ass-override` (`no`, `yes`, `scale`, `force`, `strip`).
 * @param subPos `sub-pos` without the player's controls: 100 is the bottom subtitles' own place, 0 the top, up to 150
 *   below it ([position] lifts them over the controls).
 * @param useMargins plain-text subtitles may sit in the bands around the picture (`sub-use-margins=yes`); an engine
 *   also lets them while the picture runs past the surface ([PlayerEngine.setVideoLayout]).
 */
data class SubtitleStyle(
    val fontSize: Int,
    val color: String,
    val outlineSize: Int,
    val outlineColor: String,
    val backColor: String,
    val box: Boolean,
    val bold: Boolean,
    val italic: Boolean,
    val assOverride: String,
    val subPos: Int,
    val useMargins: Boolean,
) {
    /**
     * The mpv properties of this style, as `name` to value; `sub-pos` is [position]'s and `sub-use-margins` the
     * engine's ([useMargins]). `sub-ass-video-aspect-override` gives styled subtitles the picture's aspect when the
     * player overrides it.
     */
    fun properties(): Map<String, String> = linkedMapOf(
        "sub-font-size" to fontSize.toString(),
        "sub-color" to color,
        "sub-outline-size" to outlineSize.toString(),
        "sub-outline-color" to outlineColor,
        "sub-bold" to yesNo(bold),
        "sub-italic" to yesNo(italic),
        "sub-back-color" to backColor,
        "sub-border-style" to if (box) BACKGROUND_BOX else OUTLINE,
        "sub-ass-override" to assOverride,
        "sub-ass-video-aspect-override" to "1",
    )

    /**
     * mpv's `sub-pos`: [subPos] or, while the player's controls cover [controlsLift] of the surface's height from the
     * bottom (`PlayerEngine.setSubtitleLift`), at least above the part of them over [frame], the frame mpv places the
     * subtitles in ([SubtitleFrame.lift]). Every point under 100 lifts them by 1 % of the frame's height.
     */
    fun position(controlsLift: Double, frame: SubtitleFrame): Double {
        val own = subPos.toDouble()
        val clear = frame.lift(controlsLift)
        if (clear <= 0.0) return own
        return minOf(own, 100.0 * (1.0 - clear.coerceAtMost(1.0)))
    }

    companion object {
        const val OUTLINE = "outline-and-shadow"
        const val BACKGROUND_BOX = "background-box"

        /** [appearance] as mpv values; a stored colour that isn't hex reads as its setting's default. */
        fun of(appearance: SubtitleAppearance): SubtitleStyle {
            val opacity = appearance.backgroundOpacity.coerceIn(0, 100)
            val alpha = (opacity * 255 / 100).toString(16).uppercase().padStart(2, '0')
            val background = color(appearance.backgroundColor, AppSettings.subtitleBackgroundColor.default)
            return SubtitleStyle(
                fontSize = appearance.fontSize,
                color = color(appearance.textColor, AppSettings.subtitleTextColor.default),
                outlineSize = appearance.borderSize,
                outlineColor = color(appearance.borderColor, AppSettings.subtitleBorderColor.default),
                backColor = "#$alpha${background.takeLast(6)}",
                box = opacity > 0,
                bold = appearance.bold,
                italic = appearance.italic,
                assOverride = appearance.assOverride.name.lowercase(),
                subPos = appearance.position.coerceIn(0, 150),
                useMargins = appearance.useMargins,
            )
        }

        /** The subtitle styling settings' defaults. */
        val DEFAULT: SubtitleStyle get() = of(SubtitleAppearance.DEFAULT)

        /**
         * [value] as mpv's colour: `#RRGGBB` or `#AARRGGBB`, the `#` optional, in upper case; [fallback] for anything
         * else, which mpv would refuse.
         */
        fun color(value: String, fallback: String): String {
            val hex = value.removePrefix("#").uppercase()
            return if (HEX_COLOR.matches(hex)) "#$hex" else fallback.uppercase()
        }

        private val HEX_COLOR = Regex("^[0-9A-F]{6}([0-9A-F]{2})?$")

        private fun yesNo(value: Boolean) = if (value) "yes" else "no"
    }
}

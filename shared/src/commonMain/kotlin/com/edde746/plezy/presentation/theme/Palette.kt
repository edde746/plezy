package com.edde746.plezy.presentation.theme

import com.edde746.plezy.settings.CustomThemePalette
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow

/**
 * The six colours a theme is built from, each as `0xAARRGGBB`. [accent] carries interactive and selected state (primary,
 * filled buttons, switches, progress, selection, the focus ring); body text stays [text]. The built-in themes set
 * [accent] to [text], which keeps them monochrome. Whether the theme is dark follows [bg] ([isDark]), and the colour
 * drawn on [accent] is derived ([onAccent]), so a palette states nothing else.
 */
data class Palette(
    val bg: Long,
    val surface: Long,
    val outline: Long,
    val text: Long,
    val textMuted: Long,
    val accent: Long,
) {
    /** The background is dark: the theme paints light text on dark surfaces. */
    val isDark: Boolean
        get() {
            val luminance = luminance(bg)
            return (luminance + 0.05) * (luminance + 0.05) <= BRIGHTNESS_THRESHOLD
        }

    /**
     * [bg] or white, whichever contrasts more with [accent]: never worse than [accent] against [bg], so an accent that
     * reads on the page keeps a readable label.
     */
    val onAccent: Long
        get() {
            val accentLuminance = luminance(accent)
            return if (ratio(accentLuminance, luminance(bg)) >= ratio(accentLuminance, luminance(WHITE))) bg else WHITE
        }

    companion object {
        // Secondary text (textMuted) reads at least 4.5:1 on the background, the surface and the raised fills drawn over
        // them in every built-in theme: the monochrome three at 70 % of the text.
        val LIGHT = Palette(0xFFF7F7F8, 0xFFFFFFFF, 0x19000000, 0xFF111111, 0xB3111111, 0xFF111111)
        val DARK = Palette(0xFF0E0F12, 0xFF15171C, 0x1FFFFFFF, 0xFFEDEDED, 0xB3EDEDED, 0xFFEDEDED)
        val OLED = Palette(0xFF000000, 0xFF0F0F0F, 0x1FFFFFFF, 0xFFEDEDED, 0xB3EDEDED, 0xFFEDEDED)

        /** Warm charcoal with the brand orange. */
        val EMBER = Palette(0xFF14110F, 0xFF1D1916, 0x1FF2EBE6, 0xFFF2EBE6, 0xA3F2EBE6, 0xFFFF7E57)

        /** Cool blue-grey with an ice-blue accent. */
        val GLACIER = Palette(0xFF0E1319, 0xFF151C25, 0x1FE6EDF5, 0xFFE6EDF5, 0xA3E6EDF5, 0xFF7CC4FF)

        /** Green-black with a mint accent. */
        val FOREST = Palette(0xFF0E1411, 0xFF151D18, 0x1FE5EFE8, 0xFFE5EFE8, 0xA3E5EFE8, 0xFF6BD6A0)

        /** Aubergine with an orchid accent. */
        val PLUM = Palette(0xFF151118, 0xFF1E1823, 0x1FF0E9F4, 0xFFF0E9F4, 0xA3F0E9F4, 0xFFE29BF0)

        /** Warm off-white paper with a deep teal accent: the light preset. */
        val PAPER = Palette(0xFFF3F0E9, 0xFFFBF9F4, 0x1F1F1C17, 0xFF1F1C17, 0xAD1F1C17, 0xFF1F6B6B)

        /**
         * The stored custom palette as colours, or null unless every slot holds `#RRGGBB` (opaque) or `#AARRGGBB`: a
         * partial or corrupt value never yields a palette mixing stored and made-up colours.
         */
        fun of(custom: CustomThemePalette): Palette? {
            return Palette(
                bg = parseHex(custom.bg) ?: return null,
                surface = parseHex(custom.surface) ?: return null,
                outline = parseHex(custom.outline) ?: return null,
                text = parseHex(custom.text) ?: return null,
                textMuted = parseHex(custom.textMuted) ?: return null,
                accent = parseHex(custom.accent) ?: return null,
            )
        }

        /** `#RRGGBB` (opaque) or `#AARRGGBB`, the `#` optional, as `0xAARRGGBB`; null for anything else. */
        fun parseHex(input: String): Long? {
            val digits = input.trim().removePrefix("#")
            if (digits.length != 6 && digits.length != 8) return null
            if (!digits.all { it in '0'..'9' || it in 'a'..'f' || it in 'A'..'F' }) return null
            val value = digits.toLong(16)
            return if (digits.length == 6) 0xFF000000 or value else value
        }

        /** [color] as `#AARRGGBB`, upper case: how the custom palette stores it. */
        fun toHex(color: Long): String = "#" + (color and 0xFFFFFFFF).toString(16).padStart(8, '0').uppercase()

        /** The WCAG 2 contrast ratio of two colours, alpha ignored: composite a translucent colour over its background first. */
        fun contrastRatio(a: Long, b: Long): Double = ratio(luminance(a), luminance(b))

        private const val WHITE = 0xFFFFFFFF

        /** Below this, (L + 0.05)² is a dark colour (Material's brightness estimate). */
        private const val BRIGHTNESS_THRESHOLD = 0.15

        private fun ratio(a: Double, b: Double): Double = (max(a, b) + 0.05) / (min(a, b) + 0.05)

        private fun luminance(color: Long): Double {
            fun channel(shift: Int): Double {
                val c = ((color shr shift) and 0xFF) / 255.0
                return if (c <= 0.03928) c / 12.92 else ((c + 0.055) / 1.055).pow(2.4)
            }
            return 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0)
        }
    }
}

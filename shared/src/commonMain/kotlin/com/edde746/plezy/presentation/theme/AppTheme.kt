package com.edde746.plezy.presentation.theme

import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.ThemeMode

/**
 * The theme the app paints ([resolve]): the effective [mode] and its [palette], null for System, which follows the
 * platform between [Palette.LIGHT] and [Palette.DARK] ([paletteFor]). [lockedStored] is the stored choice while only a
 * missing Supporter entitlement keeps it off screen, so a theme picker can mark it as still saved.
 */
data class AppTheme(val mode: ThemeMode, val palette: Palette?, val lockedStored: ThemeMode?) {
    /** The palette on screen, System resolved against the platform's [systemDark]. */
    fun paletteFor(systemDark: Boolean): Palette = palette ?: if (systemDark) Palette.DARK else Palette.LIGHT

    /**
     * The light and dark slots a platform theme fills, for a platform that switches them itself: a dark palette fills
     * the dark slot with Light as the light one, a light palette the light slot with Dark as the dark one; System fills
     * both with Light and Dark.
     */
    val light: Palette get() = palette?.takeUnless { it.isDark } ?: Palette.LIGHT
    val dark: Palette get() = palette?.takeIf { it.isDark } ?: Palette.DARK

    companion object {
        /**
         * What [stored] (null: never chosen) paints. A Supporter perk ([ThemeMode.isSupporterPerk]) paints only while
         * [unlocked], Custom only with a saved [custom] palette; otherwise the device's default
         * ([AppSettings.defaultThemeMode]) paints, and the stored choice is never rewritten, so regaining the
         * entitlement brings it back.
         */
        fun resolve(stored: ThemeMode?, custom: Palette?, unlocked: Boolean, tv: Boolean): AppTheme {
            val fallback = AppSettings.defaultThemeMode(tv)
            val chosen = stored ?: fallback
            val missingCustom = chosen == ThemeMode.CUSTOM && custom == null
            val locked = chosen.isSupporterPerk && !unlocked
            val mode = if (locked || missingCustom) fallback else chosen
            val lockedStored = chosen.takeIf { locked && !missingCustom && it != mode }
            return AppTheme(mode, paletteOf(mode, custom), lockedStored)
        }

        private fun paletteOf(mode: ThemeMode, custom: Palette?): Palette? = when (mode) {
            ThemeMode.SYSTEM -> null
            ThemeMode.LIGHT -> Palette.LIGHT
            ThemeMode.DARK -> Palette.DARK
            ThemeMode.OLED -> Palette.OLED
            ThemeMode.EMBER -> Palette.EMBER
            ThemeMode.GLACIER -> Palette.GLACIER
            ThemeMode.FOREST -> Palette.FOREST
            ThemeMode.PLUM -> Palette.PLUM
            ThemeMode.PAPER -> Palette.PAPER
            ThemeMode.CUSTOM -> custom
        }
    }
}

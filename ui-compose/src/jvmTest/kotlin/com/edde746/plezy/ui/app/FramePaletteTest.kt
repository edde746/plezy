package com.edde746.plezy.ui.app

import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.presentation.theme.AppearanceSettings
import com.edde746.plezy.presentation.theme.Palette
import com.edde746.plezy.settings.ThemeMode
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * The palette the startup frames paint: the theme the app will start in once the stored settings are read
 * (`RootSession.startupAppearance`), not the platform's brightness; the device's default before.
 */
class FramePaletteTest {
    private fun stored(mode: ThemeMode, forceTv: Boolean = false, detected: FormFactor = FormFactor.HANDHELD, unlocked: Boolean = false) =
        Appearance.of(AppearanceSettings(themeMode = mode, forceTvMode = forceTv), detected, unlocked)

    @Test
    fun `the stored theme paints whatever the platform brightness`() {
        assertEquals(Palette.OLED, framePalette(stored(ThemeMode.OLED), FormFactor.HANDHELD, systemDark = false))
        assertEquals(Palette.LIGHT, framePalette(stored(ThemeMode.LIGHT), FormFactor.HANDHELD, systemDark = true))
        assertEquals(Palette.LIGHT, framePalette(stored(ThemeMode.LIGHT, detected = FormFactor.TV), FormFactor.TV, systemDark = true))
    }

    @Test
    fun `system follows the platform brightness`() {
        assertEquals(Palette.DARK, framePalette(stored(ThemeMode.SYSTEM), FormFactor.DESKTOP, systemDark = true))
        assertEquals(Palette.LIGHT, framePalette(stored(ThemeMode.SYSTEM), FormFactor.DESKTOP, systemDark = false))
    }

    @Test
    fun `a supporter preset paints only while the cached entitlement unlocks it`() {
        assertEquals(Palette.EMBER, framePalette(stored(ThemeMode.EMBER, unlocked = true), FormFactor.HANDHELD, systemDark = false))
        assertEquals(Palette.LIGHT, framePalette(stored(ThemeMode.EMBER), FormFactor.HANDHELD, systemDark = false))
        assertEquals(Palette.OLED, framePalette(stored(ThemeMode.EMBER, detected = FormFactor.TV), FormFactor.TV, systemDark = false))
    }

    @Test
    fun `before the settings are read a tv paints oled and others the platform brightness`() {
        assertEquals(Palette.OLED, framePalette(null, FormFactor.TV, systemDark = false))
        assertEquals(Palette.DARK, framePalette(null, FormFactor.HANDHELD, systemDark = true))
        assertEquals(Palette.LIGHT, framePalette(null, FormFactor.DESKTOP, systemDark = false))
    }
}

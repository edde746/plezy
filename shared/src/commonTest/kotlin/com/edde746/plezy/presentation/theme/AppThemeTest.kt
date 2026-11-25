package com.edde746.plezy.presentation.theme

import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.settings.CustomThemePalette
import com.edde746.plezy.settings.GridSpacing
import com.edde746.plezy.settings.ThemeMode
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class AppThemeTest {
    @Test
    fun aFreshInstallPaintsOledOnTvAndFollowsTheSystemElsewhere() {
        assertEquals(AppTheme(ThemeMode.OLED, Palette.OLED, null), AppTheme.resolve(null, null, unlocked = false, tv = true))
        val system = AppTheme.resolve(null, null, unlocked = false, tv = false)
        assertEquals(ThemeMode.SYSTEM, system.mode)
        assertEquals(Palette.DARK, system.paletteFor(systemDark = true))
        assertEquals(Palette.LIGHT, system.paletteFor(systemDark = false))
    }

    @Test
    fun aLockedPresetPaintsTheDefaultAndKeepsTheStoredChoiceMarked() {
        val locked = AppTheme.resolve(ThemeMode.EMBER, null, unlocked = false, tv = false)
        assertEquals(ThemeMode.SYSTEM, locked.mode)
        assertEquals(ThemeMode.EMBER, locked.lockedStored)

        val unlocked = AppTheme.resolve(ThemeMode.EMBER, null, unlocked = true, tv = false)
        assertEquals(AppTheme(ThemeMode.EMBER, Palette.EMBER, null), unlocked)
    }

    @Test
    fun customWithoutASavedPaletteFallsBackUnmarked() {
        val missing = AppTheme.resolve(ThemeMode.CUSTOM, null, unlocked = true, tv = true)
        assertEquals(AppTheme(ThemeMode.OLED, Palette.OLED, null), missing)
        assertNull(AppTheme.resolve(ThemeMode.CUSTOM, null, unlocked = false, tv = true).lockedStored)

        val custom = Palette.PLUM.copy(accent = 0xFF00FF00)
        assertEquals(AppTheme(ThemeMode.CUSTOM, custom, null), AppTheme.resolve(ThemeMode.CUSTOM, custom, unlocked = true, tv = false))
    }

    @Test
    fun freeThemesPaintWithoutTheEntitlement() {
        assertEquals(Palette.LIGHT, AppTheme.resolve(ThemeMode.LIGHT, null, unlocked = false, tv = true).palette)
        assertEquals(Palette.DARK, AppTheme.resolve(ThemeMode.DARK, null, unlocked = false, tv = false).palette)
    }

    @Test
    fun aPresetFillsItsOwnSlotAndTheStockThemeTheOther() {
        val ember = AppTheme.resolve(ThemeMode.EMBER, null, unlocked = true, tv = false)
        assertEquals(Palette.EMBER, ember.dark)
        assertEquals(Palette.LIGHT, ember.light)
        val paper = AppTheme.resolve(ThemeMode.PAPER, null, unlocked = true, tv = false)
        assertEquals(Palette.PAPER, paper.light)
        assertEquals(Palette.DARK, paper.dark)
    }
}

class PaletteTest {
    @Test
    fun brightnessFollowsTheBackground() {
        assertTrue(Palette.DARK.isDark)
        assertTrue(Palette.OLED.isDark)
        assertTrue(Palette.EMBER.isDark)
        assertFalse(Palette.LIGHT.isDark)
        assertFalse(Palette.PAPER.isDark)
    }

    @Test
    fun theLabelOnTheAccentIsTheBackgroundOrWhiteWhicheverReadsBetter() {
        assertEquals(Palette.DARK.bg, Palette.DARK.onAccent)
        assertEquals(Palette.EMBER.bg, Palette.EMBER.onAccent)
        assertEquals(0xFFFFFFFF, Palette.PAPER.onAccent)
        assertEquals(0xFFFFFFFF, Palette.LIGHT.onAccent)
    }

    @Test
    fun hexColoursParseAsTheCustomThemeStoresThem() {
        assertEquals(0xFF112233, Palette.parseHex("#112233"))
        assertEquals(0x80112233, Palette.parseHex("80112233"))
        assertEquals(0xFFABCDEF, Palette.parseHex(" #abcdef "))
        assertNull(Palette.parseHex("#12345"))
        assertNull(Palette.parseHex("#GG2233"))
        assertEquals("#1FFFFFFF", Palette.toHex(Palette.DARK.outline))
    }

    @Test
    fun aPartialOrCorruptCustomPaletteReadsAsNone() {
        val stored = CustomThemePalette("#FF000000", "#FF111111", "#1FFFFFFF", "#FFEEEEEE", "#99EEEEEE", "#FF7CC4FF")
        assertEquals(Palette(0xFF000000, 0xFF111111, 0x1FFFFFFF, 0xFFEEEEEE, 0x99EEEEEE, 0xFF7CC4FF), Palette.of(stored))
        assertNull(Palette.of(stored.copy(accent = "")))
        assertNull(Palette.of(stored.copy(bg = "black")))
    }

    @Test
    fun contrastIsTheWcagRatio() {
        assertEquals(21.0, Palette.contrastRatio(0xFF000000, 0xFFFFFFFF), 0.01)
        assertEquals(1.0, Palette.contrastRatio(0xFF777777, 0xFF777777), 0.001)
    }
}

class AppearanceTest {
    @Test
    fun forceTvModeMakesAnyDeviceATvWithTheTvDefaults() {
        val forced = Appearance.of(AppearanceSettings(forceTvMode = true), FormFactor.HANDHELD, supporterUnlocked = false)
        assertEquals(FormFactor.TV, forced.formFactor)
        assertEquals(ThemeMode.OLED, forced.theme.mode)
        assertEquals(GridSpacing.NORMAL, forced.gridSpacing)

        val phone = Appearance.of(AppearanceSettings(), FormFactor.HANDHELD, supporterUnlocked = false)
        assertEquals(FormFactor.HANDHELD, phone.formFactor)
        assertEquals(GridSpacing.TIGHT, phone.gridSpacing)
        assertEquals(GridSpacing.SPACIOUS, Appearance.of(AppearanceSettings(gridSpacing = GridSpacing.SPACIOUS), FormFactor.TV, false).gridSpacing)
    }

    @Test
    fun forceTvModeLeavesTheCarFlagAndADesktopBecomesATv() {
        val car = Appearance.of(AppearanceSettings(forceTvMode = true), FormFactor.HANDHELD, supporterUnlocked = false, automotive = true)
        assertEquals(FormFactor.TV, car.formFactor)
        assertTrue(car.automotive, "the car's distraction rules stay on whatever the layout")
        assertEquals(FormFactor.TV, Appearance.of(AppearanceSettings(forceTvMode = true), FormFactor.DESKTOP, supporterUnlocked = false).formFactor)
        assertEquals(FormFactor.DESKTOP, Appearance.of(AppearanceSettings(), FormFactor.DESKTOP, supporterUnlocked = false).formFactor)
    }

    @Test
    fun aCarScalesTheInterfaceByItsStoredScaleOrByDefault() {
        val car = Appearance.of(AppearanceSettings(), FormFactor.HANDHELD, supporterUnlocked = false, automotive = true)
        assertTrue(car.automotive)
        assertEquals(1.35, car.uiScale)
        assertEquals(1.8, Appearance.of(AppearanceSettings(automotiveUiScale = 1.8), FormFactor.HANDHELD, false, automotive = true).uiScale)
    }

    @Test
    fun anythingButACarDrawsAtTheDensityOfItsPlatformWhateverIsStored() {
        for (formFactor in FormFactor.entries) {
            val appearance = Appearance.of(AppearanceSettings(automotiveUiScale = 1.8), formFactor, supporterUnlocked = false)
            assertFalse(appearance.automotive)
            assertEquals(1.0, appearance.uiScale)
        }
    }
}

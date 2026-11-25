package com.edde746.plezy.presentation.settings

import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.theme.Palette
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.CustomThemePalette
import com.edde746.plezy.settings.ThemeMode
import com.edde746.plezy.strings.T
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** Appearance → Theme: the perks' locks, the saved marker, what is selected and focused, the editor. */
class ThemePickerPageTest {
    private val perks = listOf(ThemeMode.EMBER, ThemeMode.GLACIER, ThemeMode.FOREST, ThemeMode.PLUM, ThemeMode.PAPER, ThemeMode.CUSTOM)

    private class Picker(val fixture: SettingsFixture, val store: ThemePickerPage) {
        val events: List<ThemePickerEvent> = fixture.collect(store.events)
        val rows get() = store.state.value.groups.flatMap { it.rows }
        fun row(mode: ThemeMode) = rows.single { it.mode == mode }
        val selected get() = rows.filter { it.selected }.map { it.mode }
        val focused get() = store.state.value.focusedMode
        suspend fun stored() = fixture.data.deviceSettings.value(AppSettings.themeMode)
    }

    /** The picker over [stored] (and a saved [custom] palette), the Supporter perks [available] and [unlocked]. */
    private suspend fun TestScope.picker(
        stored: ThemeMode = ThemeMode.DARK,
        available: Boolean = true,
        unlocked: Boolean = true,
        platform: SettingsPlatform = SettingsPlatform(),
        custom: Palette? = null,
    ): Picker {
        val session = FakeSettingsSession().apply { perks.value = ThemePerks(available, unlocked) }
        val fixture = settingsFixture(platform, session)
        custom?.let { fixture.data.deviceSettings.set(AppSettings.customThemePalette, customOf(it)) }
        fixture.data.deviceSettings.set(AppSettings.themeMode, stored)
        val picker = Picker(fixture, fixture.stores.themePicker())
        runCurrent()
        return picker
    }

    @Test
    fun aBuildWithoutThePerksListsOnlyTheBuiltIns() = runTest {
        val picker = picker(available = false, unlocked = false)
        val groups = picker.store.state.value.groups
        assertEquals(listOf("built_in"), groups.map { it.id })
        assertNull(groups.single().header)
        assertEquals(listOf(ThemeMode.SYSTEM, ThemeMode.LIGHT, ThemeMode.DARK, ThemeMode.OLED), picker.rows.map { it.mode })
        assertTrue(picker.rows.none { it.locked })
    }

    @Test
    fun aLockedBuildLocksEveryPerkAndTheSheetDecides() = runTest {
        val picker = picker(unlocked = false)
        for (mode in perks) assertTrue(picker.row(mode).locked, mode.name)
        for (mode in listOf(ThemeMode.SYSTEM, ThemeMode.LIGHT, ThemeMode.DARK, ThemeMode.OLED)) assertFalse(picker.row(mode).locked, mode.name)
        assertTrue(picker.row(ThemeMode.CUSTOM).locked)

        picker.store.choose(ThemeMode.EMBER)
        runCurrent()
        assertEquals(listOf<ThemePickerEvent>(ThemePickerEvent.OpenSupporter), picker.events)
        assertEquals(ThemeMode.DARK, picker.stored())

        picker.store.choose(ThemeMode.CUSTOM)
        runCurrent()
        assertEquals(listOf<ThemePickerEvent>(ThemePickerEvent.OpenSupporter, ThemePickerEvent.OpenSupporter), picker.events)

        // The sheet closed without a purchase: nothing applies.
        picker.store.supporterClosed(unlocked = false)
        runCurrent()
        assertEquals(2, picker.events.size)

        // Built-ins never ask.
        picker.store.choose(ThemeMode.OLED)
        runCurrent()
        assertEquals(2, picker.events.size)
        assertEquals(ThemeMode.OLED, picker.stored())
    }

    @Test
    fun aPurchaseInTheSheetAppliesTheLockedPickAndDropsTheLocks() = runTest {
        val picker = picker(unlocked = false)
        picker.store.choose(ThemeMode.GLACIER)
        runCurrent()
        assertEquals(listOf<ThemePickerEvent>(ThemePickerEvent.OpenSupporter), picker.events)

        picker.fixture.session.perks.value = ThemePerks(available = true, unlocked = true)
        picker.store.supporterClosed(unlocked = true)
        runCurrent()
        assertEquals(ThemeMode.GLACIER, picker.stored())
        assertTrue(picker.rows.none { it.locked })
        assertEquals(listOf(ThemeMode.GLACIER), picker.selected)
    }

    @Test
    fun aPurchaseFromCustomOpensTheEditor() = runTest {
        val picker = picker(unlocked = false)
        picker.store.choose(ThemeMode.CUSTOM)
        picker.fixture.session.perks.value = ThemePerks(available = true, unlocked = true)
        picker.store.supporterClosed(unlocked = true)
        runCurrent()
        assertEquals(listOf(ThemePickerEvent.OpenSupporter, ThemePickerEvent.OpenEditor), picker.events)
        // Nothing saved yet: the editor stores the theme on Save.
        assertEquals(ThemeMode.DARK, picker.stored())
    }

    @Test
    fun aStoredLockedPerkShowsSystemSelectedStaysStoredAndSaysSo() = runTest {
        val picker = picker(stored = ThemeMode.FOREST, unlocked = false)
        assertEquals(listOf(ThemeMode.SYSTEM), picker.selected)
        assertEquals(ThemeMode.FOREST, picker.stored())
        assertEquals(T.themeEditor.savedLocked, picker.row(ThemeMode.FOREST).note)
        assertEquals(1, picker.rows.count { it.note == T.themeEditor.savedLocked })
        assertEquals(ThemeMode.SYSTEM, picker.focused)
    }

    @Test
    fun unlockingClearsTheSavedMarkerAndPaintsTheSavedPerk() = runTest {
        val picker = picker(stored = ThemeMode.GLACIER, unlocked = false)
        assertEquals(T.themeEditor.savedLocked, picker.row(ThemeMode.GLACIER).note)
        picker.fixture.session.perks.value = ThemePerks(available = true, unlocked = true)
        runCurrent()
        assertEquals(listOf(ThemeMode.GLACIER), picker.selected)
        assertTrue(picker.rows.none { it.note == T.themeEditor.savedLocked })
    }

    @Test
    fun noSavedMarkerWhenTheSavedThemeIsWhatPaints() = runTest {
        val locked = picker(stored = ThemeMode.DARK, unlocked = false)
        assertEquals(listOf(ThemeMode.DARK), locked.selected)
        assertTrue(locked.rows.none { it.note == T.themeEditor.savedLocked })

        val free = picker(stored = ThemeMode.FOREST, unlocked = true)
        assertEquals(listOf(ThemeMode.FOREST), free.selected)
        assertTrue(free.rows.none { it.note == T.themeEditor.savedLocked })
    }

    @Test
    fun focusOpensOnTheThemeThatPaints() = runTest {
        assertEquals(ThemeMode.OLED, picker(stored = ThemeMode.OLED, unlocked = false).focused)
        assertEquals(ThemeMode.CUSTOM, picker(stored = ThemeMode.CUSTOM, custom = Palette.PLUM).focused)
        assertEquals(ThemeMode.SYSTEM, picker(stored = ThemeMode.GLACIER, unlocked = false).focused)
    }

    @Test
    fun onTvALockedSavedPerkShowsTheTvDefaultOled() = runTest {
        val tv = SettingsPlatform(os = "tvOS", isTv = true, formFactor = FormFactor.TV, appleTv = true, hasFileDialogs = false)
        val picker = picker(stored = ThemeMode.GLACIER, unlocked = false, platform = tv)
        assertEquals(listOf(ThemeMode.OLED), picker.selected)
        assertEquals(ThemeMode.OLED, picker.focused)
        assertEquals(T.themeEditor.savedLocked, picker.row(ThemeMode.GLACIER).note)
        assertEquals(ThemeMode.GLACIER, picker.stored())
    }

    @Test
    fun aFreeBuildAppliesEveryPickWithoutTheSheet() = runTest {
        val picker = picker()
        assertTrue(picker.rows.none { it.locked })
        for (mode in listOf(ThemeMode.EMBER, ThemeMode.PAPER)) {
            picker.store.choose(mode)
            runCurrent()
            assertEquals(mode, picker.stored())
            assertEquals(listOf(mode), picker.selected)
        }
        assertTrue(picker.events.isEmpty())
    }

    /** Custom says "Not created" beside its title until one is saved, and opens the editor. */
    @Test
    fun customWithNothingSavedOpensTheEditorSeededFromTheThemeOnScreen() = runTest {
        val picker = picker()
        assertEquals(T.themeEditor.editCustomDescription, picker.row(ThemeMode.CUSTOM).note)
        assertEquals(T.themeEditor.customEmpty, picker.row(ThemeMode.CUSTOM).value)
        assertNull(picker.row(ThemeMode.CUSTOM).palette)

        picker.store.choose(ThemeMode.CUSTOM)
        runCurrent()
        assertEquals(listOf<ThemePickerEvent>(ThemePickerEvent.OpenEditor), picker.events)
        // Opening the editor selects nothing until it saves.
        assertEquals(ThemeMode.DARK, picker.stored())

        val editor = picker.fixture.stores.customThemeEditor()
        runCurrent()
        assertEquals(Palette.DARK, editor.state.value.draft)
    }

    @Test
    fun customWithASavedPaletteSelectsItAndOpensTheEditorOnIt() = runTest {
        val saved = Palette.FOREST.copy(accent = 0xFFFF00AA)
        val picker = picker(custom = saved)
        assertEquals(saved, picker.row(ThemeMode.CUSTOM).palette)
        assertNull(picker.row(ThemeMode.CUSTOM).value)

        picker.store.choose(ThemeMode.CUSTOM)
        runCurrent()
        assertEquals(listOf<ThemePickerEvent>(ThemePickerEvent.OpenEditor), picker.events)
        assertEquals(ThemeMode.CUSTOM, picker.stored())
        assertEquals(listOf(ThemeMode.CUSTOM), picker.selected)
        val editor = picker.fixture.stores.customThemeEditor()
        runCurrent()
        assertEquals(saved, editor.state.value.draft)
    }

    companion object {
        internal fun customOf(palette: Palette) = CustomThemePalette(
            Palette.toHex(palette.bg), Palette.toHex(palette.surface), Palette.toHex(palette.outline),
            Palette.toHex(palette.text), Palette.toHex(palette.textMuted), Palette.toHex(palette.accent),
        )
    }
}

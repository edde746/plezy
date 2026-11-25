package com.edde746.plezy.presentation.settings

import com.edde746.plezy.presentation.settings.ThemePickerPageTest.Companion.customOf
import com.edde746.plezy.presentation.theme.Palette
import com.edde746.plezy.settings.AppSettings
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

/** The Custom theme editor: its slots, hex field, swatches, contrast warnings, Reset, Save and discarding. */
class CustomThemeEditorPageTest {
    private val white = Palette.LIGHT.copy(bg = 0xFFFFFFFF, surface = 0xFFFFFFFF)

    private class Editor(val fixture: SettingsFixture, val store: CustomThemeEditorPage) {
        val messages = fixture.collect(store.messages)
        val state get() = store.state.value
        suspend fun storedPalette() = fixture.data.deviceSettings.value(AppSettings.customThemePalette)?.let(Palette::of)
        suspend fun storedMode() = fixture.data.deviceSettings.value(AppSettings.themeMode)
    }

    /** The editor opened over the saved Custom palette [saved], else over the theme [mode] (unlocked). */
    private suspend fun TestScope.editor(saved: Palette? = null, mode: ThemeMode = ThemeMode.DARK): Editor {
        val fixture = settingsFixture()
        saved?.let { fixture.data.deviceSettings.set(AppSettings.customThemePalette, customOf(it)) }
        fixture.data.deviceSettings.set(AppSettings.themeMode, mode)
        val editor = Editor(fixture, fixture.stores.customThemeEditor())
        runCurrent()
        return editor
    }

    private fun warning(check: String, ratio: String, minimum: String) = T.themeEditor.lowContrast(check, ratio, minimum)

    @Test
    fun listsTheSixColoursWithTheirValues() = runTest {
        val editor = editor(saved = Palette.EMBER)
        assertEquals(listOf("bg", "surface", "outline", "text", "textMuted", "accent"), editor.state.slots.map { it.id })
        assertEquals(Palette.toHex(Palette.EMBER.accent), editor.state.slots.single { it.id == "accent" }.hex)
        assertEquals(Palette.EMBER, editor.state.draft)
        assertFalse(editor.state.dirty)
        // The first slot is edited, its opaque colour shown as #RRGGBB.
        assertEquals(0, editor.state.selectedSlot)
        assertEquals("#14110F", editor.state.hexText)
    }

    @Test
    fun contrastWarningsAppearBelowTheBarAndClearAtItWithoutBlockingSave() = runTest {
        val editor = editor(saved = white)
        editor.store.selectSlot(3)
        val onPage = warning(T.themeEditor.contrast.textOnBg, "4.4", "4.5")
        val onCard = warning(T.themeEditor.contrast.textOnSurface, "4.4", "4.5")
        assertFalse(onPage in editor.state.warnings)

        editor.store.editHex("#777777")
        assertTrue(onPage in editor.state.warnings)
        assertTrue(onCard in editor.state.warnings)

        editor.store.editHex("#767676")
        assertTrue(editor.state.warnings.none { T.themeEditor.contrast.textOnBg in it || T.themeEditor.contrast.textOnSurface in it })

        // An accent too close to the page warns against the 3:1 bar instead.
        editor.store.selectSlot(5)
        editor.store.editHex("#959595")
        assertTrue(warning(T.themeEditor.contrast.accentOnBg, "2.9", "3") in editor.state.warnings)
        editor.store.editHex("#949494")
        assertTrue(editor.state.warnings.none { T.themeEditor.contrast.accentOnBg in it })

        // A failing palette still saves.
        editor.store.editHex("#EEEEEE")
        assertTrue(editor.state.warnings.any { T.themeEditor.contrast.accentOnBg in it })
        editor.store.save()
        runCurrent()
        assertTrue(editor.state.saved)
        assertEquals(0xFFEEEEEE, editor.storedPalette()!!.accent)
    }

    @Test
    fun saveStoresThePaletteAndSelectsCustom() = runTest {
        val editor = editor(mode = ThemeMode.FOREST)
        assertEquals(Palette.FOREST, editor.state.draft)
        editor.store.selectSlot(5)
        editor.store.editHex("#80FF00AA")
        runCurrent()
        assertNull(editor.storedPalette(), "edits stay in the editor until Save")
        assertEquals(ThemeMode.FOREST, editor.storedMode())
        assertTrue(editor.state.dirty)

        editor.store.save()
        runCurrent()
        val expected = Palette.FOREST.copy(accent = 0x80FF00AA)
        assertEquals(expected, editor.storedPalette())
        assertEquals(ThemeMode.CUSTOM, editor.storedMode())
        assertTrue(editor.state.saved)
        assertFalse(editor.state.saving)
    }

    @Test
    fun discardingStoresNothing() = runTest {
        val editor = editor(saved = null, mode = ThemeMode.PLUM)
        editor.store.selectSlot(0)
        editor.store.editHex("#123456")
        assertTrue(editor.state.dirty)
        assertEquals("#FF123456", editor.state.slots[0].hex)
        editor.store.release()
        runCurrent()
        assertNull(editor.storedPalette())
        assertEquals(ThemeMode.PLUM, editor.storedMode())
    }

    @Test
    fun resetReturnsEveryColourToHowTheEditorOpened() = runTest {
        val editor = editor(saved = Palette.GLACIER)
        editor.store.selectSlot(1)
        editor.store.editHex("#FF0000")
        editor.store.startFrom(ThemeMode.EMBER.name)
        assertEquals(Palette.EMBER, editor.state.draft)
        assertTrue(editor.state.dirty)

        editor.store.reset()
        assertEquals(Palette.GLACIER, editor.state.draft)
        assertEquals(Palette.GLACIER.surface, Palette.parseHex(editor.state.slots[1].hex))
        assertFalse(editor.state.dirty, "nothing left to lose: leaving doesn't ask")
    }

    @Test
    fun aQuickSwatchTakesTheColourAnotherThemeUses() = runTest {
        val editor = editor()
        editor.store.selectSlot(5)
        val ember = Palette.toHex(Palette.EMBER.accent)
        assertTrue(ember in editor.state.quickSwatches)
        editor.store.pickSwatch(ember)
        assertEquals("#FF7E57", editor.state.hexText)
        assertEquals(ember, editor.state.slots[5].hex)
    }

    @Test
    fun theHexFieldTakesOnlyHexAndChangesTheDraftWhenItIsAColour() = runTest {
        val editor = editor()
        editor.store.selectSlot(3)
        editor.store.editHex("#12zz")
        assertEquals("#12", editor.state.hexText)
        assertTrue(editor.state.hexInvalid)
        assertEquals(Palette.DARK, editor.state.draft)

        editor.store.editHex("#abcdef")
        assertEquals("#ABCDEF", editor.state.hexText)
        assertFalse(editor.state.hexInvalid)
        assertEquals(0xFFABCDEF, editor.state.draft.text)

        editor.store.editHex("FFABCDEF")
        editor.store.submitHex()
        assertEquals("#ABCDEF", editor.state.hexText)
    }

    @Test
    fun aFailedSaveSaysSoAndStaysOpen() = runTest {
        val editor = editor()
        editor.fixture.failWrites(AppSettings.customThemePalette.key)
        editor.store.selectSlot(5)
        editor.store.editHex("#FF0000")
        editor.store.save()
        runCurrent()
        assertFalse(editor.state.saved)
        assertFalse(editor.state.saving)
        assertEquals(listOf(SettingsEvent.Message(T.settings.saveFailed, error = true)), editor.messages)

        editor.fixture.allowWrites(AppSettings.customThemePalette.key)
        editor.store.save()
        runCurrent()
        assertTrue(editor.state.saved)
    }
}

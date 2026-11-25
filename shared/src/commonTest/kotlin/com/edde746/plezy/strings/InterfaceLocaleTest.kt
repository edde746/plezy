package com.edde746.plezy.strings

import com.edde746.plezy.settings.AppLocale
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse

class InterfaceLocaleTest {
    @AfterTest
    fun reset() {
        InterfaceLocale.setChosen(null)
        InterfaceLocale.setSystemLanguages(listOf("en"))
    }

    @Test
    fun theSystemsFirstLanguageWithStringsIsUsed() {
        InterfaceLocale.setSystemLanguages(listOf("xx-YY", "de-AT", "fr"))
        assertEquals("de-AT", T.locale)
        assertEquals("de-AT", InterfaceLocale.tag.value)
    }

    @Test
    fun anEnglishFirstListShowsEnglish() {
        InterfaceLocale.setSystemLanguages(listOf("en-US", "es-US"))
        assertEquals("en-US", InterfaceLocale.tag.value)
        assertEquals("Play", T.common.play)
    }

    @Test
    fun aFirstLanguageWithoutStringsGivesWayToTheNextEvenEnglish() {
        InterfaceLocale.setSystemLanguages(listOf("fi-FI", "en-US", "de-DE"))
        assertEquals("en-US", InterfaceLocale.tag.value)
        assertEquals("Play", T.common.play)
    }

    @Test
    fun englishOfAnyRegionIsEnglish() {
        InterfaceLocale.setSystemLanguages(listOf("en-GB", "es-ES"))
        assertEquals("en-GB", InterfaceLocale.tag.value)
        assertEquals("Play", T.common.play)
    }

    @Test
    fun aChosenLanguageOverridesTheSystemUntilItIsCleared() {
        InterfaceLocale.setSystemLanguages(listOf("de"))
        InterfaceLocale.setChosen("ja")
        assertEquals("ja", InterfaceLocale.tag.value)
        InterfaceLocale.setChosen(null)
        assertEquals("de", InterfaceLocale.tag.value)
    }

    @Test
    fun noSystemLanguageWithStringsKeepsTheFirstTag() {
        InterfaceLocale.setSystemLanguages(listOf("xx-YY"))
        assertEquals("xx-YY", T.locale)
        assertEquals("Play", T.common.play)
    }

    /**
     * The strings' language set straight on `T` (as the tests that go through every language do, then back to English)
     * is the tag the UI lays out by, both ways: a UI drawn after them is in English, left to right.
     */
    @Test
    fun theStringsLanguageSetOnTIsTheTag() {
        T.locale = "ja"
        assertEquals("ja", InterfaceLocale.tag.value)
        T.locale = "en"
        assertEquals("en", InterfaceLocale.tag.value)
        assertFalse(InterfaceLocale.isRightToLeft(InterfaceLocale.tag.value))
    }

    /** The direction is that of the language the strings show in: none of this build's is right to left. */
    @Test
    fun aRightToLeftLanguageWithoutStringsLaysOutLeftToRight() {
        assertFalse(InterfaceLocale.isRightToLeft("ar"))
        assertFalse(InterfaceLocale.isRightToLeft("he-IL"))
        assertFalse(InterfaceLocale.isRightToLeft("de"))
    }

    @Test
    fun brazilianPortugueseServesPlainPortugueseAndOtherRegions() {
        for (tag in listOf("pt-BR", "pt", "pt-US")) {
            InterfaceLocale.setChosen(tag)
            assertEquals("Salvar", T.common.save, tag)
        }
    }

    @Test
    fun europeanPortugueseServesPortugalAndTheRegionsThatWriteIt() {
        for (region in listOf("PT", "AO", "MZ", "CV", "GW", "ST", "TL", "MO", "GQ", "LU", "CH")) {
            assertEquals("pt-PT", shownFor("pt-$region"), region)
            InterfaceLocale.setChosen("pt-$region")
            assertEquals("Guardar", T.common.save, region)
        }
    }

    private fun shownFor(vararg system: String): String {
        InterfaceLocale.setSystemLanguages(system.toList())
        return Locales.resolve(InterfaceLocale.tag.value)
    }

    @Test
    fun chineseScriptsWinOverRegionsAndRegionsPickTheScript() {
        assertEquals("zh-Hant", shownFor("zh-Hant-TW"))
        assertEquals("zh", shownFor("zh-Hans-TW"))
        for (region in listOf("TW", "HK", "MO")) assertEquals("zh-Hant", shownFor("zh-$region"), region)
        for (region in listOf("CN", "SG")) assertEquals("zh", shownFor("zh-$region"), region)
    }

    @Test
    fun theDevicesLanguagesKeepTheirOrder() {
        assertEquals("fr", shownFor("fr-FR", "zh-Hant"))
        assertEquals("zh-Hant", shownFor("xx", "zh-Hant"))
        assertEquals("zh", shownFor("zh", "zh-Hant"))
    }

    @Test
    fun everyLanguageTheSettingOffersHasItsOwnStrings() {
        assertEquals(23, AppLocale.entries.size)
        assertEquals(AppLocale.entries.map { it.tag }.toSet(), InterfaceLocale.available.toSet())
        for (locale in AppLocale.entries) assertEquals(locale.tag, Locales.resolve(locale.tag), locale.name)
    }

    /** Text in Chinese names its script and region, so the system's fallback fonts draw Chinese glyphs, not Japanese. */
    @Test
    fun chineseTextNamesTheScriptAndRegionThatPickChineseGlyphs() {
        assertEquals("zh-Hans-CN", InterfaceLocale.glyphTag("zh"))
        assertEquals("zh-Hans-CN", InterfaceLocale.glyphTag("zh-Hans"))
        assertEquals("zh-Hant-TW", InterfaceLocale.glyphTag("zh-Hant"))
        assertEquals("zh-HK", InterfaceLocale.glyphTag("zh-HK"))
        assertEquals("zh-Hans-SG", InterfaceLocale.glyphTag("zh-Hans-SG"))
        assertEquals("ja", InterfaceLocale.glyphTag("ja"))
        assertEquals("de", InterfaceLocale.glyphTag("de"))
    }

    @Test
    fun englishMenuTitlesAreInTitleCase() {
        InterfaceLocale.setSystemLanguages(listOf("en-GB"))
        assertEquals("Normalize Loudness", InterfaceLocale.menuTitle("Normalize loudness"))
        assertEquals("Auto-Play Next Episode", InterfaceLocale.menuTitle("Auto-play next episode"))
        assertEquals("Version & Quality", InterfaceLocale.menuTitle("Version & quality"))
        assertEquals("End of the Video", InterfaceLocale.menuTitle("End of the video"))
        assertEquals("HDR", InterfaceLocale.menuTitle("HDR"))
    }

    @Test
    fun otherLanguagesKeepTheirMenuTitles() {
        InterfaceLocale.setChosen("de")
        assertEquals("Audio-Synchronisation", InterfaceLocale.menuTitle("Audio-Synchronisation"))
        assertEquals("Lautstärke normalisieren", InterfaceLocale.menuTitle("Lautstärke normalisieren"))
    }
}

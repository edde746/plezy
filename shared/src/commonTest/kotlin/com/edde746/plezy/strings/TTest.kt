package com.edde746.plezy.strings

import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals

/** The generated `T` over the real shared/i18n/ files. */
class TTest {
    @AfterTest
    fun resetLocale() {
        T.locale = "en"
    }

    @Test
    fun englishByDefault() {
        assertEquals("en", T.locale)
        assertEquals("Play", T.common.play)
        assertEquals("Season 3", T.common.seasonNumber("3"))
        assertEquals("Episode 2 - Pilot", T.common.episodeNumberTitle("2", "Pilot"))
    }

    @Test
    fun switchingLocale() {
        T.locale = "de"
        assertEquals("Abspielen", T.common.play)
        assertEquals("Staffel 3", T.common.seasonNumber("3"))
        T.locale = "en"
        assertEquals("Play", T.common.play)
    }

    @Test
    fun pluralsUseTheSelectedLanguagesRules() {
        assertEquals(listOf("0 tracks", "1 track", "21 tracks"), listOf(0, 1, 21).map(T.music::trackCount))
        T.locale = "ru"
        assertEquals(listOf("1 трек", "2 трека", "5 треков", "11 треков", "21 трек"), listOf(1, 2, 5, 11, 21).map(T.music::trackCount))
        T.locale = "pl"
        assertEquals(listOf("1 utwór", "2 utwory", "5 utworów", "12 utworów", "22 utwory"), listOf(1, 2, 5, 12, 22).map(T.music::trackCount))
        // French and Portuguese put 0 in the singular.
        T.locale = "fr"
        assertEquals(listOf("0 titre", "1 titre", "2 titres"), listOf(0, 1, 2).map(T.music::trackCount))
        T.locale = "pt"
        assertEquals(listOf("0 faixa", "2 faixas"), listOf(0, 2).map(T.music::trackCount))
        T.locale = "ja"
        assertEquals(listOf("1曲", "2曲"), listOf(1, 2).map(T.music::trackCount))
    }

    @Test
    fun chineseRegionsPickTheirScript() {
        T.locale = "zh-TW"
        assertEquals("第 3 季", T.common.seasonNumber("3"))
        T.locale = "zh-CN"
        assertEquals("第3季", T.common.seasonNumber("3"))
    }

    @Test
    fun aKeyThatIsAPoorSwiftNameKeepsItsKotlinName() {
        assertEquals("Copy", T.deepLinks.copy)
    }

    @Test
    fun localeIsABcp47TagKeptAsGiven() {
        for (tag in listOf("de-AT", "de_CH", "DE", "de-DE-u-co-phonebk")) {
            T.locale = tag
            assertEquals(tag, T.locale)
            assertEquals("Abspielen", T.common.play, tag)
        }
        for (tag in listOf("fi", "en-GB", "", "x-klingon")) {
            T.locale = tag
            assertEquals("Play", T.common.play, tag)
        }
    }
}

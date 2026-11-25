package com.edde746.plezy.lang

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class LanguageTagsTest {
    @Test
    fun codesReduceToTheirShortestTag() {
        assertEquals("de", LanguageTags.canonical("ger"))
        assertEquals("de", LanguageTags.canonical("deu"))
        assertEquals("de", LanguageTags.canonical("GER"))
        assertEquals("en", LanguageTags.canonical(" eng "))
        assertEquals("pt-BR", LanguageTags.canonical("pt_br"))
        assertEquals("zh-Hant-TW", LanguageTags.canonical("chi-hant-tw"))
        assertEquals("es-419", LanguageTags.canonical("spa-419"))
        // Three-letter codes without a two-letter one stay as they are.
        assertEquals("fil", LanguageTags.canonical("fil"))
        for (none in listOf(null, "", " ", "und", "mul", "zxx", "e", "english", "en-", "e1")) {
            assertNull(LanguageTags.canonical(none), "$none")
        }
    }

    @Test
    fun subtitleServiceCodesMapToTags() {
        // The codes OpenSubtitles uses, B and T forms mixed, plus its variant codes.
        val codes = mapOf(
            "eng" to "en", "cze" to "cs", "ell" to "el", "fre" to "fr", "mac" to "mk", "ron" to "ro", "nld" to "nl",
            "pob" to "pt-BR", "zht" to "zh-Hant", "zho" to "zh", "ea" to "es-419", "scc" to "sr",
        )
        for ((code, tag) in codes) assertEquals(tag, LanguageTags.canonical(code), code)
    }

    @Test
    fun aRegionalWishPrefersItsRegionButTakesTheLanguage() {
        assertEquals(2, LanguageTags.match("pt-BR", "pt-BR"))
        assertEquals(1, LanguageTags.match("pt-BR", "pt"))
        assertEquals(1, LanguageTags.match("pt", "pt-BR"))
        assertEquals(0, LanguageTags.match("pt-BR", "es"))
    }
}

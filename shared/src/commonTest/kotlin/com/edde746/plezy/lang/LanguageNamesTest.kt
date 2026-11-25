package com.edde746.plezy.lang

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/** Language names through the platform's locale data (JDK on JVM, `NSLocale` on Apple). */
class LanguageNamesTest {
    @Test
    fun languageNamesComeInTheDisplayLanguage() {
        assertEquals("English", LanguageNames.displayName("eng", "en"))
        assertEquals("German", LanguageNames.displayName("ger", "en"))
        assertEquals("Japanese", LanguageNames.displayName("ja", "en"))
        assertEquals("Deutsch", LanguageNames.displayName("ger", "de"))
        assertEquals("Englisch", LanguageNames.displayName("en", "de"))
        // French writes language names in lowercase; a menu entry starts with a capital.
        assertEquals("Anglais", LanguageNames.displayName("eng", "fr"))
        assertEquals("Portuguese (Brazil)", LanguageNames.displayName("pt-BR", "en"))
        assertEquals("Filipino", LanguageNames.displayName("fil", "en"))
        assertNull(LanguageNames.displayName("und", "en"))
    }
}

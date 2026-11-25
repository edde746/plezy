package com.edde746.plezy.ui.components

import java.util.Locale
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** The desktop's 12/24-hour setting: Windows' short time format, a Linux session's time locale. */
class ClockFormatTest {
    @Test
    fun windowsShortTimeIs24HourWithTheCapitalHour() {
        assertTrue(windowsTimeIs24Hour("HH:mm"))
        assertTrue(windowsTimeIs24Hour("H:mm"))
        assertFalse(windowsTimeIs24Hour("h:mm tt"))
        assertFalse(windowsTimeIs24Hour("hh:mm tt"))
    }

    @Test
    fun linuxTakesTheTimeLocaleAsGlibcPicksIt() {
        assertEquals(Locale.forLanguageTag("de-DE"), posixTimeLocale(mapOf("LANG" to "en_US.UTF-8", "LC_TIME" to "de_DE.UTF-8")))
        assertEquals(Locale.forLanguageTag("en-GB"), posixTimeLocale(mapOf("LC_ALL" to "en_GB.UTF-8", "LC_TIME" to "de_DE.UTF-8")))
        assertEquals(Locale.forLanguageTag("en-US"), posixTimeLocale(mapOf("LC_ALL" to "", "LANG" to "en_US.UTF-8")))
        assertNull(posixTimeLocale(mapOf("LC_TIME" to "C.UTF-8")))
        assertNull(posixTimeLocale(mapOf("LANG" to "POSIX")))
        assertNull(posixTimeLocale(emptyMap()))
    }

    @Test
    fun aLocalesOwnClockDecidesWithoutASetting() {
        assertTrue(localeIs24Hour(Locale.forLanguageTag("de-DE")))
        assertTrue(localeIs24Hour(Locale.forLanguageTag("en-GB")))
        assertFalse(localeIs24Hour(Locale.forLanguageTag("en-US")))
    }
}

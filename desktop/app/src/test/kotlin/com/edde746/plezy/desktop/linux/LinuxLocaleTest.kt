package com.edde746.plezy.desktop.linux

import java.util.Locale
import kotlin.test.Test
import kotlin.test.assertEquals

class LinuxLocaleTest {
    private val jvm = Locale.forLanguageTag("de-DE")

    @Test
    fun theLanguageListComesFirstAndInOrder() {
        assertEquals(listOf("en-US", "es"), systemLanguages(mapOf("LANG" to "de_DE.UTF-8", "LANGUAGE" to "en_US.UTF-8:es"), jvm))
        assertEquals(listOf("de-DE"), systemLanguages(mapOf("LANG" to "de_DE.UTF-8", "LANGUAGE" to ""), jvm))
    }

    @Test
    fun aCOrPosixMessagesLocaleIgnoresTheList() {
        assertEquals(listOf("de-DE"), systemLanguages(mapOf("LANG" to "de_DE.UTF-8", "LC_MESSAGES" to "C.UTF-8", "LANGUAGE" to "en_US"), jvm))
        assertEquals(listOf("de-DE"), systemLanguages(mapOf("LC_ALL" to "POSIX", "LANG" to "en_US.UTF-8", "LANGUAGE" to "en_US"), jvm))
        assertEquals(listOf("de-DE"), systemLanguages(mapOf("LANGUAGE" to "en_US"), jvm))
    }
}

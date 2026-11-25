package com.edde746.plezy.strings

import com.edde746.plezy.strings.PluralCategory.FEW
import com.edde746.plezy.strings.PluralCategory.MANY
import com.edde746.plezy.strings.PluralCategory.ONE
import com.edde746.plezy.strings.PluralCategory.OTHER
import kotlin.test.Test
import kotlin.test.assertEquals

/** Expected values from CLDR 48's plurals.json (integer samples). */
class PluralRuleTest {
    private val edges = intArrayOf(0, 1, 2, 5, 21, 22, 101)

    private fun categories(tag: String, vararg numbers: Int) = numbers.map { PluralRule.forTag(tag).select(it) }

    @Test
    fun english() {
        assertEquals(listOf(OTHER, ONE, OTHER, OTHER, OTHER, OTHER, OTHER), categories("en", *edges))
    }

    @Test
    fun french() {
        assertEquals(listOf(ONE, ONE, OTHER, OTHER, OTHER, OTHER, OTHER), categories("fr", *edges))
        assertEquals(listOf(MANY, MANY, OTHER), categories("fr", 1_000_000, 2_000_000, 1_000_001))
    }

    @Test
    fun polish() {
        assertEquals(listOf(MANY, ONE, FEW, MANY, MANY, FEW, MANY), categories("pl", *edges))
        assertEquals(listOf(MANY, MANY, FEW, MANY), categories("pl", 12, 112, 104, 111))
    }

    @Test
    fun russian() {
        assertEquals(listOf(MANY, ONE, FEW, MANY, ONE, FEW, ONE), categories("ru", *edges))
        assertEquals(listOf(MANY, MANY, MANY, FEW), categories("ru", 11, 111, 12, 1_002))
    }

    @Test
    fun portugueseDependsOnTheRegion() {
        assertEquals(listOf(ONE, ONE, OTHER, MANY), categories("pt", 0, 1, 2, 1_000_000))
        assertEquals(listOf(ONE, ONE), categories("pt-BR", 0, 1))
        assertEquals(listOf(OTHER, ONE, OTHER, MANY), categories("pt-PT", 0, 1, 2, 1_000_000))
        assertEquals(listOf(OTHER, ONE), categories("pt_pt", 0, 1))
    }

    @Test
    fun otherLanguages() {
        assertEquals(listOf(OTHER, ONE, OTHER, MANY), categories("es", 0, 1, 2, 1_000_000))
        assertEquals(listOf(OTHER, ONE, MANY), categories("it", 0, 1, 3_000_000))
        for (tag in listOf("ja", "ko", "zh", "zh-Hant")) assertEquals(listOf(OTHER, OTHER, OTHER), categories(tag, 0, 1, 2), tag)
        for (tag in listOf("de", "az", "bg", "da", "hu", "kk", "nb", "nl", "sv", "tr", "uz")) {
            assertEquals(listOf(OTHER, ONE, OTHER, OTHER, OTHER), categories(tag, 0, 1, 2, 21, 1_000_000), tag)
        }
    }

    @Test
    fun unknownLanguagesUseEnglishRules() {
        assertEquals(categories("en", *edges), categories("tlh", *edges))
        assertEquals(categories("en", *edges), categories("", *edges))
    }

    @Test
    fun negativeCountsUseTheAbsoluteValue() {
        assertEquals(listOf(ONE, ONE, FEW), categories("ru", -1, -21, -22))
        assertEquals(listOf(ONE), categories("en", -1))
        // |Int.MIN_VALUE| overflows Int; 2147483648 % 10 = 8.
        assertEquals(listOf(MANY), categories("pl", Int.MIN_VALUE))
    }
}

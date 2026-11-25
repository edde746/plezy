package com.edde746.plezy.model

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

class DucetOrderTest {
    @Test
    fun appliesCldrKanaOrdering() {
        assertTrue(ducetCompare("ア", "あ") < 0)
        assertTrue(ducetCompare("カ", "か") < 0)
    }

    @Test
    fun ordersRepresentativeScriptsByDucetRank() {
        assertTrue(ducetCompare("A", "α") < 0)
        assertTrue(ducetCompare("α", "Ж") < 0)
        assertTrue(ducetCompare("Ж", "一") < 0)
    }

    @Test
    fun decomposesKangxiRadicalsToTheirUnifiedEquivalents() {
        assertEquals(0, ducetCompare("⼀", "一"))
        assertEquals(0, ducetCompare("⿕", "龠"))
    }

    @Test
    fun usesCodepointFallbackForMissingBmpAndSupplementaryCharacters() {
        assertTrue(ducetCompare("\u0378", "\u0379") < 0)
        assertTrue(ducetCompare("\u0378", "A") > 0)
        assertTrue(ducetCompare("😀", "😁") < 0)
        assertTrue(ducetCompare("😀", "A") > 0)
    }

    @Test
    fun preservesApostropheBackslashAndDollarRanks() {
        assertTrue(ducetCompare("'", "\$") < 0)
        assertTrue(ducetCompare("\$", "\\") > 0)
    }

    @Test
    fun comparesOnlyTheFirstCodePoint() {
        assertEquals(0, ducetCompare("A trailing text", "A different text"))
        assertEquals(0, ducetCompare("😀 trailing text", "😀 different text"))
    }

    @Test
    fun rejectsAnEmptyString() {
        assertFailsWith<IllegalArgumentException> { ducetCompare("", "A") }
        assertFailsWith<IllegalArgumentException> { ducetCompare("A", "") }
    }
}

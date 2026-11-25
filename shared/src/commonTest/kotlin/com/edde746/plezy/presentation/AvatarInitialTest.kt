package com.edde746.plezy.presentation

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

/** An avatar's initial is the name's first character as a reader sees it, never part of one, and its colour the name's. */
class AvatarInitialTest {
    @Test
    fun aLetterIsUpperCased() {
        assertEquals("K", initialOf("  kai "))
        assertEquals("É", initialOf("émile"))
        assertEquals("Ж", initialOf("жанна"))
    }

    @Test
    fun aCombiningAccentStaysWithItsLetter() {
        assertEquals("E\u0301", initialOf("e\u0301mile"))
        assertEquals("A\u0308\u0304", initialOf("a\u0308\u0304x"))
    }

    @Test
    fun anEmojiIsWhole() {
        assertEquals("😀", initialOf("😀 Fun"))
        // Variation selector, skin tone, joined emoji.
        assertEquals("❤️", initialOf("❤️ Love"))
        assertEquals("👍🏽", initialOf("👍🏽 Yes"))
        assertEquals("👩🏽‍💻", initialOf("👩🏽‍💻 Dev"))
        assertEquals("👨‍👩‍👧‍👦", initialOf("👨‍👩‍👧‍👦 Family"))
        assertEquals("🏳️‍🌈", initialOf("🏳️‍🌈"))
        assertEquals("1️⃣", initialOf("1️⃣ One"))
    }

    @Test
    fun aFlagIsWhole() {
        assertEquals("🇸🇪", initialOf("🇸🇪 Sweden"))
        // Two flags: the first.
        assertEquals("🇸🇪", initialOf("🇸🇪🇳🇴"))
        // A subdivision flag: the black flag and its tags.
        assertEquals("🏴󠁧󠁢󠁳󠁣󠁴󠁿", initialOf("🏴󠁧󠁢󠁳󠁣󠁴󠁿 Scotland"))
    }

    @Test
    fun cjkHangulAndIndicTakeOneCharacter() {
        assertEquals("東", initialOf("東京"))
        assertEquals("김", initialOf("김민준"))
        assertEquals("さ", initialOf("さくら"))
        // A consonant with its vowel sign.
        assertEquals("कि", initialOf("किरण"))
    }

    @Test
    fun aBlankNameShowsAQuestionMark() {
        assertEquals("?", initialOf(""))
        assertEquals("?", initialOf("   \t\n"))
    }

    @Test
    fun anEmptyNameTakesThePrimaryColourAndANameAlwaysItsOwn() {
        assertNull(avatarColorOf(""))
        // "a" hashes to 97: the palette's second colour.
        assertEquals(0xFF2E7D32, avatarColorOf("a"))
        // "ab" = 97 * 31 + 98 = 3105: the palette's second colour too.
        assertEquals(0xFF2E7D32, avatarColorOf("ab"))
        assertEquals(avatarColorOf("Kids"), avatarColorOf("Kids"))
        // The hash wraps to 31 bits instead of going negative.
        assertNotNull(avatarColorOf("a very long profile name that overflows an int many times over"))
    }
}

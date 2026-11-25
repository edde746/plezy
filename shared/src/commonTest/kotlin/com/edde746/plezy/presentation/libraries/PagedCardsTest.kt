package com.edde746.plezy.presentation.libraries

import com.edde746.plezy.presentation.browse.PlaceholderKind
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.presentation.layout.CardShape
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotSame
import kotlin.test.assertSame

class PagedCardsTest {
    private val made = mutableListOf<String>()

    private fun card(item: String): MediaCardUi {
        made += item
        return MediaCardUi(id = item, title = item, caption = null, shape = CardShape.POSTER, placeholder = PlaceholderKind.MOVIE, artwork = null)
    }

    @Test
    fun `a page that lands makes cards for its own items alone`() {
        val cards = PagedCards<String>()
        val first = cards.cards(mapOf(0 to "a", 1 to "b"), "key", ::card)
        val second = cards.cards(mapOf(0 to "a", 1 to "b", 2 to "c"), "key", ::card)
        assertEquals(listOf("a", "b", "c"), made)
        assertSame(first[0], second[0])
        assertSame(first[1], second[1])
    }

    @Test
    fun `a replaced item and new card settings make the cards anew`() {
        val cards = PagedCards<String>()
        val first = cards.cards(mapOf(0 to "a"), "key", ::card)
        val replaced = cards.cards(mapOf(0 to charArrayOf('a').concatToString()), "key", ::card)
        assertNotSame(first[0], replaced[0])
        val resettled = cards.cards(mapOf(0 to "a"), "other", ::card)
        assertEquals(3, made.size)
        assertNotSame(replaced[0], resettled[0])
    }
}

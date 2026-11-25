package com.edde746.plezy.presentation.browse

import com.edde746.plezy.presentation.layout.CardShape
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/** Where a row's focus goes when its cards are replaced under it. */
class FocusFollowTest {
    private fun card(id: String, series: String? = null) =
        MediaCardUi(id = id, title = id, caption = null, shape = CardShape.POSTER, placeholder = PlaceholderKind.MOVIE, artwork = null, seriesKey = series)

    @Test
    fun `visual focus follows the played item when the hub reorders`() {
        val items = (0..2).map { card("item_$it") }
        val moved = followFocus(listOf(items[1], items[0], items[2]), focused = items[1], displaced = null)
        assertEquals(FocusFollow(0, null), moved)
        assertEquals(FocusFollow(0, null), followFocus(items, focused = items[0], displaced = null))
    }

    @Test
    fun `visual focus reaches the next episode when it lands a refresh after the finished one left`() {
        val movieA = card("movie_a")
        val movieC = card("movie_c")
        val episode1 = card("episode_1", series = "show_1")
        val episode2 = card("episode_2", series = "show_1")

        // The finished episode leaves at once: nothing replaces it, focus keeps its place, the episode is remembered.
        val evicted = followFocus(listOf(movieA, movieC), focused = episode1, displaced = null)
        assertEquals(FocusFollow(-1, episode1), evicted)

        // A refresh later the next episode lands at the front: focus (clamped onto movie C meanwhile) goes to it.
        val landed = followFocus(listOf(episode2, movieA, movieC), focused = movieC, displaced = evicted.displaced)
        assertEquals(FocusFollow(0, null), landed)
    }

    @Test
    fun `an unresolved displaced item stays while focus follows the item it sits on`() {
        val movieA = card("movie_a")
        val movieC = card("movie_c")
        val episode1 = card("episode_1", series = "show_1")
        val followed = followFocus(listOf(movieC, movieA), focused = movieA, displaced = episode1)
        assertEquals(FocusFollow(1, episode1), followed)
    }

    @Test
    fun `focus on nothing it can follow keeps its positional clamp`() {
        val result = followFocus(listOf(card("a")), focused = null, displaced = null)
        assertEquals(-1, result.index)
        assertNull(result.displaced)
    }
}

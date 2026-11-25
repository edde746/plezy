package com.edde746.plezy.model

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNotEquals
import kotlin.test.assertTrue

class SearchRelevanceTest {
    private fun item(
        id: String = "item-1",
        title: String? = null,
        kind: MediaKind = MediaKind.MOVIE,
        originalTitle: String? = null,
        parentTitle: String? = null,
    ) = MediaItem(id = id, backend = BackendKind.PLEX, kind = kind, title = title, originalTitle = originalTitle, parentTitle = parentTitle)

    private fun person(id: String, name: String) = MediaPerson(id = id, name = name, backend = BackendKind.PLEX, serverId = ServerId("plex-1"))

    private fun ids(items: List<MediaItem>) = items.map { it.id }

    private fun hitIds(hits: List<SearchHit>) = hits.map {
        when (it) {
            is SearchHit.Media -> it.item.id
            is SearchHit.Person -> it.person.id
        }
    }

    @Test
    fun normalizesCanonicalCompatibilitySeparatorAndTypographyVariants() {
        assertEquals(normalizeSearchText("Ame\u0301lie"), normalizeSearchText("Amélie"))
        assertEquals(normalizeSearchText("Amelie"), normalizeSearchText("Ａｍｅｌｉｅ"))
        assertEquals(normalizeSearchText("Spider Man"), normalizeSearchText("Spider\u00a0Man"))
        val expected = normalizeSearchText("Spider Man")
        for (value in listOf("Spider-Man", "Spider\u2011Man", "Spider\u2013Man", "Spider\u2014Man")) {
            assertEquals(expected, normalizeSearchText(value), value)
        }
    }

    @Test
    fun preservesAccentsAndScriptSignificantMarks() {
        assertNotEquals(normalizeSearchText("Café"), normalizeSearchText("Cafe"))
        assertEquals(normalizeSearchText("Cafe\u0301"), normalizeSearchText("Café"))
        assertNotEquals(normalizeSearchText("कि"), normalizeSearchText("क"))
        assertTrue(normalizeSearchText("कि").contains("ि"))
    }

    @Test
    fun doesNotGiveAnEnglishOnlyLeadingArticleBonus() {
        val items = listOf(item("the", "The Boys"), item("les", "Les Boys"), item("los", "Los Boys"))
        assertEquals(listOf("the", "les", "los"), ids(rankMediaSearchResults(items, "Boys")))
        assertEquals(listOf("los", "les", "the"), ids(rankMediaSearchResults(items.reversed(), "Boys")))
    }

    @Test
    fun keepsExactTitlesAboveLongerPrefixes() {
        val items = listOf(item("longer", "The Boys in the Boat"), item("exact", "The Boys"))
        assertEquals(listOf("exact", "longer"), ids(rankMediaSearchResults(items, "The Boys")))
    }

    @Test
    fun preservesNullableFieldWeighting() {
        val items = listOf(item("parent", parentTitle = "Target"), item("original", originalTitle = "Target"))
        assertEquals(listOf("original", "parent"), ids(rankMediaSearchResults(items, "Target")))
    }

    @Test
    fun `an artists albums rank above titles that only contain the artists name`() {
        val items = listOf(
            item("mashup", "Portishead vs Radiohead Mashups", kind = MediaKind.ALBUM, parentTitle = "DJ"),
            item("album", "OK Computer", kind = MediaKind.ALBUM, parentTitle = "Radiohead"),
            item("artist", "Radiohead", kind = MediaKind.ARTIST),
        )
        assertEquals(listOf("artist", "album", "mashup"), ids(rankMediaSearchResults(items, "radiohead")))
    }

    @Test
    fun ranksEquivalentQueryFormsIdenticallyAndPreservesNormalizedTies() {
        val items = listOf(
            item("first", "Spider-Man"),
            item("second", "Spider\u2011Man"),
            item("third", "Spider Man Returns"),
            item("accented", "Amélie"),
            item("decomposed", "Ame\u0301lie"),
        )
        val asciiOrder = ids(rankMediaSearchResults(items, "Spider Man"))
        assertEquals(asciiOrder, ids(rankMediaSearchResults(items, "Ｓｐｉｄｅｒ\u3000Ｍａｎ")))
        assertEquals(asciiOrder, ids(rankMediaSearchResults(items, "Spider\u2014Man")))
        assertEquals(listOf("first", "second"), asciiOrder.take(2))
        assertEquals(listOf("first"), ids(rankMediaSearchResults(items, "Spider Man", limit = 1)))
        assertEquals(listOf("accented", "decomposed"), ids(rankMediaSearchResults(items, "Amélie")).take(2))
    }

    @Test
    fun boundedSelectionMatchesTheUnboundedFullOrderingForALargeInput() {
        val items = (0 until 1000).map { i ->
            item(
                "item-$i",
                when {
                    i == 999 -> "Target"
                    i % 137 == 0 -> "Target result $i"
                    i % 41 == 0 -> "A Target result $i"
                    else -> "Candidate $i"
                },
            )
        }
        val expected = ids(rankMediaSearchResults(items, "Target")).take(100)
        assertEquals(expected, ids(rankMediaSearchResults(items, "Target", limit = 100)))
        assertEquals("item-999", expected.first())
    }

    @Test
    fun retainsTheEarliestItemsWhenAnEqualScoreRunCrossesTheCap() {
        val items = (0 until 150).map { item("tie-$it", "Same title") }
        assertEquals((0 until 100).map { "tie-$it" }, ids(rankMediaSearchResults(items, "Same title", limit = 100)))
    }

    @Test
    fun preservesLimitBoundariesFullOrderingAndEmptyQueryInputOrder() {
        val items = listOf(item("prefix", "Target Extended"), item("exact", "Target"), item("contains", "A Target Story"))
        val expected = ids(rankMediaSearchResults(items, "Target"))
        assertEquals(emptyList(), rankMediaSearchResults(items, "Target", limit = 0))
        assertEquals(listOf("exact"), ids(rankMediaSearchResults(items, "Target", limit = 1)))
        assertEquals(expected, ids(rankMediaSearchResults(items, "Target", limit = items.size)))
        assertEquals(expected, ids(rankMediaSearchResults(items, "Target", limit = items.size + 5)))
        assertEquals(listOf("exact", "prefix", "contains"), expected)
        assertEquals(listOf("prefix", "exact"), ids(rankMediaSearchResults(items, "\u2014 \u2011 !!!", limit = 2)))
    }

    @Test
    fun keepsTheNegativeLimitFailureContract() {
        val items = listOf(item(title = "Target"))
        assertFailsWith<IllegalArgumentException> { rankMediaSearchResults(items, "Target", limit = -1) }
        assertFailsWith<IllegalArgumentException> { rankMediaSearchResults(items, "!!!", limit = -1) }
    }

    @Test
    fun aTitleOutranksPeopleWhoseNamesMatchTheQueryTheSameWay() {
        // Every candidate starts with "Rick"; the shorter names earn the larger closeness bonus.
        val hits = listOf(
            SearchHit.Person(person("rick-zahn", "Rick Zahn")),
            SearchHit.Person(person("rick-james", "Rick James")),
            SearchHit.Media(item("rick-and-morty", "Rick and Morty", kind = MediaKind.SHOW)),
        )
        assertEquals("rick-and-morty", hitIds(rankSearchHits(hits, "Rick")).first())
    }

    @Test
    fun anExactNameAndANamePrefixStillBeatWeakerTitleMatches() {
        val exactName = listOf(
            SearchHit.Media(item("portrait", "Christoph Waltz: Portrait of an Actor")),
            SearchHit.Person(person("waltz", "Christoph Waltz")),
        )
        val namePrefix = listOf(SearchHit.Media(item("variations", "The Nolan Variations")), SearchHit.Person(person("north", "Nolan North")))
        assertEquals(listOf("waltz", "portrait"), hitIds(rankSearchHits(exactName, "Christoph Waltz")))
        assertEquals(listOf("north", "variations"), hitIds(rankSearchHits(namePrefix, "Nolan")))
    }
}

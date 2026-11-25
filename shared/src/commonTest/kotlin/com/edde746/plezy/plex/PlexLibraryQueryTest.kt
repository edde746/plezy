package com.edde746.plezy.plex

import com.edde746.plezy.model.LibraryFilter
import com.edde746.plezy.model.LibraryFilterOperator
import com.edde746.plezy.model.LibraryQuery
import com.edde746.plezy.model.LibrarySort
import com.edde746.plezy.model.LibrarySortDirection
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.net.UriComponent
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class PlexLibraryQueryTest {
    private fun params(query: LibraryQuery) = plexLibraryQueryParameters(query)
    private fun single(query: LibraryQuery, key: String) = params(query).single { it.first == key }.second

    @Test
    fun `empty query produces no params`() = assertEquals(emptyList(), params(LibraryQuery()))

    @Test
    fun `kinds map to Plex type codes`() {
        assertEquals("1", single(LibraryQuery(kind = MediaKind.MOVIE), "type"))
        assertEquals("2", single(LibraryQuery(kind = MediaKind.SHOW), "type"))
        assertEquals("1,2", single(LibraryQuery(includeKinds = listOf(MediaKind.MOVIE, MediaKind.SHOW)), "type"))
        assertTrue(params(LibraryQuery(kind = MediaKind.COLLECTION)).none { it.first == "type" })
    }

    @Test
    fun `sort direction rides as a suffix`() {
        assertEquals("titleSort:asc", single(LibraryQuery(sort = LibrarySort("titleSort", LibrarySortDirection.ASCENDING)), "sort"))
        assertEquals("addedAt:desc", single(LibraryQuery(sort = LibrarySort("addedAt")), "sort"))
    }

    @Test
    fun `search puts text in title and a title clause still reaches the wire`() {
        assertEquals("star wars", single(LibraryQuery(search = "star wars"), "title"))
        val p = params(LibraryQuery(search = "wick", filters = listOf(LibraryFilter("title", listOf("The"), LibraryFilterOperator.BEGINS_WITH))))
        assertEquals("wick", p.single { it.first == "title" }.second)
        assertEquals("The", p.single { it.first == "title<" }.second)
    }

    @Test
    fun `the operator rides in the query key`() {
        val p = params(
            LibraryQuery(
                filters = listOf(
                    LibraryFilter("genre", listOf("Action", "Drama")),
                    LibraryFilter("genre", listOf("Comedy"), LibraryFilterOperator.IS_NOT),
                    LibraryFilter("year", listOf("2015"), LibraryFilterOperator.AT_LEAST),
                    LibraryFilter("year", listOf("2018"), LibraryFilterOperator.AT_MOST),
                    LibraryFilter("title", listOf("Wicked"), LibraryFilterOperator.MATCHES),
                ),
            ),
        )
        assertEquals(
            listOf("genre" to "Action,Drama", "genre!" to "Comedy", "year>>" to "2015", "year<<" to "2018", "title=" to "Wicked"),
            p,
        )
    }

    @Test
    fun `two clauses on one field repeat the key so Plex ANDs them`() {
        val p = params(LibraryQuery(filters = listOf(LibraryFilter("genre", listOf("Comedy")), LibraryFilter("genre", listOf("Drama")))))
        assertEquals("genre=Comedy&genre=Drama", UriComponent.encodeQuery(p))
    }

    @Test
    fun `a negated clause encodes to one clause`() {
        val p = params(LibraryQuery(filters = listOf(LibraryFilter("genre", listOf("Comedy", "Horror"), LibraryFilterOperator.IS_NOT))))
        assertEquals("genre!=Comedy%2CHorror", UriComponent.encodeQuery(p))
    }

    @Test
    fun `empty clauses and values are dropped`() {
        val p = params(
            LibraryQuery(filters = listOf(LibraryFilter("genre", listOf("")), LibraryFilter("", listOf("x")), LibraryFilter("tag", emptyList()))),
        )
        assertEquals(emptyList(), p)
    }
}

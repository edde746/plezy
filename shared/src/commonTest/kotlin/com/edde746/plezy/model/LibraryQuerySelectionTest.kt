package com.edde746.plezy.model

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class LibraryQuerySelectionTest {
    @Test
    fun parseSortParamReturnsNullForNullOrEmptyInput() {
        assertNull(parseSortParam(null))
        assertNull(parseSortParam(""))
    }

    @Test
    fun parseSortParamParsesABareFieldAsAscending() {
        assertEquals(LibrarySort("addedAt", LibrarySortDirection.ASCENDING), parseSortParam("addedAt"))
    }

    @Test
    fun parseSortParamStripsExplicitAscendingSuffix() {
        assertEquals(LibrarySort("titleSort", LibrarySortDirection.ASCENDING), parseSortParam("titleSort:asc"))
    }

    @Test
    fun parseSortParamParsesFieldDescAsDescending() {
        assertEquals(LibrarySort("rating", LibrarySortDirection.DESCENDING), parseSortParam("rating:desc"))
    }

    @Test
    fun parseSortParamHandlesDottedPlexSortKeysWithoutLosingTheField() {
        assertEquals(LibrarySort("episode.originallyAvailableAt", LibrarySortDirection.DESCENDING), parseSortParam("episode.originallyAvailableAt:desc"))
    }

    @Test
    fun parseSortParamReturnsNullWhenOnlyTheSuffixIsPresent() {
        assertNull(parseSortParam(":desc"))
    }

    @Test
    fun clausesSortAndAlphaPrefixReachTheQueryTogether() {
        val clauses = listOf(LibraryFilter("genre", listOf("Comedy")), LibraryFilter("unwatched", listOf("1")))
        assertEquals(
            LibraryQuery(filters = clauses, sort = LibrarySort("addedAt", LibrarySortDirection.DESCENDING), nameStartsWith = "B"),
            libraryQueryFromSelection(clauses, sortParam = "addedAt:desc", alphaPrefix = "B"),
        )
    }

    @Test
    fun libraryKindOverridesAnyGroupingTypeParameter() {
        assertEquals(MediaKind.SHOW, libraryQueryFromSelection(emptyList(), typeParam = "1", libraryKind = MediaKind.SHOW).kind)
    }

    @Test
    fun numericGroupingTypeMapsToAKindWhenNoLibraryKindIsGiven() {
        assertEquals(MediaKind.MOVIE, libraryQueryFromSelection(emptyList(), typeParam = "1").kind)
        assertNull(libraryQueryFromSelection(emptyList(), typeParam = "42").kind)
        assertNull(libraryQueryFromSelection(emptyList(), libraryKind = MediaKind.UNKNOWN).kind)
    }

    @Test
    fun multiValueTypeStaysAClauseSoPlexStillReceivesItVerbatim() {
        // Plex shared libraries use `type=1,4` for movies and episodes; no single kind covers that.
        val query = libraryQueryFromSelection(emptyList(), typeParam = "1,4")
        assertNull(query.kind)
        assertEquals(listOf(LibraryFilter("type", listOf("1", "4"))), query.filters)
    }

    @Test
    fun anEmptySelectionProducesAnEmptyQuery() {
        assertEquals(LibraryQuery(), libraryQueryFromSelection(emptyList(), typeParam = "", sortParam = "", alphaPrefix = "", search = ""))
    }
}

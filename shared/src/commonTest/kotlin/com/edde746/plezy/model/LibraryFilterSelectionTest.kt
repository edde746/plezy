package com.edde746.plezy.model

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class LibraryFilterSelectionTest {
    private val genre = LibraryFilter("genre", listOf("42"))
    private val yearFrom = LibraryFilter("year", listOf("2015"), LibraryFilterOperator.AT_LEAST)
    private val yearTo = LibraryFilter("year", listOf("2018"), LibraryFilterOperator.AT_MOST)
    private val unwatched = LibraryFilter("unwatched", listOf("1"))

    @Test
    fun findsTheClausesOfAField() {
        val selection = listOf(yearFrom, genre, yearTo)
        assertEquals(listOf(yearFrom, yearTo), selection.clausesFor("year"))
        assertEquals(yearFrom, selection.clauseFor("year"))
        assertNull(selection.clauseFor("tag"))
    }

    @Test
    fun withFieldReplacesEveryClauseOfTheFieldAtItsFirstPosition() {
        val selection = listOf(genre, yearFrom, unwatched, yearTo)
        val replacement = LibraryFilter("year", listOf("2020"))
        assertEquals(listOf(genre, replacement, unwatched), selection.withField("year", listOf(replacement)))
        assertEquals(listOf(genre, unwatched), selection.withField("year", emptyList()))
        assertEquals(listOf(genre, yearFrom, unwatched, yearTo, replacement.copy(field = "tag")), selection.withField("tag", listOf(replacement.copy(field = "tag"))))
    }

    @Test
    fun selectionsRoundTripOperatorsIncluded() {
        val selection = listOf(
            LibraryFilter("genre", listOf("sci-fi", "horror")),
            yearFrom,
            LibraryFilter("contentRating", listOf("R"), LibraryFilterOperator.IS_NOT),
        )
        assertEquals(selection, decodeLibraryFilterSelection(encodeLibraryFilterSelection(selection)))
    }

    @Test
    fun aSelectionSavedByAPreClauseBuildRestoresAsEqualityClauses() {
        assertEquals(
            listOf(LibraryFilter("genre", listOf("42", "43")), LibraryFilter("unwatched", listOf("1"))),
            decodeLibraryFilterSelection("""{"genre":"42,43","unwatched":"1","empty":",","none":null}"""),
        )
    }

    @Test
    fun aClauseWithAnUnrecognisedOperatorIsDroppedNotDowngradedToInclude() {
        val stored = """[{"field":"genre","op":"isNot","values":["42"]},{"field":"genre","op":"matchesFuzzily","values":["43"]}]"""
        assertEquals(listOf(LibraryFilter("genre", listOf("42"), LibraryFilterOperator.IS_NOT)), decodeLibraryFilterSelection(stored))
    }

    @Test
    fun emptyOrUnreadableSelectionsDecodeToNoFilters() {
        assertEquals(emptyList(), decodeLibraryFilterSelection(""))
        assertEquals(emptyList(), decodeLibraryFilterSelection("{not json"))
        assertEquals(emptyList(), decodeLibraryFilterSelection("\"genre\""))
    }
}

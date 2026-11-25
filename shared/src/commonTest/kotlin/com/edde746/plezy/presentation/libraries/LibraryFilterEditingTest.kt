package com.edde746.plezy.presentation.libraries

import com.edde746.plezy.model.LibraryFilter
import com.edde746.plezy.model.LibraryFilterOperator
import com.edde746.plezy.model.MediaFilter
import com.edde746.plezy.model.MediaFilterType
import com.edde746.plezy.model.MediaFilterUnit
import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class LibraryFilterEditingTest {
    private val genre = MediaFilter("genre", "Genre", MediaFilterType.STRING, key = "/library/sections/1/genre")

    @Test
    fun aBooleanFieldCyclesAnyYesNoInPlace() {
        var filters = listOf(LibraryFilter("genre", listOf("1")))
        var state = BooleanFilterState.ANY
        val seen = mutableListOf<BooleanFilterState>()
        repeat(3) {
            state = nextBooleanFilterState(state, supportsExclusion = true)
            filters = withBooleanFilter(filters, "unwatched", state)
            seen += booleanFilterState(filters, "unwatched")
        }
        assertEquals(listOf(BooleanFilterState.YES, BooleanFilterState.NO, BooleanFilterState.ANY), seen)
        assertEquals(listOf(LibraryFilter("genre", listOf("1"))), filters)
        assertEquals(
            listOf(LibraryFilter("unwatched", listOf("1"), LibraryFilterOperator.IS_NOT)),
            withBooleanFilter(emptyList(), "unwatched", BooleanFilterState.NO),
        )
        assertEquals(BooleanFilterState.ANY, nextBooleanFilterState(BooleanFilterState.YES, supportsExclusion = false))
    }

    @Test
    fun valuesAccumulateInOneClause() {
        var filters = toggleFilterValue(emptyList(), "genre", "10", exclude = false)
        filters = toggleFilterValue(filters, "genre", "20", exclude = false)
        assertEquals(listOf(LibraryFilter("genre", listOf("10", "20"))), filters)
        filters = toggleFilterValue(filters, "genre", "10", exclude = false)
        filters = toggleFilterValue(filters, "genre", "20", exclude = false)
        assertTrue(filters.isEmpty(), "removing the last value clears the field")
    }

    @Test
    fun theExcludeRowNegatesTheClauseAndSurvivesAValueChange() {
        var filters = toggleFilterValue(emptyList(), "genre", "10", exclude = false)
        filters = withFilterExcluded(filters, "genre", exclude = true)
        assertEquals(listOf(LibraryFilter("genre", listOf("10"), LibraryFilterOperator.IS_NOT)), filters)
        filters = toggleFilterValue(filters, "genre", "20", exclude = isFilterExcluded(filters, "genre"))
        assertEquals(listOf(LibraryFilter("genre", listOf("10", "20"), LibraryFilterOperator.IS_NOT)), filters)
    }

    @Test
    fun aNumericRangeEmitsTwoClausesInTheFieldsStoredUnit() {
        val filters = withNumberRange(emptyList(), "duration", 30, 90, MediaFilterUnit.DURATION)
        assertEquals(
            listOf(
                LibraryFilter("duration", listOf("1800000"), LibraryFilterOperator.AT_LEAST),
                LibraryFilter("duration", listOf("5400000"), LibraryFilterOperator.AT_MOST),
            ),
            filters,
        )
        assertEquals(30L, numberBound(filters, "duration", LibraryFilterOperator.AT_LEAST, MediaFilterUnit.DURATION))
        assertEquals(1, activeFilterFieldCount(filters), "a range counts as one filtered field")
    }

    @Test
    fun aRelativeDateWindowEmitsOneBoundedClause() {
        assertEquals(listOf(LibraryFilter("addedAt", listOf("-30d"), LibraryFilterOperator.AT_LEAST)), withDateWindow(emptyList(), "addedAt", "-30d", older = false))
        val older = withDateWindow(emptyList(), "addedAt", "-1y", older = true)
        assertEquals(listOf(LibraryFilter("addedAt", listOf("-1y"), LibraryFilterOperator.AT_MOST)), withDateWindow(older, "addedAt", "-1y", older = true))
        assertTrue(withDateWindow(older, "addedAt", null, older = false).isEmpty())
    }

    @Test
    fun aTextMatchModeChangesTheClauseOperatorNotTheValue() {
        val contains = withTextMatch(emptyList(), "title", "star", LibraryFilterOperator.IS)
        val begins = withTextMatch(contains, "title", "star", LibraryFilterOperator.BEGINS_WITH)
        assertEquals(listOf(LibraryFilter("title", listOf("star"), LibraryFilterOperator.BEGINS_WITH)), begins)
        assertTrue(withTextMatch(begins, "title", "", LibraryFilterOperator.BEGINS_WITH).isEmpty())
    }

    @Test
    fun summariesNameValuesOrCountThemWhenUnknown() {
        val filters = listOf(LibraryFilter("genre", listOf("7", "9"), LibraryFilterOperator.IS_NOT))
        assertEquals("2 excluded", filterFieldSummary(genre, filters, "s1", "s1:lib"))
        FilterValueNames.remember("s1", "s1:lib", "genre", "7", "Drama")
        FilterValueNames.remember("s1", "s1:lib", "genre", "9", "Comedy")
        assertEquals("Not Drama, Comedy", filterFieldSummary(genre, filters, "s1", "s1:lib"))
        val title = MediaFilter("title", "Title")
        assertEquals("star…", filterFieldSummary(title, listOf(LibraryFilter("title", listOf("star"), LibraryFilterOperator.BEGINS_WITH)), "s1", "s1:lib"))
        val added = MediaFilter("addedAt", "Added", MediaFilterType.DATE)
        assertEquals("Older than a year", filterFieldSummary(added, withDateWindow(emptyList(), "addedAt", "-1y", older = true), "s1", "s1:lib"))
        val year = MediaFilter("year", "Year", MediaFilterType.INTEGER)
        assertEquals("2000 to 2010", filterFieldSummary(year, withNumberRange(emptyList(), "year", 2000, 2010, MediaFilterUnit.NONE), "s1", "s1:lib"))
    }

    @Test
    fun summariesOfBooleansListsTextMatchesAndBoundsJoinClausesWithADot() {
        val unwatched = MediaFilter("unwatched", "Unwatched", MediaFilterType.BOOLEAN)
        assertEquals("Yes", filterFieldSummary(unwatched, withBooleanFilter(emptyList(), "unwatched", BooleanFilterState.YES), "s2", "s2:lib"))
        assertEquals("No", filterFieldSummary(unwatched, withBooleanFilter(emptyList(), "unwatched", BooleanFilterState.NO), "s2", "s2:lib"))

        val values = listOf(LibraryFilter("genre", listOf("1", "2")))
        assertEquals(T.libraries.advancedFilters.valueCount("2"), filterFieldSummary(genre, values, "s2", "s2:lib"))
        FilterValueNames.remember("s2", "s2:lib", "genre", "1", "Drama")
        FilterValueNames.remember("s2", "s2:lib", "genre", "2", "Comedy")
        assertEquals("Drama, Comedy", filterFieldSummary(genre, values, "s2", "s2:lib"))
        assertEquals(T.libraries.advancedFilters.valueCount("2"), filterFieldSummary(genre, values, "s2", "s2:other"), "titles are remembered per library")

        val title = MediaFilter("title", "Title")
        val text = listOf(
            LibraryFilter("title", listOf("war"), LibraryFilterOperator.ENDS_WITH),
            LibraryFilter("title", listOf("star"), LibraryFilterOperator.IS_NOT),
        )
        assertEquals("…war · Not star", filterFieldSummary(title, text, "s2", "s2:lib"))

        val year = MediaFilter("year", "Year", MediaFilterType.INTEGER)
        val atLeast = listOf(LibraryFilter("year", listOf("2000"), LibraryFilterOperator.AT_LEAST))
        val atMost = listOf(LibraryFilter("year", listOf("2010"), LibraryFilterOperator.AT_MOST))
        assertEquals(T.libraries.advancedFilters.atLeast("2000"), filterFieldSummary(year, atLeast, "s2", "s2:lib"))
        assertEquals(T.libraries.advancedFilters.atMost("2010"), filterFieldSummary(year, atMost, "s2", "s2:lib"))
        val added = MediaFilter("addedAt", "Added", MediaFilterType.DATE)
        assertEquals("Last 30 days", filterFieldSummary(added, withDateWindow(emptyList(), "addedAt", "-30d", older = false), "s2", "s2:lib"))
    }

    @Test
    fun theValueTitleCacheEmptiesOnceItHoldsMoreThan1000() {
        FilterValueNames.remember("cache", "cache:lib", "genre", "sentinel", "Sentinel")
        var filled = 0
        while (FilterValueNames.lookup("cache", "cache:lib", "genre", "sentinel") != null) {
            FilterValueNames.remember("cache", "cache:lib", "genre", "fill$filled", "Fill")
            filled++
            assertTrue(filled <= 1002, "the cache never empties")
        }
        // It just emptied and holds the one title remembered since.
        FilterValueNames.remember("cache", "cache:lib", "genre", "kept", "Kept")
        repeat(999) { FilterValueNames.remember("cache", "cache:lib", "genre", "more$it", "More") }
        assertEquals("Kept", FilterValueNames.lookup("cache", "cache:lib", "genre", "kept"), "1001 titles still fit")
        FilterValueNames.remember("cache", "cache:lib", "genre", "over", "Over")
        assertNull(FilterValueNames.lookup("cache", "cache:lib", "genre", "kept"))
        assertEquals("Over", FilterValueNames.lookup("cache", "cache:lib", "genre", "over"))
    }
}

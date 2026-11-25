package com.edde746.plezy.model

import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class LibraryQueryTest {
    @Test
    fun fallbackPageTotalAddsAHasMoreSentinelOnlyForFullPages() {
        assertEquals(31, fallbackPageTotal(offset = 20, itemCount = 10, requestedSize = 10))
        assertEquals(32, fallbackPageTotal(offset = 20, itemCount = 11, requestedSize = 10))
        assertEquals(29, fallbackPageTotal(offset = 20, itemCount = 9, requestedSize = 10))
        assertEquals(30, fallbackPageTotal(offset = 20, itemCount = 10, requestedSize = null))
        assertEquals(30, fallbackPageTotal(offset = 20, itemCount = 10, requestedSize = 0))
        assertEquals(30, fallbackPageTotal(offset = 20, itemCount = 10, requestedSize = -1))
    }

    private fun source(pages: List<List<Int>>, total: Int? = null): suspend (Int, Int) -> LibraryPage<Int> {
        var call = 0
        return { start, size ->
            val items = pages.getOrElse(call) { emptyList() }
            call++
            LibraryPage(items, total ?: fallbackPageTotal(start, items.size, size), start)
        }
    }

    @Test
    fun drainPagesFiresAfterEachIntermediatePageNeverAfterTheFinalPage() = runTest {
        val seen = mutableListOf<List<Int>>()
        val all = drainPages<Int>(pageSize = 2, stopOnShortPage = true, onPage = { seen += it }, fetchPage = source(listOf(listOf(1, 2), listOf(3, 4), listOf(5))))
        assertEquals(listOf(1, 2, 3, 4, 5), all)
        assertEquals(listOf(listOf(1, 2), listOf(1, 2, 3, 4)), seen)
    }

    @Test
    fun drainPagesDoesNotFireForASinglePageListing() = runTest {
        var calls = 0
        val all = drainPages<Int>(pageSize = 2, onPage = { calls++ }, fetchPage = source(listOf(listOf(1, 2)), total = 2))
        assertEquals(listOf(1, 2), all)
        assertEquals(0, calls)
    }

    @Test
    fun drainPagesDoesNotFireAfterThePageThatReachesTheAuthoritativeTotal() = runTest {
        val seen = mutableListOf<Int>()
        val all = drainPages<Int>(pageSize = 2, onPage = { seen += it.size }, fetchPage = source(listOf(listOf(1, 2), listOf(3, 4)), total = 4))
        assertEquals(listOf(1, 2, 3, 4), all)
        assertEquals(listOf(2), seen)
    }

    // Storage JSON of a clause

    @Test
    fun theOperatorIdRoundTripsAndIsLeftOutForEquality() {
        val clauses = listOf(
            LibraryFilter("genre", listOf("Comedy"), LibraryFilterOperator.IS_NOT),
            LibraryFilter("year", listOf("2015"), LibraryFilterOperator.AT_LEAST),
            LibraryFilter("title", listOf("Wick"), LibraryFilterOperator.BEGINS_WITH),
            LibraryFilter("genre", listOf("Drama")),
        )
        assertEquals(clauses, clauses.map { LibraryFilter.fromStorageJson(it.toStorageJson()) })
        assertNull(LibraryFilter("genre", listOf("Drama")).toStorageJson()["op"])
        assertEquals(
            mapOf("is" to "", "isNot" to "!", "atLeast" to ">>", "atMost" to "<<", "matches" to "=", "notMatches" to "!=", "beginsWith" to "<", "endsWith" to ">"),
            LibraryFilterOperator.entries.associate { it.id to it.wireSuffix },
        )
        assertEquals(listOf(LibraryFilterOperator.IS_NOT, LibraryFilterOperator.NOT_MATCHES), LibraryFilterOperator.entries.filter { it.isNegated })
    }

    @Test
    fun aClauseWithAnUnknownOrNonStringOperatorIsDiscardedNotDowngradedToInclude() {
        val unknown = buildJsonObject {
            put("field", "genre")
            put("op", "matchesFuzzily")
            put("values", buildJsonArray { add(JsonPrimitive("43")) })
        }
        val numeric = buildJsonObject {
            put("field", "genre")
            put("op", 1)
            put("values", buildJsonArray { add(JsonPrimitive("43")) })
        }
        assertNull(LibraryFilter.fromStorageJson(unknown))
        assertNull(LibraryFilter.fromStorageJson(numeric))
        assertNull(LibraryFilterOperator.fromId("matchesFuzzily"))
    }

    @Test
    fun clausesWithoutAFieldOrAnyNonEmptyStringValueAreDiscarded() {
        val json = Json.parseToJsonElement(
            """[{"field":"","values":["1"]},{"field":"genre","values":["",2]},{"field":"genre"},"genre",{"field":"genre","values":["","42"]}]""",
        )
        val decoded = (json as JsonArray).mapNotNull { LibraryFilter.fromStorageJson(it) }
        assertEquals(listOf(LibraryFilter("genre", listOf("42"))), decoded)
        assertTrue(decoded.single().op == LibraryFilterOperator.IS)
    }
}

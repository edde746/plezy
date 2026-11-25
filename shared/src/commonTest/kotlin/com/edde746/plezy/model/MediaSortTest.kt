package com.edde746.plezy.model

import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class MediaSortTest {
    @Test
    fun returnsPlainKeyForAscending() {
        val s = MediaSort(key = "titleSort", title = "Title")
        assertEquals("titleSort", s.getSortKey())
        assertEquals("titleSort", s.getSortKey(descending = false))
    }

    @Test
    fun appendsDescWhenNoDescKeyIsProvided() {
        assertEquals("addedAt:desc", MediaSort(key = "addedAt", title = "Recently Added").getSortKey(descending = true))
    }

    @Test
    fun usesExplicitDescKeyWhenProvided() {
        assertEquals("titleSort:desc", MediaSort(key = "titleSort", descKey = "titleSort:desc", title = "Title").getSortKey(descending = true))
        assertEquals("rating.desc.custom", MediaSort(key = "rating", descKey = "rating.desc.custom", title = "Rating").getSortKey(descending = true))
    }

    @Test
    fun isDefaultDescendingForDescCaseInsensitively() {
        for (direction in listOf("desc", "DESC", "Desc")) assertTrue(MediaSort(key = "k", title = "t", defaultDirection = direction).isDefaultDescending)
    }

    @Test
    fun isNotDefaultDescendingForAscNullOrOtherValues() {
        assertFalse(MediaSort(key = "k", title = "t", defaultDirection = "asc").isDefaultDescending)
        assertFalse(MediaSort(key = "k", title = "t").isDefaultDescending)
        assertFalse(MediaSort(key = "k", title = "t", defaultDirection = "").isDefaultDescending)
    }

    @Test
    fun fromJsonToleratesMissingOptionalFields() {
        val s = MediaSort.fromJson(buildJsonObject { put("key", "k"); put("title", "t") })
        assertNull(s.descKey)
        assertNull(s.defaultDirection)
    }

    @Test
    fun jsonWritesEveryFieldAndRoundTrips() {
        val sort = MediaSort(key = "k", title = "t", defaultDirection = "asc", unsortedDirection = "asc")
        val json = sort.toJson()
        assertEquals(JsonNull, json["descKey"])
        assertEquals(sort, MediaSort.fromJson(json))
    }

    @Test
    fun valueEqualityAcrossAllFields() {
        val a = MediaSort(key = "k", descKey = "k:desc", title = "A", defaultDirection = "asc")
        val b = MediaSort(key = "k", descKey = "k:desc", title = "A", defaultDirection = "asc")
        assertEquals(a, b)
        assertEquals(a.hashCode(), b.hashCode())
    }

    @Test
    fun differingNonKeyFieldsMakeInstancesUnequal() {
        val a = MediaSort(key = "k", descKey = "k:desc", title = "A", defaultDirection = "asc")
        val b = MediaSort(key = "k", descKey = "other", title = "B", defaultDirection = "desc")
        assertNotEquals(a, b)
    }

    @Test
    fun differentKeysAreNotEqual() {
        assertNotEquals(MediaSort(key = "k1", title = "A"), MediaSort(key = "k2", title = "A"))
    }
}

class MediaFilterJsonTest {
    @Test
    fun filterJsonDropsUnitAndOperatorsAndDefaultsMissingFields() {
        val filter = MediaFilter(filter = "year", title = "Year", filterType = MediaFilterType.INTEGER, unit = MediaFilterUnit.DURATION)
        val json = filter.toJson()
        assertEquals(setOf("filter", "filterType", "key", "title", "type"), json.keys)
        val decoded = MediaFilter.fromJson(json)
        assertEquals(MediaFilterUnit.NONE, decoded.unit)
        assertEquals(MediaFilter.defaultOperatorsFor(MediaFilterType.INTEGER), decoded.operators)
        val empty = MediaFilter.fromJson(buildJsonObject { })
        assertEquals(MediaFilter(filter = "", title = "", filterType = "string", key = "", type = "filter"), empty)
    }

    @Test
    fun filterValueJsonOmitsNullType() {
        val value = MediaFilterValue(key = "/k", title = "T")
        assertEquals(setOf("key", "title"), value.toJson().keys)
        assertEquals(value, MediaFilterValue.fromJson(value.toJson()))
        assertEquals("x", MediaFilterValue.fromJson(buildJsonObject { put("type", "x") }).type)
    }
}

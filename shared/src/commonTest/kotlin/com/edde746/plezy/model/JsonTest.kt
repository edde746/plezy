package com.edde746.plezy.model

import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue

class JsonTest {
    private fun p(value: String) = JsonPrimitive(value)
    private fun p(value: Number) = JsonPrimitive(value)
    private fun p(value: Boolean) = JsonPrimitive(value)
    private fun arr(vararg values: JsonElement) = JsonArray(values.toList())
    private val emptyObject = JsonObject(emptyMap())
    private fun obj(vararg pairs: Pair<String, JsonElement>) = JsonObject(pairs.toMap())

    @Test
    fun flexibleIntParsesIntsTruncatesDoublesAndParsesNumericStrings() {
        assertEquals(42, flexibleInt(p(42)))
        assertEquals(0, flexibleInt(p(0)))
        assertEquals(-7, flexibleInt(p(-7)))
        assertEquals(3, flexibleInt(p(3.9)))
        assertEquals(-3, flexibleInt(p(-3.9)))
        assertEquals(123, flexibleInt(p("123")))
        assertEquals(-45, flexibleInt(p("-45")))
    }

    @Test
    fun flexibleIntReturnsNullForUnparseableOrUnsupported() {
        assertNull(flexibleInt(p("abc")))
        assertNull(flexibleInt(p("12abc")))
        assertNull(flexibleInt(p("")))
        assertNull(flexibleInt(null))
        assertNull(flexibleInt(JsonNull))
        assertNull(flexibleInt(p(true)))
        assertNull(flexibleInt(arr(p(1))))
        assertNull(flexibleInt(obj("a" to p(1))))
    }

    @Test
    fun flexibleLongKeepsValuesPastIntRange() {
        assertEquals(4_000_000_000L, flexibleLong(p(4_000_000_000L)))
        assertEquals(4_000_000_000L, flexibleLong(p("4000000000")))
    }

    @Test
    fun flexibleIntOrZeroDefaultsUnsupportedValuesToZero() {
        assertEquals(3, flexibleIntOrZero(p(3.9)))
        assertEquals(42, flexibleIntOrZero(p("42")))
        assertEquals(0, flexibleIntOrZero(null))
        assertEquals(0, flexibleIntOrZero(p("bad")))
        assertEquals(0, flexibleIntOrZero(p(true)))
    }

    @Test
    fun stringOrEmptyStringifiesValuesAndDefaultsNull() {
        assertEquals("value", stringOrEmpty(p("value")))
        assertEquals("42", stringOrEmpty(p(42)))
        assertEquals("true", stringOrEmpty(p(true)))
        assertEquals("", stringOrEmpty(null))
        assertEquals("", stringOrEmpty(JsonNull))
    }

    @Test
    fun flexibleBoolMapsBoolsOnesAndTrueStrings() {
        assertTrue(flexibleBool(p(true)))
        assertFalse(flexibleBool(p(false)))
        assertTrue(flexibleBool(p(1)))
        assertFalse(flexibleBool(p(0)))
        assertFalse(flexibleBool(p(2)))
        assertFalse(flexibleBool(p(-1)))
        assertTrue(flexibleBool(p("1")))
        assertTrue(flexibleBool(p("true")))
        assertTrue(flexibleBool(p("TRUE")))
        assertFalse(flexibleBool(p("0")))
        assertFalse(flexibleBool(p("false")))
        assertFalse(flexibleBool(p("")))
        assertFalse(flexibleBool(null))
        assertFalse(flexibleBool(p(1.0)))
        assertFalse(flexibleBool(emptyObject))
    }

    @Test
    fun flexibleBoolNullableReturnsNullForMissingAndUnsupported() {
        assertEquals(true, flexibleBoolNullable(p(true)))
        assertEquals(false, flexibleBoolNullable(p(false)))
        assertEquals(true, flexibleBoolNullable(p(1)))
        assertEquals(false, flexibleBoolNullable(p(0)))
        assertEquals(false, flexibleBoolNullable(p(2)))
        assertEquals(true, flexibleBoolNullable(p("1")))
        assertEquals(true, flexibleBoolNullable(p("true")))
        assertEquals(true, flexibleBoolNullable(p("TRUE")))
        assertEquals(false, flexibleBoolNullable(p("0")))
        assertEquals(false, flexibleBoolNullable(p("false")))
        assertEquals(false, flexibleBoolNullable(p("FALSE")))
        assertNull(flexibleBoolNullable(null))
        assertNull(flexibleBoolNullable(JsonNull))
        assertNull(flexibleBoolNullable(p(1.0)))
        assertNull(flexibleBoolNullable(emptyObject))
    }

    @Test
    fun flexibleDoubleParsesNumbersAndNumericStrings() {
        assertEquals(1.5, flexibleDouble(p(1.5)))
        assertEquals(2.0, flexibleDouble(p(2)))
        assertEquals(0.0, flexibleDouble(p(0)))
        assertEquals(3.14, flexibleDouble(p("3.14")))
        assertEquals(-2.5, flexibleDouble(p("-2.5")))
        assertEquals(7.0, flexibleDouble(p("7")))
        assertNull(flexibleDouble(p("abc")))
        assertNull(flexibleDouble(p("")))
        assertNull(flexibleDouble(null))
        assertNull(flexibleDouble(p(true)))
        assertNull(flexibleDouble(arr(p(1))))
    }

    @Test
    fun readStringFieldCoercesToString() {
        assertEquals("42", readStringField(obj("x" to p(42)), "x"))
        assertEquals("3.14", readStringField(obj("x" to p(3.14)), "x"))
        assertEquals("hello", readStringField(obj("x" to p("hello")), "x"))
        assertNull(readStringField(obj("x" to p(1)), "y"))
        assertNull(readStringField(obj("x" to JsonNull), "x"))
    }

    @Test
    fun flexibleListWrapsSingleValues() {
        val input = arr(p(1), p(2), p(3))
        assertSame<List<JsonElement>?>(input, flexibleList(input))
        val item = obj("key" to p("value"))
        assertEquals(listOf<JsonElement>(item), flexibleList(item))
        assertEquals(listOf<JsonElement>(p("solo")), flexibleList(p("solo")))
        assertNull(flexibleList(null))
        assertEquals(emptyList(), flexibleList(arr()))
    }

    @Test
    fun flexibleStringListKeepsStringsOnly() {
        assertEquals(listOf("tt1", "tt3"), flexibleStringList(arr(p("tt1"), p(2), p("tt3"), JsonNull)))
        assertEquals(listOf("tt1"), flexibleStringList(p("tt1")))
        assertNull(flexibleStringList(null))
        assertNull(flexibleStringList(arr()))
        assertNull(flexibleStringList(arr(p(1), p(2), p(3))))
    }

    @Test
    fun flexibleCsvStringListSplitsTrimsAndDropsEmpties() {
        assertEquals(listOf("en", "sv"), flexibleCsvStringList(arr(p("en"), p("sv"))))
        assertEquals(listOf("en"), flexibleCsvStringList(p("en")))
        assertEquals(listOf("en", "sv"), flexibleCsvStringList(p("en,sv")))
        assertEquals(listOf("en", "sv", "fr"), flexibleCsvStringList(p("en, sv , ,fr")))
        assertNull(flexibleCsvStringList(p(",")))
        assertNull(flexibleCsvStringList(p("")))
        assertEquals(listOf("en", "sv", "fr"), flexibleCsvStringList(arr(p("en,sv"), p("fr"))))
        assertEquals(listOf("en"), flexibleCsvStringList(arr(p(1), p("en"))))
        assertNull(flexibleCsvStringList(null))
        assertNull(flexibleCsvStringList(arr()))
    }

    private fun parseId(json: JsonObject): String = (json["id"] as JsonPrimitive).also { require(it.isString) }.content

    @Test
    fun listParserKeepsValidSiblingsAroundMalformedEntries() {
        val parsed = parseFlexibleJsonList(arr(obj("id" to p("first")), obj("id" to p(2)), p("not-a-map"), obj("id" to p("last"))), ::parseId)
        assertEquals(listOf("first", "last"), parsed)
    }

    @Test
    fun objectParserFindsTheFirstMapAndContainsParseFailures() {
        assertEquals("value", parseFlexibleJsonObject(arr(p("not-a-map"), obj("id" to p("value"))), ::parseId))
        assertNull(parseFlexibleJsonObject(obj("id" to p(2)), ::parseId))
        assertNull(parseFlexibleJsonObject(null, ::parseId))
    }

    @Test
    fun stringListFromRawStringifiesOrFiltersAndReadsMapKeys() {
        val raw = arr(p("a"), p(2), JsonNull, buildJsonObject { put("tag", "b") })
        assertEquals(listOf("a"), stringListFromRaw(raw))
        assertEquals(listOf("a", "2", """{"tag":"b"}"""), stringListFromRaw(raw, stringify = true))
        assertEquals(listOf("a", "b"), stringListFromRaw(raw, mapKey = "tag"))
        assertNull(stringListFromRaw(p("a")))
        assertEquals(emptyList(), stringListFromRaw(arr()))
        assertNull(stringListFromRaw(arr(), nullIfEmpty = true))
    }

    @Test
    fun firstNonBlankSkipsBlanksAndTrims() {
        assertEquals("x", firstNonBlank(listOf(null, "  ", " x ", "y")))
        assertNull(firstNonBlank(listOf(null, "")))
        assertNull(nullIfEmptyList(emptyList<Int>()))
        assertEquals(listOf(1), nullIfEmptyList(listOf(1)))
    }
}

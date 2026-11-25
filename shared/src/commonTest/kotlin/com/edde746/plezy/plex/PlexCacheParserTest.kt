package com.edde746.plezy.plex

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull

class PlexCacheParserTest {
    private fun obj(text: String): JsonObject = Json.parseToJsonElement(text).jsonObject

    // extractMetadataList

    @Test
    fun `metadata list is null for null input`() {
        assertNull(PlexCacheParser.extractMetadataList(null))
    }

    @Test
    fun `metadata list is null when MediaContainer missing`() {
        assertNull(PlexCacheParser.extractMetadataList(obj("{}")))
    }

    @Test
    fun `metadata list is null when Metadata key missing`() {
        assertNull(PlexCacheParser.extractMetadataList(obj("""{"MediaContainer":{}}""")))
    }

    @Test
    fun `metadata list is returned when present`() {
        val list = Json.parseToJsonElement("""[{"ratingKey":"1"},{"ratingKey":"2"}]""").jsonArray
        assertEquals(list, PlexCacheParser.extractMetadataList(obj("""{"MediaContainer":{"Metadata":$list}}""")))
    }

    @Test
    fun `metadata that is present but not a list throws`() {
        assertFailsWith<IllegalArgumentException> {
            PlexCacheParser.extractMetadataList(obj("""{"MediaContainer":{"Metadata":"not-a-list"}}"""))
        }
    }

    // extractFirstMetadata

    @Test
    fun `first metadata is null for null input`() {
        assertNull(PlexCacheParser.extractFirstMetadata(null))
    }

    @Test
    fun `first metadata is null for empty Metadata`() {
        assertNull(PlexCacheParser.extractFirstMetadata(obj("""{"MediaContainer":{"Metadata":[]}}""")))
    }

    @Test
    fun `first metadata is the first map when present`() {
        val result = PlexCacheParser.extractFirstMetadata(obj("""{"MediaContainer":{"Metadata":[{"ratingKey":"1"},{"ratingKey":"2"}]}}"""))
        assertEquals(obj("""{"ratingKey":"1"}"""), result)
    }
}

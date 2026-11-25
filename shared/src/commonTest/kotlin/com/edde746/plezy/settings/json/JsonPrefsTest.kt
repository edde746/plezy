package com.edde746.plezy.settings.json

import com.edde746.plezy.model.MediaVersionPreference
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.test.assertFailsWith
import com.edde746.plezy.data.testData
import kotlinx.coroutines.test.runTest

class MediaVersionPreferencesTest {

    @Test
    fun aWriteRetiresTheUnscopedKeyAndReadsFallBackToIt() {
        val legacy = buildJsonObject { put("show-1", 2) }
        assertEquals(2, MediaVersionPreferences.saved(legacy, "srv:show-1", "show-1")?.index)

        val updated = MediaVersionPreferences.withPreference(legacy, "srv:show-1", "show-1", MediaVersionPreference(index = 0, updatedAt = 5))
        assertEquals(setOf("srv:show-1"), updated.keys)
    }

    @Test
    fun theOldestChoicesGoPastTheLimitUnscopedFirst() {
        val store = JsonObject(
            (0 until MediaVersionPreferences.LIMIT).associate { "srv:$it" to MediaVersionPreference(index = 0, updatedAt = it + 1L).toJson() } +
                ("legacy" to JsonPrimitive(1)),
        )

        val updated = MediaVersionPreferences.withPreference(store, "srv:new", "new", MediaVersionPreference(index = 0, updatedAt = 10_000))

        assertEquals(MediaVersionPreferences.LIMIT, updated.size)
        assertTrue("srv:new" in updated)
        assertFalse("legacy" in updated)
        assertFalse("srv:0" in updated)
    }
}

class SettingsLocalPlaybackHistoryStoreTest {
    @Test
    fun entriesThatAreNotTimesAreLeftOut() {
        val stored = buildJsonObject {
            put("srv-1:movie-1", 7)
            put("srv-1:bad", "7")
            put("srv-1:obj", buildJsonObject {})
        }
        assertEquals(mapOf("srv-1:movie-1" to 7L), SettingsLocalPlaybackHistoryStore.decode(stored))
    }
}

class RecentTagsTest {
    private fun add(data: Map<String, Map<String, List<String>>>, vararg tags: String, server: String = "srv-1", field: String = "label") =
        RecentTags.added(data, tags.toList(), server, field) ?: data

    @Test
    fun tagsAreKeptPerServerAndField() {
        var data = add(emptyMap(), "kids")
        data = add(data, "horror", field = "genre")
        data = add(data, "other-server-tag", server = "srv-2")

        assertEquals(listOf("kids"), data["srv-1"]?.get("label"))
        assertEquals(listOf("horror"), data["srv-1"]?.get("genre"))
        assertEquals(listOf("other-server-tag"), data["srv-2"]?.get("label"))
    }

    @Test
    fun newestFirstAndReaddingMovesATagToTheFront() {
        var data = add(add(emptyMap(), "a", "b"), "c")
        assertEquals(listOf("c", "a", "b"), data["srv-1"]?.get("label"))
        data = add(data, "b")
        assertEquals(listOf("b", "c", "a"), data["srv-1"]?.get("label"))
    }

    @Test
    fun readdingInAnotherCaseReplacesInsteadOfDuplicating() {
        assertEquals(listOf("kids"), add(add(emptyMap(), "Kids"), "kids")["srv-1"]?.get("label"))
    }

    @Test
    fun blankTagsAreIgnored() {
        assertNull(RecentTags.added(emptyMap(), listOf("", "  "), "srv-1", "label"))
    }

    @Test
    fun eachListKeepsTheNewestTwenty() {
        val data = add(emptyMap(), *Array(25) { "t$it" })
        assertEquals((0 until RecentTags.LIMIT).map { "t$it" }, data["srv-1"]?.get("label"))
    }

    @Test
    fun aMalformedValueReadsAsNoTags() {
        assertEquals(emptyMap(), RecentTags.decode(buildJsonObject { put("srv-1", "not a map") }))
    }

    @Test
    fun suggestionsPutRecentsFirstOnceEachWithoutAppliedTags() {
        val merged = RecentTags.mergeSuggestions(listOf("kids"), listOf("Kids", "horror", "documentary"), listOf("documentary"))
        assertEquals(listOf("kids", "horror"), merged)
    }

    @Test
    fun tagsAreTrimmedAndABlankProfileIsRefused() = runTest {
        assertEquals(listOf("spaced"), add(emptyMap(), " spaced ")["srv-1"]?.get("label"))
        val data = testData()
        try {
            val recent = RecentTags(data.profileSettings)
            assertFailsWith<IllegalArgumentException> { recent.addRecentTags(listOf("a"), "", "srv-1", "label") }
            assertFailsWith<IllegalArgumentException> { recent.recentTags(" ", "srv-1", "label") }
        } finally {
            data.close()
        }
    }
}

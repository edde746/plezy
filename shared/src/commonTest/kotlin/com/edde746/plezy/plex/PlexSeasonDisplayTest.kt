package com.edde746.plezy.plex

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class PlexSeasonDisplayTest {
    private fun obj(text: String): JsonObject = Json.parseToJsonElement(text).jsonObject

    private fun show(raw: String? = null) = MediaItem(id = "show", backend = BackendKind.PLEX, kind = MediaKind.SHOW, raw = raw?.let(::obj))

    private fun season(id: String) = MediaItem(id = id, backend = BackendKind.PLEX, kind = MediaKind.SEASON)

    @Test
    fun `per show hide override shows episodes directly`() {
        assertTrue(shouldShowPlexEpisodesDirectly(show("""{"flattenSeasons":1}"""), listOf(season("1"), season("2")), obj("{}")))
    }

    @Test
    fun `per show show override keeps seasons despite hidden library default`() {
        assertFalse(
            shouldShowPlexEpisodesDirectly(show("""{"flattenSeasons":0}"""), listOf(season("1"), season("2")), obj("""{"flattenSeasons":1}""")),
        )
    }

    @Test
    fun `skipChildren hides seasons when no explicit show override exists`() {
        assertTrue(shouldShowPlexEpisodesDirectly(show("""{"skipChildren":true}"""), listOf(season("1"), season("2")), obj("{}")))
    }

    @Test
    fun `falls back to library single season mode`() {
        assertTrue(shouldShowPlexEpisodesDirectly(show(), listOf(season("1")), obj("""{"flattenSeasons":"2"}""")))
        assertFalse(shouldShowPlexEpisodesDirectly(show(), listOf(season("1"), season("2")), obj("""{"flattenSeasons":"2"}""")))
    }

    @Test
    fun `a show without seasons lists episodes`() {
        assertTrue(shouldShowPlexEpisodesDirectly(show(), emptyList(), obj("{}")))
    }
}

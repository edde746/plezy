package com.edde746.plezy.model

import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class PrimaryTrailerTest {
    private fun item(id: String, backend: BackendKind = BackendKind.PLEX, raw: Map<String, String>? = null, trailerKey: String? = null) =
        MediaItem(
            id = id,
            backend = backend,
            kind = MediaKind.MOVIE,
            trailerKey = trailerKey,
            raw = raw?.let { fields -> buildJsonObject { fields.forEach { (key, value) -> put(key, JsonPrimitive(value)) } } },
        )

    private val featurette = item("featurette", raw = mapOf("ExtraType" to "Featurette"))
    private val trailer = item("trailer", raw = mapOf("ExtraType" to "Trailer"))

    @Test
    fun picksTheFirstExtraClassifiedAsATrailer() {
        assertEquals("trailer", primaryTrailer(item("movie"), listOf(featurette, trailer))?.id)
    }

    @Test
    fun prefersPlexsOwnPrimaryExtraOverTheFirstTrailer() {
        val pick = item("52601", raw = mapOf("ExtraType" to "Featurette"))
        val movie = item("movie", trailerKey = "/library/metadata/52601")

        assertEquals("52601", primaryTrailer(movie, listOf(trailer, pick))?.id)
    }

    @Test
    fun readsMediaBrowserExtraTypesAndReturnsNullWithoutATrailer() {
        val jellyfinTrailer = item("jf-trailer", BackendKind.JELLYFIN, raw = mapOf("Type" to "Trailer"))

        assertEquals("jf-trailer", primaryTrailer(item("movie"), listOf(featurette, jellyfinTrailer))?.id)
        assertNull(primaryTrailer(item("movie"), listOf(featurette)))
    }

    @Test
    fun aPlexSubtypeDecidesOnItsOwn() {
        val clip = MediaItem(id = "clip", backend = BackendKind.PLEX, kind = MediaKind.CLIP, subtype = "clip")
        val plexTrailer = MediaItem(id = "plex-trailer", backend = BackendKind.PLEX, kind = MediaKind.CLIP, subtype = "Trailer")

        assertEquals("plex-trailer", primaryTrailer(item("movie"), listOf(clip, plexTrailer))?.id)
    }
}

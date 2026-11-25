package com.edde746.plezy.model

import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlinx.serialization.json.putJsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ContentUtilsTest {
    private fun episode(viewOffsetMs: Long? = null, durationMs: Long? = null, viewCount: Int? = null) = MediaItem(
        id = "1",
        backend = BackendKind.PLEX,
        kind = MediaKind.EPISODE,
        viewOffsetMs = viewOffsetMs,
        durationMs = durationMs,
        viewCount = viewCount,
    )

    @Test
    fun stripsTwoAndThreeLetterCountryPrefixesCaseInsensitively() {
        assertEquals("PG-13", formatContentRating("us/PG-13"))
        assertEquals("15", formatContentRating("gb/15"))
        assertEquals("16", formatContentRating("deu/16"))
        assertEquals("PG-13", formatContentRating("US/PG-13"))
        assertEquals("PG", formatContentRating("Us/PG"))
    }

    @Test
    fun returnsOriginalWhenNoPrefixPresent() {
        assertEquals("PG-13", formatContentRating("PG-13"))
        assertEquals("TV-MA", formatContentRating("TV-MA"))
    }

    @Test
    fun returnsEmptyStringForNullOrEmpty() {
        assertEquals("", formatContentRating(null))
        assertEquals("", formatContentRating(""))
    }

    @Test
    fun doesNotStripSingleLetterOrDigitPrefixes() {
        assertEquals("1/foo", formatContentRating("1/foo"))
        assertEquals("a/foo", formatContentRating("a/foo"))
    }

    @Test
    fun shouldHideSpoilerIsFalseForNonEpisodes() {
        assertFalse(MediaItem(id = "1", backend = BackendKind.PLEX, kind = MediaKind.MOVIE).shouldHideSpoiler)
        assertFalse(MediaItem(id = "1", backend = BackendKind.PLEX, kind = MediaKind.SHOW).shouldHideSpoiler)
    }

    @Test
    fun shouldHideSpoilerIsFalseWhenEpisodeHasBeenWatched() {
        assertFalse(episode(viewCount = 1).shouldHideSpoiler)
    }

    @Test
    fun shouldHideSpoilerWhileInProgressUntilMarkedWatched() {
        for (offset in listOf(1000L, 4999L, 5000L, 8000L)) assertTrue(episode(viewOffsetMs = offset, durationMs = 10000).shouldHideSpoiler)
    }

    @Test
    fun shouldHideSpoilerWhenUnwatchedOrDurationMissing() {
        assertTrue(episode().shouldHideSpoiler)
        assertTrue(episode(viewOffsetMs = 0).shouldHideSpoiler)
        assertTrue(episode(viewOffsetMs = 500).shouldHideSpoiler)
    }

    @Test
    fun spoilerSafeArtPrefersTheShowsArt() {
        assertEquals("/show", episode().copy(grandparentArtPath = "/show", artPath = "/ep").spoilerSafeArt)
        assertEquals("/ep", episode().copy(artPath = "/ep").spoilerSafeArt)
    }

    @Test
    fun typeHelpers() {
        val kinds = MediaKind.entries.filter { MediaItem(id = "1", backend = BackendKind.PLEX, kind = it).isVideoContent }
        assertEquals(listOf(MediaKind.MOVIE, MediaKind.SHOW, MediaKind.SEASON, MediaKind.EPISODE), kinds)
        assertTrue(episode().isEpisode)
        assertFalse(episode().isMovie)
    }

    @Test
    fun libraryIconNormalizesTypeAndFallsBackToFolder() {
        assertEquals(LibraryIconKind.MOVIE, LibraryIconKind.forLibraryType("MOVIE"))
        assertEquals(LibraryIconKind.TV, LibraryIconKind.forLibraryType("show"))
        assertEquals(LibraryIconKind.MUSIC_NOTE, LibraryIconKind.forLibraryType("artist"))
        assertEquals(LibraryIconKind.PHOTO, LibraryIconKind.forLibraryType("photo"))
        assertEquals(LibraryIconKind.SHARE, LibraryIconKind.forLibraryType("mixed"))
        assertEquals(LibraryIconKind.FOLDER, LibraryIconKind.forLibraryType("unknown"))
    }

    @Test
    fun catalogStandInsAreRecognizedByTheirRawKey() {
        val plain = episode()
        assertFalse(plain.isCatalogItem)
        assertNull(plain.catalogItemJson)
        val entry = buildJsonObject { put("id", "tmdb:1") }
        val standIn = plain.copy(raw = buildJsonObject { put(CATALOG_ITEM_RAW_KEY, entry) })
        assertTrue(standIn.isCatalogItem)
        assertEquals(entry, standIn.catalogItemJson)
        val notAMap = plain.copy(raw = buildJsonObject { put(CATALOG_ITEM_RAW_KEY, "x") })
        assertTrue(notAMap.isCatalogItem)
        assertNull(notAMap.catalogItemJson)
        assertFalse(plain.copy(raw = buildJsonObject { put(CATALOG_ITEM_RAW_KEY, JsonNull) }).isCatalogItem)
        assertFalse(plain.copy(raw = buildJsonObject { putJsonObject("other") { } }).isCatalogItem)
    }
}

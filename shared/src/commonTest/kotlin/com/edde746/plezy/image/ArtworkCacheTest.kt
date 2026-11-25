package com.edde746.plezy.image

import com.edde746.plezy.log.UrlTokens
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertTrue

class ArtworkCacheTest {
    private val token = "secret-token"
    private val plexUrl = "https://srv.example:32400/photo/:/transcode?width=200&minSize=1" +
        "&url=%2Flibrary%2Fmetadata%2F1%2Fthumb%2F99%3FX-Plex-Token%3D$token&X-Plex-Token=$token"

    @Test
    fun `redaction blanks outer and nested Plex tokens and Jellyfin api keys`() {
        assertEquals(
            "https://srv.example:32400/photo/:/transcode?width=200&minSize=1" +
                "&url=%2Flibrary%2Fmetadata%2F1%2Fthumb%2F99%3FX-Plex-Token%3D&X-Plex-Token=",
            UrlTokens.redact(plexUrl),
        )
        assertEquals(
            "https://jf.example/Items/1/Images/Primary?maxWidth=300&api_key=",
            UrlTokens.redact("https://jf.example/Items/1/Images/Primary?maxWidth=300&api_key=$token"),
        )
        assertEquals("https://cdn.example/poster.jpg", UrlTokens.redact("https://cdn.example/poster.jpg"))
    }

    @Test
    fun `redaction blanks a token encoded twice and a Jellyfin ApiKey in any case`() {
        assertEquals(
            "https://srv/photo/:/transcode?url=https%3A%2F%2Fa%2Fb%253FX-Plex-Token%253D%2526c%253D1&apikey=#top",
            UrlTokens.redact("https://srv/photo/:/transcode?url=https%3A%2F%2Fa%2Fb%253FX-Plex-Token%253D$token%2526c%253D1&apikey=$token#top"),
        )
    }

    @Test
    fun `the cache key is the sha1 of the redacted url and holds no token`() {
        val key = ArtworkCache.key(plexUrl)

        assertFalse(token in key)
        assertEquals(ArtworkCache.key(UrlTokens.redact(plexUrl)), key)
        assertEquals(ArtworkCache.key(plexUrl.replace(token, "another-token")), key)
        // SHA-1 of "abc".
        assertEquals("plex_optimized_a9993e364706816aba3e25717850c26c9cd0d89d", ArtworkCache.key("abc"))
    }

    @Test
    fun `urls differing beyond their tokens have different keys`() {
        assertNotEquals(ArtworkCache.key(plexUrl), ArtworkCache.key(plexUrl.replace("width=200", "width=400")))
    }

    @Test
    fun `entries written more than 14 days ago are evicted`() {
        val now = 100L * DAY
        val written = listOf(now - 14 * DAY, now - 14 * DAY - 1, now, now - 30 * DAY)

        assertEquals(setOf(1, 3), ArtworkCache.evictions(written, now).toSet())
    }

    @Test
    fun `past 3000 entries the oldest written are evicted`() {
        val now = 100L * DAY
        // 3002 fresh entries, oldest at the end, plus one stale one.
        val written = List(ArtworkCache.MAX_ENTRIES + 2) { now - it * 1000L } + (now - 20 * DAY)

        val evicted = ArtworkCache.evictions(written, now)

        assertEquals(setOf(ArtworkCache.MAX_ENTRIES, ArtworkCache.MAX_ENTRIES + 1, ArtworkCache.MAX_ENTRIES + 2), evicted.toSet())
        assertTrue(ArtworkCache.evictions(written.take(ArtworkCache.MAX_ENTRIES), now).isEmpty())
    }

    @Test
    fun `downloads run six at once and three on the reduced tier`() {
        assertEquals(6, ArtworkCache.downloadConcurrency(reduced = false))
        assertEquals(3, ArtworkCache.downloadConcurrency(reduced = true))
    }

    private companion object {
        const val DAY = 24L * 60 * 60 * 1000
    }
}

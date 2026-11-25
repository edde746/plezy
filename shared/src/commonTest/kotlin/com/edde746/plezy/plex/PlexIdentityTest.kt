package com.edde746.plezy.plex

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class PlexIdentityTest {
    @Test
    fun `sanitizeHeaderValue folds Latin letters drops what headers cannot carry and nulls blanks`() {
        assertEquals("Living Room TV", sanitizeHeaderValue("Living Room TV"))
        assertEquals("Bjorns AEble Strasse", sanitizeHeaderValue("Bjørns Æble Straße"))
        assertEquals("Cafe", sanitizeHeaderValue("Café"))
        assertEquals("TV", sanitizeHeaderValue("TV\u2122"))
        assertEquals("ab", sanitizeHeaderValue("a\r\nb"))
        assertNull(sanitizeHeaderValue(null))
        assertNull(sanitizeHeaderValue(""))
        assertNull(sanitizeHeaderValue("  \u2603 "))
    }

    @Test
    fun `withPlexToken appends with the right separator and leaves tokenless urls alone`() {
        assertEquals("/library/metadata/123?X-Plex-Token=abc", withPlexToken("/library/metadata/123", "abc"))
        assertEquals("/a?type=1&X-Plex-Token=abc", withPlexToken("/a?type=1", "abc"))
        assertEquals("/a", withPlexToken("/a", null))
        assertEquals("/a", withPlexToken("/a", ""))
    }

    @Test
    fun `session identifiers are 24 lowercase alphanumerics`() {
        val id = generateSessionIdentifier()
        assertEquals(24, id.length)
        assertEquals(true, id.all { it in 'a'..'z' || it in '0'..'9' })
    }

    @Test
    fun `config headers carry the identity language only when set token only when present`() {
        val config = PlexConfig(
            baseUrl = "http://s", token = null, clientIdentifier = "cid", version = "2.26.0", platform = "Android",
            device = "Pixel", deviceName = "Phone", languageCode = " sv ",
        )
        val h = config.headers
        assertEquals("cid", h["X-Plex-Client-Identifier"])
        assertEquals("Plezy", h["X-Plex-Product"])
        assertEquals("Generic", h["X-Plex-Client-Profile-Name"])
        assertEquals("sv", h["X-Plex-Language"])
        assertEquals("sv", h["Accept-Language"])
        assertNull(h["X-Plex-Token"])
        assertEquals("tok", config.copy(token = "tok").headers["X-Plex-Token"])
        assertEquals("sv", config.copy(token = "tok").headers["X-Plex-Language"])
        assertNull(config.copy(languageCode = "  ").headers["X-Plex-Language"])
    }
}

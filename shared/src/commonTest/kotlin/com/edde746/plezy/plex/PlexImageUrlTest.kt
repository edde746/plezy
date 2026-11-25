package com.edde746.plezy.plex

import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * `minSize=1` covers the box and `minSize=0` fits inside it; `upscale=0` returns the native image instead of a
 * server-side enlargement.
 */
class PlexImageUrlTest {
    private val client = testPlexClient({ jsonResponse("{}") })

    @AfterTest
    fun close() = client.close()

    @Test
    fun `slot filling artwork covers the box without server upscaling`() {
        val url = client.thumbnailUrl("/library/metadata/1/thumb/2", width = 400, height = 600)

        assertEquals(
            "$TEST_BASE_URL/photo/:/transcode?width=400&height=600&minSize=1&upscale=0" +
                "&url=%2Flibrary%2Fmetadata%2F1%2Fthumb%2F2%3FX-Plex-Token%3D$TEST_TOKEN&X-Plex-Token=$TEST_TOKEN",
            url,
        )
    }

    @Test
    fun `contain artwork fits inside the requested box`() {
        val url = client.thumbnailUrl("/library/metadata/1/clearLogo", width = 1200, height = 360, cover = false)

        assertTrue("minSize=0" in url)
        assertTrue("upscale=0" in url)
        assertTrue("width=1200" in url)
        assertTrue("height=360" in url)
    }

    @Test
    fun `unsized server paths are the plain tokenized URL`() {
        assertEquals("$TEST_BASE_URL/library/metadata/1/thumb?X-Plex-Token=$TEST_TOKEN", client.thumbnailUrl("/library/metadata/1/thumb"))
        assertEquals("", client.thumbnailUrl(null))
        assertEquals("", client.thumbnailUrl(""))
    }

    @Test
    fun `an absolute image never sends the token to its own host`() {
        assertEquals("https://image.example/a.png", client.thumbnailUrl("https://image.example/a.png"))
        assertEquals(
            "$TEST_BASE_URL/photo/:/transcode?width=200&height=200&minSize=1&upscale=0&url=https%3A%2F%2Fimage.example%2Fa.png&X-Plex-Token=$TEST_TOKEN",
            client.thumbnailUrl("https://image.example/a.png", width = 200, height = 200),
        )
    }

    @Test
    fun `a client without a token never transcodes`() {
        val anonymous = testPlexClient({ jsonResponse("{}") }, token = null)

        assertEquals("$TEST_BASE_URL/library/metadata/1/thumb", anonymous.thumbnailUrl("/library/metadata/1/thumb", width = 100))
        assertEquals("https://epg.example/logo.png", anonymous.externalImageUrl("https://epg.example/logo.png", width = 100))
        anonymous.close()
    }

    @Test
    fun `proxied external images honour the same flags`() {
        val covering = client.externalImageUrl("https://epg.example/logo.png", width = 200, height = 200)
        val fitting = client.externalImageUrl("https://epg.example/logo.png", width = 200, height = 200, cover = false)

        assertEquals(
            "$TEST_BASE_URL/photo/:/transcode?width=200&height=200&minSize=1&upscale=0&url=https%3A%2F%2Fepg.example%2Flogo.png&X-Plex-Token=$TEST_TOKEN",
            covering,
        )
        assertTrue("minSize=0" in fitting)
        assertTrue("upscale=0" in fitting)
        assertEquals("https://epg.example/logo.png", client.externalImageUrl("https://epg.example/logo.png"))
    }
}

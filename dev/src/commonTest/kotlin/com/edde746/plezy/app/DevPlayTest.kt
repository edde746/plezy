package com.edde746.plezy.app

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class DevPlayTest {
    private val plex = ServerId("6f4d1c2b")
    private val jellyfin = ServerId("a1b2c3")
    private val emby = ServerId("e9e9")
    private val servers = listOf(plex to BackendKind.PLEX, jellyfin to BackendKind.JELLYFIN, emby to BackendKind.EMBY)

    @Test
    fun aBackendsNamePicksTheFirstServerOfThatKind() {
        assertEquals(jellyfin, DevPlay("jellyfin", "1").pickServer(servers))
        assertEquals(emby, DevPlay("emby", "1").pickServer(servers))
        assertEquals(plex, DevPlay("plex", "1").pickServer(servers + (ServerId("other") to BackendKind.PLEX)))
        assertNull(DevPlay("emby", "1").pickServer(servers.take(2)))
    }

    @Test
    fun anythingElseIsAServerId() {
        assertEquals(emby, DevPlay("e9e9", "1").pickServer(servers))
        assertNull(DevPlay("missing", "1").pickServer(servers))
    }

    @Test
    fun idsAreDigitsOrThirtyTwoHexDigits() {
        assertTrue(DevPlay.looksLikeId("12345"))
        assertTrue(DevPlay.looksLikeId("0123456789abcdefABCDEF0123456789"))
        assertFalse(DevPlay.looksLikeId("0123456789abcdef0123456789abcde"))
        assertFalse(DevPlay.looksLikeId("Sintel"))
        assertFalse(DevPlay.looksLikeId("Big Buck Bunny 2"))
    }

    @Test
    fun aTitlePicksThePlayableResultOfThatTitle() {
        val show = item("1", MediaKind.SHOW, "Sintel")
        val trailer = item("2", MediaKind.CLIP, "Sintel Trailer")
        val movie = item("3", MediaKind.MOVIE, "sintel")
        assertEquals(movie, DevPlay("plex", "Sintel").pickTitle(listOf(show, trailer, movie)))
        assertEquals(trailer, DevPlay("plex", "Sintel").pickTitle(listOf(show, trailer)))
        assertNull(DevPlay("plex", "Sintel").pickTitle(listOf(show)))
    }

    private fun item(id: String, kind: MediaKind, title: String) = MediaItem(id = id, backend = BackendKind.PLEX, kind = kind, title = title)
}

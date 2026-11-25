package com.edde746.plezy.desktop.linux

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.presentation.player.NowPlaying
import com.edde746.plezy.presentation.player.NowPlayingStatus
import com.sun.net.httpserver.HttpServer
import java.net.InetSocketAddress
import java.util.concurrent.atomic.AtomicInteger
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** Which playbacks MPRIS shows as one track, and how much of an artwork it reads. */
class MprisTrackTest {
    private val requests = AtomicInteger()
    private val server = HttpServer.create(InetSocketAddress("127.0.0.1", 0), 0).apply {
        createContext("/small") { exchange ->
            requests.incrementAndGet()
            exchange.sendResponseHeaders(200, 3)
            exchange.responseBody.use { it.write(byteArrayOf(1, 2, 3)) }
        }
        createContext("/huge") { exchange ->
            requests.incrementAndGet()
            exchange.sendResponseHeaders(200, 0)
            runCatching { exchange.responseBody.use { out -> repeat(1024) { out.write(ByteArray(64 * 1024)) } } }
        }
        start()
    }

    @AfterTest
    fun stop() = server.stop(0)

    private fun url(path: String) = "http://127.0.0.1:${server.address.port}$path"

    private fun playing(id: String?) = NowPlaying(
        title = "Pilot",
        subtitle = "Season 1 Episode 1",
        artworkUrl = null,
        durationSeconds = 1800.0,
        positionSeconds = 0.0,
        rate = 1.0,
        status = NowPlayingStatus.PLAYING,
        canSeek = true,
        canSkipNext = true,
        canSkipPrevious = false,
        live = false,
        item = id?.let { MediaItem(id = it, backend = BackendKind.PLEX, kind = MediaKind.EPISODE) },
    )

    @Test
    fun anotherItemWithTheSameTitleIsANewTrack() {
        assertFalse(sameTrack(playing("1"), playing("2")))
        assertTrue(sameTrack(playing("1"), playing("1").copy(positionSeconds = 30.0)))
        assertTrue(sameTrack(playing(null), playing(null)))
    }

    @Test
    fun anOversizedArtworkIsDropped() {
        assertNull(fetchArtwork(url("/huge"), maxBytes = 1 shl 20) { true })
        assertContentEquals(byteArrayOf(1, 2, 3), fetchArtwork(url("/small")) { true })
    }

    @Test
    fun aSupersededArtworkIsNotFetched() {
        assertNull(fetchArtwork(url("/small")) { false })
        assertEquals(0, requests.get())
    }
}

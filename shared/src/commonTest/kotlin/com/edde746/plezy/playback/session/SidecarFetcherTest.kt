package com.edde746.plezy.playback.session

import com.edde746.plezy.net.PlezyHttpClient
import com.edde746.plezy.playback.resolve.redirect
import io.ktor.client.engine.config
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.MockRequestHandleScope
import io.ktor.client.engine.mock.respond
import io.ktor.client.request.HttpRequestData
import io.ktor.client.request.HttpResponseData
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlinx.io.buffered
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.files.SystemTemporaryDirectory
import kotlinx.io.readString
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.uuid.Uuid

/** A sidecar subtitle's fetch: its redirects keep the stream's credentials on the stream's server, its size is capped. */
class SidecarFetcherTest {
    private val directory = Path(SystemTemporaryDirectory, "plezy-sidecar-test-${Uuid.random()}")
    private val requests = mutableListOf<HttpRequestData>()
    private val stream = "https://plex.example:32400/video/:/transcode/universal/start.m3u8"
    private val headers = mapOf("X-Plex-Token" to "KEY", "X-Plex-Client-Identifier" to "device")

    @AfterTest
    fun cleanUp() {
        if (SystemFileSystem.exists(directory)) SystemFileSystem.list(directory).forEach { SystemFileSystem.delete(it) }
        SystemFileSystem.delete(directory, mustExist = false)
    }

    private fun TestScope.fetcher(answer: suspend MockRequestHandleScope.(HttpRequestData) -> HttpResponseData) = SidecarFetcher(
        PlezyHttpClient.create(
            "test",
            MockEngine.config {
                dispatcher = StandardTestDispatcher(testScheduler)
                addHandler { request ->
                    requests += request
                    answer(request)
                }
            },
        ),
        directory,
        SystemFileSystem,
        StandardTestDispatcher(testScheduler),
    )

    @Test
    fun aSubtitleRedirectedToAnotherHostIsFetchedWithoutTheToken() = runTest {
        val subtitle = "1\n00:00:01,000 --> 00:00:02,000\nHello\n"
        val sidecars = fetcher { request ->
            if (request.url.host == "plex.example") redirect("https://subtitles.example/s.srt") else respond(subtitle)
        }

        val file = assertNotNull(sidecars.fetch("https://plex.example:32400/library/streams/7.srt", stream, headers))

        assertEquals(subtitle, SystemFileSystem.source(Path(file)).buffered().use { it.readString() })
        val (first, moved) = requests
        assertEquals("KEY", first.headers["X-Plex-Token"])
        assertEquals("subtitles.example", moved.url.host)
        assertNull(moved.headers["X-Plex-Token"])
    }

    @Test
    fun aSubtitleRedirectedOnTheStreamsServerKeepsTheToken() = runTest {
        val sidecars = fetcher { request -> if (request.url.encodedPath == "/old.srt") redirect("/new.srt") else respond("x") }

        assertNotNull(sidecars.fetch("https://plex.example:32400/old.srt", stream, headers))

        assertEquals(listOf("KEY", "KEY"), requests.map { it.headers["X-Plex-Token"] })
    }

    @Test
    fun aRedirectLoopEndsTheFetch() = runTest {
        val sidecars = fetcher { redirect("https://plex.example:32400/loop.srt") }

        assertNull(sidecars.fetch("https://plex.example:32400/loop.srt", stream, headers))
        assertEquals(11, requests.size, "the link and ten redirects")
    }

    @Test
    fun aSubtitleOverTheCapIsLeftOut() = runTest {
        val sidecars = fetcher { respond(ByteArray(32 * 1024 * 1024 + 1)) }

        assertNull(sidecars.fetch("https://plex.example:32400/huge.ass", stream, headers))
    }
}

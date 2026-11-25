package com.edde746.plezy.net

import com.edde746.plezy.playback.resolve.redirect
import io.ktor.client.HttpClient
import io.ktor.client.engine.config
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.respond
import io.ktor.client.request.HttpRequestData
import io.ktor.client.request.get
import io.ktor.client.request.header
import io.ktor.client.statement.bodyAsText
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/** A server's token stays on the server: the app's client drops it from every redirect hop to another origin. */
class CrossOriginCredentialsTest {
    private val requests = mutableListOf<HttpRequestData>()

    private fun client(answer: (HttpRequestData) -> String?): HttpClient = PlezyHttpClient.create(
        "test",
        MockEngine.config {
            addHandler { request ->
                requests += request
                answer(request)?.let { redirect(it) } ?: respond("ok")
            }
        },
    )

    private suspend fun get(client: HttpClient, url: String, headers: Map<String, String>): String =
        client.get(url) { for ((name, value) in headers) header(name, value) }.bodyAsText()

    @Test
    fun aPlexRedirectToAnotherHostGoesWithoutTheToken() = runTest {
        val http = client { if (it.url.host == "plex.example") "https://cdn.example/library/sections" else null }

        assertEquals("ok", get(http, "https://plex.example:32400/library/sections", mapOf("X-Plex-Token" to "KEY", "X-Plex-Product" to "Plezy")))

        val (first, moved) = requests
        assertEquals("KEY", first.headers["X-Plex-Token"])
        assertEquals("cdn.example", moved.url.host)
        assertNull(moved.headers["X-Plex-Token"])
        assertEquals("Plezy", moved.headers["X-Plex-Product"], "headers that carry no credential still go")
    }

    @Test
    fun aJellyfinRedirectToAnotherPortGoesWithoutItsCredentials() = runTest {
        val credentials = mapOf(
            "X-Emby-Token" to "KEY",
            "Authorization" to "MediaBrowser Token=\"KEY\"",
            "X-Emby-Authorization" to "MediaBrowser Token=\"KEY\"",
            "X-MediaBrowser-Token" to "KEY",
            "Cookie" to "session=KEY",
            "Proxy-Authorization" to "Basic KEY",
        )
        val http = client { if (it.url.port == 8096) "http://jellyfin.example:8920/Users" else null }

        get(http, "http://jellyfin.example:8096/Users", credentials)

        val moved = requests.last()
        assertEquals(8920, moved.url.port)
        for (name in credentials.keys) assertNull(moved.headers[name], name)
    }

    @Test
    fun onceDroppedTheCredentialsStayDroppedOnTheWayBack() = runTest {
        val http = client {
            when {
                it.url.host == "elsewhere.example" -> "https://plex.example/back"
                it.url.encodedPath == "/start" -> "https://elsewhere.example/hop"
                else -> null
            }
        }

        get(http, "https://plex.example/start", mapOf("X-Plex-Token" to "KEY"))

        assertEquals(listOf("KEY", null, null), requests.map { it.headers["X-Plex-Token"] })
    }

    @Test
    fun aRedirectOnTheSameOriginKeepsTheCredentials() = runTest {
        val http = client { if (it.url.encodedPath == "/old") "/new" else null }

        get(http, "https://plex.example:32400/old", mapOf("X-Plex-Token" to "KEY", "Authorization" to "Bearer KEY"))

        val moved = requests.last()
        assertEquals("/new", moved.url.encodedPath)
        assertEquals("KEY", moved.headers["X-Plex-Token"])
        assertEquals("Bearer KEY", moved.headers["Authorization"])
    }
}

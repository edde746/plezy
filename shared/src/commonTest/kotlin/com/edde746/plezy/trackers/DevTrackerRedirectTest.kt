package com.edde746.plezy.trackers

import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.respondOk
import io.ktor.client.request.get
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class DevTrackerRedirectTest {
    private suspend fun sent(url: String): String {
        var seen = ""
        val client = HttpClient(MockEngine { request ->
            seen = request.url.toString()
            respondOk()
        }) { install(devTrackerRedirect("http://10.0.2.2:28100")) }
        client.use { it.get(url) }
        return seen
    }

    @Test
    fun eachServiceHostGoesToTheFakeUnderItsPrefix() = runTest {
        val cases = mapOf(
            "https://api.trakt.tv/sync/history?extended=full" to "http://10.0.2.2:28100/sync/history?extended=full",
            "https://api.simkl.com/sync/history?client_id=x" to "http://10.0.2.2:28100/simkl/sync/history?client_id=x",
            "https://data.simkl.in/discover/trending/movies/week_100.json" to
                "http://10.0.2.2:28100/simkl/discover/trending/movies/week_100.json",
            "https://api.mdblist.com/imdb/movie/tt9900001" to "http://10.0.2.2:28100/mdblist/imdb/movie/tt9900001",
            "https://api.myanimelist.net/v2/anime/21?fields=mean" to "http://10.0.2.2:28100/mal/v2/anime/21?fields=mean",
            "https://myanimelist.net/v1/oauth2/token" to "http://10.0.2.2:28100/mal/v1/oauth2/token",
            "https://graphql.anilist.co" to "http://10.0.2.2:28100/anilist",
            "https://anilist.co/api/v2/oauth/token" to "http://10.0.2.2:28100/anilist/api/v2/oauth/token",
            "https://ice.plezy.app/auth/result?session=s" to "http://10.0.2.2:28100/relay/auth/result?session=s",
        )
        for ((url, expected) in cases) assertEquals(expected, sent(url), url)
    }

    @Test
    fun otherHostsPass() = runTest {
        assertEquals("https://plex.tv/api/v2/user", sent("https://plex.tv/api/v2/user"))
        assertEquals("https://trakt.tv/activate", sent("https://trakt.tv/activate"))
    }

    @Test
    fun aServiceUrlMapsToTheFake() {
        assertEquals("http://h:1/base/relay/auth/start", devTrackerUrl("http://h:1/base/", "https://ice.plezy.app/auth/start"))
        assertFailsWith<IllegalArgumentException> { devTrackerUrl("http://h:1", "https://example.com/x") }
    }
}

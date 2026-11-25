package com.edde746.plezy.plex

import io.ktor.client.request.HttpRequestData
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class PlexSearchTest {
    private fun row(ratingKey: String, type: String, title: String, extra: String = "") =
        """{"score":90,"Metadata":{"ratingKey":"$ratingKey","type":"$type","title":"$title"$extra}}"""

    private fun results(rows: List<String>) = """{"MediaContainer":{"SearchResult":[${rows.joinToString(",")}]}}"""

    @Test
    fun `search defaults to 100 movie TV music and personal media candidates`() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ request ->
            requests += request
            jsonResponse(results(listOf(row("movie-1", "movie", "The Movie"))))
        })

        val items = client.searchItems("the")

        assertEquals(listOf("movie-1"), items.map { it.id })
        val params = requests.single().url.parameters
        assertEquals("/library/search", requests.single().url.encodedPath)
        assertEquals("100", params["limit"])
        assertEquals("100", params["X-Plex-Container-Size"])
        assertEquals("movies,tv,music,otherVideos", params["searchTypes"])
        assertEquals("1", params["includeCollections"])
        assertEquals("1", params["includeExternalMedia"])
        client.close()
    }

    @Test
    fun `personal media rows are kept as movies`() = runTest {
        val client = testPlexClient({
            jsonResponse(results(listOf(row("8964", "movie", "2004 Family", ""","guid":"tv.plex.agents.none://8964","subtype":"clip""""))))
        })

        assertEquals(listOf("8964"), client.searchItems("2004").map { it.id })
        client.close()
    }

    @Test
    fun `search rows carry their library so hidden libraries can be filtered`() = runTest {
        val client = testPlexClient({
            jsonResponse(
                results(
                    listOf(
                        row("movie-1", "movie", "The Movie", ""","librarySectionID":2,"librarySectionTitle":"Movies""""),
                        row("show-1", "show", "The Show", ""","librarySectionKey":"/library/sections/7""""),
                        row("shared-1", "movie", "The Shared Movie"),
                    ),
                ),
            )
        })

        val items = client.searchItems("the")

        assertEquals(listOf("movie-1", "show-1", "shared-1"), items.map { it.id })
        assertEquals(listOf("2", "7", null), items.map { it.libraryId })
        assertEquals(listOf("$TEST_SERVER_ID:2", "$TEST_SERVER_ID:7", null), items.map { it.libraryGlobalKey })
        client.close()
    }

    @Test
    fun `a saturated mixed search supplements omitted categories and deduplicates`() = runTest {
        val searched = mutableListOf<String?>()
        val primary = List(99) { row("movie-$it", "movie", "Target Movie $it") } + row("collection-1", "collection", "Target Collection")
        val client = testPlexClient({ request ->
            val types = request.url.parameters["searchTypes"]
            searched += types
            val rows = when (types) {
                "movies,tv,music,otherVideos" -> primary
                "tv" -> listOf(row("show-1", "show", "Target"), row("movie-0", "movie", "Target Movie 0"))
                "music" -> listOf(row("artist-1", "artist", "Target"))
                "otherVideos" -> listOf(row("home-1", "movie", "Target Home Video", ""","guid":"tv.plex.agents.none://home-1""""))
                else -> emptyList()
            }
            jsonResponse(results(rows))
        })

        val ids = client.searchItems("Target").map { it.id }

        assertEquals(setOf("movies,tv,music,otherVideos", "tv", "music", "otherVideos"), searched.toSet())
        assertEquals(1, ids.count { it == "movie-0" })
        assertTrue(ids.containsAll(listOf("show-1", "artist-1", "home-1")))
        assertEquals(102, ids.size)
        client.close()
    }

    @Test
    fun `saturated personal media results still fetch the movies category`() = runTest {
        val searched = mutableListOf<String?>()
        val client = testPlexClient({ request ->
            val types = request.url.parameters["searchTypes"]
            searched += types
            val rows = when (types) {
                "movies,tv,music,otherVideos" -> List(100) {
                    row("home-$it", "movie", "Target Clip $it", ""","guid":"tv.plex.agents.none://home-$it"""")
                }
                "movies" -> listOf(row("movie-1", "movie", "Target", ""","guid":"plex://movie/1""""))
                else -> emptyList()
            }
            jsonResponse(results(rows))
        })

        val items = client.searchItems("Target")

        assertEquals(setOf("movies,tv,music,otherVideos", "movies", "tv", "music"), searched.toSet())
        assertTrue(items.any { it.id == "movie-1" })
        assertEquals(101, items.size)
        client.close()
    }

    @Test
    fun `a supplemental category failure keeps the saturated primary results`() = runTest {
        val searched = mutableListOf<String?>()
        val primary = List(99) { row("movie-$it", "movie", "Target Movie $it") } + row("artist-1", "artist", "Target Artist")
        val client = testPlexClient({ request ->
            val types = request.url.parameters["searchTypes"]
            searched += types
            if (types == "movies,tv,music,otherVideos") jsonResponse(results(primary)) else jsonResponse("temporary failure", 500)
        })

        val items = client.searchItems("Target")

        assertEquals(setOf("movies,tv,music,otherVideos", "tv", "otherVideos"), searched.toSet())
        assertEquals(3, searched.size)
        assertEquals(100, items.size)
        assertTrue(items.map { it.id }.containsAll(listOf("movie-0", "artist-1")))
        client.close()
    }
}

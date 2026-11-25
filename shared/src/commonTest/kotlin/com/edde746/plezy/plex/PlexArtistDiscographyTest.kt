package com.edde746.plezy.plex

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.DiscographyGroupKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import io.ktor.client.request.HttpRequestData
import io.ktor.http.decodeURLPart
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

/** An artist's albums (every release bucket, not only `/children`'s) and their grouping by release format. */
class PlexArtistDiscographyTest {
    private val store = MemoryApiCacheStore()
    private val requests = mutableListOf<HttpRequestData>()

    private fun artist(libraryId: String? = "7") =
        MediaItem(id = "artist-1", backend = BackendKind.PLEX, kind = MediaKind.ARTIST, serverId = TEST_SERVER_ID, libraryId = libraryId)

    private fun album(id: String, tags: String = "") = """{"ratingKey":"$id","type":"album","title":"$id"$tags}"""

    private fun listing(vararg albums: String) =
        """{"MediaContainer":{"librarySectionID":7,"size":${albums.size},"totalSize":${albums.size},"Metadata":[${albums.joinToString(",")}]}}"""

    private suspend fun cachedIds(key: String) =
        store.get(testProfileScope.value, key)!!["MediaContainer"]!!.jsonObject["Metadata"]!!.jsonArray.map { it.jsonObject["ratingKey"]!!.jsonPrimitive.content }

    private val HttpRequestData.path get() = url.encodedPath

    private fun HttpRequestData.param(name: String) = url.parameters[name]

    @Test
    fun artistAlbumsIncludeEveryReleaseBucketAndCacheAllPages() = runTest {
        val client = testPlexClient({ request ->
            requests += request
            val metadata = if (request.param("X-Plex-Container-Start") == "0") "${album("album-lp")},${album("album-ep")}" else "${album("album-single")},${album("album-compilation")}"
            jsonResponse("""{"MediaContainer":{"librarySectionID":7,"size":2,"totalSize":4,"Metadata":[$metadata]}}""")
        }, store)

        val albums = client.fetchArtistAlbums(artist())

        val all = listOf("album-lp", "album-ep", "album-single", "album-compilation")
        assertEquals(all, albums.map { it.id })
        assertEquals(listOf("0", "2"), requests.map { it.param("X-Plex-Container-Start") })
        for (request in requests) {
            assertEquals("/library/sections/7/all", request.path)
            assertEquals("9", request.param("type"))
            assertEquals("artist-1", request.param("artist.id"))
            assertEquals("album.year:desc", request.param("sort"))
        }
        assertEquals(all, cachedIds("/library/metadata/artist-1/children"))
        client.close()
    }

    @Test
    fun artistAlbumsResolveAMissingMusicSectionFromTheArtistsMetadata() = runTest {
        val client = testPlexClient({ request ->
            requests += request
            when (request.path) {
                "/library/metadata/artist-1" ->
                    jsonResponse("""{"MediaContainer":{"librarySectionID":7,"Metadata":[{"ratingKey":"artist-1","type":"artist","title":"Artist"}]}}""")
                "/library/sections/7/all" -> jsonResponse(listing(album("album-1")))
                else -> jsonResponse("not found", 404)
            }
        }, store)

        val albums = client.fetchArtistAlbums(artist(libraryId = null))

        assertEquals(listOf("/library/metadata/artist-1", "/library/sections/7/all"), requests.map { it.path })
        assertEquals(listOf("album-1"), albums.map { it.id })
        client.close()
    }

    @Test
    fun anArtistWithoutAnySectionFails() = runTest {
        val client = testPlexClient({ jsonResponse("""{"MediaContainer":{"Metadata":[{"ratingKey":"artist-1","type":"artist","title":"Artist"}]}}""") }, store)

        assertFailsWith<IllegalStateException> { client.fetchArtistAlbums(artist(libraryId = null)) }
        client.close()
    }

    @Test
    fun theDiscographyFetchesTagsInOneBatchAndGroupsEachAlbum() = runTest {
        val ids = listOf("album-1", "album-2", "album-ep", "album-live", "album-comp")
        val client = testPlexClient({ request ->
            requests += request
            if (request.path == "/library/sections/7/all") {
                jsonResponse(listing(*ids.map { album(it) }.toTypedArray()))
            } else {
                // Only rows read by id carry Format and Subformat. The EP is also tagged live (singles win), and the
                // tags' case varies.
                jsonResponse(
                    listing(
                        album("album-1"),
                        album("album-2"),
                        album("album-ep", ""","Format":[{"tag":"EP"}],"Subformat":[{"tag":"Live"}]"""),
                        album("album-live", ""","Subformat":[{"tag":"Live"}]"""),
                        album("album-comp", ""","Subformat":[{"tag":"compilation"}]"""),
                    ),
                )
            }
        }, store)

        val groups = client.fetchArtistDiscography(artist())

        assertEquals(2, requests.size)
        assertEquals("/library/sections/7/all", requests[0].path)
        assertEquals("/library/metadata/${ids.joinToString(",")}", requests[1].path.decodeURLPart())
        assertEquals("0", requests[1].param("X-Plex-Container-Start"))
        assertEquals("5", requests[1].param("X-Plex-Container-Size"))
        assertEquals(
            listOf(DiscographyGroupKind.ALBUMS, DiscographyGroupKind.SINGLES_AND_EPS, DiscographyGroupKind.LIVE, DiscographyGroupKind.COMPILATIONS),
            groups.map { it.kind },
        )
        assertEquals(listOf(listOf("album-1", "album-2"), listOf("album-ep"), listOf("album-live"), listOf("album-comp")), groups.map { group -> group.items.map { it.id } })
        assertEquals(ids, cachedIds("/library/metadata/artist-1/children"))
        assertEquals(ids, cachedIds("/library/metadata/artist-1/discography-tags/0"))
        client.close()
    }

    @Test
    fun aFailedTagBatchLeavesOneFlatAlbumsGroup() = runTest {
        val client = testPlexClient({ request ->
            requests += request
            if (request.path == "/library/sections/7/all") jsonResponse(listing(album("album-1"), album("album-2"))) else jsonResponse("boom", 500)
        }, store)

        val groups = client.fetchArtistDiscography(artist())

        assertEquals(listOf(DiscographyGroupKind.ALBUMS), groups.map { it.kind })
        assertEquals(listOf("album-1", "album-2"), groups.single().items.map { it.id })
        client.close()
    }

    @Test
    fun aSingleAlbumArtistSkipsTheTagBatch() = runTest {
        val client = testPlexClient({ request ->
            requests += request
            jsonResponse(listing(album("album-1")))
        }, store)

        val groups = client.fetchArtistDiscography(artist())

        assertEquals(listOf("/library/sections/7/all"), requests.map { it.path })
        assertEquals(listOf(DiscographyGroupKind.ALBUMS), groups.map { it.kind })
        assertEquals(listOf("album-1"), groups.single().items.map { it.id })
        client.close()
    }
}

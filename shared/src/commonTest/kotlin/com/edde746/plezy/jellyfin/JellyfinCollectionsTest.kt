package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.test.runTest

class JellyfinCollectionsTest {
    private fun item(id: String) = MediaItem(id, BackendKind.JELLYFIN, MediaKind.MOVIE)

    @Test
    fun collectionsPageQueriesServerWideBoxSets() = runTest {
        val server = JellyfinTestServer { FakeResponse(body = """{"TotalRecordCount":1,"Items":[{"Id":"collection-1","Name":"Collection 1","Type":"BoxSet"}]}""") }
        val page = JellyfinCollections(server.core()).fetchCollectionsPage("lib-movies")
        assertEquals(listOf("collection-1"), page.items.map { it.id })
        assertEquals(MediaKind.COLLECTION, page.items.single().kind)
        assertEquals(listOf("/Items"), server.requests.map { it.path })
        assertEquals(
            mapOf(
                "userId" to "user-1",
                "IncludeItemTypes" to "BoxSet",
                "Recursive" to "true",
                "StartIndex" to "0",
                "Limit" to "36",
                "SortBy" to "SortName",
                "SortOrder" to "Ascending",
                "Fields" to "RecursiveItemCount,ChildCount,OriginalTitle,SortName,Overview,DateCreated,CanDelete",
                "EnableImageTypes" to "Primary,Backdrop,Logo",
                "ImageTypeLimit" to "3",
            ),
            server.single("/Items").query,
        )
    }

    @Test
    fun collectionsPageUsesRequestedBounds() = runTest {
        val server = JellyfinTestServer { FakeResponse(body = """{"TotalRecordCount":30,"Items":[{"Id":"collection-20","Type":"BoxSet"}]}""") }
        val page = JellyfinCollections(server.core()).fetchCollectionsPage("lib-movies", start = 20, size = 10)
        assertEquals(30, page.totalCount)
        assertEquals(20, page.offset)
        val query = server.single("/Items").query
        assertFalse("ParentId" in query)
        assertEquals("20", query["StartIndex"])
        assertEquals("10", query["Limit"])
    }

    @Test
    fun collectionsPageUsesSentinelTotalWhenMissing() = runTest {
        val server = JellyfinTestServer { FakeResponse(body = """{"Items":[{"Id":"c1","Type":"BoxSet"},{"Id":"c2","Type":"BoxSet"}]}""") }
        val page = JellyfinCollections(server.core()).fetchCollectionsPage("lib-movies", size = 2)
        assertEquals(listOf("c1", "c2"), page.items.map { it.id })
        assertEquals(3, page.totalCount)
    }

    @Test
    fun collectionPageUsesItemPaging() = runTest {
        val server = JellyfinTestServer { FakeResponse(body = """{"TotalRecordCount":25,"Items":[{"Id":"movie-1","Type":"Movie"}]}""") }
        val page = JellyfinCollections(server.core()).fetchCollectionPage("collection-1", start = 20, size = 5)
        assertEquals(25, page.totalCount)
        assertEquals(20, page.offset)
        val query = server.single("/Items").query
        assertEquals("collection-1", query["ParentId"])
        assertEquals("20", query["StartIndex"])
        assertEquals("5", query["Limit"])
        assertFalse("Recursive" in query)
    }

    @Test
    fun membershipsIntersectEveryBoxSetsChildren() = runTest {
        val server = JellyfinTestServer { req ->
            when (req.query["ParentId"]) {
                null -> FakeResponse(body = """{"TotalRecordCount":2,"Items":[{"Id":"bs-1","Type":"BoxSet"},{"Id":"bs-2","Type":"BoxSet"}]}""")
                "bs-1" -> FakeResponse(body = """{"Items":[{"Id":"b"},{"Id":"x"},{"Id":"a"}]}""")
                else -> FakeResponse(body = """{"Items":[{"Id":"y"}]}""")
            }
        }
        val memberships = JellyfinCollections(server.core()).fetchCollectionMemberships(setOf("a", "b"))
        assertEquals(listOf("bs-1"), memberships.map { it.collection.id })
        assertEquals(listOf("b", "a"), memberships.single().memberIds)
        assertEquals("200", server.requests.first().query["Limit"])
        assertEquals(
            mapOf("userId" to "user-1", "ParentId" to "bs-1", "EnableImages" to "false", "EnableUserData" to "false", "EnableTotalRecordCount" to "false"),
            server.requests[1].query,
        )
    }

    @Test
    fun membershipsOfNothingMakeNoRequest() = runTest {
        val server = JellyfinTestServer()
        assertEquals(emptyList(), JellyfinCollections(server.core()).fetchCollectionMemberships(emptySet()))
        assertEquals(emptyList(), server.requests)
    }

    @Test
    fun createReturnsIdNullOrThrows() = runTest {
        val valid = JellyfinTestServer { FakeResponse(body = """{"Id":"collection-1"}""") }
        assertEquals("collection-1", JellyfinCollections(valid.core()).createCollection("library-1", "Collection", listOf(item("a"), item("b"))))
        assertEquals(mapOf("Name" to "Collection", "Ids" to "a,b", "ParentId" to "library-1"), valid.single("/Collections").query)

        val unusable = JellyfinTestServer { FakeResponse(body = "{}") }
        assertNull(JellyfinCollections(unusable.core()).createCollection("", "Collection", emptyList()))
        assertEquals(mapOf("Name" to "Collection"), unusable.single("/Collections").query)

        for (status in listOf(400, 500)) {
            val error = assertFailsWith<MediaServerHttpException> {
                JellyfinCollections(JellyfinTestServer { FakeResponse(status, "{}") }.core()).createCollection("library-1", "Collection", emptyList())
            }
            assertEquals(status, error.statusCode)
        }
    }

    @Test
    fun writeRoutes() = runTest {
        val server = JellyfinTestServer { FakeResponse(204, "") }
        val collections = JellyfinCollections(server.core())
        assertTrue(collections.addToCollection("c 1", emptyList()))
        assertTrue(collections.addToCollection("c 1", listOf(item("a"), item("b"))))
        assertTrue(collections.removeFromCollection("c 1", item("a")))
        assertTrue(collections.deleteCollection(item("c 1")))
        assertEquals(
            listOf("POST /Collections/c%201/Items Ids=a,b", "DELETE /Collections/c%201/Items Ids=a", "DELETE /Items/c%201 "),
            server.requests.map { "${it.method} ${it.path} ${it.query.entries.joinToString("&") { (k, v) -> "$k=$v" }}" },
        )
    }
}

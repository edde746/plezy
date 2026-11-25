package com.edde746.plezy.plex

import com.edde746.plezy.model.CollectionMembership
import com.edde746.plezy.model.MediaKind
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFails

class PlexCollectionMembershipsTest {
    private fun container(metadata: List<String>, totalSize: Int? = null) =
        """{"MediaContainer":{"size":${metadata.size}${totalSize?.let { ",\"totalSize\":$it" } ?: ""},"Metadata":[${metadata.joinToString(",")}]}}"""

    private fun title(id: String, library: Int, tags: List<Int> = emptyList(), released: String? = null) =
        """{"ratingKey":"$id","type":"movie","title":"Title $id","librarySectionID":$library""" +
            (released?.let { ""","originallyAvailableAt":"$it"""" } ?: "") +
            ""","Collection":[${tags.joinToString(",") { """{"id":$it,"tag":"tag text $it"}""" }}]}"""

    private fun collection(id: String, index: Int, title: String? = null, extra: String = "") =
        """{"ratingKey":"$id","type":"collection","title":"${title ?: "Collection $id"}","index":$index$extra}"""

    private fun ids(memberships: List<CollectionMembership>) = memberships.map { "${it.collection.id}:${it.memberIds.joinToString(",")}" }

    @Test
    fun matchesCollectionsByTagIdAndOrdersMembersByReleaseDateOrTitle() = runTest {
        val client = testPlexClient({ request ->
            when (request.url.encodedPath) {
                "/library/metadata/m1,m2,m3,m4" -> jsonResponse(
                    container(
                        listOf(
                            title("m1", 1, listOf(11, 12), "2024-03-01"),
                            title("m2", 1, listOf(11), "2021-10-22"),
                            title("m3", 1, listOf(12, 13, 14), "1999-01-01"),
                            title("m4", 1),
                        ),
                    ),
                )
                "/library/sections/1/collections" -> jsonResponse(
                    container(
                        listOf(
                            collection("c-dune", 11, "dune"),
                            collection("c-alpha", 12, extra = ""","collectionSort":"1""""),
                            collection("c-smart", 13, extra = ""","smart":"1""""),
                            collection("c-hidden", 14, extra = ""","collectionMode":"0""""),
                            collection("c-unrelated", 99),
                        ),
                        totalSize = 5,
                    ),
                )
                else -> jsonResponse("not found", 404)
            }
        })

        val memberships = client.fetchCollectionMemberships(setOf("m1", "m2", "m3", "m4"))

        assertEquals(listOf("c-dune:m2,m1", "c-alpha:m1,m3"), ids(memberships))
        assertEquals(MediaKind.COLLECTION, memberships.first().collection.kind)
        assertEquals("dune", memberships.first().collection.title)
    }

    @Test
    fun readsACustomOrderedCollectionsChildrenForItsOrder() = runTest {
        val client = testPlexClient({ request ->
            when (request.url.encodedPath) {
                "/library/metadata/a,b" -> jsonResponse(container(listOf(title("a", 2, listOf(5), "1977-05-25"), title("b", 2, listOf(5), "1999-05-19"))))
                "/library/sections/2/collections" -> jsonResponse(container(listOf(collection("saga", 5, extra = ""","collectionSort":"2"""")), totalSize = 1))
                "/library/collections/saga/children" -> jsonResponse(
                    container(
                        listOf(
                            """{"ratingKey":"not-downloaded","type":"movie","title":"Other"}""",
                            """{"ratingKey":"b","type":"movie","title":"Episode I"}""",
                            """{"ratingKey":"a","type":"movie","title":"Episode IV"}""",
                        ),
                        totalSize = 3,
                    ),
                )
                else -> jsonResponse("not found", 404)
            }
        })

        assertEquals(listOf("saga:b,a"), ids(client.fetchCollectionMemberships(setOf("a", "b"))))
    }

    @Test
    fun aFailedCollectionListingFailsTheLookupInsteadOfAnsweringPartially() = runTest {
        val client = testPlexClient({ request ->
            when (request.url.encodedPath) {
                "/library/metadata/x" -> jsonResponse(container(listOf(title("x", 3, listOf(1)))))
                else -> jsonResponse("error", 500)
            }
        })

        assertFails { client.fetchCollectionMemberships(setOf("x")) }
    }

    @Test
    fun aCollectionOnTheSecondPageIsFoundWhenOnlyTheHeaderCarriesTheTotal() = runTest {
        val client = testPlexClient({ request ->
            when (request.url.encodedPath) {
                "/library/metadata/m1" -> jsonResponse(container(listOf(title("m1", 1, listOf(500)))))
                "/library/sections/1/collections" -> {
                    val page = if (request.url.parameters["X-Plex-Container-Start"] == "0") {
                        (0 until 200).map { collection("c$it", it) }
                    } else {
                        listOf(collection("late", 500))
                    }
                    jsonResponse(container(page), headers = mapOf("X-Plex-Container-Total-Size" to "201"))
                }
                else -> jsonResponse("not found", 404)
            }
        })

        assertEquals(listOf("late:m1"), ids(client.fetchCollectionMemberships(setOf("m1"))))
    }
}

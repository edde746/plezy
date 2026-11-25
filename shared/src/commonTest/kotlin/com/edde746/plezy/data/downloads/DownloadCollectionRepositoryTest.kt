package com.edde746.plezy.data.downloads

import com.edde746.plezy.data.db.Download_collections
import com.edde746.plezy.data.testData
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class DownloadCollectionRepositoryTest {
    private val data = testData()
    private val collections = data.downloadCollections

    @AfterTest
    fun close() = data.close()

    @Test
    fun aRefreshReplacesTheServersCollectionsAndARemovedProfilesGo() = runTest {
        for (profileId in listOf("p1", "p2")) {
            collections.replace(profileId, "srv", mapOf("dune" to listOf("dune-1", "dune-2")), setOf("dune-2", "dune-1", "other"), syncedAt = 42)
        }
        collections.replace("p1", "srv2", mapOf("alien" to listOf("alien-1")), setOf("alien-1"), syncedAt = 40)
        assertEquals(
            listOf(StoredDownloadCollection("srv", "dune", listOf("dune-1", "dune-2")), StoredDownloadCollection("srv2", "alien", listOf("alien-1"))),
            collections.collections("p1"),
        )
        assertEquals(DownloadCollectionSync(42, setOf("dune-1", "dune-2", "other")), collections.sync("p1", "srv"))

        collections.replace("p1", "srv", emptyMap(), setOf("other"), syncedAt = 43)
        assertEquals(listOf("alien"), collections.collections("p1").map { it.collectionId }, "only that server's were replaced")
        assertEquals(DownloadCollectionSync(43, setOf("other")), collections.sync("p1", "srv"))

        collections.deleteForProfile("p2")
        assertEquals(emptyList(), collections.collections("p2"))
        assertNull(collections.sync("p2", "srv"))
        assertEquals(1, collections.collections("p1").size)

        collections.clearAll()
        assertEquals(emptyList(), collections.collections("p1"))
        assertNull(collections.sync("p1", "srv2"))
    }

    @Test
    fun aRowWhoseMembersDontDecodeIsLeftOut() = runTest {
        collections.replace("p1", "srv", mapOf("good" to listOf("1")), emptySet(), syncedAt = 1)
        data.db.write {
            q.syncRuleQueries.insertCollectionRow(Download_collections("p1", "srv", "broken", "not json"))
            q.syncRuleQueries.insertCollectionRow(Download_collections("p1", "srv", "object", "{}"))
            q.syncRuleQueries.insertCollectionRow(Download_collections("p1", "srv", "numbers", "[7, \"8\"]"))
        }
        assertEquals(
            listOf(StoredDownloadCollection("srv", "good", listOf("1")), StoredDownloadCollection("srv", "numbers", listOf("7", "8"))),
            collections.collections("p1"),
        )
        assertEquals(emptyList(), collections.collections(""))
    }
}

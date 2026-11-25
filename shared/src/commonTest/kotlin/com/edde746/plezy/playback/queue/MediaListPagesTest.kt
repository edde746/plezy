package com.edde746.plezy.playback.queue

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.MediaItem
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlinx.coroutines.test.runTest

class MediaListPagesTest {
    private class ListBackend(private val listed: List<MediaItem>, private val reportedTotal: Int) : FakeMediaBackend("s1") {
        val pages = mutableListOf<String>()
        var library: Pair<String?, String?>? = null

        override suspend fun fetchPlaylistPage(id: String, start: Int?, size: Int?): LibraryPage<MediaItem> {
            pages += "$id@$start+$size"
            return page(start, size)
        }

        override suspend fun fetchCollectionPage(collectionId: String, start: Int?, size: Int?, libraryId: String?, libraryTitle: String?): LibraryPage<MediaItem> {
            pages += "$collectionId@$start+$size"
            library = libraryId to libraryTitle
            return page(start, size)
        }

        private fun page(start: Int?, size: Int?): LibraryPage<MediaItem> {
            val offset = start ?: 0
            return LibraryPage(listed.drop(offset).take(size ?: listed.size), reportedTotal, offset)
        }
    }

    private fun items(count: Int) = List(count) { jfMovie("m$it") }

    @Test
    fun playlistsAreReadInPagesOf200UntilDrained() = runTest {
        val backend = ListBackend(items(401), reportedTotal = 401)

        val all = backend.fetchAllPlaylistItems("pl")

        assertEquals(401, all.size)
        assertEquals(listOf("pl@0+200", "pl@200+200", "pl@400+200"), backend.pages)
    }

    @Test
    fun collectionsAreReadInPagesOf100UpToAShortPage() = runTest {
        // The server overstates its total; the short page ends the read.
        val backend = ListBackend(items(150), reportedTotal = 1_000)

        val all = backend.fetchAllCollectionItems("c", libraryId = "3", libraryTitle = "Films")

        assertEquals(150, all.size)
        assertEquals(listOf("c@0+100", "c@100+100"), backend.pages)
        assertEquals("3" to "Films", backend.library)
    }
}

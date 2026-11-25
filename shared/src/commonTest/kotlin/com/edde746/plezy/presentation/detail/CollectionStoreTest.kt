package com.edde746.plezy.presentation.detail

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.playback.queue.PlayQueueLaunch
import com.edde746.plezy.playback.queue.PlayQueueResult
import com.edde746.plezy.presentation.browse.CardOptions
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.downloads.DownloadFeedback
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class CollectionStoreTest {
    private val changes = MutableSharedFlow<Any?>(extraBufferCapacity = 1)
    private val launches = mutableListOf<Pair<String, Boolean>>()
    private var members = (1..3).map { movie("m$it", 2000 + it) }
    private val gates = mutableMapOf<Int, CompletableDeferred<Unit>>()

    private fun movie(id: String, year: Int) = MediaItem(id = id, backend = BackendKind.PLEX, kind = MediaKind.MOVIE, title = id, year = year)

    private inner class Backend : FakeMediaBackend("srv") {
        override suspend fun fetchCollectionPage(collectionId: String, start: Int?, size: Int?, libraryId: String?, libraryTitle: String?): LibraryPage<MediaItem> {
            gates[start ?: 0]?.await()
            val from = start ?: 0
            val page = members.drop(from).take(2)
            return LibraryPage(page, members.size, from)
        }
    }

    private fun TestScope.store(): CollectionStore {
        val backend = Backend().apply { items = { MediaItem(id = it, backend = BackendKind.PLEX, kind = MediaKind.COLLECTION, title = "Box", childCount = 3) } }
        return CollectionStore(
            Route.CollectionDetail(ServerId("srv"), "c"),
            backend,
            { CardOptions() },
            { collection, shuffle ->
                launches += collection.id to shuffle
                PlayQueueLaunch("Shuffle", backgroundScope) { PlayQueueResult.Success }
            },
            changes,
            backgroundScope,
        )
    }

    @Test
    fun `the year span waits for every page`() = runTest {
        gates[2] = CompletableDeferred()
        val store = store()
        runCurrent()
        store.ensureLoaded(2)
        runCurrent()
        assertEquals("3 items", store.state.value.metaLine)
        gates.getValue(2).complete(Unit)
        runCurrent()
        assertEquals("3 items  ·  2001–2003", store.state.value.metaLine)
    }

    @Test
    fun `shuffle plays the collection through the queue launcher`() = runTest {
        val store = store()
        runCurrent()
        store.shuffle()
        runCurrent()
        assertEquals(listOf("c" to true), launches)
        assertNull(store.state.value.launching)
    }

    @Test
    fun `a collections change loads the grid again`() = runTest {
        val store = store()
        runCurrent()
        members = members.drop(1)
        changes.tryEmit(Unit)
        runCurrent()
        assertEquals(2, store.state.value.grid.total)
        assertTrue(store.state.value.grid.items.none { it.id.endsWith("m1") })
    }

    @Test
    fun `the page settles with its first page and stays settled through a reload`() = runTest {
        gates[0] = CompletableDeferred()
        val store = store()
        runCurrent()
        assertEquals("Box", store.state.value.title)
        assertFalse(store.state.value.settled)
        gates.getValue(0).complete(Unit)
        runCurrent()
        assertTrue(store.state.value.settled)
        gates[0] = CompletableDeferred()
        changes.tryEmit(Unit)
        runCurrent()
        assertEquals(SectionLoad.LOADING, store.state.value.grid.load)
        assertTrue(store.state.value.settled)
    }

    private inner class Folder : OfflineCollectionSource {
        val downloads = MutableSharedFlow<Any?>(extraBufferCapacity = 1)
        var titles = listOf(movie("d1", 2001), movie("d2", 2002))
        val marks = mutableListOf<Boolean>()
        var deleted = 0
        var failDelete = false
        override val changes = downloads
        override suspend fun metadata(serverId: ServerId, collectionId: String) =
            MediaItem(id = collectionId, backend = BackendKind.PLEX, kind = MediaKind.COLLECTION, title = "Box", thumbPath = "/thumb")
        override fun items(folder: MediaItem) = titles
        override fun artwork(serverId: ServerId, path: String?) = path?.let { "file:///art$it" }
        override suspend fun setWatched(folder: MediaItem, watched: Boolean): DownloadFeedback {
            marks += watched
            titles = titles.map { it.copy(viewCount = if (watched) 1 else 0) }
            return DownloadFeedback(if (watched) "watched" else "unwatched", isError = false)
        }
        override suspend fun delete(folder: MediaItem): DownloadFeedback {
            deleted++
            return DownloadFeedback("deleted", isError = failDelete)
        }
    }

    private fun TestScope.folderStore(folder: Folder) = CollectionStore(
        Route.CollectionDetail(ServerId("srv"), "c", offline = true),
        null,
        { CardOptions() },
        { _, _ -> error("no play offline") },
        changes,
        backgroundScope,
        offline = folder,
    )

    @Test
    fun `a downloads folder lists its downloaded titles with local artwork`() = runTest {
        val store = folderStore(Folder())
        runCurrent()
        val state = store.state.value
        assertEquals("Box", state.title)
        assertEquals(listOf("d1", "d2"), state.grid.items.map { it.title })
        assertEquals("file:///art/thumb", state.poster?.path)
        assertEquals(false, state.canPlay)
        assertEquals(OfflineCollectionUi(allWatched = false), state.offline)
        assertEquals(Route.MediaDetail(ServerId("srv"), "d1", offline = true), store.routeFor(state.grid.items.first().id))
        assertNull(store.item(state.grid.items.first().id))
    }

    @Test
    fun `a downloads folder marks every title watched then unwatched`() = runTest {
        val folder = Folder()
        val store = folderStore(folder)
        runCurrent()
        store.toggleWatched()
        runCurrent()
        assertEquals(listOf(true), folder.marks)
        assertEquals(true, store.state.value.offline?.allWatched)
        store.toggleWatched()
        runCurrent()
        assertEquals(listOf(true, false), folder.marks)
    }

    @Test
    fun `deleting a downloads folder asks then leaves`() = runTest {
        val folder = Folder()
        val store = folderStore(folder)
        runCurrent()
        store.deleteDownloads()
        assertTrue(store.state.value.offline!!.confirmingDelete)
        store.confirmDelete(false)
        runCurrent()
        assertEquals(0, folder.deleted)
        assertFalse(store.state.value.gone)
        store.deleteDownloads()
        store.confirmDelete(true)
        runCurrent()
        assertEquals(1, folder.deleted)
        assertEquals("deleted", store.state.value.message)
        assertTrue(store.state.value.gone)
    }

    @Test
    fun `a downloads folder reads its titles again as downloads change`() = runTest {
        val folder = Folder()
        val store = folderStore(folder)
        runCurrent()
        folder.titles = folder.titles.take(1)
        folder.downloads.emit(Unit)
        runCurrent()
        assertEquals(listOf("d1"), store.state.value.grid.items.map { it.title })
    }
}

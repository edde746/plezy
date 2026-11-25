package com.edde746.plezy.model

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class MediaHubsTest {
    private fun hub(id: String, identifier: String? = null) = MediaHub(id = id, identifier = identifier, title = "Hub", type = "mixed", items = emptyList())

    @Test
    fun recognizesPlexInProgressHubsAsContinueWatchingRows() {
        val hub = hub("/hubs/sections/1", identifier = "movie.inprogress.1")
        assertTrue(hub.isContinueWatchingHub)
        assertTrue(hub.usesContinueWatchingAction)
    }

    @Test
    fun recognizesJellyfinContinueHubsAsContinueWatchingRows() {
        val hub = hub("library.lib-99.continue")
        val homeHub = hub("home.continue")
        assertTrue(hub.isContinueWatchingHub)
        assertTrue(hub.usesContinueWatchingAction)
        assertTrue(homeHub.isContinueWatchingHub)
        assertTrue(homeHub.usesContinueWatchingAction)
    }

    @Test
    fun recognizesSyntheticHomeContinueWatchingHub() {
        val hub = hub("continue_watching", identifier = "_continue_watching_")
        assertTrue(hub.isContinueWatchingHub)
        assertTrue(hub.usesContinueWatchingAction)
    }

    @Test
    fun usesContinueWatchingActionForNextUpWithoutRemovalSemantics() {
        val hub = hub("library.lib-99.nextup")
        val homeHub = hub("home.nextup")
        assertFalse(hub.isContinueWatchingHub)
        assertTrue(hub.usesContinueWatchingAction)
        assertFalse(homeHub.isContinueWatchingHub)
        assertTrue(homeHub.usesContinueWatchingAction)
    }

    @Test
    fun usesContinueWatchingActionForPlexOnDeckWithoutRemovalSemantics() {
        val hub = hub("/hubs/sections/1", identifier = "tv.ondeck.1")
        assertFalse(hub.isContinueWatchingHub)
        assertTrue(hub.usesContinueWatchingAction)
    }

    @Test
    fun doesNotMatchUnrelatedHubsOrLibraryIdsContainingSemanticWords() {
        val recent = hub("library.lib-99.recent")
        val libraryNamedNextUp = hub("library.nextup.recent")
        assertFalse(recent.isContinueWatchingHub)
        assertFalse(recent.usesContinueWatchingAction)
        assertFalse(libraryNamedNextUp.isContinueWatchingHub)
        assertFalse(libraryNamedNextUp.usesContinueWatchingAction)
    }

    // sortMediaHubsByLibraryOrder

    private fun library(id: String) = MediaLibrary(id = id, backend = BackendKind.PLEX, title = "Library $id", kind = MediaKind.MOVIE, serverId = "server")

    private fun item(id: String, libraryId: String? = null, serverId: String? = "server") =
        MediaItem(id = id, backend = BackendKind.PLEX, kind = MediaKind.MOVIE, libraryId = libraryId, serverId = serverId)

    private fun orderedHub(id: String, libraryId: String? = null, serverId: String? = "server", items: List<MediaItem> = emptyList()) =
        MediaHub(id = id, title = id, type = "movie", items = items, libraryId = libraryId, serverId = serverId)

    @Test
    fun sortsExplicitLibraryHubsByLibraryOrder() {
        val hubs = mutableListOf(orderedHub("movies", libraryId = "1"), orderedHub("anime", libraryId = "3"), orderedHub("shows", libraryId = "2"))
        assertTrue(sortMediaHubsByLibraryOrder(hubs, listOf(library("3"), library("1"), library("2"))))
        assertEquals(listOf("anime", "movies", "shows"), hubs.map { it.id })
    }

    @Test
    fun usesItemLibraryIdsForPromotedHubs() {
        val hubs = mutableListOf(
            orderedHub("recent-movies", items = listOf(item("movie", libraryId = "1"))),
            orderedHub("recent-tv", items = listOf(item("episode", libraryId = "2"))),
        )
        assertTrue(sortMediaHubsByLibraryOrder(hubs, listOf(library("2"), library("1"))))
        assertEquals(listOf("recent-tv", "recent-movies"), hubs.map { it.id })
    }

    @Test
    fun usesTheEarliestOrderedItemLibraryWithinMixedHubs() {
        val hubs = mutableListOf(
            orderedHub("later", items = listOf(item("later", libraryId = "3"))),
            orderedHub("mixed", items = listOf(item("last", libraryId = "4"), item("first", libraryId = "1"))),
        )
        assertTrue(sortMediaHubsByLibraryOrder(hubs, listOf(library("1"), library("3"), library("4"))))
        assertEquals(listOf("mixed", "later"), hubs.map { it.id })
    }

    @Test
    fun keepsEqualAndUnknownHubsStableAfterKnownLibraries() {
        val hubs = mutableListOf(
            orderedHub("unknown-a"),
            orderedHub("second-a", libraryId = "2"),
            orderedHub("unknown-b", serverId = null, items = listOf(item("missing-server", libraryId = "1", serverId = null))),
            orderedHub("first", libraryId = "1"),
            orderedHub("second-b", libraryId = "2"),
        )
        assertTrue(sortMediaHubsByLibraryOrder(hubs, listOf(library("1"), library("2"))))
        assertEquals(listOf("first", "second-a", "second-b", "unknown-a", "unknown-b"), hubs.map { it.id })
    }

    @Test
    fun returnsFalseWhenTheCurrentOrderIsAlreadyCorrect() {
        val hubs = mutableListOf(orderedHub("first", libraryId = "1"), orderedHub("second", libraryId = "2"))
        assertFalse(sortMediaHubsByLibraryOrder(hubs, listOf(library("1"), library("2"))))
        assertEquals(listOf("first", "second"), hubs.map { it.id })
    }
}

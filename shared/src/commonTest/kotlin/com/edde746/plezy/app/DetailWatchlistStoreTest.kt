package com.edde746.plezy.app

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.catalog.CatalogSource
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.catalog.matching.LibraryWatchlistCandidates
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.presentation.libraries.mediaItem
import com.edde746.plezy.presentation.trackers.DetailWatchlistStore
import com.edde746.plezy.presentation.trackers.DetailWatchlistUi
import com.edde746.plezy.presentation.trackers.WatchlistSourceOption
import com.edde746.plezy.strings.T
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class DetailWatchlistStoreTest {
    private val server = FakeMediaBackend("s1").apply { externalIds = { ExternalIds(imdb = "tt1") } }
    private val movie = mediaItem("m1", MediaKind.MOVIE)
    private val trakt = WatchlistSource(CatalogSourceId.TRAKT)
    private var sources: List<CatalogSource> = listOf(trakt)

    private fun TestScope.store(item: MediaItem = movie): DetailWatchlistStore =
        DetailWatchlistStore({ item }, LibraryWatchlistCandidates { sources }, server, backgroundScope).also { runCurrent() }

    @Test
    fun noButtonForOtherKindsOrAnItemNoSourceCanHold() = runTest {
        assertNull(store(mediaItem("e", MediaKind.EPISODE)).state.value)
        assertNull(store(mediaItem("a", MediaKind.ALBUM)).state.value)
        server.externalIds = { ExternalIds() }
        assertNull(store().state.value)
        server.externalIds = { error("down") }
        assertNull(store().state.value)
        sources = emptyList()
        server.externalIds = { ExternalIds(imdb = "tt1") }
        assertNull(store().state.value)
    }

    @Test
    fun theButtonLoadsTheWatchlistsAndFollowsTheirChanges() = runTest {
        trakt.members = null
        val store = store(mediaItem("s", MediaKind.SHOW))
        assertEquals(1, trakt.loads)
        assertEquals(DetailWatchlistUi(onWatchlist = null, label = T.explore.addToWatchlist, enabled = false), store.state.value)
        store.press()
        runCurrent()
        assertEquals(2, trakt.loads, "a press while nothing is known loads again")
        assertEquals(emptyList(), trakt.mutations)
        trakt.members = mutableSetOf("tt1")
        trakt.changed()
        runCurrent()
        assertEquals(DetailWatchlistUi(onWatchlist = true, label = T.explore.removeFromWatchlist, enabled = true), store.state.value)
    }

    @Test
    fun oneCandidateTogglesOnPress() = runTest {
        val store = store()
        assertEquals(false, store.state.value?.onWatchlist)
        store.press()
        runCurrent()
        assertEquals(listOf("add tt1"), trakt.mutations)
        assertEquals(true, store.state.value?.onWatchlist)
        store.press()
        runCurrent()
        assertEquals(listOf("add tt1", "remove tt1"), trakt.mutations)
        assertEquals(false, store.state.value?.onWatchlist)
    }

    @Test
    fun severalCandidatesOpenTheChooserAndTogglePerSource() = runTest {
        val mdblist = WatchlistSource(CatalogSourceId.MDBLIST, mutableSetOf("tt1"))
        sources = listOf(trakt, mdblist)
        val store = store()
        assertEquals(true, store.state.value?.onWatchlist, "on any source's watchlist")
        store.press()
        assertEquals(
            listOf(
                WatchlistSourceOption(CatalogSourceId.TRAKT, "Trakt", member = false, action = T.explore.addToWatchlist),
                WatchlistSourceOption(CatalogSourceId.MDBLIST, "MDBList", member = true, action = T.explore.removeFromWatchlist),
            ),
            store.state.value?.chooser,
        )
        store.choose(null)
        runCurrent()
        assertNull(store.state.value?.chooser)
        assertEquals(emptyList(), trakt.mutations + mdblist.mutations)
        store.press()
        store.choose(1)
        runCurrent()
        assertNull(store.state.value?.chooser)
        assertEquals(listOf("remove tt1"), mdblist.mutations)
        assertEquals(false, store.state.value?.onWatchlist)
    }

    @Test
    fun severalCandidatesListTheirSourcesAheadAndToggleOneByIndex() = runTest {
        val mdblist = WatchlistSource(CatalogSourceId.MDBLIST, mutableSetOf("tt1"))
        sources = listOf(trakt, mdblist)
        val store = store()
        assertEquals(
            listOf(
                WatchlistSourceOption(CatalogSourceId.TRAKT, "Trakt", member = false, action = T.explore.addToWatchlist),
                WatchlistSourceOption(CatalogSourceId.MDBLIST, "MDBList", member = true, action = T.explore.removeFromWatchlist),
            ),
            store.state.value?.sources,
        )
        store.toggleSource(0)
        runCurrent()
        assertEquals(listOf("add tt1"), trakt.mutations)
        assertEquals(emptyList(), mdblist.mutations)
        assertEquals(true, store.state.value?.sources?.first()?.member, "Trakt's option follows its change")
        assertNull(store.state.value?.chooser, "no chooser opens")
    }

    @Test
    fun aFailedChangeLeavesAMessageOnce() = runTest {
        val store = store()
        trakt.failMutation = IllegalStateException("503")
        store.press()
        runCurrent()
        assertEquals(T.explore.watchlistUpdateFailed, store.state.value?.message)
        store.messageShown()
        assertNull(store.state.value?.message)
        trakt.failMutation = null
        store.press()
        runCurrent()
        assertEquals(listOf("add tt1"), trakt.mutations, "the failed change no longer blocks the next")
    }
}

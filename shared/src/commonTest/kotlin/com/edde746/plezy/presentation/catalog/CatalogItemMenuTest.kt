package com.edde746.plezy.presentation.catalog

import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.CatalogLink
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.presentation.explore.CatalogSourcesState
import com.edde746.plezy.presentation.explore.FakeCatalogSource
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class CatalogItemMenuTest {
    /** A source whose membership is [membership], recording its watchlist calls; [gate] holds a change open. */
    private class WatchlistSource : FakeCatalogSource(CatalogSourceId.TRAKT) {
        var membership: Boolean? = null
        var loads = 0
        val changes = mutableListOf<String>()
        var gate: CompletableDeferred<Unit>? = null
        var fails = false

        override suspend fun ensureWatchlistLoaded() {
            loads++
        }

        override fun isOnWatchlist(kind: MediaKind, ids: CatalogItemIds): Boolean? = membership

        override suspend fun addToWatchlist(kind: MediaKind, ids: CatalogItemIds) = change("add:${ids.tmdb}")

        override suspend fun removeFromWatchlist(kind: MediaKind, ids: CatalogItemIds) = change("remove:${ids.tmdb}")

        private suspend fun change(call: String) {
            changes += call
            gate?.await()
            if (fails) throw IllegalStateException("refused")
        }
    }

    private object Host : CatalogDetailHost {
        override val hasBrowser = true
        override val use24HourClock = true

        override suspend fun youTubeAppInstalled() = true

        override fun openUrl(url: String) = true

        override fun playTrailer(trailer: MediaItem) = true
    }

    private val source = WatchlistSource()

    private fun TestScope.menu() = CatalogItemMenu(MutableStateFlow(CatalogSourcesState(connected = listOf(source))), Host, backgroundScope)

    @Test
    fun anUnknownMembershipLoadsTheWatchlistInTheBackgroundAndTheEntryAppearsNextTime() = runTest {
        val menu = menu()
        val item = source.item("Matrix")
        val first = menu.entries(item)
        assertTrue(first.none { it.action is CatalogMenuAction.Watchlist })
        runCurrent()
        assertEquals(1, source.loads)

        source.membership = false
        val next = menu.entries(item)
        assertEquals(CatalogMenuEntry(T.explore.addToWatchlist, CatalogMenuAction.Watchlist(add = true)), next.last())
        source.membership = true
        assertEquals(CatalogMenuEntry(T.explore.removeFromWatchlist, CatalogMenuAction.Watchlist(add = false)), menu.entries(item).last())
        runCurrent()
        assertEquals(1, source.loads, "a known membership loads nothing")
    }

    @Test
    fun theMembershipIsReadAgainWhenTheEntryIsChosen() = runTest {
        val menu = menu()
        val item = source.item("Matrix")
        source.membership = true
        assertNull(menu.run(item, CatalogMenuAction.Watchlist(add = true)))
        source.membership = false
        assertNull(menu.run(item, CatalogMenuAction.Watchlist(add = false)))
        source.membership = null
        assertNull(menu.run(item, CatalogMenuAction.Watchlist(add = true)))
        val id = item.ids.tmdb
        assertEquals(listOf("remove:$id", "add:$id", "add:$id"), source.changes)
    }

    @Test
    fun oneChangePerTitleRunsAtATimeAndAFailureSaysSo() = runTest {
        val menu = menu()
        val matrix = source.item("Matrix")
        val other = source.item("Other")
        source.membership = false
        val gate = CompletableDeferred<Unit>()
        source.gate = gate
        val first = backgroundScope.async { menu.run(matrix, CatalogMenuAction.Watchlist(add = true)) }
        runCurrent()
        assertNull(menu.run(matrix, CatalogMenuAction.Watchlist(add = true)), "the double tap is dropped")
        val second = backgroundScope.async { menu.run(other, CatalogMenuAction.Watchlist(add = true)) }
        runCurrent()
        assertEquals(listOf("add:${matrix.ids.tmdb}", "add:${other.ids.tmdb}"), source.changes)
        gate.complete(Unit)
        assertNull(first.await())
        assertNull(second.await())

        source.gate = null
        source.fails = true
        assertEquals(T.explore.watchlistUpdateFailed, menu.run(matrix, CatalogMenuAction.Watchlist(add = true)))
        assertEquals(3, source.changes.size, "the title is free again once its change ended")
    }

    private class BrowserHost(override val hasBrowser: Boolean, private val youTube: Boolean) : CatalogDetailHost {
        override val use24HourClock = true

        override suspend fun youTubeAppInstalled() = youTube

        override fun openUrl(url: String) = true

        override fun playTrailer(trailer: MediaItem) = true
    }

    @Test
    fun entriesComeInOrderAndSkipLinksWithoutAWebUrlOrAName() = runTest {
        source.membership = false
        val item = source.item("Matrix").copy(
            trailerUrl = "https://www.youtube.com/watch?v=abc",
            links = listOf(
                CatalogLink("IMDb", "https://imdb.com/title/tt1"),
                CatalogLink("Ftp", "ftp://example.com/x"),
                CatalogLink("", "https://example.com/nameless"),
                CatalogLink("TMDB", "http://themoviedb.org/movie/1"),
            ),
        )

        assertEquals(
            listOf(
                CatalogMenuEntry(T.mediaMenu.viewDetails, CatalogMenuAction.ViewDetails),
                CatalogMenuEntry(T.explore.detail.watchTrailer, CatalogMenuAction.Trailer("https://www.youtube.com/watch?v=abc")),
                CatalogMenuEntry(T.explore.detail.openOn("IMDb"), CatalogMenuAction.Link("https://imdb.com/title/tt1")),
                CatalogMenuEntry(T.explore.detail.openOn("TMDB"), CatalogMenuAction.Link("http://themoviedb.org/movie/1")),
                CatalogMenuEntry(T.explore.addToWatchlist, CatalogMenuAction.Watchlist(add = true)),
            ),
            menu().entries(item),
        )
    }

    @Test
    fun withoutABrowserThereAreNoLinksAndNoTrailerUnlessTheYoutubeAppIsInstalled() = runTest {
        source.membership = true
        val state = MutableStateFlow(CatalogSourcesState(connected = listOf(source)))
        val item = source.item("Matrix").copy(
            trailerUrl = "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            links = listOf(CatalogLink("IMDb", "https://imdb.com/title/tt1")),
        )

        val noApp = CatalogItemMenu(state, BrowserHost(hasBrowser = false, youTube = false), backgroundScope).entries(item)
        assertEquals(listOf(CatalogMenuAction.ViewDetails, CatalogMenuAction.Watchlist(add = false)), noApp.map { it.action })

        val withApp = CatalogItemMenu(state, BrowserHost(hasBrowser = false, youTube = true), backgroundScope).entries(item)
        assertEquals(
            listOf(CatalogMenuAction.ViewDetails, CatalogMenuAction.Trailer("youtube://www.youtube.com/watch?v=dQw4w9WgXcQ"), CatalogMenuAction.Watchlist(add = false)),
            withApp.map { it.action },
        )
    }
}

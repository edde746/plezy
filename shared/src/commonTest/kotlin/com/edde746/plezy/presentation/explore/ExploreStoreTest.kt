package com.edde746.plezy.presentation.explore

import com.edde746.plezy.catalog.CatalogHubStyle
import com.edde746.plezy.catalog.CatalogPage
import com.edde746.plezy.catalog.CatalogRowId
import com.edde746.plezy.catalog.CatalogSource
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.strings.T
import com.edde746.plezy.strings.isolate
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes

class ExploreStoreTest {
    private class Harness(val scope: TestScope, initial: List<CatalogSource>) {
        val sources = MutableStateFlow(CatalogSourcesState(connected = initial))
        val store = ExploreStore(
            sources = sources,
            storeActiveSource = { id -> sources.value = sources.value.copy(preferred = id) },
            parentScope = scope.backgroundScope,
            timeSource = scope.testScheduler.timeSource,
        )

        fun show(vararg connected: CatalogSource) {
            sources.value = CatalogSourcesState(connected = connected.toList())
        }

        val body get() = store.state.value.body
        val rows get() = (body as? ExploreBody.Rows)?.rows.orEmpty()
    }

    private fun TestScope.harness(vararg initial: CatalogSource) = Harness(this, initial.toList())

    @Test
    fun sourceSwitchDuringAnInFlightLoadStartsTheNewLoadInsteadOfCoalescing() = runTest {
        val slow = FakeCatalogSource(CatalogSourceId.TRAKT).apply { gated = true }
        val fast = FakeCatalogSource(CatalogSourceId.MAL, listOf(CatalogRowId.POPULAR_ANIME))
        val h = harness()
        h.show(slow)
        runCurrent()
        assertEquals(ExploreBody.Loading, h.body)
        assertTrue(slow.pending.isNotEmpty())

        h.show(fast)
        runCurrent()
        assertEquals(listOf(CatalogRowId.POPULAR_ANIME), h.rows.map { it.row })
        assertEquals("mal:popularAnime:1", h.rows.single().hub.items.single().title)

        // The old pass finishing must not overwrite the new source's rows.
        slow.releaseAll()
        runCurrent()
        assertEquals(listOf(CatalogRowId.POPULAR_ANIME), h.rows.map { it.row })
    }

    @Test
    fun providerDefinedHubsRetainTheirTitlesAndPageThroughViewAll() = runTest {
        val source = FakeHubSource()
        val h = harness()
        h.show(source)
        runCurrent()

        assertEquals(2, h.rows.size)
        val providerHub = h.rows.last()
        assertNull(providerHub.row)
        assertEquals("trending-plex", providerHub.providerHubId)
        assertEquals("explore:plex:hub:trending-plex", providerHub.hub.id)
        assertEquals("Trending on Plex", providerHub.hub.title)
        assertEquals("Initial Recommendation", providerHub.hub.items.single().title)
        assertTrue(providerHub.hub.more)
        assertEquals(ExploreRowIcon.RECOMMENDED, providerHub.icon)

        val all = h.store.loadAll(providerHub)
        assertEquals(listOf(1, 2), source.hubPageFetches)
        assertEquals(listOf("Recommendation Page 1", "Recommendation Page 2"), all.map { it.title })
    }

    @Test
    fun nullAndShelfStylesKeepTheSameShelf() = runTest {
        val source = FakeHubSource()
        val h = harness()
        h.show(source)
        runCurrent()
        val unstyled = h.rows.last()
        assertNull(unstyled.style)

        source.hubStyle = CatalogHubStyle.SHELF
        h.store.retry()
        runCurrent()
        val shelf = h.rows.last()
        assertEquals(CatalogHubStyle.SHELF, shelf.style)
        assertEquals(unstyled.hub, shelf.hub)
    }

    @Test
    fun availabilityPlatformHubsAreSkippedInsteadOfRenderedAsTitlePosters() = runTest {
        val source = FakeHubSource().apply { hubStyle = CatalogHubStyle.AVAILABILITY_PLATFORMS }
        val h = harness()
        h.show(source)
        runCurrent()

        assertEquals(CatalogRowId.WATCHLIST, h.rows.single().row)
        assertEquals("plex:watchlist:1", h.rows.single().hub.items.single().title)
    }

    @Test
    fun providerTotalResultsReachTheRenderedHubWithoutReplacingItsItems() = runTest {
        val source = FakeHubSource().apply { hubTotalResults = 347 }
        val h = harness()
        h.show(source)
        runCurrent()

        val providerHub = h.rows.last()
        assertEquals(347, providerHub.totalResults)
        assertEquals(347, providerHub.hub.size)
        assertEquals(1, providerHub.hub.items.size)
    }

    @Test
    fun fixedRowsRenderInSupportedOrderWithTheirIdsTitlesAndIcons() = runTest {
        val source = FakeCatalogSource(CatalogSourceId.TRAKT, listOf(CatalogRowId.WATCHLIST, CatalogRowId.POPULAR_MOVIES, CatalogRowId.UPCOMING_SHOWS))
        source.failedRows += CatalogRowId.POPULAR_MOVIES
        val h = harness()
        h.show(source)
        runCurrent()

        assertEquals(listOf("explore:trakt:watchlist", "explore:trakt:upcomingShows"), h.rows.map { it.hub.id })
        assertEquals(listOf(T.explore.rows.watchlist, T.explore.rows.upcomingShows), h.rows.map { it.hub.title })
        assertEquals(listOf(ExploreRowIcon.WATCHLIST, ExploreRowIcon.UPCOMING), h.rows.map { it.icon })
        assertEquals(1, h.rows.first().hub.size)
        assertEquals("Trakt", h.store.state.value.title)
    }

    @Test
    fun emptySuccessfulHubsDoNotMaskEveryFixedRowFailing() = runTest {
        val source = FakeHubSource().apply {
            failedRows += CatalogRowId.WATCHLIST
            returnEmptyHubs = true
        }
        val h = harness()
        h.show(source)
        runCurrent()

        assertEquals(ExploreBody.Failed("watchlist failed"), h.body)
    }

    @Test
    fun aFailedReloadKeepsTheRowsItHasAndAFailedRowKeepsItsPage() = runTest {
        val source = FakeCatalogSource(CatalogSourceId.TRAKT)
        val h = harness()
        h.show(source)
        runCurrent()
        val loaded = h.rows

        source.failedRows += CatalogRowId.WATCHLIST
        source.failedRows += CatalogRowId.TRENDING_MOVIES
        h.store.retry()
        runCurrent()
        assertEquals(loaded, h.rows)

        source.failedRows -= CatalogRowId.TRENDING_MOVIES
        h.store.retry()
        runCurrent()
        assertEquals(loaded.map { it.hub.id }, h.rows.map { it.hub.id })
    }

    @Test
    fun aSourceWithNoRowsSaysSoAndKeepsTheSwitcher() = runTest {
        val empty = FakeCatalogSource(CatalogSourceId.TRAKT).apply { emptyPages = true }
        val mal = FakeCatalogSource(CatalogSourceId.MAL)
        val h = harness()
        h.show(empty, mal)
        runCurrent()

        val state = h.store.state.value
        assertEquals(ExploreBody.Empty(T.explore.emptyMessage(isolate("Trakt"))), state.body)
        assertTrue(state.showsSwitcher)
        assertEquals(listOf(true, false), state.sources.map { it.selected })

        h.store.selectSource(CatalogSourceId.MAL)
        runCurrent()
        assertEquals(CatalogSourceId.MAL, h.sources.value.preferred)
        assertEquals(listOf(false, true), h.store.state.value.sources.map { it.selected })
        assertEquals(2, h.rows.size)
    }

    @Test
    fun ensureFreshReloadsOnlyOnceTheRowsAreFifteenMinutesOld() = runTest {
        val source = FakeCatalogSource(CatalogSourceId.TRAKT)
        val h = harness(source)
        runCurrent()
        assertEquals(ExploreBody.Loading, h.body)
        assertEquals(emptyMap(), source.fetches)

        h.store.ensureFresh()
        runCurrent()
        assertEquals(1, source.fetches[CatalogRowId.TRENDING_MOVIES])

        advanceTimeBy(14.minutes)
        h.store.ensureFresh()
        runCurrent()
        assertEquals(1, source.fetches[CatalogRowId.TRENDING_MOVIES])

        advanceTimeBy(2.minutes)
        h.store.ensureFresh()
        runCurrent()
        assertEquals(2, source.fetches[CatalogRowId.TRENDING_MOVIES])
    }

    @Test
    fun loadsAskedForWhileOneRunsJoinIt() = runTest {
        val source = FakeCatalogSource(CatalogSourceId.TRAKT).apply { gated = true }
        val h = harness(source)
        h.store.ensureFresh()
        h.store.retry()
        h.store.refresh()
        runCurrent()
        assertEquals(1, source.fetches[CatalogRowId.WATCHLIST])
    }

    @Test
    fun aWatchlistChangeRefetchesTheRowOneSecondAfterTheLastChange() = runTest {
        val source = FakeCatalogSource(CatalogSourceId.TRAKT)
        val h = harness()
        h.show(source)
        runCurrent()
        assertEquals(1, source.fetches[CatalogRowId.WATCHLIST])

        source.watchlistChanged()
        runCurrent()
        advanceTimeBy(600.milliseconds)
        source.watchlistChanged()
        runCurrent()
        advanceTimeBy(600.milliseconds)
        runCurrent()
        assertEquals(1, source.fetches[CatalogRowId.WATCHLIST])

        advanceTimeBy(500.milliseconds)
        runCurrent()
        assertEquals(2, source.fetches[CatalogRowId.WATCHLIST])
        assertEquals(1, source.fetches[CatalogRowId.TRENDING_MOVIES])
    }

    @Test
    fun aMutationDuringTheInitialLoadIsCaughtUpByEnsureFresh() = runTest {
        val source = FakeCatalogSource(CatalogSourceId.TRAKT).apply { gated = true }
        val h = harness()
        h.show(source)
        runCurrent()
        assertEquals(2, source.pending.size)

        // The pages about to land were fetched before the change.
        source.watchlistChanged()
        runCurrent()
        source.gated = false
        source.releaseAll()
        runCurrent()
        assertIs<ExploreBody.Empty>(h.body)

        val before = source.fetches.getValue(CatalogRowId.WATCHLIST)
        h.store.ensureFresh()
        runCurrent()
        assertEquals(before + 1, source.fetches[CatalogRowId.WATCHLIST])
    }

    @Test
    fun aMutationRetriesProviderHubsAfterAPartialRefreshFailure() = runTest {
        val source = FakeHubSource()
        val h = harness()
        h.show(source)
        runCurrent()
        assertEquals(1, source.hubFetches)

        source.hubFailuresRemaining = 1
        source.watchlistChanged()
        runCurrent()
        h.store.ensureFresh()
        runCurrent()
        assertEquals(2, source.hubFetches)

        // The row refreshed but the hubs didn't, so the change isn't covered yet.
        h.store.ensureFresh()
        runCurrent()
        assertEquals(3, source.hubFetches)
    }

    @Test
    fun viewAllPagesByAHundredAndStopsAfterThreePages() = runTest {
        val source = FakeCatalogSource(CatalogSourceId.TRAKT).apply { pageCount = 10 }
        val h = harness()
        h.show(source)
        runCurrent()
        source.fetchedPages.clear()

        val all = h.store.loadAll(h.rows.first())
        assertEquals(listOf(1, 2, 3), source.fetchedPages)
        assertEquals(listOf("trakt:watchlist:1", "trakt:watchlist:2", "trakt:watchlist:3"), all.map { it.title })
        assertTrue(h.rows.first().hub.more)
    }

    @Test
    fun searchResultsReplaceTheShelvesWhileTheQueryIsLiveAndClearingBringsThemBack() = runTest {
        val trakt = FakeCatalogSource(CatalogSourceId.TRAKT)
        val h = harness()
        h.show(trakt)
        runCurrent()
        assertEquals(T.explore.searchHint(isolate("Trakt")), h.store.state.value.searchHint)
        assertNull(h.store.state.value.search)

        h.store.setSearchText("incep")
        assertEquals(CatalogSearchBody.Idle(null), h.store.state.value.search)
        advanceTimeBy(499.milliseconds)
        runCurrent()
        assertEquals(emptyList(), trakt.searchQueries)
        advanceTimeBy(2.milliseconds)
        runCurrent()
        assertEquals(listOf("incep"), trakt.searchQueries)
        val results = assertIs<CatalogSearchBody.Results>(h.store.state.value.search)
        assertEquals(listOf("Trakt search: incep"), results.items.map { it.title })

        h.store.setSearchText("")
        assertNull(h.store.state.value.search)
        assertEquals(2, h.rows.size)
    }

    @Test
    fun aQueryWithNoHitsShowsTheEmptyState() = runTest {
        val trakt = FakeCatalogSource(CatalogSourceId.TRAKT).apply { searchTitles = emptyList() }
        val h = harness()
        h.show(trakt)
        runCurrent()

        h.store.setSearchText("zzz")
        advanceTimeBy(600.milliseconds)
        runCurrent()
        assertEquals(CatalogSearchBody.Empty(T.explore.searchEmpty(isolate("zzz"))), h.store.state.value.search)
    }

    @Test
    fun aFailedSearchShowsTheFailureAndRecoversOnTheNextQuery() = runTest {
        val trakt = FakeCatalogSource(CatalogSourceId.TRAKT).apply { searchFails = true }
        val h = harness()
        h.show(trakt)
        runCurrent()

        h.store.setSearchText("abc")
        advanceTimeBy(600.milliseconds)
        runCurrent()
        assertEquals(CatalogSearchBody.Failed(T.explore.searchFailed), h.store.state.value.search)

        trakt.searchFails = false
        h.store.setSearchText("abcd")
        advanceTimeBy(600.milliseconds)
        runCurrent()
        val results = assertIs<CatalogSearchBody.Results>(h.store.state.value.search)
        assertEquals(listOf("Trakt search: abcd"), results.items.map { it.title })
    }

    @Test
    fun switchingSourceRerunsTheLiveQueryAgainstTheNewSource() = runTest {
        val trakt = FakeCatalogSource(CatalogSourceId.TRAKT)
        val mal = FakeCatalogSource(CatalogSourceId.MAL)
        val h = harness()
        h.show(trakt, mal)
        runCurrent()
        h.store.setSearchText("abc")
        advanceTimeBy(600.milliseconds)
        runCurrent()

        h.store.selectSource(CatalogSourceId.MAL)
        runCurrent()
        assertEquals(listOf("abc"), mal.searchQueries)
        val results = assertIs<CatalogSearchBody.Results>(h.store.state.value.search)
        assertEquals(listOf("MyAnimeList search: abc"), results.items.map { it.title })
    }

    @Test
    fun refreshRerunsTheLiveQueryElseReloadsTheRows() = runTest {
        val trakt = FakeCatalogSource(CatalogSourceId.TRAKT)
        val h = harness()
        h.show(trakt)
        runCurrent()

        h.store.refresh()
        runCurrent()
        assertEquals(2, trakt.fetches[CatalogRowId.WATCHLIST])

        h.store.setSearchText("abc")
        advanceTimeBy(600.milliseconds)
        runCurrent()
        h.store.refresh()
        runCurrent()
        assertEquals(listOf("abc", "abc"), trakt.searchQueries)
        assertEquals(2, trakt.fetches[CatalogRowId.WATCHLIST])
    }

    @Test
    fun aRefreshStaysInFlightWithTheShelvesShownUntilItsLoadLands() = runTest {
        val source = FakeCatalogSource(CatalogSourceId.TRAKT)
        val h = harness(source)
        h.store.ensureFresh()
        runCurrent()
        val shelves = h.rows
        assertEquals(2, shelves.size)
        assertFalse(h.store.state.value.refreshing)

        source.gated = true
        h.store.refresh()
        assertTrue(h.store.state.value.refreshing)
        runCurrent()
        assertEquals(2, source.pending.size)
        assertTrue(h.store.state.value.refreshing)
        assertEquals(shelves, h.rows)

        source.pending.forEach { it.complete(CatalogPage(listOf(source.item("fresh")))) }
        source.pending.clear()
        runCurrent()
        assertFalse(h.store.state.value.refreshing)
        assertEquals(listOf("fresh", "fresh"), h.rows.map { it.hub.items.single().title })
    }

    @Test
    fun aFailedRefreshEndsInFlightAndKeepsTheShelves() = runTest {
        val source = FakeCatalogSource(CatalogSourceId.TRAKT)
        val h = harness(source)
        h.store.ensureFresh()
        runCurrent()
        val shelves = h.rows

        source.gated = true
        h.store.refresh()
        runCurrent()
        assertTrue(h.store.state.value.refreshing)

        source.pending.forEach { it.completeExceptionally(IllegalStateException("offline")) }
        source.pending.clear()
        runCurrent()
        assertFalse(h.store.state.value.refreshing)
        assertEquals(shelves, h.rows)
    }

    @Test
    fun aRefreshOfTheLiveSearchStaysInFlightUntilTheSearchAnswers() = runTest {
        val source = FakeCatalogSource(CatalogSourceId.TRAKT)
        val h = harness(source)
        h.store.ensureFresh()
        h.store.setSearchText("abc")
        advanceTimeBy(600.milliseconds)
        runCurrent()
        assertFalse(h.store.state.value.refreshing)

        val gate = CompletableDeferred<Unit>()
        source.searchGate = gate
        h.store.refresh()
        runCurrent()
        assertTrue(h.store.state.value.refreshing)

        gate.complete(Unit)
        runCurrent()
        assertFalse(h.store.state.value.refreshing)
        assertIs<CatalogSearchBody.Results>(h.store.state.value.search)
    }
}

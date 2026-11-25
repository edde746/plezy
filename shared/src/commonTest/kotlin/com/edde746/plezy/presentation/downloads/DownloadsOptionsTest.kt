package com.edde746.plezy.presentation.downloads

import com.edde746.plezy.downloads.DownloadedLibrary
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.DownloadedCollection
import com.edde746.plezy.model.LibraryFilter
import com.edde746.plezy.model.LibraryFilterOperator
import com.edde746.plezy.model.LibrarySortDirection
import com.edde746.plezy.model.MediaFilterValue
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MEDIA_SORT_KEY_DATE_ADDED
import com.edde746.plezy.model.MEDIA_SORT_KEY_DOWNLOADED_AT
import com.edde746.plezy.model.MEDIA_SORT_KEY_LIBRARY
import com.edde746.plezy.model.MEDIA_SORT_KEY_RATING
import com.edde746.plezy.model.MEDIA_SORT_KEY_RELEASE_DATE
import com.edde746.plezy.model.MEDIA_SORT_KEY_SIZE
import com.edde746.plezy.model.MEDIA_SORT_KEY_TITLE
import com.edde746.plezy.model.groupByDownloadedCollection
import com.edde746.plezy.data.testData
import com.edde746.plezy.settings.LibraryPrefs
import com.edde746.plezy.strings.T
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest

class DownloadsOptionsTest {
    @BeforeTest
    fun english() {
        T.locale = "en"
    }

    private fun movie(id: String, title: String, libraryId: String? = null, libraryTitle: String? = null, viewCount: Int? = null) = MediaItem(
        id = id,
        backend = BackendKind.PLEX,
        kind = MediaKind.MOVIE,
        title = title,
        serverId = "srv",
        serverName = "Server One",
        libraryId = libraryId,
        libraryTitle = libraryTitle,
        viewCount = viewCount,
    )

    private suspend fun TestScope.options(tab: DownloadsTab, prefs: LibraryPrefs): DownloadsTabOptions {
        val options = DownloadsTabOptions(tab, prefs, backgroundScope)
        options.restored.join()
        return options
    }

    private fun prefs() = testData().libraryPrefs

    private fun DownloadsTabOptions.titles(items: List<MediaItem>) = apply(items) { emptyMap() }.map { it.title }

    @Test
    fun theEpisodesGroupingIsSelectedAndPersistedForTheTvTab() = runTest {
        val prefs = prefs()
        val options = options(DownloadsTab.TV_SHOWS, prefs)
        assertEquals(DownloadsGrouping.SHOWS, options.state.value.grouping)

        options.selectGrouping(DownloadsGrouping.EPISODES)
        options.awaitSaved()

        assertEquals(DownloadsGrouping.EPISODES, options.state.value.grouping)
        assertEquals("episodes", prefs.grouping("downloads:tv"))
        assertEquals(DownloadsGrouping.EPISODES, options(DownloadsTab.TV_SHOWS, prefs).state.value.grouping)
    }

    @Test
    fun sortingByTitleReordersTheMoviesAndPersists() = runTest {
        val prefs = prefs()
        val options = options(DownloadsTab.MOVIES, prefs)
        val items = listOf(movie("m-1", "Zeta"), movie("m-2", "Alpha"), movie("m-3", "Beta"))
        assertEquals(listOf("Zeta", "Alpha", "Beta"), options.titles(items))

        options.selectSort(options.sortOptions.first { it.key == "title" })
        options.awaitSaved()

        assertEquals(listOf("Alpha", "Beta", "Zeta"), options.titles(items))
        val stored = prefs.sort("downloads:movies")
        assertEquals("title", stored?.field)
        assertEquals(LibrarySortDirection.ASCENDING, stored?.direction)
    }

    @Test
    fun pickingTheActiveSortTurnsItAroundAndAnotherStartsInItsOwnDirection() = runTest {
        val prefs = prefs()
        val options = options(DownloadsTab.MOVIES, prefs)
        fun pickIsDescending(key: String): Boolean {
            options.selectSort(options.sortOptions.first { it.key == key })
            return options.state.value.sortDescending
        }

        assertEquals(listOf(false, true, false), List(3) { pickIsDescending("title") })
        assertEquals(listOf(true, false), List(2) { pickIsDescending("dateAdded") })
        assertFalse(pickIsDescending("library"))
        options.awaitSaved()
        assertEquals(LibrarySortDirection.ASCENDING, prefs.sort("downloads:movies")?.direction)
        assertEquals("library", prefs.sort("downloads:movies")?.field)
    }

    @Test
    fun theLibraryFilterNarrowsTheMoviesAndPersists() = runTest {
        val prefs = prefs()
        val options = options(DownloadsTab.MOVIES, prefs)
        val items = listOf(
            movie("m-1", "Alpha One", "lib-a", "Library A"),
            movie("m-2", "Alpha Two", "lib-a", "Library A"),
            movie("m-3", "Beta One", "lib-b", "Library B"),
        )

        options.setFilters(listOf(LibraryFilter("library", listOf("srv:lib-a"))))
        options.awaitSaved()

        assertEquals(listOf("Alpha One", "Alpha Two"), options.titles(items))
        assertEquals(listOf(LibraryFilter("library", listOf("srv:lib-a"))), prefs.filters("downloads:movies"))
    }

    @Test
    fun aPersistedLibraryGroupingRestoresLibrarySections() = runTest {
        val prefs = prefs()
        prefs.setGrouping("downloads:movies", "library")
        val options = options(DownloadsTab.MOVIES, prefs)

        assertEquals(DownloadsGrouping.LIBRARY, options.state.value.grouping)
        val sections = bucketDownloadsByLibrary(
            options.apply(listOf(movie("m-1", "Alpha One", "lib-a", "Library A"), movie("m-2", "Beta One", "lib-b", "Library B"))) { emptyMap() },
        ) { null }
        assertEquals(listOf("Library A", "Library B"), sections.map { it.title })
        assertEquals(listOf(1, 1), sections.map { it.items.size })
    }

    @Test
    fun aPersistedLibraryFilterSurvivesAColdStartBeforeDownloadsLoad() = runTest {
        val prefs = prefs()
        prefs.setFilters(listOf(LibraryFilter("library", listOf("srv:lib-a"))), "downloads:movies")

        // Restored before any download exists; the downloads arriving afterwards still meet the filter.
        val options = options(DownloadsTab.MOVIES, prefs)
        val items = listOf(
            movie("m-1", "Alpha One", "lib-a", "Library A"),
            movie("m-2", "Alpha Two", "lib-a", "Library A"),
            movie("m-3", "Beta One", "lib-b", "Library B"),
        )

        assertEquals(listOf("Alpha One", "Alpha Two"), options.titles(items))
    }

    @Test
    fun aLegacySharedFilterDoesNotLeakIntoTheDownloadsTab() = runTest {
        val prefs = prefs()
        prefs.setFilters(listOf(LibraryFilter("unwatched", listOf("1"))))
        val options = options(DownloadsTab.MOVIES, prefs)

        assertEquals(2, options.titles(listOf(movie("m-1", "Watched", viewCount = 1), movie("m-2", "Unwatched"))).size)
    }

    @Test
    fun aFilterMatchingNothingOffersAResetThatClearsIt() = runTest {
        val prefs = prefs()
        val options = options(DownloadsTab.MOVIES, prefs)
        val items = listOf(movie("m-1", "Watched", viewCount = 1), movie("m-2", "Also Watched", viewCount = 2))

        options.setFilters(listOf(LibraryFilter("unwatched", listOf("1"))))
        options.awaitSaved()
        assertTrue(options.titles(items).isEmpty())
        assertTrue(options.state.value.hasActiveFilters)

        options.resetFilters()
        options.awaitSaved()

        assertEquals(2, options.titles(items).size)
        assertFalse(options.state.value.hasActiveFilters)
        assertTrue(prefs.filters("downloads:movies", legacyGlobalFallback = false).isEmpty())
    }

    @Test
    fun theCollectionsGroupingFoldsACollectionIntoAFolderAndPersists() = runTest {
        val prefs = prefs()
        val options = options(DownloadsTab.MOVIES, prefs)
        val items = listOf(movie("dune-2", "Dune: Part Two"), movie("other", "Other"), movie("dune-1", "Dune"))
        val collection = MediaItem(id = "dune", backend = BackendKind.PLEX, kind = MediaKind.COLLECTION, title = "Dune Collection", serverId = "srv")

        options.selectGrouping(DownloadsGrouping.COLLECTIONS)
        options.awaitSaved()
        val filtered = options.apply(items) { emptyMap() }
        val grouped = options.sortFolders(filtered, groupByDownloadedCollection(filtered, listOf(DownloadedCollection(collection, listOf("dune-1", "dune-2")))))

        assertEquals(listOf("dune", "other"), grouped.map { it.id })
        assertEquals("collections", prefs.grouping("downloads:movies"))
    }

    @Test
    fun theLibraryFilterListsLibrariesWithTheServerWhenSeveralServersHoldDownloads() {
        val names = mapOf("srv-a" to "Living Room", "srv-b" to "Office")
        val values = libraryFilterValues(
            listOf(
                DownloadedLibrary("srv-a", "1", "Movies"),
                DownloadedLibrary("srv-b", "2", "Movies"),
                DownloadedLibrary("srv-b", null, "srv-b"),
            ),
        ) { names[it] ?: it }

        assertEquals(listOf("srv-a:1", "srv-b:2", "srv-b:"), values.map { it.key })
        assertEquals(listOf("Movies (Living Room)", "Movies (Office)", "Office"), values.map { it.title })
    }

    @Test
    fun theUnwatchedFilterCyclesThroughUnwatchedWatchedAndOffAndPersists() = runTest {
        val prefs = prefs()
        val options = options(DownloadsTab.MOVIES, prefs)
        val items = listOf(movie("m-1", "Watched", viewCount = 1), movie("m-2", "Unwatched", viewCount = 0))

        options.setUnwatchedFilter(true)
        options.awaitSaved()
        assertEquals(listOf("Unwatched"), options.titles(items))
        assertEquals(true, options.state.value.unwatchedFilter)

        options.setUnwatchedFilter(false)
        options.awaitSaved()
        assertEquals(listOf("Watched"), options.titles(items))
        assertEquals(listOf(LibraryFilter("unwatched", listOf("1"), LibraryFilterOperator.IS_NOT)), prefs.filters("downloads:movies"))
        assertEquals(false, options(DownloadsTab.MOVIES, prefs).state.value.unwatchedFilter)

        options.setUnwatchedFilter(null)
        options.awaitSaved()
        assertEquals(2, options.titles(items).size)
        assertTrue(prefs.filters("downloads:movies", legacyGlobalFallback = false).isEmpty())
    }

    @Test
    fun libraryValuesOrAndTheLastOneOutTurnsTheFilterOff() = runTest {
        val options = options(DownloadsTab.MOVIES, prefs())
        val items = listOf(movie("a", "Alpha", libraryId = "lib-a"), movie("b", "Beta", libraryId = "lib-b"), movie("c", "Gamma", libraryId = "lib-c"))

        options.toggleLibraryFilterValue("srv:lib-a")
        options.toggleLibraryFilterValue("srv:lib-b")
        assertEquals(listOf("Alpha", "Beta"), options.titles(items))

        options.toggleLibraryFilterValue("srv:lib-a")
        assertEquals(listOf("Beta"), options.titles(items))

        options.toggleLibraryFilterValue("srv:lib-b")
        assertFalse(options.state.value.hasActiveFilters)
    }

    @Test
    fun excludingTheChosenLibrariesKeepsEveryOtherAndClearingTurnsItOff() = runTest {
        val prefs = prefs()
        val options = options(DownloadsTab.TV_SHOWS, prefs)
        val items = listOf(movie("a", "Alpha", libraryId = "lib-a"), movie("b", "Beta", libraryId = "lib-b"))

        options.setLibraryFilterExcluded(true)
        assertFalse(options.state.value.hasActiveFilters)

        options.toggleLibraryFilterValue("srv:lib-a")
        options.setLibraryFilterExcluded(true)
        options.awaitSaved()
        assertEquals(listOf("Beta"), options.titles(items))
        assertEquals(listOf(LibraryFilter("library", listOf("srv:lib-a"), LibraryFilterOperator.IS_NOT)), prefs.filters("downloads:tv"))

        options.clearLibraryFilter()
        options.awaitSaved()
        assertEquals(2, options.titles(items).size)
        assertTrue(prefs.filters("downloads:tv", legacyGlobalFallback = false).isEmpty())
    }

    @Test
    fun bothFiltersMustPassAndEachTabKeepsItsOwn() = runTest {
        val prefs = prefs()
        val movies = options(DownloadsTab.MOVIES, prefs)
        val items = listOf(movie("a", "Alpha", libraryId = "lib-a", viewCount = 1), movie("b", "Beta", libraryId = "lib-a"), movie("c", "Gamma", libraryId = "lib-b"))

        movies.setUnwatchedFilter(true)
        movies.toggleLibraryFilterValue("srv:lib-a")
        movies.awaitSaved()

        assertEquals(listOf("Beta"), movies.titles(items))
        assertTrue(options(DownloadsTab.TV_SHOWS, prefs).state.value.filters.isEmpty())
        assertEquals(2, options(DownloadsTab.MOVIES, prefs).state.value.filters.size)
    }

    @Test
    fun theFilterSummariesNameTheChoice() = runTest {
        val options = options(DownloadsTab.MOVIES, prefs())
        val (unwatched, library) = options.filterDefinitions
        val values = listOf(MediaFilterValue("srv:lib-a", "Movies"), MediaFilterValue("srv:lib-b", "Kids"))
        assertEquals(null, options.state.value.filterSummary(unwatched, values))

        options.setUnwatchedFilter(false)
        options.toggleLibraryFilterValue("srv:lib-a")
        options.toggleLibraryFilterValue("srv:lib-b")
        assertEquals("No", options.state.value.filterSummary(unwatched, values))
        assertEquals("Movies, Kids", options.state.value.filterSummary(library, values))
        assertEquals("Filters (2)", options.state.value.filtersLabel)

        options.setLibraryFilterExcluded(true)
        assertEquals("Not Movies, Kids", options.state.value.filterSummary(library, values))
        // A stored library that holds no downloads any more is counted, not named.
        assertEquals("2 excluded", options.state.value.filterSummary(library, values.take(1)))
    }

    @Test
    fun aDownloadsFolderMenuOffersDeletingItsDownloadsNeverTheServerCollection() {
        val folder = MediaItem(id = "dune", backend = BackendKind.PLEX, kind = MediaKind.COLLECTION, title = "Dune Collection", serverId = "srv")

        assertEquals(listOf(DownloadMenuEntry.MARK_WATCHED, DownloadMenuEntry.DELETE_FOLDER_DOWNLOADS), downloadsFolderMenuEntries(folder))
    }

    @Test
    fun aWatchedFolderOffersUnwatchedAndAPartlyWatchedOneBothMarks() {
        val folder = MediaItem(id = "dune", backend = BackendKind.PLEX, kind = MediaKind.COLLECTION, title = "Dune Collection", serverId = "srv", leafCount = 2)

        assertEquals(
            listOf(DownloadMenuEntry.MARK_UNWATCHED, DownloadMenuEntry.DELETE_FOLDER_DOWNLOADS),
            downloadsFolderMenuEntries(folder.copy(viewedLeafCount = 2)),
        )
        assertEquals(
            listOf(DownloadMenuEntry.MARK_WATCHED, DownloadMenuEntry.MARK_UNWATCHED, DownloadMenuEntry.DELETE_FOLDER_DOWNLOADS),
            downloadsFolderMenuEntries(folder.copy(viewedLeafCount = 1)),
        )
        assertTrue(DownloadMenuEntry.DELETE_FOLDER_DOWNLOADS.destructive)
    }

    @Test
    fun eachSortStartsInItsOwnDirectionAndPickingItAgainTurnsItAround() = runTest {
        val options = options(DownloadsTab.MOVIES, prefs())
        val descendingFirst = mapOf(
            MEDIA_SORT_KEY_TITLE to false,
            MEDIA_SORT_KEY_DATE_ADDED to true,
            MEDIA_SORT_KEY_RELEASE_DATE to true,
            MEDIA_SORT_KEY_RATING to true,
            MEDIA_SORT_KEY_DOWNLOADED_AT to true,
            MEDIA_SORT_KEY_SIZE to true,
            MEDIA_SORT_KEY_LIBRARY to false,
        )
        assertEquals(descendingFirst.keys.toList(), options.sortOptions.map { it.key })

        for (sort in options.sortOptions) {
            options.selectSort(sort)
            assertEquals(descendingFirst.getValue(sort.key), options.state.value.sortDescending, "${sort.key} first")
            options.selectSort(sort)
            assertEquals(!descendingFirst.getValue(sort.key), options.state.value.sortDescending, "${sort.key} again")
        }
    }
}

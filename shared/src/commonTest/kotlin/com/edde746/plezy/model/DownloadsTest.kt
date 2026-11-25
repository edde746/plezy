package com.edde746.plezy.model

import com.edde746.plezy.strings.T
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class DownloadsTest {
    @BeforeTest
    fun english() {
        T.locale = "en"
    }

    private fun item(
        id: String,
        kind: MediaKind = MediaKind.MOVIE,
        serverId: String? = null,
        libraryId: String? = null,
        viewCount: Int? = null,
        leafCount: Int? = null,
        viewedLeafCount: Int? = null,
        title: String? = null,
    ) = MediaItem(
        id = id,
        backend = BackendKind.PLEX,
        kind = kind,
        title = title,
        serverId = serverId,
        libraryId = libraryId,
        viewCount = viewCount,
        leafCount = leafCount,
        viewedLeafCount = viewedLeafCount,
    )

    private val unwatchedClause = listOf(LibraryFilter(DOWNLOAD_FILTER_UNWATCHED, listOf("1")))

    private fun library(vararg values: String, op: LibraryFilterOperator = LibraryFilterOperator.IS) =
        listOf(LibraryFilter(DOWNLOAD_FILTER_LIBRARY, values.toList(), op))

    // Filter: unwatched

    @Test
    fun leafItemsPassOnlyWhenNotWatched() {
        assertTrue(downloadItemMatchesFilters(item("u", viewCount = 0), unwatchedClause))
        assertFalse(downloadItemMatchesFilters(item("w", viewCount = 1), unwatchedClause))
    }

    @Test
    fun containersAnswerFromUnwatchedCountWhenLeafCountsAreSet() {
        val partlyWatched = item("p", MediaKind.SHOW, leafCount = 10, viewedLeafCount = 4)
        val fullyWatched = item("f", MediaKind.SHOW, leafCount = 10, viewedLeafCount = 10)

        assertEquals(6, partlyWatched.unwatchedCount)
        assertTrue(downloadItemMatchesFilters(partlyWatched, unwatchedClause))
        assertFalse(downloadItemMatchesFilters(fullyWatched, unwatchedClause))
    }

    // Filter: library

    @Test
    fun matchesTheServerIdLibraryIdPair() {
        val movie = item("i", serverId = "s1", libraryId = "7")
        assertTrue(downloadItemMatchesFilters(movie, library("s1:7")))
        assertFalse(downloadItemMatchesFilters(movie, library("s1:8")))
        assertFalse(downloadItemMatchesFilters(movie, library("s2:7")))
    }

    @Test
    fun emptyLibrarySuffixMatchesItemsWithANullLibraryId() {
        val noLibrary = item("i", serverId = "s1")
        val withLibrary = item("j", serverId = "s1", libraryId = "7")

        assertTrue(downloadItemMatchesFilters(noLibrary, library("s1:")))
        assertFalse(downloadItemMatchesFilters(withLibrary, library("s1:")))
        assertFalse(downloadItemMatchesFilters(noLibrary, library("s1:7")))
    }

    @Test
    fun downloadLibraryFilterValueBuildsTheExpectedValueShape() {
        assertEquals("s1:7", downloadLibraryFilterValue("s1", "7"))
        assertEquals("s1:", downloadLibraryFilterValue("s1", null))
    }

    // Filter: composition

    @Test
    fun unknownFieldsAreIgnored() {
        val filters = listOf(LibraryFilter("genre", listOf("action")), LibraryFilter("year", listOf("2020")))
        assertTrue(downloadItemMatchesFilters(item("i", viewCount = 1), filters))
    }

    @Test
    fun allSelectedFiltersMustPass() {
        val movie = item("i", serverId = "s1", libraryId = "7", viewCount = 0)
        assertTrue(downloadItemMatchesFilters(movie, unwatchedClause + library("s1:7")))
        assertFalse(downloadItemMatchesFilters(movie, unwatchedClause + library("s1:8")))
    }

    @Test
    fun valuesInsideOneClauseOr() {
        val movie = item("i", serverId = "s1", libraryId = "7")
        assertTrue(downloadItemMatchesFilters(movie, library("s1:8", "s1:7")))
        assertFalse(downloadItemMatchesFilters(movie, library("s1:8", "s1:9")))
    }

    @Test
    fun aNegatedClauseInvertsItsField() {
        val watchedOnly = listOf(LibraryFilter(DOWNLOAD_FILTER_UNWATCHED, listOf("1"), LibraryFilterOperator.IS_NOT))
        assertTrue(downloadItemMatchesFilters(item("w", viewCount = 1), watchedOnly))
        assertFalse(downloadItemMatchesFilters(item("u", viewCount = 0), watchedOnly))
    }

    @Test
    fun aNegatedLibraryClauseExcludesEveryListedLibrary() {
        val movie = item("i", serverId = "s1", libraryId = "7")
        assertFalse(downloadItemMatchesFilters(movie, library("s1:7", op = LibraryFilterOperator.IS_NOT)))
        assertTrue(downloadItemMatchesFilters(movie, library("s1:8", op = LibraryFilterOperator.IS_NOT)))
    }

    @Test
    fun emptySelectionMatchesEverything() {
        assertTrue(downloadItemMatchesFilters(item("i", viewCount = 1), emptyList()))
    }

    // Sort options

    @Test
    fun offersTheSharedKeysWithoutDownloadFields() {
        assertEquals(
            listOf(MEDIA_SORT_KEY_TITLE, MEDIA_SORT_KEY_DATE_ADDED, MEDIA_SORT_KEY_RELEASE_DATE, MEDIA_SORT_KEY_RATING, MEDIA_SORT_KEY_LIBRARY),
            downloadSortOptions(includeDownloadFields = false).map { it.key },
        )
    }

    @Test
    fun includeDownloadFieldsInsertsDownloadDateAndSizeBeforeLibrary() {
        assertEquals(
            listOf(
                MEDIA_SORT_KEY_TITLE to "asc", MEDIA_SORT_KEY_DATE_ADDED to "desc", MEDIA_SORT_KEY_RELEASE_DATE to "desc", MEDIA_SORT_KEY_RATING to "desc",
                MEDIA_SORT_KEY_DOWNLOADED_AT to "desc", MEDIA_SORT_KEY_SIZE to "desc", MEDIA_SORT_KEY_LIBRARY to "asc",
            ),
            downloadSortOptions(includeDownloadFields = true).map { it.key to it.defaultDirection },
        )
    }

    // Collection grouping

    private fun movie(id: String, watched: Boolean = false, serverId: String = "s1") =
        item(id, title = id, serverId = serverId, viewCount = if (watched) 1 else 0)

    private fun collection(id: String, memberIds: List<String>, title: String? = null, serverId: String = "s1") =
        DownloadedCollection(item(id, MediaKind.COLLECTION, title = title ?: id, serverId = serverId), memberIds)

    private fun ids(items: List<MediaItem>) = items.map { it.id }

    @Test
    fun foldsTwoOrMoreMembersIntoAFolderAtTheFirstMembersPlace() {
        val items = listOf(movie("a"), movie("dune-2"), movie("b"), movie("dune-1"), movie("solo"))

        val grouped = groupByDownloadedCollection(
            items,
            listOf(collection("dune", listOf("dune-1", "dune-2", "not-downloaded")), collection("lonely", listOf("solo", "gone"))),
        )

        assertEquals(listOf("a", "dune", "b", "solo"), ids(grouped))
        assertEquals(2, grouped[1].childCount)
    }

    @Test
    fun aTitleInTwoFoldingCollectionsShowsInNeitherPlaceAlone() {
        val items = listOf(movie("x"), movie("y"), movie("z"))

        val grouped = groupByDownloadedCollection(
            items,
            listOf(collection("saga", listOf("y", "z"), title = "Saga"), collection("box", listOf("x", "y"), title = "Box")),
        )

        assertEquals(listOf("box", "saga"), ids(grouped))
    }

    @Test
    fun membersOnAnotherServerNeverMatch() {
        val items = listOf(movie("a"), movie("b"))

        val grouped = groupByDownloadedCollection(items, listOf(collection("c", listOf("a", "b"), serverId = "s2")))

        assertEquals(listOf("a", "b"), ids(grouped))
    }

    @Test
    fun foldersAddUpTheirMembersWatchStateAShowCountingItsEpisodes() {
        val show = item("s", MediaKind.SHOW, title = "s", serverId = "s1", leafCount = 4, viewedLeafCount = 4)
        val items = listOf(movie("m1", watched = true), movie("m2"), show)

        val folder = groupByDownloadedCollection(items, listOf(collection("c", listOf("m1", "m2", "s")))).single()

        assertEquals(3, folder.childCount)
        assertEquals(1, folder.unwatchedCount)
        assertFalse(folder.isWatched)
        assertTrue(folder.isPartiallyWatched)
    }
}

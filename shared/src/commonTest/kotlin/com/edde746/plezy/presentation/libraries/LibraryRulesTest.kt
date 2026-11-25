package com.edde746.plezy.presentation.libraries

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.LibraryFirstCharacter
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.navigation.Route
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class LibraryTabsTest {
    @Test
    fun tabsFollowTheEnumOrderAndGenresOnlyForMoviesAndShows() {
        val all = listOf(LibraryTab.RECOMMENDED, LibraryTab.BROWSE, LibraryTab.COLLECTIONS, LibraryTab.PLAYLISTS, LibraryTab.GENRES)
        assertEquals(all, visibleLibraryTabs(lib("m", MediaKind.MOVIE)))
        assertEquals(all, visibleLibraryTabs(lib("s", MediaKind.SHOW)))
        assertEquals(all - LibraryTab.GENRES, visibleLibraryTabs(lib("a", MediaKind.ARTIST)))
    }

    @Test
    fun sharedLibrariesGetOnlyBrowseAndPlaylists() {
        assertEquals(listOf(LibraryTab.BROWSE, LibraryTab.PLAYLISTS), visibleLibraryTabs(lib("x", shared = true)))
    }

    @Test
    fun aStoredTabIndexOfOlderReleasesReadsAsNone() {
        assertEquals(LibraryTab.GENRES, LibraryTab.of("genres"))
        assertNull(LibraryTab.of("2"))
    }

    @Test
    fun shuffleForOwnVideoAndMusicLibraries() {
        assertTrue(canShuffleLibrary(lib("m", MediaKind.MOVIE)))
        assertTrue(canShuffleLibrary(lib("c", MediaKind.CLIP)))
        assertTrue(canShuffleLibrary(lib("a", MediaKind.ARTIST)))
        assertFalse(canShuffleLibrary(lib("a", MediaKind.ARTIST, shared = true)))
        assertFalse(canShuffleLibrary(lib("m", MediaKind.MOVIE, shared = true)))
        assertFalse(canShuffleLibrary(lib("p", MediaKind.PHOTO)))
        assertTrue(canShuffleLibrary(lib("mixed", MediaKind.UNKNOWN).copy(defaultBrowseKinds = listOf(MediaKind.MOVIE, MediaKind.SHOW))))
    }
}

class LibraryBrowseGroupingTest {
    @Test
    fun movieLibrariesOptionallyIncludeFolders() {
        assertEquals(listOf(BrowseGrouping.MOVIES), browseGroupingOptions(lib("m"), canGroupByFolders = false))
        assertEquals(listOf(BrowseGrouping.MOVIES, BrowseGrouping.FOLDERS), browseGroupingOptions(lib("m"), canGroupByFolders = true))
    }

    @Test
    fun showLibrariesIncludeShowHierarchyBeforeFolders() {
        assertEquals(
            listOf(BrowseGrouping.SHOWS, BrowseGrouping.SEASONS, BrowseGrouping.EPISODES, BrowseGrouping.FOLDERS),
            browseGroupingOptions(lib("s", MediaKind.SHOW), canGroupByFolders = true),
        )
    }

    @Test
    fun musicLibrariesGroupByArtistsAlbumsAndTracks() {
        val music = lib("a", MediaKind.ARTIST)
        assertEquals(listOf(BrowseGrouping.ARTISTS, BrowseGrouping.ALBUMS, BrowseGrouping.TRACKS), browseGroupingOptions(music, canGroupByFolders = false))
        assertEquals(BrowseGrouping.ARTISTS, defaultBrowseGrouping(music, canGroupByFolders = true))
    }

    @Test
    fun sharedLibrariesExposeAllVideoGroupingsAndNeverFolders() {
        val shared = lib("x", shared = true)
        assertEquals(
            listOf(BrowseGrouping.ALL, BrowseGrouping.MOVIES, BrowseGrouping.SHOWS, BrowseGrouping.SEASONS, BrowseGrouping.EPISODES),
            browseGroupingOptions(shared, canGroupByFolders = true),
        )
        assertEquals(BrowseGrouping.ALL, defaultBrowseGrouping(shared, canGroupByFolders = true))
        assertEquals(BrowseGrouping.ALL, normalizeBrowseGrouping(shared, "folders", canGroupByFolders = true))
    }

    @Test
    fun keepsAValidSavedGroupingAndFallsBackFromAnUnavailableOne() {
        val shows = lib("s", MediaKind.SHOW)
        assertEquals(BrowseGrouping.EPISODES, normalizeBrowseGrouping(shows, "episodes", canGroupByFolders = false))
        assertEquals(BrowseGrouping.SHOWS, normalizeBrowseGrouping(shows, "folders", canGroupByFolders = false))
        assertEquals(BrowseGrouping.SHOWS, normalizeBrowseGrouping(shows, null, canGroupByFolders = false))
    }

    @Test
    fun clipLibrariesDefaultToFoldersWhenAvailableAndKeepASavedFlatGrouping() {
        val clips = lib("c", MediaKind.CLIP)
        assertEquals(BrowseGrouping.FOLDERS, normalizeBrowseGrouping(clips, null, canGroupByFolders = true))
        assertEquals(BrowseGrouping.ALL, normalizeBrowseGrouping(clips, null, canGroupByFolders = false))
        assertEquals(BrowseGrouping.ALL, normalizeBrowseGrouping(clips, "all", canGroupByFolders = true))
    }

    @Test
    fun movieLibrariesDefaultToMoviesAndOtherKindsToAll() {
        assertEquals(BrowseGrouping.MOVIES, defaultBrowseGrouping(lib("m"), canGroupByFolders = true))
        val mixed = lib("mixed", MediaKind.UNKNOWN)
        assertEquals(BrowseGrouping.ALL, defaultBrowseGrouping(mixed, canGroupByFolders = true))
        assertEquals(BrowseGrouping.ALL, normalizeBrowseGrouping(mixed, "movies", canGroupByFolders = false))
    }
}

class AlphaJumpTest {
    private val chars = listOf(LibraryFirstCharacter("b", "b", 3), LibraryFirstCharacter("A", "A", 2), LibraryFirstCharacter("#", "#", 1), LibraryFirstCharacter("C", "C", 0))

    @Test
    fun mapsTitleAscendingLettersToCumulativeOffsets() {
        val jump = AlphaJump(chars)
        assertEquals(listOf("#", "A", "B"), jump.letters)
        assertEquals(0, jump.indexFor("#"))
        assertEquals(1, jump.indexFor("A"))
        assertEquals(3, jump.indexFor("B"))
        assertNull(jump.indexFor("C"), "letters without items are dropped")
        assertEquals("A", jump.letterAt(2))
    }

    @Test
    fun mapsTitleDescendingLettersToReversedCumulativeOffsets() {
        val jump = AlphaJump(chars, descending = true)
        assertEquals(listOf("B", "A", "#"), jump.letters)
        assertEquals(0, jump.indexFor("B"))
        assertEquals(3, jump.indexFor("A"))
        assertEquals(5, jump.indexFor("#"))
    }

    @Test
    fun aShortBarKeepsTheFullestLettersInOrder() {
        val jump = AlphaJump(chars)
        assertEquals(listOf("A", "B"), jump.displayLetters(2))
        assertEquals(jump.letters, jump.displayLetters(27))
    }

    @Test
    fun aShortBarSpreadsLettersOfOneSizeEvenlyFromFirstToLast() {
        val jump = AlphaJump(AlphaJump.MEDIA_BROWSER_ALPHABET)
        assertEquals(listOf("#", "B", "D", "F", "H", "J", "L", "N", "P", "R", "T", "V", "X", "Z"), jump.displayLetters(14))
        assertEquals(listOf("#", "M", "Z"), jump.displayLetters(3))
    }

    @Test
    fun aDragDownABarOfAnyHeightReachesEveryLetterInOrder() {
        val counted = AlphaJump((listOf("#") + ('A'..'Z').map { it.toString() }).mapIndexed { i, letter -> LibraryFirstCharacter(letter, letter, i % 5 + 1) })
        for (jump in listOf(AlphaJump(AlphaJump.MEDIA_BROWSER_ALPHABET), counted)) {
            for (count in 1..30) {
                val rows = jump.rows(count)
                val at = "$count rows"
                assertTrue(rows.size <= count, at)
                assertEquals(jump.letters, rows.flatten(), "every letter in one row, in order: $at")
                val reached = (0..1000).map { alphaLetterDown(rows, it / 1000.0) }
                assertEquals(jump.letters, reached.distinct(), "top to bottom crosses every letter in order: $at")
                if (count >= 27) assertTrue(rows.all { it.size == 1 }, "all fit: $at")
            }
        }
    }

    @Test
    fun titleDescendingIsATitleKeyWithTheDescendingFlag() {
        assertTrue(isTitleSortDescending("titleSort:desc", true))
        assertTrue(isTitleSortDescending("SortName", true))
        assertFalse(isTitleSortDescending("SortName", false))
        assertFalse(isTitleSortDescending("addedAt", true))
    }

    @Test
    fun mediaBrowserAlphabetIsHashThenAToZ() {
        assertEquals(27, AlphaJump.MEDIA_BROWSER_ALPHABET.size)
        assertEquals(listOf("#", "A", "B"), AlphaJump(AlphaJump.MEDIA_BROWSER_ALPHABET).letters.take(3))
    }
}

class LibraryListEntriesTest {
    private val libraries = listOf(lib("1", server = "a", title = "Movies"), lib("2", server = "b", title = "Shows"), lib("3", server = "a", title = "Kids"))

    @Test
    fun groupsLibrariesByServerInFirstAppearanceOrder() {
        val entries = libraryListEntries(libraries, groupByServer = true)
        assertEquals(
            listOf("header:a", "row:1", "row:3", "header:b", "row:2"),
            entries.map { if (it is LibraryListEntry.Header) "header:${it.serverId}" else "row:${(it as LibraryListEntry.Row).library.id}" },
        )
        assertTrue(entries.filterIsInstance<LibraryListEntry.Row>().none { it.showServerName })
    }

    @Test
    fun showsPerRowServerNamesWithoutGroupingWhenMultipleServersAreVisible() {
        val entries = libraryListEntries(libraries, groupByServer = false)
        assertTrue(entries.all { it is LibraryListEntry.Row && it.showServerName })
        val single = libraryListEntries(libraries.filter { it.serverId == "a" }, groupByServer = true)
        assertTrue(single.all { it is LibraryListEntry.Row && !it.showServerName })
    }

    @Test
    fun reconcileLibraryOrderKeepsTheSheetOrderOverTheCurrentLibraries() {
        val sheet = listOf(libraries[2], libraries[0], lib("gone", server = "a"))
        val current = libraries + lib("new", server = "b")
        assertEquals(listOf("3", "1", "2", "new"), reconcileLibraryOrder(sheet, current).map { it.id })
    }
}

class DetailRouteTest {
    @Test
    fun anEpisodeOpensItsShowAtItsSeason() {
        val episode = mediaItem("e1", MediaKind.EPISODE).copy(parentId = "season", grandparentId = "show")
        assertEquals(Route.MediaDetail(ServerId("s1"), "show", initialSeasonId = "season", initialEpisodeId = "e1"), detailRouteFor(episode))
    }

    @Test
    fun aCollectionOpensItsOwnScreenAndAMovieItsDetail() {
        assertEquals(Route.CollectionDetail(ServerId("s1"), "c"), detailRouteFor(mediaItem("c", MediaKind.COLLECTION)))
        assertEquals(Route.MediaDetail(ServerId("s1"), "m"), detailRouteFor(mediaItem("m")))
        assertEquals(Route.MusicArtist("s1", "ar"), detailRouteFor(mediaItem("ar", MediaKind.ARTIST)))
        assertEquals(Route.MusicAlbum("s1", "al"), detailRouteFor(mediaItem("al", MediaKind.ALBUM)))
    }

    @Test
    fun pageSizesFollowTheBackend() {
        assertEquals(200, browseFetchSize(BackendKind.PLEX))
        assertEquals(72, browseFetchSize(BackendKind.EMBY))
        assertEquals(100, initialBrowseFetchSize(BackendKind.PLEX, visibleRows = 2, columns = 5))
        assertEquals(72, initialBrowseFetchSize(BackendKind.JELLYFIN, visibleRows = 6, columns = 8))
        assertEquals(36, initialBrowseFetchSize(BackendKind.JELLYFIN, visibleRows = 1, columns = 2))
    }

    @Test
    fun aMidRangeFirstPageIsUnclampedAndNoLayoutFallsBackToTheFetchSize() {
        assertEquals(108, initialBrowseFetchSize(BackendKind.PLEX, visibleRows = 5, columns = 6))
        assertEquals(70, initialBrowseFetchSize(BackendKind.JELLYFIN, visibleRows = 4, columns = 7))
        assertEquals(200, initialBrowseFetchSize(BackendKind.PLEX, visibleRows = 0, columns = 6))
        assertEquals(72, initialBrowseFetchSize(BackendKind.EMBY, visibleRows = 4, columns = 0))
    }
}

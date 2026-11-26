package com.edde746.plezy.presentation.navigation

import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.navigation.TopLevelDestination.DOWNLOADS
import com.edde746.plezy.presentation.navigation.TopLevelDestination.EXPLORE
import com.edde746.plezy.presentation.navigation.TopLevelDestination.HOME
import com.edde746.plezy.presentation.navigation.TopLevelDestination.LIBRARIES
import com.edde746.plezy.presentation.navigation.TopLevelDestination.SEARCH
import com.edde746.plezy.presentation.navigation.TopLevelDestination.SETTINGS
import com.edde746.plezy.presentation.settings.SettingsPageId
import com.edde746.plezy.trackers.TrackerService
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class NavigationHighlightTest {
    private val all = TopLevelDestination.entries.toList()
    private val server = ServerId("server_1")
    private val catalogItem = CatalogItem(CatalogSourceId.TRAKT, MediaKind.MOVIE, "Title", CatalogItemIds(trakt = 1))

    @Test
    fun everyScreenBelongsToItsDestinationOrToNone() {
        val owners: Map<Route, TopLevelDestination?> = mapOf(
            Route.Home to HOME,
            Route.LiveTv to HOME,
            Route.LiveTvShowSchedule("News", "server_1") to HOME,
            Route.HubDetail("hub", "Recently Added") to HOME,
            Route.Libraries to LIBRARIES,
            Route.Downloads to DOWNLOADS,
            Route.SyncRules to DOWNLOADS,
            Route.MediaDetail(server, "1") to LIBRARIES,
            Route.MediaDetail(server, "1", offline = true) to DOWNLOADS,
            Route.Person(server, "2", "Name") to LIBRARIES,
            Route.CollectionDetail(server, "3") to LIBRARIES,
            Route.CollectionDetail(server, "3", offline = true) to DOWNLOADS,
            Route.PlaylistDetail(server, "4") to LIBRARIES,
            Route.MusicArtist("server_1", "5") to LIBRARIES,
            Route.MusicAlbum("server_1", "6") to LIBRARIES,
            Route.MusicPlaylist("server_1", "7") to LIBRARIES,
            Route.MetadataEdit(server, "8") to LIBRARIES,
            Route.PlexMatch(server, "9", "Title", 2020, matched = true) to LIBRARIES,
            Route.Explore to EXPLORE,
            Route.CatalogDetail(catalogItem) to EXPLORE,
            Route.CatalogSearch(CatalogSourceId.TRAKT) to EXPLORE,
            Route.ExploreRow("trending", "Trending") to EXPLORE,
            Route.SeerrPerson(31, "Tom Hanks") to EXPLORE,
            Route.Search to SEARCH,
            Route.Settings to SETTINGS,
            Route.SettingsPage(SettingsPageId.GENERAL) to SETTINGS,
            Route.Services to SETTINGS,
            Route.TrackerSettings(TrackerService.TRAKT) to SETTINGS,
            Route.TrackerLibraryFilter(TrackerService.TRAKT) to SETTINGS,
            Route.SeerrConnect to SETTINGS,
            Route.SeerrSettings to SETTINGS,
            Route.ProfilePicker(required = false) to SETTINGS,
            Route.ProfilePicker(required = false, manage = true) to SETTINGS,
            Route.AddProfile to SETTINGS,
            Route.ProfileDetail("profile") to SETTINGS,
            Route.AddConnection(null) to SETTINGS,
            Route.AddPlexAccount(null) to SETTINGS,
            Route.AddMediaBrowser(MediaBrowserDialect.JELLYFIN, null) to SETTINGS,
            Route.EditConnection("connection") to SETTINGS,
            Route.BorrowConnection("profile") to SETTINGS,
            Route.ProfilePicker(required = true) to null,
            Route.SignIn to null,
            Route.Player to null,
            Route.NowPlaying to null,
            Route.WatchTogether to null,
            Route.SeerrRequest(1, MediaKind.MOVIE, "Title") to null,
        )
        for ((route, owner) in owners) assertEquals(owner, TopLevelDestination.owner(route), "$route")
    }

    @Test
    fun aPushedScreenHighlightsItsDestinationWhereverItWasPushedFrom() {
        assertEquals(LIBRARIES, TopLevelDestination.highlightedIn(listOf(Route.Home, Route.MusicArtist("server_1", "5")), all))
        assertEquals(SETTINGS, TopLevelDestination.highlightedIn(listOf(Route.Home, Route.ProfilePicker(required = false)), all))
        assertEquals(EXPLORE, TopLevelDestination.highlightedIn(listOf(Route.Search, Route.CatalogDetail(catalogItem)), all))
        assertEquals(HOME, TopLevelDestination.highlightedIn(listOf(Route.Home, Route.LiveTv), all))
        assertEquals(SEARCH, TopLevelDestination.highlightedIn(listOf(Route.Search), all))
    }

    @Test
    fun aScreenOfNoDestinationOrOfOneNotShownLeavesTheHighlightToTheScreenUnderIt() {
        val album = Route.MusicAlbum("server_1", "6")
        assertEquals(LIBRARIES, TopLevelDestination.highlightedIn(listOf(Route.Home, album, Route.WatchTogether), all))
        assertEquals(HOME, TopLevelDestination.highlightedIn(listOf(Route.Home, Route.WatchTogether), all))
        val noExplore = all - EXPLORE
        assertEquals(SEARCH, TopLevelDestination.highlightedIn(listOf(Route.Search, Route.CatalogDetail(catalogItem)), noExplore))
        assertNull(TopLevelDestination.highlightedIn(listOf(Route.SignIn), all))
    }

    private fun library(id: String, kind: MediaKind, serverId: String = "server_1") = MediaLibrary(id, BackendKind.JELLYFIN, id, kind, serverId = serverId)

    private val movies = library("movies", MediaKind.MOVIE)
    private val shows = library("shows", MediaKind.SHOW)
    private val music = library("music", MediaKind.ARTIST)
    private val otherMusic = library("other music", MediaKind.ARTIST, "server_2")
    private val libraries = listOf(movies, shows, music, otherMusic)

    private fun over(vararg screens: Route, placed: Map<Route, String> = emptyMap(), selected: MediaLibrary? = null) =
        TopLevelDestination.highlightedLibrary(screens.toList(), all, libraries, placed, selected)

    @Test
    fun aTitleOpenedFromHomeStandsForItsOwnLibraryAndAnUnknownOneForNone() {
        val movie = Route.MediaDetail(server, "1")
        val placed = mapOf<Route, String>(movie to movies.globalKey)
        assertEquals(movies, over(Route.Home, movie, placed = placed))
        // A screen opened from it with no library of its own (an actor) keeps the title's.
        assertEquals(movies, over(Route.Home, movie, Route.Person(server, "2", "Name"), placed = placed))
        // Unknown: the generic Libraries, not Libraries' selected library.
        assertNull(over(Route.Home, movie, selected = shows))
        // Over Libraries the title's own library, not the selected one; at its root the selected one.
        assertEquals(movies, over(Route.Libraries, movie, placed = placed, selected = shows))
        assertEquals(shows, over(Route.Libraries, selected = shows))
    }

    @Test
    fun anArtistAlbumOrPlaylistStandsForItsServersMusicLibrary() {
        assertEquals(otherMusic, over(Route.Home, Route.MusicAlbum("server_2", "6")))
        assertEquals(music, over(Route.Home, Route.MusicPlaylist("server_1", "7"), Route.WatchTogether))
        assertNull(over(Route.Home, Route.MusicArtist("server_3", "5")))
    }

    @Test
    fun aScreenOfAnotherDestinationOnTopStandsForNoLibrary() {
        val movie = Route.MediaDetail(server, "1")
        val placed = mapOf<Route, String>(movie to movies.globalKey)
        assertNull(over(Route.Home, movie, Route.ProfileDetail("profile"), placed = placed))
        assertNull(over(Route.Home, Route.LiveTv, selected = shows))
    }

    @Test
    fun aTitleIsPlacedInTheLibraryItWasOpenedUnderElseTheOneItsScreenFindsUntilItLeaves() {
        val navigator = PlezyNavigator(Route.Home)
        val card = MediaItem(id = "1", backend = BackendKind.JELLYFIN, kind = MediaKind.MOVIE, libraryId = "movies")
        val opened = Route.MediaDetail(server, "1").seeded(card)
        navigator.navigate(opened)
        assertEquals(movies.globalKey, navigator.stacks.value.libraries[opened])
        // The library it was opened under wins over the one its detail finds (Jellyfin's ancestors).
        navigator.placeIn(opened, shows.globalKey)
        assertEquals(movies.globalKey, navigator.stacks.value.libraries[opened])

        val linked = Route.MediaDetail(server, "2")
        navigator.navigate(linked)
        assertNull(navigator.stacks.value.libraries[linked])
        navigator.placeIn(linked, shows.globalKey)
        assertEquals(shows.globalKey, navigator.stacks.value.libraries[linked])
        assertEquals(shows, over(Route.Home, opened, linked, placed = navigator.stacks.value.libraries))

        navigator.back()
        navigator.back()
        assertEquals(emptyMap(), navigator.stacks.value.libraries)
        navigator.placeIn(linked, shows.globalKey)
        assertEquals(emptyMap(), navigator.stacks.value.libraries)
    }
}

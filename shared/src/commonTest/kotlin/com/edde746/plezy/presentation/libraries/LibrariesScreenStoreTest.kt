package com.edde746.plezy.presentation.libraries

import com.edde746.plezy.app.testData
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.LibraryChangeEvent
import com.edde746.plezy.model.LibraryFilter
import com.edde746.plezy.model.LibraryFilterResult
import com.edde746.plezy.model.LibrarySortDirection
import com.edde746.plezy.model.MediaFilter
import com.edde746.plezy.model.MediaHub
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.model.MediaPlaylist
import com.edde746.plezy.model.MediaSort
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.plex.jsonResponse
import com.edde746.plezy.plex.testPlexClient
import com.edde746.plezy.presentation.browse.LoadState
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.home.viewAllSortPick
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.servers.DeletionEvent
import com.edde746.plezy.servers.DeletionOrigin
import com.edde746.plezy.servers.HiddenLibrariesStore
import com.edde746.plezy.servers.LibrariesStore
import com.edde746.plezy.servers.LibraryRefreshType
import com.edde746.plezy.servers.WatchStateChangeType
import com.edde746.plezy.servers.WatchStateEvent
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.strings.T
import io.ktor.client.request.HttpRequestData
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Runnable
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import kotlinx.coroutines.withContext
import kotlin.coroutines.CoroutineContext
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

/** The Libraries screen over [list] on one Jellyfin server, [backend]. */
private class Harness(val test: TestScope, var list: List<MediaLibrary>) {
    val data = test.testData()
    val prefs = data.libraryPrefs
    val events = MutableSharedFlow<LibraryChangeEvent>(extraBufferCapacity = 16)
    val backend = BrowseBackend()
    val visible = MutableStateFlow(true)
    val routes = mutableListOf<Route>()
    var fetches = 0
    lateinit var libraries: LibrariesStore
    val hidden = HiddenLibrariesStore(prefs, scope = test.backgroundScope)

    suspend fun start(): Harness {
        libraries = loadedLibraries(prefs, test.backgroundScope, events) { fetches++; list }
        return this
    }

    /** The servers the user administers. */
    var admins: Set<String> = emptySet()

    /** The libraries whose server is connected. */
    var connected: (MediaLibrary) -> Boolean = { true }
    val notices = mutableListOf<Pair<String, Boolean>>()

    fun screen(playback: LibraryPlayback? = null) = LibrariesScreenStore(
        libraries = libraries,
        hidden = hidden,
        prefs = prefs,
        settings = data.deviceSettings,
        clientFor = { if (connected(it)) backend else null },
        libraryEvents = events,
        watchStates = MutableSharedFlow(),
        deletions = MutableSharedFlow(),
        refreshes = MutableSharedFlow(),
        visible = visible,
        navigate = { routes += it },
        playback = playback,
        menu = null,
        canAdminister = { it.serverId in admins },
        notify = { text, isError -> notices += text to isError },
        parentScope = test.backgroundScope,
    )

    val watchStates = MutableSharedFlow<WatchStateEvent>(extraBufferCapacity = 16)
    val deletions = MutableSharedFlow<DeletionEvent>(extraBufferCapacity = 16)
    val refreshes = MutableSharedFlow<LibraryRefreshType>(extraBufferCapacity = 16)
    val errors = mutableListOf<String>()

    fun context(library: MediaLibrary, client: MediaBackend = backend) = LibraryTabContext(
        library,
        client,
        libraries,
        events,
        watchStates = watchStates,
        deletions = deletions,
        refreshes = refreshes,
        visible = { visible.value },
        timeSource = test.testScheduler.timeSource,
        notifyError = { errors += it },
    )
}

/** Runs the stores' work, which lives in the background scope (advanceUntilIdle leaves that alone), past every pacing window. */
private fun TestScope.settle() {
    advanceTimeBy(10.minutes)
    runCurrent()
}

private val movies = lib("movies", MediaKind.MOVIE)
private val shows = lib("shows", MediaKind.SHOW)
private val shared = lib("shared", MediaKind.MOVIE, shared = true)

class LibrariesScreenStoreTest {
    @Test
    fun theSavedLibraryIsSelectedWhileVisibleElseTheFirstVisible() = runTest {
        val h = Harness(this, listOf(movies, shows)).start()
        h.prefs.setSelectedLibraryKey(shows.globalKey)
        val screen = h.screen()
        settle()
        assertEquals(shows.globalKey, screen.state.value.selected?.globalKey)
        assertEquals(LibrariesLoad.CONTENT, screen.state.value.load)

        val again = Harness(this, listOf(movies, shows)).start()
        again.prefs.setSelectedLibraryKey(shows.globalKey)
        again.hidden.hideLibrary(shows.globalKey)
        val other = again.screen()
        settle()
        assertEquals(movies.globalKey, other.state.value.selected?.globalKey)
    }

    @Test
    fun aSidebarSelectionAtFirstMountSurvivesInitialization() = runTest {
        val h = Harness(this, listOf(movies, shows)).start()
        h.prefs.setSelectedLibraryKey(movies.globalKey)
        h.hidden.hideLibrary(shows.globalKey)
        val screen = h.screen()
        screen.selectLibrary(shows.globalKey)
        settle()
        assertEquals(shows.globalKey, screen.state.value.selected?.globalKey, "a hidden library opened from the rail stays")
    }

    @Test
    fun librariesArrivingAfterAnEmptyFirstLoadSelectTheDefaultLibrary() = runTest {
        val h = Harness(this, emptyList()).start()
        val screen = h.screen()
        settle()
        assertEquals(LibrariesLoad.NO_LIBRARIES, screen.state.value.load)
        h.list = listOf(movies)
        screen.refresh()
        settle()
        assertEquals(2, h.fetches, "the toolbar refresh reloads the library list while none is selected")
        assertEquals(movies.globalKey, screen.state.value.selected?.globalKey)
    }

    @Test
    fun everyLibraryHiddenIsItsOwnState() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.hidden.hideLibrary(movies.globalKey)
        val screen = h.screen()
        settle()
        assertEquals(LibrariesLoad.ALL_HIDDEN, screen.state.value.load)
    }

    @Test
    fun restorationAppliesTheSavedTabAndAUserPickIsSaved() = runTest {
        val h = Harness(this, listOf(movies, shows)).start()
        h.prefs.setTab(movies.globalKey, "collections")
        val screen = h.screen()
        settle()
        assertEquals(LibraryTab.COLLECTIONS, screen.state.value.tab)
        screen.selectTab(LibraryTab.GENRES)
        settle()
        assertEquals("genres", h.prefs.tab(movies.globalKey))
    }

    @Test
    fun aTabSetChangeRestoresTheDestinationLibrarysSavedTab() = runTest {
        val h = Harness(this, listOf(movies, shared)).start()
        h.prefs.setTab(shared.globalKey, "playlists")
        val screen = h.screen()
        settle()
        screen.selectTab(LibraryTab.COLLECTIONS)
        settle()
        screen.selectLibrary(shared.globalKey)
        settle()
        assertEquals(listOf(LibraryTab.BROWSE, LibraryTab.PLAYLISTS), screen.state.value.tabs)
        assertEquals(LibraryTab.PLAYLISTS, screen.state.value.tab)
        assertEquals("playlists", h.prefs.tab(shared.globalKey), "the destination's saved tab is kept")
        assertEquals("collections", h.prefs.tab(movies.globalKey))
    }

    @Test
    fun aLibraryWithNoSavedTabOpensOnBrowseWhateverTabWasShown() = runTest {
        val h = Harness(this, listOf(movies, shows)).start()
        val screen = h.screen()
        settle()
        screen.selectTab(LibraryTab.COLLECTIONS)
        screen.selectLibrary(shows.globalKey)
        settle()
        assertEquals(LibraryTab.BROWSE, screen.state.value.tab)
        assertNull(h.prefs.tab(shows.globalKey), "the default isn't saved as the library's tab")
        screen.selectLibrary(movies.globalKey)
        settle()
        assertEquals(LibraryTab.COLLECTIONS, screen.state.value.tab, "a library's own saved tab still wins")
    }

    @Test
    fun aLibraryWithNoSavedTabOpensOnBrowseWithItsItemsLoaded() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.backend.pageItems = (1..3).map { mediaItem("m$it") }
        val screen = h.screen()
        settle()
        assertEquals(LibraryTab.BROWSE, screen.state.value.tab)
        val browse = screen.browse()!!.state.value
        assertEquals(LoadState.CONTENT, browse.load)
        assertEquals(3, browse.total)
        assertEquals(0, h.backend.hubCalls, "Recommended loads only once picked")
        assertNull(h.prefs.tab(movies.globalKey), "the default isn't saved as the library's tab")
    }

    @Test
    fun turningShowUnwatchedCountOffDropsTheBadgesOfTheCardsShownAtOnce() = runTest {
        val h = Harness(this, listOf(shows)).start()
        h.backend.pageItems = listOf(mediaItem("show", MediaKind.SHOW).copy(leafCount = 6, viewedLeafCount = 2))
        val screen = h.screen()
        settle()
        assertEquals("4", screen.browse()!!.state.value.cards[0]?.unwatchedLabel)

        h.data.deviceSettings.set(AppSettings.showUnwatchedCount, false)
        settle()
        assertNull(screen.browse()!!.state.value.cards[0]?.unwatchedLabel, "the card on screen drops its badge without a reload")

        h.data.deviceSettings.set(AppSettings.showUnwatchedCount, true)
        settle()
        assertEquals("4", screen.browse()!!.state.value.cards[0]?.unwatchedLabel)
    }

    @Test
    fun openingAGenreShowsBrowseFilteredToThatGenreAlone() = runTest {
        val h = Harness(this, listOf(shows)).start()
        h.prefs.setGrouping(shows.globalKey, "episodes")
        h.prefs.setFilters(listOf(LibraryFilter("year", listOf("2001"))), shows.globalKey)
        val screen = h.screen()
        settle()
        screen.openGenre("42")
        settle()
        assertEquals(LibraryTab.BROWSE, screen.state.value.tab)
        assertEquals("browse", h.prefs.tab(shows.globalKey))
        val browse = screen.browse()!!.state.value
        assertEquals(listOf(LibraryFilter("genre", listOf("42"))), browse.selectedFilters)
        assertEquals(BrowseGrouping.SHOWS, browse.grouping)
        assertEquals(listOf(LibraryFilter("genre", listOf("42"))), h.backend.queries.last().filters)
        assertTrue(screen.state.value.filtersActive)
    }

    @Test
    fun hidingTheSelectedLibrarySelectsTheFirstVisibleAndUnhidingChangesNothing() = runTest {
        val h = Harness(this, listOf(movies, shows)).start()
        val screen = h.screen()
        settle()
        screen.setHidden(movies.globalKey, hide = true)
        settle()
        assertEquals(shows.globalKey, screen.state.value.selected?.globalKey)
        screen.setHidden(movies.globalKey, hide = false)
        settle()
        assertEquals(shows.globalKey, screen.state.value.selected?.globalKey)
        assertEquals(setOf<String>(), h.prefs.hiddenLibraries())
    }

    @Test
    fun movingALibrarySavesTheOrderOverTheLoadedLibraries() = runTest {
        val h = Harness(this, listOf(movies, shows)).start()
        val screen = h.screen()
        settle()
        screen.moveLibrary(movies.globalKey, 1)
        settle()
        assertEquals(listOf(shows.globalKey, movies.globalKey), h.prefs.libraryOrder())
        assertEquals(listOf(shows, movies), screen.state.value.libraries)
        screen.moveLibrary(movies.globalKey, 2)
        screen.moveLibrary("missing", 0)
        settle()
        assertEquals(listOf(shows, movies), screen.state.value.libraries)
    }

    @Test
    fun anEpisodeCardOpensItsShowAtTheEpisode() = runTest {
        val h = Harness(this, listOf(shows)).start()
        h.prefs.setTab(shows.globalKey, "browse")
        h.backend.pageItems = listOf(mediaItem("e1", MediaKind.EPISODE).copy(parentId = "season-1", grandparentId = "show-1"))
        val screen = h.screen()
        settle()
        screen.browse()
        settle()
        screen.open(h.backend.pageItems.single().globalKey)
        assertEquals(listOf<Route>(Route.MediaDetail(ServerId("s1"), "show-1", "season-1", "e1")), h.routes)
    }

    @Test
    fun shuffleShowsOnlyWithPlaybackAndPlaysTheSelectedLibrary() = runTest {
        val h = Harness(this, listOf(movies)).start()
        assertFalse(h.screen().also { settle() }.state.value.canShuffle)
        val played = mutableListOf<LibraryPlayRequest>()
        val screen = h.screen { played += it }
        settle()
        assertTrue(screen.state.value.canShuffle)
        screen.shuffle()
        settle()
        assertEquals(listOf<LibraryPlayRequest>(LibraryPlayRequest.ShuffleLibrary(movies)), played)
    }

    @Test
    fun aMusicLibraryOffersShuffleAndPlaysItself() = runTest {
        val music = lib("music", MediaKind.ARTIST)
        val h = Harness(this, listOf(music)).start()
        val played = mutableListOf<LibraryPlayRequest>()
        val screen = h.screen { played += it }
        settle()
        assertTrue(screen.state.value.canShuffle)
        screen.shuffle()
        settle()
        assertEquals(listOf<LibraryPlayRequest>(LibraryPlayRequest.ShuffleLibrary(music)), played)
    }

    @Test
    fun libraryAdminActionsAreOfferedOnlyOnServersTheUserAdministers() = runTest {
        val plex = lib("plexlib", server = "s2", backend = BackendKind.PLEX)
        val h = Harness(this, listOf(movies, plex)).start()
        val screen = h.screen()
        settle()
        assertEquals(emptyList(), screen.adminActions(movies))
        screen.runAdminAction(movies, LibraryAdminAction.SCAN)
        settle()
        assertEquals(emptyList(), h.backend.adminCalls, "an action the user may not run never reaches the server")

        h.admins = setOf("s1", "s2")
        assertEquals(listOf(LibraryAdminAction.SCAN, LibraryAdminAction.REFRESH_METADATA), screen.adminActions(movies))
        assertEquals(
            listOf(LibraryAdminAction.SCAN, LibraryAdminAction.ANALYZE, LibraryAdminAction.REFRESH_METADATA, LibraryAdminAction.EMPTY_TRASH),
            screen.adminActions(plex),
        )
    }

    @Test
    fun anAdminActionReportsProgressThenTheServersAnswer() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.admins = setOf("s1")
        val screen = h.screen()
        settle()
        screen.runAdminAction(movies, LibraryAdminAction.REFRESH_METADATA)
        settle()
        assertEquals(listOf("refresh:movies"), h.backend.adminCalls)
        assertEquals(listOf(false, false), h.notices.map { it.second })

        h.notices.clear()
        h.backend.adminFailure = MediaServerHttpException(MediaServerHttpErrorType.CONNECTION_TIMEOUT, "private detail")
        screen.runAdminAction(movies, LibraryAdminAction.SCAN)
        settle()
        assertEquals(listOf(false, true), h.notices.map { it.second })
        assertTrue(h.notices.last().first.contains(T.errors.reasonTimedOut))
        assertFalse(h.notices.last().first.contains("private detail"))
    }

    @Test
    fun anAdminActionRefusesALibraryWhoseServerIsAbsent() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.admins = setOf("s1")
        h.connected = { false }
        val screen = h.screen()
        settle()
        screen.runAdminAction(movies, LibraryAdminAction.SCAN)
        settle()
        assertEquals(emptyList(), h.backend.adminCalls)
        assertEquals(listOf(true), h.notices.map { it.second }, "only the failure shows")
    }

    @Test
    fun aMusicLibrarysTrackPlaysAndItsArtistOpensTheArtist() = runTest {
        val music = lib("music", MediaKind.ARTIST)
        val h = Harness(this, listOf(music)).start()
        val artist = mediaItem("ar", MediaKind.ARTIST)
        val track = mediaItem("t", MediaKind.TRACK)
        h.backend.pageItems = listOf(artist, track)
        val played = mutableListOf<LibraryPlayRequest>()
        val screen = h.screen { played += it }
        settle()
        screen.selectTab(LibraryTab.BROWSE)
        settle()
        screen.open(track.globalKey)
        screen.open(artist.globalKey)
        settle()
        assertEquals(listOf<LibraryPlayRequest>(LibraryPlayRequest.Track(track)), played)
        assertEquals(listOf<Route>(Route.MusicArtist("s1", "ar")), h.routes)
    }

    @Test
    fun aPhotoOpensNothingAndSaysPhotosAreUnsupported() = runTest {
        val photos = lib("photos", MediaKind.PHOTO)
        val h = Harness(this, listOf(photos)).start()
        val photo = mediaItem("p", MediaKind.PHOTO)
        h.backend.pageItems = listOf(photo)
        val screen = h.screen()
        settle()
        screen.selectTab(LibraryTab.BROWSE)
        settle()
        screen.open(photo.globalKey)
        settle()
        assertEquals(emptyList(), h.routes)
        assertEquals(listOf(T.messages.photosNotSupported to false), h.notices)
    }

    @Test
    fun theToolbarRefreshWithALibrarySelectedReloadsEveryTabMadeSoFar() = runTest {
        val h = Harness(this, listOf(movies)).start()
        val screen = h.screen()
        settle()
        screen.recommended()
        settle()
        val hubs = h.backend.hubCalls
        val pages = h.backend.queries.size
        screen.refresh()
        settle()
        assertEquals(hubs + 1, h.backend.hubCalls, "Recommended loads again")
        assertEquals(pages + 1, h.backend.queries.size, "Browse loads again")
        assertTrue(h.backend.collectionRequests.isEmpty(), "a tab never made stays unmade")
        assertEquals(1, h.fetches, "the library list isn't refetched")
        assertEquals(movies.globalKey, screen.state.value.selected?.globalKey)
    }

    @Test
    fun anEmptyCollectionsOrPlaylistsTabSaysSo() = runTest {
        val h = Harness(this, listOf(movies)).start()
        val collections = LibraryCollectionsStore(h.context(movies), backgroundScope)
        val playlists = LibraryPlaylistsStore(h.context(movies), backgroundScope)
        collections.reload()
        playlists.reload()
        settle()
        assertEquals(LoadState.EMPTY, collections.state.value.load)
        assertEquals(LoadState.EMPTY, playlists.state.value.load)
    }

    @Test
    fun aMusicLibrarysServerWideCollectionsAreSquareOnlyWhenTheirItemsAreMusic() = runTest {
        val music = lib("music", MediaKind.ARTIST)
        val h = Harness(this, listOf(music)).start()
        h.backend.collections = listOf(mediaItem("c1", MediaKind.COLLECTION))
        val jellyfin = LibraryCollectionsStore(h.context(music), backgroundScope)
        jellyfin.reload()
        settle()
        assertEquals(CardShape.POSTER, jellyfin.state.value.shape)
        h.backend.collections = listOf(mediaItem("c1", MediaKind.COLLECTION, backend = BackendKind.PLEX))
        val plex = LibraryCollectionsStore(h.context(music), backgroundScope)
        plex.reload()
        settle()
        assertEquals(CardShape.SQUARE, plex.state.value.shape)
    }
}

class LibraryTabStoreTest {
    private fun hub(vararg ids: String) = MediaHub("recent", "Recently Added", "movie", ids.map { mediaItem(it) })

    @Test
    fun aPushMarkedLibraryReloadsOnceWhenItsTabIsNextActivated() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.backend.hubs = listOf(hub("a"))
        val store = LibraryRecommendedStore(h.context(movies), backgroundScope)
        store.reload()
        settle()
        h.events.emit(LibraryChangeEvent(ServerId("s1"), setOf("movies"), itemsAdded = true))
        settle()
        assertEquals(1, h.backend.hubCalls, "an inactive tab never fetches on a push")
        store.setActive(true)
        settle()
        assertEquals(2, h.backend.hubCalls)
        store.setActive(false)
        store.setActive(true)
        settle()
        assertEquals(2, h.backend.hubCalls, "the reload credited the push")
    }

    @Test
    fun aFailedActivationReloadLeavesTheLibraryStale() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.backend.hubs = listOf(hub("a"))
        val store = LibraryRecommendedStore(h.context(movies), backgroundScope)
        store.reload()
        settle()
        h.events.emit(LibraryChangeEvent(ServerId("s1"), setOf("movies"), itemsUpdated = true))
        settle()
        h.backend.hubsFailure = IllegalStateException("down")
        store.setActive(true)
        settle()
        assertTrue(store.isStale)
        h.backend.hubsFailure = null
        store.setActive(false)
        store.setActive(true)
        settle()
        assertFalse(store.isStale)
        assertEquals(3, h.backend.hubCalls)
    }

    @Test
    fun aLivePushSwapsItemsInPlaceWithoutClearing() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.backend.hubs = listOf(hub("a"))
        val store = LibraryRecommendedStore(h.context(movies), backgroundScope)
        store.setActive(true)
        store.reload()
        settle()
        h.backend.hubs = listOf(hub("a", "b"))
        val seen = mutableListOf<LoadState>()
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { store.state.collect { seen += it.load } }
        h.events.emit(LibraryChangeEvent(ServerId("s1"), setOf("movies"), itemsAdded = true))
        runCurrent()
        advanceTimeBy(2.seconds)
        assertEquals(1, h.backend.hubCalls, "a burst is merged over 3 s")
        settle()
        assertEquals(2, h.backend.hubCalls)
        assertEquals(listOf("a", "b"), store.state.value.items.single().items.map { it.title })
        assertFalse(LoadState.LOADING in seen)
    }

    @Test
    fun aLivePushForADifferentLibraryOrAHiddenScreenDoesNothing() = runTest {
        val h = Harness(this, listOf(movies, shows)).start()
        h.backend.hubs = listOf(hub("a"))
        val store = LibraryRecommendedStore(h.context(movies), backgroundScope)
        store.setActive(true)
        store.reload()
        settle()
        h.events.emit(LibraryChangeEvent(ServerId("s1"), setOf("shows"), itemsAdded = true))
        settle()
        h.visible.value = false
        h.events.emit(LibraryChangeEvent(ServerId("s1"), setOf("movies"), itemsAdded = true))
        settle()
        assertEquals(1, h.backend.hubCalls)
        h.visible.value = true
        store.onSurfaceVisible()
        settle()
        assertEquals(2, h.backend.hubCalls, "the push dropped while hidden replays once visible")
    }

    @Test
    fun aPushLandingMidFetchKeepsTheLibraryStale() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.backend.hubs = listOf(hub("a"))
        h.backend.gate = CompletableDeferred()
        val store = LibraryRecommendedStore(h.context(movies), backgroundScope)
        store.reload()
        runCurrent()
        h.events.emit(LibraryChangeEvent(ServerId("s1"), setOf("movies"), itemsAdded = true))
        runCurrent()
        h.backend.gate!!.complete(Unit)
        settle()
        assertEquals(LoadState.CONTENT, store.state.value.load)
        assertTrue(store.isStale)
    }

    @Test
    fun recommendedPutsContinueWatchingFirstAndDropsEmptyHubs() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.backend.hubs = listOf(hub("a"), MediaHub("empty", "Empty", "movie", emptyList()), MediaHub("cw", "Continue Watching", "movie", listOf(mediaItem("c")), identifier = "continueWatching"))
        val store = LibraryRecommendedStore(h.context(movies), backgroundScope)
        store.reload()
        settle()
        assertEquals(listOf(true, false), store.state.value.items.map { it.continueWatching })
    }

    @Test
    fun aDeletionEvictsTheItemAndWhatItHeldAndOnlyALocalOneReloads() = runTest {
        val h = Harness(this, listOf(shows)).start()
        val show = mediaItem("show", MediaKind.SHOW)
        val episode = mediaItem("ep", MediaKind.EPISODE).copy(parentId = "season", grandparentId = "show")
        val other = mediaItem("other", MediaKind.SHOW)
        h.backend.hubs = listOf(MediaHub("recent", "Recent", "show", listOf(show, other)), MediaHub("eps", "Episodes", "episode", listOf(episode)))
        val store = LibraryRecommendedStore(h.context(shows), backgroundScope)
        store.reload()
        settle()

        h.deletions.emit(DeletionEvent("ep", ServerId("s1"), listOf("season", "show"), MediaKind.EPISODE, origin = DeletionOrigin.SERVER_PUSH))
        settle()
        assertEquals(listOf(listOf("show", "other")), store.state.value.items.map { hub -> hub.items.map { it.title } }, "an episode's show stays")
        assertEquals(1, h.backend.hubCalls, "a pushed deletion leaves the refetch to the library change")

        h.backend.hubs = listOf(MediaHub("recent", "Recent", "show", listOf(other)))
        h.deletions.emit(DeletionEvent("show", ServerId("s1"), emptyList(), MediaKind.SHOW))
        settle()
        assertEquals(listOf(listOf("other")), store.state.value.items.map { hub -> hub.items.map { it.title } })
        assertEquals(2, h.backend.hubCalls, "a deletion made here reloads")
    }

    @Test
    fun aContinueWatchingRemovalDropsTheCardAndReloads() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.backend.hubs = listOf(MediaHub("cw", "Continue Watching", "movie", listOf(mediaItem("c"), mediaItem("d")), identifier = "continueWatching"), hub("c"))
        val store = LibraryRecommendedStore(h.context(movies), backgroundScope)
        store.reload()
        settle()
        val seen = mutableListOf<List<String>>()
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { store.state.collect { state -> seen += state.items.first().items.map { it.title } } }
        h.backend.gate = CompletableDeferred()
        h.watchStates.emit(WatchStateEvent("c", ServerId("s1"), WatchStateChangeType.REMOVED_FROM_CONTINUE_WATCHING, emptyList()))
        runCurrent()
        assertEquals(listOf("d"), seen.last(), "the card leaves the row at once")
        assertEquals(listOf("c"), store.state.value.items.last().items.map { it.title }, "other rows keep it")
        h.backend.hubs = listOf(MediaHub("cw", "Continue Watching", "movie", listOf(mediaItem("d")), identifier = "continueWatching"))
        h.backend.gate!!.complete(Unit)
        settle()
        assertEquals(2, h.backend.hubCalls)
        assertEquals(1, store.state.value.items.size)
    }

    @Test
    fun collectionsAndPlaylistsReloadOnlyOnTheirOwnChange() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.backend.collections = listOf(mediaItem("c1"))
        h.backend.playlists = listOf(playlist("p1"))
        val collections = LibraryCollectionsStore(h.context(movies), backgroundScope)
        val playlists = LibraryPlaylistsStore(h.context(movies), backgroundScope)
        collections.reload()
        playlists.reload()
        settle()
        h.backend.collections = listOf(mediaItem("c1"), mediaItem("c2"))
        h.backend.playlists = listOf(playlist("p1"), playlist("p2"))

        h.refreshes.emit(LibraryRefreshType.COLLECTIONS)
        settle()
        assertEquals(2, collections.state.value.total)
        assertEquals(1, playlists.state.value.total)

        h.refreshes.emit(LibraryRefreshType.PLAYLISTS)
        settle()
        assertEquals(2, playlists.state.value.total)
    }

    @Test
    fun aReloadShowsTheSpinnerButAFailedLivePassKeepsWhatShowsSilently() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.backend.hubs = listOf(hub("a"))
        val store = LibraryRecommendedStore(h.context(movies), backgroundScope)
        store.setActive(true)
        store.reload()
        settle()
        assertEquals(LoadState.CONTENT, store.state.value.load)
        store.reload()
        assertEquals(LoadState.LOADING, store.state.value.load, "a normal reload clears to the spinner")
        assertTrue(store.state.value.items.isEmpty())
        settle()
        h.backend.hubsFailure = IllegalStateException("down")
        h.events.emit(LibraryChangeEvent(ServerId("s1"), setOf("movies"), itemsAdded = true))
        settle()
        assertEquals(3, h.backend.hubCalls, "the live pass ran")
        assertEquals(LoadState.CONTENT, store.state.value.load)
        assertEquals(listOf("a"), store.state.value.items.single().items.map { it.title })
        assertNull(store.state.value.error)
        assertTrue(h.errors.isEmpty())
    }

    @Test
    fun aWatchChangeToAShownItemOrItsChildRefreshesButProgressAndOtherItemsDoNot() = runTest {
        val h = Harness(this, listOf(shows)).start()
        val show = mediaItem("show", MediaKind.SHOW)
        h.backend.hubs = listOf(MediaHub("recent", "Recent", "show", listOf(show)))
        val store = LibraryRecommendedStore(h.context(shows), backgroundScope)
        store.reload()
        settle()
        h.watchStates.emit(WatchStateEvent("ep", ServerId("s1"), WatchStateChangeType.PROGRESS_UPDATE, listOf("season", "show"), viewOffset = 10_000))
        h.watchStates.emit(WatchStateEvent("elsewhere", ServerId("s1"), WatchStateChangeType.WATCHED, emptyList()))
        settle()
        assertEquals(1, h.backend.hubCalls)

        h.backend.hubs = listOf(MediaHub("recent", "Recent", "show", listOf(show.copy(viewCount = 1))))
        h.watchStates.emit(WatchStateEvent("ep", ServerId("s1"), WatchStateChangeType.WATCHED, listOf("season", "show")))
        settle()
        assertEquals(2, h.backend.hubCalls)
        assertEquals(1, store.item(show.globalKey)?.viewCount)

        h.deletions.emit(DeletionEvent("show", ServerId("s1"), emptyList(), MediaKind.SHOW, isDownloadOnly = true))
        settle()
        assertNotNull(store.item(show.globalKey), "a deleted download leaves the server's item")
        assertEquals(2, h.backend.hubCalls)
    }

    @Test
    fun aLivePushRefetchesAShownGridInPlaceButAFailedOneReloadsFully() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.backend.collectionsFailure = IllegalStateException("down")
        val store = LibraryCollectionsStore(h.context(movies), backgroundScope)
        store.setActive(true)
        store.reload()
        settle()
        assertEquals(LoadState.ERROR, store.state.value.load)
        val seen = mutableListOf<LoadState>()
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { store.state.collect { seen += it.load } }

        h.backend.collectionsFailure = null
        h.backend.collections = listOf(mediaItem("c1"))
        h.events.emit(LibraryChangeEvent(ServerId("s1"), setOf("movies"), itemsAdded = true))
        settle()
        assertTrue(LoadState.LOADING in seen, "an error takes the clearing reload")
        assertEquals(LoadState.CONTENT, store.state.value.load)

        seen.clear()
        h.backend.collections = listOf(mediaItem("c0"), mediaItem("c1"))
        h.events.emit(LibraryChangeEvent(ServerId("s1"), setOf("movies"), itemsAdded = true))
        settle()
        assertFalse(LoadState.LOADING in seen, "a shown grid never clears")
        assertEquals(Triple("movies", 0, 1), h.backend.collectionRequests.last(), "the loaded span is refetched")
        assertEquals(2, store.state.value.total)
    }

    @Test
    fun collectionsPageBy36WithinTheLibraryAndGoSquareOnlyWhenAllMusic() = runTest {
        val plexMusic = lib("music", MediaKind.ARTIST, backend = BackendKind.PLEX)
        val h = Harness(this, listOf(plexMusic, movies)).start()
        h.backend.collections = listOf(mediaItem("c", MediaKind.COLLECTION, backend = BackendKind.PLEX))
        val music = LibraryCollectionsStore(h.context(plexMusic), backgroundScope)
        music.reload()
        settle()
        assertEquals(Triple("music", 0, 36), h.backend.collectionRequests.single())
        assertEquals(CardShape.SQUARE, music.state.value.shape, "a Plex collection of a music library is music")

        val album = mediaItem("al", MediaKind.ALBUM).copy(subtype = "album")
        h.backend.collections = listOf(album, mediaItem("v", MediaKind.COLLECTION))
        val video = LibraryCollectionsStore(h.context(movies), backgroundScope)
        video.reload()
        settle()
        assertEquals(CardShape.POSTER, video.state.value.shape, "one video collection keeps the posters")
        h.backend.collections = listOf(album)
        video.reload()
        settle()
        assertEquals(CardShape.SQUARE, video.state.value.shape)
    }

    @Test
    fun playlistsPageBy200AsAudioInAMusicLibraryElseVideo() = runTest {
        val music = lib("music", MediaKind.ARTIST)
        val h = Harness(this, listOf(music, movies)).start()
        h.backend.playlists = listOf(playlist("p1"), playlist("p2", "audio"))
        val audio = LibraryPlaylistsStore(h.context(music), backgroundScope)
        val video = LibraryPlaylistsStore(h.context(movies), backgroundScope)
        audio.reload()
        settle()
        video.reload()
        settle()
        assertEquals(listOf<Pair<String, Int?>>("audio" to 200, "video" to 200), h.backend.playlistRequests)
        assertEquals(CardShape.SQUARE, audio.state.value.shape)
        assertEquals(CardShape.SQUARE, audio.state.value.card(0)?.shape)
        assertEquals(CardShape.POSTER, video.state.value.shape)
    }

    @Test
    fun aMusicLibrarysPlaylistsTabListsOnlyAudioPlaylistsAsSquares() = runTest {
        val music = lib("music", MediaKind.ARTIST)
        val h = Harness(this, listOf(music, movies)).start()
        h.backend.playlists = listOf(playlist("films"), playlist("songs", "audio"))
        val musicTab = LibraryPlaylistsStore(h.context(music), backgroundScope)
        val moviesTab = LibraryPlaylistsStore(h.context(movies), backgroundScope)
        musicTab.reload()
        moviesTab.reload()
        settle()

        assertEquals(listOf("songs"), musicTab.state.value.cards.values.map { it.title })
        assertEquals(CardShape.SQUARE, musicTab.state.value.shape)
        assertEquals(listOf("films"), moviesTab.state.value.cards.values.map { it.title })
        assertEquals(CardShape.POSTER, moviesTab.state.value.shape)
    }

    @Test
    fun aMusicLibrarysPlaylistOpensTheMusicPlaylistPageAndAVideoLibrarysThePlaylistScreen() = runTest {
        val music = lib("music", MediaKind.ARTIST)
        val h = Harness(this, listOf(music, movies)).start()
        val songs = playlist("songs", "audio")
        val films = playlist("films")
        h.backend.playlists = listOf(films, songs)
        h.prefs.setTab(music.globalKey, "playlists")
        h.prefs.setTab(movies.globalKey, "playlists")
        h.prefs.setSelectedLibraryKey(music.globalKey)
        val screen = h.screen()
        settle()
        screen.playlists()
        settle()
        screen.open(songs.globalKey)
        screen.selectLibrary(movies.globalKey)
        settle()
        screen.playlists()
        settle()
        screen.open(films.globalKey)
        assertEquals(listOf(Route.MusicPlaylist("s1", "songs"), Route.PlaylistDetail(ServerId("s1"), "films")), h.routes)
    }

    private fun playlist(id: String, type: String = "video") = MediaPlaylist(id = id, backend = BackendKind.JELLYFIN, title = id, playlistType = type, serverId = "s1")
}

class LibraryBrowseStoreTest {
    private suspend fun TestScope.browse(h: Harness, library: MediaLibrary = movies, client: MediaBackend = h.backend): LibraryBrowseStore =
        LibraryBrowseStore(h.context(library, client), backgroundScope, h.prefs, canGroupByFolders = true).also {
            it.reload()
            settle()
        }

    /** A Plex server whose sections hold [total] titles and whose alphabet has [letters] letters, or fails. */
    private class PlexAlphabet {
        var letters = 6
        var total = 100
        var fails = false
        val asked = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ request ->
            val path = request.url.encodedPath
            val params = request.url.parameters
            when {
                path.endsWith("/firstCharacter") -> {
                    asked += request
                    if (fails) {
                        jsonResponse("{}", status = 500)
                    } else {
                        val dirs = (0 until letters).joinToString(",") { """{"key":"${'A' + it}","title":"${'A' + it}","size":1}""" }
                        jsonResponse("""{"MediaContainer":{"Directory":[$dirs]}}""")
                    }
                }
                path.endsWith("/all") && params["includeMeta"] == null -> {
                    val start = params["X-Plex-Container-Start"]?.toInt() ?: 0
                    val size = params["X-Plex-Container-Size"]?.toInt() ?: total
                    val rows = (start until minOf(total, start + size)).joinToString(",") { """{"ratingKey":"r$it","type":"movie","title":"Movie $it"}""" }
                    jsonResponse("""{"MediaContainer":{"totalSize":$total,"Metadata":[$rows]}}""")
                }
                else -> jsonResponse("""{"MediaContainer":{}}""")
            }
        })
    }

    @Test
    fun aPlexAlphabetAsksWithTheFiltersAndCollectionsAndShowsFromSixLettersAndEightyTitles() = runTest {
        val h = Harness(this, listOf(movies)).start()
        val plex = PlexAlphabet()
        val section = lib("1", backend = BackendKind.PLEX)
        val store = browse(h, section, plex.client)
        assertEquals(6, store.state.value.alphaLetters.size)
        assertEquals("/library/sections/1/firstCharacter", plex.asked.single().url.encodedPath)
        assertEquals("1", plex.asked.single().url.parameters["includeCollections"])

        store.applyFilters(listOf(LibraryFilter("genre", listOf("7"))))
        settle()
        assertEquals("7", plex.asked.last().url.parameters["genre"], "the alphabet follows the filters")
        assertEquals("1", plex.asked.last().url.parameters["includeCollections"])

        plex.letters = 5
        store.reload()
        settle()
        assertTrue(store.state.value.alphaLetters.isEmpty(), "five letters hide the bar")

        plex.letters = 6
        plex.total = 79
        store.reload()
        settle()
        assertTrue(store.state.value.alphaLetters.isEmpty(), "79 titles hide the bar")
    }

    @Test
    fun aPlexAlphabetShowsOnlyForATitleSortAndHidesForFoldersAndAFailure() = runTest {
        val h = Harness(this, listOf(movies)).start()
        val plex = PlexAlphabet()
        val section = lib("1", backend = BackendKind.PLEX)
        h.prefs.setSort(section.globalKey, "addedAt", descending = true)
        val store = browse(h, section, plex.client)
        assertTrue(store.state.value.alphaLetters.isEmpty(), "date added has no bar")

        h.prefs.setSort(section.globalKey, "titleSort", descending = true)
        store.reload()
        settle()
        assertEquals(6, store.state.value.alphaLetters.size, "title descending keeps it")

        store.setGrouping(BrowseGrouping.FOLDERS)
        settle()
        assertTrue(store.state.value.alphaLetters.isEmpty(), "folders have no bar")

        store.setGrouping(BrowseGrouping.ALL)
        plex.fails = true
        settle()
        store.reload()
        settle()
        assertEquals(LoadState.CONTENT, store.state.value.load, "the items still load")
        assertTrue(store.state.value.alphaLetters.isEmpty(), "a failed alphabet hides the bar")
    }

    @Test
    fun aPlexAlphabetAsksForTheGroupingsTypeAndASharedLibraryHasNone() = runTest {
        val h = Harness(this, listOf(movies)).start()
        val plex = PlexAlphabet()
        val section = lib("2", MediaKind.SHOW, backend = BackendKind.PLEX)
        val store = browse(h, section, plex.client)
        store.setGrouping(BrowseGrouping.EPISODES)
        settle()
        assertEquals("4", plex.asked.last().url.parameters["type"])

        val asked = plex.asked.size
        val sharedSection = lib("shared", backend = BackendKind.PLEX, shared = true)
        val sharedStore = browse(h, sharedSection, plex.client)
        assertEquals(asked, plex.asked.size, "shared content asks for no alphabet")
        assertTrue(sharedStore.state.value.alphaLetters.isEmpty())
    }

    @Test
    fun aWatchChangeFetchesTheLoadedItemsItTouchesAgainButNotProgressOrContinueWatching() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.backend.pageItems = (1..5).map { mediaItem("m$it") }
        h.backend.items = { id -> mediaItem(id).copy(title = "$id fresh") }
        val store = browse(h)
        h.watchStates.emit(WatchStateEvent("m1", ServerId("s1"), WatchStateChangeType.PROGRESS_UPDATE, emptyList()))
        h.watchStates.emit(WatchStateEvent("m1", ServerId("s1"), WatchStateChangeType.REMOVED_FROM_CONTINUE_WATCHING, emptyList()))
        h.watchStates.emit(WatchStateEvent("m1", ServerId("s2"), WatchStateChangeType.WATCHED, emptyList()))
        h.watchStates.emit(WatchStateEvent("m2", ServerId("s1"), WatchStateChangeType.WATCHED, emptyList()))
        h.watchStates.emit(WatchStateEvent("child", ServerId("s1"), WatchStateChangeType.UNWATCHED, listOf("m4")))
        settle()
        assertEquals(listOf("fetchItem:m2", "fetchItem:m4"), h.backend.calls.filter { it.startsWith("fetchItem") })
        val titles = (0 until 5).map { store.state.value.cards[it]?.title }
        assertEquals(listOf("m1", "m2 fresh", "m3", "m4 fresh", "m5"), titles)
    }

    @Test
    fun `a watch refresh landing after a sort change does not put its title in another titles place`() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.backend.pageItems = (1..3).map { mediaItem("m$it") }
        val gate = CompletableDeferred<Unit>()
        h.backend.items = { id -> gate.await(); mediaItem(id).copy(title = "$id fresh") }
        val store = browse(h)
        h.watchStates.emit(WatchStateEvent("m1", ServerId("s1"), WatchStateChangeType.WATCHED, emptyList()))
        settle()
        h.backend.pageItems = h.backend.pageItems.reversed()
        store.applySort(MediaSort("SortName", "Title"), descending = true)
        settle()
        gate.complete(Unit)
        settle()
        val titles = (0 until 3).map { store.state.value.cards[it]?.title }
        assertEquals(listOf("m3", "m2", "m1"), titles)
    }

    @Test
    fun aServerDeletionRemovesTheItemAndCountsDownItsParentWhileADownloadDeletionChangesNothing() = runTest {
        val h = Harness(this, listOf(shows)).start()
        h.backend.pageItems = listOf("a" to 3, "b" to 2, "c" to 5, "d" to 1).map { (id, leaves) -> mediaItem(id, MediaKind.SHOW).copy(leafCount = leaves) }
        val store = browse(h, shows)
        fun ids() = (0 until store.state.value.total).map { store.state.value.cards[it]?.let { card -> store.item(card.id) } }.map { it?.id to it?.leafCount }

        h.deletions.emit(DeletionEvent("b", ServerId("s1"), emptyList(), MediaKind.SHOW, isDownloadOnly = true))
        h.deletions.emit(DeletionEvent("b", ServerId("s2"), emptyList(), MediaKind.SHOW))
        settle()
        assertEquals(listOf<Pair<String?, Int?>>("a" to 3, "b" to 2, "c" to 5, "d" to 1), ids())

        h.deletions.emit(DeletionEvent("b", ServerId("s1"), emptyList(), MediaKind.SHOW, leafCount = 2, origin = DeletionOrigin.SERVER_PUSH))
        settle()
        assertEquals(listOf<Pair<String?, Int?>>("a" to 3, "c" to 5, "d" to 1), ids(), "later items move down")

        h.deletions.emit(DeletionEvent("ep", ServerId("s1"), listOf("season", "c"), MediaKind.EPISODE, origin = DeletionOrigin.SERVER_PUSH))
        settle()
        assertEquals(listOf<Pair<String?, Int?>>("a" to 3, "c" to 4, "d" to 1), ids())

        h.deletions.emit(DeletionEvent("season", ServerId("s1"), listOf("a"), MediaKind.SEASON, leafCount = 4, origin = DeletionOrigin.SERVER_PUSH))
        settle()
        assertEquals(listOf<Pair<String?, Int?>>("c" to 4, "d" to 1), ids(), "a parent left with no episodes goes")
        assertEquals(2, store.state.value.total)
    }

    @Test
    fun theRestoredSortRidesOnTheFirstPageRequest() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.backend.pageItems = (1..5).map { mediaItem("m$it") }
        h.prefs.setSort(movies.globalKey, "DateCreated", descending = true)
        val store = browse(h)
        assertEquals(1, h.backend.queries.size)
        assertEquals("DateCreated", h.backend.queries.single().sort?.field)
        assertEquals(LibrarySortDirection.DESCENDING, h.backend.queries.single().sort?.direction)
        assertEquals(LoadState.CONTENT, store.state.value.load)
        assertEquals(5, store.state.value.total)
    }

    @Test
    fun aSavedSortTheLibraryNoLongerOffersIsDropped() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.prefs.setSort(movies.globalKey, "Gone", descending = true)
        val store = browse(h)
        assertNull(store.state.value.sort)
        assertNull(h.backend.queries.single().sort)
    }

    @Test
    fun aSortChangeAfterAFailedLoadClearsTheStaleError() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.backend.pageFailure = IllegalStateException("down")
        val store = browse(h)
        assertEquals(LoadState.ERROR, store.state.value.load)
        h.backend.pageFailure = null
        store.applySort(MediaSort("SortName", "Title"), descending = false)
        settle()
        assertEquals(LoadState.EMPTY, store.state.value.load)
        assertNull(store.state.value.error)
        assertEquals("SortName", h.prefs.sort(movies.globalKey)?.field)
    }

    @Test
    fun clearingTheSortRemovesItsSavedValue() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.prefs.setSort(movies.globalKey, "SortName")
        val store = browse(h)
        store.applySort(null, descending = false)
        settle()
        assertNull(h.prefs.sort(movies.globalKey))
        assertNull(h.backend.queries.last().sort)
    }

    /**
     * Libraries' sort and a View all's pick a field the same way: from the unsorted state in its own direction (Date
     * Added newest first), while a sort is set in the direction in effect; the directions turn the field shown.
     */
    @Test
    fun librariesAndAViewAllPickAFieldTheSameWay() = runTest {
        val title = MediaSort("SortName", "Title", unsortedDirection = "asc")
        val dateAdded = MediaSort("DateCreated", "Date Added", defaultDirection = "desc")
        val sorts = listOf(title, dateAdded)
        val h = Harness(this, listOf(movies)).start()
        h.backend.sorts = sorts
        val store = browse(h)
        // A View all's sort over the same fields, picked by its choices' indices (Clear, Ascending, Descending first
        // while a sort is set).
        var viewAll: Pair<MediaSort?, Boolean> = null to false
        fun pickBoth(field: MediaSort) {
            store.pickSort(field)
            viewAll = viewAllSortPick(sorts, viewAll.first, viewAll.second, (if (viewAll.first != null) 3 else 0) + sorts.indexOf(field))
            settle()
        }
        fun library() = store.state.value.sort to store.state.value.sortDescending

        pickBoth(dateAdded)
        assertEquals(dateAdded to true, library(), "Date Added from the unsorted state: newest first")
        assertEquals(library(), viewAll, "a View all picks it the same way")
        assertEquals(LibrarySortDirection.DESCENDING, h.backend.queries.last().sort?.direction)

        pickBoth(title)
        assertEquals(title to true, library(), "Title keeps the direction in effect")
        assertEquals(library(), viewAll)

        store.pickDirection(descending = false)
        viewAll = viewAllSortPick(sorts, viewAll.first, viewAll.second, 1)
        settle()
        assertEquals(title to false, library(), "Ascending turns the field shown")
        assertEquals(library(), viewAll)

        pickBoth(dateAdded)
        assertEquals(dateAdded to false, library(), "Date Added keeps ascending")
        assertEquals(library(), viewAll)
        assertEquals(LibrarySortDirection.ASCENDING, h.backend.queries.last().sort?.direction)

        val queries = h.backend.queries.size
        store.pickSort(dateAdded)
        store.pickDirection(descending = false)
        settle()
        assertEquals(queries, h.backend.queries.size, "the field and direction shown picked again change nothing")

        store.applySort(null, descending = false)
        viewAll = viewAllSortPick(sorts, viewAll.first, viewAll.second, 0)
        settle()
        assertEquals(null to false, viewAll, "Clear")
        pickBoth(dateAdded)
        assertEquals(dateAdded to true, library(), "cleared, Date Added newest first again")
        assertEquals(library(), viewAll)
    }

    @Test
    fun withNothingSavedTheServersOwnOrderIsShownAndADirectionTurnsIt() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.backend.sorts = listOf(MediaSort("SortName", "Title", unsortedDirection = "asc"), MediaSort("DateCreated", "Date Added", defaultDirection = "desc"))
        val store = browse(h)
        assertNull(store.state.value.sort, "nothing saved")
        assertEquals("SortName", store.state.value.shownSort?.key)
        assertFalse(store.state.value.shownDescending)

        store.pickDirection(descending = true)
        settle()
        assertEquals("SortName", store.state.value.sort?.key)
        assertTrue(store.state.value.shownDescending)
        assertEquals(LibrarySortDirection.DESCENDING, h.backend.queries.last().sort?.direction)
    }

    @Test
    fun anUnknownServerOrderShowsNoSort() = runTest {
        val h = Harness(this, listOf(movies)).start()
        val store = browse(h)
        assertNull(store.state.value.shownSort)
        assertFalse(store.state.value.shownDescending)
    }

    @Test
    fun mixedLibraryAllGroupingAppliesItsExplicitRootKinds() = runTest {
        val mixed = lib("mixed", MediaKind.UNKNOWN).copy(defaultBrowseKinds = listOf(MediaKind.MOVIE, MediaKind.SHOW))
        val h = Harness(this, listOf(mixed)).start()
        browse(h, mixed)
        assertEquals(listOf(MediaKind.MOVIE, MediaKind.SHOW), h.backend.queries.single().includeKinds)
    }

    @Test
    fun aSharedLibraryOnAllListsVideoOnly() = runTest {
        val h = Harness(this, listOf(shared)).start()
        browse(h, shared)
        assertEquals(listOf(LibraryFilter("type", listOf("1", "2", "3", "4"))), h.backend.queries.single().filters)
    }

    @Test
    fun groupingPersistsAndQueriesItsType() = runTest {
        val h = Harness(this, listOf(shows)).start()
        val store = browse(h, shows)
        store.setGrouping(BrowseGrouping.EPISODES)
        settle()
        assertEquals("episodes", h.prefs.grouping(shows.globalKey))
        assertEquals(MediaKind.EPISODE, h.backend.queries.last().kind)
    }

    @Test
    fun aFolderThatFailsMidListingDropsItsPagesAndSaysSo() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.backend.rootFolders = listOf(mediaItem("dir", MediaKind.FOLDER))
        h.backend.folderPages = listOf(listOf(mediaItem("a")), null)
        val store = browse(h)
        store.setGrouping(BrowseGrouping.FOLDERS)
        settle()
        val tree = assertNotNull(store.folders)
        tree.toggle(tree.state.rows.single().id)
        settle()
        assertEquals(listOf("dir"), tree.state.rows.map { it.title }, "the partial page is gone")
        assertFalse(tree.state.rows.single().expanded)
        assertEquals(1, h.errors.size)
    }

    @Test
    fun aFoldersSeasonsAndEpisodesAreTitledByTheirOwnTitlesNotTheShows() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.backend.rootFolders = listOf(mediaItem("dir", MediaKind.FOLDER))
        val season = mediaItem("s1", MediaKind.SEASON).copy(title = "Season 1", parentTitle = "Maestro Show", grandparentTitle = "Maestro Show")
        val episode = mediaItem("e1", MediaKind.EPISODE).copy(title = "Pilot", grandparentTitle = "Maestro Show", parentIndex = 1, index = 1)
        h.backend.folderPages = listOf(listOf(season, episode))
        val store = browse(h)
        store.setGrouping(BrowseGrouping.FOLDERS)
        settle()
        val tree = assertNotNull(store.folders)
        tree.toggle(tree.state.rows.single().id)
        settle()
        assertEquals(listOf("dir", "Season 1", "Pilot"), tree.state.rows.map { it.title })
        assertEquals(listOf(null, null, "S1 E1"), tree.state.rows.map { it.subtitle }, "no subtitle repeats its title")
    }

    @Test
    fun deletingAnItemInAnExpandedFolderFetchesThatFolderAgain() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.backend.rootFolders = listOf(mediaItem("dir", MediaKind.FOLDER))
        h.backend.folderPages = listOf(listOf(mediaItem("a"), mediaItem("b")))
        val store = browse(h)
        store.setGrouping(BrowseGrouping.FOLDERS)
        settle()
        val tree = assertNotNull(store.folders)
        tree.toggle(tree.state.rows.single().id)
        settle()
        assertEquals(listOf("dir", "a", "b"), tree.state.rows.map { it.title })

        h.backend.folderPages = listOf(listOf(mediaItem("b")))
        h.deletions.emit(DeletionEvent("a", ServerId("s1"), listOf("dir"), MediaKind.MOVIE))
        settle()
        assertEquals(listOf("dir", "b"), tree.state.rows.map { it.title })
        assertTrue(tree.state.rows.first().expanded)
    }

    @Test
    fun filtersCommitOnceOnlyWhenChangedAndForTheirLibrary() = runTest {
        val h = Harness(this, listOf(movies)).start()
        val store = browse(h)
        val genre = listOf(LibraryFilter("genre", listOf("7")))
        store.applyFilters(genre, libraryKey = shows.globalKey)
        store.applyFilters(emptyList())
        settle()
        assertEquals(1, h.backend.queries.size)
        store.applyFilters(genre)
        settle()
        assertEquals(genre, h.prefs.filters(movies.globalKey))
        assertEquals(genre, h.backend.queries.last().filters)
        assertEquals(1, store.state.value.filterCount)
    }

    @Test
    fun jellyfinLettersFilterByNamePrefixAndTheActiveLetterClearsIt() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.backend.pageItems = (1..100).map { mediaItem("m$it") }
        val store = browse(h)
        store.setLayout(columns = 5, visibleRows = 4)
        assertEquals(27, store.state.value.alphaLetters.size)
        assertNull(store.selectLetter("M"))
        settle()
        assertEquals("M", h.backend.queries.last().nameStartsWith)
        assertEquals("M", store.state.value.currentLetter)
        store.selectLetter("M")
        settle()
        assertNull(h.backend.queries.last().nameStartsWith)
    }

    /** Episodes and seasons show their show's name while a letter would match their own: no bar for them. */
    @Test
    fun episodesAndSeasonsHaveNoAlphabetBar() = runTest {
        val h = Harness(this, listOf(shows)).start()
        h.backend.pageItems = (1..100).map { mediaItem("e$it", MediaKind.EPISODE) }
        val store = browse(h, shows)
        store.setLayout(columns = 5, visibleRows = 4)
        assertEquals(27, store.state.value.alphaLetters.size, "the shows have the bar")
        store.setGrouping(BrowseGrouping.EPISODES)
        settle()
        assertTrue(store.state.value.alphaLetters.isEmpty())
        store.setGrouping(BrowseGrouping.SEASONS)
        settle()
        assertTrue(store.state.value.alphaLetters.isEmpty())
    }

    /** The letter filtering the list shows over the grid ('Starting with M'), and its Clear lists everything again. */
    @Test
    fun aJellyfinLetterFilterNamesItsLetterAndClearsFromOverTheGrid() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.backend.pageItems = (1..100).map { mediaItem("m$it") }
        val store = browse(h)
        store.setLayout(columns = 5, visibleRows = 4)
        assertNull(store.state.value.filterLetter)
        store.selectLetter("M")
        settle()
        assertEquals("M", store.state.value.filterLetter)
        store.clearLetter()
        settle()
        assertNull(h.backend.queries.last().nameStartsWith)
        assertNull(store.state.value.filterLetter)
        assertNull(store.state.value.currentLetter)
        assertEquals(27, store.state.value.alphaLetters.size, "the bar stays")
    }

    @Test
    fun aJellyfinLetterWithNoTitlesKeepsTheBarAndNamesTheLetter() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.backend.pageItems = (1..100).map { mediaItem("m$it") }
        val store = browse(h)
        store.setLayout(columns = 2, visibleRows = 3)
        assertEquals(27, store.state.value.alphaLetters.size, "phones have the bar too")
        assertNull(store.state.value.emptyLetter)
        store.selectLetter("#")
        settle()
        assertEquals(LoadState.EMPTY, store.state.value.load)
        assertEquals(27, store.state.value.alphaLetters.size)
        assertEquals("#", store.state.value.emptyLetter)
        store.selectLetter("#")
        settle()
        assertEquals(LoadState.CONTENT, store.state.value.load)
        assertEquals(100, store.state.value.total)
        assertNull(store.state.value.emptyLetter)
    }

    @Test
    fun aMissingOwnerShowsAnErrorWithoutQueryingAnotherServer() = runTest {
        val h = Harness(this, listOf(movies)).start()
        val store = LibraryBrowseStore(h.context(movies).let { LibraryTabContext(it.library, null, it.libraries, it.libraryEvents) }, backgroundScope, h.prefs, canGroupByFolders = false)
        store.reload()
        settle()
        assertEquals(LoadState.ERROR, store.state.value.load)
        assertTrue(h.backend.queries.isEmpty())
    }

    /** A drag begun while a live refresh fetched keeps the user's place: the anchor jump stands down. */
    @Test
    fun aLiveRefreshKeepsTheAnchorStillUnlessADragBeganWhileItFetched() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.backend.pageItems = (1..100).map { mediaItem("m$it") }
        val store = browse(h)
        store.setActive(true)
        store.visibleRange(first = 10, count = 10)
        settle()
        val jumps = mutableListOf<Int>()
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { store.jumps.collect { jumps += it } }

        suspend fun push(drag: Boolean) {
            h.backend.pageItems = listOf(mediaItem("new${h.backend.queries.size}")) + h.backend.pageItems
            val gate = CompletableDeferred<Unit>()
            h.backend.gate = gate
            val asked = h.backend.queries.size
            h.events.emit(LibraryChangeEvent(ServerId("s1"), setOf("movies"), itemsAdded = true))
            settle()
            assertTrue(h.backend.queries.size > asked, "the refresh is fetching")
            if (drag) {
                store.setScrolling(true)
                store.setScrolling(false)
            }
            h.backend.gate = null
            gate.complete(Unit)
            settle()
        }

        push(drag = false)
        assertEquals(listOf(11), jumps, "the first visible item moved down one and is kept in view")
        push(drag = true)
        assertEquals(listOf(11), jumps, "a drag in the meantime owns the scroll position")
    }

    @Test
    fun aPlexLibraryWaitsForFiltersAndSortsBeforeItsFirstPage() = runTest {
        val h = Harness(this, listOf(movies)).start()
        val plex = lib("p", backend = BackendKind.PLEX)
        h.backend.pageItems = emptyList()
        browse(h, plex)
        assertEquals(1, h.backend.queries.size)
        assertEquals(listOf<String?>("movie"), h.backend.sortTypes)
    }

    /** A live refresh far down refetches at most 600 items centred on the first visible one. */
    @Test
    fun aLiveRefreshRefetchesAt600ItemsCentredOnTheFirstVisible() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.backend.pageItems = (0 until 2000).map { mediaItem("m$it") }
        val store = browse(h)
        store.setActive(true)
        store.visibleRange(1500, 12)
        settle()
        assertTrue(store.state.value.cards.keys.any { it < 100 } && 1500 in store.state.value.cards)
        val before = h.backend.queries.size
        h.backend.pageItems = listOf(mediaItem("new")) + h.backend.pageItems
        h.events.emit(LibraryChangeEvent(ServerId("s1"), setOf("movies"), itemsAdded = true))
        settle()
        val refetched = h.backend.queries.drop(before)
        assertTrue(refetched.isNotEmpty())
        assertTrue(refetched.all { it.offset in 1200 until 1800 }, "$refetched")
        assertTrue(store.state.value.cards.keys.all { it in 1200 until 1801 }, "the span far from the anchor is dropped")
        assertEquals("m1500", store.state.value.cards[1501]?.let { store.item(it.id) }?.id)
    }

    @Test
    fun aPlexLibrarysFirstPageWaitsForItsFiltersAndCarriesTheRestoredSort() = runTest {
        val plex = lib("p", backend = BackendKind.PLEX)
        val h = Harness(this, listOf(plex)).start()
        h.prefs.setSort(plex.globalKey, "DateCreated", descending = true)
        val gate = CompletableDeferred<Unit>()
        h.backend.filtersGate = gate
        val store = LibraryBrowseStore(h.context(plex), backgroundScope, h.prefs, canGroupByFolders = false)
        store.reload()
        settle()
        assertTrue(h.backend.queries.isEmpty(), "no page before the filters land")
        gate.complete(Unit)
        settle()
        assertEquals("DateCreated", h.backend.queries.single().sort?.field)
    }

    @Test
    fun aJellyfinLibrarysFirstPageSkipsTheFiltersWhoseFailureOnlyLogs() = runTest {
        val h = Harness(this, listOf(movies)).start()
        val genre = MediaFilter("genre", "Genre")
        h.backend.pageItems = listOf(mediaItem("m1"))
        h.backend.filters = LibraryFilterResult(listOf(genre), emptyMap())
        val gate = CompletableDeferred<Unit>()
        h.backend.filtersGate = gate
        val store = LibraryBrowseStore(h.context(movies), backgroundScope, h.prefs, canGroupByFolders = false)
        store.reload()
        settle()
        assertEquals(1, h.backend.queries.size)
        assertEquals(LoadState.CONTENT, store.state.value.load)
        assertTrue(store.state.value.filters.isEmpty())
        gate.complete(Unit)
        settle()
        assertEquals(listOf(genre), store.state.value.filters)

        h.backend.filtersGate = null
        h.backend.filtersFailure = IllegalStateException("down")
        store.reload()
        settle()
        assertEquals(LoadState.CONTENT, store.state.value.load)
        assertNull(store.state.value.error)
        assertTrue(h.errors.isEmpty())
    }

    @Test
    fun aMusicGroupingThatSortsAsAnotherTypeRefetchesSortsBeforeItsItemsAndDropsAMissingSort() = runTest {
        val music = lib("music", MediaKind.ARTIST)
        val h = Harness(this, listOf(music)).start()
        h.prefs.setSort(music.globalKey, "DateCreated", descending = true)
        val store = browse(h, music)
        assertEquals("DateCreated", store.state.value.sort?.key)
        h.backend.sorts = listOf(MediaSort("SortName", "Title"))
        store.setGrouping(BrowseGrouping.ALBUMS)
        settle()
        assertEquals(listOf<String?>(MediaKind.ARTIST.id, MediaKind.ALBUM.id), h.backend.sortTypes)
        assertEquals("albums", h.prefs.grouping(music.globalKey))
        val albums = h.backend.queries.last()
        assertEquals(MediaKind.ALBUM, albums.kind)
        assertNull(albums.sort, "the items never ask with a sort the albums' list lacks")
        assertNull(store.state.value.sort)
        assertFalse(store.state.value.sortDescending)

        store.applySort(h.backend.sorts.single(), descending = true)
        settle()
        store.setGrouping(BrowseGrouping.TRACKS)
        settle()
        assertEquals(MediaKind.TRACK.id, h.backend.sortTypes.last())
        assertEquals(MediaKind.TRACK, h.backend.queries.last().kind)
        assertEquals("SortName", h.backend.queries.last().sort?.field, "a sort the new list has stays")
        assertEquals(LibrarySortDirection.DESCENDING, h.backend.queries.last().sort?.direction)
    }

    @Test
    fun pickingTheCurrentSortAgainCommitsNothing() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.prefs.setSort(movies.globalKey, "DateCreated", descending = true)
        val store = browse(h)
        store.applySort(h.backend.sorts[1], descending = true)
        settle()
        assertEquals(1, h.backend.queries.size)
        store.applySort(h.backend.sorts[1], descending = false)
        settle()
        assertEquals(2, h.backend.queries.size)
        assertEquals(LibrarySortDirection.ASCENDING, h.prefs.sort(movies.globalKey)?.direction)
    }

    @Test
    fun theFirstPageIsSizedFromTheMeasuredGrid() = runTest {
        val plex = lib("p", backend = BackendKind.PLEX)
        val h = Harness(this, listOf(movies, plex)).start()
        val plexStore = LibraryBrowseStore(h.context(plex), backgroundScope, h.prefs, canGroupByFolders = false)
        plexStore.setLayout(columns = 6, visibleRows = 5)
        plexStore.reload()
        settle()
        assertEquals(108, h.backend.queries.last().limit, "(5 + 1) rows of 6, three screens")
        val jellyfinStore = LibraryBrowseStore(h.context(movies), backgroundScope, h.prefs, canGroupByFolders = false)
        jellyfinStore.setLayout(columns = 7, visibleRows = 4)
        jellyfinStore.reload()
        settle()
        assertEquals(70, h.backend.queries.last().limit, "(4 + 1) rows of 7, two screens")
    }

    @Test
    fun aScrollPrefetchesAheadAtOnceAndBackfillsTheVisibleRangeWithHalfAPageOnceSettled() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.backend.pageItems = (0 until 1000).map { mediaItem("m$it") }
        val store = browse(h)
        val before = h.backend.queries.size
        store.visibleRange(first = 500, count = 10)
        runCurrent()
        assertEquals(listOf(510 to 72), h.backend.queries.drop(before).map { it.offset to it.limit }, "the page after the visible span")
        advanceTimeBy(199.milliseconds)
        runCurrent()
        assertEquals(before + 1, h.backend.queries.size, "nothing more until the scroll settles")
        advanceTimeBy(2.milliseconds)
        runCurrent()
        assertEquals(464 to 46, h.backend.queries.last().let { it.offset to it.limit }, "500 less 36, up to what the prefetch holds")
    }

    @Test
    fun aLivePassWaitsWhileTheUserScrollsAndRunsWithinFifteenSecondsOfStopping() = runTest {
        val h = Harness(this, listOf(movies)).start()
        h.backend.pageItems = (1..10).map { mediaItem("m$it") }
        val store = browse(h)
        store.setActive(true)
        val before = h.backend.queries.size
        store.setScrolling(true)
        h.events.emit(LibraryChangeEvent(ServerId("s1"), setOf("movies"), itemsAdded = true))
        advanceTimeBy(2.minutes)
        runCurrent()
        assertEquals(before, h.backend.queries.size, "no pass while the user scrolls")
        store.setScrolling(false)
        advanceTimeBy(15.seconds)
        runCurrent()
        assertTrue(h.backend.queries.size > before)
    }
}

/** Plex's alphabet jump bar: its firstCharacter request, when the bar shows, and the letter scrolling highlights. */
class PlexAlphaBarTest {
    private class Server(val total: Int, val letters: List<Pair<String, Int>>, val failLetters: Boolean = false) {
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ request ->
            requests += request
            val path = request.url.encodedPath
            when {
                path.endsWith("/firstCharacter") ->
                    if (failLetters) {
                        jsonResponse("down", 500)
                    } else {
                        jsonResponse("""{"MediaContainer":{"Directory":[${letters.joinToString(",") { (l, n) -> """{"key":"$l","title":"$l","size":$n}""" }}]}}""")
                    }
                path.endsWith("/sorts") -> jsonResponse("""{"MediaContainer":{"Directory":[{"key":"titleSort","title":"Title"},{"key":"addedAt","title":"Added"}]}}""")
                path.endsWith("/all") -> {
                    val start = request.url.parameters["X-Plex-Container-Start"]?.toInt() ?: 0
                    val size = request.url.parameters["X-Plex-Container-Size"]?.toInt() ?: total
                    val end = minOf(total, start + size)
                    val rows = (start until end).joinToString(",") { """{"ratingKey":"m$it","type":"movie","title":"M$it"}""" }
                    jsonResponse("""{"MediaContainer":{"size":${end - start},"totalSize":$total,"offset":$start,"Metadata":[$rows]}}""")
                }
                else -> jsonResponse("""{"MediaContainer":{"size":0}}""")
            }
        })
        val letterRequests get() = requests.filter { it.url.encodedPath.endsWith("/firstCharacter") }
    }

    private val sixLetters = listOf("A" to 30, "B" to 30, "C" to 30, "D" to 10, "E" to 5, "F" to 5)

    private suspend fun TestScope.browse(h: Harness, server: Server, library: MediaLibrary): LibraryBrowseStore {
        val context = h.context(library)
        val store = LibraryBrowseStore(
            LibraryTabContext(library, server.client, context.libraries, context.libraryEvents),
            backgroundScope,
            h.prefs,
            canGroupByFolders = false,
        )
        store.setLayout(columns = 5, visibleRows = 4)
        store.reload()
        settle()
        return store
    }

    @Test
    fun theLettersRequestCarriesTheFiltersCollectionsAndTheGroupingsType() = runTest {
        val plex = lib("p", backend = BackendKind.PLEX)
        val h = Harness(this, listOf(plex)).start()
        h.prefs.setFilters(listOf(LibraryFilter("genre", listOf("7"))), sectionId = plex.globalKey)
        val server = Server(total = 110, letters = sixLetters)
        val store = browse(h, server, plex)
        val request = server.letterRequests.single().url
        assertEquals("/library/sections/p/firstCharacter", request.encodedPath)
        assertEquals("7", request.parameters["genre"])
        assertEquals("1", request.parameters["includeCollections"])
        assertEquals("1", request.parameters["type"])
        assertEquals(listOf("A", "B", "C", "D", "E", "F"), store.state.value.alphaLetters)
        server.client.close()
    }

    @Test
    fun theBarNeedsSixLettersEightyItemsAndATitleSort() = runTest {
        val plex = lib("p", backend = BackendKind.PLEX)
        val h = Harness(this, listOf(plex)).start()
        assertTrue(browse(h, Server(total = 79, letters = sixLetters), plex).state.value.alphaLetters.isEmpty(), "fewer than 80 items")
        assertTrue(browse(h, Server(total = 110, letters = sixLetters.take(5)), plex).state.value.alphaLetters.isEmpty(), "fewer than 6 letters")
        assertEquals(6, browse(h, Server(total = 80, letters = sixLetters), plex).state.value.alphaLetters.size)
        h.prefs.setSort(plex.globalKey, "titleSort", descending = true)
        assertEquals(6, browse(h, Server(total = 110, letters = sixLetters), plex).state.value.alphaLetters.size, "a descending title sort keeps it")
        h.prefs.setSort(plex.globalKey, "addedAt")
        assertTrue(browse(h, Server(total = 110, letters = sixLetters), plex).state.value.alphaLetters.isEmpty(), "another sort hides it")
    }

    @Test
    fun aFailedLetterLoadHidesTheBarAndASharedLibraryAsksForNone() = runTest {
        val plex = lib("p", backend = BackendKind.PLEX)
        val h = Harness(this, listOf(plex)).start()
        val store = browse(h, Server(total = 110, letters = sixLetters, failLetters = true), plex)
        assertTrue(store.state.value.alphaLetters.isEmpty())
        assertEquals(LoadState.CONTENT, store.state.value.load)
        assertNull(store.state.value.error)

        val shared = lib("shared", backend = BackendKind.PLEX, shared = true)
        val server = Server(total = 110, letters = sixLetters)
        assertTrue(browse(h, server, shared).state.value.alphaLetters.isEmpty())
        assertTrue(server.letterRequests.isEmpty())
    }

    @Test
    fun theHighlightedLetterIsTheLastItemOfTheFirstVisibleRow() = runTest {
        val plex = lib("p", backend = BackendKind.PLEX)
        val h = Harness(this, listOf(plex)).start()
        val store = browse(h, Server(total = 110, letters = sixLetters), plex)
        store.visibleRange(first = 25, count = 20)
        assertEquals("A", store.state.value.currentLetter, "item 29 is the last A")
        store.visibleRange(first = 26, count = 20)
        assertEquals("B", store.state.value.currentLetter, "item 30 starts B")
        store.visibleRange(first = 95, count = 15)
        assertEquals("D", store.state.value.currentLetter, "item 99 is the last D")
    }

    @Test
    fun plexFilterValuesAskedOffTheMainThreadAreFetchedAndNamedOnIt() = runTest {
        val main = MainProbe(StandardTestDispatcher(testScheduler))
        Dispatchers.setMain(main)
        try {
            val h = Harness(this, listOf(movies)).start()
            var fetchedOnMain: Boolean? = null
            val client = testPlexClient({ request ->
                if (request.url.encodedPath == "/library/sections/1/genre") {
                    fetchedOnMain = main.running
                    jsonResponse("""{"MediaContainer":{"Directory":[{"key":"7","title":"Drama"}]}}""")
                } else {
                    jsonResponse("""{"MediaContainer":{}}""")
                }
            })
            val section = lib("1", backend = BackendKind.PLEX)
            val store = LibraryBrowseStore(h.context(section, client), backgroundScope, h.prefs, canGroupByFolders = false)
            val genre = MediaFilter("genre", "Genre", key = "/library/sections/1/genre")

            val values = withContext(Dispatchers.Default) { store.filterValues(genre) }

            assertEquals(listOf("Drama"), values.map { it.title })
            assertEquals(true, fetchedOnMain, "the fetch runs on the main thread")
            assertEquals("Drama", FilterValueNames.lookup("s1", section.globalKey, "genre", store.valueId(genre, values.single())))
        } finally {
            Dispatchers.resetMain()
        }
    }

    /** A main dispatcher over [inner] that tells whether it is running a task now. */
    private class MainProbe(private val inner: CoroutineDispatcher) : CoroutineDispatcher() {
        var running = false

        override fun isDispatchNeeded(context: CoroutineContext): Boolean = !running

        override fun dispatch(context: CoroutineContext, block: Runnable) {
            inner.dispatch(context, Runnable {
                running = true
                try {
                    block.run()
                } finally {
                    running = false
                }
            })
        }
    }
}

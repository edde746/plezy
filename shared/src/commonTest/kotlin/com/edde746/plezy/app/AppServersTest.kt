package com.edde746.plezy.app

import com.edde746.plezy.playback.players.ExternalLaunchStatus
import com.edde746.plezy.playback.players.ExternalPlaybackResult
import com.edde746.plezy.playback.players.ExternalPlayerLaunch
import com.edde746.plezy.playback.players.ExternalPlayerLauncher
import com.edde746.plezy.playback.players.ExternalPlayerPlatform
import com.edde746.plezy.playback.players.FakeProbe
import com.edde746.plezy.presentation.browse.LoadState
import com.edde746.plezy.presentation.browse.PLAY_EXTERNAL
import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.data.connections.ConnectionStore
import com.edde746.plezy.data.connections.StoredConnection
import com.edde746.plezy.jellyfin.FakeResponse
import com.edde746.plezy.jellyfin.JellyfinConnection
import com.edde746.plezy.jellyfin.JellyfinTestServer
import com.edde746.plezy.links.AppLinks
import com.edde746.plezy.links.DeepLink
import com.edde746.plezy.links.PlayLinkResolution
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.browse.UNWATCH
import com.edde746.plezy.presentation.browse.WATCH
import com.edde746.plezy.presentation.explore.FakeCatalogSource
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.navigation.TopLevelDestination
import com.edde746.plezy.profiles.LocalProfile
import com.edde746.plezy.profiles.ProfileConnection
import com.edde746.plezy.profiles.ProfileConnectionRegistry
import com.edde746.plezy.profiles.ProfileIdentity
import com.edde746.plezy.secrets.MemorySecretStore
import com.edde746.plezy.seerr.session
import com.edde746.plezy.servers.MultiServerManager
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.strings.InterfaceLocale
import com.edde746.plezy.strings.T
import io.ktor.client.HttpClient
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.plugins.websocket.WebSockets
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes

class AppServersTest {
    private val server = JellyfinTestServer(
        handler = { request ->
            when (request.path) {
                "/Users/user-1", "/Users/Me" -> FakeResponse(200, """{"Id":"user-1","Name":"edde","Policy":{"IsAdministrator":false}}""")
                "/Users/user-1/Views" -> FakeResponse(
                    200,
                    """{"Items":[{"Id":"lib-movies","Name":"Movies","CollectionType":"movies","Type":"CollectionFolder"}]}""",
                )
                "/Users/user-1/Items/Latest" -> FakeResponse(200, """{"Items":[{"Id":"movie-1","Name":"Movie One","Type":"Movie"}]}""")
                // Continue Watching's rows: a failed resume read fails the shelf before its Next Up request goes out.
                "/UserItems/Resume", "/Shows/NextUp" -> FakeResponse(200, """{"Items":[]}""")
                "/UserPlayedItems/movie-1" -> FakeResponse(200, """{"Played":${request.method == "POST"}}""")
                "/Items/movie-1/PlaybackInfo" -> FakeResponse(200, """{"MediaSources":[{"Id":"source-1","Container":"mkv","MediaStreams":[]}]}""")
                else -> FakeResponse(404)
            }
        },
    )

    @Test
    fun aStoredJellyfinConnectionOfTheActiveProfileComesOnlineAndItsLibrariesLoad() = runTest {
        val app = appWithJellyfin()
        val libraries = app.servers.libraries.state.first { it.hasLoaded }

        assertTrue(app.servers.manager.isServerOnline(ServerId("machine-1")))
        assertEquals(listOf("lib-movies"), libraries.libraries.map { it.id })
        // The connection's own device id, and this device's name for itself.
        // Home and the library list both read the views.
        val authorization = server.requests.first { it.path == "/Users/user-1/Views" }.headers.getValue("Authorization")
        assertTrue("DeviceId=\"dev-1\"" in authorization, authorization)
        assertTrue("Client=\"Plezy%20Linux\"" in authorization, authorization)
        assertTrue("Device=\"test-box\"" in authorization, authorization)
        app.close()
    }

    @Test
    fun aConnectionWithoutItsOwnDeviceIdSpeaksAsThisDevicesClientIdentifier() = runTest {
        val app = appWithJellyfin(connection = server.connection().copy(deviceId = ""))
        val clientIdentifier = app.servers.identity.getOrCreateClientIdentifier()
        assertTrue(Regex("[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}").matches(clientIdentifier), clientIdentifier)
        val authorization = server.requests.first { it.path == "/Users/user-1/Views" }.headers.getValue("Authorization")
        assertTrue("DeviceId=\"$clientIdentifier\"" in authorization, authorization)
        app.close()
    }

    @Test
    fun aMacWindowLeftInSightBehindAnotherAppIsNotStaleButAHiddenOneIs() = runTest {
        val app = appWithJellyfin(frontAfterStart = true)
        app.graph.setWindowVisible(true)
        runCurrent()
        fun viewFetches() = server.requests.count { it.path == "/Users/user-1/Views" }
        val before = viewFetches()

        app.graph.setForeground(false)
        advanceTimeBy(10.minutes)
        app.graph.setForeground(true)
        runCurrent()
        assertEquals(before, viewFetches(), "another app in front for 10 minutes reloads nothing")

        app.graph.setWindowVisible(false)
        advanceTimeBy(10.minutes)
        app.graph.setWindowVisible(true)
        runCurrent()
        assertTrue(viewFetches() > before, "a window hidden for 10 minutes reloads")
        app.close()
    }

    @Test
    fun aMenuOpenedAfterAWatchMarkOffersTheOppositeMark() = runTest {
        val app = appWithJellyfin()
        val menu = app.mediaActions.menu
        // The card's item, as Home fetched it before the mark: the menu must not trust its stale watch state.
        val movie = MediaItem("movie-1", BackendKind.JELLYFIN, MediaKind.MOVIE, title = "Heat", serverId = "machine-1")

        menu.open(movie)
        assertEquals(WATCH, menu.menu.filterNotNull().first().entries.first().id)
        menu.select(WATCH)
        assertEquals(T.messages.markedAsWatched, menu.message.filterNotNull().first().text)
        menu.messageShown()
        runCurrent()

        menu.open(movie)
        val watched = menu.menu.filterNotNull().first().entries.map { it.id }
        assertTrue(UNWATCH in watched && WATCH !in watched, "$watched")
        menu.select(UNWATCH)
        assertEquals(T.messages.markedAsUnwatched, menu.message.filterNotNull().first().text)
        runCurrent()

        menu.open(movie)
        val unwatched = menu.menu.filterNotNull().first().entries.map { it.id }
        assertTrue(WATCH in unwatched && UNWATCH !in unwatched, "$unwatched")
        assertEquals(listOf("POST", "DELETE"), server.requests.filter { it.path == "/UserPlayedItems/movie-1" }.map { it.method })
        app.close()
    }

    /** No profile once the start settles (a first run, a sign-out): Home says it could not load, with Retry, rather than load forever. */
    @Test
    fun homeWithoutAProfileShowsItsErrorOnceTheStartSettles() = runTest {
        val app = AppSession(testGraph(), FakeAppPlatform())
        val home = assertNotNull(app.home(Route.Home))
        app.profiles.bindState.first { !it.unsettled }
        runCurrent()
        assertNull(app.profiles.active.value)
        assertEquals(LoadState.ERROR, home.state.value.load)
        assertEquals(T.errors.unableToLoad(T.discover.title), home.state.value.error)

        home.retry()
        runCurrent()
        assertEquals(LoadState.ERROR, home.state.value.load)
        app.close()
    }

    /** A launch whose profile binds: Home loads once the bind settles, once, and never shows the error on the way. */
    @Test
    fun aLaunchThatBindsAProfileLoadsHomeOnceWithNoErrorFirst() = runTest {
        val loads = mutableListOf<LoadState>()
        val app = appWithJellyfin(started = { app ->
            val home = assertNotNull(app.home(Route.Home))
            backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { home.state.collect { loads += it.load } }
        })
        assertNotNull(app.home(Route.Home)).state.first { it.load == LoadState.CONTENT }
        runCurrent()

        assertTrue(LoadState.ERROR !in loads, "$loads")
        assertEquals(1, server.requests.count { it.path == "/Users/user-1/Items/Latest" })
        app.close()
    }

    @Test
    fun aRebindOfTheActiveProfileLoadsHomeOnce() = runTest {
        val app = appWithJellyfin()
        assertNotNull(app.home(Route.Home))
        app.discover.value.state.first { !it.isLoading && !it.areHubsLoading }
        runCurrent()
        val before = server.requests.count { it.path == "/Shows/NextUp" }

        app.profiles.rebindActive()
        advanceTimeBy(1.minutes)
        runCurrent()
        assertEquals(before + 1, server.requests.count { it.path == "/Shows/NextUp" })
        app.close()
    }

    @Test
    fun pickingHomeWhileItShowsRefreshesContinueWatching() = runTest {
        val app = appWithJellyfin()
        assertNotNull(app.home(Route.Home))
        app.discover.value.state.first { !it.isLoading && !it.areHubsLoading }
        runCurrent()
        val before = server.requests.count { it.path == "/Shows/NextUp" }

        app.shell.select(TopLevelDestination.HOME)
        runCurrent()
        assertEquals(before + 1, server.requests.count { it.path == "/Shows/NextUp" })
        app.close()
    }

    @Test
    fun exploreShowsWhileACatalogSourceIsConnectedAndTheTabIsOn() = runTest {
        val app = appWithJellyfin()
        fun explore() = TopLevelDestination.EXPLORE in app.shell.state.value.destinations
        assertFalse(explore())

        app.awaitAccounts("profile-1")
        app.seerr.adoptSession(session())
        app.catalogSources.first { it.hasAnySource }
        runCurrent()
        assertTrue(explore())

        app.graph.data.deviceSettings.set(AppSettings.showExploreTab, false)
        runCurrent()
        assertFalse(explore())
        app.graph.data.deviceSettings.set(AppSettings.showExploreTab, true)
        runCurrent()
        assertTrue(explore())

        app.seerr.disconnect()
        app.catalogSources.first { !it.hasAnySource }
        runCurrent()
        assertFalse(explore())
        app.close()
    }

    /**
     * Back at the front after five minutes or more in the background, the content tabs and the libraries load again
     * (Home's full pass and the library list both read the views); a shorter background, an offline app or one whose
     * start isn't over reloads nothing.
     */
    @Test
    fun aLongBackgroundReloadsTheContentTabsUnlessOfflineOrBeforeTheStartIsOver() = runTest {
        val app = appWithJellyfin()
        assertNotNull(app.home(Route.Home))
        app.discover.value.state.first { !it.isLoading && !it.areHubsLoading }
        app.graph.setForeground(true)
        runCurrent()
        fun viewsReads() = server.requests.count { it.path == "/Users/user-1/Views" }
        fun resumeAfter(background: Duration): Int {
            app.graph.setForeground(false)
            runCurrent()
            testScheduler.advanceTimeBy(background)
            runCurrent()
            val before = viewsReads()
            app.graph.setForeground(true)
            runCurrent()
            return viewsReads() - before
        }

        assertEquals(0, resumeAfter(4.minutes))
        assertTrue(resumeAfter(5.minutes) > 0)

        app.graph.holdOffline(true)
        runCurrent()
        assertEquals(0, resumeAfter(5.minutes))
        app.graph.holdOffline(false)
        runCurrent()

        app.primed = false
        assertEquals(0, resumeAfter(5.minutes))
        app.close()
    }

    @Test
    fun aRefreshThatReachesNoServerSaysHomeCouldNotLoad() = runTest {
        val app = appWithJellyfin()
        val home = assertNotNull(app.home(Route.Home))
        app.discover.value.state.first { !it.isLoading && !it.areHubsLoading }
        runCurrent()
        assertNull(home.state.value.message)

        server.handler = { FakeResponse(500) }
        home.refresh()

        assertEquals(T.errors.unableToLoad(T.discover.title), home.state.first { it.message != null }.message)
        app.close()
    }

    /**
     * Home refreshes Continue Watching when it first shows and each time a screen pushed over it closes (its hubs fresh:
     * Continue Watching alone), and fetches nothing while the screen covers it.
     */
    @Test
    fun homeRefreshesContinueWatchingWhenItShowsAndWhenAScreenOverItCloses() = runTest {
        val app = appWithJellyfin()
        val discover = app.discover.first { it.profileId != null }
        discover.state.first { !it.isLoading && !it.areHubsLoading }
        runCurrent()
        fun continueWatchingFetches() = server.requests.count { it.path == "/Shows/NextUp" }
        val loaded = continueWatchingFetches()

        assertNotNull(app.home(Route.Home))
        runCurrent()
        assertEquals(loaded + 1, continueWatchingFetches())

        app.navigator.navigate(Route.HubDetail("recent", "Recently Added"))
        runCurrent()
        assertEquals(loaded + 1, continueWatchingFetches())

        assertTrue(app.navigator.back())
        runCurrent()
        assertEquals(loaded + 2, continueWatchingFetches())
        app.close()
    }

    /**
     * The app coming to the front right after its start, before anything the start launched has run, opens the online
     * server's push socket: the start found it in the background and stopped the push channels.
     */
    @Test
    fun theAppComingToTheFrontRightAfterItsStartOpensThePushSocket() = runTest {
        // The app's own client takes WebSockets: the fake server sees the socket's upgrade request.
        val http = HttpClient(server.engine) {
            install(HttpTimeout)
            install(WebSockets)
            expectSuccess = false
        }
        val app = appWithJellyfin(http = http, frontAfterStart = true)
        runCurrent()

        assertTrue(server.requests.any { it.path == "/socket" }, server.requests.joinToString { it.path })
        app.close()
    }

    /** Plex can't find a library item by catalogue id on its current agent: a link without `plex=` asks Discover. */
    @Test
    fun aCatalogLinkWithoutAPlexGuidAsksTheConnectedPlexCatalogForIt() = runTest {
        val app = appWithJellyfin()
        val plex = object : FakeCatalogSource(CatalogSourceId.PLEX) {
            val asked = mutableListOf<Pair<MediaKind, ExternalIds>>()

            override suspend fun resolveItemIds(kind: MediaKind, external: ExternalIds): CatalogItemIds {
                asked += kind to external
                return CatalogItemIds(plex = "5d7768ba96b655001fdc0408", tmdb = 603)
            }
        }
        val links = AppLinks(backgroundScope).apply { open("plezy://play?type=movie&tmdb=603") }
        val resolved = CompletableDeferred<PlayLinkResolution>()
        links.start(
            app.servers,
            NothingDownloaded,
            isOffline = { false },
            plexCatalog = { plex },
            stopPlayback = {},
            screensFor = {},
            launch = { link, resolver -> resolved.complete(resolver.resolve(link as DeepLink.Play)) },
            externalPlayerReturn = {},
        )

        resolved.await()
        assertEquals(listOf(MediaKind.MOVIE to ExternalIds(tmdb = 603)), plex.asked)
        app.close()
    }

    /** Each return to the front probes the servers' health again, at most once per cooldown: two minutes on a desktop. */
    @Test
    fun comingToTheFrontProbesTheServersAtMostOncePerCooldown() = runTest {
        val app = appWithJellyfin()
        runCurrent()
        fun probes() = server.requests.count { it.path == "/Users/Me" || it.path == "/Users/user-1" }

        val before = probes()
        app.graph.setForeground(true)
        runCurrent()
        val afterFirst = probes()
        assertTrue(afterFirst > before, "$before -> $afterFirst")

        app.graph.setForeground(false)
        app.graph.setForeground(true)
        runCurrent()
        assertEquals(afterFirst, probes())

        app.graph.setForeground(false)
        advanceTimeBy(MultiServerManager.RESUME_PROBE_COOLDOWN_DESKTOP)
        app.graph.setForeground(true)
        runCurrent()
        assertTrue(probes() > afterFirst)
        app.close()
    }

    @Test
    fun anItemsMenuOffersTheExternalPlayerAndPlaysTheItemThere() = runTest {
        val launched = CompletableDeferred<ExternalPlayerLaunch>()
        val launcher = object : ExternalPlayerLauncher {
            override val platform = ExternalPlayerPlatform.ANDROID
            override val probe = FakeProbe(everything = true)

            override suspend fun launch(launch: ExternalPlayerLaunch, ended: (ExternalPlaybackResult) -> Unit): ExternalLaunchStatus {
                launched.complete(launch)
                return ExternalLaunchStatus.LAUNCHED
            }
        }
        val app = appWithJellyfin(platform = FakeAppPlatform(externalPlayers = launcher))
        val menu = app.mediaActions.menu
        val movie = MediaItem("movie-1", BackendKind.JELLYFIN, MediaKind.MOVIE, title = "Heat", serverId = "machine-1")

        menu.open(movie)
        assertTrue(menu.menu.filterNotNull().first().entries.any { it.id == PLAY_EXTERNAL })
        menu.select(PLAY_EXTERNAL)

        val launch = launched.await()
        assertEquals("Heat", launch.title)
        assertTrue("movie-1" in launch.url, launch.url)
        app.close()
    }

    @Test
    fun whereTheExternalPlayerStoppedReachesTheServer() = runTest {
        val playerEnded = CompletableDeferred<(ExternalPlaybackResult) -> Unit>()
        val launcher = object : ExternalPlayerLauncher {
            override val platform = ExternalPlayerPlatform.ANDROID
            override val probe = FakeProbe(everything = true)

            override suspend fun launch(launch: ExternalPlayerLaunch, ended: (ExternalPlaybackResult) -> Unit): ExternalLaunchStatus {
                playerEnded.complete(ended)
                return ExternalLaunchStatus.LAUNCHED
            }
        }
        val app = appWithJellyfin(platform = FakeAppPlatform(externalPlayers = launcher))
        val movie = MediaItem("movie-1", BackendKind.JELLYFIN, MediaKind.MOVIE, title = "Heat", serverId = "machine-1")

        val menu = app.mediaActions.menu
        menu.open(movie)
        menu.menu.filterNotNull().first()
        menu.select(PLAY_EXTERNAL)
        playerEnded.await()(ExternalPlaybackResult(positionMs = 600_000, durationMs = 6_000_000))
        runCurrent()

        val stop = assertNotNull(server.requests.lastOrNull { it.path == "/Sessions/Playing/Stopped" }, "${server.requests.map { it.path }}")
        assertTrue("\"PositionTicks\":6000000000" in stop.body, stop.body)
        app.close()
    }

    /**
     * The app with [server]'s Jellyfin connection bound to the active profile, its libraries loaded, in the interface
     * [language] (an [AppSettings.appLocale] name) where given, over [http], on [platform]; with [frontAfterStart] it
     * comes to the front as soon as its session is built. [started] sees the session as soon as it is built.
     */
    private suspend fun TestScope.appWithJellyfin(
        language: String? = null,
        http: HttpClient = server.http,
        frontAfterStart: Boolean = false,
        connection: JellyfinConnection = server.connection(),
        platform: FakeAppPlatform = FakeAppPlatform(),
        started: (AppSession) -> Unit = {},
    ): AppSession {
        val data = testData()
        language?.let { data.deviceSettings.set(AppSettings.appLocale, it) }
        val secrets = MemorySecretStore()
        ConnectionStore(data, secrets).upsert(
            StoredConnection(connection.id, connection.kind, connection.toConfigJson(), connection.createdAt),
        )
        data.profiles.upsert(LocalProfile(id = "profile-1", displayName = "Me", createdAt = 0))
        ProfileConnectionRegistry(data, secrets).upsert(
            ProfileConnection(profileId = "profile-1", connectionId = connection.id, userIdentifier = "user-1"),
            makeDefault = true,
        )
        ProfileIdentity(data).setActiveProfileId("profile-1")
        val graph = testGraph(data, http = http, secrets = secrets)
        val app = AppSession(graph, platform)
        started(app)
        if (frontAfterStart) graph.setForeground(true)
        app.servers.libraries.state.first { it.hasLoaded }
        return app
    }

    @Test
    fun jellyfinIsAskedInNoLanguageWhateverTheInterfaces() = runTest {
        try {
            val app = appWithJellyfin(language = "de")
            assertEquals("de", InterfaceLocale.tag.value)
            app.close()
        } finally {
            InterfaceLocale.setChosen(null)
        }
        assertTrue(server.requests.isNotEmpty())
        for (request in server.requests) {
            assertNull(request.headers["Accept-Language"], request.path)
            assertTrue(request.url.parameters.names().none { it.contains("language", ignoreCase = true) }, request.path)
        }
    }

    /** The interface language changing while Home shows: its rows load again and are titled in the new language. */
    @Test
    fun homesRowsLoadAgainInANewInterfaceLanguage() = runTest {
        try {
            val app = appWithJellyfin(language = "en")
            val home = assertNotNull(app.home(Route.Home))
            val english = T.discover.recentlyAddedIn("Movies")
            home.state.first { state -> state.hubs.any { it.title == english } }

            InterfaceLocale.setChosen("de")
            val german = T.discover.recentlyAddedIn("Movies")
            assertTrue(german != english, "German titles the row \"$english\" too")
            runCurrent()
            val titles = home.state.value.hubs.map { it.title }
            assertTrue(german in titles, "Home's rows after the switch to German: $titles")
            app.close()
        } finally {
            InterfaceLocale.setChosen(null)
        }
    }

    /** The interface language changing: Settings' Services row describes itself in the new language. */
    @Test
    fun theServicesRowsDescriptionFollowsTheInterfaceLanguage() = runTest {
        try {
            val app = appWithJellyfin(language = "en")
            runCurrent()
            assertEquals("Connect Trakt, MyAnimeList, Seerr, and more", app.servicesSummary.value)

            InterfaceLocale.setChosen("de")
            runCurrent()
            assertEquals("Trakt, MyAnimeList, Seerr und mehr verbinden", app.servicesSummary.value)
            app.close()
        } finally {
            InterfaceLocale.setChosen(null)
        }
    }

    @Test
    fun plexIsAskedInTheInterfacesLanguageTraditionalChineseAsTaiwans() {
        assertEquals("de", plexLanguageCode("de-AT"))
        assertEquals("zh", plexLanguageCode("zh"))
        assertEquals("zh", plexLanguageCode("zh-CN"))
        assertEquals("zh-TW", plexLanguageCode("zh-Hant"))
        assertEquals("zh-TW", plexLanguageCode("zh-HK"))
        assertEquals("en", plexLanguageCode("fi-FI"))
    }
}

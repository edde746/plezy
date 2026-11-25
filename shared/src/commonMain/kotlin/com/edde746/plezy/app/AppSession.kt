package com.edde746.plezy.app

import com.edde746.plezy.downloads.DownloadOfflineWatchItems
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.catalog.matching.CatalogLibraryMatcher
import com.edde746.plezy.catalog.matching.libraryCopyLookup
import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogSource
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.catalog.FribbIndexSource
import com.edde746.plezy.catalog.anilist.AnilistCatalogSource
import com.edde746.plezy.catalog.mal.MalCatalogSource
import com.edde746.plezy.catalog.mdblist.MdblistCatalogSource
import com.edde746.plezy.catalog.plex.PlexCatalogSource
import com.edde746.plezy.catalog.seerr.SeerrCatalogSource
import com.edde746.plezy.catalog.simkl.SimklCatalogSource
import com.edde746.plezy.catalog.trakt.TraktCatalogSource
import com.edde746.plezy.model.MediaRatingSource
import com.edde746.plezy.presentation.explore.catalogSourceId
import com.edde746.plezy.jellyfin.JellyfinClient
import com.edde746.plezy.jellyfin.JellyfinConnection
import com.edde746.plezy.livetv.LiveTvLaunch
import com.edde746.plezy.livetv.LiveTvLaunchResult
import com.edde746.plezy.log.Log
import com.edde746.plezy.links.AppLinks
import com.edde746.plezy.links.DeepLink
import com.edde746.plezy.links.PlayLinkResolution
import com.edde746.plezy.links.PlayLinkResolver
import com.edde746.plezy.model.LibraryChangeEvent
import com.edde746.plezy.model.MediaHub
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.AccountRef
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.buildGlobalKey
import com.edde746.plezy.music.MusicPlaybackService
import com.edde746.plezy.music.MusicSessionStore
import com.edde746.plezy.music.MusicSourceResolver
import com.edde746.plezy.music.PlaybackMusicSourceResolver
import com.edde746.plezy.music.appleAudioOutput
import com.edde746.plezy.music.playTrackWithAlbumContext
import com.edde746.plezy.net.WebUrl
import com.edde746.plezy.playback.queue.PlayQueueLauncher
import com.edde746.plezy.playback.report.OfflineProgressQueue
import com.edde746.plezy.playback.report.reportExternalPlayback
import com.edde746.plezy.playback.players.ExternalLaunchOutcome
import com.edde746.plezy.playback.players.ExternalPlayerService
import com.edde746.plezy.playback.session.PlayRequest
import com.edde746.plezy.playback.source.PlaybackServers
import com.edde746.plezy.playback.source.PlaybackSourceResolver
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.cast.CastReceiver
import com.edde746.plezy.cast.CastSender
import com.edde746.plezy.cast.CastPeerInfo
import com.edde746.plezy.cast.CastDiscovery
import com.edde746.plezy.cast.CastPlayback
import com.edde746.plezy.playback.source.fileUrl
import com.edde746.plezy.playback.source.playbackServers
import com.edde746.plezy.format.localToday
import com.edde746.plezy.plex.tv.PlexDiscoverClient
import com.edde746.plezy.plex.tv.PlexDiscoverSession
import com.edde746.plezy.plex.tv.PlexAccountConnection
import com.edde746.plezy.plex.tv.PlexAccountPreferencesSource
import com.edde746.plezy.presentation.browse.CardOptions
import com.edde746.plezy.presentation.detail.CollectionStore
import com.edde746.plezy.presentation.detail.DetailDeps
import com.edde746.plezy.presentation.detail.MediaDetailStore
import com.edde746.plezy.presentation.detail.SectionLoad
import com.edde746.plezy.servers.childScope
import kotlinx.coroutines.flow.emptyFlow
import com.edde746.plezy.settings.json.MediaVersionPreferences
import com.edde746.plezy.presentation.ratings.RatingSheetStore
import com.edde746.plezy.presentation.detail.PersonStore
import com.edde746.plezy.presentation.search.SearchDeps
import com.edde746.plezy.presentation.search.SearchStore
import com.edde746.plezy.presentation.downloads.DownloadLocationModel
import com.edde746.plezy.presentation.downloads.DownloadsStore
import com.edde746.plezy.presentation.downloads.SyncRulesStore
import com.edde746.plezy.presentation.music.AlbumStore
import com.edde746.plezy.presentation.music.ArtistStore
import com.edde746.plezy.presentation.music.ControllerMusicDownloads
import com.edde746.plezy.presentation.music.MiniPlayerStore
import com.edde746.plezy.presentation.music.MusicMenuEntries
import com.edde746.plezy.presentation.music.MusicPlaylistStore
import com.edde746.plezy.presentation.music.MusicScreens
import com.edde746.plezy.presentation.music.NowPlayingStore
import com.edde746.plezy.presentation.catalog.CatalogDetailHost
import com.edde746.plezy.presentation.catalog.CatalogDetailStore
import com.edde746.plezy.presentation.catalog.CatalogItemMenu
import com.edde746.plezy.presentation.explore.CatalogSearchStore
import com.edde746.plezy.presentation.explore.CatalogSources
import com.edde746.plezy.presentation.explore.CatalogSourcesState
import com.edde746.plezy.presentation.explore.ExploreStore
import com.edde746.plezy.presentation.explore.ExploreBody
import com.edde746.plezy.presentation.explore.ExploreRowStore
import com.edde746.plezy.presentation.livetv.LiveTvAction
import com.edde746.plezy.presentation.livetv.LiveTvScreen
import com.edde746.plezy.presentation.livetv.channelsOf
import com.edde746.plezy.presentation.livetv.liveTvServers
import com.edde746.plezy.presentation.livetv.schedule.ShowScheduleStore
import com.edde746.plezy.presentation.homescreen.HomeScreenSync
import com.edde746.plezy.presentation.homescreen.SystemShelf
import com.edde746.plezy.presentation.browse.MediaActions
import com.edde746.plezy.presentation.browse.MediaMenu
import com.edde746.plezy.presentation.browse.MenuSlot
import com.edde746.plezy.presentation.browse.MenuEntryProvider
import com.edde746.plezy.presentation.browse.MenuMessage
import com.edde746.plezy.music.MusicPlayContext
import com.edde746.plezy.music.MusicPlayContextKind
import com.edde746.plezy.playback.queue.fetchAllPlaylistItems
import com.edde746.plezy.presentation.browse.QueueLaunch
import com.edde746.plezy.presentation.playlists.PlaylistDetailStore
import com.edde746.plezy.presentation.browse.hubKey
import com.edde746.plezy.presentation.browse.toCardUi
import com.edde746.plezy.presentation.home.DiscoverStore
import com.edde746.plezy.presentation.home.HomeStore
import com.edde746.plezy.presentation.home.HubDetailStore
import com.edde746.plezy.presentation.home.libraryShortcuts
import com.edde746.plezy.presentation.home.shortcutsSettled
import com.edde746.plezy.presentation.libraries.LibrariesScreenStore
import com.edde746.plezy.presentation.libraries.LibraryPlayRequest
import com.edde746.plezy.presentation.navigation.LibrarySection
import com.edde746.plezy.presentation.navigation.NavigationTabs
import com.edde746.plezy.presentation.navigation.PlezyNavigator
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.navigation.ShellAvailability
import com.edde746.plezy.presentation.navigation.ShellStore
import com.edde746.plezy.presentation.navigation.Startup
import com.edde746.plezy.presentation.navigation.TopLevelDestination
import com.edde746.plezy.presentation.onboarding.AddConnectionOption
import com.edde746.plezy.presentation.onboarding.AddMediaBrowserStore
import com.edde746.plezy.presentation.onboarding.AddPlexAccountStore
import com.edde746.plezy.presentation.onboarding.AddProfileStore
import com.edde746.plezy.presentation.onboarding.BorrowStore
import com.edde746.plezy.presentation.onboarding.EditConnectionStore
import com.edde746.plezy.presentation.onboarding.Onboarding
import com.edde746.plezy.presentation.onboarding.ProfileDetailStore
import com.edde746.plezy.presentation.onboarding.ProfilePickerStore
import com.edde746.plezy.presentation.onboarding.ReconnectStore
import com.edde746.plezy.presentation.onboarding.SignInStore
import com.edde746.plezy.presentation.home.PlexServerTasks
import com.edde746.plezy.presentation.home.ServerTaskServers
import com.edde746.plezy.presentation.home.ServerTasksStore
import com.edde746.plezy.presentation.home.UserMenuStore
import com.edde746.plezy.presentation.navigation.AuthErrorBannerUi
import com.edde746.plezy.presentation.navigation.authErrorBanner
import com.edde746.plezy.presentation.onboarding.addConnectionOptions
import com.edde746.plezy.presentation.seerr.SeerrConnectStore
import com.edde746.plezy.presentation.seerr.SeerrRequestStore
import com.edde746.plezy.presentation.seerr.SeerrPersonStore
import com.edde746.plezy.presentation.seerr.SeerrSettingsStore
import com.edde746.plezy.presentation.seerr.seerrRequestBlock
import com.edde746.plezy.presentation.supporter.AppIconPickerStore
import com.edde746.plezy.presentation.supporter.SupporterSheetStore
import com.edde746.plezy.presentation.settings.AccountPreferenceAccount
import com.edde746.plezy.presentation.settings.JellyfinAccountPreferencesSource
import com.edde746.plezy.presentation.settings.SettingsSession
import com.edde746.plezy.presentation.settings.SettingsStores
import com.edde746.plezy.presentation.settings.ThemePerks
import com.edde746.plezy.presentation.settings.resolveAccountPreferenceAccounts
import com.edde746.plezy.presentation.settings.manageLibrariesShown
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.presentation.theme.AppearanceSettings
import com.edde746.plezy.presentation.trackers.DetailWatchlistStore
import com.edde746.plezy.presentation.trackers.TrackerServicesStore
import com.edde746.plezy.presentation.trackers.servicesRowSubtitle
import com.edde746.plezy.profiles.ActivePlexToken
import com.edde746.plezy.presentation.watch.WatchToolbarUi
import com.edde746.plezy.presentation.watch.WatchTogetherStore
import com.edde746.plezy.profiles.Profile
import com.edde746.plezy.profiles.ProfileRemoval
import com.edde746.plezy.profiles.ProfileServices
import com.edde746.plezy.profiles.mediaBrowser
import com.edde746.plezy.profiles.plexAccount
import com.edde746.plezy.profiles.resolveActivePlexIdentity
import com.edde746.plezy.profiles.resolveActivePlexToken
import com.edde746.plezy.seerr.SeerrAccounts
import com.edde746.plezy.servers.DownloadedWatchItem
import com.edde746.plezy.servers.MediaBrowserServerClient
import com.edde746.plezy.servers.OfflineWatchDownloads
import com.edde746.plezy.settings.AppLocale
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.strings.InterfaceLocale
import com.edde746.plezy.trackers.TrackerHub
import com.edde746.plezy.strings.Locales
import com.edde746.plezy.strings.T
import com.edde746.plezy.trackers.TrackerBinding
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.anilist.AnilistProvider
import com.edde746.plezy.trackers.mal.MalProvider
import com.edde746.plezy.trackers.mdblist.MdblistProvider
import com.edde746.plezy.trackers.simkl.SimklProvider
import com.edde746.plezy.trackers.trakt.TraktProvider
import com.edde746.plezy.servers.TrackerWatchMarks
import com.edde746.plezy.supporter.AppIcons
import com.edde746.plezy.supporter.Supporter
import com.edde746.plezy.supporter.SupporterMode
import com.edde746.plezy.supporter.SupporterPlatform
import com.edde746.plezy.supporter.SupporterStore
import com.edde746.plezy.supporter.entitlementCache
import com.edde746.plezy.data.settings.DeviceSetting
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.merge
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.time.Duration.Companion.seconds
import com.edde746.plezy.presentation.metadata.MetadataEditDeps
import com.edde746.plezy.presentation.metadata.MetadataEditing
import com.edde746.plezy.presentation.browse.isAdminActionAllowed
import com.edde746.plezy.settings.json.RecentTags
import com.edde746.plezy.settings.AccountPreferencesController
import kotlinx.coroutines.withContext
import kotlinx.coroutines.Dispatchers
import com.edde746.plezy.settings.PreferencesAccount
import kotlinx.coroutines.flow.collectLatest

/**
 * The running app: its [navigator] over the shell's destinations, the navigation chrome's rules ([shell]), what the UIs
 * draw with ([appearance]), Home over the servers ([discover], [home], [hubDetail], [continueWatching]), the Libraries
 * destination's store ([libraries]) over [servers], its playbacks ([play], [player]), and Explore's: the active
 * profile's catalog sources ([catalogSources]) and Seerr account ([seerr]) with the stores of their screens ([explore],
 * [catalogSearch], [catalogDetail]). Built by [RootSession] (or a development session) on the main thread, or off it
 * while the main thread waits ([RootSession]'s preparation); [close] it when the app goes. It runs the profile's [music]
 * session.
 *
 * @param start where to start; null for the startup section setting's.
 * @param initialSettings the appearance settings stored when the app starts ([AppearanceSettings.read]), which the
 *   first frame paints; the app follows them as they change after.
 * @param musicSources how [music] finds a track's stream; its server's by default.
 * @param supporterPlatform the Supporter perks' platform: [AppPlatform.supporter], or a development session's choice.
 * @param supporterCached the cached Supporter entitlement, read as the app starts, so a perk never flashes locked.
 * @param serverTaskServers where Home's Server Tasks come from: the online Plex servers, or a development session's.
 */
class AppSession(
    val graph: AppGraph,
    private val platform: AppPlatform,
    start: Startup? = null,
    initialSettings: AppearanceSettings = AppearanceSettings(),
    musicSources: MusicSourceResolver? = null,
    supporterPlatform: SupporterPlatform = platform.supporter,
    supporterCached: Boolean = false,
    serverTaskServers: ServerTaskServers? = null,
) {
    private val scope = graph.scope.childScope()
    private val storedAppearance: StateFlow<AppearanceSettings> =
        AppearanceSettings.observe(graph.data.deviceSettings).stateIn(scope, SharingStarted.Eagerly, initialSettings)


    val navigator = PlezyNavigator(Route.Home)

    /** The Supporter entitlement: whether the perks (preset and custom themes, alternate icons) show and paint. */
    val supporter = Supporter(
        supporterPlatform.availability,
        supporterPlatform.billing?.takeIf { supporterPlatform.mode == SupporterMode.IAP }?.let(SupporterStore::of),
        graph.data.deviceSettings.entitlementCache(),
        supporterCached,
        scope,
    )

    /** The home-screen icon; it falls back to the default when the entitlement is revoked. */
    val appIcons = AppIcons(supporterPlatform.appIcons?.takeIf { supporter.available }, supporter.unlocked, scope)

    /** The Supporter sheet and Settings' top tile (purchasable builds). */
    val supporterSheet = SupporterSheetStore(supporter, offersAppIcons = supporterPlatform.appIcons != null, scope)

    /** Settings › Appearance's App icon row and picker. */
    val appIconPicker = AppIconPickerStore(appIcons, supporter, scope, ::notify)

    /** Where Settings' donation tile links ([SupporterPlatform.donationUrl]); null where the build has no donation tile. */
    val donationUrl: String? = supporterPlatform.donationUrl

    /** The theme, the effective form factor (Force TV mode), the card settings and whether this is a car's display. */
    val appearance: StateFlow<Appearance> = combine(storedAppearance, supporter.unlocked) { stored, unlocked ->
        Appearance.of(stored, platform.formFactor, unlocked, platform.automotive)
    }.stateIn(scope, SharingStarted.Eagerly, Appearance.of(storedAppearance.value, platform.formFactor, supporter.unlocked.value, platform.automotive))

    init {
        scope.launch {
            supporter.init()
            appIcons.refresh()
        }
        scope.launch { graph.foreground.drop(1).filter { it }.collect { supporter.onForeground() } }
    }

    /** The trackers of every profile on this device ([AppGraph.trackers]); they follow the active profile. */
    val trackers: TrackerHub get() = graph.trackers

    private val platformDownloads = platform.downloads

    /**
     * The downloaded copies offline watch state and play links read, through [downloads]' controller, which is built
     * after the servers; nothing on a device without downloads.
     */
    private val downloadedItems: OfflineWatchDownloads =
        if (platformDownloads == null) NothingDownloaded else DownloadOfflineWatchItems(graph.data.downloadLibrary) { checkNotNull(downloads).controller }

    /**
     * The `plezy://` links the app is handed ([AppLinks]); one handed over before the profiles start (those it was opened
     * with, which [RootSession] hands over once it's built) can name the profile the app starts on.
     */
    val links = AppLinks(scope)

    /** The media servers, the profiles and what reads across them; watched marks reach the active profile's trackers. */
    val servers: AppServers = AppServers(
        graph,
        platform,
        downloadedItems,
        graph.trackers.watchMarks { servers.profiles.active.value?.id },
        graph.trackers.profileWatchMarks,
        links::startupProfile,
        links::settleStartupProfile,
    )

    private val liveTvDefaultFavorites: StateFlow<Boolean> = graph.data.deviceSettings.observe(AppSettings.liveTvDefaultFavorites)
        .stateIn(scope, SharingStarted.Eagerly, AppSettings.liveTvDefaultFavorites.default)

    /**
     * The downloads; null on a device without them (Apple TV: [AppPlatform.downloads] is null). The item playing
     * ([playingKey]) is protected from auto-removal.
     */
    val downloads: AppDownloads? = platformDownloads?.let {
        AppDownloads(graph, it, platform.notificationPermission, servers, playingItemKey = { playingKey.value }) { url -> WebUrl.isWeb(url) && platform.openUrl(url) }
    }

    /** The downloads section's store, kept with Libraries' route; null without downloads. */
    fun downloadsStore(): DownloadsStore? = downloads?.let { d ->
        navigator.retain(Route.Libraries, "downloads", { d.downloadsStore(scope) }, DownloadsStore::release)
    }

    /** The sync rules screen's store, kept while its route is on a stack; null without downloads. */
    fun syncRulesStore(): SyncRulesStore? = downloads?.let { d ->
        navigator.retain(Route.SyncRules, "syncRules", { d.syncRulesStore(scope) }, SyncRulesStore::release)
    }

    /** Settings → Downloads location, for as long as the session runs; null without downloads. */
    val downloadLocation: DownloadLocationModel? by lazy { downloads?.location(scope) }

    /** The profiles: [ProfileServices.profiles], the [ProfileServices.active] one and its [ProfileServices.bindState]. */
    val profiles: ProfileServices get() = servers.profiles

    /** The active profile's Seerr account; a Plex sign-in and its re-auth take the profile's Plex token. */
    val seerr = SeerrAccounts(graph.http, graph.secrets, scope, plexToken = { activePlexToken()?.token }, language = ::serviceLanguage)

    /** Removing profiles, connections and accounts with their downloads and integrations. */
    private val removal = ProfileRemoval(profiles, graph.data, downloads?.controller, seerr)

    private val catalog = CatalogSources(
        trackerBindings = profiles.active.map { it?.id }.distinctUntilChanged()
            .flatMapLatest { id -> id?.let(graph.trackers.accounts::bindings) ?: flowOf(emptyList()) },
        seerrClient = seerr.client,
        plexSession = ::plexDiscoverSession,
        settings = graph.data.profileSettings,
        isTv = appearance.value.tv,
        trackerSource = ::trackerCatalogSource,
        plexSource = { session, imageVariants -> PlexCatalogSource(PlexDiscoverClient(session, graph.http, ::serviceLanguage), imageVariants) },
        seerrSource = ::SeerrCatalogSource,
        parentScope = scope,
    )

    /** The active profile's connected catalog sources and the one Explore shows. */
    val catalogSources: StateFlow<CatalogSourcesState> = catalog.state

    /** The profile whose Seerr account and catalog sources are bound: the active one, once its accounts are read. */
    private val boundProfile = MutableStateFlow<String?>(null)

    /** Matches catalog titles to the active profile's libraries; one per profile, so no profile sees another's copies. */
    private var matcher: CatalogLibraryMatcher? = null

    init {
        scope.launch {
            profiles.active.map { it?.id }.distinctUntilChanged().collect { profileId ->
                matcher?.dispose()
                matcher = CatalogLibraryMatcher(servers.aggregation.libraryCopyLookup(), servers.store.state, scope)
                seerr.onActiveProfileChanged(profileId)
                catalog.onActiveProfileChanged(profileId)
                boundProfile.value = profileId
            }
        }
        scope.launch {
            profiles.bindState.map { it.binding }.distinctUntilChanged().collect { catalog.onProfileBindingStateChanged(it) }
        }
    }

    /** The app started offline ([startOffline]) and no visible server has connected since. */
    private val offlineUntilConnected = MutableStateFlow(false)

    /**
     * The startup bind failed and no server is online: the app starts offline and stays so until a visible server
     * connects, whatever offline mode says meanwhile.
     */
    internal fun startOffline() {
        offlineUntilConnected.value = !servers.store.state.value.hasConnectedServers
    }

    init {
        scope.launch {
            servers.store.state.collect { if (it.hasConnectedServers) offlineUntilConnected.value = false }
        }
    }

    /**
     * Offline mode ([com.edde746.plezy.servers.OfflineModeStore]: no server the profile sees is reachable), an offline
     * start no server has ended yet, or a development session's offline switch ([AppGraph.offlineHeld]). The device's
     * network is not part of it: a server on loopback or a LAN without internet answers with no network reported.
     */
    private val availability: StateFlow<ShellAvailability> =
        combine(
            combine(servers.offlineMode.isOffline, offlineUntilConnected, graph.offlineHeld) { mode, start, held -> mode || start || held },
            servers.store.state,
            storedAppearance,
            catalog.state,
        ) { offline, servers, stored, sources ->
            ShellAvailability(
                offline = offline,
                hasLiveTv = servers.hasLiveTv,
                hasExplore = sources.hasAnySource && stored.showExploreTab,
            )
        }.stateIn(
            scope,
            SharingStarted.Eagerly,
            ShellAvailability(
                offline = servers.offlineMode.isOffline.value || offlineUntilConnected.value || graph.offlineHeld.value,
                hasLiveTv = servers.store.state.value.hasLiveTv,
                hasExplore = catalog.state.value.hasAnySource && storedAppearance.value.showExploreTab,
            ),
        )

    /** The shell is offline ([ShellAvailability.offline]). */
    val offline: Boolean get() = availability.value.offline

    private val mutableProfileSession = MutableStateFlow(0)

    /**
     * Counts the active profile's changes: the UIs key the app's screens on it, so a switch starts every screen anew for
     * the new profile ([PlezyNavigator.restart]), as a fresh start would.
     */
    val profileSession: StateFlow<Int> = mutableProfileSession.asStateFlow()

    /** The profile whose screens are up: the session's first one, then each switched to once its screens restarted. */
    private val screensProfile = MutableStateFlow<String?>(null)

    /**
     * Returns once the screens are [profileId]'s. A switch's restart ([PlezyNavigator.restart]) comes after
     * [ProfileServices.switchProfile] returns, so a screen opened right after a switch waits here first, or the restart
     * takes it off again.
     */
    suspend fun awaitScreensFor(profileId: String) {
        screensProfile.first { it == profileId }
    }

    init {
        scope.launch {
            // The first hydrated profile is the one the session starts with; each later one is a switch. A switch from
            // no profile (a first sign-in, a profile a later read found) leaves no profile's video behind: a video open
            // then (a URL's) plays on over the screens started anew.
            profiles.hydrated.first { it }
            var last = profiles.active.value?.id
            screensProfile.value = last
            profiles.active.map { it?.id }.distinctUntilChanged().drop(1).collect { id ->
                val fromNone = last == null
                last = id
                // One Plex Home user's cached answers never serve the next.
                graph.data.apiCache.clearVolatile()
                // A play still opening was the last profile's: it opens nothing in this one's screens.
                if (!fromNone) playbacks.stop()
                navigator.restart { it is Route.ProfilePicker || fromNone && it == Route.Player }
                mutableProfileSession.value++
                screensProfile.value = id
            }
        }
        scope.launch {
            // A rebind of the profile already bound settling: the screens load again.
            val settles = RebindSettles()
            combine(profiles.active.map { it?.id }, profiles.bindState.map { it.binding }, ::Pair).distinctUntilChanged().collect { (id, binding) ->
                if (settles.onState(id, binding)) invalidateScreens()
            }
        }
    }

    /**
     * Ctrl/Cmd+R: the shown destination's content loads again, keeping what shows meanwhile (Home, Libraries, Live TV,
     * Explore, Search). False when the shown screen has nothing to refresh.
     */
    fun manualRefresh(): Boolean = refreshContent(navigator.stacks.value.shown.route)

    /** Every content destination's screen loads again (a stale resume, a rebind). */
    private fun refreshContentTabs() {
        for (destination in TopLevelDestination.entries) refreshContent(destination.route)
    }

    private fun refreshContent(route: Route): Boolean {
        when (val store = navigator.retained(route, contentKey(route) ?: return false)) {
            is HomeStore -> store.refresh()
            is LibrariesScreenStore -> store.refresh()
            is LiveTvScreen -> store.screen.perform(LiveTvAction.REFRESH)
            is ExploreStore -> store.refresh()
            is SearchStore -> store.refresh()
            else -> return false
        }
        return true
    }

    private fun contentKey(route: Route): String? = when (route) {
        Route.Home -> HOME
        Route.Libraries -> LIBRARIES
        Route.LiveTv -> LIVE_TV
        Route.Explore -> EXPLORE
        Route.Search -> SEARCH
        else -> null
    }

    /** A same-profile rebind settled: cached answers, libraries, downloads' metadata and the content tabs load again. */
    private suspend fun invalidateScreens() {
        Log.i(TAG) { "the active profile was bound again: reloading the screens" }
        graph.data.apiCache.clearVolatile()
        servers.hiddenLibraries.refresh()
        servers.libraries.clear()
        scope.launch { servers.libraries.loadLibraries() }
        downloads?.let { scope.launch { it.controller.refreshMetadataFromCache() } }
        // The settle already started Home's pass (Discover loads after each bind): a second one would only repeat it.
        for (destination in TopLevelDestination.entries) {
            if (destination.route != Route.Home || !mutableDiscover.value.isLoadInFlight) refreshContent(destination.route)
        }
    }

    /** Stops the video playing, if any, and closes the player (a link switching the profile, before the switch). */
    private fun stopVideo() {
        playbacks.stop()
        navigator.remove(Route.Player)
    }

    /** The navigation chrome: the destinations it shows, the selected one, back at a root. */
    val shell = ShellStore(
        navigator,
        availability,
        start ?: NavigationTabs.startupOf(storedAppearance.value.startupSection),
        platform.appleTv,
        scope,
    )

    /** Waits until [profileId]'s Seerr account and catalog sources are bound. */
    suspend fun awaitAccounts(profileId: String) {
        boundProfile.first { it == profileId }
    }

    /**
     * The Live TV destination's stores, kept while its route is on a stack; null for another route. [use24HourClock] is
     * the platform's clock setting when the screen first opens (the UI passes changes to [LiveTvScreen.setUse24HourClock]).
     */
    fun liveTv(route: Route, use24HourClock: Boolean): LiveTvScreen? {
        if (route != Route.LiveTv) return null
        return navigator.retain(route, LIVE_TV, {
            LiveTvScreen(
                servers = servers.store.liveTvServers(),
                serverSettings = graph.data.serverSettings,
                play = ::playLive,
                openShowSchedule = { title, serverId -> navigator.navigate(Route.LiveTvShowSchedule(title, serverId.value)) },
                appForeground = graph.foreground,
                favoritesOnly = liveTvDefaultFavorites.value,
                isTv = appearance.value.tv || platform.appleTv,
                use24HourClock = use24HourClock,
                parentScope = scope,
            )
        }, LiveTvScreen::close)
    }

    /** A show's upcoming airings ([Route.LiveTvShowSchedule]), kept while its route is on a stack; null for another route. */
    fun liveTvShowSchedule(route: Route, use24HourClock: Boolean): ShowScheduleStore? {
        if (route !is Route.LiveTvShowSchedule) return null
        val serverId = ServerId(route.serverId)
        val liveTvServers = servers.store.liveTvServers()
        // The Live TV screen's channels, which What's On opens a schedule over; a schedule opened before them (or without
        // the screen) loads the server's own once its Live TV is known.
        val channels = flow {
            val shown = (navigator.retained(Route.LiveTv, LIVE_TV) as? LiveTvScreen)?.screen?.state?.value?.channels.orEmpty()
            if (shown.isNotEmpty()) {
                emit(shown)
                return@flow
            }
            withTimeoutOrNull(SCHEDULE_SERVER_WAIT) { servers.store.state.first { state -> state.liveTvServers.any { it.serverId == serverId } } }
            emit(liveTvServers.channelsOf(serverId))
        }
        return navigator.retain(route, LIVE_TV_SCHEDULE, {
            ShowScheduleStore(
                showTitle = route.showTitle,
                serverId = serverId,
                channels = channels,
                servers = liveTvServers,
                serverSettings = graph.data.serverSettings,
                play = ::playLive,
                use24HourClock = use24HourClock,
                parentScope = scope,
            )
        }, ShowScheduleStore::release)
    }

    /** Opens the player on a Live TV channel (a tab's tune, a `plezy://live` link). */
    fun playLive(launch: LiveTvLaunch) {
        play(PlayRequest.Live(launch, servers.store.liveTvServers()))
    }

    /** The Explore destination's store, kept while its route is on a stack; null for another route. */
    fun explore(route: Route): ExploreStore? {
        if (route != Route.Explore) return null
        return navigator.retain(route, EXPLORE, { ExploreStore(catalog.state, catalog::setActiveSource, scope) }, ExploreStore::release)
    }

    /**
     * The catalog search screen's store, kept while its route is on a stack; null while the route's source is not
     * connected, or for a route on no stack.
     */
    fun catalogSearch(route: Route.CatalogSearch): CatalogSearchStore? {
        val source = catalog.state.value.connected.firstOrNull { it.id == route.source } ?: return null
        return navigator.retain(route, CATALOG_SEARCH, { CatalogSearchStore(source, scope) }, CatalogSearchStore::release)
    }

    /**
     * The View All grid's store of an Explore shelf, kept while its route is on a stack; null while Explore is on no
     * stack or no longer shows the shelf (its source was switched), or for a route on no stack.
     */
    fun exploreRow(route: Route.ExploreRow): ExploreRowStore? {
        val explore = explore(Route.Explore) ?: return null
        val row = (explore.state.value.body as? ExploreBody.Rows)?.rows?.firstOrNull { it.hub.id == route.hubId } ?: return null
        return navigator.retain(route, EXPLORE_ROW, { ExploreRowStore(row, explore::loadAll, scope) }, ExploreRowStore::release)
    }

    /**
     * The Libraries destination's store (the screen and the rail's Libraries section), kept while its route is on a
     * stack.
     */
    fun libraries(): LibrariesScreenStore? = navigator.retain(Route.Libraries, LIBRARIES, {
        LibrariesScreenStore(
            libraries = servers.libraries,
            hidden = servers.hiddenLibraries,
            prefs = graph.data.libraryPrefs,
            settings = graph.data.deviceSettings,
            clientFor = { library -> ServerId.tryParse(library.serverId)?.let(servers.manager::client) },
            libraryEvents = servers.libraryContent.events,
            watchStates = servers.watchStates.events,
            deletions = servers.deletions.events,
            refreshes = servers.libraryRefresh.events,
            visible = navigator.covered(Route.Libraries).map { !it },
            navigate = navigator::navigate,
            playback = { request ->
                when (request) {
                    is LibraryPlayRequest.ShuffleLibrary -> if (request.library.kind == MediaKind.ARTIST) {
                        musicScreens.shuffleLibrary(request.library)
                    } else {
                        playQueues.launchShuffledLibrary(request.library)
                    }
                    is LibraryPlayRequest.Folder -> playQueues.launchFolder(request.folder, request.shuffle)
                    is LibraryPlayRequest.Track -> {
                        music.playTrackWithAlbumContext(request.track, ServerId.tryParse(request.track.serverId)?.let(servers.manager::client))
                    }
                }
            },
            menu = mediaActions.menu,
            canAdminister = { library ->
                val server = ServerId.tryParse(library.serverId)
                server != null && isAdminActionAllowed(servers.manager.isOwnerOrAdmin(server), library.backend, profiles.active.value)
            },
            notify = mediaActions.menu::show,
            parentScope = scope,
        )
    }, LibrariesScreenStore::close)

    /**
     * The user picked the library [globalKey] (a sidebar's library row, Home's library shortcut): it is selected and
     * Libraries shows, its stack as it was left only while that stands for this library ([ShellStore.selectLibrary]).
     */
    fun pickLibrary(globalKey: String) {
        val store = libraries()
        val stacks = navigator.stacks.value
        val standsFor = stacks.stack(TopLevelDestination.LIBRARIES)?.let { stack ->
            val state = store?.state?.value
            TopLevelDestination.highlightedLibrary(stack, shell.state.value.destinations, state?.libraries.orEmpty(), stacks.libraries, state?.selected)
        }
        store?.selectLibrary(globalKey)
        shell.selectLibrary(globalKey, standsFor?.globalKey)
    }

    /**
     * The catalog detail screen's store, kept while its route is on a stack, around the [host] its first call gives; null
     * for a route on no stack. The connected trackers score the title, except the one whose catalog it came from.
     */
    fun catalogDetail(route: Route.CatalogDetail, host: CatalogDetailHost): CatalogDetailStore? = navigator.retain(
        route,
        CATALOG_DETAIL,
        {
            val matcher = checkNotNull(matcher) { "No profile is bound yet" }
            CatalogDetailStore(
                opening = route.item,
                sources = catalog.state,
                seerrPermissions = seerr.permissions,
                seerrRequestBlock = { kind, tmdbId -> seerr.client.value?.let { seerrRequestBlock(it, kind, tmdbId) } },
                seerrRequested = seerrRequested,
                matchLibrary = matcher::match,
                expectedServerIds = { matcher.expectedServerIds },
                clients = servers.manager,
                libraries = servers.libraries.state.map { it.libraries },
                communityRatings = { item -> titleRatings(item) },
                host = host,
                parentScope = scope,
            )
        },
        CatalogDetailStore::release,
    )

    /**
     * The connected trackers' community scores of a catalog [item], each tracker looking it up by the item's ids merged
     * with what its own catalog resolves them to.
     */
    private fun titleRatings(item: CatalogItem): Flow<List<MediaRatingSource>> {
        val profileId = profiles.active.value?.id ?: return flowOf(emptyList())
        return graph.trackers.ratings.forCatalogTitle(
            profileId,
            item.kind,
            item.ids.toTitleIds(),
            ownService = TrackerService.entries.firstOrNull { it.catalogSourceId == item.source },
            resolveIds = { service ->
                catalog.state.value.connected.firstOrNull { it.id == service.catalogSourceId }
                    ?.resolveItemIds(item.kind, item.ids.toExternalIds())?.toTitleIds()
            },
        )
    }

    /** A tracker account's catalog, over the account's own api so it shares the account's session. */
    private fun trackerCatalogSource(binding: TrackerBinding): CatalogSource {
        val provider = binding.provider
        val fribb = FribbIndexSource { graph.animeMappings.indexes().fribb }
        return when (provider) {
            is TraktProvider -> TraktCatalogSource(provider.api(binding.credentials))
            is SimklProvider -> SimklCatalogSource(provider.api(binding.credentials))
            is MdblistProvider -> MdblistCatalogSource(provider.api(binding.credentials))
            is MalProvider -> MalCatalogSource(provider.api(binding.credentials), fribb)
            is AnilistProvider -> AnilistCatalogSource(provider.api(binding.credentials), fribb)
            else -> error("${binding.service.id} has no catalog source")
        }
    }

    /** A catalog card's menu around [host]; an entry's work runs in the session, outliving the menu it was picked in. */
    fun catalogMenu(host: CatalogDetailHost): CatalogItemMenu = CatalogItemMenu(catalog.state, host, scope)

    /** The TMDB ids of the requests sent from the request sheet: the details showing them ask Seerr again. */
    private val seerrRequested = MutableSharedFlow<Int>(extraBufferCapacity = 8)

    /**
     * The request sheet's store for the connected Seerr account, kept while its route is on a stack; null while Seerr
     * is not connected, or for a route on no stack.
     */
    fun seerrRequest(route: Route.SeerrRequest): SeerrRequestStore? {
        val client = seerr.client.value ?: return null
        return navigator.retain(
            route,
            SEERR_REQUEST,
            {
                SeerrRequestStore(route.tmdbId, route.kind, route.title, client, seerr.client, seerr.permissions, scope) {
                    seerrRequested.tryEmit(route.tmdbId)
                }
            },
            SeerrRequestStore::release,
        )
    }

    /**
     * A Seerr person page's store, kept while its route is on a stack; null for a route on no stack. It loads from the
     * connected Seerr; with none connected the load fails, with Retry.
     */
    fun seerrPerson(route: Route.SeerrPerson): SeerrPersonStore? = navigator.retain(
        route,
        SEERR_PERSON,
        {
            SeerrPersonStore(
                route,
                { personId -> checkNotNull(catalog.state.value.seerr as? SeerrCatalogSource) { "Seerr is not connected" }.fetchPerson(personId) },
                ::localToday,
                scope,
            )
        },
        SeerrPersonStore::release,
    )

    /** The Seerr connect screen's store, kept while its route is on a stack; null for a route on no stack. */
    fun seerrConnect(route: Route.SeerrConnect): SeerrConnectStore? =
        navigator.retain(route, SEERR_CONNECT, { SeerrConnectStore(seerr, scope) }, SeerrConnectStore::release)

    /** The Seerr settings screen's store, kept while its route is on a stack; null for a route on no stack. */
    fun seerrSettings(route: Route.SeerrSettings): SeerrSettingsStore? =
        navigator.retain(route, SEERR_SETTINGS, { SeerrSettingsStore(seerr, scope) }, SeerrSettingsStore::release)

    /**
     * External players ([ExternalPlayerService]): plays hand off to the selected one while `use_external_player` is on;
     * null where the platform has none.
     */
    val externalPlayers: ExternalPlayerService? = platform.externalPlayers?.let { ExternalPlayerService(it, graph.data.deviceSettings, graph.clock) }

    init {
        // Where each external playback stopped goes to its server (or the offline queue) for the session's lifetime.
        externalPlayers?.let { players ->
            val offlineQueue = OfflineProgressQueue { serverId, itemId, viewOffsetMs, durationMs ->
                servers.offlineWatchSync.queueProgressUpdate(serverId, itemId, viewOffsetMs, durationMs)
            }
            val trackerMarks = graph.trackers.watchMarks { servers.profiles.active.value?.id }
            scope.launch {
                players.ended.collect { ended ->
                    reportExternalPlayback(
                        ended.result, ended.item, ended.backend, servers.watchStates, trackerMarks, scope, offlineQueue,
                        ended.mediaSourceId, ended.partTimeline,
                    )
                }
            }
        }
    }

    /**
     * The active profile's server-stored account preferences: playback's track defaults (its languages, its subtitle
     * mode) and the Jellyfin account memory of track picks. Loaded again on every profile switch, and while unknown
     * whenever a server comes online (a Jellyfin account needs its client).
     */
    val accountPreferences = AccountPreferencesController(::playbackPreferencesAccount)

    /** The playbacks; internal for tests. */
    internal val playbacks = PlaybackController(
        graph, servers, downloads?.videoSource ?: NoDownloadedVideos, downloadedItems::downloadedEpisodesForShow, platform, navigator, scope, ::notify,
        externalPlayers, car = { music.car },
        accountPreferences = accountPreferences,
    )

    init {
        scope.launch {
            merge(profiles.active.map { }, servers.manager.changes.filter { accountPreferences.activePreferences.value == null })
                .collectLatest { accountPreferences.bind() }
        }
    }

    /** The account the active profile plays as, with the source of its preferences. */
    private suspend fun playbackPreferencesAccount(): PreferencesAccount? {
        val (accounts, playbackRef) = preferenceAccounts()
        val account = accounts.firstOrNull { it.target.ref == playbackRef } ?: return null
        return PreferencesAccount(account.target.ref, account.source ?: return null)
    }

    /**
     * The accounts the active profile edits preferences of, in order, each with the source of its preferences (none for
     * a Jellyfin or Emby server without a client), and the one it plays as.
     */
    private suspend fun preferenceAccounts(): Pair<List<AccountPreferenceAccount>, AccountRef?> {
        val profile = profiles.active.value ?: return emptyList<AccountPreferenceAccount>() to null
        val connections = servers.connections.list().mapNotNull { it.plexAccount() ?: it.mediaBrowser() }
        val resolution = resolveAccountPreferenceAccounts(profile, servers.bindings.listForProfile(profile.id), connections)
        val accounts = resolution.accounts.map { account ->
            val source = when (val connection = account.connection) {
                is PlexAccountConnection -> PlexAccountPreferencesSource(servers.profiles.plexAuth(), checkNotNull(account.plexToken))
                is JellyfinConnection -> (servers.manager.client(connection.serverId) as? JellyfinClient)?.let(::JellyfinAccountPreferencesSource)
                else -> null
            }
            AccountPreferenceAccount(account.target, source)
        }
        return accounts to resolution.playbackRef
    }

    /** The playback [Route.Player] shows, or null: none, or between its route going and the next play. */
    val player: StateFlow<ActivePlayback?> get() = playbacks.active

    /** The global key (`serverId:itemId`) of the server item playing now; null while none is (or a URL's video plays). */
    val playingKey: StateFlow<String?> get() = playbacks.playingKey

    /**
     * Plays [request] in the player ([Route.Player]): the playback before it ends, and a play of what already plays
     * only shows the player ([PlaybackController]). A Watch Together host's play opens paused, for the room to start.
     * While this device casts, the cast target plays it instead ([castSender]).
     */
    fun play(request: PlayRequest) {
        if (cast.takes(request)) return
        playbacks.play(watch.roomOwned(request))
    }

    private val watch = AppWatchTogether(graph, platform, servers, playbacks.active, playbacks::play, navigator, scope, playbacks.heldForProfile) {
        music.vehicleRestricted
    }
        .also { playbacks.roomRelease = it::releasePlayer }

    /** The Watch Together screen's store ([Route.WatchTogether]), kept while its route is on a stack; null for another route. */
    fun watchTogether(route: Route): WatchTogetherStore? = watch.store(route)

    /** Home's Watch Together toolbar action. */
    val watchToolbar: StateFlow<WatchToolbarUi> get() = watch.toolbar

    /**
     * The room's notices ("Sam paused"), one snackbar each, the next replacing the one showing; the player shows them as
     * its own messages while it is on top.
     */
    val watchNotices: Flow<String> get() = watch.notices

    /**
     * Plays whole lists (a collection, a playlist, a folder, a shuffled show, season or library): the queue goes to the
     * player's queue and its first (or chosen) item to [play]. A shuffle that starts its items over is the session's
     * to apply, from the queue's shuffle and the setting.
     */
    val playQueues = PlayQueueLauncher(
        scope = scope,
        servers = servers.manager,
        playbackState = servers.playbackState,
        shuffleStartsFromBeginning = { graph.data.deviceSettings.value(AppSettings.shuffleStartsFromBeginning) },
        play = { item, _ ->
            val serverId = checkNotNull(item.serverId) { "${item.id} has no server" }
            play(PlayRequest.Item(ServerId(serverId), item.id, item = item))
        },
    )

    init {
        val hub = graph.trackers
        scope.launch { profiles.active.map { it?.id }.distinctUntilChanged().collect(hub::onActiveProfileChanged) }
        // Queued tracker writes replay when the app comes back to the front and when the network returns.
        scope.launch { graph.foreground.drop(1).filter { it }.collect { hub.onForeground() } }
        scope.launch { graph.network.map { it.online }.distinctUntilChanged().drop(1).filter { it }.collect { hub.onNetworkRestored() } }
        links.start(
            servers,
            downloadedItems,
            isOffline = { offline },
            plexCatalog = { catalogSources.value.connected.firstOrNull { it.id == CatalogSourceId.PLEX } },
            stopPlayback = ::stopVideo,
            screensFor = ::awaitScreensFor,
            launch = ::launchLink,
            externalPlayerReturn = { url -> externalPlayers?.handleCallbackUrl(url) },
        )
        // The interface language follows the setting at once: every screen redraws in it, Plex clients ask in it.
        scope.launch { graph.data.deviceSettings.observe(AppSettings.appLocale).collect(::applyInterfaceLanguage) }
    }

    /**
     * The store of Settings > Services and the screens under it ([Route.Services], [Route.TrackerSettings],
     * [Route.TrackerLibraryFilter]), for the active profile: one store, kept while Services is on a stack; null for
     * another route, or without an active profile.
     */
    fun services(route: Route): TrackerServicesStore? {
        if (route != Route.Services && route !is Route.TrackerSettings && route !is Route.TrackerLibraryFilter) return null
        val profileId = profiles.active.value?.id ?: return null
        val libraries = servers.libraries.state.map { it.libraries }
        return navigator.retain(
            Route.Services,
            SERVICES,
            {
                TrackerServicesStore(
                    profileId, graph.trackers.accounts, graph.data.deviceSettings, libraries, scope,
                    discordOffered = platform.discordPresence != null,
                )
            },
            TrackerServicesStore::release,
        )
    }

    /** Settings' Services row subtitle: the active profile's connected trackers, or the row's description, worded again
     *  when the interface language changes. */
    @OptIn(ExperimentalCoroutinesApi::class)
    val servicesSummary: StateFlow<String> = combine(
        profiles.active.flatMapLatest { profile -> profile?.let { graph.trackers.accounts.observe(it.id) } ?: flowOf(emptyList()) },
        InterfaceLocale.tag,
    ) { accounts, _ -> servicesRowSubtitle(accounts) }
        .stateIn(scope, SharingStarted.Eagerly, servicesRowSubtitle(emptyList()))

    private fun <T> setting(setting: DeviceSetting<T>): StateFlow<T> =
        graph.data.deviceSettings.observe(setting).stateIn(scope, SharingStarted.Eagerly, setting.default)

    /** How cards show items: the episode poster mode, spoilers, watched and unwatched badges. */
    val cardOptions: StateFlow<CardOptions> = combine(
        storedAppearance,
        graph.data.deviceSettings.observe(
            listOf(AppSettings.hideSpoilers, AppSettings.showEpisodeNumberOnCards, AppSettings.showWatchedIndicators, AppSettings.showUnwatchedCount),
        ),
    ) { appearance, values ->
        CardOptions(appearance.episodePosterMode, values[1] as Boolean, values[0] as Boolean, values[2] as Boolean, values[3] as Boolean)
    }.stateIn(scope, SharingStarted.Eagerly, CardOptions())

    private val useGlobalHubs = setting(AppSettings.useGlobalHubs)
    private val mutableDiscover = MutableStateFlow(newDiscover(profiles.active.value?.id))

    /** Home's data for the active profile: a new store for each profile, the last one closed. */
    val discover: StateFlow<DiscoverStore> = mutableDiscover.asStateFlow()

    init {
        // "Use Home Layout" switches between the servers' home hubs and per-library hubs: Home reloads its hubs.
        scope.launch {
            graph.data.deviceSettings.observe(AppSettings.useGlobalHubs).drop(1).collect { mutableDiscover.value.load() }
        }
        // A new interface language: Plex answers in it from then on, and Home's rows, titled in the last one (the
        // servers' hub titles, Jellyfin's "Recently Added in …"), load again in it.
        scope.launch {
            InterfaceLocale.tag.drop(1).collect {
                servers.manager.updatePlexLanguage(plexLanguageCode(it))
                mutableDiscover.value.load()
            }
        }
    }

    /**
     * Continue Watching for the system's shelves (the TV launcher, the Top Shelf), with the profile it belongs to: every
     * committed change; null before the first and while no profile is active.
     */
    @OptIn(ExperimentalCoroutinesApi::class)
    val continueWatching: StateFlow<ContinueWatchingShelf?> = mutableDiscover
        .flatMapLatest { store -> store.shelf.map { items -> store.profileId?.let { id -> items?.let { ContinueWatchingShelf(id, it) } } } }
        .stateIn(scope, SharingStarted.Eagerly, null)

    /** Opening an item, the Continue Watching copy picker, items' and playlists' menus. */
    val mediaActions = MediaActions(
        navigator,
        setting(AppSettings.continueWatchingAction),
        setting(AppSettings.episodeAction),
        copiesOf = { mutableDiscover.value.continueWatchingCopiesOf(it) },
        play = { item -> ServerId.tryParse(item.serverId)?.let { play(PlayRequest.Item(it, item.id, item = item)) } },
        playTrack = { musicScreens.open(it) },
        openLibrary = { key ->
            libraries()?.selectLibrary(key)
            shell.openLibrary(LibrarySection.LIBRARY)
        },
        notify = { notify(it) },
        menu = MediaMenu(
            navigator = navigator,
            client = servers.manager::client,
            isOnline = { servers.manager.isClientOnline(it, null) },
            isOwnerOrAdmin = servers.manager::isOwnerOrAdmin,
            activeProfile = { profiles.active.value },
            isOffline = { servers.offlineMode.isOffline.value },
            hasMultipleProfiles = { profiles.profiles.value.size > 1 },
            fresh = servers.watchState::apply,
            watchStateChanges = servers.watchState.changes,
            watchActions = servers.watchActions,
            deletions = servers.deletions,
            libraryRefresh = servers.libraryRefresh,
            addedToList = { serverId, listId -> downloads?.controller?.let { scope.launch { it.onAddedToList(serverId, listId) } } },
            play = ::play,
            launchQueue = { launch ->
                when (launch) {
                    is QueueLaunch.Playlist -> playQueues.launchPlaylist(launch.playlist, launch.shuffle, launch.start)
                    is QueueLaunch.Collection -> playQueues.launchCollection(launch.collection, launch.shuffle)
                    is QueueLaunch.ShuffledShow -> playQueues.launchShuffledShow(launch.item)
                }
            },
            scope = scope,
            providers = listOf(MusicMenuEntries { musicScreens }) + downloads?.let { downloads ->
                listOf(MenuSlot.DOWNLOADS, MenuSlot.LIST_DOWNLOADS).map { DownloadMenuEntries(downloads.controller, downloads.detail, servers.manager::client, it) }
            }.orEmpty() + trackerMenuEntries() + MetadataMenuEntries { metadata },
            playAudioPlaylist = { playlist, shuffle, start ->
                val client = ServerId.tryParse(playlist.serverId)?.let(servers.manager::client)
                    ?: error("No client for ${playlist.serverId}")
                val tracks = client.fetchAllPlaylistItems(playlist.id)
                if (tracks.isNotEmpty()) musicScreens.playTracks(tracks, MusicPlayContext(playlist.title, MusicPlayContextKind.PLAYLIST), start, shuffle)
                tracks.isNotEmpty()
            },
            playExternal = if (externalPlayers == null) null else { item -> playExternally(externalPlayers, item) },
            savedVersion = { item -> versionPreferences.saved(item)?.resolveIndex(item.mediaVersions.orEmpty()) },
            currentQuality = { playbacks.defaultQuality() },
        ),
    )

    /**
     * Plays [item] in the selected external player: the active profile's download of it from its file (with the
     * subtitles saved beside it), else the stream its server resolves. The message to show when it didn't start.
     */
    private suspend fun playExternally(players: ExternalPlayerService, item: MediaItem): String? {
        val serverId = ServerId.tryParse(item.serverId)
        val client = serverId?.let(servers.manager::client)
        if (serverId != null && downloads != null && downloads.controller.getCompletedDownload(buildGlobalKey(serverId, item.id)) != null) {
            val video = downloads.videoSource.resolve(serverId, item.id, mediaIndex = null, mediaSourceId = null, allowAnyVersion = false)
            if (video != null) {
                val resolver = PlaybackSourceResolver(servers.manager.playbackServers(), downloads.videoSource, servers.cachedPlaybackMetadata)
                val subtitles = resolver.downloadedSubtitles(item, video, client).map { it.track }
                val outcome = players.launch(item, client, video.mediaIndex, video.mediaSourceId, fileUrl(video.path), subtitles)
                return (outcome as? ExternalLaunchOutcome.NotLaunched)?.message
            }
        }
        if (client == null) return T.messages.errorLoading(error = T.errors.reasonUnreachable)
        return (players.launch(item, client) as? ExternalLaunchOutcome.NotLaunched)?.message
    }

    private val mutableRatingSheet = MutableStateFlow<OpenRatingSheet?>(null)

    /** The rating sheet an item menu's Rate opened, which the UIs draw over the app until [closeRatingSheet]; or null. */
    val ratingSheet: StateFlow<OpenRatingSheet?> = mutableRatingSheet.asStateFlow()

    /** Closes the rating sheet; its pending saves still go out. */
    fun closeRatingSheet() {
        mutableRatingSheet.value?.store?.release()
        mutableRatingSheet.value = null
    }

    /**
     * The watchlist button of [route]'s detail page, through the active profile's catalog sources (its state null: no
     * button); none for a page opened from the downloads. Kept with the page's [mediaDetail], whose item it waits for.
     */
    fun detailWatchlist(route: Route.MediaDetail): DetailWatchlistStore? {
        if (route.offline) return null
        val detail = mediaDetail(route) ?: return null
        return navigator.retain(route, DETAIL_WATCHLIST, {
            DetailWatchlistStore(
                {
                    detail.state.first { it.load != SectionLoad.LOADING }
                    detail.menuItem()
                },
                catalog.watchlistCandidates,
                servers.manager.client(route.serverId),
                scope,
            )
        }, DetailWatchlistStore::release)
    }

    /** The trackers' entries in the item menus: Rate, and the watchlist through the profile's catalog sources. */
    private fun trackerMenuEntries(): List<MenuEntryProvider> {
        val online = { id: ServerId -> servers.manager.isClientOnline(id, null) }
        return listOf(
            RateMenuEntries(servers.manager::client, online) { item, backend ->
                val profileId = profiles.active.value?.id ?: return@RateMenuEntries
                val store = RatingSheetStore.open(
                    graph.trackers.userRatings, profileId, item, backend, graph.scope,
                    // The item's screens show the server's rating: they read it again.
                    onServerRatingChanged = { itemUpdated(item) },
                    onServerFavoriteChanged = { itemUpdated(item) },
                )
                closeRatingSheet()
                mutableRatingSheet.value = OpenRatingSheet(store, item.backend)
            },
            WatchlistMenuEntries(
                candidates = { catalog.watchlistCandidates },
                sources = { catalogSources.value.watchlistCapableSources },
                client = servers.manager::client,
                isOnline = online,
                isOffline = { servers.offlineMode.isOffline.value },
                choose = { mediaActions.menu.askOption(it) },
                scope = scope,
            ),
        )
    }

    /** Tells the screens showing [item] that it changed on its server, so they read it again. */
    private fun itemUpdated(item: MediaItem) {
        val serverId = ServerId.tryParse(item.serverId) ?: return
        servers.libraryContent.notifyChanged(LibraryChangeEvent(serverId, setOfNotNull(item.libraryId), itemsUpdated = true))
        metadata.onEdited(serverId, item.id)
    }

    /** A playlist's screen ([Route.PlaylistDetail]), kept while its route is on a stack; null for another route. */
    fun playlistDetail(route: Route): PlaylistDetailStore? {
        if (route !is Route.PlaylistDetail) return null
        val client = servers.manager.client(route.serverId) ?: return navigator.retained(route, PLAYLIST) as PlaylistDetailStore?
        val menu = mediaActions.menu
        return navigator.retain(route, PLAYLIST, {
            PlaylistDetailStore(
                client = client,
                playlistId = route.playlistId,
                cardOptions = { cardOptions.value },
                fresh = servers.watchState::freshWatchState,
                play = menu::play,
                delete = menu::delete,
                openMenu = { menu.open(it) },
                back = navigator::back,
                message = menu::show,
                parentScope = scope,
            )
        }, PlaylistDetailStore::close)
    }

    init {
        scope.launch {
            profiles.active.map { it?.id }.distinctUntilChanged().drop(1).collect { id ->
                val previous = mutableDiscover.value
                mutableDiscover.value = newDiscover(id)
                previous.close()
                // Another profile's search starts empty.
                (navigator.retained(Route.Search, SEARCH) as SearchStore?)?.clear()
            }
        }
        scope.launch {
            // The store loads once the first bind settles, and again after each later bind: before, the servers may still
            // answer as no profile or the previous one. Without a profile it loads too: no server answers, and Home shows
            // the error with Retry rather than load forever.
            combine(mutableDiscover, profiles.bindState.map { !it.unsettled }.distinctUntilChanged()) { store, settled -> store to settled }
                .collect { (store, settled) -> if (settled) store.load() }
        }
        // The TV's home screen shows Home's Continue Watching.
        HomeScreenSync(
            SystemShelf(platform.homeScreen) { graph.clock.now().toEpochMilliseconds() },
            profiles.active,
            profiles.profiles,
            continueWatching,
            servers.store::client,
            graph.data.deviceSettings,
            scope,
        ).start()
        // Back at the front: stale hubs reload, else Continue Watching refreshes (not on the desktop, whose window comes
        // back on every focus).
        scope.launch {
            graph.foreground.drop(1).filter { it }.collect { mutableDiscover.value.onAppResumed(platform.formFactor != FormFactor.DESKTOP) }
        }
    }

    /** Home's store, kept while its route is on a stack; null for another route. */
    fun home(route: Route): HomeStore? {
        if (route != Route.Home) return null
        return navigator.retain(route, HOME, {
            HomeStore(
                discover,
                servers.store::client,
                cardOptions,
                setting(AppSettings.showServerNameOnHubs),
                servers.watchState,
                mediaActions,
                navigator,
                libraries = combine(servers.libraries.state, servers.hiddenLibraries.state) { libraries, hidden ->
                    libraryShortcuts(libraries.libraries, hidden.hiddenLibraryKeys)
                },
                shortcutsSettled = combine(servers.libraries.state, servers.store.state, profiles.bindState, ::shortcutsSettled),
                // As the sidebar's library rows.
                selectLibrary = ::pickLibrary,
                scope = scope,
            )
        }, { })
    }

    /**
     * A hub's View all ([Route.HubDetail]), kept while its route is on a stack: a hub of Home, else of the Libraries
     * Recommended tab; null for another route, or a hub neither shows any longer.
     */
    fun hubDetail(route: Route): HubDetailStore? {
        if (route !is Route.HubDetail) return null
        val discover = mutableDiscover.value
        val data = discover.state.value
        val toCard = { item: MediaItem -> item.toCardUi(ServerId.tryParse(item.serverId)?.let(servers.store::client), cardOptions.value) }
        val create: () -> HubDetailStore = if (route.hubId == HomeStore.CONTINUE_WATCHING_ID) {
            {
                HubDetailStore(
                    HomeStore.continueWatchingHub(data.onDeck, data.hasMoreContinueWatching),
                    client = null,
                    loadItems = discover::loadAllContinueWatching,
                    toCard = toCard,
                    parentScope = scope,
                    watchStates = servers.watchStates.events,
                    edited = metadata.edited,
                    clientOf = { item -> ServerId.tryParse(item.serverId)?.let(servers.store::client) },
                )
            }
        } else {
            val hub = data.hubs.firstOrNull { hubKey(it.serverId, it.id) == route.hubId } ?: libraries()?.recommended()?.hub(route.hubId)
                ?: detailRelatedHub(route.hubId)
            if (hub == null) return navigator.retained(route, HUB_DETAIL) as HubDetailStore?
            {
                HubDetailStore(
                    hub,
                    hub.serverId?.let { ServerId.tryParse(it) }?.let(servers.store::client),
                    null,
                    toCard,
                    scope,
                    watchStates = servers.watchStates.events,
                    edited = metadata.edited,
                )
            }
        }
        return navigator.retain(route, HUB_DETAIL, create, HubDetailStore::close)
    }

    /** The related hub [key] of a detail on the shown stack (its View all opens over it). */
    private fun detailRelatedHub(key: String): MediaHub? = navigator.backStack.value.asReversed()
        .filterIsInstance<Route.MediaDetail>()
        .firstNotNullOfOrNull { (navigator.retained(it, DETAIL) as MediaDetailStore?)?.relatedHub(key) }

    private fun newDiscover(profileId: String?) = DiscoverStore(
        servers = servers.manager,
        aggregation = servers.aggregation,
        hiddenLibraries = servers.hiddenLibraries,
        libraries = servers.libraries.state.map { it.libraries }.stateIn(scope, SharingStarted.Eagerly, servers.libraries.libraries),
        onlineServerChanges = servers.store.onlineServersChanges,
        watchStates = servers.watchStates,
        deletions = servers.deletions,
        libraryContent = servers.libraryContent,
        profileId = profileId,
        isProfileBinding = { profiles.bindState.value.unsettled },
        useGlobalHubs = { useGlobalHubs.value },
        // A server's push waits while video plays: the playback path stays quiet.
        isRefreshBlocked = { Route.Player in navigator.stacks.value },
        parentScope = scope,
        watchState = servers.watchState,
    )

    /** Where the sign-in, profile and connection screens lead, and the PIN they ask for ([Onboarding.pin]). */
    val onboarding = Onboarding(navigator, platform::openUrl, platform::closeInAppBrowser, platform::exit, { appearance.value.tv }) {
        servers.profiles.active.value?.id
    }

    /** The offline strip's and rail's Reconnect. */
    val reconnect = ReconnectStore(servers.profiles, servers.manager, servers.store, scope)

    init {
        servers.profiles.pinPrompt = onboarding.pin::ask
    }

    /**
     * Shows Settings (the user menu, the desktop's Settings chord): its tab, so a second Settings never stacks. Refused
     * while the player shows: false then.
     */
    fun openSettings(): Boolean {
        if (Route.Player in navigator.stacks.value) return false
        shell.select(TopLevelDestination.SETTINGS)
        return true
    }

    /** Home's user menu: the other profiles to switch to, Manage profiles, Settings, Log out. */
    val userMenu = UserMenuStore(profiles, removal, onboarding.pin, onboarding, { openSettings() }, scope)

    /** Home's Server Tasks button and panel, over the online Plex servers' tasks. */
    val serverTasks = ServerTasksStore(serverTaskServers ?: PlexServerTasks(servers.manager, servers.store), appearance.map { it.formFactor }, scope)

    /** The sign-in [signInAgain] opened last, and the server it signs in again to. */
    private val reauth = MutableStateFlow<Pair<Route, ServerId>?>(null)

    /**
     * The banner over the app's screens while a server refuses the account; null while none does. While Sign in again is
     * open for an expired server, the banner above it doesn't offer it again for that server.
     */
    val authErrorBanner: StateFlow<AuthErrorBannerUi?> = run {
        fun banner() = authErrorBanner(servers.store.state.value, reauthOpenFor())
        combine(servers.store.state, navigator.stacks, reauth) { _, _, _ -> banner() }
            .stateIn(scope, SharingStarted.Eagerly, banner())
    }

    private fun reauthOpenFor(): Set<ServerId> =
        reauth.value?.takeIf { (route, _) -> route in navigator.stacks.value }?.let { setOf(it.second) }.orEmpty()

    /**
     * The banner's Sign in again, for the first server that refused the account's token: a Jellyfin or Emby server's
     * sign-in with its address and user filled in; a Plex server's account by PIN. Done, it closes back to this screen.
     */
    fun signInAgain() {
        val serverId = servers.store.state.value.authErrorServerIds.firstOrNull()
        val connection = serverId?.let { (servers.manager.client(it) as? MediaBrowserServerClient)?.connection as? JellyfinConnection }
        val route = when {
            connection != null -> Route.AddMediaBrowser(connection.dialect, profileId = null, url = connection.baseUrl, username = connection.userName)
            serverId != null -> Route.AddPlexAccount(profileId = null)
            else -> Route.AddConnection(profileId = null)
        }
        reauth.value = serverId?.let { route to it }
        navigator.navigate(route)
    }

    /** The first sign-in's store, kept while [route] is on a stack; null for another route. */
    fun signIn(route: Route): SignInStore? = (route as? Route.SignIn)?.let {
        navigator.retain(it, ACCOUNTS, { SignInStore(profiles, onboarding, onboarding.recoveryRequired, scope) }, SignInStore::close)
    }

    fun profilePicker(route: Route): ProfilePickerStore? = (route as? Route.ProfilePicker)?.let {
        navigator.retain(it, ACCOUNTS, {
            ProfilePickerStore(it, profiles, removal, servers.connections, servers.bindings, onboarding.pin, onboarding, scope)
        }, ProfilePickerStore::close)
    }

    fun addProfile(route: Route): AddProfileStore? = (route as? Route.AddProfile)?.let {
        navigator.retain(it, ACCOUNTS, { AddProfileStore(profiles, onboarding.pin, onboarding, scope) }, AddProfileStore::close)
    }

    fun profileDetail(route: Route): ProfileDetailStore? = (route as? Route.ProfileDetail)?.let {
        navigator.retain(it, ACCOUNTS, {
            ProfileDetailStore(it, profiles, removal, servers.connections, servers.bindings, onboarding.pin, onboarding, scope)
        }, ProfileDetailStore::close)
    }

    /** Add connection's title and cards; null for another route. */
    fun addConnection(route: Route): Pair<String, List<AddConnectionOption>>? = (route as? Route.AddConnection)?.let { add ->
        addConnectionOptions(add, add.profileId?.let { id -> profiles.profiles.value.firstOrNull { it.id == id }?.displayName })
    }

    fun addPlexAccount(route: Route): AddPlexAccountStore? = (route as? Route.AddPlexAccount)?.let {
        navigator.retain(it, ACCOUNTS, { AddPlexAccountStore(it, profiles, onboarding, scope) }, AddPlexAccountStore::close)
    }

    fun addMediaBrowser(route: Route): AddMediaBrowserStore? = (route as? Route.AddMediaBrowser)?.let {
        navigator.retain(it, ACCOUNTS, { AddMediaBrowserStore(it, profiles, servers.connections, onboarding, scope) }, AddMediaBrowserStore::close)
    }

    fun editConnection(route: Route): EditConnectionStore? = (route as? Route.EditConnection)?.let {
        navigator.retain(it, ACCOUNTS, {
            EditConnectionStore(it, profiles, servers.connections, graph.http, onboarding, scope)
        }, EditConnectionStore::close)
    }

    fun borrowConnection(route: Route): BorrowStore? = (route as? Route.BorrowConnection)?.let {
        navigator.retain(it, ACCOUNTS, { BorrowStore(it, profiles, onboarding.pin, onboarding, scope) }, BorrowStore::close)
    }

    /** The server a music cast to this device plays from ([AppCast]): in memory only, found before the registered ones. */
    private var castMusicServer: MediaBackend? = null

    private fun castMusicServer(serverId: ServerId): MediaBackend? = castMusicServer?.takeIf { it.serverId == serverId }

    /**
     * The music session: its own audio player, queue and OS media controls, over the servers' clients and the shared
     * source resolver and progress reports. It follows the active profile: a switch saves and ends the previous
     * profile's session and brings back the new one's, parked paused.
     */
    val music: MusicPlaybackService = run {
        val registered = servers.manager.playbackServers()
        val playbackServers = object : PlaybackServers by registered {
            override fun client(serverId: ServerId): MediaBackend? = castMusicServer(serverId) ?: registered.client(serverId)

            override fun isServerVisible(serverId: ServerId): Boolean = castMusicServer(serverId) != null || registered.isServerVisible(serverId)

            override fun isClientOnline(serverId: ServerId): Boolean = castMusicServer(serverId) != null || registered.isClientOnline(serverId)
        }
        MusicPlaybackService(
            scope = graph.scope,
            audioPlayerFactory = platform::createMusicAudioPlayer,
            resolver = musicSources ?: PlaybackMusicSourceResolver(
                PlaybackSourceResolver(playbackServers, downloads?.videoSource ?: NoDownloadedVideos, servers.cachedPlaybackMetadata),
                { graph.data.deviceSettings.value(AppSettings.musicQualityPreset) },
            ),
            clients = { castMusicServer(it) ?: servers.manager.client(it) },
            settings = graph.data.deviceSettings,
            coordinator = graph.playbackCoordinator,
            foreground = graph.foreground,
            formFactor = platform.formFactor,
            appleAudioOutput = appleAudioOutput,
            system = platform.musicSystem,
            controls = platform.musicControls,
            discord = platform.discordPresence,
            discordPosters = graph.discordPosters,
            notifier = servers.watchStates,
            offlineQueue = OfflineProgressQueue { serverId, itemId, viewOffsetMs, durationMs ->
                servers.offlineWatchSync.queueProgressUpdate(serverId, itemId, viewOffsetMs, durationMs)
            },
        )
    }

    init {
        scope.launch {
            profiles.hydrated.first { it }
            profiles.active.map { it?.id }.distinctUntilChanged().collect { profileId ->
                music.switchProfile(profileId?.let { MusicSessionStore(graph.data.musicSessions, it) })
            }
        }
    }

    /** Acts on [link] in the active profile, its profile already applied. */
    private suspend fun launchLink(link: DeepLink, resolver: PlayLinkResolver) {
        when (link) {
            is DeepLink.Open, is DeepLink.ExternalPlayerReturn -> Unit
            is DeepLink.Play -> when (val resolution = resolver.resolve(link)) {
                is PlayLinkResolution.Failure -> links.report(resolution.reason)
                // Replaces whatever plays.
                is PlayLinkResolution.Item -> resolution.item.let { item ->
                    play(PlayRequest.Item(ServerId(item.serverId!!), item.id, item, offline = resolution.offline, showPlay = resolution.showPlay))
                }
                // The queue reports its own failures, as a shuffle from the show's page does.
                is PlayLinkResolution.Shuffle -> playQueues.launchShuffledShow(resolution.item).await().message?.let(links::report)
            }
            // Replaces whatever plays, as tuning from the guide does.
            is DeepLink.Live -> when (val result = link.channelLink.resolve(servers.store, isOffline = offline)) {
                is LiveTvLaunchResult.Ready -> playLive(result.launch)
                is LiveTvLaunchResult.Failed -> links.report(result.message)
            }
        }
    }

    /**
     * The music screens' ground: the [music] session, the servers, the navigator. Their stores come from
     * [musicNowPlaying], [musicAlbum], [musicArtist] and [musicPlaylist] (kept while their routes are on a stack) and
     * [musicMiniPlayer] (the app's).
     */
    val musicScreens = MusicScreens(
        playback = music,
        navigator = navigator,
        clients = servers.manager::client,
        serverOnline = servers.manager::isServerOnline,
        tv = platform.formFactor == FormFactor.TV,
        offline = combine(availability, servers.offlineMode.isOffline) { shown, noServer -> shown.offline || noServer }
            .stateIn(scope, SharingStarted.Eagerly, availability.value.offline || servers.offlineMode.isOffline.value),
        sleepTimerMinutes = setting(AppSettings.sleepTimerDuration),
        parentScope = scope,
        downloads = downloads?.let { ControllerMusicDownloads(it.controller, it.detail) },
    )

    /** The mini-player and the TV rail's Now Playing item. */
    val musicMiniPlayer: MiniPlayerStore = musicScreens.miniPlayer()

    fun musicNowPlaying(): NowPlayingStore? = navigator.retain(Route.NowPlaying, MUSIC, musicScreens::nowPlaying, NowPlayingStore::close)

    fun musicAlbum(route: Route.MusicAlbum): AlbumStore? = navigator.retain(route, MUSIC, { musicScreens.album(route) }, AlbumStore::close)

    fun musicArtist(route: Route.MusicArtist): ArtistStore? = navigator.retain(route, MUSIC, { musicScreens.artist(route) }, ArtistStore::close)

    fun musicPlaylist(route: Route.MusicPlaylist): MusicPlaylistStore? =
        navigator.retain(route, MUSIC, { musicScreens.playlist(route, mediaActions.menu::delete) }, MusicPlaylistStore::close)

    /**
     * Plays a library copy's own [trailer] (an item of a bound server) in the player: what a catalog title's Watch
     * trailer plays first. False when the item has no server.
     */
    fun playLibraryTrailer(trailer: MediaItem): Boolean {
        val serverId = trailer.serverId ?: return false
        play(PlayRequest.Item(ServerId(serverId), trailer.id, trailer))
        return true
    }

    /** Casting: allowed here as the setting says, its default following the layout (a phone in Force TV mode is a TV). */
    private val cast = AppCast(
        graph, platform, servers, playbacks, music, navigator,
        allowed = combine(graph.data.deviceSettings.observe(AppSettings.allowCasting), appearance) { stored, shown ->
            AppSettings.castingAllowed(stored, shown.formFactor)
        },
        setMusicServer = { server ->
            castMusicServer = server
            music.persistsSession = server == null
        },
        parentScope = scope,
    )

    /** This device as a cast sender: the picker, the target and its controls. */
    val castSender: CastSender get() = cast.sender

    /** This device as a cast receiver: its pairing prompt and the player's "Casting from" line. */
    val castReceiver: CastReceiver get() = cast.receiver

    /**
     * A cast receiver that isn't this device, living as long as this session: [device], playing through [playback],
     * announced through [discovery]. Development tools stand one in for a second device.
     */
    fun castPeerReceiver(device: CastPeerInfo, playback: CastPlayback, discovery: CastDiscovery): CastReceiver =
        cast.peerReceiver(device, playback, discovery)

    /** A cast sender that isn't this device, casting with this session's server access: as [castPeerReceiver]. */
    fun castPeerSender(device: CastPeerInfo, discovery: CastDiscovery): CastSender = cast.peerSender(device, discovery)

    /** The settings pages' stores. */
    val settings: SettingsStores = SettingsStores(graph, platform, SessionSettings(), scope, externalPlayers = externalPlayers)

    /** Opens the web link [url] outside the app ([AppPlatform.openUrl]); any other link is dropped. */
    fun openUrl(url: String) {
        if (WebUrl.isWeb(url)) platform.openUrl(url)
    }

    private val mutableNotice = MutableStateFlow<MenuMessage?>(null)

    /**
     * A message over the app (an edit saved or failed, a sheet's parting word), outliving the screen that showed it;
     * null while none shows. [MenuMessage.isError] ones read as errors.
     */
    val notice: StateFlow<MenuMessage?> = mutableNotice.asStateFlow()

    /** Shows [text] over the app ([notice]), as an error when [isError]. */
    fun notify(text: String, isError: Boolean = false) {
        mutableNotice.value = MenuMessage(text, isError)
    }

    /** The [notice] showed: the UI clears it. */
    fun noticeShown() {
        mutableNotice.value = null
    }

    init {
        // The downloads' own messages: watched downloads removed ("Auto-removed: …") and episodes a sync rule queued.
        downloads?.controller?.let { controller ->
            scope.launch { merge(controller.autoRemovedMessages, controller.syncMessages).collect(::notify) }
        }
    }

    private val recentTags = RecentTags(graph.data.profileSettings)

    /** Metadata editing: an item's Edit, Quick Tag, Match and Unmatch, the editor's and the match screen's stores. */
    val metadata: MetadataEditing = MetadataEditing(
        deps = MetadataEditDeps(
            client = servers.manager::client,
            recentTags = { serverId, fieldId ->
                profiles.active.value?.id?.ifEmpty { null }?.let { recentTags.recentTags(it, serverId, fieldId) }.orEmpty()
            },
            addRecentTags = { tags, serverId, fieldId ->
                profiles.active.value?.id?.ifEmpty { null }?.let { recentTags.addRecentTags(tags, it, serverId, fieldId) }
            },
            notify = ::notify,
            close = { navigator.pop(it) },
            edited = { serverId, itemId -> metadata.onEdited(serverId, itemId) },
        ),
        navigator = navigator,
        isOwnerOrAdmin = servers.manager::isOwnerOrAdmin,
        activeProfile = { profiles.active.value },
        scope = scope,
    )

    init {
        scope.launch { metadata.edited.collect { mutableDiscover.value.refreshEdited(it.serverId, it.itemId) } }
    }

    /**
     * Ends the app for a quit (the window closed, the app told to quit), before [close]: the playback stops and its last
     * reports go out, then the trackers hear the stop, each waited for up to [EXIT_STEP_TIMEOUT].
     */
    suspend fun shutdownForExit(): Unit = withContext(Dispatchers.Main.immediate) {
        if (withTimeoutOrNull(EXIT_STEP_TIMEOUT) { playbacks.shutdownVideo() } == null) {
            Log.w(TAG) { "the playback's last reports didn't finish within $EXIT_STEP_TIMEOUT of the quit" }
        }
        // The hub bounds its own stop by the same time.
        trackersStopped = true
        graph.trackers.shutdown()
    }

    /** [shutdownForExit] stopped the trackers: [close] leaves them be. */
    private var trackersStopped = false

    /**
     * Ends the playback (the trackers' too), releases the screens' stores, the music session, the profile's accounts,
     * the downloads and the servers. Later calls do nothing.
     */
    fun close() {
        watch.close()
        playbacks.close()
        closeRatingSheet()

        reconnect.close()
        shell.close()
        musicMiniPlayer.close()
        navigator.close()
        music.close()
        downloads?.close()
        cast.close()
        mutableDiscover.value.close()
        settings.close()
        servers.close()
        // The open playback's stop goes out, within the hub's own time limit, in the app's scope.
        if (!trackersStopped) graph.scope.launch { graph.trackers.shutdown() }
        supporter.close()
        scope.cancel()
        matcher?.dispose()
        catalog.release()
        seerr.close()
    }

    /** The active profile's Plex identity and token, the Home user's own when it holds one. */
    private suspend fun activePlexToken(): ActivePlexToken? {
        val active = profiles.active.value
        val bindings = active?.let { servers.bindings.listForProfile(it.id) }.orEmpty()
        val identity = resolveActivePlexIdentity(active, bindings, servers.connections.list()) ?: return null
        return resolveActivePlexToken(identity, active, bindings, allowAccountTokenForHomeUser = true)?.takeIf { it.token.isNotEmpty() }
    }

    private suspend fun plexDiscoverSession(): PlexDiscoverSession? {
        val token = activePlexToken() ?: return null
        return PlexDiscoverSession(token.token, servers.identity.getOrCreateClientIdentifier()).takeIf { it.isUsable }
    }

    /** The interface language as Plex Discover and Seerr take it: `zh-TW` for Traditional Chinese, else its language code. */
    private fun serviceLanguage(): String {
        val shown = Locales.resolve(T.locale)
        return if (shown == "zh-Hant") "zh-TW" else shown.substringBefore('-')
    }

    private fun detailDeps() = DetailDeps(
        client = servers.manager::client,
        watchActions = servers.watchActions,
        watchState = servers.watchState,
        watchEvents = servers.watchStates.events,
        deletions = servers.deletions.events,
        play = ::play,
        cardOptions = { cardOptions.value },
        tv = appearance.value.tv,
        communityRatings = { item, client ->
            profiles.active.value?.id?.let { profileId ->
                graph.trackers.ratings.forLibraryItem(profileId, item, client)
            } ?: emptyFlow()
        },
        downloads = downloads?.let { ControllerDetailDownloads(it.controller, it.detail) },
        shuffle = playQueues::launchShuffledShow,
        previewTracks = { item, client -> previewDetailTracks(item, client, versionPreferences) },
        savedVersion = { item -> versionPreferences.saved(item)?.resolveIndex(item.mediaVersions.orEmpty()) },
        currentQuality = { playbacks.defaultQuality() },
        trackInvalidations = graph.data.deviceSettings.observe(AppSettings.mediaVersionPreferences).drop(1),
        offline = downloads?.let { DownloadsOfflineDetail(it.controller, servers.offlineWatch) },
        edited = metadata.edited,
        pruneDistantSeasons = appearance.value.tv && platform.lowEndHardware,
        seasonPostersOnTabs = { seasonPostersOnTabs.value },
        playingKey = { playingKey.value },
        placeIn = navigator::placeIn,
        requests = Dispatchers.Default,
    )

    private val seasonPostersOnTabs = graph.data.deviceSettings.observe(AppSettings.showSeasonPostersOnTabs)
        .stateIn(scope, SharingStarted.Eagerly, false)

    private val versionPreferences = MediaVersionPreferences(graph.data.deviceSettings)

    /** The detail store of [route], kept while the route is on a stack. */
    fun mediaDetail(route: Route.MediaDetail): MediaDetailStore? =
        navigator.retain(route, DETAIL, { MediaDetailStore(route, detailDeps(), scope) }, MediaDetailStore::close)

    /** The actor screen's store of [route]. */
    fun person(route: Route.Person): PersonStore? = navigator.retain(
        route,
        DETAIL,
        { PersonStore(route, servers.manager.client(route.serverId), { cardOptions.value }, ::localToday, scope) },
        PersonStore::close,
    )

    /** The collection screen's store of [route]. */
    fun collection(route: Route.CollectionDetail): CollectionStore? = navigator.retain(
        route,
        DETAIL,
        {
            CollectionStore(
                route,
                servers.manager.client(route.serverId),
                { cardOptions.value },
                playQueues::launchCollection,
                servers.libraryRefresh.collectionsChanged,
                scope,
                offline = downloads?.let { DownloadsOfflineCollection(it.controller, servers.watchActions) { servers.offlineMode.isOffline.value } },
            )
        },
        CollectionStore::close,
    )

    /** The Search destination's store. */
    fun search(route: Route): SearchStore? {
        if (route != Route.Search) return null
        val deps = SearchDeps(
            search = { query, hidden ->
                servers.aggregation.searchAcrossServers(query, hiddenLibraryKeys = hidden, serverOrder = servers.libraries.librariesServerOrder)
            },
            hiddenLibrariesReady = { servers.hiddenLibraries.ensureInitialized() },
            hiddenLibraryKeys = { servers.hiddenLibraries.hiddenLibraryKeys },
            hiddenLibraryChanges = servers.hiddenLibraries.state.map { it.hiddenLibraryKeys },
            client = servers.manager::client,
            serverCount = { servers.store.state.value.totalServerCount },
            libraryLabel = servers.libraries::libraryLabelFor,
            cardOptions = { cardOptions.value },
            open = { mediaActions.open(it, playDirectly = false) },
            menu = { mediaActions.menu.open(it) },
            watchStates = servers.watchStates.events,
            edited = metadata.edited,
            fetchItem = { serverId, id -> servers.manager.client(serverId)?.fetchItem(id) },
            sessionExpired = servers.store.state.map { state -> state.authErrorServers.map { it.displayName } },
        )
        return navigator.retain(route, SEARCH, { SearchStore(deps, scope) }, SearchStore::close)
    }

    /** What the settings pages read of this session: the libraries, the profiles and their accounts. */
    private inner class SessionSettings : SettingsSession {
        override val perks: StateFlow<ThemePerks> = supporter.unlocked
            .map { ThemePerks(available = supporter.available, unlocked = it) }
            .stateIn(scope, SharingStarted.Eagerly, ThemePerks(available = supporter.available, unlocked = supporter.unlocked.value))
        override val servicesSummary: StateFlow<String> get() = this@AppSession.servicesSummary
        override val hasLibraries: StateFlow<Boolean> = run {
            fun shown() = manageLibrariesShown(
                servers.libraries.state.value, servers.profiles.active.value != null,
                servers.profiles.bindState.value.unsettled, servers.store.state.value.totalServerCount,
            )
            combine(servers.libraries.state, servers.profiles.active, servers.profiles.bindState, servers.store.state) { _, _, _, _ -> shown() }
                .stateIn(scope, SharingStarted.Eagerly, shown())
        }
        override val hasCatalog: StateFlow<Boolean> =
            catalog.state.map { it.hasAnySource }.stateIn(scope, SharingStarted.Eagerly, catalog.state.value.hasAnySource)
        override val profiles: StateFlow<List<Profile>> get() = servers.profiles.profiles
        override val activeProfile: StateFlow<Profile?> get() = servers.profiles.active
        override val profileBinding: StateFlow<Boolean> = run {
            val profiles = servers.profiles
            fun binding() = !profiles.hydrated.value || (profiles.active.value != null && profiles.bindState.value.unsettled)
            combine(profiles.hydrated, profiles.active, profiles.bindState) { _, _, _ -> binding() }
                .stateIn(scope, SharingStarted.Eagerly, binding())
        }

        override val accountPreferences: AccountPreferencesController get() = this@AppSession.accountPreferences

        override suspend fun accountPreferenceAccounts(): List<AccountPreferenceAccount> = preferenceAccounts().first

        override suspend fun reloadLibraries() {
            servers.hiddenLibraries.refresh()
            scope.launch { servers.libraries.refresh() }
        }

        override suspend fun resetDownloadLocation() {
            downloads?.controller?.resetDownloadLocation()
        }

        override val castSenders: Flow<List<CastPeerInfo>> get() = cast.senders.peers.map { peers -> peers.map { it.device } }

        override suspend fun forgetCastSender(id: String) = cast.senders.forget(id)
    }

    /**
     * The start is over and the main screen shows (set by [RootSession] as it shows the main screen; a development
     * session is primed from the start): returns from the background act only then.
     */
    internal var primed = true

    private val resumeGate = ResumeGate(graph.timeSource)

    init {
        scope.launch {
            // Visibility, not activation: a Mac window left in sight while another app is in front was never away.
            graph.visible.drop(1).collect { foreground ->
                if (!foreground) return@collect resumeGate.backgrounded(inPictureInPicture = playbacks.continuesInPictureInPicture)
                val resume = resumeGate.resumed() ?: return@collect
                if (!primed) return@collect
                scope.launch { seerr.refreshUser() }
                if (resume.staleRefresh && !offline && playbacks.active.value == null && servers.store.state.value.hasConnectedServers) {
                    Log.i(TAG) { "back after a long background: reloading the content" }
                    scope.launch { servers.libraries.refresh() }
                    refreshContentTabs()
                }
                val prompt = shouldPromptProfileOnResume(
                    resumedFromBackground = resume.prompt,
                    offline = offline,
                    pickerShown = navigator.backStack.value.any { it is Route.ProfilePicker },
                    desktop = platform.formFactor == FormFactor.DESKTOP,
                    castReceiving = castReceiver.state.value.castingFrom != null,
                )
                // The picker shows over an open player, which stays paused until a profile is chosen.
                if (prompt && !links.selectsProfile && profiles.requiresSelectionOnOpen()) {
                    scope.launch { playbacks.holdForProfilePick { onboarding.pickProfile() } }
                }
            }
        }
    }

    private companion object {
        const val TAG = "AppSession"

        /** How long a quit waits for each of its steps: the playback's last reports, the trackers' stop. */
        val EXIT_STEP_TIMEOUT = 3.seconds

        const val DETAIL = "detail"
        const val DETAIL_WATCHLIST = "detailWatchlist"
        const val SEARCH = "search"
        const val MUSIC = "music"
        const val SERVICES = "services"
        const val ACCOUNTS = "accounts"
        const val EXPLORE = "explore"
        const val CATALOG_SEARCH = "catalogSearch"
        const val EXPLORE_ROW = "exploreRow"
        const val CATALOG_DETAIL = "catalogDetail"
        const val SEERR_REQUEST = "seerrRequest"
        const val SEERR_PERSON = "seerrPerson"
        const val SEERR_CONNECT = "seerrConnect"
        const val SEERR_SETTINGS = "seerrSettings"
        const val LIVE_TV = "liveTv"
        const val LIVE_TV_SCHEDULE = "liveTvSchedule"

        /** How long a show schedule opened without the Live TV screen's channels waits for its server's Live TV. */
        val SCHEDULE_SERVER_WAIT = 20.seconds
        const val HOME = "home"
        const val HUB_DETAIL = "hubDetail"
        const val PLAYLIST = "playlist"
        const val LIBRARIES = "libraries"

    }
}

/**
 * Shows the interface in the language [stored] in [AppSettings.appLocale]: none follows the device's languages
 * ([InterfaceLocale.setSystemLanguages]), a name this build doesn't know is English ([AppLocale.fromStored]).
 */
internal fun applyInterfaceLanguage(stored: String?) {
    InterfaceLocale.setChosen(AppLocale.fromStored(stored)?.tag)
}

/** A device without downloads (Apple TV): offline watch state finds nothing downloaded. */
internal object NothingDownloaded : OfflineWatchDownloads {
    override suspend fun downloadedClientScopeId(globalKey: String): String? = null

    override suspend fun ownedDownloads(profileId: String): List<DownloadedWatchItem> = emptyList()

    override suspend fun downloadedEpisodesForShow(showGlobalKey: String): List<MediaItem> = emptyList()

    override suspend fun metadata(globalKey: String): MediaItem? = null

    override suspend fun deleteWatchedDownload(globalKey: String) = Unit
}

private const val TAG = "AppSession"

package com.edde746.plezy.app

import com.edde746.plezy.backend.BackendCache
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.data.connections.ConnectionStore
import com.edde746.plezy.importer.EarlierReleaseImport
import com.edde746.plezy.importer.PlexUserLookup
import com.edde746.plezy.jellyfin.JellyfinApiCache
import com.edde746.plezy.jellyfin.JellyfinAuthService
import com.edde746.plezy.jellyfin.JellyfinCacheResolver
import com.edde746.plezy.jellyfin.JellyfinConnection
import com.edde746.plezy.jellyfin.JellyfinConnector
import com.edde746.plezy.jellyfin.JellyfinDeviceIdentity
import com.edde746.plezy.jellyfin.JellyfinProfileBinding
import com.edde746.plezy.jellyfin.VideoCodecSupport
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.plex.PlexServer
import com.edde746.plezy.playback.output.VideoCapabilities
import com.edde746.plezy.playback.source.CachedPlaybackMetadata
import com.edde746.plezy.playback.output.VideoCodec
import com.edde746.plezy.plex.PlexApiCache
import com.edde746.plezy.plex.PlexClientEnvironment
import com.edde746.plezy.plex.PlexPlatformConnector
import com.edde746.plezy.plex.tv.PlexAuthService
import com.edde746.plezy.profiles.ProfileConnectionRegistry
import com.edde746.plezy.profiles.ProfileIdentity
import com.edde746.plezy.profiles.Profile
import com.edde746.plezy.profiles.ProfileServices
import com.edde746.plezy.profiles.mediaBrowser
import com.edde746.plezy.profiles.stored
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.servers.ConnectivityProbe
import com.edde746.plezy.servers.DataAggregationService
import com.edde746.plezy.servers.MediaBrowserClientEvents
import com.edde746.plezy.servers.MediaBrowserConnection
import com.edde746.plezy.servers.PlexClientEvents
import com.edde746.plezy.servers.PlexProfileScopeId
import com.edde746.plezy.servers.PlexServerClient
import com.edde746.plezy.servers.DeletionNotifier
import com.edde746.plezy.servers.LibraryRefreshNotifier
import com.edde746.plezy.servers.HiddenLibrariesStore
import com.edde746.plezy.servers.LibrariesFetcher
import com.edde746.plezy.servers.LibrariesStore
import com.edde746.plezy.servers.LibraryContentNotifier
import com.edde746.plezy.servers.LibraryEventService
import com.edde746.plezy.servers.LocalPlaybackHistory
import com.edde746.plezy.servers.MultiServerManager
import com.edde746.plezy.servers.MultiServerStore
import com.edde746.plezy.servers.NetworkStateConnectivitySource
import com.edde746.plezy.servers.OfflineModeStore
import com.edde746.plezy.servers.OfflineWatchDownloads
import com.edde746.plezy.servers.OfflineWatchProvider
import com.edde746.plezy.servers.OfflineWatchSyncService
import com.edde746.plezy.servers.PlaybackStateStore
import com.edde746.plezy.servers.ProfileTrackerWatchMarks
import com.edde746.plezy.servers.TrackerWatchMarks
import com.edde746.plezy.servers.WatchActions
import com.edde746.plezy.servers.WatchStateNotifier
import com.edde746.plezy.servers.WatchStateStore
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.ServerWatchedThresholds
import com.edde746.plezy.settings.json.SettingsLocalPlaybackHistoryStore
import com.edde746.plezy.strings.InterfaceLocale
import com.edde746.plezy.strings.Locales
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onStart
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import kotlin.time.Duration

/**
 * The media servers of one running app ([AppSession.servers]): the connections and the profiles' bindings to them
 * ([profiles]), every connected server ([manager], [store]), offline mode, the libraries, the cross-server reads, the
 * library push channels and watch marks, offline ones included. Built on the main thread with its session, [close]d
 * with it; it lives across profile switches.
 *
 * It follows the app: coming to the foreground re-probes the servers ([MultiServerManager.probeAfterResume]), re-arms
 * the push channels and syncs offline watch state; going to the background drops the push channels. The network's
 * changes reach the manager through [AppGraph.network]; the interface language reaches the Plex clients' metadata.
 *
 * @param downloads what offline watch state reads of the downloads.
 * @param trackers where watched marks are mirrored to (Trakt, MyAnimeList, …): the active profile's trackers.
 * @param profileTrackers each profile's own trackers, for the offline watch sync's work that outlives a profile switch.
 * @param startupProfile / [settleStartupProfile] the profile a launch link names, which the profiles' start activates
 *   ([ProfileServices.start]).
 */
class AppServers internal constructor(
    private val graph: AppGraph,
    platform: AppPlatform,
    downloads: OfflineWatchDownloads,
    trackers: TrackerWatchMarks,
    profileTrackers: ProfileTrackerWatchMarks,
    private val startupProfile: (List<Profile>) -> Profile? = { null },
    private val settleStartupProfile: (applied: Boolean) -> Unit = {},
) {
    private val scope = graph.scope.childScope()
    private val data = graph.data
    private val device = platform.device
    private val formFactor = platform.formFactor
    private var closed = false

    /** The device's client identifier as last read ([ProfileIdentity.getOrCreateClientIdentifier]); null before [start]. */
    private var clientIdentifier: String? = null

    private val refusedVideoCodecs = data.deviceSettings.observe(AppSettings.refusedVideoCodecs).current(AppSettings.refusedVideoCodecs.default)
    private val directPlayCoveredQuality = data.deviceSettings.observe(AppSettings.directPlayCoveredQuality).current(AppSettings.directPlayCoveredQuality.default)
    private val specialsOrdering = data.deviceSettings.observe(AppSettings.specialsOrdering).current(AppSettings.specialsOrdering.default)
    private val autoRemoveWatchedDownloads = data.deviceSettings.observe(AppSettings.autoRemoveWatchedDownloads).current(AppSettings.autoRemoveWatchedDownloads.default)

    // Hardware decoders are read once, at the first negotiation; the user's refusals live.
    private val videoCapabilities by lazy { platform.videoCapabilities() }

    /** The stored connections. The app's only instance: two would interleave their token writes. */
    val connections = ConnectionStore(data, graph.secrets)

    /** The profiles' bindings to [connections]. The app's only instance, as [connections]. */
    val bindings = ProfileConnectionRegistry(data, graph.secrets)

    /** The active profile, recency and the client identifier. */
    val identity = ProfileIdentity(data)

    private val thresholds = ServerWatchedThresholds(data.serverSettings, scope)

    /** What the Plex clients of this device's own servers run with; [handedOverPlexClient]'s records nothing. */
    private val plexEnvironment = PlexClientEnvironment(
        transcodeVideoCodecIds = { videoCodecSupport(videoCapabilities, refusedVideoCodecs.value).transcodeCodecs },
        isVideoCodecRefused = { codec -> isRefusedVideoCodec(codec, refusedVideoCodecs.value) },
        directPlayCoveredQuality = { directPlayCoveredQuality.value },
        onWatchedThresholdChanged = thresholds::record,
        specialsOrdering = { specialsOrdering.value },
    )

    /** Which Jellyfin and Emby users' cached answers are whose: the connections and the profiles' bindings to them. */
    val jellyfinCacheResolver = JellyfinCacheResolver(data.apiCache, ::mediaBrowserConnections, ::mediaBrowserBindings)

    /** The servers' cached answers by backend, the downloads' pinned metadata among them. */
    val caches: Map<BackendKind, BackendCache>

    /** The network's links (Wi-Fi, Ethernet, cellular) as [AppGraph.network] reports them. */
    val connectivity = ConnectivityProbe(NetworkStateConnectivitySource(graph.network))

    /** Every connected server, Plex and Jellyfin/Emby; the online servers cross-server reads fan out to. */
    val manager: MultiServerManager

    /** The servers as the active profile sees them: online, refused, with Live TV. */
    val store: MultiServerStore

    val offlineMode: OfflineModeStore

    /** Libraries, Continue Watching, hubs and search across the online servers. */
    val aggregation: DataAggregationService

    /** This device's playback history, which picks the copy of a title Continue Watching shows. */
    val playbackHistory = LocalPlaybackHistory(SettingsLocalPlaybackHistoryStore(data.deviceSettings), graph.clock)

    /** Server pushes about library content, coalesced per burst. */
    val libraryContent = LibraryContentNotifier()

    /** Items deleted on a server or in the app, to drop in place. */
    val deletions = DeletionNotifier()

    /** Playlists or collections changed in the app (one created, added to, deleted): their lists load again. */
    val libraryRefresh = LibraryRefreshNotifier()

    /** Watched, progress and Continue Watching changes, from any source. */
    val watchStates = WatchStateNotifier()

    /** The session's watch-state patches over the servers' rows: what a screen draws an item's watch state from. */
    val watchState = WatchStateStore(watchStates, scope)

    /** The push channel of each visible online server. */
    val libraryEvents: LibraryEventService

    /** The library list, in the active profile's order. */
    val libraries: LibrariesStore

    /** The active profile's hidden libraries. */
    val hiddenLibraries: HiddenLibrariesStore

    val offlineWatchSync: OfflineWatchSyncService
    val offlineWatch: OfflineWatchProvider

    /** The user's watched and unwatched marks. */
    val watchActions: WatchActions

    /** The play queue the player walks. */
    val playbackState = PlaybackStateStore()

    /** The profiles, the active one, its binding, sign-in and activation. */
    val profiles: ProfileServices

    /** The items the API cache holds, which a play without its server falls back to. */
    val cachedPlaybackMetadata: CachedPlaybackMetadata

    init {
        val plexCache = PlexApiCache(data.apiCache, graph.clock)
        val jellyfinCache = JellyfinApiCache(data.apiCache, jellyfinCacheResolver)
        caches = mapOf(BackendKind.PLEX to plexCache, BackendKind.JELLYFIN to jellyfinCache, BackendKind.EMBY to jellyfinCache)
        cachedPlaybackMetadata = CachedPlaybackMetadata(data.apiCache, jellyfinCacheResolver)
        val plex = plexConnector(plexCache, plexEnvironment)
        val jellyfin = jellyfinConnector(jellyfinCache)
        manager = MultiServerManager(
            plexConnector = plex,
            mediaBrowserConnector = jellyfin,
            preferredEndpoints = data.serverSettings,
            connectivityChanges = connectivity.changes,
            scope = scope,
            resumeProbeCooldown = if (formFactor == FormFactor.DESKTOP) {
                MultiServerManager.RESUME_PROBE_COOLDOWN_DESKTOP
            } else {
                MultiServerManager.RESUME_PROBE_COOLDOWN_MOBILE
            },
            timeSource = graph.timeSource,
        )
        store = MultiServerStore(manager = manager, scope = scope)
        profiles = ProfileServices(
            data = data,
            connections = connections,
            bindings = bindings,
            identity = identity,
            manager = manager,
            servers = store,
            plexAuth = ::plexAuth,
            jellyfinAuth = ::jellyfinAuth,
            scope = scope,
            clock = graph.clock,
        )
        offlineMode = OfflineModeStore(manager, store, connectivity, profiles.bindState.map { it.binding }, scope)
        aggregation = DataAggregationService(manager) { playbackHistory.snapshot() }
        libraryEvents = LibraryEventService(manager, libraryContent, deletions, scope)
        hiddenLibraries = HiddenLibrariesStore(data.libraryPrefs, scope = scope)
        offlineWatchSync = OfflineWatchSyncService(
            queue = data.offlineWatch,
            downloads = downloads,
            clients = manager,
            notifier = watchStates,
            trackers = profileTrackers,
            thresholds = thresholds,
            offlineMode = offlineMode,
            scope = scope,
            minSyncInterval = if (formFactor == FormFactor.HANDHELD) Duration.ZERO else OfflineWatchSyncService.DESKTOP_MIN_SYNC_INTERVAL,
            forceSyncOnResume = formFactor == FormFactor.HANDHELD,
            timeSource = graph.timeSource,
        )
        offlineWatch = OfflineWatchProvider(
            syncService = offlineWatchSync,
            downloads = downloads,
            notifier = watchStates,
            scope = scope,
            specialsOrdering = { specialsOrdering.value },
            autoRemoveWatchedDownloads = { autoRemoveWatchedDownloads.value },
        )
        watchActions = WatchActions(manager, offlineMode, offlineWatch, watchStates, trackers, scope)
        libraries = LibrariesStore(
            preferences = data.libraryPrefs,
            scope = scope,
            libraryEvents = libraryContent.events,
            onlineServers = store.onlineServersChanges,
            isProfileBinding = { profiles.bindState.value.binding },
            serverOrder = { manager.serverOrder },
        )
        libraries.initialize(LibrariesFetcher { aggregation.getMediaLibrariesFromAllServers(it) })
        start()
    }

    private fun start() {
        scope.launch {
            try {
                clientIdentifier = identity.getOrCreateClientIdentifier()
                thresholds.load()
                offlineMode.initialize()
            } finally {
                // Started whatever failed above (a database that fails its reads), so the start's route
                // ([ProfileServices.bootRoute]) settles and the splash never stays. Without a network the first bind asks
                // no PIN: plex.tv can't check it, and the splash's capped wait would leave the dialog behind.
                profiles.start(
                    allowInitialPinPrompt = connectivity.check().hasNetwork,
                    startupProfile = startupProfile,
                    settleStartupProfile = settleStartupProfile,
                )
            }
        }
        scope.launch {
            store.onlineServersChanges.collect { offlineWatchSync.onServersConnected() }
        }
        scope.launch {
            // Legacy offline actions are adopted only once the profile count is known (hydrated).
            combine(profiles.active, profiles.hydrated, profiles.profiles) { active, hydrated, all ->
                active?.id to all.size.takeIf { hydrated }
            }.distinctUntilChanged().collect { (profileId, count) -> offlineWatchSync.setActiveProfileId(profileId, count) }
        }
        scope.launch {
            // The overlay is the active profile's, and keys a user-scoped server's marks (a Jellyfin or Emby user, a
            // Plex Home profile) by the scope its bound client signed in as: without the scopes, those marks never
            // resolve onto items.
            combine(profiles.active.map { it?.id }.distinctUntilChanged(), manager.statusUpdates.onStart { emit(emptyMap()) }) { id, _ -> id }
                .collect { profileId ->
                    watchState.setActiveProfileId(profileId)
                    watchState.setActiveClientScopesByServer(manager.serverIds.associateWith { manager.client(it)?.cacheServerId })
                }
        }
        scope.launch {
            // The first hydrated profile is the one the session starts with; each later one is a switch.
            profiles.hydrated.first { it }
            profiles.active.map { it?.id }.distinctUntilChanged().drop(1).collect {
                libraries.clear()
                hiddenLibraries.refresh()
            }
        }
        if (!graph.foreground.value) libraryEvents.suspend()
        // Subscribed before this returns: the app coming to the front right after the check above resumes the channels.
        scope.launch(start = CoroutineStart.UNDISPATCHED) {
            graph.foreground.drop(1).collect { foreground ->
                if (foreground) {
                    libraryEvents.resume()
                    offlineWatchSync.onAppResumed()
                    manager.probeAfterResume()
                } else {
                    libraryEvents.suspend()
                }
            }
        }
        scope.launch {
            EarlierReleaseImport(data, graph.secrets).nameImportedPlexAccount(connections, graph.network, graph.plexUserLookup(device))
        }
    }

    /** plex.tv sign-in and Home users, as this device with its current client identifier. */
    private suspend fun plexAuth(): PlexAuthService = graph.plexAuthService(device, currentClientIdentifier())

    /** Jellyfin or Emby sign-in, as this device with its current client identifier. */
    private suspend fun jellyfinAuth(dialect: MediaBrowserDialect): JellyfinAuthService =
        JellyfinAuthService(graph.http, jellyfinIdentity(currentClientIdentifier()), dialect)

    private suspend fun currentClientIdentifier(): String = identity.getOrCreateClientIdentifier().also { clientIdentifier = it }

    private fun jellyfinIdentity(deviceId: String) =
        JellyfinDeviceIdentity(device.jellyfinClientName, device.jellyfinDeviceName, graph.appVersion, deviceId)

    private suspend fun mediaBrowserConnections(): List<JellyfinConnection> = connections.list().mapNotNull { it.mediaBrowser() }

    private suspend fun mediaBrowserBindings(): List<JellyfinProfileBinding> {
        val ids = connections.list().filter { it.kind.usesMediaBrowserApi }.mapTo(HashSet()) { it.id }
        return bindings.listAll().filter { it.connectionId in ids }.map {
            JellyfinProfileBinding(it.profileId, it.connectionId, it.userIdentifier, it.isDefault, it.lastUsedAt)
        }
    }

    private fun plexConnector(cache: PlexApiCache, environment: PlexClientEnvironment) = PlexPlatformConnector(
        httpClient = graph.http,
        cache = cache,
        scope = scope,
        environment = environment,
        appVersion = graph.appVersion,
        platform = device.platform,
        device = device.plexDevice,
        deviceName = device.plexDeviceName,
        languageCode = { plexLanguageCode(InterfaceLocale.tag.value) },
        refreshServers = { accountId -> profiles.refreshPlexServers(accountId) },
    )

    private fun jellyfinConnector(cache: BackendCache) = JellyfinConnector(
        http = graph.http,
        identity = { connection -> jellyfinIdentity(connection.deviceId.ifEmpty { checkNotNull(clientIdentifier) }) },
        cache = cache,
        scope = scope,
        persist = { connection -> connections.upsert(connection.stored()) },
        codecs = { videoCodecSupport(videoCapabilities, refusedVideoCodecs.value) },
        specialsOrdering = { specialsOrdering.value },
        favorites = data.liveTvFavorites,
    )

    /**
     * A client of the Plex [server] a cast handed over, outside the registry, on its first endpoint to answer, acting
     * for [clientIdentifier] under [profileScope]. Nothing of it is stored: it caches in its own memory
     * ([HandedOverApiCache]), which goes with it, and keeps no watched threshold, endpoint or connection. Throws when no
     * endpoint answers.
     */
    internal suspend fun handedOverPlexClient(server: PlexServer, clientIdentifier: String, profileScope: PlexProfileScopeId): PlexServerClient {
        val connector = plexConnector(PlexApiCache(HandedOverApiCache(graph.clock), graph.clock), plexEnvironment.copy(onWatchedThresholdChanged = { _, _ -> }))
        val first = connector.raceEndpoints(server, null, clientIdentifier).firstOrNull()
            ?: throw IllegalStateException("No working connection found for ${server.name}")
        return connector.createClient(server, first, server.prioritizedEndpointUrls(first.url), clientIdentifier, profileScope, HandedOverEvents)
    }

    /** A client of the Jellyfin or Emby [connection] a cast handed over, stored nowhere, as [handedOverPlexClient]. */
    internal suspend fun handedOverMediaBrowserClient(connection: JellyfinConnection): MediaBackend {
        val cache = HandedOverApiCache(graph.clock)
        val resolver = JellyfinCacheResolver(cache, connections = { listOf(connection) }, bindings = { emptyList() })
        return jellyfinConnector(JellyfinApiCache(cache, resolver)).createClient(connection, HandedOverEvents)
    }

    /** A handed-over client's reports go nowhere: no failover to follow, no connection to store. */
    private object HandedOverEvents : PlexClientEvents, MediaBrowserClientEvents {
        override fun onAllEndpointsExhausted() = Unit

        override suspend fun onEndpointChanged(newUrl: String) = Unit

        override suspend fun onConnectionUpdated(updated: MediaBrowserConnection) = Unit
    }

    private fun <T> Flow<T>.current(initial: T): StateFlow<T> = stateIn(scope, SharingStarted.Eagerly, initial)

    /**
     * Stops everything: the profiles' work, the stores and the push channels at once; the servers' clients drain in the
     * background. Later calls do nothing.
     */
    fun close() {
        if (closed) return
        closed = true
        profiles.close()
        libraryEvents.dispose()
        libraries.dispose()
        hiddenLibraries.close()
        offlineMode.dispose()
        store.dispose()
        graph.scope.launch {
            try {
                manager.shutdown()
            } finally {
                scope.cancel()
            }
        }
    }
}

/**
 * The video codecs this device takes from a server, as a transcode's target or the file itself: HEVC and AV1 unless
 * the user refused them ([AppSettings.refusedVideoCodecs]) or the device's decoders are known and lack them. Where the
 * platform can't tell its hardware decoders, it takes both: a desktop decodes them in software.
 */
internal fun videoCodecSupport(capabilities: VideoCapabilities, refused: List<String>): VideoCodecSupport {
    val known = capabilities.hardwareCodecs
    fun accepts(id: String, codec: VideoCodec) = id !in refused && (known.isEmpty() || codec in known)
    return VideoCodecSupport(hevc = accepts("hevc", VideoCodec.HEVC), av1 = accepts("av1", VideoCodec.AV1))
}

/** Whether the user refused the source codec [codec] (a server's name for it, aliases included); H.264 never is. */
internal fun isRefusedVideoCodec(codec: String?, refused: List<String>): Boolean = when (codec?.lowercase()) {
    "av1" -> "av1" in refused
    "hevc", "h265", "hev1" -> "hevc" in refused
    else -> false
}

/** The language Plex metadata is asked in for the interface language [tag]: its language, Traditional Chinese as `zh-TW`. */
internal fun plexLanguageCode(tag: String): String {
    val shown = Locales.resolve(tag)
    return if (shown == "zh-Hant") "zh-TW" else shown.substringBefore('-')
}

/** plex.tv's sign-in and account service, as this [device] with [clientIdentifier]. */
internal fun AppGraph.plexAuthService(device: DeviceIdentity, clientIdentifier: String): PlexAuthService = PlexAuthService(
    http = http,
    clientIdentifier = clientIdentifier,
    appVersion = appVersion,
    platformVersion = device.platformVersion,
    platform = device.platform,
    deviceName = device.plexDeviceName,
)

/** plex.tv's `/user` for a token, asked as this [device] with the given client identifier. */
internal fun AppGraph.plexUserLookup(device: DeviceIdentity): PlexUserLookup =
    { token, clientIdentifier -> plexAuthService(device, clientIdentifier).getUserInfo(token) }

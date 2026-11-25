package com.edde746.plezy.app

import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.crash.Breadcrumb
import com.edde746.plezy.crash.CrashCapture
import com.edde746.plezy.crash.MemoryPressure
import com.edde746.plezy.crash.RuntimeUiState
import com.edde746.plezy.crash.StartupMarks
import com.edde746.plezy.data.settings.DeviceSettings
import com.edde746.plezy.downloads.DownloadedVideo
import com.edde746.plezy.downloads.DownloadedVideoSource
import com.edde746.plezy.input.VideoClickAction
import com.edde746.plezy.livetv.playback.LivePlayerSession
import com.edde746.plezy.livetv.scopeKey
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.music.CarUxRestrictionState
import com.edde746.plezy.music.CarUxRestrictions
import com.edde746.plezy.music.automotivePlaybackAllowed
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.playback.AmbientLightingController
import com.edde746.plezy.playback.PlaybackOptions
import com.edde746.plezy.playback.PlayerEngine
import com.edde746.plezy.playback.SubtitleStyle
import com.edde746.plezy.playback.output.PlaybackOutput
import com.edde746.plezy.playback.players.ExternalLaunchOutcome
import com.edde746.plezy.playback.players.ExternalPlayerService
import com.edde746.plezy.playback.queue.EpisodeQueue
import com.edde746.plezy.playback.queue.SleepTimer
import com.edde746.plezy.playback.report.OfflineProgressQueue
import com.edde746.plezy.playback.session.PlayRequest
import com.edde746.plezy.playback.session.PlaybackEnvironment
import com.edde746.plezy.playback.session.PlaybackSession
import com.edde746.plezy.playback.session.PlayerSession
import com.edde746.plezy.playback.session.SidecarFetcher
import com.edde746.plezy.playback.session.UrlPlaybackSession
import com.edde746.plezy.playback.session.VideoSessions
import com.edde746.plezy.playback.source.PlaybackSourceResolver
import com.edde746.plezy.playback.source.playbackServers
import com.edde746.plezy.playback.source.PlaybackServers
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.servers.LocalPlaybackHistory
import com.edde746.plezy.servers.LocalPlaybackHistoryStore
import com.edde746.plezy.servers.OnlineServers
import com.edde746.plezy.servers.PlaybackStateStore
import com.edde746.plezy.servers.WatchStateNotifier
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.emptyFlow
import com.edde746.plezy.presentation.navigation.PlezyNavigator
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.player.DeviceLevels
import com.edde746.plezy.presentation.player.DiscordPresence
import com.edde746.plezy.presentation.player.KeepAwakeController
import com.edde746.plezy.presentation.player.MediaControls
import com.edde746.plezy.presentation.player.PlayerConfig
import com.edde746.plezy.presentation.player.BackgroundPolicy
import com.edde746.plezy.presentation.player.PlayerHost
import com.edde746.plezy.presentation.player.PlayerLifecycle
import com.edde746.plezy.presentation.player.PlayerStore
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.AccountPreferencesController
import com.edde746.plezy.settings.PreferencesAccount
import com.edde746.plezy.presentation.settings.JellyfinAccountPreferencesSource
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.jellyfin.JellyfinClient
import com.edde746.plezy.model.AccountPreferenceKey
import com.edde746.plezy.model.AccountRef
import com.edde746.plezy.playback.tracks.TrackType
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.time.Duration.Companion.seconds

/**
 * One playback: the OS side ([platform], with its [engine]), the shared [session] over the engine, the player screen's
 * [store] over the session, and where the platform has them the OS media [controls], Discord's Rich Presence
 * ([discord]) and the display output following it. [config] is the store's keymap profile and timings; [request] what
 * was played.
 */
class ActivePlayback internal constructor(
    val request: PlayRequest,
    val platform: PlatformPlayback,
    val session: PlayerSession,
    val store: PlayerStore,
    val config: PlayerConfig,
    internal val controls: MediaControls?,
    internal val discord: DiscordPresence?,
    internal val output: PlaybackOutput?,
    internal val lifecycle: PlayerLifecycle,
    internal val scope: CoroutineScope,
) {
    val engine: PlayerEngine get() = platform.engine
}

/**
 * Starts and ends the playbacks of one [AppSession]. [play] opens the player ([Route.Player]) over a new
 * [PlatformPlayback] as this device's settings pick it; leaving the player (its route popped by Back or Close, or
 * replaced) ends the playback, which saves the progress and releases the engine. One playback at a time: a play ends
 * the one before it, and a play of what is already playing or opening (the same item, version, source, quality and
 * offline choice, or the same URL) only shows the player. Main thread only.
 *
 * A server's item plays in a [PlaybackSession] over [servers], from its downloaded copy in [downloads] where the
 * source rules pick it; a URL in a [UrlPlaybackSession].
 *
 * In a car (Android Automotive) video follows the vehicle's driving restrictions ([car]): a play waits for the vehicle's
 * verdict before it opens, nothing plays while the car forbids it, and a restriction that comes while the video plays
 * pauses it ([PlayerStore.onPlaybackAllowedChanged]). The required profile picker shown over the player holds it the
 * same way ([holdForProfilePick]).
 *
 * @param scope the app's: each playback runs in a child of it, cancelled as the playback ends.
 * @param notify shows a message over the app ([AppSession.notify]): why a playback that left the player stopped.
 * @param car the vehicle's restrictions, shared with the music session (one observer of the car service).
 * @param accountPreferences the active profile's account preferences: track defaults, and Jellyfin's memory of picks.
 */
internal class PlaybackController(
    private val graph: AppGraph,
    private val servers: AppServers,
    private val downloads: DownloadedVideoSource,
    private val downloadedEpisodes: suspend (showGlobalKey: String) -> List<MediaItem>,
    private val platform: AppPlatform,
    private val navigator: PlezyNavigator,
    private val scope: CoroutineScope,
    private val notify: (String) -> Unit,
    private val externalPlayers: ExternalPlayerService? = null,
    private val car: () -> CarUxRestrictions? = { null },
    private val accountPreferences: AccountPreferencesController,
) {
    private val mutableActive = MutableStateFlow<ActivePlayback?>(null)

    /** The playback the player shows, or null. */
    val active: StateFlow<ActivePlayback?> = mutableActive.asStateFlow()

    private val mutablePlayingKey = MutableStateFlow<String?>(null)

    /** The global key (`serverId:itemId`) of the server item playing; null for none or a URL's video. */
    val playingKey: StateFlow<String?> = mutablePlayingKey.asStateFlow()

    /** A play waiting for the device settings it opens with. */
    private var opening: Job? = null
    private var openingIdentity: Any? = null
    private var closed = false

    /** The one video at a time, and the last reports of each that ended. */
    private val videoSessions = VideoSessions()

    /**
     * What every server item's playback shares. Its last reports finish in the graph's scope: after the player closed,
     * and after the app session closed with a playback open.
     */
    private val environment by lazy {
        val playbackServers = servers.manager.playbackServers()
        PlaybackEnvironment(
            servers = playbackServers,
            serverStatus = servers.manager.statusUpdates,
            resolver = PlaybackSourceResolver(playbackServers, downloads, servers.cachedPlaybackMetadata),
            queue = EpisodeQueue(servers.playbackState, servers.manager),
            playbackState = servers.playbackState,
            settings = graph.data.deviceSettings,
            notifier = servers.watchStates,
            offlineQueue = OfflineProgressQueue { serverId, itemId, viewOffsetMs, durationMs ->
                servers.offlineWatchSync.queueProgressUpdate(serverId, itemId, viewOffsetMs, durationMs)
            },
            history = servers.playbackHistory,
            trackers = graph.trackers.playback { servers.profiles.active.value?.id },
            trackerMarks = graph.trackers.watchMarks { servers.profiles.active.value?.id },
            videoSessions = videoSessions,
            sleepTimer = SleepTimer(scope),
            reportScope = graph.scope,
            sidecars = SidecarFetcher(graph.http),
            clock = graph.clock,
            profile = { accountPreferences.activePreferences.value },
            awaitProfile = { accountPreferences.awaitActive() },
            trackSelectionMemory = ::rememberSelections,
            meteredNetwork = { graph.network.value.metered },
            playbackAllowed = ::playbackAllowed,
            downloadedEpisodes = downloadedEpisodes,
            requests = graph.requestDispatcher,
        )
    }

    /**
     * Lets a watch-together room go of a playback's player before the player is disposed of ([replaced] by another
     * one or not): the job completes once the room no longer commands it; null when the room never had it.
     */
    var roomRelease: ((playback: ActivePlayback, replaced: Boolean) -> Job?)? = null

    /** Turns on the memory of [type] picks of the Jellyfin account [backend] plays as; false for any other server. */
    private suspend fun rememberSelections(backend: MediaBackend, type: TrackType): Boolean {
        val client = backend as? JellyfinClient ?: return false
        val account = PreferencesAccount(AccountRef.mediaBrowser(client.connection.kind, client.connection.id), JellyfinAccountPreferencesSource(client))
        val key = when (type) {
            TrackType.AUDIO -> AccountPreferenceKey.REMEMBER_AUDIO_SELECTIONS
            TrackType.SUBTITLE -> AccountPreferenceKey.REMEMBER_SUBTITLE_SELECTIONS
        }
        return accountPreferences.ensureRemembersTrackSelections(account, key)
    }

    private val automotive = platform.musicSystem.car != null

    private val mutableHeldForProfile = MutableStateFlow(false)

    /** The required profile picker covers the player ([holdForProfilePick]): nothing plays meanwhile. */
    val heldForProfile: StateFlow<Boolean> = mutableHeldForProfile.asStateFlow()
    private var profileHolds = 0

    /**
     * Runs [pick] (the required profile picker, shown over the player) with the video held: a video that plays pauses,
     * and nothing starts one until [pick] returns ([playbackAllowed]); the same profile chosen, it stays paused for the
     * viewer to resume. Whoever woke the device chooses a profile, and passes its PIN, before the last one's video
     * plays again.
     */
    suspend fun <T> holdForProfilePick(pick: suspend () -> T): T {
        setProfileHolds(profileHolds + 1)
        try {
            return pick()
        } finally {
            setProfileHolds(profileHolds - 1)
        }
    }

    private fun setProfileHolds(holds: Int) {
        profileHolds = holds
        if (mutableHeldForProfile.value == holds > 0) return
        mutableHeldForProfile.value = holds > 0
        val active = mutableActive.value ?: return
        lifecycle(if (holds > 0) "Held for the profile picker" else "Released by the profile picker")
        active.store.onPlaybackAllowedChanged()
    }

    /**
     * Video may play now: the car allows it (or this isn't a car), the profile picker doesn't cover the player
     * ([holdForProfilePick]), and a TV in the background isn't holding the video ([PlayerLifecycle.holdsPlayback]).
     */
    private fun playbackAllowed(): Boolean =
        vehicleAllows() && !mutableHeldForProfile.value && mutableActive.value?.lifecycle?.holdsPlayback != true

    /**
     * The video plays on in picture in picture as the app leaves now: its window is up, or opens as the app leaves while
     * it plays (auto picture in picture opens for a playing video only).
     */
    val continuesInPictureInPicture: Boolean
        get() {
            val active = mutableActive.value ?: return false
            val state = active.session.engineState.value
            return active.store.inPictureInPicture.value ||
                active.platform.pictureInPictureStarting && state.loaded && !state.paused && !state.eof
        }

    private fun vehicleAllows(): Boolean =
        automotivePlaybackAllowed(automotive, graph.foreground.value, car()?.state?.value ?: CarUxRestrictionState.UNKNOWN)

    init {
        navigator.addRemovalListener { if (it == Route.Player) stop() }
    }

    /**
     * What the player store asks of the app: closing the player, fullscreen, always on top, the brightness and the
     * system's volume.
     */
    private val host = object : PlayerHost {
        override fun close() = closePlayer()

        override fun setFullscreen(fullscreen: Boolean) = platform.setFullscreen(fullscreen)

        override val keepsOnTop: Boolean get() = platform.keepsOnTop

        override fun setAlwaysOnTop(onTop: Boolean) = platform.setAlwaysOnTop(onTop)

        override val levels: DeviceLevels? get() = platform.deviceLevels

        override val playbackAllowed: Boolean get() = this@PlaybackController.playbackAllowed()
    }

    /**
     * Plays [request] in the player, once this device's settings are read (they pick the engine). Nothing happens once
     * the app is closed.
     *
     * [access] is a server this device isn't signed into, handed over by a cast for a [PlayRequest.Item] of it: the
     * playback resolves, queues and reports on it alone ([handedOverEnvironment]), and nothing of it outlives the
     * playback. Such a play always opens anew.
     */
    fun play(request: PlayRequest, access: MediaBackend? = null) {
        if (closed) return
        val identity = playIdentity(request, access)
        if (identity == openingIdentity || access == null && identity == mutableActive.value?.let(::activeIdentity)) {
            Log.i(TAG) { "Already playing ${request.globalKey ?: "this URL"}: showing the player" }
            if (mutableActive.value != null) navigator.navigate(Route.Player)
            return
        }
        opening?.cancel()
        openingIdentity = identity
        opening = scope.launch {
            val settings = graph.data.deviceSettings.settings()
            val playbackScope = scope.childScope()
            try {
                // A server item's source resolves first, while the rest gets ready around it.
                val environment = if (access != null) handedOverEnvironment(access) else environment
                val launch = (request as? PlayRequest.Item)?.let { PlaybackSession.prepare(it, environment, playbackScope) }
                // A car mustn't start video before the vehicle said whether it may (bounded by the car service's wait).
                if (automotive) car()?.ensureResolved()
                val handedOff = request is PlayRequest.Url && handOff(request)
                if (closed || handedOff) return@launch playbackScope.cancel()
                // The one before goes first, once its room let go of it: two engines never play at once. The fullscreen
                // it entered stays on, and stays the player's.
                val ownsFullscreen = mutableActive.value?.store?.ownsFullscreen == true
                stopPlayback(replaced = true)?.join()
                // One native player at a time: the music session's core is gone before the video's is built.
                graph.playbackCoordinator.claimVideo()
                opening = null
                openingIdentity = null
                // A stop (leaving, a profile switch) while it waited cancelled this launch: it opens nothing.
                if (closed) return@launch playbackScope.cancel()
                ensureActive()
                open(request, environment, settings, playbackScope, launch, ownsFullscreen)
            } catch (e: CancellationException) {
                playbackScope.cancel()
                throw e
            } finally {
                if (opening === coroutineContext[Job]) {
                    opening = null
                    openingIdentity = null
                }
            }
        }
    }

    /** Cancels [play] of [request] with [access] while it still waits to open: it then opens nothing. */
    fun cancelOpening(request: PlayRequest, access: MediaBackend?) {
        if (playIdentity(request, access) != openingIdentity) return
        opening?.cancel()
        opening = null
        openingIdentity = null
    }

    /**
     * Hands a URL's video to the external player while `use_external_player` is on ([ExternalPlayerService.launch]);
     * false when it didn't start, and the video plays here. A start the link carries as video links do (`t=<seconds>`
     * in its fragment or its query) is the resume point the player starts at.
     */
    private suspend fun handOff(request: PlayRequest.Url): Boolean {
        val players = externalPlayers ?: return false
        if (!graph.data.deviceSettings.value(AppSettings.useExternalPlayer)) return false
        val url = request.url.substringBefore('#')
        val startSeconds = request.url.split('#', '?', '&').drop(1).firstNotNullOfOrNull { if (it.startsWith("t=")) it.drop(2).toDoubleOrNull() else null }
        val name = url.substringBefore('?').substringAfterLast('/')
        val item = MediaItem(
            id = "url", backend = BackendKind.PLEX, kind = MediaKind.CLIP, title = name,
            viewOffsetMs = startSeconds?.let { (it * 1000).toLong() },
        )
        return when (val outcome = players.launch(item, backend = null, videoUrl = url)) {
            ExternalLaunchOutcome.Launched -> true
            is ExternalLaunchOutcome.NotLaunched -> {
                Log.w(TAG) { "The external player didn't start (${outcome.message}): playing here" }
                false
            }
        }
    }

    /** [ownsFullscreen]: the fullscreen on now is the replaced player's, which this one takes over. */
    private fun open(
        request: PlayRequest,
        environment: PlaybackEnvironment,
        settings: DeviceSettings,
        playbackScope: CoroutineScope,
        launch: PlaybackSession.Launch?,
        ownsFullscreen: Boolean,
    ) {
        val playback = platform.createPlayback(settings)
        val session = session(request, environment, playback, playbackScope, ::closePlayer)
        val passthrough = platform.deviceFeatures().audioPassthrough
        val config = graph.playerConfig(platform.playerConfig).copy(
            audioPassthrough = passthrough,
            audioPassthroughOn = passthrough && settings.audioPassthroughOn(platform.formFactor),
        )
        val ambientLighting = platform.shaderFiles?.takeIf { playback.runsAmbientLighting }?.let { files ->
            AmbientLightingController(playback.engine, files, graph.playerPreferences::setAmbientLighting, playbackScope)
        }
        // A server item's store commands the session's engine: its seeks are in the item's time (a stacked item's other
        // part opens), and a pause or play while a file reopens (the next episode) is how the new file opens.
        val store = PlayerStore(
            (session as? PlaybackSession)?.engine ?: playback.engine, session, host, graph.playerPreferences, config, playbackScope,
            shaderFiles = platform.shaderFiles, importsShaders = platform.hasFileDialogs, ambientLighting = ambientLighting,
            fullscreen = platform.isFullscreen, ownsFullscreen = ownsFullscreen && platform.isFullscreen,
        )
        val controls = playback.mediaControls?.let { MediaControls(store, session, it, playbackScope) }
        val discord = platform.discordPresence?.let {
            DiscordPresence(
                store, session, graph.data.deviceSettings.observe(AppSettings.enableDiscordRpc),
                it, playbackScope, graph.clock,
                poster = { item -> ServerId.tryParse(item.serverId)?.let(servers.manager::client)?.let { b -> graph.discordPosters.posterFor(item, b) } },
            )
        }
        val output = playback.output?.let {
            PlaybackOutput(
                session.engineState, store.state.map { s -> s.fullscreen }, platform.formFactor,
                graph.data.deviceSettings.observe(), it, playbackScope,
            ).also { output -> store.followOutput(output.negotiating, output::setHdr, output::setDolbyVisionConversion) }
        }
        playback.attach(store)
        if (session is PlaybackSession && output != null) session.beforeOpen = output::preOpen
        if (session is PlaybackSession && launch != null) session.start(launch)
        KeepAwakeController(playbackScope) { playback.keepDisplayAwake(it) }.follow(store.state)
        val background = PlayerLifecycle(
            store, session, controls, output,
            BackgroundPolicy.of(platform.formFactor, platform.appleTv, automotive),
            skipsForPictureInPicture = { store.inPictureInPicture.value || playback.pictureInPictureStarting },
            foreground = graph.foreground,
            scope = playbackScope,
        )
        val active = ActivePlayback(request, playback, session, store, config, controls, discord, output, background, playbackScope)
        mutableActive.value = active
        car()?.takeIf { automotive }?.let { vehicle ->
            playbackScope.launch {
                vehicle.state.map { vehicleAllows() }.distinctUntilChanged().drop(1).collect { store.onPlaybackAllowedChanged() }
            }
        }
        // Something but the viewer started the video (audio focus back) while the car or a TV in the background
        // forbids it: it pauses again at once.
        playbackScope.launch {
            session.engineState.map { it.loaded && !it.paused && !it.eof }.distinctUntilChanged().collect { playing ->
                if (!playing || playbackAllowed()) return@collect
                lifecycle("Playback started while not allowed: paused")
                playback.engine.setPaused(true)
            }
        }
        lifecycle("Player opened", "engine" to playback.engine::class.simpleName.orEmpty(), "url" to (request is PlayRequest.Url))
        playbackScope.launch {
            session.engineState.first { it.video != null }
            lifecycle("First frame")
        }
        StartupMarks.uiState(RuntimeUiState.PLAYER)
        // What a memory warning reports of the playback.
        MemoryPressure.playback = {
            val state = session.engineState.value
            val positionMs = (state.positionSeconds * 1000).toLong()
            MemoryPressure.playbackData(true, !state.paused, positionMs, state.cacheEndSeconds?.let { (it * 1000).toLong() } ?: positionMs)
        }
        mutablePlayingKey.value = request.globalKey
        // A server item's key follows the session: the next episode, a queue's entry played in place.
        if (session is PlaybackSession) {
            playbackScope.launch { session.playingKey.drop(1).collect { if (mutableActive.value?.session === session) mutablePlayingKey.value = it } }
        }
        navigator.navigate(Route.Player)
    }

    /**
     * The session of [request] over [playback]'s engine, running in [scope], a server item's in [environment]; [close]
     * leaves the player (a session that can't go on: a live start that failed, a playback stopped in the background).
     */
    private fun session(request: PlayRequest, environment: PlaybackEnvironment, playback: PlatformPlayback, scope: CoroutineScope, close: () -> Unit): PlayerSession =
        when (request) {
            is PlayRequest.Url -> UrlPlaybackSession(
                playback.engine,
                request.url,
                { PlaybackOptions.of(graph.data.deviceSettings.settings(), playback.hardwareDecoder) },
                graph.data.deviceSettings.observe().map { SubtitleStyle.of(it.subtitles) }.distinctUntilChanged(),
                scope,
                playbackAllowed = ::playbackAllowed,
            )
            is PlayRequest.Item -> PlaybackSession(playback.engine, playback.hardwareDecoder, environment, scope, close)
            is PlayRequest.Live -> LivePlayerSession(
                engine = playback.engine,
                launch = request.launch,
                servers = { request.servers.entries },
                client = request.servers::client,
                playbackOptions = { PlaybackOptions.of(graph.data.deviceSettings.settings(), playback.hardwareDecoder) },
                quality = ::defaultQuality,
                subtitleStyle = graph.data.deviceSettings.observe().map { SubtitleStyle.of(it.subtitles) }.distinctUntilChanged(),
                videoClick = graph.data.deviceSettings.observe(AppSettings.clickVideoTogglesPlayback).map(VideoClickAction::of),
                foreground = graph.foreground,
                tv = platform.formFactor == FormFactor.TV,
                leave = { notice ->
                    notice?.let(notify)
                    close()
                },
                playbackAllowed = ::playbackAllowed,
                parentScope = scope,
                backgroundScope = this.scope,
                clock = graph.clock,
            )
        }

    /**
     * Where a handed-over server's item plays ([play]'s access): that server alone, always online and visible; its own
     * queue state; its reports to that server only, with no trackers, no offline queue, no watch-state events for this
     * device's screens and a history of its own; the tracks its user's account preferences pick; nothing stored on this
     * device.
     */
    private suspend fun handedOverEnvironment(server: MediaBackend): PlaybackEnvironment {
        // The handed-over user's track defaults (language, subtitle mode), as a play on their own device applies them;
        // in memory for this playback only. Plex folds them into the stream its server marks selected already.
        val preferences = (server as? JellyfinClient)?.let { client ->
            try {
                withTimeoutOrNull(AccountPreferencesController.ACTIVE_WAIT) { client.fetchAccountPreferences() }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "The handed-over account's preferences didn't load: the file's defaults apply" }
                null
            }
        }
        val only = object : PlaybackServers, OnlineServers {
            override fun client(serverId: ServerId): MediaBackend? = server.takeIf { it.serverId == serverId }

            override fun isServerVisible(serverId: ServerId): Boolean = true

            override val refusedServerIds: Set<ServerId> get() = emptySet()

            override fun isClientOnline(serverId: ServerId): Boolean = serverId == server.serverId

            override val visibleOnlineClients: Map<ServerId, MediaBackend> get() = mapOf(server.serverId to server)

            override val onlineClients: Map<ServerId, MediaBackend> get() = visibleOnlineClients

            override val changes: Flow<Unit> get() = emptyFlow()
        }
        val playbackState = PlaybackStateStore()
        val history = object : LocalPlaybackHistoryStore {
            private var entries = emptyMap<String, Long>()

            override suspend fun read(): Map<String, Long> = entries

            override suspend fun write(history: Map<String, Long>) {
                entries = history
            }
        }
        return PlaybackEnvironment(
            servers = only,
            serverStatus = emptyFlow(),
            resolver = PlaybackSourceResolver(only, NoDownloadedVideos, servers.cachedPlaybackMetadata),
            queue = EpisodeQueue(playbackState, only),
            playbackState = playbackState,
            settings = graph.data.deviceSettings,
            notifier = WatchStateNotifier(),
            offlineQueue = null,
            history = LocalPlaybackHistory(history, graph.clock),
            trackers = null,
            trackerMarks = null,
            videoSessions = videoSessions,
            sleepTimer = SleepTimer(scope),
            reportScope = graph.scope,
            sidecars = SidecarFetcher(graph.http),
            clock = graph.clock,
            meteredNetwork = { graph.network.value.metered },
            profile = { preferences },
            playbackAllowed = ::playbackAllowed,
            requests = graph.requestDispatcher,
        )
    }

    /**
     * The quality playback starts at, a live tune's cap too: the cellular preset on a metered network when one is set,
     * else the default.
     */
    internal suspend fun defaultQuality(): TranscodeQualityPreset {
        val settings = graph.data.deviceSettings
        val cellular = if (graph.network.value.metered) settings.value(AppSettings.cellularQualityPreset) else null
        return cellular ?: settings.value(AppSettings.defaultQualityPreset)
    }

    /** Leaves the player: pops it. A late Back while it goes does nothing. */
    private fun closePlayer() {
        navigator.pop(Route.Player)
    }

    /**
     * Ends the current playback, if any, and cancels a play still opening, which then opens nothing: leaves
     * fullscreen when Exit fullscreen on player close is on (a playback replaced at once keeps it), takes down the
     * media controls, Discord's activity and the display output, lets the display sleep, lets a watch-together room go
     * of the player ([roomRelease], waiting up to [ROOM_RELEASE_TIMEOUT] for it), then releases the platform's side,
     * stops the store, closes the session (which saves the progress and releases the engine), and last stops what the
     * playback ran. The player closing with it gives the screen its own brightness back; a playback replaced at once
     * keeps the one the viewer swiped to.
     */
    fun stop() {
        opening?.cancel()
        opening = null
        openingIdentity = null
        stopPlayback(replaced = false)
    }

    /** The job that disposes of the playback once its room let go of it; null when it is disposed of already. */
    private fun stopPlayback(replaced: Boolean): Job? {
        val playback = mutableActive.value ?: return null
        mutableActive.value = null
        mutablePlayingKey.value = null
        MemoryPressure.playback = null
        StartupMarks.uiState(RuntimeUiState.MAIN_SCREEN)
        lifecycle("Player disposed", "replaced" to replaced)
        if (!replaced && platform.isFullscreen) {
            // Closing the player leaves fullscreen only with Exit fullscreen on player close (off by default).
            scope.launch {
                if (graph.data.deviceSettings.value(AppSettings.exitFullscreenOnPlayerClose)) platform.setFullscreen(false)
            }
        }
        if (!replaced) platform.deviceLevels?.restoreBrightness()
        val roomReleased = roomRelease?.invoke(playback, replaced)
        playback.controls?.release()
        playback.discord?.release()
        playback.output?.release()
        playback.platform.keepDisplayAwake(false)
        if (roomReleased == null || roomReleased.isCompleted) {
            dispose(playback)
            return null
        }
        return scope.launch {
            if (withTimeoutOrNull(ROOM_RELEASE_TIMEOUT) { roomReleased.join() } == null) Log.w(TAG) { "The room didn't let go of the player in time" }
            dispose(playback)
        }
    }

    private fun dispose(playback: ActivePlayback) {
        playback.platform.release()
        playback.store.release()
        playback.session.close()
        playback.scope.cancel()
    }

    /**
     * Stops the playback (as [stop], once its room let go of it) and waits for its native stop and last reports, and
     * any earlier playback's.
     */
    suspend fun shutdownVideo() {
        stopPlayback(replaced = false)?.join()
        videoSessions.shutdownVideo()
    }

    /** Ends the playback for good, and any play still opening: the app is closing. */
    fun close() {
        closed = true
        stop()
    }

    /** What makes two [play]s the same: a handed-over server's [access] opens anew each time. */
    private fun playIdentity(request: PlayRequest, access: MediaBackend?): Any = if (access != null) identity(request) to access else identity(request)

    /** What makes two plays the same launch (the item, version, source, quality and offline choice; a URL). */
    private fun identity(request: PlayRequest): Any = when (request) {
        is PlayRequest.Item -> ItemIdentity(request.globalKey, request.mediaIndex, request.mediaSourceId, request.qualityPreset, request.offline)
        is PlayRequest.Url -> request.url
        is PlayRequest.Live -> request.launch.channel.scopeKey
    }

    /** The launch [active] plays now: its request, moved on by the in-place reloads that opened ([PlaybackSession.launched]). */
    private fun activeIdentity(active: ActivePlayback): Any = identity((active.session as? PlaybackSession)?.launched ?: active.request)

    /** A `player.lifecycle` breadcrumb: what the crash report's trail says the player did. */
    private fun lifecycle(message: String, vararg data: Pair<String, Any>) {
        CrashCapture.breadcrumb(Breadcrumb("player.lifecycle", message, mapOf(*data)))
    }

    private data class ItemIdentity(
        val key: String,
        val mediaIndex: Int,
        val mediaSourceId: String?,
        val qualityPreset: TranscodeQualityPreset?,
        val offline: Boolean,
    )
}

/** A device without downloads (Apple TV), and the music session: every item streams from its server. */
internal object NoDownloadedVideos : DownloadedVideoSource {
    override suspend fun resolve(
        serverId: ServerId,
        itemId: String,
        mediaIndex: Int?,
        mediaSourceId: String?,
        allowAnyVersion: Boolean,
        partIndex: Int,
    ): DownloadedVideo? = null

    override suspend fun sidecarSubtitles(video: DownloadedVideo, metadata: MediaItem?): List<String> = emptyList()

    override suspend fun artworkUrl(serverId: ServerId, path: String): String? = null
}

private const val TAG = "playback"

/** The longest a player's disposal waits for its watch-together room to let go of it. */
private val ROOM_RELEASE_TIMEOUT = 2.seconds

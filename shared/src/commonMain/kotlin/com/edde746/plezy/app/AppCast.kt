package com.edde746.plezy.app

import com.edde746.plezy.backend.HealthStatus
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.cast.CastCommand
import com.edde746.plezy.cast.CastFailure
import com.edde746.plezy.cast.CastItem
import com.edde746.plezy.cast.CastLoadException
import com.edde746.plezy.cast.CastPeerInfo
import com.edde746.plezy.cast.CastPeers
import com.edde746.plezy.cast.CastPlayback
import com.edde746.plezy.cast.CastReceiver
import com.edde746.plezy.cast.CastSender
import com.edde746.plezy.cast.CastServer
import com.edde746.plezy.cast.CastSource
import com.edde746.plezy.cast.CastState
import com.edde746.plezy.cast.ServerAccess
import com.edde746.plezy.cast.connectCast
import com.edde746.plezy.cast.ServerLimits
import com.edde746.plezy.cast.CastDiscovery
import com.edde746.plezy.secrets.MemorySecretStore
import com.edde746.plezy.servers.childScope
import kotlinx.coroutines.flow.flowOf
import com.edde746.plezy.image.ImageKind
import com.edde746.plezy.image.PixelSize
import com.edde746.plezy.image.sizedImageUrl
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.jellyfin.JellyfinClient
import com.edde746.plezy.jellyfin.JellyfinConnection
import com.edde746.plezy.livetv.LiveTvStartPosition
import com.edde746.plezy.livetv.liveTvLaunch
import com.edde746.plezy.livetv.LiveTvLaunchResult
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.music.MusicPlayContext
import com.edde746.plezy.music.MusicPlaybackService
import com.edde746.plezy.music.MusicPlaybackStatus
import com.edde746.plezy.playback.session.PlayRequest
import com.edde746.plezy.playback.session.PlaybackSession
import com.edde746.plezy.playback.TrackKind
import com.edde746.plezy.plex.PlexClient
import com.edde746.plezy.plex.PlexConnection
import com.edde746.plezy.plex.PlexServer
import com.edde746.plezy.plex.isLocalOrPrivateHost
import com.edde746.plezy.presentation.cast.CastDeviceKind
import com.edde746.plezy.presentation.cast.CastMediaKind
import com.edde746.plezy.presentation.cast.CastOption
import com.edde746.plezy.presentation.livetv.LiveTvServers
import com.edde746.plezy.presentation.navigation.PlezyNavigator
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.player.PlaybackMode
import com.edde746.plezy.presentation.player.PlaybackStatus
import com.edde746.plezy.presentation.player.PlayerStore
import com.edde746.plezy.presentation.player.PlayerUiState
import com.edde746.plezy.presentation.player.TimelineState
import com.edde746.plezy.servers.LiveTvServerEntry
import com.edde746.plezy.servers.PlexProfileScopeId
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.strings.T
import io.ktor.http.Url
import io.ktor.network.selector.SelectorManager
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.cancel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

/**
 * Casting in one app session: this device's [sender] over its own servers and players, and its [receiver], which plays
 * what senders hand over through the same player ([PlaybackController], the music session) with the handed-over server
 * kept in memory only. [setMusicServer] tells the music session which server a music cast plays from.
 */
internal class AppCast(
    private val graph: AppGraph,
    private val platform: AppPlatform,
    private val servers: AppServers,
    private val playbacks: PlaybackController,
    private val music: MusicPlaybackService,
    private val navigator: PlezyNavigator,
    allowed: Flow<Boolean>,
    private val setMusicServer: (MediaBackend?) -> Unit,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()

    /** The sockets' selector. While a socket waits on it its loop blocks a thread in select, so it runs on IO. */
    private val selector = SelectorManager(Dispatchers.IO)

    private var device: CastPeerInfo? = null

    private val playback = Playback()

    val sender = CastSender(
        parentScope = scope,
        me = ::me,
        receivers = CastPeers(graph.secrets, CastPeers.RECEIVERS),
        discovery = platform.castDiscovery,
        connect = { host, port -> connectCast(selector, scope, host, port) },
        source = Source(),
    )

    /** The senders this device lets cast without asking: Settings lists them. */
    val senders = CastPeers(graph.secrets, CastPeers.SENDERS)

    val receiver = CastReceiver(
        parentScope = scope,
        me = ::me,
        senders = senders,
        allowed = allowed,
        playback = playback,
        access = ::connect,
        endpoint = CastServer(selector, scope),
        discovery = platform.castDiscovery,
    )

    init {
        // The selector closes as the scope ends, so its loop never outlives the session.
        scope.launch(start = CoroutineStart.UNDISPATCHED) {
            try {
                awaitCancellation()
            } finally {
                selector.close()
            }
        }
        scope.launch { senders.load() }
        music.castsTo = { tracks, start, context, shuffle -> !playback.loading && castMusic(tracks, start, context, shuffle) }
    }

    /** Sends [request] to the cast target instead of playing it here; false when no target takes it. */
    fun takes(request: PlayRequest): Boolean {
        if (!sender.casting || playback.loading) return false
        return when (request) {
            is PlayRequest.Item -> !request.offline && sender.cast(
                request.serverId.value,
                CastItem.Video(request.itemId, request.startPosition?.inWholeMilliseconds, request.mediaIndex, request.mediaSourceId, request.strictMediaSelection),
            )
            is PlayRequest.Live -> sender.cast(request.launch.serverId.value, liveItem(request))
            is PlayRequest.Url -> false
        }
    }

    private fun castMusic(tracks: List<MediaItem>, start: Int, context: MusicPlayContext, shuffle: Boolean): Boolean {
        if (!sender.casting) return false
        val serverId = tracks.first().serverId ?: return false
        if (tracks.any { it.serverId != serverId }) return false
        return sender.cast(serverId, CastItem.Music(tracks.map { it.id }, start, context.title, context.kind, shuffle))
    }

    private fun liveItem(request: PlayRequest.Live): CastItem.Live {
        val launch = request.launch
        val lineup = request.servers.entries.firstOrNull { it.serverId == launch.serverId && it.dvrKey == launch.dvrKey }?.lineup
        return CastItem.Live(launch.dvrKey, launch.channel.key, lineup)
    }

    private suspend fun me(): CastPeerInfo = device ?: CastPeerInfo(
        id = CastPeers.installId(graph.secrets),
        name = platform.device.deviceName?.takeIf { it.isNotBlank() } ?: T.cast.unknownDevice,
        platform = platform.device.platform,
        kind = when (platform.formFactor) {
            FormFactor.TV -> CastDeviceKind.TV
            FormFactor.DESKTOP -> CastDeviceKind.DESKTOP
            FormFactor.HANDHELD -> CastDeviceKind.HANDHELD
        },
    ).also { device = it }

    /**
     * A client of a handed-over server, outside the server registry and in memory only (nothing of the sender's server
     * is written here): Plex on its first endpoint to answer, Jellyfin and Emby as the user and device the token belongs
     * to.
     */
    private suspend fun connect(access: ServerAccess): MediaBackend {
        val server = try {
            when (access.kind) {
                BackendKind.PLEX -> servers.handedOverPlexClient(plexServer(access), me().id, PlexProfileScopeId.of(ServerId(access.serverId), CAST_SCOPE))
                BackendKind.JELLYFIN, BackendKind.EMBY -> servers.handedOverMediaBrowserClient(
                    JellyfinConnection(
                        id = "${access.serverId}/${access.userId}",
                        baseUrl = access.baseUrls.first(),
                        baseUrls = access.baseUrls,
                        serverName = access.name,
                        serverMachineId = access.serverId,
                        userId = checkNotNull(access.userId) { "no user" },
                        userName = access.userName.orEmpty(),
                        accessToken = access.token,
                        deviceId = access.deviceId.orEmpty(),
                        dialect = MediaBrowserDialect.entries.first { it.backend == access.kind },
                        createdAt = graph.clock.now().toEpochMilliseconds(),
                    ),
                )
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            throw CastLoadException(CastFailure.SERVER_UNREACHABLE, "Couldn't reach ${access.name}", e)
        }
        val health = server.checkHealth()
        if (health != HealthStatus.ONLINE) throw CastLoadException(CastFailure.SERVER_UNREACHABLE, "${access.name} is $health")
        return server
    }

    private fun plexServer(access: ServerAccess): PlexServer = PlexServer(
        name = access.name,
        clientIdentifier = access.serverId,
        accessToken = access.token,
        connections = access.baseUrls.map { url ->
            val parsed = Url(url)
            PlexConnection(
                protocol = parsed.protocol.name,
                address = parsed.host,
                port = parsed.port,
                uri = url.trimEnd('/'),
                local = isLocalOrPrivateHost(parsed.host),
                relay = false,
                ipv6 = ':' in parsed.host,
            )
        },
        owned = false,
    )

    /**
     * A receiver that isn't this device: [device] as it introduces itself, playing through [playback], listening on a
     * free port and announced through [discovery], remembering its senders in memory only.
     */
    fun peerReceiver(device: CastPeerInfo, playback: CastPlayback, discovery: CastDiscovery): CastReceiver = CastReceiver(
        parentScope = scope,
        me = { device },
        senders = CastPeers(MemorySecretStore(), CastPeers.SENDERS),
        allowed = flowOf(true),
        playback = playback,
        access = ::connect,
        endpoint = CastServer(selector, scope, ServerLimits(preferredPort = 0)),
        discovery = discovery,
    )

    /**
     * A sender that isn't this device: [device] as it introduces itself, finding receivers through [discovery] and
     * casting with this device's server access, remembering its receivers in memory only.
     */
    fun peerSender(device: CastPeerInfo, discovery: CastDiscovery): CastSender = CastSender(
        parentScope = scope,
        me = { device },
        receivers = CastPeers(MemorySecretStore(), CastPeers.RECEIVERS),
        discovery = discovery,
        connect = { host, port -> connectCast(selector, scope, host, port) },
        source = Source(),
    )

    fun close() = scope.cancel()

    /** The receiver's player side: the cast's video, Live TV or music, and what it plays. */
    private inner class Playback : CastPlayback {
        private val mutableState = MutableStateFlow<CastState?>(null)
        override val state: StateFlow<CastState?> = mutableState.asStateFlow()

        /** A load runs: plays it starts aren't sent on to this device's own target. */
        var loading = false
            private set

        private var video: ActivePlayback? = null
        private var musicRevision: Int? = null
        private var follow: Job? = null

        override suspend fun load(item: CastItem, server: MediaBackend, senderName: String) {
            follow?.cancel()
            video = null
            musicRevision = null
            mutableState.value = null
            loading = true
            try {
                when (item) {
                    is CastItem.Video -> {
                        setMusicServer(null)
                        val request = PlayRequest.Item(
                            server.serverId,
                            item.itemId,
                            mediaIndex = item.mediaIndex,
                            mediaSourceId = item.mediaSourceId,
                            strictMediaSelection = item.strict,
                            startPosition = item.startMs?.milliseconds,
                        )
                        playbacks.play(request, server)
                        followVideo(request, server, senderName)
                    }
                    is CastItem.Live -> {
                        setMusicServer(null)
                        val request = liveRequest(item, server)
                        playbacks.play(request)
                        followVideo(request, null, senderName)
                    }
                    is CastItem.Music -> playMusic(item, server, senderName)
                }
            } finally {
                loading = false
            }
        }

        private suspend fun liveRequest(item: CastItem.Live, server: MediaBackend): PlayRequest.Live {
            val entry = LiveTvServerEntry(server.serverId, item.dvrKey, item.lineup)
            val liveServers = object : LiveTvServers {
                override val entries: List<LiveTvServerEntry> = listOf(entry)

                override fun client(serverId: ServerId): MediaBackend? = server.takeIf { it.serverId == serverId }
            }
            val channels = try {
                server.liveTv.fetchChannels(item.lineup).map { it.copy(serverId = server.serverId.value, liveDvrKey = item.dvrKey) }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                throw CastLoadException(CastFailure.PLAYBACK_FAILED, "Couldn't list the channels", e)
            }
            val channel = channels.firstOrNull { it.key == item.channelKey }
                ?: throw CastLoadException(CastFailure.PLAYBACK_FAILED, "No channel ${item.channelKey}")
            return when (val launch = liveTvLaunch(liveServers.entries, liveServers::client, channel, channels, LiveTvStartPosition.LIVE)) {
                is LiveTvLaunchResult.Ready -> PlayRequest.Live(launch.launch, liveServers)
                is LiveTvLaunchResult.Failed -> throw CastLoadException(CastFailure.PLAYBACK_FAILED, launch.message)
            }
        }

        /**
         * Waits for [request]'s player (played with [access]) to open and start, then follows it until it's no longer the
         * player. A play that doesn't open in time opens nothing: the sender is told it failed.
         */
        private suspend fun followVideo(request: PlayRequest, access: MediaBackend?, senderName: String) {
            val active = withTimeoutOrNull(OPEN_TIMEOUT) { playbacks.active.first { it?.request === request } } ?: run {
                playbacks.cancelOpening(request, access)
                throw CastLoadException(CastFailure.PLAYBACK_FAILED, "The player didn't open")
            }
            val started = withTimeoutOrNull(START_TIMEOUT) {
                combine(playbacks.active, active.store.state) { now, ui -> if (now !== active) null else ui.status }
                    .first { it == null || it == PlaybackStatus.PLAYING || it == PlaybackStatus.PAUSED || it == PlaybackStatus.FAILED || it == PlaybackStatus.ENDED }
            }
            if (started != PlaybackStatus.PLAYING && started != PlaybackStatus.PAUSED) {
                if (playbacks.active.value === active) navigator.pop(Route.Player)
                throw CastLoadException(CastFailure.PLAYBACK_FAILED, "The video didn't start: $started")
            }
            video = active
            mutableState.value = videoState(active, active.store.state.value, active.store.timeline.value, senderName)
            follow = scope.launch {
                combine(playbacks.active, active.store.state, active.store.timeline) { now, ui, timeline ->
                    if (now !== active || ui.status == PlaybackStatus.ENDED) null else videoState(active, ui, timeline, senderName)
                }.collect { now ->
                    mutableState.value = now
                    if (now == null) {
                        video = null
                        follow?.cancel()
                    }
                }
            }
        }

        private fun videoState(active: ActivePlayback, ui: PlayerUiState, timeline: TimelineState, senderName: String): CastState {
            val item = (active.session as? PlaybackSession)?.opened?.value?.item ?: (active.request as? PlayRequest.Live)?.launch?.item
            val sourceAudio = ui.sourceAudioTracks.isNotEmpty()
            return CastState(
                kind = if (ui.mode == PlaybackMode.VIDEO) CastMediaKind.VIDEO else CastMediaKind.LIVE,
                title = ui.title,
                subtitle = ui.subtitle,
                serverId = item?.serverId,
                thumb = item?.thumbPath?.takeUnless { it.startsWith("http") },
                paused = ui.paused,
                buffering = ui.status.isLoading,
                positionMs = (timeline.positionSeconds * 1000).toLong(),
                durationMs = (timeline.durationSeconds * 1000).toLong(),
                canSeek = ui.canSeek,
                audio = (if (sourceAudio) ui.sourceAudioTracks else ui.audioTracks).map { track ->
                    CastOption("${if (sourceAudio) SOURCE else TRACK}${track.id}", track.label, track.detail, track.selected)
                },
                subtitles = ui.subtitleTracks.map { CastOption("$TRACK${it.id ?: OFF}", it.label, it.detail, it.selected) },
                qualities = ui.versions?.qualities.orEmpty().mapIndexed { index, choice -> CastOption("$index", choice.label, choice.detail, choice.selected) },
                hasPrevious = ui.episodes?.previous == true,
                hasNext = ui.episodes?.next == true,
                volume = ui.volume.percent,
                from = senderName,
            )
        }

        private suspend fun playMusic(item: CastItem.Music, server: MediaBackend, senderName: String) {
            val tracks = try {
                coroutineScope {
                    item.trackIds.chunked(MUSIC_FETCHES).flatMap { chunk -> chunk.map { id -> async { server.fetchItem(id) } }.awaitAll() }.filterNotNull()
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                throw CastLoadException(CastFailure.PLAYBACK_FAILED, "Couldn't fetch the tracks", e)
            }
            if (tracks.isEmpty()) throw CastLoadException(CastFailure.PLAYBACK_FAILED, "No track to play")
            val startId = item.trackIds.getOrNull(item.startIndex)
            setMusicServer(server)
            music.playFromList(
                tracks,
                tracks.firstOrNull { it.id == startId },
                MusicPlayContext(item.title, item.context),
                item.shuffle,
                initialPosition = item.startMs?.milliseconds,
            )
            val revision = music.queueSessionRevision
            if (music.state.value.currentTrack == null) {
                setMusicServer(null)
                throw CastLoadException(CastFailure.PLAYBACK_FAILED, "The music didn't start")
            }
            musicRevision = revision
            fun now(state: com.edde746.plezy.music.MusicState, position: kotlin.time.Duration): CastState? {
                val track = state.currentTrack
                if (music.queueSessionRevision != revision || track == null || state.status == MusicPlaybackStatus.IDLE) return null
                return CastState(
                    kind = CastMediaKind.MUSIC,
                    title = track.title.orEmpty(),
                    subtitle = track.grandparentTitle,
                    serverId = track.serverId,
                    thumb = track.thumbPath?.takeUnless { it.startsWith("http") },
                    paused = !state.isPlaying,
                    buffering = state.status == MusicPlaybackStatus.LOADING,
                    positionMs = position.inWholeMilliseconds,
                    durationMs = state.duration?.inWholeMilliseconds ?: 0,
                    canSeek = true,
                    hasPrevious = state.canGoPrevious,
                    hasNext = state.canGoNext,
                    volume = state.volume.toInt(),
                    from = senderName,
                )
            }
            mutableState.value = now(music.state.value, music.position.value)
            follow = scope.launch {
                combine(music.state, music.position, ::now).collect { now ->
                    mutableState.value = now
                    if (now == null) {
                        musicRevision = null
                        setMusicServer(null)
                        follow?.cancel()
                    }
                }
            }
        }

        override fun control(command: CastCommand) {
            val active = video?.takeIf { playbacks.active.value === it }
            if (active != null) return videoControl(active.store, command)
            if (musicRevision != null) scope.launch { musicControl(command) }
        }

        private fun videoControl(store: PlayerStore, command: CastCommand) {
            val ui = store.state.value
            val dispatched = when (command) {
                CastCommand.TogglePause -> PlayerCommand.TogglePause
                is CastCommand.SeekTo -> PlayerCommand.SeekTo(command.ms / 1000.0)
                is CastCommand.SeekBy -> PlayerCommand.SeekBy(command.ms / 1000.0)
                is CastCommand.Audio -> when {
                    command.key.startsWith(SOURCE) -> PlayerCommand.SelectSourceTrack(TrackKind.AUDIO, command.key.removePrefix(SOURCE).toIntOrNull())
                    else -> PlayerCommand.SelectTrack(TrackKind.AUDIO, command.key.removePrefix(TRACK).toLongOrNull())
                }
                is CastCommand.Subtitle -> PlayerCommand.SelectTrack(TrackKind.SUBTITLE, command.key.removePrefix(TRACK).toLongOrNull())
                is CastCommand.Quality -> command.key.toIntOrNull()?.let { ui.versions?.qualities?.getOrNull(it)?.command }
                CastCommand.Next -> PlayerCommand.NextEpisode
                CastCommand.Previous -> PlayerCommand.PreviousEpisode
                CastCommand.Stop -> PlayerCommand.Close
                is CastCommand.Volume -> PlayerCommand.SetVolume(command.percent.toDouble())
            }
            if (dispatched == null) return Log.w(TAG) { "No player command for $command" }
            store.dispatch(dispatched)
        }

        private suspend fun musicControl(command: CastCommand) {
            when (command) {
                CastCommand.TogglePause -> music.togglePlayPause()
                is CastCommand.SeekTo -> music.seek(command.ms.milliseconds)
                is CastCommand.SeekBy -> music.seek((music.position.value + command.ms.milliseconds).coerceAtLeast(kotlin.time.Duration.ZERO))
                CastCommand.Next -> music.next()
                CastCommand.Previous -> music.previous()
                CastCommand.Stop -> music.stop()
                is CastCommand.Volume -> music.setVolume(command.percent.toDouble())
                is CastCommand.Audio, is CastCommand.Subtitle, is CastCommand.Quality -> Log.d(TAG) { "Music has no $command" }
            }
        }
    }

    /** What this device casts from: its own servers and what plays here. */
    private inner class Source : CastSource {
        override fun access(serverId: String): ServerAccess? = when (val client = servers.manager.client(ServerId(serverId))) {
            is JellyfinClient -> client.connection.let { c ->
                ServerAccess(c.kind, c.serverMachineId, c.serverName, c.baseUrls, c.accessToken, c.userId, c.userName, c.deviceId)
            }
            is PlexClient -> client.config.token?.let { token ->
                ServerAccess(BackendKind.PLEX, serverId, client.serverName.orEmpty(), (listOf(client.baseUrl) + client.http.endpoints).distinct(), token)
            }
            else -> null
        }

        override fun current(): Pair<String, CastItem>? {
            val active = playbacks.active.value
            if (active != null) {
                val positionMs = (active.store.timeline.value.positionSeconds * 1000).toLong()
                return when (val request = active.request) {
                    is PlayRequest.Item -> {
                        // The item and version open now (the next episode, another version), else the play's.
                        val opened = (active.session as? PlaybackSession)?.opened?.value
                        val video = CastItem.Video(
                            itemId = opened?.item?.id ?: request.itemId,
                            startMs = positionMs,
                            mediaIndex = opened?.mediaIndex ?: request.mediaIndex,
                            mediaSourceId = if (opened != null) opened.mediaSourceId else request.mediaSourceId,
                            strict = request.strictMediaSelection,
                        )
                        (opened?.item?.serverId ?: request.serverId.value) to video
                    }
                    is PlayRequest.Live -> request.launch.serverId.value to liveItem(request)
                    is PlayRequest.Url -> null
                }
            }
            val state = music.state.value
            val track = state.currentTrack ?: return null
            val serverId = track.serverId ?: return null
            if (state.queue.any { it.serverId != serverId }) return null
            return serverId to CastItem.Music(
                trackIds = state.queue.map { it.id },
                startIndex = state.currentIndex.coerceAtLeast(0),
                title = state.playContext?.title.orEmpty(),
                context = state.playContext?.kind ?: com.edde746.plezy.music.MusicPlayContextKind.TRACKS,
                startMs = music.position.value.inWholeMilliseconds,
            )
        }

        override fun stopLocal() {
            if (playbacks.active.value != null) {
                navigator.pop(Route.Player)
            } else {
                scope.launch { music.stop() }
            }
        }

        override fun artworkUrl(serverId: String, thumb: String): String? =
            sizedImageUrl(servers.manager.client(ServerId(serverId)), thumb, ImageKind.POSTER, ARTWORK).ifEmpty { null }
    }

    private companion object {
        const val TAG = "AppCast"

        /** The API cache's namespace of handed-over Plex servers: no profile's. */
        const val CAST_SCOPE = "cast"
        const val SOURCE = "source:"
        const val TRACK = "track:"
        const val OFF = "off"
        const val MUSIC_FETCHES = 8
        val OPEN_TIMEOUT = 15.seconds
        val START_TIMEOUT = 60.seconds
        val ARTWORK = PixelSize(240, 360)
    }
}

package com.edde746.plezy.app

import com.edde746.plezy.log.Log
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.navigation.TopLevelDestination
import com.edde746.plezy.music.MusicPlayContext
import com.edde746.plezy.music.MusicPlayContextKind
import com.edde746.plezy.music.MusicSource
import com.edde746.plezy.music.MusicSourceResolver
import com.edde746.plezy.playback.session.PlayRequest
import com.edde746.plezy.profiles.Profile
import com.edde746.plezy.profiles.ProfileSwitchResult
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Duration.Companion.seconds

/**
 * The app of the development session [launch] asks for, on this graph (a local one, [AppBootstrap.local], whose
 * settings [applyDevSettings] stored first, the interface language among them): started on its [DevLaunch.open]
 * destination, every theme unlocked, signing into its [DevLaunch.servers] once it runs ([signInDevServers]), then
 * downloading its [DevLaunch.downloads] ([queueDevDownloads]), entered at [DevLaunch.entry], its trackers at
 * [DevLaunch.trackers]' fake server ([AppGraph.installDevTrackers]), connected there with [DevLaunch.trackersConnected]
 * ([connectDevTrackers]). The profile signs in to [DevLaunch.seerr]'s Seerr instance once the servers are bound, and
 * joins [DevLaunch.watchRoom] on the Watch Together screen. The playlist screen of its [DevLaunch.playlist] and the
 * detail screen of its [DevLaunch.openItem] open once the servers are bound. The player opens over it on its
 * [DevLaunch.url] or, once the servers are bound, on its [DevLaunch.play], and the metadata editor on its
 * [DevLaunch.edit]; its music session plays [DevLaunch.musicUrls] when
 * it gives some. With [DevLaunch.revokeToken] the first server's token is revoked once signed in ([revokeDevToken]);
 * with [DevLaunch.serverTasks] Home's Server Tasks are [DevServerTasks]'. A step of the launch that fails (a sign-in,
 * download, playlist, play, the trackers' connection or the Watch Together room) ends the launch as an option the launch
 * refuses does: it is logged with its stack and [failed] gets its message (Apple and the desktop exit with a non-zero
 * status, Android finishes). It never reaches the graph's failure boundary, which ends a development session's process
 * as a crash, and Xcode reports a crash of the app against every UI test of the app running on that Mac.
 */
fun AppGraph.devAppSession(launch: DevLaunch, platform: AppPlatform, failed: (String) -> Unit): AppSession {
    launch.trackers?.let { installDevTrackers(it) }
    // Each dev music track is its URL: the music session plays it as it is.
    val musicSources = if (launch.musicUrls.isEmpty()) null else MusicSourceResolver { track, _ -> MusicSource(track.id) }
    val castDemo = launch.settings.firstNotNullOfOrNull { it as? DevSetting.CastDemo }
    val demo = castDemo?.let { DevCastDemo(platform.castDiscovery) }
    val demoSender = castDemo?.sender == true
    val app = AppSession(
        this,
        object : AppPlatform by platform {
            override val automotive = launch.automotive || platform.automotive
            override val castDiscovery = demo?.app ?: platform.castDiscovery
        },
        launch.open,
        musicSources = musicSources,
        supporterPlatform = launch.supporter?.let(platform.supporter::withMode) ?: platform.supporter,
        serverTaskServers = if (launch.serverTasks) DevServerTasks() else null,
    )
    if (castDemo?.receiver == true) demo?.startReceiver(app, scope)
    launch.url?.let { app.play(PlayRequest.Url(it)) }
    if (launch.musicUrls.isNotEmpty()) {
        val tracks = launch.musicUrls.map { url ->
            MediaItem(id = url, backend = BackendKind.PLEX, kind = MediaKind.TRACK, title = url.substringAfterLast('/').substringBefore('?'))
        }
        scope.launch { app.music.playFromList(tracks, playContext = MusicPlayContext("Development", MusicPlayContextKind.TRACKS)) }
    }
    val play = launch.play
    val seerr = launch.seerr
    val edit = launch.edit
    val playlist = launch.playlist
    val watchRoom = launch.watchRoom
    val signsIn = launch.servers.isNotEmpty() || play != null || seerr != null || edit != null || playlist != null

    fun launchStep(step: suspend () -> Unit) = scope.launch {
        try {
            step()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e(TAG, e) { "The development launch failed" }
            failed(e.message ?: e.toString())
        }
    }
    if (signsIn) {
        launchStep {
            val sessions = app.signInDevServers(launch.servers, launch.entry)
            // A first run's sign-in made its profile active: the screens it opens below wait for that switch's restart.
            app.profiles.active.value?.let { app.awaitScreensFor(it.id) }
            if (launch.revokeToken) app.revokeDevToken(sessions.first())
            if (launch.downloads.isNotEmpty()) app.queueDevDownloads(sessions.first(), launch.downloads)
            launch.openMusic?.let { app.openDevMusic(it, sessions.first()) }
            launch.openItem?.let { app.openDevItem(it, sessions.first()) }
            launch.openShowSchedule?.let { app.openDevShowSchedule(it, sessions.first()) }
            if (seerr != null) app.signInToSeerr(seerr)
            if (watchRoom != null) app.joinDevWatchRoom(watchRoom)
            val clients = app.servers.manager.onlineClients.values.toList()
            if (playlist != null) app.navigator.navigate(playlist.resolve(clients))
            if (play != null) {
                val request = play.resolve(clients)
                app.play(request)
                // The stand-in sender asks over the player, then casts the same item here, replacing the local play.
                if (demoSender) {
                    launchStep {
                        delay(DEMO_SENDER_OVER_PLAYER_AFTER)
                        demo?.runSender(app, request)
                    }
                }
            }
            if (edit != null) {
                val item = edit.resolve(clients)
                app.navigator.navigate(Route.MetadataEdit(item.serverId, item.itemId))
            }
        }
    }
    if (demoSender && play == null) {
        launchStep {
            delay(DEMO_SENDER_AFTER)
            demo?.runSender(app, null)
        }
    }
    if (launch.trackersConnected) launchStep { app.connectDevTrackers() }
    // With servers to sign into, once they are (above).
    if (watchRoom != null && !signsIn) launchStep { app.joinDevWatchRoom(watchRoom) }
    if (launch.entry == DevEntry.BOOT) scope.launch { app.onboarding.enter(app.profiles.bootRoute(), recoveryRequired = false) }
    return app
}

/**
 * Opens the schedule of the show [title] on [server] over Live TV, as What's On does: once Live TV opens (its server's
 * Live TV probed), Live TV over Home with the schedule over it. Fails loudly when Live TV never opens.
 */
private suspend fun AppSession.openDevShowSchedule(title: String, server: DevServerSession) {
    checkNotNull(withTimeoutOrNull(SHOW_SCHEDULE_WAIT) { shell.state.first { it.liveTv } }) { "${server.connection.serverName} shows no Live TV" }
    shell.openLiveTv()
    navigator.navigate(Route.LiveTvShowSchedule(title, server.connection.serverId.value))
}

private val SHOW_SCHEDULE_WAIT = 60.seconds

/** How long after the start the stand-in sender links here when it has nothing to cast. */
private val DEMO_SENDER_AFTER = 3.seconds

/** How long after `--dev-play` opened the player the stand-in sender links here. */
private val DEMO_SENDER_OVER_PLAYER_AFTER = 12.seconds

/**
 * Opens [target] on [server]: Libraries on its first music library, or the artist or album of that title found by the
 * server's search, or the audio playlist of that title (`_` standing for a space, as `--dev-open-item`'s). Fails loudly
 * when there is none.
 */
private suspend fun AppSession.openDevMusic(target: DevOpenMusic, server: DevServerSession) {
    val serverId = server.connection.serverId.value
    when (target) {
        DevOpenMusic.Library -> {
            val library = checkNotNull(server.libraries.firstOrNull { it.kind.isMusic }) { "${server.connection.serverName} has no music library" }
            graph.data.libraryPrefs.setSelectedLibraryKey(library.copy(serverId = serverId).globalKey)
            shell.select(TopLevelDestination.LIBRARIES)
        }
        is DevOpenMusic.Artist -> navigator.navigate(Route.MusicArtist(serverId, devMusicItem(serverId, target.title, MediaKind.ARTIST).id))
        is DevOpenMusic.Album -> navigator.navigate(Route.MusicAlbum(serverId, devMusicItem(serverId, target.title, MediaKind.ALBUM).id))
        is DevOpenMusic.Playlist -> {
            val client = checkNotNull(musicScreens.backend(serverId)) { "No client for $serverId" }
            val title = target.title.replace('_', ' ')
            val playlist = checkNotNull(client.fetchPlaylistsPage(playlistType = "audio").items.firstOrNull { it.title.equals(title, ignoreCase = true) }) {
                "No audio playlist '${target.title}' on $serverId"
            }
            navigator.navigate(Route.MusicPlaylist(serverId, playlist.id))
        }
    }
}

/** Opens the detail screen of the item [title] names on [server] ([findDevTitle]): a collection's or an item's. */
private suspend fun AppSession.openDevItem(title: String, server: DevServerSession) {
    val name = server.connection.serverName
    val client = checkNotNull(servers.manager.mediaBrowserClient(server.connection.id)) { "--dev-open-item: $name isn't connected" }
    val serverId = server.connection.serverId
    navigator.navigate(
        when (val found = client.findDevTitle(title, "--dev-open-item", name)) {
            is DevTitle.Item -> Route.MediaDetail(serverId, found.item.id)
            is DevTitle.Collection -> Route.CollectionDetail(serverId, found.collection.id)
        },
    )
}

private suspend fun AppSession.devMusicItem(serverId: String, title: String, kind: MediaKind): MediaItem {
    val client = checkNotNull(musicScreens.backend(serverId)) { "No client for $serverId" }
    return checkNotNull(client.searchItems(title).firstOrNull { it.kind == kind && it.title == title }) { "No ${kind.name.lowercase()} '$title' on $serverId" }
}

/**
 * Signs the active profile in to [seerr] with its local account ([activeDevProfile]).
 */
private suspend fun AppSession.signInToSeerr(seerr: DevSeerr) {
    awaitAccounts(activeDevProfile().id)
    val instance = this.seerr.auth.probeFirstReachable(seerr.url)
    val signedIn = this.seerr.auth.signInWithLocal(instance.baseUrl, seerr.email, seerr.password)
    this.seerr.adoptSession(instance.complete(signedIn))
}

/**
 * The active profile; with none, a local profile "Dev" is made and switched to first. Returns once the screens are the
 * profile's ([AppSession.awaitScreensFor]): a screen opened before then goes with the switch's restart.
 */
private suspend fun AppSession.activeDevProfile(): Profile {
    profiles.hydrated.first { it }
    val profile = profiles.active.value ?: profiles.createLocalProfile(DEV_PROFILE_NAME).also { created ->
        check(profiles.switchProfile(created) { _, _ -> null } == ProfileSwitchResult.SWITCHED) { "Couldn't switch to the dev profile" }
    }
    awaitScreensFor(profile.id)
    return profile
}

/** Opens the Watch Together screen and joins the room of [code] as a recent room does: its host when it is empty. */
private suspend fun AppSession.joinDevWatchRoom(code: String) {
    activeDevProfile()
    navigator.navigate(Route.WatchTogether)
    val store = checkNotNull(watchTogether(Route.WatchTogether)) { "No Watch Together for the dev profile" }
    store.joinRecent(code)
}

/** The profile a development session signs in with when none is active. */
private const val DEV_PROFILE_NAME = "Dev"

private const val TAG = "DevSession"

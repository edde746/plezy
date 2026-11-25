package com.edde746.plezy.app

import com.edde746.plezy.log.Log
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.playback.session.OpenedFile
import com.edde746.plezy.playback.session.PlayRequest
import com.edde746.plezy.playback.session.PlaybackSession
import com.edde746.plezy.playback.session.ReloadOutcome
import com.edde746.plezy.presentation.navigation.PlezyNavigator
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.watch.RoomPlayerWatch
import com.edde746.plezy.presentation.watch.WatchOpen
import com.edde746.plezy.presentation.watch.WatchRoomText
import com.edde746.plezy.presentation.watch.WatchToolbarUi
import com.edde746.plezy.presentation.watch.WatchTogetherStore
import com.edde746.plezy.profiles.profileUserScope
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.strings.InterfaceLocale
import com.edde746.plezy.watch.RecentRoomsService
import com.edde746.plezy.watch.WatchCopy
import com.edde746.plezy.watch.WatchFileStart
import com.edde746.plezy.watch.WatchLabels
import com.edde746.plezy.watch.WatchRelayChoice
import com.edde746.plezy.watch.WatchTogether
import com.edde746.plezy.watch.watchVersionOf
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.mapNotNull
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

/**
 * Watch Together in the running app: one [WatchTogether] per active profile (a profile switch closes it, which leaves
 * its room at once), the player of each playback bound to it ([RoomPlayerWatch]), the room's file opened through the
 * app's player (in place when one plays a server's item, else as a new playback), the screen's store and Home's toolbar
 * state. Main thread only.
 *
 * @param profileHeld the profile picker covers the player ([PlaybackController.holdForProfilePick]).
 * @param vehicleRestricted the car forbids video now (Android Automotive), read once a player binds.
 */
@OptIn(ExperimentalCoroutinesApi::class)
internal class AppWatchTogether(
    private val graph: AppGraph,
    private val platform: AppPlatform,
    private val servers: AppServers,
    private val player: StateFlow<ActivePlayback?>,
    private val play: (PlayRequest) -> Unit,
    private val navigator: PlezyNavigator,
    private val scope: CoroutineScope,
    private val profileHeld: Flow<Boolean>,
    private val vehicleRestricted: () -> Flow<Boolean>,
) {
    private class Session(val profileId: String, val watch: WatchTogether)

    private val relaySetting: StateFlow<String?> =
        graph.data.deviceSettings.observe(AppSettings.watchPartyRelayUrl).stateIn(scope, SharingStarted.Eagerly, null)
    private val relays by lazy { WatchRelayChoice(graph.http) }
    private val recentRooms by lazy { RecentRoomsService(graph.data.profileSettings, graph.clock) }
    private val session = MutableStateFlow<Session?>(null)
    private var bound: ActivePlayback? = null
    private var boundWatch: WatchTogether? = null
    private var playerWatch: RoomPlayerWatch? = null

    /** Home's toolbar action, worded again when the interface language changes. */
    val toolbar: StateFlow<WatchToolbarUi> = combine(session.flatMapLatest { it?.watch?.state ?: flowOf(null) }, InterfaceLocale.tag) { state, _ -> WatchRoomText.toolbar(state) }
        .stateIn(scope, SharingStarted.Eagerly, WatchRoomText.toolbar(null))

    /** The room's notices as snackbar texts, one each. */
    val notices: Flow<String> = session.flatMapLatest { current ->
        val watch = current?.watch ?: return@flatMapLatest emptyFlow()
        watch.notices.mapNotNull { notice ->
            val s = watch.state.value
            WatchLabels.noticeText(notice, s.media, s.host, s.myPeerId)
        }
    }

    init {
        scope.launch(start = CoroutineStart.UNDISPATCHED) {
            servers.profiles.active.map { it?.id }.distinctUntilChanged().collect { profileId ->
                session.value?.watch?.close()
                session.value = profileId?.let { Session(it, newWatch(it)) }
            }
        }
        scope.launch(start = CoroutineStart.UNDISPATCHED) {
            combine(player, session) { playback, current -> playback to current?.watch }.collect { (playback, watch) -> bind(playback, watch) }
        }
    }

    private fun newWatch(profileId: String): WatchTogether = WatchTogether(
        client = "Plezy/${graph.appVersion}",
        displayName = { servers.profiles.active.value?.displayName.orEmpty() },
        profileScope = profileUserScope(profileId),
        relayBaseUrl = relaySetting,
        relaysFor = relays::relaysFor,
        recentRooms = recentRooms,
        clientFor = { servers.manager.client(ServerId(it)) },
        findCopies = servers.aggregation::findTitleCopiesAcrossServers,
        scope = scope,
    ).also { watch -> watch.navigatorOpener = { copy -> openRoomCopy(watch, copy, playback = null) } }

    /** The Watch Together screen's store, kept while its route is on a stack; null for another route or no profile. */
    fun store(route: Route): WatchTogetherStore? {
        if (route != Route.WatchTogether) return null
        val current = session.value ?: return null
        return navigator.retain(route, "$STORE:${current.profileId}", { WatchTogetherStore(current.watch, scope) }, WatchTogetherStore::close)
    }

    /**
     * [request] as the app plays it: a connected host's own play opens paused, for the room to start everyone together,
     * when the room can get the file.
     */
    fun roomOwned(request: PlayRequest): PlayRequest {
        if (request !is PlayRequest.Item || request.roomStart) return request
        val s = session.value?.watch?.state?.value ?: return request
        val shareable = !request.offline || servers.manager.isServerOnline(request.serverId)
        return if (s.connected && s.isHost && shareable) request.copy(roomStart = true) else request
    }

    /**
     * Binds [playback]'s player to [watch]: the one before is released, continuing when another player took over. A
     * URL's video and Live TV never take part.
     */
    private fun bind(playback: ActivePlayback?, watch: WatchTogether?) {
        if (playback === bound && watch === boundWatch) return
        playerWatch?.release(continuing = playback != null)
        playerWatch = null
        bound = playback
        boundWatch = watch
        if (playback == null) return
        if (watch == null) return playback.store.attachWatch(null)
        val session = playback.session as? PlaybackSession ?: return
        val bridge = RoomPlayerWatch(
            watch = watch,
            player = playback.store.watchPlayer,
            opened = session.opened.map { opened -> opened?.takeUnless { session.info.value.live }?.let(::watchOpen) },
            failed = session.info.map { it.failure != null },
            backgrounded = backgrounded(playback),
            vehicleRestricted = vehicleRestricted(),
            profileHeld = profileHeld,
            held = playback.output?.negotiating ?: flowOf(false),
            roomLaunch = (playback.request as? PlayRequest.Item)?.roomStart == true,
            openInPlace = { copy -> openRoomCopy(watch, copy, playback) },
            exitPlayer = { navigator.pop(Route.Player) },
            scope = playback.scope,
        )
        playerWatch = bridge
        session.roomOwnsStart = bridge::ownsStart
        playback.store.attachWatch(bridge)
    }

    /**
     * [playback]'s player is going ([PlaybackController] disposes of it; [replaced] by another one): the room lets go of
     * it, a host's media stopping for everyone unless replaced. The job completes once the room no longer commands the
     * player; null when the room never had it.
     */
    fun releasePlayer(playback: ActivePlayback, replaced: Boolean): Job? {
        if (playback !== bound) return null
        val bridge = playerWatch ?: return null
        playerWatch = null
        (playback.session as? PlaybackSession)?.roomOwnsStart = { false }
        return bridge.release(continuing = replaced)
    }

    /** The app out of sight on a phone, tablet or TV, outside picture in picture; a covered desktop window plays on. */
    private fun backgrounded(playback: ActivePlayback): Flow<Boolean> =
        if (platform.formFactor == FormFactor.DESKTOP) {
            flowOf(false)
        } else {
            combine(graph.foreground, playback.store.inPictureInPicture) { foreground, pip -> !foreground && !pip }
        }

    /**
     * The file the player committed to, as the room knows it, and where it opens; a download is shared while its server
     * is online.
     */
    private fun watchOpen(opened: OpenedFile): WatchOpen? {
        val item = opened.item
        val serverId = item.serverId ?: return null
        val versions = item.mediaVersions.orEmpty()
        val version = versions.getOrNull(opened.mediaIndex) ?: versions.firstOrNull { opened.mediaSourceId != null && it.id == opened.mediaSourceId }
        val shareable = !opened.offline || servers.manager.isServerOnline(ServerId(serverId))
        return WatchOpen(WatchCopy.of(item, version), shareable, WatchFileStart(opened.loadId, opened.startMs))
    }

    /**
     * Opens the room's [copy] for the room to start: in [playback]'s player in place, the room's version, once a reload
     * under way is over; as a new playback when there is none, it plays Live TV, a URL or the offline library, or it
     * has no file yet. False when it can't (offline, the item unreadable, the reload failed) or the room's copy changed
     * meanwhile.
     */
    private suspend fun openRoomCopy(watch: WatchTogether, copy: WatchCopy, playback: ActivePlayback?): Boolean {
        val bridge = playerWatch?.takeIf { playback != null && playback === bound }
        if (bridge != null && bridge.openCopy == copy) return true
        if (!graph.network.value.online) return false
        val item = copy.item ?: fetchItem(copy) ?: return false
        if (watch.roomCopy?.ref != copy) return stale(copy)
        val version = watchVersionOf(item, copy)
        val session = playback?.session as? PlaybackSession
        val offlineLibrary = (playback?.request as? PlayRequest.Item)?.offline == true
        if (bridge != null && session != null && !offlineLibrary) {
            Log.d(TAG) { "opening the room's file $copy in the player" }
            bridge.openingForRoom()
            val outcome = session.openForRoom(item, version?.index ?: 0, version?.sourceId) { watch.roomCopy?.ref == copy && playerWatch === bridge }
            if (outcome == ReloadOutcome.OPENED) return true
            bridge.abandonRoomOpen()
            // A player with no file yet, or one that closed meanwhile, gives way to a new playback.
            if (outcome != ReloadOutcome.REJECTED) return false
            if (watch.roomCopy?.ref != copy) return stale(copy)
        }
        Log.d(TAG) { "opening the room's file $copy" }
        play(
            PlayRequest.Item(
                serverId = ServerId(copy.serverId),
                itemId = copy.itemId,
                item = item,
                mediaIndex = version?.index ?: 0,
                mediaSourceId = version?.sourceId,
                roomStart = true,
            ),
        )
        return true
    }

    private fun stale(copy: WatchCopy): Boolean {
        Log.d(TAG) { "skipping the stale open of $copy" }
        return false
    }

    private suspend fun fetchItem(copy: WatchCopy): MediaItem? {
        val client = servers.manager.client(ServerId(copy.serverId)) ?: return null
        return try {
            client.fetchItem(copy.itemId)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "could not fetch ${copy.itemId}" }
            null
        }
    }

    /** Leaves the room and closes Watch Together: the app is closing. */
    fun close() {
        playerWatch?.release(continuing = false)
        playerWatch = null
        session.value?.watch?.close()
        session.value = null
    }

    private companion object {
        const val TAG = "WatchTogether"
        const val STORE = "watch"
    }
}

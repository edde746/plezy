package com.edde746.plezy.presentation.watch

import com.edde746.plezy.input.WatchCommand
import com.edde746.plezy.presentation.player.PlayerWatch
import com.edde746.plezy.strings.T
import com.edde746.plezy.watch.PlezyPlayerAdapter
import com.edde746.plezy.watch.RoomPlayer
import com.edde746.plezy.watch.WatchAway
import com.edde746.plezy.watch.WatchCopy
import com.edde746.plezy.watch.WatchFileStart
import com.edde746.plezy.watch.WatchLabels
import com.edde746.plezy.watch.WatchPlayerHooks
import com.edde746.plezy.watch.WatchSnapshot
import com.edde746.plezy.watch.WatchTogether
import kotlinx.coroutines.CompletableJob
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.mapNotNull
import kotlinx.coroutines.flow.merge
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import kotlin.math.roundToLong
import kotlin.time.TimeSource

/**
 * A file the player committed to, as the room knows it: [copy], whether the room can get it ([shareable]), and where
 * it opens ([start]) while the player doesn't report it yet.
 */
internal data class WatchOpen(val copy: WatchCopy, val shareable: Boolean, val start: WatchFileStart? = null)

/**
 * One player's side of Watch Together ([PlayerWatch]): one [PlezyPlayerAdapter] per file the player opens ([opened],
 * null while none or for Live TV), handed to the room, and the viewer's presses routed to the room while it drives this
 * player. A reload of the same file keeps its adapter, which reads as opening again until the reload shows a frame;
 * [failed] (a fatal playback failure) detaches it, and the next open binds anew. [roomLaunch] the room opened this
 * player. [backgrounded] the app is out of sight, [vehicleRestricted] the car forbids video and [profileHeld] the
 * profile picker covers the player while the room drives it (it pauses here alone, and the room's play is refused
 * meanwhile): the room stops waiting for this player meanwhile. [held] the player measures or switches the display for
 * the file: the room waits and its commands with it.
 * Registers the player's hooks ([openInPlace], [exitPlayer]) with the room. [release] when the player goes.
 */
internal class RoomPlayerWatch(
    private val watch: WatchTogether,
    private val player: RoomPlayer,
    opened: Flow<WatchOpen?>,
    failed: Flow<Boolean>,
    backgrounded: Flow<Boolean>,
    vehicleRestricted: Flow<Boolean>,
    profileHeld: Flow<Boolean>,
    held: Flow<Boolean>,
    private var roomLaunch: Boolean,
    openInPlace: suspend (WatchCopy) -> Boolean,
    exitPlayer: () -> Unit,
    private val scope: CoroutineScope,
    private val timeSource: TimeSource = TimeSource.Monotonic,
) : PlayerWatch {
    private var adapter: PlezyPlayerAdapter? = null
    private var shareable = true
    private val refusals = mutableSetOf<WatchAway>()
    private var hold: CompletableJob? = null
    private val messages = MutableSharedFlow<String>(extraBufferCapacity = MESSAGE_BUFFER)
    private val actions = WatchActions(watch, scope) { messages.tryEmit(it) }
    private val jobs: List<Job>

    /** The player as the room commands it: a car that forbids video or the profile picker refuses the room's play. */
    private val roomPlayer: RoomPlayer = object : RoomPlayer by player {
        override suspend fun play() {
            check(refusals.isEmpty()) { "playback is refused here: $refusals" }
            player.play()
        }
    }

    init {
        watch.registerPlayer(this, WatchPlayerHooks(openInPlace, exitPlayer))
        jobs = listOf(
            scope.launch(start = CoroutineStart.UNDISPATCHED) { held.distinctUntilChanged().collect(::hold) },
            scope.launch(start = CoroutineStart.UNDISPATCHED) { opened.collect(::bind) },
            scope.launch(start = CoroutineStart.UNDISPATCHED) { failed.distinctUntilChanged().collect { if (it) detach() } },
            scope.launch(start = CoroutineStart.UNDISPATCHED) {
                backgrounded.distinctUntilChanged().collect { watch.setAway(WatchAway.BACKGROUND, it) }
            },
            scope.launch(start = CoroutineStart.UNDISPATCHED) {
                vehicleRestricted.distinctUntilChanged().collect { refuse(WatchAway.VEHICLE_RESTRICTED, it) }
            },
            scope.launch(start = CoroutineStart.UNDISPATCHED) {
                profileHeld.distinctUntilChanged().collect { refuse(WatchAway.PROFILE_SELECTION, it) }
            },
        )
    }

    /**
     * The room starts this player's files now, so they open paused and at the room's speed: a connected host's file the
     * room can get, or for a guest the room's file (opening or followed).
     */
    fun ownsStart(): Boolean {
        if (!watch.isConnected) return false
        return if (watch.isHost) shareable else roomLaunch || routesControls
    }

    /** The copy of the file the player has open, as the room knows it; null while none. */
    val openCopy: WatchCopy? get() = adapter?.copy

    /** The room opens its file in this player: the next open is the room's ([abandonRoomOpen] when it didn't happen). */
    fun openingForRoom() {
        roomLaunch = true
    }

    fun abandonRoomOpen() {
        roomLaunch = false
    }

    /** The display is measured or switched for the file: the room's commands wait until it is over. */
    private fun hold(on: Boolean) {
        if (on) {
            if (hold == null) hold = Job().also { adapter?.hold(it) }
        } else {
            hold?.complete()
            hold = null
        }
    }

    /**
     * Video may not play here for [reason] (or may again): the car forbids it, the profile picker covers the player.
     * While the room drives this player, it pauses here alone and the room stops waiting for it, not a pause for
     * everyone; lifted, the room catches it up.
     */
    private fun refuse(reason: WatchAway, refused: Boolean) {
        if (refused) {
            refusals += reason
            if (!routesControls) return
            watch.setAway(reason, true)
            scope.launch { player.pause() }
        } else {
            refusals -= reason
            watch.setAway(reason, false)
        }
    }

    override val state: StateFlow<PlayerWatchUi?> =
        watch.state.map(::build).stateIn(scope, SharingStarted.Eagerly, build(watch.state.value))

    override val notices: Flow<String> = merge(
        watch.notices.mapNotNull { notice ->
            val s = watch.state.value
            WatchLabels.noticeText(notice, s.media, s.host, s.myPeerId)
        },
        messages,
    )

    override val routesControls: Boolean get() = adapter?.let(watch::follows) ?: false

    override val roomRate: Double? get() = if (routesControls) watch.roomRate else null

    override val stoppedHere: Boolean get() = watch.isAway(WatchAway.PAUSED_HERE)

    override fun stopHere() {
        if (routesControls) watch.setAway(WatchAway.PAUSED_HERE, true)
    }

    override fun resumeHere() = watch.setAway(WatchAway.PAUSED_HERE, false)

    override fun play(): Boolean = watch.play()

    override fun pause() {
        watch.pause()
    }

    override fun onLocalSeek(seconds: Double) {
        watch.seek((seconds * 1000).roundToLong())
    }

    override fun onLocalRate(rate: Double) {
        watch.setRate(rate)
    }

    override fun endMedia() {
        watch.endMedia()
    }

    override fun execute(command: WatchCommand) = actions.run(command)

    /**
     * The player committed to [open]: the adapter of an earlier open of the same file stays (a reload), reading as
     * opening until the reload shows a frame; any other open gets a new one. A room's copy that names this item without
     * a version stands for whichever version opened.
     */
    private fun bind(open: WatchOpen?) {
        val previous = adapter
        if (open == null) {
            if (previous != null) {
                adapter = null
                watch.playerClosed(previous, continuing = true)
            }
            return
        }
        shareable = open.shareable
        val copy = roomCopyFor(open.copy)
        if (previous != null && previous.copy == copy) {
            open.start?.let(previous::reopened)
            watch.playerChanged(previous)
            return
        }
        val next = PlezyPlayerAdapter(roomPlayer, copy, timeSource, open.start)
        hold?.let(next::hold)
        adapter = next
        val launch = roomLaunch
        roomLaunch = false
        watch.playerOpened(next, open.shareable, launch)
    }

    private fun roomCopyFor(opened: WatchCopy): WatchCopy {
        val room = watch.roomCopy?.ref ?: return opened
        val sameItem = room.serverId == opened.serverId && room.itemId == opened.itemId
        return if (sameItem && (room.versionId.isEmpty() || opened.versionId.isEmpty())) room else opened
    }

    /** The file failed for good: the room stops commanding this player and counting on it, and keeps its media. */
    private fun detach() {
        roomLaunch = false
        val open = adapter ?: return
        adapter = null
        watch.playerClosed(open, continuing = true)
    }

    /**
     * The player is going away; a host's media stops for everyone unless [continuing] (another player took over). The
     * background, the car's restriction, the profile picker and a pause here belonged to this player: the next one
     * starts fresh. The job completes once the room no longer commands the player (null: it never did): dispose of the
     * player after.
     */
    fun release(continuing: Boolean): Job? {
        jobs.forEach(Job::cancel)
        watch.unregisterPlayer(this)
        hold(false)
        val released = adapter?.let { watch.playerClosed(it, continuing) }
        adapter = null
        roomLaunch = false
        watch.setAway(WatchAway.PAUSED_HERE, false)
        watch.setAway(WatchAway.BACKGROUND, false)
        watch.setAway(WatchAway.VEHICLE_RESTRICTED, false)
        watch.setAway(WatchAway.PROFILE_SELECTION, false)
        return released
    }

    private fun build(s: WatchSnapshot): PlayerWatchUi? {
        if (!s.inSession) return null
        val following = s.following
        val canControl = !following || s.canControl
        return PlayerWatchUi(
            pill = WatchRoomText.pill(s),
            reconnecting = if (s.reconnecting) T.watchTogether.reconnecting else null,
            playBlocked = if (s.playBlocked) {
                WatchPlayBlockedUi(T.watchTogether.playBlockedTitle, T.watchTogether.playBlockedDescription, T.common.play)
            } else {
                null
            },
            mismatch = WatchRoomText.mismatchPrompt(s),
            room = WatchRoomText.room(s),
            canControl = canControl,
            canChangeEpisode = !following || s.isHost,
            controlsLocked = if (canControl) null else T.watchTogether.notices.controlRefused,
            following = following,
            roomRate = if (following) s.room?.rate else null,
            pausedHere = s.pausedHere,
            atMediaEnd = following && s.atMediaEnd,
        )
    }

    private companion object {
        const val MESSAGE_BUFFER = 8
    }
}

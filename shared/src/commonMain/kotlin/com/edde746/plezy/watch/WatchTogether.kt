package com.edde746.plezy.watch

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.model.TitleQuery
import com.edde746.plezy.servers.LibraryLookupResult
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.launch
import party.openwatch.Candidate
import party.openwatch.Connection
import party.openwatch.Control
import party.openwatch.EndReason
import party.openwatch.MatchState
import party.openwatch.Participant
import party.openwatch.PartyEvent
import party.openwatch.PartyException
import party.openwatch.PartyState
import party.openwatch.Phase
import party.openwatch.Relays
import party.openwatch.Resolver
import party.openwatch.WatchParty
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

/**
 * Watch Together on Open Watch Party for one profile session: one [WatchParty] per room session, the user's player
 * attached to it, and the room's state ([state]) and notices ([notices]) for the UI. A profile switch closes it
 * ([close]), which leaves the room at once.
 *
 * - [createRoom] and [joinRoom] start a room session (closing the one before), remember its code in the profile's recent
 *   rooms on the current relay, and share an open player's file when this user hosts. [leave] leaves or cancels.
 * - The player screen reports the file it opened ([playerOpened]) as a [PlezyPlayerAdapter] and the file going
 *   ([playerClosed]): a host's file is shared with the room; a guest's follows the room when it is the room's copy.
 *   The room opens its copy for a guest by itself, once per epoch and file, through the player's hooks or
 *   [navigatorOpener]. The user's presses go to the room while it drives the player ([play], [pause], [seek],
 *   [setRate]); each returns true when the room took it.
 *
 * Main thread only.
 *
 * @param client the client the relay sees: `Plezy/<app version>`.
 * @param displayName the active profile's name ([watchDisplayName] makes it a valid one).
 * @param profileScope the active profile's settings scope for recent rooms; null keeps none.
 * @param relayBaseUrl the device's self-hosted relay setting (canonical), null for the public relays.
 * @param clientFor the media server of an id this profile reaches.
 * @param findCopies the search of every server for a title ([RoomTitleResolver]).
 * @param newParty makes a room session's party; tests reach a relay of their own through it.
 */
internal class WatchTogether(
    private val client: String,
    private val displayName: () -> String,
    private val profileScope: String?,
    private val relayBaseUrl: StateFlow<String?>,
    private val relaysFor: (String?) -> Relays,
    private val recentRooms: RecentRoomsService?,
    private val clientFor: (String) -> MediaBackend?,
    findCopies: suspend (TitleQuery) -> LibraryLookupResult,
    private val scope: CoroutineScope,
    private val newParty: (relays: Relays, client: String, name: String, resolver: Resolver<WatchCopy>) -> WatchParty<WatchCopy> =
        { relays, client, name, resolver -> WatchParty(relays = relays, client = client, name = name, resolver = resolver, scope = scope) },
    private val shareDurationWait: Duration = 30.seconds,
    private val timeSource: TimeSource = TimeSource.Monotonic,
) {
    private val resolver = RoomTitleResolver(clientFor, findCopies)

    private var party: WatchParty<WatchCopy>? = null
    private var partyJobs: List<Job> = emptyList()
    private var partyState: PartyState<WatchCopy> = PartyState()
    private val mutableState = MutableStateFlow(WatchSnapshot(relayBaseUrl = relayBaseUrl.value))
    private val mutableNotices = MutableSharedFlow<WatchNotice>(extraBufferCapacity = NOTICE_BUFFER)

    /** The player that has a file open, whether or not the room follows it. */
    private var player: OpenPlayer? = null
    private var attached = false

    /** Why the user is away from the player: the room stops waiting for them meanwhile. */
    private val away = mutableSetOf<WatchAway>()
    private val isAway: Boolean get() = away.isNotEmpty()
    private var playBlocked = false
    private var searchFailedEpoch: Long? = null
    private var closed = false
    private var openedKey: String? = null
    private var shareGeneration = 0
    private var chosen = 0

    /** Bumped by every [choose]: the party drops an earlier choice's pending probe for a later one, so only the latest may act on its refusal. */
    private var chooseGeneration = 0

    private var playerHooks: WatchPlayerHooks? = null
    private var playerHooksOwner: Any? = null

    /** Opens the room's file when no player is open (a play of the app's player); true when it is opening. */
    var navigatorOpener: (suspend (WatchCopy) -> Boolean)? = null

    /** Everything the UI shows, one value per change. */
    val state: StateFlow<WatchSnapshot> = mutableState.asStateFlow()

    /** Events for snackbars and toasts. */
    val notices: SharedFlow<WatchNotice> = mutableNotices.asSharedFlow()

    private class OpenPlayer(val adapter: PlezyPlayerAdapter, val shareable: Boolean)

    // State

    private val snapshot: WatchSnapshot get() = mutableState.value

    val isConnected: Boolean get() = snapshot.connected
    val isHost: Boolean get() = snapshot.isHost
    val canControl: Boolean get() = snapshot.canControl
    val participants: List<Participant> get() = snapshot.participants
    val roomCopy: Candidate<WatchCopy>? get() = snapshot.roomCopy

    /** The room's file is open in this user's player and the room drives it. */
    val isFollowing: Boolean get() = player?.let { follows(it.adapter) } ?: false

    /** The room drives [adapter]: it is the attached player and has the room's file open. */
    fun follows(adapter: PlezyPlayerAdapter): Boolean {
        val choice = partyState.choice
        val match = partyState.match?.state
        return partyState.connection == Connection.CONNECTED &&
            attached &&
            player?.adapter === adapter &&
            choice != null &&
            choice.ref == adapter.copy &&
            (match == MatchState.MATCHED || match == MatchState.MISMATCHED)
    }

    /** The relay setting's scope, for recent rooms. */
    val relayScope: String get() = WatchPartyRelays.relayScopeOf(relayBaseUrl.value)

    /** The room's playback rate, which the player shows while it follows the room. */
    val roomRate: Double? get() = snapshot.room?.rate

    /** The recent rooms of this profile on the current relay, newest first; nothing without a profile. */
    @OptIn(ExperimentalCoroutinesApi::class)
    fun observeRecentRooms(): Flow<List<RecentRoom>> {
        val profile = profileScope ?: return emptyFlow()
        val rooms = recentRooms ?: return emptyFlow()
        return relayBaseUrl.flatMapLatest { base -> rooms.observe(profile, WatchPartyRelays.relayScopeOf(base)) }
    }

    /** Names the recent room [code] on the current relay; a blank name clears it. */
    suspend fun renameRecentRoom(code: String, name: String?) {
        val scope = profileScope ?: return
        recentRooms?.rename(scope, code, relayScope, name?.trim()?.ifEmpty { null })
    }

    suspend fun removeRecentRoom(code: String) {
        val scope = profileScope ?: return
        recentRooms?.remove(scope, code, relayScope)
    }

    // Rooms

    private fun startParty(): WatchParty<WatchCopy> {
        closeParty()
        val next = newParty(relaysFor(relayBaseUrl.value), client, watchDisplayName(displayName()), resolver)
        party = next
        openedKey = null
        playBlocked = false
        // Relay epochs restart with each room: an old room's failed search says nothing about this one.
        searchFailedEpoch = null
        partyJobs = listOf(
            scope.launch(start = CoroutineStart.UNDISPATCHED) { next.state.collect { if (party === next) onState(it) } },
            scope.launch(start = CoroutineStart.UNDISPATCHED) { next.events.collect { if (party === next) onEvent(next, it) } },
        )
        val open = player
        if (open != null && !isAway) {
            next.attachPlayer(open.adapter, open.adapter.copy)
            attached = true
        }
        return next
    }

    /** Catches up with [party]'s state after a call that changed it, before acting on it. */
    private fun sync(party: WatchParty<WatchCopy>) {
        if (this.party === party && party.state.value != partyState) onState(party.state.value)
    }

    /** Creates a room and joins it as host; its code. Throws [PartyException] with the SDK's code when it fails. */
    suspend fun createRoom(): String {
        val party = startParty()
        val code = logFailure("create") { party.create() }
        sync(party)
        rememberRoom(code)
        shareOpenPlayer()
        return code
    }

    /**
     * Joins the room of [code] as typed or pasted. With [create], a code that names no room gets a new room with that
     * code, and this user hosts it as after [createRoom]. Throws [PartyException] with the SDK's code when it fails;
     * `invalid_code` before any party for a text that isn't a code.
     */
    suspend fun joinRoom(code: String, create: Boolean = false) {
        val normalized = WatchPartyRelays.normalizeRoomCode(code) ?: throw PartyException(PartyException.INVALID_CODE, "not a room code")
        val party = startParty()
        logFailure(if (create) "join or create" else "join") { party.join(normalized, create = create) }
        sync(party)
        rememberRoom(normalized)
        val joined = party.state.value
        if (create && joined.isHost && joined.media == null) shareOpenPlayer()
    }

    /** Logs why a create or join failed: the user sees only the code's text. */
    private suspend fun <T> logFailure(action: String, attempt: suspend () -> T): T = try {
        attempt()
    } catch (e: PartyException) {
        if (e.code != PartyException.CANCELLED) {
            val relays = if (relayBaseUrl.value == null) "the public relays" else "the custom relay"
            Log.w(TAG) { "$action failed on $relays: ${e.code}: ${e.message}" }
        }
        throw e
    }

    private fun shareOpenPlayer() {
        val open = player ?: return
        if (open.shareable) scope.launch { shareCopy(open.adapter, open.adapter.positionMs) }
    }

    private suspend fun rememberRoom(code: String) {
        val profile = profileScope ?: return
        val rooms = recentRooms ?: return
        try {
            rooms.remember(profile, code, relayScope)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "could not remember the room" }
        }
    }

    /** Leaves the room, or cancels a create or join under way. */
    fun leave() {
        party?.leave()
    }

    /** Host: ends the room for everyone. */
    fun endRoom() = guard { party?.end() }

    fun setControl(mode: Control) = guard { party?.setControl(mode) }

    fun transferHost(peerId: String) = guard { party?.transferHost(peerId) }

    fun kick(peerId: String) = guard { party?.kick(peerId) }

    fun setLocked(locked: Boolean) = guard { party?.lock(locked) }

    /** Host: stops the media for everyone. */
    fun stopMedia() = guard { party?.clearMedia() }

    private inline fun guard(command: () -> Unit) {
        try {
            command()
        } catch (e: PartyException) {
            notify(refused(e))
        }
    }

    // Matching

    fun acceptMismatch() = guard { party?.acceptMismatch() }

    fun declineMismatch() = guard { party?.declineMismatch() }

    /** Searches the libraries again for the room's media. */
    fun searchAgain() {
        searchFailedEpoch = null
        guard { party?.resolveAgain() }
        publish()
    }

    /** Plays [candidate] for the room's media. False when it can't (no length, the media changed meanwhile). */
    suspend fun choose(candidate: Candidate<WatchCopy>): Boolean {
        chooseGeneration++
        val party = party ?: return false
        val took = try {
            party.choose(candidate)
        } catch (e: PartyException) {
            notify(refused(e))
            false
        }
        if (took && this.party === party) {
            chosen++
            publish()
        }
        return took
    }

    /** Plays [version] of [item], found anywhere in the app, for the room's media. */
    suspend fun chooseCopy(item: MediaItem, version: MediaVersion?): Boolean {
        if (item.serverId == null) return false
        return choose(candidateFor(item, version, clientFor))
    }

    /** Shifts this user's file against the room: local = room + [offsetMs], within 7 days either way. */
    fun setOffset(offsetMs: Long) = guard {
        party?.setOffset(offsetMs.coerceIn(-WatchPartyRelays.MAX_OFFSET_MS, WatchPartyRelays.MAX_OFFSET_MS))
    }

    // Presses: each returns true when the room took it, and the player must then be left alone.

    private fun routes(): Boolean = isFollowing && party != null

    private fun refuseWithoutControl(): Boolean {
        if (canControl) return false
        notify(WatchNotice.ControlRefused)
        return true
    }

    /** False while the player refused to start in a playing room: the press then starts the player itself. */
    fun play(): Boolean {
        if (!routes()) return false
        if (playBlocked && snapshot.room?.phase == Phase.PLAYING) {
            playBlocked = false
            publish()
            return false
        }
        if (refuseWithoutControl()) return true
        guard { party!!.play() }
        return true
    }

    /** Starts the player that refused to start in a playing room, from its own prompt. Refused again, it stays blocked. */
    suspend fun playBlockedPlayer() {
        val adapter = player?.adapter
        if (!playBlocked || adapter == null || !follows(adapter)) return
        playBlocked = false
        publish()
        try {
            adapter.player.play()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            if (closed || !follows(adapter)) return
            notify(blocked(e))
        }
    }

    fun pause(): Boolean {
        if (!routes()) return false
        if (refuseWithoutControl()) return true
        guard { party!!.pause() }
        return true
    }

    /** [positionMs] is in this user's own file. */
    fun seek(positionMs: Long): Boolean {
        if (!routes()) return false
        if (refuseWithoutControl()) return true
        guard { party!!.seek(positionMs.coerceAtLeast(0)) }
        return true
    }

    fun setRate(rate: Double): Boolean {
        if (!routes()) return false
        if (refuseWithoutControl()) return true
        guard { party!!.setRate(rate.coerceIn(WatchPartyRelays.MIN_RATE, WatchPartyRelays.MAX_RATE)) }
        return true
    }

    /**
     * Ends the room's media for everyone: the room seeks to its end and holds there ([WatchSnapshot.atMediaEnd]), and
     * the host's app decides what plays next. Nothing happens once the room is at its end.
     */
    fun endMedia(): Boolean {
        if (!routes()) return false
        if (refuseWithoutControl()) return true
        val media = partyState.media ?: return true
        if (snapshot.atMediaEnd) return true
        // The party takes this user's own position: the room's end, shifted by the offset.
        guard { party!!.seek((media.durationMs + partyState.offsetMs).coerceAtLeast(0)) }
        return true
    }

    // The player

    /** The open player screen registers how the room switches it to another file and closes it. */
    fun registerPlayer(owner: Any, hooks: WatchPlayerHooks) {
        playerHooksOwner = owner
        playerHooks = hooks
    }

    fun unregisterPlayer(owner: Any) {
        if (playerHooksOwner !== owner) return
        playerHooksOwner = null
        playerHooks = null
    }

    /**
     * The player opened [adapter]'s file. [shareable] is false for files the room can't get (a download of an offline
     * server). [roomLaunch] is true when the room asked for this file.
     *
     * A host shares the file with the room. A guest's player follows the room when it opened the room's file or another
     * version of it, and else sits out so the room doesn't wait for it.
     */
    fun playerOpened(adapter: PlezyPlayerAdapter, shareable: Boolean, roomLaunch: Boolean) {
        val previous = player?.adapter
        if (previous != null && previous !== adapter) previous.release()
        player = OpenPlayer(adapter, shareable)
        adapter.player.onChanged = { playerChanged(adapter) }
        val party = party
        if (party == null || isAway) return publish()
        val copy = adapter.copy
        if (!isConnected) {
            party.attachPlayer(adapter, copy)
            attached = true
            return publish()
        }
        if (isHost) {
            if (!shareable) {
                // The room keeps its media; this file plays on its own meanwhile.
                attached = false
                party.detachPlayer()
                notify(WatchNotice.NotShared)
            } else {
                party.attachPlayer(adapter, copy)
                attached = true
                val choice = partyState.choice
                if (!(choice?.ref == copy && choice.id.isEmpty())) scope.launch { shareCopy(adapter, adapter.positionMs) }
            }
            return publish()
        }
        val media = snapshot.media
        val choice = partyState.choice?.ref
        val otherVersion = choice != null && choice.serverId == copy.serverId && choice.itemId == copy.itemId
        when {
            choice == copy -> {
                party.attachPlayer(adapter, copy)
                attached = true
            }
            (roomLaunch || otherVersion) && media != null && copy.item != null -> {
                // The room asked for this file, or the user switched the version the room picked: this file becomes the
                // user's pick for the room's media.
                party.attachPlayer(adapter, copy)
                attached = true
                scope.launch { chooseOpened(party, adapter) }
            }
            else -> {
                attached = false
                party.detachPlayer()
            }
        }
        publish()
    }

    /**
     * Picks the file [adapter] has open for the room's media. When the party refuses it (its length is unknown), the
     * player sits out: attached to a file the room never commands, it would keep the room waiting for it.
     */
    private suspend fun chooseOpened(party: WatchParty<WatchCopy>, adapter: PlezyPlayerAdapter) {
        val copy = adapter.copy
        val epoch = party.state.value.room?.epoch
        val generation = chooseGeneration + 1 // choose() bumps it before its first suspension
        if (chooseCopy(copy.item ?: return, copy.version)) return
        // A later choice or a new epoch's search decides what this player follows.
        if (closed || this.party !== party || generation != chooseGeneration) return
        if (party.state.value.room?.epoch != epoch || !attached || player?.adapter !== adapter) return
        attached = false
        party.detachPlayer(adapter)
        notify(WatchNotice.ChoiceFailed)
        publish()
    }

    /**
     * The player is going away. A host's media stops for everyone unless [continuing] (another player takes over, such
     * as the next episode). The job completes once the party no longer commands [adapter]: dispose of the player after.
     */
    fun playerClosed(adapter: PlezyPlayerAdapter, continuing: Boolean): Job {
        adapter.release()
        adapter.player.onChanged = null
        if (player?.adapter !== adapter) return Job().apply { complete() }
        player = null
        attached = false
        playBlocked = false
        val party = party ?: return Job().apply { complete() }.also { publish() }
        val choice = partyState.choice
        if (!continuing && isConnected && isHost && choice?.ref == adapter.copy && choice.id.isEmpty()) guard { party.clearMedia() }
        val released = party.detachPlayer(adapter)
        publish()
        return released
    }

    /** The user is [away] for [reason] (or back): the room stops waiting for them meanwhile, and catches up on return. */
    fun setAway(reason: WatchAway, away: Boolean) {
        val wasAway = isAway
        if (away) this.away += reason else this.away -= reason
        val party = party
        val open = player
        when {
            wasAway == isAway || party == null -> Unit
            isAway -> {
                if (open != null) party.detachPlayer(open.adapter)
                attached = false
            }
            open != null -> playerOpened(open.adapter, open.shareable, roomLaunch = false)
        }
        publish()
    }

    /** Whether the user is away for [reason]. */
    fun isAway(reason: WatchAway): Boolean = reason in away

    /** The player's state changed: the party reads it now. */
    fun playerChanged(adapter: PlezyPlayerAdapter) {
        if (attached && player?.adapter === adapter) party?.playerChanged()
    }

    /**
     * Host: shares the file [adapter] has open with the room, starting at [positionMs]. Waits up to [shareDurationWait]
     * for the player's length when the server has none. When the room can't get it, the room's media stops and the host
     * is told.
     */
    suspend fun shareCopy(adapter: PlezyPlayerAdapter, positionMs: Long = 0): Boolean {
        val party = party
        val copy = adapter.copy
        if (party == null || !isHost || copy.item == null) return false
        val generation = ++shareGeneration
        val current = { !closed && this.party === party && generation == shareGeneration && isHost && !adapter.isReleased }
        val backend = clientFor(copy.serverId) ?: return shareFailed(party, current)
        var result = MediaDescriptor.describe(backend, copy, adapter.durationMs)
        if (result.failure == DescribeFailure.NO_DURATION) {
            val waited = timeSource.markNow()
            while (current() && adapter.durationMs == null && waited.elapsedNow() < shareDurationWait) delay(DURATION_POLL)
            if (!current()) return false
            result = MediaDescriptor.describe(backend, copy, adapter.durationMs)
        }
        if (!current()) return false
        val media = result.media ?: return shareFailed(party, current)
        return try {
            party.setMedia(media, copy, positionMs.coerceAtLeast(0))
            true
        } catch (e: PartyException) {
            Log.w(TAG) { "setMedia refused: ${e.code} ${e.message}" }
            shareFailed(party, current)
        }
    }

    private fun shareFailed(party: WatchParty<WatchCopy>, current: () -> Boolean): Boolean {
        if (!current()) return false
        notify(WatchNotice.ShareFailed)
        if (partyState.media != null) guard { party.clearMedia() }
        return false
    }

    /** Opens the room's file for this user ("Join Current Playback"). */
    suspend fun openRoomCopy(): Boolean {
        val copy = roomCopy ?: return false
        openedKey = copy.keyIn(partyState.room)
        return open(copy.ref)
    }

    // The party's streams

    private fun onState(next: PartyState<WatchCopy>) {
        val previous = partyState
        val wasFollowing = isFollowing
        partyState = next
        if (next.connection != previous.connection) {
            val reason = if (next.connection == Connection.ENDED) " (${next.endReason})" else ""
            Log.i(TAG) { "connection ${next.connection}$reason" }
        }
        if (next.connection == Connection.ENDED || next.room?.phase != Phase.PLAYING) playBlocked = false
        // The room stopped the media this guest was watching with it.
        if (wasFollowing && previous.media != null && next.media == null && next.connection == Connection.CONNECTED && !next.isHost) {
            playerHooks?.exitPlayer?.invoke()
        }
        openChoice()
        publish()
    }

    /** Opens a new choice once per epoch and file. The party's own media (id `""`) is offered, never reopened by itself. */
    private fun openChoice() {
        val choice = partyState.choice ?: return
        if (choice.id.isEmpty() || isAway || partyState.connection != Connection.CONNECTED) return
        if (player?.adapter?.copy == choice.ref) return
        val key = choice.keyIn(partyState.room)
        if (key == openedKey) return
        openedKey = key
        scope.launch { open(choice.ref) }
    }

    private suspend fun open(copy: WatchCopy): Boolean {
        val opener = playerHooks?.openInPlace ?: navigatorOpener
        var opening = false
        try {
            opening = opener != null && opener(copy)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "could not open $copy" }
        }
        if (!opening && !closed && player == null && partyState.connection == Connection.CONNECTED) {
            notify(WatchNotice.OpenFailed)
            party?.detachPlayer()
        }
        return opening
    }

    private fun onEvent(party: WatchParty<WatchCopy>, event: PartyEvent) {
        val notice = when (event) {
            is PartyEvent.Action -> if (event.byMe) {
                null
            } else {
                WatchNotice.Action(
                    kind = event.kind,
                    name = event.by?.name,
                    positionMs = if (event.kind == "seek") event.room.positionMs + partyState.offsetMs else null,
                    rate = if (event.kind == "rate") event.room.rate else null,
                )
            }
            is PartyEvent.ParticipantJoined -> WatchNotice.Joined(event.participant.name)
            is PartyEvent.ParticipantLeft -> WatchNotice.Left(event.participant.name)
            is PartyEvent.Error -> refused(event.error)
            is PartyEvent.ResolveFailed -> resolveFailed(party, event.error)
            is PartyEvent.PlayBlocked -> blocked(event.error)
            is PartyEvent.Ended -> ended(party, event.reason, event.error)
            else -> null
        }
        if (notice != null) notify(notice)
    }

    private fun resolveFailed(party: WatchParty<WatchCopy>, error: Throwable): WatchNotice {
        Log.w(TAG, error) { "library search failed" }
        // The search ran for the party's current media, whose snapshot may not have reached [partyState] yet.
        searchFailedEpoch = party.state.value.room?.epoch
        publish()
        return WatchNotice.SearchFailed
    }

    private fun refused(error: PartyException): WatchNotice {
        Log.d(TAG) { "${error.code}: ${error.message}" }
        return WatchNotice.Refused(error.code)
    }

    private fun blocked(error: Throwable): WatchNotice {
        Log.d(TAG) { "the player refused to start: ${error.message}" }
        playBlocked = true
        publish()
        return WatchNotice.PlayBlocked
    }

    /** [error] says why a [EndReason.LOST] room could not be resumed. */
    private fun ended(party: WatchParty<WatchCopy>, reason: EndReason, error: PartyException?): WatchNotice? {
        if (error != null) Log.w(TAG) { "room lost: ${error.code}: ${error.message}" }
        attached = false
        // A player that keeps its file open is the next party's to attach.
        scope.launch {
            if (this@WatchTogether.party === party && party.state.value.connection == Connection.ENDED) closeParty()
        }
        return if (reason == EndReason.LEFT) null else WatchNotice.Ended(reason)
    }

    private fun notify(notice: WatchNotice) {
        if (!closed) mutableNotices.tryEmit(notice)
    }

    private fun closeParty() {
        val party = party ?: return
        this.party = null
        attached = false
        partyJobs.forEach(Job::cancel)
        partyJobs = emptyList()
        // The last state stays readable (the end reason) until the next party.
        partyState = party.state.value
        party.close()
        publish()
    }

    private fun publish() {
        if (closed) return
        val open = player
        val copy = roomCopy(partyState)
        mutableState.value = WatchSnapshot(
            party = partyState,
            following = isFollowing,
            canJoinPlayback = partyState.connection == Connection.CONNECTED && copy != null && partyState.media != null &&
                (open == null || open.adapter.copy != copy.ref),
            playBlocked = playBlocked,
            searchFailed = searchFailedEpoch != null && searchFailedEpoch == partyState.room?.epoch,
            relayBaseUrl = relayBaseUrl.value,
            pausedHere = WatchAway.PAUSED_HERE in away,
            chosen = chosen,
        )
    }

    private fun roomCopy(state: PartyState<WatchCopy>): Candidate<WatchCopy>? = WatchSnapshot(party = state).roomCopy

    /** Leaves the room at once and closes the party: the profile session is over. */
    fun close() {
        if (closed) return
        player?.adapter?.release()
        player = null
        closeParty()
        closed = true
    }

    private companion object {
        const val TAG = "WatchTogether"
        const val NOTICE_BUFFER = 64
        val DURATION_POLL = 250.milliseconds
    }
}

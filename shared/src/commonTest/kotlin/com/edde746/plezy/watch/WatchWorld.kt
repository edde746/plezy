@file:OptIn(ExperimentalCoroutinesApi::class)

package com.edde746.plezy.watch

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.inMemoryDatabase
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPart
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.TitleQuery
import com.edde746.plezy.servers.LibraryLookupResult
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.yield
import party.openwatch.MonotonicClock
import party.openwatch.Participant
import party.openwatch.PartyException
import party.openwatch.Relays
import party.openwatch.WatchParty
import kotlin.test.fail
import kotlin.time.Clock
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Instant

/**
 * A player the room drives in tests: its state, which commands change (a play plays, a seek lands with a restart unless
 * [emitRestartOnSeek] is off), and the commands it got ([commandLog]: `play`, `pause`, `seek:<ms>`, `rate:<rate>`).
 */
internal class FakeRoomPlayer(
    override var positionMs: Long = 0,
    override var durationMs: Long? = 45 * 60_000L,
    override var playing: Boolean = false,
    override var buffering: Boolean = false,
    override var seekable: Boolean = true,
    override var renderedFrame: Boolean = false,
) : RoomPlayer {
    override var loadId = 0L
    override var audioPassthrough = false
    override var disposed = false
    override var restarts = 0
    override var onChanged: (() -> Unit)? = null
    val commandLog = mutableListOf<String>()
    var rate = 1.0

    /** The next command throws this. */
    var nextCommandError: Throwable? = null

    /** The next command waits for this. */
    var nextCommand: CompletableDeferred<Unit>? = null
    var emitRestartOnSeek = true

    /** Play throws while this says so, as a car or a browser refusing to start would. */
    var refusePlay: () -> Boolean = { false }

    private suspend fun command(name: String) {
        commandLog += name
        nextCommandError?.let {
            nextCommandError = null
            throw it
        }
        nextCommand?.let {
            nextCommand = null
            it.await()
        }
    }

    override suspend fun play() {
        command("play")
        if (refusePlay()) throw IllegalStateException("playback refused")
        playing = true
        onChanged?.invoke()
    }

    override suspend fun pause() {
        command("pause")
        playing = false
        onChanged?.invoke()
    }

    override suspend fun seek(positionMs: Long) {
        command("seek:$positionMs")
        this.positionMs = positionMs
        if (emitRestartOnSeek) emitPlaybackRestart()
    }

    override suspend fun setRate(rate: Double) {
        command("rate:$rate")
        this.rate = rate
    }

    fun emitPlaybackRestart() {
        renderedFrame = true
        restarts++
        onChanged?.invoke()
    }

    fun emitDuration(ms: Long) {
        durationMs = ms
        onChanged?.invoke()
    }

    /** The engine takes a new load of [loadId]: nothing of it is reported yet, the position still the old file's. */
    fun startLoad(loadId: Long) {
        this.loadId = loadId
        renderedFrame = false
        restarts = 0
        onChanged?.invoke()
    }

    /** The load's first frame, at [positionMs]. */
    fun showFirstFrame(positionMs: Long) {
        this.positionMs = positionMs
        emitPlaybackRestart()
    }
}

internal const val ALIEN_MS = 7_020_000L

internal fun alien(id: String, serverId: String, durationMs: Long? = ALIEN_MS, version: String = "hd") = MediaItem(
    id = id,
    backend = BackendKind.PLEX,
    kind = MediaKind.MOVIE,
    title = "Alien",
    year = 1979,
    durationMs = durationMs,
    serverId = serverId,
    mediaVersions = listOf(
        MediaVersion(id = version, parts = listOf(MediaPart(id = "$version-p", durationMs = durationMs, sizeBytes = 4_000_000, file = "/m/Alien.mkv"))),
    ),
)

internal fun copyOf(item: MediaItem) = WatchCopy.of(item, item.mediaVersions?.first())

internal val hostAlien = alien("alien", "host-nas")
internal val guestAlien = alien("g-alien", "guest-nas", durationMs = ALIEN_MS + 800, version = "g-hd")

internal fun lookup(items: List<MediaItem>, succeeded: Set<String> = emptySet(), failed: Set<String> = emptySet()) =
    LibraryLookupResult(items, succeeded.mapTo(HashSet(), ::ServerId), emptySet(), failed.mapTo(HashSet(), ::ServerId), emptySet())

/** A player with [copy] open, as the player screen hands it to the room. */
internal class OpenPlayer(val adapter: PlezyPlayerAdapter, val player: FakeRoomPlayer)

/** A participant's Watch Together and every notice it gave. */
internal class Member(val watch: WatchTogether, world: WatchWorld) {
    val notices = mutableListOf<WatchNotice>()

    init {
        world.test.backgroundScope.launch(start = CoroutineStart.UNDISPATCHED) { watch.notices.collect { notices += it } }
    }

    val peerId: String get() = watch.state.value.myPeerId!!
    val state: WatchSnapshot get() = watch.state.value

    fun participant(peerId: String): Participant = state.participants.first { it.peerId == peerId }

    inline fun <reified T : WatchNotice> noticesOf(): List<T> = notices.filterIsInstance<T>()
}

/** The player screen the app opens for the room: it opens the room's file when asked and reports the player. */
internal class Screen(private val member: Member, private val world: WatchWorld) {
    val players = mutableListOf<OpenPlayer>()
    var exits = 0
    var refusePlay = false

    /** Opens the files the room asks for from now on. */
    fun listen() {
        member.watch.navigatorOpener = ::open
    }

    suspend fun open(copy: WatchCopy): Boolean {
        // A route push: the player reports back after the room's update.
        yield()
        val opened = world.openPlayer(copy, refusePlay = { refusePlay })
        players += opened
        member.watch.registerPlayer(this, WatchPlayerHooks(::open) { exits++ })
        member.watch.playerOpened(opened.adapter, shareable = true, roomLaunch = true)
        return true
    }
}

/**
 * Participants on one [FakeOwpRelay] in the test's virtual time: the host with Alien on `host-nas`, guests with their
 * own copy on `guest-nas`.
 */
internal class WatchWorld(val test: TestScope) {
    private val dispatcher = StandardTestDispatcher(test.testScheduler)
    val relay = FakeOwpRelay(test.backgroundScope, dispatcher) { test.testScheduler.currentTime }
    val data = LocalData(inMemoryDatabase(), { 0L }, dispatcher)
    private var wallMs = 1_000_000L
    val recentRooms = RecentRoomsService(data.profileSettings, object : Clock {
        override fun now(): Instant = Instant.fromEpochMilliseconds(wallMs++)
    })
    val relayBaseUrl = MutableStateFlow<String?>(null)
    val guestQueries = mutableListOf<TitleQuery>()
    var guestAnswer: suspend (TitleQuery) -> LibraryLookupResult = { lookup(listOf(guestAlien), succeeded = setOf("guest-nas")) }
    val hostServer = FakeMediaBackend("host-nas").apply {
        externalIds = { id -> if (id == "alien") ExternalIds(imdb = "tt0078748", tmdb = 348) else ExternalIds() }
        items = { null }
    }
    private val members = mutableListOf<Member>()

    fun member(
        name: String,
        profileScope: String? = null,
        clientFor: (String) -> MediaBackend? = { null },
        findCopies: suspend (TitleQuery) -> LibraryLookupResult = { lookup(emptyList()) },
        shareDurationWait: Duration = 30.seconds,
    ): Member {
        val watch = WatchTogether(
            client = CLIENT,
            displayName = { name },
            profileScope = profileScope,
            relayBaseUrl = relayBaseUrl,
            relaysFor = { Relays.at(relay.http, RELAY) },
            recentRooms = recentRooms,
            clientFor = clientFor,
            findCopies = findCopies,
            scope = test.backgroundScope,
            newParty = { _, client, partyName, resolver ->
                WatchParty(
                    relays = Relays.at(relay.http, RELAY),
                    client = client,
                    name = partyName,
                    resolver = resolver,
                    scope = test.backgroundScope,
                    clock = MonotonicClock { test.testScheduler.currentTime },
                )
            },
            shareDurationWait = shareDurationWait,
            timeSource = test.testScheduler.timeSource,
        )
        return Member(watch, this).also { members += it }
    }

    fun host(profileScope: String? = null, shareDurationWait: Duration = 30.seconds) =
        member("Host", profileScope, clientFor = { if (it == "host-nas") hostServer else null }, shareDurationWait = shareDurationWait)

    fun guest(name: String = "Guest", profileScope: String? = null) = member(name, profileScope, findCopies = { query ->
        guestQueries += query
        guestAnswer(query)
    })

    fun openPlayer(copy: WatchCopy, durationMs: Long? = copy.durationMs, refusePlay: () -> Boolean = { false }): OpenPlayer {
        val player = FakeRoomPlayer(renderedFrame = true, durationMs = durationMs)
        player.refusePlay = refusePlay
        return OpenPlayer(PlezyPlayerAdapter(player, copy, test.testScheduler.timeSource), player)
    }

    /** Runs the test's time in 20 ms steps until [check] holds. */
    fun until(what: String, check: () -> Boolean) {
        repeat(STEPS) {
            if (check()) return
            test.advanceTimeBy(STEP_MS)
            test.runCurrent()
        }
        if (!check()) fail("timed out waiting until $what")
    }

    fun runFor(ms: Long) {
        test.advanceTimeBy(ms)
        test.runCurrent()
    }

    /** [block], with time running until it completes; its failure is thrown here. */
    fun <T> settle(block: suspend () -> T): T {
        val call = test.backgroundScope.async { runCatching { block() } }
        until("the call completed") { call.isCompleted }
        return call.getCompleted().getOrThrow()
    }

    /** The code of the [PartyException] [block] fails with; null when it completes. */
    fun refusal(block: suspend () -> Unit): String? = try {
        settle(block)
        null
    } catch (e: PartyException) {
        e.code
    }

    inline fun <reified T : WatchNotice> noticed(member: Member, what: String, crossinline test: (T) -> Boolean = { true }) =
        until(what) { member.noticesOf<T>().any { test(it) } }

    fun together(host: Member, guests: List<Member>) {
        val code = settle { host.watch.createRoom() }
        for (guest in guests) settle { guest.watch.joinRoom(code) }
        val everyone = listOf(host) + guests
        until("everyone sees ${everyone.size} participants") { everyone.all { it.state.participants.size == everyone.size } }
    }

    /** The host opens [item]; returns once the room plays it. */
    fun hostPlays(host: Member, item: MediaItem): OpenPlayer {
        val opened = openPlayer(copyOf(item))
        host.watch.playerOpened(opened.adapter, shareable = true, roomLaunch = false)
        until("the room plays the host file") { host.state.roomCopy?.ref == opened.adapter.copy }
        return opened
    }

    class Following(val host: Member, val guest: Member, val hostPlayer: OpenPlayer, val screen: Screen)

    /** A room whose host plays Alien and whose guest follows it with its own copy. */
    fun following(): Following {
        val h = host()
        val g = guest()
        val screen = Screen(g, this).also { it.listen() }
        together(h, listOf(g))
        val hostPlayer = hostPlays(h, hostAlien)
        until("the guest follows the room") { g.watch.isFollowing }
        return Following(h, g, hostPlayer, screen)
    }

    /** Closes every participant and lets their parties close. */
    fun close() {
        members.forEach { it.watch.close() }
        runFor(300)
        data.close()
    }

    companion object {
        const val CLIENT = "Plezy/9.9.9"
        const val RELAY = "http://relay.test"
        private const val STEPS = 500
        private const val STEP_MS = 20L
    }
}

/** Runs [body] in a [WatchWorld], closing it after. */
internal fun TestScope.watchWorld(body: WatchWorld.() -> Unit) {
    val world = WatchWorld(this)
    try {
        world.body()
    } finally {
        world.close()
    }
}

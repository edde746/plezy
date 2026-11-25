package com.edde746.plezy.music

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.inMemoryDatabase
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.playback.report.OfflineProgressQueue
import com.edde746.plezy.playback.source.PlaybackReportingMode
import com.edde746.plezy.presentation.player.DiscordActivity
import com.edde746.plezy.presentation.player.DiscordPresenceHost
import com.edde746.plezy.presentation.player.MediaCommand
import com.edde746.plezy.presentation.player.MediaCommandHandler
import com.edde746.plezy.presentation.player.MediaControlsHost
import com.edde746.plezy.presentation.player.NowPlaying
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlin.random.Random
import kotlin.time.Duration

fun urlFor(track: MediaItem) = "fake://${track.id}"

data class RecordedReport(val state: String, val itemId: String, val position: Duration, val duration: Duration?)

/** A server that records the playback reports and marks; [instantMixGate] holds the mix fetch. */
class RecordingBackend(serverId: String = "srv") : FakeMediaBackend(serverId) {
    val reports = mutableListOf<RecordedReport>()
    val markedWatched = mutableListOf<String>()
    var instantMixGate: CompletableDeferred<List<MediaItem>>? = null

    fun reportsFor(state: String) = reports.filter { it.state == state }

    override suspend fun reportPlaybackStarted(
        itemId: String, position: Duration, duration: Duration?, playSessionId: String?, playMethod: String?,
        liveStreamId: String?, mediaSourceId: String?, audioStreamIndex: Int?, subtitleStreamIndex: Int?,
    ) {
        reports += RecordedReport("started", itemId, position, duration)
    }

    override suspend fun reportPlaybackProgress(
        itemId: String, position: Duration, duration: Duration, isPaused: Boolean, playSessionId: String?, playMethod: String?,
        liveStreamId: String?, mediaSourceId: String?, audioStreamIndex: Int?, subtitleStreamIndex: Int?,
    ) {
        reports += RecordedReport(if (isPaused) "paused" else "progress", itemId, position, duration)
    }

    override suspend fun reportPlaybackStopped(
        itemId: String, position: Duration, duration: Duration?, playSessionId: String?, liveStreamId: String?,
        mediaSourceId: String?, audioStreamIndex: Int?, subtitleStreamIndex: Int?, report: com.edde746.plezy.backend.PlaybackReportMetadata,
    ) {
        reports += RecordedReport("stopped", itemId, position, duration)
    }

    override suspend fun markWatched(item: MediaItem) {
        markedWatched += item.id
    }

    override suspend fun fetchInstantMix(itemId: String, limit: Int): List<MediaItem> = instantMixGate?.await() ?: emptyList()
}

class FakeMusicSourceResolver(private val backend: RecordingBackend?) : MusicSourceResolver {
    val failingIds = mutableSetOf<String>()
    val resolveCounts = mutableMapOf<String, Int>()

    /** Every resolve's track id and whether it asked for a local copy only, in order. */
    val resolves = mutableListOf<Pair<String, Boolean>>()
    val urlOverrides = mutableMapOf<String, String>()

    /** Where a track's reports go; the server's by default. */
    val reporting = mutableMapOf<String, PlaybackReportingMode>()
    private val gates = mutableMapOf<String, ArrayDeque<CallGate>>()

    /** Holds the next resolve of [trackId]. */
    var gate: CompletableDeferred<Unit>? = null

    fun gateNextResolve(trackId: String): CallGate = CallGate().also { gates.getOrPut(trackId) { ArrayDeque() }.addLast(it) }

    override suspend fun resolve(track: MediaItem, offline: Boolean): MusicSource {
        resolveCounts[track.id] = (resolveCounts[track.id] ?: 0) + 1
        resolves += track.id to offline
        gates[track.id]?.removeFirstOrNull()?.block()
        gate?.await()
        if (track.id in failingIds) error("resolve failed for ${track.id}")
        return MusicSource(
            url = urlOverrides[track.id] ?: urlFor(track),
            playSessionId = "ps-${track.id}",
            playMethod = "DirectPlay",
            reporting = reporting[track.id] ?: PlaybackReportingMode.ONLINE,
            reportingBackend = backend,
        )
    }
}

/** The OS media controls: records what they show; [send] is an OS command. */
class FakeControlsHost : MediaControlsHost {
    val shows = mutableListOf<NowPlaying>()
    var hides = 0
    var userPauses = 0
    private var handler: MediaCommandHandler? = null

    val last: NowPlaying get() = shows.last()

    override fun show(nowPlaying: NowPlaying, commands: MediaCommandHandler) {
        shows += nowPlaying
        handler = commands
    }

    override fun hide() {
        hides++
        handler = null
    }

    override fun userPaused() {
        userPauses++
    }

    fun send(command: MediaCommand) = checkNotNull(handler) { "no controls up" }.perform(command)
}

/** The car service: answers [answer] (null: can't answer) and pushes with [push]. */
class FakeCarSource(var answer: CarRestrictionState? = null) : CarRestrictionsSource {
    val calls = mutableListOf<String>()

    /** Holds the answers while not null; they all land when it completes. */
    var answerGate: CompletableDeferred<Unit>? = null
    var neverAnswer = false
    private var listener: ((CarRestrictionState) -> Unit)? = null
    private val waiting = mutableListOf<(CarRestrictionState?) -> Unit>()

    override fun currentState(callback: (CarRestrictionState?) -> Unit) {
        calls += "getState"
        if (neverAnswer) return
        if (answerGate != null) waiting += callback else callback(answer)
    }

    override fun setListener(listener: ((CarRestrictionState) -> Unit)?) {
        this.listener = listener
    }

    fun releaseAnswers() {
        answerGate = null
        waiting.toList().forEach { it(answer) }
        waiting.clear()
    }

    fun push(state: CarRestrictionState) {
        answer = state
        listener?.invoke(state)
    }

    companion object {
        val PARKED = CarRestrictionState(supported = true, requiresDistractionOptimization = false, pending = false)
        val DRIVING = CarRestrictionState(supported = true, requiresDistractionOptimization = true, pending = false)
        val GONE = CarRestrictionState(supported = false, requiresDistractionOptimization = true, pending = false)
        val CONNECTING = CarRestrictionState(supported = false, requiresDistractionOptimization = true, pending = true)
    }
}

class FakeMusicSystem(override val car: CarRestrictionsSource? = null) : MusicSystem {
    var keyHandler: ((MusicKey, KeyPhase) -> Boolean)? = null
    override fun setHardwareKeyHandler(handler: ((MusicKey, KeyPhase) -> Boolean)?) {
        keyHandler = handler
    }

    /** A key's down, repeat and up: whether each was consumed. */
    fun press(key: MusicKey): List<Boolean> =
        listOf(KeyPhase.DOWN, KeyPhase.REPEAT, KeyPhase.UP).map { keyHandler?.invoke(key, it) ?: false }
}

class FakeDiscordHost : DiscordPresenceHost {
    val published = mutableListOf<DiscordActivity?>()
    val activities get() = published.filterNotNull()
    val clears get() = published.count { it == null }

    override fun publish(activity: DiscordActivity?) {
        published += activity
    }
}

/** Every-draw-lowest randomness: a deterministic shuffle that doesn't keep the head. */
object LowestRandom : Random() {
    override fun nextBits(bitCount: Int): Int = 0
}

/** Test data whose database runs on the test's scheduler. */
fun TestScope.musicData(): LocalData = LocalData(inMemoryDatabase(), { 1_790_000_000_000L }, StandardTestDispatcher(testScheduler))

/** A music session over fakes, in [test]'s background scope. */
class MusicHarness(
    private val test: TestScope,
    val data: LocalData = test.musicData(),
    sessionStore: MusicSessionStore? = null,
    val foreground: MutableStateFlow<Boolean> = MutableStateFlow(true),
    car: CarRestrictionsSource? = null,
    formFactor: FormFactor = FormFactor.HANDHELD,
    appleAudioOutput: Boolean = false,
    discord: DiscordPresenceHost? = null,
    volumeWriter: (suspend (Double) -> Unit)? = null,
    random: Random = Random.Default,
    resolver: FakeMusicSourceResolver? = null,
    val coordinator: PlaybackCoordinator = PlaybackCoordinator(),
) {
    val backend = RecordingBackend()
    val resolver = resolver ?: FakeMusicSourceResolver(backend)
    val controls = FakeControlsHost()
    val system = FakeMusicSystem(car)
    val players = mutableListOf<FakeAudioPlayer>()

    /** Seeded into every new player. */
    val failingSetNextUris = mutableSetOf<String>()

    val player: FakeAudioPlayer get() = players.last()

    /** What went to the offline queue: item id and offset, in milliseconds. */
    val offlineQueued = mutableListOf<Pair<String, Long>>()

    val service = MusicPlaybackService(
        scope = test.backgroundScope,
        audioPlayerFactory = { FakeAudioPlayer().also { it.failingSetNextUris += failingSetNextUris; players += it } },
        resolver = this.resolver,
        clients = { if (it == ServerId("srv")) backend else null },
        settings = data.deviceSettings,
        coordinator = coordinator,
        foreground = foreground,
        formFactor = formFactor,
        appleAudioOutput = appleAudioOutput,
        system = system,
        controls = controls,
        discord = discord,
        sessionStore = sessionStore,
        offlineQueue = OfflineProgressQueue { _, itemId, viewOffsetMs, _ -> offlineQueued += itemId to viewOffsetMs },
        timeSource = test.testScheduler.timeSource,
        completedConfirmDelay = Duration.ZERO,
        volumeWriter = volumeWriter ?: {},
        random = random,
    )

    val state: MusicState get() = service.state.value

    fun pump() = test.runCurrent()

    suspend fun playTracks(tracks: List<MediaItem>, startTrack: MediaItem? = null, shuffle: Boolean = false) {
        service.playFromList(tracks, startTrack, MusicPlayContext("Test", MusicPlayContextKind.ALBUM), shuffle)
        pump()
    }
}

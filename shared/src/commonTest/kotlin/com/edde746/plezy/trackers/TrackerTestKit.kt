@file:OptIn(ExperimentalCoroutinesApi::class)

package com.edde746.plezy.trackers

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.TestClock
import com.edde746.plezy.data.inMemoryDatabase
import com.edde746.plezy.data.settings.DeviceSetting
import com.edde746.plezy.data.tracker.TrackerWriteRequest
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.secrets.MemorySecretStore
import com.edde746.plezy.secrets.SecretStore
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.delay
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.serialization.json.JsonObject
import kotlin.time.Clock
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Instant

/** One call a fake tracker received, at virtual time [atMillis]. */
internal data class Call(val service: TrackerService, val op: String, val atMillis: Long, val context: TrackerContext? = null)

/**
 * A fake tracker service for one connection: it records every call on the shared [log] (so tests see the order across
 * services) and fails or stalls as a test asks. Each call takes its access token from [credentials] before it goes
 * out, as a real tracker's requests do, and [latency] is the time the service then takes to answer.
 */
internal open class FakeTracker(
    override val service: TrackerService,
    private val scope: TestScope,
    private val log: MutableList<Call>,
    val credentials: TrackerCredentials,
) : Rating {
    override val needsAnimeIds: Boolean get() = false
    override val writeSpacing: Duration get() = if (service == TrackerService.TRAKT) 1.seconds else Tracker.DEFAULT_WRITE_SPACING

    /**
     * What the next calls throw, by operation prefix (`scrobble`, `watched`, `unwatched`, `reconcile`, `rating`, `rate`,
     * `unrate`); consumed in order.
     */
    val failures = mutableMapOf<String, ArrayDeque<Throwable>>()

    /** The account's scores, by the title as [ratingId] names it. */
    val scores = mutableMapOf<String, Int>()

    /** How long each call takes. */
    var latency: Duration = Duration.ZERO

    fun failNext(op: String, vararg errors: Throwable) {
        failures.getOrPut(op) { ArrayDeque() }.addAll(errors)
    }

    protected suspend fun call(op: String, detail: String, context: TrackerContext?) {
        credentials.accessToken()
        if (latency > Duration.ZERO) delay(latency)
        log += Call(service, if (detail.isEmpty()) op else "$op $detail", scope.testScheduler.currentTime, context)
        failures[op]?.removeFirstOrNull()?.let { throw it }
    }

    override suspend fun markWatched(context: TrackerContext, watchedAt: Instant?) =
        call("watched", "${name(context)}${watchedAt?.let { " at=${it.toEpochMilliseconds()}" }.orEmpty()}", context)

    override suspend fun markUnwatched(context: TrackerContext) = call("unwatched", name(context), context)

    /** The title as the service names it: its kind and external ids, as [ExternalIds.rowIdentity] picks one. */
    protected open fun ratingId(target: RatingTarget): String =
        "${target.kind.name.lowercase()} ${target.ids.rowIdentity() ?: throw TrackerException.Unsupported(service, "rating without ids")}"

    override suspend fun rating(target: RatingTarget): Int? {
        val id = ratingId(target)
        call("rating", id, null)
        return scores[id]
    }

    override suspend fun rate(target: RatingTarget, score: Int) {
        val id = ratingId(target)
        call("rate", "$id $score", null)
        scores[id] = score
    }

    override suspend fun clearRating(target: RatingTarget) {
        val id = ratingId(target)
        call("unrate", id, null)
        scores.remove(id)
    }
}

/** Trakt, Simkl or MDBList: live reports and per-item history. */
internal class FakeRealtimeTracker(service: TrackerService, scope: TestScope, log: MutableList<Call>, credentials: TrackerCredentials) :
    FakeTracker(service, scope, log, credentials), RealtimeScrobble, EpisodeHistory {
    override val scrobblePolicy: ScrobblePolicy = when (service) {
        TrackerService.SIMKL -> ScrobblePolicy(resendThrottle = 20.seconds, seekThrottle = null)
        else -> ScrobblePolicy(resendThrottle = 30.seconds, seekThrottle = 5.seconds)
    }

    override suspend fun scrobble(context: TrackerContext, state: ScrobbleState, progressPercent: Double) =
        call("scrobble", "${state.name} ${progressPercent.toInt()}", context)

    override suspend fun reconcileWatchedAfterStop(context: TrackerContext, progressPercent: Double) =
        call("reconcile", progressPercent.toInt().toString(), context)

    override fun historyRowIdentity(context: TrackerContext): String? = context.ids.rowIdentity()

    /** Items the service answers it doesn't know. */
    val notFound = mutableSetOf<TrackerContext>()

    /** One call, as one request, with the items as [markWatched] and [markUnwatched] name theirs, comma-separated. */
    override suspend fun writeHistory(items: List<HistoryItem>, watched: Boolean): List<HistoryItem> {
        call(
            if (watched) "watched" else "unwatched",
            items.joinToString(", ") { item -> "${name(item.context)}${item.watchedAt?.let { " at=${it.toEpochMilliseconds()}" }.orEmpty()}" },
            items.first().context,
        )
        return items.filter { it.context in notFound }
    }
}

/** MyAnimeList or AniList: one progress counter per anime entry. */
internal class FakeAnimeTracker(service: TrackerService, scope: TestScope, log: MutableList<Call>, credentials: TrackerCredentials) :
    FakeTracker(service, scope, log, credentials), SeriesProgress {
    override val needsAnimeIds: Boolean get() = true

    override fun seriesEntryId(context: TrackerContext): String? =
        (if (service == TrackerService.MYANIMELIST) context.anime?.mal else context.anime?.anilist)?.toString()

    override fun seriesProgress(context: TrackerContext): Int? = context.animeProgress

    override suspend fun markWatched(context: TrackerContext, watchedAt: Instant?) =
        call("watched", "${seriesEntryId(context)}@${context.animeProgress}", context)

    /** An entry reset (the whole entry unmarked), named by the entry. */
    override suspend fun markUnwatched(context: TrackerContext) = call("unwatched", "${seriesEntryId(context)}", context)

    /** An anime list names a title by its entry; one without an entry here can't be rated. */
    override fun ratingId(target: RatingTarget): String {
        val entry = if (service == TrackerService.MYANIMELIST) target.anime?.mal else target.anime?.anilist
        return "${target.kind.name.lowercase()} ${entry ?: throw TrackerException.Unsupported(service, "rating without an anime id")}"
    }
}

/**
 * A provider for one service whose trackers are fakes; [trackers] holds each binding's tracker, newest last. Its
 * sessions refresh through [refresher] where a test sets one; [revoked] holds the sessions revoked at disconnect.
 */
internal class FakeProvider(
    override val service: TrackerService,
    private val scope: TestScope,
    private val log: MutableList<Call>,
) : TrackerProvider {
    val trackers = mutableListOf<FakeTracker>()
    var deviceCode: FakeDeviceCode? = null
    var relaySignIn: TrackerSignIn.Relay? = null
    override var refresher: TokenRefresher? = null
    val revoked = mutableListOf<TrackerSession>()

    override val signIn: TrackerSignIn get() = deviceCode ?: relaySignIn ?: error("no sign-in set up")

    override fun tracker(credentials: TrackerCredentials): Tracker {
        val tracker = when (service) {
            TrackerService.MYANIMELIST, TrackerService.ANILIST -> FakeAnimeTracker(service, scope, log, credentials)
            else -> FakeRealtimeTracker(service, scope, log, credentials)
        }
        trackers += tracker
        return tracker
    }

    override suspend fun revoke(session: TrackerSession) {
        revoked += session
    }
}

/**
 * A device-code service that answers [answers] in turn (then Pending), recording when each poll came; [failRequest]
 * makes asking for a code throw it.
 */
internal class FakeDeviceCode(
    private val scope: TestScope,
    private val answers: List<DevicePoll>,
    val grant: DeviceCodeGrant,
    private val failRequest: Throwable? = null,
) : TrackerSignIn.DeviceCode {
    val polls = mutableListOf<Long>()

    override suspend fun requestCode(): DeviceCodeGrant {
        failRequest?.let { throw it }
        return grant
    }

    override suspend fun probe(grant: DeviceCodeGrant): DevicePoll {
        polls += scope.testScheduler.currentTime
        return answers.getOrElse(polls.size - 1) { DevicePoll.Pending }
    }

    /** Who each access token signs in as; a token not listed fails its lookup. */
    val accounts = mutableMapOf("granted" to SignedInAccount("alex", "1"))

    /** The access tokens looked up, in order. */
    val lookups = mutableListOf<String>()

    /** The session [session] builds: [granted], the token answer ignored. */
    var granted = TrackerSession(accessToken = "granted", refreshToken = "r0", expiresAt = FAR_FUTURE, createdAt = 1)

    override suspend fun session(token: JsonObject): TrackerSession = granted

    /** When set, each account lookup (right after the user approved, before the session is kept) waits for it. */
    var lookupGate: CompletableDeferred<Unit>? = null

    override suspend fun account(session: TrackerSession): SignedInAccount? {
        lookups += session.accessToken
        lookupGate?.await()
        return accounts[session.accessToken]
    }
}

/** An expiry (epoch seconds, in 2100) no test reaches: a session that never needs a refresh. */
internal const val FAR_FUTURE: Long = 4_102_444_800

/** A relay service's sign-in: the relay's tokens become a session of user "kai". */
internal object FakeRelaySignIn : TrackerSignIn.Relay {
    override suspend fun session(result: RelayResult): TrackerSession =
        TrackerSession(accessToken = result.accessToken, refreshToken = result.refreshToken, expiresAt = FAR_FUTURE, username = "kai", createdAt = 1)
}

/** An OAuth relay whose session's answer is [result], once the test completes it (null: the user declined). */
internal class FakeRelay : OAuthRelay {
    val result = CompletableDeferred<RelayResult?>()

    override suspend fun start(service: TrackerService): RelayStart =
        RelayStart(session = "s1", url = "https://relay.example/auth/${service.id}?state=s1")

    override suspend fun poll(service: TrackerService, session: String): RelayResult? = result.await()
}

/**
 * A platform secret store that fails as Android's does when `commit()` can't write (a full disk), or when the Keystore
 * fails for a moment: every read while [failReads], every write while [failWrites], every delete while [failDeletes]
 * throws [IllegalStateException]. Its entries are [memory]'s.
 */
internal class FailingSecretStore(val memory: MemorySecretStore = MemorySecretStore()) : SecretStore {
    var failReads = false
    var failWrites = false
    var failDeletes = false

    override suspend fun get(key: String): ByteArray? {
        check(!failReads) { "Keystore operation failed" }
        return memory.get(key)
    }

    override suspend fun put(key: String, value: ByteArray) {
        check(!failWrites) { "commit() failed" }
        memory.put(key, value)
    }

    override suspend fun delete(key: String) {
        check(!failDeletes) { "commit() failed" }
        memory.delete(key)
    }

    override suspend fun deleteAll(prefix: String) {
        check(!failDeletes) { "commit() failed" }
        memory.deleteAll(prefix)
    }
}

/**
 * Item ids to tracker ids, by the test items' ids ([movieItem], [episodeItem], [kitsuEpisode]): an item with an IMDb
 * id keeps it and its numbering, an anime one by the datasets ([animeTt]) also gets that MAL/AniList entry with the
 * episode as progress; an item known by its Kitsu entry N maps to MAL/AniList entry N with the episode as progress, and
 * to the IMDb id in [kitsuImdb] with season 1. Unknown items are unmapped; [failing] ones throw. Each call takes the
 * next of [latencies] (none: at once).
 */
internal class FakeResolver : TrackerIdResolver {
    /** The items asked for, by id, with whether anime ids were wanted then. */
    val calls = mutableListOf<Pair<String, Boolean>>()

    /** Per episode asked for, whether its progress was to count it on top of the server's ([resolveForEpisode]). */
    val currentEpisode = mutableListOf<Boolean>()
    var animeIds: () -> Boolean = { false }

    /** Items that fail, by their IMDb id or `kitsu:N`. */
    val failing = mutableSetOf<String>()

    /** IMDb ids of Kitsu entries, by `kitsu:N`. */
    val kitsuImdb = mutableMapOf<String, String>()

    /** IMDb ids that are anime by the datasets, with their entry id. */
    val animeTt = mutableMapOf<String, Int>()
    val latencies = ArrayDeque<Duration>()

    override suspend fun resolveForMovie(movie: MediaItem): ResolvedIds? = resolve(movie, movie.id, null, null)

    override suspend fun resolveForEpisode(episode: MediaItem, includeCurrentEpisode: Boolean): ResolvedIds? {
        currentEpisode += includeCurrentEpisode
        return resolve(episode, episode.grandparentId!!, episode.parentIndex, episode.index)
    }

    override suspend fun resolveForRating(item: MediaItem): RatingTarget? = null

    override fun clearCache() = Unit

    private suspend fun resolve(item: MediaItem, show: String, season: Int?, episode: Int?): ResolvedIds? {
        val anime = animeIds()
        calls += item.id to anime
        latencies.removeFirstOrNull()?.let { delay(it) }
        if (show in failing) throw IllegalStateException("mapping download failed")
        if (show.startsWith("kitsu:")) {
            val kitsu = show.removePrefix("kitsu:").toInt()
            val mapped = kitsuImdb[show]
            return ResolvedIds(
                ids = ExternalIds(imdb = mapped),
                anime = AnimeIds(mal = kitsu, anilist = kitsu, kitsu = kitsu),
                season = 1.takeIf { mapped != null && episode != null },
                episode = episode.takeIf { mapped != null },
                animeProgress = episode,
            )
        }
        if (!show.startsWith("tt")) return null
        val entry = animeTt[show]?.takeIf { anime }
        return ResolvedIds(
            ids = ExternalIds(imdb = show),
            anime = entry?.let { AnimeIds(mal = it, anilist = it) },
            season = season,
            episode = episode,
            animeProgress = entry?.let { episode },
        )
    }
}

/**
 * How a fake tracker names the item a write is about: `kitsu:<entry>:<progress>` for one known by its Kitsu entry,
 * else `<imdb>` for a movie and `<imdb>:<season>:<episode>` for an episode.
 */
internal fun name(context: TrackerContext): String {
    context.anime?.kitsu?.let { return if (context.isMovie) "kitsu:$it" else "kitsu:$it:${context.animeProgress}" }
    return if (context.isMovie) "${context.ids.imdb}" else "${context.ids.imdb}:${context.season}:${context.episode}"
}

internal fun movieItem(imdb: String = "tt0111161") = MediaItem(id = imdb, backend = BackendKind.PLEX, kind = MediaKind.MOVIE)

internal fun showItem(imdb: String) = MediaItem(id = imdb, backend = BackendKind.PLEX, kind = MediaKind.SHOW)

internal fun episodeItem(imdb: String, season: Int, episode: Int) = MediaItem(
    id = "$imdb:$season:$episode",
    backend = BackendKind.PLEX,
    kind = MediaKind.EPISODE,
    grandparentId = imdb,
    parentIndex = season,
    index = episode,
)

/** Episodes 1 to [count] of [season] of the show [imdb]. */
internal fun episodeItems(imdb: String, count: Int, season: Int = 1) = (1..count).map { episodeItem(imdb, season, it) }

/** Episode [episode] of the anime known by its Kitsu [entry], numbered as on the entry. */
internal fun kitsuEpisode(entry: Int, episode: Int) = episodeItem("kitsu:$entry", 1, episode)

/** A write of the movie [imdb] to queue for [service], or with [watched] `false` its removal. */
internal fun movieWrite(service: TrackerService, imdb: String = "tt1", watched: Boolean = true) =
    TrackerWriteRequest("${service.id}|movie|imdb=$imdb", TrackerContext(TrackerMediaKind.MOVIE, ExternalIds(imdb)), watched, null)

/** Seconds as the observer's millisecond positions. */
internal fun at(positionSeconds: Int, durationSeconds: Int = 1000) = TrackedPosition(positionSeconds * 1000L, durationSeconds * 1000L)

/** The watched threshold the tests' playbacks start with, as their media server says. */
internal const val THRESHOLD_PERCENT = 70

/** [item] of [backend] opened at [at], playing unless [playing] says otherwise. */
internal fun TrackedPlayback.start(item: MediaItem, backend: MediaBackend, at: TrackedPosition, playing: Boolean = true) =
    onVideoStarted(item, backend, at, playing, live = false)

/**
 * A profile's trackers on the test's virtual clock: an in-memory database, an in-memory secret store ([store] makes it
 * fail as a test asks), fake providers for [services] (plus [realProviders], a service's own client against a
 * scripted service), and a [FakeResolver] unless [idResolver] is given, wired through a real [TrackerHub].
 */
internal class TrackerFixture(
    val scope: TestScope,
    services: List<TrackerService> = TrackerService.entries,
    private val relay: OAuthRelay? = null,
    private val realProviders: List<TrackerProvider> = emptyList(),
    private val idResolver: TrackerIdResolver? = null,
) {
    val profileId = "p1"
    val wallClock = TestClock()
    val data = LocalData(inMemoryDatabase(), { wallClock.now }, StandardTestDispatcher(scope.testScheduler))
    val store = FailingSecretStore()
    val tokens = TrackerTokenStore(store)
    val log = mutableListOf<Call>()
    val providers = services.associateWith { FakeProvider(it, scope, log) }
    val resolver = FakeResolver()

    /** The backends a resolver was built for, in order. */
    val resolverBackends = mutableListOf<MediaBackend>()

    /** The media server the test items come from. */
    val backend = FakeMediaBackend("s1").apply { watchedThreshold = THRESHOLD_PERCENT / 100.0 }

    val clock = object : Clock {
        override fun now(): Instant = Instant.fromEpochMilliseconds(wallClock.now + scope.testScheduler.currentTime)
    }

    val hub = newHub().apply { onActiveProfileChanged(profileId) }

    val coordinator: TrackerCoordinator get() = hub.coordinator(profileId)
    val observer by lazy { coordinator.observer() }

    /** Sets a device-wide setting, as the user does in Settings. */
    suspend fun <T> set(setting: DeviceSetting<T>, value: T) {
        data.deviceSettings.set(setting, value)
        settle()
    }

    /** Another hub over this device's database and secret store: the app's next launch. */
    fun newHub() = TrackerHub(
        accountRepository = data.trackerAccounts,
        queue = data.trackerWriteQueue,
        settings = data.deviceSettings,
        tokens = tokens,
        providers = providers.values.toList() + realProviders,
        resolvers = { backend, needsAnimeIds ->
            resolverBackends += backend
            (idResolver ?: resolver).also { if (it is FakeResolver) it.animeIds = needsAnimeIds }
        },
        relay = relay,
        clock = clock,
        timeSource = scope.testScheduler.timeSource,
        scope = scope.backgroundScope,
    )

    /** Connects [service] with a session that doesn't expire in any test. */
    suspend fun connect(service: TrackerService, session: TrackerSession = TrackerSession("a0", "r0", FAR_FUTURE, "alex", 1)) {
        hub.accounts.connect(profileId, service, session)
        settle()
    }

    /** The session this device keeps for [service], or `null`. */
    suspend fun stored(service: TrackerService): TrackerSession? = tokens.load(profileId, service)?.session

    /** The tracker of [service]'s current binding. */
    fun tracker(service: TrackerService): FakeTracker = providers.getValue(service).trackers.last()

    /** The calls [service] got, without their times. */
    fun calls(service: TrackerService): List<String> = log.filter { it.service == service }.map { it.op }

    /** [calls] without the dates replays carry. */
    fun undated(service: TrackerService): List<String> = calls(service).map { it.replace(Regex(" at=\\d+"), "") }

    fun settle() = scope.runCurrent()

    fun advance(duration: Duration) {
        scope.advanceTimeBy(duration)
        scope.runCurrent()
    }

    /** Lets every channel drain, spacing included. */
    fun drain() = advance(10.seconds)

    suspend fun queued() = data.trackerWriteQueue.pending(profileId).map {
        "${it.service.id} ${it.coalesceKey} watched=${it.watched} attempts=${it.attempts}"
    }

    fun close() = data.close()
}

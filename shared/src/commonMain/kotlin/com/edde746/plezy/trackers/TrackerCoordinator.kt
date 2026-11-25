package com.edde746.plezy.trackers

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.data.tracker.QueuedTrackerWrite
import com.edde746.plezy.data.tracker.TrackerWriteQueue
import com.edde746.plezy.data.tracker.TrackerWriteRequest
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.SpecialsOrdering
import com.edde746.plezy.model.collectEpisodes
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.servers.TrackerWatchMarks
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.Job
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.launch
import kotlin.coroutines.cancellation.CancellationException
import kotlin.math.abs
import kotlin.time.Clock
import kotlin.time.ComparableTimeMark
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Instant
import kotlin.time.TimeSource

/**
 * The only place tracker writes leave the app, for one profile. Every connected tracker the device's switches let
 * through ([TrackerGates]: the service's toggle, Trakt's watched sync, the library filter) gets each write, in parallel
 * across services and in order within one ([ServiceChannel]).
 *
 * - **Playback** ([observer]): start, pause, resume, a seek (a position jump of more than 5 s) and stop reach the
 *   [RealtimeScrobble] trackers (Trakt, Simkl, MDBList) pinned when the playback started, as live reports with the
 *   measured progress, within each service's [ScrobblePolicy] and a 1 s debounce of duplicate states. A pause or stop
 *   with no start behind it isn't sent. Once the position reaches the media server's own watched threshold
 *   ([MediaBackend.watchedThreshold]) the other trackers mark it watched, once per playback, or at stop if it got
 *   there between two positions.
 * - **One watch, one write per service:** a realtime tracker whose start went out owns the watch; its stop and
 *   [RealtimeScrobble.reconcileWatchedAfterStop] record it, and the threshold mark leaves it out. If its stop didn't
 *   land, the watch falls back to a history write. An account reconnected mid-playback gets none of it.
 * - **Manual marks** ([watchMarks]) go out one at a time, in the order they were made: a movie or episode to every
 *   tracker (an unwatched episode only to [EpisodeHistory] ones, since a series counter can't lose one episode); a
 *   season's or show's episodes to [EpisodeHistory] trackers as [EpisodeHistory.writeHistory] batches of
 *   [HISTORY_BATCH] episodes, and one write per series entry to [SeriesProgress] ones (an unwatched container resets
 *   the entry).
 * - **Retries:** a failed watched/unwatched write goes to the persisted [TrackerWriteQueue], coalesced per remote row,
 *   and is replayed by [replayQueuedWrites], a history tracker's rows batched as a season mark's are. A replay failing
 *   transiently (rate limit, 5xx, network, the secret store) keeps its attempts and defers that service for the rest
 *   of the burst; any other failure counts one of its [TrackerWriteQueue.MAX_ATTEMPTS] attempts, and a write that used
 *   them all is dropped. Live reports are never queued, only logged.
 * - **Rate limits:** a rate-limited service gets no request until the wait it asked for ends
 *   ([TrackerException.RateLimited.retryAfterSeconds]), or for [RATE_LIMIT_HOLD] when it didn't say: its live
 *   reports are skipped, its watched writes queued and its replays wait.
 * - **Isolation:** the player only posts events here; tracker work runs in this coordinator's own scope and every
 *   failure is logged, so no tracker error reaches playback or a mark's caller.
 *
 * Main-thread confined, like the stores. Built by [TrackerHub.coordinator].
 */
class TrackerCoordinator internal constructor(
    val profileId: String,
    private val accounts: TrackerAccounts,
    private val gates: TrackerGates,
    private val resolvers: TrackerIdResolverFactory,
    private val queue: TrackerWriteQueue,
    private val clock: Clock,
    private val timeSource: TimeSource.WithComparableMarks,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()
    private val events = Channel<Event>(Channel.UNLIMITED)
    private val pendingMarks = Channel<WatchedMark>(Channel.UNLIMITED)
    private val loaded = CompletableDeferred<Unit>()
    private var bound: List<BoundTracker> = emptyList()
    private val channels = mutableMapOf<TrackerService, ServiceChannel>()
    private var playback: Playback? = null

    /** The observer whose playback started last ([observer]); every other observer's events are dropped. */
    private var source: TrackedPlayback? = null
    private var replay: Job? = null
    private var replayAgain = false
    private var imported = false

    /** Moves on with [cancelInFlight]: work begun before it (a container mark, a replay) stops. */
    private var generation = 0

    /** The resolver of the backend the last playback came from, and that backend ([resolverFor]). */
    private var resolver: TrackerIdResolver? = null
    private var resolverBackend: MediaBackend? = null

    /** Whether the playback being resolved wants anime ids: a tracker that needs them may write for its library. */
    private var playbackWantsAnimeIds = false

    /** Per service, when the wait its last rate limit asked for ends. */
    private val holds = mutableMapOf<TrackerService, ComparableTimeMark>()

    /** Failed writes the queue couldn't keep (a full disk), queued again at the next replay; [UNSAVED_LIMIT] at most. */
    private val unsaved = ArrayDeque<UnsavedWrite>()

    /**
     * A new observer for one producer of playbacks (the player, a player app's hand-off): the coordinator follows one
     * playback at a time, the one whose observer started last, and drops the events of every other observer. A start
     * closes the playback still open with a stop at its last position. Observers only post events, so they can't fail
     * or block playback.
     */
    fun observer(): TrackedPlayback = object : TrackedPlayback {
        override fun onVideoStarted(item: MediaItem, backend: MediaBackend, at: TrackedPosition, playing: Boolean, live: Boolean) {
            events.trySend(Event.Started(this, item, backend, at, playing, live))
        }

        override fun onPlayingChanged(playing: Boolean, at: TrackedPosition) {
            events.trySend(Event.PlayingChanged(this, playing, at))
        }

        override fun onPosition(at: TrackedPosition) {
            events.trySend(Event.Position(this, at))
        }

        override fun onVideoStopped(at: TrackedPosition) {
            events.trySend(Event.Stopped(this, at))
        }
    }

    /**
     * The user's manual marks (and offline replays, download syncs, a player app's completion), after the media
     * server recorded them: a movie, an episode, a season or a show. Returns at once; never throws.
     */
    val watchMarks: TrackerWatchMarks = TrackerWatchMarks { item, backend, watched -> pendingMarks.trySend(WatchedMark(item, backend, watched)) }

    init {
        scope.launch {
            accounts.bound(profileId).collect {
                bound = it
                loaded.complete(Unit)
            }
        }
        scope.launch {
            loaded.await()
            for (event in events) {
                try {
                    handle(event)
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    Log.w(TAG, e) { "playback event failed" }
                }
            }
        }
        scope.launch {
            loaded.await()
            // One at a time: a mark may wait for the mapping datasets before it reaches the services' channels, and a
            // later one (an undo) must not get there first.
            for (mark in pendingMarks) {
                try {
                    applyMark(mark)
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    Log.d(TAG, e) { "manual ${if (mark.watched) "watched" else "unwatched"} mark of ${mark.item.id} failed" }
                }
            }
        }
        // The profile is bound: replay what an earlier run (or release) left queued.
        replayQueuedWrites()
    }

    /**
     * Replays the profile's queued writes. Safe to call any time: a call while a replay runs makes it run once more;
     * rows of a service that isn't connected, or that its switches keep from writing, wait untouched. Never throws.
     */
    fun replayQueuedWrites() {
        if (replay?.isActive == true) {
            replayAgain = true
            return
        }
        replay = scope.launch {
            loaded.await()
            importEarlierRelease()
            // Spans the whole burst: a service that just asked for quiet isn't asked again by the re-run.
            val deferred = mutableSetOf<TrackerService>()
            do {
                replayAgain = false
                try {
                    replayOnce(deferred)
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    Log.w(TAG, e) { "write queue replay failed" }
                }
            } while (replayAgain)
        }
    }

    /**
     * The profile is no longer the active one: drops the open playback (nothing more is reported for it) and the
     * reports still waiting, the resolver and its backend, and stops a container mark or replay under way. Writes
     * already on the wire finish.
     */
    fun cancelInFlight() {
        generation++
        events.trySend(Event.Cancel)
    }

    /**
     * Ends the open playback with its stop, and returns once every service's channel sent what it holds (the app is
     * shutting down).
     */
    internal suspend fun stopPlayback() {
        val done = CompletableDeferred<Unit>()
        events.trySend(Event.Settle(done))
        done.await()
    }

    /** Drops [service]'s queued writes, kept and unsaved alike: its account was disconnected or its session died. */
    internal suspend fun purgeWrites(service: TrackerService) {
        unsaved.removeAll { it.service == service }
        queue.removeService(profileId, service)
    }

    internal fun close() = scope.cancel()

    // Playback

    private sealed interface Event {
        class Started(
            val source: TrackedPlayback,
            val item: MediaItem,
            val backend: MediaBackend,
            val at: TrackedPosition,
            val playing: Boolean,
            val live: Boolean,
        ) : Event
        class PlayingChanged(val source: TrackedPlayback, val playing: Boolean, val at: TrackedPosition) : Event
        class Position(val source: TrackedPlayback, val at: TrackedPosition) : Event
        class Stopped(val source: TrackedPlayback, val at: TrackedPosition) : Event
        object Cancel : Event
        class Settle(val done: CompletableDeferred<Unit>) : Event
    }

    private suspend fun handle(event: Event) {
        when (event) {
            is Event.Started -> {
                source = event.source
                playback?.let { close(it) }
                if (!event.live) start(event.item, event.backend, event.at, event.playing)
            }
            is Event.PlayingChanged -> current(event.source)?.let { p ->
                p.move(event.at)
                report(p, if (event.playing) ScrobbleState.START else ScrobbleState.PAUSE)
            }
            is Event.Position -> current(event.source)?.let { p -> moved(p, event.at) }
            is Event.Stopped -> current(event.source)?.let { p ->
                p.move(event.at)
                close(p)
            }
            Event.Cancel -> {
                playback = null
                source = null
                channels.values.forEach { it.clear() }
                resolver?.clearCache()
                resolver = null
                resolverBackend = null
            }
            is Event.Settle -> {
                playback?.let { close(it) }
                channels.values.toList().forEach { it.settle() }
                event.done.complete(Unit)
            }
        }
    }

    /** The open playback, when [from] is the observer that started it. */
    private fun current(from: TrackedPlayback): Playback? {
        if (from !== source) {
            Log.d(TAG) { "dropped an event of a playback a newer one replaced" }
            return null
        }
        return playback
    }

    /**
     * Opens the playback of [item] (a movie or episode; anything else isn't tracked) when some tracker may report it
     * or record its watch; its start is reported once it plays ([playing] now, else its first resume).
     */
    private suspend fun start(item: MediaItem, backend: MediaBackend, at: TrackedPosition, playing: Boolean) {
        val kind = kindOf(item) ?: return
        val library = item.libraryGlobalKey
        val trackers = bound
        // Trakt can take a watch without reports: its scrobble and watched-sync toggles are separate.
        if (trackers.none { canWrite(it, library) || canReport(it, library) }) return
        playbackWantsAnimeIds = trackers.any { it.tracker.needsAnimeIds && canWrite(it, library) }
        val context = context(item, resolverFor(backend), kind, includeCurrentEpisode = true) ?: return
        // The playback belongs to the accounts connected when it began; a reconnect mid-playback doesn't inherit it.
        val targets = trackers.mapNotNull { b ->
            val tracker = b.tracker as? RealtimeScrobble ?: return@mapNotNull null
            if (canReport(b, library)) PlaybackTarget(b, tracker) else null
        }
        val p = Playback(context, backend.watchedThreshold, targets)
        p.move(at)
        playback = p
        if (playing) report(p, ScrobbleState.START)
    }

    private suspend fun moved(p: Playback, at: TrackedPosition) {
        val jumped = abs(at.positionMillis - p.positionMillis) > SEEK_JUMP_MILLIS
        p.move(at)
        // A seek is a checkpoint, not a transition; services without one opt out through their policy.
        if (jumped) report(p, ScrobbleState.SEEK)
        if (!p.crossed && p.reachedThreshold) {
            p.crossed = true
            dispatch(thresholdTrackers(p), p.context, watched = true)
        }
    }

    /** Ends [p], the open playback, at its last position: its stop, and the watch it recorded. */
    private suspend fun close(p: Playback) {
        playback = null
        val watched = p.crossed || p.reachedThreshold
        // Decided once, so the two ways of recording a watch stay exclusive.
        val owners = p.targets.filter { it.sessionStarted }
        if (!p.crossed && p.reachedThreshold) dispatch(thresholdTrackers(p), p.context, watched = true)
        // Measured, never inflated: the progress is the service's resume point. A session that started is closed even
        // at 0 %, or the service shows it playing for its runtime.
        report(p, ScrobbleState.STOP)
        if (!watched) return
        val percent = p.percent
        for (owner in owners) {
            // Behind the stop in the service's channel, so it knows whether the stop landed.
            channel(owner.service).submit(null, owner.tracker.writeSpacing) {
                val current = current(owner.tracker)
                if (current == null) {
                    Log.d(TAG) { "${owner.service.id}: watched reconciliation skipped, account rebound" }
                    return@submit false
                }
                if (!canWrite(current, p.context.libraryGlobalKey)) return@submit false
                if (owner.stopConfirmed) {
                    reconcile(current, owner.tracker, p.context, percent)
                } else {
                    // The stop never landed, so the service's own completion rule never ran: a history write instead.
                    applyWrite(owner.tracker, listOf(p.context), watched = true)
                }
            }
        }
    }

    /** Trackers that don't own the watch of [p]: everyone whose playback start didn't go out. */
    private fun thresholdTrackers(p: Playback): List<BoundTracker> =
        bound.filter { b -> p.targets.none { it.sessionStarted && it.tracker === b.tracker } }

    /** Queues [state] for the playback's targets that take it now. */
    private suspend fun report(p: Playback, state: ScrobbleState) {
        val now = timeSource.markNow()
        val percent = p.percent
        for (target in p.targets) {
            // Still the same sign-in: the user can sign out or reconnect mid-playback.
            val current = current(target.tracker)
            if (current == null) {
                Log.d(TAG) { "${target.service.id}: skipped scrobble ${state.name.lowercase()}, account rebound" }
                continue
            }
            // Still enabled for this library: the user can turn the tracker off mid-playback.
            if (!canReport(current, p.context.libraryGlobalKey)) continue
            if (!target.accepts(state, now)) continue
            target.record(state, now)
            channel(target.service).submit(state, target.tracker.writeSpacing) {
                if (current(target.tracker) == null) {
                    Log.d(TAG) { "${target.service.id}: skipped scrobble ${state.name.lowercase()}, account rebound" }
                    return@submit false
                }
                if (held(target.service)) return@submit false
                try {
                    target.tracker.scrobble(p.context, state, percent)
                    if (state == ScrobbleState.STOP) target.stopConfirmed = true
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    // Live reports are never queued.
                    failed(target.service, "scrobble ${state.name.lowercase()}", e)
                }
                true
            }
        }
    }

    /** Whether a request went out, as [ServiceChannel.submit] asks; a stop's watch the service didn't take is queued. */
    private suspend fun reconcile(b: BoundTracker, tracker: RealtimeScrobble, context: TrackerContext, percent: Double): Boolean {
        if (held(b.service)) {
            retryLater(tracker, b, listOf(context), watched = true)
            return false
        }
        try {
            tracker.reconcileWatchedAfterStop(context, percent)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            failed(b.service, "watched after stop", e)
            retryLater(tracker, b, listOf(context), watched = true)
        }
        return true
    }

    // Manual marks

    private suspend fun applyMark(mark: WatchedMark) {
        val item = mark.item
        if (item.kind !in MARKABLE) return
        val library = item.libraryGlobalKey
        if (bound.none { canWrite(it, library) }) return
        val wantsAnimeIds = bound.any { it.tracker.needsAnimeIds && canWrite(it, library) }
        // A resolver of its own: the server's watched counts just changed with this mark.
        val resolver = resolvers.create(mark.backend) { wantsAnimeIds }
        val started = generation
        when (item.kind) {
            MediaKind.MOVIE, MediaKind.EPISODE -> single(item, resolver, kindOf(item)!!, mark.watched)
            else -> {
                val episodes = collectEpisodes(mark.backend, item.id, unwatchedOnly = false, ordering = SpecialsOrdering.RESPECT_SERVER, fallback = item)
                if (generation != started) return
                Log.d(TAG) { "manual ${item.kind.name.lowercase()} ${item.id} expanded to ${episodes.size} episodes" }
                container(episodes, resolver, mark.watched, started)
            }
        }
    }

    private suspend fun single(item: MediaItem, resolver: TrackerIdResolver, kind: TrackerMediaKind, watched: Boolean) {
        // The server's rollup already counts this episode.
        val resolved = context(item, resolver, kind, includeCurrentEpisode = false) ?: return
        if (watched) {
            dispatch(bound, resolved, watched = true)
            return
        }
        // A series counter can't lose one episode: only a season or show unmark resets it.
        val context = resolved.copy(animeProgress = null)
        dispatch(if (context.isMovie) bound else bound.filter { it.tracker is EpisodeHistory }, context, watched = false)
    }

    /**
     * A season's or show's [episodes]: [HISTORY_BATCH] episodes a request for history trackers, one write per series
     * entry for progress ones (watched: the highest mapped progress, else the number of episodes; unwatched: a reset).
     */
    private suspend fun container(episodes: List<MediaItem>, resolver: TrackerIdResolver, watched: Boolean, started: Int) {
        val contexts = mutableListOf<TrackerContext>()
        val entries = LinkedHashMap<String, SeriesGroup>()
        for (episode in episodes) {
            val resolved = context(episode, resolver, TrackerMediaKind.EPISODE, includeCurrentEpisode = false)
            if (generation != started) return
            val context = (if (watched) resolved else resolved?.copy(animeProgress = null)) ?: continue
            contexts += context
            val key = seriesGroupKey(context) ?: continue
            entries.getOrPut(key) { SeriesGroup(context) }.add(context)
        }
        Log.d(TAG) { "manual container resolved ${contexts.size}/${episodes.size} episodes, ${entries.size} series entries" }
        for (b in bound) {
            if (b.tracker !is EpisodeHistory) continue
            val admitted = contexts.filter { canWrite(b, it.libraryGlobalKey) }
            for (batch in admitted.chunked(HISTORY_BATCH)) {
                channel(b.service).submit(null, b.tracker.writeSpacing) {
                    if (generation != started) return@submit false
                    applyWrite(b.tracker, batch, watched)
                }
            }
        }
        val progress = bound.filter { it.tracker is SeriesProgress }
        for (group in entries.values) {
            dispatch(progress, if (watched) group.watchedContext() else group.base, watched)
        }
    }

    /** The series entries [context] would touch, as one key, so one entry gets one write; `null` when none maps. */
    private suspend fun seriesGroupKey(context: TrackerContext): String? {
        val parts = mutableListOf<String>()
        for (b in bound) {
            val tracker = b.tracker as? SeriesProgress ?: continue
            if (!canWrite(b, context.libraryGlobalKey)) continue
            tracker.seriesEntryId(context)?.let { parts += "${b.service.id}=$it" }
        }
        return parts.takeIf { it.isNotEmpty() }?.joinToString("|")
    }

    // Writes

    /** Queues a watched/unwatched write of [context] on each of [trackers] that may write it. */
    private suspend fun dispatch(trackers: List<BoundTracker>, context: TrackerContext, watched: Boolean) {
        for (b in trackers) {
            if (!canWrite(b, context.libraryGlobalKey)) continue
            channel(b.service).submit(null, b.tracker.writeSpacing) { applyWrite(b.tracker, listOf(context), watched) }
        }
    }

    /**
     * One watched/unwatched write of [contexts], run in its service's channel: several only for a history tracker,
     * as one request. A success drops queued writes it covers, except those of items the service answered it doesn't
     * know; a failure, or a service waiting out a rate limit, queues them for a retry, unless the account was signed
     * out or reconnected meanwhile.
     */
    private suspend fun applyWrite(tracker: Tracker, contexts: List<TrackerContext>, watched: Boolean): Boolean {
        val b = current(tracker) ?: return false
        if (contexts.isEmpty()) return false
        val what = if (watched) "mark watched" else "mark unwatched"
        if (held(b.service)) {
            Log.i(TAG) { "${b.service.id}: $what not sent, the service asked to wait" }
            retryLater(tracker, b, contexts, watched)
            return false
        }
        val rejected = try {
            write(tracker, contexts.map { HistoryItem(it) }, watched).mapTo(HashSet()) { it.context }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            failed(b.service, what, e)
            retryLater(tracker, b, contexts, watched)
            return true
        }
        val applied = (contexts - rejected).mapNotNull { context ->
            coalesceKey(tracker, context)?.let { it to if (watched) progressClaim(tracker, context) else null }
        }.toMap()
        try {
            queue.invalidate(profileId, b.service, applied)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            // The write landed; a failed cleanup must not look like a failed write.
            Log.w(TAG, e) { "${b.service.id}: write queue cleanup failed" }
        }
        return true
    }

    /**
     * [items] to [tracker]: several only to a history tracker, which takes them in one request. Returns the items the
     * service answered it doesn't know.
     */
    private suspend fun write(tracker: Tracker, items: List<HistoryItem>, watched: Boolean): List<HistoryItem> {
        when {
            tracker is EpisodeHistory -> return tracker.writeHistory(items, watched)
            watched -> tracker.markWatched(items.single().context, items.single().watchedAt)
            else -> tracker.markUnwatched(items.single().context)
        }
        return emptyList()
    }

    /**
     * Queues the writes of [contexts] that name a remote row for a retry under the sign-in [b], filed as watched now.
     * Dropped when that sign-in ended meanwhile: its queue went with it, and the rows would otherwise replay through the
     * account that replaced it. A queue that can't keep them (a full disk) leaves them for the next replay, in memory.
     */
    private suspend fun retryLater(tracker: Tracker, b: BoundTracker, contexts: List<TrackerContext>, watched: Boolean) {
        val writes = contexts.mapNotNull { context ->
            val key = coalesceKey(tracker, context) ?: return@mapNotNull null
            TrackerWriteRequest(key, context, watched, if (watched) progressClaim(tracker, context) else null)
        }
        if (writes.isEmpty()) {
            Log.d(TAG) { "${b.service.id}: failed write has no row to retry" }
            return
        }
        if (current(tracker) == null) {
            Log.d(TAG) { "${b.service.id}: failed write dropped, account rebound mid-write" }
            return
        }
        val write = UnsavedWrite(b.service, b.account.connectedAt, writes, clock.now().toEpochMilliseconds())
        val queued = try {
            enqueue(write)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e(TAG, e) { "${b.service.id}: ${writes.size} failed write(s) not persisted, kept in memory" }
            unsaved.addLast(write)
            while (unsaved.sumOf { it.writes.size } > UNSAVED_LIMIT) {
                val dropped = unsaved.removeFirst()
                Log.w(TAG) { "${dropped.service.id}: unsaved write buffer full, ${dropped.writes.size} write(s) dropped" }
            }
            return
        }
        Log.d(TAG) { "${b.service.id}: queued $queued of ${writes.size} row(s) for retry" }
    }

    private suspend fun enqueue(write: UnsavedWrite): Int =
        queue.enqueue(profileId, write.service, write.connectedAt, write.writes, write.watchedAt)

    /** Queues again the writes an earlier failure couldn't persist; what still can't be kept waits for the next try. */
    private suspend fun restoreUnsaved() {
        while (unsaved.isNotEmpty()) {
            val write = unsaved.first()
            try {
                enqueue(write)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "unsaved writes still can't be persisted" }
                return
            }
            unsaved.removeFirst()
        }
    }

    private suspend fun importEarlierRelease() {
        if (imported) return
        try {
            queue.importEarlierRelease(profileId)
            imported = true
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e(TAG, e) { "importing an earlier release's queued tracker writes failed, trying again at the next replay" }
        }
    }

    private suspend fun replayOnce(deferred: MutableSet<TrackerService>) {
        restoreUnsaved()
        val started = generation
        val (exhausted, live) = queue.pending(profileId).partition { it.attempts >= TrackerWriteQueue.MAX_ATTEMPTS }
        for (row in exhausted) Log.w(TAG) { "${row.service.id}: queued write ${row.context.logName} dropped after ${row.attempts} attempts" }
        queue.complete(exhausted.map { it.id })
        val sends = mutableListOf<Deferred<Boolean>>()
        val trackers = bound
        for (unit in replayUnits(live) { service -> trackers.firstOrNull { it.service == service }?.tracker is EpisodeHistory }) {
            // A service with no connection keeps its rows for later.
            val b = trackers.firstOrNull { it.service == unit.first().service } ?: continue
            sends += channel(b.service).submit(null, b.tracker.writeSpacing) { replayUnit(b.tracker, unit, deferred, started) }
        }
        sends.awaitAll()
    }

    /**
     * Replays [rows], one service's rows in one direction, as one write; whether a request went out. Rows are left as
     * they are when the profile is no longer active, the account went, the service is deferred or waits out a rate
     * limit, or its switch is off; a row the library filter leaves out is dropped as done. A transient failure keeps
     * their attempts and defers the service for the rest of the burst; any other counts an attempt each. A row whose
     * item the service answers it doesn't know is dropped as done: no retry can succeed.
     */
    private suspend fun replayUnit(tracker: Tracker, rows: List<QueuedTrackerWrite>, deferred: MutableSet<TrackerService>, started: Int): Boolean {
        val service = tracker.service
        if (generation != started || service in deferred || held(service) || current(tracker) == null) return false
        if (!gates.writesWatched(service)) return false
        val watched = rows.first().watched
        check(rows.all { it.service == service && it.watched == watched }) { "a replay unit mixes services or directions" }
        val (allowed, filtered) = rows.partition { gates.allowsLibrary(service, it.context.libraryGlobalKey) }
        if (filtered.isNotEmpty()) {
            Log.d(TAG) { "${service.id}: ${filtered.size} queued write(s) dropped, library filtered out" }
            queue.complete(filtered.map { it.id })
        }
        // A newer write for a row replaced or covered it while this waited its turn.
        val replaying = allowed.filter { queue.isQueued(it.id) }
        if (replaying.isEmpty()) return false
        val rejected = try {
            write(tracker, replaying.map { HistoryItem(it.context, if (watched) Instant.fromEpochMilliseconds(it.watchedAt) else null) }, watched)
                .mapTo(HashSet()) { it.context }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            if (isTransientTrackerFailure(e)) {
                // Not an answer about the write: keep its attempts, and stop asking this service for this burst.
                deferred += service
                failed(service, "queued write deferred", e)
            } else {
                queue.recordFailure(replaying.map { it.id })
                failed(service, "queued write, will retry", e)
            }
            return true
        }
        queue.complete(replaying.map { it.id })
        val unknown = replaying.count { it.context in rejected }
        if (unknown > 0) Log.w(TAG) { "${service.id}: $unknown queued write(s) dropped, the service doesn't know the item" }
        Log.d(TAG) { "${service.id}: replayed ${replaying.size - unknown} queued write(s)" }
        return true
    }

    // Ids

    /** A movie, or an episode; `null` for anything else. */
    private fun kindOf(item: MediaItem): TrackerMediaKind? = when (item.kind) {
        MediaKind.MOVIE -> TrackerMediaKind.MOVIE
        MediaKind.EPISODE -> TrackerMediaKind.EPISODE
        else -> null
    }

    /**
     * [backend]'s resolver for playback, kept across episodes: one per backend instance, so a reconnect's new client
     * (under the same server id) gets a new one.
     */
    private fun resolverFor(backend: MediaBackend): TrackerIdResolver {
        resolverBackend?.takeIf { it === backend }?.let { return resolver!! }
        resolver?.clearCache()
        // Anime ids may download the mapping datasets: only looked up when an anime tracker may write.
        return resolvers.create(backend) { playbackWantsAnimeIds }.also {
            resolverBackend = backend
            resolver = it
        }
    }

    /**
     * [item]'s context, or `null` when it has no ids a tracker takes or its lookup failed (logged, never thrown): an
     * episode without its numbers is skipped.
     */
    private suspend fun context(item: MediaItem, resolver: TrackerIdResolver, kind: TrackerMediaKind, includeCurrentEpisode: Boolean): TrackerContext? {
        val resolved = try {
            if (kind == TrackerMediaKind.MOVIE) resolver.resolveForMovie(item) else resolver.resolveForEpisode(item, includeCurrentEpisode)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            if (e is MediaServerHttpException && e.isCancellation) {
                Log.d(TAG) { "id resolution cancelled for ${item.id}" }
            } else {
                Log.w(TAG, e) { "id resolution failed for ${item.id}, not tracked" }
            }
            return null
        }
        val anime = resolved?.anime?.takeUnless { it.isEmpty }
        if (resolved == null || resolved.ids.isEmpty && anime == null) {
            Log.d(TAG) { "no tracker ids for ${item.id}" }
            return null
        }
        val episode = kind == TrackerMediaKind.EPISODE
        val season = if (episode) resolved.season ?: item.parentIndex ?: return null else null
        val number = if (episode) resolved.episode ?: item.index ?: return null else null
        return TrackerContext(
            kind = kind,
            ids = resolved.ids,
            anime = anime,
            season = season,
            episode = number,
            animeProgress = resolved.animeProgress,
            ratingKey = item.id,
            libraryGlobalKey = item.libraryGlobalKey,
        )
    }

    // Bookkeeping

    /** [tracker]'s connection as it is now, or `null` when its sign-in ended (signed out or reconnected). */
    private fun current(tracker: Tracker): BoundTracker? = bound.firstOrNull { it.tracker === tracker }

    /** Whether [b] takes watched writes about an item of [library] now. */
    private suspend fun canWrite(b: BoundTracker, library: String?): Boolean =
        gates.writesWatched(b.service) && gates.allowsLibrary(b.service, library)

    /** Whether [b] takes live reports about an item of [library] now. */
    private suspend fun canReport(b: BoundTracker, library: String?): Boolean =
        b.tracker is RealtimeScrobble && gates.reportsPlayback(b.service) && gates.allowsLibrary(b.service, library)

    private fun channel(service: TrackerService): ServiceChannel = channels.getOrPut(service) { ServiceChannel(scope, service) }

    /** Logs a failed request; a rate limit holds [service]'s requests for the wait it asked for, else [RATE_LIMIT_HOLD]. */
    private fun failed(service: TrackerService, what: String, e: Exception) {
        if (e is TrackerException.RateLimited) holds[service] = timeSource.markNow() + (e.retryAfterSeconds?.seconds ?: RATE_LIMIT_HOLD)
        if (e is TrackerException) Log.d(TAG) { "${service.id}: $what failed: ${e.message}" } else Log.d(TAG, e) { "${service.id}: $what failed" }
    }

    /** Whether [service] is waiting out a rate limit. */
    private fun held(service: TrackerService): Boolean = holds[service]?.hasNotPassedNow() == true

    /** Failed writes of one service the queue couldn't keep, with what [TrackerWriteQueue.enqueue] takes. */
    private class UnsavedWrite(val service: TrackerService, val connectedAt: Long, val writes: List<TrackerWriteRequest>, val watchedAt: Long)

    /** The playback in progress, with the realtime trackers pinned when it began. */
    private class Playback(val context: TrackerContext, private val threshold: Double, val targets: List<PlaybackTarget>) {
        var positionMillis = 0L
            private set
        private var durationMillis = 0L
        var crossed = false

        fun move(at: TrackedPosition) {
            positionMillis = at.positionMillis
            if (at.durationMillis > 0) durationMillis = at.durationMillis
        }

        /** The position reached the media server's own watched threshold. */
        val reachedThreshold: Boolean get() = durationMillis > 0 && positionMillis.toDouble() / durationMillis >= threshold

        /** The position as a percentage (0–100) of the duration, 0 while it is unknown. */
        val percent: Double get() = if (durationMillis <= 0) 0.0 else (positionMillis * 100.0 / durationMillis).coerceIn(0.0, 100.0)
    }

    /**
     * One realtime tracker pinned to the playback with the sign-in it had then, and that playback's report
     * bookkeeping: per playback and per tracker, since each service's throttle windows are its own.
     */
    private class PlaybackTarget(b: BoundTracker, val tracker: RealtimeScrobble) {
        val service: TrackerService = b.service
        private var lastState: ScrobbleState? = null
        private var lastSentAt: ComparableTimeMark? = null
        private var lastSeekAt: ComparableTimeMark? = null

        /** A start was accepted for this playback, so the target owns its watch (whether the start lands or not). */
        var sessionStarted = false
            private set

        /** The service accepted the playback's stop, and so applied its own completion rule. */
        var stopConfirmed = false

        fun accepts(state: ScrobbleState, now: ComparableTimeMark): Boolean {
            val policy = tracker.scrobblePolicy
            if (state == ScrobbleState.SEEK) {
                // A checkpoint means something only while the service thinks playback runs, and only so often.
                val throttle = policy.seekThrottle ?: return false
                if (lastState != ScrobbleState.START) return false
                val last = lastSeekAt ?: return true
                return now - last >= throttle
            }
            // A pause or stop with no session behind it (a rolled-back start) would only invent one.
            if (state != ScrobbleState.START && !sessionStarted) return false
            if (lastState != state) return true
            val last = lastSentAt ?: return true
            val elapsed = now - last
            if (elapsed < DUPLICATE_STATE_DEBOUNCE) return false
            return state != ScrobbleState.START || elapsed >= policy.resendThrottle
        }

        fun record(state: ScrobbleState, now: ComparableTimeMark) {
            if (state == ScrobbleState.SEEK) {
                lastSeekAt = now
                // The session keeps playing, so this counts as the latest start.
                lastState = ScrobbleState.START
                lastSentAt = now
                return
            }
            lastState = state
            lastSentAt = now
            if (state == ScrobbleState.START) sessionStarted = true
        }
    }

    /** A container's episodes on one series entry, for the single write it gets. */
    private class SeriesGroup(val base: TrackerContext) {
        private var count = 0
        private var maxProgress: Int? = null

        fun add(context: TrackerContext) {
            count++
            val progress = context.animeProgress ?: return
            if (maxProgress.let { it == null || progress > it }) maxProgress = progress
        }

        /** The entry at the highest mapped progress of its episodes, else their count. */
        fun watchedContext(): TrackerContext {
            val progress = maxProgress ?: count
            return base.copy(episode = progress, animeProgress = progress)
        }
    }

    internal companion object {
        private const val TAG = "trackers"

        private val MARKABLE = setOf(MediaKind.MOVIE, MediaKind.EPISODE, MediaKind.SEASON, MediaKind.SHOW)

        const val SEEK_JUMP_MILLIS = 5_000L

        /** The player reports a state several times around one change. */
        val DUPLICATE_STATE_DEBOUNCE = 1.seconds

        /** Episodes a history request carries. */
        const val HISTORY_BATCH = 100

        /** Failed writes kept in memory while the queue can't persist them. */
        const val UNSAVED_LIMIT = 100

        /** How long a rate limit that doesn't say when to come back (no `Retry-After`) holds its service. */
        val RATE_LIMIT_HOLD = 10.seconds

        /**
         * The remote row a write changes on its service, which queued writes coalesce on: `<svc>|movie|<row>` or
         * `<svc>|s<S>e<E>|<row>` for a history tracker (its [EpisodeHistory.historyRowIdentity]), `<svc>|series|<entry>`
         * for a series tracker. Never the media server's id, which two servers share.
         */
        fun coalesceKey(tracker: Tracker, context: TrackerContext): String? = when (tracker) {
            is SeriesProgress -> tracker.seriesEntryId(context)?.let { "${tracker.service.id}|series|$it" }
            is EpisodeHistory -> tracker.historyRowIdentity(context)?.let { row ->
                val coordinate = if (context.isMovie) "movie" else "s${context.season}e${context.episode}"
                "${tracker.service.id}|$coordinate|$row"
            }
            else -> null
        }

        /** The absolute progress a watched write claims, for series-progress trackers; `null` for history writes. */
        fun progressClaim(tracker: Tracker, context: TrackerContext): Long? =
            (tracker as? SeriesProgress)?.seriesProgress(context)?.toLong()

        /**
         * A drain's units, in the order of their first row: rows of a service [batches] answers `true` for, grouped by
         * service and direction up to [HISTORY_BATCH] a unit; every other row alone.
         */
        fun replayUnits(rows: List<QueuedTrackerWrite>, batches: (TrackerService) -> Boolean): List<List<QueuedTrackerWrite>> {
            val units = mutableListOf<MutableList<QueuedTrackerWrite>>()
            val open = mutableMapOf<Pair<TrackerService, Boolean>, MutableList<QueuedTrackerWrite>>()
            for (row in rows) {
                if (!batches(row.service)) {
                    units += mutableListOf(row)
                    continue
                }
                val key = row.service to row.watched
                val unit = open[key]?.takeIf { it.size < HISTORY_BATCH } ?: mutableListOf<QueuedTrackerWrite>().also {
                    open[key] = it
                    units += it
                }
                unit += row
            }
            return units
        }
    }
}

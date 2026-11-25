package com.edde746.plezy.trackers

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.data.tracker.TrackerAccountRepository
import com.edde746.plezy.data.tracker.TrackerWriteQueue
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.profiles.profileUserScope
import com.edde746.plezy.servers.ProfileTrackerWatchMarks
import com.edde746.plezy.servers.TrackerWatchMarks
import com.edde746.plezy.trackers.ratings.TrackerRatings
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Clock
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

/**
 * The trackers of one app process: the [accounts] of every profile on this device and one [TrackerCoordinator] per
 * profile scope (a Plex Home user's profiles on every account share one), which lives as long as the hub; and the
 * connected trackers' public scores ([ratings]). Writes go through the device-wide switches in [settings] (scrobble
 * toggles, Trakt's watched sync, library filters).
 *
 * The queued-write replays it triggers, for the active profile ([onActiveProfileChanged]): the profile becoming
 * active, an account connecting, and the platform's [onForeground] and [onNetworkRestored]. Main-thread confined.
 */
class TrackerHub internal constructor(
    accountRepository: TrackerAccountRepository,
    private val queue: TrackerWriteQueue,
    settings: DeviceSettingsRepository,
    tokens: TrackerTokenStore,
    providers: List<TrackerProvider>,
    private val resolvers: TrackerIdResolverFactory,
    relay: OAuthRelay?,
    private val clock: Clock,
    private val timeSource: TimeSource.WithComparableMarks,
    private val scope: CoroutineScope,
) {
    private val coordinators = mutableMapOf<String, TrackerCoordinator>()
    private val gates = TrackerGates(settings)
    private var activeProfileId: String? = null

    /** Sign-in and connections; connecting replays the profile's queued writes. */
    val accounts: TrackerAccounts = TrackerAccounts(
        repository = accountRepository,
        tokens = tokens,
        providers = providers,
        relay = relay,
        clock = clock,
        timeSource = timeSource,
        onConnected = { profileId -> coordinator(profileId).replayQueuedWrites() },
    )

    /** The connected trackers' community scores of a title, kept per title for every profile of the process. */
    val ratings: TrackerRatings = TrackerRatings({ accounts.ratingsSources(it) }, resolvers, timeSource)

    /** The user's own scores at the connected trackers, for the rating sheet. */
    val userRatings: UserRatings = UserRatings(accounts, resolvers)

    init {
        scope.launch {
            try {
                accounts.adoptLegacyScopes()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "moving tracker connections to their profile scopes failed" }
            }
            // Sessions never outlive their connection, whichever way it went.
            accountRepository.observeConnections().collect {
                try {
                    accounts.clearUnusedTokens()
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    Log.w(TAG, e) { "clearing unused tracker sessions failed" }
                }
            }
        }
    }

    /** The profile's coordinator, created on first use (which replays what an earlier run left queued). */
    fun coordinator(profileId: String): TrackerCoordinator = coordinators.getOrPut(profileUserScope(profileId)) {
        TrackerCoordinator(
            profileId = profileId,
            accounts = accounts,
            gates = gates,
            resolvers = resolvers,
            queue = queue,
            clock = clock,
            timeSource = timeSource,
            parentScope = scope,
        )
    }

    /**
     * The app's profile changed to [profileId] (`null`: none): a sign-in in flight is cancelled; every other profile
     * scope's coordinator drops its playback, waiting reports and resolver and stops the container mark or replay under
     * way; the new profile's queued writes are replayed.
     */
    fun onActiveProfileChanged(profileId: String?) {
        accounts.cancelConnect()
        activeProfileId = profileId
        val active = profileId?.let(::profileUserScope)
        for ((scope, coordinator) in coordinators) if (scope != active) coordinator.cancelInFlight()
        if (profileId == null) return
        // A new coordinator replays as it starts.
        coordinators[active]?.replayQueuedWrites() ?: coordinator(profileId)
    }

    /**
     * Manual marks for the app's servers layer, which outlives profile switches: each goes to the coordinator of the
     * profile [activeProfileId] names when it is made, and nowhere without one.
     */
    fun watchMarks(activeProfileId: () -> String?): TrackerWatchMarks = TrackerWatchMarks { item, backend, watched ->
        activeProfileId()?.let { coordinator(it).watchMarks.mark(item, backend, watched) }
    }

    /** Each profile's marks, for work that outlives a profile switch: they reach that profile's coordinator only. */
    val profileWatchMarks: ProfileTrackerWatchMarks = ProfileTrackerWatchMarks { profileId -> coordinator(profileId).watchMarks }

    /**
     * The player's playback observer for the app's whole life: each video goes to the coordinator of the profile
     * active when it starts ([activeProfileId], read then), and the rest of its events with it; none while no profile
     * is active. One producer of playbacks (the player) takes one.
     */
    fun playback(activeProfileId: () -> String?): TrackedPlayback = object : TrackedPlayback {
        private val observers = HashMap<String, TrackedPlayback>()
        private var current: TrackedPlayback? = null

        override fun onVideoStarted(item: MediaItem, backend: MediaBackend, at: TrackedPosition, playing: Boolean, live: Boolean) {
            current = activeProfileId()?.let { id -> observers.getOrPut(id) { coordinator(id).observer() } }
            current?.onVideoStarted(item, backend, at, playing, live)
        }

        override fun onPlayingChanged(playing: Boolean, at: TrackedPosition) {
            current?.onPlayingChanged(playing, at)
        }

        override fun onPosition(at: TrackedPosition) {
            current?.onPosition(at)
        }

        override fun onVideoStopped(at: TrackedPosition) {
            current?.onVideoStopped(at)
            current = null
        }
    }

    /**
     * Drops [service]'s queued writes of the profile, so none replays through the account that connects next (a
     * disconnect, a session found dead). Never throws: a purge that fails is logged.
     */
    suspend fun purgeWriteQueue(profileId: String, service: TrackerService) {
        try {
            coordinators[profileUserScope(profileId)]?.purgeWrites(service) ?: queue.removeService(profileId, service)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "${service.id}: write queue purge failed" }
        }
    }

    /** The app came back to the foreground: replay the active profile's queued writes. */
    fun onForeground() = activeCoordinator()?.replayQueuedWrites()

    /** The network came back: replay the active profile's queued writes. */
    fun onNetworkRestored() = activeCoordinator()?.replayQueuedWrites()

    /**
     * The app is shutting down: the open playback's stop goes out (waited for up to [SHUTDOWN_STOP_TIMEOUT]), then
     * every coordinator's work still running is cancelled.
     */
    suspend fun shutdown() {
        val running = coordinators.values.toList()
        val stopped = withTimeoutOrNull(SHUTDOWN_STOP_TIMEOUT) { running.forEach { it.stopPlayback() } }
        if (stopped == null) Log.w(TAG) { "tracker playback stop didn't complete within $SHUTDOWN_STOP_TIMEOUT" }
        running.forEach { it.close() }
    }

    private fun activeCoordinator(): TrackerCoordinator? = activeProfileId?.let(::coordinator)

    private companion object {
        const val TAG = "trackers"

        val SHUTDOWN_STOP_TIMEOUT = 3.seconds
    }
}

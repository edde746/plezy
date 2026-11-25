package com.edde746.plezy.presentation.ratings

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.strings.T
import com.edde746.plezy.trackers.ItemRatings
import com.edde746.plezy.trackers.RatingAccount
import com.edde746.plezy.trackers.RatingTarget
import com.edde746.plezy.trackers.TrackerException
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.UserRatings
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlin.coroutines.cancellation.CancellationException
import kotlin.math.roundToInt
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

/** A row of the rating sheet. */
sealed interface RatingRowKey {
    /** The media server's own rating or favorite. */
    data object Server : RatingRowKey

    data class Tracker(val service: TrackerService) : RatingRowKey
}

/** What a row says after its last load or save: [isError] shows it in place of the subtitle, in the error style. */
data class RatingRowStatus(val text: String, val isError: Boolean)

/**
 * The server's row: 5 stars in half steps ([value] 0–10, each star 2) where the server takes numeric ratings, else a
 * favorite toggle ([favorite]). [loading]: a save is on its way; the control is disabled.
 */
data class ServerRatingRow(
    val favoriteOnly: Boolean,
    val title: String,
    val subtitle: String,
    val value: Int,
    val favorite: Boolean,
    val loading: Boolean,
    val status: RatingRowStatus?,
)

/** A tracker's row: 5 stars in half steps, [value] 0–10 (0: not rated); [loading] while it reads or saves. */
data class TrackerRatingRow(
    val service: TrackerService,
    val title: String,
    val subtitle: String,
    val value: Int,
    val loading: Boolean,
    val status: RatingRowStatus?,
)

/**
 * The rating sheet: the [server] row when the server rates or keeps favorites, then one row per connected tracker in
 * a fixed order; [noConnectedServices] is the text shown instead when no tracker is connected. [message] is an error
 * to show as a snackbar until [RatingSheetStore.messageShown].
 */
data class RatingSheetUiState(
    val title: String,
    val server: ServerRatingRow?,
    val trackers: List<TrackerRatingRow>,
    val noConnectedServices: String?,
    val message: String?,
)

/**
 * The rating sheet of one media item ("Rate" in its menu). Its rows are fixed when it opens: a tracker that can't rate
 * the item keeps its row and says so. The trackers' scores load at once, in parallel, after the item's ids resolve.
 *
 * A change ([change], [step]) saves after [AUTO_SAVE_DELAY] without another; [submit] saves now. A score of 0 removes
 * the rating. Saves still pending when the sheet closes ([release]) go out in [appScope], their failures only logged.
 * [onServerRatingChanged] (0–10, 0 for none) and [onServerFavoriteChanged] tell the item's screens to refresh it.
 * Main thread only.
 */
class RatingSheetStore internal constructor(
    private val ratings: ItemRatings,
    private val item: MediaItem,
    private val backend: MediaBackend?,
    private val appScope: CoroutineScope,
    private val onServerRatingChanged: (Double) -> Unit,
    private val onServerFavoriteChanged: (Boolean) -> Unit,
) {
    private val scope = appScope.childScope()
    private val accounts: Map<TrackerService, RatingAccount> = ratings.accounts.associateBy { it.service }
    private val autoSaves = mutableMapOf<RatingRowKey, Job>()

    private val mutableState = MutableStateFlow(initialState())

    val state: StateFlow<RatingSheetUiState> = mutableState.asStateFlow()

    init {
        if (accounts.isNotEmpty()) scope.launch { loadScores() }
    }

    /** The value of [key]'s control changed (a drag, a key press): saved after [AUTO_SAVE_DELAY] without another. */
    fun change(key: RatingRowKey, value: Int) {
        if (!update(key, value)) return
        autoSaves.remove(key)?.cancel()
        autoSaves[key] = scope.launch {
            delay(AUTO_SAVE_DELAY)
            autoSaves.remove(key)
            save(key)
        }
    }

    /** Left (−1) or right (+1) on [key]'s row: a favorite row unsets or sets the favorite. */
    fun step(key: RatingRowKey, delta: Int) {
        val current = when (key) {
            RatingRowKey.Server -> mutableState.value.server?.let { if (it.favoriteOnly) (if (it.favorite) 1 else 0) else it.value }
            is RatingRowKey.Tracker -> row(key.service)?.value
        } ?: return
        change(key, current + delta)
    }

    /**
     * Saves [key]'s row now: [value] where the control gave one (a tap, the end of a drag), else what it shows; a
     * favorite row without [value] flips the favorite (select on the row).
     */
    fun submit(key: RatingRowKey, value: Int? = null) {
        if (loading(key)) return
        val server = mutableState.value.server
        val next = value ?: if (key == RatingRowKey.Server && server?.favoriteOnly == true) (if (server.favorite) 0 else 1) else null
        if (next != null) update(key, next)
        autoSaves.remove(key)?.cancel()
        scope.launch { save(key) }
    }

    fun messageShown() {
        mutableState.value = mutableState.value.copy(message = null)
    }

    /** The sheet closed: changes still waiting to save are saved anyway, without anyone watching. */
    fun release() {
        val pending = autoSaves.keys.toList()
        autoSaves.values.forEach { it.cancel() }
        autoSaves.clear()
        scope.cancel()
        val state = mutableState.value
        for (key in pending) {
            appScope.launch {
                try {
                    when (key) {
                        RatingRowKey.Server -> state.server?.let { saveServer(it) }
                        is RatingRowKey.Tracker -> {
                            val account = accounts[key.service] ?: return@launch
                            val target = ratings.target() ?: return@launch
                            ratings.rate(account, target, row(state, key.service)?.value ?: 0)
                        }
                    }
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    Log.w(TAG, e) { "rating not saved after the sheet closed" }
                }
            }
        }
        ratings.close()
    }

    private suspend fun loadScores() {
        val services = accounts.keys
        val target = try {
            ratings.target()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            // The server or the anime mapping didn't answer: settle the rows, or they spin forever.
            Log.w(TAG, e) { "the item's tracker ids didn't resolve" }
            setTrackers(services) { it.copy(loading = false, status = failed()) }
            return
        }
        if (target == null) {
            setTrackers(services) { it.copy(loading = false, status = notAvailable()) }
            return
        }
        for (account in accounts.values) {
            scope.launch {
                val service = account.service
                val status = try {
                    val score = ratings.score(account, target)
                    setTrackers(setOf(service)) { it.copy(value = (score ?: 0).coerceIn(0, 10)) }
                    null
                } catch (e: CancellationException) {
                    throw e
                } catch (e: TrackerException.Unsupported) {
                    Log.d(TAG) { "${service.id} can't rate this item: ${e.message}" }
                    notAvailable()
                } catch (e: Exception) {
                    Log.w(TAG, e) { "${service.id} rating not read" }
                    failed()
                }
                setTrackers(setOf(service)) { it.copy(loading = false, status = status) }
            }
        }
    }

    /** Saves what [key]'s row shows, the row spinning meanwhile; a failure other than "not available" is a snackbar. */
    private suspend fun save(key: RatingRowKey) {
        setLoading(key, loading = true, status = null)
        val status = try {
            when (key) {
                RatingRowKey.Server -> mutableState.value.server?.let { saveServer(it) }
                is RatingRowKey.Tracker -> saveTracker(key.service)
            }
            RatingRowStatus(T.rateSheet.saved, isError = false)
        } catch (e: CancellationException) {
            throw e
        } catch (e: TrackerException.Unsupported) {
            Log.d(TAG) { "rating not available: ${e.message}" }
            notAvailable()
        } catch (e: NotAvailable) {
            notAvailable()
        } catch (e: Exception) {
            Log.w(TAG, e) { "rating not saved" }
            mutableState.value = mutableState.value.copy(message = T.errors.failedToRate)
            failed()
        }
        setLoading(key, loading = false, status = status)
    }

    private suspend fun saveServer(row: ServerRatingRow) {
        val backend = backend ?: return
        if (row.favoriteOnly) {
            backend.setFavorite(item, row.favorite)
            onServerFavoriteChanged(row.favorite)
        } else if (row.value <= 0) {
            backend.rate(item, -1.0)
            onServerRatingChanged(0.0)
        } else {
            backend.rate(item, row.value.toDouble())
            onServerRatingChanged(row.value.toDouble())
        }
    }

    private suspend fun saveTracker(service: TrackerService) {
        val account = accounts[service] ?: return
        val target: RatingTarget = ratings.target() ?: throw NotAvailable()
        ratings.rate(account, target, row(service)?.value ?: 0)
    }

    /** Sets [key]'s control to [value] (clamped), clearing its status; `false` when nothing changed or it is busy. */
    private fun update(key: RatingRowKey, value: Int): Boolean {
        if (loading(key)) return false
        val state = mutableState.value
        when (key) {
            RatingRowKey.Server -> {
                val server = state.server ?: return false
                val next = if (server.favoriteOnly) {
                    val favorite = value > 0
                    if (favorite == server.favorite) return false
                    server.copy(favorite = favorite, status = null)
                } else {
                    val stars = value.coerceIn(0, 10)
                    if (stars == server.value) return false
                    server.copy(value = stars, status = null)
                }
                mutableState.value = state.copy(server = next)
            }
            is RatingRowKey.Tracker -> {
                val stars = value.coerceIn(0, 10)
                if (row(key.service)?.value == stars) return false
                setTrackers(setOf(key.service)) { it.copy(value = stars, status = null) }
            }
        }
        return true
    }

    private fun loading(key: RatingRowKey): Boolean = when (key) {
        RatingRowKey.Server -> mutableState.value.server?.loading == true
        is RatingRowKey.Tracker -> row(key.service)?.loading == true
    }

    private fun setLoading(key: RatingRowKey, loading: Boolean, status: RatingRowStatus?) {
        when (key) {
            RatingRowKey.Server -> {
                val state = mutableState.value
                mutableState.value = state.copy(server = state.server?.copy(loading = loading, status = status))
            }
            is RatingRowKey.Tracker -> setTrackers(setOf(key.service)) { it.copy(loading = loading, status = status) }
        }
    }

    private fun setTrackers(services: Set<TrackerService>, change: (TrackerRatingRow) -> TrackerRatingRow) {
        val state = mutableState.value
        mutableState.value = state.copy(trackers = state.trackers.map { if (it.service in services) change(it) else it })
    }

    private fun row(service: TrackerService): TrackerRatingRow? = row(mutableState.value, service)

    private fun row(state: RatingSheetUiState, service: TrackerService): TrackerRatingRow? = state.trackers.firstOrNull { it.service == service }

    private fun initialState(): RatingSheetUiState {
        val capabilities = backend?.capabilities
        val server = if (backend != null && capabilities != null && (capabilities.numericUserRating || capabilities.userFavorites)) {
            ServerRatingRow(
                favoriteOnly = !capabilities.numericUserRating,
                title = T.rateSheet.server,
                subtitle = "${backend.backend.dialect?.productName ?: "Plex"} - ${backend.serverName ?: item.serverName ?: T.common.unknown}",
                value = item.userRating?.takeIf { it > 0 }?.roundToInt()?.coerceIn(0, 10) ?: 0,
                favorite = item.isFavorite == true,
                loading = false,
                status = null,
            )
        } else {
            null
        }
        return RatingSheetUiState(
            title = T.rateSheet.title,
            server = server,
            trackers = ratings.accounts.map { account ->
                TrackerRatingRow(
                    service = account.service,
                    title = serviceName(account.service),
                    subtitle = account.username?.let(T.services::connectedAs) ?: T.trakt.connected,
                    value = 0,
                    // Read at once.
                    loading = true,
                    status = null,
                )
            },
            noConnectedServices = T.rateSheet.noConnectedServices.takeIf { ratings.accounts.isEmpty() },
            message = null,
        )
    }

    /** The item has no ids a tracker could name it by. */
    private class NotAvailable : Exception("no tracker ids for the item")

    companion object {
        private const val TAG = "ratings"

        /** How long a changed score waits for another change before it saves. */
        val AUTO_SAVE_DELAY: Duration = 600.milliseconds

        /**
         * Opens the sheet for [item] of [backend] (`null`: its server is offline, so no server row and no tracker
         * ids), with the profile's connected trackers as they are now. [appScope] must outlive the sheet: pending
         * saves go out there when it closes.
         */
        suspend fun open(
            userRatings: UserRatings,
            profileId: String,
            item: MediaItem,
            backend: MediaBackend?,
            appScope: CoroutineScope,
            onServerRatingChanged: (Double) -> Unit = {},
            onServerFavoriteChanged: (Boolean) -> Unit = {},
        ): RatingSheetStore = RatingSheetStore(
            ratings = userRatings.open(profileId, item, backend),
            item = item,
            backend = backend,
            appScope = appScope,
            onServerRatingChanged = onServerRatingChanged,
            onServerFavoriteChanged = onServerFavoriteChanged,
        )

        private fun notAvailable() = RatingRowStatus(T.rateSheet.notAvailable, isError = true)

        private fun failed() = RatingRowStatus(T.errors.failedToRate, isError = true)

        private fun serviceName(service: TrackerService): String = when (service) {
            TrackerService.TRAKT -> T.trakt.title
            TrackerService.SIMKL -> T.services.names.simkl
            TrackerService.MDBLIST -> T.services.names.mdblist
            TrackerService.MYANIMELIST -> T.services.names.mal
            TrackerService.ANILIST -> T.services.names.anilist
        }
    }
}

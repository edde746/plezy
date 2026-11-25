package com.edde746.plezy.presentation.trackers

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.catalog.matching.LibraryWatchlistCandidates
import com.edde746.plezy.catalog.matching.WatchlistCandidate
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.merge
import kotlinx.coroutines.launch
import kotlin.coroutines.cancellation.CancellationException

/**
 * A detail page's watchlist button: [onWatchlist] true when the item is on any source's watchlist (a filled mark),
 * false when on none, null while every source's membership is still unknown ([enabled] false: touch and the pointer
 * can't press it; a remote's press loads the watchlists). [label] says what a press does. [chooser], while open, lists
 * the sources to pick from, anchored on the button; [sources] lists them at all times where there are several (Apple
 * TV's menu on the button). [message] is a failure to show once.
 */
data class DetailWatchlistUi(
    val onWatchlist: Boolean?,
    val label: String,
    val enabled: Boolean,
    val chooser: List<WatchlistSourceOption>? = null,
    val message: String? = null,
    val sources: List<WatchlistSourceOption>? = null,
)

/** A source in the watchlist chooser: its [logo], [name], whether the item is on its watchlist ([member]) and what picking it does ([action]). */
data class WatchlistSourceOption(val logo: CatalogSourceId, val name: String, val member: Boolean, val action: String)

/** The chooser's option for [source] given its membership ([member]: null unknown, counted as not on it). */
internal fun watchlistSourceOption(source: CatalogSourceId, member: Boolean?): WatchlistSourceOption {
    val on = member == true
    return WatchlistSourceOption(source, source.displayName, on, if (on) T.explore.removeFromWatchlist else T.explore.addToWatchlist)
}

/**
 * The watchlist button of a movie's or show's detail page ([state] null: no button, as for other kinds or an item no
 * connected source can hold). [item] waits for the page's item (null: none); its candidates come from the session's
 * [candidates] (shared with the item menus), every source's watchlist loads as the page opens, and the button follows
 * each source's changes. A press toggles the one candidate, or opens the chooser of several ([choose] toggles the
 * picked source by its own membership); one change runs at a time, and a failed one leaves a message. [release] when
 * the page goes.
 */
class DetailWatchlistStore internal constructor(
    item: suspend () -> MediaItem?,
    private val candidates: LibraryWatchlistCandidates,
    client: MediaBackend?,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()
    private val mutableState = MutableStateFlow<DetailWatchlistUi?>(null)
    private var kind = MediaKind.MOVIE
    private var found: List<WatchlistCandidate> = emptyList()
    private var chooser: List<WatchlistCandidate>? = null
    private var message: String? = null
    private var inFlight = false

    val state: StateFlow<DetailWatchlistUi?> = mutableState.asStateFlow()

    init {
        scope.launch {
            val loaded = item() ?: return@launch
            val serverId = ServerId.tryParse(loaded.serverId) ?: return@launch
            if (loaded.kind != MediaKind.MOVIE && loaded.kind != MediaKind.SHOW) return@launch
            kind = loaded.kind
            found = try {
                candidates.watchlistCandidatesFor(serverId, loaded.id, kind, client)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Watchlist candidates of ${loaded.id} failed" }
                emptyList()
            }
            publish()
            if (found.isEmpty()) return@launch
            loadWatchlists()
            merge(*found.map { it.source.watchlistChanges }.distinct().toTypedArray()).collect { publish() }
        }
    }

    /**
     * The button's press: nothing while a change runs; while every membership is unknown it loads the watchlists (a
     * remote's press on the disabled button); one candidate toggles; several open the chooser.
     */
    fun press() {
        if (inFlight || found.isEmpty()) return
        if (found.all { it.isMember() == null }) {
            loadWatchlists()
            return
        }
        if (found.size == 1) {
            toggle(found.single())
            return
        }
        chooser = found
        publish()
    }

    /** Picks the chooser's option at [index] (null: dismissed), toggling that source by its own membership. */
    fun choose(index: Int?) {
        val options = chooser ?: return
        chooser = null
        publish()
        index?.let { toggle(options[it]) }
    }

    /** Toggles the source at [index] of [DetailWatchlistUi.sources] by its own membership. */
    fun toggleSource(index: Int) {
        if (found.size > 1) found.getOrNull(index)?.let { toggle(it) }
    }

    /** The view showed [DetailWatchlistUi.message]. */
    fun messageShown() {
        message = null
        publish()
    }

    fun release() = scope.cancel()

    private fun toggle(candidate: WatchlistCandidate) {
        val current = candidate.isMember() ?: return
        if (inFlight) return
        inFlight = true
        scope.launch {
            try {
                candidates.mutateWatchlistMembership(kind, candidate, add = !current)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Watchlist change on ${candidate.source.id.id} failed" }
                message = T.explore.watchlistUpdateFailed
            } finally {
                inFlight = false
                publish()
            }
        }
    }

    private fun loadWatchlists() {
        for (candidate in found) scope.launch { candidate.source.ensureWatchlistLoaded() }
    }

    private fun publish() {
        if (found.isEmpty()) {
            mutableState.value = null
            return
        }
        val members = found.map { it.isMember() }
        val onWatchlist = when {
            true in members -> true
            false in members -> false
            else -> null
        }
        mutableState.value = DetailWatchlistUi(
            onWatchlist = onWatchlist,
            label = if (onWatchlist == true) T.explore.removeFromWatchlist else T.explore.addToWatchlist,
            enabled = onWatchlist != null,
            chooser = chooser?.map { it.option() },
            message = message,
            sources = found.takeIf { it.size > 1 }?.map { it.option() },
        )
    }

    private fun WatchlistCandidate.option(): WatchlistSourceOption = watchlistSourceOption(source.id, isMember())

    private fun WatchlistCandidate.isMember(): Boolean? = source.isOnWatchlist(kind, ids)

    private companion object {
        const val TAG = "DetailWatchlist"
    }
}

package com.edde746.plezy.app

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.localizedErrorReason
import com.edde746.plezy.catalog.CatalogSource
import com.edde746.plezy.catalog.matching.LibraryWatchlistCandidates
import com.edde746.plezy.catalog.matching.WatchlistCandidate
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.browse.MenuEntry
import com.edde746.plezy.presentation.browse.MenuEntryProvider
import com.edde746.plezy.presentation.browse.MenuIcon
import com.edde746.plezy.presentation.browse.MenuMessage
import com.edde746.plezy.presentation.browse.MenuOption
import com.edde746.plezy.presentation.browse.MenuPlace
import com.edde746.plezy.presentation.browse.MenuPrompt
import com.edde746.plezy.presentation.browse.MenuSlot
import com.edde746.plezy.presentation.browse.MenuTarget
import com.edde746.plezy.presentation.ratings.RatingSheetStore
import com.edde746.plezy.presentation.trackers.watchlistSourceOption
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch
import kotlin.coroutines.cancellation.CancellationException

/** The rating sheet an item menu's Rate opened ([AppSession.ratingSheet]): its [store], and the [backend] it rates on. */
data class OpenRatingSheet(val store: RatingSheetStore, val backend: BackendKind)

/**
 * Rate in a video item's menu ([MenuSlot.RATE]; the menu offers the slot for video kinds only): opens the rating sheet
 * over the item ([open]), its server row on the item's own server while that server answers.
 */
internal class RateMenuEntries(
    private val client: (ServerId) -> MediaBackend?,
    private val isOnline: (ServerId) -> Boolean,
    private val open: suspend (MediaItem, MediaBackend?) -> Unit,
) : MenuEntryProvider {
    override val slot: MenuSlot get() = MenuSlot.RATE

    override fun entries(target: MenuTarget, place: MenuPlace): List<MenuEntry> =
        if (target is MenuTarget.Item && target.item.isVideoContent) listOf(MenuEntry(RATE, T.mediaMenu.rate, MenuIcon.STAR)) else emptyList()

    override suspend fun perform(target: MenuTarget, place: MenuPlace, entryId: String): MenuMessage? {
        val item = (target as? MenuTarget.Item)?.item ?: return null
        val backend = ServerId.tryParse(item.serverId)?.takeIf(isOnline)?.let(client)
        return try {
            open(item, backend)
            null
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Opening the rating sheet of ${item.id} failed" }
            MenuMessage(T.messages.errorLoading(error = localizedErrorReason(e)), isError = true)
        }
    }

    companion object {
        const val RATE = "rate"
    }
}

/**
 * Add to / Remove from Watchlist in a movie's or show's menu ([MenuSlot.WATCHLIST]), through the active profile's
 * watchlist-capable catalog sources ([sources]) and the session's [candidates]: offered while one of them is connected,
 * the item's server answers and the app isn't offline, unless the item's candidates are known to be none. The label
 * says Remove only when the known candidates show the item on a watchlist; the candidates and the watchlists are
 * fetched apart ([warm], [warmAhead]). Picking the entry resolves the candidates: one is toggled as the label said,
 * unless it is already as the label asks (a label from candidates since changed), which needs nothing; several open a
 * chooser of sources ([choose]), each toggled by its own membership.
 */
internal class WatchlistMenuEntries(
    private val candidates: () -> LibraryWatchlistCandidates,
    private val sources: () -> List<CatalogSource>,
    private val client: (ServerId) -> MediaBackend?,
    private val isOnline: (ServerId) -> Boolean,
    private val isOffline: () -> Boolean,
    private val choose: suspend (MenuPrompt.Options) -> Int?,
    private val scope: CoroutineScope,
) : MenuEntryProvider {
    override val slot: MenuSlot get() = MenuSlot.WATCHLIST

    override fun entries(target: MenuTarget, place: MenuPlace): List<MenuEntry> {
        val item = (target as? MenuTarget.Item)?.item ?: return emptyList()
        if (item.kind != MediaKind.MOVIE && item.kind != MediaKind.SHOW) return emptyList()
        val serverId = ServerId.tryParse(item.serverId) ?: return emptyList()
        val sources = sources()
        if (sources.isEmpty() || !isOnline(serverId) || isOffline()) return emptyList()
        val cached = candidates().cachedWatchlistCandidatesFor(serverId, item.id)
        if (cached != null && cached.isEmpty()) return emptyList()
        return if (cached.orEmpty().any { it.isMember(item.kind) == true }) {
            listOf(MenuEntry(REMOVE, T.explore.removeFromWatchlist, MenuIcon.BOOKMARK_REMOVE))
        } else {
            listOf(MenuEntry(ADD, T.explore.addToWatchlist, MenuIcon.BOOKMARK_ADD))
        }
    }

    override suspend fun perform(target: MenuTarget, place: MenuPlace, entryId: String): MenuMessage? {
        val item = (target as? MenuTarget.Item)?.item ?: return null
        val serverId = ServerId.tryParse(item.serverId) ?: return null
        val found = try {
            candidates().watchlistCandidatesFor(serverId, item.id, item.kind, client(serverId))
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Watchlist candidates of ${item.id} failed" }
            return failed()
        }
        val (candidate, add) = when (found.size) {
            0 -> return MenuMessage(T.explore.watchlistNoMatch)
            // The intent the menu showed: Remove only when it said so.
            1 -> {
                val add = entryId == ADD
                // Already as the label asks: nothing to change, and nothing went wrong.
                if (found.single().isMember(item.kind) == add) {
                    return MenuMessage(if (add) T.explore.addedToWatchlist else T.explore.removedFromWatchlist)
                }
                found.single() to add
            }
            else -> {
                val options = found.map { c ->
                    val option = watchlistSourceOption(c.source.id, c.isMember(item.kind))
                    MenuOption(option.name, if (option.member) MenuIcon.BOOKMARK_REMOVE else MenuIcon.BOOKMARK_ADD, option.action, option.logo)
                }
                val chosen = found[choose(MenuPrompt.Options(T.explore.rows.watchlist, options)) ?: return null]
                chosen to (chosen.isMember(item.kind) != true)
            }
        }
        val ran = try {
            candidates().mutateWatchlistMembership(item.kind, candidate, add)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Watchlist ${if (add) "add" else "removal"} on ${candidate.source.id.id} failed" }
            return failed()
        }
        // The same change already running: nothing ran, nothing to say.
        if (!ran) return null
        return MenuMessage(if (add) T.explore.addedToWatchlist else T.explore.removedFromWatchlist)
    }

    /** Resolves the item's candidates and loads every source's watchlist, so the next label is known. */
    override fun warm(target: MenuTarget) {
        val item = (target as? MenuTarget.Item)?.item ?: return
        if (item.kind != MediaKind.MOVIE && item.kind != MediaKind.SHOW) return
        val serverId = ServerId.tryParse(item.serverId) ?: return
        val sources = sources()
        if (sources.isEmpty() || !isOnline(serverId) || isOffline()) return
        if (candidates().cachedWatchlistCandidatesFor(serverId, item.id)?.isEmpty() == true) return
        scope.launch {
            try {
                candidates().watchlistCandidatesFor(serverId, item.id, item.kind, client(serverId))
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.d(TAG, e) { "Warming the watchlist candidates of ${item.id} failed" }
            }
        }
        for (source in sources) scope.launch { source.ensureWatchlistLoaded() }
    }

    /**
     * Loads every source's watchlist (one load per source for the session, whichever menu asks first) and the item's
     * candidates (its ids from its own server, once per item for the session), so a card already on a watchlist offers
     * Remove in its menu. True when either wasn't known yet.
     */
    override suspend fun warmAhead(target: MenuTarget): Boolean {
        val item = (target as? MenuTarget.Item)?.item ?: return false
        if (item.kind != MediaKind.MOVIE && item.kind != MediaKind.SHOW) return false
        val serverId = ServerId.tryParse(item.serverId) ?: return false
        val sources = sources().filter { it.supportsWatchlist }
        if (sources.isEmpty() || !isOnline(serverId) || isOffline()) return false
        val known = candidates().cachedWatchlistCandidatesFor(serverId, item.id)
        if (known?.isEmpty() == true) return false
        val candidates = known ?: candidates().watchlistCandidatesFor(serverId, item.id, item.kind, client(serverId))
        val unloaded = candidates.filter { it.isMember(item.kind) == null }
        coroutineScope { unloaded.map { launch { it.source.ensureWatchlistLoaded() } } }
        // An answer missing a source that failed to resolve isn't kept, and the menu labels from what is kept.
        checkNotNull(candidates().cachedWatchlistCandidatesFor(serverId, item.id)) { "Watchlist candidates of ${item.id} are partial" }
        return known == null || unloaded.isNotEmpty()
    }

    private fun WatchlistCandidate.isMember(kind: MediaKind): Boolean? = source.isOnWatchlist(kind, ids)

    private fun failed() = MenuMessage(T.explore.watchlistUpdateFailed, isError = true)

    companion object {
        const val ADD = "watchlist_add"
        const val REMOVE = "watchlist_remove"
    }
}

private const val TAG = "TrackerMenus"

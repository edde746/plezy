package com.edde746.plezy.presentation.catalog

import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.youTubeAppUrl
import com.edde746.plezy.log.Log
import com.edde746.plezy.presentation.explore.CatalogSourcesState
import com.edde746.plezy.strings.T
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

/** What an entry of a catalog card's menu does. */
sealed interface CatalogMenuAction {
    /** Opens the title's detail screen (the UI navigates). */
    data object ViewDetails : CatalogMenuAction

    /** Opens the provider's trailer in another app. */
    data class Trailer(val url: String) : CatalogMenuAction

    /** Opens the provider's page on a site. */
    data class Link(val url: String) : CatalogMenuAction

    /** Adds the title to its watchlist ([add]) or removes it. */
    data class Watchlist(val add: Boolean) : CatalogMenuAction
}

/** One entry of a catalog card's menu, its [label] ready to show. */
data class CatalogMenuEntry(val label: String, val action: CatalogMenuAction)

/**
 * A catalog card's menu (Explore's shelves, catalog search, More like this): its entries for an item and what they do.
 * Server-backed actions have no place here: a catalog title has no server.
 *
 * - View details; Watch trailer when this device can open the trailer (the web link, or without a browser the YouTube
 *   app's link once [CatalogDetailHost.youTubeAppInstalled]); "Open on <site>" for each http(s) link with a name
 *   (none without a browser); Add to or Remove from Watchlist only while the title's watchlist membership is known
 *   ([CatalogSourcesState.watchlistSourceFor]). Unknown membership loads in the background, for the next opening.
 * - A watchlist change reads the membership again (it may have changed while the menu was open); one change per title
 *   at a time.
 *
 * Call everything on the main thread.
 */
class CatalogItemMenu(
    private val sources: StateFlow<CatalogSourcesState>,
    private val host: CatalogDetailHost,
    private val scope: CoroutineScope,
) {
    private val mutating = mutableSetOf<String>()

    /** [item]'s entries, in order. */
    suspend fun entries(item: CatalogItem): List<CatalogMenuEntry> {
        val source = sources.value.watchlistSourceFor(item)
        val onWatchlist = source?.isOnWatchlist(item.kind, item.ids)
        if (source != null && onWatchlist == null) scope.launch { source.ensureWatchlistLoaded() }
        val entries = mutableListOf(CatalogMenuEntry(T.mediaMenu.viewDetails, CatalogMenuAction.ViewDetails))
        trailerUrl(item)?.let { entries += CatalogMenuEntry(T.explore.detail.watchTrailer, CatalogMenuAction.Trailer(it)) }
        if (host.hasBrowser) {
            for (link in item.links.orEmpty()) {
                val url = webUrl(link.url) ?: continue
                if (link.label.isNotEmpty()) entries += CatalogMenuEntry(T.explore.detail.openOn(link.label), CatalogMenuAction.Link(url))
            }
        }
        if (onWatchlist != null) {
            val label = if (onWatchlist) T.explore.removeFromWatchlist else T.explore.addToWatchlist
            entries += CatalogMenuEntry(label, CatalogMenuAction.Watchlist(add = !onWatchlist))
        }
        return entries
    }

    /**
     * Does [action] for [item], except [CatalogMenuAction.ViewDetails], which is the UI's. Returns the message to show
     * when it failed ("Couldn't update watchlist", "Couldn't open the trailer on this device"), else null.
     */
    suspend fun run(item: CatalogItem, action: CatalogMenuAction): String? = when (action) {
        CatalogMenuAction.ViewDetails -> null
        is CatalogMenuAction.Trailer -> if (open(action.url)) null else T.explore.detail.trailerUnavailable
        is CatalogMenuAction.Link -> if (open(action.url)) null else T.explore.detail.linkUnavailable
        is CatalogMenuAction.Watchlist -> toggleWatchlist(item, action.add)
    }

    private suspend fun toggleWatchlist(item: CatalogItem, add: Boolean): String? {
        val source = sources.value.watchlistSourceFor(item) ?: return null
        val key = "${source.id.id}/${item.identityKey}"
        if (!mutating.add(key)) return null
        return try {
            val onWatchlist = source.isOnWatchlist(item.kind, item.ids) ?: !add
            if (onWatchlist) source.removeFromWatchlist(item.kind, item.ids) else source.addToWatchlist(item.kind, item.ids)
            null
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Catalog menu watchlist update failed for ${item.identityKey}" }
            T.explore.watchlistUpdateFailed
        } finally {
            mutating.remove(key)
        }
    }

    private fun open(url: String): Boolean {
        if (host.openUrl(url)) return true
        Log.w(TAG) { "Catalog menu could not open $url" }
        return false
    }

    private suspend fun trailerUrl(item: CatalogItem): String? {
        if (host.hasBrowser) return webUrl(item.trailerUrl)
        val appUrl = youTubeAppUrl(item.trailerUrl) ?: return null
        return appUrl.takeIf { host.youTubeAppInstalled() }
    }

    private companion object {
        const val TAG = "CatalogItemMenu"

        /** [value] when it is an http or https link. */
        fun webUrl(value: String?): String? {
            val url = value?.trim() ?: return null
            return url.takeIf { it.startsWith("https://", ignoreCase = true) || it.startsWith("http://", ignoreCase = true) }
        }
    }
}

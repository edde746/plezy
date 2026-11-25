package com.edde746.plezy.links

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.compareEpisodesSpecialsLast
import com.edde746.plezy.model.firstUnwatchedEpisode
import com.edde746.plezy.servers.LibraryLookupResult
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

/** What a [DeepLink.Play] resolved to ([PlayLinkResolver]). */
sealed interface PlayLinkResolution {
    /** Play [item]; [offline] plays its download because its server is away; [showPlay]: it plays as its show's Play. */
    data class Item(val item: MediaItem, val offline: Boolean = false, val showPlay: Boolean = false) : PlayLinkResolution

    /** Play the show or season [item] as a shuffled queue. */
    data class Shuffle(val item: MediaItem) : PlayLinkResolution

    data class Failure(val reason: PlayLinkFailure) : PlayLinkResolution
}

enum class PlayLinkFailure {
    /** The server the link needs is not reachable, or a server that may hold the title failed to answer. */
    SERVER_UNAVAILABLE,

    /** No reachable server has the title. */
    NOT_FOUND,

    /** The link names something a link can't play (music, photos, collections). */
    UNSUPPORTED_ITEM,
}

/**
 * What resolving a [DeepLink.Play] reads from the app's servers.
 *
 * @param serversChanged emits whenever servers connect or drop.
 * @param findCatalogCopies every copy of a catalogue target on the profile's servers, best first.
 * @param downloadedItem the downloaded item of `serverId:itemId`, or null when it isn't downloaded.
 * @param resolvePlexHash the Plex GUID hash Plex Discover has for a target's catalogue ids, or null when it has none;
 *   null when no Plex account is signed in. Plex can't look a library up by catalogue id on its current agent, so a
 *   link without `plex=` finds the title on Plex through this.
 */
class PlayLinkSources(
    val clientFor: (ServerId) -> MediaBackend?,
    val isServerOnline: (ServerId) -> Boolean,
    val hasOnlineServers: () -> Boolean,
    val serversChanged: Flow<*>,
    val findCatalogCopies: suspend (PlayTarget.Catalog) -> LibraryLookupResult,
    val downloadedItem: suspend (ServerId, String) -> MediaItem?,
    val resolvePlexHash: (suspend (PlayTarget.Catalog) -> String?)? = null,
)

/**
 * Turns a [DeepLink.Play] into what to play, on whichever backend has it.
 *
 * An item link plays a download at once when its server is away; otherwise it waits up to [serverWait] for the server
 * (none in an offline session), fetches the item and picks by kind: a movie, episode or clip plays as it is; a show or
 * season shuffles with [PlayMode.SHUFFLE]; a show plays its On Deck episode, else its first episode (specials last); a
 * season its first unwatched episode, else its first. A catalogue link waits for any server, finds every copy of the
 * title, and resumes the copy watched last.
 */
class PlayLinkResolver(private val sources: PlayLinkSources, private val serverWait: Duration = SERVER_WAIT) {
    suspend fun resolve(link: DeepLink.Play): PlayLinkResolution = when (val target = link.target) {
        is PlayTarget.Item -> resolveItem(target, link.mode)
        is PlayTarget.Catalog -> resolveCatalog(target, link.mode)
    }

    private suspend fun resolveItem(target: PlayTarget.Item, mode: PlayMode): PlayLinkResolution {
        val download = sources.downloadedItem(target.serverId, target.itemId)?.takeIf { it.kind.isVideo }
        fun usable() = sources.isServerOnline(target.serverId) && sources.clientFor(target.serverId) != null
        // A download plays at once instead of after waiting out an absent server.
        if (download != null && !usable()) return PlayLinkResolution.Item(download, offline = true)

        if (!waitFor(::usable)) return PlayLinkResolution.Failure(PlayLinkFailure.SERVER_UNAVAILABLE)
        val client = sources.clientFor(target.serverId) ?: return PlayLinkResolution.Failure(PlayLinkFailure.SERVER_UNAVAILABLE)
        val item = try {
            client.fetchItem(target.itemId)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Fetching ${target.itemId} on ${target.serverId} failed" }
            return if (download != null) PlayLinkResolution.Item(download, offline = true) else PlayLinkResolution.Failure(PlayLinkFailure.SERVER_UNAVAILABLE)
        } ?: return PlayLinkResolution.Failure(PlayLinkFailure.NOT_FOUND)
        return forItem(client, item.onServer(target.serverId), mode)
    }

    private suspend fun resolveCatalog(target: PlayTarget.Catalog, mode: PlayMode): PlayLinkResolution = coroutineScope {
        // Discover answers while the servers connect.
        val withPlexHash = async { withPlexHash(target) }
        if (!waitFor(sources.hasOnlineServers)) {
            withPlexHash.cancel()
            return@coroutineScope PlayLinkResolution.Failure(PlayLinkFailure.SERVER_UNAVAILABLE)
        }
        val lookup = try {
            sources.findCatalogCopies(withPlexHash.await())
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Catalogue lookup failed" }
            return@coroutineScope PlayLinkResolution.Failure(PlayLinkFailure.SERVER_UNAVAILABLE)
        }
        val copies = lookup.items.mapNotNull { item ->
            if (item.kind != target.kind) return@mapNotNull null
            val client = ServerId.tryParse(item.serverId)?.let(sources.clientFor) ?: return@mapNotNull null
            Copy(client, item)
        }
        if (copies.isEmpty()) {
            // A server that failed to answer or is offline may hold the title; one that can't run this query (a Plex
            // GUID on Jellyfin) does not.
            val unanswered = lookup.failedServerIds.isNotEmpty() || lookup.cancelledServerIds.isNotEmpty() ||
                lookup.unqueriedServerIds.any { !sources.isServerOnline(it) }
            return@coroutineScope PlayLinkResolution.Failure(if (unanswered) PlayLinkFailure.SERVER_UNAVAILABLE else PlayLinkFailure.NOT_FOUND)
        }

        if (target.kind == MediaKind.MOVIE) {
            // Progress is per copy (a 4K and an HD library, two servers): resume the copy watched last. The full item
            // carries current watch state.
            val fresh = copies.map { async { refreshed(it) } }.awaitAll()
            return@coroutineScope PlayLinkResolution.Item(fresh.watchedLast { it })
        }
        if (mode == PlayMode.SHUFFLE) return@coroutineScope PlayLinkResolution.Shuffle(copies.first().item)

        // Next: the copy being watched, and of several the one watched last.
        val watching = copies.map { async { onDeck(it) } }.awaitAll().filter { it.episode != null }
        if (watching.isNotEmpty()) {
            val latest = watching.watchedLast { it.show }
            return@coroutineScope PlayLinkResolution.Item(latest.episode!!.onServer(latest.copy.serverId), showPlay = true)
        }
        val first = copies.first()
        firstEpisode(first.client, first.item, showPlay = true)
    }

    /** [target] with the Plex GUID hash Discover has for its catalogue ids, or [target] itself. */
    private suspend fun withPlexHash(target: PlayTarget.Catalog): PlayTarget.Catalog {
        val resolve = sources.resolvePlexHash
        if (target.plexHash != null || !target.ids.hasCatalogIds || resolve == null) return target
        return try {
            val hash = resolve(target)
            if (hash.isNullOrEmpty()) target else target.copy(plexHash = hash)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            // Best effort: the catalogue ids still find the title elsewhere.
            Log.w(TAG, e) { "Plex Discover lookup failed" }
            target
        }
    }

    private suspend fun refreshed(copy: Copy): MediaItem = try {
        copy.client.fetchItem(copy.item.id)?.onServer(copy.serverId) ?: copy.item
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "Refreshing ${copy.item.globalKey} failed" }
        copy.item
    }

    private suspend fun onDeck(copy: Copy): OnDeck = try {
        val result = copy.client.fetchItemWithOnDeck(copy.item.id)
        OnDeck(copy, result.item ?: copy.item, result.onDeckEpisode)
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "On Deck lookup for ${copy.item.globalKey} failed" }
        OnDeck(copy, copy.item, null)
    }

    private suspend fun forItem(client: MediaBackend, item: MediaItem, mode: PlayMode): PlayLinkResolution = when (item.kind) {
        MediaKind.MOVIE, MediaKind.EPISODE, MediaKind.CLIP -> PlayLinkResolution.Item(item)
        MediaKind.SHOW, MediaKind.SEASON -> when {
            mode == PlayMode.SHUFFLE -> PlayLinkResolution.Shuffle(item)
            else -> {
                val onDeck = if (item.kind == MediaKind.SHOW) onDeck(Copy(client, item)).episode else null
                val showPlay = item.kind == MediaKind.SHOW
                if (onDeck != null) {
                    PlayLinkResolution.Item(onDeck.onServer(client.serverId), showPlay = true)
                } else {
                    firstEpisode(client, item, preferUnwatched = !showPlay, showPlay = showPlay)
                }
            }
        }
        else -> PlayLinkResolution.Failure(PlayLinkFailure.UNSUPPORTED_ITEM)
    }

    /**
     * The first episode of [container] (specials last), or with [preferUnwatched] the first not yet watched; [showPlay]
     * when it plays as the show's Play.
     */
    private suspend fun firstEpisode(client: MediaBackend, container: MediaItem, preferUnwatched: Boolean = false, showPlay: Boolean = false): PlayLinkResolution {
        val episodes = try {
            client.fetchPlayableDescendants(container.id)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Episodes of ${container.globalKey} failed" }
            return PlayLinkResolution.Failure(PlayLinkFailure.SERVER_UNAVAILABLE)
        }
        val ordered = episodes.filter { it.kind == MediaKind.EPISODE }.sortedWith(Comparator(::compareEpisodesSpecialsLast))
        val episode = (if (preferUnwatched) firstUnwatchedEpisode(ordered) else null) ?: ordered.firstOrNull()
            ?: return PlayLinkResolution.Failure(PlayLinkFailure.NOT_FOUND)
        return PlayLinkResolution.Item(episode.onServer(client.serverId), showPlay = showPlay)
    }

    /** Waits up to [serverWait] for [ready], checking again whenever the servers change; whether it became true. */
    private suspend fun waitFor(ready: () -> Boolean): Boolean {
        if (ready()) return true
        if (serverWait <= Duration.ZERO) return false
        return withTimeoutOrNull(serverWait) { sources.serversChanged.first { ready() } } != null || ready()
    }

    private class Copy(val client: MediaBackend, val item: MediaItem) {
        val serverId: ServerId get() = ServerId.tryParse(item.serverId) ?: client.serverId
    }

    private class OnDeck(val copy: Copy, val show: MediaItem, val episode: MediaItem?)

    companion object {
        /** How long a link waits for the server it needs to come online, e.g. while the app reconnects after a wake. */
        val SERVER_WAIT: Duration = 20.seconds
        private const val TAG = "PlayLink"
    }
}

/** [this] item with its server stamped on, for rows a backend returns without one. */
private fun MediaItem.onServer(serverId: ServerId): MediaItem = if (this.serverId == null) copy(serverId = serverId.value) else this

/** The entry whose item was watched last; the first on a tie, so with nothing watched the first (best) copy. */
private fun <T> List<T>.watchedLast(item: (T) -> MediaItem): T =
    reduce { a, b -> if ((item(b).lastViewedAt ?: 0) > (item(a).lastViewedAt ?: 0)) b else a }

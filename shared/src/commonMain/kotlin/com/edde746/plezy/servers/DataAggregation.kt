package com.edde746.plezy.servers

import com.edde746.plezy.backend.DEFAULT_HUB_PREVIEW_LIMIT
import com.edde746.plezy.backend.HubFetchDiagnostics
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.MediaServerTimeouts
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.DEFAULT_MEDIA_SEARCH_LIMIT
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.ExternalSeasonRef
import com.edde746.plezy.model.MediaHub
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.model.MediaPerson
import com.edde746.plezy.model.SearchHit
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.TitleQuery
import com.edde746.plezy.model.buildGlobalKey
import com.edde746.plezy.model.compareLibraryCopies
import com.edde746.plezy.model.findTitleCopies
import com.edde746.plezy.model.mergeLibraryCopies
import com.edde746.plezy.model.parseGlobalKey
import com.edde746.plezy.model.rankSearchHits
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.joinAll
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeout
import kotlin.time.Duration

private const val TAG = "DataAggregation"

/** Libraries one home layout fetches hubs for at once. */
private const val LIBRARY_HUB_CONCURRENCY = 3

/** The servers aggregation and push channels fan out over. */
interface OnlineServers {
    /** Online clients visible to the active profile, in the profile's server order. */
    val visibleOnlineClients: Map<ServerId, MediaBackend>

    /** Every online client, visibility ignored. */
    val onlineClients: Map<ServerId, MediaBackend>

    /** The registered client for [serverId], online or not. */
    fun client(serverId: ServerId): MediaBackend?

    /** Emits after any server status change or visible-set change. */
    val changes: Flow<Unit>
}

/**
 * Continue Watching rows after cross-library and cross-server dedupe. [copies] maps the global key of every row that
 * absorbed duplicates (the same title in a 4K and an HD library, or on two servers) to every copy in its group, the row
 * included, best first. A row without duplicates has no entry.
 */
data class ContinueWatchingRows(val items: List<MediaItem>, val copies: Map<String, List<MediaItem>>)

/**
 * [observedItems] are every row the successful responses returned, before dedupe and limit: a copy dedupe dropped was
 * still returned by its server. [copies] is [ContinueWatchingRows.copies] for [items].
 */
data class OnDeckAggregationResult(
    val items: List<MediaItem>,
    val copies: Map<String, List<MediaItem>>,
    val observedItems: List<ObservedRow>,
    val succeededServerIds: Set<ServerId>,
    val cancelledServerIds: Set<ServerId>,
    val failedServerIds: Set<ServerId>,
)

data class HubAggregationResult(
    val hubs: List<MediaHub>,
    val observedItems: List<ObservedRow>,
    val succeededServerIds: Set<ServerId>,
    val cancelledServerIds: Set<ServerId>,
    val failedServerIds: Set<ServerId>,
)

data class LibraryAggregationResult(
    val libraries: List<MediaLibrary>,
    val succeededServerIds: Set<ServerId>,
    val cancelledServerIds: Set<ServerId>,
    val failedServerIds: Set<ServerId>,
)

/**
 * [hits] are titles and people ranked together and cut to the caller's limit; [candidates] (titles) and [people] are
 * the whole pools behind them after the hidden-library filter, so a caller can re-rank a subset without a kind ranked
 * out of [hits] vanishing from its own filter.
 */
data class SearchAggregationResult(
    val hits: List<SearchHit>,
    val candidates: List<MediaItem>,
    val people: List<MediaPerson>,
    val succeededServerIds: Set<ServerId>,
    val cancelledServerIds: Set<ServerId>,
    val failedServerIds: Set<ServerId>,
) {
    companion object {
        val EMPTY = SearchAggregationResult(emptyList(), emptyList(), emptyList(), emptySet(), emptySet(), emptySet())
    }
}

/**
 * One lookup wave. [items] are the verified copies, deduped, best first. A failed or cancelled server contributed
 * nothing and says nothing about what it holds; [unqueriedServerIds] are servers that are offline, have no client, or
 * can't run the query. None of these is evidence of absence.
 */
data class LibraryLookupResult(
    val items: List<MediaItem>,
    val succeededServerIds: Set<ServerId>,
    val cancelledServerIds: Set<ServerId>,
    val failedServerIds: Set<ServerId>,
    val unqueriedServerIds: Set<ServerId>,
)

/**
 * Fans the genuinely multi-server flows out to every online client and merges the answers: libraries, Continue
 * Watching, home hubs, search and copy lookups. One server failing never sinks the pass: each result tells the servers
 * that answered from the ones that failed and the ones whose request was cancelled (a disrupted pass says nothing about
 * content and must not be committed as authoritative).
 *
 * [localLastPlayed] is this device's playback history (global key, item or series, → epoch ms); it picks which copy of
 * a duplicated Continue Watching title is shown.
 */
class DataAggregationService(
    private val servers: OnlineServers,
    private val localLastPlayed: suspend () -> Map<String, Long>,
) {
    /**
     * Online clients visible to the active profile, or the online clients in [serverIds]. A supplied set is already
     * profile-scoped (delta refreshes, lookups over the profile's expected servers), so visibility is not applied.
     */
    private fun clientsFor(serverIds: Set<ServerId>?): Map<ServerId, MediaBackend> {
        if (serverIds == null) return servers.visibleOnlineClients
        return servers.onlineClients.filterKeys { it in serverIds }
    }

    /** Libraries of every online server ([serverIds] restricts the fan-out), each server under its own deadline. */
    suspend fun getMediaLibrariesFromAllServers(serverIds: Set<ServerId>? = null): LibraryAggregationResult {
        val clients = clientsFor(serverIds)
        if (clients.isEmpty()) {
            Log.w(TAG) { "No online servers available for fetching libraries" }
            return LibraryAggregationResult(emptyList(), emptySet(), emptySet(), emptySet())
        }
        val legs = fanOut(clients, { "Failed library fetch from $it" }) { serverId, client ->
            withinServerDeadline(MediaServerTimeouts.LIBRARY_LIST_SERVER_DEADLINE, "Library fetch on $serverId") {
                client.fetchLibraries()
            }
        }
        return LibraryAggregationResult(legs.values.flatten(), legs.succeeded, legs.cancelled, legs.failed)
    }

    /**
     * Continue Watching across servers, newest first. Each server is told only its own hidden library ids; rows of a
     * hidden library are then dropped (rows without a library are kept), sorted by [MediaItem.recencySortKey],
     * deduplicated across libraries and servers, and cut to [limit].
     */
    suspend fun getOnDeckFromAllServers(
        limit: Int? = null,
        hiddenLibraryKeys: Set<String>? = null,
        serverIds: Set<ServerId>? = null,
    ): OnDeckAggregationResult {
        val clients = clientsFor(serverIds)
        if (clients.isEmpty()) return OnDeckAggregationResult(emptyList(), emptyMap(), emptyList(), emptySet(), emptySet(), emptySet())

        val legs = fanOut(clients, { "Failed on-deck fetch from $it" }) { serverId, client ->
            val rows = client.fetchContinueWatching(count = limit, excludedLibraryIds = hiddenLibraryIdsOn(serverId, hiddenLibraryKeys))
            // Captured here: after flattening and dedupe there is no way back to the client that produced a row.
            val scope = client.cacheServerId
            rows.map { ObservedRow(it, scope) }
        }
        val observed = legs.values.flatten()
        val visible = withoutHiddenLibraries(observed.map { it.item }, hiddenLibraryKeys).sortedByDescending { it.recencySortKey }
        val rows = limitContinueWatching(deduplicateContinueWatching(visible), limit)
        Log.i(TAG) { "Fetched ${rows.items.size} on deck items from all servers" }
        return OnDeckAggregationResult(rows.items, rows.copies, observed, legs.succeeded, legs.cancelled, legs.failed)
    }

    /**
     * [existing] Continue Watching rows (with the [existingCopies] they absorbed) merged with [fresh] rows from newly
     * online servers (with the [freshCopies] their own dedupe absorbed), under the same order and dedupe as
     * [getOnDeckFromAllServers]. Absorbed copies of both rejoin the pool so a regrouped row still offers them; a fresh row
     * replaces an existing one with its global key.
     */
    suspend fun mergeContinueWatching(
        existing: List<MediaItem>,
        fresh: List<MediaItem>,
        existingCopies: Map<String, List<MediaItem>>,
        freshCopies: Map<String, List<MediaItem>>,
        limit: Int? = null,
    ): ContinueWatchingRows {
        val byKey = LinkedHashMap<String, MediaItem>()
        fun pool(rows: List<MediaItem>, copies: Map<String, List<MediaItem>>) {
            for (row in rows) {
                for (copy in copies[row.globalKey] ?: listOf(row)) {
                    byKey[copy.globalKey] = if (copy.globalKey == row.globalKey) row else copy
                }
            }
        }
        pool(existing, existingCopies)
        pool(fresh, freshCopies)
        val combined = byKey.values.sortedByDescending { it.recencySortKey }
        return limitContinueWatching(deduplicateContinueWatching(combined), limit)
    }

    private fun limitContinueWatching(rows: ContinueWatchingRows, limit: Int?): ContinueWatchingRows {
        if (limit == null || limit >= rows.items.size) return rows
        val items = rows.items.take(limit)
        val copies = buildMap { for (item in items) rows.copies[item.globalKey]?.let { put(item.globalKey, it) } }
        return ContinueWatchingRows(items, copies)
    }

    /**
     * Groups duplicates rather than dropping them: the first row to claim an identity key anchors the group and holds
     * its slot; later rows sharing a claimed key join it. Each slot then shows the member last played on this device
     * (servers sync watch state across linked copies, so their last-viewed times can't tell the 4K copy from the 1080p
     * one). Rows without identity keys are never merged.
     */
    private suspend fun deduplicateContinueWatching(items: List<MediaItem>): ContinueWatchingRows {
        if (items.size < 2) return ContinueWatchingRows(items, emptyMap())

        val buckets = items.map(::titleBucket)
        val duplicateBuckets = buckets.filterNotNull().groupingBy { it }.eachCount().filterValues { it > 1 }.keys
        if (duplicateBuckets.isEmpty()) return ContinueWatchingRows(items, emptyMap())

        val identityKeys: List<Set<String>> = coroutineScope {
            val externalIdLoads = HashMap<String, Deferred<ExternalIds?>>()
            val loads = items.mapIndexed { index, item ->
                if (buckets[index] !in duplicateBuckets) return@mapIndexed null
                val external = externalIdsLoad(item, externalIdLoads)
                async { identityKeysOf(item, external?.await()) }
            }
            loads.map { it?.await() ?: emptySet() }
        }

        val keyToGroup = HashMap<String, Int>()
        val groups = mutableListOf<MutableList<MediaItem>>()
        val groupSlots = LinkedHashMap<Int, Int>()
        val result = mutableListOf<MediaItem>()
        for ((index, item) in items.withIndex()) {
            val keys = identityKeys[index]
            if (buckets[index] !in duplicateBuckets || keys.isEmpty()) {
                result += item
                continue
            }
            val joined = keys.firstNotNullOfOrNull { keyToGroup[it] }
            if (joined != null) {
                groups[joined].add(item)
                continue
            }
            val groupIndex = groups.size
            groups += mutableListOf(item)
            for (key in keys) keyToGroup[key] = groupIndex
            groupSlots[result.size] = groupIndex
            result += item
        }

        if (groupSlots.isEmpty()) return ContinueWatchingRows(result, emptyMap())
        val lastPlayed = localLastPlayed()
        val copies = LinkedHashMap<String, List<MediaItem>>()
        for ((slot, groupIndex) in groupSlots) {
            val members = groups[groupIndex]
            if (members.size < 2) continue
            val shown = preferLocallyLastPlayed(members, lastPlayed)
            result[slot] = shown
            copies[shown.globalKey] = members.sortedWith { a, b -> compareLibraryCopies(a, b) }
        }
        return ContinueWatchingRows(result, copies)
    }

    /**
     * The member last played on this device (by item or series key), or the anchor, the group's newest row, when the
     * local history has nothing newer to say.
     */
    private fun preferLocallyLastPlayed(members: List<MediaItem>, lastPlayed: Map<String, Long>): MediaItem {
        var winner = members.first()
        var winnerLastPlayedAt = 0L
        for (member in members) {
            val itemTs = lastPlayed[member.globalKey] ?: 0L
            val seriesTs = member.seriesGlobalKey?.let { lastPlayed[it] } ?: 0L
            val lastPlayedAt = maxOf(itemTs, seriesTs)
            if (lastPlayedAt > winnerLastPlayedAt) {
                winner = member
                winnerLastPlayedAt = lastPlayedAt
            }
        }
        return winner
    }

    private fun titleBucket(item: MediaItem): String? {
        val scope = identityScope(item) ?: return null
        val title = when (item.kind) {
            MediaKind.EPISODE, MediaKind.SEASON -> item.grandparentTitle ?: item.parentTitle ?: item.title
            else -> item.title
        }
        val normalized = title?.trim()?.lowercase()?.replace(WHITESPACE, " ")
        if (normalized.isNullOrEmpty()) return null
        return "$scope:$normalized"
    }

    /** The external ids of [item]'s show or movie, one request per global key; null when nothing can be asked. */
    private fun kotlinx.coroutines.CoroutineScope.externalIdsLoad(
        item: MediaItem,
        loads: MutableMap<String, Deferred<ExternalIds?>>,
    ): Deferred<ExternalIds?>? {
        val serverId = ServerId.tryParse(item.serverId) ?: return null
        val targetId = identityTargetId(item)?.takeIf { it.isNotEmpty() } ?: return null
        val client = servers.client(serverId) ?: return null
        return loads.getOrPut(buildGlobalKey(serverId, targetId)) {
            async {
                try {
                    client.fetchExternalIds(targetId)
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    Log.d(TAG, e) { "Failed to resolve Continue Watching identity for ${item.globalKey}" }
                    null
                }
            }
        }
    }

    private fun identityKeysOf(item: MediaItem, externalIds: ExternalIds?): Set<String> {
        val scope = identityScope(item) ?: return emptySet()
        val keys = LinkedHashSet<String>()
        if (externalIds != null) {
            externalIds.imdb?.trim()?.lowercase()?.takeIf { it.isNotEmpty() }?.let { keys += "$scope:imdb:$it" }
            externalIds.tmdb?.let { keys += "$scope:tmdb:$it" }
            externalIds.tvdb?.let { keys += "$scope:tvdb:$it" }
            externalIds.anidb?.let { keys += "$scope:anidb:$it" }
        }
        stableMediaGuid(item.guid)?.let { guid ->
            val guidScope = if (item.kind == MediaKind.EPISODE) "episode" else scope
            keys += "$guidScope:guid:$guid"
        }
        return keys
    }

    private fun identityScope(item: MediaItem): String? = when (item.kind) {
        MediaKind.EPISODE, MediaKind.SEASON, MediaKind.SHOW -> "show"
        MediaKind.MOVIE -> "movie"
        else -> null
    }

    private fun identityTargetId(item: MediaItem): String? = when (item.kind) {
        MediaKind.EPISODE -> item.grandparentId
        MediaKind.SEASON -> item.grandparentId ?: item.parentId
        MediaKind.SHOW, MediaKind.MOVIE -> item.id
        else -> null
    }

    private fun stableMediaGuid(guid: String?): String? {
        val value = guid?.trim()
        if (value.isNullOrEmpty() || "://" !in value || "agents.none://" in value) return null
        return value.lowercase()
    }

    /**
     * Recommendation hubs of every server. With [useGlobalHubs], rich-hub backends (Plex) use their promoted home hubs
     * plus per-library hubs of music libraries, which the promoted endpoint leaves out; the others build home from
     * per-library hubs (movie, show, clip and music libraries) so one capped "Latest" row can't hide whole library
     * types. The library list is fetched first for that. A server only counts as succeeded when its hub leg did:
     * callers must not cache a transient failure as loaded.
     */
    suspend fun getHubsFromAllServers(
        limit: Int? = null,
        hiddenLibraryKeys: Set<String>? = null,
        useGlobalHubs: Boolean = true,
        includePlaybackHubs: Boolean = true,
        serverIds: Set<ServerId>? = null,
    ): HubAggregationResult {
        val clients = clientsFor(serverIds)
        if (clients.isEmpty()) {
            Log.w(TAG) { "No online servers available for fetching hubs" }
            return HubAggregationResult(emptyList(), emptyList(), emptySet(), emptySet(), emptySet())
        }

        val libraryFetch = if (useGlobalHubs) getMediaLibrariesFromAllServers(serverIds) else null
        val librariesByServer = libraryFetch?.libraries.orEmpty().groupBy { it.serverId }
        val hubItemLimit = limit ?: DEFAULT_HUB_PREVIEW_LIMIT

        val legs = fanOut(clients, { "Failed to fetch hubs from server $it" }) { serverId, client ->
            val prefetchDegraded = libraryFetch != null &&
                (serverId in libraryFetch.failedServerIds || serverId in libraryFetch.cancelledServerIds)
            val serverLibraries = librariesByServer[serverId.value].orEmpty()
            val leg = if (useGlobalHubs && client.capabilities.richHubs) {
                globalHubLeg(client, hubItemLimit, hiddenLibraryKeys, includePlaybackHubs, serverLibraries, prefetchDegraded)
            } else if (useGlobalHubs && prefetchDegraded) {
                // A per-library backend can't fetch rows for libraries its prefetch failed to discover.
                HubLeg(emptyList(), succeeded = false, failed = false, cancelled = false)
            } else {
                val libraryHubs = fetchLibraryHubsForClient(
                    client,
                    hubItemLimit,
                    hiddenLibraryKeys,
                    includePlaybackHubs,
                    libraries = if (useGlobalHubs) serverLibraries else null,
                )
                HubLeg(
                    libraryHubs.hubs,
                    succeeded = libraryHubs.succeeded || (!libraryHubs.failed && !libraryHubs.cancelled),
                    failed = libraryHubs.failed,
                    cancelled = libraryHubs.cancelled,
                )
            }
            val processed = postProcessHubs(leg.hubs, serverId, hiddenLibraryKeys)
            val scope = client.cacheServerId
            serverId to leg.copy(hubs = processed, observed = processed.flatMap { hub -> hub.items.map { ObservedRow(it, scope) } })
        }

        val answered = legs.values
        val all = answered.flatMap { it.second.hubs }
        return HubAggregationResult(
            hubs = if (limit != null && limit < all.size) all.take(limit) else all,
            // Before the limit, so a row trimmed off the tail still counts as observed.
            observedItems = answered.flatMap { it.second.observed },
            succeededServerIds = answered.filter { it.second.succeeded }.mapTo(LinkedHashSet()) { it.first },
            cancelledServerIds = legs.cancelled + libraryFetch?.cancelledServerIds.orEmpty() +
                answered.filter { it.second.cancelled }.map { it.first },
            failedServerIds = legs.failed + libraryFetch?.failedServerIds.orEmpty() +
                answered.filter { it.second.failed }.map { it.first },
        )
    }

    private data class HubLeg(
        val hubs: List<MediaHub>,
        val succeeded: Boolean,
        val failed: Boolean,
        val cancelled: Boolean,
        val observed: List<ObservedRow> = emptyList(),
    )

    /**
     * A rich-hub server's promoted hubs plus its music libraries' hubs, both legs started together. A failed prefetch
     * can't establish that there are no visible music libraries, so the music append is skipped then. The optional
     * music append never vouches for a server whose promoted leg failed or was cancelled (that backend records it in
     * the diagnostics and answers empty): a lone music row would replace every cached movie and TV row. A promoted leg
     * that threw contributes no rows at all.
     */
    private suspend fun globalHubLeg(
        client: MediaBackend,
        limit: Int,
        hiddenLibraryKeys: Set<String>?,
        includePlaybackHubs: Boolean,
        libraries: List<MediaLibrary>,
        prefetchDegraded: Boolean,
    ): HubLeg = coroutineScope {
        val diagnostics = HubFetchDiagnostics()
        val musicLeg = if (prefetchDegraded) null else async {
            fetchLibraryHubsForClient(client, limit, hiddenLibraryKeys, includePlaybackHubs, libraries, setOf(MediaKind.ARTIST))
        }
        var globalError: Throwable? = null
        val globalHubs = try {
            client.fetchGlobalHubs(limit = limit, includePlaybackHubs = includePlaybackHubs, diagnostics = diagnostics)
        } catch (e: Throwable) {
            if (e is CancellationException) currentCoroutineContext().ensureActive()
            diagnostics.recordFailure(e)
            Log.e(TAG, e) { "Failed to fetch global hubs from server ${client.serverId}" }
            globalError = e
            emptyList()
        }
        val music = musicLeg?.await()
        val globalClean = !diagnostics.failed && !diagnostics.cancelled
        HubLeg(
            hubs = if (globalError != null) emptyList() else globalHubs + music?.hubs.orEmpty(),
            succeeded = globalHubs.isNotEmpty() || globalClean,
            failed = diagnostics.failed || music?.failed == true,
            cancelled = diagnostics.cancelled || music?.cancelled == true,
        )
    }

    private data class LibraryHubs(val hubs: List<MediaHub>, val succeeded: Boolean, val failed: Boolean, val cancelled: Boolean)

    private data class LibraryHubOutcome(val hubs: List<MediaHub>, val succeeded: Boolean, val failed: Boolean, val cancelled: Boolean)

    /**
     * Per-library hubs of one client's visible libraries of [kinds] (clip covers Jellyfin music videos and home videos,
     * artist brings music rows home), in library order. Three workers each take the next library the moment
     * they're free, so one slow library doesn't stall the ones queued behind it. [LibraryHubs.succeeded] stays
     * false when no library was fetched, so the optional music append can't mask a failed promoted leg.
     */
    private suspend fun fetchLibraryHubsForClient(
        client: MediaBackend,
        limit: Int,
        hiddenLibraryKeys: Set<String>?,
        includePlaybackHubs: Boolean,
        libraries: List<MediaLibrary>?,
        kinds: Set<MediaKind> = DEFAULT_HUB_LIBRARY_KINDS,
    ): LibraryHubs = coroutineScope {
        val visible = (libraries ?: client.fetchLibraries()).filter {
            it.kind in kinds && !it.hidden && (hiddenLibraryKeys == null || it.globalKey !in hiddenLibraryKeys)
        }
        val outcomes = arrayOfNulls<LibraryHubOutcome>(visible.size)
        val queue = Channel<Int>(Channel.UNLIMITED)
        visible.indices.forEach { queue.trySend(it) }
        queue.close()
        val workers = List(minOf(LIBRARY_HUB_CONCURRENCY, visible.size)) {
            launch {
                for (index in queue) outcomes[index] = fetchOneLibraryHubs(client, visible[index], limit, includePlaybackHubs)
            }
        }
        workers.joinAll()
        val settled = outcomes.filterNotNull()
        LibraryHubs(
            hubs = settled.flatMap { it.hubs },
            succeeded = settled.any { it.succeeded },
            failed = settled.any { it.failed },
            cancelled = settled.any { it.cancelled },
        )
    }

    private suspend fun fetchOneLibraryHubs(client: MediaBackend, library: MediaLibrary, limit: Int, includePlaybackHubs: Boolean): LibraryHubOutcome {
        val diagnostics = HubFetchDiagnostics()
        var hubs = emptyList<MediaHub>()
        var succeeded = false
        var failed = false
        var cancelled = false
        try {
            hubs = client.fetchLibraryHubs(
                library.id,
                libraryName = library.title,
                limit = limit,
                includePlaybackHubs = includePlaybackHubs,
                libraryKind = library.kind,
                diagnostics = diagnostics,
            )
            succeeded = hubs.isNotEmpty() || (!diagnostics.failed && !diagnostics.cancelled)
        } catch (e: Throwable) {
            if (e is CancellationException) currentCoroutineContext().ensureActive()
            if (isCancellation(e)) {
                cancelled = true
                Log.d(TAG) { "Cancelled library hub fetch for ${library.globalKey}" }
            } else {
                failed = true
                Log.e(TAG, e) { "Failed to fetch library hubs for ${library.globalKey}" }
            }
        }
        return LibraryHubOutcome(hubs, succeeded, failed || diagnostics.failed, cancelled || diagnostics.cancelled)
    }

    /** Drops items of hidden libraries, and the hubs that leaves empty. */
    private fun postProcessHubs(hubs: List<MediaHub>, serverId: ServerId, hiddenLibraryKeys: Set<String>?): List<MediaHub> {
        if (hiddenLibraryKeys.isNullOrEmpty()) return hubs
        return hubs.mapNotNull { hub ->
            val items = hub.items.filter { item ->
                val libraryId = item.libraryId ?: return@filter true
                buildGlobalKey(serverId, libraryId) !in hiddenLibraryKeys
            }
            if (items.isEmpty()) null else hub.copy(items = items, size = items.size)
        }
    }

    /**
     * Titles and people for [query] on every visible online server, ranked on one scale. Each server overfetches (at
     * least [DEFAULT_MEDIA_SEARCH_LIMIT]) and runs titles and people together, each under its own deadline, so one
     * stalled server fails alone. The outcome sets describe the title search only: the
     * people search is best-effort and costs a server its people, never its titles. Titles of hidden libraries are
     * dropped before ranking, so they can't spend the [limit]. Equal scores keep the servers' order: [serverOrder]'s
     * (the user's library order) first, then the profile's. Cancelling the caller cancels every leg.
     */
    suspend fun searchAcrossServers(
        query: String,
        limit: Int? = null,
        hiddenLibraryKeys: Set<String>? = null,
        serverOrder: List<ServerId> = emptyList(),
    ): SearchAggregationResult {
        if (query.isBlank()) return SearchAggregationResult.EMPTY
        currentCoroutineContext().ensureActive()
        val clients = servers.visibleOnlineClients.entries.sortedByServerOrder(serverOrder) { it.key.value }.associate { it.toPair() }
        if (clients.isEmpty()) return SearchAggregationResult.EMPTY

        val resultLimit = limit ?: DEFAULT_MEDIA_SEARCH_LIMIT
        val fetchLimit = maxOf(resultLimit, DEFAULT_MEDIA_SEARCH_LIMIT)
        val legs = fanOut(clients, { "Search failed on $it" }) { serverId, client ->
            coroutineScope {
                val excluded = hiddenLibraryIdsOn(serverId, hiddenLibraryKeys)
                val people = async { searchPeopleBestEffort(serverId, client, query, excluded) }
                val items = withinServerDeadline(MediaServerTimeouts.SEARCH_SERVER_DEADLINE, "Search on $serverId") {
                    client.searchItems(query, limit = fetchLimit, excludedLibraryIds = excluded)
                }
                items to people.await()
            }
        }
        currentCoroutineContext().ensureActive()

        val titles = legs.values.flatMap { it.first }
        val people = legs.values.flatMap { it.second }
        val visible = withoutHiddenLibraries(titles, hiddenLibraryKeys)
        // Titles first: equal scores keep input order, so a tie goes to the title.
        val hits = rankSearchHits(visible.map { SearchHit.Media(it) } + people.map { SearchHit.Person(it) }, query, resultLimit)
        Log.i(TAG) {
            "Search aggregation completed: ${hits.size} results (${legs.succeeded.size} succeeded, " +
                "${legs.cancelled.size} cancelled, ${legs.failed.size} failed), ${people.size} people"
        }
        return SearchAggregationResult(hits, visible, people, legs.succeeded, legs.cancelled, legs.failed)
    }

    /** One server's people, or none when the request fails, is cancelled or misses its deadline. */
    private suspend fun searchPeopleBestEffort(serverId: ServerId, client: MediaBackend, query: String, excluded: Set<String>): List<MediaPerson> =
        try {
            withinServerDeadline(MediaServerTimeouts.SEARCH_SERVER_DEADLINE, "People search on $serverId") {
                client.searchPeople(query, excludedLibraryIds = excluded)
            }
        } catch (e: Throwable) {
            if (e is CancellationException) currentCoroutineContext().ensureActive()
            if (isCancellation(e)) {
                Log.d(TAG) { "People search cancelled on $serverId" }
            } else {
                Log.w(TAG, e) { "People search failed on $serverId; keeping title results" }
            }
            emptyList()
        }

    /**
     * Every copy matching [ids] on the online servers among [serverIds] (the active profile's expected servers,
     * offline ones included). Each server contributes every copy it holds, not one apiece: the same movie often sits
     * in a 4K and an HD library. Expected servers that aren't online and backends that can't run the query are
     * unqueried. Servers outside [serverIds] are neither asked nor counted.
     */
    suspend fun findByExternalIdsAcrossServers(
        ids: ExternalIds,
        kind: MediaKind,
        serverIds: Set<ServerId>,
        titles: List<String> = emptyList(),
        year: Int? = null,
        plexGuid: String? = null,
        season: ExternalSeasonRef? = null,
    ): LibraryLookupResult {
        val clients = clientsFor(serverIds)
        val offline = serverIds - clients.keys
        if (clients.isEmpty()) return LibraryLookupResult(emptyList(), emptySet(), emptySet(), emptySet(), offline)
        val legs = fanOut(clients, { "External-id lookup failed on $it" }) { _, client ->
            client.findByExternalIds(ids, kind, titles, year, plexGuid, season)
        }
        return LibraryLookupResult(
            items = mergeLibraryCopies(emptyList(), legs.values.flatten()),
            succeededServerIds = legs.succeeded,
            cancelledServerIds = legs.cancelled,
            failedServerIds = legs.failed,
            unqueriedServerIds = offline + legs.unqueried,
        )
    }

    /**
     * Every copy of [query] on the visible online servers, each with its versions: one lookup per server under one
     * deadline. A server that fails, times out or is cancelled contributes nothing and lands in its outcome set.
     */
    suspend fun findTitleCopiesAcrossServers(query: TitleQuery): LibraryLookupResult {
        currentCoroutineContext().ensureActive()
        val legs = fanOut(servers.visibleOnlineClients, { "Title copy lookup failed on $it" }) { serverId, client ->
            withinServerDeadline(MediaServerTimeouts.LIBRARY_LOOKUP, "Title copy lookup on $serverId") { client.findTitleCopies(query) }
        }
        return LibraryLookupResult(
            items = mergeLibraryCopies(emptyList(), legs.values.flatten()),
            succeededServerIds = legs.succeeded,
            cancelledServerIds = legs.cancelled,
            failedServerIds = legs.failed,
            unqueriedServerIds = legs.unqueried,
        )
    }

    private class Legs<R>(
        /** The answers, in client order. */
        val values: List<R>,
        val succeeded: Set<ServerId>,
        val cancelled: Set<ServerId>,
        val failed: Set<ServerId>,
        /** Servers whose backend couldn't run the query (a null answer). */
        val unqueried: Set<ServerId>,
    )

    private sealed interface Leg<out R> {
        data class Answered<R>(val value: R) : Leg<R>
        data object Unqueried : Leg<Nothing>
        data object Cancelled : Leg<Nothing>
        data object Failed : Leg<Nothing>
    }

    /**
     * Runs [fetch] against every client in parallel. A failure is logged with [failureMessage] and contributes nothing;
     * a request cancelled under the client (its HTTP client closing) counts as cancelled, not failed. Cancelling the
     * caller cancels every leg and propagates.
     */
    private suspend fun <R : Any> fanOut(
        clients: Map<ServerId, MediaBackend>,
        failureMessage: (ServerId) -> String,
        fetch: suspend (ServerId, MediaBackend) -> R?,
    ): Legs<R> {
        val outcomes = coroutineScope {
            clients.map { (serverId, client) ->
                async {
                    serverId to try {
                        fetch(serverId, client)?.let { Leg.Answered(it) } ?: Leg.Unqueried
                    } catch (e: Throwable) {
                        if (e is CancellationException) currentCoroutineContext().ensureActive()
                        if (isCancellation(e)) {
                            Log.d(TAG) { "Cancelled (client abort): ${failureMessage(serverId)}" }
                            Leg.Cancelled
                        } else {
                            Log.e(TAG, e) { failureMessage(serverId) }
                            Leg.Failed
                        }
                    }
                }
            }.awaitAll()
        }
        fun idsOf(predicate: (Leg<R>) -> Boolean) = outcomes.filter { predicate(it.second) }.mapTo(LinkedHashSet()) { it.first }
        return Legs(
            values = outcomes.mapNotNull { (it.second as? Leg.Answered<R>)?.value },
            succeeded = idsOf { it is Leg.Answered },
            cancelled = idsOf { it == Leg.Cancelled },
            failed = idsOf { it == Leg.Failed },
            unqueried = idsOf { it == Leg.Unqueried },
        )
    }

    private companion object {
        val WHITESPACE = Regex("\\s+")
        val DEFAULT_HUB_LIBRARY_KINDS = setOf(MediaKind.MOVIE, MediaKind.SHOW, MediaKind.CLIP, MediaKind.ARTIST)
    }
}

/**
 * Runs one server's leg of a fan-out under [deadline]: the legs' results are shown together, so a server that accepted
 * the connection and stopped answering would otherwise hold back every other server. Expiry cancels the leg and fails
 * it as a [MediaServerHttpErrorType.CONNECTION_TIMEOUT]: a failure, not a cancellation.
 */
internal suspend fun <R> withinServerDeadline(deadline: Duration, operation: String, run: suspend () -> R): R =
    try {
        withTimeout(deadline) { run() }
    } catch (e: TimeoutCancellationException) {
        throw MediaServerHttpException(
            MediaServerHttpErrorType.CONNECTION_TIMEOUT,
            "$operation exceeded its ${deadline.inWholeSeconds}s budget",
            cause = e,
        )
    }

/** A request cancelled under the caller (a client torn down mid-request), as opposed to a settled failure. */
private fun isCancellation(error: Throwable): Boolean =
    (error is MediaServerHttpException && error.isCancellation) ||
        (error is CancellationException && error !is TimeoutCancellationException)

/**
 * [items] without the ones in a hidden library. Items with no library (Plex search's shared and external rows) are
 * kept: the user can't have hidden a library that isn't theirs.
 */
private fun withoutHiddenLibraries(items: List<MediaItem>, hiddenLibraryKeys: Set<String>?): List<MediaItem> {
    if (hiddenLibraryKeys.isNullOrEmpty()) return items
    return items.filter { item -> item.libraryGlobalKey.let { it == null || it !in hiddenLibraryKeys } }
}

/** The library ids [serverId] owns among the cross-server [hiddenLibraryKeys] (`serverId:libraryId`). */
private fun hiddenLibraryIdsOn(serverId: ServerId, hiddenLibraryKeys: Set<String>?): Set<String> {
    if (hiddenLibraryKeys.isNullOrEmpty()) return emptySet()
    return hiddenLibraryKeys.mapNotNullTo(LinkedHashSet()) { key ->
        parseGlobalKey(key)?.takeIf { it.first == serverId }?.second
    }
}

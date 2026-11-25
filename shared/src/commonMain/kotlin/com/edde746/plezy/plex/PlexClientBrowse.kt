package com.edde746.plezy.plex

import com.edde746.plezy.backend.HubFetchDiagnostics
import com.edde746.plezy.backend.ItemWithOnDeck
import com.edde746.plezy.backend.LibraryEventChannel
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.MediaServerTimeouts
import com.edde746.plezy.backend.PlaybackReportMetadata
import com.edde746.plezy.backend.PlaybackSessionTerminatedException
import com.edde746.plezy.backend.net.MediaServerResponse
import com.edde746.plezy.backend.net.fetchWithCacheFallback
import com.edde746.plezy.backend.net.fetchWithCacheFirst
import com.edde746.plezy.backend.net.retryTransientMediaServerCall
import com.edde746.plezy.backend.net.throwIfHttpError
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.LibraryQuery
import com.edde746.plezy.model.MediaFileInfo
import com.edde746.plezy.model.MediaHub
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.model.drainPages
import com.edde746.plezy.model.fallbackPageTotal
import com.edde746.plezy.net.UriComponent
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import com.edde746.plezy.servers.KtorLibraryEventConnector
import kotlin.time.Duration

/** Page size when walking every page of a paginated endpoint. */
internal const val PLEX_FETCH_ALL_PAGE_SIZE = 200

/** PMS caps a collection's `/children` page at this size. */
private const val COLLECTION_CHILDREN_MAX_PAGE_SIZE = 120

private const val TAG = "PlexClient"
private val COLLECTION_CHILDREN_PATH = Regex("^/library/collections/[^/]+/children/?$")
private val VIDEO_KINDS = setOf(MediaKind.MOVIE, MediaKind.SHOW, MediaKind.SEASON, MediaKind.EPISODE)
private val MUSIC_KINDS = setOf(MediaKind.ARTIST, MediaKind.ALBUM, MediaKind.TRACK)
private val SEARCH_KINDS = setOf(MediaKind.MOVIE, MediaKind.SHOW, MediaKind.ARTIST, MediaKind.ALBUM, MediaKind.TRACK)
private val FULL_METADATA_QUERY: Map<String, Any?> = mapOf("includeChapters" to 1, "includeMarkers" to 1, "checkFiles" to 1, "includeStreams" to 1)

private fun isVideoHubItem(item: MediaItem) = item.kind in VIDEO_KINDS

private fun isVideoOrMusicHubItem(item: MediaItem) = item.kind in VIDEO_KINDS || item.kind in MUSIC_KINDS

private fun isVideoOrCollectionHubItem(item: MediaItem) = item.kind in VIDEO_KINDS || item.kind == MediaKind.COLLECTION

// Response helpers shared by the PlexClient*.kt files.

/** `X-Plex-Container-Start` / `X-Plex-Container-Size`, each only when given. */
internal fun plexPaginationParams(start: Int?, size: Int?): Map<String, Any?> = buildMap {
    if (start != null) put("X-Plex-Container-Start", start)
    if (size != null) put("X-Plex-Container-Size", size)
}

/**
 * A page's total: the `X-Plex-Container-Total-Size` header, else the body's `totalSize`; with neither and no paging
 * requested, the body's `size` or the item count; else [fallbackPageTotal].
 */
internal fun plexResponseTotalSize(response: MediaServerResponse, itemCount: Int, start: Int?, requestedSize: Int?): Int {
    response.headers.entries.firstOrNull { it.key.equals("X-Plex-Container-Total-Size", ignoreCase = true) }
        ?.value?.trim()?.toIntOrNull()?.let { return it }
    val container = response.data.mediaContainer()
    container?.get("totalSize").flexInt()?.let { return it }
    val offset = start ?: container?.get("offset").flexInt() ?: 0
    if (start == null && requestedSize == null) return container?.get("size").flexInt() ?: itemCount
    return fallbackPageTotal(offset, itemCount, requestedSize)
}

/**
 * A metadata row tagged with this server. Its library is the row's own (`librarySectionID`, or a section key it names),
 * else [librarySectionId]/[librarySectionTitle].
 */
internal fun PlexClient.mediaItemFromJson(json: JsonObject, librarySectionId: Int? = null, librarySectionTitle: String? = null): MediaItem =
    PlexMappers.mediaItem(json, serverId, serverName)
        .withPlexLibrary(plexLibrarySectionIdFromJson(json) ?: librarySectionId, plexLibrarySectionTitleFromJson(json) ?: librarySectionTitle)

private fun PlexClient.metadataItemsOf(container: JsonObject?, librarySectionId: Int?, librarySectionTitle: String?): List<MediaItem> {
    val sectionId = plexLibrarySectionIdFromJson(container) ?: librarySectionId
    val sectionTitle = plexLibrarySectionTitleFromJson(container) ?: librarySectionTitle
    return container?.get("Metadata").objectList().map { mediaItemFromJson(it, sectionId, sectionTitle) }
}

/** The container's `Metadata` rows; a row without a library inherits the container's, else the given one. */
internal fun PlexClient.metadataItems(
    response: MediaServerResponse,
    librarySectionId: Int? = null,
    librarySectionTitle: String? = null,
): List<MediaItem> = metadataItemsOf(response.data.mediaContainer(), librarySectionId, librarySectionTitle)

/** [metadataItems] of a cached response. */
internal fun PlexClient.metadataItemsFromCache(cached: JsonObject): List<MediaItem> = metadataItemsOf(cached.mediaContainer(), null, null)

/** One page of [path]: its items and [plexResponseTotalSize]. */
internal suspend fun PlexClient.fetchPlexPage(
    path: String,
    start: Int?,
    size: Int?,
    librarySectionId: Int? = null,
    librarySectionTitle: String? = null,
    query: Map<String, Any?>? = null,
): LibraryPage<MediaItem> {
    val response = getWithFailover(path, query.orEmpty() + plexPaginationParams(start, size))
    val items = metadataItems(response, librarySectionId, librarySectionTitle)
    return LibraryPage(items, plexResponseTotalSize(response, items.size, start, size), start ?: 0)
}

/**
 * Every page of [path] ([PLEX_FETCH_ALL_PAGE_SIZE] each) as one response: the first page's container fields, status
 * and headers, every page's `Metadata`, and `size`/`totalSize` set to the count. It caches as one row.
 */
internal suspend fun PlexClient.fetchAllPagesResponse(path: String, query: Map<String, Any?>? = null): MediaServerResponse {
    var first: MediaServerResponse? = null
    var firstContainer: JsonObject? = null
    val all = ArrayList<JsonElement>()
    var start = 0
    while (true) {
        val response = getWithFailover(path, query.orEmpty() + plexPaginationParams(start, PLEX_FETCH_ALL_PAGE_SIZE))
        val container = response.data.mediaContainer()
        val page = container?.get("Metadata") as? JsonArray ?: JsonArray(emptyList())
        if (first == null) {
            first = response
            firstContainer = container
        }
        all.addAll(page)
        val total = plexResponseTotalSize(response, page.size, start, PLEX_FETCH_ALL_PAGE_SIZE)
        start += page.size
        if (page.isEmpty() || start >= total) break
    }
    val container = JsonObject(
        firstContainer.orEmpty() + mapOf(
            "Metadata" to JsonArray(all),
            "size" to JsonPrimitive(all.size),
            "totalSize" to JsonPrimitive(all.size),
        ),
    )
    return first!!.copy(data = JsonObject(mapOf("MediaContainer" to container)))
}

/**
 * The first `Metadata` row of `/library/metadata/{ratingKey}`, cache first. A miss fetches the full shape (chapters,
 * markers, files, streams) under [context], so the token sent and the cache scope written belong to one profile.
 */
internal suspend fun PlexClient.fetchRawMetadataJsonCacheFirst(ratingKey: String, context: PlexClient.RequestContext = captureRequestContext()): JsonObject? {
    val endpoint = "/library/metadata/$ratingKey"
    val data = fetchWithCacheFirst(
        cache = cache.store,
        cacheServerId = context.cacheServerId,
        cacheKey = endpoint,
        offline = isOfflineMode,
        networkCall = { http.get(endpoint, FULL_METADATA_QUERY, context.headers) },
        parseCache = { it },
        parseResponse = { it.data as? JsonObject },
    )
    return PlexCacheParser.extractFirstMetadata(data)
}

// Server state.

/** `/media/providers` (under [headers] when given, e.g. a candidate profile's): libraries, hub keys and EPG providers. */
internal suspend fun PlexClient.fetchMediaProviders(headers: Map<String, String>? = null): PlexMediaProviders {
    val container = getWithFailover("/media/providers", headers = headers).data.mediaContainer() ?: return PlexMediaProviders()
    val providers = container["MediaProvider"] as? JsonArray ?: return PlexMediaProviders()
    val libraries = ArrayList<MediaLibrary>()
    val epg = ArrayList<PlexEpgProvider>()
    var homeHubKey: String? = null
    var promotedHubKey: String? = null
    var continueWatchingHubKey: String? = null
    for (provider in providers.filterIsInstance<JsonObject>()) {
        val identifier = provider["identifier"].stringOrNull() ?: continue
        val features = (provider["Feature"] as? JsonArray ?: continue).filterIsInstance<JsonObject>()
        if (identifier == PLEX_LIBRARY_IDENTIFIER) {
            for (feature in features) {
                val type = feature["type"].stringOrNull()
                if (type == "promoted") promotedHubKey = promotedHubKey ?: feature["key"].stringOrNull()
                if (type == "continuewatching") continueWatchingHubKey = continueWatchingHubKey ?: feature["key"].stringOrNull()
                if (type != "content") continue
                for (dir in (feature["Directory"] as? JsonArray).orEmpty().filterIsInstance<JsonObject>()) {
                    try {
                        val id = dir["id"].scalarString()
                        if (id == null) {
                            homeHubKey = homeHubKey ?: dir["hubKey"].stringOrNull()
                            continue
                        }
                        if (dir["type"].stringOrNull() == "playlist") continue
                        val isShared = id.toIntOrNull() == null && dir["key"].scalarString()?.startsWith("/library/shared") == true
                        if (id.toIntOrNull() == null && !isShared) continue
                        libraries += PlexMappers.mediaLibrary(JsonObject(dir + ("key" to JsonPrimitive(id))), serverId, serverName, isShared)
                    } catch (e: IllegalArgumentException) {
                        Log.w(TAG, e) { "Failed to parse a media provider directory entry" }
                    }
                }
            }
        }
        if (provider["protocols"].stringOrNull()?.contains("livetv") == true) {
            for (feature in features) {
                if (feature["type"].stringOrNull() != "grid") continue
                val gridEndpoint = feature["key"].stringOrNull() ?: continue
                epg += PlexEpgProvider(identifier, gridEndpoint, provider["id"].scalarString())
            }
        }
    }
    return PlexMediaProviders(libraries, epg, homeHubKey, promotedHubKey, continueWatchingHubKey)
}

/**
 * `/:/prefs` into [PlexClient.serverPrefs], mirroring the watched threshold through the environment. A failure is
 * logged and leaves the previous preferences.
 */
internal suspend fun PlexClient.fetchServerPrefs() {
    try {
        val previous = if (hasServerPrefs) watchedThresholdPercent else null
        val container = getWithFailover("/:/prefs").data.mediaContainer()
        serverPrefs = container?.get("Setting").objectList().mapNotNull { setting ->
            val id = setting["id"].stringOrNull() ?: return@mapNotNull null
            id to (setting["value"] ?: return@mapNotNull null)
        }.toMap()
        // Runs on every connect: the setting is written only when the server's value moved.
        if (watchedThresholdPercent != previous) environment.onWatchedThresholdChanged(serverId, watchedThresholdPercent)
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.d(TAG, e) { "Failed to fetch server prefs" }
    }
}

// Libraries.

internal suspend fun PlexClient.fetchLibrariesImpl(): List<MediaLibrary> {
    if (providers.libraries.isNotEmpty()) return providers.libraries
    val container = getWithFailover("/library/sections").data.mediaContainer()
    return container?.get("Directory").objectList().map { PlexMappers.mediaLibrary(it, serverId, serverName) }
}

/** One page of a section (`shared`: the individually shared items), collections included. */
internal suspend fun PlexClient.fetchLibraryPagedContentImpl(libraryId: String, query: LibraryQuery, libraryKind: MediaKind?): LibraryPage<MediaItem> {
    val filters = plexLibraryQueryParameters(query).toMap() + ("includeCollections" to "1")
    val path = if (libraryId == "shared") "/library/shared/all" else "/library/sections/$libraryId/all"
    return fetchPlexPage(path, query.offset, query.limit, plexLibrarySectionIdFromString(libraryId), query = filters)
}

// Items.

/** Only a timeout or connection failure may answer from the cache: a status or a bad payload must surface. */
private fun shouldFallbackItemLookup(error: Throwable) = error is MediaServerHttpException && error.isTransient

private suspend fun PlexClient.fetchMetadataWithImages(ratingKey: String, includeOnDeck: Boolean): ItemWithOnDeck {
    val endpoint = "/library/metadata/$ratingKey"
    val query = buildMap<String, Any?> {
        put("includeChapters", 1)
        put("includeMarkers", 1)
        if (includeOnDeck) put("includeOnDeck", 1)
        put("checkFiles", 1)
        put("includeStreams", 1)
    }
    return fetchWithCacheFallback(
        cache = cache.store,
        cacheServerId = cacheServerId,
        cacheKey = endpoint,
        offline = isOfflineMode,
        networkCall = { http.get(endpoint, query) },
        parseCache = { cached -> ItemWithOnDeck(metadataItemsFromCache(cached).firstOrNull(), null) },
        parseResponse = { response ->
            val container = response.data.mediaContainer()
            val json = container?.get("Metadata").firstObject() ?: return@fetchWithCacheFallback ItemWithOnDeck(null, null)
            val containerId = plexLibrarySectionIdFromJson(container)
            val containerTitle = plexLibrarySectionTitleFromJson(container)
            val item = mediaItemFromJson(json, containerId, containerTitle)
            val onDeck = if (includeOnDeck) (json["OnDeck"] as? JsonObject)?.get("Metadata") as? JsonObject else null
            ItemWithOnDeck(
                item,
                onDeck?.let { mediaItemFromJson(it, item.libraryId?.toIntOrNull() ?: containerId, item.libraryTitle ?: containerTitle) },
            )
        },
        shouldFallback = ::shouldFallbackItemLookup,
    ) ?: ItemWithOnDeck(null, null)
}

/** The item, with chapters, markers and streams; a 404 is no item. The cache answers offline or after a transient failure. */
internal suspend fun PlexClient.fetchItemImpl(id: String): MediaItem? = lookupItem(id, includeOnDeck = false).item

/** [fetchItemImpl] plus the show's on-deck episode, from one request; a cached answer carries no on-deck episode. */
internal suspend fun PlexClient.fetchItemWithOnDeckImpl(id: String): ItemWithOnDeck = lookupItem(id, includeOnDeck = true)

private suspend fun PlexClient.lookupItem(id: String, includeOnDeck: Boolean): ItemWithOnDeck = try {
    fetchMetadataWithImages(id, includeOnDeck)
} catch (e: MediaServerHttpException) {
    if (e.statusCode != 404) throw e
    ItemWithOnDeck(null, null)
}

/** Every child (every page), cached as one row; the cache answers offline or after any failure. */
internal suspend fun PlexClient.fetchChildrenImpl(parentId: String): List<MediaItem> {
    val endpoint = "/library/metadata/$parentId/children"
    return fetchWithCacheFallback(
        cache = cache.store,
        cacheServerId = cacheServerId,
        cacheKey = endpoint,
        offline = isOfflineMode,
        networkCall = { fetchAllPagesResponse(endpoint, mapOf("includeStreams" to 1)) },
        parseCache = { metadataItemsFromCache(it) },
        parseResponse = { metadataItems(it) },
    ).orEmpty()
}

internal suspend fun PlexClient.fetchChildrenPageImpl(parentId: String, start: Int?, size: Int?): LibraryPage<MediaItem> =
    fetchPlexPage("/library/metadata/$parentId/children", start, size, query = mapOf("includeStreams" to 1))

/** The episodes under a show or season (`/grandchildren`: `/allLeaves` answers nothing for a season). */
internal suspend fun PlexClient.fetchPlayableDescendantsPageImpl(parentId: String, start: Int?, size: Int?): LibraryPage<MediaItem> =
    fetchPlexPage("/library/metadata/$parentId/grandchildren", start, size, query = mapOf("includeStreams" to 1))

/** An album's tracks are its children; an artist's tracks and a show's or season's episodes its grandchildren. */
internal suspend fun PlexClient.fetchPlayableDescendantsImpl(parentId: String): List<MediaItem> {
    if (fetchItemKind(parentId) == MediaKind.ALBUM) return fetchChildrenImpl(parentId)
    return drainPages(PLEX_FETCH_ALL_PAGE_SIZE) { start, size -> fetchPlayableDescendantsPageImpl(parentId, start, size) }
}

private suspend fun PlexClient.fetchItemKind(ratingKey: String): MediaKind = try {
    MediaKind.fromString(fetchRawMetadataJsonCacheFirst(ratingKey)?.get("type").stringOrNull())
} catch (e: CancellationException) {
    throw e
} catch (e: Exception) {
    Log.w(TAG, e) { "Failed to resolve the item kind of $ratingKey" }
    MediaKind.UNKNOWN
}

/** Trailers and other extras; the cache answers offline or after any failure. */
internal suspend fun PlexClient.fetchExtrasImpl(id: String): List<MediaItem> {
    val endpoint = "/library/metadata/$id/extras"
    return fetchWithCacheFallback(
        cache = cache.store,
        cacheServerId = cacheServerId,
        cacheKey = endpoint,
        offline = isOfflineMode,
        networkCall = { http.get(endpoint) },
        parseCache = { metadataItemsFromCache(it) },
        parseResponse = { metadataItems(it) },
    ).orEmpty()
}

/**
 * The file-info sheet's metadata: the cached row, unless it lacks the stream detail (some part without `Stream`,
 * `exists` or `accessible`), then refetched in full under the same profile (online only; a failed refetch keeps the
 * lean row). Any failure is no info.
 */
internal suspend fun PlexClient.getFileInfoImpl(item: MediaItem): MediaFileInfo? = try {
    val context = captureRequestContext()
    var json = fetchRawMetadataJsonCacheFirst(item.id, context)
    if (!hasStreamDetail(json) && !isOfflineMode) {
        val endpoint = "/library/metadata/${item.id}"
        val refetched = fetchWithCacheFallback(
            cache = cache.store,
            cacheServerId = context.cacheServerId,
            cacheKey = endpoint,
            offline = false,
            networkCall = { http.get(endpoint, FULL_METADATA_QUERY, context.headers) },
            parseCache = { it },
            parseResponse = { it.data as? JsonObject },
        )
        json = PlexCacheParser.extractFirstMetadata(refetched) ?: json
    }
    parsePlexFileInfoFromJson(json)
} catch (e: CancellationException) {
    throw e
} catch (e: Exception) {
    Log.e(TAG, e) { "Failed to get file info" }
    null
}

/** Whether every part carries the keys `includeStreams=1&checkFiles=1` add; a row without media has nothing to probe. */
private fun hasStreamDetail(metadata: JsonObject?): Boolean =
    metadata?.get("Media").objectList().all { media ->
        media["Part"].objectList().all { part -> "Stream" in part && "exists" in part && "accessible" in part }
    }

// Hubs.

private fun PlexClient.parseHubs(
    response: MediaServerResponse,
    librarySectionId: Int?,
    librarySectionTitle: String?,
    filter: (MediaItem) -> Boolean,
): List<MediaHub> {
    val container = response.data.mediaContainer() ?: return emptyList()
    val containerId = plexLibrarySectionIdFromJson(container) ?: librarySectionId
    val containerTitle = plexLibrarySectionTitleFromJson(container) ?: librarySectionTitle
    val hubs = ArrayList<MediaHub>()
    for (json in container["Hub"].objectList()) {
        try {
            val hubId = plexLibrarySectionIdFromJson(json) ?: containerId
            val hubTitle = plexLibrarySectionTitleFromJson(json) ?: containerTitle
            val hub = PlexMappers.mediaHub(json, serverId, serverName)
            val items = hub.items.map { it.withPlexLibrary(hubId, hubTitle) }.filter(filter)
            if (items.isNotEmpty()) hubs += hub.copy(items = items)
        } catch (e: IllegalArgumentException) {
            Log.w(TAG, e) { "Skipping a hub that does not parse" }
        }
    }
    return hubs
}

/** A hub request within [deadline] (connection errors retried, no endpoint failover); a failure is recorded and no hubs. */
private suspend fun PlexClient.fetchHubs(
    path: String,
    query: Map<String, Any?>,
    operation: String,
    deadline: Duration,
    diagnostics: HubFetchDiagnostics?,
    librarySectionId: Int? = null,
    filter: (MediaItem) -> Boolean,
): List<MediaHub> = try {
    val response = retryTransientMediaServerCall(operation, deadline) { timeout ->
        getWithFailover(path, query, timeout = timeout, allowEndpointFailover = false)
    }
    parseHubs(response, librarySectionId, null, filter)
} catch (e: CancellationException) {
    diagnostics?.recordFailure(e)
    throw e
} catch (e: Exception) {
    diagnostics?.recordFailure(e)
    Log.e(TAG, e) { "Failed: $operation" }
    emptyList()
}

/** The home hubs: the promoted hub key, else the home hub key, else `/hubs`; video rows only. */
internal suspend fun PlexClient.fetchGlobalHubsImpl(limit: Int, diagnostics: HubFetchDiagnostics?): List<MediaHub> = fetchHubs(
    path = providers.promotedHubKey ?: providers.homeHubKey ?: "/hubs",
    query = mapOf("count" to limit, "includeGuids" to 1),
    operation = "Plex global hubs",
    deadline = MediaServerTimeouts.HOME_HUB_DEADLINE,
    diagnostics = diagnostics,
    filter = ::isVideoHubItem,
)

/** A section's hubs, stamped with the section; video and music rows. */
internal suspend fun PlexClient.fetchLibraryHubsImpl(libraryId: String, limit: Int, diagnostics: HubFetchDiagnostics?): List<MediaHub> = fetchHubs(
    path = "/hubs/sections/$libraryId",
    query = mapOf("count" to limit, "includeGuids" to 1),
    operation = "Plex library hubs",
    deadline = MediaServerTimeouts.LIBRARY_HUB_DEADLINE,
    diagnostics = diagnostics,
    librarySectionId = plexLibrarySectionIdFromString(libraryId),
    filter = ::isVideoOrMusicHubItem,
)

/** Collections, similar titles and "more from" rows of an item; video and collection rows. */
internal suspend fun PlexClient.fetchRelatedHubsImpl(id: String, count: Int): List<MediaHub> = fetchHubs(
    path = "/hubs/metadata/$id/related",
    query = mapOf("count" to count),
    operation = "Plex related hubs",
    deadline = MediaServerTimeouts.LIBRARY_HUB_DEADLINE,
    diagnostics = null,
    filter = ::isVideoOrCollectionHubItem,
)

/** The largest page a hub answers: a collection's `/children` is capped. */
private fun hubRequestPageSize(hubKey: String): Int =
    if (COLLECTION_CHILDREN_PATH.matches(hubKey.substringBefore('?'))) COLLECTION_CHILDREN_MAX_PAGE_SIZE else PLEX_FETCH_ALL_PAGE_SIZE

/** Every video and music row of a hub (View All); a failure is no rows. */
internal suspend fun PlexClient.fetchMoreHubItemsImpl(hubId: String): List<MediaItem> = try {
    val sectionId = plexLibrarySectionIdFromString(hubId)
    drainPages(hubRequestPageSize(hubId)) { start, size -> fetchPlexPage(hubId, start, size, sectionId) }.filter(::isVideoOrMusicHubItem)
} catch (e: CancellationException) {
    throw e
} catch (e: Exception) {
    Log.e(TAG, e) { "Failed to get hub content" }
    emptyList()
}

/**
 * A page of a hub's video and music rows, [start] counting filtered rows. Raw pages are fetched until the page fills or
 * the hub runs out; the total is exact once it ran out, else one past the page.
 */
internal suspend fun PlexClient.fetchMoreHubItemsPageImpl(hubId: String, start: Int?, size: Int?): LibraryPage<MediaItem> {
    val filteredOffset = start ?: 0
    val pageSize = size ?: PLEX_FETCH_ALL_PAGE_SIZE
    val maxRawPageSize = hubRequestPageSize(hubId)
    val rawPageSize = if (maxRawPageSize < PLEX_FETCH_ALL_PAGE_SIZE) maxRawPageSize else maxOf(pageSize, PLEX_FETCH_ALL_PAGE_SIZE)
    val sectionId = plexLibrarySectionIdFromString(hubId)
    val pageItems = ArrayList<MediaItem>()
    var rawOffset = 0
    var filteredSeen = 0
    var rawFinished = false
    while (pageItems.size < pageSize && !rawFinished) {
        val raw = fetchPlexPage(hubId, rawOffset, rawPageSize, sectionId)
        rawOffset += raw.items.size
        for (item in raw.items) {
            if (!isVideoOrMusicHubItem(item)) continue
            if (filteredSeen >= filteredOffset && pageItems.size < pageSize) pageItems += item
            filteredSeen++
        }
        rawFinished = raw.items.isEmpty() || rawOffset >= raw.totalCount
    }
    val total = if (rawFinished) filteredSeen else filteredOffset + pageItems.size + 1
    return LibraryPage(pageItems, total, filteredOffset)
}

/**
 * Continue watching from the provider's continue-watching hub, else `/hubs` (`home.continue,home.ondeck`); both honour
 * the server's on-deck window. Episodes of one show collapse to the first, replaced by a later one with progress when
 * the first has none. Missing show logos are filled in.
 */
internal suspend fun PlexClient.fetchContinueWatchingImpl(count: Int?): List<MediaItem> {
    val hubKey = providers.continueWatchingHubKey
    val query = buildMap<String, Any?> {
        put("count", count)
        put("includeGuids", 1)
        if (hubKey == null) put("identifier", "home.continue,home.ondeck")
    }
    val response = retryTransientMediaServerCall("Plex continue watching hubs", MediaServerTimeouts.HOME_HUB_DEADLINE) { timeout ->
        getWithFailover(hubKey ?: "/hubs", query, timeout = timeout, allowEndpointFailover = false)
    }
    val result = ArrayList<MediaItem>()
    for (item in parseHubs(response, null, null, ::isVideoHubItem).flatMap { it.items }) {
        val showKey = item.grandparentId
        if (item.kind == MediaKind.EPISODE && showKey != null) {
            val index = result.indexOfFirst { it.kind == MediaKind.EPISODE && it.grandparentId == showKey }
            if (index != -1) {
                if (result[index].viewOffsetMs == null && item.viewOffsetMs != null) result[index] = item
                continue
            }
        }
        result += item
    }
    return backfillMissingLogos(result)
}

/**
 * Episode and season rows some servers send without the show's logo get it from one bulk metadata request. A failed
 * lookup leaves the rows as they are.
 */
private suspend fun PlexClient.backfillMissingLogos(items: MutableList<MediaItem>): List<MediaItem> {
    val missingByOwner = LinkedHashMap<String, MutableList<Int>>()
    items.forEachIndexed { index, item ->
        if (!item.clearLogoPath.isNullOrEmpty()) return@forEachIndexed
        val owner = when (item.kind) {
            MediaKind.EPISODE -> item.grandparentId
            MediaKind.SEASON -> item.parentId
            else -> null
        }
        if (!owner.isNullOrEmpty()) missingByOwner.getOrPut(owner) { ArrayList() } += index
    }
    if (missingByOwner.isEmpty()) return items
    try {
        val response = getWithFailover("/library/metadata/${missingByOwner.keys.joinToString(",")}", allowEndpointFailover = false)
        val logos = HashMap<String, String>()
        for (json in response.data.mediaContainer()?.get("Metadata").objectList()) {
            val owner = PlexMappers.mediaItem(json)
            val logo = owner.clearLogoPath
            if (owner.id.isNotEmpty() && !logo.isNullOrEmpty()) logos[owner.id] = logo
        }
        for ((owner, indexes) in missingByOwner) {
            val logo = logos[owner] ?: continue
            for (index in indexes) items[index] = items[index].copy(clearLogoPath = logo)
        }
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.d(TAG, e) { "Failed to backfill continue-watching logos" }
    }
    return items
}

// Search.

private fun isPersonalMediaGuid(guid: String?) = guid != null && ".agents.none://" in guid

/**
 * Movies, shows and music matching [query] (`/library/search`, at most [limit] rows). A saturated answer may have
 * crowded out whole categories: each one missing is searched on its own (a failure there keeps the primary rows) and
 * the rows merged without duplicates, primary rows first.
 */
internal suspend fun PlexClient.searchItemsImpl(query: String, limit: Int): List<MediaItem> {
    val (results, rawCount) = searchByTypes(query, "movies,tv,music,otherVideos", limit)
    if (limit <= 0 || rawCount < limit) return results
    var hasMovie = false
    var hasPersonalMedia = false
    for (item in results) {
        if (isPersonalMediaGuid(item.guid)) hasPersonalMedia = true else if (item.kind == MediaKind.MOVIE) hasMovie = true
    }
    val missing = buildList {
        if (!hasMovie) add("movies")
        if (results.none { it.kind == MediaKind.SHOW }) add("tv")
        if (results.none { it.kind in MUSIC_KINDS }) add("music")
        if (!hasPersonalMedia) add("otherVideos")
    }
    if (missing.isEmpty()) return results
    Log.i(TAG) { "Plex search saturated; fetching omitted categories (${missing.joinToString(",")})" }
    val supplemental = coroutineScope {
        missing.map { types -> async { searchSupplemental(query, types, limit) } }.awaitAll()
    }
    val deduplicated = LinkedHashMap<String, MediaItem>()
    for (item in results + supplemental.flatten()) {
        val identity = item.id.ifEmpty { "${item.kind.id}:${item.guid.orEmpty()}:${item.title.orEmpty()}" }
        deduplicated.getOrPut(identity) { item }
    }
    return deduplicated.values.toList()
}

private suspend fun PlexClient.searchSupplemental(query: String, searchTypes: String, limit: Int): List<MediaItem> = try {
    searchByTypes(query, searchTypes, limit).first
} catch (e: CancellationException) {
    throw e
} catch (e: MediaServerHttpException) {
    if (e.isCancellation) throw e
    Log.w(TAG, e) { "Plex supplemental $searchTypes search failed; keeping primary results" }
    emptyList()
} catch (e: Exception) {
    Log.w(TAG, e) { "Plex supplemental $searchTypes search failed; keeping primary results" }
    emptyList()
}

/** The usable rows and the raw `SearchResult` count. */
private suspend fun PlexClient.searchByTypes(query: String, searchTypes: String, limit: Int): Pair<List<MediaItem>, Int> {
    val response = getWithFailover(
        "/library/search",
        mapOf(
            "query" to query,
            "limit" to limit,
            "searchTypes" to searchTypes,
            "includeCollections" to 1,
            "includeExternalMedia" to 1,
            "X-Plex-Container-Size" to limit,
        ),
    )
    val searchResults = response.data.mediaContainer()?.get("SearchResult") as? JsonArray ?: return emptyList<MediaItem>() to 0
    val items = ArrayList<MediaItem>()
    for (result in searchResults) {
        val metadata = (result as? JsonObject)?.get("Metadata") as? JsonObject ?: continue
        if (MediaKind.fromString(metadata["type"].stringOrNull()) !in SEARCH_KINDS) continue
        try {
            items += mediaItemFromJson(metadata)
        } catch (e: IllegalArgumentException) {
            Log.w(TAG, e) { "Failed to parse a search result" }
        }
    }
    return items to searchResults.size
}

// Mutations.

internal suspend fun PlexClient.markWatchedImpl(item: MediaItem) {
    throwIfHttpError(http.put("/:/scrobble", mapOf("key" to item.id, "identifier" to PLEX_LIBRARY_IDENTIFIER)))
}

internal suspend fun PlexClient.markUnwatchedImpl(item: MediaItem) {
    throwIfHttpError(http.put("/:/unscrobble", mapOf("key" to item.id, "identifier" to PLEX_LIBRARY_IDENTIFIER)))
}

/** Hides the item from Continue Watching, leaving its watch state and progress. */
internal suspend fun PlexClient.removeFromContinueWatchingImpl(item: MediaItem) {
    throwIfHttpError(http.put("/actions/removeFromContinueWatching", mapOf("ratingKey" to item.id)))
}

/** [rating] 0–10 (each point half a star); -1 clears it. */
internal suspend fun PlexClient.rateImpl(item: MediaItem, rating: Double) {
    throwIfHttpError(http.put("/:/rate", mapOf("key" to item.id, "identifier" to PLEX_LIBRARY_IDENTIFIER, "rating" to rating)))
}

/**
 * A `/:/timeline` report ([state] `playing`, `paused`, `stopped` or `buffering`). [playSessionId] goes out as
 * `X-Plex-Session-Identifier`, so the server ties the report to the stream it serves. A non-stopped report the server
 * answers with a `terminationCode` throws [PlaybackSessionTerminatedException]: the session was ended server-side. The
 * stopped report is the cleanup call and never throws on it.
 */
internal suspend fun PlexClient.updateProgress(
    itemId: String,
    position: Duration,
    state: String,
    duration: Duration?,
    playSessionId: String?,
    report: PlaybackReportMetadata = PlaybackReportMetadata.live(),
) {
    val query = buildMap<String, Any?> {
        put("ratingKey", itemId)
        put("key", "/library/metadata/$itemId")
        put("time", position.inWholeMilliseconds)
        put("state", state)
        put("duration", duration?.inWholeMilliseconds)
        if (report.isOfflineReplay) put("offline", 1)
        report.recordedAt?.let { put("updated", it.epochSeconds) }
        report.willContinue?.let { put("continuing", if (it) 1 else 0) }
    }
    val response = http.post("/:/timeline", query, headers = playSessionId?.let { mapOf("X-Plex-Session-Identifier" to it) })
    throwIfHttpError(response)
    if (state == "stopped") return
    val container = response.data.mediaContainer()
    val code = container?.get("terminationCode").flexInt() ?: return
    val reason = container?.get("terminationText").scalarString()
    Log.w(TAG) { "Plex terminated the playback session of $itemId (code $code): $reason" }
    throw PlaybackSessionTerminatedException(code, reason)
}

// Images.

/** `minSize=1` covers the box, `0` fits inside it; `upscale=0` never enlarges past the source. */
private fun transcodeSizeParams(width: Int?, height: Int?, cover: Boolean): List<String> = buildList {
    if (width != null) add("width=$width")
    if (height != null) add("height=$height")
    add("minSize=${if (cover) 1 else 0}")
    add("upscale=0")
}

/** [path] on the current endpoint with the token; empty for no path. */
private fun PlexClient.plainImageUrl(path: String?): String {
    if (path.isNullOrEmpty()) return ""
    return withPlexToken(http.buildUri(path).toString(), config.token)
}

/**
 * A sized server image goes through the photo transcoder; an unsized one or a client without a token is the plain URL.
 * An absolute URL is another host's image and never gets the token: [externalImageUrlImpl] proxies it when sized.
 */
internal fun PlexClient.thumbnailUrlImpl(path: String?, width: Int?, height: Int?, cover: Boolean): String {
    if (path.isNullOrEmpty()) return ""
    if (path.startsWith("http://") || path.startsWith("https://")) return externalImageUrlImpl(path, width, height, cover)
    val token = config.token
    if ((width == null && height == null) || token == null) return plainImageUrl(path)
    val parts = transcodeSizeParams(width, height, cover) + "url=${UriComponent.encode(withPlexToken(path, token))}" + "X-Plex-Token=$token"
    return "${config.baseUrl}/photo/:/transcode?${parts.joinToString("&")}"
}

/** An external image through the server's photo transcoder when sized and a token exists; else unchanged. */
internal fun PlexClient.externalImageUrlImpl(url: String, width: Int?, height: Int?, cover: Boolean): String {
    val token = config.token
    if (token == null || (width == null && height == null)) return url
    val parts = transcodeSizeParams(width, height, cover) + "url=${UriComponent.encode(url)}" + "X-Plex-Token=$token"
    return "${config.baseUrl}/photo/:/transcode?${parts.joinToString("&")}"
}

// Library events.

/** The server's notification websocket on the current endpoint and token, over the app's HTTP client. */
internal fun PlexClient.createLibraryEventChannelImpl(): LibraryEventChannel? = PlexLibraryEventSocket(
    serverId = serverId,
    baseUrl = { http.baseUrl },
    token = { config.token },
    connector = KtorLibraryEventConnector(httpClient),
    scope = scope,
)

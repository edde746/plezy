package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.ItemWithOnDeck
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.MediaServerTimeouts
import com.edde746.plezy.backend.PLAYBACK_METADATA_CACHE_FRESHNESS
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.LibraryFilterOperator
import com.edde746.plezy.model.LibraryFilterResult
import com.edde746.plezy.model.LibraryGenre
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.LibraryQuery
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.model.MediaFilter
import com.edde746.plezy.model.MediaFilterField
import com.edde746.plezy.model.MediaFilterType
import com.edde746.plezy.model.MediaFilterValue
import com.edde746.plezy.model.MediaHub
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.model.MediaPersonDetails
import com.edde746.plezy.model.MediaSort
import com.edde746.plezy.model.SpecialsOrdering
import com.edde746.plezy.model.drainPages
import com.edde746.plezy.model.fallbackPageTotal
import com.edde746.plezy.model.sortEpisodesByWatchOrder
import com.edde746.plezy.strings.T
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Duration.Companion.seconds
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/**
 * Libraries, browsing, item detail, children and descendants, related items and deletion. Responses that back offline
 * use are written to [JellyfinCore.store] under the endpoint keys the cache layer reads.
 *
 * [specialsOrdering] is the user's episode-order preference, read per call.
 */
internal class JellyfinBrowse(
    private val core: JellyfinCore,
    private val specialsOrdering: () -> SpecialsOrdering,
) {
    private val libraryFlight = SingleFlight<Unit, List<MediaLibrary>>()
    private val itemFlight = SingleFlight<String, MediaItem?>()
    /** Item rows are written one at a time, in the order their items landed ([fetchItem]). */
    private val itemWrites = Mutex()

    /**
     * Views as of the last [fetchLibraries], for search and Continue Watching, which run per keystroke or per shelf and
     * would otherwise put a `/Views` round trip in front of every pass.
     */
    var loadedLibraryViews: List<MediaLibrary>? = null
        private set

    // Libraries and browse.

    /**
     * Concurrent callers share one `/Views` request (cold start asks twice at once); once it settles the next
     * call fetches again, so a library added server-side still appears.
     */
    suspend fun fetchLibraries(): List<MediaLibrary> = libraryFlight.run(Unit) {
        fetchLibraryViews().also { loadedLibraryViews = it }
    }

    /**
     * Collection and playlist roots are dropped: they surface as per-library tabs, as on Plex. Live TV views are dropped
     * too: Live TV holds no titles to browse (Emby ignores a `ParentId` naming its view and answers with every library's
     * items), and the app reaches it through its own Live TV entry.
     */
    suspend fun fetchLibraryViews(): List<MediaLibrary> {
        val response = core.get("/Users/${seg(core.userId)}/Views").throwIfError()
        return core.itemsArray(response.data)
            .filter { view -> view.str("CollectionType")?.lowercase().let { it != "boxsets" && it != "playlists" && it != "livetv" } }
            .mapNotNull { JellyfinMappers.library(it, core.serverId, core.connection.serverName, core.dialect) }
    }

    /** [libraryKind] is the default type only when the query names none (explicit season/episode groupings win). */
    suspend fun fetchLibraryPagedContent(libraryId: String, query: LibraryQuery, libraryKind: MediaKind? = null): LibraryPage<MediaItem> {
        val effective = if (query.kind == null && query.includeKinds.isEmpty() && libraryKind != null && libraryKind != MediaKind.UNKNOWN) {
            query.copy(kind = libraryKind)
        } else {
            query
        }
        val fields = when (effective.kind) {
            MediaKind.ALBUM -> core.musicAlbumRowFields
            MediaKind.TRACK -> core.musicTrackRowFields
            else -> core.browseFields
        }
        val params = JellyfinLibraryQueryTranslator(core.userId, libraryId, fields).toQueryParameters(effective)
        // UserData on album folders makes the server compute recursive play state per album; IsUnplayed still filters.
        if (effective.kind == MediaKind.ALBUM) params["EnableUserData"] = "false"
        // `/Artists/AlbumArtists` lists tag-derived artists, which the folder-based `/Items` MusicArtist query misses.
        val isArtistQuery = effective.kind == MediaKind.ARTIST
        if (isArtistQuery) {
            params.remove("IncludeItemTypes")
            params.remove("Recursive")
        }
        val response = core.get(if (isArtistQuery) "/Artists/AlbumArtists" else "/Items", params.toList()).throwIfError()
        val items = core.itemsArray(response.data)
        val rawTotal = response.obj?.int("TotalRecordCount")
        // AlbumArtists reports 0 with a name prefix set (10.11) while still returning rows: an unknown total.
        val totalUnreliable = isArtistQuery && rawTotal == 0 && items.isNotEmpty()
        val total = if (rawTotal != null && !totalUnreliable) rawTotal else fallbackPageTotal(effective.offset, items.size, effective.limit)
        return LibraryPage(core.mapItems(items), total, effective.offset)
    }

    /**
     * Synthetic unwatched/favourite booleans plus the genre, year, rating and tag values. Keys carry the `jellyfin:`
     * prefix saved preferences use. Only the played state can be negated on `/Items`, so the value facets and the
     * favourite offer equality only.
     */
    suspend fun fetchLibraryFiltersWithValues(libraryId: String, libraryKind: MediaKind? = null): LibraryFilterResult {
        val booleanOperators = listOf(LibraryFilterOperator.IS, LibraryFilterOperator.IS_NOT)
        val valueOperators = listOf(LibraryFilterOperator.IS)
        val filters = mutableListOf(
            MediaFilter(
                filter = MediaFilterField.UNWATCHED,
                title = if (libraryKind?.isMusic == true) T.libraries.filterCategories.unplayed else T.libraries.filterCategories.unwatched,
                filterType = MediaFilterType.BOOLEAN,
                key = "jellyfin:unwatched",
                operators = booleanOperators,
            ),
            MediaFilter(
                filter = MediaFilterField.FAVORITE,
                title = T.libraries.filterCategories.favorites,
                filterType = MediaFilterType.BOOLEAN,
                key = "jellyfin:favorite",
                operators = valueOperators,
            ),
        )
        val raw = fetchFilterValues(libraryId) ?: return LibraryFilterResult(filters, emptyMap())
        val titles = mapOf(
            MediaFilterField.GENRE to T.libraries.filterCategories.genre,
            MediaFilterField.YEAR to T.libraries.filterCategories.year,
            MediaFilterField.CONTENT_RATING to T.libraries.filterCategories.contentRating,
            MediaFilterField.TAG to T.libraries.filterCategories.tag,
        )
        val values = linkedMapOf<String, List<MediaFilterValue>>()
        for ((key, title) in titles) {
            val entries = raw[key].orEmpty()
            if (entries.isEmpty()) continue
            filters += MediaFilter(
                filter = key,
                title = title,
                filterType = if (key == MediaFilterField.YEAR) MediaFilterType.INTEGER else MediaFilterType.TAG,
                key = "jellyfin:$key",
                operators = valueOperators,
            )
            val sorted = if (key == MediaFilterField.YEAR) entries.sortedByDescending { it.toIntOrNull() ?: 0 } else entries.sorted()
            values[key] = sorted.map { MediaFilterValue(it, it) }
        }
        return LibraryFilterResult(filters, values)
    }

    /**
     * Values by filter field. Jellyfin answers the aggregate `/Items/Filters` (a transient failure → null, filters
     * without values). Emby 404s there, so it reads its four facet routes, each emptied on a transient failure. Any
     * other failure throws: a real outage must not look like a library without genres.
     */
    private suspend fun fetchFilterValues(libraryId: String): Map<String, List<String>>? {
        if (!core.dialect.supportsAggregateItemFilters) {
            return coroutineScope {
                val facets = listOf("/Genres", "/OfficialRatings", "/Tags", "/Years").map { endpoint ->
                    async {
                        try {
                            fetchFilterFacet(endpoint, libraryId)
                        } catch (e: MediaServerHttpException) {
                            if (!e.isTransient) throw e
                            Log.w(TAG, e) { "$endpoint filter facet unreachable (facet empty)" }
                            emptyList()
                        }
                    }
                }.awaitAll()
                mapOf(
                    MediaFilterField.GENRE to facets[0],
                    MediaFilterField.CONTENT_RATING to facets[1],
                    MediaFilterField.TAG to facets[2],
                    MediaFilterField.YEAR to facets[3],
                )
            }
        }
        val data = try {
            core.get("/Items/Filters", listOf("userId" to core.userId, "ParentId" to libraryId), timeoutMillis = FILTERS_TIMEOUT.inWholeMilliseconds)
                .throwIfError().obj ?: return null
        } catch (e: MediaServerHttpException) {
            if (!e.isTransient) throw e
            Log.w(TAG, e) { "/Items/Filters unreachable (filters without values)" }
            return null
        }
        return mapOf(
            MediaFilterField.GENRE to nonEmptyStrings(data["Genres"]),
            MediaFilterField.CONTENT_RATING to nonEmptyStrings(data["OfficialRatings"]),
            MediaFilterField.TAG to nonEmptyStrings(data["Tags"]),
            MediaFilterField.YEAR to (data["Years"] as? JsonArray).orEmpty().mapNotNull { year ->
                val p = year as? JsonPrimitive ?: return@mapNotNull null
                (if (p.isString) p.content else p.content.toDoubleOrNull()?.toInt()?.toString())?.ifEmpty { null }
            },
        )
    }

    /**
     * The names of one facet route (`/Genres`, `/OfficialRatings`, `/Tags`, `/Years`). `Recursive=true` is required:
     * without it Emby only counts the view's direct children and every facet is empty. A null [libraryId] is
     * server-wide (item DTOs carry no library id).
     */
    suspend fun fetchFilterFacet(endpoint: String, libraryId: String?): List<String> {
        val response = core.get(endpoint, listOf("UserId" to core.userId, "ParentId" to libraryId, "Recursive" to "true")).throwIfError()
        return (response.obj?.get("Items") as? JsonArray).orEmpty()
            .mapNotNull { (it as? JsonObject)?.str("Name")?.ifEmpty { null } }
    }

    /**
     * No server listing exists, so a fixed set; [JellyfinLibraryQueryTranslator] maps the keys to `SortBy`. Without a
     * `SortBy`, Jellyfin and Emby list movies, shows, music and home videos by name ascending, so title is marked as
     * that order there; other library types' unsorted order isn't known. A show library adds its shows' air time and
     * their last episode's date added; Start Date (a program's) never applies to a library's items.
     */
    @Suppress("UNUSED_PARAMETER")
    suspend fun fetchSortOptions(libraryId: String, libraryType: String? = null): List<MediaSort> {
        val labels = T.libraries.sortLabels
        val titleByDefault = libraryType?.lowercase() in TITLE_ORDERED_TYPES
        val sorts = mutableListOf(
            MediaSort(key = "title", title = labels.title, descKey = "title:desc", defaultDirection = "asc", unsortedDirection = "asc".takeIf { titleByDefault }),
            sort("rating", labels.communityRating, "desc"),
            sort("criticRating", labels.criticRating, "desc"),
            sort("addedAt", labels.dateAdded, "desc"),
            sort("lastViewedAt", labels.datePlayed, "desc"),
            sort("viewCount", labels.playCount, "desc"),
            sort("productionYear", labels.productionYear, "desc"),
            sort("runtime", labels.runtime, "desc"),
            sort("officialRating", labels.officialRating, "asc"),
            sort("originallyAvailableAt", labels.premiereDate, "desc"),
            sort("studio", labels.studio, "asc"),
            MediaSort(key = "random", title = labels.random, defaultDirection = "asc"),
        )
        if (libraryType?.lowercase() == "show") {
            sorts.add(4, sort("episode.addedAt", labels.lastEpisodeDateAdded, "desc"))
            sorts.add(sorts.indexOfFirst { it.key == "studio" }, sort("airTime", labels.airTime, "asc"))
        }
        return sorts
    }

    private fun sort(key: String, title: String, direction: String) = MediaSort(key = key, title = title, descKey = "$key:desc", defaultDirection = direction)

    /**
     * Scoped to the type the library's Browse lists: unscoped, a show library also reports genres no show carries
     * (Jellyfin 10.11), whose tiles would filter Browse to nothing. A genre selects by name.
     */
    suspend fun fetchLibraryGenres(libraryId: String, libraryKind: MediaKind): List<LibraryGenre> {
        val includeTypes = when (libraryKind) {
            MediaKind.MOVIE -> "Movie"
            MediaKind.SHOW -> "Series"
            else -> null
        }
        val response = core.get(
            "/Genres",
            listOf(
                "UserId" to core.userId,
                "ParentId" to libraryId,
                "Recursive" to "true",
                "IncludeItemTypes" to includeTypes,
                "SortBy" to "SortName",
                "EnableImageTypes" to "Primary",
                "ImageTypeLimit" to "1",
                "EnableTotalRecordCount" to "false",
            ),
        ).throwIfError()
        return core.itemsArray(response.data).mapNotNull { row ->
            val name = row.str("Name")?.ifEmpty { null } ?: return@mapNotNull null
            val id = row.str("Id")?.ifEmpty { null }
            val primaryTag = row.obj("ImageTags")?.str("Primary")?.ifEmpty { null }
            LibraryGenre(
                title = name,
                filterValue = name,
                artPath = if (id != null && primaryTag != null) "/Items/${seg(id)}/Images/Primary?tag=${seg(primaryTag)}" else null,
            )
        }
    }

    /** A full metadata refresh that keeps user edits, like Plex's `refresh?force=1`. */
    suspend fun refreshLibraryMetadata(libraryId: String) {
        core.post(
            "/Items/${seg(libraryId)}/Refresh",
            listOf(
                "metadataRefreshMode" to "FullRefresh",
                "imageRefreshMode" to "Default",
                "replaceAllMetadata" to "false",
                "replaceAllImages" to "false",
            ),
        ).throwIfError()
    }

    /** Jellyfin Web's "scan for new and updated files": `Default` modes fill only missing metadata. */
    suspend fun scanLibrary(libraryId: String) {
        core.post(
            "/Items/${seg(libraryId)}/Refresh",
            listOf(
                "Recursive" to "true",
                "metadataRefreshMode" to "Default",
                "imageRefreshMode" to "Default",
                "replaceAllMetadata" to "false",
                "replaceAllImages" to "false",
            ),
        ).throwIfError()
    }

    /** Direct children (`Recursive=false`), as Jellyfin Web's folder view; Browse recurses instead. */
    suspend fun fetchLibraryFolders(libraryId: String, onPage: ((List<MediaItem>) -> Unit)? = null): List<MediaItem> =
        fetchDirectFolderChildren(libraryId, onPage)

    /** Show and season rows expand through the metadata hierarchy ([fetchChildren]); other folders by direct children. */
    @Suppress("UNUSED_PARAMETER")
    suspend fun fetchFolderChildren(
        folder: MediaItem,
        libraryId: String? = null,
        libraryTitle: String? = null,
        onPage: ((List<MediaItem>) -> Unit)? = null,
    ): List<MediaItem> =
        if (folder.kind == MediaKind.SHOW || folder.kind == MediaKind.SEASON) {
            fetchChildrenInternal(folder.id, onPage)
        } else {
            fetchDirectFolderChildren(folder.id, onPage)
        }

    /**
     * Two parallel queries split by type: UserData on a folder DTO makes the server compute a recursive unplayed count
     * per folder (100–200 ms each on 10.11), and plain folder rows show no watch state. Merged folders first, then by
     * name. [onPage] fires only once the folder query has landed, so partial lists never reorder later.
     */
    @OptIn(ExperimentalCoroutinesApi::class)
    private suspend fun fetchDirectFolderChildren(parentId: String, onPage: ((List<MediaItem>) -> Unit)?): List<MediaItem> {
        val cacheKey = "/Items?ParentId=$parentId&Recursive=false&userId=${core.userId}"
        if (core.offlineMode) return core.store?.get(core.cacheServerId, cacheKey)?.let { core.mapItems(core.itemsArray(it)) }.orEmpty()

        val allRaw = coroutineScope {
            val folders = async {
                pageFolderQuery(parentId, listOf("IncludeItemTypes" to "Folder,CollectionFolder", "EnableUserData" to "false"), core.folderRowFields, null)
            }
            val media = async {
                pageFolderQuery(parentId, listOf("ExcludeItemTypes" to "Folder,CollectionFolder"), core.folderBrowseFields, onPage?.let { emit ->
                    { rowsSoFar: List<JsonObject> ->
                        if (folders.isCompleted) emit(core.mapItems(folders.getCompleted() + rowsSoFar))
                    }
                })
            }
            folders.await() + media.await()
        }.sortedWith(compareBy<JsonObject> { if (isFolderDto(it)) 0 else 1 }.thenBy { (it.str("SortName") ?: it.str("Name") ?: "").lowercase() })

        writeCache(cacheKey, allRaw)
        return core.mapItems(allRaw)
    }

    private suspend fun pageFolderQuery(
        parentId: String,
        typeParams: List<Pair<String, String>>,
        fields: String,
        onRawPage: ((List<JsonObject>) -> Unit)?,
    ): List<JsonObject> = drainPages(CHILDREN_PAGE_SIZE, stopOnShortPage = true, onPage = onRawPage) { start, size ->
        val response = core.get(
            "/Items",
            listOf(
                "userId" to core.userId,
                "ParentId" to parentId,
                "Recursive" to "false",
                "StartIndex" to "$start",
                "Limit" to "$size",
                "EnableTotalRecordCount" to "true",
                "SortBy" to "SortName",
                "SortOrder" to "Ascending",
                "Fields" to fields,
            ) + typeParams + JellyfinCore.IMAGE_PARAMS,
        ).throwIfError()
        core.pagedItems(response.data, start, size) { it }
    }

    private fun isFolderDto(item: JsonObject): Boolean {
        val type = item.str("Type")?.lowercase()
        return type == "folder" || type == "collectionfolder" || (type == null && item.bool("IsFolder") == true)
    }

    // Items.

    /**
     * Concurrent calls for one id share a request (a detail screen fires several at once, and each full DTO is
     * expensive to build); a settled call is never reused.
     *
     * 200 object → item, its row cached; any other 200 body → null; 404 → null; other statuses and cancellation
     * throw without touching the cache (a cached row would hide "signed out"/"server down"). A transport or mapping
     * failure answers the cached row when there is one. Offline: the cached row only.
     */
    suspend fun fetchItem(id: String): MediaItem? = coroutineScope { fetchItem(id, cacheWrites = this) }

    /**
     * [fetchItem], its row written in [cacheWrites] while the caller goes on with the item. The rows are written in the
     * order their items landed, so an earlier answer never overwrites a later one.
     */
    private suspend fun fetchItem(id: String, cacheWrites: CoroutineScope): MediaItem? = itemFlight.run(id) { fetchItemOnce(id, cacheWrites) }

    /** [fetchItem], but a cached detail row younger than [PLAYBACK_METADATA_CACHE_FRESHNESS] skips the round trip. */
    suspend fun fetchItemFreshCacheFirst(id: String): MediaItem? {
        try {
            core.store?.getIfFresh(core.cacheServerId, itemEndpoint(id), PLAYBACK_METADATA_CACHE_FRESHNESS)?.let(core::mapItem)?.let { return it }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "fetchItemFreshCacheFirst cache read failed" }
        }
        return fetchItem(id)
    }

    private suspend fun fetchItemOnce(id: String, cacheWrites: CoroutineScope): MediaItem? {
        val endpoint = itemEndpoint(id)
        if (core.offlineMode) return core.store?.get(core.cacheServerId, endpoint)?.let(core::mapItem)
        try {
            val data = core.get(endpoint, listOf("Fields" to JellyfinCore.DETAIL_FIELDS)).throwIfError().obj ?: return null
            // Undispatched, it queues for the lock now: the writes keep the order the items landed in.
            cacheWrites.launch(start = CoroutineStart.UNDISPATCHED) { itemWrites.withLock { writeCache(endpoint, data) } }
            return core.mapItem(data)
        } catch (e: MediaServerHttpException) {
            if (e.statusCode == 404) return null
            if (e.statusCode != null || e.isCancellation) throw e
            Log.w(TAG, e) { "fetchItem network call failed" }
            return cachedItem(endpoint) ?: throw e
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "fetchItem failed" }
            return cachedItem(endpoint) ?: throw e
        }
    }

    /** The fallback row for [fetchItemOnce]; null on a miss or a cache failure, so the caller rethrows its own. */
    private suspend fun cachedItem(endpoint: String): MediaItem? = try {
        core.store?.get(core.cacheServerId, endpoint)?.let(core::mapItem)
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "fetchItem cache fallback failed" }
        null
    }

    /**
     * The item, handed to [onItemReady] as soon as it lands (its cache row written meanwhile, before this returns); its
     * library from the ancestors (online), asked for alongside the item; then for a show its on-deck episode: the one in
     * progress played last, else `/Shows/NextUp` by series (else S1E1). That is Continue Watching's order, where an
     * in-progress episode beats its series' Next Up entry: Next Up alone skips an episode left in progress once a later
     * one is played.
     */
    suspend fun fetchItemWithOnDeck(id: String, onItemReady: ((MediaItem) -> Unit)? = null): ItemWithOnDeck = coroutineScope {
        val library = if (core.offlineMode) null else async { libraryOf(id) }
        val item = fetchItem(id, cacheWrites = this)
        if (item == null) {
            library?.cancel()
            return@coroutineScope ItemWithOnDeck(null, null)
        }
        onItemReady?.invoke(item)
        val stamped = item.inLibrary(library?.await())
        if (item.kind != MediaKind.SHOW) return@coroutineScope ItemWithOnDeck(stamped, null)
        // Emby's resume route also returns next episodes at position zero: only a position makes an episode in progress.
        val resuming = core.mapItems(
            safeItemsArray(
                core.paths.resumeItems,
                listOf(
                    "userId" to core.userId,
                    "ParentId" to id,
                    "Recursive" to "true",
                    "IncludeItemTypes" to "Episode",
                    "Fields" to core.episodeRowFields,
                ) + JellyfinCore.IMAGE_PARAMS,
            ),
        ).firstOrNull { (it.viewOffsetMs ?: 0) > 0 }
        if (resuming != null) return@coroutineScope ItemWithOnDeck(stamped, resuming)
        val nextUp = safeItemsArray(
            "/Shows/NextUp",
            listOf(
                "seriesId" to id,
                "userId" to core.userId,
                "Limit" to "1",
                "Fields" to core.episodeRowFields,
                "EnableRewatching" to if (core.sendNextUpRewatching()) "true" else null,
            ) + JellyfinCore.IMAGE_PARAMS,
        )
        ItemWithOnDeck(stamped, nextUp.firstOrNull()?.let(core::mapItem))
    }

    /**
     * The library from `/Items/{id}/Ancestors`, the only place either dialect names it: the first `CollectionFolder`.
     * Best-effort: a failure or a libraryless item (a playlist-only row) returns [item] unchanged.
     */
    suspend fun stampLibrary(item: MediaItem): MediaItem = item.inLibrary(libraryOf(item.id))

    /** [stampLibrary]'s library row for [id]; null on a failure or when no ancestor is a `CollectionFolder`. */
    private suspend fun libraryOf(id: String): JsonObject? = try {
        val response = core.get("/Items/${seg(id)}/Ancestors", listOf("userId" to core.userId)).throwIfError()
        (response.data as? JsonArray)?.filterIsInstance<JsonObject>()?.firstOrNull { it.str("Type") == "CollectionFolder" }
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.d(TAG, e) { "ancestors lookup failed" }
        null
    }

    private fun MediaItem.inLibrary(library: JsonObject?): MediaItem =
        if (library == null) this else copy(libraryId = library.str("Id"), libraryTitle = library.str("Name"))

    // Children and episodes.

    suspend fun fetchChildren(parentId: String): List<MediaItem> = fetchChildrenInternal(parentId, null)

    /**
     * A series' seasons from `/Shows/{id}/Seasons`; anything else (an error, or no seasons) falls through to the paged
     * direct-children query. Cache keys name the user: the rows carry per-user watch state. [onPage] sees the
     * accumulated items after each intermediate page of the direct-children query only.
     */
    private suspend fun fetchChildrenInternal(parentId: String, onPage: ((List<MediaItem>) -> Unit)?): List<MediaItem> {
        val seasonsKey = seasonsCacheKey(parentId)
        val childrenKey = childrenCacheKey(parentId)
        val store = core.store
        if (core.offlineMode) {
            store?.get(core.cacheServerId, seasonsKey)?.let(core::itemsArray)?.takeIf { it.isNotEmpty() }?.let { return core.mapItems(it) }
            return store?.get(core.cacheServerId, childrenKey)?.let { core.mapItems(core.itemsArray(it)) }.orEmpty()
        }

        try {
            val seasons = core.get("/Shows/${seg(parentId)}/Seasons", listOf("userId" to core.userId, "Fields" to core.browseFields) + JellyfinCore.IMAGE_PARAMS)
            val data = seasons.obj
            if (seasons.status == 200 && data != null) {
                val items = core.itemsArray(data)
                if (items.isNotEmpty()) {
                    store?.put(core.cacheServerId, seasonsKey, data)
                    return core.mapItems(items)
                }
            }
        } catch (_: MediaServerHttpException) {
            // Not a series: fall through to the direct-children query.
        }

        val allRaw = drainPages(CHILDREN_PAGE_SIZE, stopOnShortPage = true, onPage = onPage?.let { emit -> { raw: List<JsonObject> -> emit(core.mapItems(raw)) } }) { start, size ->
            val response = core.get(
                "/Items",
                listOf(
                    "userId" to core.userId,
                    "ParentId" to parentId,
                    "Fields" to core.episodeRowFields,
                    "StartIndex" to "$start",
                    "Limit" to "$size",
                ) + EPISODE_ORDER + JellyfinCore.IMAGE_PARAMS,
            ).throwIfError()
            core.pagedItems(response.data, start, size) { it }
        }
        writeCache(childrenKey, allRaw)
        return core.mapItems(allRaw)
    }

    /** Seasons first, then the direct children in episode order. Offline pages the cached lists in memory. */
    suspend fun fetchChildrenPage(parentId: String, start: Int? = null, size: Int? = null): LibraryPage<MediaItem> {
        val offset = start ?: 0
        val pageSize = size ?: PAGED_LIST_PAGE_SIZE
        if (core.offlineMode) {
            val store = core.store
            val seasons = store?.get(core.cacheServerId, seasonsCacheKey(parentId))?.let { core.mapItems(core.itemsArray(it)) }.orEmpty()
            val all = seasons.ifEmpty { store?.get(core.cacheServerId, childrenCacheKey(parentId))?.let { core.mapItems(core.itemsArray(it)) }.orEmpty() }
            val from = offset.coerceIn(0, all.size)
            return LibraryPage(all.subList(from, (from + pageSize).coerceIn(0, all.size)), all.size, offset)
        }

        try {
            val seasons = core.get(
                "/Shows/${seg(parentId)}/Seasons",
                listOf(
                    "userId" to core.userId,
                    "StartIndex" to offset.toString(),
                    "Limit" to pageSize.toString(),
                    "EnableTotalRecordCount" to "true",
                    "Fields" to core.browseFields,
                ) + JellyfinCore.IMAGE_PARAMS,
            )
            if (seasons.status == 200) {
                val items = core.itemsArray(seasons.data)
                val rawTotal = seasons.obj?.int("TotalRecordCount")
                if (items.isNotEmpty() || (rawTotal != null && rawTotal > 0)) return core.pagedItems(seasons.data, offset, pageSize, map = core::mapItems)
            }
        } catch (_: MediaServerHttpException) {
            // Not a series: fall through to the direct-children query.
        }

        val response = core.get(
            "/Items",
            listOf(
                "userId" to core.userId,
                "ParentId" to parentId,
                "StartIndex" to offset.toString(),
                "Limit" to pageSize.toString(),
                "EnableTotalRecordCount" to "true",
                "Fields" to core.episodeRowFields,
            ) + EPISODE_ORDER + JellyfinCore.IMAGE_PARAMS,
        ).throwIfError()
        return core.pagedItems(response.data, offset, pageSize, map = core::mapItems)
    }

    /** One season's real episodes (no missing or unaired placeholders). Offline: [fetchChildrenPage]. */
    suspend fun fetchSeasonEpisodesPage(seriesId: String, seasonId: String, start: Int? = null, size: Int? = null): LibraryPage<MediaItem> {
        if (core.offlineMode) return fetchChildrenPage(seasonId, start, size)
        val offset = start ?: 0
        val pageSize = size ?: PAGED_LIST_PAGE_SIZE
        val response = core.get(
            "/Shows/${seg(seriesId)}/Episodes",
            listOf(
                "userId" to core.userId,
                "SeasonId" to seasonId,
                "StartIndex" to offset.toString(),
                "Limit" to pageSize.toString(),
                "EnableTotalRecordCount" to "true",
                "IsMissing" to "false",
                "IsVirtualUnaired" to "false",
                "Fields" to core.episodeRowFields,
            ) + JellyfinCore.IMAGE_PARAMS,
        ).throwIfError()
        return core.pagedItems(response.data, offset, pageSize, map = core::mapItems)
    }

    /**
     * Every playable descendant (movies, episodes, tracks), so play-all of a collection plays a series' episodes and an
     * album or artist its tracks. Music links artists by tag, not folder, so a tag-only artist has no descendants:
     * retried once by album-artist credit, tracks only.
     */
    suspend fun fetchPlayableDescendants(parentId: String): List<MediaItem> =
        allPlayableDescendants(parentId, PLAYABLE_DESCENDANT_TYPES).ifEmpty { allPlayableDescendants(parentId, "Audio", byAlbumArtist = true) }

    /** A folder row's playable videos, generic `Video`/`MusicVideo` included; never audio. */
    suspend fun fetchPlayableFolderDescendants(parentId: String): List<MediaItem> = allPlayableDescendants(parentId, PLAYABLE_FOLDER_DESCENDANT_TYPES)

    /** Up to [limit] videos in server-random order, in one request: a random order is not stable across pages. */
    suspend fun fetchRandomLibraryVideos(libraryId: String, limit: Int): List<MediaItem> =
        playableDescendantsPage(libraryId, 0, limit, PLAYABLE_FOLDER_DESCENDANT_TYPES, randomOrder = true).items

    suspend fun fetchPlayableDescendantsPage(parentId: String, start: Int? = null, size: Int? = null): LibraryPage<MediaItem> =
        playableDescendantsPage(parentId, start, size, PLAYABLE_DESCENDANT_TYPES)

    private suspend fun allPlayableDescendants(parentId: String, includeItemTypes: String, byAlbumArtist: Boolean = false): List<MediaItem> =
        drainPages(PAGED_LIST_PAGE_SIZE) { start, size -> playableDescendantsPage(parentId, start, size, includeItemTypes, byAlbumArtist) }

    private suspend fun playableDescendantsPage(
        parentId: String,
        start: Int?,
        size: Int?,
        includeItemTypes: String,
        byAlbumArtist: Boolean = false,
        randomOrder: Boolean = false,
    ): LibraryPage<MediaItem> {
        val offset = start ?: 0
        val pageSize = size ?: PAGED_LIST_PAGE_SIZE
        val response = core.get(
            "/Items",
            listOf(
                "userId" to core.userId,
                (if (byAlbumArtist) "AlbumArtistIds" else "ParentId") to parentId,
                "Recursive" to "true",
                "IncludeItemTypes" to includeItemTypes,
                "SortBy" to if (randomOrder) "Random" else null,
                "StartIndex" to offset.toString(),
                "Limit" to pageSize.toString(),
                "Fields" to core.episodeRowFields,
                // Placeholder episodes have no file; recursive /Items returns them unless told not to.
                "ExcludeLocationTypes" to "Virtual",
            ) + JellyfinCore.IMAGE_PARAMS,
        ).throwIfError()
        return core.pagedItems(response.data, offset, pageSize, map = core::mapItems)
    }

    /**
     * A series' episodes, paged so long shows still fit. [SpecialsOrdering.RESPECT_SERVER] keeps the server's own order,
     * asked for as the server's web client asks (no `SortBy`, which Emby would honour over its own order): seasons in
     * order, Specials first, a Special the server places in a season (Jellyfin: `AirsBefore*`/`AirsAfter*` with
     * "Display specials within seasons") inside it. The other modes re-sort client-side so online next/previous matches
     * downloads and offline playback.
     */
    suspend fun fetchClientSideEpisodeQueue(seriesId: String): List<MediaItem>? {
        val all = drainPages(EPISODE_QUEUE_PAGE_SIZE, stopOnShortPage = true) { start, size ->
            val response = core.get(
                "/Shows/${seg(seriesId)}/Episodes",
                listOf(
                    "userId" to core.userId,
                    "Fields" to core.queueFields,
                    "StartIndex" to "$start",
                    "Limit" to "$size",
                    "IsMissing" to "false",
                    "IsVirtualUnaired" to "false",
                ) + JellyfinCore.IMAGE_PARAMS,
            ).throwIfError()
            core.pagedItems(response.data, start, size, map = core::mapItems)
        }
        val ordering = specialsOrdering()
        return if (ordering == SpecialsOrdering.RESPECT_SERVER) all else sortEpisodesByWatchOrder(all, ordering)
    }

    /**
     * Whether the series queue built for an episode ([fetchClientSideEpisodeQueue]) starts at it, nothing before it. In
     * the server's order it starts where the server's web client starts its queue: Jellyfin's queues the series from
     * the episode played on (`startItemId`), for a show's Play from its Next Up episode; Emby's queues the whole series
     * around an episode played on its own, and for a show's Play ([showPlay]) the show's Next Up list. The other modes
     * keep the whole series around it.
     */
    fun seriesQueueStartsAtEpisode(showPlay: Boolean): Boolean =
        specialsOrdering() == SpecialsOrdering.RESPECT_SERVER && (showPlay || core.dialect == MediaBrowserDialect.JELLYFIN)

    // Related items and people.

    suspend fun fetchRelatedHubs(id: String, count: Int = 10): List<MediaHub> {
        val response = core.get(
            "/Items/${seg(id)}/Similar",
            listOf("userId" to core.userId, "Limit" to count.toString(), "Fields" to core.browseFields) + JellyfinCore.IMAGE_PARAMS,
        ).throwIfError()
        val hub = JellyfinMappers.syntheticHub(
            identifier = "item.$id.similar",
            title = T.discover.moreLikeThis,
            type = "mixed",
            items = core.mapItems(core.itemsArray(response.data)),
            serverId = core.serverId,
            serverName = core.connection.serverName,
        )
        return listOf(hub).filter { it.items.isNotEmpty() }
    }

    /** Local trailers and special features, each failure empty; playable videos only, once each. Offline: none. */
    suspend fun fetchExtras(id: String): List<MediaItem> {
        if (core.offlineMode) return emptyList()
        val query = listOf("userId" to core.userId) + JellyfinCore.IMAGE_PARAMS
        val raw = coroutineScope {
            listOf(core.paths.localTrailers(id), core.paths.specialFeatures(id)).map { async { safeItemsArray(it, query) } }.awaitAll().flatten()
        }
        val seen = mutableSetOf<String>()
        return core.mapItems(raw).filter { it.kind.isVideo && seen.add(it.id) }
    }

    suspend fun fetchPersonMediaPage(personId: String, start: Int? = null, size: Int? = null): LibraryPage<MediaItem> {
        val offset = start ?: 0
        val pageSize = size ?: PAGED_LIST_PAGE_SIZE
        val response = core.get(
            "/Items",
            listOf(
                "userId" to core.userId,
                "PersonIds" to personId,
                "IncludeItemTypes" to PERSON_MEDIA_ITEM_TYPES,
                "Recursive" to "true",
                "StartIndex" to offset.toString(),
                "Limit" to pageSize.toString(),
                "Fields" to core.browseFields,
                "SortBy" to "PremiereDate,ProductionYear,SortName",
                "SortOrder" to "Descending,Descending,Ascending",
                "CollapseBoxSetItems" to "false",
            ) + JellyfinCore.IMAGE_PARAMS,
        ).throwIfError()
        return core.pagedItems(response.data, offset, pageSize, map = core::mapItems)
    }

    /** Not cached: [fetchItem] is the only writer of this endpoint's row, and a person has none of its fields. */
    suspend fun fetchPersonDetails(personId: String): MediaPersonDetails {
        if (core.offlineMode) return MediaPersonDetails.EMPTY
        val response = core.get("/Users/${seg(core.userId)}/Items/${seg(personId)}", listOf("Fields" to "Overview,ProductionLocations")).throwIfError()
        val data = response.obj ?: return MediaPersonDetails.EMPTY
        return MediaPersonDetails(
            biography = data.str("Overview")?.trim()?.ifEmpty { null },
            birthDate = MediaPersonDetails.parseDate(data.str("PremiereDate")),
            deathDate = MediaPersonDetails.parseDate(data.str("EndDate")),
            birthPlace = data.strings("ProductionLocations")?.firstOrNull()?.trim()?.ifEmpty { null },
        )
    }

    // Deletion.

    /**
     * `/Items?ids=` rather than the single-item route, which ignores `Fields` and ships the whole DTO. An item the user
     * cannot see comes back as no row: not deletable. A context menu waits on this, so the whole probe is capped at
     * [MediaServerTimeouts.DELETE_PERMISSION_PROBE] (the per-request timeout alone would allow connect and body
     * each that long) and never walks other endpoints; expiry throws as an HTTP timeout so callers fail closed.
     */
    suspend fun fetchDeletePermission(item: MediaItem): Boolean? {
        val timeout = MediaServerTimeouts.DELETE_PERMISSION_PROBE
        val response = try {
            withTimeout(timeout) {
                core.get(
                    "/Items",
                    listOf(
                        "ids" to item.id,
                        "userId" to core.userId,
                        "Fields" to "CanDelete",
                        "EnableImages" to "false",
                        "EnableUserData" to "false",
                        "EnableTotalRecordCount" to "false",
                    ),
                    timeoutMillis = timeout.inWholeMilliseconds,
                    allowEndpointFailover = false,
                )
            }
        } catch (e: TimeoutCancellationException) {
            throw MediaServerHttpException.from(e)
        }
        response.throwIfError()
        val row = core.itemsArray(response.data).firstOrNull() ?: return false
        return row.bool("CanDelete")
    }

    suspend fun deleteMediaItem(item: MediaItem): Boolean {
        core.delete("/Items/${seg(item.id)}").throwIfError()
        return true
    }

    // Helpers.

    private fun itemEndpoint(id: String) = "/Users/${seg(core.userId)}/Items/${seg(id)}"

    private fun seasonsCacheKey(parentId: String) = "/Shows/$parentId/Seasons?userId=${core.userId}"

    private fun childrenCacheKey(parentId: String) = "/Items?ParentId=$parentId&userId=${core.userId}"

    /** A listing is cached as `{Items, TotalRecordCount}`, the shape the offline readers parse. */
    private suspend fun writeCache(endpoint: String, rows: List<JsonObject>) = writeCache(
        endpoint,
        buildJsonObject {
            put("Items", JsonArray(rows))
            put("TotalRecordCount", rows.size)
        },
    )

    /** A failed cache write costs offline use only, never the answer. */
    private suspend fun writeCache(endpoint: String, data: JsonObject) {
        try {
            core.store?.put(core.cacheServerId, endpoint, data)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "cache write failed" }
        }
    }

    /** Rows of an optional leg: any failure but a cancellation is logged and empty, so one endpoint can't sink a screen. */
    private suspend fun safeItemsArray(path: String, query: List<Pair<String, String?>>): List<JsonObject> = try {
        core.itemsArray(core.get(path, query).throwIfError().data)
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        if (e is MediaServerHttpException && e.isCancellation) throw e
        Log.w(TAG, e) { "$path failed (treating as empty)" }
        emptyList()
    }

    private fun nonEmptyStrings(raw: kotlinx.serialization.json.JsonElement?): List<String> =
        (raw as? JsonArray).orEmpty().mapNotNull { (it as? JsonPrimitive)?.takeIf { p -> p.isString }?.content?.ifEmpty { null } }

    private companion object {
        const val TAG = "JellyfinBrowse"
        const val CHILDREN_PAGE_SIZE = 500
        const val PAGED_LIST_PAGE_SIZE = 200

        /** The library types (as sorts are asked for) whose unsorted `/Items` order is by name ascending. */
        val TITLE_ORDERED_TYPES = setOf("movie", "show", "artist", "album", "track", "clip")
        const val EPISODE_QUEUE_PAGE_SIZE = 200
        const val PLAYABLE_DESCENDANT_TYPES = "Movie,Episode,Audio"
        const val PLAYABLE_FOLDER_DESCENDANT_TYPES = "Movie,Episode,Video,MusicVideo"

        /** Title types a person's filmography lists (people search checks candidates against the same set). */
        const val PERSON_MEDIA_ITEM_TYPES = "Movie,Series"
        val EPISODE_ORDER = listOf("SortBy" to "ParentIndexNumber,IndexNumber,SortName", "SortOrder" to "Ascending,Ascending,Ascending")

        /** Filter lookups stay isolated from Browse so a very large library still opens when they are slow. */
        val FILTERS_TIMEOUT = 8.seconds

        fun seg(value: String) = JellyfinCore.segment(value)
    }
}

/**
 * Concurrent [run]s for one key share the first caller's result or failure; a settled key starts afresh. When the
 * first caller is cancelled the waiters run the block themselves rather than inherit the cancellation.
 */
private class SingleFlight<K, V> {
    private val mutex = Mutex()
    private val inFlight = mutableMapOf<K, CompletableDeferred<V>>()

    private class OwnerCancelled : Exception()

    suspend fun run(key: K, block: suspend () -> V): V {
        while (true) {
            var owner = false
            val deferred = mutex.withLock {
                inFlight[key] ?: CompletableDeferred<V>().also { inFlight[key] = it; owner = true }
            }
            if (!owner) {
                try {
                    return deferred.await()
                } catch (_: OwnerCancelled) {
                    continue
                }
            }
            val result = try {
                block()
            } catch (e: Throwable) {
                settle(key) { deferred.completeExceptionally(if (e is CancellationException) OwnerCancelled() else e) }
                throw e
            }
            settle(key) { deferred.complete(result) }
            return result
        }
    }

    private suspend fun settle(key: K, complete: () -> Unit) = withContext(NonCancellable) {
        mutex.withLock { inFlight.remove(key) }
        complete()
    }
}

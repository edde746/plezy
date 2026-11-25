package com.edde746.plezy.plex

import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.MediaServerTimeouts
import com.edde746.plezy.backend.net.MediaServerResponse
import com.edde746.plezy.backend.net.fetchWithCacheFallback
import com.edde746.plezy.backend.net.retryTransientMediaServerCall
import com.edde746.plezy.backend.net.throwIfHttpError
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.ArtistDiscographyGroup
import com.edde746.plezy.model.DiscographyGroupKind
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.ExternalSeasonRef
import com.edde746.plezy.model.LibraryFilterOperator
import com.edde746.plezy.model.LibraryFilterResult
import com.edde746.plezy.model.LibraryGenre
import com.edde746.plezy.model.LibraryFirstCharacter
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.MediaFilter
import com.edde746.plezy.model.MediaFilterField
import com.edde746.plezy.model.MediaFilterType
import com.edde746.plezy.model.MediaFilterUnit
import com.edde746.plezy.model.MediaFilterValue
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPerson
import com.edde746.plezy.model.MediaPersonDetails
import com.edde746.plezy.model.MediaSort
import com.edde746.plezy.model.buildArtistDiscographyGroups
import com.edde746.plezy.model.sortEpisodesByWatchOrder
import com.edde746.plezy.net.UriComponent
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/** Plex's online metadata provider, where a person's biography lives; the server keeps only the name and photo. */
private const val DISCOVER_PEOPLE_URL = "https://discover.provider.plex.tv/library/people/"

/** Ids per batched `/library/metadata/{ids}` request: short ids keep the URL well under proxy limits. */
private const val DISCOGRAPHY_TAG_CHUNK_SIZE = 100

/** Rows asked of people search: one person can fill a row per library section. */
private const val PEOPLE_SEARCH_ROW_LIMIT = 100

private fun MediaServerResponse.directories(): List<JsonObject> = data.mediaContainer()?.get("Directory").objectList()

// Section settings and maintenance.

/** A section's settings, id to value. */
suspend fun PlexClient.getLibrarySectionPrefs(sectionId: String): Map<String, JsonElement> {
    val settings = getWithFailover("/library/sections/$sectionId/prefs").data.mediaContainer()?.get("Setting").objectList()
    return buildMap {
        for (setting in settings) {
            val id = setting["id"].scalarString() ?: continue
            put(id, setting["value"] ?: JsonNull)
        }
    }
}

internal suspend fun PlexClient.scanLibraryImpl(libraryId: String) {
    getWithFailover("/library/sections/$libraryId/refresh")
}

internal suspend fun PlexClient.refreshLibraryMetadataImpl(libraryId: String) {
    getWithFailover("/library/sections/$libraryId/refresh", mapOf("force" to 1))
}

suspend fun PlexClient.analyzeLibrary(sectionId: String) {
    getWithFailover("/library/sections/$sectionId/analyze")
}

suspend fun PlexClient.emptyLibraryTrash(sectionId: String) {
    throwIfHttpError(http.put("/library/sections/$sectionId/emptyTrash"))
}

// Filters, sorts, genres, alphabet.

/** The values of a filter field, from its `key` ([filterKey], a path under the section). */
suspend fun PlexClient.fetchFilterValues(filterKey: String): List<MediaFilterValue> =
    getWithFailover(filterKey).directories().map {
        MediaFilterValue(it["key"].stringOrNull() ?: "", it["title"].stringOrNull() ?: "", it["type"].stringOrNull())
    }

/** The legacy `/filters` listing: only `string`/`integer`/`boolean` fields. A shared library has none. */
suspend fun PlexClient.getLibraryFilters(sectionId: String): List<MediaFilter> {
    if (sectionId == "shared") return emptyList()
    return getWithFailover("/library/sections/$sectionId/filters").directories().map { json ->
        MediaFilter(
            filter = json["filter"].stringOrNull() ?: "",
            title = json["title"].stringOrNull() ?: "",
            filterType = json["filterType"].stringOrNull() ?: MediaFilterType.STRING,
            key = json["key"].stringOrNull() ?: "",
            type = json["type"].stringOrNull() ?: "filter",
        )
    }
}

/** The values a `/filters` entry's [filterKey] lists (a section's genres, labels). */
suspend fun PlexClient.getFilterValues(filterKey: String): List<MediaFilterValue> =
    getWithFailover(filterKey).directories().map { json ->
        MediaFilterValue(key = json["key"].stringOrNull() ?: "", title = json["title"].stringOrNull() ?: "", type = json["type"].stringOrNull())
    }

/**
 * The fields and per-type operators Plex publishes with `/all?includeMeta=1` (the only source for exclusion, ranges
 * and text matching); servers that publish none fall back to [getLibraryFilters]. Values stay lazy.
 */
internal suspend fun PlexClient.fetchLibraryFiltersWithValuesImpl(libraryId: String, libraryKind: MediaKind?): LibraryFilterResult {
    if (libraryId == "shared") return LibraryFilterResult.EMPTY
    val typeId = PlexMetadataType.forKind(libraryKind)
    try {
        // Both pagination parameters: PMS ignores a lone `Size=0` and answers with the entire section.
        val query = buildMap<String, Any?> {
            put("includeMeta", 1)
            putAll(plexPaginationParams(0, 0))
            if (typeId != null) put("type", typeId)
        }
        val filters = parsePlexFilterMetadata(getWithFailover("/library/sections/$libraryId/all", query), libraryId, typeId)
        if (filters.isNotEmpty()) return LibraryFilterResult(filters, emptyMap())
        Log.d(PlexClient.TAG) { "Plex section $libraryId returned no filter metadata; falling back to /filters" }
    } catch (e: MediaServerHttpException) {
        if (e.isCancellation) throw e
        Log.w(PlexClient.TAG, e) { "Plex filter metadata unavailable for section $libraryId" }
    }
    return LibraryFilterResult(getLibraryFilters(libraryId), emptyMap())
}

/** `Meta.Type[].Field[]` of the browsed type against `Meta.FieldType[].Operator[]`. */
private fun parsePlexFilterMetadata(response: MediaServerResponse, libraryId: String, typeId: Int?): List<MediaFilter> {
    val meta = response.data.mediaContainer()?.get("Meta") as? JsonObject ?: return emptyList()

    val operatorsByFieldType = buildMap {
        for (entry in meta["FieldType"].objectList()) {
            val fieldType = entry["type"].stringOrNull() ?: continue
            val operators = entry["Operator"] as? JsonArray ?: continue
            val parsed = operators.filterIsInstance<JsonObject>().mapNotNull { plexOperatorFor(it["key"].stringOrNull()) }
            if (parsed.isNotEmpty()) put(fieldType, parsed)
        }
    }

    // `active` marks the type the request queried; without `type=` Plex marks the section's own type.
    var browsedType: JsonObject? = null
    for (entry in (meta["Type"] as? JsonArray ?: return emptyList()).filterIsInstance<JsonObject>()) {
        val fields = entry["Field"] as? JsonArray
        if (fields.isNullOrEmpty()) continue
        if ((entry["active"] as? JsonPrimitive)?.content == "true") {
            browsedType = entry
            break
        }
        if (browsedType == null) browsedType = entry
    }
    val type = browsedType ?: return emptyList()

    // A multi-type section qualifies fields with their owning type (`show.genre`); the bare name is equivalent for the
    // browsed type and is what value endpoints and saved selections use, so only that prefix is stripped.
    val ownPrefix = "${type["type"].scalarString()}."
    val filters = mutableListOf<MediaFilter>()
    for (field in type["Field"].objectList()) {
        val rawKey = field["key"].stringOrNull()
        val fieldType = field["type"].stringOrNull()
        val title = field["title"].stringOrNull()
        if (rawKey.isNullOrEmpty() || fieldType == null || title == null) continue
        val wireField = rawKey.removePrefix(ownPrefix)
        val bareField = wireField.substringAfterLast('.')
        val filterType = plexFilterTypeFor(fieldType)
        filters += MediaFilter(
            filter = wireField,
            title = title,
            filterType = filterType,
            key = plexFilterValuesKey(fieldType, bareField, libraryId, typeId),
            type = "filter",
            // `duration` is milliseconds and `mediaSize` bytes: the editor scales what the user types.
            unit = MediaFilterUnit.fromPlexSubType(field["subType"].stringOrNull()),
            operators = operatorsByFieldType[fieldType] ?: MediaFilter.defaultOperatorsFor(filterType),
        )
    }
    if (filters.isEmpty()) return emptyList()

    // Undocumented: a substring match over the item's file path, the only filename/folder filter. A show-type query
    // answers 500 for it, so only movie queries offer it.
    if (typeId == PlexMetadataType.MOVIE) {
        filters += MediaFilter(
            filter = MediaFilterField.FILE,
            title = T.libraries.filterCategories.filePath,
            filterType = MediaFilterType.STRING,
            key = "",
            type = "filter",
            operators = listOf(LibraryFilterOperator.IS, LibraryFilterOperator.IS_NOT),
        )
    }
    return filters
}

private fun plexOperatorFor(key: String?): LibraryFilterOperator? = when (key) {
    "=" -> LibraryFilterOperator.IS
    "!=" -> LibraryFilterOperator.IS_NOT
    ">>=" -> LibraryFilterOperator.AT_LEAST
    "<<=" -> LibraryFilterOperator.AT_MOST
    "==" -> LibraryFilterOperator.MATCHES
    "!==" -> LibraryFilterOperator.NOT_MATCHES
    "<=" -> LibraryFilterOperator.BEGINS_WITH
    ">=" -> LibraryFilterOperator.ENDS_WITH
    else -> null
}

/** Anything that enumerates values behaves like a tag. */
private fun plexFilterTypeFor(plexFieldType: String): String = when (plexFieldType) {
    "boolean" -> MediaFilterType.BOOLEAN
    "integer" -> MediaFilterType.INTEGER
    "date" -> MediaFilterType.DATE
    "string" -> MediaFilterType.STRING
    else -> MediaFilterType.TAG
}

/** The value listing of a field; empty for free text, dates, booleans and integers Plex doesn't list. */
private fun plexFilterValuesKey(plexFieldType: String, bareField: String, libraryId: String, typeId: Int?): String {
    val listed = when (plexFieldType) {
        "boolean", "string", "date" -> false
        "integer" -> bareField == "year" || bareField == "decade"
        else -> true
    }
    if (!listed) return ""
    val suffix = if (typeId == null) "" else "?type=$typeId"
    return "/library/sections/$libraryId/$bareField$suffix"
}

/**
 * The section's sorts (music asks per type: `album`/`track`), else the built-in fallbacks; video sections also get
 * the sorts Plex honors but doesn't advertise. A shared library sorts by title or date shared.
 */
internal suspend fun PlexClient.fetchSortOptionsImpl(libraryId: String, libraryType: String?): List<MediaSort> {
    val labels = T.libraries.sortLabels
    if (libraryId == "shared") {
        return listOf(
            MediaSort("titleSort", labels.title, "titleSort:desc", "asc"),
            MediaSort("taggingCreatedAt", labels.dateShared, "taggingCreatedAt:desc", "desc"),
        )
    }
    val type = libraryType?.lowercase()
    val base = try {
        val musicType = when (type) {
            "album" -> PlexMetadataType.ALBUM
            "track" -> PlexMetadataType.TRACK
            else -> null
        }
        val sorts = getWithFailover("/library/sections/$libraryId/sorts", musicType?.let { mapOf("type" to it) })
            .directories()
            .map { json ->
                MediaSort(
                    key = json["key"].stringOrNull() ?: "",
                    title = json["title"].stringOrNull() ?: "",
                    descKey = json["descKey"].stringOrNull(),
                    defaultDirection = json["defaultDirection"].stringOrNull(),
                    unsortedDirection = json["default"].stringOrNull(),
                )
            }
        sorts.ifEmpty { fallbackSorts(type) }
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.e(PlexClient.TAG, e) { "Failed to get library sorts" }
        fallbackSorts(type)
    }
    return withExtraSorts(base, type)
}

private fun dateAddedSort() = MediaSort("addedAt", T.libraries.sortLabels.dateAdded, "addedAt:desc", "desc")

private fun fallbackSorts(libraryType: String?): List<MediaSort> {
    val labels = T.libraries.sortLabels
    return buildList {
        add(MediaSort("titleSort", labels.title, defaultDirection = "asc"))
        add(dateAddedSort())
        if (libraryType == "show") {
            add(MediaSort("episode.originallyAvailableAt", labels.latestEpisodeAirDate, "episode.originallyAvailableAt:desc", "desc"))
        }
        add(MediaSort("originallyAvailableAt", labels.releaseDate, "originallyAvailableAt:desc", "desc"))
        add(MediaSort("rating", labels.rating, "rating:desc", "desc"))
    }
}

/**
 * Date added, plays and the user's rating sort correctly on video sections (`clip` home-video sections included)
 * but aren't advertised; appended unless already listed.
 */
private fun withExtraSorts(base: List<MediaSort>, libraryType: String?): List<MediaSort> {
    if (libraryType !in setOf("movie", "show", "clip")) return base
    val labels = T.libraries.sortLabels
    val keys = base.mapTo(HashSet()) { it.key }
    val extras = listOf(
        dateAddedSort(),
        MediaSort("viewCount", labels.playCount, "viewCount:desc", "desc"),
        MediaSort("userRating", labels.userRating, "userRating:desc", "desc"),
    ).filter { it.key !in keys }
    return base + extras
}

/**
 * The Categories tab: one tile per genre, keyed by the genre filter value that selects it. PMS composes each tile as
 * `/photo/:/transcode?blendColor=RRGGBB&…&url=<art>`; art and tint are split back apart.
 */
internal suspend fun PlexClient.fetchLibraryGenresImpl(libraryId: String, libraryKind: MediaKind): List<LibraryGenre> =
    getWithFailover("/library/sections/$libraryId/categories").directories().mapNotNull { entry ->
        val title = entry["title"].stringOrNull()
        val key = entry["key"].stringOrNull()
        if (title.isNullOrEmpty() || key == null) return@mapNotNull null
        val value = queryParameter(key, MediaFilterField.GENRE)
        if (value.isNullOrEmpty()) return@mapNotNull null
        val thumb = entry["thumb"].stringOrNull()
        if (thumb.isNullOrEmpty()) return@mapNotNull LibraryGenre(title, value)
        val art = queryParameter(thumb, "url")
        val blend = queryParameter(thumb, "blendColor")
        LibraryGenre(title, value, artPath = art?.takeIf { it.isNotEmpty() } ?: thumb, accentRgb = blend?.toIntOrNull(16))
    }

/** [name]'s decoded value in [uri]'s query, null when absent. */
private fun queryParameter(uri: String, name: String): String? {
    val query = uri.substringAfter('?', "").substringBefore('#')
    for (pair in query.split('&')) {
        val eq = pair.indexOf('=')
        val key = UriComponent.decode((if (eq < 0) pair else pair.substring(0, eq)).replace('+', ' '))
        if (key == name) return if (eq < 0) "" else UriComponent.decode(pair.substring(eq + 1).replace('+', ' '))
    }
    return null
}

/** A section's alphabet index; [filters] narrow it like the browse query they mirror. */
suspend fun PlexClient.fetchFirstCharacters(sectionId: String, type: Int? = null, filters: Map<String, Any?>? = null): List<LibraryFirstCharacter> {
    val query = buildMap {
        if (type != null) put("type", type)
        filters?.let(::putAll)
    }
    return getWithFailover("/library/sections/$sectionId/firstCharacter", query).directories().map {
        LibraryFirstCharacter(it["key"].stringOrNull() ?: "", it["title"].stringOrNull() ?: "", it["size"].flexInt() ?: 0)
    }
}

// Folders.

/**
 * Folder rows are Directory rows with no usable type, an explicit `folder` type, or a `/folder` key: they become
 * [MediaKind.FOLDER] with their key as [MediaItem.backendFolderKey].
 */
private fun classifyFolderRow(item: MediaItem): MediaItem {
    val key = item.raw?.get("key").stringOrNull()
    val isFolder = item.kind == MediaKind.FOLDER || item.kind == MediaKind.UNKNOWN || key?.contains("/folder") == true
    return if (isFolder) item.copy(kind = MediaKind.FOLDER, backendFolderKey = key) else item
}

/** A folder listing's `Metadata` and `Directory` rows; the container's section wins over the caller's. */
private fun PlexClient.folderRows(response: MediaServerResponse, librarySectionId: Int?, librarySectionTitle: String?): List<MediaItem> {
    val container = response.data.mediaContainer() ?: return emptyList()
    val sectionId = plexLibrarySectionIdFromJson(container) ?: librarySectionId
    val sectionTitle = plexLibrarySectionTitleFromJson(container) ?: librarySectionTitle
    return (container["Metadata"].objectList() + container["Directory"].objectList())
        .map { classifyFolderRow(mediaItemFromJson(it, sectionId, sectionTitle)) }
}

/** A section's top-level folders. Failures propagate so the tree can show the error. */
internal suspend fun PlexClient.fetchLibraryFoldersImpl(libraryId: String): List<MediaItem> {
    val response = getWithFailover("/library/sections/$libraryId/folder", mapOf("includeCollections" to 0))
    return folderRows(response, plexLibrarySectionIdFromString(libraryId), null)
}

/** A folder's files and subfolders, via its [MediaItem.backendFolderKey]; none without one. */
internal suspend fun PlexClient.fetchFolderChildrenImpl(folder: MediaItem, libraryId: String?, libraryTitle: String?): List<MediaItem> {
    val folderKey = folder.backendFolderKey ?: return emptyList()
    val response = getWithFailover(folderKey)
    val sectionId = plexLibrarySectionIdFromString(folderKey) ?: plexLibrarySectionIdFromString(libraryId ?: folder.libraryId)
    return folderRows(response, sectionId, libraryTitle ?: folder.libraryTitle)
}

// People.

internal suspend fun PlexClient.fetchPersonMediaPageImpl(personId: String, start: Int?, size: Int?): LibraryPage<MediaItem> =
    fetchPlexPage("/library/people/$personId/media", start, size)

/**
 * A person's biography from Plex Discover, reached through the tag's plex.tv id with the plex.tv account token (Discover
 * rejects a Home user's server token). Empty offline, without an account token, or for a tag with no plex.tv id.
 */
internal suspend fun PlexClient.fetchPersonDetailsImpl(personId: String): MediaPersonDetails {
    val accountToken = plexAccountToken
    if (isOfflineMode || accountToken.isNullOrEmpty()) return MediaPersonDetails.EMPTY
    val tagKey = getWithFailover("/library/people/$personId").directories().firstOrNull()?.get("tagKey").stringOrNull()
    if (tagKey.isNullOrEmpty()) return MediaPersonDetails.EMPTY
    // A plex.tv failure says nothing about this server's endpoints, so it must not walk the failover list.
    val response = http.get(
        DISCOVER_PEOPLE_URL + UriComponent.encode(tagKey),
        headers = mapOf("X-Plex-Token" to accountToken),
        allowEndpointFailover = false,
    )
    throwIfHttpError(response)
    return PlexMappers.personDetails(response.firstMetadata())
}

/**
 * Actors and directors from `/library/search?searchTypes=people`: one row per section the person has titles in, in
 * score order. Rows in [excludedLibraryIds] are dropped before de-duplicating by person id, so someone hidden in one
 * section still surfaces through another; [limit] counts distinct people.
 */
internal suspend fun PlexClient.searchPeopleImpl(query: String, limit: Int, excludedLibraryIds: Set<String>): List<MediaPerson> {
    val response = getWithFailover(
        "/library/search",
        mapOf(
            "query" to query,
            "limit" to PEOPLE_SEARCH_ROW_LIMIT,
            "searchTypes" to "people",
            "X-Plex-Container-Size" to PEOPLE_SEARCH_ROW_LIMIT,
        ),
    )
    val people = LinkedHashMap<String, MediaPerson>()
    for (result in response.data.mediaContainer()?.get("SearchResult").objectList()) {
        if (people.size >= limit) break
        val directory = result["Directory"] as? JsonObject ?: continue
        val sectionId = plexLibrarySectionIdFromJson(directory)
        if (sectionId != null && sectionId.toString() in excludedLibraryIds) continue
        val person = try {
            PlexMappers.personFromSearchResultJson(directory, serverId, serverName)
        } catch (e: IllegalArgumentException) {
            Log.w(PlexClient.TAG, e) { "Skipping a people search row that does not map" }
            null
        } ?: continue
        people.getOrPut(person.id) { person }
    }
    return people.values.toList()
}

// External ids.

/**
 * An item's ids: the modern `Guid` array wins per field and the legacy scalar `guid` fills the rest. A 404 (the item
 * is gone) reads as no ids; every other failure propagates, so an outage never reads as an unmatched item.
 */
internal suspend fun PlexClient.fetchExternalIdsImpl(itemId: String): ExternalIds {
    val response = try {
        getWithFailover("/library/metadata/$itemId", mapOf("includeGuids" to 1))
    } catch (e: MediaServerHttpException) {
        if (e.statusCode == 404) return ExternalIds()
        throw e
    }
    val first = response.firstMetadata() ?: return ExternalIds()
    return ExternalIds.fromGuids(first["Guid"] as? JsonArray).fillFrom(ExternalIds.fromLegacyPlexGuid(first["guid"].stringOrNull()))
}

/**
 * Server-wide reverse lookup of a movie or show: one `/library/all?guid=` prefix-filter request for [plexGuid] and every
 * legacy-agent form of [ids], plus one `/hubs/search` per title (only with ids: title rows verify by id intersection).
 * Every request runs concurrently, under the lookup deadline with endpoint failover off (a slow library isn't a dead
 * endpoint); a failure fails the lookup. Every id-verified row is kept, one per rating key: exact-guid hits first, then
 * modern `Guid` matches, then legacy ones. An agreed sequel season gates the shows on having that season. Null for
 * kinds Plex can't look up or when there is nothing to ask.
 */
internal suspend fun PlexClient.findByExternalIdsImpl(
    ids: ExternalIds,
    kind: MediaKind,
    titles: List<String>,
    year: Int?,
    plexGuid: String?,
    season: ExternalSeasonRef?,
): List<MediaItem>? {
    val plexType = when (kind) {
        MediaKind.MOVIE -> PlexMetadataType.MOVIE
        MediaKind.SHOW -> PlexMetadataType.SHOW
        else -> return null
    }
    val guids = listOfNotNull(plexGuid) + ids.legacyPlexGuidPrefixes
    val searchTitles = if (ids.hasAny) titles else emptyList()
    if (guids.isEmpty() && searchTitles.isEmpty()) return null

    val pages = coroutineScope {
        buildList {
            if (guids.isNotEmpty()) add(async { lookupByGuids(guids, plexType) })
            for (title in searchTitles) add(async { searchTitleForLookup(title, plexType) })
        }.awaitAll()
    }

    val exact = LinkedHashMap<String, JsonObject>()
    val modern = LinkedHashMap<String, JsonObject>()
    val legacy = LinkedHashMap<String, JsonObject>()
    fun collect(into: MutableMap<String, JsonObject>, item: JsonObject) {
        val ratingKey = item["ratingKey"].scalarString()
        if (ratingKey.isNullOrEmpty()) return
        into.getOrPut(ratingKey) { item }
    }
    for (page in pages) {
        for (item in page) {
            val guidArray = item["Guid"]
            when {
                plexGuid != null && item["guid"].stringOrNull() == plexGuid -> collect(exact, item)
                guidArray is JsonArray && ids.intersects(ExternalIds.fromGuids(guidArray)) -> collect(modern, item)
                ids.intersects(ExternalIds.fromLegacyPlexGuid(item["guid"].stringOrNull())) -> collect(legacy, item)
            }
        }
    }
    val ordered = LinkedHashMap(exact)
    for (bucket in listOf(modern, legacy)) {
        for ((key, value) in bucket) ordered.getOrPut(key) { value }
    }
    if (ordered.isEmpty()) return emptyList()
    return gateExternalIdMatches(ordered.values.toList(), kind, season)
}

/**
 * Drops shows the server lacks [season]'s agreed season of, in one `/library/all?type=3&show.id=<keys>&season.index=N`
 * request (`,` is OR). Only an agreed season above 1 gates; a candidate without a rating key is kept.
 */
private suspend fun PlexClient.gateExternalIdMatches(candidates: List<JsonObject>, kind: MediaKind, season: ExternalSeasonRef?): List<MediaItem> {
    val entries = candidates.map { it["ratingKey"].scalarString() to mediaItemFromJson(it) }
    val seasonIndex = season?.agreedSeason
    if (kind != MediaKind.SHOW || seasonIndex == null || seasonIndex <= 1) return entries.map { it.second }
    val ratingKeys = entries.mapNotNull { it.first?.takeIf(String::isNotEmpty) }
    if (ratingKeys.isEmpty()) return entries.map { it.second }
    val response = lookupRequest(
        "/library/all",
        mapOf("type" to PlexMetadataType.SEASON, "show.id" to ratingKeys.joinToString(","), "season.index" to seasonIndex),
        "Plex season lookup",
    )
    val withSeason = response.data.mediaContainer()?.get("Metadata").objectList()
        .mapNotNullTo(HashSet()) { it["parentRatingKey"].scalarString()?.takeIf(String::isNotEmpty) }
    return entries.filter { (key, _) -> key.isNullOrEmpty() || key in withSeason }.map { it.second }
}

private suspend fun PlexClient.lookupRequest(path: String, query: Map<String, Any?>, operation: String): MediaServerResponse =
    retryTransientMediaServerCall(operation, MediaServerTimeouts.LIBRARY_LOOKUP) { timeout ->
        getWithFailover(path, query, timeout = timeout, allowEndpointFailover = false)
    }

private suspend fun PlexClient.lookupByGuids(guids: List<String>, plexType: Int): List<JsonObject> =
    lookupRequest(
        "/library/all",
        mapOf("guid" to guids.joinToString(","), "type" to plexType, "includeGuids" to 1),
        "Plex guid lookup",
    ).data.mediaContainer()?.get("Metadata").objectList()

/** Rows of the requested type's hub only: a `tv` search also answers an episode hub. */
private suspend fun PlexClient.searchTitleForLookup(title: String, plexType: Int): List<JsonObject> {
    val isMovie = plexType == PlexMetadataType.MOVIE
    val response = lookupRequest(
        "/hubs/search",
        mapOf("query" to title, "searchTypes" to if (isMovie) "movies" else "tv", "includeGuids" to 1, "limit" to 50),
        "Plex title lookup",
    )
    val hubType = if (isMovie) "movie" else "show"
    return response.data.mediaContainer()?.get("Hub").objectList()
        .filter { it["type"].stringOrNull() == hubType }
        .flatMap { it["Metadata"].objectList() }
}

// Music.

/**
 * Every album row of the artist's section filtered to the artist (the artist's `/children` holds only the primary
 * album bucket), newest first. Cached under the artist's children key so offline fallback and invalidation cover it.
 */
internal suspend fun PlexClient.fetchArtistAlbumsImpl(artist: MediaItem): List<MediaItem> {
    val sectionId = artist.libraryId?.takeIf { it.isNotEmpty() } ?: fetchItemImpl(artist.id)?.libraryId
    check(!sectionId.isNullOrEmpty()) { "Plex artist ${artist.id} is missing a library section ID" }
    val context = captureRequestContext()
    return fetchWithCacheFallback(
        cache = cache.store,
        cacheServerId = context.cacheServerId,
        cacheKey = "/library/metadata/${artist.id}/children",
        offline = isOfflineMode,
        networkCall = {
            fetchAllPagesResponse(
                "/library/sections/$sectionId/all",
                mapOf("type" to PlexMetadataType.ALBUM, "artist.id" to artist.id, "sort" to "album.year:desc"),
            )
        },
        parseCache = { metadataItemsFromCache(it) },
        parseResponse = { metadataItems(it) },
    ).orEmpty()
}

/**
 * The artist's albums grouped by release format. Listing rows carry no `Format`/`Subformat` tags, so the albums are
 * re-read by id in batches; a failed tag fetch degrades to one flat albums group. One album at most skips the lookup.
 */
internal suspend fun PlexClient.fetchArtistDiscographyImpl(artist: MediaItem): List<ArtistDiscographyGroup> {
    val albums = fetchArtistAlbumsImpl(artist)
    if (albums.size <= 1) {
        return if (albums.isEmpty()) emptyList() else listOf(ArtistDiscographyGroup(DiscographyGroupKind.ALBUMS, albums))
    }
    val kinds = try {
        fetchDiscographyKinds(artist.id, albums.map { it.id })
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(PlexClient.TAG, e) { "Discography tag fetch failed for artist ${artist.id}, degrading to a flat albums list" }
        return listOf(ArtistDiscographyGroup(DiscographyGroupKind.ALBUMS, albums))
    }
    return buildArtistDiscographyGroups(albums) { kinds[it.id] ?: DiscographyGroupKind.ALBUMS }
}

/** Explicit container bounds defeat a server-side page cap; a missing row leaves its album in the default group. */
private suspend fun PlexClient.fetchDiscographyKinds(artistId: String, albumIds: List<String>): Map<String, DiscographyGroupKind> {
    val context = captureRequestContext()
    val results = coroutineScope {
        albumIds.chunked(DISCOGRAPHY_TAG_CHUNK_SIZE).mapIndexed { index, chunk ->
            async {
                fetchWithCacheFallback(
                    cache = cache.store,
                    cacheServerId = context.cacheServerId,
                    cacheKey = "/library/metadata/$artistId/discography-tags/$index",
                    offline = isOfflineMode,
                    networkCall = { http.get("/library/metadata/${chunk.joinToString(",")}", plexPaginationParams(0, chunk.size)) },
                    parseCache = { PlexCacheParser.extractMetadataList(it).objectList() },
                    parseResponse = { it.data.mediaContainer()?.get("Metadata").objectList() },
                )
            }
        }.awaitAll()
    }
    return buildMap {
        for (rows in results) {
            for (row in rows.orEmpty()) {
                val ratingKey = row["ratingKey"].scalarString() ?: continue
                put(ratingKey, PlexMappers.discographyKind(row))
            }
        }
    }
}

// Episodes.

/** Every episode of the series, watched ones included, in the user's specials ordering. */
internal suspend fun PlexClient.fetchClientSideEpisodeQueueImpl(seriesId: String): List<MediaItem> =
    sortEpisodesByWatchOrder(fetchPlayableDescendantsImpl(seriesId), environment.specialsOrdering())

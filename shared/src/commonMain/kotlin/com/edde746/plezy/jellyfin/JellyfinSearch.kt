package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.DEFAULT_PEOPLE_SEARCH_LIMIT
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.MediaServerTimeouts
import com.edde746.plezy.backend.net.retryTransientMediaServerCall
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.ExternalSeasonRef
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.model.MediaPerson
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.rankPeopleSearchResults
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.serialization.json.JsonObject

/**
 * Title and people search, and the reverse lookup by catalog ids. A search hit names no library, so every title
 * search is one scoped request per visible library: the only way a hit learns its library, and the only way a hidden
 * library can be left out.
 */
internal class JellyfinSearch(
    private val core: JellyfinCore,
    /** The library views less Live TV's: the client's last loaded list when it has one, else a fresh `/Views` fetch. */
    private val fetchLibraries: suspend () -> List<MediaLibrary>,
    private val fetchItem: suspend (String) -> MediaItem?,
    private val fetchChildren: suspend (String) -> List<MediaItem>,
    private val stampLibrary: suspend (MediaItem) -> MediaItem,
) {
    /**
     * Every leg keeps the whole [limit]: splitting it would cap a library that holds every match. Legs can overlap
     * (`/Artists` filters by ancestor, so an artist in two music libraries comes from both); the first hit wins.
     */
    suspend fun searchItems(query: String, limit: Int = 100, excludedLibraryIds: Set<String> = emptySet()): List<MediaItem> {
        // A photo library holds nothing search surfaces.
        val visible = fetchLibraries().filter { it.id !in excludedLibraryIds && it.kind != MediaKind.PHOTO }
        val found = LinkedHashMap<String, MediaItem>()
        for (batch in visible.chunked(CONCURRENCY)) {
            val results = coroutineScope { batch.map { async { searchLibrary(it, query, limit) } }.awaitAll() }
            for (item in results.flatten()) found.getOrPut(item.id) { item }
        }
        return found.values.toList()
    }

    private suspend fun searchLibrary(library: MediaLibrary, query: String, limit: Int): List<MediaItem> = coroutineScope {
        val base = listOf(
            "userId" to core.userId,
            "SearchTerm" to query,
            "Recursive" to "true",
            "Limit" to "$limit",
        )
        val legs = when {
            // Albums are folder rows: user data or counts would cost the server a recursive query per album,
            // so albums and tracks are asked separately.
            library.kind == MediaKind.ARTIST -> listOf(
                async {
                    fetchItemsArray(
                        "/Items",
                        base + listOf(
                            "IncludeItemTypes" to "MusicAlbum",
                            "ParentId" to library.id,
                            "Fields" to core.musicAlbumRowFields,
                            "EnableUserData" to "false",
                            "EnableTotalRecordCount" to "false",
                        ) + JellyfinCore.IMAGE_PARAMS,
                    )
                },
                async {
                    fetchItemsArray(
                        "/Items",
                        base + listOf(
                            "IncludeItemTypes" to "Audio",
                            "ParentId" to library.id,
                            "Fields" to core.musicTrackRowFields,
                            "EnableTotalRecordCount" to "false",
                        ) + JellyfinCore.IMAGE_PARAMS,
                    )
                },
            )
            // Emby answers `IncludeItemTypes=Movie` in seconds on a large library, `MediaTypes=Video` in milliseconds.
            library.kind == MediaKind.MOVIE && core.dialect.searchesMovieLibrariesByMediaType -> listOf(
                async {
                    fetchItemsArray(
                        "/Items",
                        base + listOf(
                            "MediaTypes" to "Video",
                            "ParentId" to library.id,
                            "Fields" to core.browseFields,
                            "EnableTotalRecordCount" to "false",
                        ) + JellyfinCore.IMAGE_PARAMS,
                    ).filter { it.str("Type") == "Movie" }
                },
            )
            else -> listOf(
                async {
                    fetchItemsArray(
                        "/Items",
                        base + listOf(
                            "IncludeItemTypes" to searchItemTypes(library.kind),
                            "ParentId" to library.id,
                            "Fields" to core.browseFields,
                            "EnableTotalRecordCount" to "false",
                        ) + JellyfinCore.IMAGE_PARAMS,
                    )
                },
            )
        }
        // `/Items?SearchTerm=` only matches folder-derived artists; `/Artists` also finds tag-only ones. Only a music
        // library can hold any. Best effort: a music hiccup must not sink the other legs.
        val artists = if (library.kind == MediaKind.ARTIST) {
            async {
                try {
                    fetchItemsArray(
                        "/Artists",
                        listOf(
                            "userId" to core.userId,
                            "searchTerm" to query,
                            "Limit" to "$limit",
                            "parentId" to library.id,
                            "EnableTotalRecordCount" to "false",
                        ) + JellyfinCore.IMAGE_PARAMS,
                    )
                } catch (e: Exception) {
                    if (e is CancellationException || (e is MediaServerHttpException && e.isCancellation)) throw e
                    Log.w(TAG, e) { "/Artists search failed (treating as empty)" }
                    emptyList()
                }
            }
        } else {
            null
        }
        val rows = (legs + listOfNotNull(artists)).awaitAll().flatten()
        core.mapItems(rows).map { it.copy(libraryId = library.id, libraryTitle = library.title) }
    }

    /**
     * `/Persons` lists people with no title this user can see and ignores `parentId`, so each ranked candidate is
     * checked against the same query the person's filmography runs, scoped to each visible library when some are
     * hidden.
     */
    suspend fun searchPeople(query: String, limit: Int = DEFAULT_PEOPLE_SEARCH_LIMIT, excludedLibraryIds: Set<String> = emptySet()): List<MediaPerson> {
        // Null: one unscoped check, exact whenever no library that can hold a title is hidden.
        var checkedLibraries: List<MediaLibrary>? = null
        if (excludedLibraryIds.isNotEmpty()) {
            // Music and photo libraries never hold a Movie or Series.
            val titleLibraries = fetchLibraries().filter { it.kind != MediaKind.ARTIST && it.kind != MediaKind.PHOTO }
            val visible = titleLibraries.filter { it.id !in excludedLibraryIds }
            if (visible.isEmpty()) return emptyList()
            if (visible.size < titleLibraries.size) checkedLibraries = visible
        }

        // Emby's `/Persons` takes 20+ s on a large server; its `/Items` index answers in milliseconds.
        val viaItems = core.dialect.searchesPeopleThroughItems
        val rows = fetchItemsArray(
            if (viaItems) "/Items" else "/Persons",
            listOf(
                "userId" to core.userId,
                "SearchTerm" to query,
                "IncludeItemTypes" to "Person".takeIf { viaItems },
                "Recursive" to "true".takeIf { viaItems },
                "PersonTypes" to "Actor,Director",
                // The server orders by name, not relevance: rank a wider pool client-side.
                "Limit" to "$PEOPLE_SEARCH_CANDIDATE_LIMIT",
                "EnableImageTypes" to "Primary",
                "ImageTypeLimit" to "1",
                "EnableUserData" to "false",
                "EnableTotalRecordCount" to "false",
            ),
        )
        val ranked = rankPeopleSearchResults(rows.mapNotNull(::person), query, limit)

        val found = mutableListOf<MediaPerson>()
        for (batch in ranked.chunked(CONCURRENCY)) {
            val hasMedia = coroutineScope { batch.map { async { personHasVisibleMedia(it.id, checkedLibraries) } }.awaitAll() }
            batch.forEachIndexed { index, person -> if (hasMedia[index]) found += person }
        }
        return found
    }

    private fun person(json: JsonObject): MediaPerson? {
        val id = json.str("Id")?.ifEmpty { null } ?: return null
        val name = json.str("Name")?.takeIf { it.isNotBlank() } ?: return null
        val primaryTag = json.obj("ImageTags")?.str("Primary")?.ifEmpty { null }
        return MediaPerson(
            id = id,
            name = name,
            backend = core.dialect.backend,
            serverId = ServerId(core.serverId),
            // No tagless fallback: a person without a primary image 404s there.
            thumbPath = primaryTag?.let {
                core.absolutizer.absolutize("/Items/${JellyfinCore.segment(id)}/Images/Primary?tag=${JellyfinUrls.queryComponent(it)}")
            },
            serverName = core.connection.serverName,
        )
    }

    /** Libraries are asked in turn; the first hit ends the walk. */
    private suspend fun personHasVisibleMedia(personId: String, libraries: List<MediaLibrary>?): Boolean {
        if (libraries == null) return personHasMedia(personId, parentId = null)
        return libraries.any { personHasMedia(personId, it.id) }
    }

    private suspend fun personHasMedia(personId: String, parentId: String?): Boolean = fetchItemsArray(
        "/Items",
        listOf(
            "userId" to core.userId,
            "PersonIds" to personId,
            "IncludeItemTypes" to PERSON_MEDIA_ITEM_TYPES,
            "Recursive" to "true",
            "ParentId" to parentId,
            "Limit" to "1",
            "CollapseBoxSetItems" to "false",
            "EnableTotalRecordCount" to "false",
            "EnableImages" to "false",
            "EnableUserData" to "false",
        ),
    ).isNotEmpty()

    /**
     * A title search per entry in [titles], each candidate verified against its inline `ProviderIds` (Jellyfin
     * silently ignores `anyProviderIdEquals`). Every title runs: a copy filed under another language's title is only
     * reachable through it, and every verified copy is returned (4K and HD libraries). [year] narrows
     * the first title only, and not for a sequel season, whose parent show carries season one's year. [plexGuid]
     * means nothing here. Jellyfin can't tell a non-admin its season order, so only a season TVDB and TMDB agree on
     * gates the matches.
     */
    suspend fun findByExternalIds(
        ids: ExternalIds,
        kind: MediaKind,
        titles: List<String> = emptyList(),
        year: Int? = null,
        plexGuid: String? = null,
        season: ExternalSeasonRef? = null,
    ): List<MediaItem>? {
        val itemType = when (kind) {
            MediaKind.MOVIE -> "Movie"
            MediaKind.SHOW -> "Series"
            else -> null
        }
        if (itemType == null || !ids.hasAny || titles.isEmpty()) return null

        val seasonIndex = season?.agreedSeason
        val years = if (year != null && season?.isSequel != true) "${year - 1},$year,${year + 1}" else null
        val pages = coroutineScope {
            titles.mapIndexed { index, title ->
                async {
                    val query = listOf(
                        "userId" to core.userId,
                        "SearchTerm" to title,
                        "Recursive" to "true",
                        "Limit" to "50",
                        "IncludeItemTypes" to itemType,
                        "Fields" to "ProviderIds,${core.browseFields}",
                        "years" to years.takeIf { index == 0 },
                    ) + JellyfinCore.IMAGE_PARAMS
                    val response = retryTransientMediaServerCall(LIBRARY_LOOKUP_OPERATION, MediaServerTimeouts.LIBRARY_LOOKUP) { timeout ->
                        core.get("/Items", query, timeout.inWholeMilliseconds, allowEndpointFailover = false)
                    }
                    core.itemsArray(response.throwIfError().data)
                }
            }.awaitAll()
        }
        val seen = HashSet<String>()
        val matches = pages.flatMap { core.mapItems(ExternalIds.jellyfinCandidatesMatching(it, ids)) }.filter { seen.add(it.id) }
        if (matches.isEmpty()) return emptyList()

        val kept = if (kind == MediaKind.SHOW && seasonIndex != null && seasonIndex > 1) keepMatchesWithSeason(matches, seasonIndex) else matches
        return coroutineScope { kept.map { async { stampedOrUnchanged(it) } }.awaitAll() }
    }

    /** One children fetch per candidate, concurrently: the match list is never truncated. */
    private suspend fun keepMatchesWithSeason(items: List<MediaItem>, seasonIndex: Int): List<MediaItem> = coroutineScope {
        val kept = items.map { item ->
            async { fetchChildren(item.id).any { it.kind == MediaKind.SEASON && it.index == seasonIndex } }
        }.awaitAll()
        items.filterIndexed { index, _ -> kept[index] }
    }

    /** The library stamp is best effort: a failed ancestors lookup leaves the match unstamped. */
    private suspend fun stampedOrUnchanged(item: MediaItem): MediaItem = try {
        stampLibrary(item)
    } catch (e: Exception) {
        if (e is CancellationException || (e is MediaServerHttpException && e.isCancellation)) throw e
        Log.d(TAG, e) { "library stamp failed for ${item.id}" }
        item
    }

    /** The detail row's `ProviderIds`; empty when the server has none or no such item (404). */
    suspend fun fetchExternalIds(itemId: String): ExternalIds =
        ExternalIds.fromJellyfinProviderIds(fetchItem(itemId)?.raw?.obj("ProviderIds"))

    private suspend fun fetchItemsArray(path: String, query: List<Pair<String, String?>>): List<JsonObject> =
        core.itemsArray(core.get(path, query).throwIfError().data)

    private companion object {
        const val TAG = "JellyfinSearch"
        const val CONCURRENCY = 3
        const val LIBRARY_LOOKUP_OPERATION = "Jellyfin library lookup"

        /** The title types a filmography lists, so a person search returns never opens an empty one. */
        const val PERSON_MEDIA_ITEM_TYPES = "Movie,Series"

        const val PEOPLE_SEARCH_CANDIDATE_LIMIT = 100

        /**
         * A library's types by kind: Emby takes 11–12 s on a large TV library once music types ride along, ~70 ms
         * without. Unknown kinds (mixed, books) keep the broad list.
         */
        fun searchItemTypes(kind: MediaKind) = when (kind) {
            MediaKind.MOVIE -> "Movie"
            MediaKind.SHOW -> "Series,Episode"
            // Home video and music video libraries.
            MediaKind.CLIP -> "Video,MusicVideo"
            else -> "Movie,Series,Episode,MusicAlbum,Audio"
        }
    }
}

package com.edde746.plezy.presentation.libraries

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.HubFetchDiagnostics
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.LibraryChangeEvent
import com.edde746.plezy.model.LibraryFilterResult
import com.edde746.plezy.model.LibraryGenre
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.LibraryQuery
import com.edde746.plezy.model.MediaHub
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.model.MediaPlaylist
import com.edde746.plezy.model.MediaSort
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.LibrariesFetcher
import com.edde746.plezy.servers.LibrariesStore
import com.edde746.plezy.servers.LibraryAggregationResult
import com.edde746.plezy.servers.LibraryPreferences
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.Flow

fun lib(id: String, kind: MediaKind = MediaKind.MOVIE, server: String = "s1", backend: BackendKind = BackendKind.JELLYFIN, shared: Boolean = false, title: String = id) =
    MediaLibrary(id = id, backend = backend, title = title, kind = kind, isShared = shared, serverId = server, serverName = "Server $server")

fun mediaItem(id: String, kind: MediaKind = MediaKind.MOVIE, server: String = "s1", backend: BackendKind = BackendKind.JELLYFIN) =
    MediaItem(id = id, backend = backend, kind = kind, title = id, serverId = server)

/**
 * A server answering a library's browse calls; each records its query in [queries]. [gate] holds page fetches open. A
 * name prefix keeps the [pageItems] whose title starts with it.
 */
class BrowseBackend(serverId: String = "s1", backend: BackendKind = BackendKind.JELLYFIN) : FakeMediaBackend(serverId, backend) {
    var pageItems: List<MediaItem> = emptyList()
    var sorts: List<MediaSort> = listOf(MediaSort("SortName", "Title"), MediaSort("DateCreated", "Date Added", defaultDirection = "desc"))
    var filters: LibraryFilterResult = LibraryFilterResult.EMPTY
    var pageFailure: Exception? = null
    var gate: CompletableDeferred<Unit>? = null
    var hubs: List<MediaHub> = emptyList()
    var hubsFailure: Exception? = null
    var genres: List<LibraryGenre> = emptyList()
    var collections: List<MediaItem> = emptyList()
    var playlists: List<MediaPlaylist> = emptyList()
    val queries = mutableListOf<LibraryQuery>()
    val sortTypes = mutableListOf<String?>()
    var hubCalls = 0

    override suspend fun fetchLibraryPagedContent(libraryId: String, query: LibraryQuery, libraryKind: MediaKind?): LibraryPage<MediaItem> {
        queries += query
        gate?.await()
        pageFailure?.let { throw it }
        val items = query.nameStartsWith?.let { prefix -> pageItems.filter { it.title?.startsWith(prefix, ignoreCase = true) == true } } ?: pageItems
        return LibraryPage(items.drop(query.offset).take(query.limit), items.size, query.offset)
    }

    override suspend fun fetchSortOptions(libraryId: String, libraryType: String?): List<MediaSort> {
        sortTypes += libraryType
        return sorts
    }

    /** Holds the filter fetch open; [filtersFailure] fails it. */
    var filtersGate: CompletableDeferred<Unit>? = null
    var filtersFailure: Exception? = null

    override suspend fun fetchLibraryFiltersWithValues(libraryId: String, libraryKind: MediaKind?): LibraryFilterResult {
        filtersGate?.await()
        filtersFailure?.let { throw it }
        return filters
    }

    override suspend fun fetchLibraryHubs(
        libraryId: String,
        libraryName: String,
        limit: Int,
        includePlaybackHubs: Boolean,
        libraryKind: MediaKind?,
        diagnostics: HubFetchDiagnostics?,
    ): List<MediaHub> {
        hubCalls++
        gate?.await()
        hubsFailure?.let { throw it }
        return hubs
    }

    override suspend fun fetchLibraryGenres(libraryId: String, libraryKind: MediaKind): List<LibraryGenre> = genres

    var rootFolders: List<MediaItem> = emptyList()

    /** A folder's children, delivered as these pages; a null page fails the listing there. */
    var folderPages: List<List<MediaItem>?> = emptyList()

    override suspend fun fetchLibraryFolders(libraryId: String, onPage: ((List<MediaItem>) -> Unit)?): List<MediaItem> = rootFolders

    override suspend fun fetchFolderChildren(folder: MediaItem, libraryId: String?, libraryTitle: String?, onPage: ((List<MediaItem>) -> Unit)?): List<MediaItem> {
        var shown = emptyList<MediaItem>()
        for (page in folderPages) {
            if (page == null) throw IllegalStateException("page failed")
            shown = shown + page
            onPage?.invoke(shown)
        }
        return shown
    }

    val adminCalls = mutableListOf<String>()
    var adminFailure: Exception? = null

    override suspend fun scanLibrary(libraryId: String) {
        adminCalls += "scan:$libraryId"
        adminFailure?.let { throw it }
    }

    override suspend fun refreshLibraryMetadata(libraryId: String) {
        adminCalls += "refresh:$libraryId"
        adminFailure?.let { throw it }
    }

    /** Each collections page asked for: the library, the start and the size; [collectionsFailure] fails them. */
    val collectionRequests = mutableListOf<Triple<String, Int?, Int?>>()
    var collectionsFailure: Exception? = null

    override suspend fun fetchCollectionsPage(libraryId: String, start: Int?, size: Int?): LibraryPage<MediaItem> {
        collectionRequests += Triple(libraryId, start, size)
        collectionsFailure?.let { throw it }
        val from = start ?: 0
        return LibraryPage(collections.drop(from).take(size ?: collections.size), collections.size, from)
    }

    /** Each playlists page asked for: the playlist type and the size. */
    val playlistRequests = mutableListOf<Pair<String, Int?>>()

    override suspend fun fetchPlaylistsPage(playlistType: String, smart: Boolean?, start: Int?, size: Int?): LibraryPage<MediaPlaylist> {
        playlistRequests += playlistType to size
        val from = start ?: 0
        val typed = playlists.filter { it.playlistType == playlistType }
        return LibraryPage(typed.drop(from).take(size ?: typed.size), typed.size, from)
    }
}

/** A library list over fixed [libraries], loaded at once. */
suspend fun loadedLibraries(prefs: LibraryPreferences, scope: CoroutineScope, events: Flow<LibraryChangeEvent>, libraries: () -> List<MediaLibrary>): LibrariesStore {
    val store = LibrariesStore(prefs, scope, events)
    store.initialize(
        LibrariesFetcher {
            val list = libraries()
            LibraryAggregationResult(list, list.mapNotNull { ServerId.tryParse(it.serverId) }.toSet(), emptySet(), emptySet())
        },
    )
    store.loadLibraries()
    return store
}

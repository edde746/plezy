package com.edde746.plezy.presentation.downloads

import com.edde746.plezy.downloads.DownloadedLibrary
import com.edde746.plezy.model.DOWNLOAD_FILTER_LIBRARY
import com.edde746.plezy.model.DOWNLOAD_FILTER_UNWATCHED
import com.edde746.plezy.model.LibraryFilter
import com.edde746.plezy.model.LibraryFilterOperator
import com.edde746.plezy.model.LibrarySortDirection
import com.edde746.plezy.model.MEDIA_SORT_KEY_TITLE
import com.edde746.plezy.model.MediaFilter
import com.edde746.plezy.model.MediaFilterType
import com.edde746.plezy.model.MediaFilterValue
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaItemSortExtras
import com.edde746.plezy.model.MediaSort
import com.edde746.plezy.model.clauseFor
import com.edde746.plezy.model.downloadItemMatchesFilters
import com.edde746.plezy.model.downloadLibraryFilterValue
import com.edde746.plezy.model.downloadSortOptions
import com.edde746.plezy.model.mediaItemSortComparator
import com.edde746.plezy.model.withField
import com.edde746.plezy.settings.LibraryPrefs
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/** How a downloads tab groups its items; [id] is the stored value. */
enum class DownloadsGrouping(val id: String) {
    SHOWS("shows"),
    SEASONS("seasons"),
    EPISODES("episodes"),
    MOVIES("movies"),
    ALBUMS("albums"),
    TRACKS("tracks"),
    COLLECTIONS("collections"),
    LIBRARY("library"),
    ;

    val label: String
        get() = when (this) {
            SHOWS -> T.libraries.groupings.shows
            SEASONS -> T.libraries.groupings.seasons
            EPISODES -> T.libraries.groupings.episodes
            MOVIES -> T.libraries.groupings.movies
            ALBUMS -> T.libraries.groupings.albums
            TRACKS -> T.libraries.groupings.tracks
            COLLECTIONS -> T.downloads.groupings.collections
            LIBRARY -> T.downloads.groupings.library
        }

    companion object {
        fun of(id: String?): DownloadsGrouping? = entries.firstOrNull { it.id == id }
    }
}

/**
 * The Downloads screen's tabs. A content tab keeps its grouping, sort and filters under [sectionId] (the library
 * preferences' section); [groupings] are its choices, the first the default.
 */
enum class DownloadsTab(val sectionId: String?, val groupings: List<DownloadsGrouping>) {
    MANAGE(null, emptyList()),
    TV_SHOWS(
        "downloads:tv",
        listOf(DownloadsGrouping.SHOWS, DownloadsGrouping.SEASONS, DownloadsGrouping.EPISODES, DownloadsGrouping.COLLECTIONS, DownloadsGrouping.LIBRARY),
    ),
    MOVIES("downloads:movies", listOf(DownloadsGrouping.MOVIES, DownloadsGrouping.COLLECTIONS, DownloadsGrouping.LIBRARY)),
    MUSIC("downloads:music", listOf(DownloadsGrouping.ALBUMS, DownloadsGrouping.TRACKS, DownloadsGrouping.LIBRARY)),
    ;

    val label: String
        get() = when (this) {
            MANAGE -> T.downloads.manage
            TV_SHOWS -> T.downloads.tvShows
            MOVIES -> T.downloads.movies
            MUSIC -> T.downloads.music
        }
}

/** A content tab's choices. [sort] null: the items' own order. */
data class DownloadsOptionsState(
    val grouping: DownloadsGrouping,
    val sort: MediaSort? = null,
    val sortDescending: Boolean = false,
    val filters: List<LibraryFilter> = emptyList(),
) {
    /** Whether a filter is on: an empty result then offers to reset the filters instead of saying there's nothing. */
    val hasActiveFilters: Boolean get() = filters.isNotEmpty()

    val filtersLabel: String get() = if (filters.isEmpty()) T.libraries.filters else T.libraries.filtersWithCount(filters.size.toString())

    val sortLabel: String get() = sort?.title ?: T.libraries.sort

    /** The Unwatched filter: null while off, true for unwatched titles only, false for watched ones only (negated). */
    val unwatchedFilter: Boolean? get() = filters.clauseFor(DOWNLOAD_FILTER_UNWATCHED)?.let { !it.op.isNegated }

    /** The Library filter's clause: its `serverId:libraryId` values (any of them matches), excluded when negated. */
    val libraryFilter: LibraryFilter? get() = filters.clauseFor(DOWNLOAD_FILTER_LIBRARY)

    /**
     * What [filter] is set to, for its row in the filters list: Yes or No for Unwatched; the chosen libraries' names
     * from [libraryValues] ("Not …" when excluded), or their count while a value isn't listed. Null while off.
     */
    fun filterSummary(filter: MediaFilter, libraryValues: List<MediaFilterValue>): String? {
        val clause = filters.clauseFor(filter.filter) ?: return null
        if (filter.isBoolean) return if (clause.op.isNegated) T.libraries.advancedFilters.no else T.libraries.advancedFilters.yes
        val names = clause.values.map { value -> libraryValues.firstOrNull { it.key == value }?.title }
        if (names.any { it == null }) {
            val count = clause.values.size.toString()
            return if (clause.op.isNegated) T.libraries.advancedFilters.valueCountExcluded(count) else T.libraries.advancedFilters.valueCount(count)
        }
        val joined = names.joinToString(", ")
        return if (clause.op.isNegated) T.libraries.advancedFilters.not(joined) else joined
    }
}

/**
 * A downloads content tab's grouping, sort and filters ([state]), restored from and saved to [prefs] under the tab's
 * section. Filters keep only the downloads' fields (unwatched, library) and never take the legacy shared library
 * filters; a stored library value is kept even before the downloads load (it then matches nothing until cleared).
 *
 * Call everything on the main thread.
 */
class DownloadsTabOptions(val tab: DownloadsTab, private val prefs: LibraryPrefs, private val scope: CoroutineScope) {
    private val sectionId = requireNotNull(tab.sectionId) { "$tab has no options" }
    private val mutableState = MutableStateFlow(DownloadsOptionsState(tab.groupings.first()))
    val state: StateFlow<DownloadsOptionsState> = mutableState.asStateFlow()

    /** The sorts on offer. */
    val sortOptions: List<MediaSort> = downloadSortOptions(includeDownloadFields = true)

    /** The filter categories on offer: Unwatched (a toggle) and Library (values from [libraryFilterValues]). */
    val filterDefinitions: List<MediaFilter>
        get() = listOf(
            MediaFilter(DOWNLOAD_FILTER_UNWATCHED, T.libraries.filterCategories.unwatched, MediaFilterType.BOOLEAN, key = DOWNLOAD_FILTER_UNWATCHED),
            MediaFilter(DOWNLOAD_FILTER_LIBRARY, T.downloads.groupings.library, MediaFilterType.TAG, key = DOWNLOAD_FILTER_LIBRARY),
        )

    /** Done once the stored choices are read. */
    val restored: Job = scope.launch { restore() }

    /** The last save; each save waits for the one before, so the stored choices end as the last ones made. */
    private var lastSave: Job = restored

    private fun save(write: suspend () -> Unit) {
        val previous = lastSave
        lastSave = scope.launch {
            previous.join()
            write()
        }
    }

    /** Waits until every choice made so far is stored. */
    suspend fun awaitSaved() = lastSave.join()

    private suspend fun restore() {
        val grouping = DownloadsGrouping.of(prefs.grouping(sectionId))?.takeIf { it in tab.groupings }
        val stored = prefs.sort(sectionId)
        val sort = stored?.let { s -> sortOptions.firstOrNull { it.key == s.field } }
        val filters = prefs.filters(sectionId, legacyGlobalFallback = false)
            .filter { it.field == DOWNLOAD_FILTER_UNWATCHED || it.field == DOWNLOAD_FILTER_LIBRARY }
        mutableState.value = mutableState.value.copy(
            grouping = grouping ?: mutableState.value.grouping,
            sort = sort,
            sortDescending = sort != null && stored?.direction == LibrarySortDirection.DESCENDING,
            filters = filters,
        )
    }

    fun selectGrouping(grouping: DownloadsGrouping) {
        if (grouping == mutableState.value.grouping || grouping !in tab.groupings) return
        mutableState.value = mutableState.value.copy(grouping = grouping)
        save { prefs.setGrouping(sectionId, grouping.id) }
    }

    /** Picks [sort]: the active one turns around, another starts in its own default direction. */
    fun selectSort(sort: MediaSort) {
        val current = mutableState.value
        val descending = if (current.sort?.key == sort.key) !current.sortDescending else sort.isDefaultDescending
        setSort(sort, descending)
    }

    fun setSort(sort: MediaSort, descending: Boolean) {
        val current = mutableState.value
        if (current.sort?.key == sort.key && current.sortDescending == descending) return
        mutableState.value = current.copy(sort = sort, sortDescending = descending)
        save { prefs.setSort(sectionId, sort.key, descending) }
    }

    /** Back to the items' own order; the stored sort goes too, so it can't come back. */
    fun clearSort() {
        mutableState.value = mutableState.value.copy(sort = null, sortDescending = false)
        save { prefs.clearSort(sectionId) }
    }

    fun setFilters(filters: List<LibraryFilter>) {
        if (filters == mutableState.value.filters) return
        mutableState.value = mutableState.value.copy(filters = filters.toList())
        save { prefs.setFilters(filters, sectionId) }
    }

    /** The filtered-empty state's action, and the filters' Clear all. */
    fun resetFilters() = setFilters(emptyList())

    /** Sets the Unwatched filter ([DownloadsOptionsState.unwatchedFilter]); null turns it off. */
    fun setUnwatchedFilter(value: Boolean?) {
        val op = if (value == false) LibraryFilterOperator.IS_NOT else LibraryFilterOperator.IS
        setField(DOWNLOAD_FILTER_UNWATCHED, if (value == null) emptyList() else listOf(LibraryFilter(DOWNLOAD_FILTER_UNWATCHED, listOf("1"), op)))
    }

    /** Adds the library [value] (`serverId:libraryId`) to the Library filter, or takes it out; the last one out turns it off. */
    fun toggleLibraryFilterValue(value: String) {
        val clause = mutableState.value.libraryFilter
        val values = clause?.values.orEmpty().let { if (value in it) it - value else it + value }
        setLibraryValues(values, clause?.op ?: LibraryFilterOperator.IS)
    }

    /** Whether the Library filter's values are excluded rather than kept; nothing to store while none is chosen. */
    fun setLibraryFilterExcluded(excluded: Boolean) {
        val clause = mutableState.value.libraryFilter ?: return
        setLibraryValues(clause.values, if (excluded) LibraryFilterOperator.IS_NOT else LibraryFilterOperator.IS)
    }

    /** The Library filter's "All": off. */
    fun clearLibraryFilter() = setField(DOWNLOAD_FILTER_LIBRARY, emptyList())

    private fun setLibraryValues(values: List<String>, op: LibraryFilterOperator) =
        setField(DOWNLOAD_FILTER_LIBRARY, if (values.isEmpty()) emptyList() else listOf(LibraryFilter(DOWNLOAD_FILTER_LIBRARY, values, op)))

    private fun setField(field: String, clauses: List<LibraryFilter>) = setFilters(mutableState.value.filters.withField(field, clauses))

    /**
     * [items] filtered then sorted by the current choices. [extras] gives the download date and size of each item
     * (keyed by global key; containers aggregate their completed downloads).
     */
    fun apply(items: List<MediaItem>, extras: (List<MediaItem>) -> Map<String, MediaItemSortExtras>): List<MediaItem> {
        val current = mutableState.value
        val filtered = if (current.filters.isEmpty()) items else items.filter { downloadItemMatchesFilters(it, current.filters) }
        val sort = current.sort ?: return filtered
        val byKey = extras(filtered)
        return filtered.sortedWith(mediaItemSortComparator(sort.key, current.sortDescending) { byKey[it.globalKey] ?: MediaItemSortExtras() })
    }

    /** [grouped] (collections folded into folders); under the title sort a folder files by its own title. */
    fun sortFolders(items: List<MediaItem>, grouped: List<MediaItem>): List<MediaItem> {
        val current = mutableState.value
        if (current.sort?.key != MEDIA_SORT_KEY_TITLE || grouped === items) return grouped
        return grouped.sortedWith(mediaItemSortComparator(MEDIA_SORT_KEY_TITLE, current.sortDescending))
    }
}

/**
 * The library filter's values: each library holding downloads, the server name added when several servers hold
 * them. A server's downloads without a library are titled by the server's name ([serverNameOf], which answers the id
 * itself for an unknown server).
 */
fun libraryFilterValues(libraries: List<DownloadedLibrary>, serverNameOf: (String) -> String): List<MediaFilterValue> {
    val multiServer = libraries.map { it.serverId }.toSet().size > 1
    return libraries.map { library ->
        val serverName = serverNameOf(library.serverId)
        val title = if (library.libraryId == null && serverName != library.serverId) serverName else library.title
        MediaFilterValue(
            key = downloadLibraryFilterValue(library.serverId, library.libraryId),
            title = if (multiServer && title != serverName) "$title ($serverName)" else title,
        )
    }
}

/**
 * One `serverId:libraryId` bucket of the library grouping. [title] is the library's name, the server's for downloads
 * without a library, or the unknown-library fallback; [subtitle] names the server when several servers hold downloads.
 */
data class DownloadsLibrarySection(val key: String, val title: String, val subtitle: String?, val items: List<MediaItem>)

/** [items] in library sections by title (then key); [serverNameOf] names a server when an item doesn't. */
fun bucketDownloadsByLibrary(items: List<MediaItem>, serverNameOf: (String) -> String?): List<DownloadsLibrarySection> {
    val buckets = LinkedHashMap<String, MutableList<MediaItem>>()
    for (item in items) buckets.getOrPut(downloadLibraryFilterValue(item.serverId, item.libraryId)) { mutableListOf() } += item
    val multiServer = items.mapNotNull { it.serverId }.toSet().size > 1
    return buckets.map { (key, bucket) ->
        val first = bucket.first()
        val libraryTitle = bucket.firstNotNullOfOrNull { it.libraryTitle }
        val serverName = first.serverId?.let { first.serverName ?: serverNameOf(it) }
        DownloadsLibrarySection(
            key = key,
            title = libraryTitle ?: serverName ?: T.downloads.unknownLibrary,
            subtitle = if (multiServer && libraryTitle != null) serverName else null,
            items = bucket,
        )
    }.sortedWith(compareBy<DownloadsLibrarySection> { it.title.lowercase() }.thenBy { it.key })
}

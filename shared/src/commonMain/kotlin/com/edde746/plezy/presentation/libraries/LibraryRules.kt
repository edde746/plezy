package com.edde746.plezy.presentation.libraries

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.LibraryFirstCharacter
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.ducetCompare
import com.edde746.plezy.model.groupLibrariesByFirstAppearance
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.strings.T

/** A library's sub-tab, in display order; [key] is what `library_tab_<globalKey>` stores. */
enum class LibraryTab(val key: String) {
    RECOMMENDED("recommended"),
    BROWSE("browse"),
    COLLECTIONS("collections"),
    PLAYLISTS("playlists"),
    GENRES("genres"),
    ;

    val label: String
        get() = when (this) {
            RECOMMENDED -> T.libraries.tabs.recommended
            BROWSE -> T.libraries.tabs.browse
            COLLECTIONS -> T.libraries.tabs.collections
            PLAYLISTS -> T.libraries.tabs.playlists
            GENRES -> T.libraries.tabs.genres
        }

    companion object {
        /** The tab a stored value names; anything else (the tab indexes of older releases) is none. */
        fun of(key: String?): LibraryTab? = entries.firstOrNull { it.key == key }
    }
}

/**
 * The tabs [library] shows: a shared library only Browse and Playlists; Genres only for movie and show libraries, the
 * kinds both backends tag with genres.
 */
fun visibleLibraryTabs(library: MediaLibrary): List<LibraryTab> {
    if (library.isShared) return listOf(LibraryTab.BROWSE, LibraryTab.PLAYLISTS)
    val genres = library.kind == MediaKind.MOVIE || library.kind == MediaKind.SHOW
    return LibraryTab.entries.filter { it != LibraryTab.GENRES || genres }
}

/** How Browse groups a library's items; [key] is what `library_grouping_<globalKey>` stores. */
enum class BrowseGrouping(val key: String, internal val plexType: Int?) {
    ALL("all", null),
    MOVIES("movies", 1),
    SHOWS("shows", 2),
    SEASONS("seasons", 3),
    EPISODES("episodes", 4),
    ARTISTS("artists", 8),
    ALBUMS("albums", 9),
    TRACKS("tracks", 10),
    FOLDERS("folders", null),
    ;

    val label: String
        get() = when (this) {
            ALL -> T.libraries.groupings.all
            MOVIES -> T.libraries.groupings.movies
            SHOWS -> T.libraries.groupings.shows
            SEASONS -> T.libraries.groupings.seasons
            EPISODES -> T.libraries.groupings.episodes
            ARTISTS -> T.libraries.groupings.artists
            ALBUMS -> T.libraries.groupings.albums
            TRACKS -> T.libraries.groupings.tracks
            FOLDERS -> T.libraries.groupings.folders
        }

    /** A music grouping: square cells, artists drawn round. */
    val isMusic: Boolean get() = this == ARTISTS || this == ALBUMS || this == TRACKS

    companion object {
        fun of(key: String?): BrowseGrouping? = entries.firstOrNull { it.key == key }
    }
}

/**
 * The groupings Browse offers for [library]. Folders only where the server can group by folder and the library isn't
 * shared.
 */
fun browseGroupingOptions(library: MediaLibrary, canGroupByFolders: Boolean): List<BrowseGrouping> {
    if (library.isShared) {
        return listOf(BrowseGrouping.ALL, BrowseGrouping.MOVIES, BrowseGrouping.SHOWS, BrowseGrouping.SEASONS, BrowseGrouping.EPISODES)
    }
    val own = when (library.kind) {
        MediaKind.SHOW -> listOf(BrowseGrouping.SHOWS, BrowseGrouping.SEASONS, BrowseGrouping.EPISODES)
        MediaKind.MOVIE -> listOf(BrowseGrouping.MOVIES)
        MediaKind.ARTIST -> listOf(BrowseGrouping.ARTISTS, BrowseGrouping.ALBUMS, BrowseGrouping.TRACKS)
        else -> listOf(BrowseGrouping.ALL)
    }
    return if (canGroupByFolders) own + BrowseGrouping.FOLDERS else own
}

/** The grouping [library] opens with when none is saved; home-video libraries open by folders, as servers keep them. */
fun defaultBrowseGrouping(library: MediaLibrary, canGroupByFolders: Boolean): BrowseGrouping {
    if (library.isShared) return BrowseGrouping.ALL
    return when (library.kind) {
        MediaKind.SHOW -> BrowseGrouping.SHOWS
        MediaKind.MOVIE -> BrowseGrouping.MOVIES
        MediaKind.ARTIST -> BrowseGrouping.ARTISTS
        MediaKind.CLIP -> if (canGroupByFolders) BrowseGrouping.FOLDERS else BrowseGrouping.ALL
        else -> BrowseGrouping.ALL
    }
}

/** [saved] when [library] still offers it, else the default, else the first option. */
fun normalizeBrowseGrouping(library: MediaLibrary, saved: String?, canGroupByFolders: Boolean): BrowseGrouping {
    val options = browseGroupingOptions(library, canGroupByFolders)
    BrowseGrouping.of(saved)?.takeIf { it in options }?.let { return it }
    val fallback = defaultBrowseGrouping(library, canGroupByFolders)
    return if (fallback in options) fallback else options.first()
}

/** Whether Shuffle library is offered: own (not shared) video and music libraries. */
fun canShuffleLibrary(library: MediaLibrary): Boolean {
    if (library.isShared) return false
    return when (library.kind) {
        MediaKind.MOVIE, MediaKind.SHOW, MediaKind.CLIP, MediaKind.ARTIST -> true
        else -> library.defaultBrowseKinds.any { it == MediaKind.MOVIE || it == MediaKind.SHOW }
    }
}

/** Whether [libraries] come from more than one server. */
fun librariesSpanMultipleServers(libraries: List<MediaLibrary>): Boolean = libraries.mapNotNullTo(HashSet()) { it.serverId }.size > 1

/** One entry of a library list (the dropdown, the quick picker, the rail). */
sealed interface LibraryListEntry {
    /** A server's header over its libraries. */
    data class Header(val serverId: String, val serverName: String, val backend: BackendKind) : LibraryListEntry

    /** A library; [showServerName] puts its server under its title. */
    data class Row(val library: MediaLibrary, val showServerName: Boolean) : LibraryListEntry
}

/**
 * [libraries] as a list shows them: under per-server headers (in order of first appearance) when [groupByServer] is on
 * and they span several servers; else flat, each row naming its server while several are shown.
 */
fun libraryListEntries(libraries: List<MediaLibrary>, groupByServer: Boolean): List<LibraryListEntry> {
    val multiple = librariesSpanMultipleServers(libraries)
    if (!groupByServer || !multiple) return libraries.map { LibraryListEntry.Row(it, multiple && it.serverName != null) }
    val grouped = groupLibrariesByFirstAppearance(libraries)
    return grouped.serverOrder.flatMap { server ->
        val bucket = grouped.byServer.getValue(server)
        val header = if (server.isEmpty()) {
            emptyList()
        } else {
            listOf(LibraryListEntry.Header(server, bucket.first().serverName ?: server, bucket.first().backend))
        }
        header + bucket.map { LibraryListEntry.Row(it, showServerName = false) }
    }
}

/**
 * [sheetOrder] (the Manage libraries sheet's order) over [current], the libraries loaded now: the sheet's libraries
 * that still exist in its order, then those loaded since in theirs.
 */
fun reconcileLibraryOrder(sheetOrder: List<MediaLibrary>, current: List<MediaLibrary>): List<MediaLibrary> {
    val byKey = LinkedHashMap<String, MediaLibrary>().apply { current.forEach { put(it.globalKey, it) } }
    return sheetOrder.mapNotNull { byKey.remove(it.globalKey) } + byKey.values
}

/**
 * The alphabet jump bar's letters: each letter with items (upper-cased) in the collation the servers sort titles by,
 * reversed for a descending title sort, mapped to the index its items start at.
 */
class AlphaJump(firstCharacters: List<LibraryFirstCharacter>, descending: Boolean = false) {
    val letters: List<String>
    private val starts: Map<String, Int>
    private val sizes: Map<String, Int>

    init {
        val entries = firstCharacters.filter { it.size > 0 }.map { it.title.uppercase() to it.size }
            .sortedWith { a, b -> ducetCompare(a.first, b.first) }
            .let { if (descending) it.reversed() else it }
        val starts = LinkedHashMap<String, Int>()
        var cumulative = 0
        for ((letter, size) in entries) {
            starts[letter] = cumulative
            cumulative += size
        }
        letters = starts.keys.toList()
        this.starts = starts
        sizes = entries.toMap()
    }

    /** The index [letter]'s items start at, or null. */
    fun indexFor(letter: String): Int? = starts[letter]

    /** The letter the item at [index] falls under; `#` without letters. */
    fun letterAt(index: Int): String {
        if (letters.isEmpty()) return "#"
        return letters.lastOrNull { starts.getValue(it) <= index } ?: letters.first()
    }

    /**
     * At most [maxCount] letters, in order: those with the most items; where every letter is as full (Jellyfin's and
     * Emby's, which have no counts), spread evenly from the first to the last.
     */
    fun displayLetters(maxCount: Int): List<String> {
        if (maxCount >= letters.size) return letters
        if (maxCount <= 0) return emptyList()
        if (maxCount == 1) return letters.take(1)
        if (sizes.values.toSet().size == 1) {
            val last = letters.lastIndex
            return List(maxCount) { letters[(it * last + (maxCount - 1) / 2) / (maxCount - 1)] }
        }
        return letters.indices.sortedByDescending { sizes[letters[it]] ?: 0 }.take(maxCount).sorted().map { letters[it] }
    }

    /**
     * The bar's rows for at most [count] rows of one height, in order, every letter in exactly one: a letter each where
     * all fit; else the letters [displayLetters] keeps each alone, and each run of letters between them in one row
     * (drawn as a dot), as many kept as leave a row for every run. A bar of one row is one run. They depend on the
     * letters and the room alone, so a pick never moves a row. [alphaLetterDown] finds the letter at a point down them,
     * so a drag along the bar reaches every letter.
     */
    fun rows(count: Int): List<List<String>> {
        if (count >= letters.size) return letters.map { listOf(it) }
        for (kept in count downTo 2) {
            val shown = displayLetters(kept).toSet()
            val rows = mutableListOf<List<String>>()
            var run = mutableListOf<String>()
            for (letter in letters) {
                if (letter !in shown) {
                    run += letter
                    continue
                }
                if (run.isNotEmpty()) rows += run.also { run = mutableListOf() }
                rows += listOf(letter)
            }
            if (run.isNotEmpty()) rows += run
            if (rows.size <= count) return rows
        }
        return listOf(letters)
    }

    companion object {
        /** Jellyfin's and Emby's bar: `#` and A–Z, which filter by name prefix (they have no per-letter counts). */
        val MEDIA_BROWSER_ALPHABET: List<LibraryFirstCharacter> =
            (listOf("#") + ('A'..'Z').map { it.toString() }).map { LibraryFirstCharacter(it, it, 1) }
    }
}

/**
 * The letter at [fraction] of the way down a bar of [rows] ([AlphaJump.rows]) of one height, 0 its top, 1 its bottom:
 * the row there, and in a run's row the letter at the same share of the row, so a drag down the bar crosses every letter.
 */
fun alphaLetterDown(rows: List<List<String>>, fraction: Double): String {
    val at = fraction.coerceIn(0.0, 1.0) * rows.size
    val row = at.toInt().coerceAtMost(rows.lastIndex)
    val letters = rows[row]
    return letters[((at - row) * letters.size).toInt().coerceIn(0, letters.lastIndex)]
}

/** Whether [sortKey] (a sort's key) descending sorts by title: the alphabet then runs Z to A. */
fun isTitleSortDescending(sortKey: String?, descending: Boolean): Boolean {
    if (!descending || sortKey == null) return false
    val key = sortKey.lowercase()
    return key == "title" || key == "name" || key == "sortname" || key.startsWith("titlesort")
}

/** Browse's page size: 200 on Plex, 72 on Jellyfin and Emby. */
fun browseFetchSize(backend: BackendKind): Int = if (backend == BackendKind.PLEX) 200 else 72

/**
 * Browse's first page: (visible rows + 1) × columns × 3 within 100–500 on Plex, × 2 within 36–72 on Jellyfin and
 * Emby; the fetch size without a layout yet.
 */
fun initialBrowseFetchSize(backend: BackendKind, visibleRows: Int, columns: Int): Int {
    if (visibleRows <= 0 || columns <= 0) return browseFetchSize(backend)
    val cells = (visibleRows + 1) * columns
    return if (backend == BackendKind.PLEX) (cells * 3).coerceIn(100, 500) else (cells * 2).coerceIn(36, 72)
}

/**
 * The screen a tap on [item] opens: an episode its show, at its season and on it; a collection its own screen; a music
 * artist or album its music screen; anything else its detail, seeded with [item]. Null for an item without a server.
 */
fun detailRouteFor(item: MediaItem): Route? {
    val serverId = ServerId.tryParse(item.serverId) ?: return null
    return when (item.kind) {
        MediaKind.COLLECTION -> Route.CollectionDetail(serverId, item.id)
        MediaKind.ARTIST -> Route.MusicArtist(serverId.value, item.id)
        MediaKind.ALBUM -> Route.MusicAlbum(serverId.value, item.id)
        MediaKind.EPISODE -> {
            val show = item.grandparentId ?: return Route.MediaDetail(serverId, item.id).seeded(item)
            Route.MediaDetail(serverId, show, initialSeasonId = item.parentId, initialEpisodeId = item.id)
        }
        else -> Route.MediaDetail(serverId, item.id).seeded(item)
    }
}

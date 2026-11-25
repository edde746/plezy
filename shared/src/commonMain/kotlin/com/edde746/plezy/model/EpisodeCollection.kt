package com.edde746.plezy.model

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.SeasonEpisodePaging

/** Where Specials (season 0) go in a show's episode order. [id] is persisted. */
enum class SpecialsOrdering(val id: String) {
    /**
     * The backend's own order, in the queue its own web client plays: Plex's queue for the episode played, from that
     * episode on, which Plex orders by air date (a Special between the episodes it aired between); Jellyfin's and Emby's
     * episode order as the server lists it (Specials it doesn't place in a season first), Jellyfin's starting at the
     * episode played and Emby's at a show's Play's episode. Client-side selections with no server order (offline queue,
     * downloads, offline On Deck) put Specials last.
     */
    RESPECT_SERVER("respectServer"),

    /** Specials between regular episodes by air date, everywhere. */
    AIR_DATE("airDate"),

    /** Specials strictly after the regular seasons, everywhere; on Plex from a queue built here, not the server's. */
    SPECIALS_LAST("specialsLast"),
    ;

    companion object {
        fun fromId(id: String?): SpecialsOrdering? = entries.firstOrNull { it.id == id }
    }
}

/** Season number 0, or none, is the Specials folder. */
fun isSpecialSeasonNumber(seasonNumber: Int?): Boolean = (seasonNumber ?: 0) == 0

/**
 * Every episode below a show or season, in watch order, from one [MediaBackend.fetchPlayableDescendants] call (not
 * capped by a page size). Other kinds are dropped, Specials too unless [includeSpecials], and watched episodes with
 * [unwatchedOnly]. Server, library, season and show fields an episode lacks come from [fallback]. Failures propagate,
 * so download and sync transactions can surface or roll back the operation.
 */
suspend fun collectEpisodes(
    backend: MediaBackend,
    parentId: String,
    unwatchedOnly: Boolean,
    ordering: SpecialsOrdering,
    fallback: MediaItem? = null,
    includeSpecials: Boolean = true,
): List<MediaItem> {
    // The backend returns raw container order (Plex puts S00 first); sorting this call's episodes means a "next N"
    // cut takes the episodes meant to be watched next, never the whole Specials folder.
    val collected = backend.fetchPlayableDescendants(parentId).filter { episode ->
        episode.kind == MediaKind.EPISODE &&
            (includeSpecials || !isSpecialSeasonNumber(episode.parentIndex)) &&
            (!unwatchedOnly || episode.isUnwatchedOrInProgress)
    }.map { it.withFallbackLibrary(fallback) }
    return sortEpisodesByWatchOrder(collected, ordering)
}

/**
 * The playable leaves of a list, in list order: movies, episodes and tracks as they are; shows and seasons expanded to
 * their episodes ([collectEpisodes]); albums and artists to their tracks. Clips, nested collections and playlists, and
 * unknown kinds are skipped. [unwatchedOnly] applies the same played-state filter to every kind. "Download this list"
 * and the sync rule keeping a list downloaded both expand a list with this.
 */
suspend fun collectListLeaves(
    backend: MediaBackend,
    items: List<MediaItem>,
    unwatchedOnly: Boolean,
    ordering: SpecialsOrdering,
): List<MediaItem> {
    val out = mutableListOf<MediaItem>()
    for (item in items) {
        when (item.kind) {
            MediaKind.MOVIE, MediaKind.EPISODE, MediaKind.TRACK ->
                if (!unwatchedOnly || item.isUnwatchedOrInProgress) out += item
            MediaKind.SHOW, MediaKind.SEASON ->
                out += collectEpisodes(backend, item.id, unwatchedOnly, ordering, fallback = item)
            MediaKind.ALBUM, MediaKind.ARTIST ->
                out += backend.fetchPlayableDescendants(item.id).filter { !unwatchedOnly || it.isUnwatchedOrInProgress }
            else -> Unit
        }
    }
    return out
}

/** A season's first episode, from a one-item page; null when the page holds none. */
suspend fun fetchFirstEpisodeForSeason(backend: MediaBackend, seasonId: String, seriesId: String? = null): MediaItem? =
    fetchSeasonPage(backend, seasonId, seriesId, start = 0, size = 1).items.firstOrNull { it.kind == MediaKind.EPISODE }

/** A page of a season's episodes, normalized by [normalizeSeasonEpisodes]. */
suspend fun fetchSeasonEpisodePage(backend: MediaBackend, show: MediaItem, season: MediaItem, start: Int, size: Int): LibraryPage<MediaItem> {
    val page = fetchSeasonPage(backend, season.id, show.id, start, size)
    return LibraryPage(normalizeSeasonEpisodes(page.items, show, season), page.totalCount, page.offset)
}

/** With a series id, a backend that pages seasons itself does ([SeasonEpisodePaging]); else the season's children. */
private suspend fun fetchSeasonPage(backend: MediaBackend, seasonId: String, seriesId: String?, start: Int, size: Int): LibraryPage<MediaItem> {
    if (seriesId != null && backend is SeasonEpisodePaging) return backend.fetchSeasonEpisodesPage(seriesId, seasonId, start, size)
    return backend.fetchChildrenPage(seasonId, start, size)
}

/**
 * The first regular season's index (not Specials), else the first season's, else 0: where a show opens when nothing
 * says otherwise.
 */
fun defaultPlaybackSeasonIndex(seasons: List<MediaItem>): Int {
    val regular = seasons.indexOfFirst { it.kind == MediaKind.SEASON && !isSpecialSeasonNumber(it.index) }
    if (regular != -1) return regular
    val first = seasons.indexOfFirst { it.kind == MediaKind.SEASON }
    return if (first == -1) 0 else first
}

/** The row at [defaultPlaybackSeasonIndex] when it is a season. */
fun defaultPlaybackSeason(seasons: List<MediaItem>): MediaItem? =
    seasons.getOrNull(defaultPlaybackSeasonIndex(seasons))?.takeIf { it.kind == MediaKind.SEASON }

/**
 * The first season with unwatched episodes, from its leaf counts (no episode fetch): a regular season first, Specials
 * only when no regular one is left. Null when every season is watched or none has counts.
 */
fun firstUnwatchedSeasonIndex(seasons: List<MediaItem>): Int? {
    var firstSpecial: Int? = null
    for ((index, season) in seasons.withIndex()) {
        if (season.kind != MediaKind.SEASON || season.leafWatchTotal == null || season.isWatched) continue
        if (!isSpecialSeasonNumber(season.index)) return index
        if (firstSpecial == null) firstSpecial = index
    }
    return firstSpecial
}

/** The first episode, in list order, that is unwatched or in progress. */
fun firstUnwatchedEpisode(episodes: List<MediaItem>): MediaItem? =
    episodes.firstOrNull { it.kind == MediaKind.EPISODE && it.isUnwatchedOrInProgress }

/**
 * Aired watch order: by air date (`YYYY-MM-DD`, so the string order is chronological), a Special between the regular
 * episodes it aired between. Undated episodes follow dated ones; ties and undated pairs fall back to
 * [compareEpisodesSpecialsLast], so Specials are never front-loaded.
 */
fun compareEpisodesByWatchOrder(a: MediaItem, b: MediaItem): Int {
    val aDate = a.originallyAvailableAt?.takeIf { it.isNotEmpty() }
    val bDate = b.originallyAvailableAt?.takeIf { it.isNotEmpty() }
    when {
        aDate != null && bDate != null -> aDate.compareTo(bDate).let { if (it != 0) return it }
        aDate == null && bDate != null -> return 1
        aDate != null && bDate == null -> return -1
    }
    return compareEpisodesSpecialsLast(a, b)
}

/** Specials after the regular seasons, then season, episode (missing = 0) and id, so ties are deterministic. */
fun compareEpisodesSpecialsLast(a: MediaItem, b: MediaItem): Int {
    val aSpecial = isSpecialSeasonNumber(a.parentIndex)
    val bSpecial = isSpecialSeasonNumber(b.parentIndex)
    if (aSpecial != bSpecial) return if (aSpecial) 1 else -1
    val season = (a.parentIndex ?: 0).compareTo(b.parentIndex ?: 0)
    if (season != 0) return season
    val episode = (a.index ?: 0).compareTo(b.index ?: 0)
    if (episode != 0) return episode
    return a.id.compareTo(b.id)
}

/**
 * [episodes] in the client-side watch order (offline queue, offline On Deck, "download / sync next N"):
 * [SpecialsOrdering.AIR_DATE] by [compareEpisodesByWatchOrder]; [SpecialsOrdering.SPECIALS_LAST] and
 * [SpecialsOrdering.RESPECT_SERVER], which has no server order here to respect, by [compareEpisodesSpecialsLast].
 */
fun sortEpisodesByWatchOrder(episodes: List<MediaItem>, ordering: SpecialsOrdering): List<MediaItem> =
    episodes.sortedWith(
        if (ordering == SpecialsOrdering.AIR_DATE) Comparator(::compareEpisodesByWatchOrder) else Comparator(::compareEpisodesSpecialsLast),
    )

/**
 * The first item after [currentIndex] that plays another file than the current one. A multi-episode file
 * (`S02E24-E25.mkv`) is one item per episode, and advancing to a sibling would replay the file. Items without
 * file paths never share one, so this is plain adjacency for them.
 */
fun nextEpisodeSkippingSameFile(ordered: List<MediaItem>, currentIndex: Int): MediaItem? {
    val current = ordered[currentIndex]
    for (i in currentIndex + 1 until ordered.size) {
        if (!current.sharesFileWith(ordered[i])) return ordered[i]
    }
    return null
}

/** The first earlier item playing another file, moved back to the first item of that file's group. */
fun previousEpisodeSkippingSameFile(ordered: List<MediaItem>, currentIndex: Int): MediaItem? {
    val current = ordered[currentIndex]
    for (i in currentIndex - 1 downTo 0) {
        val candidate = ordered[i]
        if (current.sharesFileWith(candidate)) continue
        var head = i
        while (head > 0 && candidate.sharesFileWith(ordered[head - 1])) head--
        return ordered[head]
    }
    return null
}

/**
 * The season a show opens on: the one [initialSeasonId] or [initialSeasonIndex] names, else the on-deck episode's (by
 * season id, then number), else [firstUnwatchedSeasonIndex] (a partly watched show off Continue Watching still opens
 * where the viewer is), else [defaultPlaybackSeasonIndex]. 0 for no seasons.
 */
fun preferredSeasonIndex(
    seasons: List<MediaItem>,
    initialSeasonId: String? = null,
    initialSeasonIndex: Int? = null,
    onDeckEpisode: MediaItem? = null,
): Int {
    if (seasons.isEmpty()) return 0
    fun seasonWhere(predicate: (MediaItem) -> Boolean): Int? =
        seasons.indexOfFirst { it.kind == MediaKind.SEASON && predicate(it) }.takeIf { it != -1 }

    initialSeasonId?.let { id -> seasonWhere { it.id == id }?.let { return it } }
    initialSeasonIndex?.let { number -> seasonWhere { it.index == number }?.let { return it } }
    onDeckEpisode?.parentId?.let { id -> seasonWhere { it.id == id }?.let { return it } }
    onDeckEpisode?.parentIndex?.let { number -> seasonWhere { it.index == number }?.let { return it } }
    return firstUnwatchedSeasonIndex(seasons) ?: defaultPlaybackSeasonIndex(seasons)
}

/**
 * A season's episode rows with the identity detail rows rely on: non-episodes dropped; server from [show] first; the
 * library from the episode, else [season] when it has a library, else [show]; the show as grandparent; the season as
 * parent where the episode names none.
 */
fun normalizeSeasonEpisodes(episodes: List<MediaItem>, show: MediaItem, season: MediaItem): List<MediaItem> {
    val fallback = if (season.libraryId != null) season else show
    val fallbackIsSeason = fallback.kind == MediaKind.SEASON
    val fallbackGrandparentTitle = fallbackGrandparentTitle(fallback, isShow = fallback.kind == MediaKind.SHOW)
    return episodes.filter { it.kind == MediaKind.EPISODE }.map { episode ->
        episode.copy(
            serverId = show.serverId ?: episode.serverId ?: fallback.serverId,
            serverName = show.serverName ?: episode.serverName ?: fallback.serverName,
            libraryId = episode.libraryId ?: fallback.libraryId,
            libraryTitle = episode.libraryTitle ?: fallback.libraryTitle,
            grandparentId = show.id,
            grandparentTitle = show.title ?: episode.grandparentTitle ?: fallbackGrandparentTitle,
            parentId = episode.parentId ?: season.id,
            parentTitle = episode.parentTitle ?: if (fallbackIsSeason) fallback.title else null,
            parentIndex = episode.parentIndex ?: season.index,
        )
    }
}

private fun MediaItem.withFallbackLibrary(fallback: MediaItem?): MediaItem {
    if (fallback == null) return this
    val fallbackIsSeason = fallback.kind == MediaKind.SEASON
    val fallbackIsShow = fallback.kind == MediaKind.SHOW
    return copy(
        serverId = serverId ?: fallback.serverId,
        serverName = serverName ?: fallback.serverName,
        libraryId = libraryId ?: fallback.libraryId,
        libraryTitle = libraryTitle ?: fallback.libraryTitle,
        parentId = parentId ?: if (fallbackIsSeason) fallback.id else null,
        parentTitle = parentTitle ?: if (fallbackIsSeason) fallback.title else null,
        grandparentId = grandparentId ?: if (fallbackIsShow) fallback.id else fallback.grandparentId ?: fallback.parentId,
        grandparentTitle = grandparentTitle ?: fallbackGrandparentTitle(fallback, fallbackIsShow),
    )
}

private fun fallbackGrandparentTitle(fallback: MediaItem, isShow: Boolean): String? =
    if (isShow) fallback.title else fallback.grandparentTitle ?: fallback.parentTitle
